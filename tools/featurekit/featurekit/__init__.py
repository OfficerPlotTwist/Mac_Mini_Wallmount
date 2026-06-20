"""featurekit — feature-first CAD: one feature list -> fused part + colored feature view."""

from featurekit.model import Feature, FeatureValidationError, Part, resolved_color
from featurekit.naming import NamingError, validate_slug
from featurekit.color import PALETTE, feature_color, normalize_hex
from featurekit.sidecar import render_sidecar, write_sidecar

__all__ = [
    "Feature", "Part", "FeatureValidationError", "resolved_color",
    "NamingError", "validate_slug",
    "PALETTE", "feature_color", "normalize_hex",
    "render_sidecar", "write_sidecar",
    "generate",
]

# Geometry adapter and generate are imported lazily to avoid importing build123d at package import.
def __getattr__(name):  # noqa: D401
    if name in {"solid", "feature_view"}:
        from featurekit import geometry
        return getattr(geometry, name)
    if name == "generate":
        from featurekit import generate as _generate_mod
        return _generate_mod.generate
    raise AttributeError(name)
