"""Claude Code adapter.

Integration path: Claude Code hooks (PreToolUse / PostToolUse / Stop /
Notification / UserPromptSubmit) run the `thirteen-hook` script, which
appends one NDJSON status line to an events file. This adapter tails that
file. Multi-session aware: each Claude Code session (session_id) claims a
key from the adapter's pool and its LED tracks the session state.

Hook setup: see docs/adapter-guide.md ("Claude Code" section) for the
settings.json snippet.

Config:

    [adapters.claude_code]
    keys = [0, 1, 2, 3, 4, 5]
    # events_file = "~/.local/state/thirteen/claude-events.jsonl"  (default)
    # done_timeout = 300   # seconds before a finished session frees its key
"""

from __future__ import annotations

import asyncio
import json
import logging
import time
from pathlib import Path
from typing import Any

from . import Adapter

log = logging.getLogger("thirteen.claude_code")

DEFAULT_EVENTS_FILE = "~/.local/state/thirteen/claude-events.jsonl"


class ClaudeCodeAdapter(Adapter):
    name = "claude_code"

    def __init__(self, daemon, config: dict[str, Any]):
        super().__init__(daemon, config)
        self.events_file = Path(
            config.get("events_file", DEFAULT_EVENTS_FILE)
        ).expanduser()
        self.done_timeout = float(config.get("done_timeout", 300))
        self._last_seen: dict[str, float] = {}  # agent_id -> monotonic ts

    async def run(self) -> None:
        self.events_file.parent.mkdir(parents=True, exist_ok=True)
        self.events_file.touch(exist_ok=True)
        log.info("tailing %s", self.events_file)

        # Tail by polling: portable (works on macOS/Linux/Windows and over
        # network mounts) and cheap at this event rate.
        with open(self.events_file, "r", encoding="utf-8") as f:
            f.seek(0, 2)  # start at EOF: ignore stale events from past runs
            while True:
                line = f.readline()
                if not line:
                    await asyncio.sleep(0.2)
                    await self._expire_finished()
                    continue
                await self._handle_line(line)

    async def _handle_line(self, line: str) -> None:
        line = line.strip()
        if not line:
            return
        try:
            ev = json.loads(line)
        except json.JSONDecodeError:
            log.debug("bad line in events file: %r", line[:120])
            return
        agent_id = ev.get("agent_id")
        state = ev.get("state")
        if not agent_id or not state:
            return
        self._last_seen[agent_id] = time.monotonic()
        await self.emit(agent_id, state)

    async def _expire_finished(self) -> None:
        """Turn long-finished sessions idle so their keys read as free."""
        now = time.monotonic()
        for agent_id, ts in list(self._last_seen.items()):
            if now - ts > self.done_timeout:
                del self._last_seen[agent_id]
                await self.emit(agent_id, "idle")

    async def handle_action(self, action: str, params: dict[str, Any]) -> None:
        # The pad's keys already type F13-F24 as a plain HID keyboard, which
        # is the natural way to answer Claude Code permission prompts (bind
        # them in your terminal). Adapter actions cover the rest:
        if action == "clear":
            # acknowledge all done/error sessions -> idle
            for agent_id in list(self._last_seen):
                del self._last_seen[agent_id]
                await self.emit(agent_id, "idle")
        else:
            log.warning("unknown action: %s", action)
