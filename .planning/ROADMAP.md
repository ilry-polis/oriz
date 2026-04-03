# Roadmap: Oriz — Agenda Inteligente para Profissionais de Beleza

## Overview

Oriz is built in eight phases following a strict dependency graph. Infrastructure and identity come first because multi-tenancy decisions cannot be safely retrofitted after data accumulates. Core domain (services, clients, team) is built next as a single combined phase since all three modules are independent of each other and prerequisites for scheduling. LGPD compliance (audit log and consent capture) is embedded in Phase 2 since it must exist from the first client data access. Scheduling follows, then financial and package management (which depends on completed appointments). External channels (public page and push notifications) come next. Phase 5.1 (Billing & Subscription) is inserted before the WhatsApp AI assistant because premium features (AI, marketing) require plan-based feature gating. The WhatsApp AI assistant — the product's killer feature — is built on stable, complete domain data. Marketing automation closes the roadmap, depending on both the WhatsApp channel and consent records being operational.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [x] **Phase 1: Identity and Foundation** - Auth, studio onboarding, and multi-tenant infrastructure (completed 2026-04-02; social login deferred)
- [ ] **Phase 2: Core Domain** - Services, clients, and team management
- [ ] **Phase 3: Scheduling Engine** - Agenda, conflict detection, and appointment workflows
- [ ] **Phase 4: Financial and Packages** - Revenue dashboard, payment recording, and session packages
- [ ] **Phase 5: External Channels** - Public booking page and push notifications
- [ ] **Phase 5.1: Billing and Subscription** - INSERTED — SaaS plans, payment gateway, feature gating
- [ ] **Phase 6: WhatsApp and AI Assistant** - AI scheduling agent and WhatsApp integration
- [ ] **Phase 7: Marketing Automation** - Birthday campaigns and client reactivation

## Phase Details

### Phase 1: Identity and Foundation
**Goal**: Professionals can create and access their studio account; the system enforces multi-tenant isolation from day one
**Depends on**: Nothing (first phase)
**Requirements**: AUTH-01, AUTH-02, AUTH-03, AUTH-04, AUTH-05
**Success Criteria** (what must be TRUE):
  1. A new professional can create an account with email and password and receive a verified session
  2. A professional can log in with Google or Apple and land in the app with a valid session
  3. A logged-in session persists across app restarts without requiring re-authentication
  4. A new studio owner completes the onboarding wizard (studio name, timezone, services, business hours) and can access her configured studio
  5. Data from one studio is never visible to any other studio (cross-tenant isolation enforced at DB and RLS level)
**Plans**: TBD

### Phase 2: Core Domain
**Goal**: Studio owners can configure their service catalog, manage their client list, and register their team
**Depends on**: Phase 1
**Requirements**: SERV-01, SERV-02, CLNT-01, CLNT-02, CLNT-03, CLNT-04, CLNT-05, CLNT-06, TEAM-01, TEAM-02, TEAM-03, TEAM-04, TEAM-05, LGPD-01, LGPD-02
**Success Criteria** (what must be TRUE):
  1. Owner can create a service with name, price, duration, category, and buffer time between appointments
  2. Owner can register a client with name, phone (stored in E.164 format), and email; duplicate phone numbers are rejected; marketing consent is captured explicitly (default: not granted)
  3. Professional can fill and view a configurable anamnesis form per client per service category
  4. Professional can view full appointment history, add private notes, and tag clients (VIP, new, inactive)
  5. Owner can register professionals, link them to services, and configure commission rules (percentage or fixed amount)
  6. Every access to sensitive client data (view, export, delete) is recorded in the audit log with user, action, and timestamp
**Plans**: 6 plans

Plans:
- [ ] 02-01-PLAN.md — Services backend: complete CRUD (list, getById, update, setActive, delete)
- [ ] 02-02-PLAN.md — Clients + LGPD backend: client CRUD, auto-tags, audit log, consent
- [ ] 02-03-PLAN.md — Anamnesis + Notes backend: anamnesis upsert, client notes, appointment history
- [ ] 02-04-PLAN.md — Team backend: professional CRUD with Supabase Auth, service links, commissions
- [ ] 02-05-PLAN.md — Services + Team Flutter screens: catalog with categories, team management
- [ ] 02-06-PLAN.md — Clients Flutter screens: list with search/filters, detail with tabs, anamnesis forms

### Phase 3: Scheduling Engine
**Goal**: Professionals can view and manage their agenda with guaranteed conflict-free booking
**Depends on**: Phase 2
**Requirements**: SCHD-01, SCHD-02, SCHD-03, SCHD-04, SCHD-05
**Success Criteria** (what must be TRUE):
  1. Professional can view her agenda in day and week view showing all appointments with client and service details
  2. Two simultaneous booking attempts for the same professional and time slot result in exactly one succeeding; the second is rejected at the database level
  3. Professional can block time slots (vacation, lunch, breaks) that prevent any booking during those periods
  4. An appointment moves through the status workflow (confirmed → completed, cancelled, or no-show) and the transition is recorded
  5. Business hours per day of week per professional are enforced — no appointment can be booked outside configured hours
