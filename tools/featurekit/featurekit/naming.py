"""Slug naming gate — the load-bearing invariant for feature ids."""
from __future__ import annotations

import re

SLUG_RE = re.compile(r"^[a-z0-9]+(?:[-_][a-z0-9]+)*$")


class NamingError(ValueError):
    """Raised when a feature name/id violates the naming rules."""


def validate_slug(value: str, *, field: str = "id") -> str:
    """Return value if it is a valid lowercase slug, else raise NamingError."""
    if not isinstance(value, str) or not value:
        raise NamingError(f"feature {field} must be a non-empty string, got {value!r}")
    if not SLUG_RE.match(value):
        raise NamingError(
            f"feature {field} {value!r} is not a valid slug "
            f"(lowercase letters/digits, single - or _ separators): {SLUG_RE.pattern}"
        )
    return value
