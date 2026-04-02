import type { FastifyReply, FastifyRequest } from "fastify";
import type { z } from "zod";
import type { StudioAuthContext } from "../middlewares/auth.js";
import type {
	CreateClientBody,
	ListClientsQuery,
	UpdateClientBody,
} from "../routes/clients.routes.js";
import type { ClientService } from "../services/client.service.js";

type CreateClientBodyType = z.infer<typeof CreateClientBody> & {
	marketing_consent?: boolean;
};
type UpdateClientBodyType = z.infer<typeof UpdateClientBody>;
type ListClientsQueryType = z.infer<typeof ListClientsQuery>;

export class ClientController {
	constructor(private service: ClientService) {}

	async create(request: FastifyRequest, reply: FastifyReply) {
		const { studioId, userId } = request.authContext as StudioAuthContext;
		const body = request.body as CreateClientBodyType;

		const client = await this.service.createClient(studioId, userId, {
			name: body.name,
			phone: body.phone,
			email: body.email,
			birth_date: body.birth_date,
			tags: body.tags,
			notes: body.notes,
			marketing_consent: body.marketing_consent,
		});

		return reply.status(201).send({ data: client });
	}

	async list(request: FastifyRequest, reply: FastifyReply) {
		const { studioId } = request.authContext as StudioAuthContext;
		const query = request.query as ListClientsQueryType;

		const result = await this.service.listClients(studioId, {
			search: query.search,
			tag: query.tag,
			cursor: query.cursor,
			limit: query.limit,
		});

		return reply.send(result);
	}

	async getById(request: FastifyRequest, reply: FastifyReply) {
		const { studioId, userId } = request.authContext as StudioAuthContext;
		const { id } = request.params as { id: string };

		const client = await this.service.getClientById(studioId, userId, id);

		return reply.send({ data: client });
	}

	async update(request: FastifyRequest, reply: FastifyReply) {
		const { studioId, userId } = request.authContext as StudioAuthContext;
		const { id } = request.params as { id: string };
		const body = request.body as UpdateClientBodyType;

		const client = await this.service.updateClient(studioId, userId, id, {
			name: body.name,
			phone: body.phone,
			email: body.email,
			birth_date: body.birth_date,
			tags: body.tags,
			notes: body.notes,
		});

		return reply.send({ data: client });
	}

	async updateTags(request: FastifyRequest, reply: FastifyReply) {
		const { studioId } = request.authContext as StudioAuthContext;
		const { id } = request.params as { id: string };
		const body = request.body as { tags: string[] };

		const client = await this.service.updateTags(studioId, id, body.tags);

		return reply.send({ data: client });
	}

	async dataDeletion(request: FastifyRequest, reply: FastifyReply) {
		const { studioId, userId } = request.authContext as StudioAuthContext;
		const { clientId } = request.params as { clientId: string };

		const client = await this.service.anonymizeClient(
			studioId,
			userId,
			clientId,
		);

		return reply.send({ data: client });
	}

	// Stub for future: list appointments per client
	async listAppointments(_request: FastifyRequest, _reply: FastifyReply) {
		throw new Error("Not implemented — Phase 3 (Appointments)");
	}
}
