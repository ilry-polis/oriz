# Contratos de API — Oriz

> Source of truth para todos os endpoints. Gerado a partir de `docs/DOMAIN_MODEL.md` e `docs/DATABASE_SCHEMA.md`.
> Se controller diverge deste contrato, o contrato vence — corrigir o controller.

## Convenções Gerais

- **Base URL**: `/api/v1`
- **Auth**: Bearer token (Supabase JWT) no header `Authorization`
- **Content-Type**: `application/json`
- **Multi-tenant**: `studio_id` extraído do JWT — nunca passado como param
- **Paginação**: cursor-based em toda listagem (`?cursor=UUID&limit=20`, default limit=20, max=100)
- **Monetário**: sempre em centavos (INTEGER)
- **Datas**: ISO 8601 (`2026-03-15`, `2026-03-15T14:00:00-03:00`)

### Response Shapes

```typescript
// Sucesso (item)
{ data: T }

// Sucesso (lista)
{ data: T[], meta: { cursor: string | null, has_more: boolean, total: number } }

// Erro
{ errors: [{ code: string, message: string, field?: string }] }
```

### HTTP Status Codes

| Code | Uso |
|------|-----|
| 200 | Leitura ou update |
| 201 | Criação (retorna recurso criado) |
| 204 | Delete (sem body) |
| 400 | Input inválido (validação Zod) |
| 401 | Não autenticado |
| 403 | Sem permissão |
| 404 | Recurso não encontrado |
| 409 | Conflito (horário ocupado, duplicata) |
| 422 | Regra de negócio violada |
| 429 | Rate limit excedido |

### Auth Levels

| Nível | Descrição |
|-------|-----------|
| `public` | Sem autenticação |
| `authenticated` | Qualquer usuário autenticado |
| `owner` | Dono do estúdio |
| `owner+professional` | Owner ou professional vinculado ao studio |
| `webhook` | Validação por signature do provider |

---

## 1. Auth

### POST /api/v1/auth/signup
Auth: `public`
Rate limit: 5/min por IP

```
Body: {
  email: string (email),
  password: string (min 8),
  full_name: string
}
Response 201: { data: { user: { id, email }, session: { access_token, refresh_token, expires_at } } }
Errors:
  409 ACCOUNT_EXISTS — Email já cadastrado
  400 WEAK_PASSWORD — Senha não atende critérios
```

### POST /api/v1/auth/login
Auth: `public`
Rate limit: 10/min por IP

```
Body: {
  email: string,
  password: string
}
Response 200: { data: { user: { id, email, profile }, session: { access_token, refresh_token, expires_at } } }
Errors:
  401 INVALID_CREDENTIALS — Email ou senha incorretos
  429 TOO_MANY_ATTEMPTS — Rate limit excedido
```

### POST /api/v1/auth/logout
Auth: `authenticated`

```
Response 204: (sem body)
```

### POST /api/v1/auth/refresh
Auth: `public`
Rate limit: 30/min por IP

```
Body: {
  refresh_token: string
}
Response 200: { data: { session: { access_token, refresh_token, expires_at } } }
Errors:
  401 INVALID_REFRESH_TOKEN — Token expirado ou inválido
```

### POST /api/v1/auth/forgot-password
Auth: `public`
Rate limit: 3/min por IP

```
Body: {
  email: string
}
Response 200: { data: { message: "Se o email existir, enviaremos instruções." } }
```
> Sempre retorna 200 para não revelar se email existe.
> Processamento via job assíncrono (BullMQ) para equalizar tempo de resposta e prevenir timing attacks.

---

## 2. Profile

### GET /api/v1/profile
Auth: `authenticated`

```
Response 200: { data: { id, full_name, phone, avatar_url, role } }
```

### PATCH /api/v1/profile
Auth: `authenticated`

```
Body: {
  full_name?: string,
  phone?: string,
  avatar_url?: string
}
Response 200: { data: Profile }
```

---

## 3. Studios & Configuration

### POST /api/v1/studios
Auth: `authenticated`

```
Body: {
  name: string,
  slug: string (regex: ^[a-z0-9-]{3,50}$),
  phone?: string,
  address?: string,
  description?: string,
  timezone?: string (default: "America/Sao_Paulo")
}
Response 201: { data: Studio }
Errors:
  409 SLUG_TAKEN — Slug já em uso
```
> Cria studio + onboarding_state (step: studio_data) + professional (owner como primeiro profissional).

### GET /api/v1/studios/me
Auth: `owner+professional`

```
Response 200: {
  data: {
    id, name, slug, phone, address, logo_url, description, timezone, settings,
    created_at, updated_at
  }
}
```

### PATCH /api/v1/studios/me
Auth: `owner`

