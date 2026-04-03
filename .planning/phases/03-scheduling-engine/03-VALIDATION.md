---
phase: 3
slug: scheduling-engine
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-03
---

# Phase 3 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Vitest (ja configurado) |
| **Config file** | `backend/vitest.config.ts` |
| **Quick run command** | `cd backend && npm run test -- --reporter=verbose tests/services/appointment.service.test.ts tests/services/blocked-slot.service.test.ts` |
| **Full suite command** | `cd backend && npm run test` |
| **Estimated runtime** | ~10 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd backend && npm run test -- tests/services/appointment.service.test.ts tests/services/blocked-slot.service.test.ts`
- **After every plan wave:** Run `cd backend && npm run test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 03-01-01 | 01 | 1 | SCHD-01 | unit | `npm run test -- tests/services/appointment.service.test.ts` | W0 | pending |
| 03-01-02 | 01 | 1 | SCHD-02 | unit | `npm run test -- tests/services/appointment.service.test.ts` | W0 | pending |
| 03-01-03 | 01 | 1 | SCHD-02 | unit | `npm run test -- tests/services/appointment.service.test.ts` | W0 | pending |
| 03-02-01 | 02 | 1 | SCHD-03 | unit | `npm run test -- tests/services/blocked-slot.service.test.ts` | W0 | pending |
| 03-02-02 | 02 | 1 | SCHD-03 | unit | `npm run test -- tests/services/blocked-slot.service.test.ts` | W0 | pending |
| 03-02-03 | 02 | 1 | SCHD-03 | unit | `npm run test -- tests/services/blocked-slot.service.test.ts` | W0 | pending |
| 03-03-01 | 03 | 1 | SCHD-04 | unit | `npm run test -- tests/services/appointment.service.test.ts` | W0 | pending |
| 03-03-02 | 03 | 1 | SCHD-04 | unit | `npm run test -- tests/services/appointment.service.test.ts` | W0 | pending |
| 03-03-03 | 03 | 1 | SCHD-04 | unit | `npm run test -- tests/services/appointment.service.test.ts` | W0 | pending |
| 03-04-01 | 04 | 2 | SCHD-05 | unit | `npm run test -- tests/services/appointment.service.test.ts` | W0 | pending |
| 03-04-02 | 04 | 2 | SCHD-05 | unit | `npm run test -- tests/services/appointment.service.test.ts` | W0 | pending |

*Status: pending / green / red / flaky*

---

## Wave 0 Requirements

- [ ] `backend/tests/services/appointment.service.test.ts` — stubs for SCHD-01, SCHD-02, SCHD-04, SCHD-05
- [ ] `backend/tests/services/blocked-slot.service.test.ts` — stubs for SCHD-03 (pontual + recorrencia)

> **Note:** Repository-layer tests (`appointment.repository.test.ts`, `blocked-slot.repository.test.ts`) are intentionally excluded from Wave 0. Repositories in this project are thin wrappers around parameterized SQL queries; service-level tests with mocked repositories provide sufficient coverage for Phase 3's scheduling logic. Repository tests may be added in a future hardening phase if needed.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Day view timeline adapts to working_hours | SCHD-01 | Flutter UI rendering | Open agenda, verify timeline start/end matches professional hours |
| Week view mini-blocks render correctly | SCHD-01 | Flutter UI rendering | Switch to week view, verify colored blocks appear per day |
| Multi-professional PageView with snap | SCHD-01 | Flutter gesture/animation | Swipe between professionals, verify snap and dot indicators |
| Appointment card swipe actions per status | SCHD-04 | Flutter gesture | Swipe pending card (->confirm), confirmed card (->complete+payment) |
| DaySelector week navigation | SCHD-01 | Flutter gesture | Swipe DaySelector left/right, verify week changes |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
