---
paths: supabase/**, backend/src/database/**, backend/src/repositories/**
---

# Supabase — Regras Automáticas

## Arquitetura de Acesso

### Banco de Dados — EXCLUSIVAMENTE via Backend
- Client (mobile/dashboard) NUNCA acessa banco diretamente
- Toda query passa pelo Fastify: Controller → Service → Repository
- Conexão via Postgres direto (pg ou drizzle-orm) OU Supabase service_role client
- NÃO usar @supabase/supabase-js para queries no client — usar API REST do Fastify
- RLS continua ativo como segunda camada de proteção (belt-and-suspenders)

### Supabase Auth — Client + Backend
- Client usa @supabase/supabase-js (mobile) e @supabase/ssr (dashboard) apenas para auth
- Fluxos no client: login, signup, social login, token refresh, logout
- Backend valida JWT em todo request autenticado (middleware)
- Backend extrai studio_id e role do JWT claims — nunca aceita de input
- service_role key: APENAS no backend, NUNCA no client

### Supabase Storage — Client via Signed URL
- Upload: backend gera signed upload URL → client envia arquivo direto pro Storage
- Download: backend gera signed download URL → client acessa
- Client NUNCA acessa Storage com service_role key
- Buckets: studio-photos, client-photos, documents
- RLS no bucket por path: {bucket}/{studio_id}/{file_id}
- Limite: 5MB imagens, 10MB documentos
- Nomes de arquivo: UUID, nunca nome original do usuário

### Supabase Realtime — Client direto
- Client subscribe em mudanças relevantes (agenda, notificações)
- Filtrar SEMPRE por studio_id no subscription
- Canal por studio: realtime:studio:{studio_id}
- Usar para: atualização de agenda em tempo real, notificações push trigger
- NÃO usar para: sync de dados geral (isso é API REST)
- Dessubscribar no dispose/unmount (cleanup obrigatório)
- Realtime é complemento, não substituto — tela deve funcionar sem ele

### Edge Functions — Webhooks e Cron
- Usar para:
  - Webhooks de pagamento (Stripe/Asaas) — validar signature antes de processar
  - Cron jobs: cleanup AuditLog (TTL 365d), cleanup NotificationLog (TTL 90d)
  - Cron jobs: refresh materialized view FinancialSummary (CONCURRENTLY)
- NÃO usar para:
  - Lógica de negócio (pertence ao Fastify)
  - CRUD de entidades (pertence ao backend)
  - Processamento que depende de estado complexo da aplicação
- Edge Function acessa banco via service_role — mesmas regras de segurança do backend

## Ambiente e MCP
- Supabase MCP conectado para operações de desenvolvimento apenas
- NUNCA conectar MCP a produção
- Sempre revisar tool calls do MCP antes de aprovar

## Migrations
- Source of truth: docs/DATABASE_SCHEMA.md → toda migration reflete o schema documentado
- Naming: NNN_descricao.sql (ex: 001_initial_schema.sql, 002_add_billing.sql)
- Migrations são imutáveis — nunca editar migration já aplicada, criar nova
- Toda migration deve ser reversível quando possível (incluir DOWN)
- Testar migration em projeto dev antes de aplicar em staging/prod

## RLS (Row Level Security)
- RLS habilitado em TODA tabela — mesmo com acesso exclusivo via backend
- Belt-and-suspenders: backend filtra por studio_id + RLS filtra no banco
- Policies separadas por operação: FOR SELECT, FOR INSERT, FOR UPDATE, FOR DELETE
- Nunca FOR ALL — cria ambiguidade entre roles
- studio_id filtro direto — nunca depender de JOIN para RLS
- Tabelas com studio_id nullable: policy com OR studio_id IS NULL para SELECT
- ConsentRecord e AuditLog: apenas SELECT + INSERT, sem UPDATE/DELETE
- AuditLog: INSERT via service_role, SELECT restrito a owner

## Queries no Backend (pg — driver puro)
- Usar `pg` (node-postgres) como driver — SQL direto, sem ORM
- Queries SQL escritas manualmente nos repositories
- Sempre parametrizar: `$1, $2, $3` — NUNCA concatenar valores
- Sempre filtrar por studio_id mesmo com RLS ativo
- Nunca SELECT * — listar colunas explicitamente
- Paginação obrigatória em toda listagem (LIMIT $n OFFSET $m)
- Ordenação explícita em toda query (ORDER BY obrigatório)
- Retorno tipado: definir interfaces TypeScript por query
- Tratar erros de banco: constraint violations (23505 = unique, 23503 = FK), timeouts, connection lost

## Padrão de Repository com pg
```typescript
// Padrão obrigatório em todo repository
const result = await pool.query<RowType>(
  `SELECT id, name, studio_id FROM clients 
   WHERE studio_id = $1 AND phone = $2
   ORDER BY name ASC
   LIMIT $3 OFFSET $4`,
  [studioId, phone, limit, offset]
);
```
- Um arquivo de repository por domínio: client.repository.ts, appointment.repository.ts
- Queries complexas: usar tagged template literals ou arquivo .sql separado
- Transactions: usar pool.connect() + client.query('BEGIN') / 'COMMIT' / 'ROLLBACK'
- Nunca esquecer de liberar o client de volta pro pool (finally block)

## Conexão com Banco
- Connection string via variável de ambiente DATABASE_URL
- Connection pooling: usar Supabase connection pooler (porta 6543 para transaction mode)
- Pool via `new Pool({ connectionString: DATABASE_URL, max: N })`
- Pool size: dev=5, staging=10, prod=20
- Statement timeout: SET statement_timeout = '30s' por sessão
- Retry em connection lost, não em query error
- Graceful shutdown: pool.end() no SIGTERM