```
Body: {
  name?: string,
  slug?: string,
  phone?: string,
  address?: string,
  logo_url?: string,
  description?: string,
  timezone?: string,
  settings?: {
    reminder_hours_before?: number (int),
    allow_public_booking?: boolean,
    default_currency?: string
  }
}
Response 200: { data: Studio }
Errors:
  409 SLUG_TAKEN — Slug já em uso
```

### Studio Photos

#### GET /api/v1/studios/me/photos
Auth: `owner+professional`

```
Response 200: { data: StudioPhoto[] }
```
> Lista completa, sem paginação — max ~20 fotos por studio.

#### POST /api/v1/studios/me/photos
Auth: `owner`

```
Body: {
  url: string (URL),
  position?: number (int, default: 0)
}
Response 201: { data: StudioPhoto }
```

#### PATCH /api/v1/studios/me/photos/:photoId
Auth: `owner`

```
Body: {
  position?: number
}
Response 200: { data: StudioPhoto }
```

#### DELETE /api/v1/studios/me/photos/:photoId
Auth: `owner`

```
Response 204
Errors:
  404 PHOTO_NOT_FOUND
```

### Onboarding

#### GET /api/v1/studios/me/onboarding
Auth: `owner`

```
Response 200: { data: { current_step, completed_at } }
```

#### PATCH /api/v1/studios/me/onboarding
Auth: `owner`

```
Body: {
  current_step: "studio_data" | "services" | "business_hours" | "complete"
}
Response 200: { data: OnboardingState }
```
> Quando `current_step` = `complete`, `completed_at` é preenchido automaticamente.

---

## 4. Service Categories

### GET /api/v1/service-categories
Auth: `owner+professional`

```
Query: { is_active?: boolean }
Response 200: { data: ServiceCategory[] }
```
> Lista completa, sem paginação — max ~15 categorias por studio.
> Retorna categorias globais (studio_id = NULL) + categorias do studio.

### POST /api/v1/service-categories
Auth: `owner`

```
Body: {
  name: string,
  icon?: string,
  position?: number (int, default: 0)
}
Response 201: { data: ServiceCategory }
```

### PATCH /api/v1/service-categories/:id
Auth: `owner`

```
Body: {
  name?: string,
  icon?: string,
  position?: number,
  is_active?: boolean
}
Response 200: { data: ServiceCategory }
Errors:
  403 GLOBAL_CATEGORY — Categorias globais não podem ser editadas
  404 CATEGORY_NOT_FOUND
```

### DELETE /api/v1/service-categories/:id
Auth: `owner`

```
Response 204
Errors:
  403 GLOBAL_CATEGORY — Categorias globais não podem ser excluídas
  409 CATEGORY_HAS_SERVICES — Desative os serviços vinculados antes
```

---

## 5. Services

### GET /api/v1/services
Auth: `owner+professional`

```
Query: {
  category_id?: UUID,
  is_active?: boolean,
  cursor?: UUID,
  limit?: number (default: 20, max: 100)
}
Response 200: { data: Service[], meta }
```

### POST /api/v1/services
Auth: `owner`

```
Body: {
  category_id: UUID,
  name: string,
  duration_minutes: number (int, min: 5),
  price: number (int, centavos, min: 0),
  buffer_minutes?: number (int, default: 0),
  is_active?: boolean (default: true)
}
Response 201: { data: Service }
Errors:
  404 CATEGORY_NOT_FOUND
```

### GET /api/v1/services/:id
Auth: `owner+professional`

```
Response 200: { data: Service }
Errors:
  404 SERVICE_NOT_FOUND
```

### PATCH /api/v1/services/:id
Auth: `owner`

```
Body: {
  category_id?: UUID,
  name?: string,
  duration_minutes?: number,
  price?: number,
  buffer_minutes?: number,
  is_active?: boolean
}
Response 200: { data: Service }
Errors:
  404 SERVICE_NOT_FOUND
```

### DELETE /api/v1/services/:id
Auth: `owner`

```
Response 204
Errors:
  409 SERVICE_HAS_APPOINTMENTS — Serviço com agendamentos futuros; desative em vez de excluir
```

---

## 6. Professionals

### GET /api/v1/professionals
Auth: `owner+professional`

```
Query: {
  is_active?: boolean,
  cursor?: UUID,
  limit?: number
}
Response 200: {
  data: [{
    id, name, avatar_url, specialties, working_hours,
    commission_type, commission_value, card_fee_policy,
    is_active, services: [{ id, name }]
  }],
  meta
}
```
> Campos `commission_type`, `commission_value`, `card_fee_policy` retornados apenas para `owner`. Profissionais recebem esses campos como `null`.

### POST /api/v1/professionals
Auth: `owner`

