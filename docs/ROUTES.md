# Rotas — Oriz

> Derivado de `docs/API_CONTRACTS.md`. Se divergir, o contrato vence.
> Cada rota mapeia para um Fastify plugin em `backend/src/routes/`.

## Convenções

- **Prefixo**: `/api/v1`
- **Auth hooks**: `authenticate` (JWT), `requireStudioMember` (owner ou professional), `requireOwner`
- **Webhook hooks**: `validateWhatsAppSignature`, `validateBillingSignature`
- **studio_id**: derivado do JWT — nunca de params/query
- **Validação**: Zod schemas no boundary (params, query, body)
- **Paginação**: cursor-based (`cursor: UUID`, `limit: 1-100`, default 20)
- **Rate limit**: endpoints públicos, webhooks e criação de studio

---

## 1. Auth — `auth.routes.ts`

Prefix: `/api/v1/auth`

| Método | Path | Auth | Body Schema | Handler | Rate Limit |
|--------|------|------|-------------|---------|------------|
| POST | /signup | public | `SignupBody` (email, password min 8, full_name) | AuthController.signup | 5/min IP |
| POST | /login | public | `LoginBody` (email, password) | AuthController.login | 10/min IP |
| POST | /logout | authenticated | — | AuthController.logout | — |
| POST | /refresh | public | `RefreshBody` (refresh_token) | AuthController.refresh | 30/min IP |
| POST | /forgot-password | public | `ForgotPasswordBody` (email) | AuthController.forgotPassword | 3/min IP |

**Notas:**
- forgot-password sempre retorna 200 (não revela se email existe)
- Processamento via BullMQ para prevenir timing attacks

---

## 2. Profile — `profile.routes.ts`

Prefix: `/api/v1/profile`

| Método | Path | Auth | Body Schema | Handler |
|--------|------|------|-------------|---------|
| GET | / | authenticated | — | ProfileController.get |
| PATCH | / | authenticated | `UpdateProfileBody` (full_name?, phone?, avatar_url?) | ProfileController.update |

---

## 3. Studios & Config — `studios.routes.ts`

Prefix: `/api/v1/studios`

| Método | Path | Auth | Body/Query Schema | Handler | Rate Limit |
|--------|------|------|-------------------|---------|------------|
| POST | / | authenticated | `CreateStudioBody` (name, slug regex `^[a-z0-9-]{3,50}$`, phone?, address?, description?, timezone default "America/Sao_Paulo") | StudioController.create | 3/min user |
| GET | /me | owner+professional | — | StudioController.get | — |
| PATCH | /me | owner | `UpdateStudioBody` (name?, slug?, phone?, address?, logo_url?, description?, timezone?, settings?: { reminder_hours_before?, allow_public_booking?, default_currency? }) | StudioController.update | — |

### Studio Photos

| Método | Path | Auth | Body Schema | Handler |
|--------|------|------|-------------|---------|
| GET | /me/photos | owner+professional | — | StudioPhotoController.list |
| POST | /me/photos | owner | `CreatePhotoBody` (url, position? default 0) | StudioPhotoController.create |
| PATCH | /me/photos/:photoId | owner | `UpdatePhotoBody` (position?) | StudioPhotoController.update |
| DELETE | /me/photos/:photoId | owner | — | StudioPhotoController.delete |

**Nota:** Sem paginação — max ~20 fotos por studio.

### Onboarding

| Método | Path | Auth | Body Schema | Handler |
|--------|------|------|-------------|---------|
| GET | /me/onboarding | owner | — | OnboardingController.get |
| PATCH | /me/onboarding | owner | `UpdateOnboardingBody` (current_step: "studio_data" \| "services" \| "business_hours" \| "complete") | OnboardingController.update |

**Nota:** Quando `current_step` = `complete`, `completed_at` é auto-preenchido.

---

## 4. Service Categories — `service-categories.routes.ts`

Prefix: `/api/v1/service-categories`

