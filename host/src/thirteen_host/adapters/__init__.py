"""Adapter framework.

An adapter is a class that emits status events (agent_id, state) and
receives action events. That's the whole contract — the device never knows
which agent it is showing. See docs/adapter-guide.md for a walkthrough.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import TYPE_CHECKING, Any

if TYPE_CHECKING:
    from ..daemon import Daemon

# Canonical states. Adapters SHOULD map whatever their agent reports onto
# these; unknown states fall back to the "idle" color.
STATES = ("idle", "thinking", "running", "waiting", "done", "error")


@dataclass
class StatusEvent:
    adapter: str
    agent_id: str
    state: str


class Adapter:
    """Base class. Subclass, set `name`, implement `run()`."""

    name = "base"

    def __init__(self, daemon: "Daemon", config: dict[str, Any]):
        self.daemon = daemon
        self.config = config
        # keys this adapter may claim for status display
        self.key_pool: list[int] = list(config.get("keys", []))

    async def run(self) -> None:
        """Long-running task; emit status via `self.emit(...)`."""
        raise NotImplementedError

    async def handle_action(self, action: str, params: dict[str, Any]) -> None:
        """Called when a key bound to this adapter is pressed."""

    async def emit(self, agent_id: str, state: str) -> None:
        await self.daemon.on_status(
            StatusEvent(adapter=self.name, agent_id=agent_id, state=state)
        )


def create_adapters(daemon: "Daemon", adapter_configs: dict[str, dict]) -> list[Adapter]:
    """Instantiate every adapter enabled in [adapters.*] config tables."""
    from .claude_code import ClaudeCodeAdapter
    from .demo import DemoAdapter
    from .generic_stdin import GenericStdinAdapter

    registry: dict[str, type[Adapter]] = {
        a.name: a for a in (ClaudeCodeAdapter, GenericStdinAdapter, DemoAdapter)
    }

    adapters = []
    for name, cfg in adapter_configs.items():
        if not cfg.get("enabled", True):
            continue
        cls = registry.get(name)
        if cls is None:
            raise ValueError(
                f"unknown adapter {name!r}; available: {sorted(registry)}"
            )
        adapters.append(cls(daemon, cfg))
    return adapters
