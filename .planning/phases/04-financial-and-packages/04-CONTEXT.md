# Phase 4: Financial and Packages - Context

**Gathered:** 2026-04-05
**Status:** Ready for planning

<domain>
## Phase Boundary

Revenue dashboard, payment recording with discounts, session packages with automatic deduction on completion, and commission tracking. Studio owners can track revenue by day/week/month, record payments with split methods, manage session packages, and view/pay commissions per professional. Collaborators see only their own financial summary. Billing/subscription (SaaS plans) belongs to Phase 5.1 — this phase covers operational finances only.

</domain>

<decisions>
## Implementation Decisions

### Dashboard financeiro — Layout
- Resumo com KPIs no topo: Faturamento total, Ticket medio, Taxa de ocupacao, Total de atendimentos
- KPIs com comparacao ao periodo anterior (seta verde/vermelha + %)
- Seletor de periodo: chips Dia / Semana / Mes
- Lista de pagamentos recentes abaixo dos KPIs
- Filtros na lista: por profissional e por metodo de pagamento (filter chips)
- Secoes expansiveis abaixo: "Por profissional" e "Por servico" com ranking, valor e %
- Acessivel via "Mais > Financeiro"

### Dashboard financeiro — Visao da colaboradora
- Colaboradora ve resumo pessoal: seus atendimentos concluidos, seu faturamento gerado, sua comissao calculada
- Nao ve dados de outras profissionais nem do estudio (consistente com Phase 2)

### Dashboard financeiro — Navegacao
- Tela Financeiro com tabs: [Resumo] [Comissoes]
- Tab Resumo = KPIs + pagamentos recentes + breakdowns
- Tab Comissoes = listagem por profissional com status pago/pendente

### Pacotes de sessoes — Criacao
- Dois caminhos: dentro do servico (secao "Pacotes") E tela separada global (Mais > Pacotes)
- Pacote sempre vinculado a um servico (relacao 1:N no DB ja existe)
- Campos: nome, total de sessoes, preco, validade em dias

### Pacotes de sessoes — Venda
- Dois caminhos: botao "+ Vender pacote" na ficha da cliente E indicacao no QuickBookSheet durante agendamento
- Na ficha da cliente: secao "Pacotes ativos" mostra pacotes vigentes com sessoes usadas/total e data de expiracao
- Venda registra assinatura (package_subscription) com data de inicio e validade
- Permite parcelamento: dona pode parcelar o pacote (ex: 3x R$200) com registro de parcelas e vencimento

### Pacotes de sessoes — Vinculo no agendamento
- Automatico com confirmacao: se cliente tem pacote ativo para o servico, checkbox "Usar pacote (3/5 sessoes)" aparece pre-marcado no QuickBookSheet
- Profissional pode desmarcar para cobrar avulso
- Pacote so se aplica ao servico vinculado — outro servico = automaticamente avulso

### Pacotes de sessoes — Deducao
- Deducao na conclusao do atendimento (nao no agendamento) — decisao do roadmap
- Se atendimento vinculado a pacote: pula payment sheet, deduz sessao automaticamente, toast com feedback ("Sessao deduzida — Pacote Lash 5x: 1 restante")
- Se nao vinculado a pacote: fluxo normal com payment sheet

### Pacotes de sessoes — Ultima sessao
- Ao completar a ultima sessao: dialog/toast avisando "Ultima sessao do pacote [nome] da [cliente]"
- Botao para renovar (criar nova assinatura do mesmo pacote)

### Pacotes de sessoes — Expiracao
- Expiracao flexivel: pacote expirado fica com badge "Expirado" e nao permite uso automatico
- Dona pode estender a validade manualmente na ficha da cliente (editar data de expiracao)

### Pacotes de sessoes — Financeiro
- Venda de pacote aparece como receita no dashboard no periodo em que foi vendida
- Tipo "Pacote" no registro de pagamento para distinguir de avulso

### Comissoes — Visualizacao
- Tab "Comissoes" dentro da tela Financeiro
- Lista profissionais com comissao acumulada no periodo + status (Pendente/Pago)
- Tap numa profissional abre detalhamento: cada atendimento + valor da comissao

### Comissoes — Periodo
- Configuravel: quinzenal ou mensal (dona configura nas settings do estudio)
- Seletor de periodo: < Abril 2026 > (ou quinzena)

### Comissoes — Calculo
- Calculada automaticamente ao completar cada atendimento (tempo real, nao batch)
- Hook no completeAppointment() ja existe como ponto de integracao
- Percentual por profissional (ja configurado na Phase 2)

### Comissoes — Pacotes
- Comissao proporcional: valor unitario da sessao (preco pacote / total sessoes)
- Ex: pacote 5x R$600 = R$120/sessao. Comissao 30% = R$36 por sessao completada

### Comissoes — Marcar como pago
- Botao/swipe "Marcar como pago" por profissional para o periodo selecionado
- Muda status de pendente para pago com registro de data

