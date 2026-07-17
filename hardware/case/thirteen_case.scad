// thirteen — parametric case
// Top plate with Kailh Choc v1 cutouts + bottom shell with USB-C opening.
//
// Render:  set `part` below (or via -D on the CLI), F6, export STL.
// See README.md in this directory for exact commands.

/* [What to render] */
// "display" is a non-printable assembled preview with keycaps, knob,
// stick and LED glow — for renders only (use preview mode, F5/no --render,
// so the colors show).
part = "plate"; // ["plate", "shell", "both", "display"]

/* [Layout] */
// Choc spacing (MX: 19.05 x 19.05)
key_pitch_x = 18.0;
key_pitch_y = 17.0;
// Choc plate cutout (MX: 14.0). 13.8 per Kailh spec.
switch_cutout = 13.8;
// keys per row, top to bottom (13 total)
row_keys = [5, 5, 3];

/* [Encoder + joystick] */
// EC11 shaft hole
enc_hole_d = 7.2;
// joystick module opening (stick clearance)
joy_hole_d = 24.0;

/* [Plate] */
plate_thickness = 1.5;   // Choc switches clip into 1.3-1.6mm
margin = 6.0;            // plate border around the key block

/* [Shell] */
wall = 2.4;
shell_inner_height = 13.0;  // room for handwiring + MCU
floor_thickness = 2.0;
// USB-C opening (plug body clearance)
usb_w = 9.6;
usb_h = 3.8;
// vertical offset of USB opening center above the inner floor —
// tune to where your MCU sits. TODO(hw-test): verify with your standoff.
usb_z = 4.0;

/* [Screws] */
insert_d = 4.2;          // M3 heat-set insert hole
insert_boss_d = 8.0;
screw_clearance_d = 3.4;

/* [Hidden] */
$fn = 48;
eps = 0.01;

// ---- derived dimensions -----------------------------------------------------

max_cols = max(row_keys);
rows = len(row_keys);
// extra row of space at the bottom for encoder + joystick
extra_row_h = 30;

block_w = max_cols * key_pitch_x;
block_h = rows * key_pitch_y;
plate_w = block_w + 2 * margin;
plate_h = block_h + extra_row_h + 2 * margin;

// key block origin (top-left key center), measured from plate corner
origin_x = margin + key_pitch_x / 2;
origin_y = plate_h - margin - key_pitch_y / 2;

// encoder / joystick centers in the extra bottom band
enc_cx = margin + block_w * 0.22;
joy_cx = margin + block_w * 0.72;
ctrl_cy = margin + extra_row_h / 2;

// screw bosses, inset from the four corners
boss_inset = margin;
boss_pos = [
    [boss_inset, boss_inset],
    [plate_w - boss_inset, boss_inset],
    [boss_inset, plate_h - boss_inset],
    [plate_w - boss_inset, plate_h - boss_inset],
];

// ---- key positions -----------------------------------------------------------

function row_offset_x(r) = (max_cols - row_keys[r]) * key_pitch_x / 2;

module at_each_key() {
    for (r = [0 : rows - 1])
        for (c = [0 : row_keys[r] - 1])
            translate([origin_x + row_offset_x(r) + c * key_pitch_x,
                       origin_y - r * key_pitch_y])
                children();
}

// ---- plate --------------------------------------------------------------------

module plate() {
    difference() {
        // plate slab
        linear_extrude(plate_thickness)
            offset(r = 2) offset(r = -2)  // rounded corners
                square([plate_w, plate_h]);

        // switch cutouts
        at_each_key()
            translate([-switch_cutout / 2, -switch_cutout / 2, -eps])
                cube([switch_cutout, switch_cutout, plate_thickness + 2 * eps]);

        // encoder shaft
        translate([enc_cx, ctrl_cy, -eps])
            cylinder(d = enc_hole_d, h = plate_thickness + 2 * eps);

        // joystick opening
        translate([joy_cx, ctrl_cy, -eps])
            cylinder(d = joy_hole_d, h = plate_thickness + 2 * eps);

        // corner screw holes (countersunk from top)
        for (p = boss_pos)
            translate([p[0], p[1], -eps]) {
                cylinder(d = screw_clearance_d, h = plate_thickness + 2 * eps);
                translate([0, 0, plate_thickness - 1.2])
                    cylinder(d1 = screw_clearance_d, d2 = 6.4, h = 1.2 + eps);
            }
    }
}

// ---- bottom shell ---------------------------------------------------------------

module shell() {
    total_h = floor_thickness + shell_inner_height;
    difference() {
        // outer body
        linear_extrude(total_h)
            offset(r = 2) offset(r = -2)
                square([plate_w, plate_h]);

        // inner cavity
        translate([wall, wall, floor_thickness])
            linear_extrude(total_h)
                offset(r = 1) offset(r = -1)
                    square([plate_w - 2 * wall, plate_h - 2 * wall]);

        // USB-C opening, centered on the top edge (MCU mounts against it)
        translate([plate_w / 2 - usb_w / 2,
                   plate_h - wall - eps,
                   floor_thickness + usb_z - usb_h / 2])
            cube([usb_w, wall + 2 * eps, usb_h]);
    }

    // heat-set insert bosses
    for (p = boss_pos)
        translate([p[0], p[1], 0])
            difference() {
                cylinder(d = insert_boss_d, h = total_h);
                translate([0, 0, total_h - 6])
                    cylinder(d = insert_d, h = 6 + eps);
            }
}

// ---- display assembly (render-only, not printable) -----------------------------

/* [Display options] */
display_style = "black"; // ["black", "white"]
show_icons = true;

