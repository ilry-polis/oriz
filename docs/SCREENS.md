# Mapa de Telas — Oriz

> Source of truth para todas as telas do produto.
> Cruzado com: `API_CONTRACTS.md` (dados), `DOMAIN_MODEL.md` (entidades), `DESIGN_SYSTEM.md` (componentes).
> Se a implementação diverge deste mapa, o mapa vence.

## Convenções

- **Rota**: caminho no GoRouter (Flutter) ou URL (web)
- **Auth**: quem acessa — `owner`, `professional` (inclui owner), `public`
- **Endpoints**: referência ao API_CONTRACTS.md (seção § número)
- **Ações**: P = primária (1 por tela), S = secundária (máx 2), N = navegação
- **Estados**: V = vazio, L = carregando, D = com dados, E = erro
- **DS**: componentes do DESIGN_SYSTEM.md usados

---

## Sumário de Fluxos

| # | Fluxo | Plataforma | Telas |
|---|-------|------------|-------|
| 1 | Onboarding | Mobile | 6 |
| 2 | Agenda | Mobile | 4 |
| 3 | Novo Agendamento | Mobile | 4 |
| 4 | Clientes | Mobile | 5 |
| 5 | Financeiro | Mobile | 4 |
| 6 | Configurações | Mobile | 6 |
| 7 | Booking Público | Web | 5 |
| 8 | IA & Conversas | Mobile | 3 |
| 9 | Marketing | Mobile | 3 |
| 10 | Billing | Mobile | 3 |
| 11 | Dashboard Web (Owner) | Web | 7 |

---

## 1. Fluxo: Onboarding

### 1.1 SplashScreen — `/splash`
Auth: `public`
Endpoints: nenhum
DS: brand logo, --brand-primary bg

```
┌──────────────────────────────────┐
│                                  │
│                                  │
│           [Logo Oriz]            │
│                                  │
│          ● ● ● (loading)        │
│                                  │
└──────────────────────────────────┘
```

- Verifica token salvo → se válido, redireciona para `/agenda`
- Se inválido/ausente → `/login`
- Tempo máximo: 2s, depois força redirecionamento

Estados:
- L: logo + indicador de carregamento
- E: falha de rede → redireciona para `/login`

---

### 1.2 LoginScreen — `/login`
Auth: `public`
Endpoints: `POST /auth/login` (§1), `POST /auth/signup` (§1)
DS: Input, Button Primary, Button Secondary, Ghost button

```
┌──────────────────────────────────┐
│                                  │
│           [Logo Oriz]            │
│                                  │
│  ┌────────────────────────────┐  │
│  │ Email                      │  │
│  └────────────────────────────┘  │
│  ┌────────────────────────────┐  │
│  │ Senha                      │  │
│  └────────────────────────────┘  │
│                                  │
│  [ Entrar ]                  (P) │
│                                  │
│  ── ou ──                        │
│                                  │
│  [G] Entrar com Google       (S) │
│  [] Entrar com Apple        (S) │
│                                  │
│  Criar conta    Esqueci senha    │
│     (N)             (N)          │
└──────────────────────────────────┘
```

Ações:
- P: Entrar (email + senha) → `POST /auth/login`
- S: Google OAuth → Supabase Auth
- S: Apple Sign-In → Supabase Auth
- N: "Criar conta" → `/signup`
- N: "Esqueci senha" → `/forgot-password`

Estados:
- D: formulário pronto
- L: botão com spinner durante request
- E: toast de erro ("Email ou senha incorretos")

Regras:
- Rate limit visual: após 3 tentativas falhas, mostrar captcha ou cooldown
- Validação inline: email format, senha min 8 chars

---

### 1.3 SignupScreen — `/signup`
Auth: `public`
Endpoints: `POST /auth/signup` (§1)
DS: Input, Button Primary, Top Bar (back)

```
┌──────────────────────────────────┐
│ ←  Criar conta                   │
│──────────────────────────────────│
│                                  │
│  Nome completo                   │
│  ┌────────────────────────────┐  │
│  │                            │  │
│  └────────────────────────────┘  │
│  Email                           │
│  ┌────────────────────────────┐  │
│  │                            │  │
│  └────────────────────────────┘  │
│  Senha                           │
│  ┌────────────────────────────┐  │
│  │                            │  │
│  └────────────────────────────┘  │
│                                  │
│  [ Criar conta ]             (P) │
│                                  │
│  Já tem conta? Entrar        (N) │
└──────────────────────────────────┘
```

Ações:
- P: Criar conta → `POST /auth/signup`
- N: "Já tem conta?" → `/login`

Estados:
- D: formulário
- L: botão com spinner
- E: inline errors (409 ACCOUNT_EXISTS, 400 WEAK_PASSWORD)

---

### 1.4 ForgotPasswordScreen — `/forgot-password`
Auth: `public`
Endpoints: `POST /auth/forgot-password` (§1)
DS: Input, Button Primary, Top Bar (back)

```
┌──────────────────────────────────┐
│ ←  Recuperar senha               │
│──────────────────────────────────│
│                                  │
│  Informe seu email e enviaremos  │
│  instruções para redefinir.      │
│                                  │
│  Email                           │
│  ┌────────────────────────────┐  │
│  │                            │  │
│  └────────────────────────────┘  │
│                                  │
│  [ Enviar instruções ]       (P) │
│                                  │
└──────────────────────────────────┘
```

Ações:
- P: Enviar → `POST /auth/forgot-password`

Estados:
- D: formulário
- L: spinner no botão
- D (sucesso): mensagem genérica "Se o email existir, enviaremos instruções."

---

### 1.5 OnboardingWizardScreen — `/onboarding`
Auth: `owner`
Endpoints: `POST /studios` (§3), `PATCH /studios/me/onboarding` (§3), `POST /services` (§5)
DS: Input, Button Primary, Button Secondary, stepper/progress indicator

Wizard de 3 passos. Cada passo é um sub-route:

**Step 1: Dados do Estúdio** — `/onboarding/studio`
```
┌──────────────────────────────────┐
│  Passo 1 de 3                    │
│  ■───○───○                       │
│──────────────────────────────────│
│                                  │
│  Nome do estúdio                 │
│  ┌────────────────────────────┐  │
│  │                            │  │
│  └────────────────────────────┘  │
│  URL pública (slug)              │
│  ┌─────┬──────────────────────┐  │
│  │oriz/│                      │  │
│  └─────┴──────────────────────┘  │
│  Telefone                        │
│  ┌────────────────────────────┐  │
│  │                            │  │
│  └────────────────────────────┘  │
│  Endereço                        │
│  ┌────────────────────────────┐  │
│  │                            │  │
│  └────────────────────────────┘  │
│  Fuso horário                    │
│  ┌────────────────────────────┐  │
│  │ America/Sao_Paulo       ▼  │  │
│  └────────────────────────────┘  │
│                                  │
│  [ Próximo ]                 (P) │
└──────────────────────────────────┘
```
→ `POST /studios` + `PATCH /studios/me/onboarding` (step: services)

**Step 2: Serviços** — `/onboarding/services`
```
┌──────────────────────────────────┐
│  Passo 2 de 3                    │
│  ■───■───○                       │
│──────────────────────────────────│
│                                  │
│  Adicione seus serviços          │
│                                  │
│  ┌──────────────────────────────┐│
│  │ Manicure        30min  R$50 ││
│  │                         [×] ││
│  ├──────────────────────────────┤│
│  │ Pedicure         45min R$60 ││
│  │                         [×] ││
│  └──────────────────────────────┘│
│                                  │
│  + Adicionar serviço         (S) │
│                                  │
│  [ Próximo ]                 (P) │
│  Pular por agora             (N) │
└──────────────────────────────────┘
```
→ `POST /services` para cada serviço adicionado
→ `PATCH /studios/me/onboarding` (step: business_hours)

**Step 3: Horário de Funcionamento** — `/onboarding/hours`
```
┌──────────────────────────────────┐
│  Passo 3 de 3                    │
│  ■───■───■                       │
│──────────────────────────────────│
│                                  │
│  Defina seus horários            │
│                                  │
│  Seg  ┌──────┐ às ┌──────┐  [✓]│
│       │08:00 │    │18:00 │      │
│  Ter  ┌──────┐ às ┌──────┐  [✓]│
│       │08:00 │    │18:00 │      │
│  Qua  ┌──────┐ às ┌──────┐  [✓]│
│       │08:00 │    │18:00 │      │
│  Qui  ┌──────┐ às ┌──────┐  [✓]│
│       │08:00 │    │18:00 │      │
│  Sex  ┌──────┐ às ┌──────┐  [✓]│
│       │08:00 │    │18:00 │      │
│  Sab  ┌──────┐ às ┌──────┐  [✓]│
│       │08:00 │    │13:00 │      │
│  Dom                         [✗] │
│                                  │
│  [ Concluir ]                (P) │
└──────────────────────────────────┘
```
→ `PATCH /professionals/:id` (working_hours do owner)
→ `PATCH /studios/me/onboarding` (step: complete)
→ Redireciona para `/agenda`

Estados (todos os steps):
- D: formulário
- L: spinner no botão ao salvar
- E: inline errors (409 SLUG_TAKEN em step 1)

---

### 1.6 OnboardingCompleteScreen — `/onboarding/complete`
Auth: `owner`
Endpoints: nenhum (tela transitória)
DS: ilustração/ícone de sucesso, Button Primary

```
┌──────────────────────────────────┐
│                                  │
│         [✓ ícone sucesso]        │
│                                  │
│     Seu estúdio está pronto!     │
│                                  │
│   Agora você pode agendar seus   │
│   primeiros atendimentos.        │
│                                  │
│  [ Ir para Agenda ]          (P) │
│                                  │
└──────────────────────────────────┘
```

Ações:
- P: Ir para Agenda → `/agenda`

---

## 2. Fluxo: Agenda

### 2.1 AgendaDayScreen — `/agenda` (tab: Agenda)
Auth: `professional`
Endpoints: `GET /appointments` (§8, filtro date=hoje), `GET /professionals` (§6, para owner filtrar)
DS: Appointment Card, Status Badge, Bottom Tab Bar, Top Bar, Empty State, Skeleton

```
┌──────────────────────────────────┐
│  Agenda          [+] [filtro] (S)│
│  Qui, 13 Mar 2026                │
│  ◀ ● ● ● ● ● ● ● ▶   Semana(N)│
│──────────────────────────────────│
│                                  │
│  08:00 ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─│
│                                  │
│  09:00 ┌────────────────────────┐│
│        │ Maria Silva     [•••]  ││
│        │ Manicure     45min     ││
│        │ ■ Confirmado           ││
│        └────────────────────────┘│
│  10:00 ┌────────────────────────┐│
│        │ Ana Costa       [•••]  ││
│        │ Pedicure      60min    ││
│        │ ■ Confirmado           ││
│        └────────────────────────┘│
│  11:00 ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─│
│                                  │
│  12:00 ┌────────────────────────┐│
│        │ ▒▒▒ Almoço ▒▒▒        ││
│        │ Bloqueado              ││
│        └────────────────────────┘│
│                                  │
│──────────────────────────────────│
│  Agenda  Clientes  Finan.  Mais  │
└──────────────────────────────────┘
```

