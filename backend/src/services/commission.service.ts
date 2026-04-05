import type { CommissionRepository, CommissionFilters, CommissionRow, CommissionSummaryByProfessional } from '../repositories/commission.repository.js';
import type { ProfessionalRepository } from '../repositories/professional.repository.js';
import type { StudioRepository } from '../repositories/studio.repository.js';
import type { PaymentMethod } from '../repositories/payment.repository.js';
import { NotFoundError } from '../utils/errors.js';

// ─── Types ─────────────────────────────────────────────────────────────────

export type CalculateCommissionInput = {
  studioId: string;
  professionalId: string;
  appointmentId: string;
  amount: number;       // total payment amount in centavos
  method: PaymentMethod;
  date: string;         // ISO date string YYYY-MM-DD
};

type PeriodBoundaries = {
  periodStart: string;
  periodEnd: string;
};

// ─── Service ───────────────────────────────────────────────────────────────

export class CommissionService {
  constructor(
    private commissionRepo: CommissionRepository,
    private professionalRepo: ProfessionalRepository,
    private studioRepo: StudioRepository,
  ) {}

  /**
   * Calculate commission based on professional config and studio settings,
   * then persist the commission row.
   *
   * Logic:
   * 1. Fetch professional (commission_type, commission_value, card_fee_policy)
   * 2. Fetch studio settings (card_fee_rates, commission_period)
   * 3. Compute card fee based on payment method (cash/pix = 0)
   * 4. Apply fee policy to determine professional's commission base
   * 5. Calculate professional_amount (percentage or fixed)
   * 6. Determine period boundaries
   * 7. Persist commission row
   *
   * All amounts in centavos. Math.round applied only at final step.
   */
  async calculateAndRecord(input: CalculateCommissionInput): Promise<CommissionRow> {
    const professional = await this.professionalRepo.getById(input.studioId, input.professionalId);
    if (!professional) {
      throw new NotFoundError(`Professional ${input.professionalId} not found`);
    }

    const studio = await this.studioRepo.findById(input.studioId);
    if (!studio) {
      throw new NotFoundError(`Studio ${input.studioId} not found`);
    }

    const settings = studio.settings as {
      commission_period?: 'monthly' | 'biweekly';
      card_fee_rates?: { credit: number; debit: number }; // basis points
    };

    const cardFeeRates = settings.card_fee_rates ?? { credit: 0, debit: 0 };
    const commissionPeriod = settings.commission_period ?? 'monthly';

    // ── Step 1: Compute card fee ──────────────────────────────────────────
    let cardFeeRateBps = 0;
    if (input.method === 'credit') {
      cardFeeRateBps = cardFeeRates.credit ?? 0;
    } else if (input.method === 'debit') {
      cardFeeRateBps = cardFeeRates.debit ?? 0;
    }
    // cash and pix: 0 fee

    const cardFeeAmount = Math.round((input.amount * cardFeeRateBps) / 10000);

    // ── Step 2: Apply fee policy ──────────────────────────────────────────
    let professionalFeeShare = 0;
    let whoPaidFee: 'studio' | 'professional' | 'split' | 'none' = 'none';

    if (cardFeeAmount === 0) {
      whoPaidFee = 'none';
      professionalFeeShare = 0;
    } else if (professional.card_fee_policy === 'professional') {
      whoPaidFee = 'professional';
      professionalFeeShare = cardFeeAmount;
    } else if (professional.card_fee_policy === 'studio') {
      whoPaidFee = 'studio';
      professionalFeeShare = 0;
    } else if (professional.card_fee_policy === 'split') {
      whoPaidFee = 'split';
      professionalFeeShare = Math.round(cardFeeAmount / 2);
    }

    // ── Step 3: Calculate professional amount ─────────────────────────────
    const commissionBase = input.amount - professionalFeeShare;
    let professionalAmount: number;

    if (professional.commission_type === 'percentage') {
      // commission_value is in basis points (e.g., 4000 = 40.00%)
      professionalAmount = Math.round((commissionBase * professional.commission_value) / 10000);
    } else {
      // fixed: flat amount regardless of payment
      professionalAmount = professional.commission_value;
    }

    const studioAmount = input.amount - professionalAmount - cardFeeAmount + (cardFeeAmount - professionalFeeShare);

    // ── Step 4: Period boundaries ─────────────────────────────────────────
    const { periodStart, periodEnd } = this.getPeriodBoundaries(input.date, commissionPeriod);

    // ── Step 5: Persist ───────────────────────────────────────────────────
    return this.commissionRepo.create({
      studioId: input.studioId,
      professionalId: input.professionalId,
      appointmentId: input.appointmentId,
      amount: input.amount,
      studioAmount,
      professionalAmount,
      cardFeeAmount,
      whoPaidFee,
      periodStart,
      periodEnd,
    });
  }

  /**
   * Compute period boundaries given a date and period type.
   * monthly: 1st to last day of the month
   * biweekly: 1-15 (1st half) or 16-end (2nd half)
   */
  getPeriodBoundaries(date: string, periodType: 'monthly' | 'biweekly'): PeriodBoundaries {
    const [year, month, day] = date.split('-').map(Number);
    const lastDay = new Date(year!, month!, 0).getDate(); // last day of month

    if (periodType === 'monthly') {
      const start = `${year}-${String(month).padStart(2, '0')}-01`;
      const end = `${year}-${String(month).padStart(2, '0')}-${String(lastDay).padStart(2, '0')}`;
      return { periodStart: start, periodEnd: end };
    }

    // biweekly
    const mm = String(month).padStart(2, '0');
    if (day! <= 15) {
      return {
        periodStart: `${year}-${mm}-01`,
        periodEnd: `${year}-${mm}-15`,
      };
    }
    return {
      periodStart: `${year}-${mm}-16`,
      periodEnd: `${year}-${mm}-${String(lastDay).padStart(2, '0')}`,
    };
  }

  async list(studioId: string, filters: CommissionFilters): Promise<CommissionRow[]> {
    return this.commissionRepo.list(studioId, filters);
  }

  async markPaid(studioId: string, commissionIds: string[]): Promise<number> {
    return this.commissionRepo.markPaid(studioId, commissionIds);
  }

  async sumByProfessional(
    studioId: string,
    periodStart: string,
    periodEnd: string,
  ): Promise<CommissionSummaryByProfessional[]> {
    return this.commissionRepo.sumByProfessional(studioId, periodStart, periodEnd);
  }
}
