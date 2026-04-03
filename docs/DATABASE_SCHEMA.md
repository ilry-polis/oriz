# Database Schema — Oriz

> Gerado a partir de `docs/DOMAIN_MODEL.md`. Source of truth = DOMAIN_MODEL.md.
> Migration correspondente: `supabase/migrations/001_initial_schema.sql`

## Convenções

- **PK**: `id UUID DEFAULT gen_random_uuid() PRIMARY KEY`
- **Timestamps**: `created_at TIMESTAMPTZ DEFAULT now()`, `updated_at TIMESTAMPTZ DEFAULT now()` (trigger)
- **Multi-tenant**: toda tabela de dados de tenant tem `studio_id UUID NOT NULL REFERENCES studios(id)`
- **Monetário**: sempre `INTEGER` (centavos), nunca float
- **JSON**: validado com Zod no boundary — nunca schema-free
- **Soft delete**: não utilizado — status fields quando necessário
- **RLS**: ativo em todas as tabelas sem exceção

---

## Extensões

| Extensão | Propósito |
|----------|-----------|
| `btree_gist` | Exclusion constraint em Appointment (tsrange overlap) |
| `pgcrypto` | `gen_random_uuid()` (Supabase já habilita) |

---

## Tabelas

### profiles

Perfil estendido do usuário (1:1 com `auth.users`).

| Coluna | Tipo | Constraints |
|--------|------|-------------|
| id | UUID | PK, FK → auth.users(id) ON DELETE CASCADE |
| full_name | TEXT | NOT NULL |
| phone | TEXT | |
| avatar_url | TEXT | |
| role | TEXT | NOT NULL, CHECK IN ('owner', 'professional', 'client') |
| created_at | TIMESTAMPTZ | DEFAULT now() |
| updated_at | TIMESTAMPTZ | DEFAULT now() |

**RLS**: `id = auth.uid()`

---

### studios

Tenant raiz — estúdio/negócio de beleza.

| Coluna | Tipo | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| owner_id | UUID | NOT NULL, FK → auth.users(id) |
| name | TEXT | NOT NULL |
| slug | TEXT | NOT NULL, UNIQUE |
| phone | TEXT | |
| address | TEXT | |
| logo_url | TEXT | |
| description | TEXT | |
| timezone | TEXT | NOT NULL, DEFAULT 'America/Sao_Paulo' |
| settings | JSONB | DEFAULT '{}' |
| created_at | TIMESTAMPTZ | DEFAULT now() |
| updated_at | TIMESTAMPTZ | DEFAULT now() |

**Índices**: UNIQUE(slug)
**RLS**: SELECT: público (booking page via slug); INSERT: owner; UPDATE/DELETE: owner

---

### studio_photos

Fotos do estúdio para página pública.

| Coluna | Tipo | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| studio_id | UUID | NOT NULL, FK → studios(id) ON DELETE CASCADE |
| url | TEXT | NOT NULL |
| position | INTEGER | NOT NULL, DEFAULT 0 |
| created_at | TIMESTAMPTZ | DEFAULT now() |

**RLS**: SELECT: público (booking page); INSERT/UPDATE/DELETE: owner only

---

### professionals

Profissional vinculado a um estúdio.

| Coluna | Tipo | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| studio_id | UUID | NOT NULL, FK → studios(id) ON DELETE CASCADE |
| user_id | UUID | NOT NULL, FK → auth.users(id) |
| name | TEXT | NOT NULL |
| avatar_url | TEXT | |
| specialties | TEXT[] | DEFAULT '{}' |
| working_hours | JSONB | DEFAULT '{}' |
| commission_type | TEXT | NOT NULL, CHECK IN ('percentage', 'fixed') |
| commission_value | NUMERIC(10,2) | NOT NULL, DEFAULT 0 — dual-purpose: percentage quando type=percentage, centavos quando type=fixed |
| card_fee_policy | TEXT | NOT NULL, CHECK IN ('studio', 'professional', 'split'), DEFAULT 'studio' |
| is_active | BOOLEAN | NOT NULL, DEFAULT true |
| created_at | TIMESTAMPTZ | DEFAULT now() |
| updated_at | TIMESTAMPTZ | DEFAULT now() |

