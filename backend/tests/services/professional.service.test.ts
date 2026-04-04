import { describe, it, expect, vi, beforeEach } from 'vitest';
import { ProfessionalService } from '../../src/services/professional.service.js';
import type { ProfessionalRepository } from '../../src/repositories/professional.repository.js';
import { NotFoundError } from '../../src/utils/errors.js';

// ─── Helpers ───────────────────────────────────────────────────────────────────

function makeRepo(overrides: Partial<ProfessionalRepository> = {}): ProfessionalRepository {
  return {
    findByUserId: vi.fn(),
    updateWorkingHours: vi.fn(),
    create: vi.fn(),
    list: vi.fn(),
    getById: vi.fn(),
    update: vi.fn(),
    replaceServiceLinks: vi.fn(),
    getServiceLinks: vi.fn(),
    ...overrides,
  } as unknown as ProfessionalRepository;
}

const fakeProfessional = {
  id: 'prof-1',
  studio_id: 'studio-1',
  user_id: 'user-1',
  name: 'Ana',
  commission_type: 'percentage' as const,
  commission_value: 10,
  card_fee_policy: 'studio' as const,
  working_hours: {},
  is_active: true,
  created_at: '2026-01-01T00:00:00Z',
  updated_at: '2026-01-01T00:00:00Z',
};

// ─── updateWorkingHours (existing) ─────────────────────────────────────────────

describe('ProfessionalService.updateWorkingHours', () => {
  let service: ProfessionalService;
  let repo: ProfessionalRepository;

  beforeEach(() => {
    repo = makeRepo();
    service = new ProfessionalService(repo);
  });

  it('updates when professional belongs to studio', async () => {
    (repo.updateWorkingHours as ReturnType<typeof vi.fn>).mockResolvedValue({ id: 'prof-1', working_hours: {} });
    const result = await service.updateWorkingHours('prof-1', 'studio-1', { monday: [] });
    expect(result.id).toBe('prof-1');
  });

  it('throws NotFoundError when not in studio', async () => {
    (repo.updateWorkingHours as ReturnType<typeof vi.fn>).mockResolvedValue(null);
    await expect(service.updateWorkingHours('prof-1', 'wrong', {})).rejects.toThrow(NotFoundError);
  });
});

// ─── listProfessionals ─────────────────────────────────────────────────────────

describe('ProfessionalService.listProfessionals', () => {
  let service: ProfessionalService;
  let repo: ProfessionalRepository;

  beforeEach(() => {
    repo = makeRepo();
    service = new ProfessionalService(repo);
  });

  it('returns data and meta with has_more false when fewer than limit', async () => {
    (repo.list as ReturnType<typeof vi.fn>).mockResolvedValueOnce([fakeProfessional]);

    const result = await service.listProfessionals('studio-1', undefined, 20);
    expect(result.data).toHaveLength(1);
    expect(result.meta.has_more).toBe(false);
  });

  it('returns has_more true when repo returns limit+1 rows', async () => {
    const rows = Array.from({ length: 21 }, (_, i) => ({ ...fakeProfessional, id: `prof-${i}` }));
    (repo.list as ReturnType<typeof vi.fn>).mockResolvedValueOnce(rows);

    const result = await service.listProfessionals('studio-1', undefined, 20);
    expect(result.data).toHaveLength(20);
    expect(result.meta.has_more).toBe(true);
    expect(result.meta.next_cursor).toBe('prof-19');
  });

  it('multi-tenancy: passes studioId to repo', async () => {
    (repo.list as ReturnType<typeof vi.fn>).mockResolvedValueOnce([]);

    await service.listProfessionals('studio-A');
    expect(repo.list).toHaveBeenCalledWith('studio-A', undefined, 21);
  });
});

// ─── getProfessionalById ───────────────────────────────────────────────────────

