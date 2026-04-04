import type { FastifyInstance } from "fastify";
import { z } from "zod";

// ─── Zod Schemas ───────────────────────────────────────────

export const ListClientsQuery = z.object({
	search: z.string().optional(),
	tag: z.string().optional(),
	inactive_days: z.coerce.number().int().min(1).optional(),
	cursor: z.string().uuid().optional(),
	limit: z.coerce.number().int().min(1).max(100).default(20),
});

export const CreateClientBody = z.object({
	name: z.string().min(1),
	phone: z
		.string()
		.regex(/^\+?\d{10,15}$/, "Invalid phone number format")
		.optional(),
	email: z.string().email().optional(),
	birth_date: z.string().date().optional(),
	tags: z.array(z.string()).optional(),
	notes: z.string().optional(),
	marketing_consent: z.boolean().default(false),
});

export const UpdateClientBody = z.object({
	name: z.string().min(1).optional(),
	phone: z
		.string()
		.regex(/^\+?\d{10,15}$/, "Invalid phone number format")
		.optional(),
	email: z.string().email().optional(),
	birth_date: z.string().date().optional(),
	tags: z.array(z.string()).optional(),
	notes: z.string().optional(),
});

export const UpdateTagsBody = z.object({
	tags: z.array(z.string()),
});

export const ListClientAppointmentsQuery = z.object({
	status: z
		.enum(["pending", "confirmed", "completed", "cancelled", "no_show"])
		.optional(),
	cursor: z.string().uuid().optional(),
	limit: z.coerce.number().int().min(1).max(100).default(20),
});

export const ListPackageSubscriptionsQuery = z.object({
	status: z.enum(["active", "completed", "expired"]).optional(),
	cursor: z.string().uuid().optional(),
	limit: z.coerce.number().int().min(1).max(100).default(20),
});

export const UpsertAnamnesisBody = z.object({
	fields: z.record(z.string(), z.unknown()),
});

export const CreateConsentBody = z.object({
	type: z.enum(["marketing_whatsapp", "marketing_push"]),
	action: z.enum(["granted", "revoked"]),
});

const ClientIdParam = z.object({ id: z.string().uuid() });
const ClientIdWithCategoryParam = z.object({
	clientId: z.string().uuid(),
	categoryId: z.string().uuid(),
});
const ClientIdParam2 = z.object({ clientId: z.string().uuid() });

// ─── Route Plugin ──────────────────────────────────────────