**Índices**: UNIQUE(studio_id, user_id)
**RLS**: SELECT: público (booking page); mutação: via studio_id

---

### service_categories

Categoria de serviço. `studio_id = NULL` → categoria global (seed).

| Coluna | Tipo | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| studio_id | UUID | FK → studios(id) ON DELETE CASCADE (nullable) |
| name | TEXT | NOT NULL |
| icon | TEXT | |
| position | INTEGER | NOT NULL, DEFAULT 0 |
| is_active | BOOLEAN | NOT NULL, DEFAULT true |
| created_at | TIMESTAMPTZ | DEFAULT now() |

**RLS**: SELECT: público (booking page + global seeds); INSERT/UPDATE/DELETE (separados) → `studio_id IS NOT NULL AND studio_id = auth.studio_id()`

---

### services

Serviço oferecido pelo estúdio.

| Coluna | Tipo | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| studio_id | UUID | NOT NULL, FK → studios(id) ON DELETE CASCADE |
| category_id | UUID | NOT NULL, FK → service_categories(id) |
| name | TEXT | NOT NULL |
| duration_minutes | INTEGER | NOT NULL |
| price | INTEGER | NOT NULL (centavos) |
| buffer_minutes | INTEGER | NOT NULL, DEFAULT 0 |
| is_active | BOOLEAN | NOT NULL, DEFAULT true |
| created_at | TIMESTAMPTZ | DEFAULT now() |
| updated_at | TIMESTAMPTZ | DEFAULT now() |

**RLS**: SELECT: público (booking page); mutação: via studio_id

---

### professional_services

Junção N:N — quais serviços cada profissional faz.

| Coluna | Tipo | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| studio_id | UUID | NOT NULL, FK → studios(id) ON DELETE CASCADE |
| professional_id | UUID | NOT NULL, FK → professionals(id) ON DELETE CASCADE |
| service_id | UUID | NOT NULL, FK → services(id) ON DELETE CASCADE |

**Índices**: UNIQUE(professional_id, service_id)
**RLS**: SELECT: público (booking page); mutação: via studio_id

---

### clients

Cliente do estúdio.

| Coluna | Tipo | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| studio_id | UUID | NOT NULL, FK → studios(id) ON DELETE CASCADE |
| name | TEXT | NOT NULL |
| phone | TEXT | |
| email | TEXT | |
| birth_date | DATE | |
| tags | JSONB | DEFAULT '[]' |
| notes | TEXT | |
| last_appointment_at | TIMESTAMPTZ | |
| created_at | TIMESTAMPTZ | DEFAULT now() |
| updated_at | TIMESTAMPTZ | DEFAULT now() |

**Índices**: UNIQUE(studio_id, phone) WHERE phone IS NOT NULL; INDEX(studio_id, last_appointment_at) WHERE last_appointment_at IS NOT NULL (reativação)
**RLS**: via studio_id

---

### anamneses

Ficha de anamnese por (client, categoria) por studio.

| Coluna | Tipo | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| studio_id | UUID | NOT NULL, FK → studios(id) ON DELETE CASCADE |
| client_id | UUID | NOT NULL, FK → clients(id) ON DELETE CASCADE |
| service_category_id | UUID | NOT NULL, FK → service_categories(id) |
| fields | JSONB | NOT NULL, DEFAULT '{}' |
| created_at | TIMESTAMPTZ | DEFAULT now() |
| updated_at | TIMESTAMPTZ | DEFAULT now() |

**Índices**: UNIQUE(studio_id, client_id, service_category_id)
**RLS**: via studio_id

---

### appointments

Agendamento.

