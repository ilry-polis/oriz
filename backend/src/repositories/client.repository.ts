import type { Pool } from "pg";
import { ConflictError, NotFoundError } from "../utils/errors.js";

export type AppointmentHistoryRow = {
	id: string;
	service_name: string;
	professional_name: string;
	scheduled_at: string;
	status: string;
};

// ─── Types ───────────────────────────────────────────────────

export type ClientRow = {
	id: string;
	studio_id: string;
	name: string;
	phone: string | null;
	email: string | null;
	birth_date: string | null;
	tags: string[];
	notes: string | null;
	last_appointment_at: string | null;
	created_at: string;
	updated_at: string;
};

export type CreateClientInput = {
	name: string;
	phone?: string | null;
	email?: string | null;
	birth_date?: string | null;
	tags?: string[];
	notes?: string | null;
};

export type UpdateClientInput = Partial<{
	name: string;
	phone: string | null;
	email: string | null;
	birth_date: string | null;
	tags: string[];
	notes: string | null;
}>;

export type ListClientsOptions = {
	cursor?: string;
	limit: number;
	search?: string;
	tag?: string;
};

export type ListClientsResult = {
	rows: ClientRow[];
	has_more: boolean;
	next_cursor: string | null;
};

// ─── Repository ──────────────────────────────────────────────

export class ClientRepository {
	constructor(private pool: Pool) {}

	async create(studioId: string, input: CreateClientInput): Promise<ClientRow> {
		try {
			const { rows } = await this.pool.query<ClientRow>(
				`INSERT INTO clients (id, studio_id, name, phone, email, birth_date, tags, notes)
         VALUES (gen_random_uuid(), $1, $2, $3, $4, $5, $6::jsonb, $7)
         RETURNING id, studio_id, name, phone, email, birth_date, tags, notes,
                   last_appointment_at, created_at, updated_at`,
				[
					studioId,
					input.name,
					input.phone ?? null,
					input.email ?? null,
					input.birth_date ?? null,
					JSON.stringify(input.tags ?? []),
					input.notes ?? null,
				],
			);
			if (!rows[0]) throw new Error("Insert returned no rows");
			return rows[0];
		} catch (err: unknown) {
			if (
				typeof err === "object" &&
				err !== null &&
				"code" in err &&
				(err as { code: string }).code === "23505"
			) {
				throw new ConflictError(
					"PHONE_ALREADY_EXISTS",
					"Phone number already exists for this studio",
					"phone",
				);
			}
			throw err;
		}
	}

	async list(
		studioId: string,
		opts: ListClientsOptions,
	): Promise<ListClientsResult> {
		const params: unknown[] = [studioId];
		const conditions: string[] = ["c.studio_id = $1"];

		// Cursor: last seen (id, name) for keyset pagination
		if (opts.cursor) {
			params.push(opts.cursor);
			// We use the id as cursor — fetch name of cursor row to do keyset
			conditions.push(`(c.name, c.id) > (
        SELECT name, id FROM clients WHERE id = $${params.length} AND studio_id = $1
      )`);
		}

		if (opts.search) {
			params.push(`%${opts.search}%`);
			conditions.push(
				`(c.name ILIKE $${params.length} OR c.phone ILIKE $${params.length})`,
			);
		}

		if (opts.tag) {
			params.push(JSON.stringify([opts.tag]));
			conditions.push(`c.tags @> $${params.length}::jsonb`);
		}

		// Fetch limit + 1 to determine has_more
		const fetchLimit = opts.limit + 1;
		params.push(fetchLimit);

		const where = conditions.join(" AND ");
		const { rows } = await this.pool.query<ClientRow>(
			`SELECT c.id, c.studio_id, c.name, c.phone, c.email, c.birth_date,
              c.tags, c.notes, c.last_appointment_at, c.created_at, c.updated_at
       FROM clients c
       WHERE ${where}
       ORDER BY c.name ASC, c.id ASC
       LIMIT $${params.length}`,
			params,
		);

		const has_more = rows.length > opts.limit;
		const data = rows.slice(0, opts.limit);
		const next_cursor = has_more ? (data[data.length - 1]?.id ?? null) : null;

		return { rows: data, has_more, next_cursor };
	}

