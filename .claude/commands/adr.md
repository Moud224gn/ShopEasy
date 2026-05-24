---
description: Formalise une décision architecturale en ADR (Architecture Decision Record) dans docs/adr/. Délègue au subagent architect. Numérotation auto, format standard avec alternatives et justification.
argument-hint: "<énoncé court de la décision à formaliser>"
allowed-tools: ["Bash", "Read", "Glob", "Grep", "WebSearch", "WebFetch"]
---

# /adr — Architecture Decision Record

Tu déclenches la rédaction d'une ADR via le subagent `architect`. Une ADR formalise toute décision architecturale **significative** : choix de techno, pattern transversal, contrat d'API public, infrastructure, ou toute décision difficile à inverser.

Décision : $ARGUMENTS

## Quand `/adr` est-il justifié ?

Critères de l'ADR (`architect` §5) — au moins un doit s'appliquer :
- Choix de dépendance majeure (lib, service tiers, framework).
- Pattern transversal au projet (ex: comment on gère le multi-currency).
- Modification de contrat d'API public.
- Choix d'infrastructure ou de cloud.
- Toute décision difficile à inverser (> 1 sprint pour back-out).

Si la décision ne satisfait aucun critère : suggère un commentaire dans le code ou une note dans la spec plutôt qu'une ADR. Les ADRs encombrent si trop nombreuses pour des micro-décisions.

## Vérification d'entrée

Si `$ARGUMENTS` est vide : demande la décision à formaliser.

Si `$ARGUMENTS` est très vague (`refactor catalog`) : demande une formulation plus précise. Une bonne ADR commence par une question claire :
- "Quel password hashing algorithm pour ShopEasy ?"
- "Modular monolith ou microservices dès le Sprint 1 ?"
- "Comment isoler les apps Django pour préparer le split microservices ?"

## Procédure

### Étape 1 — Numérotation automatique

```bash
# Trouver le prochain numéro ADR
ls docs/adr/ 2>/dev/null | grep -E "^[0-9]{4}-" | sort -r | head -1
# Si vide : prochain = 0001
# Sinon : extraire le numéro et incrémenter
```

Format du nom de fichier : `docs/adr/NNNN-<slug-kebab-case>.md`

Exemples :
- `docs/adr/0001-stack-technologique.md`
- `docs/adr/0007-multi-currency-storage-strategy.md`

### Étape 2 — Recherche d'ADRs liées

```bash
# Chercher des ADRs traitant du même sujet
grep -l -i "<keywords de la décision>" docs/adr/*.md 2>/dev/null
```

Si une ADR existe déjà sur le même sujet :
- Peut-être qu'elle se met à jour (statut "Remplacée par ADR-NNNN") plutôt qu'une nouvelle.
- Présenter l'existante à l'utilisateur, demander si extension/remplacement/parallèle.

### Étape 3 — Délègue au subagent architect

Invoque `architect` avec le contexte :

> "Rédige une ADR pour : [décision]. Numéro attribué : ADR-NNNN. Suis ton format ADR standard (Statut, Contexte, Décision, **3 alternatives considérées** avec trade-offs/coûts/risques, Justification citant principes ShopEasy et données, Conséquences positives/négatives/à surveiller, Plan de mise en œuvre, Critères de réévaluation, Références). Le fichier sera écrit dans `docs/adr/NNNN-<slug>.md`. Tiens compte des ADRs liées si existantes."

Le subagent prend le relais selon sa méthode :
1. Lit CLAUDE.md + ADRs existants.
2. Évalue les contraintes.
3. **Génère obligatoirement 2-3 alternatives** (sinon refuse de continuer).
4. Recommande avec justification citant principes/données.
5. Rédige l'ADR au format standard.
6. Écrit le fichier.

### Étape 4 — Présentation

Le subagent présente l'ADR à l'utilisateur. Demande validation explicite.

Si l'utilisateur amende : le subagent réécrit. Pas de half-commit.

### Étape 5 — Statut initial

Au moment de la rédaction, le statut est `Proposé`. L'utilisateur le passe à `Accepté` après validation par :
- Lui-même si projet solo.
- Une équipe formelle si applicable.

Le subagent écrit explicitement le statut courant. Ne marque jamais `Accepté` sans validation.

### Étape 6 — Commit

L'ADR n'est pas committée automatiquement. Une fois validée :
- Suggère `/commit` avec message `docs(adr): ADR-NNNN <titre court>`.
- Référence l'issue ou le contexte qui a déclenché la décision.

### Étape 7 — Mise à jour des références

Une ADR créée peut nécessiter des références ailleurs :
- Mention dans `CLAUDE.md` §3 (stack) ou §4 (architecture) si l'ADR change la stack ou l'architecture courante.
- Mention dans `docs/conventions/<domaine>.md` si l'ADR fixe une convention.
- Mention dans le README si l'ADR impacte la perception extérieure du projet.

Le subagent identifie ces références et propose les mises à jour. Pas auto-merge — chaque modif fait l'objet de son propre commit après validation.

## Cas particuliers

### ADR qui remplace une précédente
Si la nouvelle ADR rend une précédente obsolète :
- La nouvelle a un statut `Accepté` (après validation).
- L'ancienne passe à `Remplacée par ADR-NNNN` (avec lien).
- Mise à jour du statut de l'ancienne dans le même commit que la nouvelle.

### ADR rejetée
Si après discussion l'utilisateur décide de ne pas adopter la décision proposée :
- Soit pas d'ADR créée du tout (cas le plus courant).
- Soit ADR créée avec statut `Rejeté` (rare, utile si la question revient).

### Décision contestée
Si la décision est encore en débat :
- Statut `Proposé` reste.
- Pas de commit (ou commit avec note "draft, non-acceptée").
- Discussion continue, ADR finalisée plus tard.

### Petite décision sans alternatives évidentes
Si le subagent ne trouve pas de 2-3 alternatives crédibles (ex: "on utilise UUIDs v7 pour les PK") : c'est peut-être un détail de convention, pas une ADR. Suggère plutôt une mention dans `docs/conventions/` ou dans le `CLAUDE.md`.

## Règles strictes

### Tu ne rédiges pas l'ADR toi-même
Tu **délègues** à `architect`. C'est son rôle. La rigueur d'une ADR est sa valeur — produire une ADR superficielle est pire que pas d'ADR.

### Tu ne crées pas l'ADR sans alternatives
Si le subagent ne peut pas proposer 2-3 alternatives crédibles, la décision n'est probablement pas significative au point de mériter une ADR. Suggère une autre voie.

### Tu ne marques pas `Accepté` sans validation utilisateur explicite
Statut initial = `Proposé`. Bascule à `Accepté` seulement après "ok" explicite.

### Une ADR ≠ une spec
- Spec : *comment* on implémente une feature.
- ADR : *quoi* on choisit, *pourquoi*, *quelles alternatives* écartées.

Si l'utilisateur lance `/adr` pour une feature plutôt qu'une décision : redirige vers `/spec`.

---

**Rappel** : les ADRs sont la mémoire de l'équipe. Dans 2 ans, quelqu'un (toi inclus) se demandera pourquoi tel choix. L'ADR a la réponse.
