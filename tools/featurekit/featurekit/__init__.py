"""featurekit — feature-first CAD: one feature list -> fused part + colored feature view."""

from featurekit.model import Feature, FeatureValidationError, Part, resolved_color
from featurekit.naming import NamingError, validate_slug
from featurekit.color import PALETTE, feature_color, normalize_hex

__all__ = [
    "Feature", "Part", "FeatureValidationError", "resolved_color",
    "NamingError", "validate_slug",
    "PALETTE", "feature_color", "normalize_hex",
]
