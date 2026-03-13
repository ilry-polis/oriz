# Architecture Research

**Domain:** Beauty salon scheduling SaaS with WhatsApp AI assistant
**Researched:** 2026-03-12
**Confidence:** HIGH — based on existing project documentation (docs/ARCHITECTURE.md, DOMAIN_MODEL.md, DECISIONS_LOG.md)

## Standard Architecture

### System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│  CLIENT LAYER                                                    │
│                                                                  │
│  Flutter Mobile App     Web Page (oriz.app/slug)                │
│  (owner + professionals) (client self-service booking)          │
└────────┬──────────────────────────┬────────────────────────────┘
         │ REST API (JWT)            │ REST API (public, rate-limited)
         │                           │
┌────────▼───────────────────────────▼────────────────────────────┐
│  API GATEWAY — Fastify (Node.js + TypeScript)                   │
│                                                                  │
│  Routes → Controllers → Services → Repositories                 │
│                                                                  │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────────┐  │
│  │ Auth     │ │Scheduling│ │ Clients  │ │  Webhook Handler │  │
│  │ Module   │ │ Module   │ │ Module   │ │  (WhatsApp)      │  │
│  └──────────┘ └──────────┘ └──────────┘ └──────────────────┘  │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────────┐  │
│  │ Services │ │Financial │ │  Team    │ │  Public Page     │  │
│  │ Module   │ │ Module   │ │ Module   │ │  Module          │  │
│  └──────────┘ └──────────┘ └──────────┘ └──────────────────┘  │
└─────────────────────────┬───────────────────────────────────────┘
                           │
         ┌─────────────────┼─────────────────┐
         │                 │                  │
┌────────▼──────┐  ┌───────▼───────┐  ┌──────▼──────────────────┐
│  Supabase     │  │  Redis        │  │  BullMQ Queues           │
│  (PostgreSQL) │  │  (Cache)      │  │                          │
│               │  │               │  │  ai-response             │
│  RLS by       │  │  Agenda slots │  │  notifications           │
│  studio_id    │  │  Session data │  │  marketing               │
│               │  │  Rate limits  │  │  reports                 │
└───────────────┘  └───────────────┘  └──────┬───────────────────┘
                                              │
                          ┌───────────────────┼──────────────┐
                          │                   │              │
                   ┌──────▼──────┐   ┌────────▼────┐  ┌─────▼────┐
                   │ LangChain   │   │  FCM        │  │ WhatsApp │
                   │ AI Agent    │   │  (Push)     │  │  API     │
                   │ + Anthropic │   └─────────────┘  └──────────┘
                   │ + Pinecone  │
                   └─────────────┘
```

### Direct Supabase Access (Client SDK — no API layer)

```
Flutter App ──direct──→ Supabase Auth     (login, signup, token refresh)
Flutter App ──direct──→ Supabase Realtime (calendar live updates)
Flutter App ──direct──→ Supabase Storage  (photo/avatar upload)
```

ALL other data operations go through the Fastify API. Centralizes business logic, prevents rule duplication.

### Component Responsibilities

| Component | Responsibility | Communicates With | Does NOT touch |
|-----------|---------------|-------------------|----------------|
| Flutter App | UI, local state (Riverpod), navigation (GoRouter) | Fastify API, Supabase Auth/Storage/Realtime | Business logic, DB directly |
| Public Web Page | Self-service booking UI (anonymous) | Fastify API (public endpoints) | Admin functions |
| Fastify API | All business logic, validation, orchestration | Supabase DB, Redis, BullMQ | Direct LLM calls (delegated via queue) |
| Supabase (PostgreSQL) | Data persistence, RLS enforcement, auth | Fastify API (server-side client) | Flutter app for CRUD |
| Redis | Cache (agenda slots, sessions), job state | Fastify API, BullMQ workers | DB directly |
| BullMQ Workers | Async processing (AI, notifications, marketing) | LangChain AI, FCM, WhatsApp API, Supabase | Fastify API request cycle |
| LangChain AI Agent | LLM orchestration, tool-calling, conversation memory | Anthropic API, Pinecone, Supabase (via tools) | WhatsApp API directly |
| WhatsApp API | Message delivery/receive | Fastify webhook (inbound), BullMQ worker (outbound) | Business logic |
| FCM | Push notification delivery | BullMQ notifications worker | — |

## Data Flow

### Happy Path 1: Professional Books Appointment (Mobile App)

```
Flutter App
  → POST /appointments (Fastify API, JWT auth)
  → AppointmentController → AppointmentService
    → [conflict check] AppointmentRepository.findOverlapping()
    → [slot available] AppointmentRepository.create()
    → [emit job] BullMQ.notifications.add({ type: 'confirmation' })
  → 201 Created { data: appointment }
  → BullMQ worker → FCM → push notification to client
  → Supabase Realtime → Flutter App updates calendar UI live
