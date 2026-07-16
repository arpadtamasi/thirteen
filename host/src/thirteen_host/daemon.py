"""The daemon: serial link + adapters + LED state engine + action routing.

Responsibilities:
- keep the serial link up, resync LED state after every device `hello`
- assign agents to keys (each adapter gets a key pool from config;
  agents claim keys first-free, then least-recently-updated)
- translate status events into LED commands using the configured colors
- route device input events (keys, encoder, joystick) to bound actions
"""

from __future__ import annotations

import asyncio
import logging
import time
from dataclasses import dataclass, field
from typing import Any

from .actions import run_binding
from .adapters import Adapter, StatusEvent, create_adapters
from .config import Config
from .device import Device

log = logging.getLogger("thirteen.daemon")


@dataclass
class KeySlot:
    agent_id: str | None = None
    adapter: str | None = None
    state: str = "idle"
    updated: float = field(default_factory=time.monotonic)


class Daemon:
    def __init__(self, config: Config):
        self.config = config
        self.device = Device(config.port, config.baud, self._on_device_event)
        self.slots: dict[int, KeySlot] = {}  # key index -> slot
        self.adapters: list[Adapter] = create_adapters(self, config.adapters)
        self._adapter_by_name = {a.name: a for a in self.adapters}

    # ---- lifecycle ----------------------------------------------------------

    async def run(self) -> None:
        tasks = [asyncio.create_task(self.device.run(), name="device")]
        for adapter in self.adapters:
            tasks.append(asyncio.create_task(adapter.run(), name=adapter.name))
            log.info("adapter started: %s (keys %s)", adapter.name, adapter.key_pool)
        # If any task dies, bring the whole daemon down loudly rather than
        # running half-blind.
        done, pending = await asyncio.wait(tasks, return_when=asyncio.FIRST_EXCEPTION)
        for t in pending:
            t.cancel()
        for t in done:
            if t.exception():
                raise t.exception()

    # ---- status -> LED ------------------------------------------------------

    async def on_status(self, ev: StatusEvent) -> None:
        adapter = self._adapter_by_name.get(ev.adapter)
        if adapter is None:
            return
        key = self._claim_key(adapter, ev.agent_id)
        if key is None:
            log.warning("no free key for %s/%s", ev.adapter, ev.agent_id)
            return
        slot = self.slots[key]
        slot.state = ev.state
        slot.updated = time.monotonic()
        log.info("agent %s -> %s (key %d)", ev.agent_id, ev.state, key)
        await self._paint(key)

    def _claim_key(self, adapter: Adapter, agent_id: str) -> int | None:
        pool = adapter.key_pool
        if not pool:
            return None
        # already assigned?
        for k in pool:
            slot = self.slots.get(k)
            if slot and slot.agent_id == agent_id:
                return k
        # first free key in the pool
        for k in pool:
            if k not in self.slots or self.slots[k].agent_id is None:
                self.slots[k] = KeySlot(agent_id=agent_id, adapter=adapter.name)
                return k
        # pool full: evict the least-recently-updated finished agent,
        # else the least-recently-updated one overall
        candidates = sorted(pool, key=lambda k: self.slots[k].updated)
        for k in candidates:
            if self.slots[k].state in ("done", "error", "idle"):
                self.slots[k] = KeySlot(agent_id=agent_id, adapter=adapter.name)
                return k
        k = candidates[0]
        self.slots[k] = KeySlot(agent_id=agent_id, adapter=adapter.name)
        return k

    async def _paint(self, key: int) -> None:
        slot = self.slots[key]
        style = self.config.style_for(slot.state)
        await self.device.set_led(key, style.color, style.mode)

    async def _repaint_all(self) -> None:
        await self.device.set_led(-1, "#000000", "off")
        for key in self.slots:
            await self._paint(key)

    # ---- device events -> actions -------------------------------------------

    async def _on_device_event(self, event: dict[str, Any]) -> None:
        t = event.get("t")
        if t == "hello":
            log.info("device hello: fw=%s proto=%s", event.get("fw"), event.get("proto"))
            await self._repaint_all()
            return
        if t in ("ack", "pong", "keymap"):
            log.debug("device: %s", event)
            return

        name = self._event_to_binding_name(event)
        if name is None:
            return
        binding = self.config.bindings.get(name)
        if binding is None:
            log.debug("no binding for %s", name)
            return
        await run_binding(self, binding, event)

    @staticmethod
    def _event_to_binding_name(event: dict[str, Any]) -> str | None:
        t = event.get("t")
        if t == "key" and event.get("act") == "down":
            return f"key.{event.get('key')}"
        if t == "enc":
            delta = event.get("delta", 0)
            return "enc.cw" if delta > 0 else "enc.ccw"
        if t == "enc_btn" and event.get("act") == "down":
            return "enc.btn"
        if t == "joy" and event.get("dir") not in (None, "release"):
            return f"joy.{event.get('dir')}"
        return None

    # ---- used by actions ------------------------------------------------------

    def adapter(self, name: str) -> Adapter | None:
        return self._adapter_by_name.get(name)
