# Performance — Mobile-first, PWA, Backend

> Document détaillé référencé par `CLAUDE.md` §10.
> **Lis ce fichier avant toute optim, tâche perf, ou ajout de feature impactant le bundle.**

ShopEasy cible des marchés où la connectivité mobile lente est la norme. Chaque kilooctet et chaque milliseconde compte. **N'optimise jamais à l'aveugle** — mesure d'abord, optimise ensuite.

## 1. Budgets de performance (gates CI)

### Core Web Vitals (gate Lighthouse CI)
| Métrique | Cible | Bloquant si dépassement |
|---|---|---|
| LCP (Largest Contentful Paint) | < 2.5s | Oui |
| INP (Interaction to Next Paint) | < 200ms | Oui |
| CLS (Cumulative Layout Shift) | < 0.1 | Oui |
| FCP (First Contentful Paint) | < 1.8s | Warning |
| TTFB (Time to First Byte) | < 600ms | Warning |

### Bundle JS
| Élément | Budget |
|---|---|
| **First paint JS gzipped** | < 150kb |
| Première interaction utile | < 300kb cumulé |
| Dépendance individuelle | < 50kb gzipped sans ADR |
| Image hero LCP | < 200kb |

Bundle analyzer : `make perf-audit` génère un rapport visuel à chaque exécution. CI bloque si dépassement non justifié.

## 2. Frontend — Next.js et React

### Code splitting
- Next.js le fait nativement **par route** avec App Router.
- Ne le casse pas avec des imports synchrones lourds en haut de page.
- Dynamic imports pour composants conditionnels lourds :
  ```typescript
  const HeavyChart = dynamic(() => import('@/components/HeavyChart'), {
    loading: () => <Skeleton />,
    ssr: false, // si dépendant du window
  });
  ```

### Tree shaking
- Imports nommés uniquement sur ton code (`import { foo } from './bar'`).
- `import *` toléré uniquement pour libs idiomatiques documentées (`import * as z from 'zod'`).
- Vérifie avec `make perf-audit` qu'aucune lib ne ramène involontairement son contenu complet.

### Server Components par défaut
- App Router rend côté serveur par défaut. Profite-en — moins de JS client = plus rapide.
- `'use client'` uniquement quand nécessaire (state, event handlers, hooks navigateur).
- **Justifie en commentaire** chaque `'use client'`.

### Memoization — mesurée
React.memo, useMemo, useCallback **ne sont pas gratuits**. Le diff de props et le calcul d'égalité coûtent. Utilise-les uniquement quand un profil React DevTools montre qu'un composant re-render inutilement et coûte cher.

Par défaut : ne pas memoizer. Mesurer ensuite.

### Patterns d'interaction

#### Debounce sur recherche
```typescript
const debouncedSearch = useDebouncedCallback((value: string) => {
  setSearchQuery(value);
}, 300); // 300ms minimum
```

#### Virtualization sur grandes listes
Listes > 50 items : utiliser `@tanstack/react-virtual`.
```typescript
const virtualizer = useVirtualizer({
  count: items.length,
  estimateSize: () => 80,
  overscan: 5,
});
```

#### Prefetch des routes probables
```tsx
<Link href="/products/123" prefetch>
  Voir le produit
</Link>
```

Sur catalogue : prefetch des 6 produits visibles au-dessus du fold. Désactiver le prefetch global pour éviter la sur-consommation data sur mobile.

### Images
- `next/image` partout. Jamais de `<img>` raw.
- Format par défaut : **AVIF** avec fallback WebP, JPEG en dernier recours.
- `priority` sur l'image LCP (hero, première image catalogue).
- `loading="lazy"` par défaut sur toutes les autres.
- **`width` et `height` explicites** pour éviter CLS.
- `sizes` adapté au DPR mobile : `sizes="(max-width: 640px) 100vw, 50vw"`.

### Fonts
- `next/font/google` ou `next/font/local` pour subset automatique.
- `font-display: swap` pour éviter le FOIT (Flash of Invisible Text).
- Précharger les fonts critiques au paint initial.

### CSS
- Tailwind avec PurgeCSS actif (Next.js le configure).
- Pas de CSS-in-JS runtime (styled-components, emotion) — coût runtime sur mobile.
- Animations via CSS transforms (`translate`, `scale`), jamais `top/left` (re-layout coûteux).

## 3. PWA + Offline-first

