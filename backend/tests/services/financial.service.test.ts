import { describe, it, expect, vi, beforeEach } from 'vitest';
import { FinancialService } from '../../src/services/financial.service.js';
import type { FinancialRepository, LiveQueryResult } from '../../src/repositories/financial.repository.js';
import type { AppointmentRepository } from '../../src/repositories/appointment.repository.js';
import type { ProfessionalRepository, ProfessionalRow } from '../../src/repositories/professional.repository.js';

// ─── Factories ────────────────────────────────────────────────────────────────

function makeProfessional(overrides: Partial<ProfessionalRow> = {}): ProfessionalRow {
  return {
    id: 'prof-1',
    studio_id: 'studio-A',
    user_id: 'user-1',
    name: 'Ana Paula',
    commission_type: 'percentage',
    commission_value: 4000,
    card_fee_policy: 'studio',
    working_hours: {
      monday: [{ open: '09:00', close: '18:00' }],
      tuesday: [{ open: '09:00', close: '18:00' }],
      wednesday: [{ open: '09:00', close: '18:00' }],
      thursday: [{ open: '09:00', close: '18:00' }],
      friday: [{ open: '09:00', close: '18:00' }],
      saturday: [],
      sunday: [],
    },
    is_active: true,
    created_at: '2026-01-01T00:00:00Z',
    updated_at: '2026-01-01T00:00:00Z',
    ...overrides,
  };
}

function makeLiveResult(overrides: Partial<LiveQueryResult> = {}): LiveQueryResult {
  return {
    total_revenue: 50000,
    avg_ticket: 10000,
    total_appointments: 5,
    ...overrides,
  };
}

// ─── Setup ────────────────────────────────────────────────────────────────────

