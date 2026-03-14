# Oriz — Design System

## Filosofia
Oriz é ferramenta de trabalho, não rede social. O profissional usa entre um cliente e outro, em pé, com as mãos ocupadas. Cada pixel deve servir a uma ação. Se não serve, remove.

**Três palavras:** limpo, rápido, confiável.

## Princípios

### 1. Silêncio Visual
- Fundo limpo, poucos elementos, sem decoração
- A informação é o design — não precisa de enfeite
- Ícones só quando o significado não é óbvio pelo texto
- Sem gradientes, sombras pesadas ou animações desnecessárias

### 2. Hierarquia Brutal
- Uma ação primária por tela — grande, óbvia, acessível com o polegar
- Secundárias discretas — presentes mas não competem
- Informação organizada por prioridade: o que o profissional precisa AGORA no topo

### 3. Velocidade é Feature
- Regra dos 3 toques: qualquer ação crítica em no máximo 3 interações
- Skeleton loading em vez de spinners (percepção de velocidade)
- Transições sutis (200ms) — nunca animações que atrasam o usuário
- Cache agressivo: agenda do dia disponível offline

### 4. Confiança
- Feedback imediato em toda ação (haptic + visual)
- Ações destrutivas pedem confirmação com texto explícito
- Estados claros: o usuário sempre sabe o que aconteceu, o que está acontecendo, e o que pode fazer

---

## Tokens de Design

### Cores

#### Palette Core
| Token | Valor | Uso |
|-------|-------|-----|
| --brand-primary | #1A1A2E | Textos principais, headers, ação primária |
| --brand-accent | #E8C547 | CTAs, destaques, badges ativos |
| --brand-accent-soft | #E8C547/15% | Background de badges, highlights sutis |

#### Neutrals
| Token | Valor | Uso |
|-------|-------|-----|
| --neutral-50 | #FAFAFA | Background principal |
| --neutral-100 | #F5F5F5 | Background de cards, inputs |
| --neutral-200 | #E5E5E5 | Bordas, divisores |
| --neutral-400 | #A3A3A3 | Texto placeholder, ícones inativos |
| --neutral-600 | #525252 | Texto secundário |
| --neutral-900 | #171717 | Texto principal |

#### Semantic
| Token | Valor | Uso |
|-------|-------|-----|
| --success | #22C55E | Confirmado, concluído, pago |
| --warning | #F59E0B | Pendente, atenção |
| --error | #EF4444 | Cancelado, erro, obrigatório |
| --info | #3B82F6 | Informativo, link |

### Tipografia

| Token | Peso | Tamanho | Uso |
|-------|------|---------|-----|
| --text-display | 700 | 28px | Título de seção principal (1 por tela) |
| --text-title | 600 | 20px | Títulos de card, nome do profissional |
| --text-body | 400 | 16px | Texto corrido, descrições |
| --text-caption | 400 | 13px | Horários, meta info, labels |
| --text-micro | 500 | 11px | Badges, tags, counters |

- Font family: Inter (clean, legível em tamanhos pequenos, suporte amplo)
- Fallback: SF Pro (iOS), Roboto (Android), system-ui
- Line height: 1.4 para body, 1.2 para titles

### Espaçamento

| Token | Valor | Uso |
|-------|-------|-----|
| --space-xs | 4px | Padding interno de badges |
| --space-sm | 8px | Gap entre elementos inline |
| --space-md | 16px | Padding de cards, gap entre itens de lista |
| --space-lg | 24px | Margin entre seções |
| --space-xl | 32px | Margin entre blocos principais |
| --space-2xl | 48px | Top padding de telas |

### Raios de Borda

| Token | Valor | Uso |
|-------|-------|-----|
| --radius-sm | 6px | Badges, tags |
| --radius-md | 12px | Cards, inputs, botões |
| --radius-lg | 16px | Modais, bottom sheets |
| --radius-full | 999px | Avatares, pills |

---

## Componentes Base

### Botões

