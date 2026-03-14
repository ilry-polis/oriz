import type { FastifyInstance } from 'fastify';
import { z } from 'zod';

// ─── Zod Schemas ───────────────────────────────────────────

export const ListCampaignsQuery = z.object({
  type: z.enum(['birthday', 'reactivation', 'custom']).optional(),
  is_active: z.coerce.boolean().optional(),
  cursor: z.string().uuid().optional(),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});

export const CreateCampaignBody = z.object({
  type: z.enum(['birthday', 'reactivation', 'custom']),
  message_template: z.string().min(1).max(4096),
  discount_percentage: z.number().int().min(0).max(100).optional(),
  inactivity_days: z.number().int().min(1).default(60),
  channel: z.enum(['whatsapp', 'push', 'both']),
  is_active: z.boolean().default(true),
});

export const UpdateCampaignBody = z.object({
  message_template: z.string().min(1).max(4096).optional(),
  discount_percentage: z.number().int().min(0).max(100).optional(),
  inactivity_days: z.number().int().min(1).optional(),
  channel: z.enum(['whatsapp', 'push', 'both']).optional(),
  is_active: z.boolean().optional(),
});

export const CampaignMetricsQuery = z.object({
  date_from: z.string().date().optional(),
  date_to: z.string().date().optional(),
});

const UuidParam = z.object({ id: z.string().uuid() });

// ─── Route Plugin ──────────────────────────────────────────

export default async function campaignRoutes(app: FastifyInstance) {
  app.addHook('onRequest', app.authenticate);
  app.addHook('onRequest', app.requireOwner);

  // GET /api/v1/campaigns
  // Auth: owner
  app.get('/', {
    schema: { querystring: ListCampaignsQuery },
    handler: async (request, reply) => {
      // → CampaignController.list
      throw new Error('Not implemented');
    },
  });

  // POST /api/v1/campaigns
  // Auth: owner
  app.post('/', {
    schema: { body: CreateCampaignBody },
    handler: async (request, reply) => {
      // → CampaignController.create
      throw new Error('Not implemented');
    },
  });

  // PATCH /api/v1/campaigns/:id
  // Auth: owner
  app.patch('/:id', {
    schema: { params: UuidParam, body: UpdateCampaignBody },
    handler: async (request, reply) => {
      // → CampaignController.update
      throw new Error('Not implemented');
    },
  });

  // DELETE /api/v1/campaigns/:id
  // Auth: owner
  app.delete('/:id', {
    schema: { params: UuidParam },
    handler: async (request, reply) => {
      // → CampaignController.delete
      throw new Error('Not implemented');
    },
  });

  // GET /api/v1/campaigns/:id/metrics
  // Auth: owner
  // Stats separated from listing to avoid N+1
  app.get('/:id/metrics', {
    schema: { params: UuidParam, querystring: CampaignMetricsQuery },
    handler: async (request, reply) => {
      // → CampaignController.metrics
      throw new Error('Not implemented');
    },
  });
}

export const autoPrefix = '/api/v1/campaigns';
