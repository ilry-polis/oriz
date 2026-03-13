# Project Research Summary

**Project:** Oriz — Agenda Inteligente para Profissionais de Beleza
**Domain:** Beauty salon scheduling SaaS with WhatsApp AI assistant
**Researched:** 2026-03-12
**Confidence:** HIGH

## Executive Summary

Oriz is a multi-tenant SaaS product for Brazilian beauty professionals — solo estheticians and studio owners — that replaces fragmented manual workflows (spreadsheets, informal WhatsApp, paper) with an integrated scheduling platform. The market is well-served by legacy competitors (Trinks, Booksy, Salão99) with outdated UX and zero AI capability, which creates a clear differentiation window. The recommended approach is to build a layered system with a Fastify/Node.js/TypeScript backend on Supabase, a Flutter mobile app for professionals, a Next.js public booking page for clients, and an asynchronous AI assistant powered by LangChain.js and Anthropic Claude delivered through WhatsApp. The entire product must be multi-tenant from day one, with `studio_id` enforced at both query and RLS levels.

The architecture follows a strict dependency graph: infrastructure (auth, database, RLS) must precede core domain (services, clients, team), which must precede scheduling, which must precede the AI assistant. The WhatsApp AI is the killer feature and the primary reason for product-market differentiation, but it is also the most complex component and must be built last — after every underlying domain module is stable and tested. Building the AI before the domain is solid will produce an unreliable assistant that destroys professional trust before the product can prove its value.

The main risks are: race conditions in concurrent booking across channels (DB-level unique index is non-negotiable), WhatsApp unofficial API bans (provider abstraction from day one with Meta Cloud API failover ready), cross-tenant data leakage (belt-and-suspenders: query filter + RLS, integration tests for every repository method), and LLM hallucinating available slots (atomic check-and-book tool, never split). Timezone handling and money storage (integer centavos) must also be locked in at infrastructure phase — both are impossible to safely migrate after data accumulates.

## Key Findings

### Recommended Stack

The stack is already well-defined in project documentation and aligns with best practices for this product type. Fastify v5 on Node.js 22 LTS provides the performance headroom needed at scale; Supabase handles managed PostgreSQL, Auth, Realtime, and Storage without additional infrastructure overhead. BullMQ over Redis is the right choice for async jobs (AI responses, notifications, marketing) because it prevents blocking HTTP threads on slow third-party APIs. Flutter 3.22+ with Riverpod and GoRouter covers the mobile app; Next.js 14 with App Router is mandatory for the public booking page (Flutter Web has no SEO and fails the first-impression test). Asaas is the correct payment gateway for the Brazilian market — PIX-native, boleto support, and automatic commission splits outweigh Stripe's international reach for a Brazil-focused v1.

**Core technologies:**
- Fastify v5 + TypeScript: HTTP framework — schema-based validation, 2x faster than Express, TypeScript-first
- Supabase (PostgreSQL + Auth + Realtime + Storage): managed data layer — eliminates separate database/auth infrastructure
- BullMQ + Redis: async job queues — keeps HTTP responses fast, enables retry/DLQ for AI and notification jobs
- Flutter 3.22+ (Riverpod + GoRouter): mobile app — cross-platform, native performance, Supabase Realtime subscriptions
- Next.js 14 App Router: public booking page — SSR/ISR essential for SEO, link-in-bio for Instagram
- LangChain.js + Anthropic SDK: AI agent — tool-calling orchestration, conversation memory, RAG via Pinecone
- Asaas: payments — PIX-native, boleto, split automático for the Brazilian market
- Evolution API (with Meta Cloud API failover): WhatsApp — must be abstracted behind strategy interface

### Expected Features

The feature dependency graph is clear: Auth/Onboarding enables everything; Services/Clients/Team can be built in parallel; Scheduling depends on those; WhatsApp AI depends on all of them being solid. Marketing automation depends on WhatsApp being operational.

**Must have (table stakes):**
- Auth + Studio onboarding — first experience defines retention
- Service catalog (name, price, duration, buffer time) — prerequisite for scheduling
- Agenda visual with conflict detection — core of the product, race condition prevention required
- Client management with anamnesis — digital "caderninho", table stakes for any beauty professional
- Push notifications for confirmations and cancellations — reduces no-show and keeps professional informed
- Public studio page (oriz.app/slug) + self-service booking — client-facing scheduling without WhatsApp

