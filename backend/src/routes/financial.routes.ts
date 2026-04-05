import type { FastifyInstance } from "fastify";
import { z } from "zod";

// ─── Zod Schemas ───────────────────────────────────────────

export const FinancialSummaryQuery = z.object({
	period: z.enum(["day", "week", "month"]).default("month"),
	date: z.string().date().optional(),
});

export const FinancialBreakdownQuery = z.object({
	date_from: z.string().date().optional(),
	date_to: z.string().date().optional(),
});

// ─── Route Plugin ──────────────────────────────────────────

export default async function financialRoutes(app: FastifyInstance) {
	app.addHook("onRequest", app.authenticate);
	// requireStudioMember: both owners and professionals can see financial data
	// Controller applies role-based filtering
	app.addHook("onRequest", app.requireStudioMember);

	// GET /api/v1/financial/summary
	// Auth: owner or professional (collaborator sees studio-wide data for now)
	app.get("/summary", {
		schema: { querystring: FinancialSummaryQuery },
		handler: async (request, reply) => {
			return app.financialController.summary(request, reply);
		},
	});

	// GET /api/v1/financial/breakdown/professionals
	// Auth: owner or professional
	app.get("/breakdown/professionals", {
		schema: { querystring: FinancialBreakdownQuery },
		handler: async (request, reply) => {
			return app.financialController.breakdownByProfessional(request, reply);
		},
	});

	// GET /api/v1/financial/breakdown/services
	// Auth: owner or professional
	app.get("/breakdown/services", {
		schema: { querystring: FinancialBreakdownQuery },
		handler: async (request, reply) => {
			return app.financialController.breakdownByService(request, reply);
		},
	});
}

export const autoPrefix = "/api/v1/financial";
