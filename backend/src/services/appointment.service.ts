import type {
  AppointmentRepository,
  AppointmentRow,
  AppointmentStatus,
  AppointmentSource,
} from '../repositories/appointment.repository.js';
import type { ProfessionalRepository } from '../repositories/professional.repository.js';
import type { ServiceRepository } from '../repositories/service.repository.js';
import type { PaymentRepository, PaymentMethod } from '../repositories/payment.repository.js';
import type { BlockedSlotService } from './blocked-slot.service.js';
import { NotFoundError, UnprocessableError } from '../utils/errors.js';

// ─── Types ─────────────────────────────────────────────────────────────────

type TimeSlot = { open: string; close: string };
type WorkingHours = Record<string, TimeSlot[]>;

const DAY_NAMES = ['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday'];

/** Status transitions: from -> allowed targets */
const VALID_TRANSITIONS: Record<AppointmentStatus, AppointmentStatus[]> = {
  pending:   ['confirmed', 'cancelled'],
  confirmed: ['completed', 'cancelled', 'no_show'],
  completed: [],
  cancelled: [],
  no_show:   [],
};

export type CreateAppointmentParams = {
  clientId: string;
  professionalId: string;
  serviceId: string;
  date: string;
  startTime: string;
  source: AppointmentSource;
  notes?: string;
};

export type RescheduleParams = {
  date?: string;
  startTime?: string;
  endTime?: string;
  professionalId?: string;
  serviceId?: string;
  notes?: string;
};

export type PaymentParams = {
  amount: number;
  method: PaymentMethod;
  cardFeePercentage?: number;
};

// ─── Service ────────────────────────────────────────────────────────────────

export class AppointmentService {
  constructor(
    private appointmentRepo: AppointmentRepository,
    private professionalRepo: ProfessionalRepository,
    private serviceRepo: ServiceRepository,
    private paymentRepo: PaymentRepository,
    private blockedSlotService: BlockedSlotService,
  ) {}

  // ─── Queries ──────────────────────────────────────────────────────────────

  async listByDate(
    studioId: string,
    date: string,
    options: { professionalId?: string; status?: AppointmentStatus; cursor?: string; limit?: number } = {},
  ): Promise<AppointmentRow[]> {
    return this.appointmentRepo.listByDate(studioId, date, options);
  }

  async listByDateRange(
    studioId: string,
    dateFrom: string,
    dateTo: string,
    options: { professionalId?: string; status?: AppointmentStatus; cursor?: string; limit?: number } = {},
  ): Promise<AppointmentRow[]> {
    return this.appointmentRepo.listByDateRange(studioId, dateFrom, dateTo, options);
  }

  async getById(studioId: string, appointmentId: string): Promise<AppointmentRow> {
    const appt = await this.appointmentRepo.getById(studioId, appointmentId);
    if (!appt) throw new NotFoundError('Appointment not found');
    return appt;
  }

  // ─── Status Transitions ───────────────────────────────────────────────────

  async confirmAppointment(studioId: string, appointmentId: string): Promise<AppointmentRow> {
    return this._transition(studioId, appointmentId, 'confirmed');
  }

  async cancelAppointment(
    studioId: string,
    appointmentId: string,
    reason?: string,
  ): Promise<AppointmentRow> {
    return this._transition(studioId, appointmentId, 'cancelled', reason);
  }

  async completeAppointment(
    studioId: string,
    appointmentId: string,
    payment?: PaymentParams,
  ): Promise<AppointmentRow> {
    const appt = await this._transition(studioId, appointmentId, 'completed');

    if (payment) {
      await this.paymentRepo.create({
        studioId,
        appointmentId,
        clientId: appt.client_id,
        amount: payment.amount,
        method: payment.method,
        cardFeePercentage: payment.cardFeePercentage,
      });
    }

    return appt;
  }

  async markNoShow(studioId: string, appointmentId: string): Promise<AppointmentRow> {
    return this._transition(studioId, appointmentId, 'no_show');
  }

  // ─── Create ───────────────────────────────────────────────────────────────

  async createAppointment(
    studioId: string,
    params: CreateAppointmentParams,
  ): Promise<AppointmentRow> {
    // Fetch professional and service (validates ownership via studioId)
    const professional = await this.professionalRepo.getById(studioId, params.professionalId);
    if (!professional) throw new NotFoundError('Professional not found');

    const svc = await this.serviceRepo.getById(studioId, params.serviceId);
    if (!svc) throw new NotFoundError('Service not found');

    // Calculate end time
    const endTime = addMinutesToTime(params.startTime, svc.duration_minutes + svc.buffer_minutes);

    // Validate working hours
    this._assertWithinWorkingHours(
      professional.working_hours as WorkingHours,
      params.date,
      params.startTime,
      endTime,
    );

    // Check blocked slots
    const blocked = await this.blockedSlotService.getExpandedForDate(
      studioId,
      params.professionalId,
      params.date,
    );
    if (timesOverlapAny(params.startTime, endTime, blocked)) {
      throw new UnprocessableError('TIME_SLOT_BLOCKED', 'This time slot is blocked by an absence');
    }

    // Create — repository constraint handles concurrent double-booking
    return this.appointmentRepo.create({
      studioId,
      clientId: params.clientId,
      professionalId: params.professionalId,
      serviceId: params.serviceId,
      date: params.date,
      startTime: params.startTime,
      endTime,
      notes: params.notes,
      source: params.source,
    });
  }

  // ─── Reschedule ───────────────────────────────────────────────────────────