```
Body: {
  user_id: UUID,
  name: string,
  avatar_url?: string,
  specialties?: string[],
  working_hours?: Record<string, { open: string, close: string }>,
  commission_type: "percentage" | "fixed",
  commission_value: number,
  card_fee_policy?: "studio" | "professional" | "split" (default: "studio"),
  service_ids?: UUID[]
}
Response 201: { data: Professional }
Errors:
  409 PROFESSIONAL_EXISTS — Usuário já é profissional neste studio
  404 USER_NOT_FOUND — user_id inválido
```

### GET /api/v1/professionals/me
Auth: `owner+professional`

```
Response 200: {
  data: {
    id, name, avatar_url, specialties, working_hours,
    commission_type, commission_value, card_fee_policy,
    is_active, services: [{ id, name }],
    studio: { id, name, slug }
  }
}
Errors:
  404 NOT_A_PROFESSIONAL — Usuário autenticado não é profissional neste studio
```
> Retorna dados do profissional autenticado no studio corrente (derivado do JWT).

### GET /api/v1/professionals/:id
Auth: `owner+professional`

```
Response 200: { data: Professional (com services) }
Errors:
  404 PROFESSIONAL_NOT_FOUND
```

### PATCH /api/v1/professionals/:id
Auth: `owner`

```
Body: {
  name?: string,
  avatar_url?: string,
  specialties?: string[],
  working_hours?: Record<string, { open: string, close: string }>,
  commission_type?: "percentage" | "fixed",
  commission_value?: number,
  card_fee_policy?: "studio" | "professional" | "split",
  is_active?: boolean,
  service_ids?: UUID[]
}
Response 200: { data: Professional }
Errors:
  404 PROFESSIONAL_NOT_FOUND
```
> `service_ids` substitui completamente os vínculos em `professional_services`.

### DELETE /api/v1/professionals/:id
Auth: `owner`

```
Response 204
Errors:
  409 PROFESSIONAL_HAS_APPOINTMENTS — Profissional com agendamentos futuros; desative em vez de excluir
```

---

## 7. Clients

### GET /api/v1/clients
Auth: `owner+professional`

```
Query: {
  search?: string (busca por nome ou telefone),
  tag?: string,
  inactive_days?: number (clients sem agendamento há N dias),
  cursor?: UUID,
  limit?: number
}
Response 200: {
  data: [{
    id, name, phone, email, birth_date, tags, notes,
    last_appointment_at, created_at
  }],
  meta
}
```

### POST /api/v1/clients
Auth: `owner+professional`

```
Body: {
  name: string,
  phone?: string,
  email?: string (email),
  birth_date?: string (date ISO),
  tags?: string[],
  notes?: string
}
Response 201: { data: Client }
Errors:
  409 PHONE_ALREADY_EXISTS — Telefone já cadastrado neste studio
```

### GET /api/v1/clients/:id
Auth: `owner+professional`

```
Response 200: {
  data: {
    id, name, phone, email, birth_date, tags, notes,
    last_appointment_at, created_at, updated_at,
    stats: { total_appointments, total_spent, last_service }
  }
}
Errors:
  404 CLIENT_NOT_FOUND
```

### PATCH /api/v1/clients/:id
Auth: `owner+professional`

```
Body: {
  name?: string,
  phone?: string,
  email?: string,
  birth_date?: string,
  tags?: string[],
  notes?: string
}
Response 200: { data: Client }
Errors:
  404 CLIENT_NOT_FOUND
  409 PHONE_ALREADY_EXISTS
```

### DELETE /api/v1/clients/:id
Auth: `owner`

```
Response 204
Errors:
  409 CLIENT_HAS_APPOINTMENTS — Cliente com agendamentos futuros
```

### Client History

#### GET /api/v1/clients/:id/appointments
Auth: `owner+professional`

```
Query: {
  status?: "confirmed" | "completed" | "cancelled" | "no_show",
  cursor?: UUID,
  limit?: number
}
Response 200: {
  data: [{
    id, date, start_time, end_time, status, source,
    service: { id, name },
    professional: { id, name }
  }],
  meta
}
```

### Anamnesis

#### GET /api/v1/clients/:clientId/anamneses
Auth: `owner+professional`

```
Response 200: {
  data: [{
    id, service_category: { id, name },
    fields, updated_at
  }]
}
```
> Lista completa, sem paginação — uma anamnese por categoria de serviço (max ~15).

### Client Package Subscriptions

#### GET /api/v1/clients/:clientId/package-subscriptions
Auth: `owner+professional`

```
Query: {
  status?: "active" | "completed" | "expired",
  cursor?: UUID,
  limit?: number
}
Response 200: {
  data: [{
    id, sessions_used, sessions_total, expires_at, status,
    package: { id, name, service: { id, name } }
  }],
  meta
}
Errors:
  404 CLIENT_NOT_FOUND
```

