# Writing an adapter

An adapter is the only thing that knows about your agent. The contract is
two methods and one callback — a useful adapter fits in ~50 lines.

## The contract

```python
from thirteen_host.adapters import Adapter

class MyAdapter(Adapter):
    name = "my_agent"                       # config table: [adapters.my_agent]

    async def run(self):
        """Long-running task. Watch your agent however you like and call
        self.emit(agent_id, state) whenever something changes."""

    async def handle_action(self, action, params):
        """Called when a key bound to this adapter is pressed (optional)."""
```

- `agent_id` is any stable string — a session id, a hostname, "build".
  The daemon assigns each agent_id a key from your `keys` pool and keeps
  the mapping stable while the agent is active.
- `state` is one of `idle`, `thinking`, `running`, `waiting`, `done`,
  `error`. Map whatever your agent reports onto these six; the LED color
  scheme is configured per state, not per adapter.

Register it in `create_adapters()` (`adapters/__init__.py`) and add a
`[adapters.my_agent]` table with a `keys = [...]` pool to the config.
That's the whole integration.

## A complete example (~40 lines)

An adapter that watches a directory of lock files — any process can
`touch /tmp/agents/<name>.running` (or `.waiting`, `.done`):

```python
import asyncio
from pathlib import Path
from thirteen_host.adapters import Adapter

class LockfileAdapter(Adapter):
    name = "lockfiles"

    async def run(self):
        watch = Path(self.config.get("path", "/tmp/agents")).expanduser()
        watch.mkdir(parents=True, exist_ok=True)
        known: dict[str, str] = {}
        while True:
            seen = {}
            for f in watch.glob("*.*"):
                agent, state = f.stem, f.suffix.lstrip(".")
                if state in ("thinking", "running", "waiting", "done", "error"):
                    seen[agent] = state
            for agent, state in seen.items():
                if known.get(agent) != state:
                    await self.emit(agent, state)
            for agent in known.keys() - seen.keys():
                await self.emit(agent, "idle")
            known = seen
            await asyncio.sleep(0.5)
```

## Ready-made adapters

### claude_code

Integrates via Claude Code hooks. Each hook run executes `thirteen-hook`
(installed with the package), which appends a status line to an events
file; the adapter tails it. Multi-session aware: every Claude Code session
claims its own key.

Add to your Claude Code `settings.json` (user-level `~/.claude/settings.json`
or per-project `.claude/settings.json`):

```json
{
  "hooks": {
    "UserPromptSubmit": [{ "hooks": [{ "type": "command", "command": "thirteen-hook" }] }],
    "PreToolUse":       [{ "hooks": [{ "type": "command", "command": "thirteen-hook" }] }],
    "PostToolUse":      [{ "hooks": [{ "type": "command", "command": "thirteen-hook" }] }],
    "Notification":     [{ "hooks": [{ "type": "command", "command": "thirteen-hook" }] }],
    "Stop":             [{ "hooks": [{ "type": "command", "command": "thirteen-hook" }] }]
  }
}
```

State mapping: `UserPromptSubmit`/`PostToolUse` → thinking, `PreToolUse` →
running, `Notification` → waiting (that's your amber "needs approval"
blink), `Stop` → done.

Approvals: the pad is a real HID keyboard typing F13–F24, so bind those in
your terminal multiplexer — e.g. tmux: `bind-key -n F13 send-keys y Enter`.
No host round-trip, works even if the daemon is down.

### generic_stdin

Pipe NDJSON to the daemon and you're integrated:

```sh
echo '{"agent_id":"deploy","state":"running"}' | thirteen-host
```

This is the escape hatch for everything else: Codex CLI wrappers, n8n HTTP
→ shell, CI scripts, cron jobs.

### demo

No agent at all — cycles the six states across its key pool so you can
check wiring and colors.
