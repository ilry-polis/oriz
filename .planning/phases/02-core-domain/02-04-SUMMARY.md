---
phase: 02-core-domain
plan: 04
status: complete
started: 2026-04-02
completed: 2026-04-02
tasks_completed: 2
tasks_total: 2
---

# Plan 02-04: Team + Invites Backend — Summary

## What Was Built

Complete Team management backend with professional CRUD, invite link flow, service linking, commission configuration, and role-based permission guards.

### Migration
- `005_professional_invites.sql` — professional_invites table with token, expiration, studio/inviter references

### Repositories
- **InviteRepository** — create invite with token/expiration, findByToken, markAccepted, listByStudio
- **ProfessionalRepository** (expanded) — create, list (cursor-based), getById, update (dynamic SET), replaceServiceLinks (atomic transaction), getServiceLinks, findByUserId

### Services
- **InviteService** — createInvite (generates token, 7-day expiry), getInviteInfo (public), acceptInvite (validates token, creates professional record, marks used)
- **ProfessionalService** (expanded) — listProfessionals, getProfessionalById (with service_ids), updateProfessional (with optional service link replacement), toggleActive, replaceServiceLinks, getProfessionalByUserId

### Controllers & Routes
- **InviteController** — getInfo (public) + accept (public) endpoints
- **ProfessionalController** — list, getMe, getById, update, toggleActive
- **Role-guard middleware** — requireOwner, requireAuth preHandlers
- Routes wired in `professionals.routes.ts` and `auth.routes.ts`

### Endpoints
- `GET /api/v1/professionals` — paginated list (owner sees commissions, collaborator does not)
- `GET /api/v1/professionals/me` — current user's professional record
- `GET /api/v1/professionals/:id` — detail with role-based commission visibility
- `PATCH /api/v1/professionals/:id` — update fields + service links (owner only)
- `PATCH /api/v1/professionals/:id/active` — toggle active (owner only)
- `POST /api/v1/professionals/invite` — create invite link (owner only)
- `GET /api/v1/auth/invite/:token` — get invite info (public)
- `POST /api/v1/auth/invite/:token/accept` — accept invite (public)

## Tests

- `professional.service.test.ts` — 16 tests for professional CRUD and service linking
- `invite.service.test.ts` — 10 tests for invite creation, acceptance, expiry, and validation
- `role-guard.test.ts` — 7 tests for role-based access control

## Commits

- `5b056b2`: feat(02-04): professional_invites migration, repositories, services and tests
- `7846352`: feat(02-04): wire invite/professional controllers, routes, and role-guard middleware

## Deviations

- Added `getProfessionalByUserId` method to ProfessionalService (not in original plan) to properly encapsulate repository access from controller.

## Self-Check: PASSED

## key-files

### created
- supabase/migrations/005_professional_invites.sql
- backend/src/repositories/invite.repository.ts
- backend/src/services/invite.service.ts
- backend/src/controllers/invite.controller.ts
- backend/src/middleware/role-guard.ts
- backend/tests/services/invite.service.test.ts
- backend/tests/middleware/role-guard.test.ts

### modified
- backend/src/repositories/professional.repository.ts
- backend/src/services/professional.service.ts
- backend/src/controllers/professional.controller.ts
- backend/src/routes/professionals.routes.ts
- backend/src/routes/auth.routes.ts
- backend/src/server.ts
- backend/src/types/fastify.d.ts
- backend/tests/services/professional.service.test.ts
