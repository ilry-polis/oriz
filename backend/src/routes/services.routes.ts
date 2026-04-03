import type { FastifyInstance } from "fastify";
import { z } from "zod";

// ─── Zod Schemas ───────────────────────────────────────────

export const ListServicesQuery = z.object({
	category_id: z.string().uuid().optional(),
	is_active: z.coerce.boolean().optional(),
	cursor: z.string().uuid().optional(),
	limit: z.coerce.number().int().min(1).max(100).default(20),
});

export const CreateServiceBody = z.object({
	category_id: z.string().uuid(),
	name: z.string().min(1),
	duration_minutes: z.number().int().min(5),
	price: z.number().int().min(0),
	buffer_minutes: z.number().int().min(0).default(0),
	is_active: z.boolean().default(true),
});

export const UpdateServiceBody = z.object({
	category_id: z.string().uuid().optional(),
	name: z.string().min(1).optional(),
	duration_minutes: z.number().int().min(5).optional(),
	price: z.number().int().min(0).optional(),
	buffer_minutes: z.number().int().min(0).optional(),
});

export const SetActiveBody = z.object({
	is_active: z.boolean(),
});

const UuidParam = z.object({ id: z.string().uuid() });

// ─── Route Plugin ──────────────────────────────────────────

export default async function serviceRoutes(app: FastifyInstance) {
	app.addHook("onRequest", app.authenticate);

	// GET /api/v1/services
	// Auth: owner+professional
	app.get("/", {
		onRequest: [app.requireStudioMember],
		schema: { querystring: ListServicesQuery },
		handler: async (request, reply) => {
			return app.serviceController.list(request, reply);
		},
	});

	// POST /api/v1/services
	// Auth: owner
	app.post("/", {
		onRequest: [app.requireOwner],
		schema: { body: CreateServiceBody },
		handler: async (request, reply) => {
			return app.serviceController.create(request, reply);
		},
	});

	// GET /api/v1/services/:id
	// Auth: owner+professional
	app.get("/:id", {
		onRequest: [app.requireStudioMember],
		schema: { params: UuidParam },
		handler: async (request, reply) => {
			return app.serviceController.getById(request, reply);
		},
	});

	// PATCH /api/v1/services/:id
	// Auth: owner
	app.patch("/:id", {
		onRequest: [app.requireOwner],
		schema: { params: UuidParam, body: UpdateServiceBody },
		handler: async (request, reply) => {
			return app.serviceController.update(request, reply);
		},
	});

	// PATCH /api/v1/services/:id/active
	// Auth: owner
	app.patch("/:id/active", {
		onRequest: [app.requireOwner],
		schema: { params: UuidParam, body: SetActiveBody },
		handler: async (request, reply) => {
			return app.serviceController.setActive(request, reply);
		},
	});

	// DELETE /api/v1/services/:id
	// Auth: owner
	// Error: 409 SERVICE_HAS_APPOINTMENTS
	app.delete("/:id", {
		onRequest: [app.requireOwner],
		schema: { params: UuidParam },
		handler: async (request, reply) => {
			return app.serviceController.delete(request, reply);
		},
	});
}

export const autoPrefix = "/api/v1/services";
