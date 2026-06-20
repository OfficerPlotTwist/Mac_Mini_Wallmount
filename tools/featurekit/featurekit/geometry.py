"""build123d geometry adapter: the two reductions over a feature list."""
from __future__ import annotations

from functools import reduce
from typing import Any

from cadpy import label_shape  # vendored cadpy on sys.path (see tests/conftest.py)

from featurekit.model import Part, resolved_color


def _b123d_color(hex_str: str, alpha: float) -> Any:
    from build123d import Color

    r = int(hex_str[1:3], 16) / 255.0
    g = int(hex_str[3:5], 16) / 255.0
    b = int(hex_str[5:7], 16) / 255.0
    return Color(r, g, b, alpha)


def solid(part: Part) -> Any:
    """Fuse all 'add' solids, subtract all 'cut' solids -> one printable solid."""
    part.validate()
    adds = [f.build() for f in part.features if f.kind == "add"]
    cuts = [f.build() for f in part.features if f.kind == "cut"]
    body = reduce(lambda a, b: a + b, adds)
    if cuts:
        body = reduce(lambda a, b: a - b, cuts, body)
    body.label = part.name
    return body


def feature_view(part: Part) -> list[Any]:
    """One labeled, colored solid per feature; cuts rendered translucent (ghost)."""
    part.validate()
    bodies: list[Any] = []
    for f in part.features:
        shape = f.build()
        alpha = 1.0 if f.kind == "add" else 0.35
        label_shape(shape, f.id, color=_b123d_color(resolved_color(f), alpha))
        bodies.append(shape)
    return bodies
