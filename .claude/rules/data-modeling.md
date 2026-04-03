---
paths: backend/src/database/**, backend/src/repositories/**, docs/DOMAIN_MODEL.md, docs/DATABASE_SCHEMA.md, supabase/migrations/**
---

# Data Modeling — Regras Automáticas

## Multi-tenancy (belt-and-suspenders)
- Toda tabela de dados de tenant DEVE ter studio_id direto — sem exceção, sem JOINs para RLS
- Tabelas com studio_id nullable (ex: ServiceCategory) requerem policy especial: SELECT WHERE studio_id = auth.studio_id() OR studio_id IS NULL
- INSERT/UPDATE/DELETE sempre restritos a studio_id = auth.studio_id()
- Tabelas sem studio_id (ex: DeviceToken) usam RLS via user_id = auth.uid() — documentar qual

## Índices
- Documentar índices críticos junto com a entidade no DOMAIN_MODEL.md
- Ranges temporais (agendamentos): exclusion constraint com tsrange, não UNIQUE partial
- Não criar UNIQUE + exclusion redundantes — exclusion é superset
- Todo studio_id + campo de query frequente = índice composto

## Tipos e Schemas
- Nunca JSON sem schema — campos conhecidos viram colunas explícitas
- JSON só para extensões genuinamente imprevisíveis, validado com Zod na entrada
- Periods: period_start DATE / period_end DATE ou period_year INT / period_month INT
- Monetário: sempre em centavos (INTEGER), nunca float

## Integridade
- ConsentRecord é append-only — nunca UPDATE, consultar pelo último registro por (client_id, studio_id, type) ordenado por granted_at DESC
- AuditLog: INSERT via service_role (backend), SELECT restrito a owner do studio
- Subscription.price_cents = preço contratado no momento da assinatura (histórico imutável)

## Alto Volume
- AuditLog e NotificationLog: partição por mês (PARTITION BY RANGE created_at) + TTL (365d e 90d respectivamente)
- FinancialSummary: REFRESH MATERIALIZED VIEW CONCURRENTLY ou pré-computar via BullMQ job
- Documentar estratégia de retenção na migration

## Antes de Criar Migration
- DOMAIN_MODEL.md é source of truth — conferir antes de qualquer CREATE TABLE
- Verificar que RLS policy está documentada para a tabela
- Verificar que índices críticos do modelo estão incluídos
- Rodar mental-lint na migration antes de aplicar

## Antes de Criar Repository
- Conferir que a tabela existe no schema e no DOMAIN_MODEL.md
- Queries SEMPRE filtram por studio_id (mesmo que RLS já filtre — belt-and-suspenders)
- Nunca SELECT * — listar colunas explicitamente
- Paginação obrigatória em listagens
