import type {
	BlockedSlotRepository,
	BlockedSlotRow,
	RecurrenceRule,
} from "../repositories/blocked-slot.repository.js";
import { NotFoundError } from "../utils/errors.js";

// ─── Types ─────────────────────────────────────────────────────────────────

export type TimeRange = {
	start_time: string;
	end_time: string;
};

export type CreateBlockedSlotParams = {
	professionalId: string;
	date: string;
	startTime: string;
	endTime: string;
	title: string;
	reason?: string;
	recurrenceRule?: RecurrenceRule;
};

// ─── Service ────────────────────────────────────────────────────────────────

export class BlockedSlotService {
	constructor(private repo: BlockedSlotRepository) {}

	/**
	 * List blocked slots with optional filters. Delegates to repository.
	 * Used by the list API endpoint.
	 */
	async list(
		studioId: string,
		options: {
			professionalId?: string;
			dateFrom?: string;
			dateTo?: string;
			cursor?: string;
			limit?: number;
		} = {},
	): Promise<BlockedSlotRow[]> {
		return this.repo.list(studioId, options);
	}

	/**
	 * Returns all blocked time ranges for a professional on a specific date.
	 * Combines sporadic absences (date matches) and recurring rules (day matches).
	 * Used by AppointmentService for slot availability calculation.
	 */
	async getExpandedForDate(
		studioId: string,
		professionalId: string,
		date: string,
	): Promise<TimeRange[]> {
		const rows = await this.repo.listByDateRange(
			studioId,
			professionalId,
			date,
			date,
		);

		const result: TimeRange[] = [];

		for (const row of rows) {
			if (row.recurrence_rule === null) {
				// Sporadic: only include if date exactly matches
				if (row.date === date) {
					result.push({ start_time: row.start_time, end_time: row.end_time });
				}
			} else {
				// Recurring: check if rule is active on this date
				if (
					isRecurrenceActiveOnDate(
						row.recurrence_rule,
						date,
						row.excluded_dates,
					)
				) {
					result.push({ start_time: row.start_time, end_time: row.end_time });
				}
			}
		}

		return result;
	}

	/**
	 * Create a blocked slot (sporadic or recurring).
	 */
	async create(
		studioId: string,
		params: CreateBlockedSlotParams,
	): Promise<BlockedSlotRow> {
		return this.repo.create({
			studioId,
			professionalId: params.professionalId,
			date: params.date,
			startTime: params.startTime,
			endTime: params.endTime,
			title: params.title,
			reason: params.reason,
			recurrenceRule: params.recurrenceRule,
		});
	}

	/**
	 * Hard delete a blocked slot.
	 * Throws NotFoundError if slot does not exist in this studio.
	 */
	async delete(studioId: string, blockedSlotId: string): Promise<boolean> {
		const deleted = await this.repo.delete(studioId, blockedSlotId);
		if (!deleted) {
			throw new NotFoundError("Blocked slot not found");
		}
		return true;
	}

	/**
	 * Remove a single occurrence of a recurring absence by adding an excluded date.
	 * Returns null if the slot was not found.
	 */
	async removeOccurrence(
		studioId: string,
		blockedSlotId: string,
		date: string,
	): Promise<BlockedSlotRow | null> {
		return this.repo.addExcludedDate(studioId, blockedSlotId, date);
	}
}

// ─── Helpers ───────────────────────────────────────────────────────────────

/**
 * Determines whether a recurrence rule is active on a specific ISO date string.
 */
function isRecurrenceActiveOnDate(
	rule: RecurrenceRule,
	date: string,
	excludedDates: string[],
): boolean {
	// Check excluded dates first
	if (excludedDates.includes(date)) {
		return false;
	}

	// Check until date (if set, date must be <= until)
	if (rule.until !== null && date > rule.until) {
		return false;
	}

	// Check day of week
	// Date string is YYYY-MM-DD; parse it as UTC to avoid timezone offset issues
	const [year, month, day] = date.split("-").map(Number);
	const d = new Date(Date.UTC(year!, month! - 1, day!));
	const dayOfWeek = d.getUTCDay(); // 0=Sunday, 1=Monday, ..., 6=Saturday

	return rule.days.includes(dayOfWeek);
}
