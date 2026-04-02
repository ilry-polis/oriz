import type { AuditLogRepository, AuditAction } from '../repositories/audit-log.repository.js';

export type LogAuditParams = {
  studioId: string;
  userId: string;
  action: AuditAction;
  entityType: string;
  entityId: string;
  ip?: string | null;
};

export class AuditLogService {
  constructor(private repo: AuditLogRepository) {}

  /**
   * Fire-and-forget audit log entry.
   * On failure, logs error but never fails the parent request.
   * LGPD compliance: failures are logged (not silently swallowed).
   */
  async log(params: LogAuditParams, requestLog?: { error: (msg: string, err: unknown) => void }): Promise<void> {
    try {
      await this.repo.insert({
        studioId: params.studioId,
        userId: params.userId,
        action: params.action,
        entityType: params.entityType,
        entityId: params.entityId,
        ip: params.ip,
      });
    } catch (err) {
      // LGPD: never silently swallow audit failures — log them
      if (requestLog) {
        requestLog.error('Audit log failed:', err);
      } else {
        console.error('[AuditLogService] Audit log failed:', err);
      }
    }
  }
}
