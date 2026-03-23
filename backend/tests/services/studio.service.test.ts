import { describe, it, expect, vi, beforeEach } from 'vitest';
import { StudioService } from '../../src/services/studio.service.js';
import type { StudioRepository } from '../../src/repositories/studio.repository.js';
import type { OnboardingRepository } from '../../src/repositories/onboarding.repository.js';
import type { ProfessionalRepository } from '../../src/repositories/professional.repository.js';
import { ConflictError, NotFoundError } from '../../src/utils/errors.js';

function mockStudioRepo(): StudioRepository {
  return {
    findByOwnerId: vi.fn(),
    findBySlug: vi.fn(),
    findById: vi.fn(),
    createWithOnboarding: vi.fn(),
  } as unknown as StudioRepository;
}

function mockOnboardingRepo(): OnboardingRepository {
  return {
    findByStudioId: vi.fn(),
  } as unknown as OnboardingRepository;
}

function mockProfessionalRepo(): ProfessionalRepository {
  return {
    findByUserId: vi.fn(),
    updateWorkingHours: vi.fn(),
  } as unknown as ProfessionalRepository;
}

describe('StudioService', () => {
  let service: StudioService;
  let studioRepo: ReturnType<typeof mockStudioRepo>;
  let onboardingRepo: ReturnType<typeof mockOnboardingRepo>;
  let professionalRepo: ReturnType<typeof mockProfessionalRepo>;

  beforeEach(() => {
    studioRepo = mockStudioRepo();
    onboardingRepo = mockOnboardingRepo();
    professionalRepo = mockProfessionalRepo();
    service = new StudioService(studioRepo, onboardingRepo, professionalRepo);
  });

  describe('createStudio', () => {
    it('creates studio when slug is unique and user has no studio', async () => {
      (studioRepo.findByOwnerId as ReturnType<typeof vi.fn>).mockResolvedValue(null);
      (studioRepo.findBySlug as ReturnType<typeof vi.fn>).mockResolvedValue(null);
      (studioRepo.createWithOnboarding as ReturnType<typeof vi.fn>).mockResolvedValue({
        studio: { id: 'studio-1' },
        onboarding: { id: 'onb-1' },
        professional: { id: 'prof-1' },
      });

      const result = await service.createStudio({
        name: 'Test',
        slug: 'test',
        ownerId: 'user-1',
        ownerName: 'Ana',
        timezone: 'America/Sao_Paulo',
      });

      expect(result.studio.id).toBe('studio-1');
    });

    it('throws ConflictError when user already has a studio', async () => {
      (studioRepo.findByOwnerId as ReturnType<typeof vi.fn>).mockResolvedValue({ id: 'existing' });

      await expect(
        service.createStudio({ name: 'Test', slug: 'test', ownerId: 'user-1', ownerName: 'Ana', timezone: 'UTC' }),
      ).rejects.toThrow(ConflictError);
    });

    it('throws ConflictError when slug is taken', async () => {
      (studioRepo.findByOwnerId as ReturnType<typeof vi.fn>).mockResolvedValue(null);
      (studioRepo.findBySlug as ReturnType<typeof vi.fn>).mockResolvedValue({ id: 'other', slug: 'taken' });

      await expect(
        service.createStudio({ name: 'Test', slug: 'taken', ownerId: 'user-1', ownerName: 'Ana', timezone: 'UTC' }),
      ).rejects.toThrow(ConflictError);
    });
  });

  describe('getMyStudio', () => {
    it('returns studio with onboarding state and professional', async () => {
      (studioRepo.findByOwnerId as ReturnType<typeof vi.fn>).mockResolvedValue({ id: 'studio-1', name: 'Test' });
      (onboardingRepo.findByStudioId as ReturnType<typeof vi.fn>).mockResolvedValue({ current_step: 'services' });
      (professionalRepo.findByUserId as ReturnType<typeof vi.fn>).mockResolvedValue({ id: 'prof-1' });

      const result = await service.getMyStudio('user-1');

      expect(result.studio.id).toBe('studio-1');
      expect(result.onboarding.current_step).toBe('services');
      expect(result.professional?.id).toBe('prof-1');
    });

    it('throws NotFoundError when no studio', async () => {
      (studioRepo.findByOwnerId as ReturnType<typeof vi.fn>).mockResolvedValue(null);

      await expect(service.getMyStudio('nobody')).rejects.toThrow(NotFoundError);
    });
  });
});
