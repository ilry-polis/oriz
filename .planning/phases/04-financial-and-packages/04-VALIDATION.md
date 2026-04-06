---
phase: 4
slug: financial-and-packages
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-05
---

# Phase 4 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Vitest |
| **Config file** | `backend/vitest.config.ts` |
| **Quick run command** | `cd backend && npm run test -- --reporter=dot` |
| **Full suite command** | `cd backend && npm run test` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `cd backend && npm run test -- --reporter=dot`
- **After every plan wave:** Run `cd backend && npm run test`
- **Before `/gsd:verify-work`:** Full suite must be green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|-----------|-------------------|-------------|--------|
| 04-01-T1 | 04-01 | 1 | SERV-03 | build | `npm run build` | n/a | pending |
| 04-01-T2 | 04-01 | 1 | SERV-03, SERV-05 | unit | `npm run test -- services/package.service.test.ts` | W0 | pending |
| 04-02-T1 | 04-02 | 1 | FINC-01, FINC-02, FINC-03, FINC-04 | unit | `npm run test -- services/commission.service.test.ts services/financial.service.test.ts` | W0 | pending |
| 04-02-T2 | 04-02 | 1 | FINC-01 | build+test | `npm run build && npm run test -- --reporter=dot` | n/a | pending |
| 04-03-T1 | 04-03 | 2 | SERV-04, FINC-05 | unit | `npm run build && npm run test -- services/appointment.service.test.ts` | Partial | pending |
| 04-03-T2 | 04-03 | 2 | SERV-04, FINC-05 | unit | `npm run test -- services/appointment.service.test.ts` | Partial | pending |
| 04-04-T1 | 04-04 | 2 | FINC-01, FINC-02 | analyze | `flutter analyze --no-fatal-infos` | n/a | pending |
| 04-04-T2 | 04-04 | 2 | FINC-03, FINC-04 | analyze+test | `flutter analyze --no-fatal-infos && flutter test --no-pub` | n/a | pending |
| 04-05-T1 | 04-05 | 3 | SERV-03 | analyze | `flutter analyze --no-fatal-infos` | n/a | pending |
| 04-05-T2 | 04-05 | 3 | SERV-05 | analyze | `flutter analyze --no-fatal-infos` | n/a | pending |
| 04-06-T1 | 04-06 | 3 | SERV-04, FINC-05 | analyze+test | `flutter analyze --no-fatal-infos && flutter test --no-pub` | n/a | pending |
| 04-06-T2 | 04-06 | 3 | All | manual | Human verification checkpoint | n/a | pending |

*Status: pending · green · red · flaky*

---

## Wave 0 Requirements

- [ ] `backend/tests/services/package.service.test.ts` — stubs for SERV-03, SERV-05, subscription creation with payment recording
- [ ] `backend/tests/services/commission.service.test.ts` — stubs for FINC-05 commission logic
- [ ] `backend/tests/services/financial.service.test.ts` — stubs for FINC-01, FINC-02, FINC-03, FINC-04
- [ ] Extend `backend/tests/services/appointment.service.test.ts` — complete() hook for package deduction + commission

*Note: PackageSubscription logic is tested within package.service.test.ts (no separate PackageSubscriptionService exists).*

*Existing infrastructure covers framework installation.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Dashboard KPI visual layout | FINC-01 | Flutter UI rendering | Open financial dashboard, verify day/week/month selector, comparison arrows |
| Package purchase flow UX | SERV-03 | Multi-screen navigation | Create package -> sell to client -> verify session count |
| Commission report view | FINC-05 | Flutter screen rendering | Check commission tab displays correct periods and mark-as-paid |
| Split payment UX | FINC-05 | Two-step payment form | Complete appointment with two payment methods |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
