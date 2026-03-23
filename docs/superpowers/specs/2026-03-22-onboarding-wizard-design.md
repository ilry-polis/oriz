# Onboarding Wizard — Design Spec

**Data:** 2026-03-22
**Fase:** 1 — Identity and Foundation
**Requisitos:** AUTH-05
**Success Criteria:** "A new studio owner completes the onboarding wizard (studio name, timezone, services, business hours) and can access her configured studio"

## Decisoes

- Stepper numerico animado (circulos 1-2-3 com transicao entre steps)
- Step 1: Dados do Estudio — nome, slug (auto-sugerido), telefone, endereco, timezone. Todos no formulario.
- Step 2: Servicos — templates por categoria (unhas, cilios, cabelo, etc.) + adicao manual. Pular permitido.
- Step 3: Horarios — inline com multiplos intervalos por dia, toggle on/off. Pular permitido (usa defaults).
- Tela de conclusao com redirect para /agenda.
- Flutter UI + Backend endpoints reais. Primeira implementacao do ciclo Route → Controller → Service → Repository.
- TDD obrigatorio.
- Auth via Supabase SDK direto (ja implementado). CRUD via backend Fastify.

## Fluxo

```
[Signup] → user sem studio → GoRouter redirect → /onboarding
  ↓
GET /api/v1/studios/me → 404 = novo user, ou retorna studio + onboarding state p/ retomada
  ↓
Step 1: POST /api/v1/studios (cria studio + onboarding_state + professional owner)
         PATCH /api/v1/studios/me/onboarding (step: services)
  ↓
Step 2: GET /api/v1/service-categories (busca categorias p/ mapear IDs)
         POST /api/v1/services (para cada servico) — pular permitido
         PATCH /api/v1/studios/me/onboarding (step: business_hours)
  ↓
Step 3: PATCH /api/v1/professionals/:id (working_hours) — pular permitido
         PATCH /api/v1/studios/me/onboarding (step: complete)
  ↓
Tela de conclusao → /agenda
```

Recuperacao de rede: se a conexao cai entre steps, o wizard retoma do ultimo step persistido via `GET /api/v1/studios/me/onboarding` no `init()`.

Redirect logic no GoRouter:
- Autenticado + sem studio → `/onboarding`
- Autenticado + studio + onboarding incompleto → `/onboarding` (retoma step atual)
- Autenticado + onboarding completo → `/agenda`

## Estrutura de Arquivos — Flutter

```
lib/features/onboarding/
├── data/
│   ├── onboarding_repository.dart     HTTP client → backend API
│   └── service_templates.dart         dados estaticos de templates por categoria
├── providers/
│   └── onboarding_provider.dart       Riverpod state machine do wizard
├── presentation/
│   ├── onboarding_wizard_screen.dart  container (stepper + PageView animado)
│   ├── steps/
│   │   ├── studio_data_step.dart      Step 1: formulario de dados
│   │   ├── services_step.dart         Step 2: templates + manual
│   │   └── business_hours_step.dart   Step 3: horarios inline
│   ├── onboarding_complete_screen.dart tela de conclusao
│   └── widgets/
│       ├── wizard_stepper.dart        stepper animado (1-2-3)
│       ├── service_template_card.dart card de servico editavel
│       ├── day_hours_card.dart        card do dia com intervalos
│       └── time_range_picker.dart     seletor 15min increments
```

## Estrutura — Backend

Usa `pg` (node-postgres) como driver — SQL direto, sem ORM. Conforme regra supabase.md.

```
backend/src/
├── controllers/
│   ├── studio.controller.ts
│   ├── onboarding.controller.ts
│   ├── service.controller.ts
│   └── professional.controller.ts
├── services/
│   ├── studio.service.ts
│   ├── onboarding.service.ts
│   ├── service.service.ts
│   └── professional.service.ts
├── repositories/
│   ├── studio.repository.ts
│   ├── onboarding.repository.ts
│   ├── service.repository.ts
│   └── professional.repository.ts
```

## Telas

### Step 1: Dados do Estudio

Layout:
- Stepper animado no topo: (1)——(2)——(3) com step 1 ativo
- Titulo centralizado: "Dados do Estudio" + "Passo 1 de 3"
- Campos:
  - Nome do estudio (obrigatorio, min 1 char)
  - URL publica: prefixo "oriz.app/" fixo + input slug (auto-gerado do nome via slugify, editavel, validacao realtime contra 409 SLUG_TAKEN)
  - Telefone (opcional, formato E.164)
  - Endereco (opcional)
  - Fuso horario (dropdown, default auto-detectado do device)
