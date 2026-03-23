import { describe, it, expect, vi, beforeEach } from 'vitest';
import { ServiceCategoryService } from '../../src/services/service-category.service.js';
import type { ServiceCategoryRepository } from '../../src/repositories/service-category.repository.js';

describe('ServiceCategoryService', () => {
  let service: ServiceCategoryService;
  let repo: ServiceCategoryRepository;

  beforeEach(() => {
    repo = { listByStudio: vi.fn() } as unknown as ServiceCategoryRepository;
    service = new ServiceCategoryService(repo);
  });

  it('listByStudio delegates to repository', async () => {
    (repo.listByStudio as ReturnType<typeof vi.fn>).mockResolvedValue([{ id: 'cat-1', name: 'Unhas' }]);
    const result = await service.listByStudio('studio-1');
    expect(result).toHaveLength(1);
  });
});