| Coluna | Tipo | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| studio_id | UUID | NOT NULL, FK → studios(id) ON DELETE CASCADE |
| client_id | UUID | NOT NULL, FK → clients(id) |
| professional_id | UUID | NOT NULL, FK → professionals(id) |
| service_id | UUID | NOT NULL, FK → services(id) |
| date | DATE | NOT NULL |
| start_time | TIMESTAMPTZ | NOT NULL |
| end_time | TIMESTAMPTZ | NOT NULL |
| status | TEXT | NOT NULL, CHECK IN ('confirmed', 'completed', 'cancelled', 'no_show'), DEFAULT 'confirmed' |
| source | TEXT | NOT NULL, CHECK IN ('app', 'whatsapp_ai', 'web_page', 'manual'), DEFAULT 'manual' |
| notes | TEXT | |
| cancellation_reason | TEXT | |
| created_at | TIMESTAMPTZ | DEFAULT now() |
| updated_at | TIMESTAMPTZ | DEFAULT now() |

**Índices**:
- EXCLUDE USING gist (professional_id WITH =, tsrange(start_time, end_time) WITH &&) WHERE (status != 'cancelled')
- INDEX(professional_id, date, start_time)
- INDEX(studio_id, date)

**RLS**: via studio_id

---

### blocked_slots

Horário bloqueado (folga, almoço, férias).

| Coluna | Tipo | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| studio_id | UUID | NOT NULL, FK → studios(id) ON DELETE CASCADE |
| professional_id | UUID | NOT NULL, FK → professionals(id) ON DELETE CASCADE |
| date | DATE | NOT NULL |
| start_time | TIMESTAMPTZ | NOT NULL |
| end_time | TIMESTAMPTZ | NOT NULL |
| reason | TEXT | |
| created_at | TIMESTAMPTZ | DEFAULT now() |

**Índices**: INDEX(professional_id, date)
**RLS**: via studio_id

---

### packages

Pacote de sessões.

| Coluna | Tipo | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| studio_id | UUID | NOT NULL, FK → studios(id) ON DELETE CASCADE |
| service_id | UUID | NOT NULL, FK → services(id) |
| name | TEXT | NOT NULL |
| total_sessions | INTEGER | NOT NULL |
| price | INTEGER | NOT NULL (centavos) |
| validity_days | INTEGER | NOT NULL |
| created_at | TIMESTAMPTZ | DEFAULT now() |
| updated_at | TIMESTAMPTZ | DEFAULT now() |

**RLS**: via studio_id

---

### package_subscriptions

Pacote comprado por cliente.

| Coluna | Tipo | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| studio_id | UUID | NOT NULL, FK → studios(id) ON DELETE CASCADE |
| package_id | UUID | NOT NULL, FK → packages(id) |
| client_id | UUID | NOT NULL, FK → clients(id) |
| sessions_used | INTEGER | NOT NULL, DEFAULT 0 |
| sessions_total | INTEGER | NOT NULL |
| expires_at | TIMESTAMPTZ | NOT NULL |
| status | TEXT | NOT NULL, CHECK IN ('active', 'completed', 'expired'), DEFAULT 'active' |
| created_at | TIMESTAMPTZ | DEFAULT now() |
| updated_at | TIMESTAMPTZ | DEFAULT now() |

**RLS**: via studio_id

---

### commissions

Registro de comissão calculada.

| Coluna | Tipo | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| studio_id | UUID | NOT NULL, FK → studios(id) ON DELETE CASCADE |
| professional_id | UUID | NOT NULL, FK → professionals(id) |
| appointment_id | UUID | NOT NULL, FK → appointments(id) |
| amount | INTEGER | NOT NULL (centavos) |
| studio_amount | INTEGER | NOT NULL (centavos) |
| professional_amount | INTEGER | NOT NULL (centavos) |
| card_fee_amount | INTEGER | NOT NULL, DEFAULT 0 (centavos) |
| who_paid_fee | TEXT | CHECK IN ('studio', 'professional', 'split') |
| period_start | DATE | NOT NULL |
| period_end | DATE | NOT NULL |
| status | TEXT | NOT NULL, CHECK IN ('pending', 'paid'), DEFAULT 'pending' |
| created_at | TIMESTAMPTZ | DEFAULT now() |

