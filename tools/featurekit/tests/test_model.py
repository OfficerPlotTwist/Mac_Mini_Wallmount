import pytest

from featurekit.model import Feature, FeatureValidationError, Part


def _f(fid, kind="add", name=None, color=None):
    return Feature(id=fid, name=name or fid.replace("_", " ").title(),
                   kind=kind, build=lambda: object(), color=color)


def test_manifest_shape_and_deterministic_color():
    p = Part("widget")
    p.add(_f("base_plate", "add"))
    p.add(_f("vent_holes", "cut"))
    m = p.manifest()
    assert [row["id"] for row in m] == ["base_plate", "vent_holes"]
    assert m[0]["kind"] == "add" and m[1]["kind"] == "cut"
    assert all(row["colorHex"].startswith("#") and len(row["colorHex"]) == 7 for row in m)
    # name present
    assert m[0]["name"] == "Base Plate"


def test_explicit_color_pin_wins():
    p = Part("widget")
    p.add(_f("base_plate", "add", color="#abcdef"))
    assert p.manifest()[0]["colorHex"] == "#ABCDEF"


def test_validate_rejects_duplicate_ids():
    p = Part("widget")
    p.add(_f("dup", "add"))
    p.add(_f("dup", "cut"))
    with pytest.raises(FeatureValidationError) as exc:
        p.validate()
    assert "dup" in str(exc.value)


def test_validate_rejects_bad_kind():
    p = Part("widget")
    p.add(_f("x", "blend"))  # not add/cut
    with pytest.raises(FeatureValidationError) as exc:
        p.validate()
    assert "kind" in str(exc.value) and "x" in str(exc.value)


def test_validate_rejects_bad_slug_and_empty_name():
    p = Part("widget")
    p.add(Feature(id="Bad Id", name="x", kind="add", build=lambda: None))
    with pytest.raises(FeatureValidationError):
        p.validate()
    p2 = Part("widget")
    p2.add(Feature(id="ok", name="  ", kind="add", build=lambda: None))
    with pytest.raises(FeatureValidationError):
        p2.validate()


def test_validate_rejects_empty_part():
    with pytest.raises(FeatureValidationError):
        Part("widget").validate()


def test_validate_requires_at_least_one_add():
    p = Part("widget")
    p.add(_f("only_a_hole", "cut"))
    with pytest.raises(FeatureValidationError):
        p.validate()


def test_manifest_calls_validate():
    p = Part("widget")
    p.add(_f("dup", "add"))
    p.add(_f("dup", "add"))
    with pytest.raises(FeatureValidationError):
        p.manifest()


def test_validate_rejects_bad_color_pin():
    p = Part("widget")
    p.add(Feature(id="base_plate", name="Base plate", kind="add",
                  build=lambda: object(), color="not-a-hex"))
    with pytest.raises(FeatureValidationError) as exc:
        p.validate()
    assert "base_plate" in str(exc.value)
