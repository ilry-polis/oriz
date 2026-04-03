# Phase 3: Scheduling Engine - Research

**Researched:** 2026-04-03
**Domain:** Agendamento — Backend (Fastify/pg/Supabase) + Mobile (Flutter/Riverpod)
**Confidence:** HIGH

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Agenda visualization — Day view (primary)**
- Day view é a tela default com timeline vertical
- Timeline adapta start/end ao working_hours de cada profissional (não fixo 8-19h)
- Cards compactos: nome do cliente + nome do serviço + duração; altura reflete duração
- Color coding por status (pending, confirmed, completed, cancelled, no-show)
- Cards de completed/cancelled/no-show permanecem visíveis com opacidade 60%
- Buffer time entre agendamentos é invisível na UI — apenas enforced na lógica de slot calculation
- Tap no card abre detail bottom sheet; swipe e 3-dot menu para quick actions

**Agenda visualization — Week view**
- Grid com mini-blocks coloridos (sem texto) — colunas por dia
- Tap em um dia abre day view para aquela data

**Agenda visualization — Date navigation**
- DaySelector: row horizontal de day chips — já implementado
- Swipe horizontal no DaySelector muda de semana
- Tap no date label abre calendar picker para saltar a qualquer data

**Agenda visualization — Multi-professional (owner view)**
- Default view "Todas": PageView com horizontal snap — cada página é a daily timeline de uma profissional
- Nome da profissional exibido como header abaixo do date selector, com dot indicators
- Owner pode selecionar profissional específica via ícone de filtro
- Colaborador vê o mesmo layout mas sem filtro/seletor (apenas sua própria agenda)

**Appointment creation flow**
- Dois entry points: (1) tap em slot vazio (pré-preenche horário), (2) botão [+] no header
- Ambos abrem o mesmo bottom sheet
- Client selection: search box com autocomplete (estúdios têm 300+ clientes) — não chips
- "+ Novo cliente" inline: quick registration com name + phone apenas
- Service list: apenas serviços vinculados à profissional selecionada
- Profissional pré-selecionada da página atual do PageView; alterável via dropdown se owner
- Time: pré-preenchido do slot tapado, ajustável com sugestões de slots livres; time picker para horário customizado
- Conflict prevention: slots ocupados desabilitados nas sugestões; inline error se horário digitado manualmente conflita
- Notes: opcional, collapsed por default

**Appointment status workflow**
- Todos os agendamentos começam como **pending** (marcado), independente de quem cria
- Fluxo de confirmação por plano (WhatsApp em Phase 5.1/6, manual na Phase 3):
  - **Básico**: profissional confirma manualmente via swipe
- Studio configura quantas horas/dias antes do agendamento para disparar confirmação (campo stored agora, consumido pelas phases WhatsApp)
- Swipe behavior adapta ao status atual:
  - Pending: swipe ▶ = confirm, swipe ◀ = cancel
  - Confirmed: swipe ▶ = complete (abre payment sheet), swipe ◀ = cancel
- 3-dot context menu (bottom sheet): editar, ver cliente, marcar não compareceu, cancelar
- Cancel dialog: confirmação com campo de texto opcional (cancellation_reason stored no DB)

**Payment on completion**
- Completar agendamento abre payment bottom sheet
- Valor pré-preenchido do preço do serviço
- Seleção de método de pagamento: Dinheiro / PIX / Débito / Crédito
- Grava pagamento junto com conclusão em uma única ação

**Absences (formerly "blocked slots")**
- Terminologia: **ausência** (não "bloqueio" ou "pausa")
- Dois tipos:
  - **Pontual**: data/horário específico + título obrigatório (ex: "Dentista", "Reunião escola")
  - **Recorrente**: semanal simples — selecionar dias da semana + intervalo de horário + data final opcional
- Criação: long press em slot vazio → bottom sheet com toggle "Recorrente" sim/não
- Regra recorrente stored como JSONB: `{ frequency: "weekly", days: [...], until: date|null }`
- Exceções: tap em ausência recorrente → "Remover só este dia" ou "Remover todas" — exceções stored como lista de datas excluídas na rule
- Visual: mesmo padrão BlockedSlotCard (background neutral100, border neutral200, diagonal stripes, título + label "Ausência")

