import type { FastifyReply, FastifyRequest } from "fastify";
import type { StudioAuthContext } from "../middlewares/auth.js";
import type { AnamnesisService } from "../services/anamnesis.service.js";

export class AnamnesisController {
	constructor(private service: AnamnesisService) {}

	async upsert(request: FastifyRequest, reply: FastifyReply) {
		const { studioId } = request.authContext as StudioAuthContext;
		const { clientId, categoryId } = request.params as {
			clientId: string;
			categoryId: string;
		};
		const { fields } = request.body as { fields: Record<string, unknown> };

		const result = await this.service.upsert(
			studioId,
			clientId,
			categoryId,
			fields,
		);
		return reply.send({ data: result });
	}

	async getByClientAndCategory(request: FastifyRequest, reply: FastifyReply) {
		const { studioId } = request.authContext as StudioAuthContext;
		const { clientId, categoryId } = request.params as {
			clientId: string;
			categoryId: string;
		};

		const result = await this.service.getByClientAndCategory(
			studioId,
			clientId,
			categoryId,
		);
		return reply.send({ data: result });
	}

	async listByClient(request: FastifyRequest, reply: FastifyReply) {
		const { studioId } = request.authContext as StudioAuthContext;
		const { clientId } = request.params as { clientId: string };

		const result = await this.service.listByClient(studioId, clientId);
		return reply.send({ data: result });
	}
}
