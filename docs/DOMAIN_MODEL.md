# Modelo de Domínio — Oriz

## Entidades Principais

### Auth
- **User** — Usuário autenticado (via Supabase Auth)
- **Profile** — Perfil estendido (nome, telefone, avatar, role)
- **Roles:** owner (dono do estúdio), professional (colaborador), client (cliente)
- Role efetiva por studio é derivada da tabela Professional, não de Profile.role. Profile.role é a role primária do usuário. Para um studio específico: se existe Professional com `user_id` nesse `studio_id` → professional; se é o criador do studio → owner.

### Studio (Tenant)
- **Studio** — Estúdio/negócio de beleza (tenant raiz)
  - owner_id UUID (FK para auth.users — identifica o criador/dono do estúdio)
  - name, slug (URL), phone, address, logo, description
  - timezone (ex: America/Sao_Paulo)
  - settings (JSON: { reminder_hours_before: INT, allow_public_booking: BOOLEAN, default_currency: STRING } — validar com Zod)
- **StudioPhoto** — Fotos do estúdio para página pública
  - studio_id, url, position (ordem de exibição)
  - created_at

### Scheduling
- **Appointment** — Agendamento
  - studio_id, client_id, professional_id, service_id
  - date DATE, start_time TIMESTAMPTZ, end_time TIMESTAMPTZ
  - status: confirmed | completed | cancelled | no_show
  - source: app | whatsapp_ai | web_page | manual
  - notes, cancellation_reason
- **BlockedSlot** — Horário bloqueado (folga, almoço, férias)
  - studio_id, professional_id, date, start_time, end_time, reason

### Clients
- **Client** — Cliente do estúdio
  - studio_id, name, phone, email, birth_date
  - tags (JSON array), notes
  - last_appointment_at (para reativação)
  - created_at
- **Anamnesis** — Ficha de anamnese
  - studio_id, client_id, service_category_id
  - fields (JSON: perguntas e respostas)
  - updated_at

### Services
- **ServiceCategory** — Categoria de serviço (Unhas, Cílios, Sobrancelha, etc.)
  - name, icon (nullable), position (ordem de exibição)
  - studio_id (nullable — NULL = categoria global seed; preenchido = categoria customizada do tenant)
  - is_active
- **Service** — Serviço oferecido
  - studio_id, category_id, name, duration_minutes, price
  - buffer_minutes (intervalo obrigatório entre agendamentos)
  - is_active
- **Package** — Pacote de sessões
  - studio_id, service_id, name, total_sessions, price
  - validity_days
- **PackageSubscription** — Pacote comprado por cliente
  - studio_id, package_id, client_id, sessions_used, sessions_total
  - expires_at, status: active | completed | expired

### Team
- **Professional** — Profissional do estúdio
  - studio_id, user_id, name, avatar, specialties
  - working_hours (JSON: {day: {open, close}} — horários por dia da semana)
  - commission_type: percentage | fixed
  - commission_value
  - card_fee_policy: studio | professional | split
  - is_active
- **ProfessionalService** — Quais serviços cada profissional faz
  - studio_id, professional_id, service_id
- **Commission** — Registro de comissão calculada
  - studio_id, professional_id, appointment_id, amount
  - studio_amount, professional_amount
  - card_fee_amount, who_paid_fee
  - period_start DATE, period_end DATE
  - status: pending | paid

### Financial
- **Payment** — Pagamento recebido
  - studio_id, appointment_id, client_id
  - amount, method: cash | pix | debit | credit
  - card_fee_percentage NUMERIC(5,2) (se cartão — percentual, não centavos)
  - created_at
- **FinancialSummary** — View materializada para dashboard
  - studio_id, period_year INT, period_month INT
  - total_revenue, total_commissions, avg_ticket, occupancy_rate

### AI Assistant
- **Conversation** — Conversa no WhatsApp
  - studio_id, client_id (nullable se novo), whatsapp_number
  - status: active | closed | escalated
  - started_at, last_message_at
