# Mac Mini (M4 / M4 Pro) Wall Mount — Design Spec

**Date:** 2026-06-17
**Author:** Claude + supercoolraydude@gmail.com
**Target hardware:** Apple Mac Mini 2024 (M4 / M4 Pro) — shared 127 × 127 × 50 mm chassis
**Output:** One parametric OpenSCAD file → STL → PrusaSlicer (MK4) → printed in ASA

---

## 1. Goal

A single-piece, wall-mounted cradle that holds the Mac Mini **flat against the wall** while leaving the **rear ports + exhaust, the front ports, the bottom air intake, and the power button all usable**. Screw-mounts to the wall. No screw/VESA holes exist on the Mini, so retention is purely mechanical (edge capture).

## 2. Verified hardware facts

| Fact | Value | Source |
|------|-------|--------|
| Footprint | 127 × 127 mm (5 × 5 in) | Apple spec; GLB aspect ratio confirms 2.54:1 |
| Height | 50 mm (2 in) | Apple spec |
| Weight | ~0.67–0.73 kg | Apple spec |
| Back ports | power, Ethernet, HDMI, 3× Thunderbolt 4 | MacRumors / OWC |
| Front ports | 2× USB-C, headphone jack | MacRumors / OWC |
| Power button | **underside, rear-left corner** | MacRumors |
| Air intake | ring on the **bottom** face (perimeter of central base puck) | Apple design |
| Exhaust | out the **back** face | Apple design |
| Corner radius | **25 mm** (≈77 mm flat per side) | measured from `Macmini.glb`, all 4 corners |

The supplied `Macmini.glb` is geometrically a true Mac Mini but at an arbitrary scale (~38 units/m); it is **reference-only**. All dimensions come from Apple's published figures and are parameterized.

## 3. Orientation (locked)

Mini mounted flat against the wall:

- **Top / Apple-logo face → faces the room** (clean appearance).
- **Bottom face (intake + power button) → toward the wall**, held off the backplate by a central standoff.
- **Back edge (6 ports + exhaust) → faces DOWN** — cables route straight down the wall; exhaust vents downward.
- **Front edge (USB-C + headphone) → faces UP** — front ports remain reachable.
- **Standoff gap ≈ 28 mm** between bottom face and backplate: feeds the intake ring and gives whole-finger access to the power button.

### Coordinate convention (as mounted, viewer in the room)
- **+X** = viewer's right, **+Y** = up, **+Z** = out of wall toward viewer.
- Wall plane = XY at Z = 0 (backplate face).
- Derived power-button location: bottom face, **down edge (−Y), viewer's-right (+X) corner**, on the wall side. (Original rear-left maps to mounted lower-right after the logo-to-room / back-edge-down rotation. **To be confirmed against the physical unit**; position is parametric.)

```
 FRONT (from the room)                 SIDE (cross-section, gravity ↓)
 ┌───────────────────────┐ ← UP: front   wall│        room→
 │ o   ┌───────────┐   o │  USB-C+phones     │┌──┐
 │     │  ▲ Apple   │     │  (open)        B  │↕ ││M │ ← top/logo→room
 │     │   logo     │     │  ←L/R rails    P  │28││I │
 │     │(top face) │     │   +return lip  L  │mm││N │
 │ o   └───────────┘   o │ ← DOWN: back   E  │↕ ││I │ ← bottom face→wall
 └──────[button≈lower-R]─┘  ports+exhaust    │ s└──┘
   o = wall screw holes      (open)           standoff in gap
```

## 4. Part breakdown (single printed piece)

