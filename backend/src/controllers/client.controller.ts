import type { FastifyRequest, FastifyReply } from 'fastify';
import type { ClientRepository } from '../repositories/client.repository.js';
import type { StudioAuthContext } from '../middlewares/auth.js';

export class ClientController {
  constructor(private repo: ClientRepository) {}

  async list(request: FastifyRequest, reply: FastifyReply) {
    const { studioId } = request.authContext as StudioAuthContext;
    const query = request.query as {
      search?: string;
      cursor?: string;
      limit: number;
    };

    const result = await this.repo.list(studioId, {
      search: query.search,
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
      name: string;
      phone?: string;
      email?: string;
      birth_date?: string;
      tags?: string[];
      notes?: string;
    };

    const client = await this.repo.create({
      studioId,
      name: body.name,
      phone: body.phone,
      email: body.email,
      birthDate: body.birth_date,
      tags: body.tags,
      notes: body.notes,
    });

    return reply.status(201).send({ data: client });
  }
}
