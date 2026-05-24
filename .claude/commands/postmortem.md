---
description: Analyse blameless post-incident structurée (Google SRE style). Délègue à architect ou devops-engineer selon nature. Produit document dans docs/postmortems/ avec timeline, root cause, action items, lessons learned.
argument-hint: "<description courte de l'incident>  ex: cart-overselling-2026-03-14, payment-decline-loop"
allowed-tools: ["Bash", "Read", "Glob", "Grep", "WebSearch"]
---

# /postmortem — Postmortem blameless

Tu déclenches une analyse post-incident structurée selon les principes Google SRE (**blameless**, factuel, orienté apprentissage). Le but n'est jamais de blâmer une personne — c'est d'identifier les failles **systémiques** qui ont permis l'incident.

Incident : $ARGUMENTS

## Quand faire un postmortem ?

Obligatoire :
- Incident production avec impact utilisateur (downtime, data loss, sécurité).
- Test flaky récurrent (> 3 occurrences en 1 mois).
- Régression sérieuse détectée en CI/staging avant prod.
- Près-miss significatif (incident évité de justesse).

Optionnel mais recommandé :
- Refactor qui a pris 3x le temps estimé.
- Bug qui a survécu plusieurs sprints malgré tests.
- Décision technique qu'on regrette.

## Vérification d'entrée

Si `$ARGUMENTS` est vide ou trop vague (`bug`) : demande description précise. Format suggéré : `<nature>-<date>` ou identifiant.

## Procédure

### Étape 1 — Cadrer l'incident

Affiche :
```
Postmortem initié
Incident : <description>
Date : <timestamp>

Type identifié : production | staging | test-flaky | near-miss | retrospective
```

Pose les questions de base :
- Quand l'incident a-t-il commencé ? (heure de détection vs heure de début réel)
- Comment a-t-il été détecté ? (alerte auto, user report, observation)
- Quelle a été la réponse immédiate ?
- Quand est-il considéré résolu ?
- Quelle a été la durée totale (TTR — Time To Resolve) ?
- Quel est l'impact mesuré (users impactés, requêtes échouées, revenue perdu) ?

### Étape 2 — Délègue au subagent approprié

Le choix dépend de la nature :

- **Incident applicatif** (bug, regression, race condition) → `architect` (recul système).
- **Incident infrastructure** (déploiement raté, pipeline, K8s, DB) → `devops-engineer`.
- **Incident sécurité** (faille exploitée, breach) → `security-auditor` (avec urgence).
- **Test flaky** → `test-writer` (debug du test).

Invoque le subagent avec :

