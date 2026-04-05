import type { Pool } from "pg";
import { ConflictError } from "../utils/errors.js";

// ─── Types ─────────────────────────────────────────────────────────────────

export type PackageRow = {
	id: string;
	studio_id: string;
	service_id: string;
	name: string;
	total_sessions: number;
	price: number;
	validity_days: number;
	created_at: string;
	updated_at: string;
};

export type CreatePackageInput = {
	studioId: string;
	serviceId: string;
	name: string;
	totalSessions: number;
	price: number;
	validityDays: number;
};

export type UpdatePackageInput = {
	name?: string;
	totalSessions?: number;
	price?: number;
	validityDays?: number;
};

export type ListPackagesResult = {
	packages: PackageRow[];
	hasMore: boolean;
	nextCursor: string | null;
};

const PACKAGE_COLUMNS = `
  id,
  studio_id,
  service_id,
  name,
  total_sessions,
  price,
  validity_days,
  created_at,
  updated_at
`.trim();

// ─── Repository ────────────────────────────────────────────────────────────

export class PackageRepository {
	constructor(private pool: Pool) {}

	async list(
		studioId: string,
		options: { serviceId?: string; cursor?: string; limit?: number } = {},
	): Promise<ListPackagesResult> {
		const { serviceId, cursor, limit = 20 } = options;
		const fetchLimit = limit + 1;
		const params: unknown[] = [studioId, fetchLimit];

		let serviceFilter = "";
		if (serviceId) {
			params.push(serviceId);
			serviceFilter = `AND service_id = $${params.length}`;
		}

		let cursorClause = "";
		if (cursor) {
			const { rows: cursorRows } = await this.pool.query<{
				pkg_name: string;
				pkg_id: string;
			}>(
				`SELECT name AS pkg_name, id AS pkg_id
				 FROM packages
				 WHERE id = $1 AND studio_id = $2`,
				[cursor, studioId],
			);
			if (cursorRows[0]) {
				const c = cursorRows[0];
				params.push(c.pkg_name, c.pkg_id);
				cursorClause = `AND (name, id) > ($${params.length - 1}, $${params.length})`;
			}
		}

		const { rows } = await this.pool.query<PackageRow>(
			`SELECT ${PACKAGE_COLUMNS}
			 FROM packages
			 WHERE studio_id = $1
			   ${serviceFilter}
			   ${cursorClause}
			 ORDER BY name ASC, id ASC
			 LIMIT $2`,
			params,
		);

		const hasMore = rows.length > limit;
		const packages = hasMore ? rows.slice(0, limit) : rows;
		const nextCursor = hasMore
			? (packages[packages.length - 1]?.id ?? null)
			: null;

		return { packages, hasMore, nextCursor };
	}

	async getById(
		studioId: string,
		packageId: string,
	): Promise<PackageRow | null> {
		const { rows } = await this.pool.query<PackageRow>(
			`SELECT ${PACKAGE_COLUMNS}
			 FROM packages
			 WHERE studio_id = $1
			   AND id = $2`,
			[studioId, packageId],
		);
		return rows[0] ?? null;
	}

	async create(input: CreatePackageInput): Promise<PackageRow> {
		const { rows } = await this.pool.query<PackageRow>(
			`INSERT INTO packages
			   (id, studio_id, service_id, name, total_sessions, price, validity_days)
			 VALUES
			   (gen_random_uuid(), $1, $2, $3, $4, $5, $6)
			 RETURNING ${PACKAGE_COLUMNS}`,
			[
				input.studioId,
				input.serviceId,
				input.name,
				input.totalSessions,
				input.price,
				input.validityDays,
			],
		);
		return rows[0]!;
	}

	async update(
		studioId: string,
		packageId: string,
		data: UpdatePackageInput,
	): Promise<PackageRow | null> {
		const setClauses: string[] = [];
		const params: unknown[] = [];

		if (data.name !== undefined) {
			params.push(data.name);
			setClauses.push(`name = $${params.length}`);
		}
		if (data.totalSessions !== undefined) {
			params.push(data.totalSessions);
			setClauses.push(`total_sessions = $${params.length}`);
		}
		if (data.price !== undefined) {
			params.push(data.price);
			setClauses.push(`price = $${params.length}`);
		}
		if (data.validityDays !== undefined) {
			params.push(data.validityDays);
			setClauses.push(`validity_days = $${params.length}`);
		}

		if (setClauses.length === 0) {
			return this.getById(studioId, packageId);
		}

		setClauses.push("updated_at = NOW()");

		params.push(studioId);
		const studioParam = params.length;
		params.push(packageId);
		const idParam = params.length;

		const { rows } = await this.pool.query<PackageRow>(
			`UPDATE packages
			 SET ${setClauses.join(", ")}
			 WHERE studio_id = $${studioParam}
			   AND id = $${idParam}
			 RETURNING ${PACKAGE_COLUMNS}`,
			params,
		);
		return rows[0] ?? null;
	}

	async delete(studioId: string, packageId: string): Promise<void> {
		// Guard: cannot delete if active subscriptions exist
		const { rows: countRows } = await this.pool.query<{ count: string }>(
			`SELECT COUNT(*) AS count
			 FROM package_subscriptions
			 WHERE package_id = $1
			   AND studio_id = $2
			   AND status = 'active'`,
			[packageId, studioId],
		);
		const activeCount = parseInt(countRows[0]?.count ?? "0", 10);
		if (activeCount > 0) {
			throw new ConflictError(
				"PACKAGE_HAS_SUBSCRIPTIONS",
				"Cannot delete package with active subscriptions",
			);
		}

		await this.pool.query(
			`DELETE FROM packages
			 WHERE studio_id = $1
			   AND id = $2`,
			[studioId, packageId],
		);
	}

	/**
	 * Returns the per-session price in centavos (rounded).
	 */
	async getUnitPrice(
		studioId: string,
		packageId: string,
	): Promise<number | null> {
		const pkg = await this.getById(studioId, packageId);
		if (!pkg) return null;
		return Math.round(pkg.price / pkg.total_sessions);
	}
}
