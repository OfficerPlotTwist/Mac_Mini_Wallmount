"""featurekit — feature-first CAD: one feature list -> fused part + colored feature view."""

import importlib

from featurekit.model import Feature, FeatureValidationError, Part, resolved_color
from featurekit.naming import NamingError, validate_slug
from featurekit.color import PALETTE, feature_color, normalize_hex
from featurekit.sidecar import render_sidecar, write_sidecar

# Import the generate function eagerly.  The featurekit.generate submodule only
# imports cadpy (which is always on sys.path) at module level; build123d is
# imported lazily inside the function body, so this does NOT trigger a
# build123d import at package-import time.
from featurekit.generate import generate  # noqa: E402

__all__ = [
    "Feature", "Part", "FeatureValidationError", "resolved_color",
    "NamingError", "validate_slug",
    "PALETTE", "feature_color", "normalize_hex",
    "render_sidecar", "write_sidecar",
    "generate",
]

# Geometry adapter (solid, feature_view) is imported lazily to avoid importing
# build123d at package import.  The same-named submodule "generate" is handled
# above via an explicit eager import so that "from featurekit import generate"
# always returns the function rather than the submodule.
def __getattr__(name):  # noqa: D401
    if name in {"solid", "feature_view"}:
        geometry = importlib.import_module("featurekit.geometry")
        return getattr(geometry, name)
    raise AttributeError(name)
