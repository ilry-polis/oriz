---
paths: **/*.test.*, **/*.spec.*, backend/tests/**
---

# Regras de Testes — Oriz

## TDD (Superpowers enforce)
- Teste primeiro, implementação depois — sempre
- Se código for escrito antes do teste, Superpowers deleta e força recomeçar
- Red → Green → Refactor — nessa ordem

## Framework
- Backend: Vitest
- Mobile: Flutter test

## Obrigatório testar
- Toda regra de negócio no Service (agendamento, conflito, comissão, pacotes)
- Validação de input (schemas Zod)
- Cálculos financeiros (comissão, split, taxa de cartão)
- Lógica de disponibilidade de horários
- Lógica de reativação de clientes
- Fluxos de erro: input inválido, recurso não encontrado, conflito de horário
- RLS: tenant A não acessa dados de tenant B

## O que NÃO testar
- Controllers: testados indiretamente via integration tests
- Tipos TypeScript: compilador já valida
- Código sem lógica (getters, DTOs)

## Padrão
- Describe por feature, it por cenário
- Arrange → Act → Assert
- Mocks para Supabase client e serviços externos
- Nunca mockar lógica de negócio — mockar apenas I/O (banco, APIs externas)
- Dados de teste via factories (nunca hardcoded)
- Factory pattern: createTestStudio(), createTestClient() com defaults sensatos

## Multi-tenancy em Testes
- Todo teste com dados de 2 studios: studioA e studioB
- Verificar que operação no studioA não afeta studioB
- Testar com IDs cruzados: studioA acessando dados de studioB → deve falhar

## Proibido
- Testes que dependem de ordem de execução
- Testes que acessam banco real
- Testes sem assertion
- console.log em testes (usar expect)
- Testes skipados sem justificativa documentada

## Antes de Abrir PR
- npm run test passa 100%
- Novos testes cobrem a funcionalidade adicionada
- Testes de multi-tenancy presentes para toda entidade com studio_id
