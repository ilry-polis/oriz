import type { Pool } from 'pg';

// ─── Types ───────────────────────────────────────────────────

export type ConsentType = 'marketing_whatsapp' | 'marketing_push';
export type ConsentAction = 'granted' | 'revoked';

export type ConsentRecord = {
  id: string;
  client_id: string;
  studio_id: string;
  type: ConsentType;
  action: ConsentAction;
  created_at: string;
};

export type InsertConsentInput = {
  clientId: string;
  studioId: string;
  type: ConsentType;
  action: ConsentAction;
};

// ─── Repository ──────────────────────────────────────────────

export class ConsentRepository {
  constructor(private pool: Pool) {}

  /**
   * Append-only insert — never update consent records.
   * Each grant/revoke creates a new row.
   */
  async insert(input: InsertConsentInput): Promise<void> {
    await this.pool.query(
      `INSERT INTO consent_records (id, client_id, studio_id, type, action)
       VALUES (gen_random_uuid(), $1, $2, $3, $4)`,
      [input.clientId, input.studioId, input.type, input.action],
    );
  }

  /**
   * Returns the latest consent action for the given client/studio/type,
   * or null if no records exist.
   */
  async getCurrentConsent(
    clientId: string,
    studioId: string,
    type: ConsentType,
  ): Promise<ConsentAction | null> {
    const { rows } = await this.pool.query<{ action: ConsentAction }>(
      `SELECT action
       FROM consent_records
       WHERE client_id = $1 AND studio_id = $2 AND type = $3
       ORDER BY created_at DESC
       LIMIT 1`,
      [clientId, studioId, type],
    );
    return rows[0]?.action ?? null;
  }

  /**
   * Returns all consent records for a client/studio, ordered by most recent first.
   */
  async listByClient(
    clientId: string,
    studioId: string,
  ): Promise<ConsentRecord[]> {
    const { rows } = await this.pool.query<ConsentRecord>(
      `SELECT id, client_id, studio_id, type, action, created_at
       FROM consent_records
       WHERE client_id = $1 AND studio_id = $2
       ORDER BY created_at DESC`,
      [clientId, studioId],
    );
    return rows;
  }
}
