---
description: Génère et revue une migration Django (DB schema). Délègue à architect pour le plan, fait la génération via Django, vérifie la zero-downtime safety, propose la séquence de déploiement.
argument-hint: "<description courte du changement de schema>  ex: add product variants, soft delete on orders"
allowed-tools: ["Bash", "Read", "Glob", "Grep"]
---

# /migrate — Migration Django avec review zero-downtime

Tu déclenches la génération et la review d'une migration Django selon les règles strictes de `docs/conventions/performance.md` (zero-downtime) et `docs/conventions/security.md` (audit log si nécessaire).

Description : $ARGUMENTS

## Note sur "migration"

Le mot "migration" peut signifier :
- **Migration Django DB** (cette commande, cas par défaut) — `python manage.py makemigrations`.
- **Migration de données** (data migration) — sous-cas de Django, géré ici.
- **Migration de code** (refactor) → utilise `/refactor`.
- **Migration infrastructure** (ex: changer de cloud) → délègue à `devops-engineer`.

Si ambigu : demande à l'utilisateur de clarifier.

## Vérification d'entrée

Si `$ARGUMENTS` est vide ou trop vague : demande description précise.

Exemples valides :
- "add `variants` field as JSONB to Product"
- "soft delete column on Order"
- "rename column `slug` to `url_slug` on Category"
- "add unique constraint on User.email when active"

## Procédure

### Étape 1 — Cadrer et évaluer le risque

Avant de générer, identifie le type de changement :

| Type | Risque | Stratégie |
|---|---|---|
| Add nullable column | Faible | Migration directe |
| Add NOT NULL column | **Élevé** | Zero-downtime obligatoire (nullable → backfill → NOT NULL) |
| Drop column | Élevé | Deprecation pendant 1-2 releases, puis suppression |
| Rename column | Élevé | Add nouveau → backfill → switch code → drop ancien |
| Add index | Moyen | `CONCURRENTLY` si table peuplée |
| Add unique constraint | Élevé | Validation des données avant, sinon migration peut bloquer |
| Drop table | Élevé | Backup, deprecation, audit log |
| Data migration | Variable | Selon volume — Celery async si > 10k rows |

Affiche :
```
Migration planifiée
Description : <résolu>
Type identifié : <type>
Risque : Faible | Moyen | Élevé
Stratégie : <direct | zero-downtime étapes>
```

### Étape 2 — Délègue à architect pour le plan

Invoque `architect` :

> "Plan une migration Django pour : [description]. Type : [identifié]. Risque : [niveau].
> 
> Produis un plan structuré :
> 1. **Modification du modèle Django** : code du champ/contrainte/index à ajouter.
> 2. **Stratégie zero-downtime** si table peuplée :
>    - Migration 1 : ajout nullable.
>    - Data migration (Celery si volume > 10k) : remplir les valeurs existantes.
>    - Migration 2 : ajout NOT NULL / contrainte.
>    Séquence des releases (une migration par release recommandé).
> 3. **Impact sur les services existants** : quels endpoints touchés, quel code applicatif à mettre à jour.
> 4. **Tests à ajouter** : test du modèle, test de la migration (data migration testée idempotemment), test de régression sur les endpoints.
> 5. **Audit log** : si le changement touche données sensibles ou contraintes business, audit log à émettre lors de l'application.
> 6. **Rollback strategy** : comment annuler si problème détecté en prod (la migration ne doit JAMAIS être destructive en une seule étape).
> 
> N'écris PAS le code de migration encore. Plan seulement."

### Étape 3 — Validation utilisateur du plan

Le subagent présente le plan. L'utilisateur valide :
- "ok plan" → on génère la migration Django.
- "amende: ..." → ajustement.
- "trop risqué, divise" → split en migrations plus petites.

### Étape 4 — Génération de la migration

Une fois le plan validé :

```bash
# Modifier le modèle Django selon le plan (par l'agent principal après validation)
# Puis :
python manage.py makemigrations --name <slug_descriptif>

# Inspect le fichier généré
ls -lh apps/api/shopeasy/<app>/migrations/
```

**Nommage** : explicite et descriptif via `--name`. Format : `<verb>_<object>_<context>` :
- `add_variants_to_product`
- `soft_delete_on_order`
- `rename_slug_to_url_slug_on_category`

### Étape 5 — Review de la migration générée

Lis le fichier généré et vérifie :

- **Opérations bien ordonnées** : ajout avant suppression, etc.
- **Pas de défauts dangereux** : `default=` sur ajout NOT NULL sur grosse table peut être lent.
- **Indexes** : si table > 1M lignes, `CREATE INDEX CONCURRENTLY` (via `RunSQL` avec `atomic=False`).
- **Compatibilité backward** : le code applicatif actuel doit pouvoir fonctionner pendant et après la migration.
- **Reversible** : `reverse_code` défini sur les `RunPython` ?

Si problèmes identifiés : édite le fichier de migration manuellement (l'agent principal fait l'édition après validation).

### Étape 6 — Tests

```bash
# Test que la migration s'applique proprement
make migrate

# Test reverse
python manage.py migrate <app> <previous_migration>
python manage.py migrate

# Test sur DB peuplée si data migration
# (utiliser fixtures volume réaliste)
```

### Étape 7 — Hand-off

- "Plan validé, migration générée, tests passent. Étapes recommandées :
  1. `/commit` la modification du modèle ET la migration ensemble (`feat(<app>): add <change>`)
  2. Si zero-downtime : prévoir la séquence sur plusieurs releases (Migration 1 → release → backfill → release → Migration 2)
  3. `/deploy-check` avant déploiement de la première release"

## Règles strictes

### Pas de migration directe sur prod
Une migration s'applique en staging d'abord (déclenchée par le pipeline CI/CD). Jamais `python manage.py migrate` sur prod en SSH.

### Pas de migration destructive en une étape
Drop column/table : toujours deprecation d'abord, drop dans une release ultérieure. Même règle pour rename.

### Migration et code dans le même commit
Une migration Django sans modif du modèle correspondante est suspecte (et inversement). Le commit doit contenir les deux.

### Vérifier les data migrations
Si `RunPython` présent dans la migration : test obligatoire sur volume représentatif. Une data migration qui prend 30 minutes en prod = downtime.

### Aucune migration sans backup
`/deploy-check` doit confirmer qu'un backup récent existe avant toute migration en prod.

## Cas particuliers

### Migration de renommage de table
Très risqué. Approche standard :
1. Créer la nouvelle table (Migration 1 + déploiement).
2. Triggers ou code applicatif écrit dans les deux tables (Migration 2 + déploiement).
3. Backfill async (data migration Celery).
4. Switch des lectures vers la nouvelle table (déploiement code).
5. Drop ancienne table (Migration N + déploiement après période de grace).

### Migration touchant audit log
L'audit log est append-only (CLAUDE.md §9). Aucune migration ne doit modifier ou supprimer des données dans `apps/audit/`. Si nécessaire : archivage vers cold storage, pas suppression.

### Migration multi-tenant
Si applicable (vendeurs avec données isolées) : migration appliquée par tenant via Celery, pas en bloc.

### Faux usage `/migrate`
Si l'utilisateur lance `/migrate` pour un refactor de code (pas DB) : redirige vers `/refactor`.

---

**Rappel** : une migration cassée en prod = downtime. Une migration sans plan = roulette russe. Le plan d'abord, toujours.
