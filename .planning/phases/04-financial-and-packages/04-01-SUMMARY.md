---
phase: 04-financial-and-packages
plan: "01"
subsystem: packages
tags: [packages, subscriptions, payments, migrations, backend, tdd]
dependency_graph:
  requires: []
  provides:
    - package-crud-api
    - package-subscription-api
    - payment-type-pacote
    - financial-summaries-view-v2
  affects:
    - financial-dashboard (payment type filter)
    - appointment-completion (Plan 03: package_subscription_id FK ready)
tech_stack:
  added: []
  patterns:
    - PackageRepository with cursor pagination and delete guard
    - PackageSubscriptionRepository with atomic deductSession (UPDATE...RETURNING)
    - PaymentRepository extended for nullable appointment_id + type field
    - PackageService delegates to repos, records payment row on subscription sale
key_files:
  created:
    - supabase/migrations/013_financial_schema_updates.sql
    - backend/src/repositories/package.repository.ts
    - backend/src/repositories/package-subscription.repository.ts
    - backend/src/services/package.service.ts
    - backend/src/controllers/package.controller.ts
    - backend/src/controllers/package-subscription.controller.ts
    - backend/tests/services/package.service.test.ts
  modified:
    - backend/src/repositories/payment.repository.ts
    - backend/src/routes/packages.routes.ts
    - backend/src/routes/package-subscriptions.routes.ts
    - backend/src/types/fastify.d.ts
    - backend/src/server.ts
    - backend/src/routes/index.ts
decisions:
  - Payment type='pacote' recorded on subscription creation (no appointment_id)
  - Atomic deductSession: UPDATE...WHERE status='active' AND expires_at > NOW() RETURNING
  - financial_summaries view rebuilt to handle split payments without double-counting
  - appointment_id on payments made nullable to support package sale rows
metrics:
  duration: "9 minutes"
  completed_date: "2026-04-05"
  tasks_completed: 2
  tasks_total: 2
  files_created: 7
  files_modified: 6
---

# Phase 4 Plan 01: DB Migration + Package Backend Stack Summary

Package CRUD API with subscription management, atomic session deduction, and payment recording as revenue with type='pacote' for financial dashboard integration.

## What Was Built

### Task 1: DB Migration + Package/Subscription Repositories

- **Migration 013**: Added `discount_amount`, `discount_reason`, `type` columns to `payments` table; made `appointment_id` nullable to support package sales; added `package_subscription_id` FK on `appointments`; rebuilt `financial_summaries` materialized view with correct split-payment aggregation using CTE (per-appointment net amounts).
- **PackageRepository**: Full CRUD with cursor pagination (`list` supports optional `serviceId` filter), `delete` guard (throws `ConflictError` if active subscriptions exist), `getUnitPrice` helper.
- **PackageSubscriptionRepository**: `create`, atomic `deductSession` (single UPDATE...RETURNING that also transitions `status` to `'completed'` when sessions exhausted), `getActiveForClientService` (JOIN to packages for service_id filter), `list` with filters, `updateExpiresAt`.
- **PaymentRepository** (extended): Now accepts `appointmentId: string | null`, `type: 'avulso' | 'pacote'`, `discountAmount`, `discountReason`.

Verification: `npm run build` passes cleanly.

### Task 2: PackageService + Controllers + Route Wiring + Tests

- **PackageService**: Validates service existence on package create, delegates to repos, `createSubscription` computes `expiresAt = now + validity_days * 86400000` and records a `paymentRepo.create` call with `type='pacote'` (per CONTEXT.md decision that package sale appears as revenue in the period sold).
- **PackageController**: 7 handlers (list, getById, create, update, delete, listSubscriptions, createSubscription).
- **PackageSubscriptionController**: getById, getActive (for QuickBookSheet Plan 05 integration), extendExpiry.
- **packages.routes.ts**: All "Not implemented" stubs replaced with controller calls; added `service_id` query filter to `GET /packages`.
- **package-subscriptions.routes.ts**: Added `GET /active?client_id=&service_id=` endpoint.
- **fastify.d.ts + server.ts**: Registered `packageController`, `packageSubscriptionController`; also registered pre-existing `financialController`, `commissionController`, `paymentController` that were missing from declarations.

Verification: 9 new tests pass (create, delete guard, subscription expiry computation, payment recording, deductSession atomicity, multi-tenancy).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Fixed missing .js extensions in routes/index.ts**
- **Found during:** Task 1 build verification
- **Issue:** `routes/index.ts` was importing all route files without `.js` extensions, causing TypeScript `module: Node16` to fail resolution for all route files. Build was already broken before this plan.
- **Fix:** Added `.js` extensions to all 18 imports in `routes/index.ts`.
- **Files modified:** `backend/src/routes/index.ts`
- **Commit:** 40df18c

**2. [Rule 2 - Missing Critical Functionality] Extended PaymentRepository for new schema columns**
- **Found during:** Task 1
- **Issue:** The existing `PaymentRepository.create` only accepted `appointmentId: string` (non-nullable) and didn't know about `type`, `discount_amount`, `discount_reason`. The new migration makes `appointment_id` nullable (required for package sale rows).
- **Fix:** Extended `CreatePaymentInput` and `PaymentRow` types; updated `INSERT` to include new columns; made `appointmentId` nullable.
- **Files modified:** `backend/src/repositories/payment.repository.ts`
- **Commit:** 40df18c

**3. [Rule 3 - Blocking] Registered missing controller decorations in fastify.d.ts**
- **Found during:** Task 2 build
- **Issue:** After fixing route/index.ts, TypeScript could now parse `financial.routes.ts`, `commissions.routes.ts`, `payments.routes.ts` and found their `app.financialController` / `app.commissionController` / `app.paymentController` references were missing from `FastifyInstance` type declarations. These were pre-existing issues unmasked by the index.ts fix.
- **Fix:** Linter auto-added imports and declarations. Verified all referenced controller files exist.
- **Files modified:** `backend/src/types/fastify.d.ts`, `backend/src/server.ts`
- **Commit:** 4c0cdb3

## Deferred Issues (Out of Scope)

- 2 pre-existing test failures not caused by this plan:
  - `tests/services/invite.service.test.ts` — Supabase admin mock missing `.catch` method
  - `tests/repositories/service.repository.test.ts` — SQL pattern assertion expects `s.id >` comparison

These existed before Phase 4 and are not caused by any changes in this plan.

## Self-Check

Files created/modified verified against git status:

- Migration 013 exists: supabase/migrations/013_financial_schema_updates.sql ✓
- PackageRepository: backend/src/repositories/package.repository.ts ✓
- PackageSubscriptionRepository: backend/src/repositories/package-subscription.repository.ts ✓
- PackageService: backend/src/services/package.service.ts ✓
- PackageController: backend/src/controllers/package.controller.ts ✓
- PackageSubscriptionController: backend/src/controllers/package-subscription.controller.ts ✓
- Tests: backend/tests/services/package.service.test.ts ✓
- Build passes: `npm run build` exits 0 ✓
- Tests pass: 9 new tests + 235 existing = 244 total passing ✓

## Self-Check: PASSED
