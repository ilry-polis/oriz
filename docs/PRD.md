# PRD — Oriz: Agenda Inteligente para Profissionais de Beleza

## Visão do Produto

Oriz é uma plataforma de gestão completa para profissionais de beleza (manicures, lashers, designers de sobrancelha, depiladores, cabeleireiros) que centraliza agendamento, gestão de clientes, financeiro e marketing — com uma Atendente IA que agenda via WhatsApp automaticamente.

## Problema

Profissionais de beleza perdem tempo e clientes porque:
- Respondem WhatsApp manualmente entre atendimentos, atrasando o serviço atual
- Perdem agendamentos quando não conseguem responder a tempo
- Não têm visão de faturamento, comissões e performance
- Não fazem reativação de clientes inativos
- Gerenciam tudo em cadernos, planilhas ou apps genéricos que não entendem o negócio

## Público-Alvo

### Persona 1 — Profissional Solo
- Manicure, lasher ou designer que trabalha sozinha no próprio estúdio ou em casa
- Atende 5-15 clientes/dia
- Problema principal: parar o atendimento para responder WhatsApp
- Precisa de: agenda + IA no WhatsApp + ficha de cliente

### Persona 2 — Dona de Estúdio (com equipe)
- Tem 2-10 profissionais no estúdio
- Problema principal: calcular comissões, evitar conflitos de agenda, controlar faturamento
- Precisa de tudo da Persona 1 + gestão de equipe + financeiro + dashboard

## Módulos do Produto

### M1 — Atendente IA (WhatsApp) ★ Core Differentiator
- Conversa natural via WhatsApp com clientes do estúdio
- Responde dúvidas sobre serviços, preços e disponibilidade
- Realiza agendamentos consultando agenda real do sistema
- Envia confirmação após agendamento
- Suporta reagendamento e cancelamento
- Dona configura: tom de voz, serviços oferecidos, regras de agendamento
- Fallback para humano quando IA não consegue resolver

### M2 — Gestão de Agenda
- Agenda visual por profissional (dia/semana)
- Detecção e prevenção de conflitos de horário
- Duração configurável por serviço
- Intervalo entre atendimentos configurável
- Horários de funcionamento por dia da semana
- Bloqueio de horários (férias, folga, almoço)
- Status do agendamento: confirmado, realizado, cancelado, no-show

### M3 — Página do Negócio (Web)
- URL pública: oriz.app/nome-do-estudio
- Informações do estúdio (nome, endereço, fotos, horário)
- Lista de serviços com preços
- Profissionais disponíveis com foto e especialidades
- Avaliações de clientes
- Agendamento direto pelo site (sem IA, self-service)

### M4 — Gestão de Clientes
- Cadastro com dados básicos (nome, telefone, email)
- Ficha de anamnese configurável por tipo de serviço
- Histórico completo de atendimentos
- Notas privadas por cliente
- Tags e segmentação (VIP, novo, inativo)
- Data do último atendimento (para reativação automática)

### M5 — Gestão de Serviços e Pacotes
- Cadastro de serviços (nome, duração, preço)
- Categorias de serviços
- Pacotes com preço especial (ex: 5 sessões de depilação por R$X)
- Controle de sessões: desconta automaticamente a cada realização
- Validade do pacote configurável

### M6 — Gestão de Colaboradores
- Cadastro de profissionais do estúdio
- Vínculo: quais serviços cada profissional faz
- Comissão configurável (% por serviço ou valor fixo)
- Split automático: divide faturamento entre estúdio e profissional
- Configuração de quem absorve taxa de cartão (estúdio, profissional ou ambos)
- Relatório de comissões por período

### M7 — Módulo Financeiro
- Dashboard de faturamento (dia/semana/mês)
- Receita por profissional
- Receita por serviço
- Ticket médio
- Taxa de ocupação da agenda
- Formas de pagamento (dinheiro, PIX, cartão débito/crédito)
- Relatórios exportáveis

### M8 — Push Notifications
- Confirmação de agendamento
- Lembrete X horas antes do horário
- Confirmação de cancelamento
- Notificações de marketing (quando habilitado pelo cliente)

### M9 — Marketing Automatizado
- Mensagem automática de aniversário (WhatsApp)
- Reativação de clientes inativos (>60 dias sem agendar, configurável)
- Mensagem de reativação personalizável (com ou sem desconto)
- Dona configura: texto, desconto opcional, canal (WhatsApp/push)
- Métricas: taxa de retorno após reativação

## Modelo de Negócio

### Freemium → Premium
- **Grátis:** Agenda básica + até 30 clientes + agendamento manual
- **Pro (R$49-79/mês):** IA no WhatsApp + clientes ilimitados + pacotes + marketing
- **Business (R$99-149/mês):** Tudo do Pro + equipe + comissões + financeiro completo + página do negócio

## Requisitos Não-Funcionais

### Performance
- API: < 200ms p95 para operações CRUD
- IA: < 5s para resposta no WhatsApp (incluindo consulta de agenda)
- Suportar 1000+ estúdios simultâneos com 50 agendamentos/dia cada

### Segurança
- Multi-tenant com isolamento por estúdio (RLS no Supabase)
- Auth via Supabase Auth (email + social login)
- Dados de pagamento nunca armazenados (delegado ao gateway)
- LGPD: consentimento para marketing, exclusão de dados sob pedido
- Criptografia de dados sensíveis em repouso

### Disponibilidade
- 99.5% uptime
- Backup automático do banco (Supabase faz por padrão)
- Graceful degradation: se IA cair, agendamento manual continua

## Prioridade de Implementação (MVP)

### Fase 1 — Fundação (Semanas 1-3)
1. Auth + Onboarding do estúdio
2. Cadastro de serviços
3. Gestão de agenda (CRUD + conflitos)
4. Cadastro de clientes

### Fase 2 — Core (Semanas 4-6)
5. Agendamento pelo app (cliente agenda via mobile)
6. Push notifications (confirmação + lembrete)
7. Pacotes e controle de sessões

### Fase 3 — IA (Semanas 7-9)
8. Integração WhatsApp
9. Atendente IA — responder dúvidas e agendar
10. Página do negócio (web)

### Fase 4 — Gestão (Semanas 10-12)
11. Gestão de equipe + comissões
12. Módulo financeiro + dashboard
13. Marketing automatizado (aniversário + reativação)

## Métricas de Sucesso
- NPS > 50
- Retenção mensal > 80%
- Taxa de agendamento via IA > 40% dos agendamentos totais
- Tempo médio de resposta da IA < 5s
- Taxa de reativação de clientes inativos > 15%
