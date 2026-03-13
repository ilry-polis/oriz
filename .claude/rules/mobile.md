---
paths: mobile/**
---

# Regras Mobile (Flutter) — Oriz

## Acesso a Dados
- CRUD de dados: SEMPRE via API backend (Fastify), NUNCA direto no Supabase
- Supabase SDK no client APENAS para: Auth, RPC, Storage, Realtime
- Repository do mobile chama a API backend, não o Supabase diretamente

## Arquitetura
- Riverpod para state management
- GoRouter para navegação
- Repository pattern para acesso a dados
- Separação: UI → Provider → Repository → API/Supabase

## Performance
- Lazy loading de listas (paginação)
- Cache local de dados frequentes (serviços, profissionais)
- Imagens com CachedNetworkImage
- Evitar rebuilds desnecessários (const widgets, select em providers)

## UI/UX
- Design system consistente (cores, tipografia, espaçamento)
- Loading states em toda operação assíncrona
- Error states com ação de retry
- Empty states com instrução clara
- Formulários com validação inline

## Segurança
- Token Supabase armazenado via flutter_secure_storage
- Nunca armazenar dados sensíveis em SharedPreferences
- Limpar dados locais no logout