	async getById(studioId: string, clientId: string): Promise<ClientRow | null> {
		const { rows } = await this.pool.query<ClientRow>(
			`SELECT id, studio_id, name, phone, email, birth_date, tags, notes,
              last_appointment_at, created_at, updated_at
       FROM clients
       WHERE id = $1 AND studio_id = $2`,
			[clientId, studioId],
		);
		return rows[0] ?? null;
	}

	async update(
		studioId: string,
		clientId: string,
		input: UpdateClientInput,
	): Promise<ClientRow | null> {
		const setClauses: string[] = [];
		const params: unknown[] = [clientId, studioId];

		if (input.name !== undefined) {
			params.push(input.name);
			setClauses.push(`name = $${params.length}`);
		}
		if (input.phone !== undefined) {
			params.push(input.phone);
			setClauses.push(`phone = $${params.length}`);
		}
		if (input.email !== undefined) {
			params.push(input.email);
			setClauses.push(`email = $${params.length}`);
		}
		if (input.birth_date !== undefined) {
			params.push(input.birth_date);
			setClauses.push(`birth_date = $${params.length}`);
		}
		if (input.tags !== undefined) {
			params.push(JSON.stringify(input.tags));
			setClauses.push(`tags = $${params.length}::jsonb`);
		}
		if (input.notes !== undefined) {
			params.push(input.notes);
			setClauses.push(`notes = $${params.length}`);
		}

		if (setClauses.length === 0) {
			return this.getById(studioId, clientId);
		}

		setClauses.push("updated_at = NOW()");

		const { rows } = await this.pool.query<ClientRow>(
			`UPDATE clients
       SET ${setClauses.join(", ")}
       WHERE id = $1 AND studio_id = $2
       RETURNING id, studio_id, name, phone, email, birth_date, tags, notes,
                 last_appointment_at, created_at, updated_at`,
			params,
		);

		return rows[0] ?? null;
	}

	async listAppointments(
		studioId: string,
		clientId: string,
		cursor?: string,
		limit = 20,
	): Promise<AppointmentHistoryRow[]> {
		try {
			const params: unknown[] = [studioId, clientId, limit + 1];
			let sql = `SELECT a.id, s.name AS service_name, p.name AS professional_name,
			                  (a.date || 'T' || a.start_time) AS scheduled_at, a.status
			           FROM appointments a
			           JOIN services s ON s.id = a.service_id
			           JOIN professionals p ON p.id = a.professional_id
			           WHERE a.studio_id = $1 AND a.client_id = $2`;
			if (cursor) {
				sql += " AND (a.date, a.start_time) < (SELECT date, start_time FROM appointments WHERE id = $4 AND studio_id = $1)";
				params.push(cursor);
			}
			sql += " ORDER BY a.date DESC, a.start_time DESC LIMIT $3";
			const { rows } = await this.pool.query<AppointmentHistoryRow>(sql, params);
			return rows;
		} catch (err: unknown) {
			// TODO(phase-3): Remove defensive catch once appointments schema is stable
			const pgErr = err as { code?: string };
			if (pgErr.code === "42P01" || pgErr.code === "42703") {
				return [];
			}
			throw err;
		}
	}

	async anonymize(studioId: string, clientId: string): Promise<ClientRow> {
		const { rows } = await this.pool.query<ClientRow>(
			`UPDATE clients
       SET name = 'Cliente removido',
           phone = NULL,
           email = NULL,
           tags = '[]'::jsonb,
           updated_at = NOW()
       WHERE id = $1 AND studio_id = $2
       RETURNING id, studio_id, name, phone, email, birth_date, tags, notes,
                 last_appointment_at, created_at, updated_at`,
			[clientId, studioId],
		);
		if (!rows[0]) {
			throw new NotFoundError("Client not found");
		}
		return rows[0];
	}
}
