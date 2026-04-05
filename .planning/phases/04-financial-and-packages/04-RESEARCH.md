# Phase 04: Financial and Packages — Research

**Researched:** 2026-04-05
**Domain:** Financial dashboard, session packages, commissions, payment recording
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Dashboard financeiro — Layout**
- Resumo com KPIs no topo: Faturamento total, Ticket medio, Taxa de ocupacao, Total de atendimentos
- KPIs com comparacao ao periodo anterior (seta verde/vermelha + %)
- Seletor de periodo: chips Dia / Semana / Mes
- Lista de pagamentos recentes abaixo dos KPIs
- Filtros na lista: por profissional e por metodo de pagamento (filter chips)
- Secoes expansiveis abaixo: "Por profissional" e "Por servico" com ranking, valor e %
- Acessivel via "Mais > Financeiro"

**Dashboard financeiro — Visao da colaboradora**
- Colaboradora ve resumo pessoal: seus atendimentos concluidos, seu faturamento gerado, sua comissao calculada
- Nao ve dados de outras profissionais nem do estudio (consistente com Phase 2)

**Dashboard financeiro — Navegacao**
- Tela Financeiro com tabs: [Resumo] [Comissoes]
- Tab Resumo = KPIs + pagamentos recentes + breakdowns
- Tab Comissoes = listagem por profissional com status pago/pendente

**Pacotes de sessoes — Criacao**
- Dois caminhos: dentro do servico (secao "Pacotes") E tela separada global (Mais > Pacotes)
- Pacote sempre vinculado a um servico (relacao 1:N no DB ja existe)
- Campos: nome, total de sessoes, preco, validade em dias

**Pacotes de sessoes — Venda**
- Dois caminhos: botao "+ Vender pacote" na ficha da cliente E indicacao no QuickBookSheet durante agendamento
- Na ficha da cliente: secao "Pacotes ativos" mostra pacotes vigentes com sessoes usadas/total e data de expiracao
- Venda registra assinatura (package_subscription) com data de inicio e validade
- Permite parcelamento: dona pode parcelar o pacote (ex: 3x R$200) com registro de parcelas e vencimento

**Pacotes de sessoes — Vinculo no agendamento**
- Automatico com confirmacao: se cliente tem pacote ativo para o servico, checkbox "Usar pacote (3/5 sessoes)" aparece pre-marcado no QuickBookSheet
- Profissional pode desmarcar para cobrar avulso
- Pacote so se aplica ao servico vinculado — outro servico = automaticamente avulso

**Pacotes de sessoes — Deducao**
- Deducao na conclusao do atendimento (nao no agendamento) — decisao do roadmap
- Se atendimento vinculado a pacote: pula payment sheet, deduz sessao automaticamente, toast com feedback ("Sessao deduzida — Pacote Lash 5x: 1 restante")
- Se nao vinculado a pacote: fluxo normal com payment sheet

**Pacotes de sessoes — Ultima sessao**
- Ao completar a ultima sessao: dialog/toast avisando "Ultima sessao do pacote [nome] da [cliente]"
- Botao para renovar (criar nova assinatura do mesmo pacote)

**Pacotes de sessoes — Expiracao**
- Expiracao flexivel: pacote expirado fica com badge "Expirado" e nao permite uso automatico
- Dona pode estender a validade manualmente na ficha da cliente (editar data de expiracao)

**Pacotes de sessoes — Financeiro**
- Venda de pacote aparece como receita no dashboard no periodo em que foi vendida
- Tipo "Pacote" no registro de pagamento para distinguir de avulso

**Comissoes — Visualizacao**
- Tab "Comissoes" dentro da tela Financeiro
- Lista profissionais com comissao acumulada no periodo + status (Pendente/Pago)
- Tap numa profissional abre detalhamento: cada atendimento + valor da comissao

**Comissoes — Periodo**
- Configuravel: quinzenal ou mensal (dona configura nas settings do estudio)
- Seletor de periodo: < Abril 2026 > (ou quinzena)

**Comissoes — Calculo**
- Calculada automaticamente ao completar cada atendimento (tempo real, nao batch)
- Hook no completeAppointment() ja existe como ponto de integracao
- Percentual por profissional (ja configurado na Phase 2)

**Comissoes — Pacotes**
- Comissao proporcional: valor unitario da sessao (preco pacote / total sessoes)
- Ex: pacote 5x R$600 = R$120/sessao. Comissao 30% = R$36 por sessao completada

**Comissoes — Marcar como pago**
- Botao/swipe "Marcar como pago" por profissional para o periodo selecionado
- Muda status de pendente para pago com registro de data

**Comissoes — Taxa do cartao**
- Mostrar deducao no detalhe: Valor atendimento -> Taxa cartao -> Comissao liquida
- Politica (quem paga) ja configurada por profissional (Phase 2): studio_absorbs, professional_absorbs, split
- Taxa configuravel pela dona por metodo de pagamento nas settings do estudio (credito, debito; PIX e dinheiro = 0%)

