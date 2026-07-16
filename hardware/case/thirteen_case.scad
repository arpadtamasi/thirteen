// thirteen — parametric case
// Top plate with Kailh Choc v1 cutouts + bottom shell with USB-C opening.
//
// Render:  set `part` below (or via -D on the CLI), F6, export STL.
// See README.md in this directory for exact commands.

/* [What to render] */
part = "plate"; // ["plate", "shell", "both"]

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

// ---- output -----------------------------------------------------------------------

if (part == "plate") plate();
if (part == "shell") shell();
if (part == "both") {
    shell();
    translate([0, 0, floor_thickness + shell_inner_height + 8]) plate();
}
