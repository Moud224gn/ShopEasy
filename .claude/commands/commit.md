---
description: Prépare un commit en respectant la discipline §13 (stage + diff + message + justification, attente validation utilisateur explicite)
argument-hint: "[hint optionnel sur le message ou le scope]"
allowed-tools: ["Bash", "Read", "Glob", "Grep"]
---

# /commit — Discipline de commit ShopEasy

Tu prépares un commit en respectant strictement `CLAUDE.md` §13. **Tu ne `git commit` jamais sans validation explicite de l'utilisateur.**

Hint utilisateur (si fourni) : $ARGUMENTS

## Procédure obligatoire (5 étapes)

### Étape 1 — État actuel
Exécute :
```bash
git status --short
git diff --stat
git log --oneline -5
git branch --show-current
```

Vérifie aussi :
- Y a-t-il des fichiers non-stagés que tu pourrais avoir oublié ? (`git status` showing modifications)
- Y a-t-il des fichiers non-trackés pertinents ? (nouveaux fichiers, sauf gitignored)
- Es-tu sur une branche correcte ? (pas `main` ni `develop` directement — voir §11.2)

Si tu détectes un problème (branche incorrecte, fichiers oubliés, secrets potentiels) : alerte l'utilisateur AVANT de continuer.

### Étape 2 — Stage les bons fichiers
Si rien n'est stagé, propose ce qu'il faut stager selon l'analyse `git status`. Sépare logiquement si plusieurs scopes sont touchés (proposer split en commits multiples).

Pour stager : `git add <fichiers explicites>`. **Jamais `git add .`** sans liste préalable (risque de stager des fichiers non-intentionnels).

### Étape 3 — Présentation complète

Affiche à l'utilisateur dans ce format exact :

```
=== Commit proposé ===

Branche actuelle : <nom>
Issue/Spec liée  : #NNN (si détectable depuis branche ou commits)

Fichiers stagés (M=modifié, A=ajouté, D=supprimé, R=renommé) :
  <statut> <fichier>
  ...

Message proposé :
  <type>(<scope>): <description courte à l'impératif>

  <Corps optionnel : pourquoi, trade-offs, contexte si non-évident>

  Refs: #<issue>

Justification :
  - Spec validée : <chemin ou N/A>
  - TDD respecté : <oui/n.a. + évidence : "test_X.py committé en SHA abc123">
  - Coverage local : <%>
  - i18n : <"FR + EN ajoutés" ou "aucune chaîne utilisateur ajoutée">
  - a11y : <statut ou "pas de changement frontend">
  - RTL : <"logical properties OK" ou "pas de changement CSS">
  - Pre-push-fast : <vert/rouge ou n.a.>
  - Conventions §6 respectées : <oui + checks effectués>

Diff complet :
```diff
<output de `git diff --staged`>
```

→ Réponds :
  - "ok commit" ou "go" pour valider et commit
  - "amende: <nouveau message>" pour modifier le message
  - "split en N commits" pour reproposer en plusieurs commits
  - "reset" pour unstage tous les fichiers
  - Toute autre instruction sera traitée
```

### Étape 4 — Attendre validation

**N'exécute aucun `git commit` à cette étape.** Attends la réponse explicite de l'utilisateur.

### Étape 5 — Commit après validation

Une fois validé :
```bash
git commit -m "<type>(<scope>): <description>" -m "<corps>" -m "Refs: #<N>"
```

Puis confirme :
```
Commit créé.
SHA : <sha court>
Branche : <branche>
Prochaine étape recommandée : <continuer / pre-push / autre>
```

## Règles strictes

### Conventional Commits — types autorisés
`feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `style`, `perf`, `ci`, `build`, `revert`

### Scopes valides ShopEasy
`catalog`, `cart`, `orders`, `users`, `vendors`, `payments`, `search`, `notifications`, `analytics`, `audit`, `core`, `web`, `infra`, `ci`, `docs`, `i18n`, `a11y`, `perf`, `security`, `pwa`, `rtl`

### Message
- Description à l'impératif présent : `add` pas `added`, `fix` pas `fixed`.
- Première ligne <= 72 caractères.
- Pas d'emoji dans le message (§1 CLAUDE.md).
- Corps explique le *pourquoi*, pas le *quoi* (le diff montre le quoi).
- Pas de "WIP", "tmp", "test", "debug" en message final.

### Détection de secrets
Avant de stager, fais un scan rapide :
```bash
git diff --staged | grep -iE "(password|secret|token|api[_-]?key|private[_-]?key)\s*[:=]\s*['\"]?[^'\"]{8,}" || echo "no obvious secret"
```

Si suspicion de secret : **REFUSE de commit**, alerte l'utilisateur en majuscules, propose de retirer le fichier du stage.

### Vérification branche
Si branche actuelle est `main` ou `develop` : refuse, recommande de créer une branche feature/fix d'abord.

### Refus de tricher
Si l'utilisateur dit "commit automatique pour aller vite" ou "skip la validation" : refuse explicitement et cite §13 ("La discipline protège ton historique, lu par les employeurs").

## Cas particuliers

### Premier commit d'une feature (TDD Red)
Le message doit être un `test(scope): ...` car §11.1 impose les tests avant le code.

### Commit de format/lint automatique
Message recommandé : `chore(format): apply ruff + prettier` ou `chore(lint): fix eslint warnings`. Présente quand même le diff.

### Commit de mise à jour de dépendances
Message : `chore(deps): bump <package> from X to Y`. Inclure changelog summary dans le corps si breaking changes.

### Commit après refactor
Vérifier que tous les tests passent (`make test-watch` ou équivalent) AVANT de proposer le commit. Le diff doit montrer changement d'implémentation, pas de changement de comportement.

## Hand-offs après commit

Après un commit réussi, suggère selon le contexte :
- Si fin de cycle Red→Green→Refactor → "Continuer le cycle avec test suivant ou délègue à `code-reviewer` via `/review`."
- Si dernier commit avant push → "Lance `/pre-push` pour valider localement."
- Si commit de fix → "Test de régression ajouté ? Sinon délègue à `test-writer`."

---

**Rappel** : tu ne commits jamais sans validation. C'est la règle. Aucune exception.