**Pagamento — Desconto**
- Campo "Desconto" no payment sheet: valor em R$ ou %
- Valor final recalculado automaticamente
- Comissao calculada sobre valor liquido (apos desconto)
- Motivo do desconto: campo opcional que aparece quando desconto > 0
- Sugestoes rapidas: "Cortesia", "Fidelidade", "Pacote"

**Pagamento — Permissao de desconto**
- Dona configura % maximo de desconto que colaboradora pode dar (ex: ate 10%)
- Acima do limite, so a dona pode aplicar
- Configuravel nas settings do estudio

**Pagamento — Split de metodos**
- Permitir dois metodos de pagamento por atendimento (ex: R$100 PIX + R$50 credito)
- UX: selecionar primeiro metodo + valor, opcao "+ Adicionar metodo" para segundo

### Claude's Discretion
- Loading skeletons para dashboard e listas
- Exato design dos KPI cards (tamanho, cores, icones)
- Implementacao do grafico de comparacao (se inline nos cards ou secao separada)
- Animacoes de transicao entre tabs Resumo/Comissoes
- Design da tela global de pacotes (Mais > Pacotes)
- UX do parcelamento de pacotes (formulario, campos)
- Design do dialog de renovacao de pacote
- Skeleton/empty states para tela financeiro
- Ordem e agrupamento dos filtros
- Como exibir parcelas pendentes/pagas na ficha do pacote

### Deferred Ideas (OUT OF SCOPE)
- Export de relatorios financeiros (PDF/CSV) — v2, REPT-01
- Comparacao ano-a-ano — v2, REPT-02
- Split automatico de pagamento via gateway (auto-payout para profissional) — explicitamente fora do escopo v1
- Nota fiscal / integracao fiscal — complexidade tributaria alta, fora do escopo
- Pacotes com servicos multiplos — futuro
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| SERV-03 | Owner can create session packages with special pricing | `packages` table exists; CRUD routes stubbed; PackageRepository and PackageController/Service need implementation |
| SERV-04 | Sessions deducted automatically when appointment is completed (not on booking) | `completeAppointment()` is the hook; needs `package_subscription_id` on appointments + deduction logic |
| SERV-05 | Packages have configurable expiration date | `validity_days` column exists in packages; `expires_at` computed on subscription creation |
| FINC-01 | Owner views revenue dashboard by day/week/month | `financial_summaries` materialized view exists; `GET /financial/summary` route stubbed; FinancialController/Service needed |
| FINC-02 | Owner views revenue breakdown by professional and by service | Not in materialized view — requires live query on payments + JOIN to professional/service |
| FINC-03 | Owner views average ticket value | `avg_ticket` column in `financial_summaries` materialized view |
| FINC-04 | Owner views agenda occupancy rate | Not in materialized view — must be computed: completed_slots / total_available_slots within period |
| FINC-05 | Owner records payment method per appointment (cash, PIX, debit, credit) | `PaymentSheet` already exists; needs discount + split-method extension |
</phase_requirements>

---

## Summary

Phase 4 is primarily a back-fill phase: the data models, routes, and Flutter widget scaffolding already exist from the architectural planning in phases 1–3. The work is implementing the business logic that connects them. Every backend route in this phase is currently a `throw new Error("Not implemented")` stub — PaymentController, PackageController, PackageSubscriptionController, CommissionController, and FinancialController all need to be created and wired up. The `AppointmentService.completeAppointment()` method is the integration hub: it must be extended to optionally deduce a package session and always calculate a commission when completing an appointment.

The financial dashboard has a split architecture: aggregate KPIs come from the `financial_summaries` materialized view (already defined in migration 001), while breakdowns by professional and by service need live queries against `payments` with JOINs. The materialized view does NOT include occupancy rate or period-over-period comparison — those must be computed on demand. The view also lacks a `type` column to distinguish package sales from individual payments, which requires a schema migration to add a `type` field to the `payments` table.

On the Flutter side, the existing `PaymentSheet` widget is the foundation; it must be extended with discount logic and split-method support. The `QuickBookSheet` needs a package-detection step. The `more_screen.dart` has the Financial menu item already rendered as "Em breve" — it just needs its `onTap` wired and the financial feature screens created.

**Primary recommendation:** Implement backend services first (commission calculation, package deduction, financial queries) with full test coverage, then extend existing Flutter widgets and add new screens following the sealed-state pattern already in use.

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Fastify | existing | HTTP server | Project standard |
| Zod | existing | Input validation | Project standard — boundary validation |
| pg (node-postgres) | existing | SQL queries | Project standard — direct SQL, no ORM |
| Vitest | existing | Backend unit tests | Project standard |
| Flutter + Riverpod | existing | Mobile state management | Project standard |
| GoRouter | existing | Mobile navigation | Project standard |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| BullMQ | existing | Async job queue | Refreshing `financial_summaries` after payment recording |
| Supabase Postgres | existing | Materialized view, RLS | Financial summary storage + tenant isolation |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Materialized view refresh via BullMQ | Real-time aggregation via SQL window functions on each request | BullMQ approach is correct — live aggregation is too slow at scale. Use materialized view + async refresh |
| Manual commission calculation on demand | Pre-computed commission rows | Pre-computation (Commission row per appointment) is already the schema — don't deviate |

