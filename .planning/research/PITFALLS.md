# Pitfalls Research

**Domain:** Beauty salon scheduling SaaS with WhatsApp AI assistant
**Researched:** 2026-03-12
**Confidence:** HIGH

## Critical Pitfalls

### Pitfall 1: Double-Booking Race Condition

**What goes wrong:**
Two concurrent bookings (WhatsApp AI + web page + app) hitting the same slot simultaneously. Both pass conflict check, both insert — profissional tem dois clientes no mesmo horário.

**Why it happens:**
Check-then-insert pattern without atomic guarantee. Conflict detection is a SELECT followed by an INSERT with a time gap between them.

**How to avoid:**
- Atomic `INSERT WHERE NOT EXISTS` pattern
- Unique partial index on `(professional_id, date, start_time) WHERE status != 'cancelled'`
- Database-level constraint, not application-level check alone

**Warning signs:**
- Conflict detection only in application code (no DB constraint)
- Tests that don't simulate concurrent requests

**Phase to address:**
Phase 1 (Infrastructure + Scheduling) — must be in place before ANY booking channel exists.

---

### Pitfall 2: WhatsApp Unofficial API Ban

**What goes wrong:**
Evolution API / Z-API violate Meta Terms of Service. A spike in messages post-event (400-700 new users) can trigger a ban of the studio's WhatsApp number mid-demo.

**Why it happens:**
Unofficial APIs use reverse-engineered protocols. Meta detects bulk messaging patterns and bans numbers without warning.

**How to avoid:**
- Abstract the WhatsApp provider behind an interface (strategy pattern)
- Have official Meta Cloud API ready as failover
- Use official API for the launch event demo
- Rate limit outbound messages per number
- Gradual ramp-up of message volume, never burst

**Warning signs:**
- No provider abstraction layer
- All eggs in one API basket
- Message volume spikes without warm-up

**Phase to address:**
Phase with WhatsApp integration — provider abstraction from day 1.

---

### Pitfall 3: RLS Bypass via Service Role Key

**What goes wrong:**
Backend uses Supabase `service_role` key which bypasses ALL RLS. One missing `.eq('studio_id', ...)` filter in a repository method leaks another tenant's data — LGPD violation.

**Why it happens:**
Developers trust RLS as the only guard, but service_role key bypasses it. Or they trust query-level filter only and don't configure RLS.

**How to avoid:**
- Belt-and-suspenders: BOTH query-level `studio_id` filter AND RLS policies
- Integration tests that assert cross-tenant isolation for EVERY repository method
- Test pattern: create data in Studio A, query as Studio B, assert empty result

**Warning signs:**
- No cross-tenant isolation tests
- Repository methods without `studio_id` parameter
- "RLS will handle it" reasoning without query-level filter

**Phase to address:**
Phase 1 (Infrastructure) — RLS policies and test patterns established before any data module.

---

### Pitfall 4: LLM Agent Hallucinating Available Slots

**What goes wrong:**
AI suggests a slot it "remembers" from earlier in the conversation without re-calling `check_availability`. Creates confirmed bookings for already-filled slots. Profissional perde confiança na IA.

**Why it happens:**
LLM caches context from previous tool calls and responds from "memory" instead of making a fresh availability check. Tool description doesn't mandate re-check.

**How to avoid:**
- Tool description must mandate `check_availability` call before EVERY slot suggestion
- `create_appointment` must be one atomic tool (check + create), not a two-step
- Never expose a "suggest slot" tool that doesn't verify in real-time
- System prompt: "ALWAYS call check_availability before suggesting or confirming any time slot"

**Warning signs:**
- Separate "check" and "book" tools instead of atomic
- AI responding with times without tool calls in the trace
- Tests that don't verify tool call sequence

**Phase to address:**
AI phase — tool design is critical architecture decision.

---

### Pitfall 5: Timezone Blindness

**What goes wrong:**
Storing datetimes as naive `TIMESTAMP` instead of `TIMESTAMPTZ`. Silent breakage when any timezone context shifts (server migration, DST change, client in different timezone).

**Why it happens:**
Brazil has multiple timezones (Brasília, Manaus, Fernando de Noronha). Developer assumes all users are in same timezone. DST changes in Brazil are unpredictable.

**How to avoid:**
- `TIMESTAMPTZ` everywhere in PostgreSQL — no exceptions
- `Studio.timezone` field (e.g., 'America/Sao_Paulo')
- `date-fns-tz` for all timezone conversions in backend
- Store in UTC, display in studio's timezone
- Test with studios in different timezones

**Warning signs:**
- `TIMESTAMP` without `TZ` in any migration
- Datetime comparisons without timezone conversion
- No timezone field on studio entity

**Phase to address:**
Phase 1 (Infrastructure) — impossible to migrate safely after data accumulates.

---

## Moderate Pitfalls

### Pitfall 6: Business Hours Not Enforced by AI

**What goes wrong:**
AI agent books appointments outside business hours because it doesn't have access to or doesn't check business hour rules.

**How to avoid:**
- `check_availability` tool must enforce business hours, not just check for conflicts
- Include business hours in AI context/tools

**Phase to address:** AI phase.

---

### Pitfall 7: Floating-Point Money in Commission Splits

**What goes wrong:**
Commission of 40% on R$ 79,90 = R$ 31,96... floating point creates rounding errors. Over time, centavos accumulate into real discrepancies.

**How to avoid:**
- Store all monetary values as integers (centavos): R$ 79,90 = 7990
- All math in centavos, convert to reais only for display
- Explicit rounding rule: studio always gets the remainder centavo

