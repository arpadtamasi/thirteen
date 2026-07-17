// thirteen — firmware entry point.
//
// USB composite device: HID keyboard + CDC serial. Keys produce HID output
// according to the LittleFS keymap AND emit NDJSON events over CDC; the
// host daemon drives the per-key RGB LEDs. Protocol: protocol/PROTOCOL.md.

#include <Arduino.h>
#include <ArduinoJson.h>
#include <LittleFS.h>
#include <USB.h>
#include <USBHIDKeyboard.h>
#include <USBHIDConsumerControl.h>

#include "pins.h"
#include "keymap.h"
#include "leds.h"
#include "input.h"

#ifndef THIRTEEN_FW_VERSION
#define THIRTEEN_FW_VERSION "0.0.0-dev"
#endif
static constexpr int PROTO_VERSION = 1;

static USBHIDKeyboard Keyboard;
static USBHIDConsumerControl Consumer;

// ---- serial out ------------------------------------------------------------

static void sendJson(JsonDocument& doc) {
    doc["v"] = PROTO_VERSION;
    serializeJson(doc, Serial);
    Serial.print('\n');
}

static void sendHello() {
    JsonDocument doc;
    doc["t"] = "hello";
    doc["fw"] = THIRTEEN_FW_VERSION;
    doc["proto"] = PROTO_VERSION;
    doc["keys"] = NUM_KEYS;
    doc["edge"] = NUM_EDGE_LEDS;
    sendJson(doc);
}

static void sendAck(const char* of, const char* err = nullptr) {
    JsonDocument doc;
    doc["t"] = "ack";
    doc["of"] = of;
    doc["ok"] = (err == nullptr);
    if (err) doc["err"] = err;
    sendJson(doc);
}

static void sendKeyEvent(uint8_t key, bool down) {
    JsonDocument doc;
    doc["t"] = "key";
    doc["key"] = key;
    doc["act"] = down ? "down" : "up";
    sendJson(doc);
}

// ---- HID output ------------------------------------------------------------

static void hidPress(const KeyAction& a) {
    switch (a.type) {
        case ActionType::None:
            break;
        case ActionType::Key:
            if (a.consumer) {
                Consumer.press(a.consumer);
                Consumer.release();
            } else {
                Keyboard.press(a.hid);
            }
            break;
        case ActionType::Text:
            Keyboard.print(a.text);
            break;
    }
}

static void hidRelease(const KeyAction& a) {
    if (a.type == ActionType::Key && !a.consumer) Keyboard.release(a.hid);
}

static void hidTap(const KeyAction& a) {
    hidPress(a);
    hidRelease(a);
}

// ---- host -> device commands ------------------------------------------------

static uint32_t parseHexColor(const char* s) {
    if (!s || s[0] != '#' || strlen(s) != 7) return 0;
    return (uint32_t)strtoul(s + 1, nullptr, 16);
}

static void handleLine(char* line) {
    JsonDocument doc;
    if (deserializeJson(doc, line) != DeserializationError::Ok) return;
    const char* t = doc["t"] | "";

    if (strcmp(t, "ping") == 0) {
        JsonDocument out;
        out["t"] = "pong";
        out["fw"] = THIRTEEN_FW_VERSION;
        out["proto"] = PROTO_VERSION;
        sendJson(out);

    } else if (strcmp(t, "led") == 0) {
        int key = doc["key"] | -1;
        uint32_t rgb = parseHexColor(doc["color"] | "#000000");
        const char* m = doc["mode"] | "solid";
        LedMode mode = LedMode::Solid;
        if (strcmp(m, "pulse") == 0) mode = LedMode::Pulse;
        else if (strcmp(m, "blink") == 0) mode = LedMode::Blink;
        else if (strcmp(m, "off") == 0) mode = LedMode::Off;
        if (key >= NUM_LEDS || key < -2) {
            sendAck("led", "key out of range");
        } else {
            ledsSet(key, rgb, mode);
            sendAck("led");
        }

    } else if (strcmp(t, "keymap_set") == 0) {
        JsonObjectConst map = doc["map"];
        if (map.isNull()) {
            sendAck("keymap_set", "missing map");
        } else {
            const char* err = keymapApply(map);
            sendAck("keymap_set", err);
        }

    } else if (strcmp(t, "keymap_get") == 0) {
        JsonDocument out;
        out["t"] = "keymap";
        keymapSerialize(out["map"].to<JsonObject>());
        sendJson(out);
    }
    // unknown types are ignored (forward compatibility)
}

static void pollSerial() {
    static char buf[1024];  // must fit a full keymap_set line
    static size_t len = 0;
    while (Serial.available()) {
        char c = Serial.read();
        if (c == '\n') {
            buf[len] = 0;
            if (len > 0) handleLine(buf);
            len = 0;
        } else if (len < sizeof(buf) - 1) {
            buf[len++] = c;
        } else {
            len = 0;  // line too long: drop it
        }
    }
}

// ---- main ------------------------------------------------------------------

void setup() {
    Serial.begin(115200);
    Keyboard.begin();
    Consumer.begin();
    USB.begin();

    LittleFS.begin(true);  // format on first boot
    keymapInit();
    ledsInit();
    inputInit();

    // brief boot animation so a fresh build shows signs of life
    ledsSet(-1, 0x202020, LedMode::Pulse);

    delay(100);
    sendHello();
}

void loop() {
    InputEvents ev = inputPoll();

    for (uint8_t i = 0; i < NUM_KEYS; i++) {
        if (ev.down & (1u << i)) {
            hidPress(keymap.keys[i]);
            sendKeyEvent(i, true);
        }
        if (ev.up & (1u << i)) {
            hidRelease(keymap.keys[i]);
            sendKeyEvent(i, false);
        }
    }

    if (ev.encDelta != 0) {
        hidTap(ev.encDelta > 0 ? keymap.encCw : keymap.encCcw);
        JsonDocument doc;
        doc["t"] = "enc";
        doc["delta"] = ev.encDelta;
        sendJson(doc);
    }

    if (ev.encBtn != 0) {
        if (ev.encBtn > 0) hidPress(keymap.encBtn);
        else hidRelease(keymap.encBtn);
        JsonDocument doc;
        doc["t"] = "enc_btn";
        doc["act"] = ev.encBtn > 0 ? "down" : "up";
        sendJson(doc);
    }

    if (ev.joy != InputEvents::JoyNone) {
        static const char* dirs[] = {"", "up", "down", "left", "right",
                                     "press", "release"};
        JsonDocument doc;
        doc["t"] = "joy";
        doc["dir"] = dirs[ev.joy];
        sendJson(doc);
    }

    pollSerial();
    ledsTick();
}
