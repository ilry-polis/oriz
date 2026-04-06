import { describe, it, expect, vi, beforeEach } from 'vitest';
import { AppointmentService } from '../../src/services/appointment.service.js';
import type { AppointmentRepository, AppointmentRow } from '../../src/repositories/appointment.repository.js';
import type { ProfessionalRepository, ProfessionalRow } from '../../src/repositories/professional.repository.js';
import type { ServiceRepository, ServiceRow } from '../../src/repositories/service.repository.js';
import type { PaymentRepository } from '../../src/repositories/payment.repository.js';
import type { CommissionService } from '../../src/services/commission.service.js';
import type { PackageSubscriptionRepository, PackageSubscriptionRow } from '../../src/repositories/package-subscription.repository.js';
import type { PackageRepository } from '../../src/repositories/package.repository.js';
import type { StudioRepository } from '../../src/repositories/studio.repository.js';
import type { FinancialRefreshQueue } from '../../src/jobs/financial-refresh.job.js';
import { BlockedSlotService } from '../../src/services/blocked-slot.service.js';
import type { BlockedSlotRepository } from '../../src/repositories/blocked-slot.repository.js';
import { ConflictError, NotFoundError, UnprocessableError } from '../../src/utils/errors.js';

// ─── Factories ────────────────────────────────────────────────────────────────

function makeAppointment(overrides: Partial<AppointmentRow> = {}): AppointmentRow {
  return {
    id: 'appt-1',
    studio_id: 'studio-A',
    client_id: 'client-1',
    professional_id: 'prof-1',
    service_id: 'svc-1',
    date: '2026-04-07',
    start_time: '10:00',
    end_time: '11:00',
    status: 'pending',
    source: 'app',
    notes: null,
    cancellation_reason: null,
    created_at: '2026-04-03T10:00:00Z',
    updated_at: '2026-04-03T10:00:00Z',
    client_name: 'Maria Silva',
    client_phone: '+5511999999999',
    professional_name: 'Ana Paula',
    service_name: 'Manicure',
    duration_minutes: 60,
    price: 5000,
    buffer_minutes: 0,
    ...overrides,
  };
}

