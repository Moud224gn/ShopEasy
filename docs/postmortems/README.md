# Postmortems

Ce dossier contient les postmortems blameless des incidents et retrospectives.

## Quand creer un postmortem

- Apres tout incident affectant la production (downtime, data loss, security breach)
- Apres un test flaky persistant
- En fin de sprint pour la retrospective
- Via la commande `/postmortem <incident>`

## Principes

1. **Blameless** : on analyse les systemes, pas les personnes
2. **Factuel** : timeline basee sur les logs et metriques
3. **Actionable** : chaque postmortem produit des action items avec owners et deadlines
4. **Prioritaire** : les action items entrent dans le sprint suivant en priorite haute

## Format attendu (Google SRE style)

```markdown
# Postmortem: <titre>

- **Date de l'incident** : YYYY-MM-DD HH:MM - HH:MM (UTC)
- **Auteur** : <nom>
- **Severite** : SEV1 | SEV2 | SEV3 | SEV4
- **Impact** : <description de l'impact utilisateur>
- **Statut** : Draft | Review | Final

## Resume executif

2-3 phrases resumant l'incident et sa resolution.

## Timeline

| Heure (UTC) | Evenement |
|-------------|-----------|
| HH:MM | Premier signe du probleme |
| HH:MM | Alerte declenchee |
| HH:MM | Debut de l'investigation |
| HH:MM | Root cause identifiee |
| HH:MM | Fix deploye |
| HH:MM | Verification complete |

## Root cause

Description technique de la cause racine.

## Detection

Comment l'incident a-t-il ete detecte ? Alerting ? Utilisateur ? Monitoring ?

## Resolution

Etapes prises pour resoudre l'incident.

## Impact

- Utilisateurs affectes : <nombre>
- Duree de l'impact : <duree>
- Revenue impact : <si applicable>
- Data loss : <si applicable>

## Lessons learned

### Ce qui a bien fonctionne

- Point positif 1
- Point positif 2

### Ce qui n'a pas fonctionne

- Point negatif 1
- Point negatif 2

### Points chanceux

- Element de chance qui a limite l'impact

## Action items

| Action | Owner | Priorite | Deadline | Issue |
|--------|-------|----------|----------|-------|
| <action> | <nom> | P0/P1/P2 | YYYY-MM-DD | #NNN |

## References

- Liens vers dashboards, logs, issues, PRs
```

## Nomenclature des fichiers

`YYYY-MM-DD-<slug>.md`

Exemples :
- `2026-06-15-api-timeout.md`
- `2026-07-01-sprint-2-retro.md`
