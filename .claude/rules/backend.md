---
paths: backend/**
---

# Regras Backend — Oriz

## Fastify
- Usar JSON Schema nativo do Fastify para validação de request/response
- Plugins registrados via fastify.register() com prefixo de rota
- Nunca usar async sem try/catch no handler — Fastify engole erros silenciosos

## Banco de Dados (Supabase)
- Sempre filtrar por studio_id (multi-tenant)
- Sempre especificar colunas no select — nunca select('*')
- Paginação cursor-based obrigatória em listagens
- Usar índices para queries frequentes (studio_id + date em appointments)
- Evitar N+1: usar joins do Supabase (select com foreign tables)

## API
- Contratos definidos em docs/API_CONTRACTS.md
- Respostas sempre: { data, meta, errors }
- HTTP status codes corretos (201 criação, 204 delete, 409 conflito)
- Rate limiting em endpoints públicos (webhook WhatsApp, página do estúdio)

## Segurança
- Supabase RLS ativo em todas as tabelas
- Sanitizar dados antes de queries
- Nunca logar dados sensíveis (tokens, senhas, PII de clientes)
- Validar autorização por role em cada endpoint (owner vs professional)
- Webhook WhatsApp: validar signature antes de processar

## Jobs (BullMQ)
- Jobs de IA com timeout de 30s e 3 retries
- Dead letter queue para jobs que falharam 3x
- Rate limiting para WhatsApp API (evitar ban)
- Jobs de marketing rodam em horário comercial (8h-20h)
