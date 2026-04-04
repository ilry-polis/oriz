import { describe, it, expect, vi, beforeEach } from 'vitest';
import { ConsentService } from '../../src/services/consent.service.js';
import type { ConsentRepository } from '../../src/repositories/consent.repository.js';

// ─── Tests ──────────────────────────────────────────────────

describe('ConsentService', () => {
  let service: ConsentService;
  let repo: ConsentRepository;

  beforeEach(() => {
    repo = {
      insert: vi.fn(),
      getCurrentConsent: vi.fn(),
    } as unknown as ConsentRepository;

    service = new ConsentService(repo);
  });

  // ─── grant ───────────────────────────────────────────────

  describe('grant', () => {
    it('inserts a granted consent record (append-only)', async () => {
      (repo.insert as ReturnType<typeof vi.fn>).mockResolvedValue(undefined);

      await service.grant('client-1', 'studio-a', 'marketing_whatsapp');

      expect(repo.insert).toHaveBeenCalledWith(
        expect.objectContaining({
          clientId: 'client-1',
          studioId: 'studio-a',
          type: 'marketing_whatsapp',
          action: 'granted',
        }),
      );
    });

    it('never calls an update — always inserts new record', async () => {
      (repo.insert as ReturnType<typeof vi.fn>).mockResolvedValue(undefined);

      await service.grant('client-2', 'studio-a', 'marketing_push');

      // Only insert should be called, not any update
      expect(repo.insert).toHaveBeenCalledTimes(1);
    });
  });

  // ─── revoke ──────────────────────────────────────────────

  describe('revoke', () => {
    it('inserts a revoked consent record (append-only)', async () => {
      (repo.insert as ReturnType<typeof vi.fn>).mockResolvedValue(undefined);

      await service.revoke('client-1', 'studio-a', 'marketing_whatsapp');

      expect(repo.insert).toHaveBeenCalledWith(
        expect.objectContaining({
          clientId: 'client-1',
          studioId: 'studio-a',
          type: 'marketing_whatsapp',
          action: 'revoked',
        }),
      );
    });

    it('never calls an update — always inserts new record', async () => {
      (repo.insert as ReturnType<typeof vi.fn>).mockResolvedValue(undefined);

      await service.revoke('client-3', 'studio-a', 'marketing_push');

      expect(repo.insert).toHaveBeenCalledTimes(1);
    });
  });

  // ─── getCurrentConsent ───────────────────────────────────

  describe('getCurrentConsent', () => {
    it('returns latest action when consent records exist', async () => {
      (repo.getCurrentConsent as ReturnType<typeof vi.fn>).mockResolvedValue('granted');

      const result = await service.getCurrentConsent('client-1', 'studio-a', 'marketing_whatsapp');

      expect(result).toBe('granted');
    });

    it('returns null when no consent records exist', async () => {
      (repo.getCurrentConsent as ReturnType<typeof vi.fn>).mockResolvedValue(null);

      const result = await service.getCurrentConsent('client-1', 'studio-a', 'marketing_whatsapp');

      expect(result).toBeNull();
    });

    it('returns revoked when last action was revoke', async () => {
      (repo.getCurrentConsent as ReturnType<typeof vi.fn>).mockResolvedValue('revoked');

      const result = await service.getCurrentConsent('client-1', 'studio-a', 'marketing_whatsapp');

      expect(result).toBe('revoked');
    });
  });
});
