import type { FastifyInstance } from 'fastify';
import { z } from 'zod';

// ─── Zod Schemas ───────────────────────────────────────────

export const ListClientsQuery = z.object({
  search: z.string().optional(),
  tag: z.string().optional(),
  inactive_days: z.coerce.number().int().min(1).optional(),
  cursor: z.string().uuid().optional(),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});

export const CreateClientBody = z.object({
  name: z.string().min(1),
  phone: z.string().regex(/^\+?\d{10,15}$/, 'Invalid phone number format').optional(),
  email: z.string().email().optional(),
  birth_date: z.string().date().optional(),
  tags: z.array(z.string()).optional(),
  notes: z.string().optional(),
});

export const UpdateClientBody = z.object({
  name: z.string().min(1).optional(),
  phone: z.string().regex(/^\+?\d{10,15}$/, 'Invalid phone number format').optional(),
  email: z.string().email().optional(),
  birth_date: z.string().date().optional(),
  tags: z.array(z.string()).optional(),
  notes: z.string().optional(),
});

export const ListClientAppointmentsQuery = z.object({
  status: z.enum(['pending', 'confirmed', 'completed', 'cancelled', 'no_show']).optional(),
  cursor: z.string().uuid().optional(),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});

export const ListPackageSubscriptionsQuery = z.object({
  status: z.enum(['active', 'completed', 'expired']).optional(),
  cursor: z.string().uuid().optional(),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});

export const UpsertAnamnesisBody = z.object({
  fields: z.record(z.string(), z.unknown()),
});

export const CreateConsentBody = z.object({
  type: z.enum(['marketing_whatsapp', 'marketing_push']),
  action: z.enum(['granted', 'revoked']),
});

const ClientIdParam = z.object({ id: z.string().uuid() });
const ClientIdWithCategoryParam = z.object({
  clientId: z.string().uuid(),
  categoryId: z.string().uuid(),
});
const ClientIdParam2 = z.object({ clientId: z.string().uuid() });

// ─── Route Plugin ──────────────────────────────────────────

export default async function clientRoutes(app: FastifyInstance) {
  app.addHook('onRequest', app.authenticate);

  // GET /api/v1/clients
  // Auth: owner+professional
  app.get('/', {
    onRequest: [app.requireStudioMember],
    schema: { querystring: ListClientsQuery },
    handler: async (_request, _reply) => {
      // → ClientController.list
      throw new Error('Not implemented');
    },
  });

  // POST /api/v1/clients
  // Auth: owner+professional
  // Dedup by phone when provided (409 PHONE_ALREADY_EXISTS). No dedup when phone omitted.
  app.post('/', {
    onRequest: [app.requireStudioMember],
    schema: { body: CreateClientBody },
    handler: async (_request, _reply) => {
      // → ClientController.create
      throw new Error('Not implemented');
    },
  });

  // GET /api/v1/clients/:id
  // Auth: owner+professional
  // Includes stats: total_appointments, total_spent, last_service
  app.get('/:id', {
    onRequest: [app.requireStudioMember],
    schema: { params: ClientIdParam },
    handler: async (_request, _reply) => {
      // → ClientController.getById
      throw new Error('Not implemented');
    },
  });

  // PATCH /api/v1/clients/:id
  // Auth: owner+professional
  app.patch('/:id', {
    onRequest: [app.requireStudioMember],
    schema: { params: ClientIdParam, body: UpdateClientBody },
    handler: async (_request, _reply) => {
      // → ClientController.update
      throw new Error('Not implemented');
    },
  });

  // DELETE /api/v1/clients/:id
  // Auth: owner
  // Error: 409 CLIENT_HAS_APPOINTMENTS
  app.delete('/:id', {
    onRequest: [app.requireOwner],
    schema: { params: ClientIdParam },
    handler: async (_request, _reply) => {
      // → ClientController.delete
      throw new Error('Not implemented');
    },
  });

  // ─── Client Appointments ──────────────────────────────────

  // GET /api/v1/clients/:id/appointments
  // Auth: owner+professional
  app.get('/:id/appointments', {
    onRequest: [app.requireStudioMember],
    schema: { params: ClientIdParam, querystring: ListClientAppointmentsQuery },
    handler: async (_request, _reply) => {
      // → ClientController.listAppointments
      throw new Error('Not implemented');
    },
  });

  // ─── Anamnesis ────────────────────────────────────────────

  // GET /api/v1/clients/:clientId/anamneses
  // Auth: owner+professional | No pagination (max ~15)
  app.get('/:clientId/anamneses', {
    onRequest: [app.requireStudioMember],
    schema: { params: ClientIdParam2 },
    handler: async (_request, _reply) => {
      // → AnamnesisController.list
      throw new Error('Not implemented');
    },
  });

  // PUT /api/v1/clients/:clientId/anamneses/:categoryId
  // Auth: owner+professional | Upsert by (studio_id, client_id, service_category_id)
  app.put('/:clientId/anamneses/:categoryId', {
    onRequest: [app.requireStudioMember],
    schema: { params: ClientIdWithCategoryParam, body: UpsertAnamnesisBody },
    handler: async (_request, _reply) => {
      // → AnamnesisController.upsert
      throw new Error('Not implemented');
    },
  });

  // ─── Package Subscriptions ────────────────────────────────

  // GET /api/v1/clients/:clientId/package-subscriptions
  // Auth: owner+professional
  app.get('/:clientId/package-subscriptions', {
    onRequest: [app.requireStudioMember],
    schema: { params: ClientIdParam2, querystring: ListPackageSubscriptionsQuery },
    handler: async (_request, _reply) => {
      // → PackageSubscriptionController.listByClient
      throw new Error('Not implemented');
    },
  });

  // ─── Consent Records (LGPD) ──────────────────────────────

  // GET /api/v1/clients/:clientId/consents
  // Auth: owner+professional | No pagination (max 2 records)
  app.get('/:clientId/consents', {
    onRequest: [app.requireStudioMember],
    schema: { params: ClientIdParam2 },
    handler: async (_request, _reply) => {
      // → ConsentController.list
      throw new Error('Not implemented');
    },
  });

  // POST /api/v1/clients/:clientId/consents
  // Auth: owner+professional | Append-only
  app.post('/:clientId/consents', {
    onRequest: [app.requireStudioMember],
    schema: { params: ClientIdParam2, body: CreateConsentBody },
    handler: async (_request, _reply) => {
      // → ConsentController.create
      throw new Error('Not implemented');
    },
  });

  // ─── Data Deletion (LGPD) ────────────────────────────────

  // POST /api/v1/clients/:clientId/data-deletion
  // Auth: owner
  // Anonymizes personal data, keeps financial records
  app.post('/:clientId/data-deletion', {
    onRequest: [app.requireOwner],
    schema: { params: ClientIdParam2 },
    handler: async (_request, _reply) => {
      // → ClientController.dataDeletion
      throw new Error('Not implemented');
    },
  });
}

export const autoPrefix = '/api/v1/clients';
