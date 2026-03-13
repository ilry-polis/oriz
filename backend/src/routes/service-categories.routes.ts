import type { FastifyInstance } from 'fastify';
import { z } from 'zod';

// ─── Zod Schemas ───────────────────────────────────────────

export const ListCategoriesQuery = z.object({
  is_active: z.coerce.boolean().optional(),
});

export const CreateCategoryBody = z.object({
  name: z.string().min(1),
  icon: z.string().optional(),
  position: z.number().int().default(0),
});

export const UpdateCategoryBody = z.object({
  name: z.string().min(1).optional(),
  icon: z.string().optional(),
  position: z.number().int().optional(),
  is_active: z.boolean().optional(),
});

const UuidParam = z.object({ id: z.string().uuid() });

// ─── Route Plugin ──────────────────────────────────────────

export default async function serviceCategoryRoutes(app: FastifyInstance) {
  app.addHook('onRequest', app.authenticate);

  // GET /api/v1/service-categories
  // Auth: owner+professional | No pagination (max ~15)
  // Returns global (studio_id = NULL) + studio categories
  app.get('/', {
    onRequest: [app.requireStudioMember],
    schema: { querystring: ListCategoriesQuery },
    handler: async (request, reply) => {
      // → ServiceCategoryController.list
      throw new Error('Not implemented');
    },
  });

  // POST /api/v1/service-categories
  // Auth: owner
  app.post('/', {
    onRequest: [app.requireOwner],
    schema: { body: CreateCategoryBody },
    handler: async (request, reply) => {
      // → ServiceCategoryController.create
      throw new Error('Not implemented');
    },
  });

  // PATCH /api/v1/service-categories/:id
  // Auth: owner
  // Error: 403 GLOBAL_CATEGORY if studio_id is NULL
  app.patch('/:id', {
    onRequest: [app.requireOwner],
    schema: { params: UuidParam, body: UpdateCategoryBody },
    handler: async (request, reply) => {
      // → ServiceCategoryController.update
      throw new Error('Not implemented');
    },
  });

  // DELETE /api/v1/service-categories/:id
  // Auth: owner
  // Error: 403 GLOBAL_CATEGORY, 409 CATEGORY_HAS_SERVICES
  app.delete('/:id', {
    onRequest: [app.requireOwner],
    schema: { params: UuidParam },
    handler: async (request, reply) => {
      // → ServiceCategoryController.delete
      throw new Error('Not implemented');
    },
  });
}

export const autoPrefix = '/api/v1/service-categories';
