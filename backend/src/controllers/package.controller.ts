import type { FastifyReply, FastifyRequest } from "fastify";
import type { StudioAuthContext } from "../middlewares/auth.js";
import type { PackageService } from "../services/package.service.js";

export class PackageController {
	constructor(private service: PackageService) {}

	async list(request: FastifyRequest, reply: FastifyReply) {
		const { studioId } = request.authContext as StudioAuthContext;
		const query = request.query as {
			cursor?: string;
			limit: number;
			service_id?: string;
		};

		const result = await this.service.list(studioId, {
			serviceId: query.service_id,
			cursor: query.cursor,
			limit: query.limit,
		});

		return reply.send({
			data: result.packages,
			meta: {
				hasMore: result.hasMore,
				nextCursor: result.nextCursor,
				limit: query.limit,
			},
		});
	}

	async getById(request: FastifyRequest, reply: FastifyReply) {
		const { studioId } = request.authContext as StudioAuthContext;
		const { id } = request.params as { id: string };

		const data = await this.service.getById(studioId, id);
		return reply.send({ data });
	}

	async create(request: FastifyRequest, reply: FastifyReply) {
		const { studioId } = request.authContext as StudioAuthContext;
		const body = request.body as {
			service_ids: string[];
			name: string;
			total_sessions: number;
			price: number;
			validity_days: number;
		};

		const data = await this.service.create(studioId, {
			serviceIds: body.service_ids,
			name: body.name,
			totalSessions: body.total_sessions,
			price: body.price,
			validityDays: body.validity_days,
		});

		return reply.status(201).send({ data });
	}

	async update(request: FastifyRequest, reply: FastifyReply) {
		const { studioId } = request.authContext as StudioAuthContext;
		const { id } = request.params as { id: string };
		const body = request.body as {
			name?: string;
			total_sessions?: number;
			price?: number;
			validity_days?: number;
		};

		const data = await this.service.update(studioId, id, {
			name: body.name,
			totalSessions: body.total_sessions,
			price: body.price,
			validityDays: body.validity_days,
		});

		return reply.send({ data });
	}

	async delete(request: FastifyRequest, reply: FastifyReply) {
		const { studioId } = request.authContext as StudioAuthContext;
		const { id } = request.params as { id: string };

		await this.service.delete(studioId, id);
		return reply.status(204).send();
	}

	async listSubscriptions(request: FastifyRequest, reply: FastifyReply) {
		const { studioId } = request.authContext as StudioAuthContext;
		const { packageId } = request.params as { packageId: string };
		const query = request.query as {
			status?: "active" | "completed" | "expired";
			cursor?: string;
			limit: number;
		};

		const result = await this.service.listSubscriptions(studioId, {
			packageId,
			status: query.status,
			cursor: query.cursor,
			limit: query.limit,
		});

		return reply.send({
			data: result.subscriptions,
			meta: {
				hasMore: result.hasMore,
				nextCursor: result.nextCursor,
				limit: query.limit,
			},
		});
	}

	async createSubscription(request: FastifyRequest, reply: FastifyReply) {
		const { studioId } = request.authContext as StudioAuthContext;
		const { packageId } = request.params as { packageId: string };
		const body = request.body as { client_id: string };

		const data = await this.service.createSubscription(
			studioId,
			packageId,
			body.client_id,
		);

		return reply.status(201).send({ data });
	}
}
