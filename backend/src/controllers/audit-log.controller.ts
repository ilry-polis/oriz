import type { FastifyReply, FastifyRequest } from "fastify";
import type { z } from "zod";
import type { StudioAuthContext } from "../middlewares/auth.js";
import type { AuditLogRepository } from "../repositories/audit-log.repository.js";
import type { ListAuditLogsQuery } from "../routes/audit-logs.routes.js";

type ListAuditLogsQueryType = z.infer<typeof ListAuditLogsQuery>;

export class AuditLogController {
	constructor(private repo: AuditLogRepository) {}

	async list(request: FastifyRequest, reply: FastifyReply) {
		const { studioId } = request.authContext as StudioAuthContext;
		const query = request.query as ListAuditLogsQueryType;

		const result = await this.repo.list({
			studioId,
			cursor: query.cursor,
			limit: query.limit,
			dateFrom: query.date_from,
			dateTo: query.date_to,
			action: query.action,
			entityType: query.entity_type,
		});

		return reply.send({
			data: result.rows,
			meta: {
				has_more: result.has_more,
				next_cursor: result.next_cursor,
			},
		});
	}
}
