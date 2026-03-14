# Figma Make Prompts — Phase 1

> Gerado a partir de docs/SCREENS.md + docs/DESIGN_SYSTEM.md
> Um prompt por tela. Copie cada bloco inteiro para o Figma Make.

---

## 1. LoginScreen

```
=== LoginScreen ===

Design a mobile app screen for "Oriz", a beauty salon scheduling app.
Frame: 390x844 (iPhone 14).

Context:
- App: Oriz — agenda inteligente para profissionais de beleza
- Platform: Mobile iOS/Android
- Style: Clean, minimalist, flat design. No shadows, no gradients.
- Visual references: Cal.com, Linear, Notion

Color tokens:
- Primary: #1A1A2E (texts, headers, primary button)
- Accent: #E8C547 (CTAs, highlights, badges)
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

Typography (font: Inter):
- Display: 28px bold
- Title: 20px semibold
- Body: 16px regular
- Caption: 13px regular
- Micro: 11px medium

Spacing: XS 4px, SM 8px, MD 16px, LG 24px, XL 32px, 2XL 48px
Border radius: SM 6px, MD 12px, LG 16px, Full 999px

Screen: LoginScreen — tela de autenticação do app.

Layout (top to bottom):
1. Top area (vertically centered in upper half):
   - Logo "Oriz" centered, using the primary color #1A1A2E, display size (28px bold)
   - 32px spacing below logo

2. Form area:
   - Label "Email" in caption size (13px), color #525252, above input
   - Email input: full width, height 48px, background #F5F5F5, border 1px #E5E5E5, radius 12px, placeholder "seu@email.com" in #A3A3A3
   - 16px gap
   - Label "Senha" in caption size (13px), color #525252, above input
   - Password input: same styling as email, placeholder "••••••••", with eye icon toggle on right side
   - 24px gap

3. Primary action:
   - Button "Entrar": full width, height 48px, background #1A1A2E, text white 16px semibold, radius 12px
   - 24px gap

4. Divider:
   - Horizontal line with text "ou" centered, line color #E5E5E5, text #A3A3A3 caption size
   - 24px gap

5. Social login buttons:
   - Button "Entrar com Google": full width, height 44px, background transparent, border 1px #E5E5E5, radius 12px, Google icon on left, text #171717 16px medium
   - 12px gap
   - Button "Entrar com Apple": same styling, Apple icon on left, text "Entrar com Apple"
   - 32px gap

6. Bottom links (centered, inline):
   - "Criar conta" in #525252 caption size (13px), underlined
   - 24px horizontal gap
   - "Esqueci minha senha" in #525252 caption size (13px), underlined

State: Default (form ready, no errors, no loading)

Mandatory rules:
- Background #FAFAFA, no gradients, no shadows
- Inputs height 48px, background #F5F5F5, border 1px #E5E5E5
- Primary button: background #1A1A2E, white text, height 48px, radius 12px
- Maximum 1 primary button per screen
- Touch targets minimum 44x44px
- Contrast minimum 4.5:1
- Generous whitespace — content breathes
- No bottom tab bar on this screen (pre-auth)

Important:
- Use real Portuguese content, never lorem ipsum
- Clean, minimal aesthetic — Cal.com / Linear as reference
- Flat design: no shadows, no gradients
- Generous whitespace
- Single primary action button per screen
```

---

## 2. OnboardingWizard — Step 1: Dados do Estúdio