export default async function clientRoutes(app: FastifyInstance) {
	app.addHook("onRequest", app.authenticate);

	// GET /api/v1/clients
	// Auth: owner+professional
	app.get("/", {
		onRequest: [app.requireStudioMember],
		schema: { querystring: ListClientsQuery },
		handler: async (request, reply) =>
			app.clientController.list(request, reply),
	});

	// POST /api/v1/clients
	// Auth: owner+professional
	// Dedup by phone when provided (409 PHONE_ALREADY_EXISTS). No dedup when phone omitted.
	app.post("/", {
		onRequest: [app.requireStudioMember],
		schema: { body: CreateClientBody },
		handler: async (request, reply) =>
			app.clientController.create(request, reply),
	});

	// GET /api/v1/clients/:id
	// Auth: owner+professional
	// Includes stats: total_appointments, total_spent, last_service
	app.get("/:id", {
		onRequest: [app.requireStudioMember],
		schema: { params: ClientIdParam },
		handler: async (request, reply) =>
			app.clientController.getById(request, reply),
	});

	// PATCH /api/v1/clients/:id
	// Auth: owner+professional
	app.patch("/:id", {
		onRequest: [app.requireStudioMember],
		schema: { params: ClientIdParam, body: UpdateClientBody },
		handler: async (request, reply) =>
			app.clientController.update(request, reply),
	});

	// PATCH /api/v1/clients/:id/tags
	// Auth: owner+professional — manual tags only (VIP, custom)
	app.patch("/:id/tags", {
		onRequest: [app.requireStudioMember],
		schema: { params: ClientIdParam, body: UpdateTagsBody },
		handler: async (request, reply) =>
			app.clientController.updateTags(request, reply),
	});

	// DELETE /api/v1/clients/:id
	// Auth: owner
	// Legacy stub — kept for compatibility. Anonymization is via POST /clients/:id/data-deletion
	app.delete("/:id", {
		onRequest: [app.requireOwner],
		schema: { params: ClientIdParam },
		handler: async (_request, _reply) => {
			// Hard delete is not supported — use POST /:id/data-deletion (LGPD anonymization)
			throw new Error(
				"Hard delete not supported. Use POST /clients/:id/data-deletion for LGPD anonymization.",
			);
		},
	});

	// ─── Client Appointments ──────────────────────────────────

	// GET /api/v1/clients/:id/appointments
	// Auth: owner+professional
	app.get("/:id/appointments", {
		onRequest: [app.requireStudioMember],
		schema: { params: ClientIdParam, querystring: ListClientAppointmentsQuery },
		handler: async (request, reply) =>
			app.clientController.listAppointments(request, reply),
	});

	// ─── Anamnesis ────────────────────────────────────────────

	// GET /api/v1/clients/:clientId/anamneses
	// Auth: owner+professional | No pagination (max ~15)
	app.get("/:clientId/anamneses", {
		onRequest: [app.requireStudioMember],
		schema: { params: ClientIdParam2 },
		handler: async (request, reply) =>
			app.anamnesisController.listByClient(request, reply),
	});

	// PUT /api/v1/clients/:clientId/anamneses/:categoryId
	// Auth: owner+professional | Upsert by (studio_id, client_id, service_category_id)
	app.put("/:clientId/anamneses/:categoryId", {
		onRequest: [app.requireStudioMember],
		schema: { params: ClientIdWithCategoryParam, body: UpsertAnamnesisBody },
		handler: async (request, reply) =>
			app.anamnesisController.upsert(request, reply),
	});

	// GET /api/v1/clients/:clientId/anamneses/:categoryId
	// Auth: owner+professional
	app.get("/:clientId/anamneses/:categoryId", {
		onRequest: [app.requireStudioMember],
		schema: { params: ClientIdWithCategoryParam },
		handler: async (request, reply) =>
			app.anamnesisController.getByClientAndCategory(request, reply),
	});

	// ─── Client Notes ─────────────────────────────────────────

	// POST /api/v1/clients/:clientId/notes
	// Auth: owner+professional | Immutable — no update/delete
	app.post("/:clientId/notes", {
		onRequest: [app.requireStudioMember],
		schema: {
			params: ClientIdParam2,
			body: z.object({ content: z.string().min(1) }),
		},
		handler: async (request, reply) =>
			app.clientNoteController.create(request, reply),
	});

	// GET /api/v1/clients/:clientId/notes
	// Auth: owner+professional
	app.get("/:clientId/notes", {
		onRequest: [app.requireStudioMember],
		schema: {
			params: ClientIdParam2,
			querystring: z.object({
				cursor: z.string().uuid().optional(),
				limit: z.coerce.number().int().min(1).max(100).default(20),
			}),
		},
		handler: async (request, reply) =>
			app.clientNoteController.listByClient(request, reply),
	});

	// ─── Package Subscriptions ────────────────────────────────

	// GET /api/v1/clients/:clientId/package-subscriptions
	// Auth: owner+professional
	app.get("/:clientId/package-subscriptions", {
		onRequest: [app.requireStudioMember],
		schema: {
			params: ClientIdParam2,
			querystring: ListPackageSubscriptionsQuery,
		},
		handler: async (_request, _reply) => {
			// → PackageSubscriptionController.listByClient (Phase 4)
			throw new Error("Not implemented");
		},
	});

	// ─── Consent Records (LGPD) ──────────────────────────────

	// GET /api/v1/clients/:clientId/consents
	// Auth: owner+professional | No pagination (max 2 records)
	app.get("/:clientId/consents", {
		onRequest: [app.requireStudioMember],
		schema: { params: ClientIdParam2 },
		handler: async (request, reply) =>
			app.consentController.list(request, reply),
	});

	// POST /api/v1/clients/:clientId/consents
	// Auth: owner+professional | Append-only
	app.post("/:clientId/consents", {
		onRequest: [app.requireStudioMember],
		schema: { params: ClientIdParam2, body: CreateConsentBody },
		handler: async (request, reply) =>
			app.consentController.create(request, reply),
	});

	// ─── Data Deletion (LGPD) ────────────────────────────────

	// POST /api/v1/clients/:clientId/data-deletion
	// Auth: owner
	// Anonymizes personal data, keeps financial records
	app.post("/:clientId/data-deletion", {
		onRequest: [app.requireOwner],
		schema: { params: ClientIdParam2 },
		handler: async (request, reply) =>
			app.clientController.dataDeletion(request, reply),
	});
}

export const autoPrefix = "/api/v1/clients";
