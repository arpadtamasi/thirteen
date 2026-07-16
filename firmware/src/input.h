#pragma once

// Direct-GPIO key scanning with per-key debounce, EC11 quadrature decoding,
// and analog joystick gesture detection.

#include <Arduino.h>

struct InputEvents {
    // key events this tick: bit set in `down`/`up` per key index
    uint16_t down = 0;
    uint16_t up = 0;
    int8_t encDelta = 0;        // detents this tick, +cw / -ccw
    int8_t encBtn = 0;          // +1 down, -1 up, 0 none
    // joystick: one-shot direction gesture, or press/release
    enum Joy : uint8_t { JoyNone, JoyUp, JoyDown, JoyLeft, JoyRight,
                         JoyPress, JoyRelease };
    Joy joy = JoyNone;
};

void inputInit();
InputEvents inputPoll();
