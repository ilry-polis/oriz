# Stack Research

**Domain:** Beauty salon scheduling SaaS with WhatsApp AI assistant
**Researched:** 2026-03-12
**Confidence:** HIGH (stack decisions already validated in CLAUDE.md and docs/ARCHITECTURE.md)

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Node.js | 22 LTS | Runtime | LTS com performance improvements, native fetch, ESM mature |
| Fastify | v5 | HTTP framework | 2x faster que Express, plugin system, schema-based validation, TypeScript first |
| TypeScript | 5.4+ | Type safety | Strict mode, satisfies operator, decorators — produtividade + segurança |
| Supabase | JS v2 | PostgreSQL + Auth + Storage + Realtime | Managed PostgreSQL com RLS, Auth pronto, Realtime para agenda live updates |
| Flutter | 3.22+ | Mobile app | Cross-platform, Impeller engine, performance nativa, hot reload |
| Redis | 7+ | Cache + job state | In-memory, pub/sub, counters para rate limiting |

### Backend Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Zod | v3.23+ | Schema validation | Validar TODOS os inputs nos boundaries (routes) |
| BullMQ | v5 | Job queues | AI responses, notifications, marketing — tudo assíncrono |
| ioredis | v5 | Redis client | Client para BullMQ e cache manual |
| @supabase/supabase-js | v2 | Supabase client | Acesso ao banco, auth server-side, storage |
| Biome | v1.9+ | Linter + formatter | Substitui ESLint + Prettier — 100x mais rápido |
| Pino | v9 | Logging | Structured JSON logging, integra com Fastify nativamente |
| date-fns | v3 | Date manipulation | Leve, tree-shakeable, imutável |
| date-fns-tz | v3 | Timezone handling | Conversão timezone-aware — crítico para Brasil (múltiplos fusos) |
| nanoid | v5 | ID generation | IDs curtos para slugs e referências públicas |
| @bull-board/fastify | latest | Queue dashboard | Monitorar jobs em dev/staging |

### AI Stack

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| @anthropic-ai/sdk | latest | LLM provider | Chamadas diretas ao Claude para tool-calling |
| @langchain/core | v0.2+ | Agent framework | Orquestração de tools, conversation memory, agent loop |
| @langchain/anthropic | v0.2+ | LangChain + Claude | Provider adapter para LangChain |
| @pinecone-database/pinecone | v3 | Vector store (RAG) | Busca semântica em histórico de conversas e serviços |

**Nota sobre Pinecone vs pgvector:** pgvector (extensão PostgreSQL no Supabase) é alternativa viável e elimina dependência externa. Avaliar na fase de IA — se volume de embeddings for baixo (<100k), pgvector basta. Para escala, Pinecone.

### WhatsApp Integration

| Library | Version | Purpose | Notes |
|---------|---------|---------|-------|
| Evolution API | v2 | WhatsApp provider (primary) | Self-hosted, multidevice, webhooks, mais controle |
| Z-API | — | WhatsApp provider (fallback) | SaaS, menos controle, mais estável |

**CRITICAL:** Ambas são APIs não-oficiais. Abstrair atrás de interface (strategy pattern) para trocar sem impacto. Para evento de lançamento, considerar Meta Cloud API oficial como segurança.

### Payments

| Library | Version | Purpose | Notes |
|---------|---------|---------|-------|
| Asaas SDK | latest | Gateway de pagamento | **Recomendado** para mercado BR: PIX nativo, boleto, cartão, split automático |
| Stripe | — | Gateway alternativo | Alternativa se expansão internacional for prioridade |

**Why Asaas over Stripe:** PIX é dominante no mercado de beleza brasileiro. Asaas tem PIX nativo com split, Stripe adicionou PIX mas é mais caro e menos integrado. Asaas também tem boleto nativo — relevante para plano mensal.

### Mobile (Flutter)

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| flutter_riverpod | v2.5+ | State management | Estado global, dependency injection |
| go_router | v14+ | Navigation | Deep linking, route guards para auth |
| dio | v5 | HTTP client | Interceptors para JWT, retry, logging |
| table_calendar | v3 | Calendar widget | Agenda visual — principal tela do app |
| freezed | v2 | Code generation | Immutable models, union types, copyWith |
| json_serializable | v6 | JSON mapping | Serialização/deserialização de API responses |
| firebase_messaging | latest | Push notifications | FCM integration |
| supabase_flutter | v2 | Supabase client | Auth direto, Realtime subscriptions, Storage |
| flutter_local_notifications | latest | Local notifications | Lembretes locais quando push falha |
| cached_network_image | latest | Image caching | Avatares e fotos de serviços |

### Public Web Page (oriz.app/slug)

| Technology | Version | Purpose | Why |
|------------|---------|---------|-----|
| Next.js | 14+ (App Router) | SSR framework | SEO essencial para página pública, ISR para performance |
| Tailwind CSS | v3.4+ | Styling | Rapid UI development, consistência |
| shadcn/ui | latest | Component library | Clean, acessível, customizável — alinhado com estética Cal.com |