#### PUT /api/v1/clients/:clientId/anamneses/:categoryId
Auth: `owner+professional`

```
Body: {
  fields: Record<string, any> (validado com Zod por categoria)
}
Response 200: { data: Anamnesis }
```
> Upsert: cria se não existe, atualiza se já existe. Chave: (studio_id, client_id, service_category_id).

---

## 8. Appointments & Calendar

### GET /api/v1/appointments
Auth: `owner+professional`

```
Query: {
  date?: string (ISO date — filtra agenda do dia),
  date_from?: string (ISO date),
  date_to?: string (ISO date),
  professional_id?: UUID,
  status?: "confirmed" | "completed" | "cancelled" | "no_show",
  cursor?: UUID,
  limit?: number
}
Response 200: {
  data: [{
    id, date, start_time, end_time, status, source, notes,
    cancellation_reason,
    client: { id, name, phone },
    professional: { id, name },
    service: { id, name, duration_minutes, price }
  }],
  meta
}
```

### POST /api/v1/appointments
Auth: `owner+professional`

```
Body: {
  client_id: UUID,
  professional_id: UUID,
  service_id: UUID,
  date: string (ISO date),
  start_time: string (ISO datetime),
  notes?: string,
  source?: "app" | "manual" (default: "app")
}
Response 201: { data: Appointment }
Errors:
  404 CLIENT_NOT_FOUND
  404 PROFESSIONAL_NOT_FOUND
  404 SERVICE_NOT_FOUND
  409 TIME_SLOT_TAKEN — Horário sobrepõe agendamento existente
  422 OUTSIDE_WORKING_HOURS — Fora do horário de atendimento do profissional
  422 PROFESSIONAL_BLOCKED — Profissional bloqueou este horário
  422 PROFESSIONAL_INACTIVE — Profissional desativado
  422 SERVICE_INACTIVE — Serviço desativado
```
> `end_time` calculado automaticamente: `start_time + service.duration_minutes + service.buffer_minutes`.

### GET /api/v1/appointments/:id
Auth: `owner+professional`

```
Response 200: { data: Appointment (completo, com relações) }
Errors:
  404 APPOINTMENT_NOT_FOUND
```

### PATCH /api/v1/appointments/:id
Auth: `owner+professional`

```
Body: {
  professional_id?: UUID,
  service_id?: UUID,
  date?: string,
  start_time?: string,
  notes?: string
}
Response 200: { data: Appointment }
Errors:
  409 TIME_SLOT_TAKEN
  422 OUTSIDE_WORKING_HOURS
  422 APPOINTMENT_NOT_MODIFIABLE — Apenas confirmed pode ser modificado
```

### Appointment Status Transitions

#### POST /api/v1/appointments/:id/confirm
Auth: `owner+professional`

```
Response 200: { data: Appointment }
Errors:
  422 INVALID_STATUS_TRANSITION — Status atual não permite confirmação
```

#### POST /api/v1/appointments/:id/complete
Auth: `owner+professional`

```
Body: {
  payment?: {
    amount: number (centavos),
    method: "cash" | "pix" | "debit" | "credit",
    card_fee_percentage?: number (ex: 2.50)
  }
}
Response 200: {
  data: {
    appointment: Appointment,
    payment: Payment | null,
    commission: Commission | null
  }
}
Errors:
  422 INVALID_STATUS_TRANSITION — Só confirmed → completed
```
> Se `payment` informado, cria Payment + calcula Commission automaticamente (retornados no response).
> Se appointment usa pacote, deduz sessão do PackageSubscription.

#### POST /api/v1/appointments/:id/cancel
Auth: `owner+professional`

```
Body: {
  cancellation_reason?: string
}
Response 200: { data: Appointment }
Errors:
  422 INVALID_STATUS_TRANSITION — Só confirmed → cancelled
```

#### POST /api/v1/appointments/:id/no-show
Auth: `owner+professional`

```
Response 200: { data: Appointment }
Errors:
  422 INVALID_STATUS_TRANSITION — Só confirmed → no_show
```

### Available Slots

#### GET /api/v1/appointments/available-slots
Auth: `owner+professional`

```
Query: {
  date: string (ISO date, obrigatório),
  professional_id: UUID (obrigatório),
  service_id: UUID (obrigatório)
}
Response 200: {
  data: {
    date: string,
    slots: [{ start_time: string, end_time: string }]
  }
}
Errors:
  400 MISSING_PARAMS — date, professional_id, service_id obrigatórios
  404 PROFESSIONAL_NOT_FOUND
  404 SERVICE_NOT_FOUND
```
> Calcula slots livres cruzando: working_hours, appointments existentes, blocked_slots, duração + buffer do serviço.

### Blocked Slots

#### GET /api/v1/blocked-slots
Auth: `owner+professional`

