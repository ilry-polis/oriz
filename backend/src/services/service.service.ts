import type { ServiceRepository, CreateServiceInput } from '../repositories/service.repository.js';

type CreateServiceParams = Omit<CreateServiceInput, 'studioId'>;

export class ServiceService {
  constructor(private repo: ServiceRepository) {}

  async createService(studioId: string, params: CreateServiceParams) {
    return this.repo.create({ ...params, studioId });
  }
}
