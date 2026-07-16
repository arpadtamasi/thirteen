"""`thirteen-hook` — Claude Code hook entry point.

Claude Code invokes hooks with a JSON payload on stdin. This script maps
the hook event to a thirteen status and appends one NDJSON line to the
events file that the claude_code adapter tails. It must be fast and must
never fail the hook (always exits 0).

Wire it up in Claude Code's settings.json — see docs/adapter-guide.md.
"""

from __future__ import annotations

import json
import os
import sys
import time
from pathlib import Path

DEFAULT_EVENTS_FILE = "~/.local/state/thirteen/claude-events.jsonl"

# hook_event_name -> thirteen state
EVENT_STATE = {
    "UserPromptSubmit": "thinking",
    "PreToolUse": "running",
    "PostToolUse": "thinking",
    "Notification": "waiting",   # permission prompt / attention needed
    "Stop": "done",
    "SubagentStop": "thinking",
    "SessionEnd": "idle",
}


def main() -> None:
    try:
        payload = json.load(sys.stdin)
        state = EVENT_STATE.get(payload.get("hook_event_name", ""))
        session = payload.get("session_id")
        if state and session:
            path = Path(
                os.environ.get("THIRTEEN_EVENTS_FILE", DEFAULT_EVENTS_FILE)
            ).expanduser()
            path.parent.mkdir(parents=True, exist_ok=True)
            line = json.dumps(
                {"agent_id": session, "state": state, "ts": time.time()}
            )
            with open(path, "a", encoding="utf-8") as f:
                f.write(line + "\n")
    except Exception:
        pass  # a status LED is never worth breaking a Claude Code session
    sys.exit(0)


if __name__ == "__main__":
    main()
