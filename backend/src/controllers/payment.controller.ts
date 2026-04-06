import type { FastifyReply, FastifyRequest } from "fastify";
import type { StudioAuthContext } from "../middlewares/auth.js";
import type { PaymentMethod } from "../repositories/payment.repository.js";
import type { FinancialService } from "../services/financial.service.js";

export class PaymentController {
	constructor(private financialService: FinancialService) {}

	/**
	 * GET /api/v1/payments
	 * Paginated payment list with JOINs to appointments, clients, professionals.
	 * Owner only.
	 */
	async list(request: FastifyRequest, reply: FastifyReply) {
		const { studioId } = request.authContext as StudioAuthContext;

		const query = request.query as {
			date_from?: string;
			date_to?: string;
			method?: PaymentMethod;
			professional_id?: string;
			cursor?: string;
			limit: number;
		};

		const data = await this.financialService.listPayments(studioId, {
			dateFrom: query.date_from,
			dateTo: query.date_to,
			method: query.method,
			professionalId: query.professional_id,
			cursor: query.cursor,
			limit: query.limit,
		});

		const hasMore = data.length > query.limit;
		const items = hasMore ? data.slice(0, query.limit) : data;
		const nextCursor = hasMore ? items[items.length - 1]?.id : undefined;

		return reply.send({
			data: items,
			meta: {
				has_more: hasMore,
				next_cursor: nextCursor ?? null,
			},
		});
	}
}
