import type { ProfessionalRepository } from '../repositories/professional.repository.js';
import { NotFoundError } from '../utils/errors.js';

export class ProfessionalService {
  constructor(private repo: ProfessionalRepository) {}

  async updateWorkingHours(professionalId: string, studioId: string, workingHours: Record<string, unknown>) {
    const result = await this.repo.updateWorkingHours(professionalId, studioId, workingHours);
    if (!result) throw new NotFoundError('Professional not found in this studio');
    return result;
  }
}
