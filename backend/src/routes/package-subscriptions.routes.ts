import type { FastifyInstance } from "fastify";
import { z } from "zod";

// ─── Zod Schemas ───────────────────────────────────────────

const UuidParam = z.object({ id: z.string().uuid() });

export const ActiveSubscriptionQuery = z.object({
	client_id: z.string().uuid(),
	service_id: z.string().uuid(),
});

export const ExtendExpiryBody = z.object({
	expires_at: z.string().datetime(),
});

// ─── Route Plugin ──────────────────────────────────────────

export default async function packageSubscriptionRoutes(app: FastifyInstance) {
	app.addHook("onRequest", app.authenticate);

	// GET /api/v1/package-subscriptions/active?client_id=&service_id=
	// Auth: owner+professional
	// Returns active subscription for a client+service pair, or null.
	// Consumed by QuickBookSheet (Plan 05) to detect active packages.
	app.get("/active", {
		onRequest: [app.requireStudioMember],
		schema: { querystring: ActiveSubscriptionQuery },
		handler: async (request, reply) => {
			return app.packageSubscriptionController.getActive(request, reply);
		},
	});

	// GET /api/v1/package-subscriptions/:id
	// Auth: owner+professional
	app.get("/:id", {
		onRequest: [app.requireStudioMember],
		schema: { params: UuidParam },
		handler: async (request, reply) => {
			return app.packageSubscriptionController.getById(request, reply);
		},
	});

	// PATCH /api/v1/package-subscriptions/:id/extend
	// Auth: owner
	app.patch("/:id/extend", {
		onRequest: [app.requireOwner],
		schema: { params: UuidParam, body: ExtendExpiryBody },
		handler: async (request, reply) => {
			return app.packageSubscriptionController.extendExpiry(request, reply);
		},
	});
}

export const autoPrefix = "/api/v1/package-subscriptions";
