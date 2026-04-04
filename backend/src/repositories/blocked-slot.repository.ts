import type { Pool } from "pg";

// ─── Types ─────────────────────────────────────────────────────────────────

export interface RecurrenceRule {
	frequency: "weekly";
	/** Day-of-week numbers: 0=Sunday, 1=Monday, …, 6=Saturday */
	days: number[];
	/** ISO date string or null (no end date) */
	until: string | null;
}

export type BlockedSlotRow = {
	id: string;
	studio_id: string;
	professional_id: string;
	date: string;
	start_time: string;
	end_time: string;
	title: string;
	reason: string | null;
	recurrence_rule: RecurrenceRule | null;
	excluded_dates: string[];
	created_at: string;
};

export type CreateBlockedSlotInput = {
	studioId: string;
	professionalId: string;
	date: string;
	startTime: string;
	endTime: string;
	title: string;
	reason?: string;
	recurrenceRule?: RecurrenceRule;
	excludedDates?: string[];
};

// ─── Columns (SELECT fragment) ─────────────────────────────────────────────

const BLOCKED_SLOT_COLUMNS = `
  bs.id,
  bs.studio_id,
  bs.professional_id,
  bs.date,
  bs.start_time,
  bs.end_time,
  bs.title,
  bs.reason,
  bs.recurrence_rule,
  bs.excluded_dates,
  bs.created_at
`.trim();

// ─── Repository ────────────────────────────────────────────────────────────

export class BlockedSlotRepository {
	constructor(private pool: Pool) {}

	/**
	 * List blocked slots for a date range.
	 * Returns:
	 *   - Sporadic slots: date falls within [dateFrom, dateTo]
	 *   - Recurring slots: recurrence_rule IS NOT NULL (consumer expands recurrence)
	 *
	 * No pagination — query is bounded by date range + professional.
	 */
	async listByDateRange(
		studioId: string,
		professionalId: string,
		dateFrom: string,
		dateTo: string,
	): Promise<BlockedSlotRow[]> {
		const { rows } = await this.pool.query<BlockedSlotRow>(
			`SELECT ${BLOCKED_SLOT_COLUMNS}
       FROM blocked_slots bs
       WHERE bs.studio_id = $1
         AND bs.professional_id = $2
         AND (
           -- Sporadic: specific date in range
           (bs.recurrence_rule IS NULL AND bs.date >= $3 AND bs.date <= $4)
           OR
           -- Recurring: always return (consumer expands and filters by date range)
           bs.recurrence_rule IS NOT NULL
         )
       ORDER BY bs.date ASC, bs.start_time ASC`,
			[studioId, professionalId, dateFrom, dateTo],
		);
		return rows;
	}

	/**
	 * List blocked slots for a studio with optional filters.
	 * Used by the list endpoint (not for slot-availability computation).
	 * Returns both sporadic and recurring slots. Cursor pagination by (date, id).
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
		const { professionalId, dateFrom, dateTo, cursor, limit = 20 } = options;
		const params: unknown[] = [studioId];
		const conditions: string[] = ["bs.studio_id = $1"];

		if (professionalId) {
			params.push(professionalId);
			conditions.push(`bs.professional_id = $${params.length}`);
		}

		if (dateFrom) {
			params.push(dateFrom);
			conditions.push(`bs.date >= $${params.length}`);
		}

		if (dateTo) {
			params.push(dateTo);
			conditions.push(`bs.date <= $${params.length}`);
		}

		if (cursor) {
			params.push(cursor);
			conditions.push(`bs.id > $${params.length}`);
		}

		params.push(limit);
		const limitParam = `$${params.length}`;

		const { rows } = await this.pool.query<BlockedSlotRow>(
			`SELECT ${BLOCKED_SLOT_COLUMNS}
       FROM blocked_slots bs
       WHERE ${conditions.join(" AND ")}
       ORDER BY bs.date ASC, bs.id ASC
       LIMIT ${limitParam}`,
			params,
		);
		return rows;
	}

	/**
	 * Create a blocked slot (sporadic or recurring).
	 */
	async create(input: CreateBlockedSlotInput): Promise<BlockedSlotRow> {
		const { rows } = await this.pool.query<BlockedSlotRow>(
			`INSERT INTO blocked_slots
         (id, studio_id, professional_id, date, start_time, end_time,
          title, reason, recurrence_rule, excluded_dates)
       VALUES
         (gen_random_uuid(), $1, $2, $3,
          ($3::date || ' ' || $4::text)::timestamptz,
          ($3::date || ' ' || $5::text)::timestamptz,
          $6, $7, $8, $9)
       RETURNING ${BLOCKED_SLOT_COLUMNS.replace(/bs\./g, "")}`,
			[
				input.studioId,
				input.professionalId,
				input.date,
				input.startTime,
				input.endTime,
				input.title,
				input.reason ?? null,
				input.recurrenceRule ? JSON.stringify(input.recurrenceRule) : null,
				input.excludedDates ?? [],
			],
		);
		return rows[0]!;
	}

	/**
	 * Hard delete a blocked slot.
	 */
	async delete(studioId: string, blockedSlotId: string): Promise<boolean> {
		const { rowCount } = await this.pool.query(
			`DELETE FROM blocked_slots
       WHERE studio_id = $1 AND id = $2`,
			[studioId, blockedSlotId],
		);
		return (rowCount ?? 0) > 0;
	}

	/**
	 * Append a date to excluded_dates for a recurring absence.
	 * Used to skip a single occurrence without deleting the whole rule.
	 */
	async addExcludedDate(
		studioId: string,
		blockedSlotId: string,
		date: string,
	): Promise<BlockedSlotRow | null> {
		const { rows } = await this.pool.query<BlockedSlotRow>(
			`UPDATE blocked_slots
       SET excluded_dates = array_append(excluded_dates, $3::date)
       WHERE studio_id = $1 AND id = $2
       RETURNING ${BLOCKED_SLOT_COLUMNS.replace(/bs\./g, "")}`,
			[studioId, blockedSlotId, date],
		);
		return rows[0] ?? null;
	}
}
