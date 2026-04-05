import type { Pool } from 'pg';

// ─── Types ─────────────────────────────────────────────────────────────────

export type PaymentMethod = 'cash' | 'pix' | 'debit' | 'credit';
export type PaymentType = 'avulso' | 'pacote';

export type PaymentRow = {
  id: string;
  studio_id: string;
  appointment_id: string | null;
  client_id: string;
  amount: number;
  method: PaymentMethod;
  type: PaymentType;
  discount_amount: number;
  discount_reason: string | null;
  card_fee_percentage: number | null;
  created_at: string;
};

export type CreatePaymentInput = {
  studioId: string;
  appointmentId: string | null;
  clientId: string;
  amount: number;
  method: PaymentMethod;
  type?: PaymentType;
  discountAmount?: number;
  discountReason?: string;
  cardFeePercentage?: number;
};

export type PaymentListRow = PaymentRow & {
  client_name: string;
  professional_id: string | null;
  professional_name: string | null;
  service_name: string | null;
  appointment_date: string | null;
};

export type ListPaymentsFilters = {
  dateFrom?: string;
  dateTo?: string;
  method?: PaymentMethod;
  professionalId?: string;
  cursor?: string;
  limit?: number;
};

// ─── Repository ────────────────────────────────────────────────────────────

export class PaymentRepository {
  constructor(private pool: Pool) {}

  /**
   * Paginated list of payments with JOIN to appointments, clients, professionals.
   * Cursor is the last payment id from previous page.
   * Returns limit+1 rows so caller can detect has_more.
   */
  async list(studioId: string, filters: ListPaymentsFilters): Promise<PaymentListRow[]> {
    const { dateFrom, dateTo, method, professionalId, cursor, limit = 20 } = filters;
    const params: unknown[] = [studioId];
    let idx = 2;

    let sql = `
      SELECT p.id, p.studio_id, p.appointment_id, p.client_id, p.amount, p.method,
             p.type, p.discount_amount, p.discount_reason, p.card_fee_percentage,
             p.created_at,
             c.name AS client_name,
             a.professional_id,
             pr.name AS professional_name,
             s.name AS service_name,
             a.date AS appointment_date
      FROM payments p
      JOIN clients c ON c.id = p.client_id
      LEFT JOIN appointments a ON a.id = p.appointment_id
      LEFT JOIN professionals pr ON pr.id = a.professional_id
      LEFT JOIN services s ON s.id = a.service_id
      WHERE p.studio_id = $1
    `;

    if (dateFrom) {
      sql += ` AND p.created_at >= $${idx++}`;
      params.push(dateFrom);
    }

    if (dateTo) {
      // Include full day
      sql += ` AND p.created_at < ($${idx++}::date + interval '1 day')`;
      params.push(dateTo);
    }

    if (method) {
      sql += ` AND p.method = $${idx++}`;
      params.push(method);
    }

    if (professionalId) {
      sql += ` AND a.professional_id = $${idx++}`;
      params.push(professionalId);
    }

    if (cursor) {
      sql += ` AND p.id > $${idx++}`;
      params.push(cursor);
    }

    sql += ` ORDER BY p.created_at DESC, p.id DESC LIMIT $${idx++}`;
    params.push(limit + 1);

    const { rows } = await this.pool.query<PaymentListRow>(sql, params);
    return rows;
  }

  /**
   * Record a payment. appointment_id is nullable (package sales have no appointment).
   */
  async create(input: CreatePaymentInput): Promise<PaymentRow> {
    const { rows } = await this.pool.query<PaymentRow>(
      `INSERT INTO payments
         (id, studio_id, appointment_id, client_id, amount, method, type,
          discount_amount, discount_reason, card_fee_percentage)
       VALUES
         (gen_random_uuid(), $1, $2, $3, $4, $5, $6, $7, $8, $9)
       RETURNING
         id, studio_id, appointment_id, client_id, amount, method, type,
         discount_amount, discount_reason, card_fee_percentage, created_at`,
      [
        input.studioId,
        input.appointmentId ?? null,
        input.clientId,
        input.amount,
        input.method,
        input.type ?? 'avulso',
        input.discountAmount ?? 0,
        input.discountReason ?? null,
        input.cardFeePercentage ?? null,
      ],
    );
    return rows[0]!;
  }
}
