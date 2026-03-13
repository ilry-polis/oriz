# Mental Linting — Regra Global

## Antes de implementar qualquer funcionalidade
- Pensar na abordagem ANTES de escrever código
- Avaliar trade-offs de performance, segurança e manutenibilidade
- Verificar se a solução respeita as camadas (Route → Controller → Service → Repository)
- Confirmar que não existe duplicação de lógica no projeto
- Verificar multi-tenancy: studio_id está presente?

## Antes de qualquer query ao banco
- Verificar se já existe query similar reutilizável no repository
- Confirmar que tem filtro por studio_id
- Confirmar que tem paginação (cursor-based)
- Confirmar que especifica colunas (nunca select *)
- Avaliar necessidade de índice
- Verificar se não cria N+1

## Antes de qualquer endpoint
- Validação de input definida (JSON Schema ou Zod)?
- Autorização por role verificada?
- Rate limiting necessário?
- Response shape consistente ({ data, meta, errors })?
- RLS configurado na tabela?

## Antes de qualquer job assíncrono
- Timeout definido?
- Retry policy definida?
- Dead letter queue configurada?
- Rate limiting para APIs externas (WhatsApp, LLM)?

## Se em dúvida
- NÃO implementar
- Apresentar as opções com trade-offs
- Aguardar decisão do usuário
