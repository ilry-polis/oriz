# Arquitetura — Oriz

## Visão Geral

```
┌─────────────┐  ┌──────────────┐  ┌──────────────┐
│  App Mobile  │  │  Dashboard   │  │  Página Web  │
│  (Flutter)   │  │  (Admin)     │  │  (Público)   │
└──────┬───────┘  └──────┬───────┘  └──────┬───────┘
       │                 │                 │
       └────────────┬────┘─────────────────┘
                    │
             ┌──────▼──────┐
             │  API Fastify │
             │  (Node.js)   │
             └──────┬───────┘
                    │
       ┌────────────┼────────────┐
       │            │            │
┌──────▼──────┐ ┌───▼───┐ ┌─────▼─────┐
│  Supabase   │ │ Redis │ │  BullMQ   │
│ (PostgreSQL)│ │(Cache)│ │  (Jobs)   │
└─────────────┘ └───────┘ └─────┬─────┘
                                │
                    ┌───────────┼───────────┐
                    │           │           │
              ┌─────▼────┐ ┌───▼───┐ ┌─────▼─────┐
              │LangChain │ │ FCM   │ │ WhatsApp  │
              │(IA)      │ │(Push) │ │ (API)     │
              └──────────┘ └───────┘ └───────────┘
```

## Acesso ao Supabase — Regra Fundamental

O Supabase NÃO é acessado diretamente pelo client (mobile/dashboard) para CRUD de dados.

| Acesso | Via | Exemplo |
|--------|-----|---------|
| **Auth** | Direto (Supabase SDK no client) | Login, signup, refresh token, social login |
| **RPC** | Direto (Supabase SDK no client) | Funções PostgreSQL complexas |
| **Storage** | Direto (Supabase SDK no client) | Upload de fotos, avatares |
| **Realtime** | Direto (Supabase SDK no client) | Atualização de agenda em tempo real |
| **CRUD de dados** | Via Backend API (Fastify) | Tudo: agendamentos, clientes, serviços, etc. |

O backend é o dono de toda lógica de negócio e persistência de dados. O client nunca faz INSERT/UPDATE/DELETE direto no Supabase.

## Camadas do Backend

```
Route (Fastify) → Controller → Service → Repository → Supabase (server-side)
```

### Route
- Define endpoints HTTP e schema de validação (JSON Schema nativo do Fastify)
- Não contém lógica — apenas mapeia para o controller

### Controller
- Recebe request validada pelo Fastify
- Chama o service adequado
- Retorna response no shape padrão
- NUNCA contém lógica de negócio

### Service
- Contém TODA lógica de negócio
- Orquestra chamadas a repositories
- Emite eventos para jobs assíncronos quando necessário
- Um service por domínio

### Repository
- Abstrai acesso ao Supabase
- Queries parametrizadas, sempre com colunas explícitas
- Paginação cursor-based
- Filtra SEMPRE por tenant_id

## Multi-Tenancy

Isolamento por `studio_id` (tenant_id) usando Supabase RLS:
- Toda tabela tem coluna `studio_id`
- RLS policy: `auth.uid()` → busca `studio_id` do usuário → filtra registros
- Repository SEMPRE inclui `studio_id` no WHERE
- Nunca confiar que o RLS sozinho vai proteger — belt and suspenders

## Jobs Assíncronos (BullMQ + Redis)

| Fila | Responsabilidade |
|------|-----------------|
| ai-response | Processar mensagens WhatsApp com LangChain |
| notifications | Push notifications via FCM |
| marketing | Mensagens de aniversário e reativação |
| reports | Gerar relatórios financeiros pesados |

## Integrações Externas

| Serviço | Uso | Fallback |
|---------|-----|----------|
| Supabase | Auth, DB, Storage, Realtime | — (core, sem fallback) |
| Redis/Upstash | Cache, filas BullMQ | Degraded: sem cache, jobs síncronos |
| WhatsApp API | Mensagens da IA e marketing | Agendamento manual continua |
| Anthropic/OpenAI | LLM para Atendente IA | Mensagem pré-definida + fallback humano |
| FCM | Push notifications | — (notificação não entregue, log) |
| Stripe/Asaas | Pagamentos de assinatura | — (core billing) |

## Padrão de Response da API

```json
{
  "data": {},
  "meta": {
    "cursor": "abc123",
    "hasMore": true
  },
  "errors": []
}
```

## Decisões Arquiteturais

- Para registro completo, veja docs/DECISIONS_LOG.md
