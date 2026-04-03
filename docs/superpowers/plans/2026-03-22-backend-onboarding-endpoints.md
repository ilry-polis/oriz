# Backend Onboarding Endpoints Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the first real backend handlers (Route → Controller → Service → Repository) for studio creation, onboarding state, services, service-categories, and professional working hours — everything the onboarding wizard needs.

**Architecture:** Fastify routes (already scaffolded with Zod validation) → Controller (parse request, call service, format response) → Service (business logic, transactions) → Repository (SQL queries via `pg`). TDD mandatory — test the service layer first, then wire controllers.

**Tech Stack:** Node.js, Fastify, TypeScript, pg (node-postgres), Zod, Vitest

**Spec:** `docs/superpowers/specs/2026-03-22-onboarding-wizard-design.md`

**Existing code:**
- Routes with Zod schemas: `backend/src/routes/studios.routes.ts`, `services.routes.ts`, `professionals.routes.ts`, `service-categories.routes.ts`
- Auth middleware: `backend/src/middlewares/auth.ts` (provides `request.authContext` with `userId`, `studioId`, `role`)
- Error classes: `backend/src/utils/errors.ts` (AppError, NotFoundError, ConflictError, ValidationError)
- Database pool: `backend/src/config/database.ts` (Pool injected via `app.pool`)
- Type augmentation: `backend/src/types/fastify.d.ts` (StudioAuthContext at `backend/src/middlewares/auth.ts`)

**DB Tables:** studios, onboarding_states, professionals, services, service_categories (see spec for full schema)

---

## Task 1: Studio Repository — TDD

**Files:**
- Test: `backend/tests/repositories/studio.repository.test.ts`
- Create: `backend/src/repositories/studio.repository.ts`

- [ ] **Step 1: Write failing tests**

```typescript
import { describe, it, expect, vi, beforeEach } from 'vitest';
import type { Pool, PoolClient } from 'pg';
import { StudioRepository } from '../../src/repositories/studio.repository.js';

function mockPool() {
  const client = {
    query: vi.fn(),
    release: vi.fn(),
  } as unknown as PoolClient;
  const pool = {
    query: vi.fn(),
    connect: vi.fn().mockResolvedValue(client),
  } as unknown as Pool;
  return { pool, client };
}

describe('StudioRepository', () => {
  let repo: StudioRepository;
  let pool: Pool;
  let client: PoolClient;

  beforeEach(() => {
    const mocked = mockPool();
    pool = mocked.pool;
    client = mocked.client;
    repo = new StudioRepository(pool);
  });

  describe('findByOwnerId', () => {
    it('returns studio when found', async () => {
      const row = { id: 'studio-1', name: 'Test', slug: 'test', owner_id: 'user-1' };
      (pool.query as ReturnType<typeof vi.fn>).mockResolvedValue({ rows: [row] });

      const result = await repo.findByOwnerId('user-1');

      expect(result).toEqual(row);
      expect(pool.query).toHaveBeenCalledWith(
        expect.stringContaining('WHERE s.owner_id = $1'),
        ['user-1'],
      );
    });

    it('returns null when not found', async () => {
      (pool.query as ReturnType<typeof vi.fn>).mockResolvedValue({ rows: [] });

      const result = await repo.findByOwnerId('nobody');

      expect(result).toBeNull();
    });
  });

  describe('findBySlug', () => {
    it('returns studio when slug exists', async () => {
      const row = { id: 'studio-1', slug: 'taken' };
      (pool.query as ReturnType<typeof vi.fn>).mockResolvedValue({ rows: [row] });

      const result = await repo.findBySlug('taken');

      expect(result).toEqual(row);
    });
  });

  describe('createWithOnboarding', () => {
    it('creates studio, onboarding_state, and professional in transaction', async () => {
      (client.query as ReturnType<typeof vi.fn>)
        .mockResolvedValueOnce(undefined) // BEGIN
        .mockResolvedValueOnce({ rows: [{ id: 'studio-1' }] }) // INSERT studio
        .mockResolvedValueOnce({ rows: [{ id: 'onb-1' }] }) // INSERT onboarding_state
        .mockResolvedValueOnce({ rows: [{ id: 'prof-1' }] }) // INSERT professional
        .mockResolvedValueOnce(undefined); // COMMIT

      const result = await repo.createWithOnboarding({
        name: 'My Studio',
        slug: 'my-studio',
        ownerId: 'user-1',
        ownerName: 'Ana Silva',
        timezone: 'America/Sao_Paulo',
      });

      expect(result.studio.id).toBe('studio-1');
      expect(result.onboarding.id).toBe('onb-1');
      expect(result.professional.id).toBe('prof-1');
      expect(client.query).toHaveBeenCalledWith('BEGIN');
      expect(client.query).toHaveBeenCalledWith('COMMIT');
      expect(client.release).toHaveBeenCalled();
    });

    it('rolls back on failure', async () => {
      (client.query as ReturnType<typeof vi.fn>)
        .mockResolvedValueOnce(undefined) // BEGIN
        .mockRejectedValueOnce(new Error('DB error')); // INSERT fails

      await expect(
        repo.createWithOnboarding({
          name: 'Fail',
          slug: 'fail',
          ownerId: 'user-1',
          ownerName: 'Ana',
          timezone: 'America/Sao_Paulo',
        }),
      ).rejects.toThrow('DB error');

      expect(client.query).toHaveBeenCalledWith('ROLLBACK');
      expect(client.release).toHaveBeenCalled();
    });
  });

  describe('findById', () => {
    it('returns studio by id with studio_id filter', async () => {
      const row = { id: 'studio-1', name: 'Test' };
      (pool.query as ReturnType<typeof vi.fn>).mockResolvedValue({ rows: [row] });

      const result = await repo.findById('studio-1');

      expect(result).toEqual(row);
      expect(pool.query).toHaveBeenCalledWith(
        expect.stringContaining('WHERE s.id = $1'),
        ['studio-1'],
      );
    });
  });
});
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `cd backend && npx vitest run tests/repositories/studio.repository.test.ts`
Expected: FAIL — module does not exist

- [ ] **Step 3: Write implementation**

```typescript
import type { Pool } from 'pg';