| Método | Path | Auth | Body/Query Schema | Handler |
|--------|------|------|-------------------|---------|
| GET | / | owner+professional | `ListCategoriesQuery` (is_active?) | ServiceCategoryController.list |
| POST | / | owner | `CreateCategoryBody` (name, icon?, position? default 0) | ServiceCategoryController.create |
| PATCH | /:id | owner | `UpdateCategoryBody` (name?, icon?, position?, is_active?) | ServiceCategoryController.update |
| DELETE | /:id | owner | — | ServiceCategoryController.delete |

**Notas:**
- Sem paginação — max ~15 categorias.
- GET retorna categorias globais (studio_id = NULL) + do studio.
- Categorias globais não podem ser editadas/excluídas (403 GLOBAL_CATEGORY).

---

## 5. Services — `services.routes.ts`

Prefix: `/api/v1/services`

| Método | Path | Auth | Body/Query Schema | Handler |
|--------|------|------|-------------------|---------|
| GET | / | owner+professional | `ListServicesQuery` (category_id?, is_active?, cursor?, limit?) | ServiceController.list |
| POST | / | owner | `CreateServiceBody` (category_id UUID, name, duration_minutes int min 5, price int centavos min 0, buffer_minutes? default 0, is_active? default true) | ServiceController.create |
| GET | /:id | owner+professional | — | ServiceController.getById |
| PATCH | /:id | owner | `UpdateServiceBody` (category_id?, name?, duration_minutes?, price?, buffer_minutes?, is_active?) | ServiceController.update |
| DELETE | /:id | owner | — | ServiceController.delete |

**Nota:** DELETE retorna 409 SERVICE_HAS_APPOINTMENTS se há agendamentos futuros.

---

## 6. Professionals — `professionals.routes.ts`

Prefix: `/api/v1/professionals`

| Método | Path | Auth | Body/Query Schema | Handler |
|--------|------|------|-------------------|---------|
| GET | / | owner+professional | `ListProfessionalsQuery` (is_active?, cursor?, limit?) | ProfessionalController.list |
| POST | / | owner | `CreateProfessionalBody` (user_id UUID, name, avatar_url?, specialties? string[], working_hours? Record, commission_type "percentage"\|"fixed", commission_value, card_fee_policy? default "studio", service_ids? UUID[]) | ProfessionalController.create |
| GET | /me | owner+professional | — | ProfessionalController.getMe |
| GET | /:id | owner+professional | — | ProfessionalController.getById |
| PATCH | /:id | owner | `UpdateProfessionalBody` (name?, avatar_url?, specialties?, working_hours?, commission_type?, commission_value?, card_fee_policy?, is_active?, service_ids?) | ProfessionalController.update |
| DELETE | /:id | owner | — | ProfessionalController.delete |

**Notas:**
- `commission_type`, `commission_value`, `card_fee_policy` → null para não-owners na listagem.
- `service_ids` no PATCH substitui todos os vínculos em `professional_services`.
- DELETE retorna 409 PROFESSIONAL_HAS_APPOINTMENTS se há agendamentos futuros.

---

## 7. Clients — `clients.routes.ts`

Prefix: `/api/v1/clients`

### CRUD

| Método | Path | Auth | Body/Query Schema | Handler |
|--------|------|------|-------------------|---------|
| GET | / | owner+professional | `ListClientsQuery` (search?, tag?, inactive_days?, cursor?, limit?) | ClientController.list |
| POST | / | owner+professional | `CreateClientBody` (name, phone?, email?, birth_date? ISO date, tags? string[], notes?) — dedup por phone quando fornecido; sem phone = sem dedup | ClientController.create |
| GET | /:id | owner+professional | — | ClientController.getById |
| PATCH | /:id | owner+professional | `UpdateClientBody` (name?, phone?, email?, birth_date?, tags?, notes?) | ClientController.update |
| DELETE | /:id | owner | — | ClientController.delete |

### Client History

