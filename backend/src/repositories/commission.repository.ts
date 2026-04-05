import type { Pool } from 'pg';

// ─── Types ─────────────────────────────────────────────────────────────────

export type CommissionStatus = 'pending' | 'paid';

export type CommissionRow = {
  id: string;
  studio_id: string;
  professional_id: string;
  appointment_id: string;
  amount: number;            // total payment amount in centavos
  studio_amount: number;     // studio share in centavos
  professional_amount: number; // professional share in centavos
  card_fee_amount: number;   // card fee in centavos
  who_paid_fee: 'studio' | 'professional' | 'split' | 'none';
  period_start: string;      // DATE string YYYY-MM-DD
  period_end: string;        // DATE string YYYY-MM-DD
  status: CommissionStatus;
  paid_at: string | null;
  created_at: string;
  updated_at: string;
  // joined fields
  professional_name?: string;
};

export type CreateCommissionInput = {
  studioId: string;
  professionalId: string;
  appointmentId: string;
  amount: number;
  studioAmount: number;
  professionalAmount: number;
  cardFeeAmount: number;
  whoPaidFee: 'studio' | 'professional' | 'split' | 'none';
  periodStart: string;
  periodEnd: string;
};

export type CommissionFilters = {
  professionalId?: string;
  status?: CommissionStatus;
  periodStart?: string;
  periodEnd?: string;
  cursor?: string;
  limit?: number;
};

export type CommissionSummaryByProfessional = {
  professional_id: string;
  professional_name: string;
  total_amount: number;
  commission_count: number;
};

// ─── Repository ────────────────────────────────────────────────────────────

export class CommissionRepository {
  constructor(private pool: Pool) {}

  /**
   * Insert a new commission row.
   * All amounts in centavos. studio_id filter enforced.
   */
  async create(input: CreateCommissionInput): Promise<CommissionRow> {
    const { rows } = await this.pool.query<CommissionRow>(
      `INSERT INTO commissions
         (id, studio_id, professional_id, appointment_id, amount, studio_amount,
          professional_amount, card_fee_amount, who_paid_fee, period_start, period_end,
          status)
       VALUES
         (gen_random_uuid(), $1, $2, $3, $4, $5, $6, $7, $8, $9, $10, 'pending')
       RETURNING id, studio_id, professional_id, appointment_id, amount, studio_amount,
                 professional_amount, card_fee_amount, who_paid_fee, period_start, period_end,
                 status, paid_at, created_at, updated_at`,
      [
        input.studioId,
        input.professionalId,
        input.appointmentId,
        input.amount,
        input.studioAmount,
        input.professionalAmount,
        input.cardFeeAmount,
        input.whoPaidFee,
        input.periodStart,
        input.periodEnd,
      ],
    );
    return rows[0]!;
  }

  /**
   * Cursor-based paginated list of commissions for a studio.
   * Cursor is the last commission id from the previous page.
   * Returns limit+1 so caller can detect has_more.
   */
  async list(studioId: string, filters: CommissionFilters): Promise<CommissionRow[]> {
    const { professionalId, status, periodStart, periodEnd, cursor, limit = 20 } = filters;
    const params: unknown[] = [studioId];
    let idx = 2;

    let sql = `
      SELECT c.id, c.studio_id, c.professional_id, c.appointment_id,
             c.amount, c.studio_amount, c.professional_amount, c.card_fee_amount,
             c.who_paid_fee, c.period_start, c.period_end, c.status, c.paid_at,
             c.created_at, c.updated_at,
             p.name AS professional_name
      FROM commissions c
      JOIN professionals p ON p.id = c.professional_id
      WHERE c.studio_id = $1
    `;

    if (professionalId) {
      sql += ` AND c.professional_id = $${idx++}`;
      params.push(professionalId);
    }

    if (status) {
      sql += ` AND c.status = $${idx++}`;
      params.push(status);
    }

    if (periodStart) {
      sql += ` AND c.period_start >= $${idx++}`;
      params.push(periodStart);
    }

    if (periodEnd) {
      sql += ` AND c.period_end <= $${idx++}`;
      params.push(periodEnd);
    }

    if (cursor) {
      sql += ` AND c.id > $${idx++}`;
      params.push(cursor);
    }

    sql += ` ORDER BY c.created_at DESC, c.id DESC LIMIT $${idx++}`;
    params.push(limit + 1);

    const { rows } = await this.pool.query<CommissionRow>(sql, params);
    return rows;
  }

  /**
   * Mark a list of commission IDs as paid.
   * Returns count of rows updated.
   * Belt-and-suspenders: only touches commissions belonging to this studio.
   */
  async markPaid(studioId: string, commissionIds: string[]): Promise<number> {
    if (commissionIds.length === 0) return 0;

    const { rowCount } = await this.pool.query(
      `UPDATE commissions
       SET status = 'paid', paid_at = now(), updated_at = now()
       WHERE id = ANY($2)
         AND studio_id = $1
         AND status = 'pending'`,
      [studioId, commissionIds],
    );
    return rowCount ?? 0;
  }

  /**
   * Aggregated commission totals grouped by professional for a time period.
   */
  async sumByProfessional(
    studioId: string,
    periodStart: string,
    periodEnd: string,
  ): Promise<CommissionSummaryByProfessional[]> {
    const { rows } = await this.pool.query<CommissionSummaryByProfessional>(
      `SELECT c.professional_id,
              p.name AS professional_name,
              SUM(c.professional_amount)::int AS total_amount,
              COUNT(c.id)::int AS commission_count
       FROM commissions c
       JOIN professionals p ON p.id = c.professional_id
       WHERE c.studio_id = $1
         AND c.period_start >= $2
         AND c.period_end <= $3
       GROUP BY c.professional_id, p.name
       ORDER BY total_amount DESC`,
      [studioId, periodStart, periodEnd],
    );
    return rows;
  }
}
