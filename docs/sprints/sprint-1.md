# Sprint 1 — Technical Foundations

- **Periode** : Juin 2026 (2 semaines)
- **Sprint Goal** : Livrer une infrastructure de developpement fonctionnelle : monorepo operationnel avec API Django, frontend Next.js, stack Docker locale, hooks de qualite, et fondations transversales (i18n, multi-currency, securite) en place.
- **Velocite cible** : ~32h (solo dev + Claude Code)
- **Statut** : Planning

---

## Stories engagees

| # | Titre | Labels | Est. | Priorite |
|---|-------|--------|------|----------|
| [#1](https://github.com/Moud224gn/ShopEasy/issues/1) | Monorepo skeleton + Makefile foundation | infra | M | P0 |
| [#2](https://github.com/Moud224gn/ShopEasy/issues/2) | Docker Compose stack + multi-stage Dockerfiles | infra, docker | M | P0 |
| [#3](https://github.com/Moud224gn/ShopEasy/issues/3) | First /health endpoint (API) and / route (web) | frontend, backend | S | P0 |
| [#4](https://github.com/Moud224gn/ShopEasy/issues/4) | Git pre-commit hooks (CLAUDE.md §12 layer 1) | dx | S | P1 |

---

## Stretch goal

| # | Titre | Labels | Est. | Priorite stretch |
|---|-------|--------|------|------------------|
| [#5](https://github.com/Moud224gn/ShopEasy/issues/5) | Minimal CI pipeline (lint, typecheck, test) | ci-cd | M | 1er |

Justification : CI necessaire pour activer les required status checks des branch protections.

---

## Fondations transversales (#3)

### Frontend (apps/web)

| Fondation | Statut Sprint 1 |
|-----------|-----------------|
| next-intl | Configure : FR (defaut) + EN, routing `/[locale]` |
| dinero.js v2 | Installe dans package.json, importe dans `lib/currency.ts` (stub) |
| tailwindcss-rtl | Installe dans tailwind.config.ts, pas active (plugin present, pret pour AR) |
| Logical properties CSS | Utilisees des le premier composant |

### Backend (apps/api)

| Fondation | Statut Sprint 1 |
|-----------|-----------------|
| py-moneyed | Installe dans pyproject.toml, importe dans `core/money.py` (stub) |
| Argon2id | Configure dans `PASSWORD_HASHERS` (1er de la liste), meme sans modele User |
| gettext | Configure (`LANGUAGE_CODE`, `LANGUAGES`, `LOCALE_PATHS`) |
| JWT structure | SimpleJWT installe, settings prepares (pas de endpoints auth) |

### Tests minimaux

| Endpoint | Framework | Couverture |
|----------|-----------|------------|
| `/health` | pytest + pytest-cov | Activee |
| `/`, `/fr`, `/en` | vitest + @testing-library/react | Activee |

---

## Ordre d'implementation

```
#1 (Monorepo + Makefile)
    └──> #2 (Docker Compose + Dockerfiles)
             └──> #3 (/health + / + fondations transversales + tests)
                      └──> #4 (Pre-commit hooks)
                               └──> #5 (CI pipeline) [stretch]
```

---

## Decisions confirmees (ADR-0001)

- **Python 3.13** : verrouille
- **Next.js 15** : verrouille

---

## Specs a rediger

| Issue | Spec | Raison |
|-------|------|--------|
| #3 | `docs/specs/s1-health-endpoint.md` | Config Django + Next.js i18n + fondations transversales |

---

## ADRs potentielles

| Decision | Declencheur | ADR # |
|----------|-------------|-------|
| Pre-commit framework (pre-commit Python vs husky) | #4 | ADR-0002 |
| Structure settings Django (split vs monolithe) | #3 | ADR-0003 |

---

## Risques techniques

| Risque | Impact | Mitigation |
|--------|--------|------------|
| Python 3.13 + deps incompatibles | Bloquant | Time-box 2h, fallback investigation |
| Next.js 15 + next-intl integration | Majeur | Suivre docs officiels v3 |
| uv sur Windows | Modere | Documenter workarounds |
| .pre-push-pass marker sous Git Bash MINGW | Modere | Tester skip-worktree comportement, documenter divergence Unix si necessaire |
| Conventional Commits validation pre-commit | Mineur | Configurer commitlint ou commitizen, tester avec messages FR et EN |

---

## Definition of Done

Voir CLAUDE.md §18 — chaque issue est Done quand :

- [ ] TDD respecte (tests avant code)
- [ ] `make lint` + `make typecheck` passent
- [ ] Coverage >= 85% (sauf #3 : endpoint trivial, coverage basse OK)
- [ ] `make i18n-check` passe (FR + EN)
- [ ] Fondations transversales en place (#3)
- [ ] Commit valide par l'utilisateur (§13)

---

## Hors scope (Sprint 2+)

- Modeles users/auth complets
- Endpoints auth JWT
- Tests E2E Playwright
- PWA / Service Worker
- Sentry / OpenTelemetry
- shadcn/ui components
- Celery

---

## Retrospective

_A completer en fin de sprint._