**Phase to address:** Financial module phase.

---

### Pitfall 8: Phone Number Duplicates Across Booking Channels

**What goes wrong:**
Client books via WhatsApp (phone: +5579999001234), then books via web page (phone: 79999001234). System creates two client records — history splits.

**How to avoid:**
- Normalize all phone numbers on input (E.164 format: +55...)
- Deduplicate by normalized phone + studio_id
- Match client by phone on all booking channels

**Phase to address:** Client module (Phase 1).

---

### Pitfall 9: BullMQ Job Failures Swallowing Confirmed Bookings

**What goes wrong:**
Appointment created successfully, but notification job fails. Client never gets confirmation. Professional never knows about the booking.

**How to avoid:**
- Appointment is committed to DB before job is enqueued
- Retry policy on notification jobs (3 retries, exponential backoff)
- Dead letter queue with alerting
- In-app notification as fallback when push/WhatsApp fails

**Phase to address:** Async foundation phase.

---

### Pitfall 10: Supabase Realtime Partial Payloads

**What goes wrong:**
Realtime subscription receives partial or out-of-order updates, causing Flutter agenda view to show stale or corrupted data.

**How to avoid:**
- Treat Realtime as a trigger, not a data source — on change event, re-fetch from API
- Never build UI state solely from Realtime payloads
- Debounce rapid updates

**Phase to address:** Mobile app development.

---

### Pitfall 11: LGPD Marketing Consent Not Captured

**What goes wrong:**
Marketing messages sent without explicit consent. Client complains. Legal liability.

**How to avoid:**
- `marketing_consent` boolean on client record, default FALSE
- Consent captured at booking time (checkbox on web page, explicit question from AI)
- Marketing worker MUST check consent before sending

**Phase to address:** Client module + Marketing module.

---

## Minor Pitfalls

### Pitfall 12: Missing Service Buffer Time

**What goes wrong:**
Service duration is 60 min but professional needs 15 min cleanup between clients. Back-to-back bookings with no gap.

**How to avoid:**
- `buffer_time` field on service (default 0, configurable)
- Conflict detection considers `duration + buffer_time`

---

### Pitfall 13: Returning Clients with New Phone Number

**What goes wrong:**
Client changes phone number. AI creates a new client record. History lost.

**How to avoid:**
- Allow manual client merge by professional
- Secondary lookup by name + approximate match for AI

---

### Pitfall 14: Package Sessions Deducted on Booking Instead of Completion

**What goes wrong:**
Session deducted when booked. Client cancels. Session lost.

**How to avoid:**
- Deduct session only when appointment status = 'completed'
- Not on booking, not on confirmation

---

### Pitfall 15: N+1 Queries on Agenda View

**What goes wrong:**
Agenda day view loads 15 appointments, each triggers separate query for client + service data. 45+ queries for one screen.

**How to avoid:**
- Eager join in appointment query: include client name, service name, duration
- Single query with joins, not separate lookups

---

### Pitfall 16: Slug Conflicts on Studio Public URLs

**What goes wrong:**
Two studios named "Studio Bella" both want oriz.app/studio-bella.

**How to avoid:**
- Unique index on slug
- Auto-append number if conflict: studio-bella-2
- Validate slug on onboarding

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Skip integration tests for RLS | Faster development | Cross-tenant leak risk | Never |
| Hardcode timezone to São Paulo | Simpler code | Breaks for studios fora de Brasília | Never — add timezone field from start |
| Store money as float | Simpler DB schema | Rounding errors in commissions | Never — use integer centavos |
| Single WhatsApp provider (no abstraction) | Faster integration | Cannot switch if banned | Only for initial prototype, abstract before launch |
| Skip rate limiting on public endpoints | Faster to deploy | Calendar spam attacks | Only in dev, must have before any public exposure |

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| Evolution API / Z-API | Trusting single unofficial provider | Provider abstraction + official API failover |
| Supabase Auth | Using service_role key in Flutter app | anon key in Flutter, service_role only in backend |
| Supabase Realtime | Building UI state from Realtime events | Use as trigger → re-fetch from API |
| FCM | Not handling token refresh | Store token per device, refresh on app start |
| Anthropic API | Sending unbounded context | Window last 10-20 turns, RAG for history |
| Asaas/Stripe | Storing payment data | Never store — delegate entirely to gateway |

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Double-booking race condition | Infrastructure/Scheduling | Concurrent booking test passes |
| WhatsApp API ban | WhatsApp integration | Provider abstraction exists, failover tested |
| RLS bypass | Infrastructure | Cross-tenant isolation tests for every repo method |
| LLM hallucinating slots | AI phase | Tool call trace shows check_availability before every booking |
| Timezone blindness | Infrastructure | TIMESTAMPTZ in all migrations, studio.timezone exists |
| Business hours not enforced by AI | AI phase | AI cannot book outside business hours |
| Floating-point money | Financial module | All money stored as integer centavos |
| Phone number duplicates | Client module | E.164 normalization + unique constraint |
| Job failures swallowing bookings | Async foundation | DLQ + retry policy + fallback notification |
| LGPD consent | Client + Marketing | marketing_consent field, checked before send |

## Sources

- Project PRD: docs/PRD.md
- Architecture decisions: docs/DECISIONS_LOG.md
- Domain model: docs/DOMAIN_MODEL.md
- Brazilian market specifics (timezone, LGPD, WhatsApp dominance)
- WhatsApp unofficial API risk analysis

---
*Pitfalls research for: beauty salon scheduling SaaS*
*Researched: 2026-03-12*