**Working hours configuration**
- Editado em Configurações > Meu horário (não na tela de agenda)
- Weekly grid igual ao onboarding da Phase 1: toggle dias on/off, start/end por dia, múltiplos intervalos por dia
- Owner pode editar horários de qualquer profissional; colaborador edita apenas os próprios
- Profissional herda horários do studio por default, pode fazer override (campo JSONB já existe)

### Claude's Discretion
- Design do loading skeleton para agenda
- Paleta de cores exata para os status states (pending, confirmed, completed, cancelled, no-show)
- Tamanho dos mini-blocks na week view e mapeamento de cores
- Ilustração e copy do empty state
- Implementação do calendar picker (Flutter DatePicker ou custom)
- Animações de transição entre day/week view
- Padrões de haptic feedback
- Tratamento de error states
- Estilo do page indicator do PageView (dots vs texto)
- Edição do valor no payment sheet (permitir override ou fixo do preço do serviço)

### Deferred Ideas (OUT OF SCOPE)
- Mensagens automáticas de confirmação via WhatsApp (Phase 5.1/6)
- Conversa de confirmação via IA (Phase 6 — plano Pro)
- Página de link de confirmação para clientes (Phase 5.1 — plano Intermediário)
- Google Calendar sync (v2 — PLAT-03)
- Agendamentos recorrentes (não ausências — ex: "Maria toda terça 10h") — feature futura
- Drag-and-drop para outra profissional (rescheduling cross-professional) — melhoria futura
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| SCHD-01 | Professional views agenda in day and week view | Day view existe (mock data); precisa de API real + week view + multi-professional PageView |
| SCHD-02 | System detects and prevents double-booking with DB-level constraint | Exclusion constraint `appointments_no_overlap` já existe; precisa adicionar 'pending' ao status check e revisar exclusão de no_show |
| SCHD-03 | Professional can block time slots (vacation, breaks, lunch) | blocked_slots table existe; precisa de migração para adicionar title + recurrence_rule + excluded_dates; lógica de expansão recorrente |
| SCHD-04 | Appointments follow status workflow: confirmed → completed/cancelled/no-show | Precisa adicionar 'pending' ao CHECK constraint; implementar AppointmentService com state machine; swipe diferenciado por status no Flutter |
| SCHD-05 | Business hours configurable per day of week per professional | working_hours JSONB já existe nos professionals; precisa de tela de edição (Configurações > Meu horário) + enforcement no service de available slots |
</phase_requirements>

---

## Summary

A Phase 3 é predominantemente de **implementação de lógica em cima de infraestrutura que já existe** — o schema, as rotas scaffolded, e os widgets Flutter estão todos presentes. O trabalho é preencher as camadas intermediárias (AppointmentService, AppointmentRepository, AppointmentController) no backend, e conectar a agenda mobile à API real enquanto evolui para o modelo de dados correto.

Existem três **gaps de schema** críticos que requerem migrações antes da implementação: (1) adição de 'pending' ao CHECK constraint de `appointments.status`, (2) adição de campos `title`, `recurrence_rule` e `excluded_dates` à tabela `blocked_slots`, e (3) revisão da exclusion constraint para excluir também `no_show` além de `cancelled`.

A lógica mais complexa da phase é o **cálculo de slots disponíveis** — cruzar working_hours, appointments existentes, blocked_slots (incluindo expansão de recorrência) e duração+buffer do serviço. Essa lógica é toda em TypeScript no service (não no banco) e é a peça que mais precisa de cobertura de testes.

No Flutter, o `AppointmentModel` atual usa mock data e tem apenas 4 status (sem 'pending'). A refatoração deve introduzir Riverpod providers reais, o AppointmentRepository que bate na API, e a lógica de swipe status-aware no `AppointmentCard`.

**Primary recommendation:** Comece pelas migrações de banco (Wave 0), depois backend service+repository+controller (Wave 1), depois Flutter conectado à API (Wave 2), depois week view + multi-professional (Wave 3), depois working hours config screen (Wave 4).

