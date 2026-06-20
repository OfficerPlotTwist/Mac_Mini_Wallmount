"""Deterministic, order-independent id -> color assignment."""
from __future__ import annotations

import hashlib
import re

_HEX_RE = re.compile(r"^#[0-9a-fA-F]{6}$")

# Curated, visually distinct palette (no near-duplicates, readable on a dark viewport).
PALETTE: tuple[str, ...] = (
    "#4E79A7", "#F28E2B", "#59A14F", "#E15759",
    "#76B7B2", "#EDC948", "#B07AA1", "#FF9DA7",
    "#9C755F", "#BAB0AC", "#1B9E77", "#D95F02",
    "#7570B3", "#E7298A", "#66A61E", "#E6AB02",
)


def normalize_hex(value: str) -> str:
    """Validate and upper-case an explicit '#RRGGBB' color pin."""
    if not isinstance(value, str) or not _HEX_RE.match(value):
        raise ValueError(f"color must be '#RRGGBB' hex, got {value!r}")
    return "#" + value[1:].upper()


def feature_color(feature_id: str) -> str:
    """Deterministic palette color for a feature id (stable across processes/runs)."""
    digest = hashlib.sha1(feature_id.encode("utf-8")).digest()
    index = int.from_bytes(digest[:4], "big") % len(PALETTE)
    return PALETTE[index]
