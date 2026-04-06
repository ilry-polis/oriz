import cors from "@fastify/cors";
import rateLimit from "@fastify/rate-limit";
import Fastify from "fastify";
import {
	serializerCompiler,
	validatorCompiler,
} from "fastify-type-provider-zod";
import { Redis } from "ioredis";
import { createPool } from "./config/database.js";
import { parseEnv } from "./config/env.js";
import { createSupabaseAdmin } from "./config/supabase.js";
import { AnamnesisController } from "./controllers/anamnesis.controller.js";
import { AuditLogController } from "./controllers/audit-log.controller.js";
import { ClientNoteController } from "./controllers/client-note.controller.js";
import { ClientController } from "./controllers/client.controller.js";
import { ConsentController } from "./controllers/consent.controller.js";
import { InviteController } from "./controllers/invite.controller.js";
import { OnboardingController } from "./controllers/onboarding.controller.js";
import { ProfessionalController } from "./controllers/professional.controller.js";
import { ServiceCategoryController } from "./controllers/service-category.controller.js";
import { ServiceController } from "./controllers/service.controller.js";
import { StudioController } from "./controllers/studio.controller.js";
import { AppointmentController } from "./controllers/appointment.controller.js";
import { BlockedSlotController } from "./controllers/blocked-slot.controller.js";
import { PackageController } from "./controllers/package.controller.js";
import { PackageSubscriptionController } from "./controllers/package-subscription.controller.js";
import { FinancialController } from "./controllers/financial.controller.js";
import { CommissionController } from "./controllers/commission.controller.js";
import { PaymentController } from "./controllers/payment.controller.js";
import {
	buildAuthHook,
	buildRequireRole,
	buildRequireStudio,
} from "./middlewares/auth.js";
import { errorHandler } from "./middlewares/error-handler.js";
import { AnamnesisRepository } from "./repositories/anamnesis.repository.js";
import { AuditLogRepository } from "./repositories/audit-log.repository.js";
import { ClientNoteRepository } from "./repositories/client-note.repository.js";
import { ClientRepository } from "./repositories/client.repository.js";
import { ConsentRepository } from "./repositories/consent.repository.js";
import { InviteRepository } from "./repositories/invite.repository.js";
import { OnboardingRepository } from "./repositories/onboarding.repository.js";
import { ProfessionalRepository } from "./repositories/professional.repository.js";
import { ServiceCategoryRepository } from "./repositories/service-category.repository.js";
import { ServiceRepository } from "./repositories/service.repository.js";
import { StudioRepository } from "./repositories/studio.repository.js";
import { AppointmentRepository } from "./repositories/appointment.repository.js";
import { BlockedSlotRepository } from "./repositories/blocked-slot.repository.js";
import { PaymentRepository } from "./repositories/payment.repository.js";
import { PackageRepository } from "./repositories/package.repository.js";
import { PackageSubscriptionRepository } from "./repositories/package-subscription.repository.js";
import { CommissionRepository } from "./repositories/commission.repository.js";
import { FinancialRepository } from "./repositories/financial.repository.js";
import { createFinancialRefreshQueue } from "./jobs/financial-refresh.job.js";
import { registerRoutes } from "./routes/index.js";
import { AnamnesisService } from "./services/anamnesis.service.js";
import { AuditLogService } from "./services/audit-log.service.js";
import { ClientNoteService } from "./services/client-note.service.js";
import { ClientService } from "./services/client.service.js";
import { ConsentService } from "./services/consent.service.js";
import { InviteService } from "./services/invite.service.js";
import { OnboardingService } from "./services/onboarding.service.js";
import { ProfessionalService } from "./services/professional.service.js";
import { ServiceCategoryService } from "./services/service-category.service.js";
import { ServiceService } from "./services/service.service.js";
import { StudioService } from "./services/studio.service.js";
import { AppointmentService } from "./services/appointment.service.js";
import { BlockedSlotService } from "./services/blocked-slot.service.js";
import { PackageService } from "./services/package.service.js";
import { CommissionService } from "./services/commission.service.js";
import { FinancialService } from "./services/financial.service.js";

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
		connectTimeout: 3000,
		retryStrategy: () => null, // Don't auto-retry — we handle fallback
	});
	try {
		await redis.connect();
		rateLimitOptions.redis = redis;
		app.addHook("onClose", async () => {
			redis.disconnect();
		});
		app.log.info("Redis connected — rate limiting uses Redis store");
	} catch (err) {
		redis.disconnect();
		app.log.warn(
			`Redis unavailable — rate limiting uses in-memory fallback: ${(err as Error).message}`,
		);
	}
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
const inviteRepo = new InviteRepository(pool);
const clientRepo = new ClientRepository(pool);
const consentRepo = new ConsentRepository(pool);
const anamnesisRepo = new AnamnesisRepository(pool);
const auditLogRepo = new AuditLogRepository(pool);
const clientNoteRepo = new ClientNoteRepository(pool);
const appointmentRepo = new AppointmentRepository(pool);
const blockedSlotRepo = new BlockedSlotRepository(pool);
const paymentRepo = new PaymentRepository(pool);
const packageRepo = new PackageRepository(pool);
const packageSubRepo = new PackageSubscriptionRepository(pool);
const commissionRepo = new CommissionRepository(pool);
const financialRepo = new FinancialRepository(pool);

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
const inviteService = new InviteService(
	inviteRepo,
	professionalRepo,
	supabaseAdmin,
);
const anamnesisService = new AnamnesisService(anamnesisRepo);
const auditLogService = new AuditLogService(auditLogRepo);
const clientNoteService = new ClientNoteService(clientNoteRepo);
const blockedSlotService = new BlockedSlotService(blockedSlotRepo);
const commissionService = new CommissionService(commissionRepo, professionalRepo, studioRepo);
const financialRefreshQueue = createFinancialRefreshQueue(pool, env.REDIS_URL);
const appointmentService = new AppointmentService(
	appointmentRepo,
	professionalRepo,
	serviceRepo,
	paymentRepo,
	blockedSlotService,
	commissionService,
	packageSubRepo,
	packageRepo,
	studioRepo,
	financialRefreshQueue,
);
const packageService = new PackageService(packageRepo, packageSubRepo, serviceRepo, paymentRepo);
const financialService = new FinancialService(financialRepo, appointmentRepo, professionalRepo, paymentRepo);
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
app.decorate("inviteController", new InviteController(inviteService));
app.decorate("clientController", new ClientController(clientService));
app.decorate(
	"consentController",
	new ConsentController(consentService, consentRepo),
);
app.decorate(
	"anamnesisController",
	new AnamnesisController(anamnesisService),
);
app.decorate("auditLogController", new AuditLogController(auditLogRepo));
app.decorate("appointmentController", new AppointmentController(appointmentService));
app.decorate("blockedSlotController", new BlockedSlotController(blockedSlotService));
app.decorate("packageController", new PackageController(packageService));
app.decorate("packageSubscriptionController", new PackageSubscriptionController(packageService));
app.decorate("financialController", new FinancialController(financialService));
app.decorate("commissionController", new CommissionController(commissionService));
app.decorate("paymentController", new PaymentController(financialService));
app.decorate(
	"clientNoteController",
	new ClientNoteController(clientNoteService),
);

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
