---
description: Ajoute une nouvelle locale au projet (frontend next-intl + backend Django gettext). Crée la structure de fichiers, valide ISO 639-1, gère RTL si applicable, n'écrit pas les traductions (à faire ensuite). Workflow scripté direct.
argument-hint: "<code ISO 639-1>  ex: ar, es, pt, sw, de"
allowed-tools: ["Bash", "Read", "Glob", "Grep", "WebFetch"]
---

# /locale-add — Ajouter une nouvelle locale

Tu ajoutes une nouvelle locale au projet en suivant les conventions strictes de `docs/conventions/i18n.md`. Architecture extensible prévue dès le Sprint 1 (CLAUDE.md §2 et §8).

Code locale : $ARGUMENTS

## Vérification d'entrée

Si `$ARGUMENTS` est vide : demande le code locale (format ISO 639-1, 2 lettres minuscules).

Vérifie le format :
```bash
echo "$ARGUMENTS" | grep -E '^[a-z]{2}$'
```

Si invalide : refuse, demande un code valide (ex: `ar`, `es`, `pt`, `sw`, pas `arab`, `AR`, `arabic`).

Locales couramment ajoutées pour ShopEasy (selon vision §2) :

| Code | Langue | Direction | Marchés cibles |
|---|---|---|---|
| `ar` | Arabe | **RTL** | Maghreb, Moyen-Orient |
| `es` | Espagnol | LTR | Amérique latine |
| `pt` | Portugais | LTR | Brésil, Afrique lusophone |
| `sw` | Swahili | LTR | Afrique de l'Est |
| `de` | Allemand | LTR | Europe centrale |
| `it` | Italien | LTR | Italie |

Si le code n'est pas dans la liste ci-dessus : vérifie qu'il s'agit bien d'une ISO 639-1 valide via WebFetch sur `https://www.loc.gov/standards/iso639-2/php/code_list.php` ou demande confirmation.

## Procédure

### Étape 1 — Pré-checks

```bash
# La locale existe-t-elle déjà ?
ls apps/web/messages/ 2>/dev/null | grep "^${ARGUMENTS}$" && \
  echo "Locale ${ARGUMENTS} existe déjà côté frontend"

ls apps/api/locale/ 2>/dev/null | grep "^${ARGUMENTS}$" && \
  echo "Locale ${ARGUMENTS} existe déjà côté backend"

# Si oui : abort, demander si l'utilisateur veut rafraîchir (et dans ce cas, c'est un autre workflow).

# Identifier si RTL
case "$ARGUMENTS" in
  ar|he|fa|ur|yi|dv) echo "RTL : oui";;
  *) echo "RTL : non";;
esac
```

Affiche :
```
Ajout de locale : <code>
Direction : LTR | RTL
Frontend : à créer
Backend : à créer
```

### Étape 2 — Frontend (next-intl)

Crée la structure de fichiers de traduction.

```bash
mkdir -p apps/web/messages/${ARGUMENTS}

# Pour chaque namespace existant (basé sur FR référence), créer le fichier vide
for ns in common auth catalog cart checkout orders vendor errors; do
  if [ -f "apps/web/messages/fr/${ns}.json" ]; then
    # Copier la structure de clés FR, valeurs vides à remplir
    jq 'walk(if type == "string" then "" else . end)' \
       "apps/web/messages/fr/${ns}.json" \
       > "apps/web/messages/${ARGUMENTS}/${ns}.json"
  fi
done
```

Mettre à jour la config next-intl. Le chemin typique est `apps/web/i18n.ts` ou `apps/web/middleware.ts` :

```typescript
// Avant
export const locales = ['fr', 'en'] as const;

// Après (ajout de la nouvelle locale)
export const locales = ['fr', 'en', '${ARGUMENTS}'] as const;
```

Mettre à jour le middleware si présent :
```typescript
export const config = {
  matcher: ['/((?!api|_next|.*\\..*).*)']  // inchangé
};
```

Vérifier que `next-intl.config.ts` ou équivalent référence la nouvelle locale.

### Étape 3 — Backend (Django gettext)

```bash
mkdir -p apps/api/locale/${ARGUMENTS}/LC_MESSAGES

# Generate empty .po file via Django
cd apps/api
python manage.py makemessages -l ${ARGUMENTS}
# Cela génère apps/api/locale/<code>/LC_MESSAGES/django.po avec toutes les clés à traduire
```

Mettre à jour `settings.py` :
```python
LANGUAGES = [
    ('fr', _('French')),
    ('en', _('English')),
    ('${ARGUMENTS}', _('${LANGUE_NOM}')),  # ← ajouté
]
```

### Étape 4 — RTL (si applicable)

Si la locale est RTL (`ar`, `he`, `fa`, `ur`) :

#### Vérifier que Tailwind RTL est configuré
```bash
grep -r "tailwindcss-rtl" apps/web/package.json
```
Si non : alerter et bloquer — RTL nécessite le plugin installé.

