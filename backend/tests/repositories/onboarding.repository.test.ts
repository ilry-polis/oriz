import { describe, it, expect, vi, beforeEach } from 'vitest';
import type { Pool } from 'pg';
import { OnboardingRepository } from '../../src/repositories/onboarding.repository.js';

function mockPool() {
  return { query: vi.fn() } as unknown as Pool;
}

describe('OnboardingRepository', () => {
  let repo: OnboardingRepository;
  let pool: Pool;

  beforeEach(() => {
    pool = mockPool();
    repo = new OnboardingRepository(pool);
  });

  describe('findByStudioId', () => {
    it('returns onboarding state', async () => {
      const row = { id: 'onb-1', studio_id: 'studio-1', current_step: 'studio_data', completed_at: null };
      (pool.query as ReturnType<typeof vi.fn>).mockResolvedValue({ rows: [row] });

      const result = await repo.findByStudioId('studio-1');

      expect(result).toEqual(row);
      expect(pool.query).toHaveBeenCalledWith(
        expect.stringContaining('WHERE o.studio_id = $1'),
        ['studio-1'],
      );
    });

    it('returns null when not found', async () => {
      (pool.query as ReturnType<typeof vi.fn>).mockResolvedValue({ rows: [] });
      const result = await repo.findByStudioId('nobody');
      expect(result).toBeNull();
    });
  });

  describe('updateStep', () => {
    it('updates step without completed_at for non-complete steps', async () => {
      const row = { id: 'onb-1', current_step: 'services', completed_at: null };
      (pool.query as ReturnType<typeof vi.fn>).mockResolvedValue({ rows: [row] });

      const result = await repo.updateStep('studio-1', 'services');

      expect(result).toEqual(row);
      expect(pool.query).toHaveBeenCalledWith(
        expect.stringContaining('current_step = $1'),
        expect.arrayContaining(['services', 'studio-1']),
      );
    });

    it('sets completed_at when step is complete', async () => {
      const row = { id: 'onb-1', current_step: 'complete', completed_at: '2026-03-22T00:00:00Z' };
      (pool.query as ReturnType<typeof vi.fn>).mockResolvedValue({ rows: [row] });

      const result = await repo.updateStep('studio-1', 'complete');

      expect(result).toEqual(row);
      expect(pool.query).toHaveBeenCalledWith(
        expect.stringContaining('completed_at'),
        expect.arrayContaining(['complete', 'studio-1']),
      );
    });
  });
});
