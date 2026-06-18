// ============================================================
//  Mac Mini (M4 / M4 Pro) Wall Mount  —  v01
//  First design: straight L/R capture rails, SHARP (square) corners,
//  back ports exit a rectangular opening on the DOWN edge.
//  Snap hooks on the side rails; bottom corner ledges bear the weight.
// ============================================================
mini_w = 127; mini_h = 127; mini_t = 50;
fit      = 0.4;  gap = 28;  back_th = 4.5;  wall_th = 3.2;  lip_flat = 2.0;  ear = 16;
screw_d  = 4.5;  head_d = 9.0;  csink = 2.6;
corner_sup = 16; sup_th = 4; sup_z = 14;       // bottom corner weight ledges
vent = true; vent_h = 16; vent_z0 = 8; vent_z1 = gap;
$fn = 64;

sw = mini_w + 2*fit;  sh = mini_h + 2*fit;
zmb = back_th + gap;  zmt = zmb + mini_t;  rx = sw/2;
bw = sw + 2*wall_th + 2*ear;  bh = sh;
ex = sw/2 + wall_th + ear/2;  ey = sh/2 - 12;

module backplate() { translate([-bw/2,-bh/2,0]) cube([bw, bh, back_th]); }
module standoff()  { cylinder(h = zmb, d = 45); }

module rail_right() {
    pts = [[rx,0],[rx+wall_th,0],[rx+wall_th, zmt+wall_th+lip_flat],
           [rx-lip_flat, zmt+lip_flat],[rx-lip_flat, zmt],[rx, zmt]];
    translate([0, sh/2, 0]) rotate([90,0,0]) linear_extrude(height = sh) polygon(pts);
}
module rails() { rail_right(); mirror([1,0,0]) rail_right(); }

module support_right() {
    translate([rx-corner_sup, -sh/2-sup_th, zmt-sup_z]) cube([corner_sup, sup_th+0.01, sup_z]);
    translate([rx-corner_sup, -sh/2-sup_th, zmt-sup_z]) cube([corner_sup, sup_th+2, 3]);
}
module supports() { support_right(); mirror([1,0,0]) support_right(); }

module screw_hole() {
    translate([0,0,-1]) cylinder(h = back_th+2, d = screw_d);
    translate([0,0,back_th-csink]) cylinder(h = csink+0.01, d1 = screw_d, d2 = head_d);
}
module vents() {
    for (yy = [-40,0,40])
        translate([rx-4, yy-vent_h/2, vent_z0]) cube([wall_th+8+ear, vent_h, vent_z1-vent_z0]);
}
module mount() {
    difference() {
        union() { backplate(); standoff(); rails(); supports(); }
        for (sx=[-1,1], sy=[-1,1]) translate([sx*ex, sy*ey, 0]) screw_hole();
        if (vent) { vents(); mirror([1,0,0]) vents(); }
    }
}
mount();