```
Query: {
  professional_id?: UUID,
  date_from?: string,
  date_to?: string,
  cursor?: UUID,
  limit?: number
}
Response 200: { data: BlockedSlot[], meta }
```

#### POST /api/v1/blocked-slots
Auth: `owner+professional`

```
Body: {
  professional_id: UUID,
  date: string (ISO date),
  start_time: string (ISO datetime),
  end_time: string (ISO datetime),
  reason?: string
}
Response 201: { data: BlockedSlot }
Errors:
  403 NOT_OWN_SCHEDULE — Profissional só pode bloquear seu próprio horário (owner pode bloquear qualquer profissional)
  409 CONFLICTS_WITH_APPOINTMENT — Já existe agendamento neste horário
```

#### DELETE /api/v1/blocked-slots/:id
Auth: `owner+professional`

```
Response 204
Errors:
  404 BLOCKED_SLOT_NOT_FOUND
```

---

## 9. Packages

### GET /api/v1/packages
Auth: `owner+professional`

```
Query: { cursor?: UUID, limit?: number }
Response 200: {
  data: [{
    id, name, total_sessions, price, validity_days,
    service: { id, name },
    created_at
  }],
  meta
}
```

### POST /api/v1/packages
Auth: `owner`

```
Body: {
  service_id: UUID,
  name: string,
  total_sessions: number (int, min: 1),
  price: number (int, centavos),
  validity_days: number (int, min: 1)
}
Response 201: { data: Package }
Errors:
  404 SERVICE_NOT_FOUND
```

### PATCH /api/v1/packages/:id
Auth: `owner`

```
Body: {
  name?: string,
  total_sessions?: number,
  price?: number,
  validity_days?: number
}
Response 200: { data: Package }
Errors:
  404 PACKAGE_NOT_FOUND
  422 CANNOT_REDUCE_SESSIONS — Pacote com assinaturas ativas não pode reduzir sessões
```

### DELETE /api/v1/packages/:id
Auth: `owner`

```
Response 204
Errors:
  409 PACKAGE_HAS_SUBSCRIPTIONS — Pacote com assinaturas ativas
```

### Package Subscriptions

#### GET /api/v1/packages/:packageId/subscriptions
Auth: `owner+professional`

```
Query: {
  status?: "active" | "completed" | "expired",
  cursor?: UUID,
  limit?: number
}
Response 200: {
  data: [{
    id, sessions_used, sessions_total, expires_at, status,
    client: { id, name },
    package: { id, name }
  }],
  meta
}
```

#### POST /api/v1/packages/:packageId/subscriptions
Auth: `owner+professional`

```
Body: {
  client_id: UUID
}
Response 201: {
  data: {
    id, sessions_used: 0, sessions_total, expires_at, status: "active",
    client: { id, name }
  }
}
Errors:
  404 CLIENT_NOT_FOUND
  404 PACKAGE_NOT_FOUND
```
> `sessions_total` copiado do Package. `expires_at` calculado: `now() + package.validity_days`.

#### GET /api/v1/package-subscriptions/:id
Auth: `owner+professional`

```
Response 200: { data: PackageSubscription (completo) }
Errors:
  404 SUBSCRIPTION_NOT_FOUND
```

---

## 10. Financial

### Payments

#### GET /api/v1/payments
Auth: `owner`

```
Query: {
  date_from?: string (ISO date),
  date_to?: string (ISO date),
  method?: "cash" | "pix" | "debit" | "credit",
  professional_id?: UUID,
  cursor?: UUID,
  limit?: number
}
Response 200: {
  data: [{
    id, amount, method, card_fee_percentage, created_at,
    appointment: { id, date },
    client: { id, name },
    professional: { id, name }
  }],
  meta
}
```

### Commissions

#### GET /api/v1/commissions
Auth: `owner`

```
Query: {
  professional_id?: UUID,
  status?: "pending" | "paid",
  period_start?: string (ISO date),
  period_end?: string (ISO date),
  cursor?: UUID,
  limit?: number
}
Response 200: {
  data: [{
    id, amount, studio_amount, professional_amount,
    card_fee_amount, who_paid_fee,
    period_start, period_end, status,
    professional: { id, name },
    appointment: { id, date, service: { name } }
  }],
  meta
}
```

#### POST /api/v1/commissions/pay
Auth: `owner`

```
Body: {
  commission_ids: UUID[] (max 100)
}
Response 200: { data: { paid_count: number, total_amount: number } }
Errors:
  422 ALREADY_PAID — Uma ou mais comissões já estão pagas
```

### Financial Summary

#### GET /api/v1/financial/summary
Auth: `owner`

```
Query: {
  year?: number (default: ano corrente),
  month?: number (1-12, se omitido retorna todos os meses do ano)
}
Response 200: {
  data: [{
    period_year, period_month,
    total_revenue, total_commissions, avg_ticket
  }]
}
```
> Dados da materialized view `financial_summaries`. Refresh assíncrono via BullMQ.

