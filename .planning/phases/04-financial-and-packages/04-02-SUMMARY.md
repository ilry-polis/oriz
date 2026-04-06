---
phase: 04-financial-and-packages
plan: 02
subsystem: api
tags: [postgres, fastify, commission, financial, payments, tdd]

# Dependency graph
requires:
  - phase: 04-financial-and-packages
    provides: "DB migration with commissions table, payments table, financial_summaries view (plan 01)"
  - phase: 03-scheduling-engine
    provides: "AppointmentRepository, PaymentRepository, appointments table"
provides:
  - "CommissionRepository: CRUD for commissions table with cursor pagination"
  - "FinancialRepository: materialized view query + live queries (day/week)"
  - "CommissionService: calculate commission (percentage/fixed, 3 fee policies, monthly/biweekly periods)"
  - "FinancialService: summary routing, occupancy rate, breakdowns by professional/service"
  - "PaymentRepository.list(): paginated with JOINs to appointments/clients/professionals"
  - "GET /api/v1/financial/summary — KPI endpoint (revenue, avg ticket, occupancy)"
  - "GET /api/v1/financial/breakdown/professionals — ranked breakdown"
  - "GET /api/v1/financial/breakdown/services — ranked breakdown"
  - "GET /api/v1/commissions — paginated list"
  - "POST /api/v1/commissions/pay — mark as paid"
  - "GET /api/v1/commissions/summary — grouped by professional"
  - "GET /api/v1/payments — paginated with JOINs"
affects: [04-03-packages-session-deduction, 05-whatsapp-ai]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "TDD: RED (failing tests) → GREEN (implementation) → REFACTOR (biome lint fix)"
    - "commission_value stored in basis points (e.g., 4000 = 40.00%) for integer-safe percentage math"
    - "Card fee computed from basis points: amount * bps / 10000, Math.round at final step only"
    - "Occupancy rate: professional.working_hours JSON parsed per-day, compared to completed appointment minutes"
    - "FinancialService.summary routes to materialized view (month) or live query (day/week)"
    - "PaymentRepository.list returns limit+1 rows; controller slices and sets has_more"

key-files:
  created:
    - backend/src/repositories/commission.repository.ts
    - backend/src/repositories/financial.repository.ts
    - backend/src/services/commission.service.ts
    - backend/src/services/financial.service.ts
    - backend/src/controllers/financial.controller.ts
    - backend/src/controllers/commission.controller.ts
    - backend/src/controllers/payment.controller.ts
    - backend/tests/services/commission.service.test.ts
    - backend/tests/services/financial.service.test.ts
  modified:
    - backend/src/repositories/payment.repository.ts
    - backend/src/repositories/appointment.repository.ts
    - backend/src/routes/financial.routes.ts
    - backend/src/routes/commissions.routes.ts
    - backend/src/routes/payments.routes.ts
    - backend/src/server.ts
    - backend/src/types/fastify.d.ts

key-decisions:
  - "commission_value in basis points (not percentage float) ensures integer math throughout commission calculation"
  - "FinancialService.summary routes day/week to live query, month to materialized view — balances freshness vs performance"
  - "Occupancy rate computed on-demand from working_hours JSON + completed appointments — no caching needed at this scale"
  - "financial.routes.ts changed from requireOwner to requireStudioMember (professionals can see dashboard data)"
  - "PaymentController delegates to FinancialService.listPayments (not a separate PaymentService) — kept flat"

patterns-established:
  - "Commission calculation: fetch professional + studio settings → compute fee → apply policy → calc amount → determine period → persist"
  - "Cursor pagination in controllers: query limit+1, slice to limit, set has_more + next_cursor"
  - "AppointmentRepository.listCompletedByDateRange: lightweight query (no full row) for occupancy computation"

requirements-completed: [FINC-01, FINC-02, FINC-03, FINC-04]

# Metrics
duration: 35min
completed: 2026-04-05
---

# Phase 4 Plan 02: Financial and Commission Backend Summary

**Revenue dashboard KPIs (day/week/month), occupancy rate, breakdowns by professional/service, and commission calculation (percentage/fixed, 3 fee policies, monthly/biweekly periods) via Fastify REST API**

## Performance

- **Duration:** ~35 min
- **Started:** 2026-04-05T16:16:03Z
- **Completed:** 2026-04-05T16:22:32Z
- **Tasks:** 2
- **Files modified:** 16

## Accomplishments

