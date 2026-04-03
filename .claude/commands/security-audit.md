Execute uma auditoria de segurança completa no código atual:

1. RLS (Row Level Security)
   - Todas as tabelas do Supabase têm RLS ativado?
   - Policies estão corretas para cada role (owner, professional, client)?
   - Teste: um profissional consegue ver dados de outro estúdio?

2. Autenticação
   - Todos os endpoints (exceto públicos listados) exigem JWT?
   - Token refresh está implementado?
   - Logout invalida sessão?

3. Autorização
   - Owner pode tudo no seu estúdio?
   - Professional só acessa o que é permitido?
   - Client só vê seus próprios dados?

4. Input Validation
   - Todo endpoint valida input com JSON Schema ou Zod?
   - Campos obrigatórios estão marcados?
   - Limites de tamanho definidos?

5. Dados Sensíveis
   - Logs não contêm PII?
   - .env não está no git?
   - Secrets não estão hardcoded?

6. APIs Externas
   - Webhook WhatsApp valida signature?
   - Rate limiting configurado?
   - Timeout em chamadas externas?

7. LGPD
   - Consentimento para marketing é opt-in?
   - Existe endpoint de exclusão de dados?
   - Dados de pagamento não são armazenados?

Para cada vulnerabilidade: gravidade (alta/média/baixa), impacto, como corrigir.
