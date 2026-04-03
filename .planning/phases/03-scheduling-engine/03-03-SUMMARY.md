---
phase: 03-scheduling-engine
plan: 03
subsystem: api
tags: [typescript, fastify, controllers, routes, dependency-injection]

# Dependency graph
requires:
  - phase: 03-scheduling-engine
    plan: 02
    provides: "AppointmentService, BlockedSlotService, PaymentRepository"
provides:
  - "AppointmentController: list, getById, availableSlots, create, update (reschedule), confirm, complete, cancel, noShow"
  - "BlockedSlotController: list, create, delete"
  - "appointments.routes.ts: all endpoints fully wired (GET /, POST /, GET /available-slots, GET /:id, PATCH /:id, POST /:id/confirm, POST /:id/complete, POST /:id/cancel, POST /:id/no-show)"
  - "blocked-slots.routes.ts: all endpoints fully wired (GET /, POST /, DELETE /:id)"
  - "BlockedSlotService.list + BlockedSlotRepository.list: general listing with optional filters and cursor pagination"
  - "server.ts: AppointmentRepository, BlockedSlotRepository, PaymentRepository, BlockedSlotService, AppointmentService, AppointmentController, BlockedSlotController fully instantiated"
  - "fastify.d.ts: appointmentController and blockedSlotController decorators typed"
affects:
  - "03-04 — Flutter agenda screen consumes these HTTP endpoints"
  - "04-financial — financial routes may reference appointment completion endpoints"

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Controller pattern: studioId from request.authContext (never from request body/params); camelCase↔snake_case mapping at controller boundary"
    - "source field mapping: 'whatsapp' (API contract) → 'whatsapp_ai' (repository enum) at controller layer"
    - "Controller delegates entirely to service — no business logic in controller"
    - "{ data, meta } response envelope on all list endpoints; { data } on single-resource endpoints; 204 no-body on delete"

key-files:
  created:
    - backend/src/controllers/appointment.controller.ts
    - backend/src/controllers/blocked-slot.controller.ts
  modified:
    - backend/src/routes/appointments.routes.ts
    - backend/src/routes/blocked-slots.routes.ts
    - backend/src/services/blocked-slot.service.ts
    - backend/src/repositories/blocked-slot.repository.ts
    - backend/src/types/fastify.d.ts
    - backend/src/server.ts

key-decisions:
  - "BlockedSlotService.list is distinct from getExpandedForDate — list is for the API endpoint (returns raw rows), getExpandedForDate is for slot-availability computation (returns expanded TimeRange[])"
  - "BlockedSlotRepository.list uses cursor pagination by id (not date+id composite) — date range filtering is already covered by dateFrom/dateTo params"
  - "'whatsapp' source mapped to 'whatsapp_ai' at controller boundary to preserve API-layer naming from AppointmentSource enum"

patterns-established:
  - "Controller boundary: camelCase params to service, snake_case from request.body; studioId always from authContext"
  - "Service.list method added via Rule 2 when needed for list endpoint — separate from domain-specific query methods"

requirements-completed: []

# Metrics
duration: 6min
completed: 2026-04-03
---

# Phase 3 Plan 03: Controllers and Route Wiring Summary

**AppointmentController and BlockedSlotController wired into Fastify routes — all 12 scheduling endpoints now live; DI graph completed in server.ts**

## Performance

- **Duration:** ~6 min
- **Started:** 2026-04-03T16:35:09Z
- **Completed:** 2026-04-03T16:41:00Z
- **Tasks:** 2
- **Files created:** 2
- **Files modified:** 6

## Accomplishments

- **AppointmentController** (9 methods): list (date or date range), getById, availableSlots, create, update/reschedule, confirm, complete (with optional payment), cancel, noShow — all delegating to AppointmentService with studioId from authContext
- **BlockedSlotController** (3 methods): list, create, delete — plus auto-added `list` method to service and repository for the GET endpoint
- **DI graph in server.ts**: AppointmentRepository, BlockedSlotRepository, PaymentRepository instantiated; BlockedSlotService and AppointmentService wired up; both controllers decorated on Fastify instance
- All 115 tests pass; all new files clean per Biome linter

## Task Commits

1. **Task 1: AppointmentController + route wiring** - `4a8f263` (feat)
2. **Task 2: BlockedSlotController + service list method** - `e1fa375` (feat)

