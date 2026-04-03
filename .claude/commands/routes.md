Gere ou audite as rotas do Oriz.

## Sources of Truth
- docs/API_CONTRACTS.md — endpoints, auth levels, request/response shapes
- docs/DATABASE_SCHEMA.md — tipos e constraints para validação
- docs/DOMAIN_MODEL.md — entidades e relacionamentos

## Para Cada Arquivo de Rota, Gere
1. Registro do plugin Fastify com prefix
2. Cada endpoint com: method, path, preHandler (auth + role + validation), handler
3. Zod schemas para params, query e body
4. Mapeamento para controller method

## Checklist de Validação
- [ ] Todo endpoint do API_CONTRACTS.md tem rota correspondente
- [ ] Toda rota tem contrato no API_CONTRACTS.md
- [ ] Auth middleware aplicado em rotas autenticadas
- [ ] Role check conforme auth level do contrato
- [ ] Zod schema cobre todos os campos do request body
- [ ] Params UUID validados
- [ ] Paginação validada em listagens (page >= 1, per_page 1-100)
- [ ] Rate limit em endpoints públicos (booking, webhook)
- [ ] Webhooks validam signature antes de processar
- [ ] studio_id derivado do auth, nunca de params/query
- [ ] Arquivos organizados por domínio (um arquivo por domínio)
- [ ] Rotas públicas separadas em pasta public/

## Cruzamento
- Compare API_CONTRACTS.md com rotas existentes
- Liste: endpoints sem rota, rotas sem contrato, auth levels divergentes
- Verifique que Zod schemas batem com os tipos do DATABASE_SCHEMA.md

## Formato de Saída por Rota
```
// appointments.routes.ts
POST /api/v1/studios/:studioId/appointments
  Auth: owner+professional
  Validation: CreateAppointmentSchema (Zod)
  Handler: AppointmentController.create
  Rate limit: N/A

GET /api/v1/studios/:studioId/appointments
  Auth: owner+professional
  Validation: ListAppointmentsQuerySchema (Zod)
  Handler: AppointmentController.list
  Rate limit: N/A
```

## Se Rotas Já Existem
- Auditar contra API_CONTRACTS.md
- Reportar divergências
- Não alterar sem aprovação

Seja direto. Foque em completude e consistência com os contratos.