```
=== OnboardingWizard — Step 1: Dados do Estúdio ===

Design a mobile app screen for "Oriz", a beauty salon scheduling app.
Frame: 390x844 (iPhone 14).

Context:
- App: Oriz — agenda inteligente para profissionais de beleza
- Platform: Mobile iOS/Android
- Style: Clean, minimalist, flat design. No shadows, no gradients.
- Visual references: Cal.com, Linear, Notion

Color tokens:
- Primary: #1A1A2E
- Accent: #E8C547
- Background: #FAFAFA
- Card background: #F5F5F5
- Borders: #E5E5E5
- Text primary: #171717
- Text secondary: #525252
- Placeholder: #A3A3A3

Typography (font: Inter):
- Display: 28px bold
- Title: 20px semibold
- Body: 16px regular
- Caption: 13px regular
- Micro: 11px medium

Spacing: XS 4px, SM 8px, MD 16px, LG 24px, XL 32px, 2XL 48px
Border radius: SM 6px, MD 12px, LG 16px, Full 999px

Screen: OnboardingWizard Step 1 — coleta de dados básicos do estúdio de beleza.

Layout (top to bottom):
1. Top bar (fixed, no elevation):
   - Background #FAFAFA
   - Left: back arrow icon in #171717
   - Center: "Passo 1 de 3" in body size (16px regular), color #525252

2. Progress indicator:
   - 3 circles connected by lines, horizontally centered
   - Circle 1: filled with #1A1A2E (current step), 12px diameter
   - Circle 2 and 3: outline only, border 2px #E5E5E5, 12px diameter
   - Connecting lines: 40px wide, 2px height, #E5E5E5
   - 32px below top bar, 24px below progress indicator

3. Section title:
   - "Dados do estúdio" in title size (20px semibold), color #171717
   - 24px gap below

4. Form fields (scrollable area):
   - Label "Nome do estúdio" in caption (13px), color #525252
   - Input: full width, 48px height, bg #F5F5F5, border 1px #E5E5E5, radius 12px, placeholder "Ex: Studio Ana Beleza" in #A3A3A3
   - 16px gap

   - Label "URL pública" in caption (13px), color #525252
   - Input with prefix: prefix area "oriz.app/" in #A3A3A3 with bg #EBEBEB and right border, then input area for slug, placeholder "studio-ana" in #A3A3A3. Total height 48px, bg #F5F5F5, border 1px #E5E5E5, radius 12px
   - 16px gap

   - Label "Telefone" in caption (13px), color #525252
   - Input: full width, 48px height, same styling, placeholder "(79) 99999-0000" in #A3A3A3
   - 16px gap

   - Label "Endereço" in caption (13px), color #525252
   - Input: full width, 48px height, same styling, placeholder "Rua das Flores, 123 — Aracaju/SE" in #A3A3A3
   - 16px gap

   - Label "Fuso horário" in caption (13px), color #525252
   - Dropdown: full width, 48px height, bg #F5F5F5, border 1px #E5E5E5, radius 12px, showing "America/Sao_Paulo" in #171717, chevron-down icon on right in #A3A3A3

5. Bottom action (fixed at bottom, 16px padding):
   - Button "Próximo": full width, height 48px, background #1A1A2E, text white 16px semibold, radius 12px

State: Default (empty form, ready to fill)

Mandatory rules:
- Background #FAFAFA, no gradients, no shadows
- Inputs height 48px, background #F5F5F5, border 1px #E5E5E5
- Primary button: background #1A1A2E, white text, height 48px, radius 12px
- Maximum 1 primary button per screen
- Touch targets minimum 44x44px
- Contrast minimum 4.5:1
- Generous whitespace
- No bottom tab bar (onboarding flow)

Important:
- Use real Portuguese content, never lorem ipsum
- Clean, minimal aesthetic — Cal.com / Linear as reference
- Flat design: no shadows, no gradients
- Generous whitespace
- Single primary action button per screen
```

---

## 3. OnboardingWizard — Step 2: Serviços

