import { describe, it, expect, vi, beforeEach } from 'vitest';
import { ServiceService } from '../../src/services/service.service.js';
import type { ServiceRepository } from '../../src/repositories/service.repository.js';

describe('ServiceService', () => {
  let service: ServiceService;
  let repo: ServiceRepository;

  beforeEach(() => {
    repo = { create: vi.fn() } as unknown as ServiceRepository;
    service = new ServiceService(repo);
  });

  it('createService calls repo with studio_id', async () => {
    (repo.create as ReturnType<typeof vi.fn>).mockResolvedValue({ id: 'svc-1', name: 'Manicure' });

    const result = await service.createService('studio-1', {
      categoryId: 'cat-1', name: 'Manicure', durationMinutes: 30, price: 5000, bufferMinutes: 0, isActive: true,
    });

    expect(result.id).toBe('svc-1');
    expect(repo.create).toHaveBeenCalledWith(expect.objectContaining({ studioId: 'studio-1' }));
  });
});
