# thirteen firmware

PlatformIO project for the ESP32-S3. Builds a USB composite device:
HID keyboard + CDC serial.

## Build & flash

```sh
pio run                          # build (default env: esp32-s3-devkitc-1)
pio run -t upload                # flash over USB
pio run -t uploadfs              # upload data/keymap.json to LittleFS
pio device monitor               # watch the NDJSON event stream
```

For an ESP32-S3 SuperMini board:

```sh
pio run -e supermini -t upload
```

The SuperMini has fewer pins broken out; its pin mapping lives in
`src/pins.h` behind the `SUPERMINI` define. Check it against your specific
board — SuperMini clones vary.

If the board doesn't enumerate after flashing, unplug/replug USB (switching
to the TinyUSB stack requires a cold restart of the USB connection).

## Layout

| file          | what                                            |
|---------------|--------------------------------------------------|
| `src/main.cpp`| entry point, serial protocol, HID output         |
| `src/pins.h`  | GPIO assignment (both boards)                    |
| `src/input.*` | key debounce, EC11 decode, joystick gestures     |
| `src/leds.*`  | SK6812 chain, solid/pulse/blink modes            |
| `src/keymap.*`| LittleFS-persisted keymap, editable over serial  |
| `data/`       | default keymap shipped to LittleFS via uploadfs  |
