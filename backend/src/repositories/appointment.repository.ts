import type { Pool } from 'pg';
import { ConflictError } from '../utils/errors.js';

// ─── Types ─────────────────────────────────────────────────────────────────

export type AppointmentStatus = 'pending' | 'confirmed' | 'completed' | 'cancelled' | 'no_show';
export type AppointmentSource = 'app' | 'manual' | 'web_page' | 'whatsapp_ai';

export type AppointmentRow = {
  id: string;
  studio_id: string;
  client_id: string;
  professional_id: string;
  service_id: string;
  date: string;
  start_time: string;
  end_time: string;
  status: AppointmentStatus;
  source: AppointmentSource;
  notes: string | null;
  cancellation_reason: string | null;
  created_at: string;
  updated_at: string;
  // Joined fields
  client_name: string;
  client_phone: string | null;
  professional_name: string;
  service_name: string;
  duration_minutes: number;
  price: number;
  buffer_minutes: number;
};

export type CreateAppointmentInput = {
  studioId: string;
  clientId: string;
  professionalId: string;
  serviceId: string;
  date: string;
  startTime: string;
  endTime: string;
  notes?: string;
  source: AppointmentSource;
};

export type UpdateAppointmentFields = {
  professional_id?: string;
  service_id?: string;
  date?: string;
  start_time?: string;
  end_time?: string;
  notes?: string;
};

// ─── Columns (SELECT fragment) ─────────────────────────────────────────────

const APPOINTMENT_COLUMNS = `
  a.id,
  a.studio_id,
  a.client_id,
  a.professional_id,
  a.service_id,
  a.date,
  a.start_time,
  a.end_time,
  a.status,
  a.source,
  a.notes,
  a.cancellation_reason,
  a.created_at,
  a.updated_at,
  c.name  AS client_name,
  c.phone AS client_phone,
  p.name  AS professional_name,
  s.name  AS service_name,
  s.duration_minutes,
  s.price,
  s.buffer_minutes
`.trim();

const APPOINTMENT_JOINS = `
  JOIN clients      c ON c.id = a.client_id
  JOIN professionals p ON p.id = a.professional_id
  JOIN services     s ON s.id = a.service_id
`.trim();

// ─── Repository ────────────────────────────────────────────────────────────

export class AppointmentRepository {
  constructor(private pool: Pool) {}

  /**
   * List appointments for a specific date with optional filters.
   * Cursor-based pagination: cursor is the id of the last seen appointment.
   */
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
    const { professionalId, status, cursor, limit = 20 } = options;

    const params: unknown[] = [studioId, date];
    const conditions: string[] = ['a.studio_id = $1', 'a.date = $2'];
    let idx = 3;

    if (professionalId) { conditions.push(`a.professional_id = $${idx++}`); params.push(professionalId); }
    if (status)         { conditions.push(`a.status = $${idx++}`);          params.push(status); }
    if (cursor) {
      conditions.push(
        `(a.start_time, a.id) > (SELECT start_time, id FROM appointments WHERE id = $${idx++} AND studio_id = $1)`,
      );
      params.push(cursor);
    }
    params.push(limit);

