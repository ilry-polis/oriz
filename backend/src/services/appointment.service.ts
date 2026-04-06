import type {
	AppointmentRepository,
	AppointmentRow,
	AppointmentStatus,
	AppointmentSource,
} from "../repositories/appointment.repository.js";
import type { ProfessionalRepository } from "../repositories/professional.repository.js";
import type { ServiceRepository } from "../repositories/service.repository.js";
import type {
	PaymentRepository,
	PaymentMethod,
} from "../repositories/payment.repository.js";
import type { CommissionService } from "./commission.service.js";
import type { PackageSubscriptionRepository } from "../repositories/package-subscription.repository.js";
import type { PackageRepository } from "../repositories/package.repository.js";
import type { StudioRepository } from "../repositories/studio.repository.js";
import type { FinancialRefreshQueue } from "../jobs/financial-refresh.job.js";
import type { BlockedSlotService } from "./blocked-slot.service.js";
import { NotFoundError, UnprocessableError } from "../utils/errors.js";

// ─── Types ─────────────────────────────────────────────────────────────────

type TimeSlot = { open: string; close: string };
type WorkingHours = Record<string, TimeSlot[]>;

const DAY_NAMES = [
	"sunday",
	"monday",
	"tuesday",
	"wednesday",
	"thursday",
	"friday",
	"saturday",
];

