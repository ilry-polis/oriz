import { describe, it, expect, vi, beforeEach } from 'vitest';
import type { Pool, PoolClient } from 'pg';
import { StudioRepository } from '../../src/repositories/studio.repository.js';

function mockPool() {
  const client = {
    query: vi.fn(),
    release: vi.fn(),
  } as unknown as PoolClient;
  const pool = {
    query: vi.fn(),
    connect: vi.fn().mockResolvedValue(client),
  } as unknown as Pool;
  return { pool, client };
}

describe('StudioRepository', () => {
  let repo: StudioRepository;
  let pool: Pool;
  let client: PoolClient;

  beforeEach(() => {
    const mocked = mockPool();
    pool = mocked.pool;
    client = mocked.client;
    repo = new StudioRepository(pool);
  });

  describe('findByOwnerId', () => {
    it('returns studio when found', async () => {
      const row = { id: 'studio-1', name: 'Test', slug: 'test', owner_id: 'user-1' };
      (pool.query as ReturnType<typeof vi.fn>).mockResolvedValue({ rows: [row] });

      const result = await repo.findByOwnerId('user-1');

      expect(result).toEqual(row);
      expect(pool.query).toHaveBeenCalledWith(
        expect.stringContaining('WHERE s.owner_id = $1'),
        ['user-1'],
      );
    });

    it('returns null when not found', async () => {
      (pool.query as ReturnType<typeof vi.fn>).mockResolvedValue({ rows: [] });

      const result = await repo.findByOwnerId('nobody');

      expect(result).toBeNull();
    });
  });

  describe('findBySlug', () => {
    it('returns studio when slug exists', async () => {
      const row = { id: 'studio-1', slug: 'taken' };
      (pool.query as ReturnType<typeof vi.fn>).mockResolvedValue({ rows: [row] });

      const result = await repo.findBySlug('taken');

      expect(result).toEqual(row);
    });
  });

  describe('createWithOnboarding', () => {
    it('creates studio, onboarding_state, and professional in transaction', async () => {
      (client.query as ReturnType<typeof vi.fn>)
        .mockResolvedValueOnce(undefined) // BEGIN
        .mockResolvedValueOnce({ rows: [{ id: 'studio-1' }] }) // INSERT studio
        .mockResolvedValueOnce({ rows: [{ id: 'onb-1' }] }) // INSERT onboarding_state
        .mockResolvedValueOnce({ rows: [{ id: 'prof-1' }] }) // INSERT professional
        .mockResolvedValueOnce(undefined); // COMMIT

      const result = await repo.createWithOnboarding({
        name: 'My Studio',
        slug: 'my-studio',
        ownerId: 'user-1',
        ownerName: 'Ana Silva',
        timezone: 'America/Sao_Paulo',
      });

      expect(result.studio.id).toBe('studio-1');
      expect(result.onboarding.id).toBe('onb-1');
      expect(result.professional.id).toBe('prof-1');
      expect(client.query).toHaveBeenCalledWith('BEGIN');
      expect(client.query).toHaveBeenCalledWith('COMMIT');
      expect(client.release).toHaveBeenCalled();
    });

    it('rolls back on failure', async () => {
      (client.query as ReturnType<typeof vi.fn>)
        .mockResolvedValueOnce(undefined) // BEGIN
        .mockRejectedValueOnce(new Error('DB error')); // INSERT fails

      await expect(
        repo.createWithOnboarding({
          name: 'Fail',
          slug: 'fail',
          ownerId: 'user-1',
          ownerName: 'Ana',
          timezone: 'America/Sao_Paulo',
        }),
      ).rejects.toThrow('DB error');

      expect(client.query).toHaveBeenCalledWith('ROLLBACK');
      expect(client.release).toHaveBeenCalled();
    });
  });

  describe('findById', () => {
    it('returns studio by id with studio_id filter', async () => {
      const row = { id: 'studio-1', name: 'Test' };
      (pool.query as ReturnType<typeof vi.fn>).mockResolvedValue({ rows: [row] });

      const result = await repo.findById('studio-1');

      expect(result).toEqual(row);
      expect(pool.query).toHaveBeenCalledWith(
        expect.stringContaining('WHERE s.id = $1'),
        ['studio-1'],
      );
    });
  });
});