  async reschedule(
    studioId: string,
    appointmentId: string,
    params: RescheduleParams,
  ): Promise<AppointmentRow> {
    const appt = await this.getById(studioId, appointmentId);

    const reschedulable: AppointmentStatus[] = ['pending', 'confirmed'];
    if (!reschedulable.includes(appt.status)) {
      throw new UnprocessableError(
        'INVALID_STATUS_FOR_RESCHEDULE',
        `Cannot reschedule appointment with status '${appt.status}'`,
      );
    }

    const updated = await this.appointmentRepo.update(studioId, appointmentId, {
      professional_id: params.professionalId,
      service_id: params.serviceId,
      date: params.date,
      start_time: params.startTime,
      end_time: params.endTime,
      notes: params.notes,
    });

    if (!updated) throw new NotFoundError('Appointment not found after update');
    return updated;
  }

  // ─── Available Slots ──────────────────────────────────────────────────────

  /**
   * Returns all available start times (HH:mm) for a professional on a date for a given service.
   * Slots are generated in 15-minute intervals.
   */
  async getAvailableSlots(
    studioId: string,
    professionalId: string,
    serviceId: string,
    date: string,
  ): Promise<string[]> {
    const professional = await this.professionalRepo.getById(studioId, professionalId);
    if (!professional) throw new NotFoundError('Professional not found');

    const svc = await this.serviceRepo.getById(studioId, serviceId);
    if (!svc) throw new NotFoundError('Service not found');

    const hours = professional.working_hours as WorkingHours;
    const dayName = getDayName(date);
    const daySlots: TimeSlot[] = hours[dayName] ?? [];

    if (daySlots.length === 0) return [];

    const totalDurationMinutes = svc.duration_minutes + svc.buffer_minutes;

    // Fetch existing appointments and blocked slots in parallel
    const [existingAppts, blockedRanges] = await Promise.all([
      this.appointmentRepo.listByProfessionalDate(studioId, professionalId, date),
      this.blockedSlotService.getExpandedForDate(studioId, professionalId, date),
    ]);

    // Build all occupied ranges: existing appointments (use their actual end times which include buffer)
    const occupiedRanges = [
      ...existingAppts.map(a => ({ start_time: a.start_time, end_time: a.end_time })),
      ...blockedRanges,
    ];

    const available: string[] = [];

    for (const { open, close } of daySlots) {
      // Walk from open to (close - totalDuration) in 15-min steps
      let currentMinutes = timeToMinutes(open);
      const closeMinutes = timeToMinutes(close);

      while (currentMinutes + totalDurationMinutes <= closeMinutes) {
        const slotStart = minutesToTime(currentMinutes);
        const slotEnd = minutesToTime(currentMinutes + totalDurationMinutes);

        if (!timesOverlapAny(slotStart, slotEnd, occupiedRanges)) {
          available.push(slotStart);
        }

        currentMinutes += 15;
      }
    }

    return available;
  }

  // ─── Private Helpers ──────────────────────────────────────────────────────

  private async _transition(
    studioId: string,
    appointmentId: string,
    target: AppointmentStatus,
    cancellationReason?: string,
  ): Promise<AppointmentRow> {
    const appt = await this.appointmentRepo.getById(studioId, appointmentId);
    if (!appt) throw new NotFoundError('Appointment not found');

    const allowed = VALID_TRANSITIONS[appt.status];
    if (!allowed.includes(target)) {
      throw new UnprocessableError(
        'INVALID_STATUS_TRANSITION',
        `Cannot transition appointment from '${appt.status}' to '${target}'`,
      );
    }

    const updated = await this.appointmentRepo.updateStatus(
      studioId,
      appointmentId,
      target,
      cancellationReason,
    );
    if (!updated) throw new NotFoundError('Appointment not found after status update');
    return updated;
  }

  private _assertWithinWorkingHours(
    hours: WorkingHours,
    date: string,
    startTime: string,
    endTime: string,
  ): void {
    const dayName = getDayName(date);
    const daySlots: TimeSlot[] = hours[dayName] ?? [];

    if (daySlots.length === 0) {
      throw new UnprocessableError(
        'OUTSIDE_WORKING_HOURS',
        'Professional does not work on this day',
      );
    }

    const fits = daySlots.some(
      slot => startTime >= slot.open && endTime <= slot.close,
    );

    if (!fits) {
      throw new UnprocessableError(
        'OUTSIDE_WORKING_HOURS',
        'Appointment falls outside the professional\'s working hours',
      );
    }
  }
}

// ─── Time Utilities ────────────────────────────────────────────────────────

/** Parse "HH:mm" to total minutes since midnight */
function timeToMinutes(time: string): number {
  const [h, m] = time.split(':').map(Number);
  return h! * 60 + m!;
}

/** Convert total minutes since midnight to "HH:mm" */
function minutesToTime(minutes: number): string {
  const h = Math.floor(minutes / 60);
  const m = minutes % 60;
  return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}`;
}

/** Add minutes to an "HH:mm" time string */
function addMinutesToTime(time: string, minutes: number): string {
  return minutesToTime(timeToMinutes(time) + minutes);
}

/** Get the lowercase day name (monday, tuesday, ...) for an ISO date string */
function getDayName(date: string): string {
  const [year, month, day] = date.split('-').map(Number);
  const d = new Date(Date.UTC(year!, month! - 1, day!));
  return DAY_NAMES[d.getUTCDay()]!;
}

/** Check whether [startA, endA) overlaps any range in the list */
function timesOverlapAny(
  startA: string,
  endA: string,
  ranges: Array<{ start_time: string; end_time: string }>,
): boolean {
  return ranges.some(r => startA < r.end_time && endA > r.start_time);
}
