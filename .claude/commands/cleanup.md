---
description: Détecte dead code, dépendances inutilisées, TODOs orphelins, imports non utilisés, fichiers obsolètes. Présente les findings, ne supprime rien automatiquement — l'utilisateur valide chaque suppression.
argument-hint: "[--frontend | --backend | --all]  par défaut: --all"
allowed-tools: ["Bash", "Read", "Glob", "Grep"]
---

# /cleanup — Détection de dette technique cosmétique

Tu détectes le code mort, les dépendances inutilisées, les TODOs orphelins, et autres scories qui s'accumulent dans tout projet. **Tu ne supprimes rien automatiquement** — tu présentes, l'utilisateur valide chaque suppression via `/commit`.

Mode : $ARGUMENTS (`--frontend`, `--backend`, ou `--all` par défaut)

## Procédure

### Étape 1 — Cadrer le scope

Selon `$ARGUMENTS` :
- `--frontend` ou `front` : focus `apps/web/`
- `--backend` ou `back` : focus `apps/api/`
- `--all` ou vide : tout le repo

Affiche :
```
Cleanup scan déclenché
Scope : <résolu>
Date : <timestamp>
```

### Étape 2 — Détections

Exécute les détections appropriées selon le scope. Capture les sorties.

#### Backend Python

```bash
# Dead code (fonctions/classes non utilisées)
pnpm dlx vulture apps/api/shopeasy --min-confidence 80 2>/dev/null || \
  python -m vulture apps/api/shopeasy --min-confidence 80

# Imports inutilisés
ruff check apps/api/shopeasy --select=F401 --no-fix

# Variables inutilisées
ruff check apps/api/shopeasy --select=F841 --no-fix

# Dépendances inutilisées (Python)
# Si deptry installé:
deptry apps/api/shopeasy --known-first-party=shopeasy 2>/dev/null

# Compare requirements vs imports
pip list --not-required --format=freeze
```

#### Frontend TypeScript / JS

```bash
# Dépendances inutilisées (JS/TS)
pnpm dlx knip --reporter compact

# Exports inutilisés
pnpm dlx ts-prune

# Imports inutilisés (ESLint)
pnpm exec eslint apps/web --rule '@typescript-eslint/no-unused-vars:error' --no-fix
```

#### Toutes langues

```bash
# TODOs orphelins (sans issue liée)
grep -rEn "TODO|FIXME|XXX|HACK" apps/ \
  --include="*.py" --include="*.ts" --include="*.tsx" \
  | grep -v -E "TODO\(#[0-9]+\)|FIXME\(#[0-9]+\)"

# Fichiers gros suspects (>500 lignes, signal de refactor)
find apps/ -type f \( -name "*.py" -o -name "*.ts" -o -name "*.tsx" \) \
  -exec wc -l {} + | awk '$1 > 500' | sort -rn

# Fichiers committés qui ne devraient pas l'être
git ls-files | grep -E '\.(env|log|cache|swp|DS_Store|pyc)$'
git ls-files | grep -E '(node_modules|__pycache__|\.venv|\.next/cache)/'

# .env.example désynchronisé de .env
diff <(grep -oE '^[A-Z_]+=' .env 2>/dev/null | sort -u) \
     <(grep -oE '^[A-Z_]+=' .env.example 2>/dev/null | sort -u) || \
  echo "Désynchronisation détectée"

# Skill files inutiles (gitignored mais committés ?)
git check-ignore -v $(git ls-files) 2>/dev/null

# Fichiers de tests sans test runtime (suspect)
find apps/ -name "test_*.py" -exec sh -c 'grep -L "def test_" "$1" 2>/dev/null' _ {} \;
find apps/ -name "*.test.ts" -exec sh -c 'grep -L "test\|it(" "$1" 2>/dev/null' _ {} \;
```

### Étape 3 — Présentation des findings

Format :

```
=== Cleanup scan : <scope> ===

## Findings par catégorie

### Dead code (N occurrences)
- `apps/api/shopeasy/catalog/services.py:42` — fonction `unused_helper` jamais appelée
- `apps/api/shopeasy/orders/utils.py:18` — classe `LegacyHandler` jamais utilisée
- ...

### Dépendances inutilisées (N)
**Backend** :
- `requests` dans pyproject.toml — non importé
- `dateparser` — non importé
**Frontend** :
- `lodash` dans package.json — non importé (mais utilisé via lodash-es)
- `axios` — TanStack Query suffit

### Imports inutilisés (N)
- `apps/web/src/components/Cart/Cart.tsx:5` — `Suspense` importé mais non utilisé
- `apps/api/shopeasy/users/views.py:8` — `permission_classes` importé mais non utilisé
- ...

### TODOs orphelins (N)
- `apps/api/shopeasy/payments/services.py:34` — `# TODO: handle refund partial` (sans issue)
- `apps/web/src/lib/api.ts:67` — `// FIXME: error handling` (sans issue)

