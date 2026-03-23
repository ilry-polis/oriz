import { describe, it, expect, vi, beforeEach } from 'vitest';
import { ProfessionalService } from '../../src/services/professional.service.js';
import type { ProfessionalRepository } from '../../src/repositories/professional.repository.js';
import { NotFoundError } from '../../src/utils/errors.js';

describe('ProfessionalService', () => {
  let service: ProfessionalService;
  let repo: ProfessionalRepository;

  beforeEach(() => {
    repo = { updateWorkingHours: vi.fn(), findByUserId: vi.fn() } as unknown as ProfessionalRepository;
    service = new ProfessionalService(repo);
  });

  it('updateWorkingHours updates when professional belongs to studio', async () => {
    (repo.updateWorkingHours as ReturnType<typeof vi.fn>).mockResolvedValue({ id: 'prof-1', working_hours: {} });
    const result = await service.updateWorkingHours('prof-1', 'studio-1', { monday: [] });
    expect(result.id).toBe('prof-1');
  });

  it('updateWorkingHours throws NotFoundError when not in studio', async () => {
    (repo.updateWorkingHours as ReturnType<typeof vi.fn>).mockResolvedValue(null);
    await expect(service.updateWorkingHours('prof-1', 'wrong', {})).rejects.toThrow(NotFoundError);
  });
});
