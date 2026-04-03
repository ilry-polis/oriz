Gere ou audite os contratos de API do Oriz.

## Sources of Truth
- docs/DOMAIN_MODEL.md — entidades e relacionamentos
- docs/DATABASE_SCHEMA.md — tipos, constraints, campos reais
- docs/API_CONTRACTS.md — contratos existentes (pode estar desatualizado)

## Para Cada Endpoint, Documente
1. Método + Rota (ex: POST /api/v1/studios/:studioId/appointments)
2. Auth: owner | professional | public
3. Request: params, query params, body com tipos Zod
4. Response: status code + shape exata ({ data, meta } ou { errors })
5. Erros possíveis: código + quando ocorre
6. Rate limit: se endpoint público, especificar limite

## Agrupamento por Domínio
Organize endpoints por domínio na ordem do DOMAIN_MODEL.md:
- Studios & Configuration
- Professionals & Services
- Clients & Anamnesis
- Appointments & Calendar
- Packages & Subscriptions
- Financial (Payments, Commissions, Summaries)
- Notifications & Messages
- Campaigns & Marketing
- AI & Conversations
- Billing & Subscription (Phase 5.1)
- Compliance (ConsentRecord, AuditLog)

## Checklist de Validação
- [ ] Todo CRUD de entidade do DOMAIN_MODEL tem endpoints correspondentes
- [ ] Response shapes consistentes em todos os endpoints
- [ ] Paginação em toda listagem com meta completo
- [ ] studio_id derivado do auth, nunca de query param
- [ ] Validação Zod definida para todo request body
- [ ] HTTP status codes corretos por operação
- [ ] Rate limiting documentado em endpoints públicos
- [ ] Endpoints de webhook com validação de signature
- [ ] Ações de negócio como sub-recursos (ex: /appointments/:id/confirm)
- [ ] Nenhum verbo na URL

## Cruzamento
- Compare DOMAIN_MODEL.md com endpoints: entidades sem CRUD?
- Compare DATABASE_SCHEMA.md com request/response: campos divergentes?
- Se API_CONTRACTS.md já existe, mostre diff do que mudou

## Formato de Saída
```
### POST /api/v1/studios/:studioId/appointments
Auth: professional, owner
Body: { client_id: UUID, service_id: UUID, date: ISO8601, start_time: ISO8601 }
Response 201: { data: Appointment }
Response 409: { errors: [{ code: "TIME_SLOT_TAKEN", message: "..." }] }
Response 422: { errors: [{ code: "OUTSIDE_WORKING_HOURS", message: "..." }] }
Rate limit: N/A (autenticado)
```

Seja direto. Foque em completude e consistência com o schema.
