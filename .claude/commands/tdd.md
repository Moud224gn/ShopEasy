---
description: Démarre un cycle TDD strict (tests d'abord, code minimal Green, refactor). Délègue au subagent test-writer. Force la liste des cas avant tout code.
argument-hint: "<description courte de la fonctionnalité ou du comportement à implémenter>"
allowed-tools: ["Bash", "Read", "Glob", "Grep"]
---

# /tdd — Cycle TDD strict

Tu déclenches un cycle TDD strict selon `CLAUDE.md` §11.1. **Aucun code de production ne sera écrit avant que les tests existent et échouent (Red phase).**

Description fournie : $ARGUMENTS

## Vérification d'entrée

Si `$ARGUMENTS` est vide ou trop vague (< 10 caractères) : demande une description claire.

Exemples valides :
- "ajouter validation email unique lors de l'inscription user"
- "implémenter reserve_stock avec gestion concurrence"
- "endpoint GET /api/products/:slug avec variantes"

Exemples insuffisants (demande clarification) :
- "TDD pour orders"
- "tester"
- "ajouter ça"

## Procédure

### Étape 1 — Cadrer la feature

Affiche :
```
Cycle TDD strict initié
Feature : <description fournie>
```

Pose les questions de contexte si l'information manque :
- Spec existe ? Chemin dans `docs/specs/` ?
- Issue GitHub liée ? Numéro ?
- Module/app concerné(s) ?
- Niveau de test attendu : unit ? intégration ? les deux ?

Si la spec n'existe pas pour une feature non-triviale : suggère `/spec <issue-id>` d'abord. TDD sur une spec floue produit des tests fragiles.

### Étape 2 — Délègue au subagent test-writer

Invoque le subagent `test-writer` avec le contexte clair :

> "Démarre un cycle TDD strict pour : [description]. Suis ta méthode standard :
> 1. Comprendre la spec / critères Gherkin
> 2. **Lister exhaustivement les cas à couvrir** (cas heureux, erreur, limites, concurrence) — présenter à l'utilisateur AVANT d'écrire le moindre test
> 3. Attendre validation de la liste
> 4. Écrire un test à la fois (Red)
> 5. Implémentation minimale Green pour chaque test
> 6. Refactor si nécessaire (Refactor)
> 7. Commits séparés via `/commit` à chaque phase verte"

Le subagent prend le relais et exécute la méthode complète.

### Étape 3 — Suivi du cycle

Le subagent va d'abord présenter la liste des cas. **Tu n'interfères pas** — c'est l'utilisateur qui valide ou amende cette liste.

Une fois la liste validée, le subagent écrit test par test, fait passer chacun en Green, et propose les commits via `/commit` (qui force la validation §13).

### Étape 4 — Hand-off final

Quand tous les cas sont couverts et passent :

- Si l'implémentation Green minimale suffit → le subagent recommande `/review` avant push.
- Si refactor au-delà du Green nécessaire → hand-off vers agent principal pour implémentation complète, suivi de `/review`.

## Règles strictes (rappel)

### Tests AVANT code, sans exception
Même si l'utilisateur dit "écris juste la fonction, je verrai les tests après" : refuse, cite §11.1, propose de commencer par les tests.

### Un test à la fois
Pas de "j'écris tous les tests d'un coup". Le cycle Red→Green→Refactor s'applique à chaque test individuellement.

### Coverage 85% minimum sur apps métier
Le subagent vérifie automatiquement. Si insuffisant : ajout de tests requis avant commit final.

### Mutation testing pour payments/orders
Si la feature touche `apps/api/shopeasy/payments/` ou `apps/api/shopeasy/orders/` : rappel que `make test-mutation` doit passer (gate 75%) avant merge.

### Format des commits TDD
Le cycle produira typiquement (chaque commit validé via `/commit`) :
- `test(scope): add tests for <feature>` (Red phase commit)
- `feat(scope): implement <feature>` (Green phase commit)
- `refactor(scope): <amélioration>` (Refactor phase commit, optionnel)

## Cas particuliers

### Bug fix
Si la "feature" est en fait un bug fix : TDD = test de régression d'abord.
- Écrire le test qui reproduit le bug (échoue).
- Commit du test : `test(scope): regression test for <bug>`.
- Fix le code (le test passe).
- Commit du fix : `fix(scope): correct <bug>`.

### Feature avec dépendance externe
Si la feature dépend d'une API externe : mocker via MSW (front) ou `responses`/`requests-mock` (back). Pas d'appel réseau réel dans les tests.

### Refactor sans changement de comportement
Le cycle TDD ne s'applique pas — un refactor garde les tests existants verts. Si on en arrive là par `/tdd`, propose plutôt `/refactor`.

### Spec floue ou manquante
Le subagent va te poser des questions. Si la spec est trop floue, il refusera de continuer et recommandera `/spec <issue-id>` d'abord.

## Vérifications avant cycle

Avant de déléguer au subagent, vérifie rapidement :

```bash
# Tests existants pour cette zone ?
ls apps/api/shopeasy/<app>/tests/ 2>/dev/null || ls apps/web/src/<feature>/__tests__/ 2>/dev/null

# Branche correcte ?
git branch --show-current
# Doit être feature/* ou fix/*, pas main/develop

# Tests passent actuellement ?
make test-watch  # ou test-fast selon contexte
```

Annonce le résultat avant de déléguer pour que le subagent ait le contexte complet.

## Hand-offs possibles depuis /tdd

- Si décision archi requise pour implémenter la feature → `architect` via `/adr`.
- Si feature touche sécurité → `security-auditor` invoqué après Green phase.
- Si feature touche perf → `performance-optimizer` consulté pour valider stratégie cache/queries.

---

**Rappel** : TDD n'est pas un dogme, c'est une méthode prouvée. Tu écris les tests d'abord, tu sais ce que tu veux, tu obtiens du code testable, tu évites la régression. C'est ça la différence avec un projet d'école.
