import { describe, it, expect, vi, beforeEach } from 'vitest';

// Mock jose — vi.hoisted runs before vi.mock factory
const { mockJwtVerify } = vi.hoisted(() => ({
  mockJwtVerify: vi.fn(),
}));

vi.mock('jose', () => ({
  jwtVerify: mockJwtVerify,
  createSecretKey: vi.fn((secret: Uint8Array) => secret),
}));

// Mock pg pool
const mockQuery = vi.fn();
const mockPool = { query: mockQuery };

import { buildAuthHook } from '../../src/middlewares/auth.js';
import { UnauthorizedError, ForbiddenError } from '../../src/utils/errors.js';

function createMockRequest(authHeader?: string) {
  return {
    headers: {
      authorization: authHeader,
    },
    authContext: undefined as unknown,
  } as unknown as Parameters<ReturnType<typeof buildAuthHook>>[0];
}

describe('buildAuthHook', () => {
  const jwtSecret = 'super-secret-jwt-key-at-least-32-chars-long';
  let authenticate: ReturnType<typeof buildAuthHook>;

  beforeEach(() => {
    vi.clearAllMocks();
    authenticate = buildAuthHook(mockPool as never, jwtSecret);
  });

  it('throws UnauthorizedError when no Authorization header', async () => {
    const request = createMockRequest();
    await expect(authenticate(request, {} as never)).rejects.toThrow(UnauthorizedError);
  });

  it('throws UnauthorizedError when token format is invalid', async () => {
    const request = createMockRequest('InvalidFormat token123');
    await expect(authenticate(request, {} as never)).rejects.toThrow(UnauthorizedError);
  });

  it('throws UnauthorizedError when JWT verification fails', async () => {
    mockJwtVerify.mockRejectedValueOnce(new Error('Invalid JWT'));
    const request = createMockRequest('Bearer invalid.jwt.token');

    await expect(authenticate(request, {} as never)).rejects.toThrow(UnauthorizedError);
  });

  it('decorates request with userId when JWT is valid (no studio required)', async () => {
    const userId = 'user-uuid-123';
    mockJwtVerify.mockResolvedValueOnce({
      payload: { sub: userId },
    });
    // No studio found — that's OK for authenticate (just sets userId)
    mockQuery.mockResolvedValueOnce({ rows: [], rowCount: 0 });

    const request = createMockRequest('Bearer valid.jwt.token');
    await authenticate(request, {} as never);

    expect((request as unknown as { authContext: { userId: string } }).authContext.userId).toBe(userId);
  });

  it('decorates request with studioId and role when user owns a studio', async () => {
    const userId = 'owner-uuid';
    const studioId = 'studio-uuid';
    mockJwtVerify.mockResolvedValueOnce({
      payload: { sub: userId },
    });
    mockQuery.mockResolvedValueOnce({
      rows: [{ studio_id: studioId, role: 'owner' }],
      rowCount: 1,
    });

    const request = createMockRequest('Bearer valid.jwt.token');
    await authenticate(request, {} as never);

    const ctx = (request as unknown as { authContext: { userId: string; studioId: string; role: string } }).authContext;
    expect(ctx.userId).toBe(userId);
    expect(ctx.studioId).toBe(studioId);
    expect(ctx.role).toBe('owner');
  });

  it('returns no studio when studio is inactive (is_active = false)', async () => {
    const userId = 'owner-inactive-studio';
    mockJwtVerify.mockResolvedValueOnce({
      payload: { sub: userId },
    });
    // Query with is_active filter returns no rows for inactive studio
    mockQuery.mockResolvedValueOnce({ rows: [], rowCount: 0 });

    const request = createMockRequest('Bearer valid.jwt.token');
    await authenticate(request, {} as never);

    const ctx = (request as unknown as { authContext: { userId: string; studioId?: string; role?: string } }).authContext;
    expect(ctx.userId).toBe(userId);
    expect(ctx.studioId).toBeUndefined();
    expect(ctx.role).toBeUndefined();
  });

  it('decorates request with studioId and role when user is a professional', async () => {
    const userId = 'pro-uuid';
    const studioId = 'studio-uuid-2';
    mockJwtVerify.mockResolvedValueOnce({
      payload: { sub: userId },
    });
    mockQuery.mockResolvedValueOnce({
      rows: [{ studio_id: studioId, role: 'professional' }],
      rowCount: 1,
    });

    const request = createMockRequest('Bearer valid.jwt.token');
    await authenticate(request, {} as never);

    const ctx = (request as unknown as { authContext: { userId: string; studioId: string; role: string } }).authContext;
    expect(ctx.studioId).toBe(studioId);
    expect(ctx.role).toBe('professional');
  });
});

describe('buildRequireStudio', () => {
  it('throws ForbiddenError when authContext has no studioId', async () => {
    const { buildRequireStudio } = await import('../../src/middlewares/auth.js');
    const requireStudio = buildRequireStudio();

    const request = { authContext: { userId: 'user-1' } };
    await expect(requireStudio(request as never, {} as never)).rejects.toThrow(ForbiddenError);
  });

  it('passes when authContext has studioId', async () => {
    const { buildRequireStudio } = await import('../../src/middlewares/auth.js');
    const requireStudio = buildRequireStudio();

    const request = { authContext: { userId: 'user-1', studioId: 'studio-1', role: 'owner' } };
    await expect(requireStudio(request as never, {} as never)).resolves.toBeUndefined();
  });
});

describe('buildRequireRole', () => {
  it('throws ForbiddenError when role does not match', async () => {
    const { buildRequireRole } = await import('../../src/middlewares/auth.js');
    const requireOwner = buildRequireRole('owner');

    const request = { authContext: { userId: 'user-1', studioId: 'studio-1', role: 'professional' } };
    await expect(requireOwner(request as never, {} as never)).rejects.toThrow(ForbiddenError);
  });

  it('passes when role matches', async () => {
    const { buildRequireRole } = await import('../../src/middlewares/auth.js');
    const requireOwner = buildRequireRole('owner');

    const request = { authContext: { userId: 'user-1', studioId: 'studio-1', role: 'owner' } };
    await expect(requireOwner(request as never, {} as never)).resolves.toBeUndefined();
  });

  it('owner role satisfies owner+professional check', async () => {
    const { buildRequireRole } = await import('../../src/middlewares/auth.js');
    const requireMember = buildRequireRole('owner', 'professional');

    const request = { authContext: { userId: 'user-1', studioId: 'studio-1', role: 'owner' } };
    await expect(requireMember(request as never, {} as never)).resolves.toBeUndefined();
  });
});
