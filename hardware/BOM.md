# Bill of materials

Rough EU street prices, July 2026. Total lands around **€30** — roughly an
eighth of a Codex Micro, plus you own the firmware.

| # | part | qty | ~price (EU) | notes |
|---|------|-----|-------------|-------|
| 1 | ESP32-S3 SuperMini | 1 | €5–8 | The tiny (~22×18mm) S3 board. Any ESP32-S3 board with native USB works; the DevKitC-1 is the firmware's default env. |
| 2 | Kailh Choc v1 switch | 13 | €6–9 | Low-profile, hot-swappable feel without a hotswap socket if you solder direct. Pick your weight; linear "Red Pro" (35g) suits rapid approvals. |
| 3 | Choc keycaps (MBK or similar) | 13 | €5–8 | Or 3D-print them. One contrasting cap for the "approve" key is worth it. |
| 4 | SK6812 MINI-E RGB LED | 13 | €2–4 | The MINI-E's legs stick out sideways — hand-solderable under each switch. Buy a few spares; they don't love hot-air rework. |
| 5 | EC11 rotary encoder (with push) | 1 | €1–2 | 15mm shaft + a knob you like. |
| 6 | 2-axis analog joystick module | 1 | €1–3 | KY-023-style thumbstick module with X/Y pots and a push switch. |
| 7 | M3 heat-set inserts | 4–6 | €1 | For the case; M3×5×4 short type. |
| 8 | M3×8 screws | 4–6 | €0.50 | |
| 9 | Hookup wire (30 AWG) | — | €2 | Handwired build: no PCB needed. |
| 10 | USB-C cable | 1 | — | You have one. |

**Total: ~€25–35**

Typical EU sources: splitkb.com, mykeyboard.eu, keycapsss.com (switches,
caps, LEDs); any electronics distributor or marketplace for the rest.

## Substitutions

- **MX switches instead of Choc**: fine — enlarge the plate cutouts to
  14.0mm and the switch spacing to 19.05mm in the OpenSCAD parameters.
- **SK6812 MINI (not -E) or WS2812B 3535**: same protocol, harder to
  hand-solder (pads under the body).
- **PSP-style joystick**: works, needs its own breakout and mounting tweak.
- **ESP32-S3-DevKitC-1**: bigger, but has all pins and is the default
  firmware env. Case is sized for the SuperMini; adjust `mcu_*` parameters.