---

## 11. Notifications

### Device Tokens

#### POST /api/v1/device-tokens
Auth: `authenticated`

```
Body: {
  token: string,
  platform: "android" | "ios"
}
Response 201: { data: DeviceToken }
```
> Upsert por (user_id, token). Se já existe, atualiza `is_active` e `updated_at`.

#### DELETE /api/v1/device-tokens/:id
Auth: `authenticated`

```
Response 204
Errors:
  404 DEVICE_TOKEN_NOT_FOUND
```
> Soft delete: marca `is_active = false`. Usa ID do registro (não o token FCM) para evitar tokens sensíveis em URLs/logs.

---

## 12. AI & Conversations

### AI Config

#### GET /api/v1/ai/config
Auth: `owner`

```
Response 200: {
  data: {
    tone_of_voice, greeting_message, fallback_message, enabled,
    scheduling_rules: {
      max_advance_days, min_advance_hours, auto_confirm
    }
  }
}
```

#### PATCH /api/v1/ai/config
Auth: `owner`

```
Body: {
  tone_of_voice?: string,
  greeting_message?: string,
  fallback_message?: string,
  enabled?: boolean,
  scheduling_rules?: {
    max_advance_days?: number (int),
    min_advance_hours?: number (int),
    auto_confirm?: boolean
  }
}
Response 200: { data: AIConfig }
```

### Conversations

#### GET /api/v1/conversations
Auth: `owner+professional`

```
Query: {
  status?: "active" | "closed" | "escalated",
  cursor?: UUID,
  limit?: number
}
Response 200: {
  data: [{
    id, whatsapp_number, status, started_at, last_message_at,
    client: { id, name } | null,
    last_message: { role, content, created_at }
  }],
  meta
}
```

#### GET /api/v1/conversations/:id/messages
Auth: `owner+professional`

```
Query: {
  cursor?: UUID,
  limit?: number (default: 50)
}
Response 200: {
  data: [{
    id, role, content, metadata, created_at
  }],
  meta
}
```

#### POST /api/v1/conversations/:id/escalate
Auth: `owner+professional`

```
Response 200: { data: Conversation }
Errors:
  422 ALREADY_ESCALATED
```

#### POST /api/v1/conversations/:id/close
Auth: `owner+professional`

```
Response 200: { data: Conversation }
Errors:
  422 ALREADY_CLOSED
```

---

## 13. Campaigns & Marketing

### GET /api/v1/campaigns
Auth: `owner`

```
Query: {
  type?: "birthday" | "reactivation" | "custom",
  is_active?: boolean,
  cursor?: UUID,
  limit?: number
}
Response 200: {
  data: [{
    id, type, message_template, discount_percentage,
    inactivity_days, channel, is_active, created_at
  }],
  meta
}
```

### POST /api/v1/campaigns
Auth: `owner`

```
Body: {
  type: "birthday" | "reactivation" | "custom",
  message_template: string,
  discount_percentage?: number (int, 0-100),
  inactivity_days?: number (int, default: 60, para reactivation),
  channel: "whatsapp" | "push" | "both",
  is_active?: boolean (default: true)
}
Response 201: { data: Campaign }
```

### PATCH /api/v1/campaigns/:id
Auth: `owner`

```
Body: {
  message_template?: string,
  discount_percentage?: number,
  inactivity_days?: number,
  channel?: "whatsapp" | "push" | "both",
  is_active?: boolean
}
Response 200: { data: Campaign }
Errors:
  404 CAMPAIGN_NOT_FOUND
```

### DELETE /api/v1/campaigns/:id
Auth: `owner`

```
Response 204
Errors:
  404 CAMPAIGN_NOT_FOUND
```

### Campaign Metrics

#### GET /api/v1/campaigns/:id/metrics
Auth: `owner`

```
Query: {
  date_from?: string,
  date_to?: string
}
Response 200: {
  data: {
    total_sent: number,
    total_delivered: number,
    total_failed: number,
    total_returned: number,
    return_rate: number (percentual),
    recent_logs: [{
      client: { id, name },
      sent_at, status, result
    }]
  }
}
```

---

## 14. Billing & Subscription (SaaS)

### GET /api/v1/billing/subscription
Auth: `owner`

```
Response 200: {
  data: {
    plan, price_cents, billing_cycle, status,
    current_period_start, current_period_end
  }
}
Errors:
  404 NO_SUBSCRIPTION — Studio sem assinatura ativa
```

### POST /api/v1/billing/subscription
Auth: `owner`

