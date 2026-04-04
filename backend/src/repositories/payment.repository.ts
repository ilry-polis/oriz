import type { Pool } from 'pg';

// ─── Types ─────────────────────────────────────────────────────────────────

export type PaymentMethod = 'cash' | 'pix' | 'debit' | 'credit';

export type PaymentRow = {
  id: string;
  studio_id: string;
  appointment_id: string;
  client_id: string;
  amount: number;
  method: PaymentMethod;
  card_fee_percentage: number | null;
  created_at: string;
};

export type CreatePaymentInput = {
  studioId: string;
  appointmentId: string;
  clientId: string;
  amount: number;
  method: PaymentMethod;
  cardFeePercentage?: number;
};

// ─── Repository ────────────────────────────────────────────────────────────

export class PaymentRepository {
  constructor(private pool: Pool) {}

  /**
   * Record a payment for an appointment.
   */
  async create(input: CreatePaymentInput): Promise<PaymentRow> {
    const { rows } = await this.pool.query<PaymentRow>(
      `INSERT INTO payments
         (id, studio_id, appointment_id, client_id, amount, method, card_fee_percentage)
       VALUES
         (gen_random_uuid(), $1, $2, $3, $4, $5, $6)
       RETURNING id, studio_id, appointment_id, client_id, amount, method, card_fee_percentage, created_at`,
      [
        input.studioId,
        input.appointmentId,
        input.clientId,
        input.amount,
        input.method,
        input.cardFeePercentage ?? null,
      ],
    );
    return rows[0]!;
  }
}