> "Conduis un postmortem blameless pour l'incident : [description]. Suis le format Google SRE :
> 
> 1. **Summary** (1-2 phrases) : ce qui s'est passé.
> 2. **Impact** : utilisateurs affectés, durée, revenue/SLO impact.
> 3. **Timeline** : chronologie précise des événements (détection, escalation, mitigation, résolution).
> 4. **Root cause analysis** :
>    - Cause technique immédiate.
>    - Causes contributives.
>    - **Pourquoi cela a-t-il pu arriver ?** (5 whys jusqu'à la cause systémique).
>    - **Pourquoi cela n'a-t-il pas été détecté plus tôt ?** (gaps dans monitoring/tests/process).
> 5. **What went well** : ce qui a bien fonctionné (réponse, communication, outils).
> 6. **What went poorly** : ce qui n'a pas bien fonctionné (sans blamer personne).
> 7. **Lessons learned** : apprentissages partageables.
> 8. **Action items** : liste **concrète, ownerée, datée**. Chaque action item = une issue GitHub à créer.
> 9. **Prevention** : comment éviter cette catégorie d'incidents à l'avenir.
> 
> Format **blameless** : décris les actions sans pointer les individus. 'Le déploiement a été poussé sans run pre-push' plutôt que 'X a oublié pre-push'.
> 
> Écris le fichier dans `docs/postmortems/<date>-<slug>.md`."

### Étape 3 — Validation et écriture

Le subagent présente le draft. L'utilisateur valide ou amende.

Une fois validé, fichier écrit dans `docs/postmortems/<date>-<slug>.md`.

### Étape 4 — Création des action items

Pour chaque action item identifié, suggère création d'issue GitHub :

```bash
gh issue create \
  --title "[Postmortem 2026-03-14] Add nplusone CI gate" \
  --body "From postmortem of cart-overselling-2026-03-14. Action item: ensure N+1 detection runs in CI to prevent recurrence." \
  --label "postmortem,tech-debt" \
  --milestone "Sprint 7"
```

Les issues créées sont **trackées avec deadline**. Un action item sans owner ni deadline n'est pas un action item, c'est un vœu pieux.

### Étape 5 — Hand-offs

Après postmortem, selon les action items :
- Modifs de process (CLAUDE.md ou conventions) → PR de mise à jour.
- Test de régression à ajouter → `test-writer`.
- Refactor architectural identifié → `/refactor`.
- Convention à formaliser → `/adr`.
- Tests perf à ajouter → `test-writer` + `performance-optimizer`.

## Format du postmortem

```markdown
# Postmortem : <Incident name>

- **Date incident** : YYYY-MM-DD HH:MM TZ
- **Date postmortem** : YYYY-MM-DD
- **Auteurs** : <noms>
- **Statut** : Draft | Reviewed | Approved
- **Severity** : Sev-1 (downtime total) | Sev-2 (impact partiel) | Sev-3 (mineur)

## Summary

[1-2 phrases factuelles]

## Impact

- Durée : XX min (de HH:MM à HH:MM)
- Utilisateurs affectés : ~N (estimation basée sur ...)
- Requêtes échouées : N
- Revenue impact (estimé) : ~$XX
- SLO impact : XX% sur la fenêtre 30j

## Timeline

| Time | Event |
|---|---|
| 14:32 | Première erreur dans Sentry (404 sur /checkout) |
| 14:35 | Alert Grafana triggered (p95 latency > 2s) |
| 14:37 | Engineer notified via PagerDuty |
| 14:42 | Investigation : query lente identifiée |
| 14:50 | Index missing identifié comme cause |
| 15:05 | Rollback déployé |
| 15:08 | Service rétabli |

## Root cause

### Technical cause
[Cause immédiate, technique, factuelle]

### Contributing factors
- ...
- ...

### Five whys
1. Pourquoi l'incident s'est-il produit ? → ...
2. Pourquoi ... ? → ...
3. Pourquoi ... ? → ...
4. Pourquoi ... ? → ...
5. Pourquoi ... ? → [cause systémique]

### Why wasn't it caught earlier ?
- Test ... manquait dans la CI.
- Monitoring sur ... pas configuré.
- Process de review ne couvrait pas ...

## What went well

- ...
- ...

## What went poorly

- ... (factuel, sans pointer de personnes)
- ...

## Lessons learned

- ...
- ...

## Action items

| # | Action | Owner | Issue | Deadline | Status |
|---|---|---|---|---|---|
| 1 | Add nplusone CI gate | @userX | #234 | Sprint 7 | Open |
| 2 | Document checkout deployment runbook | @userY | #235 | Sprint 7 | Open |
| 3 | Add load test for /checkout endpoint | @userZ | #236 | Sprint 8 | Open |

## Prevention

[Comment empêcher cette catégorie d'incidents : process, outils, archi, tests]

## References

- Sentry issue : [link]
- Grafana dashboard : [link]
- ADR liée : [link si applicable]
- PR du fix : [link]
```

## Règles strictes

### Blameless absolu
Le postmortem ne nomme **jamais** un individu en faute. "Le système permettait de pousser sans pre-push" et non "X a oublié pre-push".

### Tous les action items ont un owner et une deadline
Sans ça, ce sont des vœux pieux, pas des actions.

### Pas de postmortem caché
Tous les postmortems sont dans `docs/postmortems/` versionnés. Même pour les incidents internes. La transparence est la base de l'apprentissage organisationnel.

### Pas de précipitation
Un postmortem fait à chaud (< 2h après résolution) est souvent superficiel. Recommande de revenir dessus 1-2 jours après pour les 5 whys profonds.

### Suivi des action items
Les action items créés sont trackés avec deadline. Si non-respectés : escalation, ils ne disparaissent pas dans le néant.

## Cas particuliers

### Incident sécurité
Postmortem ENCORE plus rigoureux :
- Notification utilisateurs si data leak (selon juridiction, RGPD 72h).
- Audit log review.
- Hand-off à `security-auditor` pour audit post-incident.
- Possiblement à huis-clos si exploitation active (workflow différent).

### Test flaky
Postmortem plus court. Focus : pourquoi flaky, fix, prevention de futurs flakies.

### Incident causé par dépendance externe (ex: AWS down)
Postmortem porte sur : qu'aurions-nous pu faire pour mitiger ? (circuit breakers, fallback, retry, graceful degradation).

### Postmortem sans incident (retrospective)
Si l'utilisateur lance `/postmortem` pour une rétro de sprint ou un projet qui a déraillé : OK, format adapté (focus sur ce qu'on a appris, sans le côté urgence).

---

**Rappel** : un incident sans postmortem est un incident gaspillé. La même cause systémique va causer le prochain incident. Investir 2h dans un bon postmortem évite 20h dans le prochain incident.
