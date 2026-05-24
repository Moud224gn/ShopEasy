---
description: Ajoute une nouvelle devise supportée au projet (frontend dinero.js + backend py-moneyed + config taux de change). Valide ISO 4217, met à jour les configs, ne touche pas au code applicatif. Workflow scripté direct.
argument-hint: "<code ISO 4217>  ex: XAF, NGN, KES, MAD, ZAR, GBP, JPY"
allowed-tools: ["Bash", "Read", "Glob", "Grep", "WebFetch"]
---

# /currency-add — Ajouter une nouvelle devise

Tu ajoutes une nouvelle devise supportée par ShopEasy selon les conventions strictes de `docs/conventions/i18n.md` (§Multi-currency). Architecture extensible prévue dès le Sprint 1 — ajouter une devise = mettre à jour les configs, **aucun code applicatif modifié**.

Code devise : $ARGUMENTS

## Vérification d'entrée

Si `$ARGUMENTS` est vide : demande le code ISO 4217 (3 lettres majuscules).

Vérifie le format :
```bash
echo "$ARGUMENTS" | grep -E '^[A-Z]{3}$'
```

Si invalide : refuse, demande un code valide.

Devises couramment ajoutées pour ShopEasy (selon vision §2) :

| Code | Devise | Symbole | Subdivisions | Marchés |
|---|---|---|---|---|
| `CAD` | Dollar canadien | $ | 100 cents | Canada (déjà supportée) |
| `USD` | Dollar US | $ | 100 cents | International (déjà supportée) |
| `EUR` | Euro | € | 100 centimes | UE (déjà supportée) |
| `XAF` | FCFA BEAC | FCFA | **0 (entier)** | Afrique centrale (Cameroun, Tchad, ...) |
| `XOF` | FCFA BCEAO | FCFA | **0 (entier)** | Afrique de l'Ouest (Sénégal, Côte d'Ivoire, ...) |
| `NGN` | Naira | ₦ | 100 kobo | Nigeria |
| `KES` | Shilling kenyan | KSh | 100 cents | Kenya |
| `MAD` | Dirham marocain | DH | 100 centimes | Maroc |
| `ZAR` | Rand sud-africain | R | 100 cents | Afrique du Sud |
| `GBP` | Livre sterling | £ | 100 pence | UK |
| `JPY` | Yen | ¥ | **0 (entier)** | Japon |

**Attention** : devises sans subdivision (XAF, XOF, JPY, KRW...) — la plus petite unité = 1, pas 1/100. Stockage `{ amount: 1000, currency: "JPY" }` = 1000 yens, pas 10 yens.

Si le code n'est pas dans la liste : vérifie via WebFetch sur `https://www.six-group.com/dam/download/financial-information/data-center/iso-currrency/lists/list-one.xml` (ou source ISO 4217 équivalente) ou demande confirmation.

## Procédure

### Étape 1 — Pré-checks

```bash
# La devise existe-t-elle déjà dans les configs ?
grep -r "\"${ARGUMENTS}\"\|'${ARGUMENTS}'" apps/api/shopeasy/i18n/currencies.py 2>/dev/null && \
  echo "Devise ${ARGUMENTS} déjà présente côté backend"

grep -r "${ARGUMENTS}" apps/web/src/lib/currencies.ts 2>/dev/null && \
  echo "Devise ${ARGUMENTS} déjà présente côté frontend"

# Si oui : abort, demander si l'utilisateur veut juste activer la devise pour un vendor.

# Vérifier que les libs sont en place
grep "py-moneyed" apps/api/pyproject.toml || echo "ALERT: py-moneyed manquant"
grep "dinero" apps/web/package.json || echo "ALERT: dinero.js manquant"
```

Affiche :
```
Ajout de devise : ${ARGUMENTS}
Subdivisions : 100 | 0 (selon la devise)
Frontend : à configurer (dinero.js)
Backend : à configurer (py-moneyed)
Taux de change : source à configurer
```

### Étape 2 — Backend (py-moneyed + Django)

Mettre à jour la liste des devises supportées dans la config :