- Commission calculation service handles all business rules: percentage vs fixed types, 3 card-fee policies (studio absorbs/professional absorbs/split), monthly and biweekly period boundaries — all tested with 24 passing tests
- Financial summary API routes correctly to materialized view (month = pre-computed) or live query (day/week = real-time from payments table)
- Occupancy rate computed from professional working_hours JSON across all days in range vs completed appointment minutes
- All 3 route groups wired: GET /financial/summary, GET/POST /commissions, GET /payments — build passes, 244/246 tests pass

## Task Commits

Each task was committed atomically:

1. **Task 1 RED: Failing tests** — `0605616` (test)
2. **Task 1 GREEN: Repositories + Services** — `645e057` (feat)
3. **Task 2: Controllers + routes + server** — `5a5c8cb` (feat)

## Files Created/Modified

- `backend/src/repositories/commission.repository.ts` — CRUD for commissions table (create, list paginated, markPaid, sumByProfessional)
- `backend/src/repositories/financial.repository.ts` — materialized view query, live query, breakdown by professional/service
- `backend/src/repositories/payment.repository.ts` — extended with list() method (JOINs to appointments/clients/professionals)
- `backend/src/repositories/appointment.repository.ts` — added listCompletedByDateRange() for occupancy computation
- `backend/src/services/commission.service.ts` — calculateAndRecord, list, markPaid, sumByProfessional, getPeriodBoundaries helper
- `backend/src/services/financial.service.ts` — summary (with routing logic), occupancyRate, breakdowns, listPayments
- `backend/src/controllers/financial.controller.ts` — summary (KPI + occupancy), breakdownByProfessional, breakdownByService
- `backend/src/controllers/commission.controller.ts` — list, pay, sumByProfessional
- `backend/src/controllers/payment.controller.ts` — list (delegates to financialService.listPayments)
- `backend/src/routes/financial.routes.ts` — rewritten: requireStudioMember, period/date params, 3 routes
- `backend/src/routes/commissions.routes.ts` — wired all 3 routes to controller
- `backend/src/routes/payments.routes.ts` — wired to PaymentController
- `backend/src/server.ts` — instantiate CommissionRepo, FinancialRepo, CommissionService, FinancialService, 3 controllers
- `backend/src/types/fastify.d.ts` — added financialController, commissionController, paymentController
- `backend/tests/services/commission.service.test.ts` — 13 tests covering all calculation scenarios
- `backend/tests/services/financial.service.test.ts` — 11 tests covering summary routing, occupancy, breakdowns

## Decisions Made

- `commission_value` stored in basis points (e.g., 4000 = 40.00%) — consistent with card_fee_rates format, avoids float arithmetic in centavo calculations
- `FinancialService.summary` routes to materialized view for month (pre-computed, fast), live query for day/week (real-time, acceptable latency)
- `financial.routes.ts` changed from `requireOwner` to `requireStudioMember` so collaborators can view their dashboard data
- `PaymentController` delegates to `FinancialService.listPayments` — avoids creating an unnecessary PaymentService layer

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Added AppointmentRepository.listCompletedByDateRange()**
- **Found during:** Task 1 (FinancialService.occupancyRate implementation)
- **Issue:** FinancialService.occupancyRate needs to sum completed appointment durations, but AppointmentRepository had no method for this — only full row queries with all JOINs
- **Fix:** Added lightweight `listCompletedByDateRange()` — single JOIN to services (for duration_minutes), returns only `{ duration_minutes }`, filters by studio_id + date range + status='completed'
- **Files modified:** `backend/src/repositories/appointment.repository.ts`
- **Verification:** FinancialService.occupancyRate tests pass; build passes
- **Committed in:** `645e057` (Task 1 implementation commit)

---

**Total deviations:** 1 auto-fixed (Rule 2 — missing critical method for correctness)
**Impact on plan:** Necessary for FinancialService.occupancyRate to function. No scope creep — single lightweight query method.

## Issues Encountered

- 2 pre-existing failures in `invite.service.test.ts` (TypeError on supabaseAdmin mock structure) — confirmed pre-existing before our changes, out of scope

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- CommissionService.calculateAndRecord is ready to be called from Plan 03 (completeAppointment flow)
- Financial summary endpoints ready for mobile dashboard integration
- PaymentRepository.list ready for payments history screen
- Concern: commissions table requires DB migration from Plan 01 to be applied to real DB before endpoints return real data

## Self-Check: PASSED

All 9 created files found on disk. All 3 task commits verified in git log.

---
*Phase: 04-financial-and-packages*
*Completed: 2026-04-05*
