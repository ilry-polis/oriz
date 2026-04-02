# Phase 2: Core Domain - Context

**Gathered:** 2026-04-02
**Updated:** 2026-04-02
**Status:** Ready for planning

<domain>
## Phase Boundary

Services catalog, client management, and team management with commissions. Studio owners can configure their service catalog, manage their client list with anamnesis and history, and register their team with commission rules. LGPD compliance (audit log and consent capture) is embedded since it must exist from the first client data access.

</domain>

<decisions>
## Implementation Decisions

### Client list and navigation
- List with search bar at top, scrollable
- Each row: avatar + name + last visit date
- Filter chips: VIP, Novo, Inativo
- Cursor-based pagination (backend already has this pattern)

### Client detail (ficha)
- Header: name, phone, email, tags
- Tabs: Historico | Anamnese | Notas
- Each tab is a focused view, no infinite scroll

### Client registration
- Two paths: quick inline during scheduling (name + phone only) AND full form from client list
- Phone unique per studio (DB constraint exists)
- Birthday optional but incentivized with nudge: "Adicione para enviar parabens automatico"
- Marketing consent checkbox at registration (default: unchecked, opt-in explicit)

### Client tags
- Mixed: "Novo" and "Inativo" are automatic (based on appointment history)
- "VIP" and custom tags are manual
- Tags stored as JSONB array (DB field exists)

### Anamnesis
- Per service category (unique key: client + category already in DB)
- Templates with default fields per category (lash: alergia cola, lentes; micropig: gravidez, anticoagulante, etc.)
- Professional can add/remove custom fields beyond template defaults
- Fields stored as JSONB

### Client notes
- Free text with timeline (like chat comments)
- Each note is dated, immutable once created
- Displayed in reverse chronological order in Notas tab

### Service catalog
- Services grouped by category in expandable/collapsible sections
- Each row: name + duration + price
- Tap to edit, + button to add new service
- Buffer time configurable per service (default 0, field buffer_minutes exists in DB)
- Toggle active/inactive per service (is_active field exists) — inactive hides from scheduling but preserves history

### Service categories
- Pre-defined seed categories (Lash, Unhas, Micropigmentacao, Cabelo, Estetica) + professional can create custom categories
- Categories from onboarding carry over seamlessly

### Team management
- Owner generates invite link shared via WhatsApp — link expires in 7 days
- Collaborator clicks link, creates own account (email + password), gets linked to studio automatically
- Owner pre-configures: name, services (checkbox), commission rate, card fee policy
- Each professional linked to specific services (checkbox selection)
- Toggle active/inactive per professional (is_active field exists) — inactive hides from scheduling but preserves history
- Professional inherits studio hours by default, can override with custom working_hours (JSONB field exists)

### Team permissions
- Collaborator sees only: her own agenda, her clients, her working hours
- Collaborator does NOT see: financeiro, commissions of others, studio settings, other professionals' agendas
- Owner sees everything

### Commissions
- Percentage per professional (single rate applied to all her services)
- Card fee policy configurable per professional: studio_absorbs, professional_absorbs, or split (field exists in DB)
- Commission calculated on appointment completion (not booking) — already decided in roadmap

### LGPD - Consent
- Explicit opt-in checkbox at client registration: "Aceito receber mensagens de marketing via WhatsApp"
- Default: unchecked (not granted)
- Same checkbox on public booking page (Phase 5)
- Consent revocation: professional toggles off at client's request, timestamp recorded
- ConsentRecord tracks: granted, revoked, timestamps

### LGPD - Audit log
- Automatic logging: who viewed, edited, exported, or deleted client data
- Visible in client detail (additional tab or section)
- Records: user, action, timestamp, IP

### LGPD - Data deletion
- Anonymization (not hard delete): replace name/phone/email with generic data ("Cliente removido")
- Preserves appointment history and financial records for reporting
- Audit log records the anonymization event

### Empty states
- Consistent pattern across all screens (clients, services, team)
- Illustration (clean/minimal) + contextual text + CTA button ("Adicionar primeiro cliente", etc.)
- Follows Cal.com/Linear visual reference

### Navigation
- Bottom nav with 4 tabs: Agenda | Clientes | Serviços | Mais
- "Mais" opens a list screen with: Equipe, Financeiro (em breve), Configurações, Meu perfil, Sair
- Future phases add items to "Mais" without changing bottom nav structure

### Claude's Discretion
- Loading skeletons and transition animations
- Exact spacing, typography, and color palette within clean minimal direction
- Error state handling
- Anamnesis template field types (boolean, text, select) — whatever makes clinical sense
- Audit log UI presentation (tab vs expandable section in client detail)
- How "Novo" and "Inativo" tags are calculated (days since last appointment thresholds)
- Invite link generation mechanism (token format, URL structure)
- First-login flow for collaborators after accepting invite

</decisions>

<specifics>
## Specific Ideas

- Cal.com / Linear as visual reference (carried from Phase 1) — clean, minimal, whitespace-heavy
- Service list should feel like a settings/config screen, not a storefront
- Client list should feel like contacts app — fast search, quick access
- Anamnesis templates should cover main beauty verticals: lash (alergia cola, lentes contato, lagrima artificial), micropig (gravidez, anticoagulante, queloides), unhas (alergia acetona, fungos), estetica (alergias, medicamentos)
- Bottom nav icons should be simple line icons, not filled — consistent with minimal aesthetic
- "Mais" screen should feel like iOS Settings — clean list with chevrons

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- Backend: Route → Controller → Service → Repository pattern fully established
- Backend: Zod schemas already defined for clients, services, professionals routes (stubs need implementation)
- Backend: Auth middleware with studio_id extraction from JWT
- Backend: Cursor-based pagination pattern in list schemas
- Flutter: Riverpod sealed state pattern (Loading/Success/Error) from auth/onboarding
- Flutter: ApiClient HTTP wrapper, GoRouter navigation
- Flutter: Agenda widgets (skeleton_timeline, appointment_card) as reference for list patterns
- Flutter: ShellRoute already exists for bottom nav — needs tab expansion

### Established Patterns
- Backend: snake_case in DB/API, camelCase in services — controller converts
- Backend: Response shape { data, meta } for lists, { data } for single items
- Flutter: Feature modules in features/ with data/, domain/, presentation/ subdirs
- Flutter: Widgets in presentation/widgets/, screens in presentation/
- DB: RLS policies on all tables filtering by studio_id
- DB: All Phase 2 tables already exist with proper constraints and indices

### Integration Points
- Onboarding wizard already creates services — service catalog must show these seamlessly
- Owner = first professional in studio (created during onboarding)
- Agenda (Phase 3) will consume services, clients, and professionals from this phase
- Marketing (Phase 7) depends on consent records created here
- Bottom nav currently has only Agenda — Phase 2 adds Clientes, Serviços, Mais tabs

</code_context>

<deferred>
## Deferred Ideas

- Import/export de clientes (CSV/Excel) — future feature, not Phase 2 scope
- None other — discussion stayed within phase scope

</deferred>

---

*Phase: 02-core-domain*
*Context gathered: 2026-04-02*
*Updated: 2026-04-02 — team invite flow changed to WhatsApp link, navigation and empty states added*
