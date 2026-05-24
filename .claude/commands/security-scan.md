---
description: Lance un audit sécurité approfondi sur un périmètre ciblé (fichier, module, branche). Délègue au subagent security-auditor. Obligatoire avant merge sur auth, paiements, uploads, données PII.
argument-hint: "<chemin | module | --branch | --staged>"
allowed-tools: ["Bash", "Read", "Glob", "Grep", "WebSearch", "WebFetch"]
---

# /security-scan — Audit sécurité ciblé

Tu déclenches un audit sécurité par le subagent `security-auditor` selon `CLAUDE.md` §9 et `docs/conventions/security.md`. **Obligatoire** avant merge sur tout code touchant auth, paiements, uploads, ou données personnelles.

Périmètre : $ARGUMENTS

## Détermination du périmètre

Selon `$ARGUMENTS` :
- **Chemin** (`apps/api/shopeasy/payments/`) → audit du module/fichier.
- **`--staged`** → audit des fichiers stagés (`git diff --staged --name-only`).
- **`--branch`** → audit de tous les changements de la branche par rapport à `develop`.
- **Vide** → demande à l'utilisateur de préciser.

## Procédure

### Étape 1 — Cadrer et collecter

Affiche :
```
Audit sécurité déclenché
Périmètre : <résolu>
Date : <timestamp>
```

Identifie le contexte :
- Quelles juridictions sont concernées (selon le code touché — auth = toutes, vendeurs = juridictions vendeur, etc.) ?
- Audits antérieurs sur ce périmètre dans `docs/security/audits/` ?

### Étape 2 — Délègue au subagent security-auditor

Invoque `security-auditor` avec contexte clair :

> "Effectue un audit sécurité approfondi sur [périmètre]. Suis ta méthode standard en 8 étapes : cadrage, checks automatiques (bandit, pip-audit, pnpm audit, trivy, detect-secrets), audit manuel par les 12 dimensions applicables, défense en profondeur, catégorisation findings (CRITICAL/HIGH/MEDIUM/LOW/INFO avec CWE et CVSS estimé), rapport au format standard. Archive dans `docs/security/audits/` si CRITICAL ou HIGH trouvés."

Le subagent prend le relais et exécute sa méthode.

### Étape 3 — Restitution

Le subagent présente le rapport directement. Tu n'altères rien.

### Étape 4 — Action selon verdict

- **SECURE** : "Verdict SECURE. Tu peux continuer le workflow normal (`/review`, `/pre-push`, push)."
- **CONCERNS** : "Verdict CONCERNS. N findings non-bloquants à adresser à court terme. Hand-off à l'agent principal pour corrections."
- **VULNERABLE** : "Verdict VULNERABLE. Merge BLOQUÉ. Corrections requises sur les CRITICAL/HIGH avant tout push. Hand-off à l'agent principal pour fixes, puis re-audit `/security-scan`."

## Règles strictes

### Tu ne fais pas l'audit toi-même
Délégation stricte. Le `security-auditor` a sa posture offensive et sa méthode — tu ne dupliques pas.

### Tu n'altères pas le verdict
Si l'utilisateur conteste : "Le verdict reste celui de l'auditeur. Si tu juges une règle injustifiée, on en discute via amendement de CLAUDE.md ou ADR."

### Tu rappelles l'obligation pour les zones sensibles
Si l'utilisateur tente de push sur auth/paiements/uploads/PII sans `/security-scan` préalable : rappelle que c'est obligatoire selon §9.

### Pas de fast-track
Aucun mode "audit rapide" pour `/security-scan`. L'audit complet ou rien. La sécurité n'a pas de mode économique.

## Cas particuliers

### Périmètre énorme
Si `$ARGUMENTS` cible tout le repo : le subagent va sélectionner intelligemment les zones à risque. Peut prendre 15-30min. Annonce-le à l'utilisateur.

### Audit pré-release
Avant déploiement prod : invoque sur la branche `develop` complète pour un audit de release. Combine avec `/deploy-check`.

### Re-audit après corrections
Si l'utilisateur a corrigé des findings d'un audit précédent : invoque à nouveau `/security-scan` sur le même périmètre. Compare au rapport archivé pour valider que tous les bloquants sont adressés.

---

**Rappel** : la sécurité n'est pas une feature. Une vulnérabilité non détectée maintenant = un incident dans 6 mois.
