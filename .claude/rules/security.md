# Segurança — Sempre Ativa

## Checklist Obrigatório
- Validação de entrada em todo boundary (Zod no backend, form validators no Flutter)
- Supabase RLS ativo em TODAS as tabelas — sem exceção
- Toda query filtra por studio_id (multi-tenant)
- Autorização por role verificada em cada endpoint
- Dados sensíveis nunca em logs (telefone de cliente, tokens, senhas)
- Rate limiting em APIs públicas e webhooks
- CORS configurado para domínios específicos
- Tokens JWT com expiração adequada (1h access, 7d refresh)

## LGPD
- Consentimento explícito para marketing (opt-in)
- Endpoint de exclusão de dados sob pedido do cliente
- Dados de pagamento NUNCA armazenados (delegados ao gateway)
- Logs de acesso a dados de clientes

## Proibido
- Secrets hardcoded no código; usar variáveis de ambiente
- Endpoints sem autenticação (exceto: health check, webhook WhatsApp com signature, página pública)
- Retornar stack traces em produção; logar internamente
- select('*') em qualquer query — sempre especificar colunas
- Armazenar senhas em texto plano (Supabase Auth cuida disso)
