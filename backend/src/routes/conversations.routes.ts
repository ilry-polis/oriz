import type { FastifyInstance } from 'fastify';
import { z } from 'zod';

// ─── Zod Schemas ───────────────────────────────────────────

export const ListConversationsQuery = z.object({
  status: z.enum(['active', 'closed', 'escalated']).optional(),
  cursor: z.string().uuid().optional(),
  limit: z.coerce.number().int().min(1).max(100).default(20),
});

export const ListMessagesQuery = z.object({
  cursor: z.string().uuid().optional(),
  limit: z.coerce.number().int().min(1).max(100).default(50),
});

const UuidParam = z.object({ id: z.string().uuid() });

// ─── Route Plugin ──────────────────────────────────────────

export default async function conversationRoutes(app: FastifyInstance) {
  app.addHook('onRequest', app.authenticate);
  app.addHook('onRequest', app.requireStudioMember);

  // GET /api/v1/conversations
  // Auth: owner+professional
  app.get('/', {
    schema: { querystring: ListConversationsQuery },
    handler: async (request, reply) => {
      // → ConversationController.list
      throw new Error('Not implemented');
    },
  });

  // GET /api/v1/conversations/:id/messages
  // Auth: owner+professional
  app.get('/:id/messages', {
    schema: { params: UuidParam, querystring: ListMessagesQuery },
    handler: async (request, reply) => {
      // → ConversationController.listMessages
      throw new Error('Not implemented');
    },
  });

  // POST /api/v1/conversations/:id/escalate
  // Auth: owner+professional
  app.post('/:id/escalate', {
    schema: { params: UuidParam },
    handler: async (request, reply) => {
      // → ConversationController.escalate
      throw new Error('Not implemented');
    },
  });

  // POST /api/v1/conversations/:id/close
  // Auth: owner+professional
  app.post('/:id/close', {
    schema: { params: UuidParam },
    handler: async (request, reply) => {
      // → ConversationController.close
      throw new Error('Not implemented');
    },
  });
}

export const autoPrefix = '/api/v1/conversations';