| Método | Path | Auth | Query Schema | Handler |
|--------|------|------|--------------|---------|
| GET | /:id/appointments | owner+professional | `ListClientAppointmentsQuery` (status?, cursor?, limit?) | ClientController.listAppointments |

### Anamnesis

| Método | Path | Auth | Body Schema | Handler |
|--------|------|------|-------------|---------|
| GET | /:clientId/anamneses | owner+professional | — | AnamnesisController.list |
| PUT | /:clientId/anamneses/:categoryId | owner+professional | `UpsertAnamnesisBody` (fields: Record<string, any>) | AnamnesisController.upsert |

**Nota:** Sem paginação (max ~15). PUT é upsert por (studio_id, client_id, service_category_id).

### Package Subscriptions

| Método | Path | Auth | Query Schema | Handler |
|--------|------|------|--------------|---------|
| GET | /:clientId/package-subscriptions | owner+professional | `ListPackageSubscriptionsQuery` (status?, cursor?, limit?) | PackageSubscriptionController.listByClient |

### Consent Records (LGPD)

| Método | Path | Auth | Body Schema | Handler |
|--------|------|------|-------------|---------|
| GET | /:clientId/consents | owner+professional | — | ConsentController.list |
| POST | /:clientId/consents | owner+professional | `CreateConsentBody` (type: "marketing_whatsapp"\|"marketing_push", action: "granted"\|"revoked") | ConsentController.create |

**Nota:** Sem paginação (max 2 registros). Append-only — nunca edita registros anteriores.

### Data Deletion (LGPD)

| Método | Path | Auth | Handler |
|--------|------|------|---------|
| POST | /:clientId/data-deletion | owner | ClientController.dataDeletion |

**Nota:** Anonimiza dados pessoais, mantém registros financeiros. Cria AuditLog com action = delete.

---

## 8. Appointments & Calendar — `appointments.routes.ts`

Prefix: `/api/v1/appointments`

### CRUD

| Método | Path | Auth | Body/Query Schema | Handler |
|--------|------|------|-------------------|---------|
| GET | / | owner+professional | `ListAppointmentsQuery` (date?, date_from?, date_to?, professional_id?, status?, cursor?, limit?) — `date` é sugar para `date_from=date&date_to=date`; se `date` presente, `date_from`/`date_to` são rejeitados (Zod refine) | AppointmentController.list |
| POST | / | owner+professional | `CreateAppointmentBody` (client_id UUID, professional_id UUID, service_id UUID, date ISO, start_time datetime, notes?, source? default "app") | AppointmentController.create |
| GET | /available-slots | owner+professional | `AvailableSlotsQuery` (date ISO, professional_id UUID, service_id UUID) — todos obrigatórios | AppointmentController.availableSlots |
| GET | /:id | owner+professional | — | AppointmentController.getById |
| PATCH | /:id | owner+professional | `UpdateAppointmentBody` (professional_id?, service_id?, date?, start_time?, notes?) | AppointmentController.update |

**Notas:**
- `end_time` calculado automaticamente: `start_time + duration_minutes + buffer_minutes`.
- Filtros de data: `date` é atalho para um único dia. Usar `date` OU `date_from`/`date_to`, nunca ambos (validação Zod rejeita).

### Status Transitions

| Método | Path | Auth | Body Schema | Handler |
|--------|------|------|-------------|---------|
| POST | /:id/confirm | owner+professional | — | AppointmentController.confirm |
| POST | /:id/complete | owner+professional | `CompleteAppointmentBody` (payment?: { amount int centavos, method, card_fee_percentage? }) | AppointmentController.complete |
| POST | /:id/cancel | owner+professional | `CancelAppointmentBody` (cancellation_reason?) | AppointmentController.cancel |
| POST | /:id/no-show | owner+professional | — | AppointmentController.noShow |

**Notas:**
- complete retorna `{ appointment, payment, commission }` se payment informado.
- Se appointment usa pacote, deduz sessão do PackageSubscription.
- Todas as transições partem de `confirmed` — erro 422 INVALID_STATUS_TRANSITION se status atual não permite.

