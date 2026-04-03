# Feature Research

**Domain:** Beauty salon scheduling SaaS with WhatsApp AI assistant
**Researched:** 2026-03-12
**Confidence:** HIGH

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume exist. Missing these = product feels incomplete.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Agenda visual por profissional (dia/semana) | Todo concorrente tem, profissionais esperam ver o dia | MEDIUM | Deve suportar múltiplos profissionais por estúdio |
| Detecção e prevenção de conflitos de horário | Agendamento sem conflito é o mínimo | MEDIUM | Race condition entre canais (IA + web + app) é crítico |
| CRUD de agendamentos com status workflow | Confirmado → Realizado/Cancelado/No-show | LOW | Status machine simples mas essencial |
| Bloqueio de horários (férias, folga, almoço) | Profissional precisa controlar sua disponibilidade | LOW | Por profissional, por dia da semana |
| Cadastro de clientes com dados básicos + histórico | Toda profissional mantém "caderninho" digital | LOW | Nome, telefone, email, histórico de atendimentos |
| Ficha de anamnese configurável por serviço | Obrigatório sanitário para lash, micropigmentação, depilação | MEDIUM | Templates por categoria de serviço |
| Catálogo de serviços com preço e duração | Base para agendamento funcionar | LOW | Categorias, preço, duração configurável |
| Confirmação + lembrete de agendamento | Reduz no-show drasticamente | MEDIUM | Push e/ou WhatsApp dependendo do plano |
| Notificação de cancelamento | Profissional precisa saber em tempo real | LOW | Push notification |
| Onboarding do estúdio | Primeira experiência define retenção | MEDIUM | Wizard simples: dados do estúdio → serviços → horários |
| Auth seguro (email/senha) | Padrão | LOW | Supabase Auth |
| Agendamento self-service (página web) | Cliente agenda sem depender do WhatsApp | MEDIUM | URL pública: oriz.app/slug |
| Horários de funcionamento por dia da semana | Controle básico de disponibilidade | LOW | Configuração por profissional |

### Differentiators (Competitive Advantage)

Features que nenhum ou poucos concorrentes oferecem — justificam troca e plano premium.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Atendente IA completa no WhatsApp | **Killer feature** — nenhum concorrente tem. Agenda, reagenda, cancela, tira dúvidas | HIGH | Core differentiator do Oriz |
| Configuração de personalidade da IA por estúdio | Tom de voz, saudação, regras de agendamento personalizáveis | MEDIUM | Profissional sente que a IA "é ela" |
| Fallback para humano quando IA não resolve | IA reconhece limitação e passa para profissional | MEDIUM | Confiança da profissional na IA |
| Pacotes com dedução automática de sessões | Concorrentes têm implementações fracas disso | MEDIUM | Ex: 5 sessões de depilação por R$X |
| Reativação automática de clientes inativos | >60 dias sem agendar, mensagem configurável com desconto opcional | MEDIUM | Métrica de retorno mensurável |
| Campanha de aniversário automática | Toque pessoal automatizado via WhatsApp | LOW | Data do nascimento → mensagem personalizada |
| Comissão e split automático por profissional | Elimina planilha de Excel da dona do estúdio | MEDIUM | % por serviço ou valor fixo, configurável quem absorve taxa |
| Dashboard financeiro com taxa de ocupação | Inteligência além do que concorrentes mostram | MEDIUM | Faturamento, ticket médio, receita por profissional |
| UX moderna e clean (referência Cal.com) | Percebido como feature — concorrentes têm UX de 2015 | HIGH | Design é diferencial competitivo real |
| URL pública do estúdio (oriz.app/slug) | Cartão de visita + agendamento integrado | MEDIUM | SEO + link para bio do Instagram |
| Tracking de origem do agendamento | IA vs web vs app vs manual — dado valioso | LOW | Nenhum concorrente oferece essa visibilidade |

### Anti-Features (Commonly Requested, Often Problematic)

Features que parecem boas mas criam problemas.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| App mobile para cliente | "Todo mundo tem app" | Fricção enorme — cliente não vai baixar app pra agendar unha | Página web responsiva + WhatsApp IA |
| Chat in-app em tempo real | "Preciso falar com a cliente" | WhatsApp já é o canal natural, duplicar cria confusão | WhatsApp como canal único de comunicação |
| Portfólio/galeria de fotos avançada | "Quero mostrar meu trabalho" | Instagram já faz isso melhor, escopo creep enorme | Link para Instagram no perfil do estúdio |
| Marketplace de profissionais | "Quero clientes novos" | Modelo de negócio totalmente diferente, dilui foco | Foco na profissional que já tem clientes |
| Gestão de estoque/produtos | "Vendo produtos no salão" | Segmento diferente, complexidade fiscal | Integração futura com sistema de estoque externo |
| PDV com impressão de recibo | "Preciso emitir nota" | Complexidade fiscal/tributária massiva | Parceria com sistema fiscal (Nota Carioca etc.) |
| Social login no v1 | "Facilita o login" | Atrasa launch, email/senha é suficiente | Implementar em v2 se métricas de conversão justificarem |
| Dashboard admin web separado | "Preciso de tela grande" | Duplica todo o frontend, profissional vive no celular | App mobile é suficiente; web opcional em v2 |
| Tier gratuito (freemium) | "Preciso volume de usuários" | Canal de distribuição via influencer resolve aquisição | 100% pago desde dia 1, distribuição orgânica |
| Relatórios exportáveis complexos | "Preciso de Excel" | Dashboard visual simples é o que esse público realmente usa | Dashboard in-app com métricas visuais |

