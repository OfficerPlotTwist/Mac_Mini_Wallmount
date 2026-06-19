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
screw_x  = 16;    // wall-screw X offset: 2 screws per OPEN top/bottom baseplate segment -> (±screw_x, ±screw_y)
screw_y  = 54;    // wall-screw Y: out in the open ±Y segments (no rib/wall/standoff above) so a driver
                  // has clear vertical access to the countersunk head. (The old corner screws sat
                  // UNDER the diagonal ribs at z=back_th and couldn't be reached to drive.)
ridge_w   = 5;    // rest-ridge protrusion + 45-deg chamfer height (Mini base sits on the top)
ridge_lift = 4;   // raise the rest-ridges ABOVE the spacer's contact plane (z=zmb) by this much.
                  // The Mini's perimeter (where the ridges land) is RECESSED relative to the
                  // central base the 88mm spacer touches, so ridges level with the spacer never
                  // touch. *** VERIFY on the real Mini: set = perimeter recess depth. ***
port_post = 7;    // (legacy) rail end-structure; the top/bottom opening is now governed by
                  // corner_sweep below, not this.
corner_sweep = 12;// how far the top/bottom walls wrap PAST each corner onto the straight edge.
                  // bigger = walls sweep further around the corners (more corner capture).

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
ox  = sw/2 - corner_r - corner_sweep;  // half-width of top/bottom opening; wall wraps corner_sweep past each corner
ex  = screw_x;                 // screw X (in the open top/bottom segments)
ey  = screw_y;                 // screw Y (in the open top/bottom segments)

/* ============================================================ */

// 2D rounded rectangle, w x h, corner radius r, centred
module rrect(w, h, r) offset(r) square([w - 2*r, h - 2*r], center = true);

module backplate() {
    // minimized footprint: just the rounded frame body, no protruding screw ears
    linear_extrude(back_th)
        rrect(ow, oh, orr);
}

standoff_d    = 88;        // round spacer outer dia (was 45) — wide central pad reaches the Mini's
                           //   solid base; the perimeter rest-ridges miss it past the cooling vents
standoff_bore = 72;        // central bore pushed wider (37->62->72) to shed more material. Now that the
                           //   join struts are FULL height they carry the structure, so the pad can be a
                           //   thin 8mm ring (r36->44, ~20cm2 contact) + full-height struts that also
                           //   contact the Mini centrally. (~75 dia max: strut roots sit at r37.5.)
lighten       = false;     // lightening windows removed — they clashed with the 88mm pad and worked
                           //   against the added rigidity (set true only if weight matters more)
lighten_d     = 42;        // (unused while lighten = false)

/* ---------- Organic "topology-optimized" join struts: pad -> side rails AND corners ---------- */
join_wall   = true;       // low curved struts fanning from the pad across a wide span of each side rail
join_h      = zmb;        // FULL height (= standoff/bore height): the struts now carry the structure
                          //   the solid pad used to -> far stiffer in bending, replaces material.
                          //   Tops sit at the Mini base plane, adding central contact.
join_n      = 5;          // struts per side rail
join_spread = 34;         // half-span (Y) of rail the fan attaches across (a wide arc of the side wall)
join_t_end  = 5;          // strut thickness where it meets the pad / the rail
join_t_mid  = 2.6;        // thinner mid-span (topology-optimized: material only where it's stressed)
join_bow    = 9;          // organic curvature of the outer struts
join_in     = standoff_d/2 - 4;   // pad-side root radius (fuses into the pad ring)
join_nc     = 3;          // struts per CORNER (organic fan that REPLACES the old thick diagonal rib)
join_corner_arc = 22;     // half-arc (deg) of the corner the corner-fan struts spread across

/* ---------- Support shelves (replace the continuous rest-ledge): one small shelf per strut ---------- */
shelf_len   = 10;         // length of each shelf segment (along the wall) — discrete, sits on a strut
pb_clear    = true;       // finger access to the (wall-facing) power button — through the curved SIDE wall
pb_x        = -47.9;      // power-button centre (harness coords) — from Macmini.glb 'power button' mesh
pb_y        = -47.9;      //   (back/-X side, by the -Y corner); button press-face is at z~29
pb_finger   = 22;         // diameter of the finger hole through the curved corner wall
pb_z        = 20;         // hole-centre height: in the standoff gap, top reaches up to the button (~z29-31)
pb_dir      = atan2(pb_y, pb_x);   // direction from centre to the button / finger hole (~ -135 deg)
pb_keep     = 22;         // skip ANY strut/shelf whose wall attachment lies within this angle (deg) of the
                          //   button direction. The finger cylinder used to clip the nearest -X-rail strut
                          //   (and the -X-Y corner fan) mid-span, leaving sliced stub faces poking into the
                          //   access channel ("boolean junk"). Dropping the whole strut/shelf instead of
                          //   slicing it keeps the channel clean. 22deg drops exactly the corner fan + the
                          //   one rail strut that reach into the hole; the others are untouched.
