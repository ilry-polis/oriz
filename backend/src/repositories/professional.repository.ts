import type { Pool, PoolClient } from "pg";

export type ProfessionalRow = {
	id: string;
	studio_id: string;
	user_id: string;
	name: string;
	commission_type: "percentage" | "fixed";
	commission_value: number;
	card_fee_policy: "studio" | "professional" | "split";
	working_hours: Record<string, unknown>;
	is_active: boolean;
	created_at: string;
	updated_at: string;
};

export type CreateProfessionalData = {
	studioId: string;
	userId: string;
	name: string;
	commissionType: "percentage" | "fixed";
	commissionValue: number;
	cardFeePolicy: "studio" | "professional" | "split";
};

export type UpdateProfessionalData = {
	name?: string;
	commissionType?: "percentage" | "fixed";
	commissionValue?: number;
	cardFeePolicy?: "studio" | "professional" | "split";
	isActive?: boolean;
	workingHours?: Record<string, unknown>;
};

export class ProfessionalRepository {
	constructor(private pool: Pool) {}

	// ─── Existing methods (preserved) ────────────────────────────────────────────

	async findByUserId(
		userId: string,
		studioId: string,
	): Promise<ProfessionalRow | null> {
		const { rows } = await this.pool.query<ProfessionalRow>(
			`SELECT p.id, p.studio_id, p.user_id, p.name,
              p.commission_type, p.commission_value, p.card_fee_policy,
              p.working_hours, p.is_active, p.created_at, p.updated_at
       FROM professionals p
       WHERE p.user_id = $1 AND p.studio_id = $2
       LIMIT 1`,
			[userId, studioId],
		);
		return rows[0] ?? null;
	}

	async updateWorkingHours(
		professionalId: string,
		studioId: string,
		workingHours: Record<string, unknown>,
	): Promise<ProfessionalRow | null> {
		const { rows } = await this.pool.query<ProfessionalRow>(
			`UPDATE professionals p
       SET working_hours = $3, updated_at = now()
       WHERE p.id = $1 AND p.studio_id = $2
       RETURNING p.id, p.studio_id, p.user_id, p.name,
                 p.commission_type, p.commission_value, p.card_fee_policy,
                 p.working_hours, p.is_active, p.created_at, p.updated_at`,
			[professionalId, studioId, JSON.stringify(workingHours)],
		);
		return rows[0] ?? null;
	}

	// ─── New methods ──────────────────────────────────────────────────────────────

	async create(data: CreateProfessionalData): Promise<ProfessionalRow> {
		const { rows } = await this.pool.query<ProfessionalRow>(
			`INSERT INTO professionals
         (studio_id, user_id, name, commission_type, commission_value, card_fee_policy)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING id, studio_id, user_id, name, commission_type, commission_value,
                 card_fee_policy, working_hours, is_active, created_at, updated_at`,
			[
				data.studioId,
				data.userId,
				data.name,
				data.commissionType,
				data.commissionValue,
				data.cardFeePolicy,
			],
		);
		return rows[0]!;
	}

	/**
	 * Cursor-based list ordered by name ASC.
	 * Returns limit+1 rows so caller can detect has_more.
	 * All queries filter by studio_id (belt-and-suspenders with RLS).
	 */
	async list(
		studioId: string,
		cursor?: string,
		limit = 20,
	): Promise<ProfessionalRow[]> {
		const params: unknown[] = [studioId, limit];
		let sql = `
      SELECT id, studio_id, user_id, name, commission_type, commission_value,
             card_fee_policy, working_hours, is_active, created_at, updated_at
      FROM professionals
      WHERE studio_id = $1
    `;
		if (cursor) {
			sql +=
				" AND (name, id) > ((SELECT name FROM professionals WHERE id = $3 AND studio_id = $1), $3)";
			params.push(cursor);
		}
		sql += " ORDER BY name ASC, id ASC LIMIT $2";
		const { rows } = await this.pool.query<ProfessionalRow>(sql, params);
		return rows;
	}