---

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Fastify | 4.x (existente) | Framework HTTP backend | Já em uso no projeto |
| pg (node-postgres) | existente | Queries SQL no backend | Padrão do projeto — sem ORM |
| Zod | 3.x (existente) | Validação de input no boundary | Padrão do projeto |
| Vitest | existente | Testes unitários backend | Padrão do projeto |
| Flutter | existente | UI mobile | Já em uso |
| flutter_riverpod | ^3.3.1 | State management no Flutter | Já em uso |
| go_router | ^17.1.0 | Navegação Flutter | Já em uso |
| http | ^1.4.0 | HTTP client Flutter → API | Já em uso |
| supabase_flutter | ^2.0.0 | Auth + Realtime no Flutter | Já em uso |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| btree_gist | extensão PG (existente) | Habilita exclusion constraint por tstzrange | Já instalada — necessária para SCHD-02 |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| SQL manual com pg | Drizzle ORM | SQL manual é o padrão do projeto; ORM aumentaria complexidade sem benefício na fase atual |
| Riverpod AsyncNotifier | StatefulWidget puro | Riverpod é o padrão; StatefulWidget criaria inconsistência com o resto do app |

**Installation:** Nenhum pacote novo necessário — toda a stack já está instalada.

---

## Architecture Patterns

### Recommended Project Structure

```
backend/src/
├── controllers/
│   ├── appointment.controller.ts    # NOVO
│   └── blocked-slot.controller.ts   # NOVO
├── services/
│   ├── appointment.service.ts       # NOVO — slot calculation, state machine
│   └── blocked-slot.service.ts      # NOVO — recurrence expansion
├── repositories/
│   ├── appointment.repository.ts    # NOVO
│   └── blocked-slot.repository.ts   # NOVO
└── routes/
    ├── appointments.routes.ts       # EXISTE (scaffolded) — conectar ao controller
    └── blocked-slots.routes.ts      # EXISTE (scaffolded) — conectar ao controller

supabase/migrations/
├── 010_add_pending_status.sql       # NOVO — adiciona 'pending' ao CHECK constraint
└── 011_blocked_slots_absences.sql   # NOVO — title, recurrence_rule, excluded_dates

mobile/lib/features/agenda/
├── agenda_day_screen.dart           # EXISTE — refatorar: mock → Riverpod real
├── models/
│   └── appointment_model.dart       # EXISTE — adicionar pending status, campos reais
├── providers/
│   ├── agenda_provider.dart         # NOVO
│   └── appointment_provider.dart    # NOVO
├── repositories/
│   └── appointment_repository.dart  # NOVO — chama API backend
└── widgets/
    ├── appointment_card.dart        # EXISTE — status-aware swipe
    ├── blocked_slot_card.dart       # EXISTE — adaptar para Absence com título
    ├── day_selector.dart            # EXISTE — adicionar PageView para week swiping
    ├── quick_book_sheet.dart        # EXISTE — refatorar: chips → search + API real
    ├── agenda_week_view.dart        # NOVO
    ├── create_absence_sheet.dart    # NOVO
    └── payment_sheet.dart          # NOVO
```

### Pattern 1: Status Machine no AppointmentService

**What:** O service é o único lugar que valida transições de status. Nunca no controller, nunca no Flutter.
**When to use:** Toda operação de status transition (confirm, complete, cancel, no-show).

```typescript
// Source: padrão do projeto (service.service.ts como referência)
const VALID_TRANSITIONS: Record<string, string[]> = {
  pending: ['confirmed', 'cancelled'],
  confirmed: ['completed', 'cancelled', 'no_show'],
  completed: [],
  cancelled: [],
  no_show: [],
};

async confirmAppointment(studioId: string, appointmentId: string): Promise<AppointmentRow> {
  const appt = await this.repo.getById(studioId, appointmentId);
  if (!appt) throw new NotFoundError(`Appointment ${appointmentId} not found`);

  if (!VALID_TRANSITIONS[appt.status]?.includes('confirmed')) {
    throw new UnprocessableError('INVALID_STATUS_TRANSITION');
  }

  return this.repo.updateStatus(studioId, appointmentId, 'confirmed');
}
```

### Pattern 2: Available Slot Calculation

**What:** O service calcula slots livres em memória, após buscar do banco: working_hours, appointments existentes, e blocked_slots (incluindo expansão de recorrência).
**When to use:** `GET /api/v1/appointments/available-slots`