Ações:
- P: Tap no card → `/agenda/:id` (detalhes)
- S: [+] FAB → `/appointments/new` (novo agendamento)
- S: [filtro] → bottom sheet com filtro por profissional (owner only)
- N: Setas ◀▶ → navega entre dias
- N: "Semana" → `/agenda/week`
- N: Swipe direita no card → confirmar/completar
- N: Swipe esquerda no card → cancelar

Estados:
- V: Empty state "Nenhum agendamento hoje" + botão "Novo Agendamento"
- L: Skeleton shimmer nos slots de horário
- D: lista de appointments do dia
- E: toast "Erro ao carregar agenda" + pull-to-refresh

Regras:
- Scroll automático até o horário atual
- Blocked slots exibidos com padrão visual diferente (hachurado)
- Owner vê filtro por profissional; professional vê apenas seus agendamentos
- **1 toque** para ver agenda do dia (é a tela inicial)

---

### 2.2 AgendaWeekScreen — `/agenda/week`
Auth: `professional`
Endpoints: `GET /appointments` (§8, filtro date_from/date_to da semana)
DS: Appointment Card (compacto), Top Bar (back), Bottom Tab Bar

```
┌──────────────────────────────────┐
│ ←  Semana         [filtro]   (S) │
│  10-16 Mar 2026                  │
│  Seg  Ter  Qua  Qui  Sex  Sab   │
│──────────────────────────────────│
│       │    │    │    │    │      │
│  08   │    │    │ ██ │    │      │
│  09   │ ██ │    │ ██ │ ██ │      │
│  10   │ ██ │ ██ │    │ ██ │ ██   │
│  11   │    │ ██ │    │    │ ██   │
│  12   │ ▒▒ │ ▒▒ │ ▒▒ │ ▒▒ │ ▒▒   │
│  13   │    │    │    │    │      │
│  14   │ ██ │    │ ██ │ ██ │      │
│  15   │ ██ │ ██ │ ██ │    │      │
│  16   │    │ ██ │    │ ██ │      │
│  17   │    │    │ ██ │    │      │
│       │    │    │    │    │      │
│──────────────────────────────────│
│  Agenda  Clientes  Finan.  Mais  │
└──────────────────────────────────┘
```

Ações:
- P: Tap no bloco → `/agenda/:id` (detalhes do agendamento)
- N: Tap no cabeçalho do dia → `/agenda` com filtro naquele dia
- N: Swipe horizontal → semana anterior/próxima

Estados:
- V: grade vazia, mensagem "Semana livre"
- L: skeleton shimmer na grade
- D: grade com blocos coloridos por status
- E: toast + pull-to-refresh

---

### 2.3 AppointmentDetailScreen — `/agenda/:id`
Auth: `professional`
Endpoints: `GET /appointments/:id` (§8)
DS: Card, Status Badge, Button Primary, Button Secondary, Button Danger, Top Bar (back)

```
┌──────────────────────────────────┐
│ ←  Detalhes                      │
│──────────────────────────────────│
│                                  │
│  Maria Silva                     │
│  (11) 99999-1234             (N) │
│                                  │
│  ┌──────────────────────────────┐│
│  │ Serviço    Manicure          ││
│  │ Data       13/03/2026        ││
│  │ Horário    09:00 - 09:45     ││
│  │ Duração    45min             ││
│  │ Valor      R$ 50,00          ││
│  │ Status     ■ Confirmado      ││
│  │ Origem     App               ││
│  └──────────────────────────────┘│
│                                  │
│  Notas                           │
│  ┌──────────────────────────────┐│
│  │ Preferência por esmalte     ││
│  │ claro.                       ││
│  └──────────────────────────────┘│
│                                  │
│  [ Concluir atendimento ]    (P) │
│  [ Remarcar ]  [ Cancelar ] (S)  │
│                                  │
└──────────────────────────────────┘
```

Ações (variam por status):
- **Se confirmed:**
  - P: Concluir → bottom sheet de pagamento → `POST /appointments/:id/complete`
  - S: Remarcar → `/appointments/:id/edit`
  - S: Cancelar → confirmação → `POST /appointments/:id/cancel`
- **Se completed:**
  - Sem ações. Exibe dados do pagamento e comissão.
- **Se cancelled/no_show:**
  - P: Reagendar → `/appointments/new` (pré-preenchido com client_id e service_id)
- N: Tap no nome do cliente → `/clients/:id`
- N: Tap no telefone → ligar/WhatsApp

Estados:
- L: skeleton
- D: dados completos
- E: 404 → "Agendamento não encontrado" + voltar

---

### 2.4 CompleteAppointmentSheet — bottom sheet em `/agenda/:id`
Auth: `professional`
Endpoints: `POST /appointments/:id/complete` (§8)
DS: Bottom Sheet (--radius-lg), Input, Button Primary, Button Secondary

```
┌──────────────────────────────────┐
│  ─────  (drag handle)            │
│  Registrar pagamento             │
│──────────────────────────────────│
│                                  │
│  Valor                           │
│  ┌────────────────────────────┐  │
│  │ R$ 50,00                   │  │
│  └────────────────────────────┘  │
│                                  │
│  Forma de pagamento              │
│  ┌──────┐┌──────┐┌──────┐┌────┐ │
│  │ Dinheiro││ PIX  ││Débito││Créd│ │
│  └──────┘└──────┘└──────┘└────┘ │
│                                  │
│  Taxa do cartão (se cartão)      │
│  ┌────────────────────────────┐  │
│  │ 2.50%                      │  │
│  └────────────────────────────┘  │
│                                  │
│  [ Concluir ]                (P) │
│  Concluir sem pagamento      (N) │
└──────────────────────────────────┘
```

Ações:
- P: Concluir → `POST /appointments/:id/complete` com payment body
- N: Concluir sem pagamento → `POST /appointments/:id/complete` sem payment

Estados:
- D: formulário pré-preenchido com preço do serviço (input com máscara monetária R$; converter para centavos no submit)
- L: spinner no botão
- E: inline error se falhar

---

## 3. Fluxo: Novo Agendamento

**Contagem de toques:** 3 toques (cliente → serviço → horário + confirmar)

### 3.1 SelectClientScreen — `/appointments/new/client`
Auth: `professional`
Endpoints: `GET /clients` (§7, com search), `POST /clients` (§7)
DS: Input (search), Card, Empty State, Top Bar (back)

```
┌──────────────────────────────────┐
│ ←  Selecionar cliente            │
│──────────────────────────────────│
│  ┌────────────────────────────┐  │
│  │ 🔍 Buscar por nome/tel    │  │
│  └────────────────────────────┘  │
│                                  │
│  + Novo cliente              (S) │
│                                  │
│  ┌──────────────────────────────┐│
│  │ Maria Silva                  ││
│  │ (11) 99999-1234              ││
│  ├──────────────────────────────┤│
│  │ Ana Costa                    ││
│  │ (11) 99999-5678              ││
│  ├──────────────────────────────┤│
│  │ Julia Santos                 ││
│  │ (11) 99999-9012              ││
│  └──────────────────────────────┘│
│                                  │
└──────────────────────────────────┘
```

Ações:
- P: Tap no cliente → avança para `/appointments/new/service` (toque 1)
- S: "+ Novo cliente" → inline form ou bottom sheet para criar rápido
- N: Busca com debounce (300ms)

Estados:
- V: "Nenhum cliente cadastrado" + "Cadastrar primeiro cliente"
- L: skeleton na lista
- D: lista de clientes com busca
- E: toast

---

### 3.2 SelectServiceScreen — `/appointments/new/service`
Auth: `professional`
Endpoints: `GET /services` (§5, filtro por category), `GET /service-categories` (§4)
DS: Card, chips/tabs para categorias, Top Bar (back)

```
┌──────────────────────────────────┐
│ ←  Selecionar serviço            │
│──────────────────────────────────│
│  [Todas] [Unhas] [Cílios] [+]   │
│                                  │
│  ┌──────────────────────────────┐│
│  │ Manicure                     ││
│  │ 30min  ·  R$ 50,00           ││
│  ├──────────────────────────────┤│
│  │ Pedicure                     ││
│  │ 45min  ·  R$ 60,00           ││
│  ├──────────────────────────────┤│
│  │ Mani + Pedi                  ││
│  │ 60min  ·  R$ 90,00           ││
│  └──────────────────────────────┘│
│                                  │
└──────────────────────────────────┘
```

Ações:
- P: Tap no serviço → avança para `/appointments/new/slot` (toque 2)
- N: Filtro por categoria (chips)

Estados:
- V: "Nenhum serviço cadastrado" + "Cadastrar serviço" (owner) ou mensagem (professional)
- L: skeleton
- D: lista agrupada por categoria
- E: toast

---

### 3.3 SelectSlotScreen — `/appointments/new/slot`
Auth: `professional`
Endpoints: `GET /appointments/available-slots` (§8), `GET /professionals` (§6, se owner agendando para outro)
DS: Card, chips para profissional, date picker, Top Bar (back)

```
┌──────────────────────────────────┐
│ ←  Selecionar horário            │
│──────────────────────────────────│
│  Profissional (que fazem o serviço)│
│  [Eu] [Maria]                    │
│                                  │
│  Data                            │
│  ◀  Qui, 13 Mar 2026  ▶         │
│                                  │
│  Horários disponíveis            │
│  ┌──────┐ ┌──────┐ ┌──────┐     │
│  │09:00 │ │09:30 │ │10:00 │     │
│  └──────┘ └──────┘ └──────┘     │
│  ┌──────┐ ┌──────┐ ┌──────┐     │
│  │10:30 │ │14:00 │ │14:30 │     │
│  └──────┘ └──────┘ └──────┘     │
│  ┌──────┐ ┌──────┐              │
│  │15:00 │ │15:30 │              │
│  └──────┘ └──────┘              │
│                                  │
└──────────────────────────────────┘
```

Ações:
- P: Tap no horário → avança para confirmação (toque 3)
- N: Setas ◀▶ → troca de data
- N: Chips de profissional filtrados por quem oferece o serviço selecionado (via professional_services); owner pode escolher; professional vê só "Eu"

Estados:
- V: "Sem horários disponíveis neste dia" + sugestão de trocar data
- L: skeleton nos slots
- D: grade de horários disponíveis
- E: toast

---

### 3.4 ConfirmAppointmentScreen — `/appointments/new/confirm`
Auth: `professional`
Endpoints: `POST /appointments` (§8)
DS: Card (resumo), Button Primary, Top Bar (back)

```
┌──────────────────────────────────┐
│ ←  Confirmar agendamento         │
│──────────────────────────────────│
│                                  │
│  ┌──────────────────────────────┐│
│  │ Cliente      Maria Silva     ││
│  │ Serviço      Manicure        ││
│  │ Profissional Você            ││
│  │ Data         13/03/2026      ││
│  │ Horário      09:00 - 09:30   ││
│  │ Valor        R$ 50,00        ││
│  └──────────────────────────────┘│
│                                  │
│  Notas (opcional)                │
│  ┌────────────────────────────┐  │
│  │                            │  │
│  └────────────────────────────┘  │
│                                  │
│  [ Agendar ]                 (P) │
│                                  │
└──────────────────────────────────┘
```

