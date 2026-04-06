import { describe, it, expect, vi, beforeEach } from 'vitest';
import { CommissionService } from '../../src/services/commission.service.js';
import type { CommissionRepository } from '../../src/repositories/commission.repository.js';
import type { ProfessionalRepository, ProfessionalRow } from '../../src/repositories/professional.repository.js';
import type { StudioRepository, StudioRow } from '../../src/repositories/studio.repository.js';

// ─── Factories ────────────────────────────────────────────────────────────────

function makeProfessional(overrides: Partial<ProfessionalRow> = {}): ProfessionalRow {
  return {
    id: 'prof-1',
    studio_id: 'studio-A',
    user_id: 'user-1',
    name: 'Ana Paula',
    commission_type: 'percentage',
    commission_value: 4000, // 40%
    card_fee_policy: 'studio',
    working_hours: {},
    is_active: true,
    created_at: '2026-01-01T00:00:00Z',
    updated_at: '2026-01-01T00:00:00Z',
    ...overrides,
  };
}

function makeStudio(overrides: Partial<StudioRow> = {}): StudioRow {
  return {
    id: 'studio-A',
    owner_id: 'owner-1',
    name: 'Studio A',
    slug: 'studio-a',
    phone: null,
    address: null,
    description: null,
    timezone: 'America/Sao_Paulo',
    settings: {
      commission_period: 'monthly',
      card_fee_rates: { credit: 250, debit: 150 }, // basis points
    },
    created_at: '2026-01-01T00:00:00Z',
    updated_at: '2026-01-01T00:00:00Z',
    ...overrides,
  };
}

// ─── Setup ────────────────────────────────────────────────────────────────────

