# Phase 2: Core Domain — Research

**Researched:** 2026-04-02 (atualizado 2026-04-02)
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

**Team management (UPDATED)**
- Owner generates invite link shared via WhatsApp — link expires in 7 days
- Collaborator clicks link, creates own account (email + password), gets linked to studio automatically
- Owner pre-configures: name, services (checkbox), commission rate, card fee policy
- Each professional linked to specific services (checkbox selection)
- Toggle active/inactive per professional (is_active field exists) — inactive hides from scheduling but preserves history
- Professional inherits studio hours by default, can override with custom working_hours (JSONB field exists)

**Team permissions (NEW)**
- Collaborator sees only: her own agenda, her clients, her working hours
- Collaborator does NOT see: financeiro, commissions of others, studio settings, other professionals' agendas
- Owner sees everything

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

**Empty states (NEW)**
- Consistent pattern across all screens (clients, services, team)
- Illustration (clean/minimal) + contextual text + CTA button ("Adicionar primeiro cliente", etc.)
- Follows Cal.com/Linear visual reference

**Navigation (UPDATED)**
- Bottom nav with 4 tabs: Agenda | Clientes | Serviços | Mais
- "Mais" opens a list screen with: Equipe, Financeiro (em breve), Configurações, Meu perfil, Sair
- Future phases add items to "Mais" without changing bottom nav structure

### Claude's Discretion
- Loading skeletons and transition animations
- Exact spacing, typography, and color palette within clean minimal direction
- Error state handling
- Anamnesis template field types (boolean, text, select) — whatever makes clinical sense
- Audit log UI presentation (tab vs expandable section in client detail)
- How "Novo" and "Inativo" tags are calculated (days since last appointment thresholds)
- Invite link generation mechanism (token format, URL structure)
- First-login flow for collaborators after accepting invite

### Deferred Ideas (OUT OF SCOPE)
- Import/export de clientes (CSV/Excel) — future feature, not Phase 2 scope
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
| CLNT-05 | Professional can add private notes and tag clients (VIP, new, inactive) | Notes field exists in clients table. Auto-tags (Novo/Inativo) need business logic rule in service layer. client_notes table does NOT exist — migration required. |
| CLNT-06 | Client detail shows full ficha with tabs | Flutter: ClientDetailScreen with Histórico, Anamnese, Notas tabs per SCREENS.md. |
| TEAM-01 | Owner can register professionals linked to services with commission rules | Route stub exists; ProfessionalController.update() implemented. Need: create (invite flow), list, getById, delete. professional_services N:N table exists. |
| TEAM-02 | Owner generates invite link; collaborator creates own account via link | UPDATED: no temp password. Need: professional_invites table (migration), POST /professionals/invites, POST /auth/accept-invite endpoints. |
| TEAM-03 | Each professional linked to specific services via checkbox | professional_services table exists with UNIQUE(professional_id, service_id). Patch replaces all links atomically in a transaction. |
| TEAM-04 | Commission rules: percentage or fixed amount | commission_type + commission_value fields exist in professionals table. |
| TEAM-05 | Card fee policy configurable per professional | card_fee_policy field exists ('studio', 'professional', 'split'). |
| LGPD-01 | Every access to sensitive client data is recorded in audit log | audit_log table exists (partitioned by month, INSERT via service_role). Need: AuditLogService called automatically by ClientService on view/export/delete. |
| LGPD-02 | Consent record capture and revocation | consent_records table exists (append-only). ConsentService inserts new record per action (never updates). |
</phase_requirements>

---

## Summary

Esta fase implementa três domínios independentes (Serviços, Clientes, Equipe) mais infraestrutura LGPD obrigatória. Quase todos os artefatos de infraestrutura já existem: tabelas criadas, schemas Zod definidos, stubs de rotas presentes, e os primeiros métodos de service/repository implantados. O trabalho desta fase é completar as implementações pendentes e construir as telas Flutter correspondentes.

O backend segue padrão Route → Controller → Service → Repository completamente estabelecido. Todos os repositórios usam `pg` (node-postgres) com SQL manual — sem ORM. O Flutter usa Riverpod com sealed states (Loading/Success/Error), GoRouter para navegação, e `ApiClient` HTTP wrapper já existente. O banco tem RLS ativo em todas as tabelas. Esta fase requer **duas migrations** que não existiam na versão anterior: `professional_invites` (fluxo de convite por link) e `client_notes` (timeline imutável de notas).

O fluxo de convite por link substituiu completamente a criação com senha temporária. O owner pré-configura o profissional (nome, serviços, comissão), o sistema gera um token UUID v4 com TTL de 7 dias, e o link `oriz://invite/<token>` é copiado para o WhatsApp. A colaboradora clica, cria sua própria conta (email + senha), e é automaticamente vinculada ao studio. O bottom nav também foi atualizado: o tab "Financeiro" (Phase 4) é substituído por "Serviços" nesta fase — `/financial` não aparece no nav até Phase 4.

