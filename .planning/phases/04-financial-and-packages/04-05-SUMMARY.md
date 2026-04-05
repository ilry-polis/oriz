---
phase: 04-financial-and-packages
plan: 05
subsystem: ui
tags: [flutter, riverpod, packages, sessions, subscriptions, mobile]

# Dependency graph
requires:
  - phase: 04-01
    provides: Package CRUD API endpoints and subscription endpoints
provides:
  - Flutter package management screen at /more/packages
  - PackageModel and PackageSubscriptionModel with fromJson parsers
  - PackageRepository calling /api/v1/packages and /api/v1/package-subscriptions
  - PackageNotifier (AsyncNotifier) with load/create/updatePackage/delete
  - CreatePackageSheet bottom sheet with service picker, sessions, price, validity
  - SellPackageSheet bottom sheet for selling packages to clients
  - ClientDetailScreen Pacotes tab with active subscriptions, progress bars, expiry extend
  - ServiceDetailScreen Packages section with create shortcut
  - More screen Pacotes menu item wired to /more/packages
affects: [phase-05-whatsapp, phase-06-ai, any future reporting or booking flows]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - AsyncNotifier with sealed PackageListState (Loading/Loaded/Error)
    - Repository calls API backend (not Supabase directly) — follows mobile.md rules
    - Bottom sheets with static show() factory for consistent invocation
    - Grouped list rendering (packages grouped by service name)
    - DatePicker for expiry extension

key-files:
  created:
    - mobile/lib/features/packages/models/package_model.dart
    - mobile/lib/features/packages/models/package_subscription_model.dart
    - mobile/lib/features/packages/repositories/package_repository.dart
    - mobile/lib/features/packages/providers/package_provider.dart
    - mobile/lib/features/packages/screens/packages_management_screen.dart
    - mobile/lib/features/packages/widgets/create_package_sheet.dart
    - mobile/lib/features/packages/widgets/sell_package_sheet.dart
  modified:
    - mobile/lib/features/clients/presentation/client_detail_screen.dart
    - mobile/lib/features/services_management/presentation/service_detail_screen.dart
    - mobile/lib/features/more/presentation/more_screen.dart
    - mobile/lib/core/router/app_router.dart

key-decisions:
  - "updatePackage (not update) used on AsyncNotifier to avoid Riverpod name conflict with built-in update"
  - "Packages grouped by service name in management screen using Map<String, List<PackageModel>>"
  - "SellPackageSheet filters packages by serviceId client-side (packages already loaded in provider)"
  - "Expiry extension uses DatePicker — simple UX for owner to pick new date"

patterns-established:
  - "Package feature: models/repo/provider/screens/widgets — standard feature directory layout"
  - "Bottom sheets: static show() factory + ConsumerStatefulWidget — sell/create patterns"

requirements-completed: [SERV-03, SERV-05]

# Metrics
duration: 15min
completed: 2026-04-05
---

# Phase 4 Plan 5: Package Management Flutter UI Summary

**Flutter package CRUD with service-grouped management screen, sell-to-client bottom sheet, and client detail Pacotes tab showing sessions progress and expiry extension**

## Performance

- **Duration:** ~15 min
- **Started:** 2026-04-05T19:33:00Z
- **Completed:** 2026-04-05T19:48:00Z
- **Tasks:** 2
- **Files modified:** 11

## Accomplishments

- Full package management screen at `/more/packages` with packages grouped by service, delete confirmation, refresh
- CreatePackageSheet with service picker (skipped when pre-selected from service screen), sessions/price/validity fields
- SellPackageSheet for selling packages from client detail — shows available packages with price-per-session, confirmation
- ClientDetailScreen gained a "Pacotes" tab (4th tab) showing active subscriptions with LinearProgressIndicator (used/total), expiry badge, and "Estender" button using DatePicker
- ServiceDetailScreen gained a Packages section listing service-specific packages with a "Novo pacote" shortcut
- All models parse API response correctly with formattedPrice getter and status-aware helpers (isActive, isExpired, sessionsRemaining)
- flutter analyze passes with zero errors

## Task Commits

1. **Task 1: Package models, repos, providers + management screen** - `05b8edc` (feat)
2. **Task 2: Sell package sheet + client detail integration + service edit integration** - included in `05b8edc`

**Fix:** `bca17fb` (fix: remove unused `_selectedServiceName` field in CreatePackageSheet)

## Files Created/Modified

- `mobile/lib/features/packages/models/package_model.dart` — PackageModel with formattedPrice, validityLabel
- `mobile/lib/features/packages/models/package_subscription_model.dart` — SubscriptionModel with progress, expiry, status helpers
- `mobile/lib/features/packages/repositories/package_repository.dart` — CRUD + createSubscription + extendExpiry + getActiveForClientService
- `mobile/lib/features/packages/providers/package_provider.dart` — AsyncNotifier with sealed state; client/package subscription providers
- `mobile/lib/features/packages/screens/packages_management_screen.dart` — Grouped package list, FAB, delete confirmation
- `mobile/lib/features/packages/widgets/create_package_sheet.dart` — Service picker, sessions, price, validity fields
- `mobile/lib/features/packages/widgets/sell_package_sheet.dart` — Package selection list with animated selection, price-per-session display
- `mobile/lib/features/clients/presentation/client_detail_screen.dart` — Added Pacotes tab with subscriptions, progress bars, extend expiry
- `mobile/lib/features/services_management/presentation/service_detail_screen.dart` — Added _PackagesSection with create shortcut
- `mobile/lib/features/more/presentation/more_screen.dart` — Added Pacotes menu entry under Servicos section
- `mobile/lib/core/router/app_router.dart` — Added /more/packages route

## Decisions Made

- `updatePackage` named (not `update`) to avoid Riverpod AsyncNotifier built-in method name conflict
- Packages are grouped client-side by serviceName in PackagesManagementScreen — no extra API call needed
- SellPackageSheet filters packages by serviceId client-side from the already-loaded provider state
- DatePicker used for expiry extension — clean UX, requires API PATCH /api/v1/package-subscriptions/:id

## Deviations from Plan

None - plan executed exactly as written. The prior commit `05b8edc` already included all required files. The only change made in this execution was removing an unused `_selectedServiceName` state field (Rule 1 - minor cleanup).

## Issues Encountered

None. All pre-existing test failures (router overflow, auth screen tests) are unrelated to this plan's changes.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Package management UI is complete end-to-end
- The backend API from Plan 04-01 is the only dependency and was verified as available
- Wave 3 of Phase 04 is now complete — ready for Phase 05 (WhatsApp)
- Pre-existing test failures in auth/router tests should be investigated before Phase 5

## Self-Check: PASSED

All 7 created files verified on disk. Both task commits (05b8edc, bca17fb) verified in git log.

---
*Phase: 04-financial-and-packages*
*Completed: 2026-04-05*
