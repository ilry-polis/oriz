import type { FastifyReply, FastifyRequest } from "fastify";
import type { StudioAuthContext } from "../middlewares/auth.js";
import type { AppointmentService } from "../services/appointment.service.js";

export class AppointmentController {
	constructor(private service: AppointmentService) {}

	// ─── Queries ──────────────────────────────────────────────────────────────

	async list(request: FastifyRequest, reply: FastifyReply) {
		const { studioId } = request.authContext as StudioAuthContext;
		const query = request.query as {
			date?: string;
			date_from?: string;
			date_to?: string;
			professional_id?: string;
			status?: "pending" | "confirmed" | "completed" | "cancelled" | "no_show";
			cursor?: string;
			limit: number;
		};

		const options = {
			professionalId: query.professional_id,
			status: query.status,
			cursor: query.cursor,
			limit: query.limit,
		};

		let data: Awaited<ReturnType<AppointmentService["listByDate"]>>;

		if (query.date) {
			data = await this.service.listByDate(studioId, query.date, options);
		} else {
			const dateFrom = query.date_from ?? new Date().toISOString().slice(0, 10);
			const dateTo = query.date_to ?? new Date().toISOString().slice(0, 10);
			data = await this.service.listByDateRange(
				studioId,
				dateFrom,
				dateTo,
				options,
			);
		}

		return reply.send({
			data,
			meta: { count: data.length, limit: query.limit },
		});
	}

	async monthSummary(request: FastifyRequest, reply: FastifyReply) {
		const { studioId } = request.authContext as StudioAuthContext;
		const query = request.query as {
			month: string;
			professional_id?: string;
		};

		// month = "2026-04" → dateFrom = "2026-04-01", dateTo = "2026-04-30"
		const [year, month] = query.month.split("-").map(Number);
		const dateFrom = `${year}-${String(month).padStart(2, "0")}-01`;
		const lastDay = new Date(year!, month!, 0).getDate();
		const dateTo = `${year}-${String(month).padStart(2, "0")}-${String(lastDay).padStart(2, "0")}`;

		const data = await this.service.monthSummary(
			studioId,
			dateFrom,
			dateTo,
			query.professional_id,
		);

		return reply.send({ data });
	}

	async getById(request: FastifyRequest, reply: FastifyReply) {
		const { studioId } = request.authContext as StudioAuthContext;
		const { id } = request.params as { id: string };

		const data = await this.service.getById(studioId, id);
		return reply.send({ data });
	}

	async availableSlots(request: FastifyRequest, reply: FastifyReply) {
		const { studioId } = request.authContext as StudioAuthContext;
		const query = request.query as {
			date: string;
			professional_id: string;
			service_id: string;
		};

		const data = await this.service.getAvailableSlots(
			studioId,
			query.professional_id,
			query.service_id,
			query.date,
		);

		return reply.send({ data });
	}

	// ─── Create ───────────────────────────────────────────────────────────────

	async create(request: FastifyRequest, reply: FastifyReply) {
		const { studioId } = request.authContext as StudioAuthContext;
		const body = request.body as {
			client_id: string;
			professional_id: string;
			service_id: string;
			date: string;
			start_time: string;
			notes?: string;
			source: "app" | "manual" | "web_page" | "whatsapp";
		};

		// Map 'whatsapp' source from client to the repository's 'whatsapp_ai' value
		const sourceMap: Record<
			string,
			"app" | "manual" | "web_page" | "whatsapp_ai"
		> = {
			app: "app",
			manual: "manual",
			web_page: "web_page",
			whatsapp: "whatsapp_ai",
		};

		const data = await this.service.createAppointment(studioId, {
			clientId: body.client_id,
			professionalId: body.professional_id,
			serviceId: body.service_id,
			date: body.date,
			startTime: body.start_time,
			notes: body.notes,
			source: sourceMap[body.source] ?? "manual",
		});

		return reply.status(201).send({ data });
	}

	// ─── Update (Reschedule) ──────────────────────────────────────────────────

	async update(request: FastifyRequest, reply: FastifyReply) {
		const { studioId } = request.authContext as StudioAuthContext;
		const { id } = request.params as { id: string };
		const body = request.body as {
			professional_id?: string;
			service_id?: string;
			date?: string;
			start_time?: string;
			notes?: string;
		};

		const data = await this.service.reschedule(studioId, id, {
			professionalId: body.professional_id,
			serviceId: body.service_id,
			date: body.date,
			startTime: body.start_time,
			notes: body.notes,
		});

		return reply.send({ data });
	}

	// ─── Status Transitions ───────────────────────────────────────────────────

	async confirm(request: FastifyRequest, reply: FastifyReply) {
		const { studioId } = request.authContext as StudioAuthContext;
		const { id } = request.params as { id: string };

		const data = await this.service.confirmAppointment(studioId, id);
		return reply.send({ data });
	}

	async complete(request: FastifyRequest, reply: FastifyReply) {
		const { studioId, role: userRole } =
			request.authContext as StudioAuthContext;
		const { id } = request.params as { id: string };
		const body = request.body as {
			package_subscription_id?: string;
			payments?: Array<{
				amount: number;
				method: "cash" | "pix" | "debit" | "credit";
				card_fee_percentage?: number;
			}>;
			discount_amount?: number;
			discount_reason?: string;
		};

		const result = await this.service.completeAppointment(studioId, id, {
			packageSubscriptionId: body.package_subscription_id,
			payment: body.payments
				? {
						payments: body.payments.map((p) => ({
							amount: p.amount,
							method: p.method,
							cardFeePercentage: p.card_fee_percentage,
						})),
						discountAmount: body.discount_amount,
						discountReason: body.discount_reason,
					}
				: undefined,
			userRole,
		});

		return reply.send({ data: result });
	}

	async cancel(request: FastifyRequest, reply: FastifyReply) {
		const { studioId } = request.authContext as StudioAuthContext;
		const { id } = request.params as { id: string };
		const body = request.body as { cancellation_reason?: string };

		const data = await this.service.cancelAppointment(
			studioId,
			id,
			body.cancellation_reason,
		);
		return reply.send({ data });
	}

	async noShow(request: FastifyRequest, reply: FastifyReply) {
		const { studioId } = request.authContext as StudioAuthContext;
		const { id } = request.params as { id: string };

		const data = await this.service.markNoShow(studioId, id);
		return reply.send({ data });
	}
}