**Recomendação primária:** Implementar backend primeiro (waves ordenadas por domínio: Serviços → Clientes → Equipe + Invite → LGPD), depois Flutter screens por domínio. Audit log deve ser injetado como middleware de serviço reutilizável, não duplicado em cada endpoint.

---

## Standard Stack

### Core (já em uso, HIGH confidence)

| Library | Version | Purpose | Confirmed |
|---------|---------|---------|-----------|
| Fastify | ^5.3.3 | HTTP framework | server.ts |
| Zod + fastify-type-provider-zod | ^3.25.11 / ^4.0.2 | Schema validation | routes/*.ts |
| node-postgres (pg) | ^8.20.0 | DB driver | repositories/*.ts |
| Vitest | ^3.2.1 | Unit testing | package.json |
| Flutter + Riverpod | 3.x / ^3.3.1 | Mobile app + state | mobile/lib/ |
| GoRouter | ^17.1.0 | Routing | app_router.dart |
| Supabase Flutter | ^2.0.0 | Auth only (not DB) | mobile/lib/core/ |
| @supabase/supabase-js | ^2.99.1 | Admin API (backend) | package.json |
| jose | ^6.0.11 | JWT verification | auth middleware |

### Supporting

| Library | Purpose | When to Use |
|---------|---------|-------------|
| `crypto.randomUUID()` (Node built-in) | Gerar token de convite | TEAM-02: POST /professionals/invites |
| `ioredis` | TTL de token de convite em cache (opcional) | Alternativa a TTL via DB — usar DB por simplicidade |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| SQL manual (pg) | Drizzle ORM | Projeto usa SQL manual por decisão existente — não alterar |
| Append-only inserts para consent | Update de flag | Append-only é padrão LGPD e já definido no schema |
| DB para TTL do invite token | Redis TTL | DB é mais simples e suficiente para 7d TTL com cleanup job |

---

## Architecture Patterns

### Estrutura de Arquivos — Backend (padrão estabelecido)

```
backend/src/
├── routes/
│   ├── clients.routes.ts          # stub completo com Zod schemas
│   ├── services.routes.ts         # stub completo
│   ├── professionals.routes.ts    # stub completo — adicionar /invites endpoints
│   └── audit-logs.routes.ts       # stub completo
├── controllers/
│   ├── client.controller.ts       # NOVO
│   ├── service.controller.ts      # parcial (create existe)
│   ├── professional.controller.ts # parcial (update existe) — adicionar create/invite/list/delete
│   ├── anamnesis.controller.ts    # NOVO
│   ├── consent.controller.ts      # NOVO
│   └── audit-log.controller.ts    # NOVO
├── services/
│   ├── client.service.ts          # NOVO
│   ├── service.service.ts         # parcial (createService existe)
│   ├── professional.service.ts    # parcial (updateWorkingHours existe) — adicionar invite flow
│   ├── anamnesis.service.ts       # NOVO
│   ├── consent.service.ts         # NOVO
│   └── audit-log.service.ts       # NOVO
├── repositories/
│   ├── client.repository.ts       # NOVO
│   ├── service.repository.ts      # parcial (create existe)
│   ├── professional.repository.ts # parcial (findByUserId, updateWorkingHours existem)
│   ├── anamnesis.repository.ts    # NOVO
│   ├── consent.repository.ts      # NOVO
│   └── audit-log.repository.ts    # NOVO
└── types/
    └── fastify.d.ts               # atualizar com novos controllers
```

### Estrutura de Arquivos — Flutter (padrão estabelecido)

```
mobile/lib/
├── core/
│   ├── shell/app_shell.dart           # ATUALIZAR: tab Serviços em vez de Financeiro
│   └── router/app_router.dart        # ATUALIZAR: /services rota + /invite/:token rota
└── features/
    ├── clients/
    │   ├── data/
    │   │   ├── client_repository.dart
    │   │   └── anamnesis_templates.dart
    │   ├── domain/
    │   │   ├── client_model.dart
    │   │   └── anamnesis_model.dart
    │   ├── providers/client_provider.dart
    │   └── presentation/
    │       ├── client_list_screen.dart     # NOVO (substitui _Placeholder)
    │       ├── client_detail_screen.dart   # NOVO
    │       ├── client_form_screen.dart     # NOVO
    │       ├── anamnesis_form_screen.dart  # NOVO
    │       └── widgets/
    │           ├── client_list_item.dart
    │           ├── client_list_item_skeleton.dart
    │           └── tag_chip.dart
    ├── services_management/
    │   ├── data/service_mgmt_repository.dart
    │   ├── domain/service_model.dart
    │   ├── providers/service_mgmt_provider.dart
    │   └── presentation/
    │       ├── services_management_screen.dart    # NOVO
    │       ├── service_form_screen.dart           # NOVO
    │       └── widgets/service_card.dart
    └── team/
        ├── data/team_repository.dart
        ├── domain/professional_model.dart
        ├── providers/team_provider.dart
        └── presentation/
            ├── team_management_screen.dart        # NOVO
            ├── professional_form_screen.dart      # NOVO (pré-config + gerar link)
            ├── invite_accept_screen.dart          # NOVO (collaborator signup via token)
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

### Pattern 5: Invite Link Flow (NOVO — substitui senha temporária)

**O que é:** Owner pré-configura profissional (nome, serviços, comissão). Sistema gera token UUID. Link é copiado para WhatsApp. Colaboradora abre link no app, cria conta, fica vinculada automaticamente.
**Quando usar:** POST /api/v1/professionals/invites (criar convite), POST /api/v1/auth/accept-invite (aceitar e criar conta).

**Fluxo completo:**

```
Owner (Flutter)                Backend                    Collaborator (Flutter)
─────────────────────────────────────────────────────────────────────────────────
1. Preenche form: nome,    →  POST /professionals/invites
   serviços, comissão         Body: { name, service_ids,
                               commission_type, commission_value,
                               card_fee_policy }
                           ←  201 { data: { invite_token, expires_at,
                                           whatsapp_link } }
2. Copia link WhatsApp
   oriz://invite/<token>

                                                      3. Clica no link →
                                                         App abre InviteAcceptScreen
                                                         GET /professionals/invites/<token>
                                                      ←  200 { data: { studio_name, name } }
                                                      4. Preenche email + senha
                                                         POST /auth/accept-invite
                                                         Body: { token, email, password }
                              ↑ cria auth user via Supabase
                                insere professionals row
                                deletes/expires invite_token
                           ←                          201 { data: { session } }
                                                      5. App navega para /agenda
```

**Backend — criação do invite:**

```typescript
// Source: CONTEXT.md (Team management — invite link flow)
// professional_invites table: nova migration necessária
async createInvite(studioId: string, ownerUserId: string, input: CreateInviteInput) {
  const token = crypto.randomUUID(); // UUID v4 — entropia suficiente para token seguro
  const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000); // 7 dias

  await this.repo.createInvite({
    token,
    studioId,
    createdBy: ownerUserId,
    name: input.name,
    serviceIds: input.serviceIds ?? [],
    commissionType: input.commissionType,
    commissionValue: input.commissionValue,
    cardFeePolicy: input.cardFeePolicy,
    expiresAt,
  });

  // WhatsApp deep link — abre o app Oriz na tela de aceitar convite
  const whatsappLink = `https://wa.me/?text=${encodeURIComponent(
    `Você foi convidada para usar o Oriz! Clique para aceitar: oriz://invite/${token}`
  )}`;

  return { invite_token: token, expires_at: expiresAt, whatsapp_link: whatsappLink };
}
```

**Backend — aceitar invite (criar conta):**

```typescript
// Source: CONTEXT.md + auth flow estabelecido (auth.routes.ts)
async acceptInvite(token: string, email: string, password: string) {
  // 1. Validar token (existe, não expirado, não usado)
  const invite = await this.inviteRepo.findByToken(token);
  if (!invite) throw new NotFoundError('INVITE_NOT_FOUND', 'Convite não encontrado');
  if (invite.expires_at < new Date()) throw new UnprocessableError('INVITE_EXPIRED', 'Convite expirado');
  if (invite.used_at) throw new ConflictError('INVITE_ALREADY_USED', 'Convite já foi utilizado');

  // 2. Criar usuário Supabase Auth
  const { data: authUser, error } = await this.supabaseAdmin.auth.admin.createUser({
    email,
    password,
    email_confirm: true, // confirma email automaticamente — profissional já foi convidada
  });
  if (error) throw new ConflictError('EMAIL_ALREADY_EXISTS', 'Email já cadastrado');

  // 3. Inserir professional (dentro de transaction)
  const professional = await this.professionalRepo.create({
    studioId: invite.studio_id,
    userId: authUser.user.id,
    name: invite.name,
    commissionType: invite.commission_type,
    commissionValue: invite.commission_value,
    cardFeePolicy: invite.card_fee_policy,
  });

  // 4. Vincular serviços
  if (invite.service_ids?.length) {
    await this.professionalRepo.replaceServiceLinks(professional.id, invite.studio_id, invite.service_ids);
  }

  // 5. Marcar invite como usado
  await this.inviteRepo.markUsed(token);

  // 6. Retornar sessão autenticada
  const { data: session } = await this.supabaseAdmin.auth.admin.createSession({
    user_id: authUser.user.id,
  });

  return session;
}
```

**Migration necessária — professional_invites:**

```sql
-- Source: CONTEXT.md (invite link, 7 dias TTL) + data-modeling.md rules
CREATE TABLE professional_invites (
  token         UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
  studio_id     UUID         NOT NULL REFERENCES studios(id) ON DELETE CASCADE,
  created_by    UUID         NOT NULL REFERENCES auth.users(id),
  name          TEXT         NOT NULL,
  service_ids   UUID[]       NOT NULL DEFAULT '{}',
  commission_type TEXT       NOT NULL CHECK (commission_type IN ('percentage', 'fixed')),
  commission_value NUMERIC(10,2) NOT NULL DEFAULT 0,
  card_fee_policy TEXT       NOT NULL DEFAULT 'studio'
                             CHECK (card_fee_policy IN ('studio', 'professional', 'split')),
  expires_at    TIMESTAMPTZ  NOT NULL DEFAULT (now() + interval '7 days'),
  used_at       TIMESTAMPTZ,
  created_at    TIMESTAMPTZ  NOT NULL DEFAULT now()
);

CREATE INDEX idx_professional_invites_studio_id ON professional_invites(studio_id);
-- RLS: owner do studio pode SELECT/INSERT/DELETE
ALTER TABLE professional_invites ENABLE ROW LEVEL SECURITY;
CREATE POLICY "owner_manage_invites" ON professional_invites
  USING (studio_id = auth.studio_id())
  WITH CHECK (studio_id = auth.studio_id());
-- Leitura pública do token (necessário para /auth/accept-invite sem auth)
-- Implementar via endpoint backend com service_role — não expor RLS público
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
**Quando usar:** POST /professionals/invites (accept) e PATCH /professionals/:id quando service_ids enviado.

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

### Pattern 8: Bottom Nav Update — Serviços em vez de Financeiro

**O que é:** O ShellRoute no GoRouter já tem 4 tabs. O tab 2 (index 2) era "Financeiro" — deve ser atualizado para "Serviços". Financeiro vai para a tela "Mais" como item (Phase 4 irá expandir).

**Arquivos a alterar:**
- `mobile/lib/core/shell/app_shell.dart` — trocar `/financial` por `/services`, atualizar label e ícone
- `mobile/lib/core/router/app_router.dart` — trocar rota `/financial` por `/services` com ServicesManagementScreen

```dart
// Source: mobile/lib/core/shell/app_shell.dart (existente — modificar)
// Trocar tab index 2:
// ANTES: path='/financial', label='Financeiro', icon=Icons.attach_money_rounded
// DEPOIS:
GoRoute(
  path: '/services',
  builder: (_, __) => const ServicesManagementScreen(),
),

// Em app_shell.dart — _currentIndex():
if (location.startsWith('/services')) return 2;  // era /financial

// BottomNavigationBarItem index 2:
BottomNavigationBarItem(
  icon: Icon(Icons.content_cut_outlined),      // ícone de tesoura/serviços
  activeIcon: Icon(Icons.content_cut_rounded),
  label: 'Serviços',
),
```

**Rota de deep link para invite (GoRouter):**
```dart
// Adicionar ao ShellRoute ou como rota top-level sem shell
GoRoute(
  path: '/invite/:token',
  builder: (context, state) =>
    InviteAcceptScreen(token: state.pathParameters['token']!),
),
// Esta rota NÃO precisa de auth — é para colaboradora nova que ainda não tem conta
// Deve ficar fora do ShellRoute, junto às rotas auth
```

### Pattern 9: Empty State Widget (NOVO — padrão definido)

**O que é:** Toda lista vazia mostra ilustração + texto contextual + CTA. Padrão consistente em Clientes, Serviços, Equipe.
**Referência visual:** Cal.com / Linear — clean, minimal, whitespace-heavy.

```dart
// Source: CONTEXT.md (Empty states — illustration + CTA)
class EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final String ctaLabel;
  final VoidCallback onCta;
  final Widget? illustration; // SVG ou imagem local

  const EmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    required this.onCta,
    this.illustration,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (illustration != null) ...[
              illustration!,
              const SizedBox(height: 24),
            ],
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: onCta, child: Text(ctaLabel)),
          ],
        ),
      ),
    );
  }
}

// Uso em ClientListScreen quando lista vazia:
EmptyState(
  title: 'Nenhum cliente cadastrado',
  subtitle: 'Adicione seu primeiro cliente para começar.',
  ctaLabel: 'Adicionar primeiro cliente',
  onCta: () => context.push('/clients/new'),
)
```

### Pattern 10: Team Permissions — Collaborator vs Owner

**O que é:** Colaboradora autentica normalmente, mas a API filtra o que ela pode ver com base no role extraído do JWT.
**Quando usar:** Todos os endpoints de agenda, clientes, e equipe devem respeitar o role.

**Backend — como o role é determinado:**
O `professionals.user_id` mapeia o `auth.uid()` para o registro de profissional. O middleware `requireStudioMember` já valida que o usuário pertence ao studio. O role "owner" é determinado pelo campo `studios.owner_user_id = auth.uid()`.

```typescript
// Source: padrão do projeto (middleware) — regra CONTEXT.md
// GET /api/v1/professionals — retorna todos se owner, só a própria se collaborator
async list(studioId: string, requestingUserId: string, isOwner: boolean) {
  if (isOwner) {
    return this.repo.listAll(studioId, cursor, limit);
  } else {
    // Colaboradora vê apenas seu próprio perfil
    return this.repo.findByUserId(requestingUserId, studioId);
  }
}

// Campos sensíveis (commission, card_fee_policy) → null para não-owner
// Já documentado no stub da rota: "commission → null for non-owners"
```

**Flutter — ocultar tabs baseado no role:**
```dart
// Source: CONTEXT.md (Team permissions — collaborator sees only own agenda)
// Colaboradora NÃO deve ver: tab Serviços (gerenciamento), tab Mais > Equipe, tab Mais > Financeiro
// Implementar: ler role do provider de auth, condicionar visibilidade dos tabs/items do "Mais"
```

### Anti-Patterns a Evitar

- **Select * em qualquer query:** sempre especificar colunas explicitamente (regra crítica do projeto).
- **Studio_id via params/body:** sempre derivar do JWT authContext — nunca aceitar do cliente.
- **UPDATE em consent_records:** é append-only — erro de arquitetura crítico.
- **UPDATE em audit_logs:** é append-only — INSERT via service_role apenas.
- **Lógica de tag automática no DB:** calcular no service layer, não como coluna gerada.
- **Chamar Supabase diretamente no Flutter para CRUD:** todo CRUD passa pela API Fastify.
- **Deletar hard o cliente com appointment history:** sempre anonimizar.
- **Expor token de convite em resposta de listagem:** invite_token é single-use, retornar apenas na criação.
- **Tab "Serviços" visível para colaboradora:** ocultar ou restringir baseado no role.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Phone format validation | Regex manual E.164 | Zod `.regex(/^\+[1-9]\d{10,14}$/)` no CreateClientBody | Já definido no schema existente |
| Duplicate phone detection | Verificação em service layer | Catch pg error `23505` → `ConflictError('PHONE_ALREADY_EXISTS')` | DB constraint já existe: UNIQUE(studio_id, phone) |
| Invite token generation | Hash customizado ou HMAC | `crypto.randomUUID()` (Node built-in, UUID v4) | Entropia suficiente, padrão, zero dependência |
| Invite expiry | Cron job manual | `expires_at TIMESTAMPTZ` no DB + verificação na query | Simples e confiável; cleanup periódico via job |
| Collaborator auth after invite | Fluxo customizado de "primeiro login" | Supabase Admin API `createUser` com `email_confirm: true` na aceitação | Supabase gerencia sessão; email_confirm pula verificação |
| WhatsApp deep link | SDK WhatsApp | `https://wa.me/?text=` com link encode | URL pública sem dependência; funciona em qualquer plataforma |
| Cursor pagination meta | Lógica manual | Padrão existente: fetch limit+1, has_more = rows.length > limit | Já estabelecido nos outros repositories |
| Auto-tag "Novo"/"Inativo" | Coluna calculada ou trigger | Lógica em service ao retornar cliente | Threshold configurável no futuro sem migration |
| Audit log chamada | Interceptor HTTP global | Chamada explícita no service (apenas em ClientService) | Audit log não é para todo endpoint, só dados sensíveis |

**Insight chave:** O schema do banco foi projetado para esta fase — quase todas as constraints, índices e campos necessários já existem. São necessárias apenas 2 novas migrations: `professional_invites` e `client_notes`.

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
    if (err.constraint?.includes('email')) throw new ConflictError('EMAIL_ALREADY_EXISTS', 'Email já cadastrado');
  }
  throw err;
}
```
**Warning signs:** Teste de criação duplicada retornando 500 em vez de 409.

### Pitfall 2: Phone não normalizado para E.164
**O que acontece:** Cliente registrado com "(11) 99999-1234" e outro com "+5511999991234" — ambos passam na validação mas são o mesmo número.
**Por que acontece:** Validação Zod aceita o formato E.164 mas não normaliza entrada do usuário.
**Como evitar:** Normalizar o phone no service antes de persistir:
```typescript
function normalizePhone(phone: string): string {
  const digits = phone.replace(/\D/g, '');
  if (digits.startsWith('55') && digits.length >= 12) return `+${digits}`;
  if (digits.length === 11 || digits.length === 10) return `+55${digits}`;
  return `+${digits}`;
}
```

### Pitfall 3: Audit log bloqueando resposta principal
**O que acontece:** `await auditLogService.log(...)` falha e lança exceção, tornando o GET /clients/:id um 500.
**Como evitar:** Usar fire-and-forget com catch silencioso:
```typescript
auditLogService.log({ ... }).catch(err => {
  app.log.error({ err }, 'Audit log failed — non-critical');
});
```

### Pitfall 4: anamnesis.fields JSONB sem schema → dados inconsistentes
**O que acontece:** Campo `fields` aceita qualquer coisa. Dados de Lash podem conter campos de Micropig.
**Como evitar:** Validar que boolean é boolean, não string "sim". Os templates no Flutter definem os tipos — o backend valida o formato dos valores no Zod schema antes de persistir.

### Pitfall 5: professional_services replace sem transaction
**O que acontece:** DELETE dos vínculos antigos seguido de INSERT dos novos — se o INSERT falhar, profissional fica sem serviços vinculados.
**Como evitar:** Sempre usar `pool.connect()` + BEGIN/COMMIT/ROLLBACK (Pattern 7 acima).

### Pitfall 6: Tags automáticas gravadas no campo tags do banco
**O que acontece:** Se o service gravar as auto-tags ("novo", "inativo") no campo JSONB `tags`, ficam permanentes mesmo após o cliente ter agendamentos.
**Como evitar:** Campo `tags` no banco armazena apenas tags manuais (VIP, custom). Auto-tags são adicionadas dinamicamente ao retornar o cliente, nunca persistidas.

### Pitfall 7: Audit log de `view` gerando flood no pull-to-refresh
**O que acontece:** Pull-to-refresh no Flutter gera múltiplas chamadas a GET /clients/:id → flood de audit logs.
**Como evitar:** Inserir audit log de `view` apenas uma vez por (userId, clientId) em janela de 5 minutos:
```typescript
// Antes de inserir, verificar se já existe entry recente
const { rows } = await pool.query(
  `SELECT 1 FROM audit_logs
   WHERE user_id = $1 AND entity_id = $2 AND action = 'view'
   AND created_at > now() - interval '5 minutes' LIMIT 1`,
  [userId, clientId]
);
if (rows.length === 0) {
  await this.repo.insert({ ... });
}
```

### Pitfall 8: Invite token reutilizável → profissional duplicada (NOVO)
**O que acontece:** Se o token não for marcado como `used_at` após accept, a mesma colaboradora (ou outra) pode criar outra conta e vincular ao studio novamente.
**Como evitar:** O endpoint `POST /auth/accept-invite` DEVE ser atômico: validar token → criar auth user → criar profissional → marcar `used_at = now()` em uma transação. Se qualquer passo falhar, nenhum dado é persistido.

### Pitfall 9: Rota `/invite/:token` protegida por auth → colaboradora sem conta bloqueada (NOVO)
**O que acontece:** Se o GoRouter redireciona `/invite/:token` para `/login` porque não há sessão, a colaboradora não consegue aceitar o convite.
**Como evitar:** A rota `/invite/:token` deve estar na lista de rotas públicas (junto com `/login`, `/signup`, `/forgot-password`) no redirect guard do GoRouter. Verificar o `isAuthRoute` check em `app_router.dart`:
```dart
final isAuthRoute = path == '/login' ||
    path == '/signup' ||
    path == '/forgot-password' ||
    path.startsWith('/invite'); // ADICIONAR
```

### Pitfall 10: Tab Serviços visível para colaboradora → acesso indevido a catálogo (NOVO)
**O que acontece:** Colaboradora vê e potencialmente edita o catálogo de serviços do studio.
**Como evitar:** Ocultar ou redirecionar o tab "Serviços" para usuárias com role "professional" (não owner). Verificar o role no provider antes de renderizar os tabs — ou deixar o tab mas o backend rejeita mutations com 403.

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

  if (params.tag === 'novo') {
    whereClause += ` AND (last_appointment_at IS NULL)`;
  } else if (params.tag === 'inativo') {
    whereClause += ` AND last_appointment_at < now() - interval '60 days'`;
  } else if (params.tag) {
    whereClause += ` AND tags @> $${paramIndex}::jsonb`;
    queryParams.push(JSON.stringify([params.tag]));
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
async getByIdWithStats(clientId: string, studioId: string) {
  const { rows } = await this.pool.query(
    `SELECT
       c.id, c.studio_id, c.name, c.phone, c.email, c.birth_date, c.tags,
       c.last_appointment_at, c.created_at, c.updated_at,
       COUNT(a.id) FILTER (WHERE a.status = 'completed') AS total_appointments,
       COALESCE(SUM(p.amount) FILTER (WHERE a.status = 'completed'), 0) AS total_spent
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
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      ref.read(clientListProvider.notifier).loadMore();
    }
  }
}
```

### Anamnesis Templates (Flutter)

```dart
// Source: CONTEXT.md — templates por categoria de beleza
// Claude's discretion para field types: bool = toggle, string = text
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
| Owner cria senha temporária para colaboradora | Invite link via WhatsApp | CONTEXT.md atualizado 2026-04-02 | Colaboradora cria própria conta — mais seguro, sem sharing de senha |
| Tab Financeiro no nav principal | Tab Serviços no nav principal | CONTEXT.md atualizado 2026-04-02 | Financeiro é Phase 4 — Serviços é Phase 2 |

**Deprecated/outdated (versão anterior desta RESEARCH):**
- `TEAM-02: owner sets temporary password` — SUBSTITUÍDO por invite link flow. O padrão anterior de `supabaseAdmin.auth.admin.createUser` com senha temporária ainda é usado internamente (na aceitação do invite), mas o owner não define mais a senha.

---

## Open Questions

1. **Tabela `client_notes` não existe no schema atual**
   - O que sabemos: A tabela `clients` tem um campo `notes: TEXT` (nota única), mas o CONTEXT.md define notas como "timeline imutável, como chat comments".
   - Recomendação: Criar migration para tabela `client_notes` (id, studio_id, client_id, content TEXT NOT NULL, created_by UUID FK auth.users, created_at TIMESTAMPTZ) com RLS via studio_id. Campo `notes` existente em `clients` pode ser ignorado ou removido. Esta migration é necessária antes de implementar a tab Notas.

2. **Tabela `professional_invites` não existe no schema atual**
   - O que sabemos: Nenhuma tabela de convites foi criada nas migrations 001–003. O fluxo de invite é novo (CONTEXT.md atualizado 2026-04-02).
   - Recomendação: Criar migration `004_professional_invites.sql` com schema descrito no Pattern 5 acima. Esta migration é necessária antes de implementar TEAM-02.

3. **Threshold para tags "Novo" e "Inativo"**
   - Recomendação: "Novo" = cliente sem nenhum agendamento completo (last_appointment_at IS NULL). "Inativo" = último agendamento completado há mais de 60 dias (alinha com campaigns.inactivity_days DEFAULT 60 no schema de marketing).

4. **Como a colaboradora acessa o link de convite no celular**
   - O que sabemos: O link `oriz://invite/<token>` é um deep link. No celular com o app instalado, abre diretamente na InviteAcceptScreen. Se o app não está instalado, o link não funciona.
   - Recomendação: Para Phase 2 (MVP), assumir app já instalado. O link via `wa.me/?text=` é a URL do WhatsApp Web que pré-preenche a mensagem — o owner copia manualmente para a conversa com a colaboradora. Para Phase 5+ considerar universal links com fallback para app store.

5. **Role do usuário — como o Flutter sabe se é owner ou collaborator**
   - O que sabemos: `studios.owner_user_id` identifica o owner. O JWT não inclui o role explicitamente.
   - Recomendação: O endpoint `GET /api/v1/studios/me` ou `GET /api/v1/professionals/me` deve retornar um campo `role: 'owner' | 'professional'`. Flutter armazena no provider após login.

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
| SERV-01 | createService injeta studioId corretamente | unit | `npm run test -- tests/services/service.service.test.ts` | parcial |
| SERV-01 | listServices filtra por studio_id | unit | `npm run test -- tests/services/service.service.test.ts` | ❌ Wave 0 |
| SERV-02 | setActive/setInactive modifica is_active | unit | `npm run test -- tests/services/service.service.test.ts` | ❌ Wave 0 |
| CLNT-01 | createClient normaliza phone para E.164 | unit | `npm run test -- tests/services/client.service.test.ts` | ❌ Wave 0 |
| CLNT-02 | phone duplicado lança ConflictError 409 | unit | `npm run test -- tests/services/client.service.test.ts` | ❌ Wave 0 |
| CLNT-03 | upsertAnamnesis cria e atualiza por (client,category) | unit | `npm run test -- tests/services/anamnesis.service.test.ts` | ❌ Wave 0 |
| CLNT-04 | listAppointments por client_id filtra por studio_id | unit | `npm run test -- tests/repositories/client.repository.test.ts` | ❌ Wave 0 |
| CLNT-05 | enrichTags retorna 'novo' quando sem agendamentos | unit | `npm run test -- tests/services/client.service.test.ts` | ❌ Wave 0 |
| CLNT-05 | enrichTags retorna 'inativo' após 60 dias sem visita | unit | `npm run test -- tests/services/client.service.test.ts` | ❌ Wave 0 |
| CLNT-05 | tags manuais (VIP) não são sobrepostas pelas automáticas | unit | `npm run test -- tests/services/client.service.test.ts` | ❌ Wave 0 |
| TEAM-01 | listProfessionals retorna todos para owner, apenas próprio para collaborator | unit | `npm run test -- tests/services/professional.service.test.ts` | ❌ Wave 0 |
| TEAM-02 | createInvite gera token com TTL 7 dias | unit | `npm run test -- tests/services/professional.service.test.ts` | ❌ Wave 0 |
| TEAM-02 | acceptInvite cria auth user + profissional + marca token usado | unit | `npm run test -- tests/services/professional.service.test.ts` | ❌ Wave 0 |
| TEAM-02 | acceptInvite com token expirado retorna 422 | unit | `npm run test -- tests/services/professional.service.test.ts` | ❌ Wave 0 |
| TEAM-02 | acceptInvite com token já usado retorna 409 | unit | `npm run test -- tests/services/professional.service.test.ts` | ❌ Wave 0 |
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
- [ ] Ampliar `tests/services/professional.service.test.ts` — adicionar invite flow, permissions (TEAM-01, TEAM-02, TEAM-03)
- [ ] `supabase/migrations/004_professional_invites.sql` — tabela de convites (TEAM-02)
- [ ] `supabase/migrations/004_client_notes.sql` — timeline de notas imutáveis (CLNT-05) — pode ser combinada com 004

---

## Sources

### Primary (HIGH confidence)

- `mobile/lib/core/router/app_router.dart` — ShellRoute existente, rotas atuais, estrutura de redirect guard
- `mobile/lib/core/shell/app_shell.dart` — BottomNavigationBar atual com 4 tabs (verificado ao vivo)
- `backend/src/routes/professionals.routes.ts` — Zod schemas e stubs completos (verificado ao vivo)
- `backend/src/routes/auth.routes.ts` — padrão signup existente (verificado ao vivo)
- `backend/src/services/professional.service.ts` — apenas updateWorkingHours implementado (verificado ao vivo)
- `docs/DATABASE_SCHEMA.md` — schema completo com todas as tabelas, índices, e RLS policies
- `docs/API_CONTRACTS.md` — contratos §4 (service-categories), §5 (services), §6 (professionals), §7 (clients)
- `.planning/phases/02-core-domain/02-CONTEXT.md` — todas as decisões de implementação (incluindo updates 2026-04-02)
- `.claude/rules/` — backend.md, data-modeling.md, supabase.md, mobile.md, testing.md

### Secondary (MEDIUM confidence)

- `backend/src/controllers/service.controller.ts` + `professional.controller.ts` — padrões de controller estabelecidos
- `backend/tests/services/service.service.test.ts` — padrão de test com Vitest + mocks
- `mobile/lib/features/onboarding/` — padrão Riverpod sealed state estabelecido no projeto
- `supabase/migrations/001_initial_schema.sql` — confirmado que professional_invites NÃO existe (verificado ao vivo)

### Tertiary (LOW confidence)

- Nenhuma fonte de baixa confiança usada — toda pesquisa baseada em código existente e documentação interna.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — todas as libraries verificadas no código existente (package.json, pubspec.yaml)
- Architecture: HIGH — padrão Route→Controller→Service→Repository completamente estabelecido e verificado ao vivo
- Invite link flow: HIGH — baseado em Supabase Admin API já em uso no projeto + Node.js crypto built-in
- Bottom nav update: HIGH — app_shell.dart lido ao vivo, mudança é cirúrgica (2 arquivos, trocar /financial por /services)
- Pitfalls: HIGH — baseados em regras explícitas do projeto (.claude/rules/) + schema constraints do banco

**Research date:** 2026-04-02
**Valid until:** 2026-05-02 (stack estável, sem mudanças esperadas)

---

**Gaps críticos identificados:**
1. A tabela `client_notes` NÃO existe no schema atual. A tab "Notas" requer timeline imutável — o campo `notes: TEXT` na tabela `clients` não suporta isso. Wave 0 deve incluir migration.
2. A tabela `professional_invites` NÃO existe no schema atual. O fluxo de convite por link (TEAM-02) requer esta tabela. Wave 0 deve incluir migration.
3. A rota `/invite/:token` deve ser adicionada ao GoRouter como rota pública (sem auth redirect) — senão colaboradora sem conta é bloqueada na tela de login.
4. O `app_shell.dart` e `app_router.dart` precisam ser atualizados para refletir "Serviços" no tab 2 em vez de "Financeiro".