```python
# apps/api/shopeasy/i18n/currencies.py
SUPPORTED_CURRENCIES = [
    'CAD',
    'USD',
    'EUR',
    '${ARGUMENTS}',  # ← ajouté
]
```

Et dans les settings Django :
```python
# apps/api/shopeasy/settings/base.py
CURRENCIES = ('CAD', 'USD', 'EUR', '${ARGUMENTS}')

CURRENCY_CHOICES = [
    ('CAD', 'CAD $'),
    ('USD', 'USD $'),
    ('EUR', 'EUR €'),
    ('${ARGUMENTS}', '${ARGUMENTS} ${SYMBOLE}'),  # ← ajouté
]
```

`py-moneyed` reconnaît nativement tous les codes ISO 4217 — pas de config supplémentaire requise pour les opérations arithmétiques.

### Étape 3 — Frontend (dinero.js)

Mettre à jour la config dinero.js :

```typescript
// apps/web/src/lib/currencies.ts
import { CAD, USD, EUR } from '@dinero.js/currencies';
// Pour les devises moins courantes, peut nécessiter import depuis le package complet ou définition custom

// Si dinero.js v2 ne fournit pas directement la devise (ex: XAF, KES) :
import type { Currency } from 'dinero.js';

export const ${ARGUMENTS}: Currency<number> = {
  code: '${ARGUMENTS}',
  base: 10,
  exponent: ${EXPONENT},  // 2 pour 100 subdivisions, 0 pour sans subdivision
};

export const SUPPORTED_CURRENCIES = {
  CAD,
  USD,
  EUR,
  ${ARGUMENTS},
} as const;
```

Le composant de sélection de devise (`apps/web/src/components/CurrencySelector.tsx` typiquement) sera mis à jour automatiquement s'il itère sur `SUPPORTED_CURRENCIES`.

### Étape 4 — Taux de change

Mettre à jour la task Celery de refresh :

```python
# apps/api/shopeasy/i18n/tasks/refresh_exchange_rates.py
TRACKED_CURRENCIES = ['CAD', 'USD', 'EUR', '${ARGUMENTS}']

@shared_task
def refresh_exchange_rates():
    # Appelle l'API de taux de change pour TRACKED_CURRENCIES
    # Stocke dans Redis avec TTL 24h
    ...
```

Si l'API externe (ex: ExchangeRate-API) supporte la devise : pas de config supplémentaire.
Si l'API ne supporte pas (devises rares) : configurer un fallback ou une seconde source.

Forcer un premier refresh :
```bash
docker compose exec api python manage.py shell -c "from shopeasy.i18n.tasks import refresh_exchange_rates; refresh_exchange_rates()"
```

### Étape 5 — Validation par vendor

Une devise supportée par la plateforme n'est pas automatiquement supportée par chaque vendor. Le modèle `Vendor` a typiquement un champ `supported_currencies`.

Ne **pas** automatiquement activer la nouvelle devise pour les vendors existants. C'est leur décision business.

Mentionne dans la sortie :
```
Note : la devise ${ARGUMENTS} est maintenant supportée par la plateforme,
mais elle n'est PAS automatiquement activée pour les vendors existants.
Chaque vendor doit l'activer dans son dashboard (apps/api/shopeasy/vendors/...).
```

### Étape 6 — Tests à ajouter

Génère/suggère les tests de validation :

```python
# apps/api/shopeasy/i18n/tests/test_currencies.py
def test_${ARGUMENTS.lower()}_is_supported():
    from shopeasy.i18n.currencies import SUPPORTED_CURRENCIES
    assert '${ARGUMENTS}' in SUPPORTED_CURRENCIES

def test_${ARGUMENTS.lower()}_arithmetic():
    from djmoney.money import Money
    amount = Money(1000, '${ARGUMENTS}')
    assert amount.amount == 1000
    assert str(amount.currency) == '${ARGUMENTS}'

def test_${ARGUMENTS.lower()}_exchange_rate_cached():
    from django.core.cache import cache
    rate = cache.get('exchange_rate:USD:${ARGUMENTS}')
    assert rate is not None  # après refresh_exchange_rates
```