**Primary** — ação principal da tela
- Background: --brand-primary
- Text: white, --text-body, weight 600
- Height: 48px, padding horizontal 24px
- Radius: --radius-md
- Estado pressed: opacity 0.8 + haptic light
- Estado disabled: opacity 0.4, sem interação
- Máximo 1 por tela

**Secondary** — ações complementares
- Background: transparent
- Border: 1px --neutral-200
- Text: --neutral-900, --text-body, weight 500
- Height: 44px
- Radius: --radius-md

**Danger** — ações destrutivas
- Background: --error
- Text: white
- Sempre com confirmação antes de executar

**Ghost** — ações terciárias
- Background: transparent, sem borda
- Text: --neutral-600, --text-caption
- Underline on hover/press

### Cards

- Background: --neutral-100
- Border: 1px --neutral-200
- Radius: --radius-md
- Padding: --space-md
- Sem sombra (flat design, não material)
- Hover/press: border muda para --neutral-400

**Appointment Card** (componente mais usado)
```
┌──────────────────────────────────┐
│ 10:00  Maria Silva         [•••] │
│ Manicure + Pedicure    45min     │
│ ■ Confirmado                     │
└──────────────────────────────────┘
```
- Horário: --text-body weight 600
- Nome: --text-body
- Serviço: --text-caption, --neutral-600
- Status: badge com cor semântica

### Inputs

- Height: 48px
- Background: --neutral-100
- Border: 1px --neutral-200, focus: --brand-primary
- Radius: --radius-md
- Label: acima do input, --text-caption, --neutral-600
- Erro: border --error, mensagem abaixo em --error --text-caption
- Placeholder: --neutral-400

### Empty States

Toda lista vazia mostra:
- Ícone sutil (outline, --neutral-400, 48px)
- Título curto explicando o estado (--text-title)
- Subtítulo com ação sugerida (--text-body, --neutral-600)
- Botão primário para resolver (ex: "Agendar primeiro horário")

```
┌──────────────────────────────────┐
│                                  │
│         [ícone calendário]       │
│                                  │
│     Nenhum agendamento hoje      │
│   Que tal agendar o primeiro?    │
│                                  │
│     [ Novo Agendamento ]         │
│                                  │
└──────────────────────────────────┘
```

### Status Badges

| Status | Cor | Label |
|--------|-----|-------|
| pending | --warning bg, --warning text | Pendente |
| confirmed | --info bg, --info text | Confirmado |
| completed | --success bg, --success text | Concluído |
| cancelled | --error bg, --error text | Cancelado |
| no_show | --neutral-400 bg, --neutral-600 text | Não compareceu |

- Background com 15% opacity da cor
- Text com cor full
- Radius: --radius-full
- Padding: --space-xs horizontal, 2px vertical
- Font: --text-micro

### Navigation

**Bottom Tab Bar** (Mobile)
- 4 tabs máximo: Agenda, Clientes, Financeiro, Mais
- Ícone + label
- Ativo: --brand-primary
- Inativo: --neutral-400
- Height: 56px + safe area

**Top Bar**
- Título da tela: --text-title
- Back button quando necessário
- Action buttons à direita (máx 2)
- Background: --neutral-50
- Sem elevação (flat)

---

## Padrões de Interação

### Loading
- Skeleton shimmer em vez de spinner para listas e cards
- Spinner sutil (--brand-accent, 24px) só para ações pontuais (salvar, enviar)
- Nunca bloquear tela inteira — loading inline no componente que está carregando

### Feedback
- Toast para confirmações: "Agendamento criado" (auto-dismiss 3s, deslizar para fechar)
- Toast de erro: persiste até fechar manualmente
- Haptic: light para tap, medium para ação concluída, heavy para delete

### Pull to Refresh
- Em toda tela de lista
- Indicador sutil no topo
- Atualiza dados do servidor

### Swipe Actions (em listas)
- Swipe direita: ação primária (confirmar, concluir) — --success
- Swipe esquerda: ação secundária (cancelar, editar) — --warning ou --error
- Threshold: 40% da largura do card

