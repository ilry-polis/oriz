import type { Pool } from 'pg';

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
}