```
=== OnboardingWizard — Step 2: Serviços ===

Design a mobile app screen for "Oriz", a beauty salon scheduling app.
Frame: 390x844 (iPhone 14).

Context:
- App: Oriz — agenda inteligente para profissionais de beleza
- Platform: Mobile iOS/Android
- Style: Clean, minimalist, flat design. No shadows, no gradients.
- Visual references: Cal.com, Linear, Notion

Color tokens:
- Primary: #1A1A2E
- Accent: #E8C547
- Background: #FAFAFA
- Card background: #F5F5F5
- Borders: #E5E5E5
- Text primary: #171717
- Text secondary: #525252
- Placeholder: #A3A3A3
- Error: #EF4444

Typography (font: Inter):
- Display: 28px bold
- Title: 20px semibold
- Body: 16px regular
- Caption: 13px regular
- Micro: 11px medium

Spacing: XS 4px, SM 8px, MD 16px, LG 24px, XL 32px, 2XL 48px
Border radius: SM 6px, MD 12px, LG 16px, Full 999px

Screen: OnboardingWizard Step 2 — cadastro dos serviços oferecidos pelo estúdio.

Layout (top to bottom):
1. Top bar (fixed, no elevation):
   - Background #FAFAFA
   - Left: back arrow icon in #171717
   - Center: "Passo 2 de 3" in body size (16px), color #525252

2. Progress indicator:
   - 3 circles connected by lines, horizontally centered
   - Circle 1: filled #1A1A2E (completed)
   - Circle 2: filled #1A1A2E (current)
   - Circle 3: outline only, border 2px #E5E5E5
   - Connecting line between 1 and 2: #1A1A2E (completed)
   - Connecting line between 2 and 3: #E5E5E5
   - 24px below progress

3. Section title:
   - "Adicione seus serviços" in title size (20px semibold), #171717
   - Subtitle: "Você pode adicionar mais depois" in caption (13px), #525252
   - 24px gap

4. Service list (scrollable, 3 example items):
   - Service card 1:
     - Background #F5F5F5, border 1px #E5E5E5, radius 12px, padding 16px
     - Row 1: "Manicure" in body (16px semibold) #171717, right-aligned "×" delete icon in #A3A3A3 (44x44 touch target)
     - Row 2: "30 min" in caption #525252, dot separator "·", "R$ 50,00" in caption #525252
   - 8px gap between cards

   - Service card 2:
     - Same styling
     - "Pedicure" — "45 min · R$ 60,00"

   - Service card 3:
     - Same styling
     - "Esmaltação em gel" — "60 min · R$ 80,00"

   - 16px gap after last card

5. Add button:
   - "+ Adicionar serviço" left-aligned, text #1A1A2E, body size (16px medium), with "+" icon. No background, no border (ghost button style). Touch target 44px height.
   - 16px gap

6. Bottom area (fixed at bottom, 16px padding):
   - Button "Próximo": full width, height 48px, background #1A1A2E, text white 16px semibold, radius 12px
   - 12px gap
   - "Pular por agora" centered, caption size (13px), color #525252, underlined

State: With data (3 services added)

Mandatory rules:
- Background #FAFAFA, no gradients, no shadows
- Cards: background #F5F5F5, border 1px #E5E5E5, radius 12px
- Primary button: background #1A1A2E, white text, height 48px, radius 12px
- Maximum 1 primary button per screen
- Touch targets minimum 44x44px
- Contrast minimum 4.5:1
- Generous whitespace
- No bottom tab bar (onboarding flow)

Important:
- Use real Portuguese content, never lorem ipsum
- Clean, minimal aesthetic — Cal.com / Linear as reference
- Flat design: no shadows, no gradients
- Generous whitespace
- Single primary action button per screen
```

---

## 4. OnboardingWizard — Step 3: Horários