describe('FinancialService', () => {
  let service: FinancialService;
  let financialRepo: FinancialRepository;
  let appointmentRepo: AppointmentRepository;
  let professionalRepo: ProfessionalRepository;

  beforeEach(() => {
    financialRepo = {
      getFromMaterializedView: vi.fn(),
      getLiveQuery: vi.fn(),
      breakdownByProfessional: vi.fn(),
      breakdownByService: vi.fn(),
    } as unknown as FinancialRepository;

    appointmentRepo = {
      listByDate: vi.fn(),
      listByDateRange: vi.fn(),
      listCompletedByDateRange: vi.fn(),
    } as unknown as AppointmentRepository;

    professionalRepo = {
      list: vi.fn(),
      getById: vi.fn(),
    } as unknown as ProfessionalRepository;

    service = new FinancialService(financialRepo, appointmentRepo, professionalRepo);
  });

  // ─── summary ──────────────────────────────────────────────────────────────

  describe('summary', () => {
    it('routes to materialized view for month period', async () => {
      const viewResult = { total_revenue: 100000, avg_ticket: 20000, total_appointments: 5 };
      (financialRepo.getFromMaterializedView as ReturnType<typeof vi.fn>).mockResolvedValue(viewResult);

      const result = await service.summary('studio-A', 'month', '2026-04-15');

      expect(financialRepo.getFromMaterializedView).toHaveBeenCalledWith('studio-A', 2026, 4);
      expect(financialRepo.getLiveQuery).not.toHaveBeenCalled();
      expect(result.total_revenue).toBe(100000);
      expect(result.total_appointments).toBe(5);
    });

    it('routes to live query for day period', async () => {
      (financialRepo.getLiveQuery as ReturnType<typeof vi.fn>).mockResolvedValue(makeLiveResult());

      await service.summary('studio-A', 'day', '2026-04-15');

      expect(financialRepo.getLiveQuery).toHaveBeenCalledWith('studio-A', '2026-04-15', '2026-04-15');
      expect(financialRepo.getFromMaterializedView).not.toHaveBeenCalled();
    });

    it('routes to live query for week period', async () => {
      (financialRepo.getLiveQuery as ReturnType<typeof vi.fn>).mockResolvedValue(makeLiveResult());

      await service.summary('studio-A', 'week', '2026-04-15');

      // Week containing 2026-04-15 (Wednesday): Mon 2026-04-13 to Sun 2026-04-19
      expect(financialRepo.getLiveQuery).toHaveBeenCalledWith('studio-A', '2026-04-13', '2026-04-19');
      expect(financialRepo.getFromMaterializedView).not.toHaveBeenCalled();
    });

    it('returns fallback zeros when materialized view returns null (no data yet)', async () => {
      (financialRepo.getFromMaterializedView as ReturnType<typeof vi.fn>).mockResolvedValue(null);

      const result = await service.summary('studio-A', 'month', '2026-04-15');

      expect(result.total_revenue).toBe(0);
      expect(result.avg_ticket).toBe(0);
      expect(result.total_appointments).toBe(0);
    });

    it('returns period info in the result', async () => {
      (financialRepo.getLiveQuery as ReturnType<typeof vi.fn>).mockResolvedValue(makeLiveResult());

      const result = await service.summary('studio-A', 'day', '2026-04-15');

      expect(result.period).toBe('day');
      expect(result.date_from).toBe('2026-04-15');
      expect(result.date_to).toBe('2026-04-15');
    });
  });

  // ─── occupancyRate ────────────────────────────────────────────────────────

  describe('occupancyRate', () => {
    it('computes rate = completed_minutes / available_minutes * 100', async () => {
      // 1 professional, Mon-Fri 9-18 (9h/day = 540min/day)
      // dateFrom=2026-04-14 (Mon) to dateTo=2026-04-14 (Mon) = 1 day = 540 available min
      // completed appointments = 60 min
      const professional = makeProfessional();

      (professionalRepo.list as ReturnType<typeof vi.fn>).mockResolvedValue([professional]);
      (appointmentRepo.listCompletedByDateRange as ReturnType<typeof vi.fn>).mockResolvedValue([
        { duration_minutes: 60 },
      ]);

      const rate = await service.occupancyRate('studio-A', '2026-04-14', '2026-04-14');

      // 60 / 540 * 100 = 11.11...
      expect(rate).toBeCloseTo(11.11, 1);
    });

    it('returns 0 when no professionals', async () => {
      (professionalRepo.list as ReturnType<typeof vi.fn>).mockResolvedValue([]);
      (appointmentRepo.listCompletedByDateRange as ReturnType<typeof vi.fn>).mockResolvedValue([]);

      const rate = await service.occupancyRate('studio-A', '2026-04-14', '2026-04-14');

      expect(rate).toBe(0);
    });

    it('returns 0 when professional has no working hours for that day', async () => {
      const professional = makeProfessional({
        working_hours: {
          monday: [],
          tuesday: [],
          wednesday: [],
          thursday: [],
          friday: [],
          saturday: [],
          sunday: [],
        },
      });

      (professionalRepo.list as ReturnType<typeof vi.fn>).mockResolvedValue([professional]);
      (appointmentRepo.listCompletedByDateRange as ReturnType<typeof vi.fn>).mockResolvedValue([
        { duration_minutes: 60 },
      ]);

      const rate = await service.occupancyRate('studio-A', '2026-04-14', '2026-04-14');

      expect(rate).toBe(0);
    });

    it('multi-day range accumulates available minutes across all days', async () => {
      // 1 professional Mon-Fri 9-18 (540min/day)
      // dateFrom=2026-04-14 (Mon) to dateTo=2026-04-16 (Wed) = 3 days = 1620 available min
      // completed = 270 min
      const professional = makeProfessional();

      (professionalRepo.list as ReturnType<typeof vi.fn>).mockResolvedValue([professional]);
      (appointmentRepo.listCompletedByDateRange as ReturnType<typeof vi.fn>).mockResolvedValue([
        { duration_minutes: 270 },
      ]);

      const rate = await service.occupancyRate('studio-A', '2026-04-14', '2026-04-16');

      // 270 / 1620 * 100 = 16.66...
      expect(rate).toBeCloseTo(16.67, 1);
    });
  });

  // ─── breakdowns ───────────────────────────────────────────────────────────

  describe('breakdownByProfessional', () => {
    it('delegates to financialRepo.breakdownByProfessional', async () => {
      const breakdown = [{ professional_id: 'prof-1', professional_name: 'Ana', total_amount: 50000, percentage: 100 }];
      (financialRepo.breakdownByProfessional as ReturnType<typeof vi.fn>).mockResolvedValue(breakdown);

      const result = await service.breakdownByProfessional('studio-A', '2026-04-01', '2026-04-30');

      expect(financialRepo.breakdownByProfessional).toHaveBeenCalledWith('studio-A', '2026-04-01', '2026-04-30');
      expect(result).toBe(breakdown);
    });
  });

  describe('breakdownByService', () => {
    it('delegates to financialRepo.breakdownByService', async () => {
      const breakdown = [{ service_id: 'svc-1', service_name: 'Manicure', total_amount: 50000, percentage: 100 }];
      (financialRepo.breakdownByService as ReturnType<typeof vi.fn>).mockResolvedValue(breakdown);

      const result = await service.breakdownByService('studio-A', '2026-04-01', '2026-04-30');

      expect(financialRepo.breakdownByService).toHaveBeenCalledWith('studio-A', '2026-04-01', '2026-04-30');
      expect(result).toBe(breakdown);
    });
  });
});
