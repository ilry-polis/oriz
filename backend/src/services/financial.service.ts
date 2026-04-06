import type { AppointmentRepository } from "../repositories/appointment.repository.js";
import type {
	BreakdownByMethod,
	BreakdownByProfessional,
	BreakdownByService,
	DailyRevenueRow,
	FinancialRepository,
	LiveQueryResult,
} from "../repositories/financial.repository.js";
import type {
	ListPaymentsFilters,
	PaymentListRow,
	PaymentRepository,
} from "../repositories/payment.repository.js";
import type { ProfessionalRepository } from "../repositories/professional.repository.js";

// ─── Types ─────────────────────────────────────────────────────────────────

export type PeriodType = "day" | "week" | "month";

export type FinancialSummaryResult = LiveQueryResult & {
	period: PeriodType;
	date_from: string;
	date_to: string;
};

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

// ─── Service ───────────────────────────────────────────────────────────────

export class FinancialService {
	constructor(
		private financialRepo: FinancialRepository,
		private appointmentRepo: AppointmentRepository,
		private professionalRepo: ProfessionalRepository,
		private paymentRepo?: PaymentRepository,
	) {}

	/**
	 * Get financial summary (revenue, avg ticket, appointment count).
	 * Routes to materialized view for 'month' (pre-computed monthly aggregate),
	 * and to live query for 'day' or 'week' (real-time computation from payments table).
	 *
	 * @param studioId - studio identifier
	 * @param period - 'day' | 'week' | 'month'
	 * @param date - ISO date string YYYY-MM-DD (reference date for period boundaries)
	 */
	async summary(
		studioId: string,
		period: PeriodType,
		date: string,
	): Promise<FinancialSummaryResult> {
		const { dateFrom, dateTo } = this.computeDateRange(period, date);

		let result: LiveQueryResult;

		if (period === "month") {
			const [year, month] = date.split("-").map(Number);
			const viewResult = await this.financialRepo.getFromMaterializedView(
				studioId,
				year!,
				month!,
			);
			result = viewResult ?? {
				total_revenue: 0,
				avg_ticket: 0,
				total_appointments: 0,
			};
		} else {
			result = await this.financialRepo.getLiveQuery(
				studioId,
				dateFrom,
				dateTo,
			);
		}

		return {
			...result,
			period,
			date_from: dateFrom,
			date_to: dateTo,
		};
	}

	/**
	 * Compute occupancy rate for a date range.
	 * Rate = sum(completed appointment minutes) / sum(available working minutes) * 100
	 *
	 * Available minutes are derived from each professional's working_hours config
	 * for each day in the range (skipping days with no working hours).
	 *
	 * Returns a percentage (0-100), rounded to 2 decimal places.
	 */
	async occupancyRate(
		studioId: string,
		dateFrom: string,
		dateTo: string,
	): Promise<number> {
		const professionals = await this.professionalRepo.list(studioId);
		if (professionals.length === 0) return 0;

		// Sum available working minutes across all professionals and all days in range
		let totalAvailableMinutes = 0;

		const dates = this.getDatesInRange(dateFrom, dateTo);

		for (const professional of professionals) {
			const workingHours = professional.working_hours as WorkingHours;

			for (const dateStr of dates) {
				const dayOfWeek = new Date(dateStr + "T12:00:00").getDay(); // noon to avoid DST issues
				const dayName = DAY_NAMES[dayOfWeek]!;
				const slots = workingHours[dayName] ?? [];

				for (const slot of slots) {
					totalAvailableMinutes += this.slotToMinutes(slot.open, slot.close);
				}
			}
		}

		if (totalAvailableMinutes === 0) return 0;

		// Sum completed appointment minutes
		const completedAppointments =
			await this.appointmentRepo.listCompletedByDateRange(
				studioId,
				dateFrom,
				dateTo,
			);
		const usedMinutes = completedAppointments.reduce(
			(sum, a) => sum + (a.duration_minutes ?? 0),
			0,
		);

		return Math.round((usedMinutes / totalAvailableMinutes) * 10000) / 100;
	}

	async breakdownByProfessional(
		studioId: string,
		dateFrom: string,
		dateTo: string,
	): Promise<BreakdownByProfessional[]> {
		return this.financialRepo.breakdownByProfessional(
			studioId,
			dateFrom,
			dateTo,
		);
	}

	async breakdownByService(
		studioId: string,
		dateFrom: string,
		dateTo: string,
	): Promise<BreakdownByService[]> {
		return this.financialRepo.breakdownByService(studioId, dateFrom, dateTo);
	}

	async breakdownByMethod(
		studioId: string,
		dateFrom: string,
		dateTo: string,
	): Promise<BreakdownByMethod[]> {
		return this.financialRepo.breakdownByMethod(studioId, dateFrom, dateTo);
	}

	async dailyRevenue(
		studioId: string,
		dateFrom: string,
		dateTo: string,
	): Promise<DailyRevenueRow[]> {
		return this.financialRepo.dailyRevenue(studioId, dateFrom, dateTo);
	}

	async listPayments(
		studioId: string,
		filters: ListPaymentsFilters,
	): Promise<PaymentListRow[]> {
		if (!this.paymentRepo) {
			throw new Error("PaymentRepository not injected into FinancialService");
		}
		return this.paymentRepo.list(studioId, filters);
	}

	// ─── Private helpers ─────────────────────────────────────────────────────

	private computeDateRange(
		period: PeriodType,
		date: string,
	): { dateFrom: string; dateTo: string } {
		if (period === "day") {
			return { dateFrom: date, dateTo: date };
		}

		if (period === "week") {
			const d = new Date(date + "T12:00:00");
			const dayOfWeek = d.getDay(); // 0=Sun, 1=Mon...6=Sat
			const diffToMonday = (dayOfWeek + 6) % 7; // days back to Monday
			const monday = new Date(d);
			monday.setDate(d.getDate() - diffToMonday);
			const sunday = new Date(monday);
			sunday.setDate(monday.getDate() + 6);

			return {
				dateFrom: this.formatDate(monday),
				dateTo: this.formatDate(sunday),
			};
		}

		// month
		const [year, month] = date.split("-").map(Number);
		const lastDay = new Date(year!, month!, 0).getDate();
		const mm = String(month).padStart(2, "0");
		return {
			dateFrom: `${year}-${mm}-01`,
			dateTo: `${year}-${mm}-${String(lastDay).padStart(2, "0")}`,
		};
	}

	private getDatesInRange(dateFrom: string, dateTo: string): string[] {
		const dates: string[] = [];
		const current = new Date(dateFrom + "T12:00:00");
		const end = new Date(dateTo + "T12:00:00");

		while (current <= end) {
			dates.push(this.formatDate(current));
			current.setDate(current.getDate() + 1);
		}

		return dates;
	}

	private slotToMinutes(open: string, close: string): number {
		const [openH, openM] = open.split(":").map(Number);
		const [closeH, closeM] = close.split(":").map(Number);
		return closeH! * 60 + closeM! - (openH! * 60 + openM!);
	}

	private formatDate(d: Date): string {
		const year = d.getFullYear();
		const month = String(d.getMonth() + 1).padStart(2, "0");
		const day = String(d.getDate()).padStart(2, "0");
		return `${year}-${month}-${day}`;
	}
}
