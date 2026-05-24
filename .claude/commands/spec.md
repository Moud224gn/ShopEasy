---
description: Génère une spec technique structurée pour une feature non-triviale dans docs/specs/. Délègue au subagent architect. Critères d'acceptation Gherkin, conception API, considérations transversales (i18n, a11y, sécurité, perf).
argument-hint: "<issue-id> ou <titre court de la feature>"
allowed-tools: ["Bash", "Read", "Glob", "Grep", "WebSearch"]
---

# /spec — Spec technique avant feature

Tu déclenches la rédaction d'une spec technique selon le format défini dans le subagent `architect`. Sans spec validée, une feature non-triviale est un risque (§11.1 → 11.2 CLAUDE.md, et §11.4 production-ready check).

Cible : $ARGUMENTS

## Vérification d'entrée

Si `$ARGUMENTS` est vide : demande l'issue-id ou un titre court de la feature.

Détecte le format :
- **Issue ID** (`142`, `#142`, `gh-142`) → spec liée à une issue GitHub existante.
- **Titre** (`product variants`, `payment refunds`) → nouvelle feature sans issue (rare, suggère d'en créer une d'abord).

## Procédure

### Étape 1 — Récupérer le contexte

Si issue GitHub identifiée :
```bash
# Si gh CLI dispo
gh issue view <id> --json title,body,labels,assignees,milestone,comments

# Sinon
git config --get remote.origin.url
# Et demande à l'utilisateur de coller le contenu de l'issue
```

Lis aussi :
- ADRs existants pour cohérence : `ls docs/adr/`
- Spec existantes (cas similaires) : `ls docs/specs/`
- `CLAUDE.md` §2 (vision projet) et §4 (architecture)
- Conventions pertinentes selon le domaine de la feature

### Étape 2 — Déterminer le chemin du fichier

Format : `docs/specs/<issue-id>-<slug-court>.md`

Exemples :
- `docs/specs/142-product-variants.md`
- `docs/specs/189-multi-currency-display.md`

Si une spec existe déjà à ce chemin : prévenir l'utilisateur, proposer de mettre à jour ou créer un fichier additionnel `-v2`.

### Étape 3 — Délègue au subagent architect

Invoque `architect` avec le contexte :

> "Génère une spec technique pour la feature [issue + titre]. Utilise ton format standard de spec (`Spec : <titre>` avec sections : Objectif business, Critères d'acceptation Gherkin, Conception technique [modèles, endpoints, flow], Considérations [i18n, a11y, sécurité, perf, multi-currency], Cas limites et erreurs, Plan d'implémentation, Hors scope). Tiens compte des ADRs existants et de l'architecture courante. Si le périmètre est ambigu, pose les questions à l'utilisateur avant de produire la spec."

Le subagent prend le relais et exécute sa méthode complète :
1. Comprendre le contexte (lecture CLAUDE.md, ADRs, code existant pertinent).
2. Évaluer les contraintes.
3. Si décisions architecturales requises : proposer alternatives.
4. Rédiger la spec au format standard.
5. Écrire le fichier dans `docs/specs/<chemin>`.

### Étape 4 — Présentation à l'utilisateur

Le subagent présente la spec finale et demande :
- Validation explicite ("ok spec" / "amende: ...").
- Confirmation des hypothèses si nécessaire.

**La spec n'est pas committée par /spec lui-même.** Une fois validée, l'utilisateur (ou Claude) déclenche `/commit` pour la committer (typiquement `docs(specs): add spec for #142`).

### Étape 5 — Hand-off après validation

Après validation de la spec :
- "Spec validée. Étapes recommandées :
  1. `/commit` pour committer la spec (`docs(specs): add spec for #142`)
  2. Démarrer le développement TDD avec `/tdd <description de la feature>`
  3. À chaque commit pendant la feature : référencer l'issue + la spec dans le message"

## Cas particuliers

### Feature triviale (< 1 jour d'implémentation)
Si la feature est manifestement triviale (ex: ajouter un champ optionnel à un formulaire, traduire des chaînes manquantes) : le subagent `architect` peut proposer de skip la spec et passer directement à `/tdd` avec un résumé inline dans l'issue. Suggère cette voie pour ne pas surcharger.

### Décision architecturale dépassant la feature
Si la spec révèle un choix archi non encore documenté (ex: faut-il utiliser X ou Y pour le stockage des variantes ?), le subagent peut :
- Soit décider dans la spec (avec justification courte).
- Soit recommander une ADR séparée via `/adr <decision>` AVANT de finaliser la spec.

### Feature touchant plusieurs apps
La spec doit explicitement lister les apps touchées (`catalog`, `cart`, `orders`, etc.) et préciser le mode de communication (signaux Django, Celery tasks, appels services).

### Aucune issue GitHub
Si l'utilisateur démarre sans issue : suggère d'en créer une d'abord via `gh issue create` pour la traçabilité. Si refus, accepte avec mention que la spec doit citer explicitement la motivation.

## Règles strictes

### Tu ne rédiges pas la spec toi-même
Tu **délègues** à `architect`. C'est son rôle, son format, sa méthode. Tu coordonnes seulement.

### Tu ne crées pas la spec sans validation utilisateur
Le subagent présente, l'utilisateur valide. Pas d'auto-commit, pas de "voilà c'est fait".

### Tu n'altères pas le format de spec
Le format est défini dans le prompt système d'`architect`. Si l'utilisateur veut un format différent (sections différentes, etc.), c'est un amendement du prompt agent, pas une exception pour cette commande.

### Pas de spec pour un bug fix
Si l'utilisateur lance `/spec` pour un bug : redirige vers `/tdd` avec test de régression (cycle approprié pour les fixes, voir §test-writer).

---

**Rappel** : une spec floue produit des features floues. Une spec claire fait gagner 5x le temps qu'elle a coûté.
