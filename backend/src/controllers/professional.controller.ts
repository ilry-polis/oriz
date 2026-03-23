import type { FastifyRequest, FastifyReply } from 'fastify';
import type { ProfessionalService } from '../services/professional.service.js';
import type { StudioAuthContext } from '../middlewares/auth.js';

export class ProfessionalController {
  constructor(private service: ProfessionalService) {}

  async update(request: FastifyRequest, reply: FastifyReply) {
    const { studioId } = request.authContext as StudioAuthContext;
    const { id } = request.params as { id: string };
    const body = request.body as { working_hours: Record<string, unknown> };

    const result = await this.service.updateWorkingHours(id, studioId, body.working_hours);
    return reply.send({ data: result });
  }
}
