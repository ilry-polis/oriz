import type { FastifyInstance } from "fastify";

// ─── Route Plugin ──────────────────────────────────────────
// Stub — webhook routes will be implemented in Phase 5-6

export default async function webhookRoutes(_app: FastifyInstance) {
	// Routes registered here when WhatsApp + Billing integrations are built
}

export const autoPrefix = "/api/v1/webhooks";
