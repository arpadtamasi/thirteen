# Wiring

Handwired, no PCB, no matrix, no diodes: 13 switches each go straight to a
GPIO (internal pull-up) and to a shared ground. The SK6812 LEDs form one
data chain. Everything runs off USB 5V; GPIO logic is 3.3V.

SK6812 note: the chain wants 5V supply, and its data-in officially wants
0.7×VDD = 3.5V — in practice 3.3V data into the first LED works reliably at
this scale. If your first LED glitches, power the chain from 3.3V instead,
or put a single 1N4148 in series with the 5V feed to drop it.

## GPIO assignment — ESP32-S3-DevKitC-1 (default firmware env)

| signal | GPIO | notes |
|--------|------|-------|
| K0–K1 (top band) + K2–K4 | 4, 5, 6, 7, 15 | switch → GPIO, other leg → GND |
| K5 + K6–K9 (command row) | 16, 17, 18, 21, 38 | |
| K10–K12 (bottom row, K11 = talk bar) | 39, 40, 41 | |
| LED data | 47 | → DIN of first SK6812; chain: 13 key LEDs, then 6 edge LEDs |
| Encoder A | 1 | EC11 A |
| Encoder B | 2 | EC11 B |
| Encoder push | 42 | EC11 switch pins |
| Joystick X | 9 | ADC1_CH8, module VRx |
| Joystick Y | 10 | ADC1_CH9, module VRy |
| Joystick push | 11 | module SW |

Strapping pins (0, 3, 45, 46) and octal-PSRAM pins (35–37) are deliberately
unused.

## GPIO assignment — ESP32-S3 SuperMini (`-e supermini`)

| signal | GPIO |
|--------|------|
| K0–K4 | 1, 2, 3, 4, 5 |
| K5–K9 | 6, 7, 8, 9, 10 |
| K10–K12 | 11, 12, 13 |
| LED data | 14 |
| Encoder A / B / push | 21 / 47 / 48 |
| Joystick X / Y / push | 15 / 16 / 17 |

TODO(hw-test): SuperMini clones differ in which pins reach the headers —
verify against your board before soldering, and adjust `firmware/src/pins.h`
if needed.

## ASCII wiring diagram

```
                      ESP32-S3
                 ┌───────────────┐
   USB-C ═══════▶│ USB D+/D-     │
                 │               │
  K0 ─┬─ GPIO4   │               │   GPIO47 ──▶ DIN ┌──────┐DOUT
  K1 ─┼─ GPIO5   │               │                  │SK6812│──▶ ...19 LEDs,
  ... ┼          │  13 direct    │                  │ #0   │    one under
 K12 ─┴─ GPIO41  │  GPIOs, all   │                  └──────┘    each key
   │             │  INPUT_PULLUP │                   5V│ │GND
  GND (shared)   │               │
                 │               │        EC11        joystick
                 │        GPIO1 ─┼──────── A          module
                 │        GPIO2 ─┼──────── B          ┌─────┐
                 │       GPIO42 ─┼──────── SW    ┌────┤ VRx │ GPIO9
                 │               │               │ ┌──┤ VRy │ GPIO10
                 │        GPIO9 ─┼───────────────┘ │  │ SW  │ GPIO11
                 │       GPIO10 ─┼─────────────────┘  │ 5V* │
                 │       GPIO11 ─┼────────────────────┤ GND │
                 └───────────────┘                    └─────┘

  * power the joystick module from 3.3V, not 5V — its pots feed the ADC
    directly and the S3's ADC pins are not 5V-tolerant.

  Switch wiring:  GPIO ──[switch]── GND      (no diode needed: one pin
                                              per key, nothing to ghost)
  LED chain:      5V ──┬── all SK6812 VDD
                  GND ─┴── all SK6812 GND    data chained K0→K12,
                                              then 6 edge LEDs
```

## Joystick module footprint

TODO(hw-test): a KY-023 breakout board (~26×34mm) is larger than the
top-right corner it mounts under. Options: rotate the board diagonally,
trim its corners, or desolder the stick and mount it bare on perfboard.
The plate opening only cares about the stick itself (24mm clearance).

## LED chain order

19 LEDs on one chain: key LEDs K0→K12 first (indexes 0–12), then the six
edge-glow LEDs (indexes 13–18) mounted face-down or face-out around the
shell perimeter, shining into the translucent bottom rim. Print the shell
(or just its bottom band) in translucent filament to get the diffused
edge glow; skip the 6 LEDs entirely and the pad still works — the ring
just stays dark.

## Soldering order

See `docs/build-guide.md` — LEDs first (they sit under the switches), then
switches, then the controller.