- Botao primario: "Proximo"
- Estados: formulario, loading (spinner no botao), erro inline (slug ja existe)

Acao: `POST /api/v1/studios` → cria studio + onboarding_state (step: studio_data) + professional (owner)

### Step 2: Servicos

Layout:
- Stepper: step 1 check verde, step 2 ativo, step 3 inativo
- Titulo: "Servicos" + "Passo 2 de 3"
- Chips de categoria selecionaveis: Unhas, Cilios, Cabelo, Micropigmentacao, Sobrancelha, Depilacao, Outro
- Ao selecionar, servicos sugeridos aparecem como cards editaveis:
  - Cada card: nome (editavel), duracao (dropdown 15min increments), preco em centavos (input numerico formatado como R$)
  - Botao "x" para remover
- Botao "+ Servico personalizado" para adicionar servico manual (mesmos campos, vazios)
- Botao primario: "Proximo"
- Link ghost: "Pular por agora" → avanca sem salvar

Acao por servico: `POST /api/v1/services`

Templates de servico (dados estaticos no Flutter):

| Categoria | Servico | Duracao | Preco |
|-----------|---------|---------|-------|
| Unhas | Manicure | 30min | R$50 |
| Unhas | Pedicure | 45min | R$60 |
| Unhas | Esmaltacao em gel | 60min | R$80 |
| Cilios | Extensao de cilios | 90min | R$150 |
| Cilios | Lash lifting | 60min | R$100 |
| Cabelo | Corte feminino | 45min | R$80 |
| Cabelo | Escova | 30min | R$50 |
| Cabelo | Coloracao | 120min | R$200 |
| Micropigmentacao | Sobrancelha | 120min | R$400 |
| Micropigmentacao | Labios | 120min | R$500 |
| Sobrancelha | Design de sobrancelha | 30min | R$40 |
| Sobrancelha | Henna | 30min | R$50 |
| Depilacao | Buzzo | 15min | R$20 |
| Depilacao | Meia perna | 30min | R$40 |

### Step 3: Horario de Funcionamento

Layout:
- Stepper: steps 1-2 check verde, step 3 ativo
- Titulo: "Horarios" + "Passo 3 de 3"
- 7 cards (Seg-Dom), cada um com:
  - Label do dia (Seg, Ter, ...) + toggle on/off
  - Quando ligado: intervalo(s) com time pickers (dropdown 15min increments, 00:00-23:45)
  - "+ Intervalo" link para adicionar mais ranges
  - "x" para remover intervalo extra (minimo 1 quando ligado)
  - Quando desligado: card com opacity 50%, mostra "Fechado"
- Defaults pre-preenchidos: Seg-Sab 09:00-18:00, Dom desligado
- Botao primario: "Concluir"
- Link ghost: "Pular por agora" → usa defaults

Acao: `PATCH /api/v1/professionals/:id` com working_hours JSON

**Nota:** API_CONTRACTS.md define `working_hours` como `Record<string, {open, close}>` (um intervalo por dia). Esta spec amenda o contrato para `Record<string, Array<{open, close}>>` (multiplos intervalos) conforme decisao em 01-CONTEXT.md. Atualizar API_CONTRACTS.md na implementacao.

Formato working_hours:
```json
{
  "monday": [{"open": "09:00", "close": "12:00"}, {"open": "14:00", "close": "18:00"}],
  "tuesday": [{"open": "09:00", "close": "18:00"}],
  "wednesday": [{"open": "09:00", "close": "18:00"}],
  "thursday": [{"open": "09:00", "close": "18:00"}],
  "friday": [{"open": "09:00", "close": "18:00"}],
  "saturday": [{"open": "09:00", "close": "13:00"}],
  "sunday": []
}
```

### Tela de Conclusao

Layout:
- Icone de sucesso (checkmark animado, AppColors.success)
- "Seu estudio esta pronto!"
- "Agora voce pode agendar seus primeiros atendimentos."
- Botao primario: "Ir para Agenda"
- Haptic: mediumImpact no sucesso

Acao: `PATCH /studios/me/onboarding` step → complete, depois `context.go('/agenda')`

## Router Update

Novas rotas:
- `/onboarding` — OnboardingWizardScreen (protegida, sem shell/bottom nav)
- `/onboarding/complete` — OnboardingCompleteScreen

