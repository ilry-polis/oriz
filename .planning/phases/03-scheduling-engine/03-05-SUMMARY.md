---
phase: 03-scheduling-engine
plan: 05
subsystem: ui
tags: [flutter, riverpod, dart, booking-flow, payment, bottom-sheet, autocomplete]

# Dependency graph
requires:
  - phase: 03-scheduling-engine
    plan: 04
    provides: "AppointmentRepository (searchClients, createClient, getServicesForProfessional, getAvailableSlots, create, complete, cancel), AgendaNotifier (createAppointment, completeAppointment, cancelAppointment, markNoShow, confirmAppointment), Appointment model with fromJson and status helpers"
provides:
  - "QuickBookSheet: client search autocomplete, service picker filtered by professional, available slot chips, notes, POST /api/v1/appointments on confirm"
  - "PaymentSheet: editable amount + 4-method selection (Dinheiro/PIX/Debito/Credito), calls completeAppointment"
  - "AppointmentDetailSheet: client, service, time, professional, status badge, contextual action buttons by status"
  - "CancelDialog: AlertDialog with optional reason field, calls cancelAppointment"
  - "agenda_day_screen.dart wired: empty slot tap → QuickBookSheet, appointment tap → AppointmentDetailSheet, swipe complete → PaymentSheet, cancel → CancelDialog"
affects:
  - "03-06 — CreateAbsenceSheet stub wired to long-press empty slot (plan 06 implements full absence creation)"

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Client search: debounced autocomplete (300ms Timer) + inline new-client quick form (name+phone)"
    - "Slot conflict prevention: API slots fetched after service selection; occupied slots shown disabled; inline error on manual time conflict — conflict never reaches backend"
    - "PaymentSheet opens from completeAppointment swipe — keeps payment capture in-flow without separate navigation"
    - "DetailSheet drives all status transitions: delegates to PaymentSheet (complete), CancelDialog (cancel), notifier directly (confirm, no-show)"

key-files:
  created:
    - mobile/lib/features/agenda/widgets/quick_book_sheet.dart
    - mobile/lib/features/agenda/widgets/payment_sheet.dart
    - mobile/lib/features/agenda/widgets/appointment_detail_sheet.dart
    - mobile/lib/features/agenda/widgets/cancel_dialog.dart
  modified:
    - mobile/lib/features/agenda/agenda_day_screen.dart

key-decisions:
  - "QuickBookSheet is the single booking entry point — both slot tap (pre-filled time) and [+] button use it; professionalId comes from agendaState.selectedProfessionalId"
  - "Amount in PaymentSheet is editable (pre-filled from service price) — handles discounts applied at checkout without API contract change"
  - "CancelDialog moved from inline in AppointmentCard to standalone widget — reusable from both AppointmentCard swipe and AppointmentDetailSheet"
  - "AppointmentDetailSheet uses ConsumerWidget not ConsumerStatefulWidget — all actions are one-shot, no local mutable state needed"

patterns-established:
  - "Action sheets: ConsumerStatefulWidget with _submitting bool, HapticFeedback, ApiException catch with user-friendly snackbar"
  - "Read-only detail: ConsumerWidget (no state), contextual buttons via appointment.canX helpers"

requirements-completed: [SCHD-01, SCHD-02, SCHD-04]

# Metrics
duration: 19min
completed: 2026-04-03
---

# Phase 3 Plan 05: Booking, Payment, and Detail Sheets Summary

**Booking sheet with client search autocomplete + slot picker, payment method selection sheet, appointment detail view with contextual actions, and cancel dialog — all four connected to real API via agendaNotifier**

## Performance

- **Duration:** ~19 min
- **Started:** 2026-04-03T19:48:16Z
- **Completed:** 2026-04-03T20:07:00Z
- **Tasks:** 2
- **Files created:** 4
- **Files modified:** 1

## Accomplishments

- **QuickBookSheet refactored**: Mock chips replaced with real client search autocomplete (300ms debounce), inline "Novo cliente" quick form (name + phone), service list filtered by professional from API, available slot chips (occupied = disabled + strikethrough), TimePicker fallback, inline "Horario indisponivel" error, creates appointment via provider on confirm
- **PaymentSheet**: 2x2 grid of payment method cards with animated selection border, editable amount pre-filled from service price, calls `completeAppointment(id, amountCents, method)` on confirm
- **AppointmentDetailSheet**: Shows all appointment fields with icons, StatusBadge, contextual action buttons by status (pending: Confirmar+Cancelar; confirmed: Concluir+Cancelar+Nao compareceu; terminal: Fechar only)
- **CancelDialog**: AlertDialog with optional reason TextField, replaces plan 04's inline implementation
- **AgendaDayScreen wired**: Empty slot tap → `QuickBookSheet.show` (pre-filled hour), [+] button → `QuickBookSheet.show`, appointment card tap → `AppointmentDetailSheet.show`, swipe-complete → `PaymentSheet.show`, cancel swipe → `CancelDialog.show`