```
=== OnboardingWizard — Step 3: Horários ===

Design a mobile app screen for "Oriz", a beauty salon scheduling app.
Frame: 390x844 (iPhone 14).

Context:
- App: Oriz — agenda inteligente para profissionais de beleza
- Platform: Mobile iOS/Android
- Style: Clean, minimalist, flat design. No shadows, no gradients.
- Visual references: Cal.com, Linear, Notion

Color tokens:
- Primary: #1A1A2E
- Accent: #E8C547
- Background: #FAFAFA
- Card background: #F5F5F5
- Borders: #E5E5E5
- Text primary: #171717
- Text secondary: #525252
- Placeholder: #A3A3A3
- Success: #22C55E

Typography (font: Inter):
- Display: 28px bold
- Title: 20px semibold
- Body: 16px regular
- Caption: 13px regular
- Micro: 11px medium

Spacing: XS 4px, SM 8px, MD 16px, LG 24px, XL 32px, 2XL 48px
Border radius: SM 6px, MD 12px, LG 16px, Full 999px

Screen: OnboardingWizard Step 3 — definição dos horários de funcionamento.

Layout (top to bottom):
1. Top bar (fixed, no elevation):
   - Background #FAFAFA
   - Left: back arrow icon in #171717
   - Center: "Passo 3 de 3" in body size (16px), color #525252

2. Progress indicator:
   - 3 circles all filled with #1A1A2E, connected by lines in #1A1A2E
   - 24px below progress

3. Section title:
   - "Defina seus horários" in title size (20px semibold), #171717
   - 24px gap

4. Days list (scrollable, 7 rows):
   Each row is a card-like area with 16px vertical padding, separated by 1px #E5E5E5 divider lines.

   - Row "Seg" (enabled):
     - Left: "Seg" label in body (16px semibold) #171717, width 48px
     - Center: two time inputs side by side
       - Input "08:00": width ~100px, height 40px, bg #F5F5F5, border 1px #E5E5E5, radius 12px, text centered #171717
       - Text "às" in caption #525252, centered between inputs
       - Input "18:00": same styling
     - Right: toggle switch, ON position, track color #1A1A2E, thumb white

   - Row "Ter": same as Seg, times "08:00" to "18:00", toggle ON
   - Row "Qua": same, "08:00" to "18:00", toggle ON
   - Row "Qui": same, "08:00" to "18:00", toggle ON
   - Row "Sex": same, "08:00" to "18:00", toggle ON

   - Row "Sáb" (enabled, shorter hours):
     - "Sáb" label, times "08:00" to "13:00", toggle ON

   - Row "Dom" (disabled):
     - Left: "Dom" label in body (16px) #A3A3A3 (dimmed)
     - Center: text "Fechado" in caption #A3A3A3 (no time inputs visible)
     - Right: toggle switch, OFF position, track color #E5E5E5, thumb white

5. Bottom action (fixed at bottom, 16px padding):
   - Button "Concluir": full width, height 48px, background #1A1A2E, text white 16px semibold, radius 12px

State: Default (pre-filled with typical beauty salon hours)

Mandatory rules:
- Background #FAFAFA, no gradients, no shadows
- Inputs height 40px (compact for time), background #F5F5F5, border 1px #E5E5E5
- Primary button: background #1A1A2E, white text, height 48px, radius 12px
- Maximum 1 primary button per screen
- Touch targets minimum 44x44px
- Contrast minimum 4.5:1
- Generous whitespace
- No bottom tab bar (onboarding flow)
- Toggle switches should be clean and minimal

Important:
- Use real Portuguese content, never lorem ipsum
- Clean, minimal aesthetic — Cal.com / Linear as reference
- Flat design: no shadows, no gradients
- Generous whitespace
- Single primary action button per screen
```

---

## 5. OnboardingCompleteScreen

```
=== OnboardingCompleteScreen ===

Design a mobile app screen for "Oriz", a beauty salon scheduling app.
Frame: 390x844 (iPhone 14).

Context:
- App: Oriz — agenda inteligente para profissionais de beleza
- Platform: Mobile iOS/Android
- Style: Clean, minimalist, flat design. No shadows, no gradients.
- Visual references: Cal.com, Linear, Notion

Color tokens:
- Primary: #1A1A2E
- Accent: #E8C547
- Background: #FAFAFA
- Text primary: #171717
- Text secondary: #525252
- Success: #22C55E

Typography (font: Inter):
- Display: 28px bold
- Title: 20px semibold
- Body: 16px regular
- Caption: 13px regular

Spacing: XS 4px, SM 8px, MD 16px, LG 24px, XL 32px, 2XL 48px
Border radius: SM 6px, MD 12px, LG 16px, Full 999px

Screen: OnboardingCompleteScreen — tela de celebração após completar o setup do estúdio.

Layout (everything vertically centered in the screen):
1. Success icon:
   - Large circle: 96px diameter, background #22C55E at 15% opacity, centered
   - Inside: checkmark icon, 48px, color #22C55E, stroke weight 3px
   - 32px gap below

2. Heading:
   - "Seu estúdio está pronto!" in display size (28px bold), color #1A1A2E, centered
   - 12px gap below

3. Subtitle:
   - "Agora você pode agendar seus primeiros atendimentos." in body (16px regular), color #525252, centered, max-width 280px (wraps to 2 lines naturally)
   - 48px gap below

4. Primary button:
   - "Ir para Agenda" full width (with 24px horizontal margin), height 48px, background #1A1A2E, text white 16px semibold, radius 12px

State: Static (success screen, no loading, no error)

Mandatory rules:
- Background #FAFAFA, no gradients, no shadows
- Primary button: background #1A1A2E, white text, height 48px, radius 12px
- Maximum 1 primary button per screen
- Touch targets minimum 44x44px
- Contrast minimum 4.5:1
- Very generous whitespace — celebratory, spacious feel
- No bottom tab bar (transition screen)
- No top bar (immersive success moment)

Important:
- Use real Portuguese content, never lorem ipsum
- Clean, minimal aesthetic — Cal.com / Linear as reference
- Flat design: no shadows, no gradients
- Generous whitespace
- Single primary action button per screen
- This is a joyful moment — the user just set up their business. Keep it simple and celebratory.
```

