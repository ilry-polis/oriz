---
phase: 03-scheduling-engine
plan: 01
subsystem: database
tags: [postgres, supabase, migrations, repository, typescript, gist-exclusion, recurrence]

# Dependency graph
requires:
  - phase: 02-core-domain
    provides: clients, professionals, services tables and repository patterns
provides:
  - "appointments table with pending status and no_show-aware exclusion constraint"
  - "blocked_slots table with title, recurrence_rule JSONB, excluded_dates support"
  - "AppointmentRepository: listByDate, listByDateRange, listByProfessionalDate, getById, create, updateStatus, update"
  - "BlockedSlotRepository: listByDateRange, create, delete, addExcludedDate"
  - "UnprocessableError (422) in errors.ts"
  - "RecurrenceRuleSchema exported from blocked-slots.routes.ts"
affects:
  - "03-02 — AppointmentService depends on these repositories"
  - "03-03 — AvailabilityService depends on listByProfessionalDate and BlockedSlotRepository"
  - "03-04 — Status transitions (confirm, complete, cancel, no_show) use updateStatus"

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Repository pattern: Pool injection, typed Row+Input interfaces, explicit columns, studio_id filter on every query"
    - "Cursor pagination: (start_time, id) composite sort key for stable ordering"
    - "pg error code 23P01 (exclusion constraint violation) mapped to ConflictError TIME_SLOT_TAKEN"
    - "Dynamic SET clause builder for partial update without ORM"

key-files:
  created:
    - supabase/migrations/010_add_pending_status.sql
    - supabase/migrations/011_blocked_slots_absences.sql
    - backend/src/repositories/appointment.repository.ts
    - backend/src/repositories/blocked-slot.repository.ts
  modified:
    - backend/src/utils/errors.ts
    - backend/src/routes/blocked-slots.routes.ts

key-decisions:
  - "no_show excluded from appointments_no_overlap constraint — rebooking a no-show slot is valid behavior"
  - "Recurring blocked slots returned wholesale from listByDateRange — expansion to individual dates is responsibility of the service layer (consumer), not the repository"
  - "confirmation_hours_before added to studios now (Phase 5.1/6 will consume it) — cheaper than a later migration"

patterns-established:
  - "Repository file per domain (appointment.repository.ts, blocked-slot.repository.ts)"
  - "ConflictError on pg 23P01 exclusion violation — service layer re-throws or wraps"
  - "Joined AppointmentRow includes denormalized client_name, professional_name, service_name — avoids N+1 at call sites"

requirements-completed: [SCHD-02, SCHD-03, SCHD-04]

# Metrics
duration: 3min
completed: 2026-04-03
---

# Phase 3 Plan 01: DB Foundation and Repository Layer Summary

**Appointments and blocked_slots schema extended with pending status, no_show-aware exclusion constraint, and recurrence support; typed repository layer with conflict detection ready for service layer**

## Performance

- **Duration:** 3 min
- **Started:** 2026-04-03T16:21:30Z
- **Completed:** 2026-04-03T16:24:46Z
- **Tasks:** 2
- **Files modified:** 6

## Accomplishments

- Two SQL migrations: pending status + revised exclusion constraint + studios.confirmation_hours_before; absence fields (title, recurrence_rule, excluded_dates) on blocked_slots
- AppointmentRepository with full CRUD, cursor pagination, JOIN queries to clients/professionals/services, and overlap conflict detection mapped from pg error 23P01
- BlockedSlotRepository with support for sporadic and recurring absences, excluded date append for single-occurrence removal
- UnprocessableError (422) added to errors.ts; RecurrenceRuleSchema added to blocked-slots routes

## Task Commits

1. **Task 1: DB migrations — pending status, revised constraint, absence fields** - `14f9954` (feat)
2. **Task 2: Appointment and BlockedSlot repositories** - `8ef5d29` (feat)

**Plan metadata:** TBD (docs commit)

## Files Created/Modified

- `supabase/migrations/010_add_pending_status.sql` — Adds pending status, revises exclusion constraint to exclude no_show, adds confirmation_hours_before to studios
- `supabase/migrations/011_blocked_slots_absences.sql` — Adds title, recurrence_rule JSONB, excluded_dates, and recurrence index to blocked_slots
- `backend/src/repositories/appointment.repository.ts` — Full appointment repository with typed interfaces, JOINs, cursor pagination, conflict error mapping
- `backend/src/repositories/blocked-slot.repository.ts` — Blocked slot repository with RecurrenceRule interface and excluded_date management
- `backend/src/utils/errors.ts` — Added UnprocessableError class (422)
- `backend/src/routes/blocked-slots.routes.ts` — Added RecurrenceRuleSchema and title/recurrence fields to CreateBlockedSlotBody

## Decisions Made

- **no_show excluded from overlap constraint** — A no-show slot frees the time for rebooking. This matches the business requirement that missed appointments don't permanently block a professional's availability.
- **Recurring slots returned wholesale** — `listByDateRange` returns recurring blocked slots unconditionally; the service layer (Plan 02/03) expands recurrence and applies date filters. This keeps the repository simple and delegation clear.
- **confirmation_hours_before added early** — Added to `studios` table in this migration rather than waiting for Phase 5.1 since it's directly related to appointment behavior and avoids a trivial future migration.

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

Pre-existing TypeScript errors in `routes/index.ts`, `public/studios.routes.ts`, and `server.ts` were present before this plan (26 errors total). None in files created or modified by this plan.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- Repository layer is ready for Plan 02: AppointmentService (create, reschedule, cancel, complete, no-show) and Plan 03: AvailabilityService (slot calculation, business hours enforcement)
- Migrations need to be applied to Supabase project before running integration tests
- No blockers

---
*Phase: 03-scheduling-engine*
*Completed: 2026-04-03*