**Installation:** No new dependencies required — all libraries already in use.

---

## Architecture Patterns

### Backend Layer Pattern (Established)

```
Route (Zod validation) → Controller (HTTP boundary) → Service (business logic) → Repository (SQL)
```

All new backend components must follow this pattern exactly. The CONTEXT.md integration points map cleanly:

- `completeAppointment()` in `AppointmentService` → extend with commission calculation + package deduction
- Commission calculation belongs in a new `CommissionService`
- Package deduction belongs in a new `PackageService` (or `PackageSubscriptionService`)
- Financial queries belong in a new `FinancialService`

### Recommended Feature Structure (Backend)

```
backend/src/
├── repositories/
│   ├── payment.repository.ts        # extend: add list(), needs discount + type fields
│   ├── commission.repository.ts     # new: create(), list(), markPaid()
│   ├── package.repository.ts        # new: CRUD + getByServiceForClient()
│   └── package-subscription.repository.ts  # new: create(), deductSession(), getActive()
├── services/
│   ├── appointment.service.ts       # extend: completeAppointment() hooks
│   ├── commission.service.ts        # new: calculate(), list(), markPaid()
│   ├── package.service.ts           # new: CRUD + subscription management
│   └── financial.service.ts         # new: summary(), paymentsBreakdown()
└── controllers/
    ├── commission.controller.ts     # new
    ├── package.controller.ts        # new
    ├── package-subscription.controller.ts  # new
    └── financial.controller.ts      # new
```

### Recommended Feature Structure (Flutter)

```
mobile/lib/features/
├── financial/
│   ├── models/
│   │   ├── financial_summary_model.dart
│   │   ├── payment_model.dart
│   │   └── commission_model.dart
│   ├── repositories/
│   │   ├── financial_repository.dart
│   │   └── commission_repository.dart
│   ├── providers/
│   │   ├── financial_provider.dart
│   │   └── commission_provider.dart
│   └── screens/
│       ├── financial_dashboard_screen.dart  # tabs: Resumo + Comissoes
│       ├── payments_list_screen.dart
│       └── commission_detail_screen.dart
└── packages/
    ├── models/
    │   ├── package_model.dart
    │   └── package_subscription_model.dart
    ├── repositories/
    │   └── package_repository.dart
    ├── providers/
    │   └── package_provider.dart
    └── screens/
        └── packages_management_screen.dart
```

### Pattern 1: Commission Calculation on Appointment Completion

**What:** When `completeAppointment()` runs, it must calculate and INSERT a commission row atomically in the same transaction.

**When to use:** Always — every completed appointment with a payment triggers a commission row (even if commission_value = 0).

**Example:**
```typescript
// backend/src/services/commission.service.ts
async calculateAndRecord(params: {
  studioId: string;
  appointmentId: string;
  professionalId: string;
  paymentAmount: number;  // net amount after discount
  paymentMethod: PaymentMethod;
  periodStart: Date;
  periodEnd: Date;
}): Promise<CommissionRow> {
  const professional = await this.professionalRepo.getById(params.studioId, params.professionalId);

  // Card fee calculation
  const cardFeeAmount = this.calcCardFee(params.paymentAmount, params.paymentMethod, professional.card_fee_policy);

  // Commission base: net amount after card fee (if professional absorbs)
  const commissionBase = professional.card_fee_policy === 'professional'
    ? params.paymentAmount - cardFeeAmount
    : params.paymentAmount;

  const professionalAmount = professional.commission_type === 'percentage'
    ? Math.round(commissionBase * professional.commission_value / 100)
    : professional.commission_value; // fixed value in cents

  const studioAmount = params.paymentAmount - cardFeeAmount - professionalAmount;

  return this.commissionRepo.create({
    studioId: params.studioId,
    professionalId: params.professionalId,
    appointmentId: params.appointmentId,
    amount: params.paymentAmount,
    studioAmount,
    professionalAmount,
    cardFeeAmount,
    whoPaidFee: professional.card_fee_policy,
    periodStart: params.periodStart,
    periodEnd: params.periodEnd,
  });
}
```

### Pattern 2: Package Session Deduction (Atomic)

**What:** Session deduction must be atomic — check active subscription AND decrement sessions_used in a single DB operation to prevent race conditions.

**When to use:** When completing an appointment that has `package_subscription_id` set.

