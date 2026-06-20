import re

import pytest

from featurekit.color import PALETTE, feature_color, normalize_hex

HEX = re.compile(r"^#[0-9A-F]{6}$")


def test_palette_is_distinct_valid_hex():
    assert len(PALETTE) >= 12
    assert len(set(PALETTE)) == len(PALETTE)
    assert all(HEX.match(c) for c in PALETTE)


def test_feature_color_is_deterministic_and_in_palette():
    a = feature_color("base_plate")
    b = feature_color("base_plate")
    assert a == b
    assert a in PALETTE


def test_feature_color_stable_across_added_ids():
    # Adding a new id must not change an existing id's color (hash-keyed, not order-keyed).
    before = feature_color("standoff")
    _ = feature_color("a-brand-new-feature")
    assert feature_color("standoff") == before


def test_normalize_hex_upcases_and_validates():
    assert normalize_hex("#aabbcc") == "#AABBCC"
    with pytest.raises(ValueError):
        normalize_hex("aabbcc")  # missing '#'
    with pytest.raises(ValueError):
        normalize_hex("#xyzxyz")
