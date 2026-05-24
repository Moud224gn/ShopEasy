---
description: Exécute la validation locale 3 couches avant tout git push (lint, tests, security, build, a11y, i18n). Génère le marqueur .pre-push-pass si succès.
argument-hint: "[--fast pour version réduite ~1min, sinon validation complète ~3-5min]"
allowed-tools: ["Bash", "Read", "Glob", "Grep"]
---

# /pre-push — Validation locale avant push

Tu exécutes la validation locale complète selon `CLAUDE.md` §12 ("La CI ne doit jamais détecter un problème non vu localement"). **Aucun push ne doit avoir lieu sans cette validation verte.**

Mode (si fourni) : $ARGUMENTS

## Détection du mode

- Si `$ARGUMENTS` contient `--fast` : mode rapide (lint + typecheck + unit tests seulement, ~1min).
- Sinon : mode complet (`make pre-push`, ~3-5min).

**Le mode rapide ne génère PAS de marqueur `.pre-push-pass`** — il ne remplace pas la validation complète avant un push réel.

## Procédure

### Étape 1 — État actuel
```bash
git status --short
git branch --show-current
git log --oneline -3
```

Vérifie que :
- La branche est une feature/fix/refactor (pas main/develop).
- Les changements sont committés (présenter l'état si fichiers modifiés non-stagés).

### Étape 2 — Exécution

#### Mode rapide (`--fast`)
```bash
make pre-push-fast
```

Annonce : "Mode rapide. Exécute lint + typecheck + tests unitaires seulement. NE remplace PAS `make pre-push` avant push réel."

#### Mode complet (par défaut)
```bash
make pre-push
```

Cette commande exécute (ordre prévu dans `CLAUDE.md` §12) :
1. `make lint`
2. `make typecheck`
3. `make test-api` (coverage 85%)
4. `make test-web` (coverage 85%)
5. `make test-a11y`
6. `make test-i18n`
7. `make test-rtl`
8. `make security`
9. `make build`
10. `make perf-audit`

### Étape 3 — Analyse des résultats

Capture la sortie de chaque étape. Si une étape échoue, le `make pre-push` s'arrête (mode `set -e` du Makefile recommandé).

Présente le résultat dans ce format :

```
=== Pre-push validation : <mode> ===

Branche : <nom>
Démarré : <timestamp>
Durée   : <X min Y sec>

## Résultats par étape

| # | Étape | Statut | Détails |
|---|---|---|---|
| 1 | Lint (ruff/eslint/prettier) | OK / FAIL | <résumé> |
| 2 | Typecheck (mypy/tsc) | OK / FAIL | <résumé> |
| 3 | Tests API + coverage | OK / FAIL | <% coverage, N tests> |
| 4 | Tests Web + coverage | OK / FAIL | <% coverage, N tests> |
| 5 | Tests a11y | OK / FAIL | <Lighthouse score / violations> |
| 6 | Tests i18n | OK / FAIL | <chaînes manquantes / hardcoded> |
| 7 | Tests RTL | OK / FAIL | <snapshots régressés> |
| 8 | Security scan | OK / FAIL | <vulns> |
| 9 | Build prod | OK / FAIL | <front/back> |
| 10 | Perf audit | OK / FAIL | <budgets respectés> |

## Verdict

**[PASS | FAIL]**

[Si PASS] :
Marqueur généré : `.pre-push-pass` (timestamp <date>)
Tu peux maintenant exécuter `git push` (la couche 3 pre-push hook Git le confirmera).

[Si FAIL] :
Push BLOQUÉ. Étapes échouées :
- Étape N : <résumé erreur>
- ...

Action recommandée : corriger les problèmes, puis relancer `/pre-push`.

[Si FAIL et patterns reconnus, propose des hand-offs] :
- Tests échouent : invoque le subagent `test-writer` pour debug
- Sécurité : invoque le subagent `security-auditor`
- Perf : invoque le subagent `performance-optimizer`
- i18n/a11y/RTL : invoque le subagent `accessibility-i18n-auditor`
```

### Étape 4 — Génération du marqueur (uniquement mode complet, uniquement si PASS)

Si tout passe en mode complet :
```bash
date -Iseconds > .pre-push-pass
git update-index --skip-worktree .pre-push-pass 2>/dev/null || true  # éviter qu'il soit committé par erreur
```

Vérifier que `.pre-push-pass` est dans `.gitignore`. Si non, alerte et propose de l'ajouter.

### Étape 5 — Cleanup et hand-off

- Si **PASS** complet : "Validation locale verte. Tu peux maintenant `/commit` (si pas déjà fait) puis `git push`."
- Si **FAIL** : ne pas faire de commits, ne pas push. Travailler sur les fixes.

## Règles strictes

### Tu refuses d'approuver un push sans validation
Si l'utilisateur dit "j'ai déjà testé, skip pre-push pour cette fois" : **refuse** et cite §12.

### Tu n'ignores aucune étape
Même si une étape semble "non liée au changement" (ex: tests RTL alors qu'aucun CSS modifié) : exécute. Une régression peut venir d'une dépendance commune.

### Tu suggères l'optimisation du Makefile si une étape est trop lente
Si pre-push dépasse 5-7 minutes régulièrement : note l'opportunité de paralléliser (background `make` jobs, ou réduction de scope par détection de fichiers modifiés). Suggère un finding pour amélioration future, sans le bloquer.

### Tu ne génères jamais .pre-push-pass en mode rapide
Le mode rapide est un raccourci pour le dev, pas une validation. Confondre les deux casse la chaîne de confiance.

### Vérification du Makefile
Si `make pre-push` n'existe pas dans le `Makefile` : alerte. Propose la commande à ajouter (selon §5 CLAUDE.md). Sans cette commande, le workflow §12 est cassé.

## Cas particuliers

### Premier setup du projet
Si `make pre-push` échoue car certains tools ne sont pas installés : guide l'utilisateur vers `make setup` d'abord.

### Sur une branche sans commits
Si la branche est identique à `develop`, pre-push n'a rien à valider. Annonce-le et propose de continuer le développement.

### Configuration CI manquante
Si `.github/workflows/` n'existe pas, suggère que le `devops-engineer` subagent configure la CI pour que la couche 3 existe vraiment.

---

**Rappel** : pre-push est ton filet de sécurité. Une CI rouge devrait être un événement rare. Si elle l'est : pre-push fait son travail.
