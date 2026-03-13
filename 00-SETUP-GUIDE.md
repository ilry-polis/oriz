# Oriz — Guia de Setup Passo a Passo

> Siga cada passo na ordem. Não pule etapas.

---

## PASSO 1 — Criar Repositório no GitHub

### 1.1 Criar o repo no GitHub
1. Acesse https://github.com/new
2. Nome: `oriz`
3. Descrição: "Agenda inteligente para profissionais de beleza"
4. Visibilidade: **Private**
5. Marque: Add a README file
6. .gitignore: **Node**
7. License: escolha a sua (MIT ou proprietary)
8. Clique "Create repository"

### 1.2 Clonar e criar estrutura
```bash
# Clonar
git clone https://github.com/SEU-USUARIO/oriz.git
cd oriz

# Criar estrutura completa (copie e cole tudo de uma vez)
mkdir -p docs/plans
mkdir -p .claude/commands
mkdir -p .claude/rules
mkdir -p .github/workflows
mkdir -p .gemini
mkdir -p backend/src/{controllers,services,repositories,domains,middlewares,config,utils,jobs}
mkdir -p backend/tests
mkdir -p mobile
mkdir -p dashboard
```

### 1.3 Copiar todos os arquivos deste pacote
Copie cada arquivo gerado para a pasta correspondente do repositório.

### 1.4 Primeiro commit
```bash
git add -A
git commit -m "feat: estrutura inicial do AI Engineering OS"
git push origin main
```

---

## PASSO 2 — Instalar Claude Code

### 2.1 Pré-requisitos
```bash
# Node.js 18+ (verificar)
node --version

# Se não tiver, instalar via nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
nvm install 22
nvm use 22
```

### 2.2 Instalar Claude Code
```bash
npm install -g @anthropic-ai/claude-code
```

### 2.3 Iniciar Claude Code no projeto
```bash
cd oriz
claude
```
> Na primeira execução, ele vai pedir para autenticar com sua conta Anthropic.

---

## PASSO 3 — Instalar Plugins no Claude Code

### 3.1 Superpowers (TDD + Brainstorming Socrático)
```bash
# Dentro do Claude Code, execute:
/plugin marketplace add obra/superpowers-marketplace
/plugin install superpowers@superpowers-marketplace
```
**O que faz:** Brainstorming socrático antes de codar, TDD red-green-refactor
obrigatório, code review por subagent, debugging em 4 fases.
**Regra principal:** Se Claude escrever código antes de testes, Superpowers
deleta e força recomeçar.

### 3.2 GSD — Get Shit Done (Gestão de Ciclo de Vida)
```bash
npx get-shit-done-cc --claude --global
```
**O que faz:** Planejamento por milestones, execução em fases, documentação
automática em `.planning/`, progresso rastreado.
**Regra principal:** Divide o trabalho em tarefas pequenas com limites de
tamanho para manter a qualidade.

### 3.3 Awesome (Extensões e Ferramentas)
```bash
# Dentro do Claude Code:
/plugin marketplace add anthropics/awesome-claude-code
/plugin install awesome@awesome-claude-code
```
**O que faz:** Coleção curada de extensões para Claude Code.

### 3.4 UI/UX Pro Max Skill
```bash
# Dentro do Claude Code:
/plugin marketplace add anthropics/uiux-pro-max
/plugin install uiux-pro-max@uiux-pro-max
```
**O que faz:** Design system, componentes UI profissionais, acessibilidade.

### 3.5 Claude Mem (Memória Persistente)
```bash
# Dentro do Claude Code:
/plugin marketplace add anthropics/claude-mem
/plugin install claude-mem@claude-mem
```
**O que faz:** Memória persistente entre sessões do Claude Code.

> **IMPORTANTE:** As skills/plugins podem ter nomes ou repositórios ligeiramente
> diferentes. Se algum comando falhar, pesquise no marketplace:
> `/plugin marketplace search [nome]`

---

## PASSO 4 — Configurar Stack do Backend