	async getById(
		studioId: string,
		professionalId: string,
	): Promise<ProfessionalRow | null> {
		const { rows } = await this.pool.query<ProfessionalRow>(
			`SELECT id, studio_id, user_id, name, commission_type, commission_value,
              card_fee_policy, working_hours, is_active, created_at, updated_at
       FROM professionals
       WHERE id = $1 AND studio_id = $2
       LIMIT 1`,
			[professionalId, studioId],
		);
		return rows[0] ?? null;
	}

	async update(
		studioId: string,
		professionalId: string,
		data: UpdateProfessionalData,
	): Promise<ProfessionalRow | null> {
		// Build SET clause dynamically — only update provided fields
		const setClauses: string[] = ["updated_at = now()"];
		const params: unknown[] = [professionalId, studioId];
		let idx = 3;

		if (data.name !== undefined) {
			setClauses.push(`name = $${idx++}`);
			params.push(data.name);
		}
		if (data.commissionType !== undefined) {
			setClauses.push(`commission_type = $${idx++}`);
			params.push(data.commissionType);
		}
		if (data.commissionValue !== undefined) {
			setClauses.push(`commission_value = $${idx++}`);
			params.push(data.commissionValue);
		}
		if (data.cardFeePolicy !== undefined) {
			setClauses.push(`card_fee_policy = $${idx++}`);
			params.push(data.cardFeePolicy);
		}
		if (data.isActive !== undefined) {
			setClauses.push(`is_active = $${idx++}`);
			params.push(data.isActive);
		}
		if (data.workingHours !== undefined) {
			setClauses.push(`working_hours = $${idx++}`);
			params.push(JSON.stringify(data.workingHours));
		}

		const { rows } = await this.pool.query<ProfessionalRow>(
			`UPDATE professionals
       SET ${setClauses.join(", ")}
       WHERE id = $1 AND studio_id = $2
       RETURNING id, studio_id, user_id, name, commission_type, commission_value,
                 card_fee_policy, working_hours, is_active, created_at, updated_at`,
			params,
		);
		return rows[0] ?? null;
	}

	/**
	 * Atomically replaces all service links for a professional (DELETE + INSERT in transaction).
	 * Per RESEARCH.md Pattern 7.
	 */
	async replaceServiceLinks(
		professionalId: string,
		studioId: string,
		serviceIds: string[],
	): Promise<void> {
		const client: PoolClient = await this.pool.connect();
		try {
			await client.query("BEGIN");

			// Delete all existing links for this professional in this studio
			await client.query(
				`DELETE FROM professional_services
         WHERE professional_id = $1
           AND EXISTS (
             SELECT 1 FROM professionals p
             WHERE p.id = $1 AND p.studio_id = $2
           )`,
				[professionalId, studioId],
			);

			// Insert new links
			if (serviceIds.length > 0) {
				const valuePlaceholders = serviceIds
					.map((_, i) => `(gen_random_uuid(), $1, $2, $${i + 3})`)
					.join(", ");
				await client.query(
					`INSERT INTO professional_services (id, studio_id, professional_id, service_id)
           VALUES ${valuePlaceholders}
           ON CONFLICT (professional_id, service_id) DO NOTHING`,
					[studioId, professionalId, ...serviceIds],
				);
			}

			await client.query("COMMIT");
		} catch (err) {
			await client.query("ROLLBACK");
			throw err;
		} finally {
			client.release();
		}
	}

	async getServiceLinks(
		professionalId: string,
		studioId: string,
	): Promise<string[]> {
		const { rows } = await this.pool.query<{ service_id: string }>(
			`SELECT ps.service_id
       FROM professional_services ps
       JOIN professionals p ON p.id = ps.professional_id
       WHERE ps.professional_id = $1 AND p.studio_id = $2
       ORDER BY ps.service_id ASC`,
			[professionalId, studioId],
		);
		return rows.map((r) => r.service_id);
	}
}
