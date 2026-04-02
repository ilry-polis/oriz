import { describe, it, expect, vi, beforeEach } from 'vitest';
import { ServiceService } from '../../src/services/service.service.js';
import type { ServiceRepository } from '../../src/repositories/service.repository.js';
import { NotFoundError } from '../../src/utils/errors.js';

const studioA = '11111111-1111-1111-1111-111111111111';
const studioB = '22222222-2222-2222-2222-222222222222';
const svcId = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
const catId = 'cccccccc-cccc-cccc-cccc-cccccccccccc';

const makeRepo = () => ({
  create: vi.fn(),
  list: vi.fn(),
  getById: vi.fn(),
  update: vi.fn(),
  setActive: vi.fn(),
  softDelete: vi.fn(),
} as unknown as ServiceRepository);

describe('ServiceService', () => {
  let service: ServiceService;
  let repo: ServiceRepository;

  beforeEach(() => {
    repo = makeRepo();
    service = new ServiceService(repo);
  });

  // ─── createService ───────────────────────────────────────────

  describe('createService', () => {
    it('calls repo with studio_id', async () => {
      (repo.create as ReturnType<typeof vi.fn>).mockResolvedValue({ id: svcId, name: 'Manicure' });

      const result = await service.createService(studioA, {
        categoryId: catId, name: 'Manicure', durationMinutes: 30, price: 5000, bufferMinutes: 0, isActive: true,
      });

      expect(result.id).toBe(svcId);
      expect(repo.create).toHaveBeenCalledWith(expect.objectContaining({ studioId: studioA }));
    });
  });

  // ─── listServices ────────────────────────────────────────────

  describe('listServices', () => {
    it('returns paginated list with meta', async () => {
      const services = [{ id: svcId, studio_id: studioA, name: 'Manicure' }];
      (repo.list as ReturnType<typeof vi.fn>).mockResolvedValue({
        services,
        hasMore: false,
        nextCursor: null,
      });

      const result = await service.listServices(studioA);

      expect(result.data).toEqual(services);
      expect(result.meta.has_more).toBe(false);
      expect(result.meta.next_cursor).toBeNull();
    });

    it('passes cursor and limit to repository', async () => {
      (repo.list as ReturnType<typeof vi.fn>).mockResolvedValue({
        services: [],
        hasMore: false,
        nextCursor: null,
      });

      await service.listServices(studioA, svcId, 10);

      expect(repo.list).toHaveBeenCalledWith(studioA, svcId, 10);
    });

    it('returns next_cursor when hasMore=true', async () => {
      const nextCursor = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
      (repo.list as ReturnType<typeof vi.fn>).mockResolvedValue({
        services: [{ id: svcId }],
        hasMore: true,
        nextCursor,
      });

      const result = await service.listServices(studioA);

      expect(result.meta.has_more).toBe(true);
      expect(result.meta.next_cursor).toBe(nextCursor);
    });
  });

  // ─── getServiceById ──────────────────────────────────────────

  describe('getServiceById', () => {
    it('returns the service when found', async () => {
      const svc = { id: svcId, studio_id: studioA, name: 'Manicure' };
      (repo.getById as ReturnType<typeof vi.fn>).mockResolvedValue(svc);

      const result = await service.getServiceById(studioA, svcId);

      expect(result).toEqual(svc);
    });

    it('throws NotFoundError when service does not exist', async () => {
      (repo.getById as ReturnType<typeof vi.fn>).mockResolvedValue(null);

      await expect(service.getServiceById(studioA, svcId)).rejects.toThrow(NotFoundError);
    });

    it('throws NotFoundError when service belongs to another studio', async () => {
      // repo already filters by studio_id; returns null for cross-tenant access
      (repo.getById as ReturnType<typeof vi.fn>).mockResolvedValue(null);

      await expect(service.getServiceById(studioB, svcId)).rejects.toThrow(NotFoundError);
    });
  });

  // ─── updateService ───────────────────────────────────────────

  describe('updateService', () => {
    it('validates service exists, then updates', async () => {
      const existing = { id: svcId, studio_id: studioA, name: 'Manicure' };
      const updated = { ...existing, name: 'Pedicure' };
      (repo.getById as ReturnType<typeof vi.fn>).mockResolvedValue(existing);
      (repo.update as ReturnType<typeof vi.fn>).mockResolvedValue(updated);

      const result = await service.updateService(studioA, svcId, { name: 'Pedicure' });

      expect(result).toEqual(updated);
      expect(repo.getById).toHaveBeenCalledWith(studioA, svcId);
      expect(repo.update).toHaveBeenCalledWith(studioA, svcId, { name: 'Pedicure' });
    });

    it('throws NotFoundError when service does not exist', async () => {
      (repo.getById as ReturnType<typeof vi.fn>).mockResolvedValue(null);

      await expect(service.updateService(studioA, svcId, { name: 'X' })).rejects.toThrow(NotFoundError);
    });
  });

  // ─── setActive ───────────────────────────────────────────────

  describe('setActive', () => {
    it('validates service exists, then toggles is_active', async () => {
      const existing = { id: svcId, studio_id: studioA, is_active: false };
      const updated = { ...existing, is_active: true };
      (repo.getById as ReturnType<typeof vi.fn>).mockResolvedValue(existing);
      (repo.setActive as ReturnType<typeof vi.fn>).mockResolvedValue(updated);

      const result = await service.setActive(studioA, svcId, true);

      expect(result.is_active).toBe(true);
    });

    it('throws NotFoundError when service does not exist', async () => {
      (repo.getById as ReturnType<typeof vi.fn>).mockResolvedValue(null);

      await expect(service.setActive(studioA, svcId, true)).rejects.toThrow(NotFoundError);
    });
  });

  // ─── deleteService ───────────────────────────────────────────

  describe('deleteService', () => {
    it('validates service exists, then soft-deletes', async () => {
      const existing = { id: svcId, studio_id: studioA };
      (repo.getById as ReturnType<typeof vi.fn>).mockResolvedValue(existing);
      (repo.softDelete as ReturnType<typeof vi.fn>).mockResolvedValue(undefined);

      await service.deleteService(studioA, svcId);

      expect(repo.softDelete).toHaveBeenCalledWith(studioA, svcId);
    });

    it('throws NotFoundError when service does not exist', async () => {
      (repo.getById as ReturnType<typeof vi.fn>).mockResolvedValue(null);

      await expect(service.deleteService(studioA, svcId)).rejects.toThrow(NotFoundError);
    });
  });
});