export type StudioRow = {
  id: string;
  owner_id: string;
  name: string;
  slug: string;
  phone: string | null;
  address: string | null;
  description: string | null;
  timezone: string;
  settings: Record<string, unknown>;
  created_at: string;
  updated_at: string;
};

export type CreateStudioInput = {
  name: string;
  slug: string;
  ownerId: string;
  ownerName: string;
  phone?: string;
  address?: string;
  description?: string;
  timezone: string;
};

export type CreateStudioResult = {
  studio: { id: string; name: string; slug: string; timezone: string };
  onboarding: { id: string; studio_id: string; current_step: string };
  professional: { id: string; studio_id: string; user_id: string };
};

export class StudioRepository {
  constructor(private pool: Pool) {}

  async findByOwnerId(ownerId: string): Promise<StudioRow | null> {
    const { rows } = await this.pool.query<StudioRow>(
      `SELECT s.id, s.owner_id, s.name, s.slug, s.phone, s.address,
              s.description, s.timezone, s.settings, s.created_at, s.updated_at
       FROM studios s
       WHERE s.owner_id = $1
       LIMIT 1`,
      [ownerId],
    );
    return rows[0] ?? null;
  }

  async findBySlug(slug: string): Promise<{ id: string; slug: string } | null> {
    const { rows } = await this.pool.query<{ id: string; slug: string }>(
      `SELECT s.id, s.slug FROM studios s WHERE s.slug = $1 LIMIT 1`,
      [slug],
    );
    return rows[0] ?? null;
  }

  async findById(studioId: string): Promise<StudioRow | null> {
    const { rows } = await this.pool.query<StudioRow>(
      `SELECT s.id, s.owner_id, s.name, s.slug, s.phone, s.address,
              s.description, s.timezone, s.settings, s.created_at, s.updated_at
       FROM studios s
       WHERE s.id = $1
       LIMIT 1`,
      [studioId],
    );
    return rows[0] ?? null;
  }