### Confirmação de Ações Destrutivas
- Bottom sheet com texto explícito: "Cancelar agendamento de Maria Silva às 10:00?"
- Botão de confirmação em --error
- Botão de voltar discreto

---

## Responsividade

### Mobile (< 768px) — produto principal
- Layout single column
- Cards full width com padding lateral --space-md
- Bottom tab navigation
- Touch targets mínimo 44x44dp

### Tablet (768px - 1024px)
- Agenda em split view: lista à esquerda, detalhes à direita
- Cards em grid 2 colunas

### Dashboard Web (> 1024px)
- Sidebar navigation à esquerda
- Content area com max-width 1200px
- Cards em grid 3-4 colunas
- Tabelas com sorting e filtros inline

---

## Acessibilidade

- Contraste texto: mínimo 4.5:1 (WCAG AA)
- Contraste elementos UI: mínimo 3:1
- Touch targets: mínimo 44x44dp
- Font scaling: layout não quebra até 200%
- Labels em todos os inputs e botões de ícone
- Focus visible para navegação por teclado (dashboard)
- Reduzir motion: respeitar prefers-reduced-motion

---

## Padrões Flutter (Obrigatórios)

### Animações

Toda transição de tela e mudança de estado deve ser animada. Animações comunicam continuidade e dão sensação de polish.

**Transições de Tela**
- Navegação forward: slide da direita para esquerda (300ms, Curves.easeInOut)
- Navegação back: slide da esquerda para direita (250ms, Curves.easeInOut)
- Modais e bottom sheets: slide de baixo para cima (300ms, Curves.easeOutCubic)
- Fade entre tabs: 200ms, Curves.easeIn

**Mudanças de Estado**
- Aparecer (item novo em lista): fadeIn + slideUp sutil (200ms)
- Desaparecer (item removido): fadeOut + slideDown (150ms)
- Mudança de status (badge): AnimatedSwitcher com fade (200ms)
- Expansão/colapso: AnimatedContainer (250ms, Curves.easeInOut)
- Contador mudando: AnimatedSwitcher com slideUp do número novo

**Micro-interações**
- Botão pressed: scale 0.96 (100ms) + haptic light
- Card tap: scale 0.98 (80ms)
- Toggle/switch: AnimatedAlign (200ms, Curves.easeInOut)
- Checkbox: scale bounce (150ms)
- FAB appear: scale + fade de 0 para 1 (300ms, Curves.elasticOut)

**Regras de Animação**
- Duração máxima: 300ms para UI, 500ms para onboarding/celebração
- Respeitar AccessibilityFeatures.reduceMotion — desabilitar animações decorativas
- Curves: nunca linear para UI (usar easeInOut, easeOutCubic)
- Staggered animations em listas: delay de 50ms entre itens, máximo 8 itens animados
- AnimatedList para inserção/remoção em listas dinâmicas

**Implementação Padrão**
```dart
// Implicitly animated widgets como base
AnimatedSwitcher(duration: Duration(milliseconds: 200))
AnimatedContainer(duration: Duration(milliseconds: 250), curve: Curves.easeInOut)
AnimatedOpacity(duration: Duration(milliseconds: 200))

// Para listas com insert/remove
AnimatedList + SlideTransition + FadeTransition

// Para page transitions customizadas
PageRouteBuilder com SlideTransition (300ms, Curves.easeInOut)
```

### Skeleton Loading

Nunca spinner fullscreen. Skeleton shimmer é o padrão em toda tela que carrega dados.

**Princípios**
- Skeleton reflete o layout real da tela — mesma quantidade de cards, mesma posição dos elementos
- Shimmer direction: esquerda para direita, gradiente de --neutral-200 para --neutral-100 e volta
- Duração do shimmer: 1.5s por ciclo, loop infinito até dados chegarem
- Transição skeleton → dados: fadeIn dos dados reais (200ms)

