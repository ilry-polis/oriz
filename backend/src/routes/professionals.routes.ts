import type { FastifyInstance } from 'fastify';
import { z } from 'zod';

// ─── Zod Schemas ───────────────────────────────────────────

const TimeSlot = z.object({
  open: z.string().regex(/^\d{2}:\d{2}$/, 'Format: HH:mm'),
  close: z.string().regex(/^\d{2}:\d{2}$/, 'Format: HH:mm'),
}).refine(d => d.close > d.open, { message: 'close must be after open' });

const WorkingHoursSchema = z.object({
  monday: z.array(TimeSlot).default([]),
  tuesday: z.array(TimeSlot).default([]),
  wednesday: z.array(TimeSlot).default([]),
  thursday: z.array(TimeSlot).default([]),
  friday: z.array(TimeSlot).default([]),
  saturday: z.array(TimeSlot).default([]),
  sunday: z.array(TimeSlot).default([]),
});

export const ListProfessionalsQuery = z.object({
  is_active: z.coerce.boolean().optional(),
  cursor: z.string().uuid().optional(),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});

export const CreateProfessionalBody = z.object({
  user_id: z.string().uuid(),
  name: z.string().min(1),
  avatar_url: z.string().url().optional(),
  specialties: z.array(z.string()).optional(),
  working_hours: WorkingHoursSchema.optional(),
  commission_type: z.enum(['percentage', 'fixed']),
  commission_value: z.number().min(0),
  card_fee_policy: z.enum(['studio', 'professional', 'split']).default('studio'),
  service_ids: z.array(z.string().uuid()).optional(),
});

export const UpdateProfessionalBody = z.object({
  name: z.string().min(1).optional(),
  avatar_url: z.string().url().optional(),
  specialties: z.array(z.string()).optional(),
  working_hours: WorkingHoursSchema.optional(),
  commission_type: z.enum(['percentage', 'fixed']).optional(),
  commission_value: z.number().min(0).optional(),
  card_fee_policy: z.enum(['studio', 'professional', 'split']).optional(),
  is_active: z.boolean().optional(),
  service_ids: z.array(z.string().uuid()).optional(),
});

const UuidParam = z.object({ id: z.string().uuid() });

// ─── Route Plugin ──────────────────────────────────────────

export default async function professionalRoutes(app: FastifyInstance) {
  app.addHook('onRequest', app.authenticate);

  // GET /api/v1/professionals
  // Auth: owner+professional
  // commission_type, commission_value, card_fee_policy → null for non-owners
  app.get('/', {
    onRequest: [app.requireStudioMember],
    schema: { querystring: ListProfessionalsQuery },
    handler: async (request, reply) => {
      // → ProfessionalController.list
      throw new Error('Not implemented');
    },
  });

  // POST /api/v1/professionals
  // Auth: owner
  app.post('/', {
    onRequest: [app.requireOwner],
    schema: { body: CreateProfessionalBody },
    handler: async (request, reply) => {
      // → ProfessionalController.create
      throw new Error('Not implemented');
    },
  });

  // GET /api/v1/professionals/me
  // Auth: owner+professional
  // Returns current professional's data in the current studio
  app.get('/me', {
    onRequest: [app.requireStudioMember],
    handler: async (request, reply) => {
      // → ProfessionalController.getMe
      throw new Error('Not implemented');
    },
  });

  // GET /api/v1/professionals/:id
  // Auth: owner+professional
  app.get('/:id', {
    onRequest: [app.requireStudioMember],
    schema: { params: UuidParam },
    handler: async (request, reply) => {
      // → ProfessionalController.getById
      throw new Error('Not implemented');
    },
  });

  // PATCH /api/v1/professionals/:id
  // Auth: owner
  // service_ids replaces all professional_services links
  app.patch('/:id', {
    onRequest: [app.requireOwner],
    schema: { params: UuidParam, body: UpdateProfessionalBody },
    handler: async (request, reply) => {
      return app.professionalController.update(request, reply);
    },
  });

  // DELETE /api/v1/professionals/:id
  // Auth: owner
  // Error: 409 PROFESSIONAL_HAS_APPOINTMENTS
  app.delete('/:id', {
    onRequest: [app.requireOwner],
    schema: { params: UuidParam },
    handler: async (request, reply) => {
      // → ProfessionalController.delete
      throw new Error('Not implemented');
    },
  });
}

export const autoPrefix = '/api/v1/professionals';
