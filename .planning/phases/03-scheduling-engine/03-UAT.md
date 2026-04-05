---
status: diagnosed
phase: 03-scheduling-engine
source: 03-01-SUMMARY.md, 03-02-SUMMARY.md, 03-03-SUMMARY.md, 03-04-SUMMARY.md, 03-05-SUMMARY.md, 03-06-SUMMARY.md
started: 2026-04-05T13:50:00Z
updated: 2026-04-05T14:10:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Cold Start Smoke Test
expected: Kill any running backend server and mobile app. Start the backend with `cd backend && npm run dev`. Server boots without errors. Then run the mobile app — app launches without crash.
result: pass

### 2. Agenda Day View — Appointments and Blocked Slots
expected: After logging in, navigate to the Agenda tab. The day view shows today's date with a timeline. If there are appointments, they appear as cards with client name, service, time, and a status badge (pending=amber, confirmed=blue, completed=green). Blocked slots appear as distinct cards with title. A date picker appears when tapping the date label in the header.
result: pass

### 3. Create Appointment via QuickBookSheet
expected: Tap an empty time slot on the agenda (or the [+] button). A bottom sheet opens with: client search field (type 2+ chars to see autocomplete results), service picker (filtered by professional), available slot chips (occupied slots disabled/strikethrough), optional notes field. Select a client, service, and slot, then tap Confirmar. The sheet closes, agenda refreshes, and the new appointment appears as a "pending" card.
result: pass

### 4. Confirm Appointment (Swipe Right on Pending)
expected: On a pending appointment card (amber badge), swipe right. The card transitions to "confirmed" status (blue badge). The swipe action completes without errors.
result: pass

### 5. Complete Appointment with Payment
expected: On a confirmed appointment card (blue badge), swipe right. A PaymentSheet opens showing the service price (editable), and 4 payment method options (Dinheiro, PIX, Débito, Crédito). If Crédito is selected, an installment selector (1x-12x) appears. Tap Confirmar — the appointment moves to "completed" (green badge) and the payment is recorded.
result: pass

### 6. Cancel Appointment
expected: On a pending or confirmed appointment card, swipe left. A CancelDialog appears with an optional reason text field. Tap Cancelar to confirm. The appointment moves to "cancelled" status and appears at 60% opacity with no further swipe actions.
result: pass

### 7. Appointment Detail Sheet
expected: Tap on any appointment card. A detail bottom sheet opens showing: client name, service name, time range, professional name, and a StatusBadge. Action buttons appear based on status — pending shows Confirmar + Cancelar; confirmed shows Concluir + Cancelar + Não compareceu; terminal statuses (completed/cancelled/no-show) show only Fechar.
result: pass

### 8. Mark No-Show
expected: Open a confirmed appointment's detail sheet. Tap "Não compareceu". The appointment transitions to no-show status. The slot becomes available for rebooking (a new appointment can be created at the same time).
result: pass

### 9. Create Absence (Long Press)
expected: Long press on an empty time slot. A CreateAbsenceSheet opens with: title field, date picker, start/end time selectors, recurring toggle. For a sporadic absence: fill title, select date and times, tap Salvar. The absence appears on the agenda as a blocked slot card. For recurring: enable the toggle, select days of week via FilterChips, optionally set end date, and save.
result: pass

### 10. Delete Absence
expected: Tap on a blocked slot card. An options bottom sheet appears. For a sporadic absence: "Remover todas" option. For a recurring absence: "Remover só este dia" and "Remover todas" options. Tapping remove deletes the absence and it disappears from the agenda.
result: pass

### 11. Week View Toggle
expected: In the agenda screen, tap the view toggle button (day/week icon) in the app bar. The view switches to a 7-column week grid showing colored mini-blocks per appointment status (amber=pending, blue=confirmed, green=completed, muted=cancelled/no-show). A legend appears below. Tapping a day column navigates back to the day view for that date.
result: pass

### 12. Working Hours Configuration
expected: Navigate to Mais tab > tap "Meu horário". A WorkingHoursScreen opens showing 7 days of the week, each with an enable/disable toggle and time range inputs (open/close). Disable a day — it grays out. Enable a day and set hours (e.g., 09:00-18:00). Tap Salvar — a success snackbar appears. The save button is disabled until changes are detected.
result: pass

### 13. Conflict Detection — Double Booking Rejected
expected: Create an appointment for a specific time slot. Then try to create a second appointment for the same professional at an overlapping time. The second booking should be rejected — either the slot appears as disabled/occupied in the QuickBookSheet, or if attempted via manual time entry, an error message appears indicating the time slot is taken.
result: pass

### 14. Multi-Professional Agenda Navigation
expected: If the studio has multiple professionals, the agenda screen shows a way to switch between professionals (tab bar or swipe navigation). Selecting a different professional loads their appointments and blocked slots. Each professional's agenda is independent.
result: pass

### 15. Month View with Status Summary
expected: The agenda includes a month view (calendar) where each day shows colored indicators representing appointment status counts for that day. Tapping a day navigates to the day view for that date.
result: issue
reported: "Encontrei um erro, quando estou na agenda do mês ao navegar via tab para outro colaborador, o sistema se confunde e mostra as agendas erradas/trocadas"
severity: major

## Summary

total: 15
passed: 14
issues: 1
pending: 0
skipped: 0

## Gaps

- truth: "Month view shows correct agenda per professional when switching tabs"
  status: failed
  reason: "User reported: quando estou na agenda do mês ao navegar via tab para outro colaborador, o sistema se confunde e mostra as agendas erradas/trocadas"
  severity: major
  test: 15
  root_cause: "monthSummary in AgendaState is a single shared Map, not keyed by professionalId. loadMonthData overwrites it for whichever professional was selected at call time. When switching tabs, the old professional's data stays displayed. Race condition: async loadMonthData can resolve after tab switch, showing stale data."
  artifacts:
    - path: "mobile/lib/features/agenda/providers/agenda_provider.dart"
      issue: "monthSummary is flat Map<String, Map<String, int>> — not per-professional; loadMonthData (lines ~390-408) writes to shared map"
    - path: "mobile/lib/features/agenda/widgets/agenda_month_view.dart"
      issue: "Reads agendaState.monthSummary without checking professionalId; only calls loadMonthData once in initState"
    - path: "mobile/lib/features/agenda/agenda_day_screen.dart"
      issue: "_onPageChanged calls selectProfessional but never triggers loadMonthData for new professional"
  missing:
    - "Key monthSummary by professionalId (Map<String, Map<String, Map<String, int>>>)"
    - "AgendaMonthView must re-trigger loadMonthData when selectedProfessionalId changes"
    - "_onPageChanged must trigger loadMonthData when in month view mode"