```typescript
// Algoritmo central — toda a lógica fica no AppointmentService
async getAvailableSlots(studioId: string, date: string, professionalId: string, serviceId: string) {
  // 1. Buscar profissional + working_hours para a data
  const professional = await this.professionalRepo.getById(studioId, professionalId);
  const dayOfWeek = getDayOfWeek(date); // 'monday', 'tuesday', etc.
  const hours = professional.working_hours[dayOfWeek];
  if (!hours) return { date, slots: [] }; // profissional não trabalha nesse dia

  // 2. Gerar todos os slots possíveis (ex: a cada 15 min entre open e close)
  const allSlots = generateSlots(date, hours.open, hours.close, service.duration_minutes);

  // 3. Buscar appointments do dia para a profissional
  const appointments = await this.repo.listByProfessionalDate(studioId, professionalId, date);

  // 4. Buscar blocked_slots do dia (pontual + expansão de recorrência)
  const blocked = await this.blockedSlotService.getExpandedForDate(studioId, professionalId, date);

  // 5. Filtrar: slot é livre se não sobrepõe nem appointment nem blocked_slot
  return {
    date,
    slots: allSlots.filter(slot => !overlaps(slot, appointments, service) && !overlaps(slot, blocked))
  };
}
```

### Pattern 3: Recurrence Expansion no BlockedSlotService

**What:** `blocked_slots` recorrentes têm `recurrence_rule` JSONB. O service expande as regras para uma data específica, respeitando `excluded_dates`.
**When to use:** Sempre que buscar blocked_slots para calcular disponibilidade ou renderizar a agenda.

```typescript
// Source: decisão de design do CONTEXT.md
interface RecurrenceRule {
  frequency: 'weekly';
  days: number[]; // 0=Dom, 1=Seg, ..., 6=Sáb
  until: string | null; // ISO date ou null (sem fim)
}

function isRecurrenceActiveOnDate(rule: RecurrenceRule, date: string, excludedDates: string[]): boolean {
  if (excludedDates.includes(date)) return false;
  if (rule.until && date > rule.until) return false;
  const dayOfWeek = new Date(date).getDay();
  return rule.days.includes(dayOfWeek);
}
```

### Pattern 4: Riverpod AsyncNotifier no Flutter

**What:** Providers usam `AsyncNotifier` (padrão Riverpod 2+) para estado carregamento/sucesso/erro. O `AgendaProvider` carrega appointments + blocked_slots para a data selecionada.
**When to use:** Toda tela que busca dados da API.

```dart
// Padrão Riverpod do projeto — sealed state Loading/Success/Error
@riverpod
class AgendaNotifier extends _$AgendaNotifier {
  @override
  FutureOr<AgendaState> build() => _load(DateTime.now());

  Future<void> selectDate(DateTime date) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(date));
  }

  Future<AgendaState> _load(DateTime date) async {
    final repo = ref.read(appointmentRepositoryProvider);
    final appointments = await repo.listByDate(date);
    final blockedSlots = await repo.listBlockedSlots(date);
    return AgendaState(date: date, appointments: appointments, blockedSlots: blockedSlots);
  }
}
```

### Anti-Patterns to Avoid

- **Lógica de slot calculation no controller ou repository:** toda lógica de negócio vai no service, nunca no controller (recebe e delega) nem no repository (só I/O).
- **SELECT * em qualquer query:** sempre especificar colunas conforme padrão do projeto.
- **Verificar conflito apenas no Flutter:** o backend é a fonte de verdade. O Flutter previne a maioria no frontend (UX), mas o banco faz a verificação definitiva via exclusion constraint.
- **Ignorar `no_show` na exclusion constraint:** slots `no_show` devem ser excluídos do overlap check (o profissional não atendeu, o horário ficou vago).
- **Gerar recorrências ad infinitum no banco:** nunca materializar todos os dias de uma regra recorrente. Expandir on-demand para o período consultado.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| DB-level conflict prevention | Verificação em SELECT + transação | Exclusion constraint `appointments_no_overlap` com `tstzrange` | Race condition inevitável sem constraint de banco; já existe no schema |
| Auth e extração de studio_id | Custom middleware | `app.authenticate` + `request.authContext` existentes | Já implementado e testado no projeto |
| Validação de input | Checks manuais no controller | Schemas Zod nas rotas (já scaffolded) | Padrão do projeto — validação no boundary |
| Paginação | Offset manual | Cursor-based padrão do projeto (`cursor UUID + LIMIT`) | Consistência e performance com grandes datasets |
| Error codes | Strings ad hoc | `NotFoundError`, `UnprocessableError` em `utils/errors.ts` | Padrão do projeto — garantir HTTP status codes corretos |

