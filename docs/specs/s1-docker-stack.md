# Sprint 1 #2 — Docker Stack Specification

## Objectif

Fournir un environnement de developpement Docker reproductible avec hot-reload pour l'API Django et le frontend Next.js.

## Services

| Service | Profile | Image | Ports | Justification |
|---------|---------|-------|-------|---------------|
| postgres | default | postgres:17-alpine | 5432 | Base de donnees principale |
| redis | default | redis:7.4-alpine | 6379 | Cache + sessions |
| api | default | build local | 8000 | Django dev server |
| web | default | build local | 3000 | Next.js dev server |
| minio | full | minio/minio:latest | 9000, 9001 | S3-compatible (Sprint 5+) |
| mailpit | full | axllent/mailpit:latest | 8025, 1025 | SMTP dev (Sprint 4+) |

**Usage profiles** :
- `make dev` → postgres, redis, api, web (default)
- `make dev-full` → tous les services incluant minio et mailpit

## Decisions architecturales

### Base images

| Service | Image | Raison |
|---------|-------|--------|
| API | python:3.13-slim | psycopg[binary] incompatible avec Alpine (musl-libc) |
| Web | node:22-alpine | Next.js standalone supporte Alpine, ~150MB d'economie |

### Multi-stage builds

- **API** : base (uv) → development → production
- **Web** : base → deps → builder → production

### Bind-mounts selectifs (pas le dossier complet)

Monter `./apps/api:/app` cause des conflits sur Windows (`.venv`, `__pycache__`, binaires Linux vs Windows).

**Solution** : monter uniquement le code source.

API :
- `shopeasy/`, `core/`, `manage.py`, `pyproject.toml`, `uv.lock`

Web :
- `src/`, `messages/`, `public/`, `next.config.ts`, `tailwind.config.ts`, `postcss.config.js`, `tsconfig.json`, `package.json`

### Anonymous volumes

Preservent les caches dans le container (pas ecrases par bind-mount) :
- `/app/.venv` (api)
- `/app/node_modules` (web)
- `/app/.next` (web)

### User non-root

- API : `appuser` (UID 1000)
- Web : `nextjs:nodejs` (UID/GID 1001)

### Next.js standalone output

Ajouter `output: "standalone"` dans `next.config.ts` pour image production minimale (~150MB).

## Criteres de validation

- [ ] `make dev` demarre postgres + redis + api + web en < 60s
- [ ] `make dev-full` demarre tous les services
- [ ] Hot-reload API : modifier `.py` → reload visible
- [ ] Hot-reload Web : modifier `.tsx` → reload visible
- [ ] Healthchecks postgres/redis passent en < 30s
- [ ] `make logs`, `make shell-db`, `make migrate`, `make migration` fonctionnels
- [ ] Images production < 200MB chacune

## Hors scope

- Deployment K8s (Sprint 13+)
- TLS / reverse proxy
- Multi-environment configs
