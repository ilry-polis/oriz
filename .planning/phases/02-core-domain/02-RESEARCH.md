# Phase 2: Core Domain — Research

**Researched:** 2026-04-02
**Domain:** Serviços, Clientes, Equipe, LGPD (Fastify + Flutter + Postgres/Supabase)
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Client list and navigation**
- List with search bar at top, scrollable
- Each row: avatar + name + last visit date
- Filter chips: VIP, Novo, Inativo
- Cursor-based pagination (backend already has this pattern)

**Client detail (ficha)**
- Header: name, phone, email, tags
- Tabs: Historico | Anamnese | Notas
- Each tab is a focused view, no infinite scroll

**Client registration**
- Two paths: quick inline during scheduling (name + phone only) AND full form from client list
- Phone unique per studio (DB constraint exists)
- Birthday optional but incentivized with nudge: "Adicione para enviar parabens automatico"
- Marketing consent checkbox at registration (default: unchecked, opt-in explicit)

**Client tags**
- Mixed: "Novo" and "Inativo" are automatic (based on appointment history)
- "VIP" and custom tags are manual
- Tags stored as JSONB array (DB field exists)

**Anamnesis**
- Per service category (unique key: client + category already in DB)
- Templates with default fields per category (lash: alergia cola, lentes; micropig: gravidez, anticoagulante, etc.)
- Professional can add/remove custom fields beyond template defaults
- Fields stored as JSONB

**Client notes**
- Free text with timeline (like chat comments)
- Each note is dated, immutable once created
- Displayed in reverse chronological order in Notas tab

**Service catalog**
- Services grouped by category in expandable/collapsible sections
- Each row: name + duration + price
- Tap to edit, + button to add new service
- Buffer time configurable per service (default 0, field buffer_minutes exists in DB)
- Toggle active/inactive per service (is_active field exists)
- Inactive hides from scheduling but preserves history

**Service categories**
- Pre-defined seed categories (Lash, Unhas, Micropigmentacao, Cabelo, Estetica) + professional can create custom categories
- Categories from onboarding carry over seamlessly

**Team management**
- Owner registers professional directly (name + email + services) — no invite flow
- Owner sets a temporary password; professional changes on first login
- Each professional linked to specific services (checkbox selection)
- Professional inherits studio hours by default, can override with custom working_hours (JSONB field exists)

**Commissions**
- Percentage per professional (single rate applied to all her services)
- Card fee policy configurable per professional: studio_absorbs, professional_absorbs, or split (field exists in DB)
- Commission calculated on appointment completion (not booking)

**LGPD - Consent**
- Explicit opt-in checkbox at client registration: "Aceito receber mensagens de marketing via WhatsApp"
- Default: unchecked (not granted)
- Same checkbox on public booking page (Phase 5)
- Consent revocation: professional toggles off at client's request, timestamp recorded
- ConsentRecord tracks: granted, revoked, timestamps

**LGPD - Audit log**
- Automatic logging: who viewed, edited, exported, or deleted client data
- Visible in client detail (additional tab or section)
- Records: user, action, timestamp, IP

**LGPD - Data deletion**
- Anonymization (not hard delete): replace name/phone/email with generic data ("Cliente removido")
- Preserves appointment history and financial records for reporting
- Audit log records the anonymization event

### Claude's Discretion
- Loading skeletons and transition animations
- Exact spacing, typography, and color palette within clean minimal direction
- Error state handling and empty states
- Anamnesis template field types (boolean, text, select) — whatever makes clinical sense
- Audit log UI presentation (tab vs expandable section in client detail)
- How "Novo" and "Inativo" tags are calculated (days since last appointment thresholds)

### Deferred Ideas (OUT OF SCOPE)
- None — discussion stayed within phase scope
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| SERV-01 | Owner can create a service with name, price, duration, category, and buffer time | Route stub exists; ServiceRepository.create() implemented; ServiceService.createService() implemented; ServiceController.create() implemented. Need: list, getById, update, delete methods. |
| SERV-02 | Toggle active/inactive per service; inactive hides from scheduling but preserves history | is_active field exists in DB. Need: ServiceService.setActive() + ServiceRepository.update(). |
| CLNT-01 | Owner can register client with name, phone (E.164), email; duplicate phone rejected (409); marketing consent explicit default not granted | Route stubs exist with Zod schemas. Need: ClientService, ClientRepository, ConsentService, ConsentRepository. |
| CLNT-02 | Duplicate phone numbers rejected; phone stored as E.164 | DB has UNIQUE(studio_id, phone) WHERE phone IS NOT NULL. Backend must catch pg error 23505 → 409 PHONE_ALREADY_EXISTS. |
| CLNT-03 | Professional can fill and view anamnesis form per client per service category | Route stubs exist (PUT/GET anamneses). Need: AnamnesisService, AnamnesisRepository with upsert. |
| CLNT-04 | Professional can view appointment history | Route stub exists (GET /clients/:id/appointments). Need: ClientRepository.listAppointments(). |
| CLNT-05 | Professional can add private notes and tag clients (VIP, new, inactive) | Notes field exists in clients table. Auto-tags (Novo/Inativo) need business logic rule in service layer. |
| CLNT-06 | Client detail shows full ficha with tabs | Flutter: ClientDetailScreen with Histórico, Anamnese, Notas tabs per SCREENS.md. |
| TEAM-01 | Owner can register professionals linked to services with commission rules | Route stub exists; ProfessionalController.update() implemented. Need: create, list, getById, delete. professional_services N:N table exists. |
| TEAM-02 | Owner sets temporary password; professional changes on first login | No invite flow: owner creates auth user via Supabase Admin API, sets temporary password. |
| TEAM-03 | Each professional linked to specific services via checkbox | professional_services table exists with UNIQUE(professional_id, service_id). Patch replaces all links atomically in a transaction. |
| TEAM-04 | Commission rules: percentage or fixed amount | commission_type + commission_value fields exist in professionals table. |
| TEAM-05 | Card fee policy configurable per professional | card_fee_policy field exists ('studio', 'professional', 'split'). |
| LGPD-01 | Every access to sensitive client data is recorded in audit log | audit_log table exists (partitioned by month, INSERT via service_role). Need: AuditLogService called automatically by ClientService on view/export/delete. |
| LGPD-02 | Consent record capture and revocation | consent_records table exists (append-only). ConsentService inserts new record per action (never updates). |
</phase_requirements>

