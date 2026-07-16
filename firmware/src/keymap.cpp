#include "keymap.h"

#include <LittleFS.h>
#include <USBHIDKeyboard.h>
#include <USBHIDConsumerControl.h>

Keymap keymap;

static const char* KEYMAP_PATH = "/keymap.json";

struct NamedCode {
    const char* name;
    uint8_t hid;        // Arduino-style keycode for USBHIDKeyboard::press()
    uint16_t consumer;  // consumer usage, if this is a media key
};

// Arduino ESP32 core keycodes (USBHIDKeyboard.h). F13..F24 are the
// recommended defaults — no ordinary keyboard emits them.
static const NamedCode NAMED_CODES[] = {
    {"F1", KEY_F1, 0},   {"F2", KEY_F2, 0},   {"F3", KEY_F3, 0},
    {"F4", KEY_F4, 0},   {"F5", KEY_F5, 0},   {"F6", KEY_F6, 0},
    {"F7", KEY_F7, 0},   {"F8", KEY_F8, 0},   {"F9", KEY_F9, 0},
    {"F10", KEY_F10, 0}, {"F11", KEY_F11, 0}, {"F12", KEY_F12, 0},
    {"F13", KEY_F13, 0}, {"F14", KEY_F14, 0}, {"F15", KEY_F15, 0},
    {"F16", KEY_F16, 0}, {"F17", KEY_F17, 0}, {"F18", KEY_F18, 0},
    {"F19", KEY_F19, 0}, {"F20", KEY_F20, 0}, {"F21", KEY_F21, 0},
    {"F22", KEY_F22, 0}, {"F23", KEY_F23, 0}, {"F24", KEY_F24, 0},
    {"ENTER", KEY_RETURN, 0},
    {"ESC", KEY_ESC, 0},
    {"TAB", KEY_TAB, 0},
    {"SPACE", ' ', 0},
    {"BACKSPACE", KEY_BACKSPACE, 0},
    {"UP", KEY_UP_ARROW, 0},
    {"DOWN", KEY_DOWN_ARROW, 0},
    {"LEFT", KEY_LEFT_ARROW, 0},
    {"RIGHT", KEY_RIGHT_ARROW, 0},
    {"PAGE_UP", KEY_PAGE_UP, 0},
    {"PAGE_DOWN", KEY_PAGE_DOWN, 0},
    {"VOL_UP", 0, CONSUMER_CONTROL_VOLUME_INCREMENT},
    {"VOL_DOWN", 0, CONSUMER_CONTROL_VOLUME_DECREMENT},
    {"MUTE", 0, CONSUMER_CONTROL_MUTE},
};

static bool parseAction(JsonObjectConst obj, KeyAction& out) {
    out = KeyAction{};
    const char* type = obj["type"] | "none";
    if (strcmp(type, "none") == 0) {
        out.type = ActionType::None;
        return true;
    }
    if (strcmp(type, "text") == 0) {
        const char* v = obj["value"] | "";
        out.type = ActionType::Text;
        out.text = v;
        return true;
    }
    if (strcmp(type, "key") == 0) {
        const char* code = obj["code"] | "";
        for (const auto& nc : NAMED_CODES) {
            if (strcmp(code, nc.name) == 0) {
                out.type = ActionType::Key;
                out.hid = nc.hid;
                out.consumer = nc.consumer;
                return true;
            }
        }
        // single printable ASCII character
        if (strlen(code) == 1 && code[0] >= 0x20 && code[0] < 0x7F) {
            out.type = ActionType::Key;
            out.hid = (uint8_t)code[0];
            return true;
        }
        return false;
    }
    return false;
}

static void serializeAction(const KeyAction& a, JsonObject out) {
    switch (a.type) {
        case ActionType::None:
            out["type"] = "none";
            break;
        case ActionType::Text:
            out["type"] = "text";
            out["value"] = a.text;
            break;
        case ActionType::Key: {
            out["type"] = "key";
            for (const auto& nc : NAMED_CODES) {
                if ((nc.hid && nc.hid == a.hid) ||
                    (nc.consumer && nc.consumer == a.consumer)) {
                    out["code"] = nc.name;
                    return;
                }
            }
            char buf[2] = {(char)a.hid, 0};
            out["code"] = buf;
            break;
        }
    }
}

const char* keymapApply(JsonObjectConst map) {
    JsonArrayConst keys = map["keys"];
    if (keys.isNull() || keys.size() != NUM_KEYS)
        return "map.keys must be an array of 13 entries";

    Keymap next;
    uint8_t i = 0;
    for (JsonObjectConst k : keys) {
        if (!parseAction(k, next.keys[i]))
            return "bad key code";
        i++;
    }
    JsonObjectConst enc = map["enc"];
    if (!enc.isNull()) {
        if (!parseAction(enc["cw"], next.encCw) ||
            !parseAction(enc["ccw"], next.encCcw) ||
            !parseAction(enc["btn"], next.encBtn))
            return "bad enc code";
    }
    keymap = next;

    // persist
    File f = LittleFS.open(KEYMAP_PATH, "w");
    if (!f) return "fs write failed";
    JsonDocument doc;
    keymapSerialize(doc.to<JsonObject>());
    serializeJson(doc, f);
    f.close();
    return nullptr;
}

void keymapSerialize(JsonObject out) {
    JsonArray keys = out["keys"].to<JsonArray>();
    for (uint8_t i = 0; i < NUM_KEYS; i++)
        serializeAction(keymap.keys[i], keys.add<JsonObject>());
    JsonObject enc = out["enc"].to<JsonObject>();
    serializeAction(keymap.encCw, enc["cw"].to<JsonObject>());
    serializeAction(keymap.encCcw, enc["ccw"].to<JsonObject>());
    serializeAction(keymap.encBtn, enc["btn"].to<JsonObject>());
}

static void loadDefaults() {
    // F13..F24 cover keys 0-11; key 12 defaults to "none" (serial event
    // only) since HID only has twelve extended function keys.
    static const char* defs[NUM_KEYS] = {
        "F13", "F14", "F15", "F16", "F17", "F18", "F19",
        "F20", "F21", "F22", "F23", "F24", nullptr,
    };
    for (uint8_t i = 0; i < NUM_KEYS; i++) {
        keymap.keys[i] = KeyAction{};
        if (defs[i]) {
            for (const auto& nc : NAMED_CODES) {
                if (strcmp(defs[i], nc.name) == 0) {
                    keymap.keys[i].type = ActionType::Key;
                    keymap.keys[i].hid = nc.hid;
                    break;
                }
            }
        }
    }
    keymap.encCw = keymap.encCcw = keymap.encBtn = KeyAction{};
}

void keymapInit() {
    loadDefaults();
    File f = LittleFS.open(KEYMAP_PATH, "r");
    if (!f) return;  // first boot: defaults stay active
    JsonDocument doc;
    if (deserializeJson(doc, f) == DeserializationError::Ok) {
        // Apply without re-persisting (file already on flash): parse in place.
        JsonObjectConst map = doc.as<JsonObjectConst>();
        JsonArrayConst keys = map["keys"];
        if (!keys.isNull() && keys.size() == NUM_KEYS) {
            uint8_t i = 0;
            for (JsonObjectConst k : keys) {
                KeyAction a;
                if (parseAction(k, a)) keymap.keys[i] = a;
                i++;
            }
            JsonObjectConst enc = map["enc"];
            if (!enc.isNull()) {
                parseAction(enc["cw"], keymap.encCw);
                parseAction(enc["ccw"], keymap.encCcw);
                parseAction(enc["btn"], keymap.encBtn);
            }
        }
    }
    f.close();
}
