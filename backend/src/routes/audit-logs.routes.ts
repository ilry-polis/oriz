import type { FastifyInstance } from 'fastify';
import { z } from 'zod';

// ─── Zod Schemas ───────────────────────────────────────────

export const ListAuditLogsQuery = z.object({
  date_from: z.string().date().optional(),
  date_to: z.string().date().optional(),
  action: z.enum(['view', 'export', 'delete']).optional(),
  entity_type: z.string().optional(),
  cursor: z.string().uuid().optional(),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});

// ─── Route Plugin ──────────────────────────────────────────

export default async function auditLogRoutes(app: FastifyInstance) {
  app.addHook('onRequest', app.authenticate);
  app.addHook('onRequest', app.requireOwner);

  // GET /api/v1/audit-logs
  // Auth: owner
  app.get('/', {
    schema: { querystring: ListAuditLogsQuery },
    handler: async (_request, _reply) => {
      // → AuditLogController.list
      throw new Error('Not implemented');
    },
  });
}

export const autoPrefix = '/api/v1/audit-logs';