Redirect logic atualizada:
```
if (!hasSession && !isAuthRoute) → /login
if (hasSession && !hasStudio && !isOnboardingRoute) → /onboarding
if (hasSession && hasStudio && !onboardingComplete && !isOnboardingRoute) → /onboarding
if (hasSession && onboardingComplete && (isAuthRoute || isOnboardingRoute)) → /agenda
```

Isso requer que o GoRouter tenha acesso ao studio/onboarding state. O `authNotifierProvider` ja tem a session; precisamos de um check adicional para studio existence. Duas opcoes:
- Chamar `GET /api/v1/studios/me` no boot e guardar o resultado num provider
- Verificar studio_id no JWT claims (se Supabase custom claims estiver configurado)

Abordagem: chamar `GET /api/v1/studios/me` uma vez no boot. Se retorna 404, user nao tem studio. Se retorna studio com onboarding incompleto, redirect para /onboarding no step correto.

## OnboardingRepository

Wrapper HTTP sobre o backend API:

| Metodo | Endpoint |
|--------|----------|
| `createStudio(data)` | `POST /api/v1/studios` |
| `getMyStudio()` | `GET /api/v1/studios/me` |
| `getOnboardingState()` | `GET /api/v1/studios/me/onboarding` |
| `updateOnboardingStep(step)` | `PATCH /api/v1/studios/me/onboarding` |
| `getServiceCategories()` | `GET /api/v1/service-categories` |
| `createService(data)` | `POST /api/v1/services` |
| `updateProfessional(id, data)` | `PATCH /api/v1/professionals/:id` |

**Resolucao de category_id:** No Step 2, ao entrar na tela, chamar `GET /api/v1/service-categories` para obter a lista de categorias globais (studio_id IS NULL) com seus UUIDs. Os templates estaticos sao mapeados por nome de categoria para o UUID retornado pela API. Se uma categoria nao existir no banco, o template e ignorado.

Usa `supabase.auth.currentSession?.accessToken` como Bearer token nos requests HTTP ao backend.

## OnboardingProvider (Riverpod)

```dart
sealed class OnboardingState {}
class OnboardingLoading extends OnboardingState {}
class OnboardingStep extends OnboardingState {
  final int currentStep; // 0, 1, 2
  final String? studioId;
  final String? professionalId;
}
class OnboardingComplete extends OnboardingState {}
class OnboardingError extends OnboardingState { final String message; }
```

Metodos:
- `init()` — verifica se tem studio, qual step do onboarding
- `createStudio(data)` → step 0 → step 1
- `addServices(list)` → step 1 → step 2
- `skipServices()` → step 1 → step 2
- `setBusinessHours(hours)` → step 2 → complete
- `skipBusinessHours()` → step 2 → complete
- `complete()` → marca onboarding completo, redirect

## Backend Endpoints

### POST /api/v1/studios

Validacao (Zod — ja existe em studios.routes.ts):
```typescript
{
  name: string (min 1),
  slug: string (regex: ^[a-z0-9-]{3,50}$),
  phone?: string (E.164),
  address?: string,
  description?: string,
  timezone?: string (default: "America/Sao_Paulo")
}
```

Auth: authenticated (sem requireStudioMember — user ainda nao tem studio). Rate limit ja configurado na rota (3/min).

Logica (StudioService):
1. Verificar que user nao tem studio existente (409 STUDIO_ALREADY_EXISTS)
2. Verificar slug unico (409 SLUG_TAKEN)
2. BEGIN transaction
3. INSERT studio (name, slug, phone, address, timezone, owner_id)
4. INSERT onboarding_state (studio_id, current_step: 'studio_data')
5. INSERT professional (studio_id, user_id, role: 'owner', is_active: true)
6. COMMIT
7. Retornar { data: { studio, onboarding, professional } }

**Nota:** API_CONTRACTS.md define resposta como `{ data: Studio }`. Esta spec amenda para retornar o composite `{ data: { studio, onboarding, professional } }` para evitar 2 round-trips extras no onboarding. Atualizar API_CONTRACTS.md na implementacao.

### GET /api/v1/studios/me

Logica:
1. Pegar studio_id do auth context
2. Se null → 404
3. SELECT id, name, slug, phone, address, timezone, settings FROM studios WHERE id = $1
4. Retornar { data: studio }

### PATCH /api/v1/studios/me/onboarding

Logica:
1. Validar current_step enum
2. UPDATE onboarding_states SET current_step = $1, updated_at = now() WHERE studio_id = $2
3. Se step = 'complete' → SET completed_at = now()
4. Retornar { data: onboarding_state }