1. **Backplate** — flat plate against the wall. 4 countersunk screw holes (corners) for #8 wood screws / drywall anchors. Lightened/vented where it doesn't weaken the screw bosses. Thickness ~4–5 mm.
2. **Central standoff boss** — raised pad (height = gap ≈ 28 mm) contacting **only the Mini's central base puck**, never the intake ring. Sets the airflow/finger gap.
3. **Rounded capture frame** — full-height side walls conforming to the Mini's rounded corners (corner hug + in-plane retention incl. ~0.7 kg weight). The **top & bottom port edges are opened nearly corner-to-corner (~114 mm)** — independent of `corner_r` — because the back ports span almost the full width; only small corner nubs remain. The rounded-corner cut removes the arc material in front of the outer ports too.
4. **Side snap hooks** — on the flexible left & right straight rails, a **~2 mm flat catch** with a 45° self-supporting top, retaining the Mini in Z (pull-off). Rails **vented at gap level** for side airflow.
5. **Assembly** — press the Mini straight in toward the wall: corners drop into their pockets, side rails flex, hooks snap over the top-face edge.
6. **Power-button access** — lower-right, reached through the open bottom edge + 28 mm gap (wall-side gap kept clear there).
7. **Open zones (must stay clear):** full top/logo face; front ports (up edge); back ports + exhaust (down edge); intake gap behind; power button (lower-right).

## 5. Parameters (OpenSCAD variables, with defaults)

| Param | Default | Notes |
|-------|---------|-------|
| `mini_w` | 127 | Mini width (X) |
| `mini_h` | 127 | Mini height (Y) |
| `mini_t` | 50 | Mini thickness (Z, wall→room) |
| `corner_r` | 25 | Mini rounded-corner radius (measured from GLB) |
| `port_post` | 7 | structure kept at each end of the open port edges; **sets the port-opening width** (= `mini_w + 2*fit − 2*port_post` ≈ 114 mm) independent of `corner_r` |
| `fit` | 0.4 | per-side clearance |
| `gap` | 28 | standoff height (intake + button access) |
| `lip_flat` | 2.0 | side-hook flat catch depth |
| `wall_th` | 3.2 | capture-wall thickness |
| `back_th` | 4.5 | backplate thickness |
| `ear` | 16 | side screw-ear width |
| `screw_d` | 4.5 | clearance for #8 screw shank |
| `head_d` | 9 | countersink head dia |
| `vent` | true | side-rail venting on/off |

## 6. Thermal rationale

- **Intake:** bottom ring draws from the 28 mm gap, fed by the open up edge, open down edge, and vented side rails — unobstructed.
- **Exhaust:** out the down edge, directed away from the cradle; minimal recirculation since intake is fed primarily from the up/side edges.
- **Material:** **ASA** (heat-tolerant, already in the user's filament stock). **PLA is rejected** — softens near the warm exhaust.

## 7. Print settings (target)

- Printer: Prusa MK4 (IS), 0.4 mm nozzle, 0.2 mm layers (matches existing prints on the USB).
- Orientation: backplate flat on the bed (+Z = out of wall); lips printed as chamfered overhangs → **no supports**.
- Material: ASA. Perimeters ≥ 3, infill ≥ 20% for rigidity at the rails.

## 8. Acceptance criteria

1. Mini slides in and is retained against pull-off and against sliding down (weight held).
2. All rear ports + exhaust accessible/unobstructed (down edge).
3. Both front ports + headphone accessible (up edge).
4. Bottom intake ring unobstructed; ≥ 28 mm clear gap to backplate.
5. Power button reachable without removing the Mini.
6. Mounts to wall via 4 screws; sits flat.
7. STL renders cleanly from the `.scad` (manifold, no errors) and slices support-free in PrusaSlicer.
8. Top/logo face fully visible except thin perimeter lips.

## 9. Open items / to verify

- **Power-button exact corner** — confirm lower-right mapping against the physical Mini before printing; adjust `pb_x/pb_y`.
- **Intake ring inner/outer diameter** — confirm the standoff pad stays inside the central puck and never caps the ring; refine pad diameter on first test print.
- **Fit clearance** — 0.4 mm nominal; validate with a corner test print before committing to the full part.

## 10. Toolchain

- **OpenSCAD** (installed via winget this session) authors `macmini_wall_mount.scad`.
- Render: `openscad -o macmini_wall_mount.stl macmini_wall_mount.scad`.
- Slice/print: PrusaSlicer → MK4, ASA profile.

---

*Note: working directory is not a git repository, so this spec is written to disk but not committed. Run `git init` to version it if desired.*
