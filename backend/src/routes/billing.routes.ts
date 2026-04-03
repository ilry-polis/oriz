import type { FastifyInstance } from "fastify";
import { z } from "zod";

// ─── Zod Schemas ───────────────────────────────────────────

export const CreateSubscriptionBody = z.object({
	plan: z.enum(["basic", "pro", "premium"]),
});

export const UpdateSubscriptionBody = z.object({
	plan: z.enum(["basic", "pro", "premium"]),
});

export const ListInvoicesQuery = z.object({
	status: z.enum(["pending", "paid", "failed"]).optional(),
	cursor: z.string().uuid().optional(),
	limit: z.coerce.number().int().min(1).max(100).default(20),
});

// ─── Route Plugin ──────────────────────────────────────────

export default async function billingRoutes(app: FastifyInstance) {
	app.addHook("onRequest", app.authenticate);
	app.addHook("onRequest", app.requireOwner);

	// ─── Subscription ─────────────────────────────────────────

	// GET /api/v1/billing/subscription
	// Auth: owner
	app.get("/subscription", {
		handler: async (_request, _reply) => {
			// → BillingController.getSubscription
			throw new Error("Not implemented");
		},
	});

	// POST /api/v1/billing/subscription
	// Auth: owner
	// Returns { subscription, checkout_url } — checkout_url for gateway redirect
	app.post("/subscription", {
		schema: { body: CreateSubscriptionBody },
		handler: async (_request, _reply) => {
			// → BillingController.createSubscription
			throw new Error("Not implemented");
		},
	});

	// PATCH /api/v1/billing/subscription
	// Auth: owner
	// Upgrade/downgrade on next billing cycle
	app.patch("/subscription", {
		schema: { body: UpdateSubscriptionBody },
		handler: async (_request, _reply) => {
			// → BillingController.updateSubscription
			throw new Error("Not implemented");
		},
	});

	// POST /api/v1/billing/subscription/cancel
	// Auth: owner
	app.post("/subscription/cancel", {
		handler: async (_request, _reply) => {
			// → BillingController.cancelSubscription
			throw new Error("Not implemented");
		},
	});

	// ─── Invoices ─────────────────────────────────────────────

	// GET /api/v1/billing/invoices
	// Auth: owner
	app.get("/invoices", {
		schema: { querystring: ListInvoicesQuery },
		handler: async (_request, _reply) => {
			// → BillingController.listInvoices
			throw new Error("Not implemented");
		},
	});
}

export const autoPrefix = "/api/v1/billing";
