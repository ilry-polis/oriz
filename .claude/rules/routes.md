---
paths: backend/src/routes/**, backend/src/controllers/**, backend/src/middlewares/**
---

# Routes — Regras Automáticas

## Source of Truth
- docs/API_CONTRACTS.md define os endpoints — toda rota deve ter contrato correspondente
- Rota sem contrato = rota que não deveria existir
- Contrato sem rota = rota que falta implementar

## Estrutura de Rotas
- Prefixo obrigatório: /api/v1/
- Recursos no plural, kebab-case: /service-categories, /blocked-slots
- Ações de negócio como sub-recurso: /appointments/:id/confirm, /appointments/:id/complete
- Nunca verbos na URL — usar HTTP methods
- Agrupar por domínio em arquivos separados: studios.routes.ts, appointments.routes.ts, etc.

## Registro no Fastify
- Cada arquivo de rota exporta um plugin Fastify (async function)
- Registrar com prefix no server.ts: app.register(studioRoutes, { prefix: '/api/v1' })
- Um arquivo de rota por domínio — não misturar domínios

## Middlewares (ordem de execução)
1. Auth: verificar token, extrair user_id e studio_id
2. Role check: owner | professional | public
3. Validation: Zod schema no body/params/query
4. Rate limit: apenas em endpoints públicos
5. Handler: controller method

## Auth e Multi-tenancy
- studio_id SEMPRE derivado do token, nunca de params ou query
- Rotas públicas (booking page, webhook): sem auth, com rate limit
- Rotas de webhook: validar signature do provider antes de processar
- Middleware de role verifica: owner pode tudo, professional só o permitido no contrato

## Validação
- Zod schemas definidos junto à rota ou em arquivo separado por domínio
- Params: validar UUID format
- Query: validar paginação (page >= 1, per_page entre 1-100)
- Body: schema Zod completo conforme API_CONTRACTS.md
- Resposta de validação: 400 com { errors: [{ code, message, field }] }

## Organização de Arquivos
```
backend/src/routes/
├── studios.routes.ts
├── professionals.routes.ts
├── services.routes.ts
├── clients.routes.ts
├── appointments.routes.ts
├── packages.routes.ts
├── financial.routes.ts
├── notifications.routes.ts
├── campaigns.routes.ts
├── conversations.routes.ts
├── billing.routes.ts        (Phase 5.1)
├── compliance.routes.ts
└── public/
    ├── booking.routes.ts     (sem auth, com rate limit)
    └── webhooks.routes.ts    (validação de signature)
```

## Antes de Criar Rota
- Verificar que o endpoint existe no API_CONTRACTS.md
- Verificar auth level no contrato
- Verificar se Zod schema cobre todos os campos do request
- Verificar que o controller correspondente existe ou será criado
