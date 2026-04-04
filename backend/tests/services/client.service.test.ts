import { describe, it, expect, vi, beforeEach } from 'vitest';
import { ClientService } from '../../src/services/client.service.js';
import type { ClientRepository } from '../../src/repositories/client.repository.js';
import type { ConsentService } from '../../src/services/consent.service.js';
import type { AuditLogService } from '../../src/services/audit-log.service.js';
import { ConflictError, NotFoundError } from '../../src/utils/errors.js';

// ─── Factories ──────────────────────────────────────────────

function makeClient(overrides: Record<string, unknown> = {}) {
  return {
    id: 'client-1',
    studio_id: 'studio-a',
    name: 'Ana Lima',
    phone: '+5511999999999',
    email: 'ana@test.com',
    birth_date: null,
    tags: [],
    notes: null,
    last_appointment_at: null,
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
    ...overrides,
  };
}

// ─── Tests ──────────────────────────────────────────────────

describe('ClientService', () => {
  let service: ClientService;
  let repo: ClientRepository;
  let consentService: ConsentService;
  let auditLogService: AuditLogService;

  beforeEach(() => {
    repo = {
      create: vi.fn(),
      list: vi.fn(),
      getById: vi.fn(),
      update: vi.fn(),
      anonymize: vi.fn(),
    } as unknown as ClientRepository;

    consentService = {
      grant: vi.fn(),
      revoke: vi.fn(),
      getCurrentConsent: vi.fn(),
    } as unknown as ConsentService;

    auditLogService = {
      log: vi.fn(),
    } as unknown as AuditLogService;

    service = new ClientService(repo, consentService, auditLogService);
  });

  // ─── create ──────────────────────────────────────────────

  describe('createClient', () => {
    it('creates client with valid input and returns the client', async () => {
      const client = makeClient();
      (repo.create as ReturnType<typeof vi.fn>).mockResolvedValue(client);

      const result = await service.createClient('studio-a', 'user-1', {
        name: 'Ana Lima',
        phone: '+5511999999999',
      });

      expect(result).toEqual(client);
      expect(repo.create).toHaveBeenCalledWith(
        'studio-a',
        expect.objectContaining({ name: 'Ana Lima' }),
      );
    });

    it('calls consentService.grant when marketing_consent=true', async () => {
      const client = makeClient();
      (repo.create as ReturnType<typeof vi.fn>).mockResolvedValue(client);

      await service.createClient('studio-a', 'user-1', {
        name: 'Ana Lima',
        marketing_consent: true,
      });

      expect(consentService.grant).toHaveBeenCalledWith('client-1', 'studio-a', 'marketing_whatsapp');
    });

    it('does NOT call consentService.grant when marketing_consent=false', async () => {
      const client = makeClient();
      (repo.create as ReturnType<typeof vi.fn>).mockResolvedValue(client);

      await service.createClient('studio-a', 'user-1', {
        name: 'Ana Lima',
        marketing_consent: false,
      });

      expect(consentService.grant).not.toHaveBeenCalled();
    });

    it('throws ConflictError PHONE_ALREADY_EXISTS when repo throws duplicate phone', async () => {
      (repo.create as ReturnType<typeof vi.fn>).mockRejectedValue(
        new ConflictError('PHONE_ALREADY_EXISTS', 'Phone already exists'),
      );

      await expect(
        service.createClient('studio-a', 'user-1', { name: 'Ana Lima', phone: '+5511111111111' }),
      ).rejects.toThrow(ConflictError);
    });
  });

  // ─── list ────────────────────────────────────────────────

  describe('listClients', () => {
    it('returns empty data when no clients exist', async () => {
      (repo.list as ReturnType<typeof vi.fn>).mockResolvedValue({ rows: [], has_more: false, next_cursor: null });

      const result = await service.listClients('studio-a', { limit: 20 });

      expect(result.data).toHaveLength(0);
      expect(result.meta.has_more).toBe(false);
    });

    it('returns clients with cursor-based pagination', async () => {
      const clients = [makeClient({ id: 'c1' }), makeClient({ id: 'c2' })];
      (repo.list as ReturnType<typeof vi.fn>).mockResolvedValue({
        rows: clients,
        has_more: true,
        next_cursor: 'c2',
      });

      const result = await service.listClients('studio-a', { limit: 2 });

      expect(result.data).toHaveLength(2);
      expect(result.meta.has_more).toBe(true);
      expect(result.meta.next_cursor).toBe('c2');
    });

    it('passes search and tag filters to repository', async () => {
      (repo.list as ReturnType<typeof vi.fn>).mockResolvedValue({ rows: [], has_more: false, next_cursor: null });

      await service.listClients('studio-a', { search: 'Ana', tag: 'VIP', limit: 20 });

      expect(repo.list).toHaveBeenCalledWith(
        'studio-a',
        expect.objectContaining({ search: 'Ana', tag: 'VIP' }),
      );
    });

    it('multi-tenant: only passes studioId A to repo, never studioB data', async () => {
      (repo.list as ReturnType<typeof vi.fn>).mockResolvedValue({ rows: [], has_more: false, next_cursor: null });

      await service.listClients('studio-a', { limit: 20 });
      await service.listClients('studio-b', { limit: 20 });

      const calls = (repo.list as ReturnType<typeof vi.fn>).mock.calls;
      expect(calls[0][0]).toBe('studio-a');
      expect(calls[1][0]).toBe('studio-b');
    });

    it('enriches auto-tag "novo" for client with no appointments', async () => {
      const client = makeClient({ last_appointment_at: null });
      (repo.list as ReturnType<typeof vi.fn>).mockResolvedValue({
        rows: [client],
        has_more: false,
        next_cursor: null,
      });

      const result = await service.listClients('studio-a', { limit: 20 });

      expect(result.data[0]?.auto_tags).toContain('novo');
    });

    it('enriches auto-tag "inativo" for client with last appointment 60+ days ago', async () => {
      const oldDate = new Date();
      oldDate.setDate(oldDate.getDate() - 61);
      const client = makeClient({ last_appointment_at: oldDate.toISOString() });
      (repo.list as ReturnType<typeof vi.fn>).mockResolvedValue({
        rows: [client],
        has_more: false,
        next_cursor: null,
      });

      const result = await service.listClients('studio-a', { limit: 20 });

      expect(result.data[0]?.auto_tags).toContain('inativo');
    });

    it('does NOT enrich auto-tag "inativo" for client with recent appointment', async () => {
      const recentDate = new Date();
      recentDate.setDate(recentDate.getDate() - 10);
      const client = makeClient({ last_appointment_at: recentDate.toISOString() });
      (repo.list as ReturnType<typeof vi.fn>).mockResolvedValue({
        rows: [client],
        has_more: false,
        next_cursor: null,
      });

      const result = await service.listClients('studio-a', { limit: 20 });

      expect(result.data[0]?.auto_tags).not.toContain('inativo');
      expect(result.data[0]?.auto_tags).not.toContain('novo');
    });
  });

  // ─── getById ─────────────────────────────────────────────

  describe('getClientById', () => {
    it('returns client with auto_tags when found', async () => {
      const client = makeClient({ last_appointment_at: null });
      (repo.getById as ReturnType<typeof vi.fn>).mockResolvedValue(client);

      const result = await service.getClientById('studio-a', 'user-1', 'client-1');

      expect(result.id).toBe('client-1');
      expect(result.auto_tags).toContain('novo');
    });

    it('creates audit log entry on view', async () => {
      (repo.getById as ReturnType<typeof vi.fn>).mockResolvedValue(makeClient());

      await service.getClientById('studio-a', 'user-1', 'client-1');

      expect(auditLogService.log).toHaveBeenCalledWith(
        expect.objectContaining({
          userId: 'user-1',
          action: 'view',
          entityType: 'client',
          entityId: 'client-1',
          studioId: 'studio-a',
        }),
      );
    });

    it('throws NotFoundError when client not found', async () => {
      (repo.getById as ReturnType<typeof vi.fn>).mockResolvedValue(null);

      await expect(service.getClientById('studio-a', 'user-1', 'not-exist')).rejects.toThrow(
        NotFoundError,
      );
    });

    it('multi-tenant: wrong studio returns NotFoundError', async () => {
      (repo.getById as ReturnType<typeof vi.fn>).mockResolvedValue(null);

      await expect(service.getClientById('studio-b', 'user-1', 'client-1')).rejects.toThrow(
        NotFoundError,
      );
    });
  });

  // ─── update ──────────────────────────────────────────────

  describe('updateClient', () => {
    it('updates client and creates audit log entry', async () => {
      const client = makeClient({ name: 'Ana Souza' });
      (repo.update as ReturnType<typeof vi.fn>).mockResolvedValue(client);

      const result = await service.updateClient('studio-a', 'user-1', 'client-1', { name: 'Ana Souza' });

      expect(result.name).toBe('Ana Souza');
      expect(auditLogService.log).toHaveBeenCalledWith(
        expect.objectContaining({ action: 'edit', entityType: 'client' }),
      );
    });

    it('throws NotFoundError when client belongs to different studio', async () => {
      (repo.update as ReturnType<typeof vi.fn>).mockResolvedValue(null);

      await expect(
        service.updateClient('studio-b', 'user-1', 'client-1', { name: 'Foo' }),
      ).rejects.toThrow(NotFoundError);
    });
  });

  // ─── anonymize ───────────────────────────────────────────

  describe('anonymizeClient', () => {
    it('calls repo.anonymize and creates delete audit log entry', async () => {
      const anonymized = makeClient({
        name: 'Cliente removido',
        phone: null,
        email: null,
        tags: [],
      });
      (repo.anonymize as ReturnType<typeof vi.fn>).mockResolvedValue(anonymized);

      const result = await service.anonymizeClient('studio-a', 'user-1', 'client-1');

      expect(result.name).toBe('Cliente removido');
      expect(result.phone).toBeNull();
      expect(auditLogService.log).toHaveBeenCalledWith(
        expect.objectContaining({ action: 'delete', entityType: 'client' }),
      );
    });

    it('preserves the original client id after anonymization', async () => {
      const anonymized = makeClient({ id: 'client-1', name: 'Cliente removido', phone: null });
      (repo.anonymize as ReturnType<typeof vi.fn>).mockResolvedValue(anonymized);

      const result = await service.anonymizeClient('studio-a', 'user-1', 'client-1');

      expect(result.id).toBe('client-1');
    });
  });

  // ─── updateTags ──────────────────────────────────────────

  describe('updateTags', () => {
    it('updates manual tags JSONB array', async () => {
      const updated = makeClient({ tags: ['VIP', 'cliente-fiel'] });
      (repo.update as ReturnType<typeof vi.fn>).mockResolvedValue(updated);

      const result = await service.updateTags('studio-a', 'client-1', ['VIP', 'cliente-fiel']);

      expect(result.tags).toEqual(['VIP', 'cliente-fiel']);
    });
  });
});
