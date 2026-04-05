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

// ─── Repository ────────────────────────────────────────────────────────────

export class PaymentRepository {
  constructor(private pool: Pool) {}

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