Le PWA n'est pas une lubie — c'est une fonctionnalité business pour les marchés avec connectivité instable (Afrique de l'Est, zones rurales).

### Configuration
`next-pwa` configuré dans `next.config.mjs`. Service Worker généré automatiquement à la build.

### Stratégies de cache par type de ressource

| Type | Stratégie | Justification |
|---|---|---|
| Assets statiques (JS, CSS, fonts) | **Cache-first**, revalidation en arrière-plan | Immutables, versionnés par hash |
| Images produits | **Stale-while-revalidate** (24h) | Acceptable d'afficher une ancienne version |
| API GET catalogue/produit | **Stale-while-revalidate** (1h) | Données semi-fraîches |
| API GET panier/commandes | **Network-first** avec fallback cache | Données utilisateur, idéalement fresh |
| API POST/PUT/DELETE | **Network-only** avec queue offline (background sync) | Mutations critiques |
| Pages SSR | **Network-first** avec fallback page offline | UX claire si déconnecté |

### Offline page dédiée
Quand la requête réseau échoue et qu'il n'y a pas de cache : page offline dédiée, traduite FR + EN.

```typescript
// apps/web/app/offline/page.tsx
export default function OfflinePage() {
  return (
    <main>
      <h1>{t('offline.title')}</h1>
      <p>{t('offline.message')}</p>
      <button onClick={() => location.reload()}>{t('offline.retry')}</button>
    </main>
  );
}
```

### Background sync
Mutations effectuées offline (ajout panier, soumission formulaire) sont mises en queue dans IndexedDB et rejouées dès reconnexion.

```typescript
// Service worker handles the sync
self.addEventListener('sync', (event) => {
  if (event.tag === 'sync-cart-mutations') {
    event.waitUntil(replayCartMutations());
  }
});
```

### Manifest
- `manifest.json` configuré : nom, icônes (192px, 512px, maskable), theme color, start URL.
- Installable sur Android et iOS Safari.
- Splash screen automatique iOS via meta tags.

### Versioning du cache
- Cache name versionné par release : `shopeasy-v1.2.3`.
- Au boot du SW : purge des anciens caches.
- `skipWaiting` + `clientsClaim` combinés avec une **UX de notification** (sinon l'utilisateur reste sur ancienne version).

### Tests E2E offline
Playwright avec `context.setOffline(true)` pour simuler la déconnexion :
```typescript
test('user can browse cart offline', async ({ context, page }) => {
  await page.goto('/cart');
  await context.setOffline(true);
  await page.reload();
  await expect(page.getByRole('main')).toBeVisible();
});
```

## 4. Backend — Django et Postgres

### Pagination
**Obligatoire** sur tout endpoint listant des ressources.

- **Cursor-based** préféré au offset pour les grands datasets (catalogue, commandes).
- Offset acceptable pour petits datasets bornés.
- Page size par défaut : 20. Maximum imposé : 100.

```python
# DRF cursor pagination
class ProductPagination(CursorPagination):
    page_size = 20
    max_page_size = 100
    ordering = '-created_at'
```

### N+1 queries — détection systématique
- `select_related` pour FK / OneToOne (JOIN SQL).
- `prefetch_related` pour reverse FK / M2M (requête séparée + jointure Python).
- En dev : `django-nplusone` actif, log les N+1.
- En CI : tests perf qui comptent les requêtes SQL (`assertNumQueries`).

```python
# CORRECT
products = Product.objects.select_related('vendor', 'category').prefetch_related('images')

# DANGEREUX (N+1)
for product in products:
    print(product.vendor.name)  # une requête par produit
```

### Queries optimisées
- **`SELECT`** uniquement les colonnes nécessaires :
  ```python
  Product.objects.only('id', 'name', 'price').filter(...)
  ```
- **`defer`** pour exclure les colonnes lourdes (JSONB description) si non nécessaires :
  ```python
  Product.objects.defer('long_description').all()
  ```
- **`values`** ou **`values_list`** si tu n'as pas besoin d'instancier les modèles.

### Indexes
- Indexes couvrants sur les requêtes critiques (où WHERE + ORDER BY tiennent dans l'index).
- `EXPLAIN ANALYZE` vérifié pour toute route à latence > 100ms.
- **JSONB** : `GIN` pour `contains`/`?`, `BTREE` sur clés extraites pour égalité.
- Indexes documentés dans les migrations avec commentaire expliquant la requête cible.

### Cache Redis
- Sessions, refresh token blacklist : Redis.
- **Cache produits populaires** : top 100 par catégorie, TTL 1h, invalidation à toute modif produit.
- **Cache résultats de recherche** : par requête + filtres, TTL 5 min.
- **Cache taux de change** : TTL 24h, refresh quotidien via Celery beat.
- **Cache agrégats vendeur** (stats dashboard) : TTL 5 min, invalidation à toute commande.

### Stratégie d'invalidation — documentée par clé
Toute clé cache a sa stratégie d'invalidation écrite dans le code et la doc :

```python
# apps/catalog/cache.py
PRODUCT_CACHE_KEY = "product:{id}"
PRODUCT_CACHE_TTL = 3600

def invalidate_product_cache(product_id: str) -> None:
    """Called by signals on Product save/delete."""
    cache.delete(PRODUCT_CACHE_KEY.format(id=product_id))
```

Signals Django invalident automatiquement au `post_save`/`post_delete` du modèle.

### Compression
- gzip/brotli au niveau ingress Kubernetes.
- Pas de double compression.

### Connection pooling
- **pgbouncer** en mode `transaction` devant Postgres en production.
- Pool size dimensionné en fonction du nombre de workers Gunicorn × instances.

### Tâches async via Celery
**Tout ce qui prend > 200ms hors requête → Celery**.

Cas typiques :
- Envoi d'email.
- Génération de PDF (factures, rapports).
- Indexation full-text après modif produit.
- Génération de thumbnails à l'upload d'image.
- Calculs d'agrégats lourds.
- Synchronisation avec services externes.

```python
# orders/tasks.py
@shared_task(bind=True, max_retries=3)
def send_order_confirmation(self, order_id: str) -> None:
    try:
        order = Order.objects.get(id=order_id)
        email_service.send_confirmation(order)
    except SMTPException as exc:
        raise self.retry(exc=exc, countdown=60)
```

## 5. Profiling et mesure

### Frontend
- **React DevTools Profiler** : identifier les re-renders coûteux.
- **Chrome DevTools Performance** : Long Tasks, scripts lents, layout shifts.
- **Lighthouse CI** : automatisé en CI.
- **Web Vitals** : tracking en prod via `web-vitals` lib → Grafana.

### Backend
- **Django Debug Toolbar** en dev : requêtes SQL, cache, templates.
- **django-silk** pour profiling détaillé en staging.
- **OpenTelemetry** : tracing distribué prod, latence par endpoint, span par requête SQL.
- **Grafana dashboards** : latence p50/p95/p99 par endpoint, taux d'erreur, throughput.

### Charge / load testing (Sprint 5+)
- **k6** pour tests de charge.
- Scénarios : navigation catalogue (lecture lourde), checkout (écriture transactionnelle), recherche (CPU/index).
- Target : 1000 RPS sur catalogue avec p95 < 500ms.

## 6. Anti-patterns courants

| Anti-pattern | Correction |
|---|---|
| `import * as Icons from 'lucide-react'` | `import { ShoppingCart } from 'lucide-react'` |
| `useState + useEffect + fetch` pour data | `useQuery` (TanStack Query) |
| `setInterval` pour polling | TanStack Query avec `refetchInterval` |
| `Product.objects.all()` puis filter en Python | `Product.objects.filter(...)` (DB) |
| Boucle Python sur QuerySet pour aggregation | `.aggregate(Sum(...), Avg(...))` SQL |
| Compression images runtime | `next/image` (build-time) |
| Cache sans TTL ni invalidation | TTL + signal d'invalidation explicite |
| `setTimeout` pour debounce | `useDebouncedCallback` |
| `<img src="/big-image.jpg">` 5 Mo | `next/image` + `priority` ou `loading="lazy"` |
| Map state non immutable | Zustand avec immer, ou objet plat |

## 7. Quand optimiser

**Ordre de priorité** :
1. **Le faire fonctionner** correctement avec tests.
2. **Mesurer** : profiling, Lighthouse, EXPLAIN ANALYZE.
3. **Identifier** le bottleneck réel (loi de Pareto : 80% du temps dans 20% du code).
4. **Optimiser** le bottleneck identifié.
5. **Mesurer à nouveau** : confirmer le gain, vérifier l'absence de régression ailleurs.

L'optimisation prématurée est la racine de tous les maux. **Pas d'optim sans `/perf-audit` ou profil explicite préalable.**

## 8. Ressources

- web.dev Performance : https://web.dev/performance/
- Core Web Vitals : https://web.dev/vitals/
- Next.js Performance : https://nextjs.org/docs/app/building-your-application/optimizing
- Django Performance : https://docs.djangoproject.com/en/5.2/topics/db/optimization/
- Postgres Performance : https://wiki.postgresql.org/wiki/Performance_Optimization
