import { describe, it, expect, vi, beforeEach } from 'vitest';
import type { Pool } from 'pg';
import { ServiceRepository } from '../../src/repositories/service.repository.js';

function mockPool() {
  return { query: vi.fn() } as unknown as Pool;
}

describe('ServiceRepository', () => {
  let repo: ServiceRepository;
  let pool: Pool;

  beforeEach(() => {
    pool = mockPool();
    repo = new ServiceRepository(pool);
  });

  describe('create', () => {
    it('inserts service with studio_id and returns it', async () => {
      const row = { id: 'svc-1', studio_id: 'studio-1', name: 'Manicure' };
      (pool.query as ReturnType<typeof vi.fn>).mockResolvedValue({ rows: [row] });

      const result = await repo.create({
        studioId: 'studio-1',
        categoryId: 'cat-1',
        name: 'Manicure',
        durationMinutes: 30,
        price: 5000,
        bufferMinutes: 0,
        isActive: true,
      });

      expect(result).toEqual(row);
      expect(pool.query).toHaveBeenCalledWith(
        expect.stringContaining('INSERT INTO services'),
        expect.arrayContaining(['studio-1', 'cat-1', 'Manicure', 30, 5000, 0, true]),
      );
    });
  });
});