Ações:
- P: Agendar → `POST /appointments` → toast "Agendamento criado" → `/agenda`

Estados:
- D: resumo com dados selecionados
- L: spinner no botão
- E: toast (409 TIME_SLOT_TAKEN → voltar para seleção de horário, 422 OUTSIDE_WORKING_HOURS)

---

## 4. Fluxo: Clientes

### 4.1 ClientListScreen — `/clients` (tab: Clientes)
Auth: `professional`
Endpoints: `GET /clients` (§7, com search/tag/inactive_days)
DS: Input (search), Card, Status Badge, Empty State, Bottom Tab Bar, Skeleton

```
┌──────────────────────────────────┐
│  Clientes                    [+] │
│──────────────────────────────────│
│  ┌────────────────────────────┐  │
│  │ 🔍 Buscar                  │  │
│  └────────────────────────────┘  │
│  [Todos] [VIP] [Inativos]       │
│                                  │
│  ┌──────────────────────────────┐│
│  │ [◯] Maria Silva        VIP  ││
│  │     Último: 10/03/2026       ││
│  ├──────────────────────────────┤│
│  │ [◯] Ana Costa               ││
│  │     Último: 01/02/2026       ││
│  ├──────────────────────────────┤│
│  │ [◯] Julia Santos    Inativa ││
│  │     Último: 15/12/2025       ││
│  └──────────────────────────────┘│
│                                  │
│──────────────────────────────────│
│  Agenda  Clientes  Finan.  Mais  │
└──────────────────────────────────┘
```

Ações:
- P: Tap no cliente → `/clients/:id`
- S: [+] → `/clients/new`
- N: Filtro por tag (chips)
- N: Busca por nome/telefone com debounce
- N: Pull-to-refresh

Estados:
- V: "Nenhum cliente cadastrado" + "Cadastrar primeiro cliente"
- L: skeleton shimmer
- D: lista com avatar, nome, última visita, tags
- E: toast + pull-to-refresh

---

### 4.2 ClientDetailScreen — `/clients/:id`
Auth: `professional`
Endpoints: `GET /clients/:id` (§7), `GET /clients/:id/appointments` (§7), `GET /clients/:id/consents` (§15)
DS: Card, Status Badge, Button Primary, Tabs, Top Bar (back + action)

```
┌──────────────────────────────────┐
│ ←  Maria Silva         [✏️] (S) │
│──────────────────────────────────│
│                                  │
│  [◯]  Maria Silva           VIP │
│  (11) 99999-1234                 │
│  maria@email.com                 │
│  Nascimento: 15/08/1990          │
│                                  │
│  ┌──────────┬──────────┬────────┐│
│  │ 42       │ R$2.100  │ Manic. ││
│  │ Atend.   │ Total    │ Último ││
│  └──────────┴──────────┴────────┘│
│                                  │
│  [Histórico] [Anamnese] [Pacotes]│
│──────────────────────────────────│
│                                  │
│  (conteúdo da tab selecionada)   │
│                                  │
│  [ Agendar para Maria ]     (P) │
│                                  │
└──────────────────────────────────┘
```

**Tab Histórico:** lista de `GET /clients/:id/appointments`
**Tab Anamnese:** formulário de `GET/PUT /clients/:clientId/anamneses/:categoryId` (§7)
**Tab Pacotes:** lista de `GET /clients/:clientId/package-subscriptions` (§7)

Ações:
- P: "Agendar para Maria" → `/appointments/new/service` (pré-seleciona client)
- S: [✏️] → `/clients/:id/edit`
- N: Tabs entre Histórico, Anamnese, Pacotes
- N: Tap no telefone → ligar/WhatsApp
- N: Tap num agendamento no histórico → `/agenda/:id`

Estados:
- L: skeleton
- D: dados completos com stats
- E: 404 → "Cliente não encontrado" + voltar

---

### 4.3 ClientFormScreen — `/clients/new` | `/clients/:id/edit`
Auth: `professional` (new), `professional` (edit)
Endpoints: `POST /clients` (§7) | `PATCH /clients/:id` (§7)
DS: Input, Button Primary, chips para tags, Top Bar (back)

```
┌──────────────────────────────────┐
│ ←  Novo cliente                  │
│──────────────────────────────────│
│                                  │
│  Nome *                          │
│  ┌────────────────────────────┐  │
│  │                            │  │
│  └────────────────────────────┘  │
│  Telefone                        │
│  ┌────────────────────────────┐  │
│  │                            │  │
│  └────────────────────────────┘  │
│  Email                           │
│  ┌────────────────────────────┐  │
│  │                            │  │
│  └────────────────────────────┘  │
│  Data de nascimento              │
│  ┌────────────────────────────┐  │
│  │ DD/MM/AAAA                 │  │
│  └────────────────────────────┘  │
│  Tags                            │
│  [VIP] [Novo] [+]               │
│                                  │
│  Notas                           │
│  ┌────────────────────────────┐  │
│  │                            │  │
│  └────────────────────────────┘  │
│                                  │
│  Consentimento marketing         │
│  [ ] WhatsApp  [ ] Push      (S) │
│                                  │
│  [ Salvar ]                  (P) │
└──────────────────────────────────┘
```

Ações:
- P: Salvar → `POST /clients` ou `PATCH /clients/:id`
- S: Checkboxes de consent → `POST /clients/:clientId/consents` (§15) após salvar

Estados:
- D: formulário (vazio em new, preenchido em edit)
- L: spinner no botão
- E: inline errors (409 PHONE_ALREADY_EXISTS)

---

### 4.4 AnamnesisFormScreen — `/clients/:id/anamnesis/:categoryId`
Auth: `professional`
Endpoints: `GET /clients/:clientId/anamneses` (§7), `PUT /clients/:clientId/anamneses/:categoryId` (§7)
DS: Input, Button Primary, Top Bar (back)

```
┌──────────────────────────────────┐
│ ←  Anamnese — Unhas              │
│──────────────────────────────────│
│                                  │
│  Alergia a esmalte?             │
│  ┌────────────────────────────┐  │
│  │ Não                        │  │
│  └────────────────────────────┘  │
│  Problemas nas unhas?           │
│  ┌────────────────────────────┐  │
│  │ Micose tratada em 2024     │  │
│  └────────────────────────────┘  │
│  Medicamentos em uso?           │
│  ┌────────────────────────────┐  │
│  │ Nenhum                     │  │
│  └────────────────────────────┘  │
│  Observações                     │
│  ┌────────────────────────────┐  │
│  │                            │  │
│  └────────────────────────────┘  │
│                                  │
│  [ Salvar ]                  (P) │
│                                  │
│  Última atualização: 10/03/2026  │
└──────────────────────────────────┘
```

Ações:
- P: Salvar → `PUT /clients/:clientId/anamneses/:categoryId`

Estados:
- V: formulário vazio (primeira vez)
- L: skeleton
- D: formulário preenchido com dados existentes
- E: toast

---

### 4.5 ClientDeleteConfirmation — bottom sheet em `/clients/:id`
Auth: `owner`
Endpoints: `DELETE /clients/:id` (§7), `POST /clients/:clientId/data-deletion` (§15)
DS: Bottom Sheet, Button Danger, Button Secondary

```
┌──────────────────────────────────┐
│  ─────                           │
│  Excluir cliente                 │
│──────────────────────────────────│
│                                  │
│  Tem certeza que deseja excluir  │
│  Maria Silva?                    │
│                                  │
│  [ ] Também excluir dados        │
│      pessoais (LGPD)             │
│                                  │
│  [ Excluir ]                 (P) │
│  Cancelar                    (N) │
│                                  │
└──────────────────────────────────┘
```

---

## 5. Fluxo: Financeiro

### 5.1 FinancialDashboardScreen — `/financial` (tab: Finan.)
Auth: `owner`
Endpoints: `GET /financial/summary` (§10)
DS: Card, Bottom Tab Bar, Top Bar, Skeleton

```
┌──────────────────────────────────┐
│  Financeiro                      │
│  Mar 2026              ◀ ▶  (N) │
│──────────────────────────────────│
│                                  │
│  ┌──────────────┬───────────────┐│
│  │ Faturamento  │ Comissões     ││
│  │ R$ 12.500    │ R$ 3.750      ││
│  └──────────────┴───────────────┘│
│  ┌──────────────────────────────┐│
│  │ Ticket médio    R$ 85,00     ││
│  └──────────────────────────────┘│
│                                  │
│  [ Pagamentos ]              (N) │
│  [ Comissões  ]              (N) │
│                                  │
│──────────────────────────────────│
│  Agenda  Clientes  Finan.  Mais  │
└──────────────────────────────────┘
```

Ações:
- N: "Pagamentos" → `/financial/payments`
- N: "Comissões" → `/financial/commissions`
- N: Setas ◀▶ → navega entre meses

Estados:
- V: "Nenhum dado financeiro ainda" + mensagem explicativa
- L: skeleton nos cards de métricas
- D: métricas + navegação
- E: toast + pull-to-refresh

---

### 5.2 PaymentsListScreen — `/financial/payments`
Auth: `owner`
Endpoints: `GET /payments` (§10)
DS: Card, filtro chips, Top Bar (back), Skeleton

```
┌──────────────────────────────────┐
│ ←  Pagamentos                    │
│──────────────────────────────────│
│  [Todos] [Dinheiro] [PIX] [Cart]│
│                                  │
│  13/03/2026                      │
│  ┌──────────────────────────────┐│
│  │ Maria Silva      R$ 50,00   ││
│  │ Manicure · Dinheiro          ││
│  ├──────────────────────────────┤│
│  │ Ana Costa        R$ 90,00   ││
│  │ Mani+Pedi · PIX              ││
│  └──────────────────────────────┘│
│                                  │
│  12/03/2026                      │
│  ┌──────────────────────────────┐│
│  │ Julia Santos     R$ 60,00   ││
│  │ Pedicure · Crédito (2.5%)    ││
│  └──────────────────────────────┘│
│                                  │
└──────────────────────────────────┘
```

Ações:
- P: Tap no pagamento → `/agenda/:appointmentId` (detalhe do agendamento)
- N: Filtro por método de pagamento
- N: Pull-to-refresh

Estados:
- V: "Nenhum pagamento registrado"
- L: skeleton
- D: lista agrupada por data
- E: toast

---

### 5.3 CommissionsListScreen — `/financial/commissions`
Auth: `owner`
Endpoints: `GET /commissions` (§10), `POST /commissions/pay` (§10)
DS: Card, Status Badge, Button Primary, filtro chips, Top Bar (back)