**Plans**: TBD

### Phase 4: Financial and Packages
**Goal**: Studio owners can track revenue and package sessions; financial data reflects completed work accurately
**Depends on**: Phase 3
**Requirements**: SERV-03, SERV-04, SERV-05, FINC-01, FINC-02, FINC-03, FINC-04, FINC-05
**Success Criteria** (what must be TRUE):
  1. Owner can view revenue totals by day, week, and month on a dashboard
  2. Owner can see revenue broken down by professional and by service, plus average ticket value and agenda occupancy rate
  3. Professional can record the payment method (cash, PIX, debit, credit) for each completed appointment
  4. Owner can create a session package with special pricing and an expiration date; sessions are deducted only when the appointment is marked completed, not on booking
**Plans**: TBD

### Phase 5: External Channels
**Goal**: Clients can discover and self-book at the studio via a public web page; professionals receive push alerts for bookings
**Depends on**: Phase 3
**Requirements**: PAGE-01, PAGE-02, PAGE-03, PAGE-04, PUSH-01, PUSH-02, LGPD-02
**Success Criteria** (what must be TRUE):
  1. A studio has a public URL (oriz.app/slug) showing studio info, photos, services with prices, and professionals with specialties
  2. A client can book an appointment directly from the public page without creating an account; the booking appears immediately on the professional's agenda; marketing consent is captured via explicit checkbox during booking
  3. A professional receives a push notification on her phone when a new booking is made
  4. A client receives a push reminder at a configurable number of hours before her appointment
**Plans**: TBD

### Phase 5.1: Billing and Subscription — INSERTED
**Goal**: Studios subscribe to a paid plan and the system enforces feature access based on the active subscription; Oriz generates revenue from day one
**Depends on**: Phase 5
**Requirements**: BILL-01, BILL-02, BILL-03, BILL-04
**Success Criteria** (what must be TRUE):
  1. A studio owner can subscribe to a plan (basic R$19.90, pro R$29.90, premium R$59.90) and the payment is processed via the gateway (Stripe or Asaas)
  2. Features restricted to higher plans (WhatsApp AI, marketing automation) are gated — a studio on the basic plan cannot access premium features
  3. Subscription renewals are processed automatically; failed payments move the subscription to past_due and the owner is notified
  4. A studio owner can upgrade or downgrade her plan from the app; the change takes effect at the next billing cycle
**Plans**: TBD

### Phase 6: WhatsApp and AI Assistant
**Goal**: The AI assistant manages appointments and answers questions via WhatsApp autonomously, with human fallback when needed
**Depends on**: Phase 5.1
**Requirements**: WHAI-01, WHAI-02, WHAI-03, WHAI-04, WHAI-05, WHAI-06
**Success Criteria** (what must be TRUE):
  1. A client can send a WhatsApp message asking about services, prices, or availability and receive an accurate, helpful response from the AI
  2. A client can book, reschedule, or cancel an appointment entirely through WhatsApp conversation without professional intervention
  3. When the AI cannot resolve a request, it notifies the professional and the conversation is handed off without data loss
  4. The studio owner can configure the AI's tone of voice, greeting message, and custom rules from the app
  5. A WhatsApp confirmation message is sent automatically when any appointment is created (via any channel)
**Plans**: TBD

### Phase 7: Marketing Automation
**Goal**: The system proactively re-engages clients through automated WhatsApp campaigns without manual effort from the professional
**Depends on**: Phase 6
**Requirements**: MKTG-01, MKTG-02, MKTG-03, LGPD-02
**Success Criteria** (what must be TRUE):
  1. A client receives an automatic birthday message via WhatsApp on her birthday without any manual action from the professional
  2. A client who has not booked in more than 60 days (configurable) automatically receives a reactivation message via WhatsApp
  3. The studio owner can customize the birthday and reactivation message templates, including an optional discount, from the app
  4. The system never sends a marketing message to a client without an active consent record (ConsentRecord.granted = true)
**Plans**: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5 → 5.1 → 6 → 7

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Identity and Foundation | — | ✅ Completed | 2026-04-02 |
| 2. Core Domain | 0/6 | Planning complete | - |
| 3. Scheduling Engine | 5/6 | In progress | - |
| 4. Financial and Packages | 0/TBD | Not started | - |
| 5. External Channels | 0/TBD | Not started | - |
| 5.1. Billing and Subscription | 0/TBD | Not started | - |
| 6. WhatsApp and AI Assistant | 0/TBD | Not started | - |
| 7. Marketing Automation | 0/TBD | Not started | - |