**Example:**
```sql
-- backend/src/repositories/package-subscription.repository.ts
-- Use UPDATE ... RETURNING to atomically deduct and get result
UPDATE package_subscriptions
SET sessions_used = sessions_used + 1,
    status = CASE
      WHEN sessions_used + 1 >= sessions_total THEN 'completed'
      ELSE 'active'
    END,
    updated_at = now()
WHERE id = $1
  AND studio_id = $2
  AND status = 'active'
  AND expires_at > now()
RETURNING id, sessions_used, sessions_total, status, expires_at;
-- If 0 rows returned: subscription expired or already completed → raise error
```

### Pattern 3: Sealed State in Flutter Financial Providers

**What:** All financial providers use the existing sealed state pattern (Loading / Loaded / Error).

**When to use:** Every Riverpod AsyncNotifier for financial data.

**Example:**
```dart
// mobile/lib/features/financial/providers/financial_provider.dart
@riverpod
class FinancialDashboardNotifier extends _$FinancialDashboardNotifier {
  @override
  Future<FinancialDashboardState> build() async => _load();

  Future<FinancialDashboardState> _load() async {
    final repo = ref.read(financialRepositoryProvider);
    final summary = await repo.getSummary(period: state.period);
    return FinancialDashboardState(summary: summary, period: state.period);
  }

  Future<void> changePeriod(FinancialPeriod period) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _load());
  }
}
```

### Pattern 4: Financial Summary — Day/Week/Month Support

The existing materialized view aggregates only by `period_year` and `period_month`. The CONTEXT.md requires Dia/Semana/Mes chips on the dashboard. This means:

- **Month:** Use materialized view (`GET /financial/summary?year=&month=`)
- **Day/Week:** Must query `payments` table directly (live query), since the materialized view has no day or week granularity

The `FinancialService.summary()` method must handle both paths:

```typescript
// Month → materialized view (fast)
// Day/Week → live query on payments with date range filter
async summary(studioId: string, params: { period: 'day' | 'week' | 'month', date: string }) {
  if (params.period === 'month') {
    return this.financialRepo.getFromMaterializedView(studioId, year, month);
  }
  return this.financialRepo.getLiveQuery(studioId, dateFrom, dateTo);
}
```

### Pattern 5: Split Payment Recording

The existing `payments` table has a single `amount` and `method`. Split-method support (R$100 PIX + R$50 crédito) requires recording TWO payment rows per appointment. The API contract does not currently define split payment — this is a schema/API gap that must be resolved before implementation.

**Recommended approach:** Two separate payment rows for the same `appointment_id`, each with their own `amount` and `method`. The financial queries must SUM all payment rows per appointment. The `PaymentSheet` on mobile collects both entries before submitting.

### Anti-Patterns to Avoid

- **Refresh materialized view synchronously in request handler:** Always queue a BullMQ job after payment insert, never REFRESH in the HTTP response cycle
- **Commission calculation in the controller:** Must be in `CommissionService`, called from `AppointmentService.completeAppointment()` inside a DB transaction
- **SELECT * in financial queries:** The DOMAIN_MODEL and CLAUDE.md both forbid this — always list columns explicitly
- **Float arithmetic for monetary values:** All amounts in centavos (INTEGER). Commission calculation with `Math.round()` applied at final step only
- **Package deduction outside a transaction:** The check-and-decrement must be atomic — use `UPDATE ... WHERE status = 'active' ... RETURNING` pattern
- **Occupancy rate in materialized view:** The view doesn't have it and can't without knowing working hours — compute on-demand or store separately

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Commission sum by period | Custom aggregation logic | SQL GROUP BY on commissions table with period_start/period_end filter | DB handles this efficiently with the existing index |
| Monetary rounding | Custom floating-point math | Integer centavos + `Math.round()` at final step | Floating point drift accumulates over many calculations |
| Concurrent session deduction | Application-level lock | `UPDATE ... WHERE status = 'active' RETURNING` pattern | Postgres handles concurrent writes atomically |
| Financial summary aggregation | Real-time SQL on every request | Materialized view + BullMQ refresh | Aggregating payments table across all tenants is O(N) — cache it |
| Currency formatting in Flutter | Custom formatter | `NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')` from `intl` package | Already a project dependency for locale support |

**Key insight:** The commission and package deduction logic looks simple but has many edge cases (card fee policy, discount on base, package vs. avulso, split-method totals, period boundaries). All of this must be in the Service layer with unit tests — never in controllers or widgets.

---

## Common Pitfalls

### Pitfall 1: Materialized View Does Not Auto-Refresh

**What goes wrong:** Developer inserts a payment and queries `/financial/summary` — data is stale because the materialized view wasn't refreshed.

**Why it happens:** `REFRESH MATERIALIZED VIEW CONCURRENTLY` must be called explicitly. There is no auto-trigger.