```
┌──────────────────────────────────┐
│ ←  Comissões                     │
│──────────────────────────────────│
│  [Todas] [Pendentes] [Pagas]    │
│  Profissional: [Todos ▼]        │
│                                  │
│  ┌──────────────────────────────┐│
│  │ [✓] Ana Costa     R$ 25,00  ││
│  │     Manicure · 13/03         ││
│  │     ■ Pendente               ││
│  ├──────────────────────────────┤│
│  │ [✓] Ana Costa     R$ 30,00  ││
│  │     Pedicure · 12/03         ││
│  │     ■ Pendente               ││
│  └──────────────────────────────┘│
│                                  │
│  2 selecionadas · R$ 55,00      │
│  [ Pagar selecionadas ]     (P) │
│                                  │
└──────────────────────────────────┘
```

Ações:
- P: "Pagar selecionadas" → confirmação → `POST /commissions/pay`
- S: Checkboxes para seleção múltipla
- N: Filtro por status e profissional

Estados:
- V: "Nenhuma comissão registrada"
- L: skeleton
- D: lista com seleção
- E: toast (422 ALREADY_PAID)

---

### 5.4 CommissionDetailScreen — `/financial/commissions/:id`
Auth: `owner`
Endpoints: dados carregados via lista (não necessita endpoint individual)
DS: Card, Status Badge, Top Bar (back)

```
┌──────────────────────────────────┐
│ ←  Detalhe da comissão           │
│──────────────────────────────────│
│                                  │
│  ┌──────────────────────────────┐│
│  │ Profissional    Ana Costa    ││
│  │ Serviço         Manicure     ││
│  │ Data            13/03/2026   ││
│  │ Valor total     R$ 50,00     ││
│  │ Comissão (50%)  R$ 25,00     ││
│  │ Estúdio         R$ 25,00     ││
│  │ Taxa cartão     R$ 0,00      ││
│  │ Status          ■ Pendente   ││
│  └──────────────────────────────┘│
│                                  │
└──────────────────────────────────┘
```

Estados:
- D: dados completos da comissão (carregados via lista, sem request adicional)

---

## 6. Fluxo: Configurações

### 6.1 MoreScreen — `/more` (tab: Mais)
Auth: `professional`
Endpoints: `GET /profile` (§2), `GET /studios/me` (§3)
DS: Card, Bottom Tab Bar, Top Bar

```
┌──────────────────────────────────┐
│  Mais                            │
│──────────────────────────────────│
│                                  │
│  [◯] Maria Profissional         │
│  Studio da Maria                 │
│                                  │
│  ┌──────────────────────────────┐│
│  │ 👤 Meu perfil            → ││
│  │ 🏪 Estúdio               → ││
│  │ ✂️  Serviços              → ││
│  │ 👥 Equipe                → ││
│  │ 📦 Pacotes               → ││
│  │ 🕐 Horários bloqueados   → ││
│  │ 💬 Conversas WhatsApp    → ││
│  ├──────────────────────────────┤│
│  │ 🤖 Assistente IA         → ││
│  │ 📢 Campanhas             → ││
│  │ 💳 Assinatura            → ││
│  ├──────────────────────────────┤│
│  │ 📋 Logs de auditoria     → ││
│  │ 🔔 Notificações          → ││
│  ├──────────────────────────────┤│
│  │ Sair                        ││
│  └──────────────────────────────┘│
│                                  │
│──────────────────────────────────│
│  Agenda  Clientes  Finan.  Mais  │
└──────────────────────────────────┘
```

Regras de visibilidade:
- **Owner vê tudo**
- **Professional vê:** Meu perfil, Horários bloqueados, Conversas WhatsApp, Notificações, Sair
- Itens owner-only: Estúdio, Serviços, Equipe, Pacotes, IA, Campanhas, Assinatura, Auditoria

---

### 6.2 ProfileScreen — `/profile`
Auth: `authenticated`
Endpoints: `GET /profile` (§2), `PATCH /profile` (§2)
DS: Input, Button Primary, Top Bar (back)

```
┌──────────────────────────────────┐
│ ←  Meu perfil                    │
│──────────────────────────────────│
│                                  │
│         [◯ avatar]               │
│       Trocar foto            (S) │
│                                  │
│  Nome completo                   │
│  ┌────────────────────────────┐  │
│  │ Maria Profissional         │  │
│  └────────────────────────────┘  │
│  Telefone                        │
│  ┌────────────────────────────┐  │
│  │ (11) 99999-1234            │  │
│  └────────────────────────────┘  │
│                                  │
│  [ Salvar ]                  (P) │
│                                  │
└──────────────────────────────────┘
```

---

### 6.3 StudioSettingsScreen — `/settings/studio`
Auth: `owner`
Endpoints: `GET /studios/me` (§3), `PATCH /studios/me` (§3), `GET/POST/DELETE /studios/me/photos` (§3)
DS: Input, Button Primary, Card, Top Bar (back)

```
┌──────────────────────────────────┐
│ ←  Estúdio                       │
│──────────────────────────────────│
│                                  │
│  [logo]  Trocar logo         (S) │
│                                  │
│  Nome                            │
│  ┌────────────────────────────┐  │
│  │ Studio da Maria            │  │
│  └────────────────────────────┘  │
│  URL pública                     │
│  ┌─────┬──────────────────────┐  │
│  │oriz/│ studio-maria         │  │
│  └─────┴──────────────────────┘  │
│  Telefone                        │
│  ┌────────────────────────────┐  │
│  │ (79) 99999-0000            │  │
│  └────────────────────────────┘  │
│  Endereço                        │
│  ┌────────────────────────────┐  │
│  │ Rua A, 123, Aracaju       │  │
│  └────────────────────────────┘  │
│  Descrição                       │
│  ┌────────────────────────────┐  │
│  │ Salão especializado em...  │  │
│  └────────────────────────────┘  │
│  Fuso horário                    │
│  ┌────────────────────────────┐  │
│  │ America/Sao_Paulo       ▼  │  │
│  └────────────────────────────┘  │
│                                  │
│  Configurações                   │
│  ┌──────────────────────────────┐│
│  │ Lembrete     [12h ▼] antes  ││
│  │ Booking público  [ativo]    ││
│  └──────────────────────────────┘│
│                                  │
│  Fotos do estúdio                │
│  ┌────┐┌────┐┌────┐ [+]        │
│  │ 📷 ││ 📷 ││ 📷 │             │
│  └────┘└────┘└────┘             │
│                                  │
│  [ Salvar ]                  (P) │
└──────────────────────────────────┘
```

Estados:
- L: skeleton no formulário
- D: formulário preenchido
- E: inline errors (409 SLUG_TAKEN)

---

### 6.4 ServicesManagementScreen — `/settings/services`
Auth: `owner`
Endpoints: `GET /services` (§5), `GET /service-categories` (§4)
DS: Card, FAB, chips, Top Bar (back)

```
┌──────────────────────────────────┐
│ ←  Serviços                  [+] │
│──────────────────────────────────│
│  [Todas] [Unhas] [Cílios] [...]  │
│                                  │
│  ┌──────────────────────────────┐│
│  │ Manicure          [✏️] [🗑] ││
│  │ 30min · R$50 · Buffer 5min   ││
│  │ ■ Ativo                      ││
│  ├──────────────────────────────┤│
│  │ Pedicure          [✏️] [🗑] ││
│  │ 45min · R$60 · Buffer 10min  ││
│  │ ■ Ativo                      ││
│  └──────────────────────────────┘│
│                                  │
└──────────────────────────────────┘
```

Ações:
- S: [+] → bottom sheet ou `/settings/services/new`
- P: Tap → `/settings/services/:id/edit`
- S: [🗑] → confirmação → `DELETE /services/:id`

Estados:
- V: "Nenhum serviço cadastrado" + "Criar serviço"
- L: skeleton nos cards
- D: lista filtrada por categoria
- E: toast (409 SERVICE_HAS_APPOINTMENTS ao excluir)

---

### 6.5 TeamManagementScreen — `/settings/team`
Auth: `owner`
Endpoints: `GET /professionals` (§6)
DS: Card, FAB, Top Bar (back)

```
┌──────────────────────────────────┐
│ ←  Equipe                    [+] │
│──────────────────────────────────│
│                                  │
│  ┌──────────────────────────────┐│
│  │ [◯] Maria (você)    Owner   ││
│  │     Manicure, Pedicure       ││
│  │     Comissão: 50%            ││
│  ├──────────────────────────────┤│
│  │ [◯] Ana Costa    Profission.││
│  │     Cílios, Sobrancelha      ││
│  │     Comissão: 40%            ││
│  │     ■ Ativo                  ││
│  └──────────────────────────────┘│
│                                  │
└──────────────────────────────────┘
```

Ações:
- S: [+] → `/settings/team/new`
- P: Tap → `/settings/team/:id/edit`

Estados:
- V: "Apenas você no estúdio" + "Convidar profissional"
- L: skeleton nos cards
- D: lista de profissionais com comissão e status
- E: toast

---

### 6.6 ProfessionalFormScreen — `/settings/team/new` | `/settings/team/:id/edit`
Auth: `owner`
Endpoints: `POST /professionals` (§6), `PATCH /professionals/:id` (§6), `GET /services` (§5)
DS: Input, Button Primary, chips, Top Bar (back)

```
┌──────────────────────────────────┐
│ ←  Novo profissional             │
│──────────────────────────────────│
│                                  │
│  Nome                            │
│  ┌────────────────────────────┐  │
│  │                            │  │
│  └────────────────────────────┘  │
│  Especialidades                  │
│  ┌────────────────────────────┐  │
│  │ Unhas, Pedicure            │  │
│  └────────────────────────────┘  │
│                                  │
│  Serviços vinculados             │
│  [✓] Manicure                    │
│  [✓] Pedicure                    │
│  [ ] Cílios                      │
│  [ ] Sobrancelha                 │
│                                  │
│  Comissão                        │
│  [Percentual] [Fixo]            │
│  ┌────────────────────────────┐  │
│  │ 50                     %   │  │
│  └────────────────────────────┘  │
│                                  │
│  Taxa do cartão                  │
│  [Estúdio] [Profissional] [50/50]│
│                                  │
│  Horários                        │
│  Seg  08:00 - 18:00         [✓] │
│  Ter  08:00 - 18:00         [✓] │
│  ...                             │
│                                  │
│  [ Salvar ]                  (P) │
└──────────────────────────────────┘
```

Estados:
- D: formulário (vazio em new, preenchido em edit)
- L: spinner no botão + skeleton na lista de serviços
- E: inline errors (409 PROFESSIONAL_HAS_APPOINTMENTS ao excluir)

---

## 7. Fluxo: Booking Público (Web)

### 7.1 PublicStudioPage — `oriz.app/:slug`
Auth: `public`
Endpoints: `GET /public/studios/:slug` (§17), `GET /public/studios/:slug/service-categories` (§17)
DS: (web-specific, segue tokens do Design System)

```
┌──────────────────────────────────┐
│  [logo]  Studio da Maria         │
│  Rua A, 123, Aracaju            │
│  (79) 99999-0000                 │
│──────────────────────────────────│
│                                  │
│  ┌────┐┌────┐┌────┐             │
│  │ 📷 ││ 📷 ││ 📷 │   (carousel)│
│  └────┘└────┘└────┘             │
│                                  │
│  Salão especializado em unhas    │
│  e design de sobrancelha...      │
│                                  │
│  [ Agendar agora ]          (P) │
│                                  │
└──────────────────────────────────┘
```

