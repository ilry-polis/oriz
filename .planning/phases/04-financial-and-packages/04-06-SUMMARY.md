---
phase: 04-financial-and-packages
plan: 06
subsystem: ui
tags: [flutter, riverpod, packages, payment, discount, split-payment, booking-flow, mobile]

# Dependency graph
requires:
  - phase: 04-01
    provides: Package subscription API and extended appointment complete endpoint
  - phase: 04-03
    provides: Backend completeAppointment with payments array, discount, package_subscription_id
  - phase: 04-04
    provides: Financial dashboard UI
  - phase: 04-05
    provides: Package management UI, PackageRepository, PackageSubscriptionModel
provides:
  - QuickBookSheet package detection — checkbox "Usar pacote (X/Y sessoes)" pre-checked when active subscription found
  - PaymentSheet with discount (R$/%, reason chips, strikethrough preview) and split payment (2 methods)
  - Package-aware completion flow: skip PaymentSheet, toast feedback, last-session renewal dialog
  - AppointmentDetailSheet converted to ConsumerStatefulWidget with _completeAppointment flow
  - AgendaNotifier.completeAppointmentFull supporting packageSubscriptionId, payments, discount
  - AppointmentRepository.completeFull returning raw Map<String, dynamic> response
affects: [agenda-flow, booking-flow, payment-flow, phase-05-whatsapp, any future analytics]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - Live package check at completion time (not stored in Appointment model) — avoids stale state
    - PaymentEntry value-class holding method+amountController pair for split payment
    - SegmentedButton for R$/% discount toggle
    - CompleteAppointmentFull returns Map<String,dynamic> so caller can inspect lastSession/sessionsRemaining
    - ConsumerStatefulWidget with async _completeAppointment dispatching to either package path or PaymentSheet

key-files:
  created: []
  modified:
    - mobile/lib/features/agenda/widgets/quick_book_sheet.dart
    - mobile/lib/features/agenda/widgets/payment_sheet.dart
    - mobile/lib/features/agenda/widgets/appointment_detail_sheet.dart
    - mobile/lib/features/agenda/providers/agenda_provider.dart
    - mobile/lib/features/agenda/repositories/appointment_repository.dart

key-decisions:
  - "Package check at completion time via live API call (not stored in Appointment model) — avoids stale data"
  - "Split payment uses two _PaymentEntry objects, both sent as payments[] array to backend"
  - "Discount section collapsed by default — expands on tap, shows strikethrough original price"
  - "Last-session renewal is TODO (dialog stub) — full renewal flow deferred to future phase"
  - "AppointmentDetailSheet converted to ConsumerStatefulWidget to hold _completingWithPackage bool state"

patterns-established:
  - "Package-aware flow: check active sub → if found skip payment → if last session show renewal dialog"
  - "Payment sheet pattern: amount + method + optional discount + optional second method"

requirements-completed: [SERV-04, FINC-05]

# Metrics
duration: 20min
completed: 2026-04-05
---

# Phase 4 Plan 6: Booking and Payment Flow Integration Summary

**Package-aware booking (checkbox in QuickBookSheet), payment sheet with discount and split, and package-aware completion flow that auto-deducts sessions and shows last-session renewal dialog**

## Performance

- **Duration:** ~20 min
- **Started:** 2026-04-05T19:50:00Z
- **Completed:** 2026-04-05T20:10:00Z
- **Tasks:** 1 (Task 2 is human-verify checkpoint — awaiting verification)
- **Files modified:** 5

## Accomplishments

- QuickBookSheet extended: after client + service selected, calls `packageRepository.getActiveForClientService()` and shows `CheckboxListTile` "Usar pacote (N/M sessoes)" pre-checked; unchecking reverts to avulso flow
- PaymentSheet rewritten: discount section (collapsed by default) with R$/% SegmentedButton, amount field, reason chips (Cortesia/Fidelidade/Pacote) + freetext, strikethrough original price preview; split payment via second `_PaymentEntry` added with "+ Adicionar metodo" button
- AppointmentDetailSheet converted from `ConsumerWidget` to `ConsumerStatefulWidget`; `_completeAppointment()` checks for active package live at completion time and either (a) deducts session with toast feedback and shows renewal dialog on last session, or (b) falls back to PaymentSheet
- AgendaNotifier gained `completeAppointmentFull()` method returning `Map<String, dynamic>` for inspecting `lastSession` and `sessionsRemaining`
- AppointmentRepository gained `completeFull()` method sending extended body to `POST /appointments/:id/complete`

## Task Commits

1. **Task 1: Package-aware booking/completion + payment discount and split** — `00ec136` (feat)
2. **Fix: format payment.repository.ts with Biome** — `1d53925` (chore)

## Files Modified

- `mobile/lib/features/agenda/widgets/quick_book_sheet.dart` — package detection state + _checkActivePackage() + _buildPackageSection()
- `mobile/lib/features/agenda/widgets/payment_sheet.dart` — full rewrite: _PaymentEntry, discount section, split payment
- `mobile/lib/features/agenda/widgets/appointment_detail_sheet.dart` — ConsumerStatefulWidget conversion, _completeAppointment(), _showLastSessionDialog()
- `mobile/lib/features/agenda/providers/agenda_provider.dart` — completeAppointmentFull() method
- `mobile/lib/features/agenda/repositories/appointment_repository.dart` — completeFull() method

## Decisions Made

- Package check done at completion time (live API call) rather than storing packageSubscriptionId in Appointment model — avoids stale data and keeps the model clean
- Two `_PaymentEntry` objects hold method+amountController for split payment; both sent as `payments[]` to backend
- Discount section is collapsed by default; strikethrough preview shown when discount > 0
- Last-session renewal stub: shows dialog with "Renovar pacote" button but defers actual renewal creation to a future phase

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] AppointmentDetailSheet was ConsumerWidget, needed state for _completingWithPackage**
- **Found during:** Task 1
- **Issue:** The original `AppointmentDetailSheet` was a `ConsumerWidget` (stateless). The package completion flow needs a `_completingWithPackage` bool to show "Concluindo..." label during async operation.
- **Fix:** Converted to `ConsumerStatefulWidget` + `ConsumerState`.
- **Files modified:** `appointment_detail_sheet.dart`
- **Commit:** `00ec136`

## Issues Encountered

- `flutter analyze` run after Task 1 — passes with zero errors

## User Setup Required

None — no external service configuration required for this plan.

## Next Phase Readiness

- Phase 4 Wave 3 is functionally complete pending human verification (Task 2)
- The only incomplete item is the package renewal flow (`TODO` in `_showLastSessionDialog`) — deferred to a future phase
- Ready for Phase 5 (WhatsApp) after verification

## Self-Check: PASSED

All 5 modified files verified on disk. Commits 00ec136 and 1d53925 verified in git log.

---
*Phase: 04-financial-and-packages*
*Completed: 2026-04-05*
