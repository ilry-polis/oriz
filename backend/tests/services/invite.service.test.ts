import { describe, it, expect, vi, beforeEach } from 'vitest';
import { InviteService } from '../../src/services/invite.service.js';
import type { InviteRepository } from '../../src/repositories/invite.repository.js';
import type { ProfessionalRepository } from '../../src/repositories/professional.repository.js';
import { NotFoundError, ConflictError, ValidationError } from '../../src/utils/errors.js';

// ─── Helpers ───────────────────────────────────────────────────────────────────

function makeInviteRepo(overrides: Partial<InviteRepository> = {}): InviteRepository {
  return {
    create: vi.fn(),
    findByToken: vi.fn(),
    markUsed: vi.fn(),
    ...overrides,
  } as unknown as InviteRepository;
}

function makeProfessionalRepo(overrides = {}): ProfessionalRepository {
  return {
    create: vi.fn(),
    list: vi.fn(),
    getById: vi.fn(),
    update: vi.fn(),
    replaceServiceLinks: vi.fn(),
    getServiceLinks: vi.fn(),
    findByUserId: vi.fn(),
    updateWorkingHours: vi.fn(),
    ...overrides,
  } as unknown as ProfessionalRepository;
}

function makeSupabaseAdmin(overrides = {}) {
  return {
    auth: {
      admin: {
        createUser: vi.fn(),
        createSession: vi.fn(),
        deleteUser: vi.fn(),
      },
    },
    ...overrides,
  };
}

// ─── createInvite ───────────────────────────────────────────────────────────────

describe('InviteService.createInvite', () => {
  let inviteRepo: InviteRepository;
  let professionalRepo: ProfessionalRepository;
  let supabaseAdmin: ReturnType<typeof makeSupabaseAdmin>;
  let service: InviteService;

  beforeEach(() => {
    inviteRepo = makeInviteRepo();
    professionalRepo = makeProfessionalRepo();
    supabaseAdmin = makeSupabaseAdmin();
    service = new InviteService(inviteRepo, professionalRepo, supabaseAdmin as never);
  });

  it('creates invite and returns token, expires_at, and whatsapp_link', async () => {
    (inviteRepo.create as ReturnType<typeof vi.fn>).mockResolvedValueOnce(undefined);

    const result = await service.createInvite('studio-1', 'owner-1', {
      name: 'Ana',
      serviceIds: ['svc-1'],
      commissionType: 'percentage',
      commissionValue: 10,
      cardFeePolicy: 'studio',
    });

    expect(result.invite_token).toBeDefined();
    expect(result.invite_token).toMatch(
      /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/,
    );
    expect(result.expires_at).toBeInstanceOf(Date);
    expect(result.whatsapp_link).toContain('wa.me');
    expect(result.whatsapp_link).toContain(result.invite_token);
  });

  it('sets expiry to ~7 days from now', async () => {
    (inviteRepo.create as ReturnType<typeof vi.fn>).mockResolvedValueOnce(undefined);

    const before = Date.now();
    const result = await service.createInvite('studio-1', 'owner-1', {
      name: 'Ana',
      serviceIds: [],
      commissionType: 'percentage',
      commissionValue: 10,
      cardFeePolicy: 'studio',
    });
    const after = Date.now();

    const sevenDays = 7 * 24 * 60 * 60 * 1000;
    const expiresMs = result.expires_at.getTime();
    expect(expiresMs).toBeGreaterThanOrEqual(before + sevenDays - 1000);
    expect(expiresMs).toBeLessThanOrEqual(after + sevenDays + 1000);
  });

  it('calls inviteRepo.create with correct data', async () => {
    (inviteRepo.create as ReturnType<typeof vi.fn>).mockResolvedValueOnce(undefined);

    await service.createInvite('studio-1', 'owner-1', {
      name: 'Ana',
      serviceIds: ['svc-1'],
      commissionType: 'percentage',
      commissionValue: 10,
      cardFeePolicy: 'professional',
    });

    expect(inviteRepo.create).toHaveBeenCalledOnce();
    const callArg = (inviteRepo.create as ReturnType<typeof vi.fn>).mock.calls[0][0];
    expect(callArg.studioId).toBe('studio-1');
    expect(callArg.createdBy).toBe('owner-1');
    expect(callArg.name).toBe('Ana');
    expect(callArg.serviceIds).toEqual(['svc-1']);
    expect(callArg.commissionType).toBe('percentage');
    expect(callArg.commissionValue).toBe(10);
    expect(callArg.cardFeePolicy).toBe('professional');
  });
});

// ─── getInviteInfo ──────────────────────────────────────────────────────────────