Ações:
- P: "Agendar agora" → `/book/:slug/service`

Estados:
- L: skeleton
- D: info do estúdio com fotos
- E: 404 "Estúdio não encontrado"

---

### 7.2 PublicSelectServicePage — `oriz.app/:slug/book/service`
Auth: `public`
Endpoints: `GET /public/studios/:slug/services` (§17), `GET /public/studios/:slug/service-categories` (§17)

```
┌──────────────────────────────────┐
│ ←  Escolha o serviço             │
│──────────────────────────────────│
│  [Todos] [Unhas] [Cílios]       │
│                                  │
│  ┌──────────────────────────────┐│
│  │ Manicure                     ││
│  │ 30min  ·  R$ 50,00           ││
│  ├──────────────────────────────┤│
│  │ Pedicure                     ││
│  │ 45min  ·  R$ 60,00           ││
│  └──────────────────────────────┘│
│                                  │
└──────────────────────────────────┘
```

Ações:
- P: Tap → `/book/:slug/professional`

Estados:
- V: "Nenhum serviço disponível no momento"
- L: skeleton nos cards
- D: lista de serviços agrupada por categoria
- E: toast

---

### 7.3 PublicSelectProfessionalPage — `oriz.app/:slug/book/professional`
Auth: `public`
Endpoints: `GET /public/studios/:slug/professionals` (§17)

```
┌──────────────────────────────────┐
│ ←  Escolha o profissional        │
│──────────────────────────────────│
│                                  │
│  ┌──────────────────────────────┐│
│  │ [◯] Maria                   ││
│  │     Unhas, Pedicure          ││
│  ├──────────────────────────────┤│
│  │ [◯] Ana                     ││
│  │     Cílios, Sobrancelha      ││
│  └──────────────────────────────┘│
│                                  │
└──────────────────────────────────┘
```

Ações:
- P: Tap → `/book/:slug/slot`

Estados:
- V: "Nenhum profissional disponível para este serviço"
- L: skeleton nos cards
- D: lista de profissionais com especialidades
- E: toast

---

### 7.4 PublicSelectSlotPage — `oriz.app/:slug/book/slot`
Auth: `public`
Endpoints: `GET /public/studios/:slug/available-slots` (§17)

```
┌──────────────────────────────────┐
│ ←  Escolha o horário             │
│──────────────────────────────────│
│  ◀  Qui, 13 Mar 2026  ▶         │
│                                  │
│  ┌──────┐ ┌──────┐ ┌──────┐     │
│  │09:00 │ │09:30 │ │10:00 │     │
│  └──────┘ └──────┘ └──────┘     │
│  ┌──────┐ ┌──────┐ ┌──────┐     │
│  │14:00 │ │14:30 │ │15:00 │     │
│  └──────┘ └──────┘ └──────┘     │
│                                  │
└──────────────────────────────────┘
```

Ações:
- P: Tap no horário → `/book/:slug/confirm`

Estados:
- V: "Sem horários disponíveis neste dia"
- L: skeleton
- D: grade de slots
- E: toast (422 PUBLIC_BOOKING_DISABLED)

---

### 7.5 PublicConfirmBookingPage — `oriz.app/:slug/book/confirm`
Auth: `public`
Endpoints: `POST /public/studios/:slug/appointments` (§17)

```
┌──────────────────────────────────┐
│ ←  Confirmar agendamento         │
│──────────────────────────────────│
│                                  │
│  ┌──────────────────────────────┐│
│  │ Serviço      Manicure        ││
│  │ Profissional Maria           ││
│  │ Data         13/03/2026      ││
│  │ Horário      09:00 - 09:30   ││
│  │ Valor        R$ 50,00        ││
│  └──────────────────────────────┘│
│                                  │
│  Seu nome *                      │
│  ┌────────────────────────────┐  │
│  │                            │  │
│  └────────────────────────────┘  │
│  Seu telefone *                  │
│  ┌────────────────────────────┐  │
│  │                            │  │
│  └────────────────────────────┘  │
│  Observações                     │
│  ┌────────────────────────────┐  │
│  │                            │  │
│  └────────────────────────────┘  │
│                                  │
│  [✓] Aceito receber mensagens    │
│      de marketing via WhatsApp   │
│                                  │
│  (Consent push capturado apenas  │
│   no app — cliente público não   │
│   tem app instalado)             │
│                                  │
│  [ Confirmar agendamento ]   (P) │
│                                  │
└──────────────────────────────────┘
```

Pós-confirmação: tela de sucesso inline com resumo.

```
┌──────────────────────────────────┐
│                                  │
│         [✓ ícone sucesso]        │
│                                  │
│   Agendamento confirmado!        │
│                                  │
│   Manicure com Maria             │
│   13/03/2026 às 09:00            │
│                                  │
│   Você receberá uma confirmação  │
│   por WhatsApp.                  │
│                                  │
│  [ Agendar outro ]          (S) │
│                                  │
└──────────────────────────────────┘
```

Ações:
- P: "Confirmar agendamento" → `POST /public/studios/:slug/appointments`
- S: "Agendar outro" → volta ao início do fluxo

Estados:
- D: formulário
- L: spinner no botão
- E: inline errors (409 TIME_SLOT_TAKEN, 429 TOO_MANY_REQUESTS)

---

## 8. Fluxo: IA & Conversas

### 8.1 ConversationListScreen — `/conversations`
Auth: `professional`
Endpoints: `GET /conversations` (§12)
DS: Card, Status Badge, Top Bar, Skeleton

```
┌──────────────────────────────────┐
│ ←  Conversas WhatsApp            │
│──────────────────────────────────│
│  [Ativas] [Escaladas] [Fechadas]│
│                                  │
│  ┌──────────────────────────────┐│
│  │ Maria Silva       14:32     ││
│  │ "Olá, quero agendar..."     ││
│  │ ■ Ativa                      ││
│  ├──────────────────────────────┤│
│  │ (11) 99999-0000    13:15    ││
│  │ "Quanto custa manicure?"    ││
│  │ ■ Escalada                   ││
│  └──────────────────────────────┘│
│                                  │
└──────────────────────────────────┘
```

Ações:
- P: Tap → `/conversations/:id`
- N: Filtro por status

Estados:
- V: "Nenhuma conversa ainda" + info sobre ativar IA
- L: skeleton
- D: lista ordenada por last_message_at
- E: toast

---

### 8.2 ConversationDetailScreen — `/conversations/:id`
Auth: `professional`
Endpoints: `GET /conversations/:id/messages` (§12), `POST /conversations/:id/escalate` (§12), `POST /conversations/:id/close` (§12)
DS: Card (mensagens), Button Secondary, Top Bar (back + actions)

```
┌──────────────────────────────────┐
│ ←  Maria Silva    [Escalar](S)   │
│──────────────────────────────────│
│                                  │
│         [🤖 IA]                  │
│  Olá Maria! Sou a assistente     │
│  do Studio. Como posso ajudar?   │
│                                  │
│  [👤 Cliente]                    │
│  Quero agendar manicure          │
│  pra sexta                       │
│                                  │
│         [🤖 IA]                  │
│  Temos horários disponíveis na   │
│  sexta: 09:00, 10:00, 14:00.    │
│  Qual prefere?                   │
│                                  │
│  [👤 Cliente]                    │
│  10h                             │
│                                  │
│         [🤖 IA]                  │
│  Agendado! Manicure sexta        │
│  15/03 às 10:00 com Maria.       │
│                                  │
│──────────────────────────────────│
│  [ Fechar conversa ]         (P) │
└──────────────────────────────────┘
```

Ações:
- P: "Fechar conversa" → `POST /conversations/:id/close`
- S: "Escalar" → `POST /conversations/:id/escalate`

Estados:
- L: skeleton
- D: mensagens com visual diferenciado por role (client/assistant/system)
- E: toast

---

### 8.3 AIConfigScreen — `/settings/ai`
Auth: `owner`
Endpoints: `GET /ai/config` (§12), `PATCH /ai/config` (§12)
DS: Input, Button Primary, toggle, Top Bar (back)

```
┌──────────────────────────────────┐
│ ←  Assistente IA                 │
│──────────────────────────────────│
│                                  │
│  Ativar assistente     [ativo]   │
│                                  │
│  Tom de voz                      │
│  ┌────────────────────────────┐  │
│  │ Profissional e amigável    │  │
│  └────────────────────────────┘  │
│  Mensagem de boas-vindas         │
│  ┌────────────────────────────┐  │
│  │ Olá! Sou a assistente do   │  │
│  │ Studio da Maria...         │  │
│  └────────────────────────────┘  │
│  Mensagem de fallback            │
│  ┌────────────────────────────┐  │
│  │ Desculpe, não consegui     │  │
│  │ entender. Vou chamar...    │  │
│  └────────────────────────────┘  │
│                                  │
│  Regras de agendamento           │
│  ┌──────────────────────────────┐│
│  │ Antecedência máx. [30] dias ││
│  │ Antecedência mín. [2] horas ││
│  │ Auto-confirmar    [ativo]   ││
│  └──────────────────────────────┘│
│                                  │
│  [ Salvar ]                  (P) │
└──────────────────────────────────┘
```

---

## 9. Fluxo: Marketing

### 9.1 CampaignListScreen — `/campaigns`
Auth: `owner`
Endpoints: `GET /campaigns` (§13)
DS: Card, Status Badge, FAB, Top Bar (back)

```
┌──────────────────────────────────┐
│ ←  Campanhas                 [+] │
│──────────────────────────────────│
│  [Todas] [Aniversário] [Reativ.] │
│                                  │
│  ┌──────────────────────────────┐│
│  │ 🎂 Aniversário              ││
│  │ WhatsApp · Ativa             ││
│  │ "Feliz aniversário, {nome}!"││
│  ├──────────────────────────────┤│
│  │ 🔄 Reativação               ││
│  │ WhatsApp · Ativa             ││
│  │ Inatividade: 60 dias         ││
│  │ Desconto: 10%                ││
│  └──────────────────────────────┘│
│                                  │
└──────────────────────────────────┘
```

Ações:
- S: [+] → `/campaigns/new`
- P: Tap → `/campaigns/:id`

---

### 9.2 CampaignDetailScreen — `/campaigns/:id`
Auth: `owner`
Endpoints: `GET /campaigns/:id/metrics` (§13), `PATCH /campaigns/:id` (§13), `DELETE /campaigns/:id` (§13)
DS: Card, Button Primary, Button Danger, Top Bar (back + edit)