#### Vérifier que les composants utilisent logical properties
```bash
# Scan rapide des physical properties (CLAUDE.md §8 RTL)
grep -rE "(margin-left|margin-right|text-align:\s*(left|right))" apps/web/src --include="*.tsx" --include="*.css" | head
```
Si occurrences trouvées : avertir l'utilisateur que le RTL va exposer des problèmes existants. Recommander `/i18n-check apps/web/src` avant de finaliser l'ajout RTL.

#### Configurer la direction
Dans le layout next-intl, s'assurer que `<html dir>` est dynamique selon la locale :
```typescript
// apps/web/app/[locale]/layout.tsx
import { getLocale } from 'next-intl/server';

const RTL_LOCALES = ['ar', 'he', 'fa', 'ur', 'yi', 'dv'];

const locale = await getLocale();
const dir = RTL_LOCALES.includes(locale) ? 'rtl' : 'ltr';

return (
  <html lang={locale} dir={dir}>
    ...
  </html>
);
```

### Étape 5 — Tests à ajouter

Génère un test de complétude qui s'exécute à chaque CI :

```typescript
// apps/web/__tests__/i18n-completeness.test.ts
import frCommon from '@/messages/fr/common.json';
import enCommon from '@/messages/en/common.json';
import ${ARGUMENTS}Common from '@/messages/${ARGUMENTS}/common.json';

function extractKeys(obj: object, prefix = ''): string[] {
  // ... extrait toutes les clés récursivement
}

test('${ARGUMENTS} has same keys as fr/en', () => {
  expect(extractKeys(${ARGUMENTS}Common).sort()).toEqual(extractKeys(frCommon).sort());
});
```

Pour RTL, ajouter un test snapshot Playwright :
```typescript
test('catalog renders correctly in ${ARGUMENTS} (RTL)', async ({ page }) => {
  await page.goto('/${ARGUMENTS}/catalog');
  await expect(page).toHaveScreenshot('catalog-${ARGUMENTS}.png');
});
```

### Étape 6 — Présentation et hand-off

```
=== Locale ${ARGUMENTS} ajoutée ===

Structure créée :
- apps/web/messages/${ARGUMENTS}/ (8 namespaces JSON, valeurs vides)
- apps/api/locale/${ARGUMENTS}/LC_MESSAGES/django.po (clés à traduire)

Config mise à jour :
- apps/web/i18n.ts (locale ajoutée)
- apps/api/shopeasy/settings.py (LANGUAGES)
[Si RTL : apps/web/app/[locale]/layout.tsx (dir dynamique)]

Tests ajoutés :
- apps/web/__tests__/i18n-completeness.test.ts (gate CI)
[Si RTL : Playwright snapshot test]

Étapes suivantes :
1. Remplir les traductions :
   - JSON files dans apps/web/messages/${ARGUMENTS}/
   - django.po dans apps/api/locale/${ARGUMENTS}/LC_MESSAGES/
   - Compiler avec `make i18n-compile` (génère .mo)
2. [Si RTL] `/i18n-check apps/web/src` pour identifier physical properties à corriger
3. `make test-i18n` pour vérifier la complétude
4. [Si RTL] `make test-rtl` pour vérifier les snapshots
5. `/commit` pour committer (`feat(i18n): add ${ARGUMENTS} locale support`)

Hand-offs recommandés :
- Pour les traductions : workflow externe (Crowdin, traducteur humain, ou agent dédié)
- Pour audit complet après ajout : `/i18n-check` puis `/a11y-audit` sur quelques routes
[Si RTL : - Pour fixer les physical properties détectées : agent principal + `/refactor` si massif]
```

## Règles strictes

### Pas de traductions automatiques
Tu n'inventes **jamais** de traductions. Les valeurs JSON et .po sont créées vides, à remplir par un humain qualifié ou un service de traduction professionnel. Une mauvaise traduction est pire que pas de traduction.

### Vérification RTL avant ajout
Si la locale est RTL et que des physical properties sont massivement présentes dans le code : avertir avant de finaliser. L'ajout RTL sur un code non-RTL-ready va causer des bugs visuels.

### ISO 639-1 strict
Seuls les codes ISO 639-1 valides (2 lettres) sont acceptés. Pas de variants régionaux à ce stade (pas `fr-CA`, `en-US`) — gérés au niveau du formatage via `Intl`.

### Pas de doublon
Si la locale existe déjà : refuse l'ajout. Suggère plutôt `/i18n-check apps/web/messages/<code>/` pour audit.

## Cas particuliers

### Locale avec variants régionaux
Si l'utilisateur veut différencier `pt-BR` vs `pt-PT` : c'est une décision archi. Hand-off à `/adr` pour décider de la stratégie (variants vs locale unique avec formatage différencié).

### Locale en alphabet non-latin
Pour `ar`, `zh`, `ja`, `ko` : vérifier que les fonts du projet supportent l'alphabet. Sinon, ajouter les font subsets dans la config Next.js.

### Première locale RTL ajoutée
Si c'est la première fois que RTL est introduit : `/i18n-check` complet avant de finaliser, puis `make test-rtl` pour générer la baseline des snapshots.

---

**Rappel** : ajouter une locale est facile. Maintenir 5 locales propres demande discipline. Ne pas multiplier les locales sans engagement de maintenance.
