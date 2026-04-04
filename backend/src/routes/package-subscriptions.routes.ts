import type { FastifyInstance } from "fastify";
import { z } from "zod";

// ─── Zod Schemas ───────────────────────────────────────────

const UuidParam = z.object({ id: z.string().uuid() });

// ─── Route Plugin ──────────────────────────────────────────

export default async function packageSubscriptionRoutes(app: FastifyInstance) {
	app.addHook("onRequest", app.authenticate);

	// GET /api/v1/package-subscriptions/:id
	// Auth: owner+professional
	app.get("/:id", {
		onRequest: [app.requireStudioMember],
		schema: { params: UuidParam },
		handler: async (_request, _reply) => {
			// → PackageSubscriptionController.getById
			throw new Error("Not implemented");
		},
	});
}

export const autoPrefix = "/api/v1/package-subscriptions";