---

## 9. Blocked Slots — `blocked-slots.routes.ts`

Prefix: `/api/v1/blocked-slots`

| Método | Path | Auth | Body/Query Schema | Handler |
|--------|------|------|-------------------|---------|
| GET | / | owner+professional | `ListBlockedSlotsQuery` (professional_id?, date_from?, date_to?, cursor?, limit?) | BlockedSlotController.list |
| POST | / | owner+professional | `CreateBlockedSlotBody` (professional_id UUID, date ISO, start_time datetime, end_time datetime, reason?) | BlockedSlotController.create |
| DELETE | /:id | owner+professional | — | BlockedSlotController.delete |

**Nota:** Profissional só pode criar/deletar bloqueios do seu próprio horário (403 NOT_OWN_SCHEDULE). Owner pode criar/deletar bloqueios de qualquer profissional.

---

## 10. Packages — `packages.routes.ts`

Prefix: `/api/v1/packages`

### CRUD

| Método | Path | Auth | Body/Query Schema | Handler |
|--------|------|------|-------------------|---------|
| GET | / | owner+professional | `ListPackagesQuery` (cursor?, limit?) | PackageController.list |
| POST | / | owner | `CreatePackageBody` (service_id UUID, name, total_sessions int min 1, price int centavos, validity_days int min 1) | PackageController.create |
| PATCH | /:id | owner | `UpdatePackageBody` (name?, total_sessions?, price?, validity_days?) | PackageController.update |
| DELETE | /:id | owner | — | PackageController.delete |

**Nota:** PATCH retorna 422 CANNOT_REDUCE_SESSIONS se há assinaturas ativas. DELETE retorna 409 PACKAGE_HAS_SUBSCRIPTIONS.

### Package Subscriptions

| Método | Path | Auth | Body/Query Schema | Handler |
|--------|------|------|-------------------|---------|
| GET | /:packageId/subscriptions | owner+professional | `ListSubscriptionsQuery` (status?, cursor?, limit?) | PackageSubscriptionController.listByPackage |
| POST | /:packageId/subscriptions | owner+professional | `CreateSubscriptionBody` (client_id UUID) | PackageSubscriptionController.create |

**Nota:** `sessions_total` copiado do Package. `expires_at` = `now() + validity_days`.

---

## 11. Package Subscriptions (standalone) — `package-subscriptions.routes.ts`

Prefix: `/api/v1/package-subscriptions`

| Método | Path | Auth | Handler |
|--------|------|------|---------|
| GET | /:id | owner+professional | PackageSubscriptionController.getById |

---

## 12. Payments — `payments.routes.ts`

Prefix: `/api/v1/payments`

| Método | Path | Auth | Query Schema | Handler |
|--------|------|------|--------------|---------|
| GET | / | owner | `ListPaymentsQuery` (date_from?, date_to?, method?, professional_id?, cursor?, limit?) | PaymentController.list |

---

## 13. Commissions — `commissions.routes.ts`

Prefix: `/api/v1/commissions`

| Método | Path | Auth | Body/Query Schema | Handler |
|--------|------|------|-------------------|---------|
| GET | / | owner | `ListCommissionsQuery` (professional_id?, status?, period_start?, period_end?, cursor?, limit?) | CommissionController.list |
| POST | /pay | owner | `PayCommissionsBody` (commission_ids UUID[] min 1 max 100) | CommissionController.pay |

---

## 14. Financial Summary — `financial.routes.ts`

Prefix: `/api/v1/financial`

| Método | Path | Auth | Query Schema | Handler |
|--------|------|------|--------------|---------|
| GET | /summary | owner | `FinancialSummaryQuery` (year?, month? 1-12) | FinancialController.summary |

**Nota:** Dados da materialized view `financial_summaries`. Refresh via BullMQ.

---

## 15. Notifications — `notifications.routes.ts`

Prefix: `/api/v1/device-tokens`

