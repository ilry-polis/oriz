---
phase: 02-core-domain
plan: 03
status: complete
started: 2026-04-02
completed: 2026-04-02
tasks_completed: 2
tasks_total: 2
---

# Plan 02-03: Anamnesis + Client Notes — Summary

## What Was Built

Anamnesis per-category forms with template defaults, immutable client notes timeline, and appointment history endpoint.

### Migration
- `004_client_notes.sql` — client_notes table with RLS (INSERT+SELECT only, no UPDATE/DELETE)

### Repositories
- **AnamnesisRepository** — upsert with ON CONFLICT (studio_id, client_id, service_category_id), getByClientAndCategory, listByClient
- **ClientNoteRepository** — create (immutable), listByClient with cursor-based pagination DESC
- **ClientRepository** (expanded) — listAppointments with graceful handling for missing table (Phase 3)

### Services
- **AnamnesisService** — template defaults for 5 categories (lash, micropig, unhas, estetica, cabelo), merge logic (stored values override defaults), upsert delegates to repo
- **ClientNoteService** — create + paginated list
- **ClientService** (expanded) — listAppointments with cursor-based pagination

### Endpoints
- `PUT /clients/:clientId/anamneses/:categoryId` — upsert anamnesis
- `GET /clients/:clientId/anamneses/:categoryId` — get by category
- `GET /clients/:clientId/anamneses` — list all for client
- `POST /clients/:clientId/notes` — create note (immutable)
- `GET /clients/:clientId/notes` — list notes (DESC, paginated)
- `GET /clients/:id/appointments` — appointment history (empty until Phase 3)

## Tests
- `anamnesis.service.test.ts` — 9 tests (templates, merge, CRUD)
- `client-note.service.test.ts` — 4 tests (create, pagination)

## Commits
- `882ee0d`: feat(02-03): anamnesis, client notes, and appointment history

## Deviations
None.

## Self-Check: PASSED
