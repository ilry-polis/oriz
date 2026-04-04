# Phase 3: Scheduling Engine - Context

**Gathered:** 2026-04-03
**Status:** Ready for planning

<domain>
## Phase Boundary

Professionals can view and manage their agenda with guaranteed conflict-free booking. Includes: day/week view, appointment CRUD with status workflow (pending → confirmed → completed/cancelled/no-show), absence management (sporadic and recurring), available slot calculation, and payment recording on completion. WhatsApp confirmation automation belongs to Phase 5.1/6 — this phase builds the status model that supports it.

</domain>

<decisions>
## Implementation Decisions

### Agenda visualization — Day view (primary)
- Day view is the default screen with vertical timeline
- Timeline adapts start/end to each professional's working_hours (no fixed 8-19h)
- Appointment cards are compact: client name + service name + duration, height reflects duration
- Color coding by status (pending, confirmed, completed, cancelled, no-show)
- Completed/cancelled/no-show cards remain visible with reduced opacity (60%)
- Buffer time between appointments is invisible in UI — only enforced in slot calculation logic
- Tap on card opens detail bottom sheet; swipe and 3-dot menu for quick actions

### Agenda visualization — Week view
- Grid with mini-blocks (colored, no text) — columns per day
- Tap on a day opens day view for that date
- Provides quick occupancy overview

### Agenda visualization — Date navigation
- DaySelector: horizontal row of day chips (Seg/Ter/.../Dom) — already implemented
- Swipe horizontally on DaySelector to change week
- Tap on date label (e.g., "Terça, 3 de abril") opens calendar picker to jump to any date

### Agenda visualization — Multi-professional (owner view)
- Default view "Todas": PageView with horizontal snap — each page is one professional's daily timeline
- Professional name displayed as header below date selector, with dot indicators
- Owner can also select a specific professional via filter icon to see only her agenda
- Collaborator sees the same screen layout but without filter/selector (only her own agenda)

### Appointment creation flow
- Two entry points: (1) tap on empty slot (pre-fills time), (2) [+] button in header (no pre-filled time)
- Both open the same bottom sheet
- Client selection: search box with autocomplete (studios have 300+ clients) — not chips
- "+ Novo cliente" inline option: quick registration with name + phone only (consistent with Phase 2)
- Service list: only shows services linked to the selected professional
- Professional pre-selected from current PageView page; changeable via dropdown if owner
- Time: pre-filled from tapped slot, adjustable with free slot suggestions; time picker for custom time
- Conflict prevention: occupied slots disabled in suggestions; inline error if manually entered time conflicts — never reaches backend with conflict
- Notes: optional, collapsed by default ("+ Adicionar observação" expands text field)

### Appointment status workflow
- All appointments start as **pending** (marcado), regardless of who creates them
- Rationale: clients book 10+ days ahead; professional sends confirmation message before the date
- Confirmation flow by plan tier (WhatsApp automation in Phase 5.1/6, manual in Phase 3):
  - **Básico**: professional confirms manually via swipe
  - **Intermediário** (future): WhatsApp message with confirm/cancel link; cancel asks optional reason
  - **Pro** (future): AI converses and confirms/cancels automatically
- Studio configures how many hours/days before appointment to trigger confirmation (field stored now, consumed by WhatsApp phases)
- Swipe behavior adapts to current status:
  - Pending: swipe ▶ = confirm, swipe ◀ = cancel
  - Confirmed: swipe ▶ = complete (opens payment sheet), swipe ◀ = cancel
- 3-dot context menu (bottom sheet): edit, view client, mark no-show, cancel
- Cancel dialog: confirmation with optional reason text field (cancellation_reason stored in DB)

### Payment on completion
- Completing an appointment opens a payment bottom sheet
- Pre-filled value from service price
- Payment method selection: Dinheiro / PIX / Débito / Crédito
- Records payment alongside completion in a single action

### Appointment detail
- Tap on appointment card opens detail bottom sheet
- Shows: client name, service, time, professional, status, notes
- Action buttons: confirm/complete/cancel/no-show/edit (contextual to current status)

### Absences (formerly "blocked slots")
- Terminology: **ausência** (absence), not "bloqueio" or "pausa"
- Two types:
  - **Sporadic**: specific date/time + mandatory title (e.g., "Dentista", "Reunião escola")
  - **Recurring**: weekly simple engine — select days of week + time range + optional end date
