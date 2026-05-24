# Accessibility — WCAG 2.1 Level AA

> Document détaillé référencé par `CLAUDE.md` §7.
> **Lis ce fichier avant tout composant UI nouveau ou modification visuelle.**

L'accessibilité n'est pas optionnelle. `make test-a11y` doit passer sur toute PR frontend, et **Lighthouse a11y >= 95** est un gate CI.

## 1. HTML sémantique obligatoire

### Balises natives uniquement
Utilise les éléments HTML5 sémantiques. Les screen readers s'appuient sur eux.

- Interaction : `<button>`, `<a>`, `<input>`, `<select>`, `<textarea>`, `<details>`, `<summary>`
- Structure : `<main>`, `<nav>`, `<header>`, `<footer>`, `<aside>`, `<section>`, `<article>`
- Formulaire : `<form>`, `<label>`, `<fieldset>`, `<legend>`
- Listes : `<ul>`, `<ol>`, `<li>`, `<dl>`, `<dt>`, `<dd>`

### Interdictions absolues
- **Jamais de `<div>` cliquable**. Si ça se clique, c'est un `<button>` ou un `<a>`. Pas d'exception.
- **Jamais de `<span>` avec `onClick`**. Même règle.
- **Jamais de bouton fait avec `<a href="#">`**. Soit c'est un lien (`<a href="/page">`), soit c'est un bouton (`<button>`).

### Hiérarchie des titres
- Un seul `<h1>` par page (titre principal).
- Pas de saut de niveau : `h1 → h2 → h3`, jamais `h1 → h3`.
- Le niveau reflète la structure logique, pas la taille visuelle (la taille = CSS).

### Landmarks sur chaque page
Au minimum : `<header>`, `<nav>`, `<main>`, `<footer>`. Permet aux utilisateurs de screen reader de naviguer par landmark.

### Attribut `lang`
- `<html lang="fr">` ou `<html lang="en">`, mis à jour à chaque changement de locale (géré par next-intl).
- `<html dir="rtl">` pour les locales RTL (arabe), géré automatiquement.

## 2. ARIA — uniquement quand le HTML natif ne suffit pas

Première règle ARIA : **ne pas utiliser ARIA**. Si tu peux exprimer la sémantique avec du HTML natif, fais-le. ARIA est un complément, pas un remplacement.

### Cas légitimes
- `aria-label` sur bouton icon-only — texte traduit via i18n.
- `aria-describedby="error-id"` pour lier un champ à son message d'erreur.
- `aria-live="polite"` pour notifications/toasts (lecture non-interruptive).
- `aria-live="assertive"` ou `role="alert"` pour erreurs critiques (interruption).
- `aria-expanded="true|false"` sur accordéons, menus déroulants, combobox.
- `aria-current="page"` sur le lien actif dans la navigation.
- `aria-modal="true"` sur les dialogues (combiné avec focus trap).
- `aria-hidden="true"` pour cacher du décoratif aux screen readers (icônes purement visuelles).

### Anti-patterns courants
- `role="button"` sur un `<div>` → utilise `<button>`.
- `aria-label` qui contredit le contenu visible → confusion.
- `aria-hidden="true"` sur un élément focusable → bug majeur (l'utilisateur tab dessus mais ne sait pas ce que c'est).

## 3. Navigation clavier

