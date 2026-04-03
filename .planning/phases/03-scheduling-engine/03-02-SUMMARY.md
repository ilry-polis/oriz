---
phase: 03-scheduling-engine
plan: 02
subsystem: backend-services
tags: [typescript, vitest, tdd, status-machine, scheduling, recurrence, availability]

# Dependency graph
requires:
  - phase: 03-scheduling-engine
    plan: 01
    provides: "AppointmentRepository, BlockedSlotRepository, UnprocessableError"
  - phase: 02-core-domain
    provides: "professionals, services tables and repository patterns"
provides:
  - "BlockedSlotService: getExpandedForDate, create, delete, removeOccurrence"
  - "AppointmentService: createAppointment, confirmAppointment, completeAppointment, cancelAppointment, markNoShow, reschedule, listByDate, listByDateRange, getById, getAvailableSlots"
  - "PaymentRepository: create"
  - "ProfessionalRepository.getById(studioId, professionalId)"
  - "ServiceRepository.getById(studioId, serviceId)"
affects:
  - "03-03 — Controllers will call AppointmentService and BlockedSlotService"
  - "03-04 — Flutter agenda screen consumes available slots and appointment status workflow"

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "VALID_TRANSITIONS map: explicit status machine — illegal transitions throw UnprocessableError INVALID_STATUS_TRANSITION"
    - "TDD: RED (failing test) -> GREEN (minimal implementation) -> compile check cycle"
    - "UTC date parsing for day-of-week: new Date(Date.UTC(y, m-1, d)) avoids timezone drift"
    - "15-minute slot intervals within working_hours ranges; slots excluded via half-open interval overlap [start, end)"
    - "PaymentRepository records to existing payments table on appointment completion"

key-files:
  created:
    - backend/src/services/blocked-slot.service.ts
    - backend/src/services/appointment.service.ts
    - backend/src/repositories/payment.repository.ts
    - backend/tests/services/blocked-slot.service.test.ts
    - backend/tests/services/appointment.service.test.ts
  modified:
    - backend/src/repositories/professional.repository.ts
    - backend/src/repositories/service.repository.ts

key-decisions:
  - "Slot interval: 15-minute granularity for getAvailableSlots — balances precision with array size"
  - "end_time = startTime + duration_minutes + buffer_minutes — buffer included in appointment span, not as a separate gap"
  - "PaymentRepository created as separate repository — payments table already exists in initial schema (001_initial_schema.sql)"
  - "ProfessionalRepository.getById and ServiceRepository.getById added as Rule 2 auto-additions — required for working hours and service duration lookups"

# Metrics
duration: 5min
completed: 2026-04-03
---

# Phase 3 Plan 02: AppointmentService and BlockedSlotService Summary

**Status machine, recurrence expansion, available slot calculation, and payment recording implemented with TDD — 51 tests green across both services**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-04-03T16:27:57Z
- **Completed:** 2026-04-03T16:32:23Z
- **Tasks:** 2 (BlockedSlotService, AppointmentService)
- **Tests added:** 51 (16 + 35)
- **Files created/modified:** 7

## Accomplishments

- **BlockedSlotService** (16 tests): `getExpandedForDate` expands recurring blocked slots for a target date using UTC day-of-week matching; handles sporadic absences, weekly recurrence rules, `until` dates, and `excluded_dates`; `create`, `delete` (with NotFoundError), `removeOccurrence`
- **AppointmentService** (35 tests): Status machine with explicit VALID_TRANSITIONS map; `createAppointment` validates working hours and blocked slots before delegating to repository (which catches concurrent conflicts via exclusion constraint); `getAvailableSlots` generates 15-minute intervals within working_hours, excluding occupied time ranges; `completeAppointment` optionally records payment via PaymentRepository
- **PaymentRepository**: thin repository wrapping the existing `payments` table; used by `completeAppointment`
- **ProfessionalRepository.getById** and **ServiceRepository.getById**: added as required lookups for working hours validation and service duration/buffer calculation