### 4.1 Iniciar projeto Node.js
```bash
cd backend

# Iniciar package.json
npm init -y

# Dependências principais
npm install fastify @fastify/cors @fastify/helmet @fastify/rate-limit
npm install @supabase/supabase-js
npm install ioredis bullmq
npm install langchain @langchain/anthropic @langchain/community
npm install zod dotenv pino

# Dependências de desenvolvimento
npm install -D typescript @types/node tsx vitest
npm install -D eslint prettier
npm install -D @biomejs/biome

# Iniciar TypeScript
npx tsc --init
```

### 4.2 Configurar tsconfig.json
```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "ESNext",
    "moduleResolution": "bundler",
    "lib": ["ES2022"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "tests"]
}
```

### 4.3 Configurar scripts no package.json
```json
{
  "scripts": {
    "dev": "tsx watch src/server.ts",
    "build": "tsc",
    "start": "node dist/server.js",
    "test": "vitest run",
    "test:watch": "vitest",
    "lint": "biome check .",
    "lint:fix": "biome check --write .",
    "format": "biome format --write ."
  }
}
```

---

## PASSO 5 — Configurar Supabase

### 5.1 Criar projeto no Supabase
1. Acesse https://supabase.com/dashboard
2. Clique "New project"
3. Nome: `oriz`
4. Senha do banco: gere uma senha forte e salve
5. Região: escolha a mais próxima dos seus usuários
6. Clique "Create new project"

### 5.2 Pegar as chaves
1. Vá em Settings → API
2. Copie:
   - `Project URL` → vai no .env como SUPABASE_URL
   - `anon public` → vai no .env como SUPABASE_ANON_KEY
   - `service_role` → vai no .env como SUPABASE_SERVICE_KEY (NUNCA expor no client)

### 5.3 Criar .env no backend
```bash
# backend/.env
SUPABASE_URL=https://xxxx.supabase.co
SUPABASE_ANON_KEY=eyJhbG...
SUPABASE_SERVICE_KEY=eyJhbG...
REDIS_URL=redis://localhost:6379
ANTHROPIC_API_KEY=sk-ant-...
PORT=3000
NODE_ENV=development
```

### 5.4 Adicionar .env ao .gitignore
```bash
echo ".env" >> ../.gitignore
echo ".env.local" >> ../.gitignore
```

---

## PASSO 6 — Configurar Flutter (Mobile)

### 6.1 Criar projeto Flutter
```bash
cd ../mobile
flutter create --org com.oriz --project-name oriz .
```

### 6.2 Dependências essenciais
```bash
flutter pub add supabase_flutter
flutter pub add flutter_riverpod
flutter pub add go_router
flutter pub add dio
flutter pub add intl
flutter pub add cached_network_image
```

---

## PASSO 7 — Primeiro Teste de Sanidade

### 7.1 Verificar backend
```bash
cd ../backend
npm run dev
# Deve iniciar sem erros na porta 3000
```

### 7.2 Verificar Claude Code
```bash
cd ..
claude
# Digite: "Leia o CLAUDE.md e confirme que entendeu o projeto"
```

### 7.3 Verificar Superpowers
```bash
# Dentro do Claude Code:
/superpowers
# Deve mostrar o menu do plugin
```

---

## PASSO 8 — Começar o Desenvolvimento

### Fluxo conforme AI Engineering OS Guide:
1. Use `/plan [feature]` para criar plano antes de codar
2. Mental Linting roda automaticamente (está no CLAUDE.md)
3. Superpowers força TDD — testes primeiro, código depois
4. Use `/review` antes de abrir PR
5. Use `/mental-lint` para auditoria profunda
6. Abra PR → Gemini Code Assist faz review automático
7. Você aprova e faz merge

---

## Checklist de Verificação

- [ ] Repositório criado no GitHub
- [ ] Estrutura de pastas completa
- [ ] CLAUDE.md na raiz
- [ ] Todos os arquivos de rules e commands copiados
- [ ] Claude Code instalado e autenticado
- [ ] Superpowers instalado
- [ ] GSD instalado
- [ ] Backend rodando com Fastify
- [ ] Supabase configurado com chaves no .env
- [ ] Flutter project criado
- [ ] Primeiro commit enviado
