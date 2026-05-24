# Gotchas — Pièges techniques documentés

> Document détaillé référencé par `CLAUDE.md` §17.
> Liste vivante des pièges spécifiques au projet. **Consulte ce fichier** quand tu touches à ces domaines pour la première fois.

**Règle de contribution** : quand tu découvres un nouveau piège en travaillant, ajoute-le ici dans la même PR. Ce fichier est précieux uniquement s'il est maintenu.

## Next.js 15 App Router

### Client Components ne peuvent pas être `async`
```typescript
// INTERDIT
'use client';
export default async function MyComponent() { ... }  // erreur build

// CORRECT
// Si async data fetch → Server Component
// Si interactif → 'use client' + useEffect/useQuery
```

### `'use client'` est viral
Tout import dans un Client Component devient client. Vérifie le bundle après avoir ajouté `'use client'` :
```bash
make perf-audit  # ou pnpm build && pnpm analyze
```

Si un composant Server Component lourd est tiré dans le bundle client par accident, le bundle explose.

### Server Actions
- `'use server'` en haut du fichier obligatoire.
- **Valider les inputs avec Zod, toujours**. Le client peut soumettre n'importe quoi.
- Retourner un objet sérialisable (pas de classes, pas de fonctions).
- Pour mutations : invalider le cache avec `revalidatePath()` ou `revalidateTag()`.

```typescript
'use server';

import { z } from 'zod';

const schema = z.object({ name: z.string().min(1).max(100) });

export async function updateName(formData: FormData) {
  const parsed = schema.safeParse({ name: formData.get('name') });
  if (!parsed.success) return { error: parsed.error.format() };
  // ... mutation
  revalidatePath('/account');
  return { success: true };
}
```

### `fetch` est cached par défaut
Piège pour données utilisateur — tous les users voient les mêmes données.

```typescript
// DANGEREUX (cache par défaut)
const data = await fetch('/api/me');

// CORRECT pour data utilisateur
const data = await fetch('/api/me', { cache: 'no-store' });
// ou avec revalidate
const data = await fetch('/api/products', { next: { revalidate: 60 } });
```

### next-intl en App Router
Ne pas mélanger les helpers serveur et client.
- **Server Component** : `getTranslations()` (async).
- **Client Component** : `useTranslations()` (hook).

```typescript
// Server
import { getTranslations } from 'next-intl/server';
const t = await getTranslations('cart');

// Client
'use client';
import { useTranslations } from 'next-intl';
const t = useTranslations('cart');
```

### Middleware Next.js et i18n
Le middleware next-intl doit être configuré avec les paths exclus (API, images, _next). Vérifie le `matcher` dans `middleware.ts`.

## Django 5.2 + DRF

### `UniqueConstraint` avec `condition` > `unique_together`
Préférer `UniqueConstraint(fields=[...], condition=Q(deleted_at__isnull=True))` car compatible avec le soft-delete.

```python
# CORRECT — compatible soft-delete
class Meta:
    constraints = [
        UniqueConstraint(
            fields=['email'],
            condition=Q(deleted_at__isnull=True),
            name='unique_active_email'
        )
    ]

# LIMITÉ — bloque même les comptes supprimés
class Meta:
    unique_together = ['email']
```

### `select_for_update()` dans les transactions checkout
**Obligatoire** pour prévenir l'overselling lors de checkouts concurrents.

```python
# orders/services.py
@transaction.atomic
def reserve_stock(order_items: list[OrderItem]) -> None:
    for item in order_items:
        product = Product.objects.select_for_update().get(id=item.product_id)
        if product.stock < item.quantity:
            raise OutOfStockError(product)
        product.stock -= item.quantity
        product.save()
```

Sans `select_for_update`, deux acheteurs peuvent réserver les 2 dernières unités simultanément → stock négatif.

### `@transaction.atomic` explicite
Sur toute mutation cross-table. Django n'autocommit pas les modifications multi-modèles dans une vue (sauf `ATOMIC_REQUESTS=True`).

### drf-spectacular et schemas custom
Si tu personnalises un endpoint (response non-standard, serializer dynamique) : décorer avec `@extend_schema`, sinon l'OpenAPI ment.

```python
@extend_schema(
    responses={200: ProductSerializer, 404: ErrorSerializer},
    parameters=[OpenApiParameter('include_variants', bool)],
)
def retrieve(self, request, *args, **kwargs):
    ...
```

### `gettext_lazy` vs `gettext`
- **`gettext_lazy`** dans les modèles, constantes, chemins évalués au démarrage.
- **`gettext`** (alias `_`) dans les vues, services, runtime.

Erreur classique : `gettext` dans un model field → la locale active au démarrage est figée, indépendamment de la requête.

### `bulk_create` ne déclenche pas les signaux
Si tu utilises `Model.objects.bulk_create(...)`, les signaux `pre_save`/`post_save` ne sont pas émis. Conséquences : index de recherche pas mis à jour, audit log pas écrit, cache pas invalidé.

Solution : itérer manuellement ou émettre les signaux explicitement.

