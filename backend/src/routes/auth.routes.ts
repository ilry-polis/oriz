import type { FastifyInstance } from "fastify";
import { z } from "zod";

// ─── Zod Schemas ───────────────────────────────────────────

export const SignupBody = z.object({
	email: z.string().email(),
	password: z.string().min(8),
	full_name: z.string().min(1),
});

export const AcceptInviteBody = z.object({
	token: z.string().uuid(),
	email: z.string().email(),
	password: z.string().min(8, "A senha deve ter pelo menos 8 caracteres"),
});

export const LoginBody = z.object({
	email: z.string().email(),
	password: z.string(),
});

export const RefreshBody = z.object({
	refresh_token: z.string().min(1),
});

export const ForgotPasswordBody = z.object({
	email: z.string().email(),
});

// ─── Route Plugin ──────────────────────────────────────────

export default async function authRoutes(app: FastifyInstance) {
	// POST /api/v1/auth/signup
	// Auth: public | Rate limit: 5/min per IP
	app.post("/signup", {
		schema: { body: SignupBody },
		config: { rateLimit: { max: 5, timeWindow: "1 minute" } },
		handler: async (_request, _reply) => {
			// → AuthController.signup
			throw new Error("Not implemented");
		},
	});

	// POST /api/v1/auth/login
	// Auth: public | Rate limit: 10/min per IP
	app.post("/login", {
		schema: { body: LoginBody },
		config: { rateLimit: { max: 10, timeWindow: "1 minute" } },
		handler: async (_request, _reply) => {
			// → AuthController.login
			throw new Error("Not implemented");
		},
	});

	// POST /api/v1/auth/logout
	// Auth: authenticated
	app.post("/logout", {
		onRequest: [app.authenticate],
		handler: async (_request, _reply) => {
			// → AuthController.logout
			throw new Error("Not implemented");
		},
	});

	// POST /api/v1/auth/refresh
	// Auth: public | Rate limit: 30/min per IP
	app.post("/refresh", {
		schema: { body: RefreshBody },
		config: { rateLimit: { max: 30, timeWindow: "1 minute" } },
		handler: async (_request, _reply) => {
			// → AuthController.refresh
			throw new Error("Not implemented");
		},
	});

	// POST /api/v1/auth/forgot-password
	// Auth: public | Rate limit: 3/min per IP
	// Async processing via BullMQ to prevent timing attacks
	app.post("/forgot-password", {
		schema: { body: ForgotPasswordBody },
		config: { rateLimit: { max: 3, timeWindow: "1 minute" } },
		handler: async (_request, _reply) => {
			// → AuthController.forgotPassword
			throw new Error("Not implemented");
		},
	});

	// POST /api/v1/auth/accept-invite
	// Auth: public | Rate limit: 5/min per IP (prevents brute-force token guessing)
	// Collaborator creates their own account by accepting an invite link.
	// Creates Supabase Auth user + professional row + service links atomically.
	// Returns session for immediate login.
	app.post("/accept-invite", {
		schema: { body: AcceptInviteBody },
		config: { rateLimit: { max: 5, timeWindow: "1 minute" } },
		handler: async (request, reply) => {
			return app.inviteController.accept(request, reply);
		},
	});
}

export const autoPrefix = "/api/v1/auth";
