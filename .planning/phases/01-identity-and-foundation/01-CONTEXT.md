# Phase 1: Identity and Foundation - Context

**Gathered:** 2026-03-13
**Status:** Ready for planning

<domain>
## Phase Boundary

Auth (email magic link + Google + Apple), studio onboarding wizard, and multi-tenant infrastructure. Professionals can create and access their studio account; the system enforces multi-tenant isolation from day one. Team management and per-professional configuration belong to Phase 2.

</domain>

<decisions>
## Implementation Decisions

### Onboarding wizard flow
- Step-by-step screens with progress indicator (4 steps: studio info, services, business hours, done)
- Steps can be skipped — services and business hours are optional during onboarding
- App accessible immediately after studio name + timezone + slug are set
- Persistent top banner when onboarding is incomplete: "Complete your studio setup" with progress chip (2/4 done), tappable to resume
- Service step offers category templates (nails, lashes, hair, micropigmentation, etc.) with suggested services, durations, and prices to customize

### Auth screen experience
- First screen: logo + tagline ("Sua agenda inteligente") + prominent Google/Apple social buttons + smaller "continuar com e-mail" link below
- Email flow uses magic link — single email field, no password. System sends login link to inbox
- No password-based auth — magic link + social login only
- Visual feel: clean minimal — white/light background, subtle brand colors, lots of whitespace. Cal.com / Linear reference
- i18n from the start: Portuguese (pt-BR) + English supported

### Studio profile details
- Required during onboarding: studio name, timezone (auto-detected from device), slug (oriz.app/slug)
- Slug auto-suggested from studio name ("Espaco Ana Lash" → "espaco-ana-lash"), editable, real-time availability check
- Optional (configurable later in settings): logo/photo, address, phone, description
- Owner account = first professional in the studio automatically (no separate professional setup step)
- Optional logo upload available in Phase 1; full branding (colors, cover photo) deferred to Phase 5

### Business hours setup
- Weekly grid with pre-filled defaults: Mon-Sat 09:00–18:00, Sunday off
- Toggle days on/off, adjust start/end time per day
- Multiple time ranges per day supported (e.g., 09:00-12:00 + 14:00-18:00 for lunch break)
- Time picker uses 15-minute increments
- Business hours set per studio in Phase 1 (not per professional — that comes in Phase 2 with team management)

### Claude's Discretion
- Loading skeleton and transition animations between onboarding steps
- Exact spacing, typography, and color palette within the clean minimal direction
- Error state handling (invalid email, slug taken, network errors)
- Magic link email template design
- Timezone auto-detection fallback behavior

</decisions>

<specifics>
## Specific Ideas

- Cal.com / Linear as visual reference for clean, minimal, whitespace-heavy design
- Social login buttons should be the primary CTA — email is secondary
- Category templates for services should cover the main beauty verticals: nails, lashes, hair, micropigmentation, aesthetics
- The "skip allowed with nudge" pattern should feel helpful, not nagging

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- No existing code — greenfield project

### Established Patterns
- Stack defined: Node.js + Fastify + TypeScript (backend), Flutter + Riverpod + GoRouter (mobile), Supabase (auth/db/storage)
- Architecture: Route → Controller → Service → Repository layers
- Supabase Auth handles identity — magic link and social login are built-in Supabase Auth features

### Integration Points
- Supabase Auth for magic link, Google, and Apple sign-in
- Supabase Storage for logo upload
- Supabase RLS for multi-tenant isolation (studio_id on all tables)
- Flutter i18n via ARB files or intl package for pt-BR + English

</code_context>

<deferred>
## Deferred Ideas

- None — discussion stayed within phase scope

</deferred>

---

*Phase: 01-identity-and-foundation*
*Context gathered: 2026-03-13*
