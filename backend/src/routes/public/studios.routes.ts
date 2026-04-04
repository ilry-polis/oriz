import type { FastifyInstance, FastifyRequest, FastifyReply } from "fastify";
import { z } from "zod";

// ─── Zod Schemas ───────────────────────────────────────────

const SlugParam = z.object({ slug: z.string().min(3).max(50) });

export const PublicServicesQuery = z.object({
	category_id: z.string().uuid().optional(),
});

export const PublicAvailableSlotsQuery = z.object({
	date: z.string().date(),
	professional_id: z.string().uuid(),
	service_id: z.string().uuid(),
});

export const PublicBookingBody = z.object({
	client_name: z.string().min(1).max(100).trim(),
	client_phone: z
		.string()
		.regex(/^\+?\d{10,15}$/, "Invalid phone number format"),
	professional_id: z.string().uuid(),
	service_id: z.string().uuid(),
	date: z.string().date(),
	start_time: z.string().datetime(),
	notes: z.string().max(500).optional(),
});

// ─── Route Plugin ──────────────────────────────────────────

export default async function publicStudioRoutes(app: FastifyInstance) {
	// All routes are public — no auth required
	// studio_id resolved internally via slug, never sent by client

	// GET /api/v1/public/studios/:slug
	// Rate limit: 60/min per IP
	// Never returns: settings, owner_id
	app.get("/:slug", {
		config: { rateLimit: { max: 60, timeWindow: "1 minute" } },
		schema: { params: SlugParam },
		handler: async (_request, _reply) => {
			// → PublicStudioController.getBySlug
			throw new Error("Not implemented");
		},
	});

	// GET /api/v1/public/studios/:slug/professionals
	// Rate limit: 60/min per IP
	// Only active professionals. Never returns: working_hours, commission_*, card_fee_policy
	app.get("/:slug/professionals", {
		config: { rateLimit: { max: 60, timeWindow: "1 minute" } },
		schema: { params: SlugParam },
		handler: async (_request, _reply) => {
			// → PublicStudioController.listProfessionals
			throw new Error("Not implemented");
		},
	});

	// GET /api/v1/public/studios/:slug/services
	// Rate limit: 60/min per IP
	// Only active services
	app.get("/:slug/services", {
		config: { rateLimit: { max: 60, timeWindow: "1 minute" } },
		schema: { params: SlugParam, querystring: PublicServicesQuery },
		handler: async (_request, _reply) => {
			// → PublicStudioController.listServices
			throw new Error("Not implemented");
		},
	});

	// GET /api/v1/public/studios/:slug/service-categories
	// Rate limit: 60/min per IP
	// Global + studio categories, only active
	app.get("/:slug/service-categories", {
		config: { rateLimit: { max: 60, timeWindow: "1 minute" } },
		schema: { params: SlugParam },
		handler: async (_request, _reply) => {
			// → PublicStudioController.listServiceCategories
			throw new Error("Not implemented");
		},
	});

	// GET /api/v1/public/studios/:slug/available-slots
	// Rate limit: 30/min per IP
	app.get("/:slug/available-slots", {
		config: { rateLimit: { max: 30, timeWindow: "1 minute" } },
		schema: { params: SlugParam, querystring: PublicAvailableSlotsQuery },
		handler: async (_request, _reply) => {
			// → PublicStudioController.availableSlots
			throw new Error("Not implemented");
		},
	});

	// POST /api/v1/public/studios/:slug/appointments
	// Rate limit: 3/min per IP (via @fastify/rate-limit) + 1/min per phone (via service layer Redis check)
	// Creates Client if phone doesn't exist in studio. Source = 'web_page'.
	// Initial status depends on ai_config.scheduling_rules.auto_confirm.
	app.post("/:slug/appointments", {
		config: {
			rateLimit: {
				max: 3,
				timeWindow: "1 minute",
				keyGenerator: (request: FastifyRequest) => {
					const body = request.body as { client_phone?: string } | undefined;
					return body?.client_phone
						? `${request.ip}:${body.client_phone}`
						: request.ip;
				},
			},
		},
		schema: { params: SlugParam, body: PublicBookingBody },
		handler: async (_request: FastifyRequest, _reply: FastifyReply) => {
			// → PublicStudioController.createAppointment
			// Service layer MUST enforce per-phone rate limit (1/min) via Redis
			// to prevent abuse from rotating IPs with same phone
			throw new Error("Not implemented");
		},
	});
}

export const autoPrefix = "/api/v1/public/studios";
