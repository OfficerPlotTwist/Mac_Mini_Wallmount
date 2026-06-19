// ============================================================
//  Mac Mini (M4 / M4 Pro) Wall Mount  —  parametric, corner-hugging
//  Spec: docs/superpowers/specs/2026-06-17-macmini-wall-mount-design.md
//
//  Orientation (mounted on wall, +Z = out of wall toward room):
//    - Apple-logo (top) face   -> room (+Z)
//    - Bottom face (intake+power button) -> wall, held off by standoff
//    - Back edge (6 ports + exhaust) -> DOWN (-Y), open
//    - Front edge (USB-C + headphone) -> UP (+Y), open
//
//  Retention: four corner pockets conform to the Mini's 25 mm rounded
//  corners and cup them -> they hold the Mini in-plane (incl. its weight)
//  with no separate ledges. Flexible left/right side rails carry snap
//  hooks that retain it in Z. Central standoff sets the air/finger gap.
//  Top & bottom straight edges are left open for the ports + exhaust.
//  Print backplate-down (no supports); material: ASA.
// ============================================================

/* ---------- Mac Mini dimensions (Apple M4/M4 Pro chassis) ---------- */
mini_w   = 127;   // width  (X)
mini_h   = 127;   // height (Y)
mini_t   = 50;    // thickness (Z, wall -> room)
corner_r = 25;    // rounded-corner radius (measured from Macmini.glb; tunable)

/* ---------- Fit / structure ---------- */
fit      = 0.4;   // per-side clearance around the Mini
gap      = 28;    // standoff height: intake airflow + power-button access
back_th  = 4.5;   // backplate thickness
wall_th  = 3.2;   // capture-wall thickness
lip_flat = 2.0;   // flat catch depth of the side snap hooks
ear      = 16;    // side mounting-ear width (screw strips)
port_post = 7;    // structure kept at each END of the open port edges
                  // (opening width = mini_w + 2*fit - 2*port_post). Ports
                  // span nearly full width, so this is decoupled from corner_r.

/* ---------- Wall screws (#8 wood screw / drywall anchor) ---------- */
screw_d  = 4.5;   // shank clearance
head_d   = 9.0;   // countersink head dia
csink    = 2.6;   // countersink depth

/* ---------- Airflow vents in the side rails ---------- */
vent     = true;
vent_h   = 16;    // slot height (Y)
vent_z0  = 8;     // slot bottom (Z)
vent_z1  = gap;   // slot top (Z)

$fn = 96;

/* ---------- Derived ---------- */
sw  = mini_w + 2*fit;          // slot width
sh  = mini_h + 2*fit;          // slot height
cr  = corner_r + fit;          // slot corner radius
ow  = sw + 2*wall_th;          // frame outer width
oh  = sh + 2*wall_th;          // frame outer height
orr = cr + wall_th;            // frame outer corner radius
zmb = back_th + gap;           // Mini bottom face (Z)
zmt = zmb + mini_t;            // Mini top  face (Z)
rx  = sw/2;                    // inner face of side rail (X)
sy  = sh/2 - corner_r;         // half-length of a straight side edge (Y)
ox  = sw/2 - corner_r;         // v02: opening tied to corner radius (~77mm, narrow)
ex  = ow/2 + ear/2;            // screw X (centre of ear)
ey  = sh/2 - 12;              // screw Y inset

/* ============================================================ */

// 2D rounded rectangle, w x h, corner radius r, centred
module rrect(w, h, r) offset(r) square([w - 2*r, h - 2*r], center = true);

module backplate() {
    linear_extrude(back_th) {
        rrect(ow, oh, orr);                              // rounded body
        for (s = [-1, 1])                                // side ears for screws
            translate([s*(ow/2 + ear/2), 0])
                square([ear + 1, 2*ey + 22], center = true);
    }
}

module standoff() {
    // central pad: contacts only the Mini's central base puck, never the intake ring
    cylinder(h = zmb, d = 45);
}

// Rounded capture frame, full height, with top & bottom straight sections opened
module frame() {
    difference() {
        linear_extrude(zmt)
            difference() { rrect(ow, oh, orr); rrect(sw, sh, cr); }
        // open the top & bottom port edges across the full opening width.
        // cut from the start of the corner arc (sh/2 - corner_r) outward, so
        // the rounded corner material in front of the outer ports is removed
        // too. stops short of the central standoff (y stays > slot-corner).
        oy0 = sh/2 - corner_r - 2;
        oy1 = oh/2 + 2;
        for (s = [-1, 1])
            translate([-ox, (s > 0) ? oy0 : -oy1, back_th])
                cube([2*ox, oy1 - oy0, zmt - back_th + 10]);
    }
}

// Snap hook sitting on top of one side rail (right); left = mirror.
module side_hook_right() {
    pts = [
        [rx - lip_flat, zmt],                       // catch tip (over the Mini)
        [rx + wall_th,  zmt],                        // outer (over the wall top)
        [rx + wall_th,  zmt + wall_th + lip_flat],
        [rx - lip_flat, zmt + lip_flat]              // 45-deg self-supporting top
    ];
    translate([0, sy, 0])
        rotate([90, 0, 0])
            linear_extrude(height = 2*sy)            // only along the straight edge
                polygon(pts);
}

module side_hooks() {
    side_hook_right();
    mirror([1,0,0]) side_hook_right();
}

module screw_hole() {
    translate([0,0,-1]) cylinder(h = back_th + 2, d = screw_d);
    translate([0,0,back_th - csink])
        cylinder(h = csink + 0.01, d1 = screw_d, d2 = head_d);
}

module vents_right() {
    for (yy = [-24, 0, 24])
        translate([rx - 2, yy - vent_h/2, vent_z0])
            cube([wall_th + 4, vent_h, vent_z1 - vent_z0]);
}

module mount() {
    difference() {
        union() {
            backplate();
            standoff();
            frame();
            side_hooks();
        }
        for (a = [-1, 1], b = [-1, 1])               // 4 wall screws
            translate([a*ex, b*ey, 0]) screw_hole();
        if (vent) { vents_right(); mirror([1,0,0]) vents_right(); }
    }
}

mount();
