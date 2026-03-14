import type { FastifyInstance } from 'fastify';
import { z } from 'zod';

// ─── Zod Schemas ───────────────────────────────────────────

export const FinancialSummaryQuery = z.object({
  year: z.coerce.number().int().optional(),
  month: z.coerce.number().int().min(1).max(12).optional(),
}).refine(
  (d) => !(d.month && !d.year),
  { message: 'year is required when month is provided', path: ['year'] },
);

// ─── Route Plugin ──────────────────────────────────────────

export default async function financialRoutes(app: FastifyInstance) {
  app.addHook('onRequest', app.authenticate);
  app.addHook('onRequest', app.requireOwner);

  // GET /api/v1/financial/summary
  // Auth: owner
  // Data from materialized view financial_summaries, refreshed via BullMQ
  app.get('/summary', {
    schema: { querystring: FinancialSummaryQuery },
    handler: async (request, reply) => {
      // → FinancialController.summary
      throw new Error('Not implemented');
    },
  });
}

export const autoPrefix = '/api/v1/financial';