// smallest absolute angle (deg) between headings a and b
function adiff(a, b) = abs(((((a - b) % 360) + 540) % 360) - 180);
// true if a wall attachment at heading 'ang' falls inside the power-button keep-out
function near_pb(ang) = pb_clear && adiff(ang, pb_dir) <= pb_keep;

/* ---------- Airflow vents in the backplate, in the gaps between the struts ---------- */
airflow   = true;
air_r     = 53;           // radius of the vent ring (between the pad r44 and the rails r63.9)
air_d     = 7;            // vent hole diameter
air_ang   = [90, 270, 33, 57, 123, 147, 303, 327];   // angles that fall in the gaps between the fans

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

// Quadratic Bezier point
function bez(p0, p1, p2, t) =
    [ pow(1-t,2)*p0[0] + 2*(1-t)*t*p1[0] + t*t*p2[0],
      pow(1-t,2)*p0[1] + 2*(1-t)*t*p1[1] + t*t*p2[1] ];

// One organic tapered strut (2D): thick where it anchors (ends), thin mid-span.
module join_strut2d(p0, p1, p2, seg = 16) {
    for (i = [0 : seg-1]) {
        t0 = i/seg;  t1 = (i+1)/seg;
        r0 = (join_t_mid + (join_t_end - join_t_mid)*pow(2*t0-1, 2)) / 2;
        r1 = (join_t_mid + (join_t_end - join_t_mid)*pow(2*t1-1, 2)) / 2;
        hull() {
            translate(bez(p0,p1,p2,t0)) circle(r = r0);
            translate(bez(p0,p1,p2,t1)) circle(r = r1);
        }
    }
}

// Fan of struts from the pad ring out to a wide span of a side rail.
// sx = +1 -> +X rail, sx = -1 -> -X rail. A strut whose rail attachment falls in the
// power-button keep-out is dropped (not generated) so the finger cylinder never has to
// slice it into stub geometry.
module join_fan_rightX(sx = 1) {
    for (i = [0 : join_n-1]) {
        f  = (join_n == 1) ? 0 : (i/(join_n-1))*2 - 1;   // -1..1 across the fan
        yr = f * join_spread;                            // attach point on the rail (Y)
        if (!near_pb(atan2(yr, sx*rx))) {                // skip the strut that reaches into the finger hole
            pa = f * 42;                                 // root fanned +/-42 deg around +X on the pad
            p0 = [ join_in*cos(pa), join_in*sin(pa) ];   // pad-ring root
            p2 = [ rx, yr ];                             // rail attach (drawn for +X; sx flips it)
            dx = p2[0]-p0[0]; dy = p2[1]-p0[1]; L = sqrt(dx*dx + dy*dy);
            mid = [ (p0[0]+p2[0])/2, (p0[1]+p2[1])/2 ];
            p1 = [ mid[0] - (dy/L)*join_bow*f, mid[1] + (dx/L)*join_bow*f ];  // bow splays outward with f
            scale([sx, 1, 1]) join_strut2d(p0, p1, p2);
        }
    }
}
// Extended organic fan from the pad out to a wider arc of the +45 corner wall.
// Replaces the old thick diagonal rib with several thinner triangulated struts.
module join_fan_corner() {
    cc = [sw/2 - cr, sh/2 - cr];                      // inner corner-arc centre (+X+Y)
    for (i = [0 : join_nc-1]) {
        f   = (join_nc == 1) ? 0 : (i/(join_nc-1))*2 - 1;   // -1..1 across the fan
        phi = 45 + f*join_corner_arc;                 // attach angle on the corner arc
        p2  = [ cc[0] + cr*cos(phi), cc[1] + cr*sin(phi) ];  // corner-wall attach (end circle embeds in)
        pa  = 45 + f*25;                              // pad-root angle, tracking the fan
        p0  = [ join_in*cos(pa), join_in*sin(pa) ];   // pad-ring root
        dx = p2[0]-p0[0]; dy = p2[1]-p0[1]; L = sqrt(dx*dx + dy*dy);
        mid = [ (p0[0]+p2[0])/2, (p0[1]+p2[1])/2 ];
        p1  = [ mid[0] - (dy/L)*join_bow*f, mid[1] + (dx/L)*join_bow*f ];
        join_strut2d(p0, p1, p2);
    }
}
module join_walls() {
    linear_extrude(join_h) {
        join_fan_rightX(1); join_fan_rightX(-1);                     // to the two side rails
        for (a = [0, 90, 180, 270]) if (!near_pb(45 + a))            // corners (skip the finger-hole corner)
            rotate([0, 0, a]) join_fan_corner();
    }
}

