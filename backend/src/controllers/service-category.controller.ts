import type { FastifyReply, FastifyRequest } from "fastify";
import type { StudioAuthContext } from "../middlewares/auth.js";
import type { ServiceCategoryService } from "../services/service-category.service.js";

export class ServiceCategoryController {
	constructor(private service: ServiceCategoryService) {}

	async list(request: FastifyRequest, reply: FastifyReply) {
		const { studioId } = request.authContext as StudioAuthContext;
		const { scope } = request.query as { scope?: string };
		const result = await this.service.listByStudio(studioId, scope);
		return reply.send({ data: result });
	}

	async create(request: FastifyRequest, reply: FastifyReply) {
		const { studioId } = request.authContext as StudioAuthContext;
		const { name, icon, position } = request.body as {
			name: string;
			icon?: string;
			position?: number;
		};
		const result = await this.service.create(studioId, name, icon, position);
		return reply.status(201).send({ data: result });
	}

	async update(request: FastifyRequest, reply: FastifyReply) {
		const { studioId } = request.authContext as StudioAuthContext;
		const { id } = request.params as { id: string };
		const body = request.body as {
			name?: string;
			icon?: string;
			position?: number;
			is_active?: boolean;
		};
		const result = await this.service.update(id, studioId, body);
		if (!result) {
			return reply.status(404).send({
				errors: [{ code: "NOT_FOUND", message: "Categoria não encontrada" }],
			});
		}
		return reply.send({ data: result });
	}

	async delete(request: FastifyRequest, reply: FastifyReply) {
		const { studioId } = request.authContext as StudioAuthContext;
		const { id } = request.params as { id: string };
		const result = await this.service.delete(id, studioId);
		if (!result.deleted) {
			if (result.reason === "CATEGORY_HAS_SERVICES") {
				return reply.status(409).send({
					errors: [
						{
							code: "CATEGORY_HAS_SERVICES",
							message: "Categoria possui serviços vinculados",
						},
					],
				});
			}
			return reply.status(404).send({
				errors: [{ code: "NOT_FOUND", message: "Categoria não encontrada" }],
			});
		}
		return reply.status(204).send();
	}

	async copyGlobals(request: FastifyRequest, reply: FastifyReply) {
		const { studioId } = request.authContext as StudioAuthContext;
		const { category_ids } = request.body as { category_ids: string[] };
		const result = await this.service.copyGlobalsToStudio(
			studioId,
			category_ids,
		);
		return reply.status(201).send({ data: result });
	}
}