**How to avoid:** After every payment insertion in `PaymentRepository.create()`, enqueue a BullMQ job `refreshFinancialSummary(studioId)`. The job runs `REFRESH MATERIALIZED VIEW CONCURRENTLY financial_summaries`. Deduplicate jobs with a per-studio queue key to avoid thundering herd.

**Warning signs:** Dashboard shows R$0 or yesterday's total immediately after completing an appointment.

---

### Pitfall 2: Discount Does Not Exist in Current Schema

**What goes wrong:** The `payments` table has no `discount_amount` or `discount_reason` column. The CONTEXT.md requires discount recording with commission calculated on the net value.

**Why it happens:** Discount was not in Phase 3 scope and wasn't added to the initial schema.

**How to avoid:** Migration needed (`011_add_discount_to_payments.sql`) to add:
- `discount_amount INTEGER NOT NULL DEFAULT 0` (centavos)
- `discount_reason TEXT` (nullable)

Commission must then be calculated on `amount - discount_amount`.

---

### Pitfall 3: Payment Type Not in Schema

**What goes wrong:** The CONTEXT.md says "Venda de pacote aparece como receita no dashboard no periodo em que foi vendida" with a "Tipo Pacote" distinction. The current `payments` table has no `type` column.

**Why it happens:** The initial schema was designed before package payment flows were detailed.

**How to avoid:** Migration needed to add `type TEXT NOT NULL DEFAULT 'avulso' CHECK IN ('avulso', 'pacote')` to the `payments` table. Package subscription purchase creates a payment with `type = 'pacote'`.

---

### Pitfall 4: Occupancy Rate Requires Working Hours Data

**What goes wrong:** FINC-04 requires occupancy rate. The `financial_summaries` view has no `occupancy_rate` column (DOMAIN_MODEL.md lists it as a field, but the SQL in migration 001 does NOT compute it).

**Why it happens:** Occupancy rate = completed_appointments_minutes / total_available_working_minutes in the period. This requires working_hours JSONB from the professionals table, which can't easily be joined in a materialized view without significant complexity.

**How to avoid:** Compute occupancy rate on-demand in `FinancialService`:

```typescript
// For each professional in the period:
// availableMinutes = sum of working_hours slots across each day in period
// usedMinutes = sum of (end_time - start_time) for completed appointments
// occupancyRate = usedMinutes / availableMinutes
```

Or: add `occupancy_rate` as a separate BullMQ-computed metric stored in `studio_settings` or a new table. The simplest v1 approach: compute on-demand with a single query joining appointments + professionals, cached per request.

---

### Pitfall 5: Package Subscription on QuickBookSheet — Race Condition

**What goes wrong:** Client has 1 session left on a package. Two professionals are booking simultaneously. Both see "1 session remaining" and both proceed, but only one deduction should succeed.

**Why it happens:** The QuickBookSheet check is a read, not a lock.

**How to avoid:** The package is only LINKED at booking time (stored as `package_subscription_id` on the appointment). Deduction happens ONLY on completion via the atomic `UPDATE ... WHERE status = 'active'` pattern. If the deduction fails (0 rows returned), the completion handler returns a graceful error and clears the package link — the appointment still completes as avulso.

---

### Pitfall 6: Commission Period Boundary — Quinzenal vs Mensal

**What goes wrong:** The commission `period_start` / `period_end` on each Commission row must match the studio's configured period (quinzenal or mensal). If this isn't computed correctly at insert time, the period grouping in the Commissions tab will be wrong.

**Why it happens:** The period boundary calculation must read `studio.settings` at commission creation time.

**How to avoid:** `CommissionService.calculateAndRecord()` reads the studio's commission period setting and computes the correct `period_start`/`period_end` for the appointment's date before inserting:

```typescript
function getPeriodBoundaries(date: Date, periodType: 'monthly' | 'biweekly'): { start: Date, end: Date } {
  if (periodType === 'monthly') {
    return { start: startOfMonth(date), end: endOfMonth(date) };
  }
  // biweekly: days 1–15 = first half, 16–end = second half
  const day = date.getDate();
  if (day <= 15) {
    return { start: startOfMonth(date), end: setDate(date, 15) };
  }
  return { start: setDate(date, 16), end: endOfMonth(date) };
}
```

---

### Pitfall 7: Split Payment Creates Two Payment Rows — Aggregation Must SUM

**What goes wrong:** Financial queries that count distinct payment rows to compute `avg_ticket` will be wrong if an appointment has two payment rows (split method).

**Why it happens:** The current `financial_summaries` view groups by appointment implicitly through payments. If one appointment has two rows, `COUNT(p.id)` overcounts.

**How to avoid:** The materialized view aggregation and any live query for avg_ticket must group by `appointment_id` first, then aggregate:

```sql
SELECT
  studio_id,
  SUM(total_per_appt) AS total_revenue,
  AVG(total_per_appt) AS avg_ticket,
  COUNT(DISTINCT appointment_id) AS total_appointments
FROM (
  SELECT studio_id, appointment_id, SUM(amount) AS total_per_appt
  FROM payments
  WHERE studio_id = $1
  GROUP BY studio_id, appointment_id
) sub
```

