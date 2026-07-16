#include "input.h"
#include "pins.h"

// ---- keys: 5ms integrating debounce ---------------------------------------

static constexpr uint8_t DEBOUNCE_MS = 5;
static uint8_t keyIntegrator[NUM_KEYS];   // 0..DEBOUNCE_MS
static bool keyState[NUM_KEYS];           // debounced, true = pressed
static uint32_t lastKeyScan = 0;

// ---- encoder: quadrature state machine ------------------------------------

// Full-step transition table indexed by (prevAB << 2) | AB. Rejects bounce
// (invalid transitions score 0). One detent = 4 valid quarter-steps.
static const int8_t QUAD_TABLE[16] = {
    0, -1, 1, 0,
    1, 0, 0, -1,
    -1, 0, 0, 1,
    0, 1, -1, 0,
};
static uint8_t encPrevAB;
static int8_t encAccum;       // quarter-steps toward a detent
static bool encBtnState;
static uint8_t encBtnIntegrator;

// ---- joystick --------------------------------------------------------------

// 12-bit ADC, center ~2048. Gesture fires when leaving the deadzone and
// re-arms only after returning to center — one event per flick.
// TODO(hw-test): tune thresholds for your joystick module; cheap modules
// often sit off-center by a few hundred counts.
static constexpr uint16_t JOY_CENTER = 2048;
static constexpr uint16_t JOY_TRIGGER = 1200;  // distance from center to fire
static constexpr uint16_t JOY_REARM = 400;     // distance to re-arm
static bool joyArmed = true;
static bool joySwState;
static uint8_t joySwIntegrator;

void inputInit() {
    for (uint8_t i = 0; i < NUM_KEYS; i++) {
        pinMode(KEY_PINS[i], INPUT_PULLUP);
        keyIntegrator[i] = 0;
        keyState[i] = false;
    }
    pinMode(PIN_ENC_A, INPUT_PULLUP);
    pinMode(PIN_ENC_B, INPUT_PULLUP);
    pinMode(PIN_ENC_SW, INPUT_PULLUP);
    pinMode(PIN_JOY_SW, INPUT_PULLUP);
    analogReadResolution(12);
    encPrevAB = (digitalRead(PIN_ENC_A) << 1) | digitalRead(PIN_ENC_B);
}

static void pollKeys(InputEvents& ev) {
    uint32_t now = millis();
    if (now == lastKeyScan) return;  // integrate at most once per ms
    lastKeyScan = now;

    for (uint8_t i = 0; i < NUM_KEYS; i++) {
        bool raw = digitalRead(KEY_PINS[i]) == LOW;  // active low
        if (raw && keyIntegrator[i] < DEBOUNCE_MS) keyIntegrator[i]++;
        if (!raw && keyIntegrator[i] > 0) keyIntegrator[i]--;

        if (!keyState[i] && keyIntegrator[i] == DEBOUNCE_MS) {
            keyState[i] = true;
            ev.down |= (1u << i);
        } else if (keyState[i] && keyIntegrator[i] == 0) {
            keyState[i] = false;
            ev.up |= (1u << i);
        }
    }

    // encoder push, same integrator scheme
    bool sw = digitalRead(PIN_ENC_SW) == LOW;
    if (sw && encBtnIntegrator < DEBOUNCE_MS) encBtnIntegrator++;
    if (!sw && encBtnIntegrator > 0) encBtnIntegrator--;
    if (!encBtnState && encBtnIntegrator == DEBOUNCE_MS) {
        encBtnState = true;
        ev.encBtn = 1;
    } else if (encBtnState && encBtnIntegrator == 0) {
        encBtnState = false;
        ev.encBtn = -1;
    }

    // joystick push
    bool jsw = digitalRead(PIN_JOY_SW) == LOW;
    if (jsw && joySwIntegrator < DEBOUNCE_MS) joySwIntegrator++;
    if (!jsw && joySwIntegrator > 0) joySwIntegrator--;
    if (!joySwState && joySwIntegrator == DEBOUNCE_MS) {
        joySwState = true;
        if (ev.joy == InputEvents::JoyNone) ev.joy = InputEvents::JoyPress;
    } else if (joySwState && joySwIntegrator == 0) {
        joySwState = false;
        if (ev.joy == InputEvents::JoyNone) ev.joy = InputEvents::JoyRelease;
    }
}

static void pollEncoder(InputEvents& ev) {
    // Poll fast (every loop). The table filters bounce; accumulate quarter
    // steps and emit one delta per full detent.
    uint8_t ab = (digitalRead(PIN_ENC_A) << 1) | digitalRead(PIN_ENC_B);
    int8_t step = QUAD_TABLE[(encPrevAB << 2) | ab];
    encPrevAB = ab;
    if (step == 0) return;
    encAccum += step;
    if (encAccum >= 4) {
        ev.encDelta++;
        encAccum = 0;
    } else if (encAccum <= -4) {
        ev.encDelta--;
        encAccum = 0;
    }
}

static void pollJoystick(InputEvents& ev) {
    static uint32_t lastRead = 0;
    uint32_t now = millis();
    if (now - lastRead < 10) return;  // 100 Hz is plenty
    lastRead = now;

    int16_t dx = (int16_t)analogRead(PIN_JOY_X) - JOY_CENTER;
    int16_t dy = (int16_t)analogRead(PIN_JOY_Y) - JOY_CENTER;
    uint16_t ax = abs(dx), ay = abs(dy);

    if (joyArmed) {
        if (ax >= JOY_TRIGGER || ay >= JOY_TRIGGER) {
            joyArmed = false;
            if (ev.joy == InputEvents::JoyNone) {
                if (ax > ay)
                    ev.joy = dx > 0 ? InputEvents::JoyRight : InputEvents::JoyLeft;
                else
                    ev.joy = dy > 0 ? InputEvents::JoyDown : InputEvents::JoyUp;
            }
        }
    } else if (ax < JOY_REARM && ay < JOY_REARM) {
        joyArmed = true;
    }
}

InputEvents inputPoll() {
    InputEvents ev;
    pollKeys(ev);
    pollEncoder(ev);
    pollJoystick(ev);
    return ev;
}