## Task Commits

1. **Task 1: Booking sheet refactor with client search and slot suggestions** - `56b338a` (feat)
2. **Task 2: Payment sheet, appointment detail sheet, cancel dialog** - `28e6d9b` (feat)

## Files Created/Modified

- `mobile/lib/features/agenda/widgets/quick_book_sheet.dart` — Full booking flow: client search, service picker, slot picker, notes, API create
- `mobile/lib/features/agenda/widgets/payment_sheet.dart` — Payment method selection + editable amount on appointment completion
- `mobile/lib/features/agenda/widgets/appointment_detail_sheet.dart` — Appointment detail view with contextual status-aware action buttons
- `mobile/lib/features/agenda/widgets/cancel_dialog.dart` — Cancel confirmation dialog with optional reason field
- `mobile/lib/features/agenda/agenda_day_screen.dart` — Wired slot tap, [+] button, card tap, swipe actions to the new sheets

## Decisions Made

- **Editable amount in PaymentSheet**: Service price pre-fills the amount but user can override (e.g. applied discount). Stored in cents, displayed in R$ format.
- **Single QuickBookSheet entry point**: Both empty slot tap (pre-filled hour) and [+] header button open the same sheet — minimizes surface area and keeps booking UX consistent.
- **CancelDialog as standalone widget**: Extracted from the inline implementation in plan 04's agenda screen so both the swipe action and detail sheet can reuse it without duplication.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Plan 04 ran in parallel and changed the Appointment model and repository**
- **Found during:** Task 1 setup
- **Issue:** Plan 04 committed models, repositories, and providers that plan 05 depends on. Their committed versions differed from what was present at the start (models had `pending` status, `fromJson`, `canX` helpers; repository had `searchClients`, `createClient`, `getServicesForProfessional`)
- **Fix:** Used plan 04's committed versions as-is; no duplication needed
- **Impact:** Plan 05 code directly imports and uses plan 04's clean implementations

**2. [Rule 3 - Blocking] agenda_day_screen.dart import of create_absence_sheet.dart**
- **Found during:** Task 1 (running flutter analyze)
- **Issue:** Plan 04 imported `create_absence_sheet.dart` stub (for plan 06) but the stub in their commit had `_showOptions` already; no action needed beyond confirming the stub was present
- **Fix:** Verified stub was already committed by plan 04
- **Files:** `mobile/lib/features/agenda/widgets/create_absence_sheet.dart`

---

**Total deviations:** 2 (both blocking — parallel execution context)
**Impact on plan:** Zero scope change. Plan 04's parallel execution pre-populated all required infrastructure; plan 05 consumed it directly.

## Issues Encountered

- The `AppointmentCard` in plan 04 uses `_swipeRightAction` internally based on `appointment.canConfirm/canComplete`; this means the swipe automatically routes to the correct action. PaymentSheet integration required only changing the `onComplete` callback in the screen from a direct provider call to `PaymentSheet.show()`.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- All four booking/action sheets are live and wired to the real API
- Plan 06 (week view + absences + working hours) can proceed independently
- `CreateAbsenceSheet` stub is in place — plan 06 implements the full UI
- `flutter analyze` passes with zero errors across the agenda feature
- No blockers

---

## Self-Check: PASSED

**Files verified present:**
- mobile/lib/features/agenda/widgets/quick_book_sheet.dart — FOUND
- mobile/lib/features/agenda/widgets/payment_sheet.dart — FOUND
- mobile/lib/features/agenda/widgets/appointment_detail_sheet.dart — FOUND
- mobile/lib/features/agenda/widgets/cancel_dialog.dart — FOUND

**Commits verified present:**
- 56b338a feat(03-05): booking sheet with client search, slot picker, and API create — FOUND
- 28e6d9b feat(03-05): payment sheet, appointment detail sheet, cancel dialog — FOUND

---
*Phase: 03-scheduling-engine*
*Completed: 2026-04-03*