### Migrations zero-downtime
Pour ajouter une colonne NOT NULL sur une table peuplée, sans downtime :

1. Migration 1 : ajouter la colonne `nullable=True`.
2. Backfill async (data migration Celery) : remplir les valeurs.
3. Migration 2 : passer en `NOT NULL`.

Faire ça en une seule migration sur une grosse table = lock long = downtime. Voir `docs/runbooks/zero-downtime-migrations.md`.

## Postgres 17

### JSONB indexes
- `GIN` index pour les requêtes de containment (`@>`, `?`) :
  ```sql
  CREATE INDEX product_attrs_gin ON catalog_product USING GIN (attributes);
  ```
- `BTREE` sur clé extraite pour égalité :
  ```sql
  CREATE INDEX product_attrs_color ON catalog_product ((attributes->>'color'));
  ```

Mélanger les deux types sur la même colonne = double maintenance, gain nul.

### Soft-delete partout
On utilise `deleted_at IS NULL` comme filtre par défaut, géré par `core/managers.py:SoftDeleteManager`.

```python
class Product(SoftDeleteModel):
    objects = SoftDeleteManager()  # filtre auto
    all_objects = models.Manager()  # accès brut, pour admin
```

Toujours filtrer dans les managers par défaut. Si tu vois `.all()` quelque part sans filtre, alarme.

### Migrations longues
- `ALTER TABLE` sur grosse table prend un lock exclusif.
- `CREATE INDEX CONCURRENTLY` à utiliser pour les index sur tables > 1M lignes (pas bloquant).
- En migration Django : `RunSQL` avec `atomic=False` pour `CREATE INDEX CONCURRENTLY`.

## RTL (Right-to-Left)

### `margin-left` cassera l'UI arabe
**Toujours** logical properties.

| Cas | Mauvais | Bon |
|---|---|---|
| Marge gauche | `ml-4`, `margin-left: 1rem` | `ms-4`, `margin-inline-start: 1rem` |
| Marge droite | `mr-4` | `me-4` |
| Position gauche | `left-0` | `start-0` |
| Position droite | `right-0` | `end-0` |
| Texte aligné | `text-left` | `text-start` |
| Bordure gauche | `border-l` | `border-s` |

### Icônes directionnelles à flipper
Chevrons, flèches retour, breadcrumb separators : `rtl:rotate-180` ou variant `rtl:` Tailwind.

```tsx
<ChevronRight className="rtl:rotate-180" />
<ArrowLeft className="rtl:rotate-180" />
```

Icônes universelles : panier, recherche, lock, user, settings. **Ne pas flipper.**

### Tests visuels obligatoires
`make test-rtl` après tout composant nouveau. Snapshots Playwright en `<html dir="rtl">`.

### Layouts flex/grid
Flexbox et CSS Grid avec `direction: rtl` mirrorent automatiquement `flex-direction: row`. Pas besoin de `flex-row-reverse` sauf cas particulier (où le sens est sémantique, pas directionnel).

## Multi-currency

### Ne JAMAIS additionner des montants de devises différentes
Sans conversion explicite via taux daté, l'opération est une erreur logique.

```python
# CATASTROPHIQUE
total = item_cad.amount + item_usd.amount  # ajoute 100 + 80 = 180 sans sens

# CORRECT
total_cad = item_cad + currency_service.convert(item_usd, target='CAD')
```

`py-moneyed` lève une exception si on tente d'additionner deux devises différentes sans conversion. Ne pas attraper cette exception silencieusement.

### Stockage en plus petite unité
- 19.99 CAD se stocke `{ amount: 1999, currency: "CAD" }`.
- Diviser par 100 **uniquement à l'affichage** (et seulement si la lib ne le fait pas pour toi).
- dinero.js et py-moneyed gèrent ça nativement.

### Arrondi
Bankers' rounding (round-half-to-even) par défaut dans les libs. Évite le biais positif du round-half-up.

Pour calculs fiscaux/légaux : appliquer les règles d'arrondi de la juridiction (cents au Canada, centimes en France, etc.).

### Devises sans subdivisions
Certaines devises (JPY, KRW, XOF, XAF) n'ont pas de subdivision décimale. La plus petite unité = 1 yen, 1 won, 1 franc CFA.

```python
# JPY : 1000 yens = Money(1000, 'JPY'), pas Money(100000, 'JPY')
```

Les libs gèrent ça automatiquement via les métadonnées ISO 4217, mais vérifie quand tu ajoutes une devise.

## PWA / Service Worker

### Cache empoisonné
- Versionner les caches par release : `shopeasy-v1.2.3`.
- Au boot du SW : purger les anciens caches.
- Sans ça, un utilisateur peut rester bloqué sur une ancienne version JS qui ne fonctionne plus avec la nouvelle API.

### `skipWaiting` et `clientsClaim`
Ces deux flags activent l'update du SW immédiatement après installation. Sans UX de notification, l'utilisateur peut perdre du state in-flight (formulaires non soumis, panier non sauvé).

