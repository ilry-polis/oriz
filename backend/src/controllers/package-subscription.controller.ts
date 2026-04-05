import type { FastifyReply, FastifyRequest } from "fastify";
import type { StudioAuthContext } from "../middlewares/auth.js";
import type { PackageService } from "../services/package.service.js";

export class PackageSubscriptionController {
	constructor(private service: PackageService) {}

	async getById(request: FastifyRequest, reply: FastifyReply) {
		const { studioId } = request.authContext as StudioAuthContext;
		const { id } = request.params as { id: string };

		const data = await this.service.getSubscriptionById(studioId, id);

		if (!data) {
			return reply.status(404).send({
				errors: [
					{ code: "RESOURCE_NOT_FOUND", message: "Subscription not found" },
				],
			});
		}

		return reply.send({ data });
	}

	async getActive(request: FastifyRequest, reply: FastifyReply) {
		const { studioId } = request.authContext as StudioAuthContext;
		const query = request.query as {
			client_id: string;
			service_id: string;
		};

		const data = await this.service.getActiveForClientService(
			studioId,
			query.client_id,
			query.service_id,
		);

		return reply.send({ data });
	}

	async extendExpiry(request: FastifyRequest, reply: FastifyReply) {
		const { studioId } = request.authContext as StudioAuthContext;
		const { id } = request.params as { id: string };
		const body = request.body as { expires_at: string };

		const data = await this.service.extendSubscriptionExpiry(
			studioId,
			id,
			body.expires_at,
		);

		if (!data) {
			return reply.status(404).send({
				errors: [
					{ code: "RESOURCE_NOT_FOUND", message: "Subscription not found" },
				],
			});
		}

		return reply.send({ data });
	}
}