- Creation: long press on empty slot → bottom sheet with toggle "Recorrente" yes/no
- Recurring rule stored as JSONB: `{ frequency: "weekly", days: [...], until: date|null }`
- Exceptions: tap on recurring absence → "Remover só este dia" or "Remover todas" — exceptions stored as excluded dates list in the rule
- Visual: same BlockedSlotCard pattern (neutral100 background, neutral200 border, diagonal stripes, title + "Ausência" label)

### Working hours configuration
- Edited in Configurações > Meu horário (not in agenda screen)
- Weekly grid same as Phase 1 onboarding: toggle days on/off, start/end per day, multiple ranges per day
- Owner can edit any professional's hours; collaborator edits only her own
- Professional inherits studio hours by default, can override (JSONB field already exists)

### Claude's Discretion
- Loading skeleton design for agenda
- Exact color palette for status states (pending, confirmed, completed, cancelled, no-show)
- Week view mini-block sizing and color mapping
- Empty state illustration and copy
- Calendar picker implementation (Flutter DatePicker or custom)
- Transition animations between day/week view
- Haptic feedback patterns
- Error state handling
- PageView page indicator style (dots vs text)
- Payment sheet value editing (allow override or fixed from service price)

</decisions>

<specifics>
## Specific Ideas

- BlockedSlotCard visual (diagonal stripes + neutral colors) is the established pattern for absences — reuse exactly
- AppointmentCard already has swipe (Dismissible), 3-dot menu (bottom sheet), drag-and-drop — extend, don't rebuild
- DaySelector chip layout is the established date navigation pattern — extend with swipe for week change
- QuickBookSheet bottom sheet pattern established — evolve with search box instead of chips
- Cal.com / Linear visual reference continues (clean, minimal, whitespace-heavy)
- Regra dos 3 toques: agendar = selecionar cliente → serviço → confirmar

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `BlockedSlotCard` (mobile/lib/features/agenda/widgets/blocked_slot_card.dart): diagonal stripe painter + neutral styling — reuse for absences
- `AppointmentCard` (mobile/lib/features/agenda/widgets/appointment_card.dart): swipe (Dismissible) + 3-dot menu + status badge — extend for status-aware swipe behavior
- `DaySelector` (mobile/lib/features/agenda/widgets/day_selector.dart): week day chips with selection — extend with PageView for week swiping
- `QuickBookSheet` (mobile/lib/features/agenda/widgets/quick_book_sheet.dart): bottom sheet booking pattern — refactor with search box + API data
- `StatusBadge` (mobile/lib/features/agenda/widgets/status_badge.dart): status indicator widget
- `SkeletonTimeline` (mobile/lib/features/agenda/widgets/skeleton_timeline.dart): loading state
- `EmptyAgenda` (mobile/lib/features/agenda/widgets/empty_agenda.dart): empty state with CTA
- Backend: appointments.routes.ts fully scaffolded with Zod schemas (list, create, update, complete, cancel, no-show, available-slots)

### Established Patterns
- Backend: Route → Controller → Service → Repository layers
- Backend: Zod validation at boundary, { data, meta } response shape
- Backend: cursor-based pagination, explicit column selection, studio_id filtering
- Flutter: Riverpod sealed state (Loading/Success/Error), GoRouter, ApiClient
- Flutter: Bottom sheets for all create/action flows (app-wide pattern)
- Flutter: 3-dot menu via bottom sheet (not PopupMenuButton)
- DB: Exclusion constraint `appointments_no_overlap` prevents double-booking at DB level
- DB: `blocked_slots` table with professional_id, date, start/end time, reason

### Integration Points
- Services (Phase 2): service list filtered by professional link for booking
- Clients (Phase 2): client search for booking, client detail from appointment
- Professionals (Phase 2): working_hours JSONB, professional-service links
- Bottom nav: Agenda is already the default tab (initialLocation: '/agenda')
- ShellRoute + AppShell: agenda screen already wired in navigation
- DB: appointments table, blocked_slots table, btree_gist extension — all exist in migration 001
- DB: Need migration to add 'pending' to appointments status CHECK constraint

</code_context>

<deferred>
## Deferred Ideas

- WhatsApp automatic confirmation messages (Phase 5.1/6) — status model supports it, automation is future
- AI confirmation conversation (Phase 6 — Pro plan)
- Confirmation link page for clients (Phase 5.1 — Intermediário plan)
- Google Calendar sync (v2 — PLAT-03)
- Recurring appointments (not absences — e.g., "Maria every Tuesday 10am") — future feature
- Drag-and-drop to different professional (cross-professional rescheduling) — future enhancement

</deferred>

---

*Phase: 03-scheduling-engine*
*Context gathered: 2026-04-03*