This requires a migration to fix the `financial_summaries` view definition.

---

## Code Examples

### Repository: List Payments with JOIN

```typescript
// backend/src/repositories/payment.repository.ts
async list(studioId: string, filters: {
  dateFrom?: string;
  dateTo?: string;
  method?: PaymentMethod;
  professionalId?: string;
  cursor?: string;
  limit?: number;
}): Promise<{ rows: PaymentWithRelations[], hasMore: boolean }> {
  const limit = filters.limit ?? 20;
  const params: unknown[] = [studioId];
  const conditions: string[] = ['p.studio_id = $1'];

  if (filters.dateFrom) { params.push(filters.dateFrom); conditions.push(`p.created_at::date >= $${params.length}`); }
  if (filters.dateTo)   { params.push(filters.dateTo);   conditions.push(`p.created_at::date <= $${params.length}`); }
  if (filters.method)   { params.push(filters.method);   conditions.push(`p.method = $${params.length}`); }
  if (filters.professionalId) { params.push(filters.professionalId); conditions.push(`a.professional_id = $${params.length}`); }
  if (filters.cursor)   { params.push(filters.cursor);   conditions.push(`p.id > $${params.length}`); }

  params.push(limit + 1);
  const { rows } = await this.pool.query<PaymentWithRelations>(`
    SELECT
      p.id, p.amount, p.method, p.card_fee_percentage, p.discount_amount,
      p.discount_reason, p.type, p.created_at,
      a.id AS appointment_id, a.date AS appointment_date,
      c.id AS client_id, c.name AS client_name,
      pr.id AS professional_id, pr.name AS professional_name
    FROM payments p
    JOIN appointments a ON a.id = p.appointment_id
    JOIN clients c ON c.id = p.client_id
    JOIN professionals pr ON pr.id = a.professional_id
    WHERE ${conditions.join(' AND ')}
    ORDER BY p.created_at DESC, p.id DESC
    LIMIT $${params.length}
  `, params);

  const hasMore = rows.length > limit;
  return { rows: rows.slice(0, limit), hasMore };
}
```

### Service: completeAppointment Extension Pattern

```typescript
// backend/src/services/appointment.service.ts — extended completeAppointment
async completeAppointment(
  studioId: string,
  appointmentId: string,
  payload?: {
    payment?: { amount: number; method: PaymentMethod; cardFeePercentage?: number; discountAmount?: number; discountReason?: string; type?: 'avulso' | 'pacote' };
    packageSubscriptionId?: string;
  },
): Promise<{ appointment: AppointmentRow; lastSession: boolean }> {
  const appt = await this._transition(studioId, appointmentId, 'completed');
  let lastSession = false;

  if (payload?.packageSubscriptionId) {
    // Deduct session — atomic UPDATE
    const result = await this.packageSubRepo.deductSession(studioId, payload.packageSubscriptionId);
    if (!result) throw new UnprocessableError('PACKAGE_UNAVAILABLE', 'Package session could not be deducted');
    lastSession = result.status === 'completed';
    // Commission uses package unit price
    const unitPrice = await this.packageRepo.getUnitPrice(studioId, result.packageId);
    await this.commissionService.calculateAndRecord({ studioId, appointmentId, professionalId: appt.professional_id, paymentAmount: unitPrice, paymentMethod: 'package' });
  } else if (payload?.payment) {
    await this.paymentRepo.create({ studioId, appointmentId, ...payload.payment });
    await this.commissionService.calculateAndRecord({ studioId, appointmentId, professionalId: appt.professional_id, paymentAmount: payload.payment.amount - (payload.payment.discountAmount ?? 0), paymentMethod: payload.payment.method });
    // Enqueue BullMQ job to refresh materialized view
    await this.financialRefreshQueue.add('refresh', { studioId });
  }

  return { appointment: appt, lastSession };
}
```

### Flutter: PaymentSheet — Discount Extension Pattern

```dart
// Extend existing PaymentSheet state to add discount support
int _discountCents = 0;
String _discountReason = '';
bool _showDiscountField = false;

int get _finalAmountCents => _amountCents - _discountCents;

// Discount presets (Claude's discretion: use quick chips)
static const _discountPresets = ['Cortesia', 'Fidelidade', 'Pacote'];
```

### Flutter: Package Detection in QuickBookSheet

```dart
// After client + service selected, check for active package subscription
Future<PackageSubscription?> _checkActivePackage(String clientId, String serviceId) async {
  final repo = ref.read(packageRepositoryProvider);
  return repo.getActiveForClientAndService(clientId: clientId, serviceId: serviceId);
}

// Show checkbox if package found
if (_activePackage != null)
  CheckboxListTile(
    value: _usePackage,
    onChanged: (v) => setState(() => _usePackage = v ?? true),
    title: Text('Usar pacote (${_activePackage!.sessionsUsed}/${_activePackage!.sessionsTotal} sessões)'),
  )
```

