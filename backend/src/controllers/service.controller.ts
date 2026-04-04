import type { FastifyRequest, FastifyReply } from 'fastify';
import type { ServiceService } from '../services/service.service.js';
import type { StudioAuthContext } from '../middlewares/auth.js';

export class ServiceController {
  constructor(private service: ServiceService) {}

  async list(request: FastifyRequest, reply: FastifyReply) {
    const { studioId } = request.authContext as StudioAuthContext;
    const query = request.query as {
      category_id?: string;
      is_active?: boolean;
      cursor?: string;
      limit: number;
    };

    const result = await this.service.listServices(studioId, {
      categoryId: query.category_id,
      isActive: query.is_active,
      cursor: query.cursor,
      limit: query.limit,
    });

    return reply.send({
      data: result.data,
      meta: { has_more: result.hasMore },
    });
  }

  async create(request: FastifyRequest, reply: FastifyReply) {
    const { studioId } = request.authContext as StudioAuthContext;
    const body = request.body as {
      category_id: string;
      name: string;
      duration_minutes: number;
      price: number;
      buffer_minutes: number;
      is_active: boolean;
    };

    const result = await this.service.createService(studioId, {
      categoryId: body.category_id,
      name: body.name,
      durationMinutes: body.duration_minutes,
      price: body.price,
      bufferMinutes: body.buffer_minutes,
      isActive: body.is_active,
    });

    return reply.status(201).send({ data: result });
  }
}
