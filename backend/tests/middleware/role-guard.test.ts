import { describe, it, expect, vi, beforeEach } from 'vitest';
import { requireOwner, requireSelf } from '../../src/middleware/role-guard.js';
import type { FastifyRequest, FastifyReply } from 'fastify';

// ─── Helpers ───────────────────────────────────────────────────────────────────

function makeReply() {
  const reply = {
    status: vi.fn().mockReturnThis(),
    send: vi.fn().mockReturnThis(),
  };
  return reply as unknown as FastifyReply;
}

function makeRequest(overrides: Record<string, unknown> = {}) {
  return {
    authContext: {
      userId: 'user-1',
      studioId: 'studio-1',
      role: 'owner',
    },
    params: {},
    ...overrides,
  } as unknown as FastifyRequest;
}

// ─── requireOwner ──────────────────────────────────────────────────────────────

describe('requireOwner', () => {
  it('passes without sending response when role is owner', async () => {
    const request = makeRequest({ authContext: { userId: 'u-1', studioId: 's-1', role: 'owner' } });
    const reply = makeReply();

    await requireOwner(request, reply);

    expect(reply.status).not.toHaveBeenCalled();
    expect(reply.send).not.toHaveBeenCalled();
  });

  it('returns 403 OWNER_ONLY when role is professional (collaborator)', async () => {
    const request = makeRequest({ authContext: { userId: 'u-1', studioId: 's-1', role: 'professional' } });
    const reply = makeReply();

    await requireOwner(request, reply);

    expect(reply.status).toHaveBeenCalledWith(403);
    expect(reply.send).toHaveBeenCalledWith(
      expect.objectContaining({
        errors: expect.arrayContaining([
          expect.objectContaining({ code: 'OWNER_ONLY' }),
        ]),
      }),
    );
  });

  it('returns 403 when authContext is missing', async () => {
    const request = makeRequest({ authContext: null });
    const reply = makeReply();

    await requireOwner(request, reply);

    expect(reply.status).toHaveBeenCalledWith(403);
  });
});

// ─── requireSelf ───────────────────────────────────────────────────────────────

describe('requireSelf', () => {
  it('passes for owner accessing any professional ID', async () => {
    const request = makeRequest({
      authContext: { userId: 'u-1', studioId: 's-1', role: 'owner', professionalId: 'prof-owner' },
      params: { id: 'prof-other' }, // accessing another professional
    });
    const reply = makeReply();

    await requireSelf(request, reply);

    expect(reply.status).not.toHaveBeenCalled();
  });

  it('passes for collaborator accessing own ID', async () => {
    const request = makeRequest({
      authContext: { userId: 'u-1', studioId: 's-1', role: 'professional', professionalId: 'prof-1' },
      params: { id: 'prof-1' }, // accessing own ID
    });
    const reply = makeReply();

    await requireSelf(request, reply);

    expect(reply.status).not.toHaveBeenCalled();
  });

  it('returns 403 when collaborator accesses another professional\'s ID', async () => {
    const request = makeRequest({
      authContext: { userId: 'u-1', studioId: 's-1', role: 'professional', professionalId: 'prof-1' },
      params: { id: 'prof-2' }, // accessing another professional — forbidden
    });
    const reply = makeReply();

    await requireSelf(request, reply);

    expect(reply.status).toHaveBeenCalledWith(403);
    expect(reply.send).toHaveBeenCalledWith(
      expect.objectContaining({
        errors: expect.arrayContaining([
          expect.objectContaining({ code: 'FORBIDDEN' }),
        ]),
      }),
    );
  });

  it('returns 403 when collaborator accesses without professionalId in context', async () => {
    const request = makeRequest({
      authContext: { userId: 'u-1', studioId: 's-1', role: 'professional' },
      params: { id: 'prof-1' },
    });
    const reply = makeReply();

    await requireSelf(request, reply);

    expect(reply.status).toHaveBeenCalledWith(403);
  });
});
