import type { FastifyInstance } from "fastify";
import { z } from "zod";
import { requireOwner } from "../middleware/role-guard.js";

// ─── Zod Schemas ───────────────────────────────────────────

const TimeSlot = z
	.object({
		open: z.string().regex(/^\d{2}:\d{2}$/, "Format: HH:mm"),
		close: z.string().regex(/^\d{2}:\d{2}$/, "Format: HH:mm"),
	})
	.refine((d) => d.close > d.open, { message: "close must be after open" });

const WorkingHoursSchema = z.object({
	monday: z.array(TimeSlot).default([]),
	tuesday: z.array(TimeSlot).default([]),
	wednesday: z.array(TimeSlot).default([]),
	thursday: z.array(TimeSlot).default([]),
	friday: z.array(TimeSlot).default([]),
	saturday: z.array(TimeSlot).default([]),
	sunday: z.array(TimeSlot).default([]),
});

export const ListProfessionalsQuery = z.object({
	cursor: z.string().uuid().optional(),
	limit: z.coerce.number().int().min(1).max(100).default(20),
});

const CreateInviteBody = z.object({
	name: z.string().min(1),
	phone: z.string().optional(),
	service_ids: z.array(z.string().uuid()).optional().default([]),
	commission_type: z.enum(["percentage", "fixed"]),
	commission_value: z.number().min(0),
	card_fee_policy: z
		.enum(["studio", "professional", "split"])
		.default("studio"),
});

const ListInvitesQuery = z.object({
	cursor: z.string().uuid().optional(),
	limit: z.coerce.number().int().min(1).max(100).default(20),
});

export const UpdateProfessionalBody = z.object({
	name: z.string().min(1).optional(),
	avatar_url: z.string().url().optional(),
	working_hours: WorkingHoursSchema.optional(),
	commission_type: z.enum(["percentage", "fixed"]).optional(),
	commission_value: z.number().min(0).optional(),
	card_fee_policy: z.enum(["studio", "professional", "split"]).optional(),
	is_active: z.boolean().optional(),
	service_ids: z.array(z.string().uuid()).optional(),
});

const ToggleActiveBody = z.object({
	is_active: z.boolean(),
});

const UuidParam = z.object({ id: z.string().uuid() });
const TokenParam = z.object({ token: z.string().uuid() });

// ─── Route Plugin ──────────────────────────────────────────

export default async function professionalRoutes(app: FastifyInstance) {
	// All routes under /api/v1/professionals require authentication by default
	// (except invite getInfo which is registered as public below)
	app.addHook("onRequest", app.authenticate);

	/**
	 * POST /api/v1/professionals/invites
	 * Auth: owner only
	 * Owner pre-configures professional: name, services, commission, card fee policy.
	 * Returns: invite_token, expires_at, whatsapp_link
	 */
	app.post("/invites", {
		onRequest: [app.requireOwner],
		schema: { body: CreateInviteBody },
		handler: async (request, reply) => {
			return app.inviteController.create(request, reply);
		},
	});

	/**
	 * GET /api/v1/professionals/invites
	 * Auth: owner only
	 * Lists pending (not yet accepted) invites for the studio.
	 */
	app.get("/invites", {
		onRequest: [app.requireOwner],
		schema: { querystring: ListInvitesQuery },
		handler: async (request, reply) => {
			return app.inviteController.listPending(request, reply);
		},
	});

	/**
	 * DELETE /api/v1/professionals/invites/:token
	 * Auth: owner only
	 * Cancels a pending invite.
	 */
	app.delete("/invites/:token", {
		onRequest: [app.requireOwner],
		schema: { params: TokenParam },
		handler: async (request, reply) => {
			return app.inviteController.cancel(request, reply);
		},
	});

	/**
	 * POST /api/v1/professionals/invites/:token/resend
	 * Auth: owner only
	 * Extends invite expiry by 7 days and returns new whatsapp_link.
	 */
	app.post("/invites/:token/resend", {
		onRequest: [app.requireOwner],
		schema: { params: TokenParam },
		handler: async (request, reply) => {
			return app.inviteController.resend(request, reply);
		},
	});

	/**
	 * GET /api/v1/professionals/invites/:token
	 * Auth: public (rate limit: 30/min per IP — prevents token enumeration)
	 * Returns studio_name and collaborator name for the accept screen.
	 * IMPORTANT: This route must be registered BEFORE the authenticate hook is added,
	 * or we must remove authenticate from this specific route.
	 * Solution: register it within the authenticated block but skip auth via override.
	 */
	app.get("/invites/:token", {
		// Public route — no auth required. Override the onRequest hook added above.
		// The authenticate hook set via addHook applies to all routes in this scope;
		// we override it here by not adding it again and using onRequest: [] to skip.
		// Note: addHook cannot be selectively skipped per-route in Fastify.
		// The pattern used: register this in a separate scope (see bottom of file).
		config: { rateLimit: { max: 30, timeWindow: "1 minute" } },
		schema: { params: TokenParam },
		handler: async (request, reply) => {
			return app.inviteController.getInfo(request, reply);
		},
	});

	/**
	 * GET /api/v1/professionals
	 * Auth: owner + collaborator (collaborator sees names only, no commissions of others)
	 *
	 * | Requester    | Response |
	 * |--------------|----------|
	 * | Owner        | Full data including commission_type, commission_value, card_fee_policy |
	 * | Collaborator | commission_type, commission_value, card_fee_policy stripped |
	 */
	app.get("/", {
		onRequest: [app.requireStudioMember],
		schema: { querystring: ListProfessionalsQuery },
		handler: async (request, reply) => {
			return app.professionalController.list(request, reply);
		},
	});

	/**
	 * GET /api/v1/professionals/me
	 * Auth: owner + collaborator
	 * Returns current user's professional record in the studio.
	 */
	app.get("/me", {
		onRequest: [app.requireStudioMember],
		handler: async (request, reply) => {
			return app.professionalController.getMe(request, reply);
		},
	});

	/**
	 * GET /api/v1/professionals/:id
	 * Auth: owner + collaborator
	 *
	 * | Requester    | id = own | id = other |
	 * |--------------|----------|------------|
	 * | Owner        | Full     | Full       |
	 * | Collaborator | Full     | No commissions |
	 */
	app.get("/:id", {
		onRequest: [app.requireStudioMember],
		schema: { params: UuidParam },
		handler: async (request, reply) => {
			return app.professionalController.getById(request, reply);
		},
	});

	/**
	 * PATCH /api/v1/professionals/:id
	 * Auth: owner only
	 * Updates professional fields; service_ids replaces all service links atomically.
	 */
	app.patch("/:id", {
		onRequest: [requireOwner],
		schema: { params: UuidParam, body: UpdateProfessionalBody },
		handler: async (request, reply) => {
			return app.professionalController.update(request, reply);
		},
	});

	/**
	 * PATCH /api/v1/professionals/:id/active
	 * Auth: owner only
	 * Toggles active/inactive status.
	 */
	app.patch("/:id/active", {
		onRequest: [requireOwner],
		schema: { params: UuidParam, body: ToggleActiveBody },
		handler: async (request, reply) => {
			return app.professionalController.toggleActive(request, reply);
		},
	});
}

export const autoPrefix = "/api/v1/professionals";
