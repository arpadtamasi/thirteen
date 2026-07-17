# Bill of materials

Rough EU street prices, July 2026. Total lands around **€30** — roughly an
eighth of a Codex Micro, plus you own the firmware.

| # | part | qty | ~price (EU) | notes |
|---|------|-----|-------------|-------|
| 1 | ESP32-S3 SuperMini | 1 | €5–8 | The tiny (~22×18mm) S3 board. Any ESP32-S3 board with native USB works; the DevKitC-1 is the firmware's default env. |
| 2 | Kailh Choc v1 switch | 13 | €6–9 | Low-profile, hot-swappable feel without a hotswap socket if you solder direct. Pick your weight; linear "Red Pro" (35g) suits rapid approvals. |
| 3 | Choc keycaps (MBK or similar) | 12× 1u + 1× 2u | €5–8 | The 2u goes on the talk bar (no stabilizer needed at this size). Or 3D-print them. One contrasting cap for the "approve" key is worth it. |
| 4 | SK6812 MINI-E RGB LED | 19 | €3–5 | 13 under the keys + 6 for the edge-glow ring. The MINI-E's legs stick out sideways — hand-solderable. Buy spares; they don't love hot-air rework. |
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

## Where to buy

Direct product pages (EU-friendly):

- Kailh Choc v1 switches: [splitkb.com](https://splitkb.com/products/kailh-low-profile-choc-switches)
- MBK Choc keycaps: [fkcaps.com](https://fkcaps.com/keycaps/mbk), [splitkb.com keycaps](https://splitkb.com/collections/switches-and-keycaps)
- SK6812 MINI-E: [splitkb.com](https://splitkb.com/products/sk6812mini-e-rgb-leds), [keycapsss.com](https://keycapsss.com/keyboard-parts/parts/114/sk6812-mini-e-rgb-smd-led)
- ESP32-S3 SuperMini, EC11, joystick module, inserts, screws, wire:
  any electronics marketplace or distributor — search "ESP32-S3 SuperMini",
  "EC11 rotary encoder", "KY-023 joystick", "M3 heat-set insert".

## Agent shopping prompt

Copy-paste this into any AI assistant with web browsing and let it fill
your cart. The three classic ordering mistakes (Choc v2, RGBW LEDs, an
ESP32-**C3** instead of S3) are guarded against in the item notes.

```text
Help me buy the parts for a DIY macropad
(project: https://github.com/arpadtamasi/thirteen).
I'm in the EU — prefer EU shops for the keyboard parts (splitkb.com,
mykeyboard.eu, keycapsss.com); a marketplace like AliExpress is fine for
the generic electronics. Target total: EUR 25-40. For each item find the
exact product page, check stock, and give me the final cart list with
prices and shipping.

1. Kailh Choc v1 low-profile switches, LINEAR, ~35-50g — qty 13
   (must be Choc v1 / PG1350, NOT Choc v2, NOT KS-33)
2. MBK-profile Choc keycaps, blank — qty 12 in 1u plus ONE 2u (for the
   talk bar), any dark color + 1 accent color if available (must be
   Choc v1 stem, NOT MX)
3. SK6812 MINI-E RGB LEDs — qty 25 (19 + spares).
   CRITICAL: the RGB version, NOT the RGBW variant, and MINI-E (with side
   legs), not the plain MINI.
4. ESP32-S3 SuperMini dev board — qty 1. Must be ESP32-S3 (not C3/C6/H2!),
   USB-C, with native USB. Prefer a listing that shows the pinout diagram.
5. EC11 rotary encoder with push button, 15-20mm shaft — qty 1, plus one
   knurled aluminum knob for 6mm D-shaft
6. Dual-axis analog thumb joystick module (KY-023 style, 2 pots + switch,
   5-pin) — qty 1
7. M3 heat-set threaded inserts, M3x5mm, OD ~4.5mm — qty 10 (need 6)
8. M3x8mm socket head screws — qty 10
9. 30 AWG silicone-insulated hookup wire, 3+ colors — 1 small spool set

Flag anything where the listing is ambiguous about the variant (especially
items 1, 3, 4) instead of guessing.
```
