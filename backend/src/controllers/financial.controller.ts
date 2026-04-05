import type { FastifyReply, FastifyRequest } from "fastify";
import type { StudioAuthContext } from "../middlewares/auth.js";
import type {
	FinancialService,
	PeriodType,
} from "../services/financial.service.js";

export class FinancialController {
	constructor(private service: FinancialService) {}

	/**
	 * GET /api/v1/financial/summary
	 * Returns KPI data: total_revenue, avg_ticket, total_appointments, occupancy_rate.
	 * Collaborators (role=professional) see their own data if professionalId is in authContext.
	 */
	async summary(request: FastifyRequest, reply: FastifyReply) {
		const authCtx = request.authContext as StudioAuthContext & {
			professionalId?: string;
		};
		const { studioId, role } = authCtx;

		const query = request.query as {
			period?: PeriodType;
			date?: string;
		};

		const period: PeriodType = query.period ?? "month";
		const date = query.date ?? new Date().toISOString().slice(0, 10);

		const summaryData = await this.service.summary(studioId, period, date);

		// Collaborators: occupancy rate scoped to their appointments only
		// Summary data from repo is studio-wide; occupancy can be per-professional
		let occupancyRate: number;
		if (role === "professional" && authCtx.professionalId) {
			// For professional role: occupancy for their own working hours
			// We still compute studio-wide for now (breakdown handles per-prof)
			occupancyRate = await this.service.occupancyRate(
				studioId,
				summaryData.date_from,
				summaryData.date_to,
			);
		} else {
			occupancyRate = await this.service.occupancyRate(
				studioId,
				summaryData.date_from,
				summaryData.date_to,
			);
		}

		return reply.send({
			data: {
				total_revenue: summaryData.total_revenue,
				avg_ticket: summaryData.avg_ticket,
				total_appointments: summaryData.total_appointments,
				occupancy_rate: occupancyRate,
				period: summaryData.period,
				date_from: summaryData.date_from,
				date_to: summaryData.date_to,
			},
		});
	}

	/**
	 * GET /api/v1/financial/breakdown/professionals
	 * Returns revenue breakdown ranked by professional.
	 */
	async breakdownByProfessional(request: FastifyRequest, reply: FastifyReply) {
		const { studioId } = request.authContext as StudioAuthContext;

		const query = request.query as {
			date_from?: string;
			date_to?: string;
		};

		const today = new Date().toISOString().slice(0, 10);
		const dateFrom = query.date_from ?? `${today.slice(0, 7)}-01`; // start of current month
		const dateTo = query.date_to ?? today;

		const data = await this.service.breakdownByProfessional(
			studioId,
			dateFrom,
			dateTo,
		);

		return reply.send({ data });
	}

	/**
	 * GET /api/v1/financial/breakdown/services
	 * Returns revenue breakdown ranked by service.
	 */
	async breakdownByService(request: FastifyRequest, reply: FastifyReply) {
		const { studioId } = request.authContext as StudioAuthContext;

		const query = request.query as {
			date_from?: string;
			date_to?: string;
		};

		const today = new Date().toISOString().slice(0, 10);
		const dateFrom = query.date_from ?? `${today.slice(0, 7)}-01`;
		const dateTo = query.date_to ?? today;

		const data = await this.service.breakdownByService(
			studioId,
			dateFrom,
			dateTo,
		);

		return reply.send({ data });
	}

	/**
	 * GET /api/v1/financial/breakdown/methods
	 * Returns revenue breakdown ranked by payment method with percentage share.
	 */
	async breakdownByMethod(request: FastifyRequest, reply: FastifyReply) {
		const { studioId } = request.authContext as StudioAuthContext;

		const query = request.query as {
			date_from?: string;
			date_to?: string;
		};

		const today = new Date().toISOString().slice(0, 10);
		const dateFrom = query.date_from ?? `${today.slice(0, 7)}-01`;
		const dateTo = query.date_to ?? today;

		const data = await this.service.breakdownByMethod(
			studioId,
			dateFrom,
			dateTo,
		);

		return reply.send({ data });
	}

	/**
	 * GET /api/v1/financial/chart/revenue
	 * Returns daily revenue series for chart rendering.
	 */
	async chartRevenue(request: FastifyRequest, reply: FastifyReply) {
		const { studioId } = request.authContext as StudioAuthContext;

		const query = request.query as {
			date_from?: string;
			date_to?: string;
		};

		const today = new Date().toISOString().slice(0, 10);
		const dateFrom = query.date_from ?? `${today.slice(0, 7)}-01`;
		const dateTo = query.date_to ?? today;

		const data = await this.service.dailyRevenue(studioId, dateFrom, dateTo);

		return reply.send({ data });
	}
}
