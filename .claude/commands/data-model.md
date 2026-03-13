Analise ou gere schema de banco de dados para o Oriz.

## Source of Truth
- docs/DOMAIN_MODEL.md é a referência absoluta. Toda entidade lá = tabela no banco.
- Se encontrar divergência entre modelo e schema, reporte antes de prosseguir.

## Para Cada Tabela, Mostre
1. Campos com tipos PostgreSQL explícitos
2. Primary key, foreign keys, constraints
3. Índices (incluindo partial e exclusion constraints)
4. RLS policy (quem lê, quem escreve, via studio_id ou user_id)
5. Estratégia de partição/TTL se for alto volume

## Checklist de Validação
- [ ] Toda tabela de tenant tem studio_id direto
- [ ] Tabelas com studio_id nullable têm policy OR IS NULL documentada
- [ ] ConsentRecord é append-only (sem UPDATE)
- [ ] AuditLog: INSERT via service_role, SELECT via owner
- [ ] JSON columns têm schema Zod definido
- [ ] Campos monetários em centavos (INTEGER)
- [ ] Periods com tipo explícito (DATE ou INT)
- [ ] Índices críticos do DOMAIN_MODEL.md presentes
- [ ] Exclusion constraint em ranges temporais de Appointment
- [ ] Nenhum SELECT * nos repositories planejados

## Cruzamento
- Compare DOMAIN_MODEL.md com o schema gerado/existente
- Liste: tabelas faltantes, campos divergentes, índices ausentes, RLS não documentada
- Se o schema já existe, mostre diff

## Formato de Saída
Para cada tabela:
```
TABELA: nome
CAMPOS: campo tipo constraint
ÍNDICES: nome (campos) tipo
RLS: policy description
NOTAS: partição, TTL, observações
```

Seja direto. Não explique o que está correto — foque no que falta ou diverge.