**Why NOT Flutter Web:** Flutter Web não tem SEO, é pesado para carregar, péssimo para primeira impressão. Página pública precisa ser leve, indexável, rápida.

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| Biome | Lint + format | Config única para todo o backend |
| Vitest | v2 | Testing | ESM native, faster que Jest, compatible API |
| Docker Compose | Local dev | Supabase local + Redis + Evolution API |
| Sentry | Error tracking | Monitoramento de erros em produção |

## Installation

```bash
# Backend core
npm install fastify @fastify/cors @fastify/jwt @fastify/rate-limit
npm install @supabase/supabase-js zod pino nanoid date-fns date-fns-tz

# Queues
npm install bullmq ioredis @bull-board/fastify

# AI
npm install @anthropic-ai/sdk @langchain/core @langchain/anthropic @pinecone-database/pinecone

# Payments
npm install asaas  # ou stripe

# Dev dependencies
npm install -D typescript @types/node vitest @biomejs/biome
```

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| Fastify | Express | Nunca — Fastify é superior em tudo para novos projetos |
| Zod | Joi / Yup | Nunca — Zod é TypeScript-first, melhor inference |
| BullMQ | Agenda.js / pg-boss | pg-boss se quiser eliminar Redis (trade-off: menos features) |
| Biome | ESLint + Prettier | Nunca — Biome é drop-in replacement, 100x mais rápido |
| Vitest | Jest | Nunca para ESM projects — Jest tem problemas com ESM |
| Asaas | Stripe | Se expansão internacional for prioridade |
| Pinecone | pgvector | Se volume de embeddings < 100k (avoids external dependency) |
| date-fns | dayjs / moment | moment está deprecated, dayjs é viável mas date-fns é mais tree-shakeable |
| Next.js (public page) | Flutter Web | Nunca para SEO-critical pages |
| Evolution API | Z-API | Se preferir SaaS managed over self-hosted |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Express | Mais lento, middleware chain confuso, não tem schema validation nativa | Fastify |
| Moment.js | Deprecated, enorme bundle size | date-fns |
| Jest | Problemas com ESM, configuração complexa | Vitest |
| ESLint + Prettier | Lento, config hell, conflitos entre os dois | Biome |
| Prisma | ORM pesado, migration system conflita com Supabase migrations | Supabase client direto + raw SQL quando necessário |
| Drizzle ORM | Adiciona camada desnecessária quando Supabase client já faz query builder | Supabase client direto |
| Flutter Web (página pública) | Zero SEO, bundle pesado, carregamento lento | Next.js |
| Sequelize | ORM legacy, TypeScript support fraco | Supabase client |
| Socket.io | Supabase Realtime já resolve WebSocket needs | Supabase Realtime |

## Stack Patterns by Variant

**If solo professional (Persona 1):**
- Same stack, simpler data model (no team/commission modules active)
- Pricing tier controls feature access, not separate codebase

**If studio with team (Persona 2):**
- Full stack with team module, commission splits, multi-professional agenda
- Financial dashboard with per-professional breakdown

**If scaling beyond 1000 studios:**
- Add Redis cluster for slot caching
- Scale BullMQ workers horizontally
- Consider pgvector → Pinecone migration for vector search
- Add read replica on Supabase

## Version Compatibility

| Package A | Compatible With | Notes |
|-----------|-----------------|-------|
| Fastify v5 | Node 22+ | Requires ESM |
| BullMQ v5 | ioredis v5, Redis 7+ | Breaking changes from v4 |
| @langchain/core v0.2 | @langchain/anthropic v0.2 | Must match major versions |
| supabase_flutter v2 | Flutter 3.22+ | Dart 3 required |
| Next.js 14 | React 18 | App Router preferred |

## Infrastructure

| Service | Purpose | Cost Estimate |
|---------|---------|---------------|
| Railway / Render | Backend hosting | $5-20/mo |
| Vercel | Public web page (Next.js) | Free tier sufficient |
| Supabase | Database + Auth + Storage + Realtime | Free → $25/mo Pro |
| Upstash Redis | Managed Redis | Free tier → $10/mo |
| Sentry | Error monitoring | Free tier (5k events/mo) |
| Evolution API | WhatsApp (self-hosted on Railway) | $5-10/mo |
| Pinecone | Vector DB | Free tier (100k vectors) |

## Sources

- Project CLAUDE.md — stack decisions
- docs/ARCHITECTURE.md — architectural patterns
- docs/DECISIONS_LOG.md — technology choices rationale
- Fastify, BullMQ, LangChain.js official documentation
- Asaas vs Stripe comparison for Brazilian market

---
*Stack research for: beauty salon scheduling SaaS*
*Researched: 2026-03-12*