### Comissoes — Taxa do cartao
- Mostrar deducao no detalhe: Valor atendimento -> Taxa cartao -> Comissao liquida
- Politica (quem paga) ja configurada por profissional (Phase 2): studio_absorbs, professional_absorbs, split
- Taxa configuravel pela dona por metodo de pagamento nas settings do estudio (credito, debito; PIX e dinheiro = 0%)

### Pagamento — Desconto
- Campo "Desconto" no payment sheet: valor em R$ ou %
- Valor final recalculado automaticamente
- Comissao calculada sobre valor liquido (apos desconto)
- Motivo do desconto: campo opcional que aparece quando desconto > 0
- Sugestoes rapidas: "Cortesia", "Fidelidade", "Pacote"

### Pagamento — Permissao de desconto
- Dona configura % maximo de desconto que colaboradora pode dar (ex: ate 10%)
- Acima do limite, so a dona pode aplicar
- Configuravel nas settings do estudio

### Pagamento — Split de metodos
- Permitir dois metodos de pagamento por atendimento (ex: R$100 PIX + R$50 credito)
- UX: selecionar primeiro metodo + valor, opcao "+ Adicionar metodo" para segundo

### Claude's Discretion
- Loading skeletons para dashboard e listas
- Exato design dos KPI cards (tamanho, cores, icones)
- Implementacao do grafico de comparacao (se inline nos cards ou secao separada)
- Animacoes de transicao entre tabs Resumo/Comissoes
- Design da tela global de pacotes (Mais > Pacotes)
- UX do parcelamento de pacotes (formulario, campos)
- Design do dialog de renovacao de pacote
- Skeleton/empty states para tela financeiro
- Ordem e agrupamento dos filtros
- Como exibir parcelas pendentes/pagas na ficha do pacote

</decisions>

<specifics>
## Specific Ideas

- Dashboard deve seguir a mesma estetica Cal.com/Linear (clean, minimal, whitespace-heavy) das demais telas
- KPIs com seta + % de comparacao dao contexto instantaneo sem precisar de graficos
- Pacotes sao feature core para o mercado beauty — clientes compram pacotes de lash, micropig, unhas com frequencia
- Fluxo de conclusao com pacote deve ser mais rapido que avulso (sem payment sheet) para incentivar uso
- Tab Comissoes e natural dentro do Financeiro — dona ja esta no contexto financeiro quando precisa ver/pagar comissoes

</specifics>

<code_context>
## Existing Code Insights

### Reusable Assets
- `PaymentSheet` (mobile/lib/features/agenda/widgets/payment_sheet.dart): UI completa para registro de pagamento — estender com campo desconto e split
- `PaymentRepository.create()` (backend/src/repositories/payment.repository.ts): registra pagamento, precisa de list/filter
- `AppointmentService.completeAppointment()` (backend/src/services/appointment.service.ts): ja integra payment recording — hook para comissao e deducao de sessao
- `AppointmentController.complete()` (backend/src/controllers/appointment.controller.ts): handler HTTP implementado
- `StatusBadge`, `EmptyStateWidget`, skeleton patterns — reutilizar no dashboard
- Design system tokens (AppColors, AppSpacing, typography) — aplicar nos KPI cards
- Sealed state pattern (Loading/Loaded/Error) — usar nos providers financeiros

### Established Patterns
- Backend: Route -> Controller -> Service -> Repository com Zod validation
- Backend: Response shape { data, meta } para listas, cursor-based pagination
- Backend: snake_case DB/API, camelCase services
- Flutter: Riverpod sealed state + Notifier pattern
- Flutter: Bottom sheets para todos os fluxos de criacao/acao
- DB: RLS policies em todas as tabelas com studio_id filtering
- DB: Valores monetarios em centavos (integer), nunca float
- DB: Tabelas payments, packages, package_subscriptions, commissions ja existem com schema completo

### Integration Points
- Appointment completion flow: ponto de integracao para deducao de sessao e calculo de comissao
- QuickBookSheet: ponto de integracao para checkbox de pacote
- Client detail (ficha): ponto de integracao para secao "Pacotes ativos" e venda
- Service edit screen: ponto de integracao para secao "Pacotes" do servico
- Navigation "Mais": adicionar "Financeiro" e "Pacotes" (ja planejado na Phase 2 como "em breve")
- Settings do estudio: ponto de integracao para configuracao de taxas, periodo de comissao, limite de desconto
- Routes stubbed: payments, packages, package-subscriptions, financial, commissions — todos precisam de controller/service implementation

</code_context>

<deferred>
## Deferred Ideas

- Export de relatorios financeiros (PDF/CSV) — v2, REPT-01
- Comparacao ano-a-ano — v2, REPT-02
- Split automatico de pagamento via gateway (auto-payout para profissional) — explicitamente fora do escopo v1
- Nota fiscal / integracao fiscal — complexidade tributaria alta, fora do escopo
- Pacotes com servicos multiplos (ex: pacote "Beauty Complete" com lash + unha) — futuro

</deferred>

---

*Phase: 04-financial-and-packages*
*Context gathered: 2026-04-05*
