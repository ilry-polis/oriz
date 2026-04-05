---
phase: 04-financial-and-packages
plan: "03"
subsystem: appointment-completion
tags: [appointment, packages, commission, payment, split-payment, discount, bullmq]
dependency_graph:
  requires: [04-01, 04-02]
  provides: [complete-appointment-flow]
  affects: [appointments, payments, commissions, package_subscriptions, financial_summaries]
tech_stack:
  added: [bullmq]
  patterns: [tdd-red-green, optional-dependencies, deduplication-jobid, in-process-fallback]
key_files:
  created:
    - backend/src/jobs/financial-refresh.job.ts
  modified:
    - backend/src/services/appointment.service.ts
    - backend/src/controllers/appointment.controller.ts
    - backend/src/routes/appointments.routes.ts
    - backend/src/server.ts
    - backend/tests/services/appointment.service.test.ts
decisions:
  - "completeAppointment now returns { appointment, lastSession?, sessionsRemaining? } — break from old AppointmentRow return type"
  - "BullMQ queue uses jobId=studioId for deduplication; in-process fallback uses Map<studioId, setTimeout> with 5s debounce"
  - "New dependencies (commissionService, packageSubRepo, etc.) are optional constructor params for backward compatibility"
  - "Discount fully applied to first payment row in split payments (not proportionally split)"
metrics:
  duration: "~15 minutes"
  completed_date: "2026-04-05"
  tasks: 2
  files_changed: 6
---

# Phase 4 Plan 03: Appointment Completion Integration Summary

Integrates package session deduction, commission calculation, discount enforcement, split payment, and async financial view refresh into the existing appointment completion flow.

## What Was Built

Extended `completeAppointment()` in `AppointmentService` to be the integration hub connecting packages (Plan 01) and financial (Plan 02) into the appointment lifecycle.

**Package path:** When `packageSubscriptionId` is provided, atomically deducts a session via `packageSubRepo.deductSession`. If the subscription is expired/completed, throws `PACKAGE_UNAVAILABLE`. Calculates commission on the package's per-session unit price using `paymentMethod = 'package'`. Returns `{ appointment, lastSession, sessionsRemaining }` for UI feedback.

**Payment path:** Accepts an `ExtendedPaymentParams` payload with `payments[]` (1-2 entries for split), `discountAmount`, and `discountReason`. For non-owner roles, enforces `max_discount_percentage` from studio settings — throws `DISCOUNT_EXCEEDS_LIMIT` if exceeded. Creates one payment row per entry (discount applied to first row). Calculates commission on `totalAmount - discountAmount`. Enqueues async financial summary view refresh.

**FinancialRefreshQueue:** New `backend/src/jobs/financial-refresh.job.ts` with `FinancialRefreshQueue` interface. BullMQ implementation uses Redis when available (jobId = studioId for deduplication). In-process fallback uses a `Map<studioId, setTimeout>` with 5-second debounce when Redis is unavailable.

## Task Commits

| Task | Description | Commit |
|------|-------------|--------|
| 1+2 | completeAppointment + BullMQ job + controller + route schema + tests | 63b8715 |

Note: Tasks 1 and 2 were implemented together in a single TDD cycle. Tests were written first (RED), then implementation made them pass (GREEN).

## Tests Added

12 new test cases covering:
- Package deduction happy path (sessions remaining)
- Package last session (returns `lastSession=true`)
- Package expired/completed subscription (throws `PACKAGE_UNAVAILABLE`)
- Commission on package unit price
- No payment row created for package appointments
- Payment with discount — commission on net amount
- Split payment (2 entries) — creates 2 payment rows
- Split payment commission on total net amount
- Financial view refresh enqueued after payment
- Discount limit enforcement for professional role
- Owner can exceed discount limit
- Discount within limit succeeds for professional

All 47 appointment tests pass. Full suite: 256/258 pass (2 pre-existing failures unrelated to this plan).

## Deviations from Plan

None — plan executed exactly as written.

The two failing tests (`invite.service.test.ts` and `service.repository.test.ts`) are pre-existing failures confirmed to exist before this plan's changes.

## Key Decisions Made

1. **Return type change:** `completeAppointment` now returns `{ appointment, lastSession?, sessionsRemaining? }` instead of `AppointmentRow` directly. Controller maps this to `{ data: result }`. This is a breaking change handled by updating the controller and tests.

2. **Optional constructor params:** New dependencies (`commissionService`, `packageSubRepo`, etc.) are optional to maintain backward compatibility with existing instantiation patterns in tests.

3. **Discount on first payment row:** In split payments, the full discount is applied to the first payment row (`discountAmount` on row 0, 0 on subsequent rows). This simplifies reporting while maintaining correct totals.

4. **In-process fallback debounce:** 5-second timeout per studio — multiple rapid completions for the same studio only trigger one view refresh.

## Self-Check: PASSED

Files created:
- backend/src/jobs/financial-refresh.job.ts — FOUND

Files modified:
- backend/src/services/appointment.service.ts — FOUND
- backend/src/controllers/appointment.controller.ts — FOUND
- backend/src/routes/appointments.routes.ts — FOUND
- backend/src/server.ts — FOUND
- backend/tests/services/appointment.service.test.ts — FOUND

Commit 63b8715 — FOUND
