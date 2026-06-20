# Feature-First CAD with a Live Legend Viewport — Design Spec

**Date:** 2026-06-19
**Status:** Draft for review
**Scope:** Modules 0–2 (manifest contract, `featurekit` generator + naming-rigor
enforcement, viewer Feature Legend panel + live-refresh).
**Explicitly out of scope:** any Mac Mini–specific port or part-specific content.
This spec delivers the reusable engine + viewer only.

Companion methodology:
[`docs/methodology/part-separation-vs-merged-whole.md`](../../methodology/part-separation-vs-merged-whole.md).

## 1. Problem

Today CAD parts are authored as a **merged whole**: every addition and removal is
fused into one anonymous solid (OpenSCAD `union`/`difference`, or the `cad`
skill's "one valid solid" STEP). After generation, individual features
(backplate, standoff, frame, port cuts…) are not addressable — they cannot be
colored, named, isolated, reviewed independently, or owned by separate agents.

We want an iterative **text-to-CAD** workflow where each feature is **distinct
geometry**: named, deterministically colored, individually isolatable, with
removals shown as translucent ghost cutters — all in a **continually-open
viewport** with a docked legend (color → name key) that **refreshes in place** as
the user iterates by text, while the real exported part stays a single printable
solid.

## 2. Decisions (locked)

| Decision | Choice |
|---|---|
| Authoring toolchain | build123d → STEP, on top of the installed `cad`/`cadpy` engine |
| Feature ↔ part relationship | **Viz layer over one fused part** (fused solid is the print source of truth) |
| Subtractive features | **Translucent ghost cutters** — each removal is its own colored, labeled solid in the feature view |
| Viewport interactivity | **Custom Feature Legend panel** (Approach B), built in upstream viewer source |
| Legend location | **Docked under the render**, following the existing file-sheet visual language |
| Ghost styling | **Feature-identity color is primary** (each feature its own stable hue); cuts rendered translucent/x-ray and tagged `cut` in the legend. Revisitable. |
| Viewer source | Build against upstream **`earthtojake/text-to-cad`** (`main`, top-level `viewer/`); rebuild `dist` and sync into the local skill runtime |
| Naming | **Enforced at generation time** (a gate, not a guideline) |

## 3. Architecture

Three modules joined by one contract (the Feature Manifest). Each module is
independently understandable and testable.

```
 author (Python)                generate                         view (browser)
┌────────────────┐   featurekit   ┌──────────────────────┐  cad-viewer  ┌──────────────────────┐
│ Feature list   │ ─────────────▶ │ part.step (fused)    │ ───────────▶ │ 3D canvas            │
│ id/name/kind/  │  (Module 1)    │ part.features.step   │  (Module 2)  │ ─ Feature Legend ──  │
│ color/build()  │                │ part.features.step.js│              │ swatch·name·add/cut  │
└────────────────┘                │  (manifest = Mod 0)  │              │ eye·solo·ghost·reset │
        ▲                         └──────────────────────┘              └──────────────────────┘
        │ naming-rigor gate (fails generation on violation)                     ▲
        └───────────────────────────────────────────────────────────────────────┘
                          live-refresh: regenerate → reload in place, keep camera + panel state
```

### 3.1 Module 0 — Feature Manifest (the shared contract)

The spine every other module reads/writes. A feature is:

| Field | Type | Rules |
|---|---|---|
| `id` | string | lowercase slug (`^[a-z0-9]+(?:[-_][a-z0-9]+)*$`), unique within a part. **STEP part label == this id.** |
| `name` | string | non-empty display name |
| `kind` | enum | `add` \| `cut` |
| `colorHex` | string | `#RRGGBB`, deterministic function of `id` unless explicitly pinned |

Serialized into the `.features.step.js` sidecar as `manifest.features: Feature[]`,
alongside the existing step-module manifest fields (`schemaVersion`,
`step.path`). The sidecar also sets diagnostic-color and ghost-on view defaults.
The manifest is the single source the panel renders from; the STEP labels are the
binding between manifest rows and 3D bodies.

### 3.2 Module 1 — `featurekit` (Python, on cadpy/build123d)

A small library + authoring convention. Lives with the `cad` skill's `cadpy`
package (new module `cadpy.featurekit`) so it reuses `AssemblyHelper`, labels,
colors, and STEP/GLB export.

**Authoring API (shape, not final signatures):**

```python
from cadpy.featurekit import Feature, Part

part = Part(name="widget")
part.add(Feature(id="base_plate", name="Base plate", kind="add",
                 build=lambda ctx: ...))            # returns a build123d solid
part.add(Feature(id="vent_holes", name="Vent holes", kind="cut",
                 build=lambda ctx: ...))            # cutter solid (positive volume)
part.generate("models/widget")                       # writes the three artifacts
```

**Two reductions from the one feature list:**

1. `solid()` → fuse all `add` solids, subtract all `cut` solids → one printable
   solid → `widget.step` (and optional STL/3MF via existing `cad` exports).
2. `feature_view()` → `AssemblyHelper` compound: each `add` = opaque colored
   labeled solid; each `cut` = its cutter solid, labeled, colored, with alpha
   (the ghost) → `widget.features.step` + GLB sidecar + `widget.features.step.js`.

**Deterministic color:** `colorHex = palette[stable_hash(id) % len(palette)]`,
from a curated, visually-distinct palette. Explicit `color=` pins override. Same
id ⇒ same color across regenerations and across agents.

**Naming-rigor gate (cross-cutting, enforced here):** before any geometry is
built, `featurekit` validates the feature list and **raises on violation**:
- missing/empty `id` or `name`;
- `id` not matching the slug regex;
- duplicate `id` within the part;
- `kind` not in `{add, cut}`;
- a `cut` builder that returns a non-solid / open surface;
- color drift (a pinned color that disagrees with a previously-recorded binding,
  if a lock file is present).
Errors name the offending feature and the rule. This gate is what makes parallel
authoring safe (see methodology §"Naming rigor").

**Outputs (deterministic, explicit targets):** `<stem>.step`,
`<stem>.features.step`, `<stem>.features.step.js`, plus GLB/topology sidecars the
viewer already consumes. No directory-wide generation.

### 3.3 Module 2 — Viewer: Feature Legend panel + live-refresh

Built in the upstream `viewer/` React+Three source, designed with the
`frontend-design` skill, matching the existing file-sheet visual language.

**Panel (docked under the canvas):** one row per `manifest.features` entry:
- color swatch (the feature's `colorHex`),
- `name`,
- `add`/`cut` chip,
- **eye** (hide/show this body),
- **solo** (isolate: hide all others).
Plus global controls: **Ghost cutters** master toggle (show/hide all `cut`
bodies), **Reset** (restore all visible + default camera), and a collapse handle.
Hover/selection highlights the corresponding body; rows map to assembly parts by
`id` (== STEP label).

**Live-refresh (state-preserving):** when `part.features.step` changes on disk
(the agent regenerated it), the viewer reloads geometry **in place** and
preserves: camera pose, per-feature visibility/solo state, and ghost toggle —
all keyed by feature `id` so a removed/added feature degrades gracefully.
Mechanism: a lightweight change signal from the backend (content-hash poll or
SSE on the active file) that triggers a geometry reload without a full page
reset. New ids appear with defaults; vanished ids drop from the panel.

**Build & sync:** clone `earthtojake/text-to-cad`, follow root `AGENTS.md` to run
the viewer dev server, implement the panel + refresh, rebuild `dist`, and sync
the produced bundle into the local skill runtime
(`.agents/skills/cad-viewer/scripts/viewer/dist` + `backend/server.mjs`). Record
the upstream commit the bundle was built from.

## 4. End-to-end data flow

1. Author declares features (Python) → `part.generate(stem)`.
2. `featurekit` runs the naming-rigor gate, then emits `part.step` (fused),
   `part.features.step` (assembly), and `part.features.step.js` (manifest).
3. The workflow hands `part.features.step` to `cad-viewer`, which starts/reuses
   the server and opens the bottom-docked legend.
4. User iterates by text → regenerate → viewer hot-reloads in place, preserving
   camera + panel state.
5. For manufacturing, `part.step` (the fused solid) is the export source; STL/3MF
   derive from it.

## 5. Naming-rigor enforcement (cross-cutting requirement)

The single most important invariant. One identity in four places:
`source builder name → STEP label → manifest id → legend row id`. Enforced by the
Module 1 gate (§3.2). Optional `features.lock.json` records id→color bindings so
color stability is verifiable across sessions and agents. Generation **fails
closed**: a naming violation produces no artifacts, never a quietly-wrong blob.

## 6. Parallel-agent workflow (why this exists)

The separation + naming gate makes a fleet workflow safe: agents claim feature
`id`s, each builds its feature(s) against the shared datum/coordinate contract and
returns solids, and the reducer composes deterministically into the fused part +
feature view. Per-feature snapshot/measure/diff enables independent review;
stable ids/colors keep the legend and reviewer mental-model intact across
recombination. This spec delivers the engine that this workflow runs on; the
fleet orchestration itself is a downstream use, not part of Modules 0–2.

## 7. Error handling

- **Naming violations:** fail generation with a feature-named, rule-named error.
- **Non-solid cutter:** rejected by the gate before composition.
- **Empty feature list / no `add` features:** error (nothing printable).
- **Viewer can't read manifest:** panel falls back to the stock assembly tree and
  reports the missing/!invalid sidecar; geometry still renders.
- **Live-refresh signal lost:** viewer keeps last geometry and surfaces a "stale"
  indicator rather than silently diverging from disk.

## 8. Testing & validation

- **Module 0:** schema validation tests (valid/invalid manifests; slug regex;
  duplicate ids; bad kind).
- **Module 1:** generate a **trivial 2-feature test part** (one `add`, one `cut`)
  and assert: fused `part.step` is one solid; `part.features.step` has exactly two
  labeled bodies with ids == labels; cutter carries alpha; colors deterministic
  across two runs; naming gate raises on each violation class. Validate geometry
  with `scripts/inspect refs --facts` and a `scripts/snapshot` packet.
- **Module 2:** load the test part's feature view; assert the panel renders two
  rows with correct swatch/name/add-cut; eye/solo/ghost/reset behave; regenerate
  the part and confirm camera + panel state persist and the changed body updates
  in place. Visual review via the running viewer.

The 2-feature test part is a generic fixture (e.g. a plate with a hole), **not**
a Mac Mini artifact.

## 9. Build phasing

0. **Lock the Feature Manifest contract** (schema + slug rules + sidecar shape).
1. **`featurekit` generator + naming-rigor gate**, validated on the trivial
   2-feature fixture (deterministic colors, dual output, sidecar).
2. **Viewer Feature Legend panel + live-refresh** in upstream source; rebuild and
   sync the bundle.

Each phase is independently verifiable; Module 2 depends only on the Module 0
contract and a sample feature-view artifact from Module 1.

## 10. Assumptions & open items

- `cadpy`'s color/alpha export reaches the viewer's GLB sidecar with per-part
  fidelity (grounded: `AssemblyHelper.add_part(..., color=...)` exists and the
  export path references color/alpha; confirm alpha round-trips during Phase 1).
- Upstream `viewer/` builds cleanly per root `AGENTS.md` on this Windows
  environment; if not, capture the blocker before committing to the bundle sync.
- Live-refresh transport (hash-poll vs SSE) chosen in Phase 2 based on what the
  backend already exposes; both preserve the same state-keyed-by-id behavior.
- Ghost styling default (identity-hue + translucent + `cut` tag) may be tuned
  after first visual review.
