import type { ConsentRepository, ConsentType, ConsentAction } from '../repositories/consent.repository.js';

export class ConsentService {
  constructor(private repo: ConsentRepository) {}

  /**
   * Records a new "granted" consent entry (append-only — never update).
   */
  async grant(clientId: string, studioId: string, type: ConsentType): Promise<void> {
    await this.repo.insert({ clientId, studioId, type, action: 'granted' });
  }

  /**
   * Records a new "revoked" consent entry (append-only — never update).
   */
  async revoke(clientId: string, studioId: string, type: ConsentType): Promise<void> {
    await this.repo.insert({ clientId, studioId, type, action: 'revoked' });
  }

  /**
   * Returns the latest consent action, or null if no records exist.
   */
  async getCurrentConsent(
    clientId: string,
    studioId: string,
    type: ConsentType,
  ): Promise<ConsentAction | null> {
    return this.repo.getCurrentConsent(clientId, studioId, type);
  }
}