/* ---------- Support shelves: short chamfered ledges, each sitting on a join strut ----------
   Replaces the old continuous rest-ridge. Each shelf is a small ledge at the recessed-perimeter
   height (zr); a full-height join strut lands directly beneath it -> clean support + print path.
   The same chamfered profile is placed on the straight rails AND on the swept corner walls. */
// one straight shelf on the +X rail at y=yc (mirrored by sx); top at zr, 45° underside (prints in place)
module rail_shelf(sx, yc) {
    zr = zmb + ridge_lift;
    pts = [[rx-ridge_w, zr], [rx+wall_th, zr], [rx+wall_th, zr-ridge_w], [rx, zr-ridge_w]];
    scale([sx, 1, 1])
        translate([0, yc + shelf_len/2, 0]) rotate([90,0,0]) linear_extrude(shelf_len) polygon(pts);
}
// one shelf on the rounded corner wall (the new swept-wall section) at arc-angle phi; top at zr
module corner_shelf(phi) {
    zr = zmb + ridge_lift; cc = [sw/2 - cr, sh/2 - cr];
    pts = [[cr-ridge_w, zr], [cr+wall_th, zr], [cr+wall_th, zr-ridge_w], [cr, zr-ridge_w]];
    translate(cc) rotate([0,0,phi])
        translate([0, shelf_len/2, 0]) rotate([90,0,0]) linear_extrude(shelf_len) polygon(pts);
}
// place one shelf above each join strut (both rails + all four swept corners); skip the power-button zone
module support_shelves() {
    for (sx = [1, -1])
        for (i = [0 : join_n-1]) {
            f  = (join_n == 1) ? 0 : (i/(join_n-1))*2 - 1;
            if (!near_pb(atan2(f * join_spread, sx*rx)))   // drop the shelf over the dropped finger-hole strut
                rail_shelf(sx, f * join_spread);
        }
    for (a = [0, 90, 180, 270]) if (!near_pb(45 + a))
        rotate([0,0,a])
            for (i = [0 : join_nc-1]) {
                f = (join_nc == 1) ? 0 : (i/(join_nc-1))*2 - 1;
                corner_shelf(45 + f*join_corner_arc);
            }
}
// clears the power button: removes everything above pb_clear_h in a zone next to the rail
// (also shortens the join struts there to pb_clear_h -> "ribs beneath the button = 3 mm")
module pb_cut() {
    // The power button faces the wall, so a backplate hole is useless when mounted flush. Instead cut
    // a finger-sized hole through the exposed CURVED CORNER SIDE WALL, aimed radially at the button, in
    // the standoff-gap band — also clears the struts/shelves in the finger path. The channel is shifted
    // outward so its inner end stays clear of the central pad; the backplate stays solid.
    rb  = norm([pb_x, pb_y]);          // button radius from centre (~67.7)
    dir = atan2(pb_y, pb_x);           // direction to the button / corner (~ -135 deg)
    translate([(rb + 8)*cos(dir), (rb + 8)*sin(dir), pb_z])
        rotate([0, 0, dir]) rotate([0, 90, 0])
            cylinder(h = 44, d = pb_finger, center = true);
}

