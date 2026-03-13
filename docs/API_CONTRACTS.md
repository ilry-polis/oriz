# Contratos de API — Oriz

## Convenções Gerais

- Base URL: `/api/v1`
- Auth: Bearer token (Supabase JWT)
- Content-Type: `application/json`
- Response shape: `{ data, meta, errors }`
- Paginação: cursor-based (`?cursor=xxx&limit=20`)
- Todas as rotas (exceto auth) requerem autenticação
- Multi-tenant: studio_id extraído do JWT, não passado no request

## Módulos

### Auth
```
POST   /api/v1/auth/signup          — Criar conta
POST   /api/v1/auth/login           — Login (email + senha)
POST   /api/v1/auth/logout          — Logout
POST   /api/v1/auth/refresh         — Refresh token
POST   /api/v1/auth/forgot-password — Enviar email de reset
```

### Studio (Onboarding)
```
POST   /api/v1/studios              — Criar estúdio (onboarding)
GET    /api/v1/studios/me           — Dados do estúdio do usuário logado
PATCH  /api/v1/studios/me           — Atualizar estúdio
GET    /api/v1/s/:slug              — Página pública do estúdio (sem auth)
```

### Services
```
GET    /api/v1/services             — Listar serviços do estúdio
POST   /api/v1/services             — Criar serviço
PATCH  /api/v1/services/:id         — Atualizar serviço
DELETE /api/v1/services/:id         — Desativar serviço (soft delete)
```

### Appointments
```
GET    /api/v1/appointments                — Listar agendamentos (filtros: date, professional_id, status)
POST   /api/v1/appointments                — Criar agendamento
PATCH  /api/v1/appointments/:id            — Atualizar agendamento
PATCH  /api/v1/appointments/:id/status     — Mudar status (confirm, complete, cancel, no-show)
GET    /api/v1/appointments/available-slots — Horários disponíveis (query: date, professional_id, service_id)
```

### Clients
```
GET    /api/v1/clients              — Listar clientes (paginado, busca por nome/telefone)
POST   /api/v1/clients              — Criar cliente
GET    /api/v1/clients/:id          — Detalhes + histórico
PATCH  /api/v1/clients/:id          — Atualizar cliente
GET    /api/v1/clients/:id/history  — Histórico de atendimentos
```

### Professionals
```
GET    /api/v1/professionals        — Listar profissionais do estúdio
POST   /api/v1/professionals        — Adicionar profissional
PATCH  /api/v1/professionals/:id    — Atualizar (comissão, serviços, etc.)
DELETE /api/v1/professionals/:id    — Desativar (soft delete)
```

### Packages
```
GET    /api/v1/packages                    — Listar pacotes
POST   /api/v1/packages                    — Criar pacote
POST   /api/v1/packages/:id/subscribe      — Cliente compra pacote
PATCH  /api/v1/packages/subscriptions/:id  — Usar sessão do pacote
```

### Financial
```
GET    /api/v1/financial/summary       — Dashboard (filtros: period)
GET    /api/v1/financial/commissions   — Comissões (filtros: professional_id, period)
GET    /api/v1/financial/payments      — Pagamentos (filtros: method, period)
```

### WhatsApp / IA
```
POST   /api/v1/webhooks/whatsapp      — Webhook recebe mensagens (sem auth, validação por signature)
GET    /api/v1/ai/config              — Configuração da IA do estúdio
PATCH  /api/v1/ai/config              — Atualizar configuração da IA
GET    /api/v1/ai/conversations       — Listar conversas
```

### Marketing
```
GET    /api/v1/campaigns              — Listar campanhas
POST   /api/v1/campaigns              — Criar campanha
PATCH  /api/v1/campaigns/:id          — Atualizar campanha
GET    /api/v1/campaigns/:id/metrics  — Métricas de envio e retorno
```

## Exemplo de Response

```json
// GET /api/v1/appointments?date=2026-03-15&limit=20
{
  "data": [
    {
      "id": "uuid",
      "client": { "id": "uuid", "name": "Maria Silva" },
      "professional": { "id": "uuid", "name": "Ana" },
      "service": { "id": "uuid", "name": "Alongamento de Cílios" },
      "date": "2026-03-15",
      "start_time": "14:00",
      "end_time": "15:30",
      "status": "confirmed",
      "source": "whatsapp_ai"
    }
  ],
  "meta": {
    "cursor": "abc123",
    "hasMore": true,
    "total": 42
  },
  "errors": []
}
```
