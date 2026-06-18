# Mac Mini M4 Wall Mount

A parametric, 3D-printable wall mount for the **Apple Mac Mini M4 / M4 Pro** (127 × 127 × 50 mm chassis), authored in **OpenSCAD**.

The Mini mounts flat against the wall with the **Apple logo facing the room**; the intake base + power button face the wall, held off by a ¾″ standoff gap. It's rotated 90° so the port faces meet the side rails — back ports (3× Thunderbolt, HDMI, Ethernet, power) on one rail, front (2× USB‑C, headphone) on the other.

## Design highlights

- **Corner‑hugging frame** — four rounded corner pockets cup the Mini's 25 mm corners; flexible side rails with snap hooks retain it in Z (press‑in assembly).
- **Side‑rail port cutouts** — obround holes sized per connector, widened for rubber strain‑relief boots, with inter‑port webs auto‑clamped to ≥ 3 perimeters.
- **Ø88 mm central contact pad** with a wide bore, reaching the Mini's solid central base past the recessed cooling vents.
- **Organic "topology‑optimized" bracing** — tapered Bézier struts fan from the pad to the side rails and corners (thick at the anchors, thin mid‑span).
- **Discrete support shelves** — small chamfered ledges, each sitting on a strut, at the recessed‑perimeter height.
- **Power‑button access pocket** — ribs beneath the wall‑facing power button shortened so a finger/tool can reach it.
- Four wall screws in the open top/bottom segments (clear driver access), countersunk for #8 wood screws / drywall anchors.

Target: **Prusa MK4**, 0.4 mm nozzle / 0.2 mm layer, **PETG**. A structural check (≈ 0.85 kg Mini, SF 10) leaves the load‑bearing wall at ~1.6 % of yield — the printed structure is far stronger than needed; wall anchors are the real limit.

## Files

| Path | What |
|------|------|
| `macmini_wall_mount.scad` | Parametric source (always the latest design) |
| `macmini_wall_mount.stl`  | Latest rendered mesh |
| `Macmini.glb`             | Reference Mac Mini model (stylized — verify dims against a real unit) |
| `versions/`               | Snapshots (`vNN_*.scad` + `.stl`), `thumbs/`, and `VERSIONS.md` change log |

## Build

```sh
openscad -o macmini_wall_mount.stl macmini_wall_mount.scad
```

Key parameters live at the top of the `.scad` (fit, standoff gap, wall thickness, port lists, strut/shelf controls, power‑button location). See `versions/VERSIONS.md` for the design evolution.

> **Before printing:** port positions and the power‑button location come from a *stylized* reference GLB — verify against your actual Mac Mini, and set `ridge_lift` to the measured perimeter recess depth.