### POST /api/v1/services

Validacao (Zod — ja existe em services.routes.ts):
```typescript
{
  category_id: uuid,
  name: string (min 1),
  duration_minutes: int (min 5),
  price: int (min 0, centavos),
  buffer_minutes: int (min 0, default 0),
  is_active: boolean (default true)
}
```

Logica:
1. Pegar studio_id do auth context
2. INSERT service (studio_id, category_id, name, duration_minutes, price, buffer_minutes, is_active)
3. Retornar 201 { data: service }

### PATCH /api/v1/professionals/:id

Logica:
1. Verificar que professional pertence ao studio do auth context
2. UPDATE professionals SET working_hours = $1, updated_at = now() WHERE id = $2 AND studio_id = $3
3. Retornar { data: professional }

Validacao Zod para working_hours (a adicionar em professionals.routes.ts):
```typescript
const TimeRange = z.object({
  open: z.string().regex(/^\d{2}:\d{2}$/),
  close: z.string().regex(/^\d{2}:\d{2}$/),
}).refine(d => d.close > d.open, { message: 'close must be after open' });

const WorkingHours = z.object({
  monday: z.array(TimeRange).default([]),
  tuesday: z.array(TimeRange).default([]),
  wednesday: z.array(TimeRange).default([]),
  thursday: z.array(TimeRange).default([]),
  friday: z.array(TimeRange).default([]),
  saturday: z.array(TimeRange).default([]),
  sunday: z.array(TimeRange).default([]),
});
```

## Design System

- Stepper: circulos 28px visuais, mas com touch target 44x44 (padding invisible). Tappavel para voltar a steps completos, nao para avancar. bg AppColors.primary (ativo), AppColors.success + checkmark (completo), AppColors.neutral200 (inativo). Linhas conectoras 2px. Animacao: 300ms ease-in-out entre steps.
- Formularios: AuthTextField reutilizado (ja existe). Novos: slug input com prefix, dropdown, toggle switch.
- Cards de servico: AppColors.neutral100 bg, AppRadius.md, padding AppSpacing.md. Botao x em AppColors.neutral400.
- Cards de horario: AppColors.neutral100 bg, toggle nativo Material com cor AppColors.primary. Time pickers como dropdowns.
- Transicoes entre steps: slide horizontal via PageView com Curves.easeInOut 300ms.
- Skip link: ghost style (AppTypography.caption, AppColors.neutral600).
- Spinner inline no botao: AppColors.accent, 20px (mesmo padrao do auth).

## Estrategia de Testes

### Backend Unit Tests

**studio.service.test.ts**
- createStudio cria studio + onboarding_state + professional em transaction
- createStudio rejeita slug duplicado (409 SLUG_TAKEN)
- createStudio rejeita se user ja tem studio
- getMyStudio retorna studio do user
- getMyStudio retorna 404 se user nao tem studio

**service.service.test.ts**
- createService cria servico com studio_id correto
- createService valida campos obrigatorios

**onboarding.service.test.ts**
- updateStep atualiza step
- updateStep seta completed_at quando step = complete

### Flutter Unit Tests

**onboarding_provider_test.dart**
- init: carrega step correto do backend
- createStudio: sucesso → avanca para step 1
- addServices: sucesso → avanca para step 2
- skipServices: avanca sem salvar
- setBusinessHours: sucesso → completa
- erro: mostra mensagem

### Flutter Widget Tests

**wizard_stepper_test.dart**
- renderiza 3 circulos
- marca step correto como ativo
- marca steps completos com check

**studio_data_step_test.dart**
- renderiza todos os campos
- valida nome obrigatorio
- valida slug format
- auto-gera slug do nome

**services_step_test.dart**
- renderiza chips de categoria
- selecionar categoria mostra templates
- adicionar servico personalizado
- remover servico

**business_hours_step_test.dart**
- renderiza 7 dias com defaults
- toggle desliga/liga dia
- adicionar intervalo
- remover intervalo extra

**onboarding_complete_screen_test.dart**
- renderiza mensagem de sucesso
- botao redireciona para /agenda

## Fora de Escopo

- Upload de logo — diferido para Settings/Phase 5
- i18n — diferido
- Categorias de servico vindas do banco (usa dados estaticos por enquanto)
- Validacao de timezone contra lista IANA (aceita qualquer string)
- Onboarding banner persistente ("Complete seu setup") — diferido, nao bloqueia
- Business hours por professional (Phase 2 — aqui e por studio/owner)
