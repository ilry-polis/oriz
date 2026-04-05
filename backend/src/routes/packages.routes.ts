import type { FastifyInstance } from "fastify";
import { z } from "zod";

// ─── Zod Schemas ───────────────────────────────────────────

export const ListPackagesQuery = z.object({
	cursor: z.string().uuid().optional(),
	limit: z.coerce.number().int().min(1).max(100).default(20),
	service_id: z.string().uuid().optional(),
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
	status: z.enum(["active", "completed", "expired"]).optional(),
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
	app.addHook("onRequest", app.authenticate);

	// GET /api/v1/packages
	// Auth: owner+professional
	app.get("/", {
		onRequest: [app.requireStudioMember],
		schema: { querystring: ListPackagesQuery },
		handler: async (request, reply) => {
			return app.packageController.list(request, reply);
		},
	});

	// GET /api/v1/packages/:id
	// Auth: owner+professional
	app.get("/:id", {
		onRequest: [app.requireStudioMember],
		schema: { params: UuidParam },
		handler: async (request, reply) => {
			return app.packageController.getById(request, reply);
		},
	});

	// POST /api/v1/packages
	// Auth: owner
	app.post("/", {
		onRequest: [app.requireOwner],
		schema: { body: CreatePackageBody },
		handler: async (request, reply) => {
			return app.packageController.create(request, reply);
		},
	});

	// PATCH /api/v1/packages/:id
	// Auth: owner
	// Error: 409 PACKAGE_HAS_SUBSCRIPTIONS
	app.patch("/:id", {
		onRequest: [app.requireOwner],
		schema: { params: UuidParam, body: UpdatePackageBody },
		handler: async (request, reply) => {
			return app.packageController.update(request, reply);
		},
	});

	// DELETE /api/v1/packages/:id
	// Auth: owner
	// Error: 409 PACKAGE_HAS_SUBSCRIPTIONS
	app.delete("/:id", {
		onRequest: [app.requireOwner],
		schema: { params: UuidParam },
		handler: async (request, reply) => {
			return app.packageController.delete(request, reply);
		},
	});

	// ─── Package Subscriptions ────────────────────────────────

	// GET /api/v1/packages/:packageId/subscriptions
	// Auth: owner+professional
	app.get("/:packageId/subscriptions", {
		onRequest: [app.requireStudioMember],
		schema: { params: PackageIdParam, querystring: ListSubscriptionsQuery },
		handler: async (request, reply) => {
			return app.packageController.listSubscriptions(request, reply);
		},
	});

	// POST /api/v1/packages/:packageId/subscriptions
	// Auth: owner+professional
	// sessions_total copied from Package; expires_at = now() + validity_days
	app.post("/:packageId/subscriptions", {
		onRequest: [app.requireStudioMember],
		schema: { params: PackageIdParam, body: CreateSubscriptionBody },
		handler: async (request, reply) => {
			return app.packageController.createSubscription(request, reply);
		},
	});
}

export const autoPrefix = "/api/v1/packages";