---

## 6. AgendaDayScreen

```
=== AgendaDayScreen ===

Design a mobile app screen for "Oriz", a beauty salon scheduling app.
Frame: 390x844 (iPhone 14).

Context:
- App: Oriz — agenda inteligente para profissionais de beleza
- Platform: Mobile iOS/Android
- Style: Clean, minimalist, flat design. No shadows, no gradients.
- Visual references: Cal.com, Linear, Notion

Color tokens:
- Primary: #1A1A2E
- Accent: #E8C547
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

Typography (font: Inter):
- Display: 28px bold
- Title: 20px semibold
- Body: 16px regular
- Caption: 13px regular
- Micro: 11px medium

Spacing: XS 4px, SM 8px, MD 16px, LG 24px, XL 32px, 2XL 48px
Border radius: SM 6px, MD 12px, LG 16px, Full 999px

Screen: AgendaDayScreen — visão diária da agenda de atendimentos (tela principal do app).

Layout (top to bottom):

1. Top bar (fixed, no elevation):
   - Background #FAFAFA
   - Left: "Agenda" in title size (20px semibold), color #171717
   - Right: filter icon (funnel) in #525252, 24px, touch target 44x44. Then 8px gap. Then "+" icon in a circle with background #E8C547, icon color #1A1A2E, 36px diameter

2. Date section (fixed, below top bar):
   - Row 1: "Quinta, 13 de março" in body (16px regular), color #525252
   - Row 2 (16px below): horizontal day selector showing 7 days
     - Each day: column with day abbreviation on top ("Seg" in micro 11px, #A3A3A3) and date number below ("10" in body 16px, #525252)
     - Selected day (today, "Qui 13"): date number inside a filled circle 36px diameter, background #1A1A2E, text white
     - Other days: no circle, just text
     - Days spaced evenly across full width
   - 1px divider line #E5E5E5 below date selector, 16px gap

3. Timeline area (scrollable):
   Hour labels on the left side (width 48px), content on the right.

   - 08:00 — empty slot:
     - Hour label "08:00" in caption (13px), color #A3A3A3, right-aligned in 48px column
     - Dashed line extending to the right, 1px dashed #E5E5E5

   - 09:00 — appointment card:
     - Hour label "09:00"
     - Card: full remaining width, background #F5F5F5, border 1px #E5E5E5, radius 12px, padding 12px
       - Row 1: "Maria Silva" in body (16px semibold) #171717. Right: "•••" context menu icon in #A3A3A3
       - Row 2: "Manicure · 30 min" in caption (13px) #525252
       - Row 3: status badge "Confirmado" — background #3B82F6 at 15% opacity, text #3B82F6, micro size (11px medium), radius 999px, padding 4px 8px

   - 10:00 — appointment card:
     - "Ana Costa" — "Pedicure · 45 min" — badge "Confirmado" (same blue styling)

   - 11:00 — appointment card:
     - "Juliana Mendes" — "Esmaltação em gel · 60 min" — badge "Confirmado"

   - 12:00 — blocked slot:
     - Card: full remaining width, background with diagonal stripe pattern using #E5E5E5 on #F5F5F5, border 1px #E5E5E5, radius 12px, padding 12px
     - Text: "Almoço" in body (16px) #A3A3A3
     - Below: "Bloqueado" in caption (13px) #A3A3A3

   - 13:00 — empty slot (dashed line)

   - 14:00 — appointment card:
     - "Carla Souza" — "Sobrancelha · 30 min" — badge "Confirmado"

   - 15:00 — empty slot (dashed line)

4. Bottom tab bar (fixed at bottom):
   - Height 56px + safe area inset
   - Background #FAFAFA
   - Top border: 1px #E5E5E5
   - 4 tabs, evenly spaced:
     - Tab 1 (active): calendar icon + "Agenda" in micro (11px medium), color #1A1A2E
     - Tab 2: people icon + "Clientes" in micro, color #A3A3A3
     - Tab 3: dollar icon + "Financeiro" in micro, color #A3A3A3
     - Tab 4: three-dots icon + "Mais" in micro, color #A3A3A3
   - Each tab: icon 24px above label, total touch target 44x44 minimum

State: With data (4 appointments, 1 blocked slot, typical workday)

Mandatory rules:
- Background #FAFAFA, no gradients, no shadows
- Cards: background #F5F5F5, border 1px #E5E5E5, radius 12px
- Inputs height 48px, background #F5F5F5, border 1px #E5E5E5
- Primary button: background #1A1A2E, white text, height 48px, radius 12px
- Status badges: radius 999px, background 15% of the color, text in full color
- Bottom tab bar: 4 tabs (Agenda, Clientes, Financeiro, Mais), height 56px
- Top bar: no elevation, background #FAFAFA
- Generous whitespace — content breathes
- Touch targets minimum 44x44px
- Contrast minimum 4.5:1

Important:
- Use real Portuguese content, never lorem ipsum
- Clean, minimal aesthetic — Cal.com / Linear as reference
- Flat design: no shadows, no gradients
- Generous whitespace
- The agenda is the heart of the app — it should feel calm, organized, and easy to scan
- Timeline should feel like a professional calendar, not cluttered
```