// Airflow vents bored through the backplate, in the open gaps between the radial struts.
module air_holes() {
    for (a = air_ang)
        translate([air_r*cos(a), air_r*sin(a), -1])
            cylinder(h = back_th + 2, d = air_d);
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

/* ---------- Port cutouts (traced from Macmini.glb) ----------
   Mini rotated so its port faces meet the side rails (logo faces room).
   Each entry = [ Y centre, width(Y), height(Z) ];  height < 0 = round port.
   Lists MUST stay sorted ascending by Y centre (the web auto-clamp below
   assumes neighbours are adjacent in the list). */
cut_ports  = true;
base_grow  = 1.0;     // base connector clearance (print-in-place fit) — both axes
boot_grow  = 3.0;     // EXTRA room for the rubber strain-relief boot on the plug:
                      //   - applied in full to HEIGHT (Z) on every port
                      //   - applied to WIDTH (Y) only as far as the web clamp allows
web_min    = 2.0;     // min material left between adjacent cutouts. Was 1.35 (3 perimeters @0.45) and
                      //   the webs between the crowded Thunderbolt/USB-C sockets SNAPPED. Raised to
                      //   2.0 (~4-5 perimeters) for a sturdier column; the teardrop roofs (above) also
                      //   tie each web into the solid wall, so it is no longer a free-standing pillar.
                      //   The back rail is crowded (the 3 Thunderbolt sockets sit 8.5mm apart on the
                      //   real Mini and can't be moved), so width growth is clamped per-port to keep
                      //   every web >= this. Isolated ports (Power, headphone) still reach full width.
                      //   *** This narrows the crowded ports ~0.6mm; if a plug boot won't seat, drop
                      //   back toward 1.6. ***
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

// Per-port WIDTH grow, clamped so the web to each neighbour stays >= web_min.
// Pair budget B = 2*gap - (raw_i + raw_j) - 2*web_min  is the max of (g_i + g_j);
// splitting it equally gives g_i <= B/2, which is provably web-safe for both
// neighbours and needs no circular solve. Floored at base_grow (never narrower
// than the current fit), capped at base_grow + boot_grow (full boot allowance).
function pair_half(gap, ri, rj) = (2*gap - (ri + rj) - 2*web_min) / 2;
function wgrow(L, i) =
    let(full = base_grow + boot_grow,
        loP  = (i > 0)        ? pair_half(L[i][0]   - L[i-1][0], abs(L[i][1]), abs(L[i-1][1])) : 1e9,
        hiP  = (i < len(L)-1) ? pair_half(L[i+1][0] - L[i][0],   abs(L[i][1]), abs(L[i+1][1])) : 1e9)
    max(base_grow, min(full, loP, hiP));

/* Self-supporting "teardrop" port profile so each hole's top never exceeds a 45°
   overhang when printed backplate-down. The old round/obround tops bridged as a
   near-horizontal arch across the wide ports (Power, HDMI, Ethernet) and drooped.
   A 45° gable roof self-supports and, because adjacent gables converge to points,
   it also ties each thin inter-port web back into the solid wall above the band
   (bracing the columns that were snapping).
   NOTE on axes: this 2D profile is extruded then placed by rotate([0,90,0]), which maps
   local +x -> global -Z. So the printed-UP direction (global +Z, where the ceiling droops)
   is local -x: the gable apex must point toward -x. */
teardrop = true;   // 45° gable roof on every port; set false for plain round/obround holes
module port_profile2d(W, H, round=false) {
    if (round) {
        r = W/2;
        union() {
            circle(d = W);
            if (teardrop) polygon([[0,-r],[0,r],[-r,0]]);                    // gable from the equator up to a point
        }
    } else {
        R = min(W, H) / 2; a = W/2;
        union() {
            offset(R) square([max(H-2*R,0.01), max(W-2*R,0.01)], center=true);     // obround body
            if (teardrop) translate([-(H/2 - R), 0]) polygon([[0,-a],[0,a],[-a,0]]); // 45° gable on the (up) top
        }
    }
}
module port_slot(sgn, yc, w, h, wg, hg, zc = port_z) {
    translate([sgn * 65, yc, zc])
        rotate([0, 90, 0])
            linear_extrude(height = 40, center = true)
                port_profile2d(w + wg, h + hg, round = (h < 0));
}
module port_cuts() {
    hg = base_grow + boot_grow;                                  // full boot allowance in Z (unconstrained)
    for (i = [0:len(back_ports)-1])
        let(p = back_ports[i])  port_slot(-1, p[0], p[1], p[2], wgrow(back_ports, i),  hg);
    for (i = [0:len(front_ports)-1])
        let(p = front_ports[i]) port_slot( 1, p[0], p[1], p[2], wgrow(front_ports, i), hg);
    if (led) port_slot(1, led_y, led_d, -led_d, 0, 0, led_z);    // round LED hole (kept small, no widening)
}

module mount() {
    difference() {
        union() {
            backplate();
            standoff();
            frame();
            side_hooks();
            // Clip the struts + shelves to the outer footprint so their straight segments can't
            // poke past the rounded corners (the inner ledge protrusions are well inside, so kept).
            intersection() {
                union() {
                    if (join_wall) join_walls();
                    support_shelves();
                }
                linear_extrude(zmt) rrect(ow, oh, orr);
            }
        }
        if (pb_clear) pb_cut();                      // power-button finger hole through the corner side wall
        if (airflow) air_holes();                    // airflow vents through the backplate, between the struts
        for (a = [-1, 1], b = [-1, 1])               // 4 wall screws
            translate([a*ex, b*ey, 0]) screw_hole();
        translate([0, 0, -1])                        // hollow standoff, bored clean through the backplate
            cylinder(h = zmb + 2, d = standoff_bore);
        if (lighten) lighten_holes();                // lightening windows in the wall plate
        if (vent) { vents_right(); mirror([1,0,0]) vents_right(); }
        if (cut_ports) port_cuts();                  // port holes in the side rails
    }
}

show_cutters = false;   // true -> output ONLY the port/LED cutter solids (for an external boolean)
if (show_cutters) port_cuts(); else mount();
