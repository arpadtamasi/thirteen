"""Demo adapter: cycles states across its key pool so you can test the
LED pipeline with no agent attached.

    [adapters.demo]
    keys = [9, 10, 11, 12]
    # interval = 2.0
"""

from __future__ import annotations

import asyncio
import itertools
import logging

from . import STATES, Adapter

log = logging.getLogger("thirteen.demo")


class DemoAdapter(Adapter):
    name = "demo"

    async def run(self) -> None:
        interval = float(self.config.get("interval", 2.0))
        if not self.key_pool:
            log.warning("demo adapter has no keys configured")
            await asyncio.Event().wait()
            return
        for step in itertools.count():
            for i in range(len(self.key_pool)):
                state = STATES[(step + i) % len(STATES)]
                await self.emit(f"demo-{i}", state)
            await asyncio.sleep(interval)
