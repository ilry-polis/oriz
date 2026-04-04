import type { Pool } from "pg";

export type AnamnesisRow = {
	id: string;
	studio_id: string;
	client_id: string;
	service_category_id: string;
	fields: Record<string, unknown>;
	created_at: string;
	updated_at: string;
};

export class AnamnesisRepository {
	constructor(private pool: Pool) {}

	async upsert(
		studioId: string,
		clientId: string,
		serviceCategoryId: string,
		fields: Record<string, unknown>,
	): Promise<AnamnesisRow> {
		const { rows } = await this.pool.query<AnamnesisRow>(
			`INSERT INTO anamneses (studio_id, client_id, service_category_id, fields)
			 VALUES ($1, $2, $3, $4)
			 ON CONFLICT (studio_id, client_id, service_category_id)
			 DO UPDATE SET fields = $4, updated_at = now()
			 RETURNING id, studio_id, client_id, service_category_id, fields, created_at, updated_at`,
			[studioId, clientId, serviceCategoryId, JSON.stringify(fields)],
		);
		return rows[0];
	}

	async getByClientAndCategory(
		studioId: string,
		clientId: string,
		serviceCategoryId: string,
	): Promise<AnamnesisRow | null> {
		const { rows } = await this.pool.query<AnamnesisRow>(
			`SELECT id, studio_id, client_id, service_category_id, fields, created_at, updated_at
			 FROM anamneses
			 WHERE studio_id = $1 AND client_id = $2 AND service_category_id = $3
			 LIMIT 1`,
			[studioId, clientId, serviceCategoryId],
		);
		return rows[0] ?? null;
	}

	async listByClient(
		studioId: string,
		clientId: string,
	): Promise<AnamnesisRow[]> {
		const { rows } = await this.pool.query<AnamnesisRow>(
			`SELECT id, studio_id, client_id, service_category_id, fields, created_at, updated_at
			 FROM anamneses
			 WHERE studio_id = $1 AND client_id = $2
			 ORDER BY created_at ASC`,
			[studioId, clientId],
		);
		return rows;
	}
}