---

## Summary

Esta fase implementa três domínios independentes (Serviços, Clientes, Equipe) mais infraestrutura LGPD obrigatória. Todos os artefatos de infraestrutura já existem: tabelas criadas, schemas Zod definidos, stubs de rotas presentes, e os primeiros métodos de service/repository implantados. O trabalho desta fase é completar as implementações pendentes e construir as telas Flutter correspondentes.

O backend segue padrão Route → Controller → Service → Repository completamente estabelecido. Todos os repositórios usam `pg` (node-postgres) com SQL manual — sem ORM. O Flutter usa Riverpod com sealed states (Loading/Success/Error), GoRouter para navegação, e `ApiClient` HTTP wrapper já existente. O banco tem RLS ativo em todas as tabelas e a fase não requer nenhuma migration nova — o schema de Phase 1 já cobre tudo.

O domínio de clientes tem a maior complexidade: gestão de tags automáticas (Novo/Inativo baseado em histórico de agendamentos), anamnese JSONB por categoria, notas imutáveis com timeline, consentimento LGPD append-only, e audit log automático em todo acesso a dados sensíveis. Equipe tem uma particularidade: criação de profissional envolve Supabase Auth Admin API para criar o usuário, além do registro no banco. Serviços são o domínio mais simples — a estrutura já existe quase completa.

**Recomendação primária:** Implementar backend primeiro (waves ordenadas por domínio: Serviços → Clientes → Equipe → LGPD), depois Flutter screens por domínio. Audit log deve ser injetado como middleware de serviço reutilizável, não duplicado em cada endpoint.

---

## Standard Stack

### Core (já em uso, HIGH confidence)

