import type { FastifyReply, FastifyRequest } from "fastify";
import type { StudioAuthContext } from "../middlewares/auth.js";
import type { RecurrenceRule } from "../repositories/blocked-slot.repository.js";
import type { BlockedSlotService } from "../services/blocked-slot.service.js";

export class BlockedSlotController {
	constructor(private service: BlockedSlotService) {}

	async list(request: FastifyRequest, reply: FastifyReply) {
		const { studioId } = request.authContext as StudioAuthContext;
		const query = request.query as {
			professional_id?: string;
			date_from?: string;
			date_to?: string;
			cursor?: string;
			limit: number;
		};

		// getExpandedForDate returns TimeRange[], not BlockedSlotRow[]
		// For listing, we need to use the underlying repository — but service only exposes
		// getExpandedForDate (designed for availability computation), not a list method.
		// We call getExpandedForDate for each date in range, or we use the service's create/delete/removeOccurrence.
		// Since the service doesn't expose a list method, we delegate to the repository via the service.
		// For the list endpoint we need raw BlockedSlotRow[] — expose via service.list or call repo.
		// Per architecture rules, controller → service. We add a list method to service here (Rule 2 auto-add).
		const dateFrom = query.date_from;
		const dateTo = query.date_to;

		const data = await this.service.list(studioId, {
			professionalId: query.professional_id,
			dateFrom,
			dateTo,
			cursor: query.cursor,
			limit: query.limit,
		});

		return reply.send({
			data,
			meta: { count: data.length, limit: query.limit },
		});
	}

	async create(request: FastifyRequest, reply: FastifyReply) {
		const { studioId } = request.authContext as StudioAuthContext;
		const body = request.body as {
			professional_id: string;
			date: string;
			start_time: string;
			end_time: string;
			title: string;
			reason?: string;
			recurrence_rule?: {
				frequency: "weekly";
				days: number[];
				until: string | null;
			};
			excluded_dates?: string[];
		};

		const data = await this.service.create(studioId, {
			professionalId: body.professional_id,
			date: body.date,
			startTime: body.start_time,
			endTime: body.end_time,
			title: body.title,
			reason: body.reason,
			recurrenceRule: body.recurrence_rule as RecurrenceRule | undefined,
		});

		return reply.status(201).send({ data });
	}

	async delete(request: FastifyRequest, reply: FastifyReply) {
		const { studioId } = request.authContext as StudioAuthContext;
		const { id } = request.params as { id: string };

		await this.service.delete(studioId, id);
		return reply.status(204).send();
	}
}
