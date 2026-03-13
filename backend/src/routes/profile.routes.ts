import type { FastifyInstance } from 'fastify';
import { z } from 'zod';

// ─── Zod Schemas ───────────────────────────────────────────

export const UpdateProfileBody = z.object({
  full_name: z.string().min(1).optional(),
  phone: z.string().optional(),
  avatar_url: z.string().url().optional(),
});

// ─── Route Plugin ──────────────────────────────────────────

export default async function profileRoutes(app: FastifyInstance) {
  // All routes require authentication
  app.addHook('onRequest', app.authenticate);

  // GET /api/v1/profile
  // Auth: authenticated
  app.get('/', {
    handler: async (request, reply) => {
      // → ProfileController.get
      throw new Error('Not implemented');
    },
  });

  // PATCH /api/v1/profile
  // Auth: authenticated
  app.patch('/', {
    schema: { body: UpdateProfileBody },
    handler: async (request, reply) => {
      // → ProfileController.update
      throw new Error('Not implemented');
    },
  });
}

export const autoPrefix = '/api/v1/profile';