## Feature Dependencies

```
Auth + Onboarding
    └──requires──> Serviços (precisa existir pra configurar agenda)
                       └──requires──> Agenda (precisa de serviços pra definir duração)
                                          └──requires──> Clientes (agendamento cria/vincula cliente)

Agenda ──requires──> Conflito Detection (core da agenda)

Push Notifications ──requires──> Agenda (notifica sobre agendamentos)

Pacotes ──requires──> Serviços + Clientes (pacote vincula ambos)

Página Web Pública ──requires──> Agenda + Serviços (self-service booking)

WhatsApp IA ──requires──> TODOS os módulos de domínio (agenda, serviços, clientes)
    └──enhances──> Agenda (canal de agendamento automatizado)

Marketing ──requires──> Clientes + WhatsApp (precisa de dados e canal)

Financeiro ──requires──> Agenda + Equipe (calcula de atendimentos realizados)

Equipe/Comissões ──requires──> Serviços + Agenda (comissão por serviço realizado)
```

### Dependency Notes

- **WhatsApp IA requires ALL domain modules:** IA DEVE ser o último módulo construído — ela lê dados reais de agenda. Dados inconsistentes = IA agendando slots errados = confiança destruída
- **Agenda requires Conflito Detection:** Não é feature separada, é parte core da agenda desde dia 1
- **Marketing requires WhatsApp:** Canal de envio é WhatsApp, precisa estar operacional antes

## MVP Definition

### Launch With (v1)

- [ ] Auth + Onboarding — primeiro contato define retenção
- [ ] Catálogo de serviços — base para agendamento
- [ ] Gestão de agenda com conflitos — core do produto
- [ ] Cadastro de clientes com anamnese — "caderninho digital"
- [ ] Pacotes com controle de sessões — diferencial vs planilha
- [ ] Push notifications — reduz no-show
- [ ] Página pública do estúdio — agendamento self-service
- [ ] WhatsApp IA completa — killer feature, razão de existir
- [ ] Equipe + comissões — atende Persona 2 (dona de estúdio)
- [ ] Dashboard financeiro — visibilidade do negócio
- [ ] Marketing automatizado — aniversário + reativação

### Add After Validation (v1.x)

- [ ] OAuth / social login — se métricas de conversão justificarem
- [ ] Relatórios exportáveis — se profissionais pedirem
- [ ] Múltiplas unidades por conta — se estúdios com filiais aparecerem
- [ ] Integração com Google Calendar — sincronia bidirecional

### Future Consideration (v2+)

- [ ] Dashboard web — quando base crescer e donas de estúdio pedirem
- [ ] Marketplace — modelo de negócio diferente, avaliar separadamente
- [ ] Integração com sistemas fiscais — quando demanda justificar

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Agenda visual + conflitos | HIGH | MEDIUM | P1 |
| WhatsApp IA completa | HIGH | HIGH | P1 |
| Cadastro de clientes + anamnese | HIGH | LOW | P1 |
| Catálogo de serviços | HIGH | LOW | P1 |
| Auth + Onboarding | HIGH | MEDIUM | P1 |
| Página web pública | HIGH | MEDIUM | P1 |
| Push notifications | MEDIUM | MEDIUM | P1 |
| Pacotes + sessões | MEDIUM | MEDIUM | P1 |
| Equipe + comissões | MEDIUM | MEDIUM | P1 |
| Dashboard financeiro | MEDIUM | MEDIUM | P1 |
| Marketing automatizado | MEDIUM | MEDIUM | P1 |
| UX moderna (Cal.com ref) | HIGH | HIGH | P1 |

## Competitor Feature Analysis

| Feature | Trinks | Booksy | Salão99 | Oriz (Our Approach) |
|---------|--------|--------|---------|---------------------|
| Agenda | Sim, UI antiga | Sim, UI razoável | Sim, UI antiga | Moderna, Cal.com-inspired |
| Agendamento online | Sim, site genérico | Sim, app cliente | Sim, site genérico | Página pública customizada + WhatsApp IA |
| IA WhatsApp | Nenhum | Nenhum | Nenhum | **Core differentiator** |
| Comissões | Básico | Básico | Básico | Split automático configurável |
| Marketing | Email básico | Nenhum | SMS básico | WhatsApp automatizado (aniversário + reativação) |
| Design/UX | Datado (2015) | Razoável | Datado | Clean, moderno, fluido |
| Velocidade | Lento | Médio | Lento | < 200ms p95 target |

## Sources

- Análise de concorrentes: Trinks, Booksy, Salão99, TuaAgenda, Agend, PRKD
- Feedback direto do mercado via influencer de micropigmentação
- PRD do projeto (docs/PRD.md)

---
*Feature research for: beauty salon scheduling SaaS*
*Researched: 2026-03-12*
