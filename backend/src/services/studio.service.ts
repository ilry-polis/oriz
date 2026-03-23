import type { StudioRepository, CreateStudioInput } from '../repositories/studio.repository.js';
import type { OnboardingRepository } from '../repositories/onboarding.repository.js';
import type { ProfessionalRepository } from '../repositories/professional.repository.js';
import { ConflictError, NotFoundError } from '../utils/errors.js';

export class StudioService {
  constructor(
    private studioRepo: StudioRepository,
    private onboardingRepo: OnboardingRepository,
    private professionalRepo: ProfessionalRepository,
  ) {}

  async createStudio(input: CreateStudioInput) {
    const existing = await this.studioRepo.findByOwnerId(input.ownerId);
    if (existing) {
      throw new ConflictError('STUDIO_ALREADY_EXISTS', 'User already has a studio');
    }

    const slugTaken = await this.studioRepo.findBySlug(input.slug);
    if (slugTaken) {
      throw new ConflictError('SLUG_TAKEN', 'This slug is already in use', 'slug');
    }

    return this.studioRepo.createWithOnboarding(input);
  }

  async getMyStudio(userId: string) {
    const studio = await this.studioRepo.findByOwnerId(userId);
    if (!studio) {
      throw new NotFoundError('No studio found for this user');
    }

    const onboarding = await this.onboardingRepo.findByStudioId(studio.id);
    const professional = await this.professionalRepo.findByUserId(userId, studio.id);

    return { studio, onboarding, professional };
  }
}
