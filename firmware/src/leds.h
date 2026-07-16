#pragma once

// Per-key SK6812 mini LED chain, one LED per key, driven by FastLED.
// Modes: solid, pulse (breathe), blink (hard on/off), off.

#include <Arduino.h>

enum class LedMode : uint8_t { Off, Solid, Pulse, Blink };

void ledsInit();
// key: 0..NUM_KEYS-1, or -1 for all.
void ledsSet(int key, uint32_t rgb, LedMode mode);
// Call every loop; renders pulse/blink animation, throttled internally.
void ledsTick();
