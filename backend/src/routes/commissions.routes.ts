import type { FastifyInstance } from 'fastify';
import { z } from 'zod';

// ─── Zod Schemas ───────────────────────────────────────────

export const ListCommissionsQuery = z.object({
  professional_id: z.string().uuid().optional(),
  status: z.enum(['pending', 'paid']).optional(),
  period_start: z.string().date().optional(),
  period_end: z.string().date().optional(),
  cursor: z.string().uuid().optional(),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});

export const PayCommissionsBody = z.object({
  commission_ids: z.array(z.string().uuid()).min(1).max(100),
});

// ─── Route Plugin ──────────────────────────────────────────

export default async function commissionRoutes(app: FastifyInstance) {
  app.addHook('onRequest', app.authenticate);
  app.addHook('onRequest', app.requireOwner);

  // GET /api/v1/commissions
  // Auth: owner
  app.get('/', {
    schema: { querystring: ListCommissionsQuery },
    handler: async (request, reply) => {
      // → CommissionController.list
      throw new Error('Not implemented');
    },
  });

  // POST /api/v1/commissions/pay
  // Auth: owner
  app.post('/pay', {
    schema: { body: PayCommissionsBody },
    handler: async (request, reply) => {
      // → CommissionController.pay
      throw new Error('Not implemented');
    },
  });
}

export const autoPrefix = '/api/v1/commissions';