describe('ProfessionalService.getProfessionalById', () => {
  let service: ProfessionalService;
  let repo: ProfessionalRepository;

  beforeEach(() => {
    repo = makeRepo();
    service = new ProfessionalService(repo);
  });

  it('returns professional with service links', async () => {
    (repo.getById as ReturnType<typeof vi.fn>).mockResolvedValueOnce(fakeProfessional);
    (repo.getServiceLinks as ReturnType<typeof vi.fn>).mockResolvedValueOnce(['svc-1', 'svc-2']);

    const result = await service.getProfessionalById('studio-1', 'prof-1');
    expect(result.id).toBe('prof-1');
    expect(result.service_ids).toEqual(['svc-1', 'svc-2']);
  });

  it('throws NotFoundError when professional does not exist', async () => {
    (repo.getById as ReturnType<typeof vi.fn>).mockResolvedValueOnce(null);
    await expect(service.getProfessionalById('studio-1', 'prof-x')).rejects.toThrow(NotFoundError);
  });

  it('multi-tenancy: throws NotFoundError when professional belongs to other studio', async () => {
    (repo.getById as ReturnType<typeof vi.fn>).mockResolvedValueOnce(null); // repo filters by studio_id
    await expect(service.getProfessionalById('studio-B', 'prof-1')).rejects.toThrow(NotFoundError);
  });
});

// ─── updateProfessional ────────────────────────────────────────────────────────

describe('ProfessionalService.updateProfessional', () => {
  let service: ProfessionalService;
  let repo: ProfessionalRepository;

  beforeEach(() => {
    repo = makeRepo();
    service = new ProfessionalService(repo);
  });

  it('updates professional fields', async () => {
    (repo.update as ReturnType<typeof vi.fn>).mockResolvedValueOnce({ ...fakeProfessional, name: 'Ana Updated' });

    const result = await service.updateProfessional('studio-1', 'prof-1', { name: 'Ana Updated' });
    expect(result.name).toBe('Ana Updated');
  });

  it('also replaces service links when service_ids provided', async () => {
    (repo.update as ReturnType<typeof vi.fn>).mockResolvedValueOnce(fakeProfessional);
    (repo.replaceServiceLinks as ReturnType<typeof vi.fn>).mockResolvedValueOnce(undefined);

    await service.updateProfessional('studio-1', 'prof-1', { service_ids: ['svc-new'] });
    expect(repo.replaceServiceLinks).toHaveBeenCalledWith('prof-1', 'studio-1', ['svc-new']);
  });

  it('throws NotFoundError when professional does not exist in studio', async () => {
    (repo.update as ReturnType<typeof vi.fn>).mockResolvedValueOnce(null);
    await expect(service.updateProfessional('studio-1', 'bad-id', {})).rejects.toThrow(NotFoundError);
  });
});

// ─── toggleActive ──────────────────────────────────────────────────────────────

describe('ProfessionalService.toggleActive', () => {
  let service: ProfessionalService;
  let repo: ProfessionalRepository;

  beforeEach(() => {
    repo = makeRepo();
    service = new ProfessionalService(repo);
  });

  it('sets professional is_active to false', async () => {
    (repo.update as ReturnType<typeof vi.fn>).mockResolvedValueOnce({ ...fakeProfessional, is_active: false });

    const result = await service.toggleActive('studio-1', 'prof-1', false);
    expect(result.is_active).toBe(false);
  });

  it('sets professional is_active to true', async () => {
    (repo.update as ReturnType<typeof vi.fn>).mockResolvedValueOnce({ ...fakeProfessional, is_active: true });

    const result = await service.toggleActive('studio-1', 'prof-1', true);
    expect(result.is_active).toBe(true);
  });

  it('throws NotFoundError when professional not found', async () => {
    (repo.update as ReturnType<typeof vi.fn>).mockResolvedValueOnce(null);
    await expect(service.toggleActive('studio-1', 'bad', true)).rejects.toThrow(NotFoundError);
  });
});

// ─── replaceServiceLinks ───────────────────────────────────────────────────────

describe('ProfessionalService.replaceServiceLinks', () => {
  let service: ProfessionalService;
  let repo: ProfessionalRepository;

  beforeEach(() => {
    repo = makeRepo();
    service = new ProfessionalService(repo);
  });

  it('delegates to repo.replaceServiceLinks', async () => {
    (repo.getById as ReturnType<typeof vi.fn>).mockResolvedValueOnce(fakeProfessional);
    (repo.replaceServiceLinks as ReturnType<typeof vi.fn>).mockResolvedValueOnce(undefined);

    await service.replaceServiceLinks('studio-1', 'prof-1', ['svc-1', 'svc-2']);
    expect(repo.replaceServiceLinks).toHaveBeenCalledWith('prof-1', 'studio-1', ['svc-1', 'svc-2']);
  });

  it('throws NotFoundError when professional not found in studio', async () => {
    (repo.getById as ReturnType<typeof vi.fn>).mockResolvedValueOnce(null);
    await expect(service.replaceServiceLinks('studio-1', 'bad', [])).rejects.toThrow(NotFoundError);
  });
});
