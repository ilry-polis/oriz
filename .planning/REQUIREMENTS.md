# Requirements: Oriz

**Defined:** 2026-03-13
**Core Value:** A profissional nunca mais precisa parar um atendimento para responder WhatsApp — a IA agenda, responde dúvidas e gerencia a agenda automaticamente.

## v1 Requirements

Requirements for initial release. Each maps to roadmap phases.

### Authentication

- [ ] **AUTH-01**: User can create account with email and password
- [ ] **AUTH-02**: User can login with Google account
- [ ] **AUTH-03**: User can login with Apple account
- [ ] **AUTH-04**: User session persists across app refresh
- [ ] **AUTH-05**: Studio owner completes onboarding wizard (studio data → services → business hours)

### Services & Packages

- [x] **SERV-01**: Owner can create services with name, duration, price, and category
- [x] **SERV-02**: Owner can set buffer time between appointments per service
- [ ] **SERV-03**: Owner can create session packages with special pricing
- [ ] **SERV-04**: Sessions deducted automatically when appointment is completed (not on booking)
- [ ] **SERV-05**: Packages have configurable expiration date

### Scheduling

- [x] **SCHD-01**: Professional views agenda in day and week view
- [x] **SCHD-02**: System detects and prevents double-booking with DB-level constraint
- [x] **SCHD-03**: Professional can block time slots (vacation, breaks, lunch)
- [x] **SCHD-04**: Appointments follow status workflow: confirmed → completed/cancelled/no-show
- [x] **SCHD-05**: Business hours configurable per day of week per professional

### Clients

- [ ] **CLNT-01**: Professional can register clients with name, phone, and email
- [ ] **CLNT-02**: Client phone numbers normalized to E.164 format for deduplication
- [ ] **CLNT-03**: Professional can fill configurable anamnesis form per service category
- [ ] **CLNT-04**: Professional can view full appointment history per client
- [ ] **CLNT-05**: Professional can add private notes per client
- [ ] **CLNT-06**: Professional can tag clients (VIP, new, inactive)

### Team & Commissions

- [ ] **TEAM-01**: Owner can register professionals in the studio
- [ ] **TEAM-02**: Owner can link professionals to services they perform
- [ ] **TEAM-03**: Owner can configure commission per professional (% or fixed amount per service)
- [ ] **TEAM-04**: System calculates commission split for reporting (not payment gateway split)
- [ ] **TEAM-05**: Owner can configure who absorbs card processing fees

### Financial

- [ ] **FINC-01**: Owner views revenue dashboard by day/week/month
- [ ] **FINC-02**: Owner views revenue breakdown by professional and by service
- [ ] **FINC-03**: Owner views average ticket value
- [ ] **FINC-04**: Owner views agenda occupancy rate
- [ ] **FINC-05**: Owner records payment method per appointment (cash, PIX, debit, credit)

### Public Page

- [ ] **PAGE-01**: Studio has public URL (oriz.app/slug) with studio info and photos
- [ ] **PAGE-02**: Public page lists services with prices
- [ ] **PAGE-03**: Public page lists professionals with specialties
- [ ] **PAGE-04**: Client can book appointment directly from public page (self-service)

### Push Notifications

- [ ] **PUSH-01**: Professional receives push notification on new booking
- [ ] **PUSH-02**: Client receives reminder X hours before appointment

### WhatsApp & AI

- [ ] **WHAI-01**: AI assistant answers questions about services, prices, and availability via WhatsApp
- [ ] **WHAI-02**: AI assistant books appointments by checking real agenda availability
- [ ] **WHAI-03**: AI assistant handles rescheduling and cancellation
- [ ] **WHAI-04**: AI falls back to human when it cannot resolve
- [ ] **WHAI-05**: Owner configures AI personality (tone of voice, greeting, rules)
- [ ] **WHAI-06**: System sends appointment confirmation via WhatsApp

### Marketing

- [ ] **MKTG-01**: System sends automatic birthday message via WhatsApp
- [ ] **MKTG-02**: System sends reactivation message to inactive clients (>60 days, configurable)
- [ ] **MKTG-03**: Owner can customize message templates with optional discount

### LGPD & Compliance

- [ ] **LGPD-01**: System logs access to sensitive client data (view, export, delete) in audit trail
- [ ] **LGPD-02**: Marketing consent captured explicitly per client (opt-in, default false); no message sent without consent

### Billing & Subscription

