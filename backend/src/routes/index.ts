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
// webhookRoutes requires validateWhatsAppSignature/validateBillingSignature
// middlewares that are not yet implemented. Re-enable when they exist.
// import webhookRoutes from './webhooks.routes';
import publicStudioRoutes from './public/studios.routes';

// autoPrefix is NOT supported by manual app.register() — it requires @fastify/autoload.
// Prefixes must be passed explicitly as the second argument.

export async function registerRoutes(app: FastifyInstance) {
  // ─── Auth (public + authenticated) ────────────────────────
  await app.register(authRoutes, { prefix: '/api/v1/auth' });

  // ─── Profile (authenticated) ──────────────────────────────
  await app.register(profileRoutes, { prefix: '/api/v1/profile' });

  // ─── Studios & Config (owner+professional) ────────────────
  await app.register(studioRoutes, { prefix: '/api/v1/studios' });

  // ─── Domain: Services ─────────────────────────────────────
  await app.register(serviceCategoryRoutes, { prefix: '/api/v1/service-categories' });
  await app.register(serviceRoutes, { prefix: '/api/v1/services' });

  // ─── Domain: Team ─────────────────────────────────────────
  await app.register(professionalRoutes, { prefix: '/api/v1/professionals' });

  // ─── Domain: Clients ──────────────────────────────────────
  await app.register(clientRoutes, { prefix: '/api/v1/clients' });

  // ─── Domain: Scheduling ───────────────────────────────────
  await app.register(appointmentRoutes, { prefix: '/api/v1/appointments' });
  await app.register(blockedSlotRoutes, { prefix: '/api/v1/blocked-slots' });

  // ─── Domain: Packages ─────────────────────────────────────
  await app.register(packageRoutes, { prefix: '/api/v1/packages' });
  await app.register(packageSubscriptionRoutes, { prefix: '/api/v1/package-subscriptions' });

  // ─── Domain: Financial (owner-only) ───────────────────────
  await app.register(paymentRoutes, { prefix: '/api/v1/payments' });
  await app.register(commissionRoutes, { prefix: '/api/v1/commissions' });
  await app.register(financialRoutes, { prefix: '/api/v1/financial' });

  // ─── Notifications ────────────────────────────────────────
  await app.register(notificationRoutes, { prefix: '/api/v1/device-tokens' });

  // ─── AI & Conversations ───────────────────────────────────
  await app.register(aiRoutes, { prefix: '/api/v1/ai' });
  await app.register(conversationRoutes, { prefix: '/api/v1/conversations' });

  // ─── Marketing ────────────────────────────────────────────
  await app.register(campaignRoutes, { prefix: '/api/v1/campaigns' });

  // ─── Billing (SaaS) ──────────────────────────────────────
  await app.register(billingRoutes, { prefix: '/api/v1/billing' });

  // ─── Compliance ───────────────────────────────────────────
  await app.register(auditLogRoutes, { prefix: '/api/v1/audit-logs' });

  // ─── Webhooks (signature-validated) ───────────────────────
  // Disabled: webhook middleware not yet implemented
  // await app.register(webhookRoutes, { prefix: '/api/v1/webhooks' });

  // ─── Public (no auth) ─────────────────────────────────────
  await app.register(publicStudioRoutes, { prefix: '/api/v1/public/studios' });
}