- **Message** — Mensagem individual
  - studio_id, conversation_id, role: client | assistant | system
  - content, metadata (JSON)
  - created_at
- **AIConfig** — Configuração da IA por estúdio
  - studio_id, tone_of_voice, greeting_message
  - scheduling_rules (JSON: { max_advance_days: INT, min_advance_hours: INT, auto_confirm: BOOLEAN } — validar com Zod)
  - fallback_message
  - enabled: boolean

### Notifications
- **DeviceToken** — Token FCM por dispositivo
  - user_id, token, platform: android | ios
  - is_active
  - created_at, updated_at
- **NotificationLog** — Registro de push enviados
  - studio_id, user_id, appointment_id (nullable)
  - type: new_booking | reminder | cancellation
  - status: sent | delivered | failed
  - sent_at

### Billing
- **Subscription** — Assinatura SaaS do estúdio
  - studio_id, plan: basic | pro | premium
  - price_cents, billing_cycle: monthly
  - status: active | past_due | cancelled
  - current_period_start, current_period_end
  - gateway_subscription_id (Stripe/Asaas)
- **Invoice** — Fatura gerada por ciclo
  - studio_id, subscription_id, amount_cents
  - status: pending | paid | failed
  - gateway_invoice_id
  - due_at, paid_at

### Compliance
- **ConsentRecord** — Consentimento LGPD para marketing (append-only)
  - client_id, studio_id
  - type: marketing_whatsapp | marketing_push
  - action: granted | revoked
  - created_at
  - Consent ativo = último registro por (client_id, studio_id, type) tem action = granted
- **AuditLog** — Log de acesso a dados sensíveis de clientes
  - studio_id, user_id, action: view | export | delete
  - entity_type, entity_id
  - created_at

### Onboarding
- **OnboardingState** — Progresso do wizard de setup
  - studio_id, current_step: studio_data | services | business_hours | complete
  - completed_at (nullable)

### Marketing
- **Campaign** — Campanha automática
  - studio_id, type: birthday | reactivation | custom
  - message_template, discount_percentage (nullable)
  - inactivity_days (para reativação, default 60)
  - channel: whatsapp | push | both
  - is_active
- **CampaignLog** — Registro de envios
  - studio_id, campaign_id, client_id, sent_at
  - status: sent | delivered | failed
  - result: returned | no_response (para métricas)

## Relacionamentos Chave

```
Studio (1) ──→ (N) Professional
Studio (1) ──→ (N) Client
Studio (1) ──→ (N) Service
Studio (1) ──→ (N) Appointment
Professional (1) ──→ (N) Appointment
Client (1) ──→ (N) Appointment
Service (1) ──→ (N) Appointment
Client (1) ──→ (N) PackageSubscription
Package (1) ──→ (N) PackageSubscription
Appointment (1) ──→ (1) Payment
Appointment (1) ──→ (1) Commission
Professional (N) ←──→ (N) Service       [via ProfessionalService]
Anamnesis (N) ──→ (1) ServiceCategory
Campaign (1) ──→ (N) CampaignLog ←── (N) Client
Studio (1) ──→ (N) StudioPhoto
Studio (1) ──→ (1) Subscription ──→ (N) Invoice
Studio (1) ──→ (1) OnboardingState
User (1) ──→ (N) DeviceToken
Client (1) ──→ (N) ConsentRecord
```

## Índices Críticos

Índices obrigatórios para performance e integridade. Devem existir nas migrations.

