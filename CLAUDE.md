# Projeto: Oriz — Agenda Inteligente para Profissionais de Beleza

## Stack
- Backend: Node.js + Fastify + TypeScript + Clean Architecture
- Mobile: Flutter + Riverpod + GoRouter
- Dashboard Admin: Flutter Web ou React (TBD)
- Banco: Supabase (PostgreSQL gerenciado) + Auth + Storage + Realtime
- Cache/Filas: Redis + BullMQ
- IA: LangChain.js + Anthropic SDK + Pinecone (RAG)
- WhatsApp: Evolution API ou Z-API
- Pagamentos: Stripe ou Asaas
- Push: Firebase Cloud Messaging

## Comandos Essenciais
- `cd backend && npm run dev` — backend local
- `cd backend && npm run test` — testes
- `cd backend && npm run lint` — linter (Biome)
- `cd backend && npm run build` — build produção
- `cd mobile && flutter run` — app mobile
- `cd mobile && flutter test` — testes mobile

## Estrutura
- `backend/` — API Fastify + lógica de negócio
- `mobile/` — App Flutter (cliente final)
- `dashboard/` — Dashboard admin (dono do estúdio)
- `docs/` — Documentação técnica

## Regras Críticas
- Nunca SELECT * — sempre especificar colunas
- Paginação obrigatória em listagens (cursor-based preferido)
- Validar input no boundary com Zod schemas
- Nunca confiar em dados do cliente
- Testes obrigatórios para regras de negócio
- Usar Supabase RLS (Row Level Security) em todas as tabelas
- Multi-tenant: toda query DEVE filtrar por tenant_id (studio)

## Arquitetura
- Camadas: Route → Controller → Service → Repository
- Lógica de negócio NUNCA no controller ou route
- Um service por domínio (AppointmentService, ClientService, etc.)
- Repository abstrai Supabase — serviço nunca acessa banco direto
- Jobs assíncronos via BullMQ (IA, notificações, marketing)
- Para detalhes, veja docs/ARCHITECTURE.md

## Domínios Principais
| Quando | Onde buscar |
|--------|------------|
| agendamento, horário, conflito, agenda | docs/DOMAIN_MODEL.md#scheduling |
| cliente, anamnese, histórico, ficha | docs/DOMAIN_MODEL.md#clients |
| serviço, pacote, sessão, procedimento | docs/DOMAIN_MODEL.md#services |
| comissão, colaborador, equipe, split | docs/DOMAIN_MODEL.md#team |
| financeiro, faturamento, relatório | docs/DOMAIN_MODEL.md#financial |
| IA, WhatsApp, atendente, chatbot | docs/DOMAIN_MODEL.md#ai-assistant |
| marketing, reativação, aniversário, push | docs/DOMAIN_MODEL.md#marketing |
| auth, login, permissão, role | docs/DOMAIN_MODEL.md#auth |

## Padrão de Commits
- feat: nova funcionalidade
- fix: correção de bug
- refactor: refatoração sem mudança de comportamento
- docs: documentação
- test: testes
- chore: configuração, dependências

## Antes de Qualquer PR
- Rodar `npm run test`
- Rodar `npm run lint`
- Verificar se não há SELECT * ou N+1 queries
- Verificar validação de input com Zod
- Verificar RLS nas tabelas novas
- Verificar tenant_id em todas as queries

## Mental Linting (OBRIGATÓRIO)
Antes de escrever QUALQUER código, execute mentalmente:
1. Isso escala? E se tiver 1000 estúdios com 50 clientes cada agendando ao mesmo tempo?
2. Isso viola a arquitetura definida em docs/ARCHITECTURE.md?
3. Isso traz dados desnecessários do banco? Tem paginação?
4. Isso abre brecha de segurança? Tem RLS? Tem validação?
5. Isso respeita multi-tenancy? Filtra por tenant_id?
6. Isso aumenta complexidade sem necessidade?
7. Existe algo pronto no Supabase que resolve isso?
Se qualquer resposta for preocupante, PARE e proponha alternativa antes de implementar.
