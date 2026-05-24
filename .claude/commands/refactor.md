---
description: Planifie un refactor (sans l'exécuter). Délègue au subagent architect pour analyser, proposer le plan, identifier les risques. L'exécution se fait après validation par l'agent principal.
argument-hint: "<cible du refactor : fichier, module, pattern, ou description>"
allowed-tools: ["Bash", "Read", "Glob", "Grep"]
---

# /refactor — Plan de refactor (pas exécution)

Tu déclenches l'analyse et la planification d'un refactor via le subagent `architect`. **Le refactor n'est jamais exécuté par /refactor.** L'exécution suit, validée pas à pas.

Cible : $ARGUMENTS

## Pourquoi ne pas exécuter directement ?

Un refactor est risqué :
- Casse de comportement implicite non-testé.
- Régression dans des modules dépendants.
- Sur-engineering qui aggrave la dette.

L'approche senior :
1. **Plan d'abord** (cette commande) — quoi, pourquoi, comment, risques, gain.
2. **Validation** par l'utilisateur.
3. **Tests existants en filet de sécurité** (vérifier qu'ils couvrent le comportement avant refactor).
4. **Exécution incrémentale** — petits pas, tests verts à chaque pas.

## Vérification d'entrée

Si `$ARGUMENTS` est vide : demande la cible du refactor.

Si trop vague (`refactor le code`) : demande précision.

Exemples valides :
- `apps/api/shopeasy/orders/services.py` (fichier)
- `cart module` (module)
- `extract pricing logic from product model` (description)
- `replace ad-hoc money handling with py-moneyed throughout backend` (pattern transversal)

## Procédure

### Étape 1 — Cadrer la cible

Affiche :
```
Refactor à planifier
Cible : <précision>
```

### Étape 2 — Analyse rapide

Avant de déléguer à `architect`, fournis-lui le contexte initial :

```bash
# Si fichier ou module spécifique
wc -l <cible>
git log --oneline --follow <cible> | head -10
grep -rn "<symboles définis dans la cible>" apps/ | wc -l  # dépendants

# Couverture actuelle
make test-watch <cible> --coverage 2>/dev/null || echo "vérifier manuellement"
```

Ces données préliminaires alimentent l'analyse.

### Étape 3 — Délègue au subagent architect

Invoque `architect` avec le contexte :

> "Analyse le refactor demandé : [cible]. Produis un plan de refactor structuré (PAS le code refactorisé). Le plan doit contenir :
> 1. **Objectif** : que cherche-t-on à améliorer (lisibilité, testabilité, séparation des responsabilités, perf — ce dernier nécessite un profil préalable via /perf-audit) ?
> 2. **État actuel** : description précise (couplages, antipatterns, dette identifiée).
> 3. **État cible** : à quoi ressemble le code après.
> 4. **Plan d'étapes incrémentales** : refactor découpé en N pas, chacun gardant les tests verts.
> 5. **Filet de sécurité** : tests existants suffisants ? Si non, identifie les tests à ajouter AVANT le refactor.
> 6. **Risques** : régressions possibles, fichiers à risque, modules dépendants.
> 7. **Coût** : effort estimé en jours.
> 8. **Validation** : critères pour considérer le refactor terminé.
> 
> N'écris PAS le code refactorisé. Le plan suffit. Hand-off ensuite vers l'agent principal pour exécution étape par étape."

Le subagent applique sa méthode standard d'analyse, produit le plan structuré.

### Étape 4 — Présentation et validation

Le subagent présente le plan. L'utilisateur valide :
- "ok plan" → on procède à l'exécution.
- "amende: ..." → le subagent ajuste.
- "trop risqué" → on archive le plan, on n'exécute pas.

### Étape 5 — Avant exécution : vérifier le filet de sécurité

**Si tests existants insuffisants** (identifié par `architect`) :
1. Hand-off vers `test-writer` pour ajouter les tests manquants AVANT refactor.
2. Ces tests "characterization tests" vérifient le comportement courant (pas le comportement idéal).
3. Une fois ces tests verts, on peut refactorer en sachant qu'on ne casse rien.

**Si tests suffisants** :
1. Vérifier qu'ils sont tous verts (`make test`).
2. Mesurer la couverture sur la zone à refactorer (doit être >= 85%).
3. Si OK, on peut commencer l'exécution.

### Étape 6 — Exécution incrémentale (hors `/refactor`)

L'exécution n'est PAS du ressort de cette commande. Une fois le plan validé :
1. L'agent principal applique l'étape 1 du plan.
2. `make test` → tests verts.
3. `/commit` (validation §13) → message `refactor(scope): <étape 1 description>`.
4. Répète pour chaque étape du plan.

Le refactor est terminé quand toutes les étapes du plan sont committées, tests verts, et critères de validation atteints.

### Étape 7 — Validation finale

Après exécution complète :
- `/review` pour s'assurer que le refactor n'a rien cassé d'invisible.
- Si performance était un objectif : `/perf-audit` pour confirmer le gain.

## Cas particuliers

### Refactor "pour la perf"
Le subagent `architect` exige un profil préalable avant d'accepter ce type de refactor.
- Sans `/perf-audit` montrant un bottleneck sur la cible : refuse, redirige vers profiling d'abord.

### Refactor de tests
Si la cible est un fichier de tests : c'est typiquement OK sans plan élaboré (les tests testent eux-mêmes). Mais reste prudent : un test qui change de structure peut perdre des cas couverts subtilement. Le subagent applique la méthode normale, juste avec plus de tolérance.

### Refactor massif (> 1 semaine)
Si le plan estime > 5 jours : `architect` recommande de découper en plusieurs refactors plus petits, chacun avec son propre cycle plan → exécution → review. Pas de "big bang refactor" sans découpage.

### Refactor qui change un contrat d'API
Si l'API publique change (même nom de fonction, mais signature différente) :
- Préfère deprecation > suppression directe.
- Garde l'ancienne version avec warning de deprecation pendant 1-2 sprints.
- Migration progressive des consumers.
- Suppression après période de grace documentée.

Le subagent identifie ces cas et propose la stratégie deprecation.

### Refactor multi-module
Si le refactor touche plusieurs apps (`catalog` + `orders` + `cart`) :
- Plan structuré par app.
- Chaque app refactorisée séparément, tests verts entre chaque.
- Pas de PR géante — splits par app.

## Règles strictes

### Tu ne refactorises pas dans /refactor
**Cette commande produit un plan uniquement.** Si le subagent commence à écrire du code applicatif, il viole sa propre règle (`architect` ne touche pas au code).

### Tu n'exécutes pas sans filet de sécurité
Si la cible a une couverture < 70% : `test-writer` est invoqué d'abord pour combler. Pas de refactor à l'aveugle.

### Tu ne contournes pas la validation §13
Chaque étape du refactor produit un commit qui passe par `/commit`. Pas de "commit en masse à la fin".

### Tu refuses le sur-engineering
Si le subagent identifie que le refactor proposé introduit plus de complexité qu'il n'en retire (ex: introduire CQRS sur un CRUD simple) : il refuse et propose alternative ou pas de refactor.

---

**Rappel** : un refactor n'est valide que si les tests restent verts à chaque pas. Pas de "je refactore, je verrai si ça marche après". C'est le filet, pas l'épée.