### Règles absolues
- Tout élément interactif est **focusable et actionnable au clavier**.
- Ordre de tabulation logique (top-to-bottom, left-to-right en LTR ; mirroir en RTL).
- **Jamais `tabindex > 0`** (casse l'ordre naturel).
- `tabindex="-1"` autorisé uniquement pour rendre un élément focusable par script (modale, gestion focus manuelle).
- Focus **visible** avec outline distincte. Jamais `outline: none` sans replacement équivalent (`focus-visible:ring-2`).
- `Escape` ferme : modales, dropdowns, popovers, comboboxes.
- `Enter` et `Space` activent les boutons.
- Flèches naviguent dans les listes, menus, comboboxes (suivre les patterns ARIA Authoring Practices).

### Focus trap dans les modales
Lorsqu'une modale est ouverte :
- Le focus reste piégé dans la modale (Tab ne sort pas).
- À l'ouverture : focus sur le premier élément focusable (ou bouton de fermeture).
- À la fermeture : focus retourne sur l'élément qui a ouvert la modale.
- Implémentation : `radix-ui` ou `react-aria` gèrent ça correctement. Ne le code pas à la main.

## 4. Contraste et visuel

### Ratios obligatoires (WCAG AA)
- **Texte courant** (>= 18.66px ou 14px gras) : ratio **4.5:1** minimum.
- **Texte small** (< 18.66px) : ratio **7:1**.
- **Éléments UI** (boutons, inputs, icônes informatives) : ratio **3:1** minimum.

Vérification : extension navigateur "axe DevTools" ou Lighthouse. Le hook pre-commit refuse les couleurs non conformes via `eslint-plugin-jsx-a11y`.

### Typographie
- Taille de police minimum : **16px body**, **14px absolu** (jamais en dessous, sauf petits caractères de mention légale qui ont leur propre traitement).
- `line-height` minimum : **1.5** pour le texte courant, **1.3** pour les titres.
- Espacement entre paragraphes : 1.5x line-height minimum.
- `letter-spacing` >= 0.12em sur les blocs de texte long.

### Information par la couleur — interdit
- Jamais d'information transmise **uniquement** par la couleur.
- Exemple : un champ en erreur ne doit pas être identifiable seulement par "le contour est rouge". Il doit aussi avoir une icône, un texte d'erreur, et `aria-invalid="true"`.
- Statuts (succès, warning, erreur, info) : couleur + icône + texte.

### Animations et mouvement
- Toute animation respecte `prefers-reduced-motion`.
- Tailwind : utilise `motion-safe:` et `motion-reduce:`.
- Aucune animation clignotante > 3 fois/seconde (risque épileptique).
- Carrousels en autoplay : interdits sauf avec bouton pause clairement visible.

## 5. Formulaires accessibles

### Étiquetage
- Chaque `<input>` a un `<label>` **visible** associé (`htmlFor` ↔ `id`).
- Placeholder ≠ label. Le placeholder disparaît à la saisie, perdant l'information.
- Si l'espace manque visuellement : utilise `aria-label`, mais préfère toujours le label visible.

### Validation accessible
- Messages d'erreur liés au champ via `aria-describedby="error-id"`.
- `aria-invalid="true"` sur les champs en erreur.
- Messages d'erreur traduits via i18n, jamais hardcodés.
- Erreurs annoncées : utilise `role="alert"` ou un container `aria-live="polite"` pour la liste des erreurs au submit.

### Groupes de champs
- Champs liés (ex: jour/mois/année, prénom/nom) dans un `<fieldset>` avec `<legend>`.
- Radio buttons toujours dans un `<fieldset>` avec `<legend>` décrivant le groupe.

### Autocomplete
Attribut `autocomplete` correct sur chaque champ pertinent. Bénéfices : remplissage automatique navigateur + gestionnaires de mot de passe + accessibilité cognitive.

Valeurs courantes : `name`, `given-name`, `family-name`, `email`, `tel`, `street-address`, `address-line1`, `postal-code`, `country`, `cc-number`, `cc-exp`, `username`, `current-password`, `new-password`.

## 6. Images et médias

### Texte alternatif
- `alt` **descriptif** sur chaque image **informative** — décrit le contenu/la fonction de l'image, pas le médium ("photo de", "image de" interdits).
- `alt=""` (vide) sur les images **purement décoratives** (background visuel sans information).
- `alt` traduit via i18n si l'image transmet du contenu textuel.

### Médias dynamiques
- Sous-titres sur les vidéos (`<track kind="subtitles">`).
- Transcript pour les podcasts/audios.
- **Jamais d'autoplay** sur les médias avec son.
- Si autoplay sans son : option pause/stop visible et accessible.

### Icônes
- Icônes purement décoratives : `aria-hidden="true"` (le screen reader saute).
- Icônes porteuses de sens : `aria-label="..."` traduit, ou texte adjacent visuellement masqué (`sr-only`).

## 7. Tests automatisés

### Stack de tests a11y
- **axe-core** via `@axe-core/playwright` sur routes critiques.
- **Lighthouse CI** avec gate a11y >= 95.
- **eslint-plugin-jsx-a11y** dans le linter (catch les erreurs courantes au build).
- Snapshots Playwright en mode RTL (`make test-rtl`).

### Routes critiques (toujours testées)
- Home `/`
- Catalogue `/catalog`
- Page produit `/products/[slug]`
- Panier `/cart`
- Checkout `/checkout`
- Login `/login`, register `/register`
- Compte utilisateur `/account`
- Dashboard vendeur `/vendor/dashboard`

### Tests manuels (avant merge sur flows critiques)
Avant de merger un changement sur un flow critique (auth, checkout, panier), tester manuellement :
1. Navigation complète au clavier (Tab, Shift+Tab, Enter, Escape, flèches).
2. Lecture par un screen reader (VoiceOver macOS, NVDA Windows) sur au moins une route.
3. Zoom navigateur à 200% — pas de débordement, pas de superposition.
4. Mode contraste élevé Windows — tous les éléments restent visibles.

## 8. Composants critiques — checklist rapide

Quand tu codes/modifies ces composants, applique ces vérifications minimales :

### Modale
- Focus trap fonctionne (Tab ne sort pas).
- `Escape` ferme.
- Focus retourne sur le déclencheur après fermeture.
- `role="dialog"` + `aria-modal="true"` + `aria-labelledby="title-id"`.
- Background scroll bloqué pendant l'ouverture.

### Dropdown / menu
- Touche flèche bas ouvre.
- Flèches haut/bas naviguent dans les options.
- `Enter` ou `Space` sélectionne.
- `Escape` ferme.
- `aria-expanded`, `aria-haspopup`, `aria-controls`.

### Carrousel
- Boutons précédent/suivant `aria-label` traduit.
- Indicateurs `aria-current="true"` sur la slide active.
- Bouton pause si autoplay.
- Pas d'autoplay > 5 secondes sans contrôle.

### Toast / notification
- `aria-live="polite"` pour info, `assertive` pour erreur.
- Durée d'affichage : minimum 5 secondes pour message court, plus pour message long.
- Bouton fermer accessible au clavier.

### Tableau de données
- `<table>` avec `<thead>`, `<tbody>`, `<th scope="col|row">`.
- `<caption>` décrivant le contenu du tableau.
- Pas de tableau pour la mise en page (utilise CSS Grid/Flexbox).

## 9. Ressources

- WCAG 2.1 Quick Reference : https://www.w3.org/WAI/WCAG21/quickref/
- ARIA Authoring Practices : https://www.w3.org/WAI/ARIA/apg/
- axe DevTools : extension navigateur Chrome/Firefox
- Inclusive Components : https://inclusive-components.design/

Tout nouveau pattern d'interaction non-standard : consulte ARIA APG **avant** de coder.
