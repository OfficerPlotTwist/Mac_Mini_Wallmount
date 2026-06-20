# featurekit Engine (Modules 0–1) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the Python `featurekit` engine that turns one feature list into a fused printable STEP plus a colored, labeled feature-view assembly + a manifest sidecar, with naming rigor enforced as a generation-time gate.

**Architecture:** A standalone local package `tools/featurekit/` imports the installed `cadpy`. A pure-Python core (manifest contract, slug naming gate, deterministic id→color, sidecar emission) carries the naming-rigor value and is testable without build123d. A thin geometry adapter uses `cadpy`/`build123d` to produce the two reductions: `solid()` (fuse adds, subtract cuts) and `feature_view()` (a list of labeled, colored solids — adds opaque, cuts translucent) that the existing `scripts/step` CLI renders into STEP + GLB.

**Tech Stack:** Python 3.12, pytest 9, build123d (geometry), cadpy (`AssemblyHelper`, `label_shape`), the `cad` skill's `scripts/step` generator pipeline.

## Global Constraints

- Python target: **3.12** (matches local `python` 3.12.10).
- `featurekit` lives at **`tools/featurekit/`** and imports the installed cadpy from `.agents/skills/cad/scripts/packages/cadpy/src` (added to `sys.path` via `tests/conftest.py`); never edit the vendored `cadpy` files. (Refinement of the spec's "cadpy.featurekit" wording — keeps our code out of vendored skill dirs that get overwritten on skill update.)
- Feature `id` slug regex: **`^[a-z0-9]+(?:[-_][a-z0-9]+)*$`** (verbatim from spec §3.1).
- Feature `kind` ∈ **`{"add", "cut"}`** (verbatim).
- `colorHex` format: **`#RRGGBB`** uppercase hex; deterministic function of `id` unless explicitly pinned.
- Color determinism MUST use **`hashlib.sha1`**, never builtin `hash()` (which is salted per-process).
- STEP part **label == feature id** (the binding the viewer maps rows to bodies by).
- Generation **fails closed**: any naming violation raises before geometry is built; no artifacts written.
- Cutter (`kind == "cut"`) ghost alpha: **0.35**; additive alpha: **1.0**.
- `docs`/`tools` are gitignored by the repo's allowlist `.gitignore`; add `!tools` exception in the scaffold task.

---

### Task 1: Package scaffold + dependency install + cadpy import seam

**Files:**
- Create: `tools/featurekit/featurekit/__init__.py`
- Create: `tools/featurekit/tests/conftest.py`
- Create: `tools/featurekit/README.md`
- Create: `tools/featurekit/requirements.txt`
- Modify: `.gitignore` (add `!tools`)

**Interfaces:**
- Consumes: nothing.
- Produces: importable package `featurekit`; `tests/conftest.py` puts the vendored cadpy `src` on `sys.path` so `import cadpy` works in tests.

- [ ] **Step 1: Add the gitignore exception**

In `.gitignore`, directly after the `!docs` line added earlier, add:

```gitignore
# Feature-first CAD engine (local package)
!tools
```

- [ ] **Step 2: Create the package + conftest + deps**

`tools/featurekit/featurekit/__init__.py`:

```python
"""featurekit — feature-first CAD: one feature list -> fused part + colored feature view."""

__all__ = []
```

`tools/featurekit/tests/conftest.py`:

```python
import sys
from pathlib import Path

# Make the local featurekit package importable.
PKG_ROOT = Path(__file__).resolve().parents[1]
if str(PKG_ROOT) not in sys.path:
    sys.path.insert(0, str(PKG_ROOT))

# Make the installed (vendored) cadpy importable for geometry tests.
REPO_ROOT = PKG_ROOT.parents[1]
CADPY_SRC = REPO_ROOT / ".agents" / "skills" / "cad" / "scripts" / "packages" / "cadpy" / "src"
if CADPY_SRC.is_dir() and str(CADPY_SRC) not in sys.path:
    sys.path.insert(0, str(CADPY_SRC))
```

`tools/featurekit/requirements.txt`:

```text
build123d>=0.7
```

`tools/featurekit/README.md`:

```markdown
# featurekit

Feature-first CAD engine. Declare a part as an ordered list of named features
(each `add` or `cut`, each with a stable id and deterministic color); generate
a fused printable STEP plus a colored, labeled feature-view assembly + manifest
sidecar for the CAD Viewer's Feature Legend panel.

## Dev setup

```bash
pip install -r tools/featurekit/requirements.txt   # build123d for geometry
python -m pytest tools/featurekit/tests -v
```

Geometry tests are skipped automatically when build123d is not installed.
```

- [ ] **Step 3: Verify the package imports and cadpy is reachable from tests**

Run: `cd tools/featurekit && python -c "import sys; sys.path.insert(0,'.'); import featurekit; print('ok')"`
Expected: prints `ok`.

Run: `python -m pytest tools/featurekit/tests -q`
Expected: `no tests ran` (collection succeeds, conftest imports cleanly).

- [ ] **Step 4: Commit**

```bash
git add .gitignore tools/featurekit
git commit -m "feat(featurekit): scaffold package + cadpy import seam"
```

---

### Task 2: Slug naming gate

**Files:**
- Create: `tools/featurekit/featurekit/naming.py`
- Test: `tools/featurekit/tests/test_naming.py`

**Interfaces:**
- Consumes: nothing.
- Produces:
  - `SLUG_RE: re.Pattern` — compiled `^[a-z0-9]+(?:[-_][a-z0-9]+)*$`.
  - `class NamingError(ValueError)`.
  - `validate_slug(value: str, *, field: str = "id") -> str` — returns the slug or raises `NamingError` naming the field and value.

- [ ] **Step 1: Write the failing test**

`tools/featurekit/tests/test_naming.py`:

```python
import pytest

from featurekit.naming import NamingError, validate_slug


@pytest.mark.parametrize("good", ["base_plate", "vent-holes", "m3", "a1-b2_c3"])
def test_validate_slug_accepts_valid(good):
    assert validate_slug(good) == good


@pytest.mark.parametrize("bad", ["", "Base", "base plate", "-x", "x-", "x__y" "@", "Ünïcode"])
def test_validate_slug_rejects_invalid(bad):
    with pytest.raises(NamingError):
        validate_slug(bad)


def test_naming_error_names_field_and_value():
    with pytest.raises(NamingError) as exc:
        validate_slug("Bad Id", field="id")
    msg = str(exc.value)
    assert "id" in msg and "Bad Id" in msg
```

- [ ] **Step 2: Run test to verify it fails**

Run: `python -m pytest tools/featurekit/tests/test_naming.py -v`
Expected: FAIL — `ModuleNotFoundError: No module named 'featurekit.naming'`.

- [ ] **Step 3: Write minimal implementation**

`tools/featurekit/featurekit/naming.py`:

```python
"""Slug naming gate — the load-bearing invariant for feature ids."""
from __future__ import annotations

import re

SLUG_RE = re.compile(r"^[a-z0-9]+(?:[-_][a-z0-9]+)*$")


class NamingError(ValueError):
    """Raised when a feature name/id violates the naming rules."""


def validate_slug(value: str, *, field: str = "id") -> str:
    """Return value if it is a valid lowercase slug, else raise NamingError."""
    if not isinstance(value, str) or not value:
        raise NamingError(f"feature {field} must be a non-empty string, got {value!r}")
    if not SLUG_RE.match(value):
        raise NamingError(
            f"feature {field} {value!r} is not a valid slug "
            f"(lowercase letters/digits, single - or _ separators): {SLUG_RE.pattern}"
        )
    return value
```

- [ ] **Step 4: Run test to verify it passes**

Run: `python -m pytest tools/featurekit/tests/test_naming.py -v`
Expected: PASS (all parametrized cases).

- [ ] **Step 5: Commit**

```bash
git add tools/featurekit/featurekit/naming.py tools/featurekit/tests/test_naming.py
git commit -m "feat(featurekit): slug naming gate"
```

---

### Task 3: Deterministic id→color palette

**Files:**
- Create: `tools/featurekit/featurekit/color.py`
- Test: `tools/featurekit/tests/test_color.py`

**Interfaces:**
- Consumes: nothing.
- Produces:
  - `PALETTE: tuple[str, ...]` — curated, visually distinct `#RRGGBB` colors.
  - `feature_color(feature_id: str) -> str` — deterministic `#RRGGBB` via `hashlib.sha1(id) % len(PALETTE)`.
  - `normalize_hex(value: str) -> str` — validates/upcases an explicit `#RRGGBB` pin, raises `ValueError` on bad format.

- [ ] **Step 1: Write the failing test**

`tools/featurekit/tests/test_color.py`:

```python
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `python -m pytest tools/featurekit/tests/test_color.py -v`
Expected: FAIL — `ModuleNotFoundError: No module named 'featurekit.color'`.

- [ ] **Step 3: Write minimal implementation**

`tools/featurekit/featurekit/color.py`:

```python
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
```

- [ ] **Step 4: Run test to verify it passes**

Run: `python -m pytest tools/featurekit/tests/test_color.py -v`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add tools/featurekit/featurekit/color.py tools/featurekit/tests/test_color.py
git commit -m "feat(featurekit): deterministic id->color palette"
```

---

### Task 4: Feature + Part model with the naming-rigor gate

**Files:**
- Create: `tools/featurekit/featurekit/model.py`
- Modify: `tools/featurekit/featurekit/__init__.py`
- Test: `tools/featurekit/tests/test_model.py`

**Interfaces:**
- Consumes: `validate_slug`/`NamingError` (Task 2), `feature_color`/`normalize_hex` (Task 3).
- Produces:
  - `@dataclass class Feature` with fields `id: str`, `name: str`, `kind: str`, `build: Callable[[], Any]`, `color: str | None = None`.
  - `class Part`: `__init__(self, name: str)`; `add(self, feature: Feature) -> Feature`; `validate(self) -> None`; `features: list[Feature]`; `manifest(self) -> list[dict]` where each dict is `{"id","name","kind","colorHex"}`.
  - `class FeatureValidationError(NamingError)`.
  - `resolved_color(feature: Feature) -> str` helper (pin via `normalize_hex` else `feature_color(id)`).

- [ ] **Step 1: Write the failing test**

`tools/featurekit/tests/test_model.py`:

```python
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `python -m pytest tools/featurekit/tests/test_model.py -v`
Expected: FAIL — `ModuleNotFoundError: No module named 'featurekit.model'`.

- [ ] **Step 3: Write minimal implementation**

`tools/featurekit/featurekit/model.py`:

```python
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
```

`tools/featurekit/featurekit/__init__.py` (replace contents):

```python
"""featurekit — feature-first CAD: one feature list -> fused part + colored feature view."""

from featurekit.model import Feature, FeatureValidationError, Part, resolved_color
from featurekit.naming import NamingError, validate_slug
from featurekit.color import PALETTE, feature_color, normalize_hex

__all__ = [
    "Feature", "Part", "FeatureValidationError", "resolved_color",
    "NamingError", "validate_slug",
    "PALETTE", "feature_color", "normalize_hex",
]
```

- [ ] **Step 4: Run test to verify it passes**

Run: `python -m pytest tools/featurekit/tests/test_model.py -v`
Expected: PASS (all cases).

- [ ] **Step 5: Commit**

```bash
git add tools/featurekit/featurekit/model.py tools/featurekit/featurekit/__init__.py tools/featurekit/tests/test_model.py
git commit -m "feat(featurekit): Feature/Part model + naming-rigor gate"
```

---

### Task 5: Manifest sidecar (`.features.step.js`) emission

**Files:**
- Create: `tools/featurekit/featurekit/sidecar.py`
- Modify: `tools/featurekit/featurekit/__init__.py` (export `render_sidecar`, `write_sidecar`)
- Test: `tools/featurekit/tests/test_sidecar.py`

**Interfaces:**
- Consumes: `Part.manifest()` (Task 4).
- Produces:
  - `render_sidecar(part: Part, *, step_path: str) -> str` — returns the `.features.step.js` ES-module text. `step_path` is workspace-relative POSIX. Embeds `manifest.schemaVersion = 1`, `manifest.step.path`, `manifest.features`, and view defaults `{ colorMode: "diagnostic", ghostCutters: true }`.
  - `write_sidecar(part: Part, *, features_step_path: Path) -> Path` — writes `<stem>.step.js` next to the features STEP and returns its path; computes the embedded `step.path` as the features STEP path relative to repo root if possible, else its name.

- [ ] **Step 1: Write the failing test**

`tools/featurekit/tests/test_sidecar.py`:

```python
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
```

- [ ] **Step 2: Run test to verify it fails**

Run: `python -m pytest tools/featurekit/tests/test_sidecar.py -v`
Expected: FAIL — `ModuleNotFoundError: No module named 'featurekit.sidecar'`.

- [ ] **Step 3: Write minimal implementation**

`tools/featurekit/featurekit/sidecar.py`:

```python
"""Emit the .features.step.js manifest sidecar the viewer's legend panel reads."""
from __future__ import annotations

import json
from pathlib import Path

from featurekit.model import Part


def _payload(part: Part, *, step_path: str) -> dict:
    return {
        "manifest": {
            "schemaVersion": 1,
            "step": {"path": step_path},
            "features": part.manifest(),
        },
        "view": {"colorMode": "diagnostic", "ghostCutters": True},
    }


def render_sidecar(part: Part, *, step_path: str) -> str:
    data = _payload(part, step_path=step_path)
    blob = json.dumps(data, indent=2)
    # Embed a machine-readable JSON block (for tooling/tests) plus the live ES export.
    return (
        "// Generated by featurekit. Do not edit by hand.\n"
        "/*FEATUREKIT_JSON\n" + blob + "\nFEATUREKIT_JSON*/\n"
        "export default " + blob + ";\n"
    )


def _repo_relative_posix(path: Path) -> str:
    resolved = path.resolve()
    # Walk up looking for the repo root (a .git dir); fall back to the file name.
    for parent in [resolved, *resolved.parents]:
        if (parent / ".git").exists():
            try:
                return resolved.relative_to(parent).as_posix()
            except ValueError:
                break
    return resolved.name


def write_sidecar(part: Part, *, features_step_path: Path) -> Path:
    features_step_path = Path(features_step_path)
    step_rel = _repo_relative_posix(features_step_path)
    js = render_sidecar(part, step_path=step_rel)
    out = features_step_path.with_suffix(features_step_path.suffix + ".js")
    out.write_text(js, encoding="utf-8")
    return out
```

Add to `tools/featurekit/featurekit/__init__.py` imports and `__all__`:

```python
from featurekit.sidecar import render_sidecar, write_sidecar
```

(append `"render_sidecar", "write_sidecar"` to `__all__`.)

- [ ] **Step 4: Run test to verify it passes**

Run: `python -m pytest tools/featurekit/tests/test_sidecar.py -v`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add tools/featurekit/featurekit/sidecar.py tools/featurekit/featurekit/__init__.py tools/featurekit/tests/test_sidecar.py
git commit -m "feat(featurekit): manifest sidecar emission"
```

---

### Task 6: Geometry adapter — `solid()` and `feature_view()` (build123d)

**Files:**
- Create: `tools/featurekit/featurekit/geometry.py`
- Modify: `tools/featurekit/featurekit/__init__.py` (export `solid`, `feature_view`)
- Test: `tools/featurekit/tests/test_geometry.py`

**Interfaces:**
- Consumes: `Part`/`Feature`/`resolved_color` (Task 4); cadpy `label_shape` and build123d at runtime.
- Produces:
  - `solid(part: Part) -> Any` — validates, fuses all `add` builds, subtracts all `cut` builds, returns one build123d `Part`/`Solid`. Label = `part.name`.
  - `feature_view(part: Part) -> list[Any]` — validates; returns a list of build123d solids, one per feature, each labeled with `feature.id` and colored: adds at alpha 1.0, cuts at alpha 0.35 (the ghost). Suitable as the `children` return of a `gen_step()`.
  - `_b123d_color(hex_str: str, alpha: float)` helper.

Geometry tests are guarded with `pytest.importorskip("build123d")` so they skip when build123d is absent (as in the current local env).

- [ ] **Step 1: Write the failing test**

`tools/featurekit/tests/test_geometry.py`:

```python
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
    assert float(add_body.color.alpha) == pytest.approx(1.0, abs=1e-6)
    assert float(cut_body.color.alpha) == pytest.approx(0.35, abs=1e-6)
```

- [ ] **Step 2: Run test to verify it fails (or skips without build123d)**

Run: `python -m pytest tools/featurekit/tests/test_geometry.py -v`
Expected (no build123d installed locally): SKIPPED at collection (`importorskip`). After `pip install -r tools/featurekit/requirements.txt`: FAIL — `ModuleNotFoundError: No module named 'featurekit.geometry'`.

- [ ] **Step 3: Write minimal implementation**

`tools/featurekit/featurekit/geometry.py`:

```python
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
```

Add to `tools/featurekit/featurekit/__init__.py`:

```python
# Geometry adapter is imported lazily to avoid importing build123d at package import.
def __getattr__(name):  # noqa: D401
    if name in {"solid", "feature_view"}:
        from featurekit import geometry
        return getattr(geometry, name)
    raise AttributeError(name)
```

- [ ] **Step 4: Run the tests**

Run: `pip install -r tools/featurekit/requirements.txt`
Then: `python -m pytest tools/featurekit/tests/test_geometry.py -v`
Expected: PASS (both tests). If build123d cannot be installed in this environment, record that as a blocker and leave the tests skipping; do not fake the geometry.

- [ ] **Step 5: Commit**

```bash
git add tools/featurekit/featurekit/geometry.py tools/featurekit/featurekit/__init__.py tools/featurekit/tests/test_geometry.py
git commit -m "feat(featurekit): build123d geometry adapter (solid + feature_view)"
```

---

### Task 7: End-to-end fixture + `generate()` orchestration through the `scripts/step` pipeline

**Files:**
- Create: `tools/featurekit/featurekit/generate.py`
- Create: `tools/featurekit/examples/plate_with_hole.py` (the generic 2-feature fixture — NOT a Mac Mini part)
- Modify: `tools/featurekit/featurekit/__init__.py` (export `generate`)
- Test: `tools/featurekit/tests/test_generate.py`

**Interfaces:**
- Consumes: `solid`/`feature_view` (Task 6), `write_sidecar` (Task 5), `Part` (Task 4).
- Produces:
  - `generate(part: Part, *, stem: Path) -> dict[str, Path]` — writes three artifacts next to `stem`: `<stem>.step` (fused, via cadpy's `export_build123d_step_scene`), `<stem>.features.step` (assembly, via cadpy assembly export of the feature_view children), and `<stem>.features.step.js` (sidecar). Returns `{"part": ..., "features": ..., "sidecar": ...}`. Validates first (fails closed).
  - `examples/plate_with_hole.py` exposes `build_part() -> Part` and a `gen_step()`-style `main()` calling `generate`.

**Implementation note (grounding):** the fused STEP uses `cadpy.step_export.export_build123d_step_scene(shape, output_path, text_to_cad_entry_kind="part", source_path=..., source_hash=...)`. The features STEP wraps the `feature_view()` children in a `build123d.Compound(label=part.name, children=[...])` and exports it the same way with `text_to_cad_entry_kind="assembly"`. `source_hash` may be a fixed sentinel (e.g. `"featurekit"`) since featurekit owns generation rather than the `scripts/step` discovery path.

- [ ] **Step 1: Write the failing test**

`tools/featurekit/tests/test_generate.py`:

```python
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
```

`tools/featurekit/examples/plate_with_hole.py`:

```python
"""Generic 2-feature fixture (a plate with a bored hole). Not a Mac Mini part."""
from __future__ import annotations

from pathlib import Path


def build_part():
    from build123d import Box, Cylinder
    from featurekit.model import Feature, Part

    p = Part("plate")
    p.add(Feature(id="base_plate", name="Base plate", kind="add",
                  build=lambda: Box(20, 20, 4)))
    p.add(Feature(id="vent_hole", name="Vent hole", kind="cut",
                  build=lambda: Cylinder(3, 10)))
    return p


def main(stem: str = "models/plate") -> None:
    from featurekit.generate import generate
    generate(build_part(), stem=Path(stem))


if __name__ == "__main__":
    main()
```

- [ ] **Step 2: Run test to verify it fails (or skips without build123d)**

Run: `python -m pytest tools/featurekit/tests/test_generate.py -v`
Expected (no build123d): SKIPPED. With build123d: FAIL — `ModuleNotFoundError: No module named 'featurekit.generate'`.

- [ ] **Step 3: Write minimal implementation**

`tools/featurekit/featurekit/generate.py`:

```python
"""Orchestrate the two reductions + sidecar into three on-disk artifacts."""
from __future__ import annotations

from pathlib import Path

from featurekit.geometry import feature_view, solid
from featurekit.model import Part
from featurekit.sidecar import write_sidecar


def _export_step(shape, output_path: Path, *, entry_kind: str) -> Path:
    from cadpy.step_export import export_build123d_step_scene

    output_path.parent.mkdir(parents=True, exist_ok=True)
    export_build123d_step_scene(
        shape,
        output_path,
        text_to_cad_entry_kind=entry_kind,
        source_path=Path(__file__).name,
        source_hash="featurekit",
    )
    return output_path


def generate(part: Part, *, stem: Path) -> dict[str, Path]:
    part.validate()  # fail closed before any write
    stem = Path(stem)

    from build123d import Compound

    part_solid = solid(part)
    view_children = feature_view(part)
    view_compound = Compound(label=part.name, children=view_children)

    part_step = _export_step(part_solid, stem.with_suffix(".step"), entry_kind="part")
    features_step = _export_step(
        view_compound, stem.with_name(stem.name + ".features.step"), entry_kind="assembly"
    )
    sidecar = write_sidecar(part, features_step_path=features_step)
    return {"part": part_step, "features": features_step, "sidecar": sidecar}
```

Add `generate` to the lazy `__getattr__` set in `__init__.py` (alongside `solid`, `feature_view`).

- [ ] **Step 4: Run the tests**

Run: `python -m pytest tools/featurekit/tests/test_generate.py -v`
Expected: PASS with build123d installed (`test_generate_fails_closed_on_bad_names` passes even without geometry because validation raises before the build123d import path is exercised — keep it outside the `importorskip` only if validation runs first; since the module-level `importorskip` skips the whole file without build123d, the fail-closed guarantee is also covered by `test_model.py`). 

- [ ] **Step 5: Verify the artifacts load in the existing pipeline (manual integration check)**

Run:
```bash
PYTHONPATH="$(pwd)/.agents/skills/cad/scripts/packages/cadpy/src:$(pwd)/tools/featurekit" \
  python tools/featurekit/examples/plate_with_hole.py
```
Expected: writes `models/plate.step`, `models/plate.features.step`, `models/plate.features.step.js`. Then hand `models/plate.features.step` to the running CAD Viewer (`http://127.0.0.1:<port>/?dir=<abs>&file=plate.features.step`) and confirm two distinctly colored bodies with labels `base_plate` and `vent_hole`. This artifact is the sample Plan B (the viewer panel) will design against.

- [ ] **Step 6: Commit**

```bash
git add tools/featurekit/featurekit/generate.py tools/featurekit/featurekit/__init__.py tools/featurekit/examples/plate_with_hole.py tools/featurekit/tests/test_generate.py
git commit -m "feat(featurekit): generate() + 2-feature fixture end-to-end"
```

---

### Task 8: Full suite green + docs note

**Files:**
- Modify: `tools/featurekit/README.md` (usage example)
- Test: full suite

**Interfaces:**
- Consumes: everything above.
- Produces: a passing `pytest` run and a documented usage path.

- [ ] **Step 1: Run the whole suite**

Run: `python -m pytest tools/featurekit/tests -v`
Expected: pure-core tests PASS; geometry/generate tests PASS if build123d installed, else SKIPPED with a clear reason. No failures.

- [ ] **Step 2: Add a usage example to the README**

Append to `tools/featurekit/README.md`:

```markdown
## Usage

```python
from pathlib import Path
from build123d import Box, Cylinder
from featurekit import Feature, Part, generate

p = Part("plate")
p.add(Feature(id="base_plate", name="Base plate", kind="add", build=lambda: Box(20, 20, 4)))
p.add(Feature(id="vent_hole", name="Vent hole", kind="cut", build=lambda: Cylinder(3, 10)))

generate(p, stem=Path("models/plate"))
# -> models/plate.step (fused, printable)
#    models/plate.features.step (colored feature-view assembly)
#    models/plate.features.step.js (legend manifest sidecar)
```
```

- [ ] **Step 3: Commit**

```bash
git add tools/featurekit/README.md
git commit -m "docs(featurekit): usage example + suite green"
```

---

## Self-Review

**Spec coverage (Modules 0–2 spec):**
- §3.1 Feature Manifest contract → Tasks 2 (slug), 4 (manifest fields/label==id), 5 (sidecar schema). ✅
- §3.2 featurekit dual output → Tasks 6 (solid/feature_view), 7 (generate). ✅
- §3.2 deterministic id→color → Task 3. ✅
- §3.2 naming-rigor gate (fails closed: missing id/name, bad slug, duplicate id, bad kind, non-add-only) → Tasks 2, 4, 7. ✅ (Non-solid-cutter check is deferred — see note below.)
- §5 naming-rigor enforcement (one identity in four places) → label==id (Task 6), manifest id (Task 4/5). ✅
- §3.3 Module 2 viewer panel → **OUT OF SCOPE for this plan** (separate Plan B; this plan emits the sample `plate.features.step` it consumes, Task 7 Step 5). ✅ (intentional split)
- §8 testing: 2-feature generic fixture → Task 7. ✅

**Gaps intentionally deferred (not blocking the engine):**
- *Non-solid cutter rejection* (spec §3.2/§7): requires build123d type checks; add as a follow-up test in `test_geometry.py` once build123d is installed locally (assert a `cut` whose `build()` returns a non-solid raises). Noted here so it is not silently dropped.
- *`features.lock.json` color-lock* (spec §5, optional): not implemented; deterministic `feature_color` already gives cross-run stability, so the lock file is YAGNI until multi-agent color pinning is needed.

**Placeholder scan:** no TBD/TODO; every code step has complete code. ✅

**Type consistency:** `Part.manifest()` returns `list[dict]` with keys `id/name/kind/colorHex` consistently across Tasks 4, 5, 7; `feature_view()` returns labeled solids consumed by `generate()`'s `Compound(children=...)`; `generate()` returns the `{"part","features","sidecar"}` dict asserted in Task 7. ✅

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-06-19-featurekit-engine.md`.
