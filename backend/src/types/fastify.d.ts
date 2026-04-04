import type { SupabaseClient } from "@supabase/supabase-js";
import type { FastifyReply, FastifyRequest } from "fastify";
import type { Pool } from "pg";
import type { AnamnesisController } from "../controllers/anamnesis.controller.js";
import type { AuditLogController } from "../controllers/audit-log.controller.js";
import type { ClientNoteController } from "../controllers/client-note.controller.js";
import type { ClientController } from "../controllers/client.controller.js";
import type { ConsentController } from "../controllers/consent.controller.js";
import type { InviteController } from "../controllers/invite.controller.js";
import type { OnboardingController } from "../controllers/onboarding.controller.js";
import type { ProfessionalController } from "../controllers/professional.controller.js";
import type { ServiceCategoryController } from "../controllers/service-category.controller.js";
import type { ServiceController } from "../controllers/service.controller.js";
import type { StudioController } from "../controllers/studio.controller.js";
import type { AuthContext } from "../middlewares/auth.js";

type HookFn = (request: FastifyRequest, reply: FastifyReply) => Promise<void>;

declare module "fastify" {
	interface FastifyInstance {
		pool: Pool;
		supabaseAdmin: SupabaseClient;
		authenticate: HookFn;
		requireStudio: HookFn;
		requireOwner: HookFn;
		requireStudioMember: HookFn;
		studioController: StudioController;
		onboardingController: OnboardingController;
		serviceController: ServiceController;
		serviceCategoryController: ServiceCategoryController;
		professionalController: ProfessionalController;
		inviteController: InviteController;
		clientController: ClientController;
		consentController: ConsentController;
		anamnesisController: AnamnesisController;
		auditLogController: AuditLogController;
		clientNoteController: ClientNoteController;
	}

	interface FastifyRequest {
		authContext: AuthContext;
	}
}
