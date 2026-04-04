import type { FastifyInstance } from "fastify";
import { z } from "zod";

// ─── Zod Schemas ───────────────────────────────────────────

export const ListCategoriesQuery = z.object({
	is_active: z.coerce.boolean().optional(),
	scope: z.enum(["studio", "global"]).optional(),
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

export const CopyGlobalsBody = z.object({
	category_ids: z.array(z.string().uuid()).min(1),
});

const UuidParam = z.object({ id: z.string().uuid() });

// ─── Route Plugin ──────────────────────────────────────────

export default async function serviceCategoryRoutes(app: FastifyInstance) {
	app.addHook("onRequest", app.authenticate);

	// GET /api/v1/service-categories
	// Auth: owner+professional | No pagination (max ~15)
	// Query: ?scope=studio (only studio categories) | ?scope=global (only global)
	app.get("/", {
		onRequest: [app.requireStudioMember],
		schema: { querystring: ListCategoriesQuery },
		handler: async (request, reply) => {
			return app.serviceCategoryController.list(request, reply);
		},
	});

	// POST /api/v1/service-categories
	// Auth: owner
	app.post("/", {
		onRequest: [app.requireOwner],
		schema: { body: CreateCategoryBody },
		handler: async (request, reply) => {
			return app.serviceCategoryController.create(request, reply);
		},
	});

	// POST /api/v1/service-categories/copy-globals
	// Auth: owner — copies selected global categories to studio
	app.post("/copy-globals", {
		onRequest: [app.requireOwner],
		schema: { body: CopyGlobalsBody },
		handler: async (request, reply) => {
			return app.serviceCategoryController.copyGlobals(request, reply);
		},
	});

	// PATCH /api/v1/service-categories/:id
	// Auth: owner
	app.patch("/:id", {
		onRequest: [app.requireOwner],
		schema: { params: UuidParam, body: UpdateCategoryBody },
		handler: async (request, reply) => {
			return app.serviceCategoryController.update(request, reply);
		},
	});

	// DELETE /api/v1/service-categories/:id
	// Auth: owner
	// Error: 409 CATEGORY_HAS_SERVICES
	app.delete("/:id", {
		onRequest: [app.requireOwner],
		schema: { params: UuidParam },
		handler: async (request, reply) => {
			return app.serviceCategoryController.delete(request, reply);
		},
	});
}

export const autoPrefix = "/api/v1/service-categories";
