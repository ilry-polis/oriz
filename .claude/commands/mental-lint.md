Analise o código atual ou a mudança proposta com o seguinte checklist:

ESCALA
- Funciona com 1000 estúdios simultâneos?
- Funciona com 50 agendamentos/dia por estúdio?
- A IA aguenta picos de mensagens WhatsApp?

MULTI-TENANCY
- Toda query filtra por studio_id?
- RLS ativo nas tabelas envolvidas?
- Dados de um estúdio nunca vazam para outro?

ARQUITETURA
- Respeita separação: Route → Controller → Service → Repository?
- Lógica de negócio está no Service?
- Dependências estão na direção correta?

DADOS
- Queries especificam colunas (nunca select *)?
- Tem paginação cursor-based?
- Evita N+1?
- Índices necessários existem?

SEGURANÇA
- Input validado (JSON Schema/Zod)?
- Autorização por role verificada?
- Dados sensíveis protegidos?
- Webhook validado por signature?

COMPLEXIDADE
- Tem solução mais simples?
- Funções têm responsabilidade única?
- O Supabase resolve isso nativamente?

Para cada item com problema: o que está errado, por que é problema, como corrigir.
Seja direto e objetivo.