    const { rows } = await this.pool.query<AppointmentRow>(
      `SELECT ${APPOINTMENT_COLUMNS}
       FROM appointments a
       ${APPOINTMENT_JOINS}
       WHERE ${conditions.join(' AND ')}
       ORDER BY a.start_time ASC, a.id ASC
       LIMIT $${params.length}`,
      params,
    );
    return rows;
  }

  /**
   * List appointments across a date range with optional filters.
   */
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
    const { professionalId, status, cursor, limit = 20 } = options;

    const params: unknown[] = [studioId, dateFrom, dateTo];
    let idx = 4;

    const extra: string[] = [];
    if (professionalId) { extra.push(`a.professional_id = $${idx++}`); params.push(professionalId); }
    if (status)         { extra.push(`a.status = $${idx++}`);          params.push(status); }
    if (cursor) {
      extra.push(
        `(a.date, a.start_time, a.id) > (SELECT date, start_time, id FROM appointments WHERE id = $${idx++} AND studio_id = $1)`,
      );
      params.push(cursor);
    }
    params.push(limit);

    const where = [
      'a.studio_id = $1',
      'a.date >= $2',
      'a.date <= $3',
      ...extra,
    ].join(' AND ');

    const { rows } = await this.pool.query<AppointmentRow>(
      `SELECT ${APPOINTMENT_COLUMNS}
       FROM appointments a
       ${APPOINTMENT_JOINS}
       WHERE ${where}
       ORDER BY a.date ASC, a.start_time ASC, a.id ASC
       LIMIT $${params.length}`,
      params,
    );
    return rows;
  }

  /**
   * Returns non-cancelled, non-no_show appointments for a professional on a date.
   * Used by slot availability calculation — day-bounded, no pagination needed.
   */
  async listByProfessionalDate(
    studioId: string,
    professionalId: string,
    date: string,
  ): Promise<AppointmentRow[]> {
    const { rows } = await this.pool.query<AppointmentRow>(
      `SELECT ${APPOINTMENT_COLUMNS}
       FROM appointments a
       ${APPOINTMENT_JOINS}
       WHERE a.studio_id = $1
         AND a.professional_id = $2
         AND a.date = $3
         AND a.status NOT IN ('cancelled', 'no_show')
       ORDER BY a.start_time ASC`,
      [studioId, professionalId, date],
    );
    return rows;
  }

  /**
   * Get single appointment with joined fields.
   */
  async getById(studioId: string, appointmentId: string): Promise<AppointmentRow | null> {
    const { rows } = await this.pool.query<AppointmentRow>(
      `SELECT ${APPOINTMENT_COLUMNS}
       FROM appointments a
       ${APPOINTMENT_JOINS}
       WHERE a.studio_id = $1 AND a.id = $2
       LIMIT 1`,
      [studioId, appointmentId],
    );
    return rows[0] ?? null;
  }

  /**
   * Create appointment. Throws ConflictError on time slot overlap (exclusion constraint violation).
   */
  async create(input: CreateAppointmentInput): Promise<AppointmentRow> {
    try {
      const { rows } = await this.pool.query<AppointmentRow>(
        `WITH inserted AS (
          INSERT INTO appointments
            (id, studio_id, client_id, professional_id, service_id, date,
             start_time, end_time, notes, source)
          VALUES
            (gen_random_uuid(), $1, $2, $3, $4, $5,
             ($5::date || ' ' || $6::text)::timestamptz,
             ($5::date || ' ' || $7::text)::timestamptz,
             $8, $9)
          RETURNING *
        )
        SELECT ${APPOINTMENT_COLUMNS}
        FROM inserted a
        ${APPOINTMENT_JOINS}`,
        [
          input.studioId,
          input.clientId,
          input.professionalId,
          input.serviceId,
          input.date,
          input.startTime,
          input.endTime,
          input.notes ?? null,
          input.source,
        ],
      );
      return rows[0]!;
    } catch (err: unknown) {
      // PostgreSQL exclusion constraint violation: error code 23P01
      if (isPostgresError(err) && err.code === '23P01') {
        throw new ConflictError('TIME_SLOT_TAKEN', 'This time slot is already booked');
      }
      throw err;
    }
  }

  /**
   * Update appointment status (and optionally cancellation reason).
   */
  async updateStatus(
    studioId: string,
    appointmentId: string,
    status: AppointmentStatus,
    cancellationReason?: string,
  ): Promise<AppointmentRow | null> {
    const { rows } = await this.pool.query<AppointmentRow>(
      `WITH updated AS (
        UPDATE appointments
        SET status = $3,
            cancellation_reason = COALESCE($4, cancellation_reason),
            updated_at = now()
        WHERE studio_id = $1 AND id = $2
        RETURNING *
      )
      SELECT ${APPOINTMENT_COLUMNS}
      FROM updated a
      ${APPOINTMENT_JOINS}`,
      [studioId, appointmentId, status, cancellationReason ?? null],
    );
    return rows[0] ?? null;
  }

  /**
   * Partial update for rescheduling (professional, service, date, start/end time, notes).
   * Throws ConflictError on overlap if new time slot is taken.
   */
  async update(
    studioId: string,
    appointmentId: string,
    fields: UpdateAppointmentFields,
  ): Promise<AppointmentRow | null> {
    const allowed: Array<keyof UpdateAppointmentFields> = [
      'professional_id',
      'service_id',
      'date',
      'start_time',
      'end_time',
      'notes',
    ];

    const setClauses: string[] = [];
    const params: unknown[] = [studioId, appointmentId];
    let idx = 3;

    for (const key of allowed) {
      if (fields[key] !== undefined) {
        setClauses.push(`${key} = $${idx++}`);
        params.push(fields[key] ?? null);
      }
    }

    if (setClauses.length === 0) return this.getById(studioId, appointmentId);

    setClauses.push('updated_at = now()');

    try {
      const { rows } = await this.pool.query<AppointmentRow>(
        `WITH updated AS (
          UPDATE appointments
          SET ${setClauses.join(', ')}
          WHERE studio_id = $1 AND id = $2
          RETURNING *
        )
        SELECT ${APPOINTMENT_COLUMNS}
        FROM updated a
        ${APPOINTMENT_JOINS}`,
        params,
      );
      return rows[0] ?? null;
    } catch (err: unknown) {
      if (isPostgresError(err) && err.code === '23P01') {
        throw new ConflictError('TIME_SLOT_TAKEN', 'This time slot is already booked');
      }
      throw err;
    }
  }
}

// ─── Helpers ───────────────────────────────────────────────────────────────

interface PostgresError extends Error {
  code: string;
}

function isPostgresError(err: unknown): err is PostgresError {
  return err instanceof Error && 'code' in err;
}
