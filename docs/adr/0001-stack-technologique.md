# ADR-0001 : Stack technologique et architecture fondatrice de ShopEasy

- **Statut** : Accepté
- **Date** : 2026-05-24
- **Auteur** : Moud224gn (en collaboration avec architecte senior — sessions Phase 0)
- **Remplace** : —
- **Remplacée par** : —

## Contexte

ShopEasy est une plateforme e-commerce multi-vendeurs conçue pour des marchés internationaux (Canada, UE francophone, Maghreb, Afrique de l'Ouest, Afrique de l'Est, Afrique du Sud). Le projet sert deux objectifs simultanés :

1. **Académique** : projet de session du cours INF1763 (UQO) — démontrer la maîtrise des outils DevOps, méthodes agiles, qualité logicielle.
2. **Portfolio** : artefact public démontrant un niveau d'ingénierie senior aux recruteurs.

Ces deux objectifs convergent : le projet doit être **production-grade, scalable à 1M+ utilisateurs, maintenable à long terme**, conforme à des exigences réelles d'industrie.

Plutôt que prendre des décisions ad hoc en cours de route, la **Phase 0** a été dédiée à fixer en bloc les choix structurants : stack, architecture, conventions, outillage AI-assisted (Claude Code), discipline opérationnelle. Cette ADR formalise l'ensemble de ces décisions et leur justification.

### Contraintes fixées

1. **Internationalisation native** : FR + EN livrés au Sprint 1, architecture prête pour AR (RTL), ES, PT, SW sans refactor du code applicatif.
2. **Multi-currency native** : CAD/USD/EUR au Sprint 1, ajout de devises (XAF, XOF, NGN, KES, MAD, ZAR, etc.) sans refactor.
3. **Accessibilité WCAG 2.1 AA** dès le premier rendu, vérifiée en CI.
4. **Conformité multi-juridiction** : RGPD (UE), Loi 25 (Québec), PIPEDA (Canada), POPIA (Afrique du Sud), NDPR (Nigeria), DPA (Kenya), Loi 09-08 (Maroc).
5. **Solo developer** assisté par Claude Code — la discipline doit compenser l'absence d'équipe.
6. **Budget cloud limité** (~400 CAD/mois maximum projeté) — pas d'over-engineering.
7. **15 semaines** de calendrier (session universitaire).
8. **Public dès le départ** — code ouvert, aucun secret en historique Git.

## Décision

ShopEasy adopte la stack et l'architecture décrites ci-dessous, verrouillées pour toute la durée du projet. Tout changement futur de ces décisions requiert une nouvelle ADR documentée.

### Frontend

| Composant | Choix | Version |
|---|---|---|
| Framework | **Next.js** App Router + Server Components | 15.x |
| Library UI | React | 18.x |
| Langage | **TypeScript strict** | 5.x |
| Styling | **Tailwind CSS** + `tailwindcss-rtl` | 3.4+ |
| Composants accessibles | **shadcn/ui** (primitives Radix) | latest |
| PWA | `next-pwa` (offline-first) | 5.x |
| State client | **Zustand** | 4.x |
| State serveur | **TanStack Query v5** | 5.x |
| Forms | **react-hook-form** + **Zod** | latest |
| i18n | **next-intl** | 3.x |
| Money | **dinero.js v2** | 2.x |
| Tests unit/intégration | **Vitest** + Testing Library | latest |
| Tests E2E | **Playwright** | latest |
| Mocks réseau | **MSW** | 2.x |
| A11y testing | **axe-core** + `@axe-core/playwright` | latest |
| Package manager | **pnpm** | 9.x |
| Runtime | **Node.js LTS** | 22.x |

### Backend

| Composant | Choix | Version |
|---|---|---|
| Framework | **Django LTS** + Django REST Framework | 5.2 LTS |
| Langage | **Python** | 3.13 |
| Package manager | **uv** | 0.5+ |
| Base de données | **PostgreSQL** | 17 |
| Cache + broker Celery | **Redis** | 7.4 |
| Async tasks | **Celery** | 5.x |
| Auth tokens | `djangorestframework-simplejwt` (rotation activée) | latest |
| Password hashing | **Argon2id** via `django-argon2` | latest |
| Rate limiting / lockout | **django-axes** | latest |
| OpenAPI | **drf-spectacular** | latest |
| Translations | gettext + **django-rosetta** (admin UI) | latest |
| Money | **py-moneyed** | latest |
| Tests | **pytest** + factory-boy | latest |
| Mutation testing | **mutmut** | latest |
| Linter | **ruff** | latest |
| Type checker | **mypy --strict** | latest |

