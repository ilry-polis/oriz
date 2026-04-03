import { describe, it, expect, vi, beforeEach } from 'vitest';
import type { Pool } from 'pg';
import { ServiceRepository } from '../../src/repositories/service.repository.js';

function mockPool() {
  return { query: vi.fn() } as unknown as Pool;
}

const studioA = '11111111-1111-1111-1111-111111111111';
const studioB = '22222222-2222-2222-2222-222222222222';
const svcId = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
const catId = 'cccccccc-cccc-cccc-cccc-cccccccccccc';

describe('ServiceRepository', () => {
  let repo: ServiceRepository;
  let pool: Pool;

  beforeEach(() => {
    pool = mockPool();
    repo = new ServiceRepository(pool);
  });

  // ─── create ──────────────────────────────────────────────────

  describe('create', () => {
    it('inserts service with studio_id and returns it', async () => {
      const row = { id: svcId, studio_id: studioA, name: 'Manicure' };
      (pool.query as ReturnType<typeof vi.fn>).mockResolvedValue({ rows: [row] });

      const result = await repo.create({
        studioId: studioA,
        categoryId: catId,
        name: 'Manicure',
        durationMinutes: 30,
        price: 5000,
        bufferMinutes: 0,
        isActive: true,
      });

      expect(result).toEqual(row);
      expect(pool.query).toHaveBeenCalledWith(
        expect.stringContaining('INSERT INTO services'),
        expect.arrayContaining([studioA, catId, 'Manicure', 30, 5000, 0, true]),
      );
    });
  });

  // ─── list ────────────────────────────────────────────────────

  describe('list', () => {
    it('returns services for the given studio only', async () => {
      const rows = [
        { id: svcId, studio_id: studioA, name: 'Manicure', category_name: 'Unhas' },
      ];
      (pool.query as ReturnType<typeof vi.fn>).mockResolvedValue({ rows });

      const result = await repo.list(studioA);

      expect(result.services).toEqual(rows);
      expect(pool.query).toHaveBeenCalledWith(
        expect.stringContaining('studio_id'),
        expect.arrayContaining([studioA]),
      );
    });

    it('returns empty array when studio has no services', async () => {
      (pool.query as ReturnType<typeof vi.fn>).mockResolvedValue({ rows: [] });

      const result = await repo.list(studioA);

      expect(result.services).toEqual([]);
      expect(result.hasMore).toBe(false);
    });

    it('returns has_more=true when there are more results', async () => {
      // Returns limit+1 rows; repository slices to limit and sets hasMore=true
      const rows = Array.from({ length: 21 }, (_, i) => ({
        id: `id-${i}`,
        studio_id: studioA,
        name: `Service ${i}`,
        category_name: 'Unhas',
      }));
      (pool.query as ReturnType<typeof vi.fn>).mockResolvedValue({ rows });

      const result = await repo.list(studioA, undefined, 20);

      expect(result.services).toHaveLength(20);
      expect(result.hasMore).toBe(true);
      expect(result.nextCursor).toBe('id-19');
    });

    it('multi-tenant isolation: query includes studio_id filter', async () => {
      (pool.query as ReturnType<typeof vi.fn>).mockResolvedValue({ rows: [] });

      await repo.list(studioB);

      const [sql, params] = (pool.query as ReturnType<typeof vi.fn>).mock.calls[0]!;
      expect(sql).toContain('studio_id');
      expect(params).toContain(studioB);
    });

    it('accepts cursor for pagination', async () => {
      (pool.query as ReturnType<typeof vi.fn>).mockResolvedValue({ rows: [] });

      await repo.list(studioA, svcId, 10);

      const [sql, params] = (pool.query as ReturnType<typeof vi.fn>).mock.calls[0]!;
      // cursor value (the ID) must appear in params
      expect(params).toContain(svcId);
      // SQL must have a comparison operator to paginate past the cursor
      expect(sql).toMatch(/s\.id\s*>/);
    });
  });

  // ─── getById ─────────────────────────────────────────────────

  describe('getById', () => {
    it('returns service when it exists and belongs to the studio', async () => {
      const row = { id: svcId, studio_id: studioA, name: 'Manicure' };
      (pool.query as ReturnType<typeof vi.fn>).mockResolvedValue({ rows: [row] });

      const result = await repo.getById(studioA, svcId);

      expect(result).toEqual(row);
    });

    it('returns null when service does not exist', async () => {
      (pool.query as ReturnType<typeof vi.fn>).mockResolvedValue({ rows: [] });

      const result = await repo.getById(studioA, svcId);

      expect(result).toBeNull();
    });

    it('multi-tenant: returns null when service belongs to another studio', async () => {
      // Query filters by studio_id; different studio returns empty
      (pool.query as ReturnType<typeof vi.fn>).mockResolvedValue({ rows: [] });

      const result = await repo.getById(studioB, svcId);

      expect(result).toBeNull();
      const [sql, params] = (pool.query as ReturnType<typeof vi.fn>).mock.calls[0]!;
      expect(params).toContain(studioB);
      expect(params).toContain(svcId);
    });

    it('filters by deleted_at IS NULL', async () => {
      (pool.query as ReturnType<typeof vi.fn>).mockResolvedValue({ rows: [] });

      await repo.getById(studioA, svcId);

      const [sql] = (pool.query as ReturnType<typeof vi.fn>).mock.calls[0]!;
      expect(sql).toContain('deleted_at IS NULL');
    });
  });

  // ─── update ──────────────────────────────────────────────────

  describe('update', () => {
    it('updates service fields and returns updated row', async () => {
      const updated = { id: svcId, studio_id: studioA, name: 'Pedicure', price: 6000 };
      (pool.query as ReturnType<typeof vi.fn>).mockResolvedValue({ rows: [updated] });

      const result = await repo.update(studioA, svcId, { name: 'Pedicure', price: 6000 });

      expect(result).toEqual(updated);
      expect(pool.query).toHaveBeenCalledWith(
        expect.stringContaining('UPDATE services'),
        expect.arrayContaining([studioA, svcId]),
      );
    });

    it('includes studio_id in WHERE clause (multi-tenant)', async () => {
      const updated = { id: svcId, studio_id: studioA, name: 'Pedicure' };
      (pool.query as ReturnType<typeof vi.fn>).mockResolvedValue({ rows: [updated] });

      await repo.update(studioA, svcId, { name: 'Pedicure' });

      const [sql, params] = (pool.query as ReturnType<typeof vi.fn>).mock.calls[0]!;
      expect(sql).toContain('studio_id');
      expect(params).toContain(studioA);
    });
  });

  // ─── setActive ───────────────────────────────────────────────

  describe('setActive', () => {
    it('sets is_active=true and returns updated row', async () => {
      const updated = { id: svcId, studio_id: studioA, is_active: true };
      (pool.query as ReturnType<typeof vi.fn>).mockResolvedValue({ rows: [updated] });

      const result = await repo.setActive(studioA, svcId, true);

      expect(result).toEqual(updated);
      expect(pool.query).toHaveBeenCalledWith(
        expect.stringContaining('is_active'),
        expect.arrayContaining([true, studioA, svcId]),
      );
    });

    it('sets is_active=false (deactivate)', async () => {
      const updated = { id: svcId, studio_id: studioA, is_active: false };
      (pool.query as ReturnType<typeof vi.fn>).mockResolvedValue({ rows: [updated] });

      const result = await repo.setActive(studioA, svcId, false);

      expect(result.is_active).toBe(false);
    });
  });

  // ─── softDelete ──────────────────────────────────────────────

  describe('softDelete', () => {
    it('sets deleted_at to now and returns void', async () => {
      (pool.query as ReturnType<typeof vi.fn>).mockResolvedValue({ rows: [] });

      const result = await repo.softDelete(studioA, svcId);

      expect(result).toBeUndefined();
      expect(pool.query).toHaveBeenCalledWith(
        expect.stringContaining('deleted_at'),
        expect.arrayContaining([studioA, svcId]),
      );
    });

    it('includes studio_id in WHERE clause (multi-tenant)', async () => {
      (pool.query as ReturnType<typeof vi.fn>).mockResolvedValue({ rows: [] });

      await repo.softDelete(studioA, svcId);

      const [sql, params] = (pool.query as ReturnType<typeof vi.fn>).mock.calls[0]!;
      expect(sql).toContain('studio_id');
      expect(params).toContain(studioA);
    });
  });
});