**Componentes Skeleton**
```
Skeleton de Card:
┌──────────────────────────────────┐
│ ████  ██████████████       ████  │
│ ████████████████    ██████       │
│ ██████                           │
└──────────────────────────────────┘

Skeleton de Lista:
┌──────────────────────────────────┐
│ ████  ██████████████       ████  │
└──────────────────────────────────┘
┌──────────────────────────────────┐
│ ████  ██████████████       ████  │
└──────────────────────────────────┘
┌──────────────────────────────────┐
│ ████  ██████████████       ████  │
└──────────────────────────────────┘

Skeleton de Avatar + Nome:
  ⬤  ████████████
```

**Quando usar cada padrão**
| Situação | Loading Pattern |
|----------|----------------|
| Primeira carga de tela | Skeleton shimmer (layout completo) |
| Pull to refresh | Indicador no topo + dados antigos visíveis |
| Load more (infinite scroll) | Skeleton de 2-3 itens no final da lista |
| Ação pontual (salvar, enviar) | Botão com loading state (spinner inline 20px) |
| Navegação entre tabs | Skeleton se dados não cacheados, dados direto se cacheados |

**Implementação Padrão**
```dart
// Package: shimmer 3.x
Shimmer.fromColors(
  baseColor: Color(0xFFE5E5E5),   // --neutral-200
  highlightColor: Color(0xFFF5F5F5), // --neutral-100
  child: SkeletonLayout(),
)

// Cada domínio tem seu skeleton widget
AppointmentCardSkeleton()
ClientListItemSkeleton()
FinancialSummarySkeleton()
```

### Infinite Scroll

Paginação infinita é o padrão em toda lista. Nunca botão "carregar mais", nunca paginação numérica no mobile.

**Comportamento**
- Carregar próxima página quando scroll atingir 80% da lista (prefetch threshold)
- Mostrar 2-3 skeleton items no final enquanto carrega
- Se erro no carregamento: mostrar card de retry inline ("Erro ao carregar. Tentar novamente")
- Se fim da lista: mostrar indicador sutil ("Todos os resultados carregados") e parar de requisitar
- Primeira carga: skeleton full screen
- Cargas subsequentes: skeleton apenas nos novos itens

**Parâmetros Padrão**
- per_page: 20 (conforme API_CONTRACTS.md)
- Prefetch threshold: 80% do scroll (ou 5 itens antes do final)
- Retry automático: 1x após falha, depois manual
- Cache: manter itens já carregados no state (não recarregar do zero no back)

**Implementação Padrão**
```dart
// ScrollController com listener
scrollController.addListener(() {
  if (scrollController.position.pixels >= 
      scrollController.position.maxScrollExtent * 0.8) {
    loadNextPage();
  }
});

// State management (Riverpod)
// AsyncNotifier gerencia: items[], page, hasMore, isLoadingMore
// loadNextPage() incrementa page, appenda items, seta hasMore = false quando acabar

// ListView.builder com itemCount = items.length + (hasMore ? 3 : 1)
// Últimos itens: skeleton se hasMore, "fim da lista" se !hasMore
```

**Pull to Refresh + Infinite Scroll (combo)**
- Pull to refresh: reseta para page 1, substitui lista inteira
- Infinite scroll: incrementa page, appenda no final
- Ambos coexistem na mesma tela
- RefreshIndicator wrapping ListView.builder

---

## Anti-padrões (NUNCA fazer)

- Modais sobre modais
- Mais de 1 botão primário por tela
- Tela em branco sem empty state
- Animações > 300ms
- Sombras pesadas ou gradientes
- Texto sobre imagem sem overlay
- Scroll horizontal em listas
- Ações destrutivas sem confirmação
- Ícones sem label acessível
- Cores como único indicador de estado (adicionar texto/ícone)
- Spinner fullscreen em vez de skeleton shimmer
- Lista com botão "carregar mais" ou paginação numérica no mobile
- Animação linear (sempre usar curves)
- Animação > 300ms em interações de UI
- Recarregar lista inteira ao voltar de tela de detalhe (manter state)
- Scroll sem prefetch (carregar só quando chega no final)
- Loading que esconde dados já disponíveis
