# Security — Authentication, Secrets, Compliance

> Document détaillé référencé par `CLAUDE.md` §9.
> **Lis ce fichier avant tout code touchant : auth, paiements, uploads, données personnelles, ou exposition publique.**

ShopEasy traite des données personnelles, des moyens de paiement, et opère sous **plusieurs juridictions**. La sécurité n'est jamais en patch après coup — elle est dans l'architecture.

## 1. Authentification

### Password hashing — Argon2id
- **Argon2id uniquement** via `django-argon2`. Lauréat du Password Hashing Competition 2015, recommandé par OWASP.
- Bcrypt **interdit en production** (toléré uniquement pour la lecture de comptes hérités lors d'une migration, jamais pour de nouveaux comptes).
- Paramètres production : memory cost >= 64 MB, time cost = 3, parallelism = 4. Mesurer le coût CPU sur l'infra avant de fixer définitivement.
- Migration automatique : si un user existant se connecte avec un hash bcrypt, on le re-hash en Argon2id à la volée.

### JWT — tokens courts + rotation
- **Access token** : 15 minutes, signé HS256 ou RS256.
- **Refresh token** : 7 jours, **rotation à chaque usage** (l'ancien est invalidé immédiatement après émission du nouveau).
- Refresh stocké en **httpOnly cookie**, `Secure`, `SameSite=Strict`, `Path=/api/auth/refresh`.
- **JAMAIS en localStorage** — vulnérable au XSS.
- Logout : invalidation côté serveur via blacklist Redis (`refresh_blacklist:<jti>`, TTL = exp du token).
- Faille classique évitée : si la rotation est mal codée et que l'ancien refresh reste valide, attaquant peut replay → vol de session permanent.

### Multi-factor authentication (post-Sprint 1)
Architecture prête pour TOTP (2FA) via `django-otp`. À activer pour les comptes vendeurs et admins en Sprint 4+.

### Rate limiting des endpoints auth
- `django-axes` : 5 tentatives login échouées → blocage IP+username 15 minutes.
- `django-ratelimit` : 5 requêtes/minute sur `/api/auth/register`, 10/minute sur `/api/auth/login`.
- Cloudflare WAF en amont : règles bot management + rate limiting edge.

## 2. Autorisation — RBAC

### Rôles
- `customer` : utilisateur final, par défaut.
- `vendor` : vendeur, accès à ses propres ressources uniquement.
- `vendor_admin` : admin d'un compte vendeur multi-utilisateurs.
- `platform_admin` : admin ShopEasy, accès global.

Stockés dans `users/models.py:User.role`, plus permissions granulaires via `users/models.py:Permission` (RBAC fine-grained).

### Permissions DRF custom
```python
# users/permissions.py
class IsOwnerOrAdmin(BasePermission):
    def has_object_permission(self, request, view, obj):
        return obj.owner == request.user or request.user.role == 'platform_admin'

class IsVendorOfProduct(BasePermission):
    def has_object_permission(self, request, view, obj):
        return request.user.vendor == obj.vendor
```

### Règle d'or
**Permission par défaut = refus**. `IsAuthenticated` seul ne suffit jamais — toujours ajouter une permission de propriété/rôle.

```python
# CORRECT
permission_classes = [IsAuthenticated, IsOwnerOrAdmin]

# DANGEREUX
permission_classes = [IsAuthenticated]  # n'importe quel user voit tout
```

## 3. Validation des entrées

### Front + back — pas de confusion
- Front (Zod) : valide **pour l'UX** (feedback immédiat). Considère que le front peut être contourné.
- Back (DRF serializers) : valide **pour la sécurité**. Source de vérité.

Les schemas Zod et les serializers DRF doivent être **alignés** (mêmes règles métier, mêmes contraintes).

### Sanitization HTML
Tout contenu utilisateur affiché dans du HTML rich (descriptions produits, commentaires) doit être nettoyé :
- **Python** : `bleach.clean(html, tags=ALLOWED_TAGS, attributes=ALLOWED_ATTRS)`
- **JS** (si rendu côté client à partir de HTML utilisateur) : `DOMPurify.sanitize(html)`

Whitelist stricte : pas de `<script>`, pas de `on*` events, pas de `style` brut.

### Injection SQL
- **Requêtes paramétrées uniquement**. Le Django ORM le fait nativement, c'est sûr.
- **Jamais de `.raw()` ou `cursor.execute()` avec concaténation**. Si tu dois utiliser raw : paramètres explicitement.
  ```python
  # CORRECT
  User.objects.raw("SELECT * FROM users WHERE email = %s", [email])
  
  # INTERDIT
  User.objects.raw(f"SELECT * FROM users WHERE email = '{email}'")  # injection
  ```

### Path traversal
Tout chemin construit à partir d'input utilisateur : validation explicite.
```python
import os
from django.core.exceptions import SuspiciousOperation

safe_path = os.path.normpath(os.path.join(SAFE_BASE_DIR, user_input))
if not safe_path.startswith(SAFE_BASE_DIR):
    raise SuspiciousOperation("Path traversal attempt")
```

### XSS (Cross-Site Scripting)
- Next.js échappe par défaut le JSX. Pas de `dangerouslySetInnerHTML` sans sanitization.
- Django templates échappent par défaut. Pas de `|safe` sans sanitization.
- Headers : `Content-Security-Policy` strict configuré via `django-csp`.

### CSRF
- Django CSRF middleware actif.
- DRF : `csrf_exempt` interdit sauf endpoints d'API publics sans cookie d'auth.
- SameSite=Strict sur cookies de session.

## 4. Headers de sécurité

Configurés via middleware Django + ingress Kubernetes :

| Header | Valeur |
|---|---|
| `Strict-Transport-Security` | `max-age=31536000; includeSubDomains; preload` |
| `X-Content-Type-Options` | `nosniff` |
| `X-Frame-Options` | `DENY` (sauf routes embed explicites) |
| `Referrer-Policy` | `strict-origin-when-cross-origin` |
| `Permissions-Policy` | `geolocation=(), microphone=(), camera=()` |
| `Content-Security-Policy` | Strict, allow-list explicite, `'nonce-<random>'` pour scripts inline |
| `Cross-Origin-Opener-Policy` | `same-origin` |
| `Cross-Origin-Embedder-Policy` | `require-corp` |

### CORS
- Allow-list explicite par environnement (`CORS_ALLOWED_ORIGINS`).
- **Jamais `*`** en production.
- `Access-Control-Allow-Credentials: true` uniquement avec origin précis.

## 5. Secrets — gestion

### Règles absolues
- **Aucun secret en clair dans le repo**. `.env` gitignored. `.env.example` commité avec placeholders.
- **Si Claude voit un secret dans le contexte** (token, password, clé API, certificat privé) : refuse la tâche, alerte l'utilisateur, suggère la rotation.

### Stockage par environnement
- **Dev local** : `.env` (gitignored), chargé par `python-dotenv`.
- **CI** : GitHub Actions secrets (chiffrés).
- **Staging/Prod** :
  - AWS : Secrets Manager
  - GCP : Secret Manager
  - Montés dans K8s via **External Secrets Operator** (jamais de secrets dans les manifests YAML).

### Rotation
- Trimestrielle pour DB passwords, JWT signing keys, API keys partenaires.
- Procédure documentée : `docs/runbooks/secret-rotation.md`.
- Rotation des JWT signing keys : avec période de grace pour valider les tokens émis avec l'ancienne clé.

### Detect-secrets
Hook pre-commit `detect-secrets` scan les fichiers modifiés. Si un secret est détecté : commit bloqué.

## 6. Logging et observabilité

### Ce qu'on logue
- Erreurs avec stack trace (Sentry).
- Actions utilisateur non-sensibles (analytics).
- Requêtes API avec status, latence, user_id (Grafana).
- Événements infra (Kubernetes events, autoscaling).

### Ce qu'on ne logue JAMAIS
- Mots de passe (même hashés).
- Tokens (access, refresh, API keys) — même partiellement.
- Numéros de carte bancaire (PAN), CVV.
- Numéros d'identification (SIN, NAS, passeport, permis).
- Adresses email en clair dans les logs publics (acceptable dans audit log signé).
- Contenu des messages privés utilisateur.

### Structuration
- Logs JSON structurés, jamais texte libre.
- Format : `{ timestamp, level, service, request_id, user_id, message, ...context }`.
- `request_id` propagé entre services pour tracing distribué (OpenTelemetry).

### Sanitization automatique
Middleware Django filtre les patterns sensibles avant émission :
- Headers `Authorization`, `Cookie` → `[REDACTED]`
- Body fields nommés `password`, `token`, `cc_number`, `cvv` → `[REDACTED]`
- Email patterns en mode public log → masqués (`a***@gmail.com`)

## 7. Audit log immuable

### Architecture
`apps/audit/` — application dédiée, **append-only**, séparée des logs applicatifs.

```python
# apps/audit/models.py
class AuditEntry(models.Model):
    id = UUIDField(default=uuid7, primary_key=True)
    timestamp = DateTimeField(auto_now_add=True, db_index=True)
    actor_id = UUIDField()  # qui
    actor_role = CharField(max_length=20)
    action = CharField(max_length=100)  # quoi : "order.create", "payment.refund", "user.export_data"
    resource_type = CharField(max_length=50)
    resource_id = UUIDField()
    jurisdiction = CharField(max_length=10)  # CA-QC, FR, MA, NG, ...
    ip_address = GenericIPAddressField()
    user_agent = TextField()
    metadata = JSONField()  # contexte additionnel
    signature = TextField()  # HMAC-SHA256 du record pour intégrité
```

### Actions auditées (non-exhaustif)
- Création/modification/annulation de commande.
- Création/remboursement de paiement.
- Changement de rôle utilisateur.
- Accès aux données d'un autre vendeur (admin).
- Export RGPD/Loi 25 des données utilisateur.
- Suppression de compte (droit à l'oubli).
- Modification de configuration vendeur (KYC, payouts).
- Accès aux logs ou à l'audit log lui-même.

### Rétention
- **7 ans minimum** (conformité commerciale + fiscalité).
- Stockage : Postgres + archivage froid trimestriel vers S3/GCS avec versioning.

### Intégrité
- Chaque entrée signée avec HMAC-SHA256 (clé stockée séparément, rotation annuelle avec rétention).
- Vérification d'intégrité périodique (Celery beat hebdomadaire).
- **Aucune modification possible** après écriture (contrainte DB + permission DB stricte).

## 8. Conformité réglementaire multi-juridiction

L'architecture supporte l'application simultanée de plusieurs cadres selon la résidence de l'utilisateur. Chaque utilisateur a un champ `jurisdiction` calculé à l'inscription (adresse + IP géoloc + déclaration).

Le dispatcher `apps/audit/compliance.py` applique les règles spécifiques.

### Cadres supportés
| Juridiction | Cadre | Particularités |
|---|---|---|
| Québec | Loi 25 | Registre traitements, consentement granulaire, droit à l'oubli, notification violation < 72h |
| Canada | PIPEDA | Politique confidentialité accessible, opt-in marketing, droit d'accès |
| UE | RGPD | DPO, AIPD, exports JSON, suppression effective |
| Royaume-Uni | UK GDPR | Similaire RGPD, ICO comme autorité |
| Afrique du Sud | POPIA | Registration Information Regulator, consentement explicite |
| Nigeria | NDPR | DPO, audit annuel, notification violation |
| Kenya | DPA 2019 | Registration ODPC, base légale documentée |
| Maroc | Loi 09-08 | Déclaration CNDP, transferts hors Maroc encadrés |

### Mécanismes communs implémentés
- **Registre des traitements** : géré dans `audit/compliance.py:ProcessingRegistry`.
- **Consentement granulaire** : finalités séparées (compte, marketing, analytics, partage partenaires), opt-in explicite, modification à tout moment.
- **Droit à l'oubli** : suppression hard du user + anonymisation des données conservées légalement (commandes, factures), enregistrement dans audit log.
- **Portabilité** : export JSON de toutes les données utilisateur via `/api/users/me/export` (rate-limité, vérification email).
- **Notification de violation** : workflow déclenché, notification utilisateurs + autorité de référence dans la fenêtre légale.

### Transferts internationaux
- Hébergement des données par juridiction quand requis (RGPD : UE, Loi 09-08 : Maroc).
- Multi-cloud (AWS + GCP) permet le déploiement par région.
- Clauses contractuelles types pour les transferts hors zone.

## 9. Dépendances et supply chain

### Audit obligatoire avant chaque PR
- `bandit` : SAST Python.
- `pip-audit` : CVEs des deps Python.
- `pnpm audit` : CVEs des deps JS.
- `trivy fs` : scan filesystem.
- `snyk` : audit complet (optionnel selon licence).

`make security` exécute tout. CI bloque si vulnérabilité high/critical.

### Gestion des deps
- **Renovate** ou **Dependabot** actif, PRs auto pour patchs sécurité.
- Pas de dépendance < 100 stars GitHub sans review documentée + ADR.
- Lockfile committé (`uv.lock`, `pnpm-lock.yaml`) — reproductibilité garantie.

### Container security
- Base images : distroless ou Alpine officiel quand possible.
- Multi-stage builds : pas de tools de build dans l'image finale.
- `trivy image` sur chaque build CI.
- Pas d'utilisateur `root` dans le container (USER non-root).
- Pas de port privilégié exposé.

## 10. Réponse aux incidents

### Workflow
1. Détection (Sentry alert, anomalie métrique, signalement user).
2. Containment (feature flag off, rollback si critique).
3. Investigation (logs, traces, audit log).
4. Postmortem (`/postmortem <incident>`).
5. Actions correctives (issues GitHub, tests de non-régression).

### Notification utilisateurs en cas de violation de données
- Évaluation < 24h.
- Notification dans la fenêtre légale (72h RGPD/Loi 25, variable selon juridiction).
- Template d'email dans `apps/api/templates/emails/<lang>/data-breach-notification.html`.

## 11. Checklist sécurité avant merge

Touche au moins une de ces zones ? Tout doit être coché.

- [ ] **Auth** : permissions explicites, rate limiting actif, refresh rotation testée.
- [ ] **Paiements** : montants validés serveur, audit log écrit, transactions atomiques.
- [ ] **Uploads** : type/taille validés, scan antivirus si applicable, stockage isolé.
- [ ] **Données personnelles** : consentement vérifié, audit log écrit, juridiction prise en compte.
- [ ] **API publique** : rate limiting, validation, pas de leak d'info dans les erreurs.
- [ ] **Secrets** : aucun en clair, `.env.example` à jour, rotation prévue.
- [ ] `make security` vert.
- [ ] Headers de sécurité préservés.

## 12. Ressources

- OWASP Top 10 : https://owasp.org/Top10/
- OWASP Cheat Sheets : https://cheatsheetseries.owasp.org/
- Django Security : https://docs.djangoproject.com/en/5.2/topics/security/
- Next.js Security : https://nextjs.org/docs/pages/building-your-application/configuring/content-security-policy
- CIS Benchmarks (Kubernetes, Docker) : https://www.cisecurity.org/cis-benchmarks/
