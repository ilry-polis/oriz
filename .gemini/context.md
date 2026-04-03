# Contexto para Code Review — Oriz

## Projeto
Plataforma SaaS multi-tenant para profissionais de beleza. Node.js + Fastify + TypeScript com Clean Architecture. Flutter para mobile. Supabase como banco.

## Foco do Review
- Segurança: input validation, autorização por role, RLS no Supabase, dados sensíveis
- Multi-tenancy: toda query filtra por studio_id
- Performance: N+1, select(*), paginação cursor-based
- Arquitetura: separação Route → Controller → Service → Repository
- Consistência: padrões do projeto respeitados

## Padrões do Projeto
- Route → Controller → Service → Repository
- Input validado com JSON Schema (Fastify) ou Zod
- Responses: { data, meta, errors }
- Testes obrigatórios para regras de negócio (Vitest)
- Jobs assíncronos via BullMQ

## Rejeitar PR se
- select('*') encontrado
- Endpoint sem validação de input
- Lógica de negócio no controller ou route
- Regra de negócio sem teste
- Query sem filtro por studio_id
- Tabela nova sem RLS
