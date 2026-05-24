---
description: Validation pré-déploiement (staging ou prod). Délègue au subagent devops-engineer. Vérifie health checks, secrets, migrations, smoke tests, rollback plan, observabilité.
argument-hint: "[--staging | --prod]  par défaut: staging"
allowed-tools: ["Bash", "Read", "Glob", "Grep"]
---

# /deploy-check — Validation pré-déploiement

Tu déclenches une checklist pré-déploiement via le subagent `devops-engineer`. **Aucun déploiement (surtout prod) sans cette validation verte.**

Cible : $ARGUMENTS (`--staging` par défaut, ou `--prod` pour les checks renforcés)

## Détection du mode

- **`--staging`** ou vide : checks staging (déploiement automatique sur `develop` merge).
- **`--prod`** : checks renforcés pour production (déclenchement par tag git, validation supplémentaire requise).

Si `--prod` : exige confirmation explicite de l'utilisateur avant de continuer ("Je confirme que je veux déployer en prod").

## Procédure

### Étape 1 — Cadrer

Affiche :
```
Pré-déploiement validation
Cible : staging | PRODUCTION
Date : <timestamp>
Branche : <nom>
Tag (si prod) : <vX.Y.Z>
Build SHA : <sha>
```

### Étape 2 — Délègue au subagent devops-engineer

Invoque `devops-engineer` :

> "Exécute une checklist pré-déploiement [staging|prod] pour ShopEasy. Vérifie systématiquement :
> 
> 1. **CI verte** sur la branche / le tag à déployer.
> 2. **`make pre-push`** vert avec marqueur récent (< 1h).
> 3. **Migrations Django** :
>    - Migrations non-appliquées identifiées (`python manage.py showmigrations | grep '\\['`).
>    - Stratégie zero-downtime confirmée si table peuplée touchée.
>    - Plan de rollback documenté.
> 4. **Secrets** :
>    - Tous les secrets requis présents dans le secret store de l'env cible (AWS Secrets Manager pour prod, GCP Secret Manager pour staging).
>    - External Secrets Operator synchronisé.
>    - Aucun `.env` local committé par erreur.
> 5. **Health checks** :
>    - Endpoints `/health` (liveness) et `/ready` (readiness) implémentés.
>    - Probes K8s configurées.
> 6. **Observabilité** :
>    - Sentry release créée pour la version.
>    - Métriques OpenTelemetry actives.
>    - Dashboards Grafana à jour si nouveau composant.
> 7. **Audit log** opérationnel (table `audit` accessible, retention configurée).
> 8. **Smoke tests** post-deploy définis :
>    - URLs de test pour vérifier la santé.
>    - Critères d'échec clairs (latence, status code).
> 9. **Rollback plan** :
>    - Procédure documentée dans `docs/runbooks/`.
>    - Rollback testé en staging avant prod.
>    - Communication channel actif (Slack / PagerDuty).
> 10. **Spécifique prod uniquement** :
>     - Approval reviewer GitHub Environment.
>     - Fenêtre de déploiement appropriée (pas vendredi soir, pas heures de pointe).
>     - Backup DB récent (< 6h).
>     - Communication équipe.
> 
> Produis un rapport au format ci-dessous avec verdict explicite."

### Étape 3 — Restitution

Le subagent produit le rapport :

```
=== Pre-deployment validation : <staging|prod> ===

| # | Check | Statut | Notes |
|---|---|---|---|
| 1 | CI verte | OK/KO | <run link> |
| 2 | make pre-push récent | OK/KO | <timestamp> |
| 3 | Migrations zero-downtime | OK/KO | <plan> |
| ... | ... | ... | ... |

Verdict : [READY_TO_DEPLOY | BLOCKED]

[Si BLOCKED] :
Issues à résoudre avant déploiement :
- ...
- ...

[Si READY_TO_DEPLOY] :
Commandes recommandées pour déclencher :
- Staging : `git push origin develop` (auto-deploy)
- Prod : `git tag v<X.Y.Z> && git push origin v<X.Y.Z>`

Post-déploiement immédiat :
- Vérifier dashboards Grafana
- Lancer smoke tests
- Surveiller Sentry pour nouvelles erreurs (5 min minimum)
```

### Étape 4 — Action selon verdict

- **READY_TO_DEPLOY** : "Validation OK. Tu peux déclencher le déploiement avec [commande]."
- **BLOCKED** : "Déploiement BLOQUÉ. Adresse les checks rouges, relance `/deploy-check`."

### Étape 5 — Post-déploiement

Une fois le déploiement déclenché :
- Suggère de monitorer Grafana / Sentry pendant 15 min minimum.
- Smoke tests exécutés automatiquement par la pipeline.
- Si problème détecté : invoque `/postmortem <incident>` immédiatement après stabilisation.

## Règles strictes

### Pas de bypass de la checklist
Si l'utilisateur dit "skip cette vérification, urgent" : refuse. Cite §12 (la CI ne doit jamais détecter ce qu'on n'a pas vu) et l'immutability principle du `devops-engineer` (staging d'abord).

### Production exige confirmation explicite
Pour `--prod`, l'utilisateur doit confirmer **explicitement** vouloir déployer. Pas de "ok" passif. Une phrase comme "je confirme déploiement prod de v1.2.3".

### Vendredi soir, heures de pointe
Le subagent flag les déploiements aux heures à risque (vendredi 17h+, weekends, périodes de fort trafic). Refuse pas absolument, mais demande justification (hotfix justifié vs feature normale).

### Pas de prod sans staging récent
Si la même version (SHA) n'a pas tourné en staging > 1h : refuse. La période de soak en staging est nécessaire pour détecter les régressions.

## Cas particuliers

### Hotfix urgent
Si hotfix avec justification :
- Process accéléré documenté dans `docs/runbooks/emergency-hotfix.md`.
- Staging quand même (peut être 15 min seulement).
- Tag spécial (`v1.2.3-hotfix.1`).
- Postmortem obligatoire après stabilisation.

### Rollback en cours
Si une release précédente est en rollback : refuse nouveau déploiement avant que la situation soit stabilisée.

### Migration de schema risquée
Si `/deploy-check` détecte une migration Django avec risque élevé sans plan zero-downtime documenté : hand-off à `/migrate` pour replanifier avant déploiement.

### Première mise en prod
Si c'est le premier déploiement prod du projet (jamais de version `v*` existante) : checks renforcés incluant audit complet `/security-scan` + `/a11y-audit` + `/perf-audit` sur les routes critiques.

## Hand-offs typiques

- Si CI rouge : hand-off à `code-reviewer` pour identifier les fixes.
- Si secrets manquants : `devops-engineer` direct pour configurer.
- Si migration risquée : `/migrate` pour replanifier.
- Si incident post-déploiement : `/postmortem`.

---

**Rappel** : la production est sacrée. Un déploiement précipité = un incident à 3h du matin. La checklist coûte 5 min, l'incident coûte une nuit.