```

### Happy Path 2: Client Messages WhatsApp AI

```
WhatsApp API webhook
  → POST /webhooks/whatsapp (Fastify, signature-verified, rate-limited)
  → WebhookController → enqueue message
  → BullMQ.ai-response.add({ message, phone, studioId })

BullMQ ai-response worker
  → Load Conversation from DB (or create new)
  → LangChain Agent.invoke({ message, history, studioId })
    → LLM (Anthropic Claude) decides action
    → Tool: checkAvailability(service, date) → Supabase query
    → Tool: createAppointment(clientId, serviceId, slot) → AppointmentService
    → Tool: getServiceList(studioId) → ServiceRepository
    → Compose reply
  → Save Message to Conversation
  → WhatsApp API.sendMessage(reply)
  → [if appointment created] BullMQ.notifications.add(...)
```

### Happy Path 3: Client Books via Public Web Page

```
oriz.app/studio-slug
  → GET /public/studios/:slug (no auth, cached in Redis)
  → Display services, professionals, available slots

Client selects slot
  → POST /public/appointments (rate-limited, no JWT, studio_id from slug)
  → PublicAppointmentController → AppointmentService (same service, different entry)
  → Client created if new (or matched by phone)
  → Appointment created with source: 'web_page'
  → Push notification + WhatsApp confirmation dispatched
```

### Background Flow: Marketing Automation

```
Cron (daily) or BullMQ repeatable job
  → MarketingWorker scans for trigger conditions:
    - Birthdays today → Campaign type: birthday
    - Last appointment > 60 days → Campaign type: reactivation
  → For each eligible client: BullMQ.marketing.add(payload)
  → Marketing worker → WhatsApp API.sendMessage() or FCM.send()
  → CampaignLog.create({ status: 'sent' })
```

## Module Build Order (Dependency Graph)

```
Layer 0: Infrastructure
  Supabase project setup (tables, RLS policies, indexes)
  Redis + BullMQ boilerplate (queue definitions, worker skeleton)
  Fastify server skeleton (plugin system, error handler, response shape)

Layer 1: Identity (prerequisite for everything)
  Auth module (Supabase Auth integration, JWT verification)
  Studio onboarding (creates tenant, sets studio_id)
  Profile management (roles: owner, professional)

Layer 2: Core Domain (can be built in parallel after Layer 1)
  Services module (ServiceCategory, Service CRUD)
  Clients module (Client CRUD, Anamnesis)
  Team module (Professional CRUD, ProfessionalService)

Layer 3: Scheduling (depends on Layer 2)
  Appointment CRUD
  Conflict detection logic (critical: must handle edge cases)
  BlockedSlot management
  Business hours enforcement

Layer 4: Async Foundation (depends on Layer 0, needed for Layer 5+)
  BullMQ workers operational
  FCM integration
  Push notification worker

Layer 5: Financial + Packages (depends on Layer 3 + 4)
  Payment recording
  Commission calculation
  Package + PackageSubscription management
  Financial dashboard

Layer 6: External Channels (depends on Layer 3 + 4)
  Public web page + self-service booking
  WhatsApp webhook handler
  WhatsApp outbound (confirmation messages)

Layer 7: AI Assistant (depends on Layer 6 + all domain services)
  LangChain agent setup + tool definitions
  Conversation + Message persistence
  AI Config per studio
  ai-response BullMQ worker
  Escalation + fallback-to-human flow

Layer 8: Marketing Automation (depends on Layer 4 + 6)
  Campaign engine
  Birthday + reactivation triggers
  CampaignLog tracking