**Key insight:** O projeto tem toda a infraestrutura de auth, middleware, error handling, e DB constraint pronta. O trabalho da Phase 3 é implementar lógica de negócio nas camadas service e repository, não reconstruir infraestrutura.

---

## Common Pitfalls

### Pitfall 1: Constraint `appointments_no_overlap` não cobre `pending`

**What goes wrong:** A constraint atual exclui do overlap apenas `cancelled`: `WHERE (status != 'cancelled')`. Após adicionar 'pending', agendamentos pending vão bloquear outros agendamentos no mesmo horário — comportamento correto, mas precisa ser explicitamente testado.

**Why it happens:** O schema inicial não tinha 'pending'. A constraint foi escrita para 4 status.

**How to avoid:** Migration 010 deve: (1) alterar o CHECK constraint para incluir 'pending', (2) alterar o DEFAULT de 'confirmed' para 'pending', (3) revisar a exclusion constraint para incluir `no_show` na exclusão (ou seja: `WHERE (status NOT IN ('cancelled', 'no_show'))`).

**Warning signs:** Se uma profissional aparece disponível num horário onde ela tem um no_show, a exclusion constraint está errada.

### Pitfall 2: Expansão de recorrência sem limite de data

**What goes wrong:** Buscar todos os blocked_slots recorrentes sem filtro de data e expandir no loop retorna infinitos registros teóricos.

**Why it happens:** Regras com `until: null` não têm data de término.

**How to avoid:** O repository sempre filtra por `date` (ou `date_from`/`date_to`). A expansão de recorrência acontece apenas para o período consultado. A query busca regras recorrentes onde `start_date <= date_to AND (until IS NULL OR until >= date_from)`, depois expande em memória apenas para o intervalo.

### Pitfall 3: working_hours JSONB sem validação no boundary

**What goes wrong:** `working_hours` é armazenado como JSONB sem schema fixo no banco. Se o frontend enviar formato errado, o slot calculation quebra silenciosamente.

**Why it happens:** JSONB não valida estrutura no PostgreSQL.

**How to avoid:** Validar o formato `working_hours` com um schema Zod no endpoint de atualização de horários:
```typescript
const WorkingHoursSchema = z.record(
  z.enum(['monday','tuesday','wednesday','thursday','friday','saturday','sunday']),
  z.object({ open: z.string().regex(/^\d{2}:\d{2}$/), close: z.string().regex(/^\d{2}:\d{2}$/) }).nullable()
);
```

### Pitfall 4: Timeline fixa 8h-19h no Flutter

**What goes wrong:** O `AgendaDayScreen` atual tem `_startHour = 8` e `_endHour = 19` hardcoded. A decisão de UX é que a timeline adapta ao working_hours de cada profissional.

**Why it happens:** Era mock data — nenhum working_hours real ainda.

**How to avoid:** Após carregar os dados da API, derivar `timelineStart` e `timelineEnd` do `working_hours` da profissional selecionada para o dia da semana atual. Se sem working_hours (folga), exibir empty state "Profissional não trabalha neste dia."

### Pitfall 5: `AppointmentCard` swipe não diferencia status

**What goes wrong:** O swipe atual (Dismissible) tem comportamento fixo: ▶ = complete, ◀ = cancel. Isso ignora a decisão de UX: pending ▶ = confirm, confirmed ▶ = complete.

**Why it happens:** Era mock com status fixo.

**How to avoid:** `AppointmentCard` recebe o status e configura `background`/`secondaryBackground` e callbacks de acordo. Passar `onConfirm` e `onComplete` como callbacks separados, ativar um ou outro conforme status.

### Pitfall 6: Conflict check no Flutter não reflete buffer time

