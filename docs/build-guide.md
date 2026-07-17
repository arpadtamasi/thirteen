# Build guide

From parts bag to glowing keys. Budget an evening.

## 0. Before you solder

Flash the firmware first and test the bare board:

```sh
cd firmware
pio run -t upload            # DevKitC-1; add `-e supermini` for SuperMini
pio run -t uploadfs          # ship the default keymap to LittleFS
pio device monitor
```

You should see the `hello` line:

```json
{"t":"hello","fw":"0.1.0","proto":1,"keys":13,"edge":6,"v":1}
```

Short any key GPIO (see `hardware/WIRING.md`) to GND with a jumper — a
`key` event should appear and the board should type F13-ish keys into your
editor. If that works, everything electrical that follows is just
repetition.

If the board doesn't enumerate: hold BOOT while plugging in to enter the
ROM bootloader, flash, then unplug/replug.

## 1. Print the case

`hardware/case/README.md`. Print the plate first and test-fit one switch —
Choc clips should snap in firmly. Adjust `switch_cutout` ±0.1mm if not.

## 2. Solder, in this order

The LEDs live under the switches, so the order matters:

1. **LED chain first.** Place the 13 SK6812 MINI-E under each key position
   (legs sideways, hand-solderable). Chain them K0→K12: DOUT of each to DIN
   of the next, then continue the chain into the 6 edge-glow LEDs around
   the shell perimeter (indexes 13-18; skip them if you don't want the
   glowing rim — everything else still works). Common 5V and GND rails
   along the rows.
   Check the chain NOW — power the board and run:

   ```sh
   printf '{"v":1,"t":"led","key":-1,"color":"#220022","mode":"solid"}\n' > /dev/ttyACM0
   ```

   (Windows: use the host daemon or a serial terminal on COM3 instead.)
   All 19 LEDs should light. A dead LED mid-chain kills everything after
   it — fix now, not after the switches are in.

2. **Switches into the plate**, then one leg of each switch to its GPIO
   (30 AWG), the other legs daisy-chained to GND. No diodes — every key has
   its own pin.

3. **Encoder and joystick** into the top band (knob left, stick right);
   A/B/SW and X/Y/SW wires
   per the wiring table. Power the joystick from **3.3V** (its pots feed
   ADC pins that are not 5V-tolerant).

4. **Controller** on standoffs or a dab of double-sided foam against the
   shell's USB opening.

## 3. Close it up

M3 inserts into the shell bosses (soldering iron, ~220°C), plate on top,
four M3×8 screws. Keycaps on.

## 4. First run

```sh
cd host
pip install -e .
cp config/thirteen.example.toml thirteen.toml
# edit thirteen.toml -> serial port: /dev/ttyACM0 (Linux),
#                       /dev/cu.usbmodem* (macOS), COM3 (Windows)
thirteen-host
```

Sanity checks, in escalating order of satisfaction:

1. Enable `[adapters.demo]` in the config → bottom-row LEDs cycle colors.
2. `echo '{"agent_id":"me","state":"waiting"}' | thirteen-host` → a key
   blinks amber.
3. Wire up Claude Code hooks (`docs/adapter-guide.md`) → start a session,
   watch its key pulse violet while it thinks, blink amber when it wants
   approval, go green when done.

Then set up your key bindings and the voice talk bar:
[user-guide.md](user-guide.md).

## 5. Remapping keys

No reflash needed — the keymap lives on the device's flash filesystem and
is editable over serial. Example, make key 12 type "y\n" (approve):

```sh
python3 - <<'EOF'
import json, serial
port = "/dev/ttyACM0"           # or COM3
s = serial.Serial(port, 115200, timeout=2)
s.write(b'{"v":1,"t":"keymap_get"}\n')
km = json.loads(s.readline())["map"]
km["keys"][12] = {"type": "text", "value": "y\n"}
s.write((json.dumps({"v":1,"t":"keymap_set","map":km}) + "\n").encode())
print(s.readline().decode())    # ack
EOF
```

## Troubleshooting

| symptom | try |
|---------|-----|
| no serial port appears | different cable (data lines!), unplug/replug after first flash |
| LEDs flicker / first LED wrong color | shorten the data wire to LED 0; power chain from 3.3V; check GRB vs RGB order in `leds.cpp` |
| joystick fires ghost directions | raise `JOY_TRIGGER` in `input.cpp`; cheap modules sit off-center — TODO(hw-test) center calibration is on the roadmap |
| encoder skips detents | swap A/B pins in `pins.h`, or your EC11 is half-step — halve the accumulator threshold in `input.cpp` |
| keys double-fire | raise `DEBOUNCE_MS` in `input.cpp` (5 → 8) |
