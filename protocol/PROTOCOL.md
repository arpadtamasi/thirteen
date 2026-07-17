# thirteen serial protocol — v1

Newline-delimited JSON (NDJSON) over USB CDC serial, **115200 baud**, UTF-8.
One JSON object per line, terminated by `\n`. No line may exceed 1024 bytes
(a full `keymap_set` with text macros approaches this; keep macros short).

Every message carries a version field `"v": 1`. Receivers MUST ignore
messages with a higher major version than they support, and MUST ignore
unknown fields (forward compatibility).

Message type is in `"t"`.

## Transport

- The device enumerates as a USB composite device: HID keyboard + CDC serial.
- The HID interface types keystrokes directly (no host software needed for
  basic macro use). The CDC interface carries this protocol.
- On (re)connect the device sends `hello`. The host SHOULD wait for `hello`
  (or send `ping`) before assuming the link is up.

## Host → Device

### `ping`

```json
{"v": 1, "t": "ping"}
```

Device replies with `pong`.

### `led` — set the state of one key LED (or all)

```json
{"v": 1, "t": "led", "key": 4, "color": "#00FF88", "mode": "pulse"}
```

| field   | type   | notes                                              |
|---------|--------|----------------------------------------------------|
| `key`   | int    | 0–12 = key LEDs, 13–18 = edge-glow segments, `-1` = every LED, `-2` = the edge ring as a group |
| `color` | string | `#RRGGBB` hex                                       |
| `mode`  | string | `"solid"`, `"pulse"` (slow breathe), `"blink"` (hard on/off), `"off"` |

Device replies with `ack`.

### `keymap_set` — replace the stored keymap

```json
{"v": 1, "t": "keymap_set", "map": {"keys": [{"type": "key", "code": "F13"}, ...]}}
```

The `map` object is persisted to LittleFS (`/keymap.json`) and applied
immediately — no reflash required. See **Keymap format** below.
Device replies with `ack` (with `"ok": false` and an `"err"` string if the
map fails validation).

### `keymap_get` — read the current keymap

```json
{"v": 1, "t": "keymap_get"}
```

Device replies with `{"v": 1, "t": "keymap", "map": {...}}`.

## Device → Host

### `hello` — sent once on boot / USB reconnect

```json
{"v": 1, "t": "hello", "fw": "0.1.0", "proto": 1, "keys": 13, "edge": 6}
```

`edge` is the number of edge-glow LEDs after the key LEDs on the chain
(0 if the build has none).

### `key` — key press / release

```json
{"v": 1, "t": "key", "key": 7, "act": "down"}
```

`act` is `"down"` or `"up"`. Sent **in addition to** any HID output the
keymap produces for that key; keys mapped as `"none"` produce only this
event.

### `enc` — rotary encoder rotation

```json
{"v": 1, "t": "enc", "delta": 1}
```

`delta` is a signed integer: positive = clockwise. Multiple detents within
one poll interval are coalesced.

### `enc_btn` — encoder push

```json
{"v": 1, "t": "enc_btn", "act": "down"}
```

### `joy` — joystick gesture

```json
{"v": 1, "t": "joy", "dir": "up"}
```

`dir` is one of `"up"`, `"down"`, `"left"`, `"right"` (emitted once when the
stick leaves the deadzone in that direction; re-armed when it returns to
center) or `"press"` / `"release"` for the stick button.

### `ack`

```json
{"v": 1, "t": "ack", "of": "led", "ok": true}
{"v": 1, "t": "ack", "of": "keymap_set", "ok": false, "err": "bad key code"}
```

### `pong`

```json
{"v": 1, "t": "pong", "fw": "0.1.0", "proto": 1}
```

## Keymap format

The keymap is a JSON object stored on the device at `/keymap.json`:

```json
{
  "keys": [
    {"type": "key",  "code": "F13"},
    {"type": "key",  "code": "ENTER"},
    {"type": "text", "value": "yes\n"},
    {"type": "none"},
    ...13 entries total...
  ],
  "enc": {"cw": {"type": "key", "code": "VOL_UP"},
          "ccw": {"type": "key", "code": "VOL_DOWN"},
          "btn": {"type": "none"}}
}
```

Entry types:

| type   | fields  | behaviour                                            |
|--------|---------|------------------------------------------------------|
| `key`  | `code`  | sends a single HID keycode (see codes below)         |
| `text` | `value` | types the string verbatim (`\n` allowed)             |
| `none` | —       | no HID output; the serial event is still emitted     |

Recognised `code` values: `F1`–`F24`, `ENTER`, `ESC`, `TAB`, `SPACE`,
`BACKSPACE`, `UP`, `DOWN`, `LEFT`, `RIGHT`, `PAGE_UP`, `PAGE_DOWN`,
`VOL_UP`, `VOL_DOWN`, `MUTE`, and any single ASCII character (`"y"`, `"1"`).

`F13`–`F24` are the recommended defaults: real HID codes that no ordinary
keyboard emits, so they are safe to bind globally on the host side.

## Versioning

- `proto` in `hello`/`pong` is the protocol major version implemented by the
  firmware.
- Additive changes (new fields, new message types) do not bump the version.
- Breaking changes bump `v`/`proto`; a host seeing a higher `proto` than it
  knows SHOULD warn and fall back to `ping`/`key` events only.