```typescript
// apps/web/src/lib/__tests__/currencies.test.ts
import { dinero, toDecimal } from 'dinero.js';
import { ${ARGUMENTS} } from '../currencies';

test('${ARGUMENTS} dinero creation', () => {
  const amount = dinero({ amount: 1000, currency: ${ARGUMENTS} });
  expect(toDecimal(amount)).toBe('1000');  // si exponent 0, sinon '10.00'
});
```

### Étape 7 — Présentation et hand-off

```
=== Devise ${ARGUMENTS} ajoutée ===

Subdivisions : ${EXPONENT === 0 ? 'Aucune (devise entière)' : '100'}
Stockage : { amount: integer, currency: "${ARGUMENTS}" }
${EXPONENT === 0 ? 'Attention : amount = unité directe (ex: 1000 = 1000 unités)' : 'amount = plus petite subdivision (ex: 1999 = 19.99)'}

Configs mises à jour :
- apps/api/shopeasy/i18n/currencies.py
- apps/api/shopeasy/settings/base.py
- apps/web/src/lib/currencies.ts
- apps/api/shopeasy/i18n/tasks/refresh_exchange_rates.py

Tests ajoutés :
- apps/api/shopeasy/i18n/tests/test_currencies.py
- apps/web/src/lib/__tests__/currencies.test.ts

Étapes suivantes :
1. Vérifier que l'API de taux de change supporte ${ARGUMENTS}
2. Forcer un premier refresh : `docker compose exec api python manage.py shell -c "..."`
3. `make test-api` et `make test-web` pour valider les tests ajoutés
4. Les vendors qui veulent supporter ${ARGUMENTS} doivent l'activer dans leur dashboard
5. `/commit` pour committer (`feat(i18n): add ${ARGUMENTS} currency support`)

Hand-offs recommandés :
- Pour l'i18n des labels associés (nom de la devise dans chaque locale) : `/locale-add` workflow ou mise à jour des fichiers de traduction existants
- Si vendor activation automatique souhaitée : data migration via `/migrate`
```

## Règles strictes

### Pas d'activation auto pour vendors existants
La devise ajoutée est **disponible** mais pas **active** pour les vendors. Activer pour tous serait une décision business — refuse.

### Stockage en plus petite unité respecté
Insister sur le stockage : `{ amount, currency }`, pas `float`. Si devise sans subdivision (XAF, JPY) : amount = unité directe.

### ISO 4217 strict
Seuls les codes ISO 4217 valides (3 lettres majuscules). Pas de codes inventés (BTC, ETH ne sont pas ISO 4217 standard pour le commerce traditionnel).

### Hardcoded forbidden
Rappelle que dans le **code applicatif** (services, vues, composants), la devise reste paramétrique. Cette commande met à jour la **config**, pas le code applicatif.

### Vérification taux de change
Si l'API externe ne supporte pas la devise : avertir AVANT de finaliser. Sans taux de change, la conversion sera impossible et la devise inutilisable au-delà des opérations en devise locale.

## Cas particuliers

### Devise sans subdivision (XAF, XOF, JPY, KRW)
Insister visuellement dans la sortie : exponent = 0. C'est un piège classique — un développeur écrit `Money(1000, 'JPY')` en pensant à 10 yens, c'est en réalité 1000 yens.

### Devise crypto-monnaie
Hors scope ISO 4217. Si l'utilisateur demande `BTC` : refuse, hand-off à `/adr` pour décider de la stratégie crypto séparément.

### Devise discontinuée
Certaines devises sont obsolètes (ex: zimbabwéen ZWL pré-2025). Vérifier via la source ISO 4217 que la devise est active. Sinon : refuse.

### Devise locale au Québec
CAD est déjà supportée. Pas besoin de re-créer. Si l'utilisateur insiste : suggère `/i18n-check` pour vérifier l'usage existant.

---

**Rappel** : multi-currency n'est pas seulement supporter plusieurs devises, c'est gérer les conversions, les taxes selon juridiction, et l'affichage locale-aware. Ajouter la devise est l'étape 1 d'un effort plus large.
