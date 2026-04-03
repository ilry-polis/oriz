import { describe, it, expect, vi, beforeEach } from 'vitest';
import type { Pool } from 'pg';
import { ServiceCategoryRepository } from '../../src/repositories/service-category.repository.js';

function mockPool() {
  return { query: vi.fn() } as unknown as Pool;
}

describe('ServiceCategoryRepository', () => {
  let repo: ServiceCategoryRepository;
  let pool: Pool;

  beforeEach(() => {
    pool = mockPool();
    repo = new ServiceCategoryRepository(pool);
  });

  describe('listByStudio', () => {
    it('returns global + studio categories', async () => {
      const rows = [
        { id: 'cat-1', name: 'Unhas', studio_id: null },
        { id: 'cat-2', name: 'Custom', studio_id: 'studio-1' },
      ];
      (pool.query as ReturnType<typeof vi.fn>).mockResolvedValue({ rows });

      const result = await repo.listByStudio('studio-1');

      expect(result).toEqual(rows);
      expect(pool.query).toHaveBeenCalledWith(
        expect.stringContaining('studio_id IS NULL OR studio_id = $1'),
        ['studio-1'],
      );
    });
  });
});
