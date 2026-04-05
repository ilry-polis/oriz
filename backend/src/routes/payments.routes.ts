import type { FastifyInstance } from "fastify";
import { z } from "zod";

// ─── Zod Schemas ───────────────────────────────────────────

export const ListPaymentsQuery = z.object({
	date_from: z.string().date().optional(),
	date_to: z.string().date().optional(),
	method: z.enum(["cash", "pix", "debit", "credit"]).optional(),
	professional_id: z.string().uuid().optional(),
	cursor: z.string().uuid().optional(),
	limit: z.coerce.number().int().min(1).max(100).default(20),
});

// ─── Route Plugin ──────────────────────────────────────────

export default async function paymentRoutes(app: FastifyInstance) {
	app.addHook("onRequest", app.authenticate);
	app.addHook("onRequest", app.requireOwner);

	// GET /api/v1/payments
	// Auth: owner
	app.get("/", {
		schema: { querystring: ListPaymentsQuery },
		handler: async (request, reply) => {
			return app.paymentController.list(request, reply);
		},
	});
}

export const autoPrefix = "/api/v1/payments";