## Task Commits

1. **Task 1: BlockedSlotService + tests** - `fb73205` (feat)
2. **Task 2: AppointmentService + tests + supporting repositories** - `994833b` (feat)

**Plan metadata:** (docs commit below)

## Files Created/Modified

- `backend/src/services/blocked-slot.service.ts` — Recurrence expansion logic with UTC date parsing
- `backend/src/services/appointment.service.ts` — Full scheduling business logic with status machine
- `backend/src/repositories/payment.repository.ts` — Payment creation for existing payments table
- `backend/tests/services/blocked-slot.service.test.ts` — 16 tests covering recurrence logic
- `backend/tests/services/appointment.service.test.ts` — 35 tests covering all service behaviors
- `backend/src/repositories/professional.repository.ts` — Added `getById` method
- `backend/src/repositories/service.repository.ts` — Added `getById` method

## Decisions Made

- **15-minute slot granularity**: `getAvailableSlots` steps in 15-minute intervals — flexible enough for most beauty services without generating excessive data
- **Buffer included in appointment span**: `end_time = startTime + duration + buffer`. The buffer is part of the appointment's exclusion window; it is not rendered in the UI but is enforced in conflict detection
- **PaymentRepository is separate**: payments already have their own table with `studio_id` — clean separation, no columns added to appointments

## Deviations from Plan

### Auto-added Missing Critical Functionality

**[Rule 2 — Missing Critical] ProfessionalRepository.getById**
- **Found during:** Task 2 (AppointmentService — needs working_hours for slot validation)
- **Issue:** ProfessionalRepository only had `findByUserId` and `updateWorkingHours` — no method to fetch by ID for service-level use
- **Fix:** Added `getById(studioId, professionalId)` with explicit column list and studio_id filter
- **Files modified:** `backend/src/repositories/professional.repository.ts`
- **Commit:** `994833b`

**[Rule 2 — Missing Critical] ServiceRepository.getById**
- **Found during:** Task 2 (AppointmentService — needs duration_minutes and buffer_minutes for end_time calculation)
- **Issue:** ServiceRepository only had `create` — no read method
- **Fix:** Added `getById(studioId, serviceId)` with explicit column list and studio_id filter
- **Files modified:** `backend/src/repositories/service.repository.ts`
- **Commit:** `994833b`

**[Rule 1 — Bug Fix] Removed unused ConflictError import**
- **Found during:** Task 2 TypeScript build check
- **Issue:** `ConflictError` was imported but not used in `appointment.service.ts` (service re-throws from repo layer without wrapping)
- **Fix:** Removed from import statement
- **Files modified:** `backend/src/services/appointment.service.ts`
- **Commit:** `994833b`

## Issues Encountered

Pre-existing TypeScript errors in `routes/index.ts`, `public/studios.routes.ts`, and `server.ts` remain (26 errors total). None in files created or modified by this plan. These were documented in 03-01-SUMMARY.md.

## User Setup Required

None.

## Next Phase Readiness

- Service layer is ready for Plan 03: Controllers + route wiring (AppointmentController, BlockedSlotController)
- Test count: 115 total (64 pre-existing + 51 new)
- No blockers

---

## Self-Check: PASSED

**Files verified present:**
- backend/src/services/appointment.service.ts — FOUND
- backend/src/services/blocked-slot.service.ts — FOUND
- backend/tests/services/appointment.service.test.ts — FOUND
- backend/tests/services/blocked-slot.service.test.ts — FOUND
- backend/src/repositories/payment.repository.ts — FOUND
- backend/src/repositories/professional.repository.ts — FOUND
- backend/src/repositories/service.repository.ts — FOUND

**Commits verified present:**
- fb73205 feat(03-02): BlockedSlotService with recurrence expansion — FOUND
- 994833b feat(03-02): AppointmentService with status machine and slot availability — FOUND

---
*Phase: 03-scheduling-engine*
*Completed: 2026-04-03*