**What goes wrong:** O Flutter pode mostrar como disponível um slot que na verdade conflita porque o appointment anterior ainda está no buffer.

**Why it happens:** O `end_time` de um appointment = `start_time + duration_minutes + buffer_minutes`. Se o Flutter calcular disponibilidade com apenas `duration_minutes`, erra.

**How to avoid:** A fonte de verdade para slots disponíveis é sempre o endpoint `GET /available-slots`. O Flutter deve usar esse endpoint para preencher as sugestões de horário no booking sheet — nunca calcular disponibilidade localmente.

---

## Code Examples

### Migration: Adicionar 'pending' e corrigir exclusion constraint

```sql
-- Source: supabase/migrations/001_initial_schema.sql (padrão do projeto)

-- 010_add_pending_status.sql

-- 1. Remover CHECK constraint antiga
ALTER TABLE appointments
  DROP CONSTRAINT IF EXISTS appointments_status_check;

-- 2. Adicionar nova CHECK com 'pending'
ALTER TABLE appointments
  ADD CONSTRAINT appointments_status_check
  CHECK (status IN ('pending', 'confirmed', 'completed', 'cancelled', 'no_show'));

-- 3. Alterar DEFAULT de 'confirmed' para 'pending'
ALTER TABLE appointments
  ALTER COLUMN status SET DEFAULT 'pending';

-- 4. Remover exclusion constraint antiga
ALTER TABLE appointments
  DROP CONSTRAINT appointments_no_overlap;

-- 5. Recriar incluindo no_show na exclusão (no_show = horário vago)
ALTER TABLE appointments
  ADD CONSTRAINT appointments_no_overlap
  EXCLUDE USING gist (
    professional_id WITH =,
    tstzrange(start_time, end_time) WITH &&
  ) WHERE (status NOT IN ('cancelled', 'no_show'));
```

### Migration: Absences — adicionar campos à blocked_slots

```sql
-- 011_blocked_slots_absences.sql

ALTER TABLE blocked_slots
  ADD COLUMN title TEXT NOT NULL DEFAULT 'Ausência',
  ADD COLUMN recurrence_rule JSONB,
  ADD COLUMN excluded_dates DATE[] NOT NULL DEFAULT '{}';

-- reason vira opcional (já era) — manter coluna para compatibilidade
-- Índice para busca de regras recorrentes num intervalo de datas
CREATE INDEX blocked_slots_recurrence_idx ON blocked_slots (professional_id)
  WHERE recurrence_rule IS NOT NULL;
```

### Repository: Buscar appointments por profissional + data

```typescript
// Source: padrão do projeto (service.repository.ts como referência)
async listByProfessionalDate(
  studioId: string,
  professionalId: string,
  date: string,
): Promise<AppointmentRow[]> {
  const result = await pool.query<AppointmentRow>(
    `SELECT
       a.id, a.studio_id, a.client_id, a.professional_id, a.service_id,
       a.date, a.start_time, a.end_time, a.status, a.source,
       a.notes, a.cancellation_reason, a.created_at, a.updated_at,
       c.name AS client_name, c.phone AS client_phone,
       p.name AS professional_name,
       s.name AS service_name, s.duration_minutes, s.price
     FROM appointments a
     JOIN clients c ON c.id = a.client_id
     JOIN professionals p ON p.id = a.professional_id
     JOIN services s ON s.id = a.service_id
     WHERE a.studio_id = $1
       AND a.professional_id = $2
       AND a.date = $3
       AND a.status NOT IN ('cancelled', 'no_show')
     ORDER BY a.start_time ASC`,
    [studioId, professionalId, date],
  );
  return result.rows;
}
```

### Flutter: AppointmentModel com todos os status

```dart
// Atualizar mobile/lib/features/agenda/models/appointment_model.dart
enum AppointmentStatus {
  pending,
  confirmed,
  completed,
  cancelled,
  noShow;

  static AppointmentStatus fromString(String s) => switch (s) {
    'pending' => pending,
    'confirmed' => confirmed,
    'completed' => completed,
    'cancelled' => cancelled,
    'no_show' => noShow,
    _ => throw ArgumentError('Unknown status: $s'),
  };

  bool get canConfirm => this == pending;
  bool get canComplete => this == confirmed;
  bool get canCancel => this == pending || this == confirmed;
  bool get canMarkNoShow => this == confirmed;
  bool get isTerminal => this == completed || this == cancelled || this == noShow;
}
```