**Should have (competitive differentiators):**
- WhatsApp AI assistant — the killer feature, no competitor has it; schedules, reschedules, cancels, answers questions
- Package management with session deduction on completion (not booking) — better than competitors' weak implementations
- Team + commission splits — eliminates the Excel spreadsheet for studio owners (Persona 2)
- Financial dashboard with occupancy rate — business intelligence no legacy competitor provides
- Marketing automation: birthday campaigns + client reactivation (>60 days inactive)
- Configurable AI personality per studio — professional feels the AI is "hers"
- Source tracking per appointment (AI vs web vs app vs manual)

**Defer (v2+):**
- Dashboard web admin — mobile is sufficient; professional lives on her phone
- OAuth/social login — email/password is sufficient for v1; add if conversion metrics justify
- Marketplace — entirely different business model, evaluates separately
- Multi-unit (filiais) support — add if studio chains emerge in user base
- Exportable reports — visual dashboard is what this audience actually uses

### Architecture Approach

The architecture is a layered monolith with async-first I/O: a Fastify API handles all business logic through Route → Controller → Service → Repository layers, with BullMQ workers processing all external I/O (AI calls, WhatsApp, FCM) outside the HTTP request cycle. Flutter connects directly to Supabase only for Auth, Realtime (used as a trigger to re-fetch, not as a data source), and Storage; all CRUD goes through the Fastify API. Multi-tenancy is enforced at both the application layer (every repository query includes `.eq('studio_id', studioId)`) and the database layer (Supabase RLS policies). The AI subsystem runs entirely through BullMQ workers: webhook handler returns 202 immediately, worker loads context, LangChain agent calls domain tools (which are themselves scoped to `studio_id` from job context — never from LLM output), and sends the WhatsApp reply.

**Major components:**
1. Fastify API — all business logic, validation, orchestration; never calls LLM synchronously
2. Supabase (PostgreSQL + RLS) — multi-tenant data persistence; service_role key only on backend
3. BullMQ workers — async processing for AI responses, notifications, and marketing jobs
4. LangChain AI Agent — tool-calling orchestration; studio_id injected from job context, not LLM
5. WhatsApp provider (Evolution API / strategy pattern) — inbound webhooks + outbound replies
6. Flutter mobile app — UI and local state only; no business logic; Realtime as trigger only
7. Next.js public page — SEO-optimized client-facing booking, ISR for slot availability

### Critical Pitfalls

1. **Double-booking race condition** — Use a unique partial index on `(professional_id, date, start_time) WHERE status != 'cancelled'` and an atomic INSERT WHERE NOT EXISTS pattern. Application-level conflict check alone is insufficient when multiple booking channels (AI, web, app) run concurrently. Must be in place before any booking channel goes live.

2. **WhatsApp unofficial API ban** — Abstract provider behind a strategy interface from day one. Have Meta Cloud API ready as failover. Never burst-send; warm up volume gradually. A ban mid-launch-event can destroy the demo and professional trust.

3. **RLS bypass via service_role key** — Belt-and-suspenders: both query-level `studio_id` filter AND RLS policies. Integration tests must assert cross-tenant isolation for every repository method (create data in Studio A, query as Studio B, assert empty result).

4. **LLM hallucinating available slots** — Make `create_appointment` an atomic tool (check availability + create in one call). Never expose a suggest-slot tool that doesn't verify real-time. System prompt must mandate `check_availability` before every slot suggestion. Tests must verify tool call sequence.

5. **Timezone blindness** — `TIMESTAMPTZ` everywhere in PostgreSQL, never plain `TIMESTAMP`. Store `Studio.timezone` from onboarding. Store in UTC, display in studio timezone. Use `date-fns-tz` for all conversions. Brazil has multiple timezones and unpredictable DST changes.

## Implications for Roadmap

The architecture research identifies 8 clear dependency layers that directly map to roadmap phases. The build order is non-negotiable — skipping layers produces runtime failures that are expensive to fix retroactively (timezone migrations, RLS retrofits, AI hallucinations from unstable domain data).

### Phase 1: Infrastructure Foundation
**Rationale:** All subsequent phases depend on this being solid. Timezone decisions and RLS policies cannot be safely retrofitted after data accumulates.
**Delivers:** Supabase project with schema, RLS policies, and cross-tenant isolation tests; Redis + BullMQ boilerplate with queue definitions; Fastify server skeleton with error handling, response shape, and plugin system.
**Avoids:** Timezone blindness (TIMESTAMPTZ from day 1), RLS bypass (policies before any data module), double-booking race condition (DB constraint before any booking channel).
**Research flag:** Standard patterns — no deeper research needed.

### Phase 2: Identity and Onboarding
**Rationale:** Auth and tenant creation are prerequisites for every domain module. Onboarding quality defines retention.
**Delivers:** Supabase Auth integration, JWT verification middleware, studio creation (tenant), and professional roles (owner, professional). Wizard for studio data, services, and business hours.
**Addresses:** Auth + onboarding (table stakes), studio timezone field (critical infrastructure).
**Research flag:** Standard patterns — Supabase Auth is well-documented.

