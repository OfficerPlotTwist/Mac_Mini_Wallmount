"""Feature/Part model + the generation-time naming-rigor gate."""
from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any, Callable

from featurekit.color import feature_color, normalize_hex
from featurekit.naming import NamingError, validate_slug

KINDS = ("add", "cut")


class FeatureValidationError(NamingError):
    """Raised when a part's feature list violates the naming-rigor invariants."""


@dataclass
class Feature:
    id: str
    name: str
    kind: str
    build: Callable[[], Any]
    color: str | None = None


def resolved_color(feature: Feature) -> str:
    if feature.color is not None:
        return normalize_hex(feature.color)
    return feature_color(feature.id)


class Part:
    def __init__(self, name: str) -> None:
        self.name = name
        self.features: list[Feature] = []

    def add(self, feature: Feature) -> Feature:
        self.features.append(feature)
        return feature

    def validate(self) -> None:
        if not self.features:
            raise FeatureValidationError(f"part {self.name!r} has no features")
        seen: set[str] = set()
        adds = 0
        for f in self.features:
            try:
                validate_slug(f.id, field="id")
            except NamingError as exc:
                raise FeatureValidationError(str(exc)) from exc
            if not isinstance(f.name, str) or not f.name.strip():
                raise FeatureValidationError(f"feature {f.id!r} has empty name")
            if f.kind not in KINDS:
                raise FeatureValidationError(
                    f"feature {f.id!r} kind {f.kind!r} must be one of {KINDS}"
                )
            if f.id in seen:
                raise FeatureValidationError(f"duplicate feature id {f.id!r}")
            seen.add(f.id)
            if f.color is not None:
                normalize_hex(f.color)  # raises ValueError on bad pin
            if f.kind == "add":
                adds += 1
        if adds == 0:
            raise FeatureValidationError(
                f"part {self.name!r} has no 'add' features — nothing printable"
            )

    def manifest(self) -> list[dict]:
        self.validate()
        return [
            {"id": f.id, "name": f.name.strip(), "kind": f.kind, "colorHex": resolved_color(f)}
            for f in self.features
        ]