### Flutter: Status-aware swipe no AppointmentCard

```dart
// Lógica de swipe adaptada ao status — dentro do AppointmentCard
Dismissible(
  key: Key(appointment.id),
  background: _swipeBackground(
    color: appointment.status.canConfirm ? AppColors.info : AppColors.success,
    icon: appointment.status.canConfirm
        ? Icons.check_circle_outline
        : Icons.check_rounded,
    alignment: Alignment.centerLeft,
  ),
  secondaryBackground: _swipeBackground(
    color: AppColors.error,
    icon: Icons.close_rounded,
    alignment: Alignment.centerRight,
  ),
  confirmDismiss: (direction) async {
    HapticFeedback.mediumImpact();
    if (direction == DismissDirection.startToEnd) {
      if (appointment.status.canConfirm) {
        onConfirm?.call();
      } else if (appointment.status.canComplete) {
        onComplete?.call();
      }
    } else if (direction == DismissDirection.endToStart) {
      if (appointment.status.canCancel) {
        onCancel?.call();
      }
    }
    return false; // nunca remover da lista — a atualização vem da API
  },
  child: ...,
)
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Swipe sempre confirm/cancel (mock) | Swipe status-aware (pending/confirmed diferenciam) | Phase 3 | AppointmentCard precisa de refactor |
| Timeline fixa 8h-19h | Timeline dinâmica por working_hours da profissional | Phase 3 | AgendaDayScreen recalcula bounds ao mudar de profissional/dia |
| blocked_slots sem título | blocked_slots com title obrigatório | Phase 3 | Migration + UI update |
| Mock data no Flutter | API real via Riverpod providers | Phase 3 | Substituição total do flutter mock |
| status default 'confirmed' | status default 'pending' | Phase 3 | Migration + todos os fluxos de confirmação |

**Deprecated/outdated:**
- `mockAppointments()` e `mockBlockedSlots()`: remover após conectar à API real
- `_startHour = 8`, `_endHour = 19` hardcoded: substituir por dynamic bounds do working_hours

---

## Open Questions

1. **Overlap dos slots com blocking de no_show**
   - What we know: A constraint atual exclui apenas 'cancelled'. No_show é um horário que ficou vago.
   - What's unclear: Se excluirmos 'no_show' da constraint, um novo agendamento pode ser criado retroativamente num horário de no_show — o que é correto (profissional ficou livre), mas a UI da agenda mostrará os dois sobrepostos visualmente.
   - Recommendation: Excluir 'no_show' da constraint (conforme migration acima). Na agenda UI, cards de no_show aparecem com opacity 60% — visualmente distintos, não conflitantes.

2. **Endereçamento de múltiplos intervalos de horário por dia no working_hours**
   - What we know: O DOMAIN_MODEL.md menciona "múltiplos ranges por dia" no onboarding da Phase 1, mas a struct JSONB dos professionals tem `{day: {open, close}}` — apenas um intervalo.
   - What's unclear: Se o produto precisa de suporte a múltiplos intervalos por dia (ex: 9h-12h e 14h-18h) no `working_hours` JSONB.
   - Recommendation: Manter estrutura simples `{day: {open, close}}` por agora (single range). O CONTEXT.md confirma "múltiplos ranges por dia" no weekly grid — mas a representação no JSONB pode ser `{day: [{open, close}]}` (array). Definir e documentar antes de implementar o endpoint de edição de horários.

---

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Vitest (já configurado) |
| Config file | `backend/vitest.config.ts` |
| Quick run command | `cd backend && npm run test -- --reporter=verbose tests/services/appointment.service.test.ts` |
| Full suite command | `cd backend && npm run test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SCHD-01 | Appointments list por data retorna dados corretos | unit (repository mock) | `npm run test -- tests/services/appointment.service.test.ts` | ❌ Wave 0 |
| SCHD-02 | Conflito de horário retorna 409 TIME_SLOT_TAKEN | unit (service) | `npm run test -- tests/services/appointment.service.test.ts` | ❌ Wave 0 |
| SCHD-02 | Tenant A não vê appointments de Tenant B | unit (service multi-tenancy) | `npm run test -- tests/services/appointment.service.test.ts` | ❌ Wave 0 |
| SCHD-03 | Blocked slot pontual bloqueia slot no cálculo de disponibilidade | unit (service) | `npm run test -- tests/services/appointment.service.test.ts` | ❌ Wave 0 |
| SCHD-03 | Blocked slot recorrente é expandido corretamente para a data | unit (service) | `npm run test -- tests/services/blocked-slot.service.test.ts` | ❌ Wave 0 |
| SCHD-03 | Data excluída de recorrência não bloqueia o slot | unit (service) | `npm run test -- tests/services/blocked-slot.service.test.ts` | ❌ Wave 0 |
| SCHD-04 | pending → confirmed é válido; confirmed → pending é inválido | unit (service state machine) | `npm run test -- tests/services/appointment.service.test.ts` | ❌ Wave 0 |
| SCHD-04 | confirmed → completed cria Payment e Commission | unit (service) | `npm run test -- tests/services/appointment.service.test.ts` | ❌ Wave 0 |
| SCHD-04 | Transição inválida retorna 422 INVALID_STATUS_TRANSITION | unit (service) | `npm run test -- tests/services/appointment.service.test.ts` | ❌ Wave 0 |
| SCHD-05 | Slot fora do working_hours retorna 422 OUTSIDE_WORKING_HOURS | unit (service) | `npm run test -- tests/services/appointment.service.test.ts` | ❌ Wave 0 |
| SCHD-05 | Profissional sem working_hours para o dia retorna 0 slots | unit (service) | `npm run test -- tests/services/appointment.service.test.ts` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `cd backend && npm run test -- tests/services/appointment.service.test.ts tests/services/blocked-slot.service.test.ts`
- **Per wave merge:** `cd backend && npm run test`
- **Phase gate:** Full suite green antes de `/gsd:verify-work`