| Método | Path | Auth | Body Schema | Handler |
|--------|------|------|-------------|---------|
| POST | / | authenticated | `CreateDeviceTokenBody` (token, platform: "android"\|"ios") | DeviceTokenController.create |
| DELETE | /:id | authenticated | — | DeviceTokenController.delete |

**Notas:**
- POST é upsert por (user_id, token).
- DELETE é soft delete (is_active = false). Usa ID do registro, não o token FCM.

---

## 16. AI Config — `ai.routes.ts`

Prefix: `/api/v1/ai`

| Método | Path | Auth | Body Schema | Handler |
|--------|------|------|-------------|---------|
| GET | /config | owner | — | AIConfigController.get |
| PATCH | /config | owner | `UpdateAIConfigBody` (tone_of_voice?, greeting_message?, fallback_message?, enabled?, scheduling_rules?: { max_advance_days?, min_advance_hours?, auto_confirm? }) | AIConfigController.update |

---

## 17. Conversations — `conversations.routes.ts`

Prefix: `/api/v1/conversations`

| Método | Path | Auth | Body/Query Schema | Handler |
|--------|------|------|-------------------|---------|
| GET | / | owner+professional | `ListConversationsQuery` (status?, cursor?, limit?) | ConversationController.list |
| GET | /:id/messages | owner+professional | `ListMessagesQuery` (cursor?, limit? default 50) | ConversationController.listMessages |
| POST | /:id/escalate | owner+professional | — | ConversationController.escalate |
| POST | /:id/close | owner+professional | — | ConversationController.close |

---

## 18. Campaigns — `campaigns.routes.ts`

Prefix: `/api/v1/campaigns`

| Método | Path | Auth | Body/Query Schema | Handler |
|--------|------|------|-------------------|---------|
| GET | / | owner | `ListCampaignsQuery` (type?, is_active?, cursor?, limit?) | CampaignController.list |
| POST | / | owner | `CreateCampaignBody` (type, message_template, discount_percentage? 0-100, inactivity_days? default 60, channel, is_active? default true) | CampaignController.create |
| PATCH | /:id | owner | `UpdateCampaignBody` (message_template?, discount_percentage?, inactivity_days?, channel?, is_active?) | CampaignController.update |
| DELETE | /:id | owner | — | CampaignController.delete |
| GET | /:id/metrics | owner | `CampaignMetricsQuery` (date_from?, date_to?) | CampaignController.metrics |

**Nota:** Stats separados da listagem para evitar N+1.

---

## 19. Billing & Subscription — `billing.routes.ts`

Prefix: `/api/v1/billing`

### Subscription

| Método | Path | Auth | Body Schema | Handler |
|--------|------|------|-------------|---------|
| GET | /subscription | owner | — | BillingController.getSubscription |
| POST | /subscription | owner | `CreateSubscriptionBody` (plan: "basic"\|"pro"\|"premium") | BillingController.createSubscription |
| PATCH | /subscription | owner | `UpdateSubscriptionBody` (plan) | BillingController.updateSubscription |
| POST | /subscription/cancel | owner | — | BillingController.cancelSubscription |

**Nota:** POST retorna `{ subscription, checkout_url }`. Upgrade/downgrade no próximo ciclo.

### Invoices

| Método | Path | Auth | Query Schema | Handler |
|--------|------|------|--------------|---------|
| GET | /invoices | owner | `ListInvoicesQuery` (status?, cursor?, limit?) | BillingController.listInvoices |

---

## 20. Audit Logs — `audit-logs.routes.ts`

Prefix: `/api/v1/audit-logs`

| Método | Path | Auth | Query Schema | Handler |
|--------|------|------|--------------|---------|
| GET | / | owner | `ListAuditLogsQuery` (date_from?, date_to?, action?, entity_type?, cursor?, limit?) | AuditLogController.list |

---

## 21. Webhooks — `webhooks.routes.ts`

Prefix: `/api/v1/webhooks`

