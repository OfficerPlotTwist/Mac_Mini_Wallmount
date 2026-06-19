# Mac Mini Wall Mount — Versions & the Prompts That Created Them

Every saved model in `versions/` paired with the user prompt(s) that drove it (quoted verbatim).
`vNN` = parametric OpenSCAD (`.scad` + `.stl`); `vNNb` = the same design produced via Blender's boolean (`.stl`).

---

## Setup
> **"extract mac mini model off pruda usb to here"**

Pulled `Macmini.glb` off the PRUSA USB into the project (used thereafter as the dimensional reference / port-trace source).

---

## v01 — `v01_straight-rails_ports-down`
> **"I want to model a wall mount that leaves ports , powerbutton, and cooling ducts on the back exposed"**

Brainstorm answers that shaped it:
> **"flat against wall"**
> *(retention)* **"bottom face with button towards wall, back spacer on the center give room for power button to be accessed"**
> *(wall mount)* **"Screw-through holes"**
> *(ports edge)* **"there are ports on top and bottom but side with more ports down"**
> *(gap)* **"Widen the gap"** · *(toolchain)* **"Install + render STL"**
> **"do it"** · **"go"**

→ First design: straight L/R capture rails, **square corners**, back ports out a rectangular opening on the **down** edge, snap hooks + bottom corner ledges, screw ears, 28 mm standoff.

---

## v02 — `v02_corner-hug_narrow-open`
> **"hug the profile of the rounded corners"**

→ Rounded-rect frame conforming to the Mini's 25 mm corners (corner pockets retain it). Opening tied to corner radius (~77 mm — too narrow).

---

## v03 — `v03_corner-hug_wide-open_screw-ears`
> **"the slots do not line up with the ports"**

→ Port opening **decoupled** from the corner radius (`port_post`, ~114 mm) so all rear ports clear.

---

## blender_port-traced — `blender_port-traced.stl`
> **"in mcp of your choice of rhino or blender, I want you to trace an offset of the ports on the mac mini model, extrude those, and make the cut that way."**
> *(which MCP)* **"https://github.com/ahujasid/blender-mcp.git do it"**

Loop-select dialogue while tracing:
> **"identify currently selected edge loops for the first side. verify no loops dipped below the surface edge"**
> **"deselect edges off the primary plane for me"**
> **"ethernet doesn't look broken unless on edge segment is missing where I don't see"**
> **"do that"** *(auto-close the loops)* · **"reace and extruce backside"** *(trace + extrude back)*

→ Real GLB ports traced (bisect → convex hull → 1 mm offset → extrude) and cut as port-shaped holes into closed panels on the top/bottom edges.

---

## v04 — `v04_short-spacer_no-vents_min-footprint`
> **"close airflow holes. reduce back spacer to 3/16 inch"** → **"no, 1/2 inch"** → **"no, 3/4 inch"**
> **"minimize wall plate footprint. remove screw tabes and move screwholes to within that footprint"**
> **"save all versions of design as it evolved"**

→ Spacer → ¾″ (19.05 mm); vents removed; ears removed → footprint minimized, 4 screws moved inside it. (And this `versions/` archive was created.)

---

## v05 — `v05_side-ports_led`
> **"rotate mini 90 degrees so port cutouts will be in the existing sides with clips. also flip around so apple logo faces away from the wall"**
> **"cut the ports into the side rails then make those other changes"**
> **"add a hole for the power light"**
> **"cutout for power light missing. very small circle with no inlay on the side with 3 cuts"**
> **"no, bring back the mac mini model and I'll loop select"** · **"selected"**

→ Logo faces the room; all 9 ports cut into the **side rails** (6 back / 3 front) + the **LED** hole loop-selected off the model (front, between USB-C and headphone).

---

## v05b — `v05b_blender-boolean-cut`
> **"blender has boolean capabilities do it after adding power light cutout"**
> **"we're slicing blender. update blender model"**

→ Same v05 design produced through Blender's boolean (`modifier_apply` in a `temp_override`). From here on, every version also gets a Blender cut (`vNNb`).

---

## v06 — `v06_rest-ridges_inner-screws_hollow-standoff` (+ `v06b`)
> **"add ridge rest on the side pieces. move screws in a half inch towards the center. hollow out the round spacer"**

→ Rest ridges on the side rails; screws moved ½″ inward (53→40.3); standoff hollowed to a 4 mm ring.

---

## v07 — `v07_bored-standoff_lightened-plate` (+ `v07b`)
> **"is clip overhang printable if printed in place?"** *(question — discussed, no change)*
> **"looks fine. the hollow support should cut all the way through the base plate."**
> **"use less material on the base"**

→ Standoff bore taken **clean through** the wall plate; plate **lightened** with 4 windows.

---

## v08 — `v08_print-in-place_chamfer-catch_round-ports` (+ `v08b`)
> **"camfer catch ledges, widen and round port holes so bracket is print in place with the back on the print bed"**

→ Port holes widened + rounded to **obround**; (catch chamfer applied to the snap hooks — corrected in v09). Blender cut switched to using the exact OpenSCAD obround cutter solids.

---

## v09 — `v09_chamfered-rest-ridges` (+ `v09b`)  ← current
> **"not thos ledges. camfer the lower catch edges"**

→ Snap hooks **reverted**; the **lower rest ridges** get the 45° chamfered underside (self-supporting, back-on-bed print).

---

### Also asked along the way (no new version)
> **"where is the addon locally?"** · **"show me the mac mini with port cutouts"**
