import { describe, it, expect, vi, beforeEach } from 'vitest';
import { BlockedSlotService } from '../../src/services/blocked-slot.service.js';
import type { BlockedSlotRepository } from '../../src/repositories/blocked-slot.repository.js';
import type { BlockedSlotRow } from '../../src/repositories/blocked-slot.repository.js';
import { NotFoundError } from '../../src/utils/errors.js';

// ─── Factories ────────────────────────────────────────────────────────────────

function makeBlockedSlot(overrides: Partial<BlockedSlotRow> = {}): BlockedSlotRow {
  return {
    id: 'bs-1',
    studio_id: 'studio-A',
    professional_id: 'prof-1',
    date: '2026-04-07',
    start_time: '14:00',
    end_time: '15:00',
    title: 'Almoço',
    reason: null,
    recurrence_rule: null,
    excluded_dates: [],
    created_at: '2026-04-03T10:00:00Z',
    ...overrides,
  };
}

// ─── Tests ────────────────────────────────────────────────────────────────────

describe('BlockedSlotService', () => {
  let service: BlockedSlotService;
  let repo: BlockedSlotRepository;

  beforeEach(() => {
    repo = {
      listByDateRange: vi.fn(),
      create: vi.fn(),
      delete: vi.fn(),
      addExcludedDate: vi.fn(),
    } as unknown as BlockedSlotRepository;
    service = new BlockedSlotService(repo);
  });

  // ─── getExpandedForDate ──────────────────────────────────────────────────

  describe('getExpandedForDate', () => {
    it('returns sporadic absence when date matches', async () => {
      const slot = makeBlockedSlot({ date: '2026-04-05', recurrence_rule: null });
      (repo.listByDateRange as ReturnType<typeof vi.fn>).mockResolvedValue([slot]);

      const result = await service.getExpandedForDate('studio-A', 'prof-1', '2026-04-05');

      expect(result).toHaveLength(1);
      expect(result[0]).toMatchObject({ start_time: '14:00', end_time: '15:00' });
    });

    it('does NOT return sporadic absence when date does not match', async () => {
      const slot = makeBlockedSlot({ date: '2026-04-05', recurrence_rule: null });
      (repo.listByDateRange as ReturnType<typeof vi.fn>).mockResolvedValue([slot]);

      // date-range will not contain the slot because repo returns only date-matched sporadic slots
      // but simulate repo returning it anyway to test service-level filter robustness:
      const result = await service.getExpandedForDate('studio-A', 'prof-1', '2026-04-06');

      // Service should exclude: the slot date (2026-04-05) doesn't match query date (2026-04-06)
      expect(result).toHaveLength(0);
    });

    it('returns recurring absence when day-of-week matches (Monday=1)', async () => {
      const slot = makeBlockedSlot({
        date: '2026-04-01', // reference date (ignored for recurrence matching)
        recurrence_rule: { frequency: 'weekly', days: [1, 3], until: null },
        excluded_dates: [],
      });
      (repo.listByDateRange as ReturnType<typeof vi.fn>).mockResolvedValue([slot]);

      // 2026-04-06 is a Monday (day 1)
      const result = await service.getExpandedForDate('studio-A', 'prof-1', '2026-04-06');

      expect(result).toHaveLength(1);
    });

    it('does NOT return recurring absence when day-of-week does not match', async () => {
      const slot = makeBlockedSlot({
        recurrence_rule: { frequency: 'weekly', days: [1, 3], until: null },
        excluded_dates: [],
      });
      (repo.listByDateRange as ReturnType<typeof vi.fn>).mockResolvedValue([slot]);

      // 2026-04-07 is a Tuesday (day 2) — not in [1, 3]
      const result = await service.getExpandedForDate('studio-A', 'prof-1', '2026-04-07');

      expect(result).toHaveLength(0);
    });

    it('does NOT return recurring absence when until date has passed', async () => {
      const slot = makeBlockedSlot({
        recurrence_rule: { frequency: 'weekly', days: [1], until: '2026-04-10' },
        excluded_dates: [],
      });
      (repo.listByDateRange as ReturnType<typeof vi.fn>).mockResolvedValue([slot]);

      // 2026-04-13 is a Monday (day 1), but after until date
      const result = await service.getExpandedForDate('studio-A', 'prof-1', '2026-04-13');

      expect(result).toHaveLength(0);
    });

    it('returns recurring absence when until date has NOT passed', async () => {
      const slot = makeBlockedSlot({
        recurrence_rule: { frequency: 'weekly', days: [1], until: '2026-04-10' },
        excluded_dates: [],
      });
      (repo.listByDateRange as ReturnType<typeof vi.fn>).mockResolvedValue([slot]);

      // 2026-04-06 is a Monday (day 1), before until date 2026-04-10
      const result = await service.getExpandedForDate('studio-A', 'prof-1', '2026-04-06');

      expect(result).toHaveLength(1);
    });

    it('does NOT return recurring absence when date is in excluded_dates', async () => {
      const slot = makeBlockedSlot({
        recurrence_rule: { frequency: 'weekly', days: [1], until: null },
        excluded_dates: ['2026-04-06'],
      });
      (repo.listByDateRange as ReturnType<typeof vi.fn>).mockResolvedValue([slot]);

      // 2026-04-06 is a Monday but is excluded
      const result = await service.getExpandedForDate('studio-A', 'prof-1', '2026-04-06');

      expect(result).toHaveLength(0);
    });

    it('returns recurring absence when no excluded_dates and no until', async () => {
      const slot = makeBlockedSlot({
        recurrence_rule: { frequency: 'weekly', days: [3], until: null },
        excluded_dates: [],
      });
      (repo.listByDateRange as ReturnType<typeof vi.fn>).mockResolvedValue([slot]);

      // 2026-04-08 is a Wednesday (day 3)
      const result = await service.getExpandedForDate('studio-A', 'prof-1', '2026-04-08');

      expect(result).toHaveLength(1);
    });

    it('passes studioId and professionalId to repository', async () => {
      (repo.listByDateRange as ReturnType<typeof vi.fn>).mockResolvedValue([]);

      await service.getExpandedForDate('studio-A', 'prof-1', '2026-04-06');

      expect(repo.listByDateRange).toHaveBeenCalledWith(
        'studio-A',
        'prof-1',
        '2026-04-06',
        '2026-04-06',
      );
    });
  });

  // ─── create ──────────────────────────────────────────────────────────────

  describe('create', () => {
    it('creates sporadic blocked slot', async () => {
      const created = makeBlockedSlot({ title: 'Dentista' });
      (repo.create as ReturnType<typeof vi.fn>).mockResolvedValue(created);

      const result = await service.create('studio-A', {
        professionalId: 'prof-1',
        date: '2026-04-07',
        startTime: '14:00',
        endTime: '15:00',
        title: 'Dentista',
      });

      expect(result.title).toBe('Dentista');
      expect(repo.create).toHaveBeenCalledWith(
        expect.objectContaining({ studioId: 'studio-A', title: 'Dentista' }),
      );
    });

    it('creates recurring blocked slot with recurrence rule', async () => {
      const rule = { frequency: 'weekly' as const, days: [1], until: null };
      const created = makeBlockedSlot({ recurrence_rule: rule });
      (repo.create as ReturnType<typeof vi.fn>).mockResolvedValue(created);

      await service.create('studio-A', {
        professionalId: 'prof-1',
        date: '2026-04-07',
        startTime: '12:00',
        endTime: '13:00',
        title: 'Almoço',
        recurrenceRule: rule,
      });

      expect(repo.create).toHaveBeenCalledWith(
        expect.objectContaining({ recurrenceRule: rule }),
      );
    });
  });

  // ─── delete ──────────────────────────────────────────────────────────────

  describe('delete', () => {
    it('deletes blocked slot and returns true when found', async () => {
      (repo.delete as ReturnType<typeof vi.fn>).mockResolvedValue(true);

      const result = await service.delete('studio-A', 'bs-1');

      expect(result).toBe(true);
      expect(repo.delete).toHaveBeenCalledWith('studio-A', 'bs-1');
    });

    it('throws NotFoundError when slot not found', async () => {
      (repo.delete as ReturnType<typeof vi.fn>).mockResolvedValue(false);

      await expect(service.delete('studio-A', 'bs-not-found')).rejects.toThrow(NotFoundError);
    });
  });

  // ─── removeOccurrence ────────────────────────────────────────────────────

  describe('removeOccurrence', () => {
    it('adds excluded date for recurring absence', async () => {
      const updated = makeBlockedSlot({ excluded_dates: ['2026-04-06'] });
      (repo.addExcludedDate as ReturnType<typeof vi.fn>).mockResolvedValue(updated);

      const result = await service.removeOccurrence('studio-A', 'bs-1', '2026-04-06');

      expect(result?.excluded_dates).toContain('2026-04-06');
      expect(repo.addExcludedDate).toHaveBeenCalledWith('studio-A', 'bs-1', '2026-04-06');
    });

    it('returns null when slot not found', async () => {
      (repo.addExcludedDate as ReturnType<typeof vi.fn>).mockResolvedValue(null);

      const result = await service.removeOccurrence('studio-A', 'bs-not-found', '2026-04-06');

      expect(result).toBeNull();
    });
  });

  // ─── Multi-tenancy ───────────────────────────────────────────────────────

  describe('multi-tenancy', () => {
    it('getExpandedForDate scopes to studioId', async () => {
      (repo.listByDateRange as ReturnType<typeof vi.fn>).mockResolvedValue([]);

      await service.getExpandedForDate('studio-B', 'prof-1', '2026-04-06');

      expect(repo.listByDateRange).toHaveBeenCalledWith(
        'studio-B',
        expect.any(String),
        expect.any(String),
        expect.any(String),
      );
    });
  });
});
