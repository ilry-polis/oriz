import type { Pool } from 'pg';

export type OnboardingRow = {
  id: string;
  studio_id: string;
  current_step: string;
  completed_at: string | null;
  created_at: string;
  updated_at: string;
};

export class OnboardingRepository {
  constructor(private pool: Pool) {}

  async findByStudioId(studioId: string): Promise<OnboardingRow | null> {
    const { rows } = await this.pool.query<OnboardingRow>(
      `SELECT o.id, o.studio_id, o.current_step, o.completed_at, o.created_at, o.updated_at
       FROM onboarding_states o
       WHERE o.studio_id = $1
       LIMIT 1`,
      [studioId],
    );
    return rows[0] ?? null;
  }

  async updateStep(studioId: string, step: string): Promise<OnboardingRow | null> {
    const { rows } = await this.pool.query<OnboardingRow>(
      `UPDATE onboarding_states
       SET current_step = $1,
           completed_at = CASE WHEN $1 = 'complete' THEN now() ELSE completed_at END,
           updated_at = now()
       WHERE studio_id = $2
       RETURNING id, studio_id, current_step, completed_at, created_at, updated_at`,
      [step, studioId],
    );
    return rows[0] ?? null;
  }
}
