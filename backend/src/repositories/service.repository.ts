import type { Pool } from 'pg';

export type ServiceRow = {
  id: string;
  studio_id: string;
  category_id: string;
  name: string;
  duration_minutes: number;
  price: number;
  buffer_minutes: number;
  is_active: boolean;
  created_at: string;
  updated_at: string;
};

export type CreateServiceInput = {
  studioId: string;
  categoryId: string;
  name: string;
  durationMinutes: number;
  price: number;
  bufferMinutes: number;
  isActive: boolean;
};

export class ServiceRepository {
  constructor(private pool: Pool) {}

  async list(
    studioId: string,
    opts: { categoryId?: string; isActive?: boolean; cursor?: string; limit: number },
  ): Promise<{ data: ServiceRow[]; hasMore: boolean }> {
    const params: unknown[] = [studioId, opts.limit + 1];
    const conditions = ['studio_id = $1'];
    let paramIndex = 3;

    if (opts.categoryId) {
      conditions.push(`category_id = $${paramIndex}`);
      params.push(opts.categoryId);
      paramIndex++;
    }
    if (opts.isActive !== undefined) {
      conditions.push(`is_active = $${paramIndex}`);
      params.push(opts.isActive);
      paramIndex++;
    }
    if (opts.cursor) {
      conditions.push(`id < $${paramIndex}`);
      params.push(opts.cursor);
      paramIndex++;
    }

    const where = conditions.join(' AND ');
    const { rows } = await this.pool.query<ServiceRow>(
      `SELECT id, studio_id, category_id, name, duration_minutes, price, buffer_minutes, is_active, created_at, updated_at
       FROM services
       WHERE ${where}
       ORDER BY name ASC, id DESC
       LIMIT $2`,
      params,
    );

    const hasMore = rows.length > opts.limit;
    if (hasMore) rows.pop();

    return { data: rows, hasMore };
  }

  async getById(studioId: string, serviceId: string): Promise<ServiceRow | null> {
    const { rows } = await this.pool.query<ServiceRow>(
      `SELECT id, studio_id, category_id, name, duration_minutes, price, buffer_minutes, is_active, created_at, updated_at
       FROM services
       WHERE studio_id = $1 AND id = $2
       LIMIT 1`,
      [studioId, serviceId],
    );
    return rows[0] ?? null;
  }

  async create(input: CreateServiceInput): Promise<ServiceRow> {
    const { rows } = await this.pool.query<ServiceRow>(
      `INSERT INTO services (id, studio_id, category_id, name, duration_minutes, price, buffer_minutes, is_active)
       VALUES (gen_random_uuid(), $1, $2, $3, $4, $5, $6, $7)
       RETURNING id, studio_id, category_id, name, duration_minutes, price, buffer_minutes, is_active, created_at, updated_at`,
      [input.studioId, input.categoryId, input.name, input.durationMinutes, input.price, input.bufferMinutes, input.isActive],
    );
    return rows[0]!;
  }
}
