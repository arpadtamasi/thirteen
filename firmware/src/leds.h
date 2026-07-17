#pragma once

// SK6812 mini LED chain driven by FastLED: one LED per key (0-12) plus
// the edge-glow ring (13..NUM_LEDS-1) diffusing through the case rim.
// Modes: solid, pulse (breathe), blink (hard on/off), off.

#include <Arduino.h>

enum class LedMode : uint8_t { Off, Solid, Pulse, Blink };

void ledsInit();
// key: 0..NUM_LEDS-1 for a single LED, -1 for all, -2 for the edge ring.
void ledsSet(int key, uint32_t rgb, LedMode mode);
// Call every loop; renders pulse/blink animation, throttled internally.
void ledsTick();