### Phase 3: Core Domain — Services, Clients, Team
**Rationale:** These three modules can be built in parallel after auth. They have no dependency on each other and are prerequisites for scheduling.
**Delivers:** Service catalog (category, price, duration, buffer_time), Client CRUD with anamnesis templates, Team/Professional management with ProfessionalService mapping.
**Avoids:** Phone number duplicates (E.164 normalization + unique constraint in client module), LGPD consent (marketing_consent field defaults FALSE from day one).
**Research flag:** Standard patterns — well-understood CRUD with RLS. No deeper research needed.

### Phase 4: Scheduling Engine
**Rationale:** Depends on services, clients, and team being complete. Conflict detection is not a separate feature — it is part of the scheduling engine itself.
**Delivers:** Appointment CRUD with status workflow, atomic conflict detection with DB-level unique index, blocked slot management, business hours enforcement.
**Avoids:** Double-booking race condition (unique partial index + atomic INSERT), N+1 queries on agenda view (eager join for client + service data).
**Research flag:** Conflict detection atomicity pattern warrants review during planning — verify PostgreSQL advisory locks vs. unique index approach for the specific Supabase client SDK version.

### Phase 5: Async Foundation — Notifications
**Rationale:** BullMQ workers must be operational before external channels (WhatsApp, public page) are built, since both produce notification jobs.
**Delivers:** BullMQ workers operational, FCM integration, push notification worker with retry policy and DLQ, in-app notification fallback.
**Avoids:** Job failures swallowing confirmed bookings (DLQ + retry + fallback notification in place before any channel goes live).
**Research flag:** Standard patterns — BullMQ documentation is clear.

### Phase 6: Financial and Packages
**Rationale:** Depends on scheduling being complete (commissions calculated from completed appointments). Packages depend on services and clients.
**Delivers:** Payment recording, commission calculation (integer centavos), package + PackageSubscription with session deduction on appointment completion, financial dashboard.
**Avoids:** Floating-point money (all values stored as integer centavos), package session deducted on booking instead of completion.
**Research flag:** Asaas SDK integration may need deeper research during planning — verify current SDK version and PIX split API.

### Phase 7: External Channels — Public Page and WhatsApp Outbound
**Rationale:** Scheduling and async foundation must be complete before external channels are exposed. WhatsApp provider abstraction must be built here, before AI integration.
**Delivers:** Next.js public studio page with ISR, self-service booking endpoint (rate-limited by IP and phone), WhatsApp provider strategy interface, outbound confirmation messages.
**Avoids:** WhatsApp API ban (provider abstraction from day 1 in this phase), public booking endpoint without rate limiting, slug conflicts (unique index + auto-append on onboarding).
**Research flag:** WhatsApp provider integration (Evolution API v2 + Meta Cloud API failover) needs deeper research during planning — API authentication, webhook signature verification, and outbound message formatting have version-specific gotchas.

### Phase 8: AI Assistant
**Rationale:** Must be last. AI reads real data from all domain modules. Unstable or incomplete domain data produces hallucinations that destroy professional trust before the product can prove its value.
**Delivers:** LangChain agent with studio-scoped tools (check_availability, create_appointment, cancel_appointment, get_services, get_client_history, escalate_to_human), Conversation + Message persistence, AIConfig per studio (personality, rules), ai-response BullMQ worker, escalation to human flow.
**Avoids:** LLM hallucinating slots (atomic check-and-book tool), business hours not enforced by AI (check_availability enforces hours, not just conflicts), unbounded conversation history (last 10-20 turns + Pinecone RAG).
**Research flag:** This phase REQUIRES `/gsd:research-phase` during planning — LangChain.js tool-calling API, Anthropic tool-use format, Pinecone vs pgvector decision, and agent prompt engineering patterns all need verification against current documentation.

### Phase 9: Marketing Automation
**Rationale:** Depends on WhatsApp (Phase 7) and clients (Phase 3) being complete. Marketing messages require an operational outbound channel and verified consent data.
**Delivers:** Campaign engine with BullMQ repeatable jobs, birthday trigger, client reactivation trigger (>60 days inactive), CampaignLog tracking, configurable message templates per studio.
**Avoids:** LGPD marketing consent violation (marketing_consent checked before every send), marketing messages via WhatsApp before channel is stable.
**Research flag:** Standard patterns — marketing automation logic is straightforward once WhatsApp channel is operational.

### Phase Ordering Rationale

