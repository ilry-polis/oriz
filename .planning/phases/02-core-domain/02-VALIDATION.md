---
phase: 2
slug: core-domain
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-02
---

# Phase 2 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Vitest 3.2.1 (backend), Flutter test (mobile) |
| **Config file** | `backend/vitest.config.ts` |
| **Quick run command** | `cd backend && npm run test` |
| **Full suite command** | `cd backend && npm run test && cd ../mobile && flutter test` |
| **Estimated runtime** | ~5 seconds (backend) + ~7 seconds (mobile) |

---

## Sampling Rate

- **After every task commit:** Run `cd backend && npm run test`
- **After every plan wave:** Run `cd backend && npm run test && cd ../mobile && flutter test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 12 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| W0-svc | 01 | 0 | SERV-01 | unit | `npm run test -- tests/services/service.service.test.ts` | ✅ (parcial) | ⬜ pending |
| W0-clt | 01 | 0 | CLNT-01,02,05 | unit | `npm run test -- tests/services/client.service.test.ts` | ❌ W0 | ⬜ pending |
| W0-anam | 01 | 0 | CLNT-03 | unit | `npm run test -- tests/services/anamnesis.service.test.ts` | ❌ W0 | ⬜ pending |
| W0-cons | 01 | 0 | LGPD-02 | unit | `npm run test -- tests/services/consent.service.test.ts` | ❌ W0 | ⬜ pending |
| W0-prof | 01 | 0 | TEAM-01,03,04 | unit | `npm run test -- tests/services/professional.service.test.ts` | ✅ (parcial) | ⬜ pending |
| W0-lgpd | 01 | 0 | LGPD-01 | unit | `npm run test -- tests/services/client.service.test.ts` | ❌ W0 | ⬜ pending |
| W0-mt | 01 | 0 | Multi-tenancy | unit | `npm run test -- tests/services/client.service.test.ts` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `tests/services/client.service.test.ts` — stubs for CLNT-01, CLNT-02, CLNT-05, LGPD-01, multi-tenancy
- [ ] `tests/services/anamnesis.service.test.ts` — stubs for CLNT-03
- [ ] `tests/services/consent.service.test.ts` — stubs for LGPD-02
- [ ] `tests/repositories/client.repository.test.ts` — stubs for CLNT-04 (listAppointments)
- [ ] Expand `tests/services/service.service.test.ts` — add list, update, setActive (SERV-01, SERV-02)
- [ ] Expand `tests/services/professional.service.test.ts` — add create, replaceServiceLinks, commission calc (TEAM-01, TEAM-03, TEAM-04)
- [ ] `supabase/migrations/004_client_notes.sql` — client_notes table for timeline notes (CLNT-06)

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Flutter list/detail UI renders correctly | CLNT-04 (visual) | Visual verification | Open client list, tap detail, check tabs |
| Service catalog grouped by category | SERV-01 (visual) | Visual verification | Open services screen, verify grouping |
| Team management screens | TEAM-01 (visual) | Visual verification | Open team screen, add professional |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 12s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
