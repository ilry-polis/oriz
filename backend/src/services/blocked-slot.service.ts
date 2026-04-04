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
	 * List blocked slots with optional filters.
	 * Expands recurring slots into virtual entries for each matching day in the range.
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
		const rows = await this.repo.list(studioId, options);

		// If no date range, return raw rows (no expansion possible)
		if (!options.dateFrom || !options.dateTo) {
			return rows;
		}

		const result: BlockedSlotRow[] = [];

		for (const row of rows) {
			if (row.recurrence_rule === null) {
				// Sporadic: return as-is
				result.push(row);
			} else {
				// Normalize excluded_dates (pg may return Date objects)
				const excluded = (row.excluded_dates ?? []).map((d: unknown) =>
					d instanceof Date ? d.toISOString().slice(0, 10) : String(d),
				);

				// Recurring: expand into virtual entries for each matching day
				const dates = expandRecurrenceDates(
					row.recurrence_rule,
					options.dateFrom,
					options.dateTo,
					excluded,
				);

				// Extract time portion from original timestamps
				const startTimePart = extractTime(row.start_time);
				const endTimePart = extractTime(row.end_time);

				for (const date of dates) {
					result.push({
						...row,
						date,
						start_time: `${date}T${startTimePart}`,
						end_time: `${date}T${endTimePart}`,
					});
				}
			}
		}

		// Sort by date + start_time (normalize in case pg returns Date objects)
		result.sort((a, b) => {
			const da = (a.date as unknown) instanceof Date ? (a.date as unknown as Date).toISOString().slice(0, 10) : String(a.date);
			const db = (b.date as unknown) instanceof Date ? (b.date as unknown as Date).toISOString().slice(0, 10) : String(b.date);
			if (da !== db) return da < db ? -1 : 1;
			return String(a.start_time) < String(b.start_time) ? -1 : 1;
		});

		return result;
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
	if (excludedDates.includes(date)) {
		return false;
	}

	if (rule.until !== null && date > rule.until) {
		return false;
	}

	const [year, month, day] = date.split("-").map(Number);
	const d = new Date(Date.UTC(year!, month! - 1, day!));
	const dayOfWeek = d.getUTCDay(); // 0=Sunday, 1=Monday, ..., 6=Saturday

	return rule.days.includes(dayOfWeek);
}

/**
 * Returns all ISO date strings within [dateFrom, dateTo] that match the recurrence rule.
 */
function expandRecurrenceDates(
	rule: RecurrenceRule,
	dateFrom: string,
	dateTo: string,
	excludedDates: string[],
): string[] {
	const results: string[] = [];

	const [fy, fm, fd] = dateFrom.split("-").map(Number);
	const [ty, tm, td] = dateTo.split("-").map(Number);
	const start = new Date(Date.UTC(fy!, fm! - 1, fd!));
	const end = new Date(Date.UTC(ty!, tm! - 1, td!));

	const current = new Date(start);
	while (current <= end) {
		const iso = current.toISOString().slice(0, 10);
		if (isRecurrenceActiveOnDate(rule, iso, excludedDates)) {
			results.push(iso);
		}
		current.setUTCDate(current.getUTCDate() + 1);
	}

	return results;
}

/**
 * Extracts time portion (HH:MM:SS) from a timestamp.
 * pg driver may return a Date object or a string depending on column type.
 */
function extractTime(timestamp: unknown): string {
	if (timestamp instanceof Date) {
		const h = String(timestamp.getHours()).padStart(2, "0");
		const m = String(timestamp.getMinutes()).padStart(2, "0");
		const s = String(timestamp.getSeconds()).padStart(2, "0");
		return `${h}:${m}:${s}`;
	}
	const str = String(timestamp);
	const tIndex = str.indexOf("T");
	if (tIndex !== -1) {
		return str.slice(tIndex + 1);
	}
	const spaceIndex = str.indexOf(" ");
	if (spaceIndex !== -1) {
		return str.slice(spaceIndex + 1);
	}
	return str;
}
