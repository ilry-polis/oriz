Gere prompts otimizados para o Figma Make para as telas do Oriz.

## Sources of Truth
- docs/DESIGN_SYSTEM.md — tokens, componentes, padrões visuais
- docs/SCREENS.md — mapa de telas com layout, ações, estados

## Instruções

Para cada tela solicitada, gere UM prompt completo para o Figma Make contendo:

### 1. Contexto do App
```
App: Oriz — agenda inteligente para profissionais de beleza.
Plataforma: [Mobile iOS/Android | Web Desktop]
Estilo: Clean, minimalista, flat design. Sem sombras, sem gradientes.
Referências visuais: Cal.com, Linear, Notion.
```

### 2. Tokens (sempre incluir)
```
Cores:
- Primary: #1A1A2E (textos, headers, botão primário)
- Accent: #E8C547 (CTAs, destaques, badges)
- Background: #FAFAFA
- Card background: #F5F5F5
- Borders: #E5E5E5
- Text primary: #171717
- Text secondary: #525252
- Placeholder: #A3A3A3
- Success: #22C55E
- Warning: #F59E0B
- Error: #EF4444
- Info: #3B82F6

Tipografia:
- Font: Inter
- Display: 28px bold
- Title: 20px semibold
- Body: 16px regular
- Caption: 13px regular
- Micro: 11px medium

Espaçamento:
- XS: 4px, SM: 8px, MD: 16px, LG: 24px, XL: 32px, 2XL: 48px

Border radius:
- SM: 6px (badges), MD: 12px (cards, inputs, botões), LG: 16px (modais), Full: 999px (avatares)
```

### 3. Especificação da Tela
Para cada tela, incluir:
- Nome e propósito (1 frase)
- Layout descrito em linguagem visual (não código)
- Hierarquia: ação primária, secundárias, navegação
- Componentes específicos com medidas (altura de input: 48px, botão: 48px, touch target: 44x44)
- Conteúdo real em português (nunca lorem ipsum)
- Estado sendo gerado (com dados, vazio, loading, ou erro)

### 4. Regras Visuais (sempre incluir no prompt)
```
Regras obrigatórias:
- Fundo #FAFAFA, sem gradientes, sem sombras
- Cards com background #F5F5F5, borda 1px #E5E5E5, radius 12px
- Inputs com altura 48px, background #F5F5F5, borda 1px #E5E5E5
- Botão primário: background #1A1A2E, texto branco, altura 48px, radius 12px
- Máximo 1 botão primário por tela
- Status badges: radius 999px, background com 15% da cor, texto na cor full
- Bottom tab bar: 4 tabs (Agenda, Clientes, Financeiro, Mais), altura 56px
- Top bar: sem elevação, background #FAFAFA
- Muito espaço em branco — a informação respira
- Touch targets mínimo 44x44px
- Contraste mínimo 4.5:1
```

### 5. Estados Adicionais
Se solicitado, gerar variantes:
- **Estado vazio**: ícone outline 48px em #A3A3A3, título, subtítulo com ação sugerida, botão primário
- **Estado loading**: skeleton shimmer com blocos em #E5E5E5 refletindo o layout real
- **Estado erro**: toast vermelho ou mensagem inline com retry

## Formato de Saída

Para cada tela, entregar o prompt formatado assim:

```
=== [NOME DA TELA] ===

Design a mobile app screen for "Oriz", a beauty salon scheduling app.

[contexto + tokens + especificação + regras]

Important:
- Use real Portuguese content, never lorem ipsum
- Clean, minimal aesthetic — Cal.com / Linear as reference
- Flat design: no shadows, no gradients
- Generous whitespace
- Single primary action button per screen
```

## Agrupamento

Se o usuário pedir por Phase, agrupar as telas conforme o roadmap:
- Phase 1: LoginScreen, OnboardingWizard (3 steps), OnboardingComplete, AgendaDayScreen
- Phase 2: ClientListScreen, ClientDetailScreen, ClientFormScreen, SelectClientScreen, SelectServiceScreen, SelectSlotScreen, ConfirmAppointmentScreen
- Phase 3: TeamManagementScreen, ProfessionalFormScreen, ServicesManagementScreen
- E assim por diante conforme SCREENS.md

## Regras
- Um prompt por tela — não misturar telas no mesmo prompt
- Sempre incluir tokens e regras visuais (Figma Make precisa de contexto completo por prompt)
- Usar conteúdo realista em português (nomes brasileiros, valores em R$, datas no formato DD/MM)
- Especificar dimensão do frame: 390x844 (iPhone 14) para mobile, 1440x900 para web
- Se a tela tem bottom tab bar, incluir no prompt
- Se a tela é "com dados", usar 3-5 itens de exemplo na lista
