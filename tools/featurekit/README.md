# featurekit

Feature-first CAD engine. Declare a part as an ordered list of named features
(each `add` or `cut`, each with a stable id and deterministic color); generate
a fused printable STEP plus a colored, labeled feature-view assembly + manifest
sidecar for the CAD Viewer's Feature Legend panel.

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

## Dev setup

```bash
pip install -r tools/featurekit/requirements.txt   # build123d for geometry
python -m pytest tools/featurekit/tests -v
```

Geometry tests are skipped automatically when build123d is not installed.