### Wave 0 Gaps

- [ ] `backend/tests/services/appointment.service.test.ts` — cobre SCHD-01, SCHD-02, SCHD-04, SCHD-05
- [ ] `backend/tests/services/blocked-slot.service.test.ts` — cobre SCHD-03 (pontual + recorrência)
- [ ] `backend/tests/repositories/appointment.repository.test.ts` — cobre queries SQL (com pool mockado)
- [ ] `backend/tests/repositories/blocked-slot.repository.test.ts` — cobre queries SQL

---

## Sources

### Primary (HIGH confidence)

- Código-fonte do projeto (`supabase/migrations/001_initial_schema.sql`) — schema real das tabelas appointments, blocked_slots, professionals
- Código-fonte do projeto (`backend/src/routes/appointments.routes.ts`, `blocked-slots.routes.ts`) — rotas scaffolded com Zod schemas
- Código-fonte do projeto (`mobile/lib/features/agenda/`) — widgets existentes e seu estado atual
- Código-fonte do projeto (`backend/vitest.config.ts`, `backend/tests/`) — infraestrutura de testes
- `.planning/phases/03-scheduling-engine/03-CONTEXT.md` — decisões de produto locked
- `docs/API_CONTRACTS.md` — contratos de API para todos os endpoints de scheduling
- `docs/DOMAIN_MODEL.md` — modelo de domínio das entidades

### Secondary (MEDIUM confidence)

- Padrão de service/repository deduzido dos arquivos existentes (`service.service.ts`, `service.repository.ts`, `service.controller.ts`) — estrutura replicável

### Tertiary (LOW confidence)

- Nenhum item de baixa confiança — toda a pesquisa é baseada no código real do projeto.

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — tudo já instalado e em uso no projeto
- Architecture: HIGH — padrão derivado diretamente do código existente
- Database schema gaps: HIGH — verificado linha a linha nas migrations
- Pitfalls: HIGH — identificados via análise do código real (hardcoded hours, status checks, etc.)
- Slot calculation algorithm: MEDIUM — lógica comum de agendamento, mas detalhes de edge case (múltiplos ranges, timezone) requerem atenção na implementação

**Research date:** 2026-04-03
**Valid until:** 2026-05-03 (stack estável; risco principal é mudança de decisão de produto)
