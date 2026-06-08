# Runbooks

Ce dossier contient les runbooks operationnels pour les procedures de maintenance, deploiement, et incident response.

## Quand creer un runbook

- Avant tout deploiement d'une nouvelle infrastructure
- Pour documenter une procedure de recovery ou rollback
- Quand une operation manuelle doit etre reproductible par n'importe quel membre de l'equipe
- Apres un incident dont la resolution doit etre documentee

## Format attendu

```markdown
# Runbook: <titre>

- **Derniere mise a jour** : YYYY-MM-DD
- **Auteur** : <nom>
- **Criticite** : Low | Medium | High | Critical
- **Temps estime** : <duree>

## Quand utiliser ce runbook

Description des situations declenchant cette procedure.

## Pre-requis

- Acces necessaires (AWS, GCP, kubectl, etc.)
- Outils requis
- Variables d'environnement

## Procedure

### Etape 1: <titre>

```bash
# Commande a executer
```

**Verification** : Comment verifier que l'etape a reussi.

### Etape 2: <titre>

...

## Rollback

Si la procedure echoue, voici comment revenir a l'etat precedent.

## Verification finale

Comment confirmer que la procedure complete est reussie.

## Contacts

- Oncall : <contact>
- Escalade : <contact>

## Historique

| Date | Modification | Auteur |
|------|--------------|--------|
| YYYY-MM-DD | Creation | <nom> |
```

## Exemples de runbooks a creer

- `deploy-staging.md` : Deploiement sur staging
- `deploy-production.md` : Deploiement sur production
- `rollback-migration.md` : Rollback d'une migration Django
- `scale-up-api.md` : Augmentation de capacite API
- `rotate-secrets.md` : Rotation des secrets
