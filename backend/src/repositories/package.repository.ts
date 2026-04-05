import type { Pool } from "pg";
import { ConflictError } from "../utils/errors.js";

// ─── Types ─────────────────────────────────────────────────────────────────

export type PackageRow = {
	id: string;
	studio_id: string;
	name: string;
	total_sessions: number;
	price: number;
	validity_days: number;
	created_at: string;
	updated_at: string;
	service_ids?: string[];
	service_names?: string[];
};

export type CreatePackageInput = {
	studioId: string;
	serviceIds: string[];
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
			serviceFilter = `AND p.id IN (SELECT package_id FROM package_services WHERE service_id = $${params.length})`;
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
				cursorClause = `AND (p.name, p.id) > ($${params.length - 1}, $${params.length})`;
			}
		}

		const { rows } = await this.pool.query<PackageRow>(
			`SELECT p.${PACKAGE_COLUMNS.split(",\n").map((c) => c.trim()).join(", p.")},
			        COALESCE(array_agg(ps.service_id) FILTER (WHERE ps.service_id IS NOT NULL), '{}') AS service_ids,
			        COALESCE(array_agg(s.name) FILTER (WHERE s.name IS NOT NULL), '{}') AS service_names
			 FROM packages p
			 LEFT JOIN package_services ps ON ps.package_id = p.id
			 LEFT JOIN services s ON s.id = ps.service_id
			 WHERE p.studio_id = $1
			   ${serviceFilter}
			   ${cursorClause}
			 GROUP BY p.id
			 ORDER BY p.name ASC, p.id ASC
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
			`SELECT p.id, p.studio_id, p.name, p.total_sessions, p.price,
			        p.validity_days, p.created_at, p.updated_at,
			        COALESCE(array_agg(ps.service_id) FILTER (WHERE ps.service_id IS NOT NULL), '{}') AS service_ids,
			        COALESCE(array_agg(s.name) FILTER (WHERE s.name IS NOT NULL), '{}') AS service_names
			 FROM packages p
			 LEFT JOIN package_services ps ON ps.package_id = p.id
			 LEFT JOIN services s ON s.id = ps.service_id
			 WHERE p.studio_id = $1
			   AND p.id = $2
			 GROUP BY p.id`,
			[studioId, packageId],
		);
		return rows[0] ?? null;
	}

	async create(input: CreatePackageInput): Promise<PackageRow> {
		const client = await this.pool.connect();
		try {
			await client.query("BEGIN");

			const { rows } = await client.query<PackageRow>(
				`INSERT INTO packages
				   (id, studio_id, name, total_sessions, price, validity_days)
				 VALUES
				   (gen_random_uuid(), $1, $2, $3, $4, $5)
				 RETURNING ${PACKAGE_COLUMNS}`,
				[
					input.studioId,
					input.name,
					input.totalSessions,
					input.price,
					input.validityDays,
				],
			);
			const pkg = rows[0] as PackageRow;

			// Insert junction rows
			for (const serviceId of input.serviceIds) {
				await client.query(
					`INSERT INTO package_services (package_id, service_id, studio_id)
					 VALUES ($1, $2, $3)`,
					[pkg.id, serviceId, input.studioId],
				);
			}

			await client.query("COMMIT");

			pkg.service_ids = input.serviceIds;
			return pkg;
		} catch (err) {
			await client.query("ROLLBACK");
			throw err;
		} finally {
			client.release();
		}
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

		await this.pool.query(
			`UPDATE packages
			 SET ${setClauses.join(", ")}
			 WHERE studio_id = $${studioParam}
			   AND id = $${idParam}`,
			params,
		);
		return this.getById(studioId, packageId);
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
		const activeCount = Number.parseInt(countRows[0]?.count ?? "0", 10);
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
