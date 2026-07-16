"""Serial link to the macropad: NDJSON over USB CDC, 115200 baud.

Reconnects automatically if the device is unplugged. Outbound messages are
queued while disconnected and flushed on reconnect (LED state is re-sent by
the daemon after every `hello`).
"""

from __future__ import annotations

import asyncio
import json
import logging
from typing import Any, Awaitable, Callable

import serial_asyncio

from . import PROTO_VERSION

log = logging.getLogger("thirteen.device")

EventHandler = Callable[[dict[str, Any]], Awaitable[None]]


class Device:
    def __init__(self, port: str, baud: int, on_event: EventHandler):
        self._port = port
        self._baud = baud
        self._on_event = on_event
        self._writer: asyncio.StreamWriter | None = None
        self._send_lock = asyncio.Lock()

    @property
    def connected(self) -> bool:
        return self._writer is not None

    async def send(self, msg: dict[str, Any]) -> None:
        """Send one protocol message; silently dropped while disconnected."""
        if self._writer is None:
            return
        msg.setdefault("v", PROTO_VERSION)
        line = json.dumps(msg, separators=(",", ":")) + "\n"
        async with self._send_lock:
            self._writer.write(line.encode())
            await self._writer.drain()

    async def set_led(self, key: int, color: str, mode: str) -> None:
        await self.send({"t": "led", "key": key, "color": color, "mode": mode})

    async def run(self) -> None:
        """Connect-read-reconnect loop; runs forever."""
        while True:
            try:
                reader, writer = await serial_asyncio.open_serial_connection(
                    url=self._port, baudrate=self._baud
                )
            except (OSError, asyncio.TimeoutError) as e:
                log.debug("serial open failed (%s), retrying in 2s", e)
                await asyncio.sleep(2)
                continue

            log.info("connected to %s", self._port)
            self._writer = writer
            try:
                while True:
                    raw = await reader.readline()
                    if not raw:
                        break  # EOF: device gone
                    try:
                        event = json.loads(raw)
                    except json.JSONDecodeError:
                        log.debug("dropping non-JSON line: %r", raw[:80])
                        continue
                    if isinstance(event, dict):
                        await self._on_event(event)
            except (OSError, asyncio.IncompleteReadError) as e:
                log.warning("serial link lost: %s", e)
            finally:
                self._writer = None
                writer.close()
            log.info("disconnected, waiting for device")
            await asyncio.sleep(1)
