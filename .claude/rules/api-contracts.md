---
paths: backend/src/controllers/**, backend/src/routes/**, docs/API_CONTRACTS.md
---

# API Contracts — Regras Automáticas

## Source of Truth
- docs/API_CONTRACTS.md é a referência para todos os endpoints
- DOMAIN_MODEL.md define as entidades, DATABASE_SCHEMA.md define os tipos
- Se controller diverge do contrato, o contrato vence — corrigir o controller

## Response Shape (obrigatório em TODOS os endpoints)
- Sucesso: { data, meta }
- Erro: { errors: [{ code, message, field? }] }
- Lista: { data: [], meta: { total, page, per_page, total_pages } }
- Nunca retornar array solto — sempre envelopado em { data }

## HTTP Status Codes
- 200: leitura ou update com sucesso
- 201: criação com sucesso (retornar o recurso criado)
- 204: delete com sucesso (sem body)
- 400: input inválido (validação falhou)
- 401: não autenticado
- 403: autenticado mas sem permissão
- 404: recurso não encontrado
- 409: conflito (ex: horário já ocupado, duplicata)
- 422: entidade não processável (regra de negócio violada)
- 429: rate limit excedido

## Paginação
- Obrigatória em todo endpoint de listagem
- Query params: ?page=1&per_page=20
- Default: page=1, per_page=20, max per_page=100
- Meta sempre inclui total, page, per_page, total_pages

## Multi-tenancy
- Todo endpoint filtra por studio_id do token autenticado
- Nunca aceitar studio_id como query param — derivar do auth context
- Belt-and-suspenders: RLS filtra no banco + service filtra na aplicação

## Validação
- Input validado com Zod no controller (boundary)
- Nunca confiar em dados do cliente
- IDs em params: validar formato UUID
- Datas: aceitar ISO 8601, rejeitar formatos ambíguos

## Versionamento
- Prefixo /api/v1/ em todas as rotas
- Mudanças breaking = nova versão

## Segurança
- Rate limiting em endpoints públicos (login, booking, webhook)
- Endpoints autenticados: Bearer token no header Authorization
- Webhook endpoints: validar signature do provider (Stripe/Asaas)
- Nunca retornar stack traces — logar internamente, retornar error code

## Naming
- Rotas em kebab-case: /api/v1/service-categories
- Recursos no plural: /studios, /clients, /appointments
- Ações específicas como sub-recurso: /appointments/:id/confirm
- Nunca verbos na URL (não /getClients, sim GET /clients)

## Documentação por Endpoint
Cada endpoint no API_CONTRACTS.md deve ter:
1. Método + Rota
2. Auth: quem pode acessar (owner, professional, public)
3. Request: params, query, body (com tipos)
4. Response: status code + shape
5. Erros possíveis com códigos
6. Rate limit (se público)
