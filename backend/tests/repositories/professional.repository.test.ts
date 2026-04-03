import { describe, it, expect, vi, beforeEach } from 'vitest';
import type { Pool } from 'pg';
import { ProfessionalRepository } from '../../src/repositories/professional.repository.js';

function mockPool() {
  return { query: vi.fn() } as unknown as Pool;
}

describe('ProfessionalRepository', () => {
  let repo: ProfessionalRepository;
  let pool: Pool;

  beforeEach(() => {
    pool = mockPool();
    repo = new ProfessionalRepository(pool);
  });

  describe('updateWorkingHours', () => {
    it('updates working_hours filtered by studio_id', async () => {
      const hours = { monday: [{ open: '09:00', close: '18:00' }] };
      const row = { id: 'prof-1', working_hours: hours };
      (pool.query as ReturnType<typeof vi.fn>).mockResolvedValue({ rows: [row] });

      const result = await repo.updateWorkingHours('prof-1', 'studio-1', hours);

      expect(result).toEqual(row);
      expect(pool.query).toHaveBeenCalledWith(
        expect.stringContaining('WHERE p.id = $1 AND p.studio_id = $2'),
        expect.arrayContaining(['prof-1', 'studio-1']),
      );
    });

    it('returns null when professional not in studio', async () => {
      (pool.query as ReturnType<typeof vi.fn>).mockResolvedValue({ rows: [] });

      const result = await repo.updateWorkingHours('prof-1', 'wrong-studio', {});

      expect(result).toBeNull();
    });
  });

  describe('findByUserId', () => {
    it('returns professional by user_id and studio_id', async () => {
      const row = { id: 'prof-1', user_id: 'user-1', studio_id: 'studio-1' };
      (pool.query as ReturnType<typeof vi.fn>).mockResolvedValue({ rows: [row] });

      const result = await repo.findByUserId('user-1', 'studio-1');

      expect(result).toEqual(row);
    });
  });
});
