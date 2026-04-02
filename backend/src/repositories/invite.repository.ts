import type { Pool } from 'pg';

export type InviteRow = {
  token: string;
  studio_id: string;
  created_by: string;
  name: string;
  service_ids: string[];
  commission_type: 'percentage' | 'fixed';
  commission_value: number;
  card_fee_policy: 'studio' | 'professional' | 'split';
  expires_at: Date;
  used_at: Date | null;
  created_at: Date;
};

export type CreateInviteData = {
  token: string;
  studioId: string;
  createdBy: string;
  name: string;
  serviceIds: string[];
  commissionType: 'percentage' | 'fixed';
  commissionValue: number;
  cardFeePolicy: 'studio' | 'professional' | 'split';
  expiresAt: Date;
};

export class InviteRepository {
  constructor(private pool: Pool) {}

  async create(data: CreateInviteData): Promise<void> {
    await this.pool.query(
      `INSERT INTO professional_invites
         (token, studio_id, created_by, name, service_ids, commission_type, commission_value, card_fee_policy, expires_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)`,
      [
        data.token,
        data.studioId,
        data.createdBy,
        data.name,
        data.serviceIds,
        data.commissionType,
        data.commissionValue,
        data.cardFeePolicy,
        data.expiresAt,
      ],
    );
  }

  /**
   * Returns invite row or null.
   * Does NOT filter expired/used here — caller decides policy.
   * Token lookup is done via service_role (bypasses RLS).
   */
  async findByToken(token: string): Promise<InviteRow | null> {
    const { rows } = await this.pool.query<InviteRow>(
      `SELECT token, studio_id, created_by, name, service_ids,
              commission_type, commission_value, card_fee_policy,
              expires_at, used_at, created_at
       FROM professional_invites
       WHERE token = $1
       LIMIT 1`,
      [token],
    );
    return rows[0] ?? null;
  }

  async markUsed(token: string): Promise<void> {
    await this.pool.query(
      `UPDATE professional_invites SET used_at = now() WHERE token = $1`,
      [token],
    );
  }
}
