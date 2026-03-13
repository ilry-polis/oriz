---
paths: **/*.test.*, **/*.spec.*
---

# Regras de Testes — Oriz

## Framework
- Backend: Vitest
- Mobile: Flutter test

## Obrigatório testar
- Toda regra de negócio no Service (agendamento, conflito, comissão, pacotes)
- Validação de input (schemas Zod)
- Cálculos financeiros (comissão, split, taxa de cartão)
- Lógica de disponibilidade de horários
- Lógica de reativação de clientes

## Padrão
- Describe por feature, it por cenário
- Arrange → Act → Assert
- Mocks para Supabase e serviços externos
- Dados de teste via factories (nunca hardcoded)

## Proibido
- Testes que dependem de ordem de execução
- Testes que acessam banco real
- Testes sem assertion
- console.log em testes (usar expect)