/** Status transitions: from -> allowed targets */
const VALID_TRANSITIONS: Record<AppointmentStatus, AppointmentStatus[]> = {
	pending: ["confirmed", "cancelled"],
	confirmed: ["completed", "cancelled", "no_show"],
	completed: [],
	cancelled: [],
	no_show: [],
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

/** @deprecated Use ExtendedPaymentParams instead */
export type PaymentParams = {
	amount: number;
	method: PaymentMethod;
	cardFeePercentage?: number;
};

export type ExtendedPaymentParams = {
	payments: Array<{
		amount: number;
		method: PaymentMethod;
		cardFeePercentage?: number;
	}>;
	discountAmount?: number; // centavos
	discountReason?: string;
	type?: "avulso" | "pacote";
};

export type CompleteAppointmentPayload = {
	packageSubscriptionId?: string;
	payment?: ExtendedPaymentParams;
	userRole?: "owner" | "professional";
};

// ─── Service ────────────────────────────────────────────────────────────────

export class AppointmentService {
	constructor(
		private appointmentRepo: AppointmentRepository,
		private professionalRepo: ProfessionalRepository,
		private serviceRepo: ServiceRepository,
		private paymentRepo: PaymentRepository,
		private blockedSlotService: BlockedSlotService,
		private commissionService?: CommissionService,
		private packageSubRepo?: PackageSubscriptionRepository,
		private packageRepo?: PackageRepository,
		private studioRepo?: StudioRepository,
		private financialRefreshQueue?: FinancialRefreshQueue,
	) {}

	// ─── Queries ──────────────────────────────────────────────────────────────

	async listByDate(
		studioId: string,
		date: string,
		options: {
			professionalId?: string;
			status?: AppointmentStatus;
			cursor?: string;
			limit?: number;
		} = {},
	): Promise<AppointmentRow[]> {
		return this.appointmentRepo.listByDate(studioId, date, options);
	}

	async listByDateRange(
		studioId: string,
		dateFrom: string,
		dateTo: string,
		options: {
			professionalId?: string;
			status?: AppointmentStatus;
			cursor?: string;
			limit?: number;
		} = {},
	): Promise<AppointmentRow[]> {
		return this.appointmentRepo.listByDateRange(
			studioId,
			dateFrom,
			dateTo,
			options,
		);
	}

	async monthSummary(
		studioId: string,
		dateFrom: string,
		dateTo: string,
		professionalId?: string,
	) {
		return this.appointmentRepo.monthSummary(
			studioId,
			dateFrom,
			dateTo,
			professionalId,
		);
	}

	async getById(
		studioId: string,
		appointmentId: string,
	): Promise<AppointmentRow> {
		const appt = await this.appointmentRepo.getById(studioId, appointmentId);
		if (!appt) throw new NotFoundError("Appointment not found");
		return appt;
	}

	// ─── Status Transitions ───────────────────────────────────────────────────

	async confirmAppointment(
		studioId: string,
		appointmentId: string,
	): Promise<AppointmentRow> {
		return this._transition(studioId, appointmentId, "confirmed");
	}

	async cancelAppointment(
		studioId: string,
		appointmentId: string,
		reason?: string,
	): Promise<AppointmentRow> {
		return this._transition(studioId, appointmentId, "cancelled", reason);
	}

	async completeAppointment(
		studioId: string,
		appointmentId: string,
		payload?: CompleteAppointmentPayload,
	): Promise<{
		appointment: AppointmentRow;
		lastSession?: boolean;
		sessionsRemaining?: number;
	}> {
		// ── Package path ─────────────────────────────────────────────────────────
		if (payload?.packageSubscriptionId) {
			if (!this.packageSubRepo)
				throw new Error("packageSubRepo not configured");
			if (!this.packageRepo) throw new Error("packageRepo not configured");

			const subResult = await this.packageSubRepo.deductSession(
				studioId,
				payload.packageSubscriptionId,
			);
			if (!subResult) {
				throw new UnprocessableError(
					"PACKAGE_UNAVAILABLE",
					"Package subscription is not available for deduction",
				);
			}

			// Transition appointment status
			const appt = await this._transition(studioId, appointmentId, "completed");

			// Calculate commission on package unit price
			const unitPrice = await this.packageRepo.getUnitPrice(
				studioId,
				subResult.package_id,
			);
			if (unitPrice !== null && this.commissionService) {
				await this.commissionService.calculateAndRecord({
					studioId,
					appointmentId,
					professionalId: appt.professional_id,
					amount: unitPrice,
					method: "package" as PaymentMethod,
					date: appt.date,
				});
			}

			const lastSession = subResult.status === "completed";
			const sessionsRemaining =
				subResult.sessions_total - subResult.sessions_used;

			return { appointment: appt, lastSession, sessionsRemaining };
		}

		// ── Regular payment path ─────────────────────────────────────────────────
		if (payload?.payment) {
			const {
				payments,
				discountAmount = 0,
				discountReason,
				type,
			} = payload.payment;
			const userRole = payload.userRole;
			const totalAmount = payments.reduce((sum, p) => sum + p.amount, 0);

			// Discount enforcement for non-owners
			if (userRole !== "owner" && discountAmount > 0 && totalAmount > 0) {
				const studio = await this.studioRepo?.findById(studioId);
				const settings = (studio?.settings ?? {}) as {
					max_discount_percentage?: number;
				};
				const maxPct = settings.max_discount_percentage ?? 100;
				const discountPct = (discountAmount / totalAmount) * 100;
				if (discountPct > maxPct) {
					throw new UnprocessableError(
						"DISCOUNT_EXCEEDS_LIMIT",
						`Discount of ${discountPct.toFixed(1)}% exceeds allowed maximum of ${maxPct}%`,
					);
				}
			}

			const appt = await this._transition(studioId, appointmentId, "completed");

			// Create payment row(s). Apply full discount on first row only.
			for (let i = 0; i < payments.length; i++) {
				const p = payments[i]!;
				await this.paymentRepo.create({
					studioId,
					appointmentId,
					clientId: appt.client_id,
					amount: p.amount,
					method: p.method,
					cardFeePercentage: p.cardFeePercentage,
					type: type ?? "avulso",
					discountAmount: i === 0 ? discountAmount : 0,
					discountReason: i === 0 ? discountReason : undefined,
				});
			}

			// Commission on net amount
			const netAmount = totalAmount - discountAmount;
			if (this.commissionService) {
				await this.commissionService.calculateAndRecord({
					studioId,
					appointmentId,
					professionalId: appt.professional_id,
					amount: netAmount,
					method: payments[0]!.method,
					date: appt.date,
				});
			}

			// Enqueue async view refresh
			this.financialRefreshQueue?.add(studioId);

			return { appointment: appt };
		}

		// ── No payment / no package ──────────────────────────────────────────────
		const appt = await this._transition(studioId, appointmentId, "completed");
		return { appointment: appt };
	}

	async markNoShow(
		studioId: string,
		appointmentId: string,
	): Promise<AppointmentRow> {
		return this._transition(studioId, appointmentId, "no_show");
	}

	// ─── Create ───────────────────────────────────────────────────────────────

	async createAppointment(
		studioId: string,
		params: CreateAppointmentParams,
	): Promise<AppointmentRow> {
		// Fetch professional and service (validates ownership via studioId)
		const professional = await this.professionalRepo.getById(
			studioId,
			params.professionalId,
		);
		if (!professional) throw new NotFoundError("Professional not found");

		const svc = await this.serviceRepo.getById(studioId, params.serviceId);
		if (!svc) throw new NotFoundError("Service not found");

		// Calculate end time
		const endTime = addMinutesToTime(
			params.startTime,
			svc.duration_minutes + svc.buffer_minutes,
		);

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
			throw new UnprocessableError(
				"TIME_SLOT_BLOCKED",
				"This time slot is blocked by an absence",
			);
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

		const reschedulable: AppointmentStatus[] = ["pending", "confirmed"];
		if (!reschedulable.includes(appt.status)) {
			throw new UnprocessableError(
				"INVALID_STATUS_FOR_RESCHEDULE",
				`Cannot reschedule appointment with status '${appt.status}'`,
			);
		}

		// Recalculate end_time when start_time changes
		let endTime = params.endTime;
		if (params.startTime && !endTime) {
			endTime = addMinutesToTime(
				params.startTime,
				appt.duration_minutes + appt.buffer_minutes,
			);
		}

		const updated = await this.appointmentRepo.update(studioId, appointmentId, {
			professional_id: params.professionalId,
			service_id: params.serviceId,
			date: params.date,
			start_time: params.startTime,
			end_time: endTime,
			notes: params.notes,
		});

		if (!updated) throw new NotFoundError("Appointment not found after update");
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
		const professional = await this.professionalRepo.getById(
			studioId,
			professionalId,
		);
		if (!professional) throw new NotFoundError("Professional not found");

		const svc = await this.serviceRepo.getById(studioId, serviceId);
		if (!svc) throw new NotFoundError("Service not found");

		const hours = professional.working_hours as WorkingHours | null;
		if (!hours) return [];
		const dayName = getDayName(date);
		const daySlots: TimeSlot[] = hours[dayName] ?? [];

		if (daySlots.length === 0) return [];

		const totalDurationMinutes = svc.duration_minutes + svc.buffer_minutes;

		// Fetch existing appointments and blocked slots in parallel
		const [existingAppts, blockedRanges] = await Promise.all([
			this.appointmentRepo.listByProfessionalDate(
				studioId,
				professionalId,
				date,
			),
			this.blockedSlotService.getExpandedForDate(
				studioId,
				professionalId,
				date,
			),
		]);

		// Build all occupied ranges: existing appointments (use their actual end times which include buffer)
		const occupiedRanges = [
			...existingAppts.map((a) => ({
				start_time: a.start_time,
				end_time: a.end_time,
			})),
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
		if (!appt) throw new NotFoundError("Appointment not found");

		const allowed = VALID_TRANSITIONS[appt.status];
		if (!allowed.includes(target)) {
			throw new UnprocessableError(
				"INVALID_STATUS_TRANSITION",
				`Cannot transition appointment from '${appt.status}' to '${target}'`,
			);
		}

		const updated = await this.appointmentRepo.updateStatus(
			studioId,
			appointmentId,
			target,
			cancellationReason,
		);
		if (!updated)
			throw new NotFoundError("Appointment not found after status update");
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
				"OUTSIDE_WORKING_HOURS",
				"Professional does not work on this day",
			);
		}

		const fits = daySlots.some(
			(slot) => startTime >= slot.open && endTime <= slot.close,
		);

		if (!fits) {
			throw new UnprocessableError(
				"OUTSIDE_WORKING_HOURS",
				"Appointment falls outside the professional's working hours",
			);
		}
	}
}

