import type { FastifyReply, FastifyRequest } from "fastify";
import type { StudioAuthContext } from "../middlewares/auth.js";
import type { ServiceCategoryService } from "../services/service-category.service.js";

export class ServiceCategoryController {
	constructor(private service: ServiceCategoryService) {}

	async list(request: FastifyRequest, reply: FastifyReply) {
		const { studioId } = request.authContext as StudioAuthContext;
		const result = await this.service.listByStudio(studioId);
		return reply.send({ data: result });
	}
}
