#include "leds.h"

#include <FastLED.h>
#include "pins.h"

// SK6812 mini-e is an RGB part speaking the WS2812 protocol at GRB order.
// (The RGBW variant exists — if yours is RGBW, switch the chipset to SK6812
// in the FastLED.addLeds call and handle the W channel.)

static CRGB leds[NUM_KEYS];
static uint32_t baseColor[NUM_KEYS];
static LedMode mode[NUM_KEYS];

static constexpr uint8_t FRAME_MS = 16;       // ~60 fps
static constexpr uint16_t PULSE_PERIOD = 2000; // ms per breathe cycle
static constexpr uint16_t BLINK_PERIOD = 500;  // ms per on/off half-cycle

void ledsInit() {
    FastLED.addLeds<WS2812B, PIN_LED_DATA, GRB>(leds, NUM_KEYS);
    FastLED.setBrightness(96);  // SK6812 mini-e at full white pulls ~10mA/ch
    for (uint8_t i = 0; i < NUM_KEYS; i++) {
        baseColor[i] = 0;
        mode[i] = LedMode::Off;
    }
    FastLED.clear(true);
}

void ledsSet(int key, uint32_t rgb, LedMode m) {
    if (key < 0) {
        for (uint8_t i = 0; i < NUM_KEYS; i++) {
            baseColor[i] = rgb;
            mode[i] = m;
        }
    } else if (key < NUM_KEYS) {
        baseColor[key] = rgb;
        mode[key] = m;
    }
}

void ledsTick() {
    static uint32_t lastFrame = 0;
    uint32_t now = millis();
    if (now - lastFrame < FRAME_MS) return;
    lastFrame = now;

    for (uint8_t i = 0; i < NUM_KEYS; i++) {
        CRGB c = CRGB(baseColor[i]);
        switch (mode[i]) {
            case LedMode::Off:
                c = CRGB::Black;
                break;
            case LedMode::Solid:
                break;
            case LedMode::Pulse: {
                // triangle wave 0..255..0 over PULSE_PERIOD, eased by scale8
                uint16_t phase = now % PULSE_PERIOD;
                uint8_t level = (phase < PULSE_PERIOD / 2)
                    ? phase * 255 / (PULSE_PERIOD / 2)
                    : 255 - (phase - PULSE_PERIOD / 2) * 255 / (PULSE_PERIOD / 2);
                c.nscale8_video(ease8InOutQuad(level));
                break;
            }
            case LedMode::Blink:
                if ((now / BLINK_PERIOD) & 1) c = CRGB::Black;
                break;
        }
        leds[i] = c;
    }
    FastLED.show();
}
