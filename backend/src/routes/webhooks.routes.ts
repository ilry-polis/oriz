import type { FastifyInstance } from 'fastify';

// ─── Route Plugin ──────────────────────────────────────────

export default async function webhookRoutes(app: FastifyInstance) {
  // POST /api/v1/webhooks/whatsapp
  // Auth: webhook (signature validation by provider)
  // Rate limit: 100/min per IP
  // Processes asynchronously via BullMQ, returns 200 immediately
  app.post('/whatsapp', {
    config: { rateLimit: { max: 100, timeWindow: '1 minute' } },
    preHandler: [app.validateWhatsAppSignature],
    handler: async (request, reply) => {
      // → WebhookController.whatsapp
      throw new Error('Not implemented');
    },
  });

  // POST /api/v1/webhooks/billing
  // Auth: webhook (signature validation by Stripe/Asaas)
  // Rate limit: 100/min per IP
  // Events: invoice.paid, invoice.failed, subscription.cancelled, etc.
  app.post('/billing', {
    config: { rateLimit: { max: 100, timeWindow: '1 minute' } },
    preHandler: [app.validateBillingSignature],
    handler: async (request, reply) => {
      // → WebhookController.billing
      throw new Error('Not implemented');
    },
  });
}

export const autoPrefix = '/api/v1/webhooks';
