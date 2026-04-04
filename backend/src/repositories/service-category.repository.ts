import type { Pool } from "pg";

export type ServiceCategoryRow = {
	id: string;
	studio_id: string | null;
	name: string;
	icon: string | null;
	position: number;
	is_active: boolean;
	created_at: string;
};

export class ServiceCategoryRepository {
	constructor(private pool: Pool) {}

	/** Global + studio categories (used in onboarding) */
	async listByStudio(studioId: string): Promise<ServiceCategoryRow[]> {
		const { rows } = await this.pool.query<ServiceCategoryRow>(
			`SELECT c.id, c.studio_id, c.name, c.icon, c.position, c.is_active, c.created_at
       FROM service_categories c
       WHERE (studio_id IS NULL OR studio_id = $1)
         AND c.is_active = true
       ORDER BY c.position ASC, c.name ASC
       LIMIT 50`,
			[studioId],
		);
		return rows;
	}

	/** Studio-only categories (excludes globals) */
	async listStudioOnly(studioId: string): Promise<ServiceCategoryRow[]> {
		const { rows } = await this.pool.query<ServiceCategoryRow>(
			`SELECT c.id, c.studio_id, c.name, c.icon, c.position, c.is_active, c.created_at
       FROM service_categories c
       WHERE studio_id = $1
         AND c.is_active = true
       ORDER BY c.position ASC, c.name ASC
       LIMIT 50`,
			[studioId],
		);
		return rows;
	}

	/** Global categories only (for onboarding template selection) */
	async listGlobal(): Promise<ServiceCategoryRow[]> {
		const { rows } = await this.pool.query<ServiceCategoryRow>(
			`SELECT c.id, c.studio_id, c.name, c.icon, c.position, c.is_active, c.created_at
       FROM service_categories c
       WHERE studio_id IS NULL
         AND c.is_active = true
       ORDER BY c.position ASC, c.name ASC
       LIMIT 50`,
		);
		return rows;
	}

	async create(
		studioId: string,
		name: string,
		icon?: string,
		position?: number,
	): Promise<ServiceCategoryRow> {
		const { rows } = await this.pool.query<ServiceCategoryRow>(
			`INSERT INTO service_categories (studio_id, name, icon, position)
       VALUES ($1, $2, $3, COALESCE($4, (SELECT COALESCE(MAX(position), 0) + 1 FROM service_categories WHERE studio_id = $1)))
       RETURNING id, studio_id, name, icon, position, is_active, created_at`,
			[studioId, name, icon ?? null, position ?? null],
		);
		return rows[0]!;
	}

	async update(
		id: string,
		studioId: string,
		data: { name?: string; icon?: string; position?: number; is_active?: boolean },
	): Promise<ServiceCategoryRow | null> {
		const sets: string[] = [];
		const values: unknown[] = [];
		let idx = 1;

		if (data.name !== undefined) {
			sets.push(`name = $${idx++}`);
			values.push(data.name);
		}
		if (data.icon !== undefined) {
			sets.push(`icon = $${idx++}`);
			values.push(data.icon);
		}
		if (data.position !== undefined) {
			sets.push(`position = $${idx++}`);
			values.push(data.position);
		}
		if (data.is_active !== undefined) {
			sets.push(`is_active = $${idx++}`);
			values.push(data.is_active);
		}

		if (sets.length === 0) return null;

		values.push(id, studioId);
		const { rows } = await this.pool.query<ServiceCategoryRow>(
			`UPDATE service_categories
       SET ${sets.join(", ")}
       WHERE id = $${idx++} AND studio_id = $${idx}
       RETURNING id, studio_id, name, icon, position, is_active, created_at`,
			values,
		);
		return rows[0] ?? null;
	}

	async delete(id: string, studioId: string): Promise<boolean> {
		const { rowCount } = await this.pool.query(
			`DELETE FROM service_categories WHERE id = $1 AND studio_id = $2`,
			[id, studioId],
		);
		return (rowCount ?? 0) > 0;
	}

	async hasServices(id: string): Promise<boolean> {
		const { rows } = await this.pool.query<{ count: string }>(
			`SELECT COUNT(*)::text as count FROM services WHERE category_id = $1 AND deleted_at IS NULL`,
			[id],
		);
		return Number.parseInt(rows[0]?.count ?? "0") > 0;
	}

	/** Copy selected global categories to studio-specific ones. Returns created rows. */
	async copyGlobalsToStudio(
		studioId: string,
		globalCategoryIds: string[],
	): Promise<ServiceCategoryRow[]> {
		if (globalCategoryIds.length === 0) return [];

		const placeholders = globalCategoryIds.map((_, i) => `$${i + 2}`).join(", ");
		const { rows } = await this.pool.query<ServiceCategoryRow>(
			`INSERT INTO service_categories (studio_id, name, icon, position)
       SELECT $1, g.name, g.icon, g.position
       FROM service_categories g
       WHERE g.id IN (${placeholders})
         AND g.studio_id IS NULL
       ON CONFLICT DO NOTHING
       RETURNING id, studio_id, name, icon, position, is_active, created_at`,
			[studioId, ...globalCategoryIds],
		);
		return rows;
	}
}