---

## Schema Gaps — Migrations Required

These are missing from the current schema and must be added before implementation:

### Migration 011: Add discount fields to payments

```sql
ALTER TABLE payments
  ADD COLUMN discount_amount  INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN discount_reason  TEXT,
  ADD COLUMN type             TEXT NOT NULL DEFAULT 'avulso'
                              CHECK (type IN ('avulso', 'pacote'));
```

### Migration 012: Add package_subscription_id to appointments

The appointment must record which package subscription it's using (for deduction on completion):

```sql
ALTER TABLE appointments
  ADD COLUMN package_subscription_id UUID REFERENCES package_subscriptions(id);
```

### Migration 013: Fix financial_summaries view for split payments

```sql
DROP MATERIALIZED VIEW IF EXISTS financial_summaries;

CREATE MATERIALIZED VIEW financial_summaries AS
SELECT
  appt_totals.studio_id,
  EXTRACT(YEAR  FROM appt_totals.created_at)::INTEGER AS period_year,
  EXTRACT(MONTH FROM appt_totals.created_at)::INTEGER AS period_month,
  SUM(appt_totals.total_per_appt)                     AS total_revenue,
  COALESCE(SUM(comm.total_professional), 0)            AS total_commissions,
  CASE WHEN COUNT(appt_totals.appointment_id) > 0
    THEN SUM(appt_totals.total_per_appt) / COUNT(appt_totals.appointment_id)
    ELSE 0
  END                                                  AS avg_ticket,
  COUNT(appt_totals.appointment_id)                    AS total_appointments
FROM (
  SELECT
    p.studio_id,
    p.appointment_id,
    MAX(p.created_at) AS created_at,
    SUM(p.amount - p.discount_amount) AS total_per_appt
  FROM payments p
  GROUP BY p.studio_id, p.appointment_id
) appt_totals
LEFT JOIN LATERAL (
  SELECT SUM(c.professional_amount) AS total_professional
  FROM commissions c
  WHERE c.appointment_id = appt_totals.appointment_id
) comm ON true
GROUP BY appt_totals.studio_id, period_year, period_month;

CREATE UNIQUE INDEX financial_summaries_key
  ON financial_summaries (studio_id, period_year, period_month);
```

### Migration 014: Add commission period setting to studio settings

The `studios.settings` JSONB must accept `commission_period: 'monthly' | 'biweekly'` and `card_fee_rates: { credit: number, debit: number }`. No schema migration needed (JSONB), but the Zod validator for studio settings must be extended.

---

## State of the Art

| Old Approach | Current Approach | Impact |
|--------------|------------------|--------|
| Financial view refreshed on HTTP request | BullMQ async refresh via `REFRESH CONCURRENTLY` | No request blocking, always eventually consistent |
| Single payment row per appointment | Two payment rows for split method, aggregated by appointment_id | Correct avg_ticket calculation |
| Commission calculated as batch job | Commission calculated per-appointment at completion time | Real-time accuracy, simpler retry logic |

**Existing but not yet connected:**
- `financial_summaries` view: exists in DB, but `FinancialController` not implemented
- `commissions` table: exists in DB, but `CommissionController` + `CommissionService` not implemented
- All financial routes: stubbed, throw `Not implemented`

---

## Open Questions

1. **Occupancy rate day/week/month granularity**
   - What we know: DOMAIN_MODEL.md lists `occupancy_rate` as a field of FinancialSummary but the SQL view does not compute it; the CONTEXT.md requires it as a KPI
   - What's unclear: Whether occupancy should be computed per studio (all professionals combined) or per professional; how to handle professionals with different working hours
   - Recommendation: Compute on-demand in `FinancialService` for the selected period, aggregating across all active professionals. Formula: `SUM(completed_appointment_minutes) / SUM(available_working_minutes)`. No DB storage needed for v1.

2. **Parcelamento de pacotes (installments)**
   - What we know: CONTEXT.md says "Permite parcelamento: dona pode parcelar o pacote (ex: 3x R$200) com registro de parcelas e vencimento"
   - What's unclear: There is no `installments` table in the current schema. The UX/design is Claude's discretion.
   - Recommendation: For v1, record installment information as JSONB on the `package_subscriptions` table (or add a simple `installments` TEXT column encoding "3x200"). Full installment tracking table is v2 complexity. This needs a clarification from the planner before implementation.

3. **BullMQ queue for financial refresh**
   - What we know: The architecture doc says materialized view should be refreshed via BullMQ
   - What's unclear: Whether a BullMQ queue instance already exists in the backend for financial jobs, or needs to be bootstrapped
   - Recommendation: Check `backend/src/jobs/` — if no queue exists, create a minimal `FinancialRefreshQueue` following any existing BullMQ patterns in the project.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Vitest |
