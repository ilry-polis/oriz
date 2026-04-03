import type { FastifyReply, FastifyRequest } from "fastify";
import type { StudioAuthContext } from "../middlewares/auth.js";
import type { UpdateServiceInput } from "../repositories/service.repository.js";
import type { ServiceService } from "../services/service.service.js";

export class ServiceController {
	constructor(private service: ServiceService) {}

	async create(request: FastifyRequest, reply: FastifyReply) {
		const { studioId } = request.authContext as StudioAuthContext;
		const body = request.body as {
			category_id: string;
			name: string;
			duration_minutes: number;
			price: number;
			buffer_minutes: number;
			is_active: boolean;
		};

		const result = await this.service.createService(studioId, {
			categoryId: body.category_id,
			name: body.name,
			durationMinutes: body.duration_minutes,
			price: body.price,
			bufferMinutes: body.buffer_minutes,
			isActive: body.is_active,
		});

		return reply.status(201).send({ data: result });
	}

	async list(request: FastifyRequest, reply: FastifyReply) {
		const { studioId } = request.authContext as StudioAuthContext;
		const query = request.query as {
			cursor?: string;
			limit?: number;
		};

		const result = await this.service.listServices(
			studioId,
			query.cursor,
			query.limit,
		);

		return reply.send(result);
	}

	async getById(request: FastifyRequest, reply: FastifyReply) {
		const { studioId } = request.authContext as StudioAuthContext;
		const { id } = request.params as { id: string };

		const service = await this.service.getServiceById(studioId, id);

		return reply.send({ data: service });
	}

	async update(request: FastifyRequest, reply: FastifyReply) {
		const { studioId } = request.authContext as StudioAuthContext;
		const { id } = request.params as { id: string };
		const body = request.body as {
			category_id?: string;
			name?: string;
			duration_minutes?: number;
			price?: number;
			buffer_minutes?: number;
		};

		const data: UpdateServiceInput = {};
		if (body.category_id !== undefined) data.categoryId = body.category_id;
		if (body.name !== undefined) data.name = body.name;
		if (body.duration_minutes !== undefined)
			data.durationMinutes = body.duration_minutes;
		if (body.price !== undefined) data.price = body.price;
		if (body.buffer_minutes !== undefined)
			data.bufferMinutes = body.buffer_minutes;

		const updated = await this.service.updateService(studioId, id, data);

		return reply.send({ data: updated });
	}

	async setActive(request: FastifyRequest, reply: FastifyReply) {
		const { studioId } = request.authContext as StudioAuthContext;
		const { id } = request.params as { id: string };
		const body = request.body as { is_active: boolean };

		const updated = await this.service.setActive(studioId, id, body.is_active);

		return reply.send({ data: updated });
	}

	async delete(request: FastifyRequest, reply: FastifyReply) {
		const { studioId } = request.authContext as StudioAuthContext;
		const { id } = request.params as { id: string };

		await this.service.deleteService(studioId, id);

		return reply.status(204).send();
	}
}
