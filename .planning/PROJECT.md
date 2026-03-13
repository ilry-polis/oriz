# Oriz — Agenda Inteligente para Profissionais de Beleza

## What This Is

Oriz é uma plataforma mobile-first de gestão para profissionais de beleza (manicures, lashers, micropigmentadoras, cabeleireiras) que centraliza agendamento, gestão de clientes e marketing — com uma Atendente IA que agenda e atende via WhatsApp automaticamente. Profissionais usam o app mobile, colaboradoras acessam pelo app também, e clientes agendam via página web pública do estúdio.

## Core Value

A profissional nunca mais precisa parar um atendimento para responder WhatsApp — a IA agenda, responde dúvidas e gerencia a agenda automaticamente.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] Auth + onboarding do estúdio
- [ ] Cadastro e gestão de serviços (nome, duração, preço, categorias)
- [ ] Gestão de agenda visual por profissional (dia/semana) com detecção de conflitos
- [ ] Cadastro de clientes com ficha de anamnese e histórico
- [ ] Pacotes com controle de sessões e validade
- [ ] Push notifications (confirmação + lembrete)
- [ ] Página pública do estúdio (oriz.app/nome) com agendamento self-service
- [ ] Integração WhatsApp com Atendente IA completa (agendar, reagendar, cancelar, dúvidas, fallback humano)
- [ ] Gestão de colaboradores com comissões e split automático
- [ ] Módulo financeiro com dashboard de faturamento
- [ ] Marketing automatizado (aniversário + reativação de clientes inativos)

### Out of Scope

- App mobile para clientes — clientes acessam via página web do estúdio
- Real-time chat entre profissional e cliente — WhatsApp já cumpre esse papel
- Video posts / portfólio avançado — foco é agenda, não rede social
- OAuth / social login no v1 — email/password suficiente
- Dashboard admin web separado — gestão toda pelo app mobile

## Context

- **Distribuição:** Esposa do fundador é influencer de micropigmentação com base sólida de leads no mercado de estética. Canal de aquisição validado.
- **Mercado:** Concorrentes existem (Trinks, Booksy, Salão99, TuaAgenda, Agend, PRKD) mas todos pecam em: design antiquado, UX engessada, lentidão, e nenhum tem IA de atendimento via WhatsApp.
- **Diferencial:** Experiência moderna (referência Cal.com/Calendly em limpeza visual) + IA no WhatsApp como killer feature que ninguém oferece.
- **Filosofia:** Menos features, melhor execução. Interface clean, fluida, que qualquer profissional consiga usar sem treinamento.
- **Público:** Profissionais solo (5-15 clientes/dia) e donas de estúdio com 2-10 colaboradoras.
- **Lançamento:** Beta fechado com profissionais-chave → waitlist para gerar desejo → lançamento oficial em evento presencial em Aracaju (meados de setembro/2026) com stand para 400-700 profissionais.
- **Equipe:** Fundador solo + Claude como dev principal.

## Constraints

- **Timeline:** v1 completo (Fases 1-3 do PRD) pronto para setembro/2026 — evento de lançamento
- **Tech stack:** Node.js + Fastify + TypeScript (backend), Flutter (mobile), Supabase (banco/auth/storage)
- **Plataforma:** Mobile-first (Flutter) para profissionais, página web para clientes agendarem
- **Multi-tenant:** Isolamento total por estúdio com RLS no Supabase
- **Performance:** API < 200ms p95, IA < 5s resposta no WhatsApp
- **LGPD:** Consentimento para marketing, exclusão de dados sob pedido

## Pricing

| Plano | Preço | Inclui |
|-------|-------|--------|
| Básico | R$ 19,90/mês | Agenda + clientes + serviços + pacotes + financeiro + equipe |
| Intermediário | R$ 29,90/mês | Básico + confirmação WhatsApp + recuperação de clientes + aniversário |
| Top | R$ 59,90/mês | Tudo + Atendente IA completa no WhatsApp |

Desconto no plano anual (% a definir). Nomes dos planos a definir.

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Mobile-first (Flutter), sem app pra cliente | Simplifica v1, cliente agenda via web | — Pending |
| 100% pago, sem freemium | Monetização desde dia 1, distribuição via influencer compensa falta de free tier | — Pending |
| IA completa no v1 (não incremental) | É o diferencial — lançar sem IA não faz sentido | — Pending |
| Cal.com como referência de UX | Clean, minimalista, foco na funcionalidade core | — Pending |
| Lançamento em evento presencial | Base captive de 400-700 profissionais, demo ao vivo da IA | — Pending |

---
*Last updated: 2026-03-12 after initialization*