```

## Architectural Patterns

### Pattern 1: Async-First for External I/O

**What:** Never call WhatsApp API, Anthropic, or FCM synchronously within an HTTP request cycle. Always enqueue to BullMQ and return fast.
**When to use:** Any call to a third-party API that can take > 500ms or needs retry.
**Trade-offs:** Adds complexity (queue + worker), but prevents blocked threads and enables retry.

### Pattern 2: Repository as Single DB Access Point

**What:** Services never import Supabase client directly. All DB access goes through repository classes.
**When to use:** Always. No exceptions.
**Trade-offs:** More boilerplate, but testable and swappable.

### Pattern 3: Belt-and-Suspenders Multi-Tenancy

**What:** Filter by `studio_id` in BOTH the repository query AND rely on Supabase RLS. Never trust one alone.
**When to use:** Every query, every table.
**Trade-offs:** Query-level filter is primary defense. RLS is safety net. If either fails, the other catches it.

### Pattern 4: LangChain Agent with Scoped Domain Tools

**What:** AI agent does NOT have raw SQL access. It operates via typed tool functions that call existing services/repositories with `studio_id` pre-injected from job context (not from LLM output).
**When to use:** All AI agent tool definitions.
**Trade-offs:** Prevents prompt injection from accessing cross-tenant data. Tools have built-in `studio_id` scoping — LLM cannot override it.

### Pattern 5: Graceful Degradation

**What:** Every external dependency has a defined failure behavior.

| Dependency fails | System behavior |
|-----------------|-----------------|
| Anthropic API | Send fallback message + escalate to human |
| WhatsApp API | Appointment still exists; log failure; alert owner in-app |
| Redis / BullMQ | API handles CRUD synchronously; async jobs degrade gracefully |
| FCM | Push not delivered; internal log only |

## Anti-Patterns

### Anti-Pattern 1: Synchronous LLM Calls in HTTP Handler

**What people do:** Calling Anthropic/LangChain inside a Fastify route handler.
**Why it's wrong:** Ties up HTTP thread for 1-5s, no retry, WhatsApp retries webhook → duplicate messages.
**Do this instead:** Always enqueue to `ai-response` queue, return 202 immediately.

### Anti-Pattern 2: Cross-Tenant Data Leakage via Missing studio_id

**What people do:** Repository query that filters by `client_id` without `studio_id`.
**Why it's wrong:** Phone numbers can appear across studios; returns wrong tenant's data.
**Do this instead:** Every repository method includes `.eq('studio_id', studioId)`.

### Anti-Pattern 3: Business Logic in BullMQ Workers

**What people do:** Putting conflict detection, commission calculation in worker code.
**Why it's wrong:** Logic diverges from HTTP layer. Cannot be unit tested through service layer.
**Do this instead:** Workers call the same service classes as HTTP controllers. Workers are transport, not logic.

### Anti-Pattern 4: Unbounded Conversation History to LLM

**What people do:** Re-sending full conversation history on every Anthropic call.
**Why it's wrong:** Token cost grows unboundedly. At 50+ messages, costs spike.
**Do this instead:** Load last 10-20 turns. Use Pinecone for long-term context as RAG.

### Anti-Pattern 5: Public Booking Endpoint Without Rate Limiting

**What people do:** `/public/appointments` without rate limiting.
**Why it's wrong:** Attacker floods a studio's calendar with fake bookings.
**Do this instead:** Rate limit by IP (5 bookings/hour) AND by phone (3 pending per phone). Redis counters.

## Scaling Considerations

| Scale | Architecture Adjustments |
|-------|--------------------------|
| 0-100 studios | Single Supabase instance, single BullMQ worker — fine |
| 100-1,000 studios | Supabase Pro tier, add read replica, scale worker replicas |
| 1,000-10,000 studios | Supabase Enterprise, distributed lock for calendar, worker pool per tier |

### Scaling Priorities

1. **First bottleneck:** AI response time under concurrent WhatsApp messages — scale BullMQ workers, tune Anthropic concurrency
2. **Second bottleneck:** Calendar conflict detection under high concurrency — Redis slot cache per professional per day

## AI Assistant Subsystem Detail

```
WhatsApp API (inbound)
  │
  ▼
Fastify Webhook Handler
  - Verify HMAC signature (Evolution API / Z-API)
  - Extract: phone, message, studio_id (via registered number lookup)
  - Rate limit: max 10 messages/minute per phone
  │
  ▼ enqueue (202 response returned here)
BullMQ: ai-response queue
  │
  ▼ worker
AI Response Worker
  - Load or create Conversation record
  - Load client record by phone (or mark as new/unknown)
  - Load AIConfig for studio (tone, rules, enabled flag)
  │
  ▼
LangChain Agent (studio context injected — not from LLM)
  Tools:
    check_availability(serviceId, date) → SchedulingService
    get_services(studioId) → ServiceRepository
    create_appointment(...) → AppointmentService
    cancel_appointment(appointmentId) → AppointmentService
    get_client_history(clientId) → ClientRepository
    escalate_to_human(reason) → flags Conversation + notifies owner
  │
  ▼
  - Save Message records (role: client + assistant)
  - If appointment created → emit notifications job
  - If escalated → Conversation.status = 'escalated', push to owner
  │
  ▼
WhatsApp API (outbound) — send reply
```

This subsystem can only be built after Auth, Services, Scheduling, and Clients modules are complete and stable.

## Sources

- Project documentation: docs/ARCHITECTURE.md — HIGH confidence
- Domain model: docs/DOMAIN_MODEL.md — HIGH confidence
- Architectural decisions: docs/DECISIONS_LOG.md — HIGH confidence
- LangChain.js agent/tools pattern — MEDIUM confidence (verify against current docs during AI phase)
- BullMQ patterns — MEDIUM confidence (verify current API)

---
*Architecture research for: beauty salon scheduling SaaS*
*Researched: 2026-03-12*