// ─── Time Utilities ────────────────────────────────────────────────────────

/** Parse "HH:mm" to total minutes since midnight */
function timeToMinutes(time: string): number {
	const [h, m] = time.split(":").map(Number);
	return h! * 60 + m!;
}

/** Convert total minutes since midnight to "HH:mm" */
function minutesToTime(minutes: number): string {
	const h = Math.floor(minutes / 60);
	const m = minutes % 60;
	return `${String(h).padStart(2, "0")}:${String(m).padStart(2, "0")}`;
}

/** Add minutes to an "HH:mm" time string */
function addMinutesToTime(time: string, minutes: number): string {
	return minutesToTime(timeToMinutes(time) + minutes);
}

/** Get the lowercase day name (monday, tuesday, ...) for an ISO date string */
function getDayName(date: string): string {
	const [year, month, day] = date.split("-").map(Number);
	const d = new Date(Date.UTC(year!, month! - 1, day!));
	return DAY_NAMES[d.getUTCDay()]!;
}

/** Check whether [startA, endA) overlaps any range in the list */
function timesOverlapAny(
	startA: string,
	endA: string,
	ranges: Array<{ start_time: string; end_time: string }>,
): boolean {
	return ranges.some((r) => startA < r.end_time && endA > r.start_time);
}
