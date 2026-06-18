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
gap      = 19.05; // back spacer = 3/4 inch (intake gap + power-button access)
back_th  = 4.5;   // backplate thickness
wall_th  = 3.2;   // capture-wall thickness
lip_flat = 2.0;   // flat catch depth of the side snap hooks
screw_xy = 40.3;  // screw-hole position (moved 1/2 inch toward centre, from 53)
ridge_w  = 5;     // rest-ridge protrusion from the side rails (Mini base sits on it)
ridge_h  = 3;     // rest-ridge thickness (top flush with the Mini base)
port_post = 7;    // structure kept at each END of the open port edges
                  // (opening width = mini_w + 2*fit - 2*port_post). Ports
                  // span nearly full width, so this is decoupled from corner_r.

/* ---------- Wall screws (#8 wood screw / drywall anchor) ---------- */
screw_d  = 4.5;   // shank clearance
head_d   = 9.0;   // countersink head dia
csink    = 2.6;   // countersink depth

/* ---------- Airflow vents in the side rails ---------- */
vent     = false; // airflow vents CLOSED
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
zmb = back_th + gap;           // Mini bottom (intake/wall) face (Z)
zmt = zmb + mini_t;            // Mini top (logo/room) face (Z)
port_z = zmb + 22;             // port band centre: ~22mm above the wall-side face
rx  = sw/2;                    // inner face of side rail (X)
sy  = sh/2 - corner_r;         // half-length of a straight side edge (Y)
ox  = sw/2 - port_post;        // half-width of open top/bottom port section (X)
ex  = screw_xy;                // screw X (within minimized footprint)
ey  = screw_xy;                // screw Y (within minimized footprint)

/* ============================================================ */

// 2D rounded rectangle, w x h, corner radius r, centred
module rrect(w, h, r) offset(r) square([w - 2*r, h - 2*r], center = true);

module backplate() {
    // minimized footprint: just the rounded frame body, no protruding screw ears
    linear_extrude(back_th)
        rrect(ow, oh, orr);
}

standoff_d    = 45;        // round spacer outer diameter
standoff_bore = 45 - 2*4;  // hollow bore (4 mm ring wall) — bored through the backplate in mount()
lighten       = true;      // lightening windows in the wall plate
lighten_d     = 42;        // radial position of each window (N/S/E/W, clear of the corner screws)

module lighten_holes() {
    for (a = [0, 90, 180, 270])
        rotate([0, 0, a]) translate([0, lighten_d, -1])
            linear_extrude(back_th + 2)
                offset(6) square([34, 10], center = true);   // ~46 x 22 rounded window
}

module standoff() {
    // central pad that contacts the Mini's base puck (bored hollow in mount())
    cylinder(h = zmb, d = standoff_d);
}

// rest ridges: ledges on the side rails the Mini's base perimeter sits on
module rest_ridge_right() {
    translate([rx - ridge_w, -sy, zmb - ridge_h])
        cube([ridge_w + wall_th, 2*sy, ridge_h]);
}
module rest_ridges() { rest_ridge_right(); mirror([1,0,0]) rest_ridge_right(); }

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

/* ---------- Port cutouts (traced from Macmini.glb, +1mm clearance) ----------
   Mini rotated so its port faces meet the side rails (logo faces room).
   Each entry = [ Y centre, width(Y), height(Z) ];  height < 0 = round port. */
cut_ports  = true;
back_ports = [        // 6 ports on the -X rail
    [-40.75,  4.7, 10.5],   // Thunderbolt 1
    [-32.25,  4.7, 10.5],   // Thunderbolt 2
    [-23.65,  4.7, 10.5],   // Thunderbolt 3
    [ -9.00, 17.1,  7.0],   // HDMI
    [ 10.00, 14.6, 12.6],   // Ethernet
    [ 32.05, 19.1, 10.7],   // Power
];
front_ports = [       // 3 ports on the +X rail
    [-37.00,  4.7, 10.5],   // USB-C
    [-22.10,  4.7, 10.5],   // USB-C
    [ 36.40,  6.2, -6.2],   // headphone (round)
];

// Power-status LED hole (NOT in the GLB -- position estimated; verify on a real unit)
led    = true;
led_y  = 24.4;         // front, between the USB-C pair and the headphone (loop-selected off the model)
led_z  = 45.7;         // port-band height (the flush ~1.9mm status light)
led_d  = 2.2;          // very small circle, plain through-hole (no inlay)

module port_slot(sgn, yc, w, h, zc = port_z, r = 1.2) {
    translate([sgn * 65, yc, zc])
        rotate([0, 90, 0]) {
            if (h < 0)
                cylinder(h = 40, d = w, center = true);          // round
            else
                linear_extrude(height = 40, center = true)       // rounded rect
                    offset(r) square([max(h-2*r,0.1), max(w-2*r,0.1)], center = true);
        }
}
module port_cuts() {
    for (p = back_ports)  port_slot(-1, p[0], p[1], p[2]);
    for (p = front_ports) port_slot( 1, p[0], p[1], p[2]);
    if (led) port_slot(1, led_y, led_d, -led_d, led_z);   // round LED hole, front rail
}

module mount() {
    difference() {
        union() {
            backplate();
            standoff();
            frame();
            side_hooks();
            rest_ridges();
        }
        for (a = [-1, 1], b = [-1, 1])               // 4 wall screws
            translate([a*ex, b*ey, 0]) screw_hole();
        translate([0, 0, -1])                        // hollow standoff, bored clean through the backplate
            cylinder(h = zmb + 2, d = standoff_bore);
        if (lighten) lighten_holes();                // lightening windows in the wall plate
        if (vent) { vents_right(); mirror([1,0,0]) vents_right(); }
        if (cut_ports) port_cuts();                  // port holes in the side rails
    }
}

mount();