**RLS**: via studio_id

---

### payments

Pagamento recebido.

| Coluna | Tipo | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| studio_id | UUID | NOT NULL, FK → studios(id) ON DELETE CASCADE |
| appointment_id | UUID | NOT NULL, FK → appointments(id) |
| client_id | UUID | NOT NULL, FK → clients(id) |
| amount | INTEGER | NOT NULL (centavos) |
| method | TEXT | NOT NULL, CHECK IN ('cash', 'pix', 'debit', 'credit') |
| card_fee_percentage | NUMERIC(5,2) | |
| created_at | TIMESTAMPTZ | DEFAULT now() |

**RLS**: via studio_id

---

### conversations

Conversa no WhatsApp.

| Coluna | Tipo | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| studio_id | UUID | NOT NULL, FK → studios(id) ON DELETE CASCADE |
| client_id | UUID | FK → clients(id) |
| whatsapp_number | TEXT | NOT NULL |
| status | TEXT | NOT NULL, CHECK IN ('active', 'closed', 'escalated'), DEFAULT 'active' |
| started_at | TIMESTAMPTZ | DEFAULT now() |
| last_message_at | TIMESTAMPTZ | DEFAULT now() |

**Índices**: INDEX(studio_id, status)
**RLS**: via studio_id

---

### messages

Mensagem individual de uma conversa.

| Coluna | Tipo | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| studio_id | UUID | NOT NULL, FK → studios(id) ON DELETE CASCADE |
| conversation_id | UUID | NOT NULL, FK → conversations(id) ON DELETE CASCADE |
| role | TEXT | NOT NULL, CHECK IN ('client', 'assistant', 'system') |
| content | TEXT | NOT NULL |
| metadata | JSONB | DEFAULT '{}' |
| created_at | TIMESTAMPTZ | DEFAULT now() |

**Índices**: INDEX(conversation_id, created_at)
**RLS**: via studio_id

---

### ai_configs

Configuração da IA por estúdio (1:1).

| Coluna | Tipo | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| studio_id | UUID | NOT NULL, UNIQUE, FK → studios(id) ON DELETE CASCADE |
| tone_of_voice | TEXT | |
| greeting_message | TEXT | |
| scheduling_rules | JSONB | DEFAULT '{}' |
| fallback_message | TEXT | |
| enabled | BOOLEAN | NOT NULL, DEFAULT false |
| created_at | TIMESTAMPTZ | DEFAULT now() |
| updated_at | TIMESTAMPTZ | DEFAULT now() |

**RLS**: via studio_id

---

### device_tokens

Token FCM por dispositivo. Pertence ao user, não ao studio.

| Coluna | Tipo | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| user_id | UUID | NOT NULL, FK → auth.users(id) ON DELETE CASCADE |
| token | TEXT | NOT NULL |
| platform | TEXT | NOT NULL, CHECK IN ('android', 'ios') |
| is_active | BOOLEAN | NOT NULL, DEFAULT true |
| created_at | TIMESTAMPTZ | DEFAULT now() |
| updated_at | TIMESTAMPTZ | DEFAULT now() |

**Índices**: UNIQUE(user_id, token)
**RLS**: `user_id = auth.uid()` (sem studio_id)

---

### notification_logs

Registro de push enviados. **Particionado por mês** (`sent_at`), TTL 90 dias.

| Coluna | Tipo | Constraints |
|--------|------|-------------|
| id | UUID | DEFAULT gen_random_uuid() |
| studio_id | UUID | NOT NULL |
| user_id | UUID | NOT NULL |
| appointment_id | UUID | |
| type | TEXT | NOT NULL, CHECK IN ('new_booking', 'reminder', 'cancellation') |
| status | TEXT | NOT NULL, CHECK IN ('sent', 'delivered', 'failed') |
| sent_at | TIMESTAMPTZ | NOT NULL, DEFAULT now() |

