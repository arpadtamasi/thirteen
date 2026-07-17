// thirteen — parametric case
// Top plate with Kailh Choc v1 cutouts + bottom shell with USB-C opening.
//
// Layout: encoder knob top-left, joystick top-right, two keys between
// them, then rows of 4 / 4 / 3 keys (13 keys total). An optional
// translucent bottom rim acts as a diffuser for the 6 edge-glow LEDs.
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
// width reserved for the knob / joystick corner cells in the top band
corner_cell = 24.0;
// height of the top band (knob + joystick + 2 keys)
top_band = 28.0;

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

// top band: corner cell + 2 keys + corner cell
plate_w = 2 * corner_cell + 2 * key_pitch_x + 2 * margin;
plate_h = top_band + 3 * key_pitch_y + 2 * margin;

top_cy   = plate_h - margin - top_band / 2;   // knob / joystick / K0-K1 center
rows_top = plate_h - margin - top_band;       // top edge of the 4/4/3 block

enc_cx = margin + corner_cell / 2;            // knob, top-left
joy_cx = plate_w - margin - corner_cell / 2;  // joystick, top-right

// rows below the top band: 4 keys, 4 keys, then 1u + 2u talk bar + 1u

// screw bosses, inset from the four corners
boss_inset = margin;
boss_pos = [
    [boss_inset, boss_inset],
    [plate_w - boss_inset, boss_inset],
    [boss_inset, plate_h - boss_inset],
    [plate_w - boss_inset, plate_h - boss_inset],
];

// ---- key positions -----------------------------------------------------------

// key index -> [x, y] center. K0-K1 sit in the top band between knob and
// joystick; K2-K12 fill the 4/4/3 rows below.
function key_pos(i) =
    i < 2 ? [margin + corner_cell + (i + 0.5) * key_pitch_x, top_cy]
  : i < 10 ? let(j = i - 2,
        r = j < 4 ? 0 : 1,
        c = r == 0 ? j : j - 4,
        x0 = (plate_w - 4 * key_pitch_x) / 2)
    [x0 + (c + 0.5) * key_pitch_x,
     rows_top - r * key_pitch_y - key_pitch_y / 2]
    // bottom row: 1u, 2u talk bar, 1u (cells 18 / 36 / 18)
  : let(x0 = (plate_w - 4 * key_pitch_x) / 2,
        cx = i == 10 ? 0.5 * key_pitch_x
           : i == 11 ? 2.0 * key_pitch_x
           : 3.5 * key_pitch_x)
    [x0 + cx, rows_top - 2 * key_pitch_y - key_pitch_y / 2];

module at_each_key() {
    for (i = [0 : 12]) translate(key_pos(i)) children();
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
        translate([enc_cx, top_cy, -eps])
            cylinder(d = enc_hole_d, h = plate_thickness + 2 * eps);

        // joystick opening
        translate([joy_cx, top_cy, -eps])
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
// edge-glow color shown in the preview (the daemon paints it with the
// highest-priority agent state); "" = off
edge_glow = "#FFB000";

// per-key LED glow colors for the preview: the daemon's default state
// palette. "" = LED off. K0-K5 are the six agent keys.
glow_colors = [
    "#8A2BE2", "#00A0FF",                       // K0-K1, top band
    "#FFB000", "#00C853", "#8A2BE2", "",        // K2-K5, agent row
    "", "", "", "",                             // K6-K9, command row
    "", "", ""                                  // K10-K12, bottom row
];

case_color = display_style == "white" ? [0.90, 0.90, 0.91] : [0.13, 0.13, 0.14];
cap_color  = display_style == "white" ? [0.96, 0.96, 0.97] : [0.17, 0.17, 0.18];
icon_color = display_style == "white" ? [0.30, 0.30, 0.34] : [0.80, 0.80, 0.84];

// keycap legends: session dots 1-6 on the agent keys (top band + second
// row), then approve / reject / run / pause, then prev / next / clear
// bottom row: prev / push-to-talk bar / clear
icon_ids = ["d1", "d2",
            "d3", "d4", "d5", "d6",
            "chk", "x", "play", "pause",
            "left", "mic", "ring"];

module rounded_sq(w, h, r) {
    offset(r = r) offset(r = -r) square([w, h], center = true);
}

// MBK-ish Choc keycap; u = width in key units (2 = the talk bar)
module keycap(u = 1) {
    w = 16.9 + (u - 1) * 18;
    hull() {
        linear_extrude(0.01) rounded_sq(w, 15.9, 2);
        translate([0, 0, 3.2])
            linear_extrude(0.01) rounded_sq(w - 2.4, 13.5, 3);
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
      : n == 5 ? [[-2, -2], [2, -2], [0, 0], [-2, 2], [2, 2]]
      :          [[-1.8, -2.2], [1.8, -2.2], [-1.8, 0], [1.8, 0],
                  [-1.8, 2.2], [1.8, 2.2]];
    for (q = p) translate(q) circle(d = 1.7);
}

module icon(id) {
    if (id == "d1") dots(1);
    if (id == "d2") dots(2);
    if (id == "d3") dots(3);
    if (id == "d4") dots(4);
    if (id == "d5") dots(5);
    if (id == "d6") dots(6);
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
    if (id == "mic") scale(0.85) {
        // body
        hull() {
            translate([0, 3.2]) circle(d = 3.2);
            translate([0, 0.8]) circle(d = 3.2);
        }
        // holder: bottom half-ring wrapping under the body
        difference() {
            circle(d = 6.6);
            circle(d = 4.8);
            translate([0, 3.05]) square([8, 5.1], center = true);
        }
        // stem + base
        seg([0, -3.3], [0, -4.4], 1.2);
        seg([-1.8, -4.7], [1.8, -4.7], 1.2);
    }
}

module display_assembly() {
    top_z = floor_thickness + shell_inner_height;  // plate rests here

    color(case_color) shell();
    color(case_color) translate([0, 0, top_z]) plate();

    // edge-glow diffuser rim, lit by the 6 underglow LEDs
    if (edge_glow != "")
        color(edge_glow, 0.55)
            translate([0, 0, -0.5])
                linear_extrude(2.6)
                    difference() {
                        offset(r = 3.2) offset(r = -1.2) square([plate_w, plate_h]);
                        offset(r = 2) offset(r = -2) square([plate_w, plate_h]);
                    }

    // keycaps + legends + LED glow (K11 is the 2u talk bar)
    for (i = [0 : 12]) {
        p = key_pos(i);
        u = i == 11 ? 2 : 1;
        translate([p[0], p[1], top_z + plate_thickness + 1.8])
            color(cap_color) keycap(u);
        if (show_icons)
            color(icon_color)
                translate([p[0], p[1], top_z + plate_thickness + 1.8 + 3.2])
                    linear_extrude(0.4) icon(icon_ids[i]);
        if (glow_colors[i] != "")
            color(glow_colors[i], 0.9)
                translate([p[0], p[1], top_z + plate_thickness])
                    linear_extrude(1.6)
                        rounded_sq(18.6 + (u - 1) * 18, 17.6, 2);
    }

    translate([enc_cx, top_cy, top_z + plate_thickness]) knob();
    translate([joy_cx, top_cy, top_z + plate_thickness - 2]) stick();

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
