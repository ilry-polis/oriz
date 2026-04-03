import { describe, it, expect, vi, beforeEach } from 'vitest';
import { OnboardingService } from '../../src/services/onboarding.service.js';
import type { OnboardingRepository } from '../../src/repositories/onboarding.repository.js';
import { NotFoundError } from '../../src/utils/errors.js';

describe('OnboardingService', () => {
  let service: OnboardingService;
  let repo: OnboardingRepository;

  beforeEach(() => {
    repo = { findByStudioId: vi.fn(), updateStep: vi.fn() } as unknown as OnboardingRepository;
    service = new OnboardingService(repo);
  });

  it('getByStudioId returns onboarding state', async () => {
    (repo.findByStudioId as ReturnType<typeof vi.fn>).mockResolvedValue({ current_step: 'services' });
    const result = await service.getByStudioId('studio-1');
    expect(result.current_step).toBe('services');
  });

  it('getByStudioId throws NotFoundError when missing', async () => {
    (repo.findByStudioId as ReturnType<typeof vi.fn>).mockResolvedValue(null);
    await expect(service.getByStudioId('nobody')).rejects.toThrow(NotFoundError);
  });

  it('updateStep updates and returns', async () => {
    (repo.findByStudioId as ReturnType<typeof vi.fn>).mockResolvedValue({ current_step: 'business_hours' });
    (repo.updateStep as ReturnType<typeof vi.fn>).mockResolvedValue({ current_step: 'complete', completed_at: '2026-03-22' });
    const result = await service.updateStep('studio-1', 'complete');
    expect(result.current_step).toBe('complete');
  });
});
