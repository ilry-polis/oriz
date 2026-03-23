import type { Pool } from 'pg';

export type ProfessionalRow = {
  id: string;
  studio_id: string;
  user_id: string;
  name: string;
  working_hours: Record<string, unknown>;
  is_active: boolean;
  created_at: string;
  updated_at: string;
};

export class ProfessionalRepository {
  constructor(private pool: Pool) {}

  async findByUserId(userId: string, studioId: string): Promise<ProfessionalRow | null> {
    const { rows } = await this.pool.query<ProfessionalRow>(
      `SELECT p.id, p.studio_id, p.user_id, p.name, p.working_hours, p.is_active, p.created_at, p.updated_at
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
       RETURNING p.id, p.studio_id, p.user_id, p.name, p.working_hours, p.is_active, p.created_at, p.updated_at`,
      [professionalId, studioId, JSON.stringify(workingHours)],
    );
    return rows[0] ?? null;
  }
}
