import type { Pool } from 'pg';

// ─── Types ───────────────────────────────────────────────────

export type AuditAction = 'view' | 'edit' | 'export' | 'delete';

export type AuditLogRow = {
  id: string;
  studio_id: string;
  user_id: string;
  action: AuditAction;
  entity_type: string;
  entity_id: string;
  ip: string | null;
  created_at: string;
};

export type InsertAuditLogInput = {
  studioId: string;
  userId: string;
  action: AuditAction;
  entityType: string;
  entityId: string;
  ip?: string | null;
};

export type ListAuditLogsOptions = {
  studioId: string;
  cursor?: string;
  limit: number;
  dateFrom?: string;
  dateTo?: string;
  action?: AuditAction;
  entityType?: string;
};

// ─── Repository ──────────────────────────────────────────────

export class AuditLogRepository {
  constructor(private pool: Pool) {}

  async insert(input: InsertAuditLogInput): Promise<void> {
    await this.pool.query(
      `INSERT INTO audit_logs (id, studio_id, user_id, action, entity_type, entity_id, ip)
       VALUES (gen_random_uuid(), $1, $2, $3, $4, $5, $6)`,
      [
        input.studioId,
        input.userId,
        input.action,
        input.entityType,
        input.entityId,
        input.ip ?? null,
      ],
    );
  }

  async list(opts: ListAuditLogsOptions): Promise<{
    rows: AuditLogRow[];
    has_more: boolean;
    next_cursor: string | null;
  }> {
    const params: unknown[] = [opts.studioId];
    const conditions: string[] = ['al.studio_id = $1'];

    if (opts.cursor) {
      params.push(opts.cursor);
      conditions.push(`al.id < $${params.length}`);
    }

    if (opts.dateFrom) {
      params.push(opts.dateFrom);
      conditions.push(`al.created_at >= $${params.length}::date`);
    }

    if (opts.dateTo) {
      params.push(opts.dateTo);
      conditions.push(`al.created_at < ($${params.length}::date + INTERVAL '1 day')`);
    }

    if (opts.action) {
      params.push(opts.action);
      conditions.push(`al.action = $${params.length}`);
    }

    if (opts.entityType) {
      params.push(opts.entityType);
      conditions.push(`al.entity_type = $${params.length}`);
    }

    const fetchLimit = opts.limit + 1;
    params.push(fetchLimit);

    const where = conditions.join(' AND ');
    const { rows } = await this.pool.query<AuditLogRow>(
      `SELECT al.id, al.studio_id, al.user_id, al.action, al.entity_type,
              al.entity_id, al.ip, al.created_at
       FROM audit_logs al
       WHERE ${where}
       ORDER BY al.created_at DESC, al.id DESC
       LIMIT $${params.length}`,
      params,
    );

    const has_more = rows.length > opts.limit;
    const data = rows.slice(0, opts.limit);
    const next_cursor = has_more ? data[data.length - 1]!.id : null;

    return { rows: data, has_more, next_cursor };
  }
}
