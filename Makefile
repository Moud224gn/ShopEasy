# ShopEasy Makefile
# See CLAUDE.md §5 for documentation
#
# Compatible: GNU Make 4+, Git Bash MINGW, POSIX shells
# Avoid: bash-isms ([[ ]]), $'...' quoting, echo -e

.PHONY: help setup dev dev-down dev-api dev-web logs \
        test test-api test-web test-e2e test-a11y test-i18n test-rtl test-mutation test-watch \
        lint format typecheck security \
        migrate migration shell-db shell-api \
        seed reset-db \
        i18n-extract i18n-check a11y-audit perf-audit \
        pre-push pre-push-fast \
        build deploy-staging \
        clean

# ==============================================================================
# Variables
# ==============================================================================

UV := uv
PNPM := pnpm
DOCKER_COMPOSE := docker compose
API_DIR := apps/api
WEB_DIR := apps/web

# Colors (POSIX compatible)
CYAN := \033[36m
GREEN := \033[32m
YELLOW := \033[33m
RED := \033[31m
RESET := \033[0m

# ==============================================================================
# Default target
# ==============================================================================

.DEFAULT_GOAL := help

# ==============================================================================
# Help
# ==============================================================================

help:
	@printf "$(CYAN)ShopEasy$(RESET) - Available commands\n"
	@printf "\n"
	@printf "$(GREEN)Setup:$(RESET)\n"
	@printf "  make setup            Install all dependencies (uv + pnpm)\n"
	@printf "  make clean            Remove build artifacts and caches\n"
	@printf "\n"
	@printf "$(GREEN)Development:$(RESET)\n"
	@printf "  make dev              Start Docker dev stack (postgres, redis, etc.)\n"
	@printf "  make dev-down         Stop Docker dev stack\n"
	@printf "  make dev-api          Run Django development server\n"
	@printf "  make dev-web          Run Next.js development server\n"
	@printf "  make logs             Stream Docker logs\n"
	@printf "\n"
	@printf "$(GREEN)Testing:$(RESET)\n"
	@printf "  make test             Run all tests (API + Web)\n"
	@printf "  make test-api         Run Python tests (pytest)\n"
	@printf "  make test-web         Run JavaScript tests (vitest)\n"
	@printf "  make test-watch       Run tests in watch mode\n"
	@printf "  make test-e2e         Run E2E tests (Playwright)\n"
	@printf "  make test-a11y        Run accessibility tests (axe-core)\n"
	@printf "  make test-i18n        Run i18n completeness tests\n"
	@printf "  make test-rtl         Run RTL visual regression tests\n"
	@printf "  make test-mutation    Run mutation tests (mutmut)\n"
	@printf "\n"
	@printf "$(GREEN)Quality:$(RESET)\n"
	@printf "  make lint             Run all linters\n"
	@printf "  make format           Auto-format all code\n"
	@printf "  make typecheck        Run type checkers (mypy + tsc)\n"
	@printf "  make security         Run security scans (bandit, trivy)\n"
	@printf "  make i18n-extract     Extract new i18n keys\n"
	@printf "  make i18n-check       Check i18n completeness\n"
	@printf "  make a11y-audit       Run Lighthouse accessibility audit\n"
	@printf "  make perf-audit       Run performance audit\n"
	@printf "\n"
	@printf "$(GREEN)Database:$(RESET)\n"
	@printf "  make migrate          Run Django migrations\n"
	@printf "  make migration        Generate new migration (name=<name>)\n"
	@printf "  make shell-db         Open psql shell in container\n"
	@printf "  make shell-api        Open Django shell\n"
	@printf "  make seed             Load development fixtures\n"
	@printf "  make reset-db         Drop, recreate, migrate, seed (destructive)\n"
	@printf "\n"
	@printf "$(GREEN)Validation:$(RESET)\n"
	@printf "  make pre-push         Full CI simulation (~3-5 min)\n"
	@printf "  make pre-push-fast    Quick validation (~1 min)\n"
	@printf "\n"
	@printf "$(GREEN)Build/Deploy:$(RESET)\n"
	@printf "  make build            Build production artifacts\n"
	@printf "  make deploy-staging   Deploy to staging (CI only)\n"
	@printf "\n"

# ==============================================================================
# Setup
# ==============================================================================

setup:
	@printf "$(CYAN)Installing Python dependencies (uv)...$(RESET)\n"
	cd $(API_DIR) && $(UV) sync --group dev
	@printf "$(CYAN)Installing Node dependencies (pnpm)...$(RESET)\n"
	cd $(WEB_DIR) && $(PNPM) install
	@printf "$(CYAN)Setting up environment...$(RESET)\n"
	@if [ ! -f .env ]; then \
		cp .env.example .env; \
		printf "$(GREEN)Created .env from .env.example$(RESET)\n"; \
	else \
		printf "$(YELLOW).env already exists, skipping$(RESET)\n"; \
	fi
	@printf "$(GREEN)Setup complete!$(RESET)\n"
	@printf "Next steps:\n"
	@printf "  1. Edit .env with your settings\n"
	@printf "  2. Run 'make dev' to start the Docker stack\n"
	@printf "  3. Run 'make dev-api' and 'make dev-web' in separate terminals\n"

clean:
	@printf "$(CYAN)Cleaning build artifacts...$(RESET)\n"
	rm -rf $(WEB_DIR)/node_modules
	rm -rf $(WEB_DIR)/.next
	rm -rf $(WEB_DIR)/coverage
	rm -rf $(API_DIR)/.venv
	rm -rf $(API_DIR)/.pytest_cache
	rm -rf $(API_DIR)/.mypy_cache
	rm -rf $(API_DIR)/.ruff_cache
	rm -rf $(API_DIR)/htmlcov
	rm -rf $(API_DIR)/.coverage
	rm -f .pre-push-pass
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	@printf "$(GREEN)Clean complete!$(RESET)\n"

# ==============================================================================
# Development
# ==============================================================================

dev:
	@printf "$(RED)Not implemented yet$(RESET) - Requires docker-compose.yml (Sprint 1 issue #2)\n"
	@printf "Run 'make dev-api' and 'make dev-web' separately for now.\n"
	@exit 1

dev-down:
	@printf "$(RED)Not implemented yet$(RESET) - Requires docker-compose.yml (Sprint 1 issue #2)\n"
	@exit 1

dev-api:
	@printf "$(CYAN)Starting Django development server...$(RESET)\n"
	cd $(API_DIR) && $(UV) run python manage.py runserver

dev-web:
	@printf "$(CYAN)Starting Next.js development server...$(RESET)\n"
	cd $(WEB_DIR) && $(PNPM) dev

logs:
	@printf "$(RED)Not implemented yet$(RESET) - Requires docker-compose.yml (Sprint 1 issue #2)\n"
	@exit 1

# ==============================================================================
# Testing
# ==============================================================================

test: test-api test-web
	@printf "$(GREEN)All tests passed!$(RESET)\n"

test-api:
	@printf "$(CYAN)Running Python tests...$(RESET)\n"
	cd $(API_DIR) && $(UV) run pytest

test-web:
	@printf "$(CYAN)Running JavaScript tests...$(RESET)\n"
	cd $(WEB_DIR) && $(PNPM) test run

test-watch:
	@printf "$(CYAN)Running tests in watch mode...$(RESET)\n"
	cd $(WEB_DIR) && $(PNPM) test

test-e2e:
	@printf "$(RED)Not implemented yet$(RESET) - Requires Playwright setup (Sprint 2)\n"
	@exit 1

test-a11y:
	@printf "$(RED)Not implemented yet$(RESET) - Requires axe-core setup (Sprint 3)\n"
	@exit 1

test-i18n:
	@printf "$(RED)Not implemented yet$(RESET) - Requires i18n-check script (Sprint 3)\n"
	@exit 1

test-rtl:
	@printf "$(RED)Not implemented yet$(RESET) - Requires RTL snapshots (Sprint 3)\n"
	@exit 1

test-mutation:
	@printf "$(RED)Not implemented yet$(RESET) - Requires mutmut config (Sprint 3)\n"
	@exit 1

# ==============================================================================
# Quality
# ==============================================================================

lint:
	@printf "$(CYAN)Linting Python code (ruff)...$(RESET)\n"
	cd $(API_DIR) && $(UV) run ruff check .
	@printf "$(CYAN)Linting TypeScript code (eslint + prettier)...$(RESET)\n"
	cd $(WEB_DIR) && $(PNPM) lint
	@printf "$(GREEN)Lint passed!$(RESET)\n"

format:
	@printf "$(CYAN)Formatting Python code (ruff)...$(RESET)\n"
	cd $(API_DIR) && $(UV) run ruff format .
	cd $(API_DIR) && $(UV) run ruff check --fix .
	@printf "$(CYAN)Formatting TypeScript code (prettier)...$(RESET)\n"
	cd $(WEB_DIR) && $(PNPM) lint:fix
	@printf "$(GREEN)Format complete!$(RESET)\n"

typecheck:
	@printf "$(CYAN)Type checking Python (mypy)...$(RESET)\n"
	cd $(API_DIR) && $(UV) run mypy .
	@printf "$(CYAN)Type checking TypeScript (tsc)...$(RESET)\n"
	cd $(WEB_DIR) && $(PNPM) typecheck
	@printf "$(GREEN)Type check passed!$(RESET)\n"

security:
	@printf "$(RED)Not implemented yet$(RESET) - Requires bandit + trivy setup (Sprint 2)\n"
	@exit 1

i18n-extract:
	@printf "$(RED)Not implemented yet$(RESET) - Requires i18n tooling (Sprint 3)\n"
	@exit 1

i18n-check:
	@printf "$(RED)Not implemented yet$(RESET) - Requires i18n-check script (Sprint 3)\n"
	@exit 1

a11y-audit:
	@printf "$(RED)Not implemented yet$(RESET) - Requires Lighthouse CLI (Sprint 3)\n"
	@exit 1

perf-audit:
	@printf "$(RED)Not implemented yet$(RESET) - Requires Lighthouse + bundle analyzer (Sprint 3)\n"
	@exit 1

# ==============================================================================
# Database
# ==============================================================================

migrate:
	@printf "$(RED)Not implemented yet$(RESET) - Requires docker-compose.yml (Sprint 1 issue #2)\n"
	@exit 1

migration:
	@printf "$(RED)Not implemented yet$(RESET) - Requires docker-compose.yml (Sprint 1 issue #2)\n"
	@exit 1

shell-db:
	@printf "$(RED)Not implemented yet$(RESET) - Requires docker-compose.yml (Sprint 1 issue #2)\n"
	@exit 1

shell-api:
	@printf "$(CYAN)Opening Django shell...$(RESET)\n"
	cd $(API_DIR) && $(UV) run python manage.py shell

seed:
	@printf "$(RED)Not implemented yet$(RESET) - Requires user models (Sprint 2)\n"
	@exit 1

reset-db:
	@printf "$(RED)Not implemented yet$(RESET) - Requires seed (Sprint 2)\n"
	@exit 1

# ==============================================================================
# Validation (CLAUDE.md §12)
# ==============================================================================

pre-push-fast:
	@printf "$(CYAN)Running quick validation...$(RESET)\n"
	@printf "\n$(CYAN)[1/2] Lint$(RESET)\n"
	@$(MAKE) lint
	@printf "\n$(CYAN)[2/2] Typecheck$(RESET)\n"
	@$(MAKE) typecheck
	@printf "\n$(GREEN)Quick validation passed!$(RESET)\n"
	@printf "$(YELLOW)Note: Run 'make pre-push' for full validation before pushing.$(RESET)\n"

pre-push:
	@printf "$(CYAN)Running full CI simulation...$(RESET)\n"
	@printf "$(YELLOW)This may take 3-5 minutes.$(RESET)\n"
	@printf "\n$(CYAN)[1/4] Lint$(RESET)\n"
	@$(MAKE) lint
	@printf "\n$(CYAN)[2/4] Typecheck$(RESET)\n"
	@$(MAKE) typecheck
	@printf "\n$(CYAN)[3/4] Tests (API)$(RESET)\n"
	@$(MAKE) test-api
	@printf "\n$(CYAN)[4/4] Tests (Web)$(RESET)\n"
	@$(MAKE) test-web
	@printf "\n$(GREEN)========================================$(RESET)\n"
	@printf "$(GREEN)Pre-push validation PASSED$(RESET)\n"
	@printf "$(GREEN)========================================$(RESET)\n"
	@printf "\n$(YELLOW)Note: The following checks will be added in future sprints:$(RESET)\n"
	@printf "  - test-a11y (Sprint 3)\n"
	@printf "  - test-i18n (Sprint 3)\n"
	@printf "  - test-rtl (Sprint 3)\n"
	@printf "  - security (Sprint 2)\n"
	@printf "  - perf-audit (Sprint 3)\n"
	@printf "\n"
	@date -Iseconds > .pre-push-pass
	@printf "$(GREEN)Marker .pre-push-pass created.$(RESET)\n"
	@printf "You may now 'git push'.\n"

# ==============================================================================
# Build / Deploy
# ==============================================================================

build:
	@printf "$(CYAN)Building Next.js production bundle...$(RESET)\n"
	cd $(WEB_DIR) && $(PNPM) build
	@printf "$(GREEN)Build complete!$(RESET)\n"
	@printf "$(YELLOW)Note: Docker image builds will be added in Sprint 1 issue #2.$(RESET)\n"

deploy-staging:
	@printf "$(RED)Not implemented yet$(RESET) - Requires Terraform/K8s (Sprint 13+)\n"
	@exit 1
