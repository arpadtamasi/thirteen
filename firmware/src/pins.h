#pragma once

// Pin assignment — ESP32-S3-DevKitC-1 (default) and SuperMini override.
// 13 keys on direct GPIO (internal pull-ups, switch to GND — no matrix,
// no diodes). See hardware/WIRING.md for the physical layout.

#include <cstdint>

constexpr uint8_t NUM_KEYS = 13;
// SK6812 chain: one LED per key (0-12), then the edge-glow ring LEDs
// around the case rim (13..). Edge LEDs are addressed via the protocol
// as indexes 13-18, or -2 for the whole ring.
constexpr uint8_t NUM_EDGE_LEDS = 6;
constexpr uint8_t NUM_LEDS = NUM_KEYS + NUM_EDGE_LEDS;

#ifdef SUPERMINI
// ESP32-S3 SuperMini: fewer pins broken out. GPIO 33-37 are not available
// (used by internal flash/PSRAM on most SuperMini modules); 43/44 are the
// UART0 pads. This mapping uses only pins present on the common SuperMini
// pinout. TODO(hw-test): verify against your specific SuperMini clone —
// pinouts vary between sellers.
constexpr uint8_t KEY_PINS[NUM_KEYS] = {
    1, 2, 3, 4, 5,        // K0-K1 top band, K2-K4 agent row
    6, 7, 8, 9, 10,       // K5 agent row, K6-K9 command row
    11, 12, 13            // K10-K12 bottom row (K11 = talk bar)
};
constexpr uint8_t PIN_LED_DATA = 14;   // SK6812 chain data-in
constexpr uint8_t PIN_ENC_A    = 21;
constexpr uint8_t PIN_ENC_B    = 47;
constexpr uint8_t PIN_ENC_SW   = 48;
constexpr uint8_t PIN_JOY_X    = 15;   // must be ADC-capable
constexpr uint8_t PIN_JOY_Y    = 16;   // must be ADC-capable
constexpr uint8_t PIN_JOY_SW   = 17;
#else
// ESP32-S3-DevKitC-1. Avoids strapping pins (0, 3, 45, 46) and the pins
// used by octal PSRAM on the N8R8 variant (35, 36, 37).
constexpr uint8_t KEY_PINS[NUM_KEYS] = {
    4, 5, 6, 7, 15,       // K0-K1 top band, K2-K4 agent row
    16, 17, 18, 21, 38,   // K5 agent row, K6-K9 command row
    39, 40, 41            // K10-K12 bottom row (K11 = talk bar)
};
constexpr uint8_t PIN_LED_DATA = 47;   // SK6812 chain data-in
constexpr uint8_t PIN_ENC_A    = 1;
constexpr uint8_t PIN_ENC_B    = 2;
constexpr uint8_t PIN_ENC_SW   = 42;
constexpr uint8_t PIN_JOY_X    = 9;    // ADC1_CH8
constexpr uint8_t PIN_JOY_Y    = 10;   // ADC1_CH9
constexpr uint8_t PIN_JOY_SW   = 11;
#endif
