import type { ServiceRepository, CreateServiceInput } from '../repositories/service.repository.js';

type CreateServiceParams = Omit<CreateServiceInput, 'studioId'>;

export class ServiceService {
  constructor(private repo: ServiceRepository) {}

  async listServices(
    studioId: string,
    opts: { categoryId?: string; isActive?: boolean; cursor?: string; limit: number },
  ) {
    return this.repo.list(studioId, opts);
  }

  async createService(studioId: string, params: CreateServiceParams) {
    return this.repo.create({ ...params, studioId });
  }
}