```
Body: {
  plan: "basic" | "pro" | "premium"
}
Response 201: { data: { subscription: Subscription, checkout_url: string | null } }
Errors:
  409 ALREADY_SUBSCRIBED — Studio já tem assinatura ativa
```
> Integra com gateway (Stripe/Asaas). `checkout_url` é a URL de pagamento do gateway — o frontend redireciona o usuário. NULL se pagamento já processado (ex: trial).

### PATCH /api/v1/billing/subscription
Auth: `owner`

```
Body: {
  plan: "basic" | "pro" | "premium"
}
Response 200: { data: Subscription }
Errors:
  404 NO_SUBSCRIPTION
```
> Upgrade/downgrade no próximo ciclo.

### POST /api/v1/billing/subscription/cancel
Auth: `owner`

```
Response 200: { data: Subscription (status: cancelled, válido até current_period_end) }
Errors:
  404 NO_SUBSCRIPTION
  422 ALREADY_CANCELLED
```

### Invoices

#### GET /api/v1/billing/invoices
Auth: `owner`

```
Query: {
  status?: "pending" | "paid" | "failed",
  cursor?: UUID,
  limit?: number
}
Response 200: {
  data: [{
    id, amount_cents, status, due_at, paid_at
  }],
  meta
}
```

---

## 15. Compliance (LGPD)

### Consent Records

#### GET /api/v1/clients/:clientId/consents
Auth: `owner+professional`

```
Response 200: {
  data: [{
    type: "marketing_whatsapp" | "marketing_push",
    current_status: "granted" | "revoked",
    last_updated: string (ISO datetime)
  }]
}
```
> Lista completa, sem paginação — max 2 registros (um por tipo de consent).
> Derivado do último registro por tipo em `consent_records`.

#### POST /api/v1/clients/:clientId/consents
Auth: `owner+professional`

```
Body: {
  type: "marketing_whatsapp" | "marketing_push",
  action: "granted" | "revoked"
}
Response 201: { data: { type, action, created_at } }
```
> Append-only. Nunca edita registros anteriores.

### Audit Log

#### GET /api/v1/audit-logs
Auth: `owner`

```
Query: {
  date_from?: string,
  date_to?: string,
  action?: "view" | "export" | "delete",
  entity_type?: string,
  cursor?: UUID,
  limit?: number
}
Response 200: {
  data: [{
    id, user: { id, name }, action, entity_type, entity_id, created_at
  }],
  meta
}
```

### Data Deletion (LGPD)

#### POST /api/v1/clients/:clientId/data-deletion
Auth: `owner`

```
Response 200: {
  data: {
    client_id: UUID,
    deleted_records: {
      appointments: number,
      anamneses: number,
      consent_records: number,
      campaign_logs: number
    }
  }
}
Errors:
  404 CLIENT_NOT_FOUND
```
> Remove dados pessoais do cliente mantendo registros financeiros anonimizados. Cria AuditLog com action = delete.

---

## 16. Webhooks

### POST /api/v1/webhooks/whatsapp
Auth: `webhook` (validação por signature do provider)
Rate limit: 100/min por IP

```
Body: (definido pelo provider — Evolution API / Z-API)
Response 200: { data: { received: true } }
Errors:
  401 INVALID_SIGNATURE — Signature do webhook inválida
```
> Processa assincronamente via BullMQ. Retorna 200 imediatamente.

### POST /api/v1/webhooks/billing
Auth: `webhook` (validação por signature Stripe/Asaas)
Rate limit: 100/min por IP

```
Body: (definido pelo gateway)
Response 200: { data: { received: true } }
Errors:
  401 INVALID_SIGNATURE
```
> Processa eventos: `invoice.paid`, `invoice.failed`, `subscription.cancelled`, etc.

---

## 17. Public Booking Page

Endpoints sem autenticação para a página pública `oriz.app/:slug`.

### GET /api/v1/public/studios/:slug
Auth: `public`
Rate limit: 60/min por IP

```
Response 200: {
  data: {
    id, name, slug, phone, address, description, timezone, logo_url,
    photos: [{ url, position }],
    allow_public_booking: boolean
  }
}
Errors:
  404 STUDIO_NOT_FOUND
```
> Nunca retorna: settings, owner_id.

### GET /api/v1/public/studios/:slug/professionals
Auth: `public`
Rate limit: 60/min por IP

```
Response 200: {
  data: [{
    id, name, avatar_url, specialties,
    services: [{ id, name, duration_minutes, price }]
  }]
}
```
> Apenas profissionais ativos. Nunca retorna: working_hours, commission_value, commission_type, card_fee_policy.

### GET /api/v1/public/studios/:slug/services
Auth: `public`
Rate limit: 60/min por IP

```
Query: { category_id?: UUID }
Response 200: {
  data: [{
    id, name, duration_minutes, price, buffer_minutes,
    category: { id, name, icon }
  }]
}
```
> Apenas serviços ativos.

