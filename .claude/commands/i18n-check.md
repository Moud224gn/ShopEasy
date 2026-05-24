---
description: Vérifie l'internationalisation sur un chemin (chaînes hardcodées, complétude FR/EN, formats locale-aware, devises hardcodées, RTL readiness). Délègue au subagent accessibility-i18n-auditor avec focus i18n.
argument-hint: "<chemin | --staged | --branch>  ex: apps/web/src/components/Cart"
allowed-tools: ["Bash", "Read", "Glob", "Grep"]
---

# /i18n-check — Vérification i18n + multi-currency + RTL

Tu déclenches une vérification i18n approfondie par le subagent `accessibility-i18n-auditor` selon `CLAUDE.md` §8 et `docs/conventions/i18n.md`. **Aucune chaîne visible utilisateur ne doit être hardcodée, FR + EN sont obligatoires dès le Sprint 1.**

Périmètre : $ARGUMENTS

## Différence avec `make i18n-check`

- **`make i18n-check`** (CI) : check global automatique. Zéro chaîne hardcodée + complétude FR/EN sur tout le repo. Lancé en CI et `make pre-push`.
- **`/i18n-check <chemin>`** (cette commande) : analyse approfondie d'un périmètre ciblé. Inclut détection devises hardcodées, formatage non-locale-aware, RTL readiness des CSS touchés.

## Procédure

### Étape 1 — Cadrer le périmètre

Selon `$ARGUMENTS` :
- **Chemin** : `apps/web/src/components/Cart` → analyse récursive du chemin.
- **`--staged`** : analyse des fichiers stagés.
- **`--branch`** : analyse des changements de la branche par rapport à `develop`.
- **Vide** : demande à l'utilisateur de préciser.

Affiche :
```
Vérification i18n déclenchée
Périmètre : <résolu>
Date : <timestamp>
Locales actuelles : FR (défaut), EN
```

### Étape 2 — Délègue au subagent accessibility-i18n-auditor

Invoque le subagent avec contexte précis (focus i18n + multi-currency + RTL) :

> "Effectue une vérification i18n approfondie sur [périmètre]. Focus sur :
> 1. **Chaînes hardcodées** : JSX, placeholder, title, alt, aria-label, messages d'erreur API.
> 2. **Complétude FR + EN** : toute clé présente dans une locale doit être dans l'autre. Pas de valeur `TODO`.
> 3. **Formatage locale-aware** : dates via useFormatter().dateTime, nombres/devises via useFormatter().number, pluralisation ICU.
> 4. **Multi-currency** : aucune devise hardcodée (ISO 4217 ou symbole) dans le code applicatif. Montants stockés en minor units. Opérations via dinero.js/py-moneyed.
> 5. **RTL readiness** : logical properties uniquement (jamais `margin-left`/`right`, `text-align: left/right`, classes Tailwind `ml-*`, `pl-*`, `text-left`).
> 
> L'audit a11y (WCAG) n'est pas le focus principal ici sauf si tu détectes des violations critiques en passant. Suis ta méthode standard, catégorise findings (CRITICAL/HIGH/MEDIUM/LOW/INFO), produis rapport au format standard. Archive dans `docs/audits/accessibility-i18n/` si CRITICAL/HIGH."

Le subagent applique sa méthode avec ce focus.

### Étape 3 — Restitution

Le rapport inclut les 4 sections opérationnelles spécifiques i18n :
- **Chaînes hardcodées** : table avec fichier, ligne, chaîne, clé suggérée.
- **Clés manquantes par locale** : table FR/EN avec statut.
- **Formatage non-locale-aware** : table fichier, ligne, problème.
- **Devises hardcodées** : table fichier, ligne, code/symbole.
- **Physical properties à corriger** (RTL) : table avant/après.

### Étape 4 — Action selon verdict

- **ACCESSIBLE** (le subagent utilise ce verdict global pour a11y+i18n) : "Verdict OK pour l'i18n. Tu peux continuer."
- **CONCERNS** : "N findings non-bloquants. Hand-off agent principal pour corrections."
- **INACCESSIBLE** : "Bloquant. Une locale entière manque sur une route critique, ou devise hardcodée bloquant un marché cible. Merge BLOQUÉ. Hand-off pour fixes."

## Règles strictes

### Tu ne fais pas l'audit toi-même
Délégation au subagent qui a la méthode et les regex de détection.

### Tu n'altères pas le verdict
"L'arabe c'est dans 2 ans, on testera plus tard" → refuse, cite la dette technique exponentielle du refactor RTL.

### Tu rappelles que FR + EN sont obligatoires
Pas de "je traduirai plus tard". Toute PR ajoutant des chaînes doit ajouter FR ET EN.

### Tu refuses les exceptions sur multi-currency
Toute devise hardcodée dans le code applicatif (hors `constants`, `config`, `tests`) est un finding minimum HIGH. CLAUDE.md §8 multi-currency.

## Cas particuliers

### Chaîne en namespace vs hardcodée
Si une chaîne semble hardcodée mais est en réalité une clé technique (ex: `role: "admin"`, `status: "pending"`) : le subagent ne la flag pas. Mais si elle est affichée à l'utilisateur quelque part : nécessite un mapping i18n côté affichage.

### Tooltips et messages courts
Tooltips, hints, error messages — tous concernés. Ne pas oublier ces zones souvent négligées.

### Audit pré-release
Avant déploiement prod : `/i18n-check` sur tout le frontend (`apps/web/src`). Vérifie que toutes les routes user-facing sont complètes FR + EN.

### Ajout d'une nouvelle locale
Si l'utilisateur prévoit d'ajouter `ar`, `es`, ou autre : utilise `/locale-add <code>` (commande dédiée) avant d'ajouter des chaînes pour cette locale.

## Hand-offs typiques

- Pattern récurrent (ex: 20 chaînes hardcodées dans un module) → `architect` pour ADR sur namespace organisation.
- Composant à refactor pour RTL → `architect` via `/refactor`.
- Tests de non-régression i18n à ajouter → `test-writer` pour vérifier que toutes les locales restent complètes.

---

**Rappel** : ShopEasy vise l'international (CLAUDE.md §2). Une chaîne hardcodée aujourd'hui = 30 secondes de refactor demain. 200 chaînes hardcodées dans 3 mois = 3 jours de refactor sous pression.
