import type { FastifyReply, FastifyRequest } from "fastify";
import type { StudioAuthContext } from "../middlewares/auth.js";
import type { ClientNoteService } from "../services/client-note.service.js";

export class ClientNoteController {
	constructor(private service: ClientNoteService) {}

	async create(request: FastifyRequest, reply: FastifyReply) {
		const { studioId, professionalId } = request.authContext as StudioAuthContext & {
			professionalId?: string;
		};
		const { clientId } = request.params as { clientId: string };
		const { content } = request.body as { content: string };

		if (!professionalId) {
			return reply.status(400).send({
				errors: [{ code: "MISSING_PROFESSIONAL", message: "Professional ID not found for this user" }],
			});
		}
		const profId = professionalId;
		const result = await this.service.create(
			studioId,
			clientId,
			profId,
			content,
		);
		return reply.status(201).send({ data: result });
	}

	async listByClient(request: FastifyRequest, reply: FastifyReply) {
		const { studioId } = request.authContext as StudioAuthContext;
		const { clientId } = request.params as { clientId: string };
		const query = request.query as { cursor?: string; limit?: number };

		const result = await this.service.listByClient(
			studioId,
			clientId,
			query.cursor,
			query.limit,
		);
		return reply.send(result);
	}
}