describe('InviteService.getInviteInfo', () => {
  let inviteRepo: InviteRepository;
  let professionalRepo: ProfessionalRepository;
  let supabaseAdmin: ReturnType<typeof makeSupabaseAdmin>;
  let service: InviteService;

  beforeEach(() => {
    inviteRepo = makeInviteRepo();
    professionalRepo = makeProfessionalRepo();
    supabaseAdmin = makeSupabaseAdmin();
    service = new InviteService(inviteRepo, professionalRepo, supabaseAdmin as never);
  });

  it('returns studio info and name for valid token', async () => {
    (inviteRepo.findByToken as ReturnType<typeof vi.fn>).mockResolvedValueOnce({
      token: 'token-1',
      studio_id: 'studio-1',
      name: 'Ana',
      commission_type: 'percentage',
      commission_value: 10,
      card_fee_policy: 'studio',
      service_ids: [],
      expires_at: new Date(Date.now() + 86400000),
      used_at: null,
      created_at: new Date(),
      created_by: 'owner-1',
    });

    const result = await service.getInviteInfo('token-1');
    expect(result.name).toBe('Ana');
    expect(result.studio_id).toBe('studio-1');
  });

  it('throws NotFoundError when token does not exist', async () => {
    (inviteRepo.findByToken as ReturnType<typeof vi.fn>).mockResolvedValueOnce(null);
    await expect(service.getInviteInfo('bad-token')).rejects.toThrow(NotFoundError);
  });
});

// ─── acceptInvite ───────────────────────────────────────────────────────────────

describe('InviteService.acceptInvite', () => {
  let inviteRepo: InviteRepository;
  let professionalRepo: ProfessionalRepository;
  let supabaseAdmin: ReturnType<typeof makeSupabaseAdmin>;
  let service: InviteService;

  const validInvite = {
    token: 'token-1',
    studio_id: 'studio-1',
    name: 'Ana',
    commission_type: 'percentage',
    commission_value: 10,
    card_fee_policy: 'studio',
    service_ids: ['svc-1'],
    expires_at: new Date(Date.now() + 86400000), // valid: expires tomorrow
    used_at: null,
    created_at: new Date(),
    created_by: 'owner-1',
  };

  beforeEach(() => {
    inviteRepo = makeInviteRepo();
    professionalRepo = makeProfessionalRepo();
    supabaseAdmin = makeSupabaseAdmin();
    service = new InviteService(inviteRepo, professionalRepo, supabaseAdmin as never);
  });

  it('creates account and links professional on success', async () => {
    (inviteRepo.findByToken as ReturnType<typeof vi.fn>).mockResolvedValueOnce(validInvite);
    (supabaseAdmin.auth.admin.createUser as ReturnType<typeof vi.fn>).mockResolvedValueOnce({
      data: { user: { id: 'user-new' } },
      error: null,
    });
    (professionalRepo.create as ReturnType<typeof vi.fn>).mockResolvedValueOnce({
      id: 'prof-new',
      studio_id: 'studio-1',
      user_id: 'user-new',
      name: 'Ana',
    });
    (professionalRepo.replaceServiceLinks as ReturnType<typeof vi.fn>).mockResolvedValueOnce(undefined);
    (inviteRepo.markUsed as ReturnType<typeof vi.fn>).mockResolvedValueOnce(undefined);
    (supabaseAdmin.auth.admin.createSession as ReturnType<typeof vi.fn>).mockResolvedValueOnce({
      data: { session: { access_token: 'tok', refresh_token: 'ref' } },
      error: null,
    });

    const result = await service.acceptInvite('token-1', 'ana@email.com', 'senha123');
    expect(result).toBeDefined();
    expect(inviteRepo.markUsed).toHaveBeenCalledWith('token-1');
    expect(professionalRepo.create).toHaveBeenCalled();
    expect(professionalRepo.replaceServiceLinks).toHaveBeenCalledWith('prof-new', 'studio-1', ['svc-1']);
  });

  it('throws NotFoundError when token does not exist', async () => {
    (inviteRepo.findByToken as ReturnType<typeof vi.fn>).mockResolvedValueOnce(null);
    await expect(service.acceptInvite('bad', 'a@b.com', 'senha123')).rejects.toThrow(NotFoundError);
  });

  it('throws ValidationError when invite is expired', async () => {
    (inviteRepo.findByToken as ReturnType<typeof vi.fn>).mockResolvedValueOnce({
      ...validInvite,
      expires_at: new Date(Date.now() - 86400000), // expired: yesterday
    });
    await expect(service.acceptInvite('token-1', 'a@b.com', 'senha123')).rejects.toThrow(ValidationError);
  });

  it('throws ConflictError when invite already used', async () => {
    (inviteRepo.findByToken as ReturnType<typeof vi.fn>).mockResolvedValueOnce({
      ...validInvite,
      used_at: new Date(),
    });
    await expect(service.acceptInvite('token-1', 'a@b.com', 'senha123')).rejects.toThrow(ConflictError);
  });

  it('throws ConflictError EMAIL_ALREADY_EXISTS when Supabase rejects email', async () => {
    (inviteRepo.findByToken as ReturnType<typeof vi.fn>).mockResolvedValueOnce(validInvite);
    (supabaseAdmin.auth.admin.createUser as ReturnType<typeof vi.fn>).mockResolvedValueOnce({
      data: null,
      error: { message: 'User already registered', status: 422 },
    });

    await expect(service.acceptInvite('token-1', 'existing@email.com', 'senha123')).rejects.toThrow(
      ConflictError,
    );
  });
});
