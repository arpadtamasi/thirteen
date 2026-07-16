"""Generic stdin adapter.

Reads NDJSON status events from the daemon's stdin, so anything that can
print a line of JSON can drive the pad — a shell script, Codex CLI wrapper,
n8n, a Makefile:

    {"agent_id": "build", "state": "running"}
    {"agent_id": "build", "state": "done"}

Example:

    (my-long-task && echo '{"agent_id":"task","state":"done"}' \\
      || echo '{"agent_id":"task","state":"error"}') | thirteen-host

Config:

    [adapters.generic_stdin]
    keys = [6, 7, 8]
"""

from __future__ import annotations

import asyncio
import json
import logging
import sys

from . import Adapter

log = logging.getLogger("thirteen.generic_stdin")


class GenericStdinAdapter(Adapter):
    name = "generic_stdin"

    async def run(self) -> None:
        loop = asyncio.get_running_loop()
        reader = asyncio.StreamReader()
        protocol = asyncio.StreamReaderProtocol(reader)
        try:
            await loop.connect_read_pipe(lambda: protocol, sys.stdin)
        except (OSError, ValueError):
            # no usable stdin (daemonized) — stay alive but inert
            log.info("stdin not readable; adapter idle")
            await asyncio.Event().wait()
            return

        while True:
            raw = await reader.readline()
            if not raw:
                log.info("stdin closed; adapter idle")
                await asyncio.Event().wait()
                return
            try:
                ev = json.loads(raw)
            except json.JSONDecodeError:
                log.debug("bad stdin line: %r", raw[:120])
                continue
            agent_id = ev.get("agent_id")
            state = ev.get("state")
            if agent_id and state:
                await self.emit(str(agent_id), str(state))
