import json
import re
from pathlib import Path

from featurekit.model import Feature, Part
from featurekit.sidecar import render_sidecar, write_sidecar


def _part():
    p = Part("widget")
    p.add(Feature(id="base_plate", name="Base plate", kind="add", build=lambda: None))
    p.add(Feature(id="vent_holes", name="Vent holes", kind="cut", build=lambda: None))
    return p


def _extract_default_object(js: str) -> dict:
    # The sidecar embeds its manifest as a JSON blob in a marked comment for testability.
    m = re.search(r"/\*FEATUREKIT_JSON\n(.*?)\nFEATUREKIT_JSON\*/", js, re.S)
    assert m, "sidecar must embed a FEATUREKIT_JSON block"
    return json.loads(m.group(1))


def test_render_sidecar_is_es_module_with_manifest():
    js = render_sidecar(_part(), step_path="models/widget.features.step")
    assert "export default" in js
    data = _extract_default_object(js)
    assert data["manifest"]["schemaVersion"] == 1
    assert data["manifest"]["step"]["path"] == "models/widget.features.step"
    feats = data["manifest"]["features"]
    assert [f["id"] for f in feats] == ["base_plate", "vent_holes"]
    assert feats[1]["kind"] == "cut"
    assert data["view"]["ghostCutters"] is True
    assert data["view"]["colorMode"] == "diagnostic"


def test_write_sidecar_writes_named_file(tmp_path):
    step = tmp_path / "widget.features.step"
    step.write_text("placeholder", encoding="utf-8")
    out = write_sidecar(_part(), features_step_path=step)
    assert out == tmp_path / "widget.features.step.js"
    assert "export default" in out.read_text(encoding="utf-8")