---

## 7. AgendaDayScreen — Estado Vazio

```
=== AgendaDayScreen — Estado Vazio ===

Design a mobile app screen for "Oriz", a beauty salon scheduling app.
Frame: 390x844 (iPhone 14).

Context:
- App: Oriz — agenda inteligente para profissionais de beleza
- Platform: Mobile iOS/Android
- Style: Clean, minimalist, flat design. No shadows, no gradients.
- Visual references: Cal.com, Linear, Notion

Color tokens:
- Primary: #1A1A2E
- Accent: #E8C547
- Background: #FAFAFA
- Borders: #E5E5E5
- Text primary: #171717
- Text secondary: #525252
- Placeholder: #A3A3A3

Typography (font: Inter):
- Display: 28px bold
- Title: 20px semibold
- Body: 16px regular
- Caption: 13px regular
- Micro: 11px medium

Spacing: XS 4px, SM 8px, MD 16px, LG 24px, XL 32px, 2XL 48px
Border radius: SM 6px, MD 12px, LG 16px, Full 999px

Screen: AgendaDayScreen empty state — dia sem agendamentos.

Layout (top to bottom):

1. Top bar (fixed, no elevation):
   - Same as data state: "Agenda" title left, filter + "+" icons right
   - Background #FAFAFA

2. Date section (fixed):
   - "Quinta, 13 de março" in body (16px), #525252
   - Day selector: 7 days, "Qui 13" selected with filled circle #1A1A2E
   - Divider line below

3. Empty state content (vertically centered in remaining space):
   - Calendar outline icon: 48px, color #A3A3A3, centered
   - 16px gap
   - "Nenhum agendamento hoje" in title (20px semibold), color #171717, centered
   - 8px gap
   - "Que tal agendar o primeiro?" in body (16px regular), color #525252, centered
   - 24px gap
   - Button "Novo Agendamento": width auto (padding 24px horizontal), height 48px, background #1A1A2E, text white 16px semibold, radius 12px, centered

4. Bottom tab bar (fixed at bottom):
   - Same as data state: 4 tabs, "Agenda" active in #1A1A2E, others in #A3A3A3
   - Height 56px + safe area

State: Empty (no appointments for selected day)

Mandatory rules:
- Background #FAFAFA, no gradients, no shadows
- Maximum 1 primary button per screen
- Bottom tab bar: 4 tabs, height 56px
- Top bar: no elevation, background #FAFAFA
- Empty state icon: outline style, 48px, #A3A3A3
- Generous whitespace
- Touch targets minimum 44x44px
- Contrast minimum 4.5:1

Important:
- Use real Portuguese content, never lorem ipsum
- Clean, minimal aesthetic — Cal.com / Linear as reference
- Flat design: no shadows, no gradients
- Generous whitespace
- Empty state should feel inviting, not sad — encourage action
```

