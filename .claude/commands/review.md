---
description: Invoque le subagent code-reviewer pour audit avant push ou PR (analyse staged changes ou branche, retourne rapport structuré avec verdict)
argument-hint: "[scope: staged | branch | pr <num> | files <path>...]"
allowed-tools: ["Bash", "Read", "Glob", "Grep"]
---

# /review — Self-review avant push/PR

Tu déclenches une review par le subagent `code-reviewer` selon `CLAUDE.md` §13 et §16.

Scope demandé : $ARGUMENTS

## Détermination du scope

Selon `$ARGUMENTS` :

- **Vide ou `staged`** : reviews les changements stagés (`git diff --staged`).
- **`branch`** : reviews tous les changements de la branche par rapport à `develop` (`git diff develop...HEAD`).
- **`pr <num>`** : reviews la PR GitHub spécifiée (utilise `gh pr view <num>` et `gh pr diff <num>`).
- **`files <path>...`** : reviews les fichiers explicitement listés.

Si le scope est ambigu (rien stagé ET rien sur la branche par rapport à develop) : demande à l'utilisateur de clarifier.

## Procédure

### Étape 1 — Cadrer

Affiche au début :
```
Review déclenchée
Scope : <staged | branch | pr #N | files explicites>
Branche : <nom>
Commits inclus : <N> (depuis <SHA>)
Lignes changées : +X / -Y dans M fichiers
```

### Étape 2 — Délègue au subagent code-reviewer

Invoque le subagent `code-reviewer` avec le contexte clair :

> "Effectue une review complète sur [scope précis]. Suis ta méthode standard en 8 étapes : cadrage, checks automatiques, lecture commits, lecture code, audit par dimension, catégorisation findings, rapport, verdict. Applique l'archivage selon les critères contextuels. Tous les outputs respectent le format défini dans ton prompt système."

Le subagent prend le relais et exécute :
1. Cadrer le périmètre.
2. Exécuter `make lint`, `make typecheck`, `make test-*`, `make security`, etc.
3. Lire commits (`git log -p`).
4. Lire le code modifié et son contexte.
5. Auditer par dimension (TDD, archi, sécurité, perf, i18n, a11y, RTL, doc, workflow).
6. Catégoriser findings (BLOQUANT, IMPORTANT, SUGGESTION, NIT).
7. Produire le rapport au format standardisé.
8. Rendre verdict (APPROVED, CHANGES REQUESTED, BLOCKED).

### Étape 3 — Restitution

Le rapport généré par `code-reviewer` est présenté directement à l'utilisateur. Tu n'altères pas son contenu — c'est sa responsabilité.

### Étape 4 — Suggestions post-review

Selon le verdict :

- **APPROVED** : 
  > "Verdict APPROVED. Étapes suivantes recommandées :
  > 1. `/pre-push` si pas déjà fait
  > 2. `git push origin <branche>`
  > 3. Ouvrir une PR avec le template (`gh pr create`)"

- **CHANGES REQUESTED** :
  > "Verdict CHANGES REQUESTED. Adresse les N bloquants et M importants. Re-lance `/review` après corrections."

- **BLOCKED** :
  > "Verdict BLOCKED. Problème structurel détecté. Invoque le subagent `architect` pour reconsidérer l'approche avant de continuer."

## Cas particuliers

### Aucun changement à reviewer
Si `git diff --staged` est vide ET la branche est à jour avec develop : annonce qu'il n'y a rien à reviewer.

### Branche sans `develop` comme parent
Si la branche feature n'a pas été créée depuis `develop` (cas rare mais possible si projet vient d'être créé) : utilise `main` comme base de comparaison, mentionne-le explicitement.

### `gh` CLI absent pour scope `pr`
Si `gh` n'est pas installé et que `pr <num>` est demandé : suggère `gh auth login` ou utilise `git fetch origin pull/<num>/head:pr-<num>` comme fallback.

### Code-reviewer recommande des hand-offs
Si le rapport recommande d'invoquer `security-auditor`, `performance-optimizer`, ou `accessibility-i18n-auditor` : présente ces recommandations clairement et offre à l'utilisateur de déclencher la commande appropriée (`/security-scan`, `/perf-audit`, `/a11y-audit`).

## Règles strictes

### Tu ne fais pas la review toi-même
Tu **délègues** au subagent `code-reviewer`. Ne tente pas de produire le rapport directement. Le subagent a une posture, une méthode, et un format que tu ne dois pas dupliquer ou contourner.

### Tu n'altères pas le verdict
Si l'utilisateur dit "le verdict est trop sévère, change-le" : refuse. Le verdict est la responsabilité du subagent selon les règles du projet. Si l'utilisateur conteste une règle, c'est via un amendement de CLAUDE.md, pas via une override en passant.

### Tu rappelles la discipline §13 quand pertinent
Si après review l'utilisateur veut commit/push, rappelle :
- Pour commit : `/commit` (validation §13)
- Pour push : `/pre-push` doit être vert (couche 2 §12)

---

**Rappel** : la review est ce qui sépare un projet portfolio professionnel d'un projet d'école. On ne skip pas.
