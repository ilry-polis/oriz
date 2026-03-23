import type { FastifyInstance } from 'fastify';
import { z } from 'zod';

// ─── Zod Schemas ───────────────────────────────────────────

export const CreateStudioBody = z.object({
  name: z.string().min(1),
  slug: z.string().regex(/^[a-z0-9-]{3,50}$/),
  phone: z.string().regex(/^\+?\d{10,15}$/, 'Invalid phone number format').optional(),
  address: z.string().optional(),
  description: z.string().optional(),
  timezone: z.string().default('America/Sao_Paulo'),
});

export const UpdateStudioBody = z.object({
  name: z.string().min(1).optional(),
  slug: z.string().regex(/^[a-z0-9-]{3,50}$/).optional(),
  phone: z.string().regex(/^\+?\d{10,15}$/, 'Invalid phone number format').optional(),
  address: z.string().optional(),
  logo_url: z.string().url().refine(
    (u) => !u.startsWith('file:') && !u.startsWith('ftp:'),
    'Only HTTP(S) URLs are allowed',
  ).optional(),
  description: z.string().optional(),
  timezone: z.string().optional(),
  settings: z.object({
    reminder_hours_before: z.number().int().optional(),
    allow_public_booking: z.boolean().optional(),
    default_currency: z.string().optional(),
  }).optional(),
});

// Photo URLs must point to Supabase Storage; validated at service layer via SUPABASE_URL env.
// Route-level validation ensures it's a valid URL; service layer enforces domain whitelist.
export const CreatePhotoBody = z.object({
  url: z.string().url().refine(
    (u) => !u.startsWith('file:') && !u.startsWith('ftp:'),
    'Only HTTP(S) URLs are allowed',
  ),
  position: z.number().int().default(0),
});

export const UpdatePhotoBody = z.object({
  position: z.number().int().optional(),
});

export const UpdateOnboardingBody = z.object({
  current_step: z.enum(['studio_data', 'services', 'business_hours', 'complete']),
});

const UuidParam = z.object({ photoId: z.string().uuid() });

// ─── Route Plugin ──────────────────────────────────────────

export default async function studioRoutes(app: FastifyInstance) {
  // All routes require authentication
  app.addHook('onRequest', app.authenticate);

  // POST /api/v1/studios
  // Auth: authenticated | Rate limit: 3/min per user
  // Creates studio + onboarding_state + professional (owner)
  app.post('/', {
    schema: { body: CreateStudioBody },
    config: { rateLimit: { max: 3, timeWindow: '1 minute' } },
    handler: async (request, reply) => {
      return app.studioController.create(request, reply);
    },
  });

  // GET /api/v1/studios/me
  // Auth: authenticated (no requireStudioMember — needed for onboarding redirect)
  app.get('/me', {
    handler: async (request, reply) => {
      return app.studioController.getMe(request, reply);
    },
  });

  // PATCH /api/v1/studios/me
  // Auth: owner
  app.patch('/me', {
    onRequest: [app.requireOwner],
    schema: { body: UpdateStudioBody },
    handler: async (request, reply) => {
      // → StudioController.update
      throw new Error('Not implemented');
    },
  });

  // ─── Studio Photos ────────────────────────────────────────

  // GET /api/v1/studios/me/photos
  // Auth: owner+professional | No pagination (max ~20)
  app.get('/me/photos', {
    onRequest: [app.requireStudioMember],
    handler: async (request, reply) => {
      // → StudioPhotoController.list
      throw new Error('Not implemented');
    },
  });

  // POST /api/v1/studios/me/photos
  // Auth: owner
  app.post('/me/photos', {
    onRequest: [app.requireOwner],
    schema: { body: CreatePhotoBody },
    handler: async (request, reply) => {
      // → StudioPhotoController.create
      throw new Error('Not implemented');
    },
  });

  // PATCH /api/v1/studios/me/photos/:photoId
  // Auth: owner
  app.patch('/me/photos/:photoId', {
    onRequest: [app.requireOwner],
    schema: { params: UuidParam, body: UpdatePhotoBody },
    handler: async (request, reply) => {
      // → StudioPhotoController.update
      throw new Error('Not implemented');
    },
  });

  // DELETE /api/v1/studios/me/photos/:photoId
  // Auth: owner
  app.delete('/me/photos/:photoId', {
    onRequest: [app.requireOwner],
    schema: { params: UuidParam },
    handler: async (request, reply) => {
      // → StudioPhotoController.delete
      throw new Error('Not implemented');
    },
  });

  // ─── Onboarding ───────────────────────────────────────────

  // GET /api/v1/studios/me/onboarding
  // Auth: owner
  app.get('/me/onboarding', {
    onRequest: [app.requireOwner],
    handler: async (request, reply) => {
      return app.onboardingController.get(request, reply);
    },
  });

  // PATCH /api/v1/studios/me/onboarding
  // Auth: owner
  // When current_step = 'complete', completed_at is auto-set
  app.patch('/me/onboarding', {
    onRequest: [app.requireOwner],
    schema: { body: UpdateOnboardingBody },
    handler: async (request, reply) => {
      return app.onboardingController.update(request, reply);
    },
  });
}

export const autoPrefix = '/api/v1/studios';
