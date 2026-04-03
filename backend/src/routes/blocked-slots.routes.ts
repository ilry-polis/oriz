import type { FastifyInstance } from 'fastify';
import { z } from 'zod';

// ─── Zod Schemas ───────────────────────────────────────────

export const ListBlockedSlotsQuery = z.object({
  professional_id: z.string().uuid().optional(),
  date_from: z.string().date().optional(),
  date_to: z.string().date().optional(),
  cursor: z.string().uuid().optional(),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});

export const RecurrenceRuleSchema = z.object({
  frequency: z.literal('weekly'),
  days: z.array(z.number().int().min(0).max(6)).min(1),
  until: z.string().date().nullable(),
});

export const CreateBlockedSlotBody = z.object({
  professional_id: z.string().uuid(),
  date: z.string().date(),
  start_time: z.string().datetime(),
  end_time: z.string().datetime(),
  title: z.string().min(1).max(200),
  reason: z.string().optional(),
  recurrence_rule: RecurrenceRuleSchema.optional(),
  excluded_dates: z.array(z.string().date()).optional(),
});

const UuidParam = z.object({ id: z.string().uuid() });

// ─── Route Plugin ──────────────────────────────────────────

export default async function blockedSlotRoutes(app: FastifyInstance) {
  app.addHook('onRequest', app.authenticate);

  // GET /api/v1/blocked-slots
  // Auth: owner+professional
  app.get('/', {
    onRequest: [app.requireStudioMember],
    schema: { querystring: ListBlockedSlotsQuery },
    handler: async (_request, _reply) => {
      // → BlockedSlotController.list
      throw new Error('Not implemented');
    },
  });

  // POST /api/v1/blocked-slots
  // Auth: owner+professional
  // Professional can only block own schedule; owner can block any professional
  app.post('/', {
    onRequest: [app.requireStudioMember],
    schema: { body: CreateBlockedSlotBody },
    handler: async (_request, _reply) => {
      // → BlockedSlotController.create
      throw new Error('Not implemented');
    },
  });

  // DELETE /api/v1/blocked-slots/:id
  // Auth: owner+professional
  // Ownership: professional can only delete own blocks; owner can delete any
  app.delete('/:id', {
    onRequest: [app.requireStudioMember],
    schema: { params: UuidParam },
    handler: async (_request, _reply) => {
      // → BlockedSlotController.delete
      throw new Error('Not implemented');
    },
  });
}

export const autoPrefix = '/api/v1/blocked-slots';