```
┌──────────────────────────────────┐
│ ←  Aniversário       [✏️]   (S) │
│──────────────────────────────────│
│                                  │
│  ┌──────────┬──────────┬────────┐│
│  │ 150      │ 142      │ 12     ││
│  │ Enviadas │ Entregues│ Retorno││
│  └──────────┴──────────┴────────┘│
│  Taxa de retorno: 8%             │
│                                  │
│  Configuração                    │
│  ┌──────────────────────────────┐│
│  │ Tipo        Aniversário      ││
│  │ Canal       WhatsApp         ││
│  │ Status      Ativa            ││
│  │ Mensagem    "Feliz aniv..."  ││
│  │ Desconto    10%              ││
│  └──────────────────────────────┘│
│                                  │
│  Envios recentes (últimos 5)     │
│  ┌──────────────────────────────┐│
│  │ Maria Silva   12/03  Entregue││
│  │ Ana Costa     10/03  Retorno ││
│  └──────────────────────────────┘│
│  Ver todos os envios →       (N) │
│                                  │
│  [ Excluir campanha ]    Danger  │
│                                  │
└──────────────────────────────────┘
```

---

### 9.3 CampaignFormScreen — `/campaigns/new` | `/campaigns/:id/edit`
Auth: `owner`
Endpoints: `POST /campaigns` (§13), `PATCH /campaigns/:id` (§13)
DS: Input, Button Primary, radio/segmented control, Top Bar (back)

```
┌──────────────────────────────────┐
│ ←  Nova campanha                 │
│──────────────────────────────────│
│                                  │
│  Tipo                            │
│  [Aniversário] [Reativação] [+] │
│                                  │
│  Mensagem                        │
│  ┌────────────────────────────┐  │
│  │ Olá {nome}! Preparamos     │  │
│  │ algo especial para você... │  │
│  └────────────────────────────┘  │
│  Use {nome} para o nome do       │
│  cliente.                        │
│                                  │
│  Desconto (%)                    │
│  ┌────────────────────────────┐  │
│  │ 10                         │  │
│  └────────────────────────────┘  │
│                                  │
│  Inatividade (dias, se reativ.) │
│  ┌────────────────────────────┐  │
│  │ 60                         │  │
│  └────────────────────────────┘  │
│                                  │
│  Canal                           │
│  [WhatsApp] [Push] [Ambos]      │
│                                  │
│  [ Criar campanha ]          (P) │
└──────────────────────────────────┘
```

Ações:
- P: "Criar campanha" / "Salvar" → `POST /campaigns` ou `PATCH /campaigns/:id`

Estados:
- D: formulário (vazio em new, preenchido em edit)
- L: spinner no botão
- E: inline errors (422 INVALID_CHANNEL, 400 campo obrigatório)

---

## 10. Fluxo: Billing

### 10.1 SubscriptionScreen — `/billing`
Auth: `owner`
Endpoints: `GET /billing/subscription` (§14)
DS: Card, Button Primary, Button Secondary, Top Bar (back)

```
┌──────────────────────────────────┐
│ ←  Assinatura                    │
│──────────────────────────────────│
│                                  │
│  Plano atual                     │
│  ┌──────────────────────────────┐│
│  │ PRO               R$ 29,90  ││
│  │ Mensal                       ││
│  │ Válido até 13/04/2026        ││
│  │ ■ Ativo                      ││
│  └──────────────────────────────┘│
│                                  │
│  [ Trocar plano ]            (P) │
│  [ Ver faturas ]             (N) │
│                                  │
│  Cancelar assinatura         (N) │
│                                  │
└──────────────────────────────────┘
```

Ações:
- P: "Trocar plano" → `/billing/plans`
- N: "Ver faturas" → `/billing/invoices`
- N: "Cancelar" → confirmação → `POST /billing/subscription/cancel`

Estados:
- V (sem assinatura): mostrar planos disponíveis diretamente
- L: skeleton
- D: dados da subscription
- E: toast

---

### 10.2 PlansScreen — `/billing/plans`
Auth: `owner`
Endpoints: `POST /billing/subscription` (§14), `PATCH /billing/subscription` (§14)
DS: Card, Button Primary, Top Bar (back)

```
┌──────────────────────────────────┐
│ ←  Escolha seu plano             │
│──────────────────────────────────│
│                                  │
│  ┌──────────────────────────────┐│
│  │ BÁSICO           R$ 19,90/m ││
│  │ · Agenda ilimitada           ││
│  │ · Clientes ilimitados        ││
│  │ · Página pública             ││
│  │ [ Assinar ]                  ││
│  ├──────────────────────────────┤│
│  │ PRO ★ popular    R$ 29,90/m ││
│  │ · Tudo do Básico             ││
│  │ · Relatórios financeiros     ││
│  │ · Push notifications         ││
│  │ [ Assinar ]             (P)  ││
│  ├──────────────────────────────┤│
│  │ PREMIUM          R$ 59,90/m ││
│  │ · Tudo do Pro                ││
│  │ · Assistente IA WhatsApp     ││
│  │ · Campanhas de marketing     ││
│  │ [ Assinar ]                  ││
│  └──────────────────────────────┘│
│                                  │
└──────────────────────────────────┘
```

Ações:
- P: "Assinar" → `POST /billing/subscription` → redireciona para checkout_url do gateway

---

### 10.3 InvoicesScreen — `/billing/invoices`
Auth: `owner`
Endpoints: `GET /billing/invoices` (§14)
DS: Card, Status Badge, Top Bar (back)

```
┌──────────────────────────────────┐
│ ←  Faturas                       │
│──────────────────────────────────│
│  [Todas] [Pendentes] [Pagas]    │
│                                  │
│  ┌──────────────────────────────┐│
│  │ Mar 2026         R$ 29,90   ││
│  │ Vence: 13/03     ■ Paga     ││
│  ├──────────────────────────────┤│
│  │ Fev 2026         R$ 29,90   ││
│  │ Vence: 13/02     ■ Paga     ││
│  ├──────────────────────────────┤│
│  │ Jan 2026         R$ 29,90   ││
│  │ Vence: 13/01     ■ Paga     ││
│  └──────────────────────────────┘│
│                                  │
└──────────────────────────────────┘
```

---

## 11. Fluxo: Dashboard Web (Owner)

> Layout web > 1024px. Sidebar fixa à esquerda, content area com max-width 1200px.
> Segue tokens do DESIGN_SYSTEM.md com adaptações para desktop (tabelas com sorting, grid 3-4 colunas).
> Rotas prefixadas com `/dashboard`.

### 11.1 DashboardOverviewPage — `/dashboard`
Auth: `owner`
Endpoints: `GET /financial/summary` (§10), `GET /appointments` (§8, date=hoje), `GET /commissions` (§10, status=pending)
DS: Card (métricas), Appointment Card, Sidebar Navigation, Skeleton

```
┌────────────┬─────────────────────────────────────────────────┐
│            │  Overview                        Studio da Maria│
│  [logo]    │─────────────────────────────────────────────────│
│            │                                                 │
│  Overview● │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌─────┐│
│  Agenda    │  │Faturamento│ │ Agend.   │ │ Ticket   │ │Comis││
│  Clientes  │  │ R$12.500 │ │ hoje: 8  │ │ R$85,00  │ │pend.││
│  Financeiro│  │ +12% ▲   │ │          │ │          │ │R$1.2││
│  Equipe    │  └──────────┘ └──────────┘ └──────────┘ └─────┘│
│  Serviços  │                                                 │
│  Pacotes   │  Agenda de hoje                                 │
│  IA        │  ┌─────────────────────────────────────────────┐│
│  Campanhas │  │ 09:00  Maria Silva    Manicure   ■ Confirm. ││
│  Billing   │  │ 10:00  Ana Costa      Pedicure   ■ Confirm. ││
│  Auditoria │  │ 11:00  ─ ─ ─ livre ─ ─ ─                   ││
│            │  │ 12:00  ▒▒▒ Almoço ▒▒▒                      ││
│  ─────     │  │ 14:00  Julia Santos   Cílios     ■ Confirm. ││
│  Config.   │  └─────────────────────────────────────────────┘│
│  Sair      │                                                 │
└────────────┴─────────────────────────────────────────────────┘
```

Ações:
- P: Tap em card de métrica → navega para seção correspondente
- N: Tap em agendamento → `/dashboard/agenda/:id`
- N: Sidebar items → navegação entre seções

Estados:
- V: "Configure seu estúdio para começar" + link para onboarding
- L: skeleton shimmer nos cards de métricas e lista
- D: métricas + agenda do dia
- E: toast + retry

---

### 11.2 DashboardAgendaPage — `/dashboard/agenda`
Auth: `owner`
Endpoints: `GET /appointments` (§8), `GET /professionals` (§6)
DS: Appointment Card, Status Badge, Sidebar Navigation, filtros inline

```
┌────────────┬─────────────────────────────────────────────────┐
│            │  Agenda              [+ Novo agendamento]   (P) │
│  Sidebar   │─────────────────────────────────────────────────│
│            │  ◀  Semana 10-16 Mar 2026  ▶    [Dia] [Semana] │
│  ...       │  Profissional: [Todos ▼]                        │
│  Agenda●   │                                                 │
│  ...       │        Seg    Ter    Qua    Qui    Sex    Sab   │
│            │  Maria  ██     ██     ██     ██     ██     ██   │
│            │  Ana     ██            ██     ██     ██          │
│            │  Julia          ██     ██            ██     ██   │
│            │                                                 │
│            │─────────────────────────────────────────────────│
│            │  Qui, 13 Mar — Detalhes do dia                  │
│            │  ┌─────────────────────────────────────────────┐│
│            │  │ 09:00  Maria Silva  Manicure  Maria ■Conf. ││
│            │  │ 10:00  Ana Costa    Pedicure  Ana   ■Conf. ││
│            │  │ 14:00  Julia Santos Cílios    Julia ■Conf. ││
│            │  └─────────────────────────────────────────────┘│
└────────────┴─────────────────────────────────────────────────┘
```

Ações:
- P: [+ Novo agendamento] → modal de criação rápida
- N: Setas ◀▶ → semana anterior/próxima
- N: Toggle Dia/Semana
- N: Filtro por profissional
- N: Tap em agendamento → detalhe no painel lateral ou modal
- N: Tap em dia da grade → expande detalhes abaixo

Estados:
- V: "Nenhum agendamento esta semana" + botão agendar
- L: skeleton na grade
- D: grade multi-profissional + lista detalhada
- E: toast + retry

Regras:
- **Visão multi-profissional**: diferencial do dashboard vs mobile (que mostra 1 profissional por vez)
- API: `GET /appointments` sem `professional_id` retorna todos do studio; frontend agrupa por `professional_id` no response
- Cores por profissional na grade semanal
- Split view: grade em cima, detalhes do dia selecionado embaixo

---

### 11.3 DashboardClientsPage — `/dashboard/clients`
Auth: `owner`
Endpoints: `GET /clients` (§7)
DS: Table (web), Input (search), filtros inline, Sidebar Navigation

