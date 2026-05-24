---
description: Lance un audit accessibilité WCAG 2.1 AA approfondi sur une route ou un composant. Délègue au subagent accessibility-i18n-auditor. Inclut Lighthouse a11y, axe-core, vérification clavier, contraste, ARIA, RTL.
argument-hint: "<route | composant>  ex: /checkout, ProductCard, /vendor/dashboard"
allowed-tools: ["Bash", "Read", "Glob", "Grep", "WebFetch"]
---

# /a11y-audit — Audit accessibilité ciblé

Tu déclenches un audit a11y par le subagent `accessibility-i18n-auditor` selon `CLAUDE.md` §7 et `docs/conventions/accessibility.md`. **L'a11y est WCAG 2.1 AA non-négociable, vérifiée à chaque PR frontend.**

Cible : $ARGUMENTS

## Différence avec `make test-a11y`

- **`make test-a11y`** (CI) : vérification automatique du score Lighthouse a11y >= 95 et zéro violation axe sur les routes critiques. Lancé en CI et `make pre-push`.
- **`/a11y-audit <cible>`** (cette commande) : audit approfondi d'une route ou composant spécifique. Inclut tests manuels (clavier, screen reader perspective), revue ARIA, vérification logique RTL.

## Procédure

### Étape 1 — Cadrer la cible

Types :
- **Route** : `/checkout`, `/products/[slug]`, `/account` → audit complet de la page.
- **Composant** : `ProductCard`, `Checkout/PaymentForm`, `Header/Nav` → audit du composant et ses dépendants visuels.
- **Flow** : `auth flow`, `checkout flow` → audit de bout-en-bout d'un parcours utilisateur.

Affiche :
```
Audit a11y déclenché
Cible : <résolu>
Date : <timestamp>
```

### Étape 2 — Délègue au subagent accessibility-i18n-auditor

Invoque le subagent avec contexte précis (focus a11y) :

> "Effectue un audit accessibilité WCAG 2.1 AA sur [cible]. Focus sur **a11y** (l'audit i18n n'est pas nécessairement le focus ici, sauf si tu détectes des chaînes hardcodées en passant). Suis ta méthode standard : checks automatiques (Lighthouse, axe-core, eslint-jsx-a11y), audit manuel par les 4 principes WCAG (Perceivable, Operable, Understandable, Robust), perspective utilisateur réel (screen reader, clavier, low-vision, cognitive, RTL), catégorisation findings (CRITICAL/HIGH/MEDIUM/LOW/INFO avec WCAG critère cité), rapport au format standard. Archive dans `docs/audits/accessibility-i18n/` si CRITICAL/HIGH trouvés."

Le subagent prend le relais.

### Étape 3 — Restitution

Le rapport inclut :
- Score Lighthouse a11y vs cible (>= 95).
- Violations axe-core détaillées.
- Findings par sévérité avec utilisateur impacté + WCAG critère + remédiation code AVANT/APRÈS + test de régression à ajouter.

### Étape 4 — Action selon verdict

- **ACCESSIBLE** : "Verdict ACCESSIBLE. Tu peux continuer."
- **CONCERNS** : "Verdict CONCERNS. N findings non-bloquants à adresser. Hand-off à l'agent principal."
- **INACCESSIBLE** : "Verdict INACCESSIBLE. Flow critique bloqué pour une catégorie d'utilisateurs. Merge BLOQUÉ. Hand-off pour corrections puis re-audit."

## Règles strictes

### Tu ne fais pas l'audit toi-même
Délégation au subagent qui a la perspective utilisateur et les outils.

### Tu n'altères pas le verdict
"Personne n'utilise screen reader sur ce projet" n'est jamais une justification valide. Cite §7 et la dimension légale (Loi 25, AODA, EAA, ADA).

### Tu rappelles l'obligation pour les changements frontend
Tout changement non-trivial frontend devrait passer par `/a11y-audit` au moins une fois avant merge.

### Pas d'audit "rapide"
L'a11y vérifiée à 80% est de l'a11y dégradée. L'audit complet ou rien.

## Cas particuliers

### Audit RTL spécifique
Si l'utilisateur demande "/a11y-audit en mode RTL" ou similaire : le subagent active le check RTL (snapshots Playwright avec `dir="rtl"`). Identifie les régressions visuelles.

### Composant atomique vs page
Un composant atomique (`Button`, `Input`) s'audite isolément en Storybook si dispo. Une page s'audite sur staging avec Lighthouse + tests E2E axe.

### Audit pré-release
Avant déploiement prod : `/a11y-audit` sur tous les flows critiques (auth, catalog, product, cart, checkout, account).

### Régression sur audit précédent
Si un audit antérieur dans `docs/audits/accessibility-i18n/` montrait verdict ACCESSIBLE et qu'une nouvelle violation apparaît : flag comme régression dans le rapport, hand-off urgent.

## Hand-offs typiques

- Pattern récurrent (ex: 10x `<div>` cliquable) → `architect` pour ADR sur convention composants interactifs.
- Tests a11y manquants à ajouter → `test-writer` pour scenarios Playwright avec `@axe-core/playwright`.

---

**Rappel** : 1.3 milliard de personnes en situation de handicap dans le monde (OMS). Beaucoup plus avec assistance temporaire. L'a11y est business-critical et légalement requise.