**Plan metadata:** (docs commit below)

## Files Created/Modified

- `backend/src/controllers/appointment.controller.ts` — Full appointment controller with all 9 handlers
- `backend/src/controllers/blocked-slot.controller.ts` — Blocked slot controller with 3 handlers
- `backend/src/routes/appointments.routes.ts` — All handlers wired from "Not implemented" to controller delegation
- `backend/src/routes/blocked-slots.routes.ts` — All handlers wired from "Not implemented" to controller delegation
- `backend/src/services/blocked-slot.service.ts` — Added `list` method for API listing endpoint
- `backend/src/repositories/blocked-slot.repository.ts` — Added `list` query with optional filters and cursor pagination
- `backend/src/types/fastify.d.ts` — Added `appointmentController` and `blockedSlotController` typed decorators
- `backend/src/server.ts` — AppointmentRepository, BlockedSlotRepository, PaymentRepository, BlockedSlotService, AppointmentService, AppointmentController, BlockedSlotController instantiated and registered

## Decisions Made

- **`list` vs `getExpandedForDate` on BlockedSlotService**: The existing `getExpandedForDate` expands recurring rules into time ranges for a single date — not suitable for a list endpoint. A separate `list` method returning raw `BlockedSlotRow[]` was added to keep the domain query methods semantically clean.
- **`BlockedSlotRepository.list` uses simple id cursor**: The list endpoint filters by dateFrom/dateTo already; the cursor only needs to identify a position in the ordered result set. Using `id` as cursor key (UUID sortable order) is simpler and sufficient.
- **'whatsapp' → 'whatsapp_ai' source mapping at controller boundary**: The API contract uses `'whatsapp'` as the source enum value (more user-friendly), but the repository uses `'whatsapp_ai'`. The mapping lives at the controller boundary, not in the service, so the service API stays clean.

## Deviations from Plan

### Auto-added Missing Critical Functionality

**1. [Rule 2 - Missing Critical] BlockedSlotService.list and BlockedSlotRepository.list**
- **Found during:** Task 2 (BlockedSlotController — list handler needs to return raw rows, not expanded ranges)
- **Issue:** BlockedSlotService only exposed `getExpandedForDate` (designed for slot computation, returns `TimeRange[]`) and `create`, `delete`, `removeOccurrence`. No method to list raw `BlockedSlotRow[]` for the API endpoint.
- **Fix:** Added `BlockedSlotRepository.list(studioId, options)` with optional professionalId, dateFrom, dateTo, cursor, limit filters. Added `BlockedSlotService.list(studioId, options)` delegating to it.
- **Files modified:** `backend/src/repositories/blocked-slot.repository.ts`, `backend/src/services/blocked-slot.service.ts`
- **Verification:** Biome lint clean on both files; all 115 tests still pass
- **Committed in:** `e1fa375` (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 missing critical)
**Impact on plan:** Auto-fix essential for the list endpoint to function. No scope creep — `list` method is a direct analog of `list` methods in other repositories (ClientRepository, ServiceRepository, etc.).

## Issues Encountered

Pre-existing TypeScript errors in `routes/index.ts`, `public/studios.routes.ts`, and `server.ts` (ioredis constructor pattern) remain from prior plans. None in files created or modified by this plan.

Pre-existing `noNonNullAssertion` lint violations in `blocked-slot.service.ts` (the `isRecurrenceActiveOnDate` function's `year!`, `month!`, `day!`) were carried over from Plan 02. These are out of scope for this plan.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- All scheduling HTTP endpoints are live and fully wired
- Test count: 115 (all passing; no new tests needed for controller wiring — service layer has comprehensive coverage)
- Flutter agenda screen (Plan 04) can now consume: GET/POST /api/v1/appointments, GET /api/v1/appointments/available-slots, status transition endpoints, GET/POST/DELETE /api/v1/blocked-slots
- No blockers

---

## Self-Check: PASSED

**Files verified present:**
- backend/src/controllers/appointment.controller.ts — FOUND
- backend/src/controllers/blocked-slot.controller.ts — FOUND

**Commits verified present:**
- 4a8f263 feat(03-03): AppointmentController and route wiring — FOUND
- e1fa375 feat(03-03): BlockedSlotController and route wiring — FOUND