### GET /api/v1/public/studios/:slug/service-categories
Auth: `public`
Rate limit: 60/min por IP

```
Response 200: {
  data: [{ id, name, icon, position }]
}
```
> Categorias globais + do studio, apenas ativas.

### GET /api/v1/public/studios/:slug/available-slots
Auth: `public`
Rate limit: 30/min por IP

```
Query: {
  date: string (ISO date, obrigatório),
  professional_id: UUID (obrigatório),
  service_id: UUID (obrigatório)
}
Response 200: {
  data: {
    date: string,
    slots: [{ start_time: string, end_time: string }]
  }
}
Errors:
  400 MISSING_PARAMS
  404 STUDIO_NOT_FOUND
  422 PUBLIC_BOOKING_DISABLED — Estúdio não permite agendamento público
```

### POST /api/v1/public/studios/:slug/appointments
Auth: `public`
Rate limit: 3/min por IP + 1/min por client_phone

```
Body: {
  client_name: string,
  client_phone: string,
  professional_id: UUID,
  service_id: UUID,
  date: string (ISO date),
  start_time: string (ISO datetime),
  notes?: string
}
Response 201: {
  data: {
    id, date, start_time, end_time, status,
    professional: { name },
    service: { name, duration_minutes }
  }
}
Errors:
  409 TIME_SLOT_TAKEN
  422 PUBLIC_BOOKING_DISABLED
  422 OUTSIDE_WORKING_HOURS
  429 TOO_MANY_REQUESTS
```
> `studio_id` resolvido internamente via slug do path param — nunca enviado pelo cliente.
> Cria Client se telefone não existe no studio (dedup por phone). Source = `web_page`.
> Status inicial depende de `ai_config.scheduling_rules.auto_confirm`.

---

## Checklist de Validação

- [x] Todo CRUD de entidade do DOMAIN_MODEL tem endpoints correspondentes
- [x] Response shapes consistentes: `{ data, meta }` para listas, `{ data }` para itens, `{ errors }` para erros
- [x] Paginação cursor-based em toda listagem com meta (cursor, has_more, total)
- [x] studio_id derivado do auth, nunca de query param
- [x] Validação Zod definida para todo request body (tipos documentados)
- [x] HTTP status codes corretos por operação
- [x] Rate limiting documentado em endpoints públicos e webhooks
- [x] Endpoints de webhook com validação de signature
- [x] Ações de negócio como sub-recursos (/appointments/:id/confirm, /complete, /cancel, /no-show)
- [x] Nenhum verbo na URL
- [x] Campos sensíveis excluídos de respostas públicas (settings, commission_value, working_hours)
- [x] LGPD: consent records append-only, data deletion endpoint, audit log
- [x] Tabelas públicas do schema mapeadas para endpoints públicos (studios, photos, professionals, services, categories, professional_services)

## Cruzamento com Schema

| Entidade (DOMAIN_MODEL) | Endpoints | Status |
|--------------------------|-----------|--------|
| Profile | GET, PATCH | OK |
| Studio | POST, GET, PATCH | OK |
| StudioPhoto | GET, POST, PATCH, DELETE | OK |
| Professional | GET, GET/me, POST, PATCH, DELETE | OK |
| ProfessionalService | via Professional PATCH (service_ids) | OK |
| ServiceCategory | GET, POST, PATCH, DELETE | OK |
| Service | GET, POST, GET/:id, PATCH, DELETE | OK |
| Client | GET, POST, GET/:id, PATCH, DELETE | OK |
| Anamnesis | GET, PUT (upsert) | OK |
| Appointment | GET, POST, GET/:id, PATCH + status transitions | OK |
| BlockedSlot | GET, POST, DELETE | OK |
| Package | GET, POST, PATCH, DELETE | OK |
| PackageSubscription | GET (by package), GET (by client), POST, GET/:id | OK |
| Commission | GET, POST /pay | OK |
| Payment | GET | OK — criado via /appointments/:id/complete |
| Conversation | GET, escalate, close | OK |
| Message | GET (via conversation) | OK — criado via webhook |
| AIConfig | GET, PATCH | OK |
| DeviceToken | POST, DELETE | OK |
| NotificationLog | — | OK — interno, sem endpoint (criado por jobs) |
| Subscription | GET, POST, PATCH, cancel | OK |
| Invoice | GET | OK — criado por webhook billing |
| ConsentRecord | GET, POST (via client) | OK |
| AuditLog | GET | OK — criado por backend service_role |
| OnboardingState | GET, PATCH | OK |
| Campaign | GET, POST, PATCH, DELETE + metrics | OK |
| CampaignLog | via campaign metrics | OK — criado por jobs |
| FinancialSummary | via /financial/summary | OK — materialized view |
