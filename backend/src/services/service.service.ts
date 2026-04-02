import type {
	CreateServiceInput,
	ServiceRepository,
	ServiceRow,
	UpdateServiceInput,
} from "../repositories/service.repository.js";
import { NotFoundError } from "../utils/errors.js";

type CreateServiceParams = Omit<CreateServiceInput, "studioId">;

export type ListServicesResult = {
	data: ServiceRow[];
	meta: {
		has_more: boolean;
		next_cursor: string | null;
	};
};

export class ServiceService {
	constructor(private repo: ServiceRepository) {}

	async createService(
		studioId: string,
		params: CreateServiceParams,
	): Promise<ServiceRow> {
		return this.repo.create({ ...params, studioId });
	}

	async listServices(
		studioId: string,
		cursor?: string,
		limit?: number,
	): Promise<ListServicesResult> {
		const result = await this.repo.list(studioId, cursor, limit);
		return {
			data: result.services,
			meta: {
				has_more: result.hasMore,
				next_cursor: result.nextCursor,
			},
		};
	}

	async getServiceById(
		studioId: string,
		serviceId: string,
	): Promise<ServiceRow> {
		const service = await this.repo.getById(studioId, serviceId);
		if (!service) {
			throw new NotFoundError(`Service ${serviceId} not found`);
		}
		return service;
	}

	async updateService(
		studioId: string,
		serviceId: string,
		data: UpdateServiceInput,
	): Promise<ServiceRow> {
		const existing = await this.repo.getById(studioId, serviceId);
		if (!existing) {
			throw new NotFoundError(`Service ${serviceId} not found`);
		}
		return this.repo.update(studioId, serviceId, data);
	}

	async setActive(
		studioId: string,
		serviceId: string,
		isActive: boolean,
	): Promise<ServiceRow> {
		const existing = await this.repo.getById(studioId, serviceId);
		if (!existing) {
			throw new NotFoundError(`Service ${serviceId} not found`);
		}
		return this.repo.setActive(studioId, serviceId, isActive);
	}

	async deleteService(studioId: string, serviceId: string): Promise<void> {
		const existing = await this.repo.getById(studioId, serviceId);
		if (!existing) {
			throw new NotFoundError(`Service ${serviceId} not found`);
		}
		await this.repo.softDelete(studioId, serviceId);
	}
}
