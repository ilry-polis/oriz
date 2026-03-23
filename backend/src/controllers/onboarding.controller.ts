import type { FastifyRequest, FastifyReply } from 'fastify';
import type { OnboardingService } from '../services/onboarding.service.js';
import type { StudioAuthContext } from '../middlewares/auth.js';

export class OnboardingController {
  constructor(private service: OnboardingService) {}

  async get(request: FastifyRequest, reply: FastifyReply) {
    const { studioId } = request.authContext as StudioAuthContext;
    const result = await this.service.getByStudioId(studioId);
    return reply.send({ data: result });
  }

  async update(request: FastifyRequest, reply: FastifyReply) {
    const { studioId } = request.authContext as StudioAuthContext;
    const body = request.body as { current_step: string };
    const result = await this.service.updateStep(studioId, body.current_step);
    return reply.send({ data: result });
  }
}
