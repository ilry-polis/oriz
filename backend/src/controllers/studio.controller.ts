import type { FastifyReply, FastifyRequest } from "fastify";
import type { StudioService } from "../services/studio.service.js";

export class StudioController {
	constructor(private service: StudioService) {}

	async create(request: FastifyRequest, reply: FastifyReply) {
		const { userId, userName } = request.authContext;
		const body = request.body as {
			name: string;
			slug: string;
			phone?: string;
			address?: string;
			description?: string;
			timezone: string;
		};

		const result = await this.service.createStudio({
			name: body.name,
			slug: body.slug,
			phone: body.phone,
			address: body.address,
			description: body.description,
			ownerId: userId,
			ownerName: userName ?? body.name,
			timezone: body.timezone,
		});

		return reply.status(201).send({ data: result });
	}

	async getMe(request: FastifyRequest, reply: FastifyReply) {
		const { userId } = request.authContext;
		const result = await this.service.getMyStudio(userId);
		return reply.send({ data: result });
	}
}
