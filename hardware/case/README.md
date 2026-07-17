# Case

Parametric OpenSCAD case: a top plate with Choc cutouts and a bottom shell
with a USB-C opening, screwed together with four M3 heat-set inserts.

## Export STLs

With [OpenSCAD](https://openscad.org/) installed:

```sh
openscad -D 'part="plate"' -o thirteen_plate.stl thirteen_case.scad
openscad -D 'part="shell"' -o thirteen_shell.stl thirteen_case.scad
```

Or in the GUI: open `thirteen_case.scad`, pick the part in the Customizer,
press F6 (render), then File → Export → STL.

## Render a preview image

`part="display"` is a non-printable assembled preview — keycaps, encoder
knob, thumbstick and per-key LED glow in the daemon's default state
colors. Render it in preview mode (no `--render`, so colors show):

```sh
openscad -D 'part="display"' --imgsize=1920,1440 \
  --colorscheme='Tomorrow Night' --camera=51,46,8,45,0,318,240 \
  -o thirteen.png thirteen_case.scad
```

## Print settings

- Plate: 0.2mm layers, 4+ perimeters, print flat, no supports. PETG or ABS
  preferred — Choc clips stress PLA over time.
- Shell: same, USB opening prints fine without supports at 45° bridging.
- Push M3 inserts into the shell bosses with a soldering iron at ~220°C.

## Tuning

Everything is a parameter at the top of the file. The ones you'll most
likely touch:

| parameter | default | change when |
|-----------|---------|-------------|
| `switch_cutout` | 13.8 | your printer over/under-extrudes (try ±0.1) |
| `key_pitch_x/y` | 18.0 / 17.0 | using MX switches (19.05 / 19.05, cutout 14.0) |
| `shell_inner_height` | 13.0 | your wiring is tidier/messier than average |
| `usb_z` | 4.0 | your MCU sits at a different height — TODO(hw-test) |
| `joy_hole_d` | 24.0 | different joystick module |