### Infrastructure

| Composant | Choix |
|---|---|
| Containerisation | **Docker** multi-stage, USER non-root, scan Trivy |
| Orchestration locale | Docker Compose |
| Orchestration cloud | **Kubernetes** avec **Kustomize** (base + overlays staging/prod) |
| Production cloud | **AWS EKS** |
| Staging cloud | **GCP GKE** Autopilot |
| IaC | **Terraform** modules cloud-agnostic (interfaces communes, implémentations AWS/GCP) |
| CI/CD | **GitHub Actions** avec OIDC trust (zéro credentials long-lived) |
| Secrets | **External Secrets Operator** synchronisant depuis AWS Secrets Manager / GCP Secret Manager |
| CDN + edge | **Cloudflare** |
| Errors | **Sentry** (Python SDK + JS SDK) |
| Logs | stdout JSON → **Grafana Loki** via Fluent Bit |
| Métriques | **OpenTelemetry → Prometheus → Grafana** |
| Traces | OpenTelemetry → **Grafana Tempo** |
| Alerting | AlertManager → email (staging) / PagerDuty (prod) |

### Architecture applicative

**Modular monolith** au démarrage, préparé pour extraction de services :

```
apps/api/shopeasy/
├── catalog/        # Produits, catégories, variantes
├── search/         # Recherche full-text (extraction FastAPI Sprint 8)
├── cart/           # Panier, pricing
├── orders/         # Commandes, état machine
├── users/          # Auth, profils, RBAC
├── vendors/        # Gestion vendeurs, payouts
├── payments/       # Intégration paiement (mocked initialement)
├── notifications/  # Emails, push (extraction FastAPI + RabbitMQ Sprint 9)
├── analytics/      # Agrégations, rapports
├── audit/          # Journal immuable append-only
├── i18n/           # Devises, taux de change, locales
└── core/           # Base models, utilitaires partagés
```

**Discipline d'isolation entre apps** : communication via signals Django ou Celery tasks, jamais d'import direct cross-app du code privé. Cette discipline rend l'extraction future de services techniquement triviale.

### Discipline opérationnelle

| Discipline | Détail |
|---|---|
| TDD strict | Tests avant code de production. Coverage gate 85% sur apps métier. Mutation testing 75% sur `payments` et `orders`. |
| Validation locale 3 couches | (1) Git pre-commit hook (<10s) → (2) `make pre-push` complet (3-5min) générant marker `.pre-push-pass` → (3) CI |
| Commits | Conventional Commits, validation explicite utilisateur via `/commit` (CLAUDE.md §13) |
| Branches | `main` (prod), `develop` (intégration), `feature/*`, `fix/*`, `refactor/*` |
| Pas d'emoji | Dans code, commits, doc, réponses |
| Code review | `code-reviewer` agent invoqué via `/review` avant chaque push significatif |
| ADRs | Pour toute décision archi non-triviale |
| Postmortems | Blameless, format Google SRE, archivés dans `docs/postmortems/` |

### Outillage AI-assisted

7 subagents spécialisés (`.claude/agents/`) :
- `architect` (décisions, ADRs, specs)
- `code-reviewer` (review pre-push/PR)
- `test-writer` (TDD strict)
- `security-auditor` (audits sécurité, compliance)
- `accessibility-i18n-auditor` (WCAG, i18n, RTL, multi-currency)
- `performance-optimizer` (profiling, optim mesurée)
- `devops-engineer` (CI/CD, K8s, Terraform, observabilité)

18 slash commands (`.claude/commands/`) orchestrant les workflows quotidiens (`/commit`, `/pre-push`, `/review`, `/tdd`, `/spec`, `/adr`, etc.).

## Alternatives considérées

Plusieurs choix structurants ont fait l'objet d'une évaluation comparative. Les principales alternatives écartées :

### Stack frontend : Vue.js vs Next.js

**Vue.js + Nuxt** considéré pour la simplicité de la courbe d'apprentissage et la qualité de l'écosystème francophone. Écarté au profit de Next.js pour :
- **Demande du marché de l'emploi** : Next.js + React domine les offres senior chez les recruteurs (Canada, UE, US).
- **SEO/Server Components** : avec App Router, le rendu serveur natif favorise le SEO e-commerce.
- **Maturité de l'écosystème** : shadcn/ui, libs i18n et a11y plus matures côté React.

Vue reste un choix valide en absolu — la décision est contextuelle au projet et à l'objectif portfolio.