---

## 8. AgendaDayScreen — Estado Loading

```
=== AgendaDayScreen — Estado Loading ===

Design a mobile app screen for "Oriz", a beauty salon scheduling app.
Frame: 390x844 (iPhone 14).

Context:
- App: Oriz — agenda inteligente para profissionais de beleza
- Platform: Mobile iOS/Android
- Style: Clean, minimalist, flat design. No shadows, no gradients.
- Visual references: Cal.com, Linear, Notion

Color tokens:
- Primary: #1A1A2E
- Background: #FAFAFA
- Card background: #F5F5F5
- Borders: #E5E5E5
- Placeholder: #A3A3A3

Typography (font: Inter):
- Micro: 11px medium

Spacing: XS 4px, SM 8px, MD 16px, LG 24px
Border radius: MD 12px

Screen: AgendaDayScreen loading state — skeleton shimmer while agenda loads.

Layout (top to bottom):

1. Top bar (real, not skeleton):
   - "Agenda" title left, filter + "+" icons right
   - Background #FAFAFA

2. Date section (real, not skeleton):
   - "Quinta, 13 de março"
   - Day selector with "Qui 13" selected
   - Divider below

3. Skeleton timeline (replaces real content):
   Show 4 skeleton appointment cards at different time positions to mimic a typical day.

   - 09:00 — skeleton card:
     - Hour label "09:00" in caption #A3A3A3 (real text)
     - Card shape: full width, height 80px, background #E5E5E5, radius 12px
     - Inside: 3 skeleton bars
       - Bar 1 (name): width 140px, height 14px, radius 6px, color #D4D4D4
       - Bar 2 (service): width 100px, height 12px, radius 6px, color #D4D4D4
       - Bar 3 (badge): width 70px, height 18px, radius 999px, color #D4D4D4

   - 10:00 — skeleton card: same layout, slightly different bar widths (120px, 90px, 60px)

   - 12:00 — skeleton card: same

   - 14:00 — skeleton card: same

   All skeleton elements should have a shimmer gradient animation indicator (show as a subtle diagonal lighter stripe across the skeleton blocks to indicate animation direction, left to right).

4. Bottom tab bar (real, not skeleton):
   - 4 tabs, "Agenda" active
   - Height 56px + safe area

State: Loading (skeleton shimmer reflecting timeline layout)

Mandatory rules:
- Background #FAFAFA, no gradients, no shadows on real elements
- Skeleton blocks: base color #E5E5E5, shimmer highlight color #F5F5F5
- Skeleton cards have same radius as real cards (12px)
- Skeleton bars have radius 6px
- Show shimmer direction indicator (diagonal light stripe)
- Bottom tab bar and top bar are real (not skeletons)
- Hour labels are real text (not skeletons)

Important:
- Use real Portuguese content for non-skeleton elements
- Clean, minimal aesthetic — Cal.com / Linear as reference
- Skeleton should clearly represent the real layout structure
- The shimmer conveys loading — keep it subtle and professional
```
