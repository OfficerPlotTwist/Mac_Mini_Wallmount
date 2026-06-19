# Mac Mini Wall Mount — Design Evolution

All dimensions in mm. Working source: `../macmini_wall_mount.scad` (always = latest).
Reference model: `../Macmini.glb` (M4 chassis, 127 × 127 × 50 mm).

| Ver | File | Key change |
|-----|------|-----------|
| v16 | `v16_teardrop-ports_thick-webs_pb-cleanup.scad` | **Current. Printability fixes.** (1) **Droopy port overhangs** — every port (obround + round) now gets a **45° teardrop gable** on top (`teardrop`, `port_profile2d`) so the printed-up ceiling never bridges horizontally; the converging gables also tie each thin inter-port web into the wall above. (2) **Snapped USB-C/Thunderbolt webs** — `web_min` 1.35 → **2.0 mm** (the crowded back-rail webs were exactly 1.35 mm = 3 perimeters and broke; now ~2.0 mm, ports ~0.6 mm narrower). (3) **Power-button boolean junk** — replaced the single-corner `pb_skip_a` drop with an angular keep-out `near_pb()` (`pb_dir`, `pb_keep=22`) that drops **every** strut/shelf reaching into the finger channel (the −X-rail strut the finger cylinder used to slice into stub geometry + the −X−Y corner fan), leaving the channel clean. Mesh verified single-solid (CGAL `Volumes: 2`). |
| v15 | `v15_airflow-vents_finger-corner-cleanup.scad` | **Airflow vents** (`airflow`, `air_*`): 8 holes bored through the backplate in the gaps between the radial struts (skipping the finger-hole corner). **Junk cleanup**: the finger cylinder ran along the −X,−Y corner and shredded that corner's fan into stub fragments → that one corner's fan + shelves are now dropped (`pb_skip_a`, auto-derived from the button angle = 180°). Also: project rescaled to **mm** in Blender and the GLB Mini reference reseated cleanly. |
| v14 | `v14_pbutton-side-finger-hole.scad` | The v13 backplate through-hole was useless mounted flush to a wall → replaced with a **finger hole through the curved corner SIDE wall** (`pb_finger=22`, `pb_z=20`): a horizontal channel aimed radially at the button (z-band ~9–31, reaching the press-face at z≈29), clearing the corner wall + struts in the path. Backplate stays solid; inner end clears the central pad by ~10 mm. |
| v13 | `v13_pbutton-through-hole.scad` | Power button faces the wall and was unreachable in the mount → `pb_cut` changed from a blind pocket to a **Ø20 through-hole** (`pb_r`) from the back face up to the button, clearing the backplate + struts/shelves in that column (pad & corner wall untouched). Assembly fit-check (Mini seated in harness from `Macmini.glb`) confirmed **no clipping**; contact gaps ~0.8–2 mm suggest `ridge_lift`≈4.5 — verify on a real unit. |
| v12 | `v12_corner-clip-fix_pbutton-pocket.scad` | **Fixed corner clipping** — struts+shelves now intersected with the outer footprint so their straight segments can't poke past the rounded corners. **Power button located** from the GLB ‘power button’ mesh (Mini seated in the harness): button at harness (−47.9, −47.9). Clearance changed to a **round access pocket** (`pb_x/pb_y/pb_r`) at that spot, ribs left 3 mm above the backplate base (`pb_rib_h`). |
| v11 | `v11_strut-shelves_pbutton-clearance.scad` | Continuous rest-ledge → **discrete chamfered shelves**, one per join strut (both rails + the swept corner walls) so each is cleanly supported by a rib beneath. **Power-button clearance**: the join ribs in a zone next to the back rail are shortened to **3 mm** (`pb_*` params — verify `pb_side`/`pb_y` on a real Mini). |
| v10 | `v10_organic-struts_wide-bore.scad` | Big jump from v09 (intervening work consolidated): side ports widened for rubber boots (width web-clamped to 3 perims), **Ø88 mm central pad**, 4 screws → **open top/bottom segments**, rest-ridges **lifted** (`ridge_lift`), top/bottom walls **swept past corners** (`corner_sweep`), central **bore widened to 72 mm**, and **full-height organic "topology-optimized" struts** (fans to the side rails + corners) replacing the solid pad and the thick diagonal ribs. Material now **PETG**. |
| v01 | `v01_straight-rails_ports-down.scad` | First design. Straight L/R capture rails, **square corners**, back ports exit a rectangular opening on the **down** edge. Snap hooks + bottom corner ledges. Screw ears. |
| v02 | `v02_corner-hug_narrow-open.scad` | **Corner-hugging**: rounded-rect frame conforming to the Mini's 25 mm corners; four corner pockets retain it. Port opening tied to `corner_r` (~77 mm, **too narrow** — clipped outer ports). |
| v03 | `v03_corner-hug_wide-open_screw-ears.scad` | Port opening **decoupled** from corner radius via `port_post` (~114 mm, clears all ports). Screw ears still present. |
| v04 | `v04_short-spacer_no-vents_min-footprint.scad` | Back spacer (standoff) → **¾″ (19.05 mm)**; side **airflow vents removed**; **screw ears removed** → footprint minimized to the frame (≈134 mm sq), 4 screws relocated **inside** the footprint. |
| v09 | `v09_chamfered-rest-ridges.scad` | Corrected which catch got chamfered: snap **hooks reverted** to original; the **lower rest ridges** now have a **45° chamfered underside** (self-supporting). Obround ports + bored/lightened plate carried over. |
| v08 | `v08_print-in-place_chamfer-catch_round-ports.scad` | **Print‑in‑place (back on bed):** catch ledges **45° chamfered** (self‑supporting hooks), port holes **widened + rounded to obround** (`port_grow`). Standoff **bored through** the plate; plate **lightened** (4 windows). Blender cut now uses the *exact* OpenSCAD obround cutters (via `show_cutters` output mode). |
| v07 | `v07_bored-standoff_lightened-plate.scad` | Standoff bored clean through the backplate; wall plate lightened with 4 windows. |
| v06 | `v06_rest-ridges_inner-screws_hollow-standoff.scad` | Added **rest ridges** on the side rails (Mini base sits on them); **screws moved ½″ toward centre** (`screw_xy` 53→40.3); **standoff hollowed** (4 mm ring wall). LED at the loop-selected spot (`led_y=24.4, led_z=45.7`). |
| v05 | `v05_side-ports_led.scad` | All **9 ports cut into the side rails** (parametric, in OpenSCAD): 6 back (3×TB, HDMI, Ethernet, power) on the −X rail, 3 front (2×USB-C + headphone) on the +X rail, **+ power-LED hole** (front-left, `led_y/led_z/led_d` — estimated, not in the GLB). Port band `port_z = zmb + 22`. |

