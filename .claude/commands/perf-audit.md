---
description: Lance un audit perf approfondi sur une route, un endpoint, ou une métrique spécifique. Délègue au subagent performance-optimizer. Mesure avant toute optimisation.
argument-hint: "<route | endpoint | métrique>  ex: /catalog, /api/products, LCP, bundle"
allowed-tools: ["Bash", "Read", "Glob", "Grep", "WebSearch", "WebFetch"]
---

# /perf-audit — Audit performance ciblé

Tu déclenches un audit perf par le subagent `performance-optimizer` selon `CLAUDE.md` §10 et `docs/conventions/performance.md`. **Mesure d'abord, optimise ensuite.**

Cible : $ARGUMENTS

## Différence avec `make perf-audit`

- **`make perf-audit`** (commande Make) : vérification automatique des budgets globaux (bundle, Lighthouse). Lancé en CI et `make pre-push`.
- **`/perf-audit <cible>`** (cette commande) : profiling approfondi d'une route ou métrique spécifique. Identifie les bottlenecks, propose optimisations chiffrées.

Si l'utilisateur lance `/perf-audit` sans cible : demande si c'est un check global (suggère `make perf-audit`) ou ciblé (demande la cible).

## Procédure

### Étape 1 — Cadrer la cible

Types de cible :
- **Route frontend** : `/catalog`, `/products/[slug]`, `/checkout` → audit Lighthouse + Web Vitals + bundle.
- **Endpoint API** : `/api/products?category=...`, `/api/checkout` → profiling backend (queries, latence, N+1).
- **Métrique** : `LCP`, `INP`, `CLS`, `bundle`, `p95` → audit centré sur cette métrique sur les routes critiques.
- **Composant** : `ProductCard`, `SearchBar` → React Profiler ciblé.

Affiche :
```
Audit perf déclenché
Cible : <résolu>
Date : <timestamp>
```

### Étape 2 — Délègue au subagent performance-optimizer

Invoque `performance-optimizer` avec contexte précis :

> "Effectue un audit performance sur [cible]. Suis ta méthode standard en 12 étapes : cadrage, baseline mesurée (Lighthouse / Web Vitals / Django Debug Toolbar / EXPLAIN ANALYZE selon le type), comparaison aux budgets §10, identification des bottlenecks via Pareto, détection anti-patterns, profiling top 3 bottleneck, estimation des gains pour chaque optimisation, plan de re-mesure, catégorisation findings avec gain CHIFFRÉ obligatoire, rapport, archivage si EXCEEDED, hand-off. Pas d'optimisation à l'aveugle — mesure d'abord."

Le subagent applique sa méthode.

### Étape 3 — Restitution

Le rapport du subagent est présenté directement. Inclut la baseline, les bottlenecks identifiés, le plan de remédiation priorisé par ROI.

### Étape 4 — Action selon verdict

- **WITHIN_BUDGETS** : "Tous les budgets respectés sur la cible. Tu peux continuer."
- **DEGRADED** : "Dégradation perçue mais budgets respectés. Optimisations recommandées (voir rapport). Pas bloquant."
- **EXCEEDED** : "Budgets dépassés. Merge BLOQUÉ. Hand-off à l'agent principal pour appliquer les optims priorité 1-2. Re-mesure obligatoire après."

## Règles strictes

### Pas d'optimisation sans cette commande
Si l'utilisateur veut "optimiser X" sans `/perf-audit` préalable : refuse, lance `/perf-audit X` d'abord. Cite "measure first, optimize second".

### Tu ne fais pas l'audit toi-même
Délégation au subagent qui a la méthode rigoureuse et les outils (Lighthouse, EXPLAIN, React Profiler).

### Tu n'acceptes pas un verdict sans mesure
Si le subagent retourne un verdict sans baseline numérique : c'est suspect, demande re-execution.

### Tu rappelles le plan de re-mesure
Toute optim recommandée doit avoir son plan de re-mesure documenté dans le rapport. Sans ça, le gain ne peut pas être prouvé.

## Cas particuliers

### Cible "mon site est lent"
Trop vague. Demande précision : quelle route ? quelle métrique observée ? sur quel device ? Sans précision, l'audit est une chasse au fantôme.

### Cible déjà auditée récemment
Si un rapport existe dans `docs/performance/` (< 7 jours) sur la même cible : présente-le d'abord. Re-audit seulement si changement de code intervenu depuis.

### Audit pré-release
Avant déploiement prod : `/perf-audit` sur les 5 routes critiques (home, catalog, product, cart, checkout). Combine avec `/deploy-check`.

### Optim acceptée mais non vérifiée
Si l'utilisateur dit "j'ai appliqué l'optim, on continue" sans re-mesure : refuse, exige re-execution de `/perf-audit` pour confirmer le gain.

## Hand-offs typiques

- Pattern récurrent identifié (ex: 10x N+1 sur des modules différents) → `architect` pour ADR sur convention de queries.
- Tests de non-régression perf à ajouter → `test-writer` pour scénarios k6 ou Lighthouse CI.

---

**Rappel** : 90% des optimisations "à l'œil" sont du bruit. Le bottleneck réel est presque toujours ailleurs que là où on pense.
