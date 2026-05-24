---
description: Planification de sprint (début de sprint). Délègue à architect pour priorisation backlog, identification des dépendances, génération user stories au format Gherkin, estimation des risques techniques.
argument-hint: "[<numéro de sprint> ou <focus du sprint>]  ex: 3, payments-foundation"
allowed-tools: ["Bash", "Read", "Glob", "Grep", "WebSearch"]
---

# /sprint-plan — Planification de sprint

Tu déclenches une session de planification de sprint via le subagent `architect`. Aligné avec l'organisation agile du projet INF1763 (sprints de 2-3 semaines, voir CLAUDE.md §2 et `docs/Roadmap.md` si présent).

Sprint : $ARGUMENTS

## Procédure

### Étape 1 — Cadrer le sprint

Si `$ARGUMENTS` est numérique : identifier le sprint correspondant.
Si `$ARGUMENTS` est descriptif : utiliser comme focus.
Si vide : demander à l'utilisateur sprint courant ou prochain.

Affiche :
```
Sprint planning initié
Sprint cible : <Sprint N> | <focus thématique>
Période estimée : <dates si dispo>
```

### Étape 2 — Collecter le contexte

```bash
# Backlog actuel
gh issue list --milestone "Sprint <N>" --json number,title,labels,assignees

# Issues sans milestone (backlog)
gh issue list --search "no:milestone" --json number,title,labels --limit 50

# Sprint précédent (vélocité)
gh issue list --milestone "Sprint <N-1>" --state closed

# Postmortems récents (action items)
ls docs/postmortems/

# ADRs récentes
ls docs/adr/ | tail -5
```

### Étape 3 — Délègue au subagent architect

Invoque `architect` avec contexte :

> "Plan le Sprint [N|focus] pour ShopEasy. Le projet est en sprints de 2 semaines (méthode agile, contexte INF1763). Vélocité projet : [extraite des sprints précédents si dispo, sinon estimation à faire].
> 
> Produis un plan structuré :
> 
> 1. **Objectif du sprint** (Sprint Goal) : phrase courte qui résume la valeur livrée. Si focus thématique fourni, l'utiliser comme guide.
> 
> 2. **User stories candidates** (issues GitHub priorité haute, action items des postmortems, dette technique critique) :
>    - Format Gherkin pour chaque story.
>    - Estimation S/M/L (ou points si le projet utilise).
>    - Dépendances entre stories.
> 
> 3. **Stories engagées** : la sélection en fonction de la vélocité disponible (1 personne avec Claude Code, ~30-40 heures effectives par sprint). Ne pas surcharger — la qualité prime sur le volume.
> 
> 4. **Découpage technique** : pour chaque story, briève idée d'implémentation (apps Django concernées, écrans Next.js, conventions à appliquer).
> 
> 5. **Risques techniques** identifiés et plan de mitigation.
> 
> 6. **Specs à rédiger** : stories non-triviales qui nécessitent `/spec <issue>` avant code.
> 
> 7. **ADRs potentielles** identifiées : décisions architecturales que le sprint va déclencher.
> 
> 8. **Definition of Done** rappelée pour ce sprint.
> 
> 9. **Risques agile** : ce qui pourrait dérailler le sprint (dépendances externes, attente de validation, manque de clarté sur certaines stories).
> 
> 10. **Hors scope assumé** : ce qui est volontairement reporté au sprint suivant.
> 
> Reste réaliste sur la capacité. Mieux vaut un sprint sous-engagé qui livre que sur-engagé qui glisse."

### Étape 4 — Présentation et validation

Le subagent présente le plan. L'utilisateur :
- Valide → on passe à l'étape 5 (création des issues).
- Amende → ajustements du plan.
- Reporte → certaines stories vers le prochain sprint.

### Étape 5 — Mise à jour du backlog GitHub

Pour chaque story du sprint engagé :

```bash
# Si issue n'existe pas encore, créer
gh issue create \
  --title "<scope>: <story>" \
  --body "$(cat <<'EOF'
## User story
As <user type>, I want <action> so that <benefit>.

## Acceptance criteria (Gherkin)
Given <context>
When <action>
Then <expected result>

## Technical notes
- Apps touchées : ...
- ADR potentielle : ...
- Spec à rédiger : Oui/Non

## Definition of Done
Voir CLAUDE.md §18

## Estimation
S | M | L
EOF
)" \
  --label "sprint-<N>,story" \
  --milestone "Sprint <N>"

# Si existe, ajouter au milestone
gh issue edit <num> --milestone "Sprint <N>"
```

### Étape 6 — Archivage du plan

Écrit le sprint plan dans `docs/sprints/sprint-<N>.md` (créé par l'agent principal après validation).

Format :
```markdown
# Sprint <N>

- **Période** : <dates>
- **Sprint Goal** : <phrase>
- **Vélocité cible** : <points>
- **Statut** : Planning | In Progress | Closed

## Stories engagées
[Liste avec issue links]

## Specs à rédiger
[Liste]

## ADRs potentielles
[Liste]

## Risques
[Liste]

## Hors scope
[Liste]
```

### Étape 7 — Hand-offs

- Specs à rédiger → `/spec <issue>` pour chacune.
- ADRs potentielles → `/adr <decision>` quand elles arrivent.
- Stories prêtes à démarrer → `/tdd <description>` quand on attaque la première.

## Règles strictes

### Vélocité réaliste
Un sprint sur-engagé est un sprint qui glisse. Pour un solo dev + Claude Code : 30-40h effectives sur 2 semaines (en supposant temps réservé pour la veille, la doc, les reviews).

### Pas de story sans critères d'acceptation
Une story floue produit du code flou. Format Gherkin obligatoire avant entrée au sprint.

### Action items de postmortems prioritaires
Les action items issus de postmortems précédents ont priorité haute dans le sprint planning. Reporter un action item est risquer la récidive de l'incident.

### Hors scope explicite
Ce qui est repoussé au sprint suivant doit être explicitement listé. Pas de "on verra".

## Cas particuliers

### Premier sprint du projet (Sprint 1)
Focus : fondations (CI/CD setup, premiers ADRs, structure projet). User stories applicatives volontairement légères pour valider l'infra.

### Sprint après incident grave
Premières stories = action items du postmortem. Reste du sprint = backlog normal réduit.

### Sprint pré-démo/soutenance
Réserver 20-30% du temps pour stabilisation, doc, polish. Pas de features risquées en fin de sprint avant démo.

### Sprint hors-cycle (hotfix sprint)
Format léger : seulement les fixes critiques, pas de nouvelles features. Doit être suivi d'un postmortem.

## Hand-offs en cascade

Pendant le sprint, le workflow naturel :
- `/spec` sur chaque story non-triviale.
- `/tdd` pour démarrer chaque story.
- `/commit` à chaque phase TDD.
- `/review` avant chaque push.
- `/pre-push` avant chaque push.
- Audits ciblés (`/security-scan`, `/perf-audit`, `/a11y-audit`, `/i18n-check`) selon le domaine.
- `/deploy-check` avant déploiement.
- `/postmortem` si incident.

À la fin du sprint : rétrospective (peut être un `/postmortem retrospective` ou format dédié).

---

**Rappel** : un bon sprint planning vaut 10 heures de dev. Un mauvais sprint planning coûte 50 heures de chaos.
