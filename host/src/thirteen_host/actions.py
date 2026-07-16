"""Execute bound actions: shell commands, adapter actions, direct LED sets.

Note on keystroke macros: the device itself is a USB HID keyboard, so plain
keystroke output needs no host software at all — put it in the device keymap
(F13-F24 by default) and bind those in your terminal/OS. Host-side bindings
are for everything a keycode can't do.
"""

from __future__ import annotations

import asyncio
import logging
from typing import TYPE_CHECKING, Any

from .config import Binding

if TYPE_CHECKING:
    from .daemon import Daemon

log = logging.getLogger("thirteen.actions")


async def run_binding(daemon: "Daemon", binding: Binding, event: dict[str, Any]) -> None:
    if binding.type == "shell":
        await _run_shell(binding.params.get("command", ""))
    elif binding.type == "adapter":
        adapter = daemon.adapter(binding.params.get("adapter", ""))
        if adapter is None:
            log.warning("binding targets unknown adapter: %s", binding.params)
            return
        await adapter.handle_action(binding.params.get("action", ""), binding.params)
    elif binding.type == "led":
        await daemon.device.set_led(
            int(binding.params.get("key", -1)),
            binding.params.get("color", "#000000"),
            binding.params.get("mode", "solid"),
        )


async def _run_shell(command: str) -> None:
    if not command:
        return
    log.info("shell: %s", command)
    proc = await asyncio.create_subprocess_shell(command)
    # fire and forget, but reap the process to avoid zombies
    asyncio.get_running_loop().create_task(_reap(proc, command))


async def _reap(proc: asyncio.subprocess.Process, command: str) -> None:
    rc = await proc.wait()
    if rc != 0:
        log.warning("command exited %d: %s", rc, command)
