import type { Pool } from 'pg';
import type { SupabaseClient } from '@supabase/supabase-js';
import type { FastifyReply, FastifyRequest } from 'fastify';
import type { AuthContext } from '../middlewares/auth.js';
import type { StudioController } from '../controllers/studio.controller.js';
import type { OnboardingController } from '../controllers/onboarding.controller.js';
import type { ServiceController } from '../controllers/service.controller.js';
import type { ServiceCategoryController } from '../controllers/service-category.controller.js';
import type { ProfessionalController } from '../controllers/professional.controller.js';

type HookFn = (request: FastifyRequest, reply: FastifyReply) => Promise<void>;

declare module 'fastify' {
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
  }

  interface FastifyRequest {
    authContext: AuthContext;
  }
}
