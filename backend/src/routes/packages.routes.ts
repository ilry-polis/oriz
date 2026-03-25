import type { FastifyInstance } from 'fastify';
import { z } from 'zod';

// ─── Zod Schemas ───────────────────────────────────────────

export const ListPackagesQuery = z.object({
  cursor: z.string().uuid().optional(),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});

export const CreatePackageBody = z.object({
  service_id: z.string().uuid(),
  name: z.string().min(1),
  total_sessions: z.number().int().min(1),
  price: z.number().int().min(0),
  validity_days: z.number().int().min(1),
});

export const UpdatePackageBody = z.object({
  name: z.string().min(1).optional(),
  total_sessions: z.number().int().min(1).optional(),
  price: z.number().int().min(0).optional(),
  validity_days: z.number().int().min(1).optional(),
});

export const ListSubscriptionsQuery = z.object({
  status: z.enum(['active', 'completed', 'expired']).optional(),
  cursor: z.string().uuid().optional(),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});

export const CreateSubscriptionBody = z.object({
  client_id: z.string().uuid(),
});

const UuidParam = z.object({ id: z.string().uuid() });
const PackageIdParam = z.object({ packageId: z.string().uuid() });
// SubscriptionIdParam removed — identical to UuidParam, use UuidParam instead

// ─── Route Plugin ──────────────────────────────────────────

export default async function packageRoutes(app: FastifyInstance) {
  app.addHook('onRequest', app.authenticate);

  // GET /api/v1/packages
  // Auth: owner+professional
  app.get('/', {
    onRequest: [app.requireStudioMember],
    schema: { querystring: ListPackagesQuery },
    handler: async (_request, _reply) => {
      // → PackageController.list
      throw new Error('Not implemented');
    },
  });

  // POST /api/v1/packages
  // Auth: owner
  app.post('/', {
    onRequest: [app.requireOwner],
    schema: { body: CreatePackageBody },
    handler: async (_request, _reply) => {
      // → PackageController.create
      throw new Error('Not implemented');
    },
  });

  // PATCH /api/v1/packages/:id
  // Auth: owner
  // Error: 422 CANNOT_REDUCE_SESSIONS if active subscriptions exist
  app.patch('/:id', {
    onRequest: [app.requireOwner],
    schema: { params: UuidParam, body: UpdatePackageBody },
    handler: async (_request, _reply) => {
      // → PackageController.update
      throw new Error('Not implemented');
    },
  });

  // DELETE /api/v1/packages/:id
  // Auth: owner
  // Error: 409 PACKAGE_HAS_SUBSCRIPTIONS
  app.delete('/:id', {
    onRequest: [app.requireOwner],
    schema: { params: UuidParam },
    handler: async (_request, _reply) => {
      // → PackageController.delete
      throw new Error('Not implemented');
    },
  });

  // ─── Package Subscriptions ────────────────────────────────

  // GET /api/v1/packages/:packageId/subscriptions
  // Auth: owner+professional
  app.get('/:packageId/subscriptions', {
    onRequest: [app.requireStudioMember],
    schema: { params: PackageIdParam, querystring: ListSubscriptionsQuery },
    handler: async (_request, _reply) => {
      // → PackageSubscriptionController.listByPackage
      throw new Error('Not implemented');
    },
  });

  // POST /api/v1/packages/:packageId/subscriptions
  // Auth: owner+professional
  // sessions_total copied from Package; expires_at = now() + validity_days
  app.post('/:packageId/subscriptions', {
    onRequest: [app.requireStudioMember],
    schema: { params: PackageIdParam, body: CreateSubscriptionBody },
    handler: async (_request, _reply) => {
      // → PackageSubscriptionController.create
      throw new Error('Not implemented');
    },
  });
}

export const autoPrefix = '/api/v1/packages';