// per-key LED glow colors for the preview: the daemon's default state
// palette. "" = LED off.
glow_colors = [
    "#8A2BE2", "#8A2BE2", "#00A0FF", "#FFB000", "",   // top row
    "#00C853", "#8A2BE2", "", "", "",                  // middle row
    "", "", ""                                         // bottom row
];

case_color = display_style == "white" ? [0.90, 0.90, 0.91] : [0.13, 0.13, 0.14];
cap_color  = display_style == "white" ? [0.96, 0.96, 0.97] : [0.17, 0.17, 0.18];
icon_color = display_style == "white" ? [0.30, 0.30, 0.34] : [0.80, 0.80, 0.84];

// keycap legends, top row to bottom: session slots 1-5, then
// approve / reject / run / pause / stop, then prev / next / clear
icon_ids = ["d1", "d2", "d3", "d4", "d5",
            "chk", "x", "play", "pause", "stop",
            "left", "right", "ring"];

module rounded_sq(w, h, r) {
    offset(r = r) offset(r = -r) square([w, h], center = true);
}

// MBK-ish Choc keycap: 17.2x16.2 footprint tapering to a smaller top
module keycap() {
    hull() {
        linear_extrude(0.01) rounded_sq(16.9, 15.9, 2);
        translate([0, 0, 3.2])
            linear_extrude(0.01) rounded_sq(14.5, 13.5, 3);
    }
}

// knurled aluminum encoder knob
module knob() {
    color([0.72, 0.73, 0.76]) {
        cylinder(d = 13, h = 9);
        for (i = [0 : 23])
            rotate([0, 0, i * 15])
                translate([6.5, 0, 0.8]) cube([0.5, 0.8, 7.5], center = true);
    }
}

// thumbstick: shaft + flat rubber cap
module stick() {
    color([0.10, 0.10, 0.11]) {
        cylinder(d = 9, h = 7);
        translate([0, 0, 7]) cylinder(d = 20, h = 3.5);
        translate([0, 0, 10.5])
            cylinder(d1 = 20, d2 = 16, h = 1.2);
    }
}

// ---- keycap icons (2D, built from primitives — no font dependency) ---------

module seg(a, b, w) {
    hull() {
        translate(a) circle(d = w);
        translate(b) circle(d = w);
    }
}

module dots(n) {
    p = n == 1 ? [[0, 0]]
      : n == 2 ? [[-1.8, 0], [1.8, 0]]
      : n == 3 ? [[-2.4, 0], [0, 0], [2.4, 0]]
      : n == 4 ? [[-1.8, -1.8], [1.8, -1.8], [-1.8, 1.8], [1.8, 1.8]]
      :          [[-2, -2], [2, -2], [0, 0], [-2, 2], [2, 2]];
    for (q = p) translate(q) circle(d = 1.7);
}

module icon(id) {
    if (id == "d1") dots(1);
    if (id == "d2") dots(2);
    if (id == "d3") dots(3);
    if (id == "d4") dots(4);
    if (id == "d5") dots(5);
    if (id == "chk") {
        seg([-2.8, 0.2], [-0.9, -1.8], 1.5);
        seg([-0.9, -1.8], [2.9, 2.4], 1.5);
    }
    if (id == "x") {
        seg([-2.2, -2.2], [2.2, 2.2], 1.5);
        seg([-2.2, 2.2], [2.2, -2.2], 1.5);
    }
    if (id == "play") polygon([[-2, -2.8], [-2, 2.8], [3, 0]]);
    if (id == "pause") {
        translate([-1.5, 0]) square([1.7, 5.6], center = true);
        translate([1.5, 0]) square([1.7, 5.6], center = true);
    }
    if (id == "stop") square([4.8, 4.8], center = true);
    if (id == "left") polygon([[2, -2.8], [2, 2.8], [-3, 0]]);
    if (id == "right") polygon([[-2, -2.8], [-2, 2.8], [3, 0]]);
    if (id == "ring") difference() {
        circle(d = 6);
        circle(d = 3.2);
    }
}

module display_assembly() {
    top_z = floor_thickness + shell_inner_height;  // plate rests here

    color(case_color) shell();
    color(case_color) translate([0, 0, top_z]) plate();

    // keycaps + LED glow, keyed to glow_colors by index
    for (r = [0 : rows - 1])
        for (c = [0 : row_keys[r] - 1]) {
            i = (r == 0) ? c : (r == 1) ? 5 + c : 10 + c;
            x = origin_x + row_offset_x(r) + c * key_pitch_x;
            y = origin_y - r * key_pitch_y;
            translate([x, y, top_z + plate_thickness + 1.8])
                color(cap_color) keycap();
            if (show_icons)
                color(icon_color)
                    translate([x, y, top_z + plate_thickness + 1.8 + 3.2])
                        linear_extrude(0.4) icon(icon_ids[i]);
            if (glow_colors[i] != "")
                color(glow_colors[i], 0.9)
                    translate([x, y, top_z + plate_thickness])
                        linear_extrude(1.6) rounded_sq(18.6, 17.6, 2);
        }

    translate([enc_cx, ctrl_cy, top_z + plate_thickness]) knob();
    translate([joy_cx, ctrl_cy, top_z + plate_thickness - 2]) stick();

    // white USB-C cable stub out the top edge
    color([0.92, 0.92, 0.92])
        translate([plate_w / 2, plate_h - 1, floor_thickness + usb_z])
            rotate([-90, 0, 0]) cylinder(d = 3.6, h = 18);
}

// ---- output -----------------------------------------------------------------------

if (part == "plate") plate();
if (part == "shell") shell();
if (part == "both") {
    shell();
    translate([0, 0, floor_thickness + shell_inner_height + 8]) plate();
}
if (part == "display") display_assembly();
