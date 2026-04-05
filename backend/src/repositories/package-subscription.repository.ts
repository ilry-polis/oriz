import type { Pool } from "pg";

// ─── Types ─────────────────────────────────────────────────────────────────

export type SubscriptionStatus = "active" | "completed" | "expired";

export type PackageSubscriptionRow = {
	id: string;
	studio_id: string;
	package_id: string;
	client_id: string;
	sessions_used: number;
	sessions_total: number;
	expires_at: string;
	status: SubscriptionStatus;
	created_at: string;
	updated_at: string;
};

export type CreateSubscriptionInput = {
	studioId: string;
	packageId: string;
	clientId: string;
	sessionsTotal: number;
	expiresAt: string; // ISO 8601
};

export type ListSubscriptionsResult = {
	subscriptions: PackageSubscriptionRow[];
	hasMore: boolean;
	nextCursor: string | null;
};

const SUBSCRIPTION_COLUMNS = `
  id,
  studio_id,
  package_id,
  client_id,
  sessions_used,
  sessions_total,
  expires_at,
  status,
  created_at,
  updated_at
`.trim();

// ─── Repository ────────────────────────────────────────────────────────────

export class PackageSubscriptionRepository {
	constructor(private pool: Pool) {}

	async create(
		input: CreateSubscriptionInput,
	): Promise<PackageSubscriptionRow> {
		const { rows } = await this.pool.query<PackageSubscriptionRow>(
			`INSERT INTO package_subscriptions
			   (id, studio_id, package_id, client_id, sessions_used, sessions_total, expires_at, status)
			 VALUES
			   (gen_random_uuid(), $1, $2, $3, 0, $4, $5, 'active')
			 RETURNING ${SUBSCRIPTION_COLUMNS}`,
			[
				input.studioId,
				input.packageId,
				input.clientId,
				input.sessionsTotal,
				input.expiresAt,
			],
		);
		return rows[0]!;
	}

	/**
	 * Atomic session deduction using UPDATE...RETURNING.
	 * - Only deducts if status = 'active' AND expires_at > now()
	 * - Automatically transitions to 'completed' when sessions_used reaches sessions_total
	 * - Returns null if the subscription is expired, completed, or not found
	 */
	async deductSession(
		studioId: string,
		subscriptionId: string,
	): Promise<PackageSubscriptionRow | null> {
		const { rows } = await this.pool.query<PackageSubscriptionRow>(
			`UPDATE package_subscriptions
			 SET
			   sessions_used = sessions_used + 1,
			   status = CASE
			     WHEN sessions_used + 1 >= sessions_total THEN 'completed'
			     ELSE 'active'
			   END,
			   updated_at = NOW()
			 WHERE id = $1
			   AND studio_id = $2
			   AND status = 'active'
			   AND expires_at > NOW()
			 RETURNING ${SUBSCRIPTION_COLUMNS}`,
			[subscriptionId, studioId],
		);
		return rows[0] ?? null;
	}

	/**
	 * Returns the active (non-expired) subscription for a client+service pair.
	 * Joins packages to filter by service_id.
	 */
	async getActiveForClientService(
		studioId: string,
		clientId: string,
		serviceId: string,
	): Promise<PackageSubscriptionRow | null> {
		const { rows } = await this.pool.query<PackageSubscriptionRow>(
			`SELECT
			   ps.id,
			   ps.studio_id,
			   ps.package_id,
			   ps.client_id,
			   ps.sessions_used,
			   ps.sessions_total,
			   ps.expires_at,
			   ps.status,
			   ps.created_at,
			   ps.updated_at
			 FROM package_subscriptions ps
			 JOIN packages pk ON pk.id = ps.package_id
			 WHERE ps.studio_id = $1
			   AND ps.client_id = $2
			   AND pk.service_id = $3
			   AND ps.status = 'active'
			   AND ps.expires_at > NOW()
			 ORDER BY ps.expires_at ASC
			 LIMIT 1`,
			[studioId, clientId, serviceId],
		);
		return rows[0] ?? null;
	}

	async list(
		studioId: string,
		options: {
			packageId?: string;
			clientId?: string;
			status?: SubscriptionStatus;
			cursor?: string;
			limit?: number;
		} = {},
	): Promise<ListSubscriptionsResult> {
		const { packageId, clientId, status, cursor, limit = 20 } = options;
		const fetchLimit = limit + 1;
		const params: unknown[] = [studioId, fetchLimit];
		const filters: string[] = [];

		if (packageId) {
			params.push(packageId);
			filters.push(`package_id = $${params.length}`);
		}
		if (clientId) {
			params.push(clientId);
			filters.push(`client_id = $${params.length}`);
		}
		if (status) {
			params.push(status);
			filters.push(`status = $${params.length}`);
		}

		let cursorClause = "";
		if (cursor) {
			const { rows: cursorRows } = await this.pool.query<{ id: string }>(
				`SELECT id FROM package_subscriptions WHERE id = $1 AND studio_id = $2`,
				[cursor, studioId],
			);
			if (cursorRows[0]) {
				params.push(cursor);
				cursorClause = `AND id > $${params.length}`;
			}
		}

		const whereClause =
			filters.length > 0
				? `AND ${filters.join(" AND ")}`
				: "";

		const { rows } = await this.pool.query<PackageSubscriptionRow>(
			`SELECT ${SUBSCRIPTION_COLUMNS}
			 FROM package_subscriptions
			 WHERE studio_id = $1
			   ${whereClause}
			   ${cursorClause}
			 ORDER BY created_at DESC, id DESC
			 LIMIT $2`,
			params,
		);

		const hasMore = rows.length > fetchLimit - 1;
		const subscriptions = hasMore ? rows.slice(0, limit) : rows;
		const nextCursor = hasMore
			? (subscriptions[subscriptions.length - 1]?.id ?? null)
			: null;

		return { subscriptions, hasMore, nextCursor };
	}

	async getById(
		studioId: string,
		subscriptionId: string,
	): Promise<PackageSubscriptionRow | null> {
		const { rows } = await this.pool.query<PackageSubscriptionRow>(
			`SELECT ${SUBSCRIPTION_COLUMNS}
			 FROM package_subscriptions
			 WHERE studio_id = $1
			   AND id = $2`,
			[studioId, subscriptionId],
		);
		return rows[0] ?? null;
	}

	async updateExpiresAt(
		studioId: string,
		subscriptionId: string,
		newExpiresAt: string,
	): Promise<PackageSubscriptionRow | null> {
		const { rows } = await this.pool.query<PackageSubscriptionRow>(
			`UPDATE package_subscriptions
			 SET expires_at = $1, updated_at = NOW()
			 WHERE studio_id = $2
			   AND id = $3
			 RETURNING ${SUBSCRIPTION_COLUMNS}`,
			[newExpiresAt, studioId, subscriptionId],
		);
		return rows[0] ?? null;
	}
}