describe('CommissionService', () => {
  let service: CommissionService;
  let commissionRepo: CommissionRepository;
  let professionalRepo: ProfessionalRepository;
  let studioRepo: StudioRepository;

  beforeEach(() => {
    commissionRepo = {
      create: vi.fn(),
      list: vi.fn(),
      markPaid: vi.fn(),
      sumByProfessional: vi.fn(),
    } as unknown as CommissionRepository;

    professionalRepo = {
      getById: vi.fn(),
      findByUserId: vi.fn(),
      updateWorkingHours: vi.fn(),
      create: vi.fn(),
      list: vi.fn(),
      update: vi.fn(),
      replaceServiceLinks: vi.fn(),
      getServiceLinks: vi.fn(),
    } as unknown as ProfessionalRepository;

    studioRepo = {
      findById: vi.fn(),
      findByOwnerId: vi.fn(),
      findBySlug: vi.fn(),
      createWithOnboarding: vi.fn(),
    } as unknown as StudioRepository;

    service = new CommissionService(commissionRepo, professionalRepo, studioRepo);
  });

  // ─── calculateAndRecord ───────────────────────────────────────────────────

  describe('calculateAndRecord', () => {
    it('percentage type: calculates professional_amount as percentage of net amount', async () => {
      const professional = makeProfessional({ commission_type: 'percentage', commission_value: 4000 }); // 40%
      const studio = makeStudio();

      (professionalRepo.getById as ReturnType<typeof vi.fn>).mockResolvedValue(professional);
      (studioRepo.findById as ReturnType<typeof vi.fn>).mockResolvedValue(studio);
      (commissionRepo.create as ReturnType<typeof vi.fn>).mockResolvedValue({ id: 'comm-1' });

      await service.calculateAndRecord({
        studioId: 'studio-A',
        professionalId: 'prof-1',
        appointmentId: 'appt-1',
        amount: 10000, // R$100.00
        method: 'cash',
        date: '2026-04-15',
      });

      const createCall = (commissionRepo.create as ReturnType<typeof vi.fn>).mock.calls[0]![0];
      // cash has 0 fee, studio_absorbs: net = 10000, 40% = 4000
      expect(createCall.professionalAmount).toBe(4000);
      expect(createCall.cardFeeAmount).toBe(0);
    });

    it('fixed type: professional_amount = fixed value regardless of payment amount', async () => {
      const professional = makeProfessional({ commission_type: 'fixed', commission_value: 3000 }); // R$30.00
      const studio = makeStudio();

      (professionalRepo.getById as ReturnType<typeof vi.fn>).mockResolvedValue(professional);
      (studioRepo.findById as ReturnType<typeof vi.fn>).mockResolvedValue(studio);
      (commissionRepo.create as ReturnType<typeof vi.fn>).mockResolvedValue({ id: 'comm-1' });

      await service.calculateAndRecord({
        studioId: 'studio-A',
        professionalId: 'prof-1',
        appointmentId: 'appt-1',
        amount: 10000,
        method: 'cash',
        date: '2026-04-15',
      });

      const createCall = (commissionRepo.create as ReturnType<typeof vi.fn>).mock.calls[0]![0];
      expect(createCall.professionalAmount).toBe(3000);
    });

    it('card fee policy "professional_absorbs": card fee reduces commission base', async () => {
      const professional = makeProfessional({
        commission_type: 'percentage',
        commission_value: 5000, // 50%
        card_fee_policy: 'professional',
      });
      const studio = makeStudio({
        settings: {
          commission_period: 'monthly',
          card_fee_rates: { credit: 250, debit: 150 }, // 2.5% credit
        },
      });

      (professionalRepo.getById as ReturnType<typeof vi.fn>).mockResolvedValue(professional);
      (studioRepo.findById as ReturnType<typeof vi.fn>).mockResolvedValue(studio);
      (commissionRepo.create as ReturnType<typeof vi.fn>).mockResolvedValue({ id: 'comm-1' });

      await service.calculateAndRecord({
        studioId: 'studio-A',
        professionalId: 'prof-1',
        appointmentId: 'appt-1',
        amount: 10000, // R$100.00
        method: 'credit',
        date: '2026-04-15',
      });

      // credit fee = 2.5% of 10000 = 250
      // professional absorbs: base = 10000 - 250 = 9750
      // 50% of 9750 = 4875
      const createCall = (commissionRepo.create as ReturnType<typeof vi.fn>).mock.calls[0]![0];
      expect(createCall.cardFeeAmount).toBe(250);
      expect(createCall.professionalAmount).toBe(4875);
      expect(createCall.whoPaidFee).toBe('professional');
    });

    it('card fee policy "studio_absorbs": card fee does not reduce commission base', async () => {
      const professional = makeProfessional({
        commission_type: 'percentage',
        commission_value: 5000, // 50%
        card_fee_policy: 'studio',
      });
      const studio = makeStudio({
        settings: {
          commission_period: 'monthly',
          card_fee_rates: { credit: 250, debit: 150 },
        },
      });

      (professionalRepo.getById as ReturnType<typeof vi.fn>).mockResolvedValue(professional);
      (studioRepo.findById as ReturnType<typeof vi.fn>).mockResolvedValue(studio);
      (commissionRepo.create as ReturnType<typeof vi.fn>).mockResolvedValue({ id: 'comm-1' });

      await service.calculateAndRecord({
        studioId: 'studio-A',
        professionalId: 'prof-1',
        appointmentId: 'appt-1',
        amount: 10000,
        method: 'credit',
        date: '2026-04-15',
      });

      // studio absorbs fee: base = 10000 (not reduced)
      // 50% of 10000 = 5000
      const createCall = (commissionRepo.create as ReturnType<typeof vi.fn>).mock.calls[0]![0];
      expect(createCall.cardFeeAmount).toBe(250);
      expect(createCall.professionalAmount).toBe(5000);
      expect(createCall.whoPaidFee).toBe('studio');
    });

    it('card fee policy "split": fee split 50/50 between studio and professional', async () => {
      const professional = makeProfessional({
        commission_type: 'percentage',
        commission_value: 5000, // 50%
        card_fee_policy: 'split',
      });
      const studio = makeStudio({
        settings: {
          commission_period: 'monthly',
          card_fee_rates: { credit: 200, debit: 150 }, // 2.0% credit
        },
      });

      (professionalRepo.getById as ReturnType<typeof vi.fn>).mockResolvedValue(professional);
      (studioRepo.findById as ReturnType<typeof vi.fn>).mockResolvedValue(studio);
      (commissionRepo.create as ReturnType<typeof vi.fn>).mockResolvedValue({ id: 'comm-1' });

      await service.calculateAndRecord({
        studioId: 'studio-A',
        professionalId: 'prof-1',
        appointmentId: 'appt-1',
        amount: 10000,
        method: 'credit',
        date: '2026-04-15',
      });

      // credit fee = 2.0% of 10000 = 200
      // split: professional pays 100, studio pays 100
      // professional base = 10000 - 100 = 9900
      // 50% of 9900 = 4950
      const createCall = (commissionRepo.create as ReturnType<typeof vi.fn>).mock.calls[0]![0];
      expect(createCall.cardFeeAmount).toBe(200);
      expect(createCall.professionalAmount).toBe(4950);
      expect(createCall.whoPaidFee).toBe('split');
    });

    it('cash and pix methods have 0 card fee regardless of configured rates', async () => {
      const professional = makeProfessional({ commission_type: 'percentage', commission_value: 5000 });
      const studio = makeStudio();

      (professionalRepo.getById as ReturnType<typeof vi.fn>).mockResolvedValue(professional);
      (studioRepo.findById as ReturnType<typeof vi.fn>).mockResolvedValue(studio);
      (commissionRepo.create as ReturnType<typeof vi.fn>).mockResolvedValue({ id: 'comm-1' });

      for (const method of ['cash', 'pix'] as const) {
        vi.clearAllMocks();
        (professionalRepo.getById as ReturnType<typeof vi.fn>).mockResolvedValue(professional);
        (studioRepo.findById as ReturnType<typeof vi.fn>).mockResolvedValue(studio);
        (commissionRepo.create as ReturnType<typeof vi.fn>).mockResolvedValue({ id: 'comm-1' });

        await service.calculateAndRecord({
          studioId: 'studio-A',
          professionalId: 'prof-1',
          appointmentId: 'appt-1',
          amount: 10000,
          method,
          date: '2026-04-15',
        });

        const createCall = (commissionRepo.create as ReturnType<typeof vi.fn>).mock.calls[0]![0];
        expect(createCall.cardFeeAmount).toBe(0);
      }
    });

    it('period boundaries monthly: 1st to last day of month', async () => {
      const professional = makeProfessional();
      const studio = makeStudio({ settings: { commission_period: 'monthly', card_fee_rates: { credit: 250, debit: 150 } } });

      (professionalRepo.getById as ReturnType<typeof vi.fn>).mockResolvedValue(professional);
      (studioRepo.findById as ReturnType<typeof vi.fn>).mockResolvedValue(studio);
      (commissionRepo.create as ReturnType<typeof vi.fn>).mockResolvedValue({ id: 'comm-1' });

      await service.calculateAndRecord({
        studioId: 'studio-A',
        professionalId: 'prof-1',
        appointmentId: 'appt-1',
        amount: 10000,
        method: 'cash',
        date: '2026-04-15',
      });

      const createCall = (commissionRepo.create as ReturnType<typeof vi.fn>).mock.calls[0]![0];
      expect(createCall.periodStart).toBe('2026-04-01');
      expect(createCall.periodEnd).toBe('2026-04-30');
    });

    it('period boundaries biweekly: 1st half = 1-15', async () => {
      const professional = makeProfessional();
      const studio = makeStudio({ settings: { commission_period: 'biweekly', card_fee_rates: { credit: 250, debit: 150 } } });

      (professionalRepo.getById as ReturnType<typeof vi.fn>).mockResolvedValue(professional);
      (studioRepo.findById as ReturnType<typeof vi.fn>).mockResolvedValue(studio);
      (commissionRepo.create as ReturnType<typeof vi.fn>).mockResolvedValue({ id: 'comm-1' });

      await service.calculateAndRecord({
        studioId: 'studio-A',
        professionalId: 'prof-1',
        appointmentId: 'appt-1',
        amount: 10000,
        method: 'cash',
        date: '2026-04-10',
      });

      const createCall = (commissionRepo.create as ReturnType<typeof vi.fn>).mock.calls[0]![0];
      expect(createCall.periodStart).toBe('2026-04-01');
      expect(createCall.periodEnd).toBe('2026-04-15');
    });

    it('period boundaries biweekly: 2nd half = 16-end of month', async () => {
      const professional = makeProfessional();
      const studio = makeStudio({ settings: { commission_period: 'biweekly', card_fee_rates: { credit: 250, debit: 150 } } });

      (professionalRepo.getById as ReturnType<typeof vi.fn>).mockResolvedValue(professional);
      (studioRepo.findById as ReturnType<typeof vi.fn>).mockResolvedValue(studio);
      (commissionRepo.create as ReturnType<typeof vi.fn>).mockResolvedValue({ id: 'comm-1' });

      await service.calculateAndRecord({
        studioId: 'studio-A',
        professionalId: 'prof-1',
        appointmentId: 'appt-1',
        amount: 10000,
        method: 'cash',
        date: '2026-04-20',
      });

      const createCall = (commissionRepo.create as ReturnType<typeof vi.fn>).mock.calls[0]![0];
      expect(createCall.periodStart).toBe('2026-04-16');
      expect(createCall.periodEnd).toBe('2026-04-30');
    });

    it('amounts stored in centavos (integers), Math.round applied at final step', async () => {
      const professional = makeProfessional({ commission_type: 'percentage', commission_value: 3333 }); // 33.33%
      const studio = makeStudio();

      (professionalRepo.getById as ReturnType<typeof vi.fn>).mockResolvedValue(professional);
      (studioRepo.findById as ReturnType<typeof vi.fn>).mockResolvedValue(studio);
      (commissionRepo.create as ReturnType<typeof vi.fn>).mockResolvedValue({ id: 'comm-1' });

      await service.calculateAndRecord({
        studioId: 'studio-A',
        professionalId: 'prof-1',
        appointmentId: 'appt-1',
        amount: 10000, // 33.33% of 10000 = 3333
        method: 'cash',
        date: '2026-04-15',
      });

      const createCall = (commissionRepo.create as ReturnType<typeof vi.fn>).mock.calls[0]![0];
      expect(Number.isInteger(createCall.professionalAmount)).toBe(true);
    });
  });

  // ─── list / markPaid / sumByProfessional ─────────────────────────────────

  describe('list', () => {
    it('delegates to commissionRepo.list with correct args', async () => {
      (commissionRepo.list as ReturnType<typeof vi.fn>).mockResolvedValue([]);

      await service.list('studio-A', { limit: 10 });

      expect(commissionRepo.list).toHaveBeenCalledWith('studio-A', { limit: 10 });
    });
  });

  describe('markPaid', () => {
    it('delegates to commissionRepo.markPaid', async () => {
      (commissionRepo.markPaid as ReturnType<typeof vi.fn>).mockResolvedValue(2);

      const result = await service.markPaid('studio-A', ['comm-1', 'comm-2']);

      expect(commissionRepo.markPaid).toHaveBeenCalledWith('studio-A', ['comm-1', 'comm-2']);
      expect(result).toBe(2);
    });
  });

  describe('sumByProfessional', () => {
    it('delegates to commissionRepo.sumByProfessional', async () => {
      const summary = [{ professional_id: 'prof-1', professional_name: 'Ana', total_amount: 10000, commission_count: 5 }];
      (commissionRepo.sumByProfessional as ReturnType<typeof vi.fn>).mockResolvedValue(summary);

      const result = await service.sumByProfessional('studio-A', '2026-04-01', '2026-04-30');

      expect(commissionRepo.sumByProfessional).toHaveBeenCalledWith('studio-A', '2026-04-01', '2026-04-30');
      expect(result).toBe(summary);
    });
  });
});