  async createWithOnboarding(input: CreateStudioInput): Promise<CreateStudioResult> {
    const client = await this.pool.connect();
    try {
      await client.query('BEGIN');

      const { rows: studioRows } = await client.query<{ id: string; name: string; slug: string; timezone: string }>(
        `INSERT INTO studios (id, owner_id, name, slug, phone, address, description, timezone)
         VALUES (gen_random_uuid(), $1, $2, $3, $4, $5, $6, $7)
         RETURNING id, name, slug, timezone`,
        [input.ownerId, input.name, input.slug, input.phone ?? null, input.address ?? null, input.description ?? null, input.timezone],
      );
      const studio = studioRows[0];

      const { rows: onboardingRows } = await client.query<{ id: string; studio_id: string; current_step: string }>(
        `INSERT INTO onboarding_states (id, studio_id, current_step)
         VALUES (gen_random_uuid(), $1, 'studio_data')
         RETURNING id, studio_id, current_step`,
        [studio.id],
      );
      const onboarding = onboardingRows[0];

      const { rows: professionalRows } = await client.query<{ id: string; studio_id: string; user_id: string }>(
        `INSERT INTO professionals (id, studio_id, user_id, name, commission_type, commission_value)
         VALUES (gen_random_uuid(), $1, $2, $3, 'percentage', 0)
         RETURNING id, studio_id, user_id`,
        [studio.id, input.ownerId, input.ownerName],
      );
      const professional = professionalRows[0];

      await client.query('COMMIT');

      return { studio, onboarding, professional };
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `cd backend && npx vitest run tests/repositories/studio.repository.test.ts`
Expected: All tests PASS

- [ ] **Step 5: Commit**

```bash
git add backend/tests/repositories/studio.repository.test.ts backend/src/repositories/studio.repository.ts
git commit -m "feat: StudioRepository with TDD — CRUD + transactional createWithOnboarding"
```

---

## Task 2: Onboarding Repository — TDD

**Files:**
- Test: `backend/tests/repositories/onboarding.repository.test.ts`
- Create: `backend/src/repositories/onboarding.repository.ts`

- [ ] **Step 1: Write failing tests**

```typescript
import { describe, it, expect, vi, beforeEach } from 'vitest';
import type { Pool } from 'pg';
import { OnboardingRepository } from '../../src/repositories/onboarding.repository.js';

function mockPool() {
  return { query: vi.fn() } as unknown as Pool;
}

describe('OnboardingRepository', () => {
  let repo: OnboardingRepository;
  let pool: Pool;

  beforeEach(() => {
    pool = mockPool();
    repo = new OnboardingRepository(pool);
  });

  describe('findByStudioId', () => {
    it('returns onboarding state', async () => {
      const row = { id: 'onb-1', studio_id: 'studio-1', current_step: 'studio_data', completed_at: null };
      (pool.query as ReturnType<typeof vi.fn>).mockResolvedValue({ rows: [row] });

      const result = await repo.findByStudioId('studio-1');

      expect(result).toEqual(row);
      expect(pool.query).toHaveBeenCalledWith(
        expect.stringContaining('WHERE o.studio_id = $1'),
        ['studio-1'],
      );
    });

    it('returns null when not found', async () => {
      (pool.query as ReturnType<typeof vi.fn>).mockResolvedValue({ rows: [] });
      const result = await repo.findByStudioId('nobody');
      expect(result).toBeNull();
    });
  });

  describe('updateStep', () => {
    it('updates step without completed_at for non-complete steps', async () => {
      const row = { id: 'onb-1', current_step: 'services', completed_at: null };
      (pool.query as ReturnType<typeof vi.fn>).mockResolvedValue({ rows: [row] });

      const result = await repo.updateStep('studio-1', 'services');

      expect(result).toEqual(row);
      expect(pool.query).toHaveBeenCalledWith(
        expect.stringContaining('current_step = $1'),
        expect.arrayContaining(['services', 'studio-1']),
      );
    });

    it('sets completed_at when step is complete', async () => {
      const row = { id: 'onb-1', current_step: 'complete', completed_at: '2026-03-22T00:00:00Z' };
      (pool.query as ReturnType<typeof vi.fn>).mockResolvedValue({ rows: [row] });

      const result = await repo.updateStep('studio-1', 'complete');

      expect(result).toEqual(row);
      expect(pool.query).toHaveBeenCalledWith(
        expect.stringContaining('completed_at'),
        expect.arrayContaining(['complete', 'studio-1']),
      );
    });
  });
});
```

- [ ] **Step 2: Run tests, verify fail**
- [ ] **Step 3: Write implementation**

```typescript
import type { Pool } from 'pg';

export type OnboardingRow = {
  id: string;
  studio_id: string;
  current_step: string;
  completed_at: string | null;
  created_at: string;
  updated_at: string;
};

export class OnboardingRepository {
  constructor(private pool: Pool) {}

  async findByStudioId(studioId: string): Promise<OnboardingRow | null> {
    const { rows } = await this.pool.query<OnboardingRow>(
      `SELECT o.id, o.studio_id, o.current_step, o.completed_at, o.created_at, o.updated_at
       FROM onboarding_states o
       WHERE o.studio_id = $1
       LIMIT 1`,
      [studioId],
    );
    return rows[0] ?? null;
  }

  async updateStep(studioId: string, step: string): Promise<OnboardingRow | null> {
    const { rows } = await this.pool.query<OnboardingRow>(
      `UPDATE onboarding_states
       SET current_step = $1,
           completed_at = CASE WHEN $1 = 'complete' THEN now() ELSE completed_at END,
           updated_at = now()
       WHERE studio_id = $2
       RETURNING id, studio_id, current_step, completed_at, created_at, updated_at`,
      [step, studioId],
    );
    return rows[0] ?? null;
  }
}
```

- [ ] **Step 4: Run tests, verify pass**
- [ ] **Step 5: Commit**

```bash
git add backend/tests/repositories/onboarding.repository.test.ts backend/src/repositories/onboarding.repository.ts
git commit -m "feat: OnboardingRepository with TDD — findByStudioId + updateStep"
```

---

## Task 3: Service Repository — TDD

**Files:**
- Test: `backend/tests/repositories/service.repository.test.ts`
- Create: `backend/src/repositories/service.repository.ts`

- [ ] **Step 1: Write failing tests**

```typescript
import { describe, it, expect, vi, beforeEach } from 'vitest';
import type { Pool } from 'pg';
import { ServiceRepository } from '../../src/repositories/service.repository.js';

function mockPool() {
  return { query: vi.fn() } as unknown as Pool;
}

describe('ServiceRepository', () => {
  let repo: ServiceRepository;
  let pool: Pool;

  beforeEach(() => {
    pool = mockPool();
    repo = new ServiceRepository(pool);
  });

  describe('create', () => {
    it('inserts service with studio_id and returns it', async () => {
      const row = { id: 'svc-1', studio_id: 'studio-1', name: 'Manicure' };
      (pool.query as ReturnType<typeof vi.fn>).mockResolvedValue({ rows: [row] });

      const result = await repo.create({
        studioId: 'studio-1',
        categoryId: 'cat-1',
        name: 'Manicure',
        durationMinutes: 30,
        price: 5000,
        bufferMinutes: 0,
        isActive: true,
      });

      expect(result).toEqual(row);
      expect(pool.query).toHaveBeenCalledWith(
        expect.stringContaining('INSERT INTO services'),
        expect.arrayContaining(['studio-1', 'cat-1', 'Manicure', 30, 5000, 0, true]),
      );
    });
  });
});
```

- [ ] **Step 2: Run tests, verify fail**
- [ ] **Step 3: Write implementation**

```typescript
import type { Pool } from 'pg';

export type ServiceRow = {
  id: string;
  studio_id: string;
  category_id: string;
  name: string;
  duration_minutes: number;
  price: number;
  buffer_minutes: number;
  is_active: boolean;
  created_at: string;
  updated_at: string;
};

export type CreateServiceInput = {
  studioId: string;
  categoryId: string;
  name: string;
  durationMinutes: number;
  price: number;
  bufferMinutes: number;
  isActive: boolean;
};

export class ServiceRepository {
  constructor(private pool: Pool) {}

  async create(input: CreateServiceInput): Promise<ServiceRow> {
    const { rows } = await this.pool.query<ServiceRow>(
      `INSERT INTO services (id, studio_id, category_id, name, duration_minutes, price, buffer_minutes, is_active)
       VALUES (gen_random_uuid(), $1, $2, $3, $4, $5, $6, $7)
       RETURNING id, studio_id, category_id, name, duration_minutes, price, buffer_minutes, is_active, created_at, updated_at`,
      [input.studioId, input.categoryId, input.name, input.durationMinutes, input.price, input.bufferMinutes, input.isActive],
    );
    return rows[0];
  }
}
```

- [ ] **Step 4: Run tests, verify pass**
- [ ] **Step 5: Commit**

```bash
git add backend/tests/repositories/service.repository.test.ts backend/src/repositories/service.repository.ts
git commit -m "feat: ServiceRepository with TDD — create service"
```

---

## Task 4: ServiceCategory Repository — TDD

**Files:**
- Test: `backend/tests/repositories/service-category.repository.test.ts`
- Create: `backend/src/repositories/service-category.repository.ts`

- [ ] **Step 1: Write failing tests**

```typescript
import { describe, it, expect, vi, beforeEach } from 'vitest';
import type { Pool } from 'pg';
import { ServiceCategoryRepository } from '../../src/repositories/service-category.repository.js';

function mockPool() {
  return { query: vi.fn() } as unknown as Pool;
}

describe('ServiceCategoryRepository', () => {
  let repo: ServiceCategoryRepository;
  let pool: Pool;

  beforeEach(() => {
    pool = mockPool();
    repo = new ServiceCategoryRepository(pool);
  });

  describe('listByStudio', () => {
    it('returns global + studio categories', async () => {
      const rows = [
        { id: 'cat-1', name: 'Unhas', studio_id: null },
        { id: 'cat-2', name: 'Custom', studio_id: 'studio-1' },
      ];
      (pool.query as ReturnType<typeof vi.fn>).mockResolvedValue({ rows });

      const result = await repo.listByStudio('studio-1');

      expect(result).toEqual(rows);
      expect(pool.query).toHaveBeenCalledWith(
        expect.stringContaining('studio_id IS NULL OR studio_id = $1'),
        ['studio-1'],
      );
    });
  });
});
```

- [ ] **Step 2: Run tests, verify fail**
- [ ] **Step 3: Write implementation**

```typescript
import type { Pool } from 'pg';

export type ServiceCategoryRow = {
  id: string;
  studio_id: string | null;
  name: string;
  icon: string | null;
  position: number;
  is_active: boolean;
  created_at: string;
};

export class ServiceCategoryRepository {
  constructor(private pool: Pool) {}

  async listByStudio(studioId: string): Promise<ServiceCategoryRow[]> {
    const { rows } = await this.pool.query<ServiceCategoryRow>(
      `SELECT c.id, c.studio_id, c.name, c.icon, c.position, c.is_active, c.created_at
       FROM service_categories c
       WHERE (c.studio_id IS NULL OR c.studio_id = $1)
         AND c.is_active = true
       ORDER BY c.position ASC, c.name ASC
       LIMIT 50`,
      [studioId],
    );
    return rows;
  }
}
```

- [ ] **Step 4: Run tests, verify pass**
- [ ] **Step 5: Commit**

```bash
git add backend/tests/repositories/service-category.repository.test.ts backend/src/repositories/service-category.repository.ts
git commit -m "feat: ServiceCategoryRepository with TDD — listByStudio"
```

---

## Task 5: Professional Repository — TDD

**Files:**
- Test: `backend/tests/repositories/professional.repository.test.ts`
- Create: `backend/src/repositories/professional.repository.ts`

- [ ] **Step 1: Write failing tests**

```typescript
import { describe, it, expect, vi, beforeEach } from 'vitest';
import type { Pool } from 'pg';
import { ProfessionalRepository } from '../../src/repositories/professional.repository.js';

function mockPool() {
  return { query: vi.fn() } as unknown as Pool;
}

describe('ProfessionalRepository', () => {
  let repo: ProfessionalRepository;
  let pool: Pool;

  beforeEach(() => {
    pool = mockPool();
    repo = new ProfessionalRepository(pool);
  });

  describe('updateWorkingHours', () => {
    it('updates working_hours filtered by studio_id', async () => {
      const hours = { monday: [{ open: '09:00', close: '18:00' }] };
      const row = { id: 'prof-1', working_hours: hours };
      (pool.query as ReturnType<typeof vi.fn>).mockResolvedValue({ rows: [row] });

      const result = await repo.updateWorkingHours('prof-1', 'studio-1', hours);

      expect(result).toEqual(row);
      expect(pool.query).toHaveBeenCalledWith(
        expect.stringContaining('WHERE p.id = $1 AND p.studio_id = $2'),
        expect.arrayContaining(['prof-1', 'studio-1']),
      );
    });

    it('returns null when professional not in studio', async () => {
      (pool.query as ReturnType<typeof vi.fn>).mockResolvedValue({ rows: [] });

      const result = await repo.updateWorkingHours('prof-1', 'wrong-studio', {});

      expect(result).toBeNull();
    });
  });

  describe('findByUserId', () => {
    it('returns professional by user_id and studio_id', async () => {
      const row = { id: 'prof-1', user_id: 'user-1', studio_id: 'studio-1' };
      (pool.query as ReturnType<typeof vi.fn>).mockResolvedValue({ rows: [row] });

      const result = await repo.findByUserId('user-1', 'studio-1');

      expect(result).toEqual(row);
    });
  });
});
```

- [ ] **Step 2: Run tests, verify fail**
- [ ] **Step 3: Write implementation**

```typescript
import type { Pool } from 'pg';

export type ProfessionalRow = {
  id: string;
  studio_id: string;
  user_id: string;
  name: string;
  working_hours: Record<string, unknown>;
  is_active: boolean;
  created_at: string;
  updated_at: string;
};

export class ProfessionalRepository {
  constructor(private pool: Pool) {}

  async findByUserId(userId: string, studioId: string): Promise<ProfessionalRow | null> {
    const { rows } = await this.pool.query<ProfessionalRow>(
      `SELECT p.id, p.studio_id, p.user_id, p.name, p.working_hours, p.is_active, p.created_at, p.updated_at
       FROM professionals p
       WHERE p.user_id = $1 AND p.studio_id = $2
       LIMIT 1`,
      [userId, studioId],
    );
    return rows[0] ?? null;
  }

  async updateWorkingHours(
    professionalId: string,
    studioId: string,
    workingHours: Record<string, unknown>,
  ): Promise<ProfessionalRow | null> {
    const { rows } = await this.pool.query<ProfessionalRow>(
      `UPDATE professionals p
       SET working_hours = $3, updated_at = now()
       WHERE p.id = $1 AND p.studio_id = $2
       RETURNING p.id, p.studio_id, p.user_id, p.name, p.working_hours, p.is_active, p.created_at, p.updated_at`,
      [professionalId, studioId, JSON.stringify(workingHours)],
    );
    return rows[0] ?? null;
  }
}
```

- [ ] **Step 4: Run tests, verify pass**
- [ ] **Step 5: Commit**

```bash
git add backend/tests/repositories/professional.repository.test.ts backend/src/repositories/professional.repository.ts
git commit -m "feat: ProfessionalRepository with TDD — updateWorkingHours + findByUserId"
```

---

## Task 6: Studio Service — TDD

**Files:**
- Test: `backend/tests/services/studio.service.test.ts`
- Create: `backend/src/services/studio.service.ts`

- [ ] **Step 1: Write failing tests**

```typescript
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
        service.createStudio({ name: 'Test', slug: 'taken', ownerId: 'user-1', timezone: 'UTC' }),
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
```

- [ ] **Step 2: Run tests, verify fail**
- [ ] **Step 3: Write implementation**

```typescript
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
```

- [ ] **Step 4: Run tests, verify pass**
- [ ] **Step 5: Commit**

```bash
git add backend/tests/services/studio.service.test.ts backend/src/services/studio.service.ts
git commit -m "feat: StudioService with TDD — createStudio + getMyStudio"
```

---

## Task 7: Onboarding + Service + Professional Services — TDD

**Files:**
- Test: `backend/tests/services/onboarding.service.test.ts`
- Create: `backend/src/services/onboarding.service.ts`
- Test: `backend/tests/services/service.service.test.ts`
- Create: `backend/src/services/service.service.ts`
- Test: `backend/tests/services/professional.service.test.ts`
- Create: `backend/src/services/professional.service.ts`

These are simple pass-through services. Grouped for efficiency.

- [ ] **Step 1: Write failing tests for all three**

**onboarding.service.test.ts:**
```typescript
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
```

**service-category.service.test.ts:**
```typescript
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
```

**service.service.test.ts:**
```typescript
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
```

**professional.service.test.ts:**
```typescript
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
```

- [ ] **Step 2: Run all three test files, verify fail**
- [ ] **Step 3: Write implementations**

**onboarding.service.ts:**
```typescript
import type { OnboardingRepository } from '../repositories/onboarding.repository.js';
import { NotFoundError, ValidationError } from '../utils/errors.js';

const STEP_ORDER = ['studio_data', 'services', 'business_hours', 'complete'] as const;

export class OnboardingService {
  constructor(private repo: OnboardingRepository) {}

  async getByStudioId(studioId: string) {
    const state = await this.repo.findByStudioId(studioId);
    if (!state) throw new NotFoundError('Onboarding state not found');
    return state;
  }

  async updateStep(studioId: string, step: string) {
    // Validate forward-only transitions (skipping allowed, going back not)
    const current = await this.repo.findByStudioId(studioId);
    if (!current) throw new NotFoundError('Onboarding state not found');

    const currentIdx = STEP_ORDER.indexOf(current.current_step as typeof STEP_ORDER[number]);
    const targetIdx = STEP_ORDER.indexOf(step as typeof STEP_ORDER[number]);
    if (targetIdx <= currentIdx) {
      throw new ValidationError('Cannot go back to a previous step');
    }

    const updated = await this.repo.updateStep(studioId, step);
    if (!updated) throw new NotFoundError('Onboarding state not found');
    return updated;
  }
}
```

**service.service.ts:**
```typescript
import type { ServiceRepository, CreateServiceInput } from '../repositories/service.repository.js';

type CreateServiceParams = Omit<CreateServiceInput, 'studioId'>;

export class ServiceService {
  constructor(private repo: ServiceRepository) {}

  async createService(studioId: string, params: CreateServiceParams) {
    return this.repo.create({ ...params, studioId });
  }
}
```

**service-category.service.ts:**
```typescript
import type { ServiceCategoryRepository } from '../repositories/service-category.repository.js';

export class ServiceCategoryService {
  constructor(private repo: ServiceCategoryRepository) {}

  async listByStudio(studioId: string) {
    return this.repo.listByStudio(studioId);
  }
}
```

**professional.service.ts:**
```typescript
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
```

- [ ] **Step 4: Run all tests, verify pass**
- [ ] **Step 5: Commit**

```bash
git add backend/tests/services/ backend/src/services/
git commit -m "feat: OnboardingService, ServiceService, ProfessionalService with TDD"
```

---

## Task 8: Wire Controllers into Routes

**Files:**
- Create: `backend/src/controllers/studio.controller.ts`
- Create: `backend/src/controllers/onboarding.controller.ts`
- Create: `backend/src/controllers/service.controller.ts`
- Create: `backend/src/controllers/service-category.controller.ts`
- Create: `backend/src/controllers/professional.controller.ts`
- Modify: `backend/src/routes/studios.routes.ts` — replace stubs with controller calls
- Modify: `backend/src/routes/services.routes.ts` — replace POST stub
- Modify: `backend/src/routes/service-categories.routes.ts` — replace GET stub
- Modify: `backend/src/routes/professionals.routes.ts` — replace PATCH stub
- Modify: `backend/src/server.ts` — instantiate repositories, services, controllers and decorate app
- Modify: `backend/src/types/fastify.d.ts` — add controller types
- Modify: `backend/src/routes/professionals.routes.ts` — update WorkingHoursSchema to array format

This is the integration task — wiring everything together. Controllers are thin: parse request, call service, format response.

- [ ] **Step 1: Create controllers**

Each controller follows this pattern:
```typescript
import type { FastifyRequest, FastifyReply } from 'fastify';
import type { StudioService } from '../services/studio.service.js';
import type { StudioAuthContext } from '../middlewares/auth.js';

export class StudioController {
  constructor(private service: StudioService) {}

  async create(request: FastifyRequest, reply: FastifyReply) {
    const { userId } = request.authContext;
    const body = request.body as { name: string; slug: string; phone?: string; address?: string; description?: string; timezone: string };

    const result = await this.service.createStudio({
      name: body.name,
      slug: body.slug,
      phone: body.phone,
      address: body.address,
      description: body.description,
      ownerId: userId,
      ownerName: body.name, // Uses studio name as professional name; user can update later in profile
      timezone: body.timezone,
    });

    return reply.status(201).send({ data: result });
  }

  async getMe(request: FastifyRequest, reply: FastifyReply) {
    const { userId } = request.authContext;
    const result = await this.service.getMyStudio(userId);
    return reply.send({ data: result });
  }
}
```

Create similar controllers for Onboarding, Service, ServiceCategory, Professional. Each method: extract from request, call service, send response with `{ data }` envelope.

- [ ] **Step 2: Update server.ts — instantiate and decorate**

Add after existing decorators in server.ts:
```typescript
import { StudioRepository } from './repositories/studio.repository.js';
import { OnboardingRepository } from './repositories/onboarding.repository.js';
import { ServiceRepository } from './repositories/service.repository.js';
import { ServiceCategoryRepository } from './repositories/service-category.repository.js';
import { ProfessionalRepository } from './repositories/professional.repository.js';
import { StudioService } from './services/studio.service.js';
import { OnboardingService } from './services/onboarding.service.js';
import { ServiceService } from './services/service.service.js';
import { ServiceCategoryService } from './services/service-category.service.js';
import { ProfessionalService } from './services/professional.service.js';
import { StudioController } from './controllers/studio.controller.js';
import { OnboardingController } from './controllers/onboarding.controller.js';
import { ServiceController } from './controllers/service.controller.js';
import { ServiceCategoryController } from './controllers/service-category.controller.js';
import { ProfessionalController } from './controllers/professional.controller.js';

// Repositories
const studioRepo = new StudioRepository(pool);
const onboardingRepo = new OnboardingRepository(pool);
const serviceRepo = new ServiceRepository(pool);
const serviceCategoryRepo = new ServiceCategoryRepository(pool);
const professionalRepo = new ProfessionalRepository(pool);

// Services
const studioService = new StudioService(studioRepo, onboardingRepo, professionalRepo);
const onboardingService = new OnboardingService(onboardingRepo);
const serviceService = new ServiceService(serviceRepo);
const professionalService = new ProfessionalService(professionalRepo);

// Controllers
app.decorate('studioController', new StudioController(studioService));
app.decorate('onboardingController', new OnboardingController(onboardingService));
app.decorate('serviceController', new ServiceController(serviceService));
const serviceCategoryService = new ServiceCategoryService(serviceCategoryRepo);
app.decorate('serviceCategoryController', new ServiceCategoryController(serviceCategoryService));
app.decorate('professionalController', new ProfessionalController(professionalService));
```

- [ ] **Step 3: Update fastify.d.ts — add controller types**

- [ ] **Step 4: Update routes — replace stubs with controller calls**

Example for studios.routes.ts POST handler:
```typescript
handler: async (request, reply) => {
  return app.studioController.create(request, reply);
},
```

**IMPORTANT: `GET /studios/me` auth guard change.** The existing route uses `onRequest: [app.requireStudioMember]` which throws 403 for users without a studio. Change to NO additional guard (only the top-level `app.authenticate` applies). The handler returns 404 via `StudioService.getMyStudio` when user has no studio. This is required for onboarding redirect logic.

```typescript
// GET /api/v1/studios/me — remove requireStudioMember
app.get('/me', {
  // No onRequest guard — only authenticate (from addHook above)
  handler: async (request, reply) => {
    return app.studioController.getMe(request, reply);
  },
});
```

- [ ] **Step 5: Update WorkingHoursSchema in professionals.routes.ts to array format**

```typescript
const TimeSlot = z.object({
  open: z.string().regex(/^\d{2}:\d{2}$/, 'Format: HH:mm'),
  close: z.string().regex(/^\d{2}:\d{2}$/, 'Format: HH:mm'),
}).refine(d => d.close > d.open, { message: 'close must be after open' });

const WorkingHoursSchema = z.object({
  monday: z.array(TimeSlot).default([]),
  tuesday: z.array(TimeSlot).default([]),
  wednesday: z.array(TimeSlot).default([]),
  thursday: z.array(TimeSlot).default([]),
  friday: z.array(TimeSlot).default([]),
  saturday: z.array(TimeSlot).default([]),
  sunday: z.array(TimeSlot).default([]),
});
```

- [ ] **Step 6: Run all backend tests**

Run: `cd backend && npm test`
Expected: All existing tests pass + new tests pass

- [ ] **Step 7: Commit**

```bash
git add backend/src/controllers/ backend/src/server.ts backend/src/types/fastify.d.ts backend/src/routes/
git commit -m "feat: wire controllers into routes — first real backend handlers"
```

---

## Task 9: Full Backend Test Suite + Smoke Test

- [ ] **Step 1: Run complete test suite**

Run: `cd backend && npm test`
Expected: All tests pass (36 existing + ~20 new = ~56 total)

- [ ] **Step 2: Verify build**

Run: `cd backend && npm run build`
Expected: TypeScript compiles without errors

- [ ] **Step 3: Commit if needed**

---

## Summary

| Task | Descricao | TDD | Arquivos |
|------|-----------|-----|----------|
| 1 | StudioRepository | Sim | repository + test |
| 2 | OnboardingRepository | Sim | repository + test |
| 3 | ServiceRepository | Sim | repository + test |
| 4 | ServiceCategoryRepository | Sim | repository + test |
| 5 | ProfessionalRepository | Sim | repository + test |
| 6 | StudioService | Sim | service + test |
| 7 | Onboarding/Service/Professional Services | Sim | 3 services + 3 tests |
| 8 | Wire Controllers into Routes | Integracao | controllers + routes + server |
| 9 | Full Suite + Smoke | Verificacao | — |

**Ordem:** Repositories (1-5) → Services (6-7) → Controllers + Wiring (8) → Smoke (9)