| Library | Version | Purpose | Confirmed |
|---------|---------|---------|-----------|
| Fastify | ^5.x | HTTP framework | server.ts |
| Zod + fastify-type-provider-zod | ^3.x | Schema validation | routes/*.ts |
| node-postgres (pg) | ^8.x | DB driver | repositories/*.ts |
| Vitest | ^3.2.1 | Unit testing | package.json |
| Flutter + Riverpod | 3.x | Mobile app + state | mobile/lib/ |
| GoRouter | 14.x | Routing | app_router.dart |
| Supabase Flutter | 2.x | Auth only (not DB) | mobile/lib/core/ |

### Supporting

| Library | Purpose | When to Use |
|---------|---------|-------------|
| `@supabase/supabase-js` (admin) | Criar usuário via Admin API para profissional | TEAM-02: criar usuário auth ao registrar profissional |
| `jose` | JWT verification | Já em uso no auth middleware |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| SQL manual (pg) | Drizzle ORM | Projeto usa SQL manual por decisão existente — não alterar |
| Append-only inserts para consent | Update de flag | Append-only é padrão LGPD e já definido no schema |

---

## Architecture Patterns

### Estrutura de Arquivos — Backend (padrão estabelecido)

```
backend/src/
├── routes/
│   ├── clients.routes.ts        # stub completo com Zod schemas
│   ├── services.routes.ts       # stub completo
│   ├── professionals.routes.ts  # stub completo
│   └── audit-logs.routes.ts     # stub completo
├── controllers/
│   ├── client.controller.ts     # NOVO
│   ├── service.controller.ts    # parcial (create existe)
│   ├── professional.controller.ts # parcial (update existe)
│   ├── anamnesis.controller.ts  # NOVO
│   ├── consent.controller.ts    # NOVO
│   └── audit-log.controller.ts  # NOVO
├── services/
│   ├── client.service.ts        # NOVO
│   ├── service.service.ts       # parcial (createService existe)
│   ├── professional.service.ts  # parcial (updateWorkingHours existe)
│   ├── anamnesis.service.ts     # NOVO
│   ├── consent.service.ts       # NOVO
│   └── audit-log.service.ts     # NOVO
├── repositories/
│   ├── client.repository.ts     # NOVO
│   ├── service.repository.ts    # parcial (create existe)
│   ├── professional.repository.ts # parcial (findByUserId, updateWorkingHours existem)
│   ├── anamnesis.repository.ts  # NOVO
│   ├── consent.repository.ts    # NOVO
│   └── audit-log.repository.ts  # NOVO
└── types/
    └── fastify.d.ts             # atualizar com novos controllers
```

### Estrutura de Arquivos — Flutter (padrão estabelecido)

```
mobile/lib/features/
├── clients/
│   ├── data/
│   │   ├── client_repository.dart     # NOVO
│   │   └── anamnesis_templates.dart   # NOVO
│   ├── domain/
│   │   ├── client_model.dart          # NOVO
│   │   └── anamnesis_model.dart       # NOVO
│   ├── providers/
│   │   └── client_provider.dart       # NOVO
│   └── presentation/
│       ├── client_list_screen.dart    # NOVO (substitui _Placeholder)
│       ├── client_detail_screen.dart  # NOVO
│       ├── client_form_screen.dart    # NOVO
│       ├── anamnesis_form_screen.dart # NOVO
│       └── widgets/
│           ├── client_list_item.dart
│           ├── client_list_item_skeleton.dart
│           └── tag_chip.dart
├── services_management/
│   ├── data/service_mgmt_repository.dart
│   ├── domain/service_model.dart       # (pode reuso do onboarding)
│   ├── providers/service_mgmt_provider.dart
│   └── presentation/
│       ├── services_management_screen.dart  # NOVO
│       ├── service_form_screen.dart         # NOVO
│       └── widgets/service_card.dart
└── team/
    ├── data/team_repository.dart
    ├── domain/professional_model.dart
    ├── providers/team_provider.dart
    └── presentation/
        ├── team_management_screen.dart   # NOVO
        ├── professional_form_screen.dart # NOVO
        └── widgets/professional_card.dart
```

### Pattern 1: Cursor-Based Pagination com pg

**O que é:** Todas as listagens usam cursor UUID — mais eficiente que OFFSET em tabelas grandes.
**Quando usar:** Toda listagem no backend (clientes, serviços, profissionais, audit logs).

```typescript
// Source: padrão estabelecido no projeto (service-category.repository.ts)
async list(studioId: string, cursor?: string, limit = 20): Promise<ClientRow[]> {
  const params: unknown[] = [studioId, limit + 1];
  let sql = `
    SELECT id, studio_id, name, phone, email, tags, last_appointment_at, created_at
    FROM clients
    WHERE studio_id = $1
  `;
  if (cursor) {
    sql += ` AND id > $3`;
    params.push(cursor);
  }
  sql += ` ORDER BY name ASC, id ASC LIMIT $2`;
  const { rows } = await this.pool.query<ClientRow>(sql, params);
  return rows;
}
// has_more = rows.length > limit; data = rows.slice(0, limit)
```

### Pattern 2: Auto-Tags (Novo/Inativo) — Business Logic no Service Layer

**O que é:** Tags "Novo" e "Inativo" são calculadas em tempo real no service, não armazenadas.
**Quando usar:** Ao retornar dados de cliente, o service enriquece as tags.

```typescript
// Source: decisão de design do projeto (CONTEXT.md)
// "Novo" = sem agendamentos concluídos (total_appointments = 0 ou last_appointment_at IS NULL)
// "Inativo" = sem agendamento nos últimos N dias (Claude's discretion: 60 dias default)
function enrichTags(client: ClientRow, stats: ClientStats): string[] {
  const tags = [...(client.tags as string[])];
  if (!stats.total_appointments || stats.total_appointments === 0) {
    tags.push('novo');
  }
  const daysSinceLastAppointment = client.last_appointment_at
    ? Math.floor((Date.now() - new Date(client.last_appointment_at).getTime()) / 86400000)
    : null;
  if (daysSinceLastAppointment !== null && daysSinceLastAppointment >= 60) {
    tags.push('inativo');
  }
  return [...new Set(tags)];
}
```

### Pattern 3: Audit Log Automático via AuditLogService

**O que é:** AuditLogService.log() é chamado por ClientService em todo acesso sensível. Não é middleware HTTP — é chamada explícita na camada de service.
**Quando usar:** ClientService.getById(), ClientService.delete(), ClientService.anonymize().

```typescript
// Source: audit_logs schema (DATABASE_SCHEMA.md) + decisão LGPD (CONTEXT.md)
export class AuditLogService {
  constructor(private repo: AuditLogRepository) {}

  async log(params: {
    studioId: string;
    userId: string;
    action: 'view' | 'export' | 'delete';
    entityType: string;
    entityId: string;
    ip?: string;
  }): Promise<void> {
    await this.repo.insert(params);
    // Fire-and-forget é aceitável para audit log — não bloquear a resposta principal
  }
}
```

### Pattern 4: ConsentRecord Append-Only

**O que é:** Consentimento NUNCA é atualizado. Cada mudança (grant/revoke) é um novo INSERT.
**Quando usar:** ConsentService.grant(), ConsentService.revoke().
**Consulta do estado atual:** SELECT mais recente por (client_id, studio_id, type) ORDER BY created_at DESC LIMIT 1.

```typescript
// Source: data-modeling.md rule + DATABASE_SCHEMA.md (consent_records)
async getCurrentConsent(clientId: string, studioId: string, type: string): Promise<'granted' | 'revoked' | null> {
  const { rows } = await this.pool.query(
    `SELECT action FROM consent_records
     WHERE client_id = $1 AND studio_id = $2 AND type = $3
     ORDER BY created_at DESC
     LIMIT 1`,
    [clientId, studioId, type]
  );
  return rows[0]?.action ?? null;
}
```

### Pattern 5: Professional Create com Supabase Admin API

**O que é:** Criar profissional requer criar um usuário Supabase Auth primeiro (owner define senha temporária), depois inserir o registro em professionals.
**Quando usar:** POST /api/v1/professionals.

```typescript
// Source: supabase.md rules + CONTEXT.md (Team management decisions)
// supabaseAdmin é o Supabase Admin Client (service_role key) — já decorado no Fastify
async createProfessional(studioId: string, input: CreateProfessionalInput) {
  // 1. Criar usuário no Supabase Auth com senha temporária
  const { data: authUser, error } = await this.supabaseAdmin.auth.admin.createUser({
    email: input.email,
    password: input.temporaryPassword,
    email_confirm: true, // confirma email automaticamente
  });
  if (error) throw new ConflictError('USER_CREATION_FAILED', error.message);

  // 2. Criar registro em professionals (dentro de transaction quando possível)
  const professional = await this.repo.create({
    studioId,
    userId: authUser.user.id,
    name: input.name,
    commissionType: input.commissionType,
    commissionValue: input.commissionValue,
    cardFeePolicy: input.cardFeePolicy,
    workingHours: input.workingHours ?? {},
  });

  // 3. Vincular serviços em professional_services (DELETE + INSERT em batch)
  if (input.serviceIds?.length) {
    await this.repo.replaceServiceLinks(professional.id, studioId, input.serviceIds);
  }

  return professional;
}
```

### Pattern 6: Riverpod Sealed State (Flutter — padrão estabelecido)

```dart
// Source: mobile/lib/features/onboarding/providers/onboarding_provider.dart
sealed class ClientListState { const ClientListState(); }
class ClientListLoading extends ClientListState { const ClientListLoading(); }
class ClientListLoaded extends ClientListState {
  final List<Client> clients;
  final bool hasMore;
  final String? nextCursor;
  const ClientListLoaded({required this.clients, required this.hasMore, this.nextCursor});
}
class ClientListError extends ClientListState {
  final String message;
  const ClientListError(this.message);
}
```

### Pattern 7: Transaction para service_ids replace (professional_services)

**O que é:** Atualizar os serviços de um profissional faz DELETE + INSERT em batch dentro de uma transação.
**Quando usar:** POST /professionals e PATCH /professionals/:id quando service_ids enviado.

```typescript
// Source: API_CONTRACTS.md (§6 PATCH professionals/:id — "service_ids substitui completamente os vínculos")
async replaceServiceLinks(professionalId: string, studioId: string, serviceIds: string[]): Promise<void> {
  const client = await this.pool.connect();
  try {
    await client.query('BEGIN');
    await client.query(
      `DELETE FROM professional_services WHERE professional_id = $1 AND studio_id = $2`,
      [professionalId, studioId]
    );
    if (serviceIds.length > 0) {
      const values = serviceIds.map((_, i) => `(gen_random_uuid(), $${i * 3 + 1}, $${i * 3 + 2}, $${i * 3 + 3})`).join(', ');
      const params = serviceIds.flatMap(svcId => [studioId, professionalId, svcId]);
      await client.query(
        `INSERT INTO professional_services (id, studio_id, professional_id, service_id) VALUES ${values}`,
        params
      );
    }
    await client.query('COMMIT');
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}
```

### Anti-Patterns a Evitar

- **Select * em qualquer query:** sempre especificar colunas explicitamente (regra crítica do projeto).
- **Studio_id via params/body:** sempre derivar do JWT authContext — nunca aceitar do cliente.
- **UPDATE em consent_records:** é append-only — erro de arquitetura crítico.
- **UPDATE em audit_logs:** é append-only — INSERT via service_role apenas.
- **Lógica de tag automática no DB:** calcular no service layer, não como coluna gerada — mais fácil de mudar o threshold.
- **Chamar Supabase diretamente no Flutter para CRUD:** todo CRUD passa pela API Fastify (regra mobile.md).
- **Deletar hard o cliente com appointment history:** sempre anonimizar, nunca DELETE real quando há histórico.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Phone format validation | Regex manual E.164 | Zod `.regex(/^\+[1-9]\d{10,14}$/)` no CreateClientBody | Já definido no schema existente |
| Duplicate phone detection | Verificação em service layer | Catch pg error `23505` (unique_violation) → `ConflictError('PHONE_ALREADY_EXISTS')` | DB constraint já existe: UNIQUE(studio_id, phone) |
| Professional user creation | Flow de invite customizado | Supabase Admin API `createUser` com `email_confirm: true` | Supabase já gerencia auth, não reinventar |
| Cursor pagination meta | Lógica manual | Padrão existente: fetch limit+1, has_more = rows.length > limit | Já estabelecido nos outros repositories |
| Auto-tag "Novo"/"Inativo" | Coluna calculada ou trigger | Lógica em service ao retornar cliente | Threshold configurável no futuro sem migration |
| Audit log chamada | Interceptor HTTP global | Chamada explícita no service (apenas em ClientService) | Audit log não é para todo endpoint, só dados sensíveis de clientes |

**Insight chave:** O schema do banco foi projetado para esta fase — todas as constraints, índices e campos necessários já existem. Não criar migrations novas; toda a lógica é implementação de código sobre estrutura existente.

---

## Common Pitfalls

### Pitfall 1: pg error 23505 não tratado → 500 em vez de 409
**O que acontece:** Inserir cliente com phone duplicado lança `error.code = '23505'` do pg. Se não tratado, Fastify retorna 500.
**Por que acontece:** O driver `pg` lança um erro nativo do Postgres, não um AppError.
**Como evitar:** Em todo repository que tem constraint unique, capturar o erro pg e converter:
```typescript
} catch (err: any) {
  if (err.code === '23505') {
    if (err.constraint?.includes('phone')) throw new ConflictError('PHONE_ALREADY_EXISTS', 'Telefone já cadastrado');
    if (err.constraint?.includes('user_id')) throw new ConflictError('PROFESSIONAL_EXISTS', 'Usuário já é profissional');
  }
  throw err;
}
```
**Warning signs:** Teste de criação duplicada retornando 500 em vez de 409.

### Pitfall 2: Phone não normalizado para E.164
**O que acontece:** Cliente registrado com "(11) 99999-1234" e outro com "+5511999991234" — ambos passam na validação de formato mas são o mesmo número, bypass da dedup.
**Por que acontece:** Validação Zod aceita o formato E.164 mas não normaliza entrada do usuário.
**Como evitar:** Normalizar o phone no service antes de persistir:
```typescript
// Remover tudo exceto dígitos e +, garantir prefixo +55 para BR
function normalizePhone(phone: string): string {
  const digits = phone.replace(/\D/g, '');
  if (digits.startsWith('55') && digits.length >= 12) return `+${digits}`;
  if (digits.length === 11 || digits.length === 10) return `+55${digits}`;
  return `+${digits}`;
}
```
**Warning signs:** Mesmo cliente registrado duas vezes com formatos diferentes de phone.

### Pitfall 3: Audit log bloqueando resposta principal
**O que acontece:** `await auditLogService.log(...)` falha (ex: timeout de DB) e lança exceção, tornando o GET /clients/:id um 500.
**Por que acontece:** Audit log é infraestrutura secundária — falha dela não deve derrubar a operação principal.
**Como evitar:** Usar fire-and-forget com catch silencioso para audit log:
```typescript
// Não bloquear resposta pelo audit log
auditLogService.log({ ... }).catch(err => {
  app.log.error({ err }, 'Audit log failed — non-critical');
});
```
**Warning signs:** Falha de DB no audit_logs derrubando endpoints de leitura de clientes.

### Pitfall 4: anamnesis.fields JSONB sem schema → dados inconsistentes
**O que acontece:** Campo `fields` é JSONB sem schema fixo. Se não validado por categoria no backend, dados de anamnese de Lash podem conter campos de Micropig.
**Por que acontece:** JSONB aceita qualquer coisa.
**Como evitar:** Definir um mapa de campos esperados por categoria no service. Não rejeitar campos extras (flexibilidade de customização), mas validar que o formato dos valores é correto (booleano é booleano, não string "sim").
**Warning signs:** Anamnese retornando `{ "gravidez": "sim" }` em vez de `{ "gravidez": true }`.

### Pitfall 5: professional_services replace sem transaction
**O que acontece:** DELETE dos vínculos antigos seguido de INSERT dos novos — se o INSERT falhar, o profissional fica sem serviços vinculados.
**Por que acontece:** Duas queries separadas sem transaction.
**Como evitar:** Sempre usar `pool.connect()` + BEGIN/COMMIT/ROLLBACK para replace de vínculos N:N (Pattern 7 acima).
**Warning signs:** Profissional aparece na lista mas sem serviços vinculados após edição.

### Pitfall 6: Tags automáticas "Novo"/"Inativo" sendo gravadas no campo tags do banco
**O que acontece:** Se o service gravar as auto-tags ("novo", "inativo") no campo JSONB `tags`, elas serão duplicadas ou permanecerão mesmo após o cliente ter agendamentos.
**Por que acontece:** Confusão entre tags manuais persistidas e tags automáticas calculadas.
**Como evitar:** Campo `tags` no banco armazena apenas tags manuais (VIP, custom). Auto-tags são adicionadas dinamicamente no service ao retornar o cliente, nunca persistidas.

### Pitfall 7: ClientDetailScreen sem audit log no Flutter
**O que acontece:** GET /clients/:id no backend registra audit log, mas se o Flutter faz múltiplas chamadas (ex: reload automático), gera flood de audit log entries.
**Por que acontece:** Pull-to-refresh + auto-reload no Flutter.
**Como evitar:** Audit log de `view` deve ser registrado apenas na primeira visualização da sessão, não em cada reload. Implementar debounce no backend: verificar se já foi registrado `view` para o mesmo (userId, clientId) nos últimos N minutos antes de inserir.

---

## Code Examples

### Repository Query Pattern — Client List com Search

```typescript
// Source: padrão pg do projeto (supabase.md rules) + API_CONTRACTS.md §7
async list(params: {
  studioId: string;
  search?: string;
  tag?: string;
  inactiveDays?: number;
  cursor?: string;
  limit: number;
}): Promise<ClientRow[]> {
  const queryParams: unknown[] = [params.studioId];
  let whereClause = `studio_id = $1`;
  let paramIndex = 2;

  if (params.search) {
    whereClause += ` AND (name ILIKE $${paramIndex} OR phone LIKE $${paramIndex + 1})`;
    queryParams.push(`%${params.search}%`, `%${params.search}%`);
    paramIndex += 2;
  }

  if (params.tag) {
    whereClause += ` AND tags @> $${paramIndex}::jsonb`;
    queryParams.push(JSON.stringify([params.tag]));
    paramIndex++;
  }

  if (params.inactiveDays) {
    whereClause += ` AND (last_appointment_at IS NULL OR last_appointment_at < now() - interval '$${paramIndex} days')`;
    queryParams.push(params.inactiveDays);
    paramIndex++;
  }

  if (params.cursor) {
    whereClause += ` AND id > $${paramIndex}`;
    queryParams.push(params.cursor);
    paramIndex++;
  }

  const { rows } = await this.pool.query<ClientRow>(
    `SELECT id, studio_id, name, phone, email, birth_date, tags, last_appointment_at, created_at
     FROM clients
     WHERE ${whereClause}
     ORDER BY name ASC, id ASC
     LIMIT $${paramIndex}`,
    [...queryParams, params.limit + 1]
  );
  return rows;
}
```

### Client Stats Join (sem N+1)

```typescript
// Source: API_CONTRACTS.md §7 (GET /clients/:id — inclui stats)
// NUNCA fazer 3 queries separadas para as stats — usar subquery
async getByIdWithStats(clientId: string, studioId: string) {
  const { rows } = await this.pool.query(
    `SELECT
       c.id, c.studio_id, c.name, c.phone, c.email, c.birth_date, c.tags, c.notes,
       c.last_appointment_at, c.created_at, c.updated_at,
       COUNT(a.id) FILTER (WHERE a.status = 'completed') AS total_appointments,
       COALESCE(SUM(p.amount) FILTER (WHERE a.status = 'completed'), 0) AS total_spent,
       (SELECT s.name FROM appointments la JOIN services s ON la.service_id = s.id
        WHERE la.client_id = c.id AND la.status = 'completed'
        ORDER BY la.start_time DESC LIMIT 1) AS last_service
     FROM clients c
     LEFT JOIN appointments a ON a.client_id = c.id AND a.studio_id = c.studio_id
     LEFT JOIN payments p ON p.appointment_id = a.id
     WHERE c.id = $1 AND c.studio_id = $2
     GROUP BY c.id`,
    [clientId, studioId]
  );
  return rows[0] ?? null;
}
```

### Anamnesis Upsert Pattern

```typescript
// Source: DATABASE_SCHEMA.md (UNIQUE(studio_id, client_id, service_category_id))
async upsert(params: {
  studioId: string;
  clientId: string;
  serviceCategoryId: string;
  fields: Record<string, unknown>;
}): Promise<AnamnesisRow> {
  const { rows } = await this.pool.query<AnamnesisRow>(
    `INSERT INTO anamneses (id, studio_id, client_id, service_category_id, fields)
     VALUES (gen_random_uuid(), $1, $2, $3, $4)
     ON CONFLICT (studio_id, client_id, service_category_id)
     DO UPDATE SET fields = EXCLUDED.fields, updated_at = now()
     RETURNING id, studio_id, client_id, service_category_id, fields, created_at, updated_at`,
    [params.studioId, params.clientId, params.serviceCategoryId, JSON.stringify(params.fields)]
  );
  return rows[0]!;
}
```

### Flutter: Infinite Scroll Pattern (ClientListScreen)

```dart
// Source: SCREENS.md §4.1 + padrão AppointmentCard existente no projeto
class _ClientListState extends ConsumerState<ClientListScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    // Prefetch at 80% scroll (pattern defined in SCREENS.md)
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      ref.read(clientListProvider.notifier).loadMore();
    }
  }
  // ...
}
```

### Anamnesis Templates (Flutter) — Tipos de campos por clínica

```dart
// Source: CONTEXT.md — templates por categoria de beleza
// Claude's discretion para field types: bool = toggle, string = text, list = select
const Map<String, List<AnamnesisField>> kAnamnesisTemplates = {
  'Lash': [
    AnamnesisField(key: 'alergia_cola', label: 'Alergia a cola de cílios?', type: FieldType.bool),
    AnamnesisField(key: 'usa_lentes', label: 'Usa lentes de contato?', type: FieldType.bool),
    AnamnesisField(key: 'lagrima_artificial', label: 'Usa lágrima artificial?', type: FieldType.bool),
    AnamnesisField(key: 'olho_sensivel', label: 'Olho sensível?', type: FieldType.bool),
    AnamnesisField(key: 'observacoes', label: 'Observações', type: FieldType.text),
  ],
  'Micropigmentacao': [
    AnamnesisField(key: 'gravidez', label: 'Está grávida ou amamentando?', type: FieldType.bool),
    AnamnesisField(key: 'anticoagulante', label: 'Usa anticoagulante?', type: FieldType.bool),
    AnamnesisField(key: 'queloides', label: 'Tem histórico de queloides?', type: FieldType.bool),
    AnamnesisField(key: 'diabetes', label: 'Tem diabetes?', type: FieldType.bool),
    AnamnesisField(key: 'medicamentos', label: 'Medicamentos em uso', type: FieldType.text),
  ],
  'Unhas': [
    AnamnesisField(key: 'alergia_acetona', label: 'Alergia a acetona ou esmalte?', type: FieldType.bool),
    AnamnesisField(key: 'fungos', label: 'Histórico de micose nas unhas?', type: FieldType.bool),
    AnamnesisField(key: 'unhas_fracas', label: 'Unhas fracas ou quebradiças?', type: FieldType.bool),
  ],
  'Estetica': [
    AnamnesisField(key: 'alergias', label: 'Alergias conhecidas', type: FieldType.text),
    AnamnesisField(key: 'medicamentos', label: 'Medicamentos em uso', type: FieldType.text),
    AnamnesisField(key: 'gestante', label: 'Gestante?', type: FieldType.bool),
    AnamnesisField(key: 'marca_passo', label: 'Usa marca-passo?', type: FieldType.bool),
  ],
};
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| ORM (Prisma/Drizzle) | pg driver + SQL manual | Decisão de design do projeto | Queries mais explícitas, sem mágica de ORM |
| UPDATE consent flags | Append-only INSERT | Requisito LGPD | Histórico completo de consent, auditável |
| Hard delete de clientes | Anonymization | Requisito LGPD | Preserva histórico financeiro |
| Tags como coluna TEXT[] | JSONB array | Schema do projeto | Mais flexível para tags customizadas |

**Deprecated/outdated:**
- `notes: TEXT` em clients: o campo `notes` existe na tabela mas o produto usa timeline de notas imutáveis. A tab "Notas" da ficha exige uma tabela separada `client_notes` — **gap identificado** (ver Open Questions).

---

## Open Questions

1. **Tabela `client_notes` não existe no schema atual**
   - O que sabemos: A tabela `clients` tem um campo `notes: TEXT` (nota única), mas o CONTEXT.md define notas como "timeline imutável, como chat comments".
   - O que está incerto: CONTEXT.md diz "Free text with timeline (like chat comments) — each note is dated, immutable once created". O campo `notes` atual não suporta isso.
   - Recomendação: Criar migration para tabela `client_notes` (id, studio_id, client_id, content TEXT NOT NULL, created_by UUID FK auth.users, created_at TIMESTAMPTZ) com RLS via studio_id. O campo `notes` existente em `clients` pode ser migrado como primeira nota ou descartado. Esta migration é necessária antes de implementar a tab Notas.

2. **Threshold para tags "Novo" e "Inativo"**
   - O que sabemos: Claude's Discretion define os thresholds.
   - O que está incerto: Valor exato a usar.
   - Recomendação: "Novo" = cliente sem nenhum agendamento completo (total_appointments = 0). "Inativo" = último agendamento completado há mais de 60 dias (alinha com campaigns.inactivity_days DEFAULT 60 no schema).

3. **Audit log de `view` no GET /clients — flood de registros**
   - O que sabemos: Cada GET /clients/:id deve gerar audit log de `view`.
   - O que está incerto: Se pull-to-refresh no Flutter gera flood de audit logs.
   - Recomendação: Inserir audit log de `view` apenas uma vez por (userId, clientId) em janela de 5 minutos. Implementar com verificação simples: `SELECT 1 FROM audit_logs WHERE user_id = $1 AND entity_id = $2 AND created_at > now() - interval '5 minutes' LIMIT 1`.

4. **Supabase Admin API para criar profissional — senha temporária**
   - O que sabemos: CONTEXT.md define que "Owner sets a temporary password; professional changes on first login".
   - O que está incerto: Fluxo de "primeiro login" — Flutter precisa detectar se é primeiro acesso e forçar troca de senha.
   - Recomendação: Na criação do profissional, incluir metadado no Supabase user metadata: `{ force_password_change: true }`. Flutter lê esse metadado após login e redireciona para tela de troca de senha antes de acessar o app.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Vitest 3.2.1 |
| Config file | `backend/vitest.config.ts` (existe) |
| Quick run command | `cd backend && npm run test` |
| Full suite command | `cd backend && npm run test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SERV-01 | createService injeta studioId corretamente | unit | `npm run test -- tests/services/service.service.test.ts` | ✅ (parcial — só create) |
| SERV-01 | listServices filtra por studio_id | unit | `npm run test -- tests/services/service.service.test.ts` | ❌ Wave 0 |
| SERV-02 | setActive/setInactive modifica is_active | unit | `npm run test -- tests/services/service.service.test.ts` | ❌ Wave 0 |
| CLNT-01 | createClient normaliza phone para E.164 | unit | `npm run test -- tests/services/client.service.test.ts` | ❌ Wave 0 |
| CLNT-02 | phone duplicado lança ConflictError 409 | unit | `npm run test -- tests/services/client.service.test.ts` | ❌ Wave 0 |
| CLNT-03 | upsertAnamnesis cria e atualiza por (client,category) | unit | `npm run test -- tests/services/anamnesis.service.test.ts` | ❌ Wave 0 |
| CLNT-04 | listAppointments por client_id filtra por studio_id | unit | `npm run test -- tests/repositories/client.repository.test.ts` | ❌ Wave 0 |
| CLNT-05 | enrichTags retorna 'novo' quando sem agendamentos | unit | `npm run test -- tests/services/client.service.test.ts` | ❌ Wave 0 |
| CLNT-05 | enrichTags retorna 'inativo' após 60 dias sem visita | unit | `npm run test -- tests/services/client.service.test.ts` | ❌ Wave 0 |
| CLNT-05 | tags manuais (VIP) não são sobrepostas pelas automáticas | unit | `npm run test -- tests/services/client.service.test.ts` | ❌ Wave 0 |
| TEAM-01 | createProfessional cria auth user + registro no DB | unit | `npm run test -- tests/services/professional.service.test.ts` | ❌ Wave 0 |
| TEAM-03 | replaceServiceLinks usa transaction (delete + insert) | unit | `npm run test -- tests/services/professional.service.test.ts` | ❌ Wave 0 |
| TEAM-04 | comissão percentage calculada corretamente | unit | `npm run test -- tests/services/professional.service.test.ts` | ❌ Wave 0 |
| LGPD-01 | clientService.getById chama auditLog.log com action=view | unit | `npm run test -- tests/services/client.service.test.ts` | ❌ Wave 0 |
| LGPD-01 | clientService.anonymize chama auditLog.log com action=delete | unit | `npm run test -- tests/services/client.service.test.ts` | ❌ Wave 0 |
| LGPD-02 | consentService insere novo registro (nunca update) | unit | `npm run test -- tests/services/consent.service.test.ts` | ❌ Wave 0 |
| LGPD-02 | getCurrentConsent retorna estado mais recente | unit | `npm run test -- tests/services/consent.service.test.ts` | ❌ Wave 0 |
| Multi-tenancy | studioA não acessa dados de studioB (clients) | unit | `npm run test -- tests/services/client.service.test.ts` | ❌ Wave 0 |
| Multi-tenancy | studioA não acessa dados de studioB (professionals) | unit | `npm run test -- tests/services/professional.service.test.ts` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `cd backend && npm run test`
- **Per wave merge:** `cd backend && npm run test`
- **Phase gate:** Full suite green antes de `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `tests/services/client.service.test.ts` — cobre CLNT-01, CLNT-02, CLNT-05, LGPD-01
- [ ] `tests/services/anamnesis.service.test.ts` — cobre CLNT-03
- [ ] `tests/services/consent.service.test.ts` — cobre LGPD-02
- [ ] `tests/repositories/client.repository.test.ts` — cobre CLNT-04 (listAppointments)
- [ ] Ampliar `tests/services/service.service.test.ts` — adicionar list, update, setActive (SERV-01, SERV-02)
- [ ] Ampliar `tests/services/professional.service.test.ts` — adicionar create, replaceServiceLinks (TEAM-01, TEAM-03)

---

## Sources

### Primary (HIGH confidence)

- `backend/src/routes/clients.routes.ts` — Zod schemas e stubs completos para todos os endpoints de clientes
- `backend/src/routes/services.routes.ts` — schemas e stubs de serviços
- `backend/src/routes/professionals.routes.ts` — schemas e stubs de profissionais
- `backend/src/routes/audit-logs.routes.ts` — stub do audit log
- `docs/DATABASE_SCHEMA.md` — schema completo com todas as tabelas, índices, e RLS policies
- `docs/API_CONTRACTS.md` — contratos §4 (service-categories), §5 (services), §6 (professionals), §7 (clients)
- `docs/SCREENS.md` — wireframes §4 (clients), §6.4 (services management), §6.5/6.6 (team), AuditLogScreen
- `.planning/phases/02-core-domain/02-CONTEXT.md` — todas as decisões de implementação
- `.claude/rules/` — backend.md, data-modeling.md, supabase.md, mobile.md, testing.md

### Secondary (MEDIUM confidence)

- `backend/src/controllers/service.controller.ts` + `professional.controller.ts` — padrões de controller estabelecidos
- `backend/tests/services/service.service.test.ts` — padrão de test com Vitest + mocks
- `mobile/lib/features/onboarding/` — padrão Riverpod sealed state estabelecido no projeto

### Tertiary (LOW confidence)

- Nenhuma fonte de baixa confiança usada — toda pesquisa baseada em código existente e documentação interna.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — todas as libraries verificadas no código existente
- Architecture: HIGH — padrão Route→Controller→Service→Repository completamente estabelecido e verificado
- Pitfalls: HIGH — baseados em regras explícitas do projeto (.claude/rules/) + schema constraints do banco
- Flutter patterns: HIGH — verificados no código existente de onboarding e agenda

**Research date:** 2026-04-02
**Valid until:** 2026-05-02 (stack estável, sem mudanças esperadas)

---

**Gap crítico identificado:** A tabela `client_notes` NÃO existe no schema atual. A tab "Notas" (CLNT-05/CLNT-06 + CONTEXT.md) requer timeline imutável de notas — o campo `notes: TEXT` na tabela `clients` não suporta isso. O Wave 0 do plano DEVE incluir a migration para `client_notes`.