function makeProfessional(overrides: Partial<ProfessionalRow> = {}): ProfessionalRow {
  return {
    id: 'prof-1',
    studio_id: 'studio-A',
    user_id: 'user-1',
    name: 'Ana Paula',
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

function makeService(overrides: Partial<ServiceRow> = {}): ServiceRow {
  return {
    id: 'svc-1',
    studio_id: 'studio-A',
    category_id: 'cat-1',
    name: 'Manicure',
    duration_minutes: 60,
    price: 5000,
    buffer_minutes: 0,
    is_active: true,
    created_at: '2026-01-01T00:00:00Z',
    updated_at: '2026-01-01T00:00:00Z',
    ...overrides,
  };
}

// ─── Additional Factories ────────────────────────────────────────────────────

function makeSubscription(overrides: Partial<PackageSubscriptionRow> = {}): PackageSubscriptionRow {
  return {
    id: 'sub-1',
    studio_id: 'studio-A',
    package_id: 'pkg-1',
    client_id: 'client-1',
    sessions_used: 1,
    sessions_total: 5,
    expires_at: '2027-01-01T00:00:00Z',
    status: 'active',
    created_at: '2026-01-01T00:00:00Z',
    updated_at: '2026-01-01T00:00:00Z',
    ...overrides,
  };
}

// ─── Setup ────────────────────────────────────────────────────────────────────

describe('AppointmentService', () => {
  let service: AppointmentService;
  let appointmentRepo: AppointmentRepository;
  let professionalRepo: ProfessionalRepository;
  let serviceRepo: ServiceRepository;
  let paymentRepo: PaymentRepository;
  let commissionService: CommissionService;
  let packageSubRepo: PackageSubscriptionRepository;
  let packageRepo: PackageRepository;
  let studioRepo: StudioRepository;
  let financialRefreshQueue: FinancialRefreshQueue;
  let blockedSlotRepo: BlockedSlotRepository;
  let blockedSlotService: BlockedSlotService;

  beforeEach(() => {
    appointmentRepo = {
      listByDate: vi.fn(),
      listByDateRange: vi.fn(),
      listByProfessionalDate: vi.fn(),
      getById: vi.fn(),
      create: vi.fn(),
      updateStatus: vi.fn(),
      update: vi.fn(),
    } as unknown as AppointmentRepository;

    professionalRepo = {
      getById: vi.fn(),
      findByUserId: vi.fn(),
      updateWorkingHours: vi.fn(),
    } as unknown as ProfessionalRepository;

    serviceRepo = {
      getById: vi.fn(),
      create: vi.fn(),
    } as unknown as ServiceRepository;

    paymentRepo = {
      create: vi.fn(),
    } as unknown as PaymentRepository;

    commissionService = {
      calculateAndRecord: vi.fn().mockResolvedValue({ id: 'comm-1' }),
    } as unknown as CommissionService;

    packageSubRepo = {
      deductSession: vi.fn(),
      getActiveForClientService: vi.fn(),
    } as unknown as PackageSubscriptionRepository;

    packageRepo = {
      getUnitPrice: vi.fn().mockResolvedValue(3000),
      getById: vi.fn(),
    } as unknown as PackageRepository;

    studioRepo = {
      findById: vi.fn().mockResolvedValue({
        id: 'studio-A',
        settings: { max_discount_percentage: 20 },
      }),
    } as unknown as StudioRepository;

    financialRefreshQueue = {
      add: vi.fn(),
    } as unknown as FinancialRefreshQueue;

    blockedSlotRepo = {
      listByDateRange: vi.fn(),
      create: vi.fn(),
      delete: vi.fn(),
      addExcludedDate: vi.fn(),
    } as unknown as BlockedSlotRepository;

    blockedSlotService = new BlockedSlotService(blockedSlotRepo);

    service = new AppointmentService(
      appointmentRepo,
      professionalRepo,
      serviceRepo,
      paymentRepo,
      blockedSlotService,
      commissionService,
      packageSubRepo,
      packageRepo,
      studioRepo,
      financialRefreshQueue,
    );
  });

  // ─── Status Machine ────────────────────────────────────────────────────────

  describe('status transitions', () => {
    it('confirmAppointment: pending -> confirmed', async () => {
      const appt = makeAppointment({ status: 'pending' });
      (appointmentRepo.getById as ReturnType<typeof vi.fn>).mockResolvedValue(appt);
      (appointmentRepo.updateStatus as ReturnType<typeof vi.fn>).mockResolvedValue(
        makeAppointment({ status: 'confirmed' }),
      );

      const result = await service.confirmAppointment('studio-A', 'appt-1');

      expect(result.status).toBe('confirmed');
      expect(appointmentRepo.updateStatus).toHaveBeenCalledWith(
        'studio-A', 'appt-1', 'confirmed', undefined,
      );
    });

    it('cancelAppointment: pending -> cancelled', async () => {
      const appt = makeAppointment({ status: 'pending' });
      (appointmentRepo.getById as ReturnType<typeof vi.fn>).mockResolvedValue(appt);
      (appointmentRepo.updateStatus as ReturnType<typeof vi.fn>).mockResolvedValue(
        makeAppointment({ status: 'cancelled' }),
      );

      const result = await service.cancelAppointment('studio-A', 'appt-1', 'Client request');

      expect(result.status).toBe('cancelled');
    });

    it('cancelAppointment: confirmed -> cancelled', async () => {
      const appt = makeAppointment({ status: 'confirmed' });
      (appointmentRepo.getById as ReturnType<typeof vi.fn>).mockResolvedValue(appt);
      (appointmentRepo.updateStatus as ReturnType<typeof vi.fn>).mockResolvedValue(
        makeAppointment({ status: 'cancelled' }),
      );

      const result = await service.cancelAppointment('studio-A', 'appt-1');

      expect(result.status).toBe('cancelled');
    });

    it('completeAppointment: confirmed -> completed', async () => {
      const appt = makeAppointment({ status: 'confirmed' });
      (appointmentRepo.getById as ReturnType<typeof vi.fn>).mockResolvedValue(appt);
      (appointmentRepo.updateStatus as ReturnType<typeof vi.fn>).mockResolvedValue(
        makeAppointment({ status: 'completed' }),
      );

      const result = await service.completeAppointment('studio-A', 'appt-1');

      expect(result.appointment.status).toBe('completed');
    });

    it('markNoShow: confirmed -> no_show', async () => {
      const appt = makeAppointment({ status: 'confirmed' });
      (appointmentRepo.getById as ReturnType<typeof vi.fn>).mockResolvedValue(appt);
      (appointmentRepo.updateStatus as ReturnType<typeof vi.fn>).mockResolvedValue(
        makeAppointment({ status: 'no_show' }),
      );

      const result = await service.markNoShow('studio-A', 'appt-1');

      expect(result.status).toBe('no_show');
    });

    it('throws UnprocessableError for invalid transition: completed -> confirmed', async () => {
      const appt = makeAppointment({ status: 'completed' });
      (appointmentRepo.getById as ReturnType<typeof vi.fn>).mockResolvedValue(appt);

      await expect(
        service.confirmAppointment('studio-A', 'appt-1'),
      ).rejects.toThrow(UnprocessableError);
    });

    it('throws UnprocessableError for invalid transition: cancelled -> confirmed', async () => {
      const appt = makeAppointment({ status: 'cancelled' });
      (appointmentRepo.getById as ReturnType<typeof vi.fn>).mockResolvedValue(appt);

      await expect(
        service.confirmAppointment('studio-A', 'appt-1'),
      ).rejects.toThrow(UnprocessableError);
    });

    it('throws UnprocessableError for invalid transition: no_show -> completed', async () => {
      const appt = makeAppointment({ status: 'no_show' });
      (appointmentRepo.getById as ReturnType<typeof vi.fn>).mockResolvedValue(appt);

      await expect(
        service.completeAppointment('studio-A', 'appt-1'),
      ).rejects.toThrow(UnprocessableError);
    });

    it('throws UnprocessableError: completed -> cancelled', async () => {
      const appt = makeAppointment({ status: 'completed' });
      (appointmentRepo.getById as ReturnType<typeof vi.fn>).mockResolvedValue(appt);

      await expect(
        service.cancelAppointment('studio-A', 'appt-1'),
      ).rejects.toThrow(UnprocessableError);
    });

    it('throws NotFoundError when appointment does not exist', async () => {
      (appointmentRepo.getById as ReturnType<typeof vi.fn>).mockResolvedValue(null);

      await expect(
        service.confirmAppointment('studio-A', 'nonexistent'),
      ).rejects.toThrow(NotFoundError);
    });
  });

  // ─── completeAppointment with payment ─────────────────────────────────────

  describe('completeAppointment with payment', () => {
    it('records payment when payment data provided (new extended format)', async () => {
      const appt = makeAppointment({ status: 'confirmed' });
      (appointmentRepo.getById as ReturnType<typeof vi.fn>).mockResolvedValue(appt);
      (appointmentRepo.updateStatus as ReturnType<typeof vi.fn>).mockResolvedValue(
        makeAppointment({ status: 'completed' }),
      );
      (paymentRepo.create as ReturnType<typeof vi.fn>).mockResolvedValue({ id: 'pay-1' });

      await service.completeAppointment('studio-A', 'appt-1', {
        payment: {
          payments: [{ amount: 5000, method: 'pix' }],
        },
      });

      expect(paymentRepo.create).toHaveBeenCalledWith(
        expect.objectContaining({
          studioId: 'studio-A',
          appointmentId: 'appt-1',
          clientId: 'client-1',
          amount: 5000,
          method: 'pix',
        }),
      );
    });

    it('does NOT record payment when no payload provided', async () => {
      const appt = makeAppointment({ status: 'confirmed' });
      (appointmentRepo.getById as ReturnType<typeof vi.fn>).mockResolvedValue(appt);
      (appointmentRepo.updateStatus as ReturnType<typeof vi.fn>).mockResolvedValue(
        makeAppointment({ status: 'completed' }),
      );

      await service.completeAppointment('studio-A', 'appt-1');

      expect(paymentRepo.create).not.toHaveBeenCalled();
    });

    it('records commission on net amount (amount minus discountAmount)', async () => {
      const appt = makeAppointment({ status: 'confirmed', date: '2026-04-07' });
      (appointmentRepo.getById as ReturnType<typeof vi.fn>).mockResolvedValue(appt);
      (appointmentRepo.updateStatus as ReturnType<typeof vi.fn>).mockResolvedValue(
        makeAppointment({ status: 'completed' }),
      );
      (paymentRepo.create as ReturnType<typeof vi.fn>).mockResolvedValue({ id: 'pay-1' });

      await service.completeAppointment('studio-A', 'appt-1', {
        payment: {
          payments: [{ amount: 5000, method: 'pix' }],
          discountAmount: 500,
        },
      });

      expect(commissionService.calculateAndRecord).toHaveBeenCalledWith(
        expect.objectContaining({
          amount: 4500, // 5000 - 500 discount
          studioId: 'studio-A',
          appointmentId: 'appt-1',
          professionalId: 'prof-1',
        }),
      );
    });

    it('split payment creates 2 payment rows', async () => {
      const appt = makeAppointment({ status: 'confirmed' });
      (appointmentRepo.getById as ReturnType<typeof vi.fn>).mockResolvedValue(appt);
      (appointmentRepo.updateStatus as ReturnType<typeof vi.fn>).mockResolvedValue(
        makeAppointment({ status: 'completed' }),
      );
      (paymentRepo.create as ReturnType<typeof vi.fn>).mockResolvedValue({ id: 'pay-1' });

      await service.completeAppointment('studio-A', 'appt-1', {
        payment: {
          payments: [
            { amount: 3000, method: 'pix' },
            { amount: 2000, method: 'credit' },
          ],
        },
      });

      expect(paymentRepo.create).toHaveBeenCalledTimes(2);
    });

    it('split payment: commission calculated on total net amount', async () => {
      const appt = makeAppointment({ status: 'confirmed', date: '2026-04-07' });
      (appointmentRepo.getById as ReturnType<typeof vi.fn>).mockResolvedValue(appt);
      (appointmentRepo.updateStatus as ReturnType<typeof vi.fn>).mockResolvedValue(
        makeAppointment({ status: 'completed' }),
      );
      (paymentRepo.create as ReturnType<typeof vi.fn>).mockResolvedValue({ id: 'pay-1' });

      await service.completeAppointment('studio-A', 'appt-1', {
        payment: {
          payments: [
            { amount: 3000, method: 'pix' },
            { amount: 2000, method: 'cash' },
          ],
          discountAmount: 1000,
        },
      });

      // total = 5000, discount = 1000, net = 4000
      expect(commissionService.calculateAndRecord).toHaveBeenCalledWith(
        expect.objectContaining({ amount: 4000 }),
      );
    });

    it('enqueues financial view refresh after payment', async () => {
      const appt = makeAppointment({ status: 'confirmed' });
      (appointmentRepo.getById as ReturnType<typeof vi.fn>).mockResolvedValue(appt);
      (appointmentRepo.updateStatus as ReturnType<typeof vi.fn>).mockResolvedValue(
        makeAppointment({ status: 'completed' }),
      );
      (paymentRepo.create as ReturnType<typeof vi.fn>).mockResolvedValue({ id: 'pay-1' });

      await service.completeAppointment('studio-A', 'appt-1', {
        payment: { payments: [{ amount: 5000, method: 'pix' }] },
      });

      expect(financialRefreshQueue.add).toHaveBeenCalledWith('studio-A');
    });

    it('discount limit enforcement: non-owner exceeding max_discount_percentage throws DISCOUNT_EXCEEDS_LIMIT', async () => {
      const appt = makeAppointment({ status: 'confirmed' });
      (appointmentRepo.getById as ReturnType<typeof vi.fn>).mockResolvedValue(appt);
      (appointmentRepo.updateStatus as ReturnType<typeof vi.fn>).mockResolvedValue(
        makeAppointment({ status: 'completed' }),
      );
      // max_discount_percentage = 20, discount = 30% (1500 / 5000 = 30%)
      await expect(
        service.completeAppointment('studio-A', 'appt-1', {
          payment: {
            payments: [{ amount: 5000, method: 'pix' }],
            discountAmount: 1500,
          },
          userRole: 'professional',
        }),
      ).rejects.toThrow(UnprocessableError);
    });

    it('discount limit: owner can exceed max_discount_percentage', async () => {
      const appt = makeAppointment({ status: 'confirmed' });
      (appointmentRepo.getById as ReturnType<typeof vi.fn>).mockResolvedValue(appt);
      (appointmentRepo.updateStatus as ReturnType<typeof vi.fn>).mockResolvedValue(
        makeAppointment({ status: 'completed' }),
      );
      (paymentRepo.create as ReturnType<typeof vi.fn>).mockResolvedValue({ id: 'pay-1' });

      // owner can exceed limit (1500 / 5000 = 30% > 20%)
      await expect(
        service.completeAppointment('studio-A', 'appt-1', {
          payment: {
            payments: [{ amount: 5000, method: 'pix' }],
            discountAmount: 1500,
          },
          userRole: 'owner',
        }),
      ).resolves.toBeDefined();
    });

    it('discount within limit for professional succeeds', async () => {
      const appt = makeAppointment({ status: 'confirmed' });
      (appointmentRepo.getById as ReturnType<typeof vi.fn>).mockResolvedValue(appt);
      (appointmentRepo.updateStatus as ReturnType<typeof vi.fn>).mockResolvedValue(
        makeAppointment({ status: 'completed' }),
      );
      (paymentRepo.create as ReturnType<typeof vi.fn>).mockResolvedValue({ id: 'pay-1' });

      // 500/5000 = 10% <= 20% max
      await expect(
        service.completeAppointment('studio-A', 'appt-1', {
          payment: {
            payments: [{ amount: 5000, method: 'pix' }],
            discountAmount: 500,
          },
          userRole: 'professional',
        }),
      ).resolves.toBeDefined();
    });
  });

  // ─── completeAppointment with package ─────────────────────────────────────

  describe('completeAppointment with package', () => {
    it('deducts session and returns sessionsRemaining when sessions still available', async () => {
      const appt = makeAppointment({ status: 'confirmed' });
      (appointmentRepo.getById as ReturnType<typeof vi.fn>).mockResolvedValue(appt);
      (appointmentRepo.updateStatus as ReturnType<typeof vi.fn>).mockResolvedValue(
        makeAppointment({ status: 'completed' }),
      );
      // 2 used out of 5 after deduction, status still active
      (packageSubRepo.deductSession as ReturnType<typeof vi.fn>).mockResolvedValue(
        makeSubscription({ sessions_used: 2, sessions_total: 5, status: 'active' }),
      );

      const result = await service.completeAppointment('studio-A', 'appt-1', {
        packageSubscriptionId: 'sub-1',
      });

      expect(result.appointment.status).toBe('completed');
      expect(result.lastSession).toBe(false);
      expect(result.sessionsRemaining).toBe(3); // 5 - 2
      expect(packageSubRepo.deductSession).toHaveBeenCalledWith('studio-A', 'sub-1');
    });

    it('returns lastSession=true when subscription transitions to completed', async () => {
      const appt = makeAppointment({ status: 'confirmed' });
      (appointmentRepo.getById as ReturnType<typeof vi.fn>).mockResolvedValue(appt);
      (appointmentRepo.updateStatus as ReturnType<typeof vi.fn>).mockResolvedValue(
        makeAppointment({ status: 'completed' }),
      );
      // Last session used (5/5), status=completed
      (packageSubRepo.deductSession as ReturnType<typeof vi.fn>).mockResolvedValue(
        makeSubscription({ sessions_used: 5, sessions_total: 5, status: 'completed' }),
      );

      const result = await service.completeAppointment('studio-A', 'appt-1', {
        packageSubscriptionId: 'sub-1',
      });

      expect(result.lastSession).toBe(true);
      expect(result.sessionsRemaining).toBe(0);
    });

    it('throws PACKAGE_UNAVAILABLE when deductSession returns null (expired/completed)', async () => {
      const appt = makeAppointment({ status: 'confirmed' });
      (appointmentRepo.getById as ReturnType<typeof vi.fn>).mockResolvedValue(appt);
      (packageSubRepo.deductSession as ReturnType<typeof vi.fn>).mockResolvedValue(null);

      await expect(
        service.completeAppointment('studio-A', 'appt-1', {
          packageSubscriptionId: 'sub-expired',
        }),
      ).rejects.toThrow(UnprocessableError);
    });

    it('records commission on package unit price when deducting session', async () => {
      const appt = makeAppointment({ status: 'confirmed', date: '2026-04-07' });
      (appointmentRepo.getById as ReturnType<typeof vi.fn>).mockResolvedValue(appt);
      (appointmentRepo.updateStatus as ReturnType<typeof vi.fn>).mockResolvedValue(
        makeAppointment({ status: 'completed' }),
      );
      (packageSubRepo.deductSession as ReturnType<typeof vi.fn>).mockResolvedValue(
        makeSubscription({ sessions_used: 2, sessions_total: 5, status: 'active' }),
      );
      // unit price = 3000 (mocked in beforeEach)

      await service.completeAppointment('studio-A', 'appt-1', {
        packageSubscriptionId: 'sub-1',
      });

      expect(packageRepo.getUnitPrice).toHaveBeenCalledWith('studio-A', 'pkg-1');
      expect(commissionService.calculateAndRecord).toHaveBeenCalledWith(
        expect.objectContaining({
          amount: 3000,
          method: 'package',
          appointmentId: 'appt-1',
          studioId: 'studio-A',
          professionalId: 'prof-1',
        }),
      );
    });

    it('does NOT record payment row for package appointment', async () => {
      const appt = makeAppointment({ status: 'confirmed' });
      (appointmentRepo.getById as ReturnType<typeof vi.fn>).mockResolvedValue(appt);
      (appointmentRepo.updateStatus as ReturnType<typeof vi.fn>).mockResolvedValue(
        makeAppointment({ status: 'completed' }),
      );
      (packageSubRepo.deductSession as ReturnType<typeof vi.fn>).mockResolvedValue(
        makeSubscription(),
      );

      await service.completeAppointment('studio-A', 'appt-1', {
        packageSubscriptionId: 'sub-1',
      });

      expect(paymentRepo.create).not.toHaveBeenCalled();
    });
  });

  // ─── createAppointment ────────────────────────────────────────────────────

  describe('createAppointment', () => {
    beforeEach(() => {
      // Default: professional works Mon-Fri 09:00-18:00; service 60min, 0 buffer
      (professionalRepo.getById as ReturnType<typeof vi.fn>).mockResolvedValue(makeProfessional());
      (serviceRepo.getById as ReturnType<typeof vi.fn>).mockResolvedValue(makeService());
      (blockedSlotRepo.listByDateRange as ReturnType<typeof vi.fn>).mockResolvedValue([]);
    });

    it('creates appointment when slot is valid', async () => {
      const created = makeAppointment({ status: 'pending' });
      (appointmentRepo.create as ReturnType<typeof vi.fn>).mockResolvedValue(created);

      // 2026-04-06 is a Monday
      const result = await service.createAppointment('studio-A', {
        clientId: 'client-1',
        professionalId: 'prof-1',
        serviceId: 'svc-1',
        date: '2026-04-06',
        startTime: '10:00',
        source: 'app',
      });

      expect(result.status).toBe('pending');
      expect(appointmentRepo.create).toHaveBeenCalledWith(
        expect.objectContaining({
          studioId: 'studio-A',
          startTime: '10:00',
          endTime: '11:00', // 10:00 + 60min
        }),
      );
    });

    it('calculates end_time including buffer_minutes', async () => {
      const svcWithBuffer = makeService({ duration_minutes: 60, buffer_minutes: 30 });
      (serviceRepo.getById as ReturnType<typeof vi.fn>).mockResolvedValue(svcWithBuffer);
      (appointmentRepo.create as ReturnType<typeof vi.fn>).mockResolvedValue(makeAppointment());

      await service.createAppointment('studio-A', {
        clientId: 'client-1',
        professionalId: 'prof-1',
        serviceId: 'svc-1',
        date: '2026-04-06',
        startTime: '10:00',
        source: 'app',
      });

      expect(appointmentRepo.create).toHaveBeenCalledWith(
        expect.objectContaining({
          endTime: '11:30', // 10:00 + 60min + 30min buffer
        }),
      );
    });

    it('throws UnprocessableError OUTSIDE_WORKING_HOURS when before open time', async () => {
      await expect(
        service.createAppointment('studio-A', {
          clientId: 'client-1',
          professionalId: 'prof-1',
          serviceId: 'svc-1',
          date: '2026-04-06', // Monday
          startTime: '08:00', // before 09:00
          source: 'app',
        }),
      ).rejects.toThrow(UnprocessableError);
    });

    it('throws UnprocessableError OUTSIDE_WORKING_HOURS when after close time', async () => {
      await expect(
        service.createAppointment('studio-A', {
          clientId: 'client-1',
          professionalId: 'prof-1',
          serviceId: 'svc-1',
          date: '2026-04-06', // Monday
          startTime: '17:30', // 17:30 + 60min = 18:30, exceeds close 18:00
          source: 'app',
        }),
      ).rejects.toThrow(UnprocessableError);
    });

    it('throws UnprocessableError OUTSIDE_WORKING_HOURS on day professional does not work', async () => {
      // Professional does not work on Saturday
      await expect(
        service.createAppointment('studio-A', {
          clientId: 'client-1',
          professionalId: 'prof-1',
          serviceId: 'svc-1',
          date: '2026-04-04', // Saturday
          startTime: '10:00',
          source: 'app',
        }),
      ).rejects.toThrow(UnprocessableError);
    });

    it('throws UnprocessableError TIME_SLOT_BLOCKED when blocked slot covers time', async () => {
      const { BlockedSlotRow } = await import('../../src/repositories/blocked-slot.repository.js');
      // Blocked slot 10:00-11:00
      (blockedSlotRepo.listByDateRange as ReturnType<typeof vi.fn>).mockResolvedValue([
        {
          id: 'bs-1',
          studio_id: 'studio-A',
          professional_id: 'prof-1',
          date: '2026-04-06',
          start_time: '10:00',
          end_time: '11:00',
          title: 'Almoço',
          reason: null,
          recurrence_rule: null,
          excluded_dates: [],
          created_at: '2026-04-03T10:00:00Z',
        },
      ]);

      await expect(
        service.createAppointment('studio-A', {
          clientId: 'client-1',
          professionalId: 'prof-1',
          serviceId: 'svc-1',
          date: '2026-04-06',
          startTime: '10:00',
          source: 'app',
        }),
      ).rejects.toThrow(UnprocessableError);
    });

    it('propagates ConflictError TIME_SLOT_TAKEN from repository (concurrent booking)', async () => {
      (appointmentRepo.create as ReturnType<typeof vi.fn>).mockRejectedValue(
        new ConflictError('TIME_SLOT_TAKEN', 'This time slot is already booked'),
      );

      await expect(
        service.createAppointment('studio-A', {
          clientId: 'client-1',
          professionalId: 'prof-1',
          serviceId: 'svc-1',
          date: '2026-04-06',
          startTime: '10:00',
          source: 'app',
        }),
      ).rejects.toThrow(ConflictError);
    });

    it('throws NotFoundError when professional not found', async () => {
      (professionalRepo.getById as ReturnType<typeof vi.fn>).mockResolvedValue(null);

      await expect(
        service.createAppointment('studio-A', {
          clientId: 'client-1',
          professionalId: 'prof-not-found',
          serviceId: 'svc-1',
          date: '2026-04-06',
          startTime: '10:00',
          source: 'app',
        }),
      ).rejects.toThrow(NotFoundError);
    });

    it('throws NotFoundError when service not found', async () => {
      (serviceRepo.getById as ReturnType<typeof vi.fn>).mockResolvedValue(null);

      await expect(
        service.createAppointment('studio-A', {
          clientId: 'client-1',
          professionalId: 'prof-1',
          serviceId: 'svc-not-found',
          date: '2026-04-06',
          startTime: '10:00',
          source: 'app',
        }),
      ).rejects.toThrow(NotFoundError);
    });
  });

  // ─── getAvailableSlots ────────────────────────────────────────────────────

  describe('getAvailableSlots', () => {
    beforeEach(() => {
      (professionalRepo.getById as ReturnType<typeof vi.fn>).mockResolvedValue(makeProfessional());
      (serviceRepo.getById as ReturnType<typeof vi.fn>).mockResolvedValue(makeService());
      (appointmentRepo.listByProfessionalDate as ReturnType<typeof vi.fn>).mockResolvedValue([]);
      (blockedSlotRepo.listByDateRange as ReturnType<typeof vi.fn>).mockResolvedValue([]);
    });

    it('returns slots for a working day in 15-minute intervals', async () => {
      // Monday 09:00-18:00, service 60min, no appointments, no blocked slots
      // Expected: 09:00, 09:15, 09:30, ..., 17:00 (last slot ending at 18:00)
      const slots = await service.getAvailableSlots('studio-A', 'prof-1', 'svc-1', '2026-04-06');

      expect(slots.length).toBeGreaterThan(0);
      expect(slots[0]).toBe('09:00');
      // Last slot: start 17:00, end 18:00 (exactly at close)
      expect(slots).toContain('17:00');
      expect(slots).not.toContain('17:15'); // 17:15 + 60min = 18:15 > 18:00
    });

    it('returns empty array when professional does not work on that day', async () => {
      // Saturday: professional has no hours
      const slots = await service.getAvailableSlots('studio-A', 'prof-1', 'svc-1', '2026-04-04'); // Saturday

      expect(slots).toHaveLength(0);
    });

    it('excludes slot occupied by existing appointment', async () => {
      (appointmentRepo.listByProfessionalDate as ReturnType<typeof vi.fn>).mockResolvedValue([
        makeAppointment({ start_time: '10:00', end_time: '11:00', date: '2026-04-06' }),
      ]);

      const slots = await service.getAvailableSlots('studio-A', 'prof-1', 'svc-1', '2026-04-06');

      expect(slots).not.toContain('10:00');
      expect(slots).not.toContain('10:15'); // 10:15 + 60min = 11:15 overlaps appt ending 11:00
    });

    it('excludes slot covered by blocked slot', async () => {
      (blockedSlotRepo.listByDateRange as ReturnType<typeof vi.fn>).mockResolvedValue([
        {
          id: 'bs-1',
          studio_id: 'studio-A',
          professional_id: 'prof-1',
          date: '2026-04-06',
          start_time: '14:00',
          end_time: '15:00',
          title: 'Almoço',
          reason: null,
          recurrence_rule: null,
          excluded_dates: [],
          created_at: '2026-04-03T10:00:00Z',
        },
      ]);

      const slots = await service.getAvailableSlots('studio-A', 'prof-1', 'svc-1', '2026-04-06');

      expect(slots).not.toContain('14:00');
    });

    it('considers buffer_minutes in slot exclusion', async () => {
      const svcWithBuffer = makeService({ duration_minutes: 60, buffer_minutes: 30 });
      (serviceRepo.getById as ReturnType<typeof vi.fn>).mockResolvedValue(svcWithBuffer);
      // Appointment at 10:00 blocks until 11:30 (60min + 30min buffer)
      (appointmentRepo.listByProfessionalDate as ReturnType<typeof vi.fn>).mockResolvedValue([
        makeAppointment({ start_time: '10:00', end_time: '11:30', date: '2026-04-06', buffer_minutes: 30 }),
      ]);

      const slots = await service.getAvailableSlots('studio-A', 'prof-1', 'svc-1', '2026-04-06');

      // Slot at 11:00 would end at 12:30 (60min + 30min buffer = 90min after 11:00)
      // But slot at 11:00 starts before 11:30 (existing appointment end including buffer)
      expect(slots).not.toContain('10:00');
      expect(slots).not.toContain('11:00'); // 11:00 < 11:30 (existing appt end)
      expect(slots).toContain('11:30'); // 11:30 is >= 11:30 (exactly at existing appt end)
    });

    it('throws NotFoundError when professional not found', async () => {
      (professionalRepo.getById as ReturnType<typeof vi.fn>).mockResolvedValue(null);

      await expect(
        service.getAvailableSlots('studio-A', 'prof-not-found', 'svc-1', '2026-04-06'),
      ).rejects.toThrow(NotFoundError);
    });
  });

  // ─── listByDate ──────────────────────────────────────────────────────────

  describe('listByDate', () => {
    it('delegates to repository with studioId', async () => {
      const appts = [makeAppointment()];
      (appointmentRepo.listByDate as ReturnType<typeof vi.fn>).mockResolvedValue(appts);

      const result = await service.listByDate('studio-A', '2026-04-06');

      expect(result).toEqual(appts);
      expect(appointmentRepo.listByDate).toHaveBeenCalledWith(
        'studio-A', '2026-04-06', expect.any(Object),
      );
    });
  });

  // ─── getById ─────────────────────────────────────────────────────────────

  describe('getById', () => {
    it('returns appointment when found', async () => {
      const appt = makeAppointment();
      (appointmentRepo.getById as ReturnType<typeof vi.fn>).mockResolvedValue(appt);

      const result = await service.getById('studio-A', 'appt-1');

      expect(result.id).toBe('appt-1');
    });

    it('throws NotFoundError when appointment not found', async () => {
      (appointmentRepo.getById as ReturnType<typeof vi.fn>).mockResolvedValue(null);

      await expect(service.getById('studio-A', 'nonexistent')).rejects.toThrow(NotFoundError);
    });
  });

  // ─── reschedule ──────────────────────────────────────────────────────────

  describe('reschedule', () => {
    it('reschedules appointment when status allows it', async () => {
      const appt = makeAppointment({ status: 'pending' });
      (appointmentRepo.getById as ReturnType<typeof vi.fn>).mockResolvedValue(appt);
      (appointmentRepo.update as ReturnType<typeof vi.fn>).mockResolvedValue(
        makeAppointment({ date: '2026-04-07', start_time: '14:00', end_time: '15:00' }),
      );

      const result = await service.reschedule('studio-A', 'appt-1', {
        date: '2026-04-07',
        startTime: '14:00',
        endTime: '15:00',
      });

      expect(result.start_time).toBe('14:00');
    });

    it('throws UnprocessableError when rescheduling a completed appointment', async () => {
      const appt = makeAppointment({ status: 'completed' });
      (appointmentRepo.getById as ReturnType<typeof vi.fn>).mockResolvedValue(appt);

      await expect(
        service.reschedule('studio-A', 'appt-1', { date: '2026-04-07', startTime: '14:00' }),
      ).rejects.toThrow(UnprocessableError);
    });

    it('throws UnprocessableError when rescheduling a cancelled appointment', async () => {
      const appt = makeAppointment({ status: 'cancelled' });
      (appointmentRepo.getById as ReturnType<typeof vi.fn>).mockResolvedValue(appt);

      await expect(
        service.reschedule('studio-A', 'appt-1', { date: '2026-04-07', startTime: '14:00' }),
      ).rejects.toThrow(UnprocessableError);
    });
  });

  // ─── Multi-tenancy ───────────────────────────────────────────────────────

  describe('multi-tenancy', () => {
    it('getById with wrong studioId returns NotFoundError (repo returns null)', async () => {
      (appointmentRepo.getById as ReturnType<typeof vi.fn>).mockResolvedValue(null);

      await expect(
        service.getById('studio-B', 'appt-1'),
      ).rejects.toThrow(NotFoundError);
    });

    it('createAppointment scopes professional lookup to studioId', async () => {
      (professionalRepo.getById as ReturnType<typeof vi.fn>).mockResolvedValue(null);

      await expect(
        service.createAppointment('studio-B', {
          clientId: 'client-1',
          professionalId: 'prof-1', // belongs to studio-A
          serviceId: 'svc-1',
          date: '2026-04-06',
          startTime: '10:00',
          source: 'app',
        }),
      ).rejects.toThrow(NotFoundError);

      expect(professionalRepo.getById).toHaveBeenCalledWith('studio-B', 'prof-1');
    });
  });
});
