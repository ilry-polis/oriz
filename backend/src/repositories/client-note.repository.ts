import type { Pool } from "pg";

export type ClientNoteRow = {
	id: string;
	studio_id: string;
	client_id: string;
	professional_id: string;
	content: string;
	created_at: string;
};

export class ClientNoteRepository {
	constructor(private pool: Pool) {}

	async create(
		studioId: string,
		clientId: string,
		professionalId: string,
		content: string,
	): Promise<ClientNoteRow> {
		const { rows } = await this.pool.query<ClientNoteRow>(
			`INSERT INTO client_notes (studio_id, client_id, professional_id, content)
			 VALUES ($1, $2, $3, $4)
			 RETURNING id, studio_id, client_id, professional_id, content, created_at`,
			[studioId, clientId, professionalId, content],
		);
		return rows[0];
	}

	async listByClient(
		studioId: string,
		clientId: string,
		cursor?: string,
		limit = 20,
	): Promise<ClientNoteRow[]> {
		const params: unknown[] = [studioId, clientId, limit + 1];
		let sql = `SELECT id, studio_id, client_id, professional_id, content, created_at
		           FROM client_notes
		           WHERE studio_id = $1 AND client_id = $2`;
		if (cursor) {
			sql += " AND created_at < (SELECT created_at FROM client_notes WHERE id = $4 AND studio_id = $1)";
			params.push(cursor);
		}
		sql += " ORDER BY created_at DESC LIMIT $3";
		const { rows } = await this.pool.query<ClientNoteRow>(sql, params);
		return rows;
	}
}
