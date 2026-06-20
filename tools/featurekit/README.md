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
