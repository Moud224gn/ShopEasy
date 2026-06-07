"""Smoke test: ensures Django machinery loads correctly."""

from __future__ import annotations

from django.apps import apps


def test_core_app_is_loaded() -> None:
    """The core app should be registered with Django."""
    assert apps.is_installed("core")


def test_django_settings_loaded() -> None:
    """Settings should load without error."""
    from django.conf import settings

    assert settings.LANGUAGE_CODE == "fr"
