Revise o código alterado neste branch com foco em:

1. Segurança: vulnerabilidades, input não validado, dados expostos, RLS faltando
2. Multi-tenancy: toda query filtra por studio_id? RLS ativo?
3. Performance: N+1 queries, select(*), falta de paginação, índices ausentes
4. Arquitetura: lógica no lugar errado, violação de camadas
5. Testes: regras de negócio sem cobertura
6. Consistência: response shape { data, meta, errors } respeitado?

Para cada problema encontrado, indique:
- Arquivo e linha
- Problema
- Sugestão de correção

Seja direto. Não elogie código correto.
