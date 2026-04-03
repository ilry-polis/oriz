import type { ServiceCategoryRepository } from "../repositories/service-category.repository.js";

export class ServiceCategoryService {
	constructor(private repo: ServiceCategoryRepository) {}

	async listByStudio(studioId: string, scope?: string) {
		if (scope === "studio") {
			return this.repo.listStudioOnly(studioId);
		}
		if (scope === "global") {
			return this.repo.listGlobal();
		}
		return this.repo.listByStudio(studioId);
	}

	async create(studioId: string, name: string, icon?: string, position?: number) {
		return this.repo.create(studioId, name, icon, position);
	}

	async update(
		id: string,
		studioId: string,
		data: { name?: string; icon?: string; position?: number; is_active?: boolean },
	) {
		return this.repo.update(id, studioId, data);
	}

	async delete(id: string, studioId: string) {
		const hasServices = await this.repo.hasServices(id);
		if (hasServices) {
			return { deleted: false, reason: "CATEGORY_HAS_SERVICES" };
		}
		const deleted = await this.repo.delete(id, studioId);
		return { deleted, reason: deleted ? null : "NOT_FOUND" };
	}

	async copyGlobalsToStudio(studioId: string, globalCategoryIds: string[]) {
		return this.repo.copyGlobalsToStudio(studioId, globalCategoryIds);
	}
}
