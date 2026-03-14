---
paths: mobile/lib/**, dashboard/**, docs/SCREENS.md, docs/DESIGN_SYSTEM.md
---

# Screens & UI — Regras Automáticas

## Source of Truth
- docs/DESIGN_SYSTEM.md — linguagem visual, tokens, componentes base
- docs/SCREENS.md — mapa de telas com fluxos e estados
- docs/API_CONTRACTS.md — dados disponíveis por tela (o que a API entrega)
- DOMAIN_MODEL.md — entidades que cada tela representa

## Princípios de Design
- Clean e minimalista — cada elemento na tela deve justificar sua existência
- Espaço em branco é feature, não desperdício
- Hierarquia visual clara: uma ação primária por tela, no máximo duas secundárias
- Mobile-first: tela do profissional é o produto principal, dashboard é complemento
- Velocidade: profissional em pé, entre um cliente e outro, precisa resolver em 3 toques ou menos

## Regra dos 3 Toques
- Agendar = máximo 3 toques (selecionar cliente → serviço → horário)
- Confirmar/cancelar = máximo 2 toques (abrir agendamento → ação)
- Ver agenda do dia = 1 toque (tela inicial)
- Se um fluxo exceder 3 toques, simplificar ou repensar

## Componentes
- Reutilizar antes de criar — verificar DESIGN_SYSTEM.md antes de fazer componente novo
- Todo componente deve ter: estado vazio, estado carregando, estado com dados, estado de erro
- Formulários: validação inline, nunca só no submit
- Listas: skeleton loading, pull-to-refresh, paginação infinita ou load more
- Nunca mostrar tela em branco — sempre empty state com ação sugerida

## Dados e API
- Tela só mostra campos que a API entrega — conferir API_CONTRACTS.md
- Nunca inventar campo que não existe no contrato
- Paginação no frontend deve respeitar os limites do contrato (per_page max 100)
- Offline-first para agenda do dia: cachear localmente, sincronizar quando voltar

## Acessibilidade
- Contraste mínimo 4.5:1 para texto, 3:1 para elementos grandes
- Touch targets mínimo 44x44dp
- Labels em todos os inputs
- Suporte a font scaling (não quebrar layout com texto grande)

## Multi-tenancy na UI
- Nome e logo do studio sempre visível no contexto
- Nunca mostrar dados de outro studio
- Professional vê apenas seus dados + dados que o contrato permite
- Owner vê tudo do studio

## Antes de Criar Tela
- Verificar que os endpoints necessários existem no API_CONTRACTS.md
- Verificar que os dados existem no DOMAIN_MODEL.md
- Definir os 4 estados: vazio, carregando, com dados, erro
- Verificar se componentes do DESIGN_SYSTEM.md cobrem a necessidade