### State management : Pinia vs Zustand vs Redux Toolkit

**Redux Toolkit** écarté pour boilerplate excessif sur un solo project.
**Pinia** non applicable (lié à Vue).
**Zustand** retenu pour minimalisme, intégration TypeScript naturelle, absence de boilerplate.

### Password hashing : bcrypt vs Argon2id

**bcrypt** : standard historique Django.
**Argon2id** retenu — **gagnant du Password Hashing Competition** (2015), résistant aux GPU/ASIC, recommandé OWASP en première position. Pas de raison de retenir bcrypt sur un projet neuf en 2026.

### Architecture : Monolithe vs Microservices

**Microservices dès le Sprint 1** considéré (split immédiat catalog/cart/orders/notifications/search). Écarté :
- Overhead opérationnel disproportionné pour un solo developer.
- Complexité réseau, gestion des transactions distribuées, observabilité.
- Coût cloud multiplié.
- "You don't need microservices" (Sam Newman, "Building Microservices").

**Modular monolith** retenu : tous les avantages structurels (isolation, testabilité, séparation des responsabilités) sans le coût opérationnel. Extraction des services planifiée pour Sprint 8 (search) et Sprint 9 (notifications) une fois le projet stabilisé.

### Cloud : AWS-only vs GCP-only vs Multi-cloud

**Single cloud** (AWS ou GCP exclusivement) plus simple à opérer. Écarté :
- Risque de lock-in.
- Démontre une compétence multi-cloud à valeur portfolio.
- Crédits gratuits étudiants disponibles sur les deux clouds (économie réelle).

**Multi-cloud avec modules Terraform cloud-agnostic** retenu — AWS production, GCP staging. Les modules ont des interfaces communes et des implémentations spécifiques par cloud. Coût pédagogique justifié, et c'est un sujet recherché chez les recruteurs senior.

### PWA : avec vs sans Service Worker

**Sans PWA** considéré pour simplifier l'initial. Écarté car cible marchés émergents (Afrique, Maghreb) où la connectivité est variable — l'offline-first n'est pas un luxe mais une nécessité utilisateur réelle.

### Mode de développement assisté : sans Claude Code vs avec Claude Code

**Développement sans assistance AI** considéré (approche traditionnelle). Écarté car :
- 1 solo developer sur 15 semaines = vélocité insuffisante pour le scope visé.
- Claude Code permet la délégation contrôlée (tests, reviews, audits) tout en gardant le développeur en position de décision finale.
- La discipline §13 (validation utilisateur sur chaque commit) maintient l'apprentissage et la propriété intellectuelle.

## Justification

Cette ADR fondatrice fait converger plusieurs principes :

### Production-ready dès la première ligne
Chaque outil retenu est utilisé en production par des entreprises servant des millions d'utilisateurs. Pas de tech expérimentale, pas de "boring tech" non plus (Django 5.2 LTS, Next.js 15, PostgreSQL 17 sont stables et modernes). Le mantra du projet : **boring tech first**.

### Scalable à 1M+ utilisateurs
Le modular monolith Django avec PostgreSQL et Redis tient nativement plusieurs centaines de RPS. L'extraction Celery pour le travail asynchrone, l'horizontal scaling K8s, et l'extraction planifiée de services (search, notifications) couvrent la trajectoire 100k → 1M utilisateurs sans rewrite.

### Internationale dès le Sprint 1
Le coût d'introduction de l'i18n et du RTL au Sprint 11-12 sur 200 composants déjà écrits serait de 3-4 semaines. Le coût d'application des conventions (next-intl, logical properties, dinero.js) dès le Sprint 1 est marginal. Décision sans coût supplémentaire.

### Sécurisée dès le Sprint 1
Argon2id, JWT rotation avec httpOnly cookies, External Secrets Operator, audit log immuable, scan Trivy automatique — l'ensemble est introduit en Phase 0 plutôt qu'ajouté en patch.

### Observable dès le Sprint 1
Sentry + OpenTelemetry + Grafana introduits comme services dès le premier déploiement. "An unobservable service in production is a service we cannot operate."

### Discipline solo soutenable
Le `make pre-push` 3 couches + les 7 subagents + les 18 slash commands permettent à un solo developer de maintenir le niveau de discipline d'une équipe de 5. La validation utilisateur sur chaque commit (§13) préserve la propriété intellectuelle et garantit la compréhension du code.

## Conséquences