| Método | Path | Auth | Handler | Rate Limit |
|--------|------|------|---------|------------|
| POST | /whatsapp | webhook (validateWhatsAppSignature) | WebhookController.whatsapp | 100/min IP |
| POST | /billing | webhook (validateBillingSignature) | WebhookController.billing | 100/min IP |

**Notas:**
- Body definido pelo provider (Evolution API / Z-API para WhatsApp, Stripe/Asaas para billing).
- Processamento assíncrono via BullMQ — retorna 200 imediatamente.
- Erro 401 INVALID_SIGNATURE se validação falha.

---

## 22. Public Booking Page — `public/studios.routes.ts`

Prefix: `/api/v1/public/studios`

| Método | Path | Auth | Body/Query Schema | Handler | Rate Limit |
|--------|------|------|-------------------|---------|------------|
| GET | /:slug | public | — | PublicStudioController.getBySlug | 60/min IP |
| GET | /:slug/professionals | public | — | PublicStudioController.listProfessionals | 60/min IP |
| GET | /:slug/services | public | `PublicServicesQuery` (category_id?) | PublicStudioController.listServices | 60/min IP |
| GET | /:slug/service-categories | public | — | PublicStudioController.listServiceCategories | 60/min IP |
| GET | /:slug/available-slots | public | `PublicAvailableSlotsQuery` (date, professional_id, service_id) — todos obrigatórios | PublicStudioController.availableSlots | 30/min IP |
| POST | /:slug/appointments | public | `PublicBookingBody` (client_name, client_phone, professional_id UUID, service_id UUID, date ISO, start_time datetime, notes?) | PublicStudioController.createAppointment | 3/min IP + 1/min phone |

**Notas:**
- studio_id resolvido via slug — nunca enviado pelo cliente.
- Nunca retorna: settings, owner_id, working_hours, commission_*, card_fee_policy.
- POST /appointments cria Client se telefone não existe (dedup por phone). Source = `web_page`.
- Status inicial depende de `ai_config.scheduling_rules.auto_confirm`.

---

## Cruzamento: API_CONTRACTS.md ↔ Rotas

| Domínio | Endpoints no Contrato | Rotas Implementadas | Status |
|---------|----------------------|---------------------|--------|
| Auth | 5 | 5 | OK |
| Profile | 2 | 2 | OK |
| Studios & Config | 8 | 8 | OK |
| Service Categories | 4 | 4 | OK |
| Services | 5 | 5 | OK |
| Professionals | 6 | 6 | OK |
| Clients (CRUD + sub-resources) | 12 | 12 | OK |
| Appointments & Calendar | 9 | 9 | OK |
| Blocked Slots | 3 | 3 | OK |
| Packages & Subscriptions | 7 | 7 | OK |
| Payments | 1 | 1 | OK |
| Commissions | 2 | 2 | OK |
| Financial Summary | 1 | 1 | OK |
| Notifications | 2 | 2 | OK |
| AI Config | 2 | 2 | OK |
| Conversations | 4 | 4 | OK |
| Campaigns | 5 | 5 | OK |
| Billing | 5 | 5 | OK |
| Audit Logs | 1 | 1 | OK |
| Webhooks | 2 | 2 | OK |
| Public Booking | 6 | 6 | OK |
| **Total** | **93** | **93** | **100%** |

## Auth Levels por Arquivo

| Auth Level | Arquivos |
|------------|----------|
| public | auth (signup, login, refresh, forgot-password), public/studios |
| authenticated | auth (logout), profile, studios (POST /), notifications |
| owner+professional | studios (/me, photos GET), service-categories (GET), services (GET, GET/:id), professionals, clients, appointments, blocked-slots, packages (GET, subscriptions), conversations |
| owner | studios (PATCH /me, photos CUD, onboarding), service-categories (CUD), services (CUD), professionals (CUD), clients (DELETE, data-deletion), packages (CUD), financial, ai, campaigns, billing, audit-logs |
| webhook | webhooks (whatsapp, billing) |