| Config file | `backend/vitest.config.ts` |
| Quick run command | `cd backend && npm run test -- --reporter=verbose` |
| Full suite command | `cd backend && npm run test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SERV-03 | Owner creates package with service_id, name, sessions, price, validity | unit | `npm run test -- services/package.service.test.ts` | ❌ Wave 0 |
| SERV-03 | Package creation fails if service_id not found | unit | `npm run test -- services/package.service.test.ts` | ❌ Wave 0 |
| SERV-04 | Sessions deducted atomically on appointment completion | unit | `npm run test -- services/package-subscription.service.test.ts` | ❌ Wave 0 |
| SERV-04 | Deduction fails gracefully if subscription expired | unit | `npm run test -- services/package-subscription.service.test.ts` | ❌ Wave 0 |
| SERV-04 | No payment sheet when package is used; commission uses unit price | unit | `npm run test -- services/appointment.service.test.ts` | Partial — file exists, complete() hook tests needed |
| SERV-05 | Package subscription expires_at = now() + validity_days | unit | `npm run test -- services/package.service.test.ts` | ❌ Wave 0 |
| FINC-01 | FinancialService returns summary from materialized view for month period | unit | `npm run test -- services/financial.service.test.ts` | ❌ Wave 0 |
| FINC-01 | FinancialService returns live query for day/week periods | unit | `npm run test -- services/financial.service.test.ts` | ❌ Wave 0 |
| FINC-02 | Breakdown by professional returns ranked list with amounts | unit | `npm run test -- services/financial.service.test.ts` | ❌ Wave 0 |
| FINC-03 | avg_ticket calculated correctly (split-method: SUM per appt / COUNT appts) | unit | `npm run test -- services/financial.service.test.ts` | ❌ Wave 0 |
| FINC-04 | Occupancy rate computed as completed_minutes / available_minutes | unit | `npm run test -- services/financial.service.test.ts` | ❌ Wave 0 |
| FINC-05 | Payment recorded with method, discount, commission on completion | unit | `npm run test -- services/appointment.service.test.ts` | Partial — extend existing |
| FINC-05 | Discount enforces max_discount_percentage for non-owner role | unit | `npm run test -- services/commission.service.test.ts` | ❌ Wave 0 |
| FINC-05 | Commission calculated on net amount (after discount) | unit | `npm run test -- services/commission.service.test.ts` | ❌ Wave 0 |
| FINC-05 | Commission uses card_fee_policy: studio / professional / split | unit | `npm run test -- services/commission.service.test.ts` | ❌ Wave 0 |
| Multi-tenancy | Studio A cannot read Studio B payments/commissions | unit | `npm run test -- services/financial.service.test.ts` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `cd backend && npm run test -- --reporter=dot`
- **Per wave merge:** `cd backend && npm run test`
- **Phase gate:** Full suite green before `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `backend/tests/services/package.service.test.ts` — covers SERV-03, SERV-05
- [ ] `backend/tests/services/package-subscription.service.test.ts` — covers SERV-04
- [ ] `backend/tests/services/commission.service.test.ts` — covers FINC-05 commission logic
- [ ] `backend/tests/services/financial.service.test.ts` — covers FINC-01, FINC-02, FINC-03, FINC-04
- [ ] Extend `backend/tests/services/appointment.service.test.ts` — complete() hook for package deduction + commission

---

## Sources

### Primary (HIGH confidence)

- Direct code inspection: `backend/src/` — all services, repositories, routes, and controllers
- Direct schema inspection: `supabase/migrations/001_initial_schema.sql` — actual SQL definitions
- `docs/DATABASE_SCHEMA.md` — schema documentation
- `docs/API_CONTRACTS.md` — endpoint contracts
- `docs/DOMAIN_MODEL.md` — entity definitions
- `docs/SCREENS.md` — Flutter screen map with endpoints and states
- `.planning/phases/04-financial-and-packages/04-CONTEXT.md` — all locked user decisions

### Secondary (MEDIUM confidence)

- `docs/DESIGN_SYSTEM.md` + existing widgets — UI pattern consistency verified by reading `payment_sheet.dart`, `quick_book_sheet.dart`, `more_screen.dart`

### Tertiary (LOW confidence)

- Installments table design — no official decision recorded, design recommendation is researcher's assessment

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all libraries confirmed in existing codebase
- Architecture: HIGH — patterns confirmed by reading actual service/repository code
- Schema gaps: HIGH — confirmed by reading migration SQL directly
- Pitfalls: HIGH — derived from reading actual code paths and schema definitions
- Occupancy rate computation: MEDIUM — DOMAIN_MODEL lists it but implementation path inferred
- Installments: LOW — no schema decision made, recommendation is inference

**Research date:** 2026-04-05
**Valid until:** 2026-05-05 (stable domain, no fast-moving dependencies)