Pattern recommandé : afficher un toast "Nouvelle version disponible. Recharger ?" avec bouton.

### Background sync
- Tester offline → online avec mutations en queue.
- Vérifier que les mutations sont rejouées dans l'ordre.
- Gérer les erreurs : si la mutation échoue côté serveur après replay, notifier l'utilisateur.

### iOS Safari et PWA
Limitations connues :
- Pas de push notifications natif (mais possible via web push depuis iOS 16.4).
- Stockage limité plus agressif (purgé en cas de pression mémoire).
- Pas d'install prompt natif (utiliser instructions manuelles).

### DevTools
- Chrome DevTools > Application > Service Workers pour debugger.
- Toggle "Update on reload" pendant le dev (sinon le SW persistant cause des confusions).

## Sécurité

### Refresh token rotation
Invalider l'ancien refresh **immédiatement** après émission du nouveau. Sinon : faille de replay (un attaquant qui vole un refresh peut l'utiliser tant qu'il n'est pas explicitement révoqué).

```python
# auth/services.py
def refresh_access_token(refresh_token: str) -> tuple[str, str]:
    payload = decode_and_verify(refresh_token)
    if blacklist.contains(payload['jti']):
        raise InvalidTokenError("Token already used (replay attempt)")
    
    blacklist.add(payload['jti'], ttl=payload['exp'] - now())  # invalide l'ancien IMMÉDIATEMENT
    
    new_access = generate_access(payload['user_id'])
    new_refresh = generate_refresh(payload['user_id'])  # nouveau jti
    
    return new_access, new_refresh
```

### Argon2id memory cost
- 64 MB minimum en prod.
- Mesurer le coût CPU sur l'infra avant de set définitivement — un user/seconde est typique pour login, plus de RAM = plus de sécurité mais plus de CPU.
- Voir `apps/api/shopeasy/settings/production.py:ARGON2_PARAMS`.

### JWT signing key rotation
Lors du changement de clé de signature :
- Période de grace : ancienne clé valide pour décodage seulement (pas d'émission) pendant la durée de vie max d'un token.
- Variables `JWT_SIGNING_KEY` (active) et `JWT_VERIFICATION_KEYS` (liste, inclut ancienne pendant la transition).

### CORS et credentials
`Access-Control-Allow-Credentials: true` ne fonctionne **jamais** avec `Access-Control-Allow-Origin: *`. Toujours spécifier l'origin précis.

### Sessions Django et SameSite
Cookies de session avec `SameSite=Strict` peuvent casser les flows OAuth depuis providers externes. Pour OAuth : flow dédié avec state token, ou cookie séparé `SameSite=Lax`.

## CI/CD

### Cache npm/pnpm en CI
Sans cache, chaque CI run réinstalle tout. Avec cache : 30s vs 3 min.

```yaml
- uses: actions/cache@v4
  with:
    path: ~/.local/share/pnpm/store
    key: pnpm-${{ hashFiles('pnpm-lock.yaml') }}
```

### Tests en parallèle
- pytest avec `pytest-xdist` : `pytest -n auto`.
- Vitest parallèle par défaut.
- Playwright workers : ajuster selon CPU disponible.

### Docker layer caching
- Ordonner les `COPY` du moins fréquent au plus fréquent.
- `COPY package.json pnpm-lock.yaml ./` avant `COPY .` pour cacher l'install.
- BuildKit cache mounts pour pnpm/uv : `RUN --mount=type=cache,target=/root/.local/share/pnpm/store`.

### Secrets dans GitHub Actions
- Jamais d'`echo $SECRET`. GitHub masque mais peut leaker via subprocess.
- Toujours via les variables d'env masquées.
- Pour les valeurs JSON : `${{ toJSON(secrets.MY_KEY) }}`.

## Divers

### Timezone UTC partout côté backend
`USE_TZ = True` dans `settings.py`, jamais touché. Tous les `DateTimeField` sont en UTC en DB.

Conversion à l'affichage uniquement, selon la préférence utilisateur.

### Floats pour les montants — interdit
Erreurs d'arrondi binaire connues :
```python
>>> 0.1 + 0.2
0.30000000000000004
```

Sur un total de panier, ça donne des bugs business-critical. Toujours Money / Decimal.

### Mutability des objets — pièges Python
```python
def bad(items: list = []):  # piège : default mutable partagé entre appels
    items.append(1)
    return items
```

Utiliser `None` + check :
```python
def good(items: list | None = None):
    items = items or []
    ...
```

### Tests flaky
- Tests dépendant du timing : utiliser `freezegun` (Python) ou Vitest fake timers.
- Tests dépendant de l'ordre : `pytest -p no:randomly` (pour debug, jamais en CI).
- Tests dépendant du réseau : MSW ou VCR. Jamais d'appel réseau réel dans les tests.

Si un test devient flaky : ouvrir une issue, désactiver temporairement, fixer dans la semaine. Tolérance flakiness en CI = zéro à long terme.

---

**Liste vivante.** Ajoute tout nouveau piège ici, dans la PR où tu l'as rencontré.