### Positives
- Stack moderne et demandée sur le marché de l'emploi.
- Architecture extensible géographiquement sans refactor.
- Discipline portable vers tout futur projet ou employeur.
- Coût cloud maîtrisé (~400 CAD/mois projeté).
- Public dès le départ — aucun secret accidentel ne risque de fuiter via historique privé/public switch.
- Outillage AI documenté et versionné — reproductible sur d'autres projets.

### Négatives
- Courbe d'apprentissage initiale élevée (Next.js App Router, Kustomize, External Secrets Operator, Argon2id, etc.). Mitigation : documentation projet (CLAUDE.md + conventions) lue à chaque session.
- Coût cloud non-zéro même en idle (LoadBalancer ALB, RDS minimum). Mitigation : staging GCP partiellement spot, prod scale-to-zero hors heures de pointe envisageable plus tard.
- Discipline `/commit` ralentit le développement initial. Mitigation : c'est intentionnel — sans cette discipline le projet portfolio devient indiscernable d'un projet d'école.
- Multi-cloud double la maintenance Terraform. Mitigation : modules cloud-agnostic limitent la duplication, et l'apprentissage acquis a une valeur portfolio supérieure au coût.

### À surveiller
- Performance perçue mobile sur marchés émergents (3G/4G dégradés). Audit perf en continu via Lighthouse CI.
- Coût cloud réel vs projection (réviser mensuellement).
- Limite de comportement Argon2id en cold-start (latence login). Profiler dès Sprint 3.
- Stabilité du marker `.pre-push-pass` sous Git Bash Windows (skip-worktree comportement).

## Plan de mise en œuvre

### Phase 0 — Foundation (TERMINÉE au moment de cette ADR)
- CLAUDE.md + 5 documents de conventions
- 7 subagents `.claude/agents/`
- 18 slash commands `.claude/commands/`
- `.gitignore`, `README.md`, `LICENSE`, templates `.github/`
- Cette ADR-0001

### Sprint 1 — Infrastructure de base
- Monorepo `apps/api` + `apps/web`
- Makefile complet (toutes commandes documentées dans CLAUDE.md §5)
- `docker-compose.yml` pour stack locale
- Dockerfiles multi-stage frontend et backend
- Premier endpoint `/health` côté API
- Premier endpoint `/` côté web
- CI/CD GitHub Actions de base
- Pre-commit hooks Git

### Sprints 2-15
Voir `README.md` section Status pour la roadmap.

## Critères de réévaluation

Cette ADR doit être réexaminée si :

- Un composant majeur de la stack atteint la fin de support (LTS) avant la fin du projet.
- Le budget cloud projeté est dépassé de 50% (déclenchement audit coûts).
- Une faille de sécurité critique CVE affecte une dépendance majeure.
- Le projet pivote son scope (ajout marché mobile natif, blockchain, etc.).
- Une métrique de performance reste hors budget après 2 sprints d'optimisation (signal d'architecture inadaptée).

Réexamen automatique programmé : **fin Sprint 8** (mi-projet, point de bilan).

## Références

### Documentation projet
- `CLAUDE.md` (briefing session)
- `docs/conventions/accessibility.md`
- `docs/conventions/i18n.md`
- `docs/conventions/security.md`
- `docs/conventions/performance.md`
- `docs/conventions/gotchas.md`

### Documentation externe
- [Next.js 15 App Router](https://nextjs.org/docs)
- [Django 5.2 release notes](https://docs.djangoproject.com/en/5.2/releases/5.2/)
- [PostgreSQL 17](https://www.postgresql.org/docs/17/)
- [OWASP Password Storage Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html) (Argon2id)
- [12-Factor App](https://12factor.net/)
- [Google SRE — Postmortem Culture](https://sre.google/sre-book/postmortem-culture/)
- ["Building Microservices" — Sam Newman](https://samnewman.io/books/building_microservices/) (justification monolithe modulaire)

### Standards et conformité
- [WCAG 2.1 AA](https://www.w3.org/TR/WCAG21/)
- [RGPD](https://eur-lex.europa.eu/eli/reg/2016/679/oj) (UE)
- [Loi 25](https://www.legisquebec.gouv.qc.ca/fr/document/lc/P-39.1) (Québec)
- [PIPEDA](https://www.priv.gc.ca/en/privacy-topics/privacy-laws-in-canada/the-personal-information-protection-and-electronic-documents-act-pipeda/) (Canada)
- [POPIA](https://popia.co.za/) (Afrique du Sud)
- ISO 4217 (codes devises)
- ISO 639-1 (codes langues)
