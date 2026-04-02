import cors from "@fastify/cors";
import rateLimit from "@fastify/rate-limit";
import Fastify from "fastify";
import {
	serializerCompiler,
	validatorCompiler,
} from "fastify-type-provider-zod";
import Redis from "ioredis";
import { createPool } from "./config/database.js";
import { parseEnv } from "./config/env.js";
import { createSupabaseAdmin } from "./config/supabase.js";
import { AuditLogController } from "./controllers/audit-log.controller.js";
import { ClientController } from "./controllers/client.controller.js";
import { ConsentController } from "./controllers/consent.controller.js";
import { OnboardingController } from "./controllers/onboarding.controller.js";
import { ProfessionalController } from "./controllers/professional.controller.js";
import { ServiceCategoryController } from "./controllers/service-category.controller.js";
import { ServiceController } from "./controllers/service.controller.js";
import { StudioController } from "./controllers/studio.controller.js";
import {
	buildAuthHook,
	buildRequireRole,
	buildRequireStudio,
} from "./middlewares/auth.js";
import { errorHandler } from "./middlewares/error-handler.js";
import { AuditLogRepository } from "./repositories/audit-log.repository.js";
import { ClientRepository } from "./repositories/client.repository.js";
import { ConsentRepository } from "./repositories/consent.repository.js";
import { OnboardingRepository } from "./repositories/onboarding.repository.js";
import { ProfessionalRepository } from "./repositories/professional.repository.js";
import { ServiceCategoryRepository } from "./repositories/service-category.repository.js";
import { ServiceRepository } from "./repositories/service.repository.js";
import { StudioRepository } from "./repositories/studio.repository.js";
import { registerRoutes } from "./routes/index.js";
import { AuditLogService } from "./services/audit-log.service.js";
import { ClientService } from "./services/client.service.js";
import { ConsentService } from "./services/consent.service.js";
import { OnboardingService } from "./services/onboarding.service.js";
import { ProfessionalService } from "./services/professional.service.js";
import { ServiceCategoryService } from "./services/service-category.service.js";
import { ServiceService } from "./services/service.service.js";
import { StudioService } from "./services/studio.service.js";

const env = parseEnv();

// ─── Infrastructure ────────────────────────────────────────
const pool = createPool(env.DATABASE_URL);
const supabaseAdmin = createSupabaseAdmin(
	env.SUPABASE_URL,
	env.SUPABASE_SERVICE_ROLE,
);

// ─── Fastify App ───────────────────────────────────────────
const app = Fastify({
	logger: {
		level: env.NODE_ENV === "production" ? "info" : "debug",
	},
});

// ─── Zod Validation ─────────────────────────────────────────
app.setValidatorCompiler(validatorCompiler);
app.setSerializerCompiler(serializerCompiler);

// ─── Plugins ───────────────────────────────────────────────
await app.register(cors, {
	origin:
		env.NODE_ENV === "production"
			? env.CORS_ORIGINS
				? env.CORS_ORIGINS.split(",")
				: false
			: /^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/,
});

// Redis-backed rate limiting in production; in-memory fallback for dev without Redis
const rateLimitOptions: Parameters<typeof rateLimit>[1] = {
	max: 100,
	timeWindow: "1 minute",
};

if (env.REDIS_URL) {
	const redis = new Redis(env.REDIS_URL, {
		maxRetriesPerRequest: 1,
		enableOfflineQueue: false,
		lazyConnect: true,
	});
	redis.connect().catch((err) => {
		app.log.warn(
			`Redis unavailable — rate limiting falls back to in-memory: ${err.message}`,
		);
	});
	rateLimitOptions.redis = redis;
	app.addHook("onClose", async () => {
		redis.disconnect();
	});
}

await app.register(rateLimit, rateLimitOptions);

// ─── Error Handler ─────────────────────────────────────────
app.setErrorHandler(errorHandler);

// ─── Decorators ────────────────────────────────────────────
app.decorate("pool", pool);
app.decorate("supabaseAdmin", supabaseAdmin);

// Auth hooks — used as onRequest hooks in routes
const authenticate = buildAuthHook(
	pool,
	env.SUPABASE_JWT_SECRET,
	env.SUPABASE_URL,
);
const requireStudio = buildRequireStudio();
const requireOwner = buildRequireRole("owner");
const requireStudioMember = buildRequireRole("owner", "professional");

app.decorate("authenticate", authenticate);
app.decorate("requireStudio", requireStudio);
app.decorate("requireOwner", requireOwner);
app.decorate("requireStudioMember", requireStudioMember);

// ─── Repositories ─────────────────────────────────────────
const studioRepo = new StudioRepository(pool);
const onboardingRepo = new OnboardingRepository(pool);
const serviceRepo = new ServiceRepository(pool);
const serviceCategoryRepo = new ServiceCategoryRepository(pool);
const professionalRepo = new ProfessionalRepository(pool);
const clientRepo = new ClientRepository(pool);
const consentRepo = new ConsentRepository(pool);
const auditLogRepo = new AuditLogRepository(pool);

// ─── Services ─────────────────────────────────────────────
const studioService = new StudioService(
	studioRepo,
	onboardingRepo,
	professionalRepo,
);
const onboardingService = new OnboardingService(onboardingRepo);
const serviceService = new ServiceService(serviceRepo);
const serviceCategoryService = new ServiceCategoryService(serviceCategoryRepo);
const professionalService = new ProfessionalService(professionalRepo);
const auditLogService = new AuditLogService(auditLogRepo);
const consentService = new ConsentService(consentRepo);
const clientService = new ClientService(
	clientRepo,
	consentService,
	auditLogService,
);

// ─── Controllers ──────────────────────────────────────────
app.decorate("studioController", new StudioController(studioService));
app.decorate(
	"onboardingController",
	new OnboardingController(onboardingService),
);
app.decorate("serviceController", new ServiceController(serviceService));
app.decorate(
	"serviceCategoryController",
	new ServiceCategoryController(serviceCategoryService),
);
app.decorate(
	"professionalController",
	new ProfessionalController(professionalService),
);
app.decorate("clientController", new ClientController(clientService));
app.decorate(
	"consentController",
	new ConsentController(consentService, consentRepo),
);
app.decorate("auditLogController", new AuditLogController(auditLogRepo));

// ─── Request Decorator ─────────────────────────────────────
app.decorateRequest(
	"authContext",
	null as unknown as import("./middlewares/auth.js").AuthContext,
);

// ─── Routes ───────────────────────────────────────────────
await registerRoutes(app);

// ─── Health Check ──────────────────────────────────────────
app.get("/health", async (_request, reply) => {
	try {
		await pool.query("SELECT 1");
		return { status: "ok", timestamp: new Date().toISOString() };
	} catch {
		return reply.status(503).send({
			status: "unhealthy",
			timestamp: new Date().toISOString(),
		});
	}
});

// ─── Graceful Shutdown ─────────────────────────────────────
async function shutdown(signal: string) {
	app.log.info(`${signal} received — shutting down`);
	await app.close();
	await pool.end();
	process.exit(0);
}

process.on("SIGTERM", () => shutdown("SIGTERM"));
process.on("SIGINT", () => shutdown("SIGINT"));

// ─── Start ─────────────────────────────────────────────────
try {
	await app.listen({ port: env.PORT, host: "0.0.0.0" });
	app.log.info(`Server running on port ${env.PORT}`);
} catch (err) {
	app.log.error(err);
	process.exit(1);
}

export { app };
