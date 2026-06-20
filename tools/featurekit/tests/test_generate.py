import pytest

pytest.importorskip("build123d")

from pathlib import Path  # noqa: E402

from featurekit.generate import generate  # noqa: E402
from examples.plate_with_hole import build_part  # noqa: E402


def test_generate_writes_three_artifacts(tmp_path):
    out = generate(build_part(), stem=tmp_path / "plate")
    assert out["part"].name == "plate.step"
    assert out["features"].name == "plate.features.step"
    assert out["sidecar"].name == "plate.features.step.js"
    for p in out.values():
        assert p.exists() and p.stat().st_size > 0
    # sidecar references the features STEP and lists both features
    js = out["sidecar"].read_text(encoding="utf-8")
    assert "base_plate" in js and "vent_hole" in js


def test_generate_fails_closed_on_bad_names(tmp_path):
    from featurekit.model import Feature, Part
    bad = Part("plate")
    bad.add(Feature(id="Bad Id", name="x", kind="add", build=lambda: None))
    from featurekit.model import FeatureValidationError
    with pytest.raises(FeatureValidationError):
        generate(bad, stem=tmp_path / "plate")
    # no artifacts written
    assert not list(tmp_path.glob("plate*"))
