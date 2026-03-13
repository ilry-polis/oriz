# ============================================
# AI Engineering OS — Makefile
# Stack: Flutter + Node.js/TypeScript
# ============================================

.PHONY: help run run-backend run-mobile run-web run-all stop install install-backend install-mobile install-web test test-backend lint build build-backend build-mobile

# —— Cores para output bonito ——
GREEN  := \033[0;32m
YELLOW := \033[0;33m
CYAN   := \033[0;36m
RESET  := \033[0m

# —— Help (default) ——
help: ## Mostra todos os comandos disponíveis
	@echo ""
	@echo "$(CYAN)🚀 AI Engineering OS — Comandos Disponíveis$(RESET)"
	@echo "$(CYAN)============================================$(RESET)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)make %-18s$(RESET) %s\n", $$1, $$2}'
	@echo ""

# ============================================
# 🏃 RUN — Rodar serviços
# ============================================

run-backend: ## Roda o backend (Node.js)
	@echo "$(GREEN)▶ Iniciando backend...$(RESET)"
	cd backend && npm run dev

run-mobile: ## Roda o app mobile (Flutter)
	@echo "$(GREEN)▶ Iniciando app Flutter...$(RESET)"
	cd mobile && flutter run

run-web: ## Roda o dashboard web
	@echo "$(GREEN)▶ Iniciando web dashboard...$(RESET)"
	cd web && npm run dev

run-all: ## Roda backend + web em paralelo (background)
	@echo "$(GREEN)▶ Iniciando backend + web em paralelo...$(RESET)"
	@cd backend && npm run dev &
	@cd web && npm run dev &
	@echo "$(YELLOW)⚡ Backend e Web rodando em background. Use 'make stop' para parar.$(RESET)"

stop: ## Para todos os processos Node rodando em background
	@echo "$(YELLOW)⏹ Parando processos...$(RESET)"
	@pkill -f "npm run dev" 2>/dev/null || true
	@echo "$(GREEN)✔ Processos parados.$(RESET)"

# ============================================
# 📦 INSTALL — Instalar dependências
# ============================================

install: install-backend install-mobile install-web ## Instala TODAS as dependências

install-backend: ## Instala dependências do backend
	@echo "$(CYAN)📦 Instalando backend...$(RESET)"
	cd backend && npm install

install-mobile: ## Instala dependências do Flutter
	@echo "$(CYAN)📦 Instalando mobile...$(RESET)"
	cd mobile && flutter pub get

install-web: ## Instala dependências do web
	@echo "$(CYAN)📦 Instalando web...$(RESET)"
	cd web && npm install

# ============================================
# 🧪 TEST & LINT
# ============================================

test: ## Roda todos os testes
	@echo "$(CYAN)🧪 Rodando testes...$(RESET)"
	cd backend && npm run test

test-backend: ## Roda testes só do backend
	cd backend && npm run test

lint: ## Roda linter no backend
	cd backend && npm run lint

# ============================================
# 🏗️ BUILD
# ============================================

build-backend: ## Build do backend
	@echo "$(CYAN)🏗️  Build backend...$(RESET)"
	cd backend && npm run build

build-mobile: ## Build do app Flutter (APK)
	@echo "$(CYAN)🏗️  Build mobile (APK)...$(RESET)"
	cd mobile && flutter build apk

build-web: ## Build do dashboard web
	@echo "$(CYAN)🏗️  Build web...$(RESET)"
	cd web && npm run build

build: build-backend build-web ## Build backend + web

# ============================================
# 🔍 CHECK — Validação pré-PR
# ============================================

check: ## Roda lint + test (usar antes de abrir PR)
	@echo "$(CYAN)🔍 Checagem pré-PR...$(RESET)"
	@$(MAKE) lint
	@$(MAKE) test
	@echo "$(GREEN)✔ Tudo certo! Pode abrir o PR.$(RESET)"