```
┌────────────┬─────────────────────────────────────────────────┐
│            │  Clientes (247)           [+ Novo cliente]  (P) │
│  Sidebar   │─────────────────────────────────────────────────│
│            │  ┌─────────────────────────────┐ Tags: [Todos▼]│
│  ...       │  │ 🔍 Buscar por nome/telefone │ Inativos: [▼] │
│  Clientes● │  └─────────────────────────────┘                │
│  ...       │                                                 │
│            │  ┌─────┬──────────┬──────────┬────────┬───────┐│
│            │  │     │ Nome     │ Telefone │ Última │ Tags  ││
│            │  │     │          │          │ visita │       ││
│            │  ├─────┼──────────┼──────────┼────────┼───────┤│
│            │  │ [◯] │Maria     │99999-1234│10/03   │ VIP   ││
│            │  │ [◯] │Ana Costa │99999-5678│01/02   │       ││
│            │  │ [◯] │Julia     │99999-9012│15/12   │Inativa││
│            │  │ [◯] │Carol     │99999-3456│08/03   │ VIP   ││
│            │  │ [◯] │Beatriz   │99999-7890│05/03   │ Nova  ││
│            │  └─────┴──────────┴──────────┴────────┴───────┘│
│            │                                                 │
│            │  [ Carregar mais ]                               │
└────────────┴─────────────────────────────────────────────────┘
```

Ações:
- P: [+ Novo cliente] → modal de criação
- N: Tap no nome → `/dashboard/clients/:id` (painel lateral ou página)
- N: Busca com debounce
- N: Filtro por tag e inatividade
- N: Sorting por coluna (nome, última visita)
- N: "Carregar mais" → próxima página via cursor

Estados:
- V: "Nenhum cliente cadastrado" + botão criar
- L: skeleton na tabela
- D: tabela com sorting + botão "Carregar mais" (cursor-based)
- E: toast + retry

Regras:
- **Tabela com sorting** (diferencial web vs mobile que usa lista)
- Paginação cursor-based: botão "Carregar mais" em vez de paginação numérica (API usa cursor, não offset)
- Colunas sortáveis: Nome, Última visita, Tags

---

### 11.4 DashboardFinancialPage — `/dashboard/financial`
Auth: `owner`
Endpoints: `GET /financial/summary` (§10), `GET /payments` (§10), `GET /commissions` (§10)
DS: Card (métricas), Table, Sidebar Navigation

```
┌────────────┬─────────────────────────────────────────────────┐
│            │  Financeiro               Período: [Mar 2026 ▼]│
│  Sidebar   │─────────────────────────────────────────────────│
│            │                                                 │
│  ...       │  ┌──────────┐ ┌──────────┐ ┌──────────────────┐│
│  Finance●  │  │Faturamento│ │Comissões │ │ Ticket médio     ││
│  ...       │  │ R$12.500 │ │ R$3.750  │ │ R$ 85,00         ││
│            │  └──────────┘ └──────────┘ └──────────────────┘│
│            │                                                 │
│            │  ┌─────────────────────────────────────────────┐│
│            │  │  Faturamento mensal (gráfico de barras)     ││
│            │  │  ████                                       ││
│            │  │  ████ ████                                  ││
│            │  │  ████ ████ ████                             ││
│            │  │  Jan  Fev  Mar                              ││
│            │  └─────────────────────────────────────────────┘│
│            │                                                 │
│            │  [Pagamentos] [Comissões]                       │
│            │  ┌─────┬──────────┬────────┬────────┬─────────┐│
│            │  │Data │ Cliente  │ Valor  │ Método │Profiss. ││
│            │  ├─────┼──────────┼────────┼────────┼─────────┤│
│            │  │13/03│Maria     │R$50    │Dinheiro│Maria    ││
│            │  │13/03│Ana Costa │R$90    │PIX     │Ana      ││
│            │  │12/03│Julia     │R$60    │Crédito │Maria    ││
│            │  └─────┴──────────┴────────┴────────┴─────────┘│
│            │                                                 │
│            │  [ Carregar mais ]                               │
└────────────┴─────────────────────────────────────────────────┘
```

Ações:
- P: Seletor de período → recarrega dados
- N: Tabs Pagamentos/Comissões → alterna tabela
- N: Sorting por coluna
- S: Botão "Pagar selecionadas" na tab Comissões (mesmo fluxo do mobile)

Estados:
- V: "Nenhum dado financeiro" + mensagem explicativa
- L: skeleton nos cards + tabela
- D: métricas + gráfico + tabela detalhada
- E: toast + retry

Regras:
- **Gráfico de barras**: diferencial do dashboard (mobile não tem gráficos)
- Revenue por profissional e por serviço como breakdown expandível
- Exportar dados (futuro v2, não incluir botão agora)

---

### 11.5 DashboardTeamPage — `/dashboard/team`
Auth: `owner`
Endpoints: `GET /professionals` (§6)
DS: Card (grid), Table, Sidebar Navigation

```
┌────────────┬─────────────────────────────────────────────────┐
│            │  Equipe (3)            [+ Novo profissional] (P)│
│  Sidebar   │─────────────────────────────────────────────────│
│            │                                                 │
│  ...       │  ┌──────────────┐ ┌──────────────┐ ┌──────────┐│
│  Equipe●   │  │ [◯] Maria    │ │ [◯] Ana      │ │ [◯] Julia││
│  ...       │  │ Owner        │ │ Profissional  │ │ Profiss. ││
│            │  │ Unhas, Pedi  │ │ Cílios, Sobr. │ │ Unhas    ││
│            │  │ Comissão 50% │ │ Comissão 40%  │ │ Com. 45% ││
│            │  │ ■ Ativo      │ │ ■ Ativo       │ │ ■ Ativo  ││
│            │  │ [Editar]     │ │ [Editar]      │ │ [Editar] ││
│            │  └──────────────┘ └──────────────┘ └──────────┘│
│            │                                                 │
│            │  Performance do mês                             │
│            │  ┌────────┬──────────┬────────┬────────────────┐│
│            │  │Profiss.│Atendim.  │Receita │Comissão pend.  ││
│            │  ├────────┼──────────┼────────┼────────────────┤│
│            │  │Maria   │ 42       │R$3.200 │ R$ 1.600       ││
│            │  │Ana     │ 35       │R$4.500 │ R$ 1.800       ││
│            │  │Julia   │ 28       │R$2.800 │ R$ 1.260       ││
│            │  └────────┴──────────┴────────┴────────────────┘│
└────────────┴─────────────────────────────────────────────────┘
```

Ações:
- P: [+ Novo profissional] → modal ou `/dashboard/team/new`
- N: [Editar] → modal de edição do profissional
- N: Tap na linha da tabela → detalhes de performance

Estados:
- V: "Apenas você no estúdio" + botão adicionar
- L: skeleton nos cards + tabela
- D: grid de profissionais + tabela de performance
- E: toast + retry

Regras:
- **Grid de cards** para visão geral + **tabela de performance** para métricas
- Performance derivada por profissional: Atendimentos via `GET /appointments?professional_id=X&date_from&date_to` (count), Receita/Comissão via `GET /commissions?professional_id=X&period_start&period_end` — aceito como N+1 trade-off no v1 (~5 profissionais por studio); considerar endpoint agregado `GET /professionals/performance` no v2

---

### 11.6 DashboardSettingsPage — `/dashboard/settings`
Auth: `owner`
Endpoints: `GET /studios/me` (§3), `PATCH /studios/me` (§3), `GET/POST/DELETE /studios/me/photos` (§3)
DS: Input, Button Primary, Card, Sidebar Navigation

```
┌────────────┬─────────────────────────────────────────────────┐
│            │  Configurações do Estúdio                        │
│  Sidebar   │─────────────────────────────────────────────────│
│            │                                                 │
│  ...       │  [Geral] [Serviços] [Categorias] [Assinatura]  │
│  Config.●  │                                                 │
│  ...       │  ── Tab Geral ──                                │
│            │                                                 │
│            │  ┌───────────────────┬─────────────────────────┐│
│            │  │ [logo]            │ Nome                    ││
│            │  │ Trocar logo   (S) │ ┌─────────────────────┐ ││
│            │  │                   │ │ Studio da Maria      │ ││
│            │  │                   │ └─────────────────────┘ ││
│            │  │                   │ URL pública              ││
│            │  │                   │ ┌──────┬──────────────┐ ││
│            │  │                   │ │oriz/ │studio-maria  │ ││
│            │  │                   │ └──────┴──────────────┘ ││
│            │  └───────────────────┴─────────────────────────┘│
│            │                                                 │
│            │  Telefone              Endereço                 │
│            │  ┌──────────────────┐  ┌──────────────────────┐│
│            │  │(79) 99999-0000   │  │Rua A, 123, Aracaju  ││
│            │  └──────────────────┘  └──────────────────────┘│
│            │                                                 │
│            │  Configurações                                  │
│            │  ┌─────────────────────────────────────────────┐│
│            │  │ Lembrete         [12] horas antes           ││
│            │  │ Booking público  [ativo]                    ││
│            │  │ Moeda padrão     [BRL ▼]                    ││
│            │  └─────────────────────────────────────────────┘│
│            │                                                 │
│            │  Fotos do estúdio                                │
│            │  ┌────┐┌────┐┌────┐┌────┐ [+]                  │
│            │  │ 📷 ││ 📷 ││ 📷 ││ 📷 │                      │
│            │  └────┘└────┘└────┘└────┘                      │
│            │                                                 │
│            │  [ Salvar alterações ]                      (P) │
└────────────┴─────────────────────────────────────────────────┘
```

Ações:
- P: "Salvar alterações" → `PATCH /studios/me`
- S: Trocar logo → upload
- N: Tabs Geral/Serviços/Categorias/Assinatura → alterna conteúdo (Serviços reutiliza layout de 6.4, Categorias reutiliza §4 CRUD inline, Assinatura reutiliza layout de 10.2 — todos adaptados para largura desktop)
- N: [+] fotos → `POST /studios/me/photos`

Estados:
- L: skeleton no formulário
- D: formulário preenchido
- E: inline errors (409 SLUG_TAKEN)

---

### 11.7 DashboardCampaignsPage — `/dashboard/campaigns`
Auth: `owner`
Endpoints: `GET /campaigns` (§13), `GET /campaigns/:id/metrics` (§13)
DS: Card, Table, Status Badge, Sidebar Navigation

```
┌────────────┬─────────────────────────────────────────────────┐
│            │  Campanhas              [+ Nova campanha]   (P) │
│  Sidebar   │─────────────────────────────────────────────────│
│            │                                                 │
│  ...       │  ┌──────────┬──────────┬──────────┬───────────┐│
│  Campaign● │  │Campanha  │ Tipo     │ Enviadas │ Retorno   ││
│  ...       │  ├──────────┼──────────┼──────────┼───────────┤│
│            │  │Aniversário│birthday │ 150      │ 8%        ││
│            │  │Reativação │reactivat│ 89       │ 12%       ││
│            │  │Black Friday│custom  │ 0        │ -         ││
│            │  └──────────┴──────────┴──────────┴───────────┘│
│            │                                                 │
│            │  ── Detalhes: Aniversário ──                    │
│            │                                                 │
│            │  ┌──────────┐ ┌──────────┐ ┌──────────────────┐│
│            │  │ 150      │ │ 142      │ │ 12 retornos      ││
│            │  │ Enviadas │ │ Entregues│ │ Taxa: 8%         ││
│            │  └──────────┘ └──────────┘ └──────────────────┘│
│            │                                                 │
│            │  Mensagem: "Feliz aniversário, {nome}! ..."    │
│            │  Canal: WhatsApp · Desconto: 10% · ■ Ativa     │
│            │                                                 │
│            │  [Editar] (S)     [Excluir] (Danger)            │
└────────────┴─────────────────────────────────────────────────┘
```

