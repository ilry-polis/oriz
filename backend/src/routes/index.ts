import type { FastifyInstance } from 'fastify';

import authRoutes from './auth.routes';
import profileRoutes from './profile.routes';
import studioRoutes from './studios.routes';
import serviceCategoryRoutes from './service-categories.routes';
import serviceRoutes from './services.routes';
import professionalRoutes from './professionals.routes';
import clientRoutes from './clients.routes';
import appointmentRoutes from './appointments.routes';
import blockedSlotRoutes from './blocked-slots.routes';
import packageRoutes from './packages.routes';
import packageSubscriptionRoutes from './package-subscriptions.routes';
import paymentRoutes from './payments.routes';
import commissionRoutes from './commissions.routes';
import financialRoutes from './financial.routes';
import notificationRoutes from './notifications.routes';
import aiRoutes from './ai.routes';
import conversationRoutes from './conversations.routes';
import campaignRoutes from './campaigns.routes';
import billingRoutes from './billing.routes';
import auditLogRoutes from './audit-logs.routes';
import webhookRoutes from './webhooks.routes';
import publicStudioRoutes from './public/studios.routes';

export async function registerRoutes(app: FastifyInstance) {
  // ─── Auth (public + authenticated) ────────────────────────
  await app.register(authRoutes);

  // ─── Profile (authenticated) ──────────────────────────────
  await app.register(profileRoutes);

  // ─── Studios & Config (owner+professional) ────────────────
  await app.register(studioRoutes);

  // ─── Domain: Services ─────────────────────────────────────
  await app.register(serviceCategoryRoutes);
  await app.register(serviceRoutes);

  // ─── Domain: Team ─────────────────────────────────────────
  await app.register(professionalRoutes);

  // ─── Domain: Clients ──────────────────────────────────────
  await app.register(clientRoutes);

  // ─── Domain: Scheduling ───────────────────────────────────
  await app.register(appointmentRoutes);
  await app.register(blockedSlotRoutes);

  // ─── Domain: Packages ─────────────────────────────────────
  await app.register(packageRoutes);
  await app.register(packageSubscriptionRoutes);

  // ─── Domain: Financial (owner-only) ───────────────────────
  await app.register(paymentRoutes);
  await app.register(commissionRoutes);
  await app.register(financialRoutes);

  // ─── Notifications ────────────────────────────────────────
  await app.register(notificationRoutes);

  // ─── AI & Conversations ───────────────────────────────────
  await app.register(aiRoutes);
  await app.register(conversationRoutes);

  // ─── Marketing ────────────────────────────────────────────
  await app.register(campaignRoutes);

  // ─── Billing (SaaS) ──────────────────────────────────────
  await app.register(billingRoutes);

  // ─── Compliance ───────────────────────────────────────────
  await app.register(auditLogRoutes);

  // ─── Webhooks (signature-validated) ───────────────────────
  await app.register(webhookRoutes);

  // ─── Public (no auth) ─────────────────────────────────────
  await app.register(publicStudioRoutes);
}
