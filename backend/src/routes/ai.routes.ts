import type { FastifyInstance } from 'fastify';
import { z } from 'zod';

// ─── Zod Schemas ───────────────────────────────────────────

export const UpdateAIConfigBody = z.object({
  tone_of_voice: z.string().optional(),
  greeting_message: z.string().optional(),
  fallback_message: z.string().optional(),
  enabled: z.boolean().optional(),
  scheduling_rules: z.object({
    max_advance_days: z.number().int().optional(),
    min_advance_hours: z.number().int().optional(),
    auto_confirm: z.boolean().optional(),
  }).optional(),
});

// ─── Route Plugin ──────────────────────────────────────────

export default async function aiRoutes(app: FastifyInstance) {
  app.addHook('onRequest', app.authenticate);
  app.addHook('onRequest', app.requireOwner);

  // GET /api/v1/ai/config
  // Auth: owner
  app.get('/config', {
    handler: async (request, reply) => {
      // → AIConfigController.get
      throw new Error('Not implemented');
    },
  });

  // PATCH /api/v1/ai/config
  // Auth: owner
  app.patch('/config', {
    schema: { body: UpdateAIConfigBody },
    handler: async (request, reply) => {
      // → AIConfigController.update
      throw new Error('Not implemented');
    },
  });
}

export const autoPrefix = '/api/v1/ai';
