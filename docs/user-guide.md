# User guide

What every control does, how to wire the keys into your OS, and how to
talk to your agents through the pad. For assembly see
[build-guide.md](build-guide.md); for writing adapters see
[adapter-guide.md](adapter-guide.md).

## The controls

```
 ┌────────────────────────────────┐
 │ (knob)   [•] [••]   (joystick) │   top band
 │   [•3] [•4] [•5] [•6]          │   agent keys 3-6
 │   [✓]  [✗]  [▶]  [⏸]           │   command row
 │   [◀] [   🎤 talk   ] [○]      │   bottom row
 └────────────────────────────────┘
        edge-glow rim all around
```

| control | index | default HID output | intended use |
|---------|-------|--------------------|--------------|
| agent keys | K0–K5 | F13–F18 | one per agent session; LED = its state, press = act on it |
| ✓ approve | K6 | F19 | approve / confirm |
| ✗ reject | K7 | F20 | reject / cancel |
| ▶ run | K8 | F21 | continue / resume |
| ⏸ pause | K9 | F22 | interrupt / stop |
| ◀ prev | K10 | F23 | previous item / undo-ish |
| 🎤 talk bar | K11 | F24 | push-to-talk → your dictation tool |
| ○ clear | K12 | none (serial only) | clears finished sessions (daemon binding) |
| encoder | — | volume up/down, push = mute | scroll history, or rebind |
| joystick | — | serial events only | direction: navigate; press: select |

Everything above is remappable: the HID side over serial
(`protocol/PROTOCOL.md`, no reflash), the action side in `thirteen.toml`.

## LED states

| color | mode | meaning |
|-------|------|---------|
| violet | pulse | agent is thinking |
| blue | pulse | agent is running tools |
| **amber** | **blink** | **agent is waiting for YOU** |
| green | solid | done |
| red | blink | error |

The translucent **edge rim** always shows the most attention-worthy state
across all agents (error > waiting > running > thinking > done) — the
"do I need to look?" signal that works from across the room.

## Wiring the keys into your OS

The pad types F13–F24 — real keycodes no normal keyboard emits, so you can
bind them globally without collisions. The daemon does **not** need to run
for any of this; it's plain USB keyboard input.

### Terminal (tmux) — the classic Claude Code setup

```tmux
# ~/.tmux.conf — approve / reject / continue / interrupt from the pad
bind-key -n F19 send-keys y Enter      # ✓
bind-key -n F20 send-keys n Enter      # ✗
bind-key -n F21 send-keys Enter        # ▶
bind-key -n F22 send-keys C-c          # ⏸
bind-key -n F13 select-window -t 1     # agent key 1 -> its window
bind-key -n F14 select-window -t 2     # agent key 2 -> its window
```

Run each Claude Code session in its own tmux window and the agent keys
become "jump to that session" buttons: amber key blinks → press it →
you're in that session → ✓ to approve.

### macOS

- System Settings → Keyboard → Keyboard Shortcuts → App Shortcuts, or a
  tool like Karabiner-Elements / BetterTouchTool / Raycast to bind
  F13–F24 to anything (scripts, window focus, menu items).
- iTerm2: Settings → Keys → Key Bindings → "Send Text" to map F19 → `y\n`
  directly in the terminal, no tmux needed.

### Windows

AutoHotkey v2 (`thirteen.ahk`, drop in `shell:startup`):

```ahk
F19::Send "y{Enter}"      ; approve
F20::Send "n{Enter}"      ; reject
F22::Send "^c"            ; interrupt
```

### Linux

Most desktop environments bind F13–F24 in Settings → Keyboard →
Custom Shortcuts. For window managers: `wtype`/`xdotool` in a script,
or bind in your terminal emulator / tmux as above.

## Voice: the talk bar 🎤

There is **no microphone in the pad** (same as the Codex Micro — its mic
key just triggers the ChatGPT app). The talk bar types **F24**; your
computer's dictation tool does the listening. Press the bar, speak, and
the text lands wherever your cursor is — e.g. the Claude Code prompt.

### macOS

Option A — built-in Dictation:
1. System Settings → Keyboard → Dictation → **on**.
2. Set *Shortcut* → Customize… → press the talk bar (registers as F24).
3. Talk bar → speak → text appears at the cursor. Press again to stop.

Option B — Whisper-based tools (better for code/technical terms):
Superwhisper, VoiceInk, MacWhisper all support a global toggle hotkey —
set it to F24. Push-to-talk mode in Superwhisper feels exactly like a
hardware mic bar.

### Windows

Built-in dictation sits on Win+H and can't be rebound directly — bridge
it with AutoHotkey v2:

```ahk
F24::Send "#h"   ; talk bar toggles Windows dictation
```

Whisper-based alternatives (e.g. Whisper Typing, Aiko-likes) accept a
custom hotkey — set F24 directly, no bridge needed.

### Linux

[nerd-dictation](https://github.com/ideasman42/nerd-dictation) (VOSK,
offline) with a toggle wrapper is the usual choice. Either bind F24 to
the toggle script in your DE's keyboard settings, or skip the keymap
entirely and let the daemon run it:

```toml
# thirteen.toml
[keys]
11 = { type = "shell", command = "nerd-dictation-toggle" }
```

(If you bind it in the daemon, consider remapping K11's HID output to
`none` over serial so F24 doesn't also fire.)

### The voice workflow

1. Amber key blinks — an agent wants something.
2. Press its agent key → your terminal focuses that session (tmux
   binding above).
3. Hold your answer? ✓ / ✗ is one press. Longer answer? Talk bar,
   speak, Enter.

## Everyday daemon usage

```sh
thirteen-host                 # foreground, ctrl-c to stop
thirteen-host -v              # verbose: see every event and LED command
thirteen-host -c work.toml    # alternate config
```

Run it however you run small daemons: a systemd user unit, a LaunchAgent,
or just a tmux pane. If it dies or you unplug the pad, keys keep typing
F13–F24 (HID needs no software) — only the status LEDs pause; the daemon
reconnects and repaints automatically.

Multiple Claude Code sessions: nothing to configure. Each session's hooks
report with its own `session_id`; the daemon gives each one a key from
the `claude_code` pool and frees it `done_timeout` seconds after the
session goes quiet. The ○ key clears all finished sessions immediately.