- Phases 1-2 are non-negotiable first: infrastructure decisions (timezone, RLS, schema) cannot be safely changed after data accumulates. Identity is required by every other module.
- Phases 3-4 follow the feature dependency graph exactly: services/clients/team must exist before scheduling can reference them; conflict detection must be in scheduling from the start, not added later.
- Phase 5 (async foundation) is intentionally placed before external channels: notification workers must be tested in isolation before WhatsApp and the public page start producing notification events.
- Phase 6 (financial) can overlap with Phase 7 development — they share no direct dependencies — but the roadmap lists them sequentially to keep scope manageable.
- Phase 8 (AI) is locked to last position. This is the most important ordering constraint in the entire roadmap. Any attempt to build AI earlier will result in an unstable assistant operating on incomplete domain data.
- Phase 9 (marketing) follows AI because the two share the WhatsApp outbound channel and marketing quality improves when AI conversation data is available for targeting.

### Research Flags

Phases requiring deeper research during planning:
- **Phase 7 (WhatsApp integration):** Evolution API v2 webhook signature verification, rate limiting specifics, Meta Cloud API failover setup, and message formatting. Unofficial API behavior changes frequently.
- **Phase 8 (AI Assistant):** LangChain.js current tool-calling API, Anthropic tool-use JSON schema format, Pinecone vs pgvector decision (depends on expected embedding volume at launch), agent system prompt structure, and conversation windowing strategy.

Phases with standard patterns (research-phase not needed):
- **Phase 1 (Infrastructure):** PostgreSQL schema, RLS policies, Supabase setup — well-documented.
- **Phase 2 (Identity):** Supabase Auth + JWT — standard, official SDK handles complexity.
- **Phase 3 (Core Domain):** CRUD with RLS — established patterns, no novel problems.
- **Phase 5 (Async Foundation):** BullMQ workers, FCM — official documentation is current and clear.
- **Phase 9 (Marketing):** Cron-based campaign engine — straightforward once WhatsApp is operational.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Validated against existing project docs (CLAUDE.md, ARCHITECTURE.md, DECISIONS_LOG.md); technology choices are well-reasoned and specific to Brazilian market requirements |
| Features | HIGH | Competitor analysis (Trinks, Booksy, Salão99) is concrete; feature dependencies are documented; MVP scope is well-defined with anti-features explicitly called out |
| Architecture | HIGH | Based on existing project architecture documentation; component boundaries, data flows, and anti-patterns are detailed and specific |
| Pitfalls | HIGH | Pitfalls are concrete, specific to this domain, and mapped to prevention phases; race condition, RLS, and LLM hallucination mitigations are actionable |

**Overall confidence:** HIGH

### Gaps to Address

- **Pinecone vs pgvector decision:** Research recommends Pinecone for scale but acknowledges pgvector (available via Supabase) may be sufficient if embedding volume stays below ~100k vectors. Validate during Phase 8 planning based on projected launch volume.
- **LangChain.js tool-calling API:** Marked MEDIUM confidence in ARCHITECTURE.md — API surface has changed across versions. Verify current `@langchain/core v0.2` and `@langchain/anthropic v0.2` tool-calling patterns before implementing Phase 8.
- **Asaas SDK integration specifics:** Commission split configuration and PIX webhook flow need validation against current Asaas SDK documentation during Phase 6 planning.
- **Evolution API v2 production behavior:** Rate limits, number warm-up requirements, and ban detection heuristics are not officially documented. Validate with community sources or direct testing before Phase 7.
- **Multi-unit (filiais) support:** Not in v1 scope but the data model should not make this impossible. Validate that `studio_id` as the sole tenant key doesn't create a structural blocker for eventual multi-unit support.

## Sources

### Primary (HIGH confidence)
- Project CLAUDE.md — stack decisions, architecture rules, domain map
- docs/ARCHITECTURE.md — component responsibilities, data flows, anti-patterns
- docs/DOMAIN_MODEL.md — domain entities and relationships
- docs/DECISIONS_LOG.md — technology choices with rationale
- docs/PRD.md — product requirements and persona definitions

### Secondary (MEDIUM confidence)
- Fastify v5, BullMQ v5, LangChain.js official documentation — technology patterns
- Asaas vs Stripe comparison for Brazilian market — payment gateway selection
- Competitor analysis: Trinks, Booksy, Salão99, TuaAgenda — feature benchmarking

### Tertiary (LOW confidence — needs validation)
- Evolution API / Z-API behavior under high volume — WhatsApp ban risk assessment
- LangChain.js tool-calling patterns — marked MEDIUM in ARCHITECTURE.md, needs current docs verification
- Pinecone free tier limits and pgvector production performance comparison

---
*Research completed: 2026-03-12*
*Ready for roadmap: yes*
