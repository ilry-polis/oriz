import type { ServiceCategoryRepository } from '../repositories/service-category.repository.js';

export class ServiceCategoryService {
  constructor(private repo: ServiceCategoryRepository) {}

  async listByStudio(studioId: string) {
    return this.repo.listByStudio(studioId);
  }
}
