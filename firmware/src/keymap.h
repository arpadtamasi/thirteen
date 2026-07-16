#pragma once

// Keymap: loaded from LittleFS (/keymap.json), editable over serial via
// keymap_set — no reflash needed to remap. Format: protocol/PROTOCOL.md.

#include <Arduino.h>
#include <ArduinoJson.h>
#include "pins.h"

enum class ActionType : uint8_t { None, Key, Text };

struct KeyAction {
    ActionType type = ActionType::None;
    uint8_t hid = 0;          // HID keycode for ActionType::Key
    uint16_t consumer = 0;    // consumer-control usage (volume etc.), 0 if none
    String text;              // for ActionType::Text
};

struct Keymap {
    KeyAction keys[NUM_KEYS];
    KeyAction encCw, encCcw, encBtn;
};

extern Keymap keymap;

// Load /keymap.json from LittleFS; falls back to F13..F24 + none defaults.
void keymapInit();

// Parse a keymap JSON object, apply it, and persist to LittleFS.
// Returns nullptr on success, or a static error string.
const char* keymapApply(JsonObjectConst map);

// Serialize the active keymap into `out` (as the "map" object).
void keymapSerialize(JsonObject out);
