Gere ou audite o mapa de telas do Oriz.

## Sources of Truth
- docs/DESIGN_SYSTEM.md — linguagem visual e componentes
- docs/API_CONTRACTS.md — dados disponíveis por endpoint
- docs/DOMAIN_MODEL.md — entidades e relacionamentos
- docs/SCREENS.md — mapa existente (pode estar desatualizado)
- .planning/ — roadmap com phases e features

## Para Cada Tela, Documente
1. Nome e rota (ex: AgendaScreen — /agenda)
2. Quem acessa: owner | professional | public
3. Dados: quais endpoints consome (referência ao API_CONTRACTS.md)
4. Layout: wireframe textual com hierarquia dos elementos
5. Ações: primária (1), secundárias (máx 2), navegação
6. Estados: vazio, carregando, com dados, erro
7. Componentes: quais do DESIGN_SYSTEM.md usa

## Agrupamento por Fluxo
Organize telas por fluxo do usuário:

### Mobile (Profissional/Owner)
- Onboarding: splash → login → setup studio → setup services → done
- Agenda: dia → semana → detalhes do agendamento → ações
- Clientes: lista → ficha → histórico → anamnese
- Novo agendamento: selecionar cliente → serviço → horário → confirmar
- Financeiro: resumo → pagamentos → comissões → detalhes
- Configurações: studio → profissionais → serviços → horários

### Dashboard (Owner)
- Overview: métricas do dia/semana/mês
- Agenda: visão geral de todos os profissionais
- Clientes: lista com filtros e busca
- Financeiro: dashboard com gráficos
- Configurações: studio, equipe, planos

### Público (Cliente)
- Booking page: selecionar serviço → profissional → horário → dados → confirmar
- Confirmação: resumo do agendamento

## Regra dos 3 Toques
Para cada fluxo crítico, contar toques:
- Agendar: ≤ 3 toques
- Confirmar/cancelar: ≤ 2 toques
- Ver agenda do dia: 1 toque
- Se exceder, propor simplificação

## Checklist de Validação
- [ ] Toda feature do roadmap (.planning/) tem tela correspondente
- [ ] Toda tela consome endpoints que existem no API_CONTRACTS.md
- [ ] Nenhum campo na tela que não existe na API
- [ ] Componentes reusados do DESIGN_SYSTEM.md
- [ ] 4 estados definidos para cada tela
- [ ] Regra dos 3 toques respeitada nos fluxos críticos
- [ ] Empty states com ação sugerida (nunca tela em branco)
- [ ] Acessibilidade: contraste, touch targets, labels

## Cruzamento
- Compare roadmap com telas: features sem tela?
- Compare API_CONTRACTS.md com telas: endpoints não usados?
- Compare DESIGN_SYSTEM.md com telas: componentes faltantes?

Seja direto. Foque em completude e consistência com os contratos e o roadmap.
