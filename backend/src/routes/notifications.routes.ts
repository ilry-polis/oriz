import type { FastifyInstance } from 'fastify';
import { z } from 'zod';

// ─── Zod Schemas ───────────────────────────────────────────

export const CreateDeviceTokenBody = z.object({
  token: z.string().min(1),
  platform: z.enum(['android', 'ios']),
});

const UuidParam = z.object({ id: z.string().uuid() });

// ─── Route Plugin ──────────────────────────────────────────

export default async function notificationRoutes(app: FastifyInstance) {
  app.addHook('onRequest', app.authenticate);

  // POST /api/v1/device-tokens
  // Auth: authenticated
  // Upsert by (user_id, token)
  app.post('/', {
    schema: { body: CreateDeviceTokenBody },
    handler: async (_request, _reply) => {
      // → DeviceTokenController.create
      throw new Error('Not implemented');
    },
  });

  // DELETE /api/v1/device-tokens/:id
  // Auth: authenticated
  // Soft delete: marks is_active = false. Uses record ID (not FCM token) in URL.
  app.delete('/:id', {
    schema: { params: UuidParam },
    handler: async (_request, _reply) => {
      // → DeviceTokenController.delete
      throw new Error('Not implemented');
    },
  });
}

export const autoPrefix = '/api/v1/device-tokens';
