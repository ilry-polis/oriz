---
phase: 04-financial-and-packages
plan: 04
subsystem: mobile-ui
tags: [flutter, riverpod, financial, commissions, dashboard, kpi]

# Dependency graph
requires:
  - phase: 04-financial-and-packages
    provides: "Financial and commission API endpoints (plan 02)"
provides:
  - "FinancialDashboardScreen: 2-tab UI (Resumo/Comissões) at /more/financial"
  - "KpiCard widget with delta badge (comparison arrow + percentage)"
  - "PaymentListItemWidget with method icon, discount strikethrough"
  - "BreakdownSection: expandable ranked breakdown by professional/service"
  - "CommissionDetailScreen: per-professional commission entries + footer sum"
  - "FinancialDashboardNotifier: sealed state, period selector, filter, load-more"
  - "CommissionNotifier: monthly/biweekly period navigation, markPaid"
  - "Navigation from More > Financeiro wired via GoRouter"
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "FutureProvider.autoDispose.family for read-only async detail screens (Riverpod 3 compatible)"
    - "Sealed state (Loading/Loaded/Error) pattern for dashboard notifiers"
    - "CommissionPeriod value object with next/previous navigation and label formatting"
    - "Record types used as FutureProvider.family arg (CommissionDetailParams)"

key-files:
  created:
    - mobile/lib/features/financial/models/financial_summary_model.dart
    - mobile/lib/features/financial/models/payment_model.dart
    - mobile/lib/features/financial/models/commission_model.dart
    - mobile/lib/features/financial/repositories/financial_repository.dart
    - mobile/lib/features/financial/repositories/commission_repository.dart
    - mobile/lib/features/financial/providers/financial_provider.dart
    - mobile/lib/features/financial/providers/commission_provider.dart
    - mobile/lib/features/financial/screens/financial_dashboard_screen.dart
    - mobile/lib/features/financial/screens/commission_detail_screen.dart
    - mobile/lib/features/financial/widgets/kpi_card.dart
    - mobile/lib/features/financial/widgets/payment_list_item.dart
    - mobile/lib/features/financial/widgets/breakdown_section.dart
  modified:
    - mobile/lib/features/more/presentation/more_screen.dart
    - mobile/lib/core/router/app_router.dart

key-decisions:
  - "FutureProvider.autoDispose.family used for CommissionDetailScreen — FamilyNotifier does not exist in Riverpod 3.x, FutureProvider.family is the idiomatic approach for read-only async data"
  - "CommissionPeriod is a value object (not enum) to support both monthly and biweekly boundaries with next/previous navigation"
  - "markPaid dialog fetches commission IDs on-demand from repository to avoid storing stale IDs in UI state"

# Metrics
duration: 45min
completed: 2026-04-05
---

# Phase 4 Plan 04: Financial Dashboard and Commission UI Summary

**Flutter financial dashboard with KPI cards, period selector, paginated payment list, expandable breakdowns, and commission tab with mark-as-paid functionality connected to financial APIs from Plan 02**

## Performance

- **Duration:** ~45 min
- **Started:** 2026-04-05T16:27:53Z
- **Completed:** 2026-04-05
- **Tasks:** 2
- **Files modified:** 14

## Accomplishments

- Financial dashboard screen accessible via More > Financeiro with 2 tabs: Resumo and Comissões
- Resumo tab: period chips (Dia/Semana/Mês), 2x2 KPI grid with formatted values, filter chips by payment method, cursor-paginated payments list, expandable breakdowns by professional and service
- Comissões tab: monthly/biweekly period navigator, professional list with commission summary and Pagar/Pago badges, confirmation dialog with mark-as-paid action
- CommissionDetailScreen: individual commission entries with gross amount strikethrough + net commission, card fee display, summary footer
- All models handle API responses with formatted getters (R$ currency, percentage, date)
- flutter analyze passes with no errors from new code (63 pre-existing infos/warnings)
- Pre-existing test failure in app_router_test.dart (agenda_day_screen overflow) confirmed not related to our changes

