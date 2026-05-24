# ShopEasy

> Multi-vendor e-commerce platform engineered for international scale, built with strict production-grade discipline.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Code Style: Ruff](https://img.shields.io/badge/code%20style-ruff-000000.svg)](https://github.com/astral-sh/ruff)
[![TypeScript](https://img.shields.io/badge/TypeScript-strict-3178C6.svg)](https://www.typescriptlang.org/)

ShopEasy is a multi-vendor e-commerce platform designed from day one for **international markets** (Canada, EU francophone, Maghreb, West/East Africa, South Africa) with **WCAG 2.1 AA accessibility**, **multi-currency**, and **RTL-ready architecture** as foundational requirements — not afterthoughts.

This is a portfolio-grade project. Every architectural decision is documented in [`docs/adr/`](docs/adr/). Every convention is enforced via CI gates.

---

## Vision

Build an e-commerce platform that:

- Scales to **1M+ users** without architectural rewrite
- Supports **multi-locale and multi-currency** transactions natively
- Meets **WCAG 2.1 AA** from the first rendered pixel
- Complies with **GDPR (EU), Loi 25 (Quebec), PIPEDA (Canada), POPIA (South Africa), NDPR (Nigeria), DPA (Kenya), Loi 09-08 (Morocco)**
- Deploys to **multi-cloud Kubernetes** (AWS production, GCP staging) with cloud-agnostic Terraform modules
- Is operated with **observability-first** principles (logs/metrics/traces from day one)

## Tech Stack

### Frontend (`apps/web`)

- **Next.js 15** with App Router and Server Components
- **React 18** + **TypeScript 5** (strict mode)
- **Tailwind CSS** with `tailwindcss-rtl` for RTL locale support
- **shadcn/ui** for accessible component primitives
- **next-intl** for internationalization (FR + EN at Sprint 1, AR/ES/PT/SW ready)
- **dinero.js v2** for multi-currency money handling
- **TanStack Query v5** for server state
- **Zustand** for client state
- **next-pwa** for offline-first experience (critical for emerging markets)
- **Vitest** + **Playwright** + **MSW** + **axe-core** for testing

### Backend (`apps/api`)

- **Django 5.2 LTS** with **Django REST Framework**
- **Python 3.13** managed by **uv**
- **PostgreSQL 17** with **Redis 7.4** for cache and Celery broker
- **Celery 5** for async tasks (notifications, exchange rates refresh, exports)
- **Argon2id** for password hashing
- **JWT** authentication (15min access + 7d refresh with rotation, httpOnly cookies)
- **py-moneyed** for currency-safe money operations
- **drf-spectacular** for OpenAPI 3.1 documentation
- **pytest** + **mutmut** + **ruff** + **mypy --strict**

### Infrastructure (`infrastructure/`)

- **Docker** multi-stage builds, non-root containers, Trivy-scanned
- **Kubernetes** with **Kustomize** overlays (base + staging + production)
- **Terraform** modules cloud-agnostic (AWS EKS for prod, GCP GKE for staging)
- **GitHub Actions** CI/CD with OIDC trust (no long-lived cloud credentials)
- **Sentry** for errors, **OpenTelemetry → Grafana** stack for metrics/traces/logs
- **External Secrets Operator** synchronizing from AWS Secrets Manager / GCP Secret Manager

## Architecture

ShopEasy starts as a **modular monolith** with strict app boundaries, prepared for service extraction without rewrites. See [ADR-0001](docs/adr/0001-stack-technologique.md) for the full rationale.

### Backend modules

```
apps/api/shopeasy/
├── catalog/        # Products, categories, variants
├── search/         # Full-text search (extracted to FastAPI in Sprint 8)
├── cart/           # Cart and pricing
├── orders/         # Order lifecycle, status machine
├── users/          # Auth, profiles, RBAC
├── vendors/        # Vendor management, payouts
├── payments/       # Payment integration, refunds (mocked initially)
├── notifications/  # Emails, push, in-app (extracted to FastAPI in Sprint 9)
├── analytics/      # Aggregations, reports
├── audit/          # Immutable audit log
├── i18n/           # Currencies, exchange rates, locales
└── core/           # Shared utilities, base models
```

### Frontend structure

```
apps/web/src/
├── app/[locale]/   # Localized routes (next-intl)
├── components/     # UI components (shadcn/ui base)
├── lib/            # Utilities, API clients
├── messages/       # i18n JSON files (fr/, en/, ...)
└── stores/         # Zustand stores
```

## Quick Start

> Full instructions in `docs/setup.md` once Sprint 1 ships the Makefile.

```bash
# Clone
git clone git@github.com:Moud224gn/ShopEasy.git
cd ShopEasy

# (Coming in Sprint 1)
make setup       # Install dependencies, init env
make dev         # Start full stack via docker-compose
make pre-push    # Local validation before pushing
```

## Project Discipline

ShopEasy is built with strict discipline that mirrors real production environments:

- **TDD strict**: Tests written before any production code. 85% coverage gate, 75% mutation gate on `payments`/`orders`.
- **Conventional Commits**: Validated via `/commit` workflow (see [CLAUDE.md](CLAUDE.md) §13).
- **Local-first validation**: `make pre-push` runs 10 gates locally (lint, typecheck, tests, a11y, i18n, RTL, security, build, perf) before any push to GitHub.
- **Code review on every PR**, even solo. Self-review via the [`code-reviewer`](.claude/agents/code-reviewer.md) agent.
- **Architecture Decision Records** (ADRs) for every non-trivial decision.
- **No emojis** in code, commits, or documentation.

## Documentation

| Document | Purpose |
|---|---|
| [`CLAUDE.md`](CLAUDE.md) | Senior briefing for AI-assisted development (loaded every session) |
| [`docs/conventions/accessibility.md`](docs/conventions/accessibility.md) | WCAG 2.1 AA conventions |
| [`docs/conventions/i18n.md`](docs/conventions/i18n.md) | Internationalization, RTL, multi-currency |
| [`docs/conventions/security.md`](docs/conventions/security.md) | Security baselines, multi-jurisdiction compliance |
| [`docs/conventions/performance.md`](docs/conventions/performance.md) | Performance budgets, Core Web Vitals |
| [`docs/conventions/gotchas.md`](docs/conventions/gotchas.md) | Project-specific traps and learnings |
| [`docs/adr/`](docs/adr/) | Architecture Decision Records |

## Status

**Currently**: Phase 0 — Foundation. Architecture, conventions, and AI tooling are in place. Sprint 1 begins implementation.

**Roadmap** (15 weeks):
- Sprint 1-2: Foundations (CI/CD, Makefile, base apps, first endpoint)
- Sprint 3-4: User accounts, authentication, RBAC
- Sprint 5-6: Catalog, search, vendor onboarding
- Sprint 7-8: Cart, orders, pricing, payments (mocked)
- Sprint 9-10: Notifications, observability, performance polish
- Sprint 11-12: Internationalization expansion (AR, ES, PT, SW), accessibility audit
- Sprint 13-14: Production deployment, load testing, monitoring
- Sprint 15: Documentation, demo preparation

## Context

This project is developed in the context of **INF1763** (Techniques et outils professionnels de développement logiciel) at **UQO**, but engineered as a portfolio-grade artifact. Documentation primarily in French to match the academic context, with code, commits, and public-facing documentation in English.

## License

MIT — see [LICENSE](LICENSE).

## Author

Mamoudou Diallo — [diam657@uqo.ca](mailto:diam657@uqo.ca)
