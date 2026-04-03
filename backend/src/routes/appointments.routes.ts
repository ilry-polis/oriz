import type { FastifyInstance } from "fastify";
import { z } from "zod";

// ─── Zod Schemas ───────────────────────────────────────────

// date is sugar for date_from=date & date_to=date.
// If date is present, date_from/date_to are ignored.
export const ListAppointmentsQuery = z
	.object({
		date: z.string().date().optional(),
		date_from: z.string().date().optional(),
		date_to: z.string().date().optional(),
		professional_id: z.string().uuid().optional(),
		status: z
			.enum(["pending", "confirmed", "completed", "cancelled", "no_show"])
			.optional(),
		cursor: z.string().uuid().optional(),
		limit: z.coerce.number().int().min(1).max(100).default(20),
	})
	.refine((data) => !(data.date && (data.date_from || data.date_to)), {
		message: "Use date OR date_from/date_to, not both",
		path: ["date"],
	});

export const CreateAppointmentBody = z.object({
	client_id: z.string().uuid(),
	professional_id: z.string().uuid(),
	service_id: z.string().uuid(),
	date: z.string().date(),
	start_time: z.string().datetime(),
	notes: z.string().optional(),
	source: z.enum(["app", "manual", "web_page", "whatsapp"]).default("app"),
});

export const UpdateAppointmentBody = z.object({
	professional_id: z.string().uuid().optional(),
	service_id: z.string().uuid().optional(),
	date: z.string().date().optional(),
	start_time: z.string().datetime().optional(),
	notes: z.string().optional(),
});

export const CompleteAppointmentBody = z.object({
	payment: z
		.object({
			amount: z.number().int().min(0),
			method: z.enum(["cash", "pix", "debit", "credit"]),
			card_fee_percentage: z.number().min(0).optional(),
		})
		.optional(),
});

export const CancelAppointmentBody = z.object({
	cancellation_reason: z.string().optional(),
});

export const AvailableSlotsQuery = z.object({
	date: z.string().date(),
	professional_id: z.string().uuid(),
	service_id: z.string().uuid(),
});

const UuidParam = z.object({ id: z.string().uuid() });

// ─── Route Plugin ──────────────────────────────────────────

export default async function appointmentRoutes(app: FastifyInstance) {
	app.addHook("onRequest", app.authenticate);

	// GET /api/v1/appointments
	// Auth: owner+professional
	app.get("/", {
		onRequest: [app.requireStudioMember],
		schema: { querystring: ListAppointmentsQuery },
		handler: async (request, reply) =>
			app.appointmentController.list(request, reply),
	});

	// POST /api/v1/appointments
	// Auth: owner+professional
	// end_time auto-calculated: start_time + duration_minutes + buffer_minutes
	app.post("/", {
		onRequest: [app.requireStudioMember],
		schema: { body: CreateAppointmentBody },
		handler: async (request, reply) =>
			app.appointmentController.create(request, reply),
	});

	// GET /api/v1/appointments/available-slots
	// Auth: owner+professional
	app.get("/available-slots", {
		onRequest: [app.requireStudioMember],
		schema: { querystring: AvailableSlotsQuery },
		handler: async (request, reply) =>
			app.appointmentController.availableSlots(request, reply),
	});

	// GET /api/v1/appointments/:id
	// Auth: owner+professional
	app.get("/:id", {
		onRequest: [app.requireStudioMember],
		schema: { params: UuidParam },
		handler: async (request, reply) =>
			app.appointmentController.getById(request, reply),
	});

	// PATCH /api/v1/appointments/:id
	// Auth: owner+professional
	// Error: 422 INVALID_STATUS_FOR_RESCHEDULE if status not in [pending, confirmed]
	app.patch("/:id", {
		onRequest: [app.requireStudioMember],
		schema: { params: UuidParam, body: UpdateAppointmentBody },
		handler: async (request, reply) =>
			app.appointmentController.update(request, reply),
	});

	// ─── Status Transitions ───────────────────────────────────

	// POST /api/v1/appointments/:id/confirm
	// Auth: owner+professional
	app.post("/:id/confirm", {
		onRequest: [app.requireStudioMember],
		schema: { params: UuidParam },
		handler: async (request, reply) =>
			app.appointmentController.confirm(request, reply),
	});

	// POST /api/v1/appointments/:id/complete
	// Auth: owner+professional
	// Returns { data: appointment } (payment recorded but not returned in response)
	app.post("/:id/complete", {
		onRequest: [app.requireStudioMember],
		schema: { params: UuidParam, body: CompleteAppointmentBody },
		handler: async (request, reply) =>
			app.appointmentController.complete(request, reply),
	});

	// POST /api/v1/appointments/:id/cancel
	// Auth: owner+professional
	app.post("/:id/cancel", {
		onRequest: [app.requireStudioMember],
		schema: { params: UuidParam, body: CancelAppointmentBody },
		handler: async (request, reply) =>
			app.appointmentController.cancel(request, reply),
	});

	// POST /api/v1/appointments/:id/no-show
	// Auth: owner+professional
	app.post("/:id/no-show", {
		onRequest: [app.requireStudioMember],
		schema: { params: UuidParam },
		handler: async (request, reply) =>
			app.appointmentController.noShow(request, reply),
	});
}

export const autoPrefix = "/api/v1/appointments";
