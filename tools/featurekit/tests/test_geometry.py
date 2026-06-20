import pytest

pytest.importorskip("build123d")
from build123d import Box, Cylinder, Pos  # noqa: E402

from featurekit.geometry import feature_view, solid  # noqa: E402
from featurekit.model import Feature, Part  # noqa: E402


def _part():
    p = Part("widget")
    p.add(Feature(id="base_plate", name="Base plate", kind="add",
                  build=lambda: Box(20, 20, 4)))
    p.add(Feature(id="vent_hole", name="Vent hole", kind="cut",
                  build=lambda: Pos(0, 0, 0) * Cylinder(3, 10)))
    return p


def test_solid_is_single_solid_with_hole_removed():
    s = solid(_part())
    # one fused solid
    assert len(s.solids()) == 1
    # volume is plate minus the bored cylinder (cylinder spans the 4mm plate)
    plate_vol = 20 * 20 * 4
    assert s.volume < plate_vol
    assert s.label == "widget"


def test_feature_view_has_labeled_colored_bodies():
    bodies = feature_view(_part())
    assert [b.label for b in bodies] == ["base_plate", "vent_hole"]
    add_body, cut_body = bodies
    # alpha encodes add vs cut (1.0 vs 0.35)
    # build123d Color has no .alpha property; alpha is the 4th element of the iterator
    assert float(list(add_body.color)[3]) == pytest.approx(1.0, abs=1e-6)
    assert float(list(cut_body.color)[3]) == pytest.approx(0.35, abs=1e-6)