| Tabela | Índice | Tipo | Propósito |
|--------|--------|------|-----------|
| Appointment | `EXCLUDE USING gist (professional_id WITH =, tsrange(start_time, end_time) WITH &&) WHERE (status != 'cancelled')` | EXCLUSION | Previne sobreposição de horários (requer btree_gist) |
| Appointment | `(professional_id, date, start_time)` | INDEX | Lookup rápido por profissional e dia (B-tree, sem constraint) |
| Client | `(studio_id, phone)` | UNIQUE | Deduplicação por telefone dentro do tenant |
| CampaignLog | `(campaign_id, client_id, sent_at)` | UNIQUE | Previne envio duplicado na mesma campanha |
| AuditLog | `(studio_id, created_at)` | INDEX | Consulta de audit por tenant e período |
| Invoice | `(studio_id, due_at)` | INDEX | Listagem de faturas por vencimento |
| ConsentRecord | `(client_id, studio_id, type, created_at DESC)` | INDEX | Lookup do consent mais recente por tipo |
| Appointment | `(studio_id, date)` | INDEX | Agenda do dia por tenant |
| BlockedSlot | `(professional_id, date)` | INDEX | Verificação de disponibilidade |
| Studio | `(slug)` | UNIQUE | URL pública única por estúdio (oriz.app/slug) |
| DeviceToken | `(user_id, token)` | UNIQUE | Previne duplicata de token por dispositivo |
| Professional | `(studio_id, user_id)` | UNIQUE | Um user só pode ser profissional uma vez por studio |
| Anamnesis | `(studio_id, client_id, service_category_id)` | UNIQUE | Uma anamnese por (client, categoria) por studio |

## Notas de Implementação

Decisões para a fase de migrations e infraestrutura. Não alteram o modelo, mas devem ser respeitadas na implementação.

### AuditLog — Particionamento e TTL
AuditLog cresce ~250k linhas/dia em escala (1000 estúdios × 50 agendamentos × ~5 ops). Usar `PARTITION BY RANGE (created_at)` com partições mensais. TTL de 365 dias via pg_cron ou job BullMQ que dropa partições antigas.

### NotificationLog — Particionamento e TTL
NotificationLog cresce ~150k linhas/dia em escala. Mesma estratégia: partição mensal por `sent_at`, TTL de 90 dias. Dados mais antigos não têm valor operacional.

### FinancialSummary — Estratégia de Refresh
FinancialSummary é view materializada. Usar `REFRESH MATERIALIZED VIEW CONCURRENTLY` (requer unique index na view) disparado por job BullMQ periódico (a cada 15 min ou sob demanda após pagamento registrado). Nunca refresh síncrono em request HTTP.

### AuditLog — Política de RLS
AuditLog usa service_role key para INSERT (backend grava sem restrição). SELECT restrito via RLS: `studio_id = auth.studio_id() AND auth.role() = 'owner'`. Write-only para a aplicação, read-only para o owner. Profissionais não acessam audit log.

### DeviceToken — RLS por user_id
DeviceToken não pertence a um studio — pertence a um user. RLS usa `user_id = auth.uid()` em vez de `studio_id`. Um user que atua em múltiplos studios (ex: profissional freelancer) mantém os mesmos device tokens.

### Appointment — Exclusion Constraint (btree_gist)
A exclusion constraint em Appointment requer a extensão `btree_gist`. Habilitar via migration: `CREATE EXTENSION IF NOT EXISTS btree_gist`. A constraint garante que nenhum par de agendamentos ativos sobreponha horários para o mesmo profissional (ex: 10:00-11:00 vs 10:30-11:30). Um INDEX B-tree regular `(professional_id, date, start_time)` complementa para lookups rápidos sem atuar como constraint.

### ServiceCategory — RLS com studio_id nullable
Categorias globais (seed) têm `studio_id = NULL`. SELECT é público (necessário para página de booking). INSERT/UPDATE/DELETE restritos a `studio_id IS NOT NULL AND studio_id = auth.studio_id()` — ninguém modifica categorias globais via API. Seeds são inseridas via migration.

### Tabelas com SELECT público (página de booking)
As seguintes tabelas permitem SELECT sem autenticação para suportar a página pública de agendamento (`oriz.app/:slug`): `studios`, `studio_photos`, `professionals`, `service_categories`, `services`, `professional_services`. Dados sensíveis (clients, appointments, payments, etc.) permanecem restritos via studio_id + auth. O backend deve expor apenas os campos necessários via API pública — nunca retornar `settings`, `commission_value`, ou `working_hours` para visitantes anônimos.