**Particionamento**: PARTITION BY RANGE (sent_at) — partições mensais, TTL 90 dias
**RLS**: via studio_id

---

### subscriptions

Assinatura SaaS do estúdio (1:1).

| Coluna | Tipo | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| studio_id | UUID | NOT NULL, UNIQUE, FK → studios(id) ON DELETE CASCADE |
| plan | TEXT | NOT NULL, CHECK IN ('basic', 'pro', 'premium') |
| price_cents | INTEGER | NOT NULL |
| billing_cycle | TEXT | NOT NULL, DEFAULT 'monthly' |
| status | TEXT | NOT NULL, CHECK IN ('active', 'past_due', 'cancelled'), DEFAULT 'active' |
| current_period_start | TIMESTAMPTZ | NOT NULL |
| current_period_end | TIMESTAMPTZ | NOT NULL |
| gateway_subscription_id | TEXT | |
| created_at | TIMESTAMPTZ | DEFAULT now() |
| updated_at | TIMESTAMPTZ | DEFAULT now() |

**RLS**: via studio_id (owner only)

---

### invoices

Fatura gerada por ciclo de assinatura.

| Coluna | Tipo | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| studio_id | UUID | NOT NULL, FK → studios(id) ON DELETE CASCADE |
| subscription_id | UUID | NOT NULL, FK → subscriptions(id) |
| amount_cents | INTEGER | NOT NULL |
| status | TEXT | NOT NULL, CHECK IN ('pending', 'paid', 'failed'), DEFAULT 'pending' |
| gateway_invoice_id | TEXT | |
| due_at | TIMESTAMPTZ | NOT NULL |
| paid_at | TIMESTAMPTZ | |
| created_at | TIMESTAMPTZ | DEFAULT now() |

**Índices**: INDEX(studio_id, due_at)
**RLS**: via studio_id (owner only)

---

### consent_records

Consentimento LGPD — **append-only**, nunca UPDATE.

| Coluna | Tipo | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| client_id | UUID | NOT NULL, FK → clients(id) ON DELETE CASCADE |
| studio_id | UUID | NOT NULL, FK → studios(id) ON DELETE CASCADE |
| type | TEXT | NOT NULL, CHECK IN ('marketing_whatsapp', 'marketing_push') |
| action | TEXT | NOT NULL, CHECK IN ('granted', 'revoked') |
| created_at | TIMESTAMPTZ | DEFAULT now() |

**Índices**: INDEX(client_id, studio_id, type, created_at DESC)
**RLS**: SELECT + INSERT only (append-only, LGPD) — sem UPDATE/DELETE

---

### audit_logs

Log de acesso a dados sensíveis. **Particionado por mês** (`created_at`), TTL 365 dias.

| Coluna | Tipo | Constraints |
|--------|------|-------------|
| id | UUID | DEFAULT gen_random_uuid() |
| studio_id | UUID | NOT NULL |
| user_id | UUID | NOT NULL |
| action | TEXT | NOT NULL, CHECK IN ('view', 'export', 'delete') |
| entity_type | TEXT | NOT NULL |
| entity_id | UUID | NOT NULL |
| created_at | TIMESTAMPTZ | NOT NULL, DEFAULT now() |

**Particionamento**: PARTITION BY RANGE (created_at) — partições mensais, TTL 365 dias
**Índices**: INDEX(studio_id, created_at)
**RLS**: INSERT via service_role; SELECT → `studio_id AND role = owner`

---

### onboarding_states

Progresso do wizard de setup (1:1 com studio).

| Coluna | Tipo | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| studio_id | UUID | NOT NULL, UNIQUE, FK → studios(id) ON DELETE CASCADE |
| current_step | TEXT | NOT NULL, CHECK IN ('studio_data', 'services', 'business_hours', 'complete'), DEFAULT 'studio_data' |
| completed_at | TIMESTAMPTZ | |
| created_at | TIMESTAMPTZ | DEFAULT now() |
| updated_at | TIMESTAMPTZ | DEFAULT now() |

**RLS**: via studio_id

---

### campaigns