## Task Commits

Each task was committed atomically:

1. **Task 1: Models, repositories, providers** — `f07983e`
2. **Task 2: Screens, widgets, navigation** — `ddb1239`

## Files Created/Modified

### Created
- `mobile/lib/features/financial/models/financial_summary_model.dart` — FinancialSummaryModel (KPIs) + BreakdownItem with formatted getters
- `mobile/lib/features/financial/models/payment_model.dart` — PaymentListItem with method label + discount helpers
- `mobile/lib/features/financial/models/commission_model.dart` — CommissionModel + CommissionSummary with formatted amounts
- `mobile/lib/features/financial/repositories/financial_repository.dart` — getSummary, getBreakdownByProfessional/Service, listPayments (cursor-paginated)
- `mobile/lib/features/financial/repositories/commission_repository.dart` — list, sumByProfessional, markPaid
- `mobile/lib/features/financial/providers/financial_provider.dart` — FinancialDashboardNotifier with sealed state, FinancialPeriod enum with date range helpers
- `mobile/lib/features/financial/providers/commission_provider.dart` — CommissionNotifier, CommissionPeriod value object, FutureProvider.family for detail
- `mobile/lib/features/financial/screens/financial_dashboard_screen.dart` — Main screen with Resumo + Comissões tabs (>300 lines)
- `mobile/lib/features/financial/screens/commission_detail_screen.dart` — Detail screen with entry list + summary footer
- `mobile/lib/features/financial/widgets/kpi_card.dart` — KpiCard + KpiCardSkeleton + delta badge
- `mobile/lib/features/financial/widgets/payment_list_item.dart` — PaymentListItemWidget + method icon + skeleton
- `mobile/lib/features/financial/widgets/breakdown_section.dart` — ExpansionTile with ranked rows + percentage bars

### Modified
- `mobile/lib/features/more/presentation/more_screen.dart` — Financeiro row activated (removed "Em breve", added navigation)
- `mobile/lib/core/router/app_router.dart` — Added /more/financial and /more/financial/commissions/:professionalId routes

## Decisions Made

- **FutureProvider.autoDispose.family for CommissionDetail:** `FamilyNotifier` does not exist in Riverpod 3.x. The correct approach is `FutureProvider.autoDispose.family` with a function that receives the arg — idiomatic for read-only async data.
- **CommissionPeriod as value object:** Needs to support both monthly (month boundaries) and biweekly (15-day periods) modes, plus next/previous navigation — an enum cannot hold this dynamic state.
- **markPaid fetches IDs on-demand:** The commission summaries from `/commissions/summary` don't include individual commission IDs. The mark-paid dialog fetches pending commission IDs via `commissionRepository.list()` before calling `markPaid`. This avoids stale IDs in UI state.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Replaced FamilyNotifier with FutureProvider.family**
- **Found during:** Task 1/2 (flutter analyze error)
- **Issue:** `FamilyNotifier` does not exist as a class in Riverpod 3.x (riverpod 3.2.1 / flutter_riverpod 3.3.1). The plan called for `NotifierProvider.family` pattern but the class hierarchy doesn't have `FamilyNotifier`.
- **Fix:** Used `FutureProvider.autoDispose.family<CommissionDetailLoaded, CommissionDetailParams>` with a function-based provider — the idiomatic Riverpod 3 pattern for read-only async family data. CommissionDetailScreen updated to use `asyncState.when(...)`.
- **Files modified:** `commission_provider.dart`, `commission_detail_screen.dart`
- **Committed in:** `ddb1239`

---

**Total deviations:** 1 auto-fixed (Rule 1 — API mismatch between plan assumption and actual Riverpod 3.x API)

## User Setup Required

None — no external service configuration required.

## Self-Check: PASSED
