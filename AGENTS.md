# Projeto: Oriz — Agenda Inteligente para Profissionais de Beleza

## Stack
Node.js + Fastify + TypeScript + Clean Architecture, Flutter + Riverpod, Supabase (PostgreSQL), Redis + BullMQ, LangChain.js

## Regras
- Nunca select('*') — sempre especificar colunas
- Paginação cursor-based obrigatória
- Validar input no boundary (JSON Schema / Zod)
- Testes para regras de negócio (Vitest)
- Lógica de negócio no Service, nunca no Controller ou Route
- Multi-tenant: toda query filtra por studio_id
- Supabase RLS ativo em todas as tabelas

## Referências
- Arquitetura: docs/ARCHITECTURE.md
- Contratos de API: docs/API_CONTRACTS.md
- Modelo de domínio: docs/DOMAIN_MODEL.md
- PRD: docs/PRD.md
