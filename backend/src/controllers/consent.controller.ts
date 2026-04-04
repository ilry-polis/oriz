import type { FastifyReply, FastifyRequest } from "fastify";
import type { StudioAuthContext } from "../middlewares/auth.js";
import type { ConsentRepository } from "../repositories/consent.repository.js";
import type {
	ConsentAction,
	ConsentType,
} from "../repositories/consent.repository.js";
import type { ConsentService } from "../services/consent.service.js";

export class ConsentController {
	constructor(
		private service: ConsentService,
		private repo: ConsentRepository,
	) {}

	async list(request: FastifyRequest, reply: FastifyReply) {
		const { studioId } = request.authContext as StudioAuthContext;
		const { clientId } = request.params as { clientId: string };

		const records = await this.repo.listByClient(clientId, studioId);

		return reply.send({ data: records });
	}

	async create(request: FastifyRequest, reply: FastifyReply) {
		const { studioId } = request.authContext as StudioAuthContext;
		const { clientId } = request.params as { clientId: string };
		const body = request.body as { type: ConsentType; action: ConsentAction };

		if (body.action === "granted") {
			await this.service.grant(clientId, studioId, body.type);
		} else {
			await this.service.revoke(clientId, studioId, body.type);
		}

		return reply.status(201).send({
			data: { clientId, studioId, type: body.type, action: body.action },
		});
	}
}