Ações:
- P: [+ Nova campanha] → modal ou página de criação
- N: Tap na linha da tabela → expande detalhes abaixo (master-detail)
- S: [Editar] → modal de edição
- Danger: [Excluir] → confirmação → `DELETE /campaigns/:id`

Estados:
- V: "Nenhuma campanha criada" + botão criar + explicação de tipos
- L: skeleton na tabela
- D: tabela + painel de detalhes
- E: toast + retry

---

### Sidebar Navigation (Dashboard Web)

```
┌────────────────┐
│  [logo] Oriz   │
│  Studio da Maria│
│────────────────│
│  Overview      │
│  Agenda        │
│  Clientes      │
│  Financeiro    │
│  Equipe        │
│  Serviços      │
│  Pacotes       │
│────────────────│
│  IA            │
│  Campanhas     │
│  Billing       │
│────────────────│
│  Auditoria     │
│  Configurações │
│────────────────│
│  Sair          │
└────────────────┘
```

- Ativo: --brand-primary com bg --brand-accent-soft
- Inativo: --neutral-600
- Hover: bg --neutral-100
- Width fixa: 240px
- Collapse para ícones em < 1200px viewport

---

## Telas Auxiliares

### BlockedSlotsScreen — `/settings/blocked-slots`
Auth: `professional`
Endpoints: `GET /blocked-slots` (§8), `POST /blocked-slots` (§8), `DELETE /blocked-slots/:id` (§8)
DS: Card, FAB, date picker, Top Bar (back)

```
┌──────────────────────────────────┐
│ ←  Horários bloqueados       [+] │
│──────────────────────────────────│
│                                  │
│  13/03/2026                      │
│  ┌──────────────────────────────┐│
│  │ 12:00 - 13:00   Almoço  [×]││
│  ├──────────────────────────────┤│
│  │ 17:00 - 18:00   Reunião [×] ││
│  └──────────────────────────────┘│
│                                  │
│  15/03 - 20/03                   │
│  ┌──────────────────────────────┐│
│  │ Dia inteiro      Férias  [×] ││
│  └──────────────────────────────┘│
│                                  │
└──────────────────────────────────┘
```

Ações:
- S: [+] → bottom sheet para criar novo bloqueio (data, horário início/fim, motivo)
- N: [×] → confirmação → `DELETE /blocked-slots/:id`

Estados:
- V: "Nenhum horário bloqueado" + "Bloquear horário"
- L: skeleton na lista
- D: lista agrupada por data
- E: toast + pull-to-refresh

---

### AuditLogScreen — `/settings/audit`
Auth: `owner`
Endpoints: `GET /audit-logs` (§15)
DS: Card, filtro chips, Top Bar (back)

```
┌──────────────────────────────────┐
│ ←  Logs de auditoria             │
│──────────────────────────────────│
│  [Todos] [View] [Export] [Delete]│
│                                  │
│  ┌──────────────────────────────┐│
│  │ Maria visualizou cliente     ││
│  │ Ana Costa · 13/03 14:32      ││
│  ├──────────────────────────────┤│
│  │ Maria exportou clientes      ││
│  │ 13/03 10:15                  ││
│  └──────────────────────────────┘│
│                                  │
│  [ Carregar mais ]               │
│                                  │
└──────────────────────────────────┘
```

Ações:
- N: Filtro por tipo de ação (chips)
- N: Pull-to-refresh
- N: "Carregar mais" → próxima página via cursor

Estados:
- V: "Nenhuma atividade registrada"
- L: skeleton na lista
- D: lista com filtros + paginação cursor-based
- E: toast + pull-to-refresh

---

### PackagesManagementScreen — `/settings/packages`
Auth: `owner`
Endpoints: `GET /packages` (§9), `POST /packages` (§9), `PATCH /packages/:id` (§9), `DELETE /packages/:id` (§9)
DS: Card, FAB, Top Bar (back)

```
┌──────────────────────────────────┐
│ ←  Pacotes                   [+] │
│──────────────────────────────────│
│                                  │
│  ┌──────────────────────────────┐│
│  │ Combo Manicure 10x           ││
│  │ R$ 400,00 · 10 sessões      ││
│  │ Validade: 90 dias            ││
│  ├──────────────────────────────┤│
│  │ Cílios VIP 5x               ││
│  │ R$ 500,00 · 5 sessões       ││
│  │ Validade: 60 dias            ││
│  └──────────────────────────────┘│
│                                  │
└──────────────────────────────────┘
```

Ações:
- S: [+] → bottom sheet ou `/settings/packages/new`
- P: Tap no card → `/settings/packages/:id/edit`
- N: Swipe para excluir → confirmação → `DELETE /packages/:id`

Estados:
- V: "Nenhum pacote cadastrado" + "Criar pacote"
- L: skeleton nos cards
- D: lista de pacotes
- E: toast (409 PACKAGE_HAS_SUBSCRIPTIONS ao excluir)

---

## Regra dos 3 Toques — Validação

| Fluxo | Toques | Status |
|-------|--------|--------|
| Agendar (app) | 3 (cliente → serviço → horário+confirmar) | OK |
| Agendar (público) | 4 (serviço → profissional → horário → dados+confirmar) | OK* |
| Confirmar agendamento | 2 (tap no card → botão confirmar) | OK |
| Cancelar agendamento | 2 (tap no card → confirmar cancelamento) | OK |
| Completar agendamento | 2 (tap no card → preencher pagamento + confirmar) | OK |
| Ver agenda do dia | 1 (tela inicial) | OK |
| Ver ficha do cliente | 2 (tab Clientes → tap no cliente) | OK |

\* Público tem 4 etapas mas o 4º é inserção de dados obrigatórios (nome/telefone). Não há como reduzir sem comprometer segurança.

---

## Checklist de Validação

- [x] Toda feature do roadmap tem tela correspondente
- [x] Toda tela consome endpoints que existem no API_CONTRACTS.md
- [x] Nenhum campo na tela que não existe na API
- [x] Componentes reusados do DESIGN_SYSTEM.md
- [x] 4 estados definidos para cada tela (V, L, D, E)
- [x] Regra dos 3 toques respeitada nos fluxos críticos
- [x] Empty states com ação sugerida (nunca tela em branco)
- [x] Acessibilidade: contraste, touch targets 44dp, labels

---

## Cruzamento com Fontes

### Features → Telas

| Requirement | Tela(s) |
|-------------|---------|
| AUTH-01/02/03 | LoginScreen, SignupScreen |
| AUTH-04 | SplashScreen (token check) |
| AUTH-05 | OnboardingWizardScreen |
| SERV-01/02 | ServicesManagementScreen, OnboardingWizard step 2 |
| SERV-03/04/05 | PackagesManagementScreen, ClientDetailScreen (tab Pacotes) |
| SCHD-01 | AgendaDayScreen, AgendaWeekScreen, DashboardAgendaPage |
| SCHD-02 | ConfirmAppointmentScreen (erro 409) |
| SCHD-03 | BlockedSlotsScreen |
| SCHD-04 | AppointmentDetailScreen (botões de status) |
| SCHD-05 | ProfessionalFormScreen (working_hours), OnboardingWizard step 3 |
| CLNT-01 | ClientFormScreen |
| CLNT-02 | ClientFormScreen (validação phone) |
| CLNT-03 | AnamnesisFormScreen |
| CLNT-04 | ClientDetailScreen (tab Histórico) |
| CLNT-05 | ClientFormScreen (campo notas), ClientDetailScreen |
| CLNT-06 | ClientFormScreen (tags), ClientListScreen (filtro tags) |
| TEAM-01/02 | TeamManagementScreen, ProfessionalFormScreen |
| TEAM-03/04/05 | ProfessionalFormScreen (commission, card_fee_policy) |
| FINC-01/02/03/04 | FinancialDashboardScreen, DashboardFinancialPage |
| FINC-05 | CompleteAppointmentSheet |
| PAGE-01 | PublicStudioPage |
| PAGE-02 | PublicSelectServicePage |
| PAGE-03 | PublicSelectProfessionalPage |
| PAGE-04 | PublicConfirmBookingPage |
| PUSH-01/02 | (backend-driven, sem tela dedicada — notificação OS) |
| WHAI-01/02/03 | ConversationDetailScreen (IA gerencia) |
| WHAI-04 | ConversationListScreen (filtro escaladas), ConversationDetailScreen |
| WHAI-05 | AIConfigScreen |
| WHAI-06 | (backend-driven via WhatsApp, sem tela) |
| MKTG-01/02/03 | CampaignListScreen, CampaignFormScreen, CampaignDetailScreen, DashboardCampaignsPage |
| LGPD-01 | AuditLogScreen |
| LGPD-02 | ClientFormScreen (consent checkboxes), PublicConfirmBookingPage |
| BILL-01 | PlansScreen |
| BILL-02 | MoreScreen (visibilidade condicional por plano) |
| BILL-03 | InvoicesScreen |
| BILL-04 | SubscriptionScreen, PlansScreen |

### Endpoints não usados em telas (backend-only)

| Endpoint | Motivo |
|----------|--------|
| POST /auth/logout | Ação no menu "Sair", sem tela dedicada |
| POST /auth/refresh | Automático pelo SDK |
| POST /device-tokens, DELETE /device-tokens/:id | Automático pelo app (FCM) |
| POST /webhooks/whatsapp | Recebido pelo backend |
| POST /webhooks/billing | Recebido pelo backend |
| POST /clients/:clientId/data-deletion | Ação dentro de ClientDeleteConfirmation |

### Componentes do DESIGN_SYSTEM.md usados

| Componente | Telas que usam |
|------------|---------------|
| Button Primary | Todas (1 por tela) |
| Button Secondary | Login, Appointment Detail, Commissions |
| Button Danger | Client Delete, Campaign Delete |
| Button Ghost | Login (links), Onboarding (pular) |
| Card | Todas as listas |
| Appointment Card | Agenda Day/Week, Client History |
| Input | Todos os formulários |
| Empty State | Todas as listas |
| Status Badge | Agenda, Appointments, Commissions, Invoices |
| Bottom Tab Bar | Agenda, Clientes, Financeiro, Mais |
| Top Bar | Todas exceto Splash |
| Skeleton | Todas as telas com dados remotos |
| Toast | Todas as ações de escrita |
| Bottom Sheet | Complete Appointment, Delete Client, filtros |
| Sidebar Navigation | Dashboard Web (todas as páginas) |
| Table (web) | DashboardClients, DashboardFinancial, DashboardTeam, DashboardCampaigns |

---

*Gerado: 2026-03-13*
*Fontes: API_CONTRACTS.md, DOMAIN_MODEL.md, DESIGN_SYSTEM.md, ROADMAP.md, REQUIREMENTS.md*
