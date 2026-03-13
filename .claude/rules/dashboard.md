---
paths: dashboard/**
---

# Regras Dashboard Admin — Oriz

## Propósito
Dashboard web para donos de estúdio gerenciarem agenda, equipe, financeiro e marketing.

## Stack (TBD — decidir na implementação)
- Opção A: Flutter Web (reutiliza componentes do mobile)
- Opção B: React + Next.js + Tailwind (melhor para dashboards complexos)

## Regras
- Dados sempre paginados
- Loading states em toda operação
- Responsivo (desktop-first, mas funcionar em tablet)
- Gráficos com lazy loading
- Auth via Supabase — mesmo JWT do mobile
- Role guard: apenas owner acessa dashboard