Campanha automática de marketing.

| Coluna | Tipo | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| studio_id | UUID | NOT NULL, FK → studios(id) ON DELETE CASCADE |
| type | TEXT | NOT NULL, CHECK IN ('birthday', 'reactivation', 'custom') |
| message_template | TEXT | NOT NULL |
| discount_percentage | INTEGER | |
| inactivity_days | INTEGER | DEFAULT 60 |
| channel | TEXT | NOT NULL, CHECK IN ('whatsapp', 'push', 'both') |
| is_active | BOOLEAN | NOT NULL, DEFAULT true |
| created_at | TIMESTAMPTZ | DEFAULT now() |
| updated_at | TIMESTAMPTZ | DEFAULT now() |

**RLS**: via studio_id

---

### campaign_logs

Registro de envios de campanha.

| Coluna | Tipo | Constraints |
|--------|------|-------------|
| id | UUID | PK |
| studio_id | UUID | NOT NULL, FK → studios(id) ON DELETE CASCADE |
| campaign_id | UUID | NOT NULL, FK → campaigns(id) ON DELETE CASCADE |
| client_id | UUID | NOT NULL, FK → clients(id) |
| sent_at | TIMESTAMPTZ | NOT NULL, DEFAULT now() |
| status | TEXT | NOT NULL, CHECK IN ('sent', 'delivered', 'failed') |
| result | TEXT | CHECK IN ('returned', 'no_response') |

**Índices**: UNIQUE(campaign_id, client_id, sent_at)
**RLS**: via studio_id

---

## Views Materializadas

### financial_summaries

Dashboard financeiro pré-computado. Refresh via BullMQ (nunca síncrono em request).
Usa `LEFT JOIN LATERAL` em commissions para evitar duplicação de revenue quando um appointment tem múltiplas comissões (ex: split).

| Coluna | Tipo |
|--------|------|
| studio_id | UUID |
| period_year | INTEGER |
| period_month | INTEGER |
| total_revenue | INTEGER (centavos) |
| total_commissions | INTEGER (centavos) |
| avg_ticket | INTEGER (centavos) |

**Unique index**: (studio_id, period_year, period_month) — necessário para `REFRESH CONCURRENTLY`

---

## Funções Helper

| Função | Retorno | Propósito |
|--------|---------|-----------|
| `updated_at_trigger()` | TRIGGER | Atualiza `updated_at` automaticamente em UPDATE |

---

## Resumo de RLS

| Tabela | Política |
|--------|----------|
| profiles | `id = auth.uid()` |
| studios | SELECT: público; INSERT/UPDATE/DELETE: owner |
| studio_photos | SELECT: público; INSERT/UPDATE/DELETE: owner only |
| professionals | SELECT: público; mutação: via studio_id |
| service_categories | SELECT: público; INSERT/UPDATE/DELETE (separados): `studio_id IS NOT NULL AND = X` |
| services | SELECT: público; mutação: via studio_id |
| professional_services | SELECT: público; mutação: via studio_id |
| clients | via studio_id |
| anamneses | via studio_id |
| appointments | via studio_id |
| blocked_slots | via studio_id |
| packages | via studio_id |
| package_subscriptions | via studio_id |
| commissions | via studio_id |
| payments | via studio_id |
| conversations | via studio_id |
| messages | via studio_id |
| ai_configs | via studio_id |
| device_tokens | `user_id = auth.uid()` |
| notification_logs | via studio_id |
| subscriptions | via studio_id (owner) |
| invoices | via studio_id (owner) |
| consent_records | SELECT + INSERT only (append-only, LGPD) |
| audit_logs | INSERT: service_role; SELECT: studio_id + owner |
| onboarding_states | via studio_id |
| campaigns | via studio_id |
| campaign_logs | via studio_id |

---

## Contagem de Tabelas

- **Tabelas regulares**: 23
- **Tabelas particionadas**: 2 (audit_logs, notification_logs)
- **Views materializadas**: 1 (financial_summaries)
- **Total**: 26
