# Registro de Decisões Arquiteturais — Oriz

## 2026-03-12 — CRUD via Backend, não direto no Supabase
- **Contexto:** Definir como o client (mobile/dashboard) acessa dados
- **Decisão:** Todo CRUD de dados passa pela API Fastify. Client acessa Supabase direto apenas para Auth, RPC, Storage e Realtime
- **Motivo:** Centraliza lógica de negócio no backend, facilita validação, auditoria e controle. Evita duplicação de regras entre client e server
- **Alternativa descartada:** Client acessar Supabase direto com RLS (mais simples mas espalha lógica)

## 2026-03-12 — Fastify em vez de Express
- **Contexto:** Escolha de framework HTTP para o backend
- **Decisão:** Fastify com TypeScript
- **Motivo:** 2-3x mais rápido que Express, schema validation nativa via JSON Schema, suporte TypeScript de primeira classe, plugin ecosystem maduro
- **Alternativa descartada:** Express (mais popular mas mais lento, sem validação nativa)

## 2026-03-12 — Supabase como backend-as-a-service
- **Contexto:** Necessidade de banco PostgreSQL, auth, storage e realtime
- **Decisão:** Supabase como plataforma gerenciada
- **Motivo:** PostgreSQL completo com RLS para multi-tenancy, auth integrado com social login, realtime para atualizar agenda em tempo real, SDK nativo para Flutter
- **Alternativa descartada:** PostgreSQL self-hosted + Auth0 (mais complexo, mais caro)

## 2026-03-12 — LangChain.js para orquestração de IA
- **Contexto:** Atendente IA precisa consultar agenda, entender contexto e agendar
- **Decisão:** LangChain.js com tools/agents para orquestrar LLM + busca de dados
- **Motivo:** Permite definir tools (consultar agenda, criar agendamento), mantém histórico de conversa, suporta múltiplos LLM providers
- **Alternativa descartada:** Chamada direta ao Anthropic SDK (funciona para chat simples, mas não para agent com ferramentas)

## 2026-03-12 — BullMQ + Redis para jobs assíncronos
- **Contexto:** Processamento de IA, notificações e marketing não podem ser síncronos
- **Decisão:** BullMQ rodando sobre Redis
- **Motivo:** Retry automático, dead letter queue, dashboard de monitoramento, rate limiting nativo
- **Alternativa descartada:** Supabase Edge Functions (limitado para jobs longos como processamento de IA)

## 2026-03-12 — Cursor-based pagination em vez de offset
- **Contexto:** Listagens de agendamentos e clientes
- **Decisão:** Paginação cursor-based como padrão
- **Motivo:** Performance consistente independente da página, sem problemas com inserções durante navegação
- **Alternativa descartada:** Offset/limit (degradação de performance em tabelas grandes)
