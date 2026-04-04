import type { Pool } from 'pg';
import { ConflictError } from '../utils/errors.js';

export type ClientRow = {
  id: string;
  studio_id: string;
  name: string;
  phone: string | null;
  email: string | null;
  birth_date: string | null;
  tags: string[] | null;
  notes: string | null;
  last_appointment_at: string | null;
  created_at: string;
  updated_at: string;
};

export type CreateClientInput = {
  studioId: string;
  name: string;
  phone?: string;
  email?: string;
  birthDate?: string;
  tags?: string[];
  notes?: string;
};

const CLIENT_COLUMNS = 'id, studio_id, name, phone, email, birth_date, tags, notes, last_appointment_at, created_at, updated_at';

export class ClientRepository {
  constructor(private pool: Pool) {}

  async list(
    studioId: string,
    opts: { search?: string; cursor?: string; limit: number },
  ): Promise<{ data: ClientRow[]; hasMore: boolean }> {
    const params: unknown[] = [studioId, opts.limit + 1];
    const conditions = ['studio_id = $1'];
    let paramIndex = 3;

    if (opts.search) {
      conditions.push(`(name ILIKE $${paramIndex} OR phone ILIKE $${paramIndex})`);
      params.push(`%${opts.search}%`);
      paramIndex++;
    }

    if (opts.cursor) {
      conditions.push(`id < $${paramIndex}`);
      params.push(opts.cursor);
      paramIndex++;
    }

    const where = conditions.join(' AND ');
    const { rows } = await this.pool.query<ClientRow>(
      `SELECT ${CLIENT_COLUMNS}
       FROM clients
       WHERE ${where}
       ORDER BY name ASC, id DESC
       LIMIT $2`,
      params,
    );

    const hasMore = rows.length > opts.limit;
    if (hasMore) rows.pop();

    return { data: rows, hasMore };
  }

  async create(input: CreateClientInput): Promise<ClientRow> {
    if (input.phone) {
      const { rows: existing } = await this.pool.query(
        'SELECT id FROM clients WHERE studio_id = $1 AND phone = $2 LIMIT 1',
        [input.studioId, input.phone],
      );
      if (existing.length > 0) {
        throw new ConflictError('PHONE_ALREADY_EXISTS', 'Client with this phone already exists', 'phone');
      }
    }

    const { rows } = await this.pool.query<ClientRow>(
      `INSERT INTO clients (id, studio_id, name, phone, email, birth_date, tags, notes)
       VALUES (gen_random_uuid(), $1, $2, $3, $4, $5, $6, $7)
       RETURNING ${CLIENT_COLUMNS}`,
      [
        input.studioId,
        input.name,
        input.phone ?? null,
        input.email ?? null,
        input.birthDate ?? null,
        input.tags ? JSON.stringify(input.tags) : null,
        input.notes ?? null,
      ],
    );
    return rows[0]!;
  }
}
