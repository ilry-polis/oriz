# Modelo de Domínio — Oriz

## Entidades Principais

### Auth
- **User** — Usuário autenticado (via Supabase Auth)
- **Profile** — Perfil estendido (nome, telefone, avatar, role)
- **Roles:** owner (dono do estúdio), professional (colaborador), client (cliente)

### Studio (Tenant)
- **Studio** — Estúdio/negócio de beleza (tenant raiz)
  - name, slug (URL), phone, address, logo, description
  - business_hours (JSON: {day: {open, close}})
  - settings (JSON: configs gerais)
  - subscription_plan, subscription_status

### Scheduling
- **Appointment** — Agendamento
  - studio_id, client_id, professional_id, service_id
  - date, start_time, end_time
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
  - client_id, service_category_id
  - fields (JSON: perguntas e respostas)
  - updated_at

### Services
- **ServiceCategory** — Categoria (Unhas, Cílios, Sobrancelha, etc.)
- **Service** — Serviço oferecido
  - studio_id, category_id, name, duration_minutes, price
  - is_active
- **Package** — Pacote de sessões
  - studio_id, service_id, name, total_sessions, price
  - validity_days
- **PackageSubscription** — Pacote comprado por cliente
  - package_id, client_id, sessions_used, sessions_total
  - expires_at, status: active | completed | expired

### Team
- **Professional** — Profissional do estúdio
  - studio_id, user_id, name, avatar, specialties
  - commission_type: percentage | fixed
  - commission_value
  - card_fee_policy: studio | professional | split
  - is_active
- **ProfessionalService** — Quais serviços cada profissional faz
  - professional_id, service_id
- **Commission** — Registro de comissão calculada
  - professional_id, appointment_id, amount
  - studio_amount, professional_amount
  - card_fee_amount, who_paid_fee
  - period, status: pending | paid

### Financial
- **Payment** — Pagamento recebido
  - studio_id, appointment_id, client_id
  - amount, method: cash | pix | debit | credit
  - card_fee_percentage (se cartão)
  - created_at
- **FinancialSummary** — View materializada para dashboard
  - studio_id, period, total_revenue, total_commissions
  - avg_ticket, occupancy_rate

### AI Assistant
- **Conversation** — Conversa no WhatsApp
  - studio_id, client_id (nullable se novo), whatsapp_number
  - status: active | closed | escalated
  - started_at, last_message_at
- **Message** — Mensagem individual
  - conversation_id, role: client | assistant | system
  - content, metadata (JSON)
  - created_at
- **AIConfig** — Configuração da IA por estúdio
  - studio_id, tone_of_voice, greeting_message
  - scheduling_rules (JSON), fallback_message
  - enabled: boolean

### Marketing
- **Campaign** — Campanha automática
  - studio_id, type: birthday | reactivation | custom
  - message_template, discount_percentage (nullable)
  - inactivity_days (para reativação, default 60)
  - channel: whatsapp | push | both
  - is_active
- **CampaignLog** — Registro de envios
  - campaign_id, client_id, sent_at
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
```
