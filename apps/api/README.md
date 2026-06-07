# ShopEasy API

Django REST Framework backend for ShopEasy e-commerce platform.

## Requirements

- Python 3.13+
- PostgreSQL 17
- Redis 7.4

## Setup

```bash
# From repository root
make setup

# Or manually
cd apps/api
uv sync --group dev
uv run python manage.py migrate
uv run python manage.py runserver
```

## Development

```bash
# Run tests
uv run pytest

# Lint & format
uv run ruff check .
uv run ruff format .

# Type check
uv run mypy .
```

## Project Structure

```text
apps/api/
├── shopeasy/          # Django project configuration
│   ├── settings.py    # Settings (single file, YAGNI)
│   ├── urls.py        # Root URL configuration
│   ├── wsgi.py        # WSGI entry point
│   └── asgi.py        # ASGI entry point
├── core/              # Core app (shared utilities)
├── manage.py          # Django CLI
├── pyproject.toml     # Python dependencies (uv)
└── .python-version    # Python version (3.13)
```

## Apps (Sprint 2+)

- `catalog/` - Products, categories, variants
- `cart/` - Shopping cart, sessions
- `orders/` - Checkout, order management
- `users/` - Authentication, profiles
- `vendors/` - Vendor accounts, KYC
- `payments/` - Payment processing
- `notifications/` - Email, in-app notifications
- `analytics/` - Business metrics
- `audit/` - Audit logging
