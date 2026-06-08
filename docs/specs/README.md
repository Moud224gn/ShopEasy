# Specs Techniques

Ce dossier contient les specifications techniques des features non-triviales.

## Quand creer une spec

- Avant toute feature qui touche plusieurs apps Django ou plusieurs domaines
- Quand les criteres d'acceptation Gherkin de l'issue ne suffisent pas a guider l'implementation
- Quand une decision technique significative doit etre documentee avant le code
- Via la commande `/spec <issue-id>`

## Format attendu

```markdown
# Spec: <titre>

- **Issue** : #NNN
- **Auteur** : <nom>
- **Date** : YYYY-MM-DD
- **Statut** : Draft | Review | Approved | Implemented

## Contexte

Pourquoi cette feature existe-t-elle ? Quel probleme resout-elle ?

## Objectifs

- Objectif 1
- Objectif 2

## Non-objectifs (hors scope)

- Ce qui est explicitement exclu

## Design technique

### API (si applicable)

Endpoints, schemas request/response, codes d'erreur.

### Modeles (si applicable)

Schemas Django, relations, index.

### Frontend (si applicable)

Composants, routes, state management.

## Criteres d'acceptation (Gherkin)

Given ...
When ...
Then ...

## Considerations transversales

- **i18n** : impact sur les traductions FR/EN
- **a11y** : considerations WCAG 2.1 AA
- **Securite** : validations, permissions, audit log
- **Performance** : queries, cache, bundle size
- **Multi-currency** : si montants impliques

## Plan d'implementation

1. Etape 1 (avec estimation)
2. Etape 2
3. ...

## Questions ouvertes

- Question 1 ?
- Question 2 ?
```

## Exemple minimal

Voir `docs/specs/s1-health-endpoint.md` (a creer pour l'issue #3).
