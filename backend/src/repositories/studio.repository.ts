import type { Pool } from 'pg';

export type StudioRow = {
  id: string;
  owner_id: string;
  name: string;
  slug: string;
  phone: string | null;
  address: string | null;
  description: string | null;
  timezone: string;
  settings: Record<string, unknown>;
  created_at: string;
  updated_at: string;
};

export type CreateStudioInput = {
  name: string;
  slug: string;
  ownerId: string;
  ownerName: string;
  phone?: string;
  address?: string;
  description?: string;
  timezone: string;
};

export type CreateStudioResult = {
  studio: { id: string; name: string; slug: string; timezone: string };
  onboarding: { id: string; studio_id: string; current_step: string };
  professional: { id: string; studio_id: string; user_id: string };
};

export class StudioRepository {
  constructor(private pool: Pool) {}

  async findByOwnerId(ownerId: string): Promise<StudioRow | null> {
    const { rows } = await this.pool.query<StudioRow>(
      `SELECT s.id, s.owner_id, s.name, s.slug, s.phone, s.address,
              s.description, s.timezone, s.settings, s.created_at, s.updated_at
       FROM studios s
       WHERE s.owner_id = $1
       LIMIT 1`,
      [ownerId],
    );
    return rows[0] ?? null;
  }

  async findBySlug(slug: string): Promise<{ id: string; slug: string } | null> {
    const { rows } = await this.pool.query<{ id: string; slug: string }>(
      `SELECT s.id, s.slug FROM studios s WHERE s.slug = $1 LIMIT 1`,
      [slug],
    );
    return rows[0] ?? null;
  }

  async findById(studioId: string): Promise<StudioRow | null> {
    const { rows } = await this.pool.query<StudioRow>(
      `SELECT s.id, s.owner_id, s.name, s.slug, s.phone, s.address,
              s.description, s.timezone, s.settings, s.created_at, s.updated_at
       FROM studios s
       WHERE s.id = $1
       LIMIT 1`,
      [studioId],
    );
    return rows[0] ?? null;
  }

  async createWithOnboarding(input: CreateStudioInput): Promise<CreateStudioResult> {
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');

      const { rows: studioRows } = await client.query<{ id: string; name: string; slug: string; timezone: string }>(
        `INSERT INTO studios (id, owner_id, name, slug, phone, address, description, timezone)
         VALUES (gen_random_uuid(), $1, $2, $3, $4, $5, $6, $7)
         RETURNING id, name, slug, timezone`,
        [input.ownerId, input.name, input.slug, input.phone ?? null, input.address ?? null, input.description ?? null, input.timezone],
      );
      const studio = studioRows[0]!;

      const { rows: onboardingRows } = await client.query<{ id: string; studio_id: string; current_step: string }>(
        `INSERT INTO onboarding_states (id, studio_id, current_step)
         VALUES (gen_random_uuid(), $1, 'studio_data')
         RETURNING id, studio_id, current_step`,
        [studio.id],
      );
      const onboarding = onboardingRows[0]!;

      const { rows: professionalRows } = await client.query<{ id: string; studio_id: string; user_id: string }>(
        `INSERT INTO professionals (id, studio_id, user_id, name, commission_type, commission_value)
         VALUES (gen_random_uuid(), $1, $2, $3, 'percentage', 0)
         RETURNING id, studio_id, user_id`,
        [studio.id, input.ownerId, input.ownerName],
      );
      const professional = professionalRows[0]!;

      await client.query('COMMIT');

      return { studio, onboarding, professional };
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  }
}