- [ ] **BILL-01**: Studio owner can subscribe to a plan (basic, pro, premium) via payment gateway
- [ ] **BILL-02**: System enforces feature gating based on active subscription plan
- [ ] **BILL-03**: System processes subscription renewals and records invoices via gateway webhook
- [ ] **BILL-04**: Studio owner can upgrade or downgrade plan from the app

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Notifications v2

- **NOTF-01**: User can configure notification preferences (which notifications to receive)
- **NOTF-02**: Email notifications as alternative channel

### Moderation

- **MODR-01**: Owner can block client from booking
- **MODR-02**: Rate limiting on public booking per phone number

### Advanced Reporting

- **REPT-01**: Exportable reports (PDF/CSV)
- **REPT-02**: Year-over-year comparison dashboard

### Platform Expansion

- **PLAT-01**: Dashboard web admin for large studios
- **PLAT-02**: Multi-unit (filiais) support
- **PLAT-03**: Google Calendar bidirectional sync

## Out of Scope

| Feature | Reason |
|---------|--------|
| Mobile app for clients | Clients book via public web page or WhatsApp AI — no app install needed |
| In-app real-time chat | WhatsApp is the natural communication channel |
| Photo portfolio/gallery | Instagram handles this better |
| Professional marketplace | Different business model entirely |
| Product inventory management | Different market segment |
| POS with receipt printing | Fiscal/tax complexity too high |
| Freemium tier | 100% paid from day 1; distribution via influencer channel |
| Payment gateway split (auto-payout) | v1 calculates commissions for reporting only; actual payment is manual |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| AUTH-01 | Phase 1 | Pending |
| AUTH-02 | Phase 1 | Pending |
| AUTH-03 | Phase 1 | Pending |
| AUTH-04 | Phase 1 | Pending |
| AUTH-05 | Phase 1 | Pending |
| SERV-01 | Phase 2 | Complete |
| SERV-02 | Phase 2 | Complete |
| SERV-03 | Phase 4 | Pending |
| SERV-04 | Phase 4 | Pending |
| SERV-05 | Phase 4 | Pending |
| SCHD-01 | Phase 3 | Complete |
| SCHD-02 | Phase 3 | Complete |
| SCHD-03 | Phase 3 | Complete |
| SCHD-04 | Phase 3 | Complete |
| SCHD-05 | Phase 3 | Complete |
| CLNT-01 | Phase 2 | Pending |
| CLNT-02 | Phase 2 | Pending |
| CLNT-03 | Phase 2 | Pending |
| CLNT-04 | Phase 2 | Pending |
| CLNT-05 | Phase 2 | Pending |
| CLNT-06 | Phase 2 | Pending |
| TEAM-01 | Phase 2 | Pending |
| TEAM-02 | Phase 2 | Pending |
| TEAM-03 | Phase 2 | Pending |
| TEAM-04 | Phase 2 | Pending |
| TEAM-05 | Phase 2 | Pending |
| FINC-01 | Phase 4 | Pending |
| FINC-02 | Phase 4 | Pending |
| FINC-03 | Phase 4 | Pending |
| FINC-04 | Phase 4 | Pending |
| FINC-05 | Phase 4 | Pending |
| PAGE-01 | Phase 5 | Pending |
| PAGE-02 | Phase 5 | Pending |
| PAGE-03 | Phase 5 | Pending |
| PAGE-04 | Phase 5 | Pending |
| PUSH-01 | Phase 5 | Pending |
| PUSH-02 | Phase 5 | Pending |
| WHAI-01 | Phase 6 | Pending |
| WHAI-02 | Phase 6 | Pending |
| WHAI-03 | Phase 6 | Pending |
| WHAI-04 | Phase 6 | Pending |
| WHAI-05 | Phase 6 | Pending |
| WHAI-06 | Phase 6 | Pending |
| MKTG-01 | Phase 7 | Pending |
| MKTG-02 | Phase 7 | Pending |
| MKTG-03 | Phase 7 | Pending |
| LGPD-01 | Phase 2 | Pending |
| LGPD-02 | Phase 2, 5, 7 | Pending |
| BILL-01 | Phase 5.1 | Pending |
| BILL-02 | Phase 5.1 | Pending |
| BILL-03 | Phase 5.1 | Pending |
| BILL-04 | Phase 5.1 | Pending |

**Coverage:**
- v1 requirements: 51 total
- Mapped to phases: 51
- Unmapped: 0

---
*Requirements defined: 2026-03-13*
*Last updated: 2026-03-13 — added LGPD (2) and Billing (4) requirements, all 51 mapped*