## Parameter diffs (v03 → v04)
- `gap`: 28 → **19.05** (¾ inch)
- `vent`: true → **false**
- screw mounting: outboard ears (`ex = ow/2 + ear/2`) → **inboard** (`screw_xy = 53`, within footprint)
- `backplate()`: rounded body **+ ears** → rounded body only

## Blender-MCP branch (port-traced cutouts)
Parallel exploration using the real GLB ports (not yet merged into the parametric `.scad`):
- `blender_port-traced.stl` — ports **traced** from the GLB (bisect each opening → convex hull → 1 mm offset → extrude), cut as port-shaped holes into **closed panels** on the top/bottom edges.
- Then re-oriented per request: **logo faces room**, Mini **rotated 90°** so ports land on the **side rails (with clips)**; back ports (3×TB, HDMI, Ethernet, power) on one side, front (2×USB-C + headphone) on the other.
- ✅ Blender boolean **does work** here — via `bpy.ops.object.modifier_apply` inside a `temp_override`. (The earlier failure was the *method*: `evaluated_get(depsgraph)` + `new_from_object` silently no-ops in this MCP context. `modifier_apply` mutates the mesh directly and works.)
- `v05b_blender-boolean-cut.stl` — the v05 base with all 9 ports + LED cut by **Blender's boolean** (rect cutters + round headphone/LED), cleaned to watertight. Equivalent to the OpenSCAD `v05` part.

## Traced port footprints (for OpenSCAD side-rail cutouts)
Ports arranged along Y on the ±X side faces, +1 mm clearance. Z is relative to the Mini's wall-side (intake) face; re-derive absolute Z from `gap`.
- **Back (−X):** TB1/2/3 each 4.7 (Y) × 10.5 (Z); HDMI 17.1 × 7.0; Ethernet 14.6 × 12.6; Power 19.1 × 10.7.
- **Front (+X):** USB-C ×2 each 4.7 × 10.5; Headphone ⌀6.2.
- Port band sat ~22 mm above the intake face (centre), spanning ~11 mm tall.

## Caveat
The GLB is a **stylized** visualization model (TB ports drawn as vertical slits, 25 mm corners look large). Verify port sizes/positions against a real Mac Mini before printing.