### Fichiers > 500 lignes (signal de refactor)
- `apps/api/shopeasy/orders/services.py` — 678 lignes
- `apps/web/src/app/checkout/page.tsx` — 542 lignes

### Fichiers committés à risque
- `.env.staging` committé (devrait être gitignored !) — ALERTE SÉCURITÉ
- `apps/web/.next/cache/...` — devrait être gitignored

### .env / .env.example désynchronisation
Variables dans `.env` absentes de `.env.example` :
- `STRIPE_WEBHOOK_SECRET`
- `SENTRY_DSN`

## Plan de cleanup proposé

### Actions sécuritaires (suppression directe possible)
1. Supprimer imports inutilisés (auto-fixable via `ruff --fix` / eslint)
2. Synchroniser `.env.example` avec `.env` (sans values, juste les clés)

### Actions à valider une par une
1. Dead code détecté — peut être appelé dynamiquement (decorators, signals, registres)
2. Dépendances apparemment inutilisées — peut être runtime-only
3. TODOs orphelins — soit créer une issue, soit supprimer

### Actions à investiguer
1. Fichiers > 500 lignes — invoquer `/refactor` si justifié
2. Fichiers committés à risque — auditer historique git (peut-être déjà leaké)
```

### Étape 4 — Hand-off

Aucune action automatique. Pour chaque finding, propose :

- **Imports/variables inutilisés** : "Voulez-vous que je lance `ruff check --fix` ? Présenter le diff avant commit via `/commit`."
- **Dépendances inutilisées** : "Avant suppression, vérifier le runtime (imports dynamiques, require conditionnel). Validation manuelle requise."
- **Dead code** : "Vérifier qu'il n'est pas appelé via reflection, signals Django, ou registres dynamiques. Si suppression validée : changement présenté via `/commit`."
- **TODOs orphelins** : "Deux options : 1) Créer une issue GitHub et lier le TODO ; 2) Supprimer si plus pertinent."
- **Fichiers à risque committés** : "URGENT — vérifier si secrets dans l'historique. Hand-off à `security-auditor` si suspect."
- **Fichiers gros** : "Lance `/refactor <fichier>` si refactor pertinent."

## Règles strictes

### Pas de suppression automatique
**Aucune** modification de code par cette commande. Tu identifies, l'utilisateur décide, l'agent principal applique via `/commit`.

### Tu n'accuses pas à tort
Si le détecteur de dead code flag une fonction utilisée via reflection (e.g. signal Django, registre de plugins) : signale-le comme "à vérifier" plutôt que "à supprimer". Faux positifs courants :
- Signals Django (`@receiver`)
- DRF serializers méthodes magiques (`validate_<field>`)
- Pytest fixtures
- Celery tasks (`@shared_task`)
- Models Django Manager methods
- Hooks React custom utilisés dynamiquement

### Tu rappelles la sécurité sur les fichiers committés à risque
Un `.env` committé = potentiel leak de secrets. Hand-off immédiat à `security-auditor`. Vérifier l'historique git :
```bash
git log --all --full-history -- .env
```

Si des secrets ont été committés : rotation obligatoire.

## Cas particuliers

### Premier cleanup du projet
Le premier `/cleanup` produit typiquement beaucoup de findings. Recommande de procéder par catégorie (un commit par catégorie) plutôt qu'un commit géant.

### Cleanup post-migration
Après un gros refactor : `/cleanup` permet de détecter le code orphelin laissé. Souvent nécessaire dans la PR de finalisation.

### Faux positifs récurrents
Si un faux positif est récurrent (ex: vulture flag un signal handler) : ajouter à la whitelist du tool :
- Vulture : `# noqa: vulture` ou whitelist file
- Ruff : `# noqa: F401`
- knip : `knip.config.json` ignore list

---

**Rappel** : la dette cosmétique s'accumule lentement et coûte en lisibilité. Un cleanup mensuel garde le projet sain. Mais pas de suppression aveugle — chaque ligne supprimée fait l'objet d'une décision consciente.
