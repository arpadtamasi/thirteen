"""Key-slot assignment logic, exercised without any serial device."""

import pytest

from thirteen_host.config import Config
from thirteen_host.daemon import Daemon
from thirteen_host.adapters import StatusEvent


class FakeDevice:
    def __init__(self):
        self.leds = {}

    async def set_led(self, key, color, mode):
        self.leds[key] = (color, mode)


@pytest.fixture
def daemon():
    cfg = Config()
    cfg.adapters = {"demo": {"enabled": True, "keys": [0, 1]}}
    # built-in colors are populated by load_config; give the bare Config a
    # minimal palette here
    from thirteen_host.config import DEFAULT_COLORS, LedStyle
    for state, style in DEFAULT_COLORS.items():
        cfg.colors[state] = LedStyle(**style)
    d = Daemon(cfg)
    d.device = FakeDevice()
    return d


async def emit(daemon, agent_id, state):
    await daemon.on_status(StatusEvent(adapter="demo", agent_id=agent_id, state=state))


@pytest.mark.asyncio
async def test_agents_claim_and_keep_keys(daemon):
    await emit(daemon, "a", "running")
    await emit(daemon, "b", "thinking")
    await emit(daemon, "a", "waiting")

    assert daemon.slots[0].agent_id == "a"
    assert daemon.slots[0].state == "waiting"
    assert daemon.slots[1].agent_id == "b"
    # LED for key 0 shows the waiting style
    assert daemon.device.leds[0] == (
        daemon.config.style_for("waiting").color,
        daemon.config.style_for("waiting").mode,
    )


@pytest.mark.asyncio
async def test_full_pool_evicts_finished_first(daemon):
    await emit(daemon, "a", "done")
    await emit(daemon, "b", "running")
    await emit(daemon, "c", "thinking")  # pool full: should evict "a" (done)

    owners = {slot.agent_id for slot in daemon.slots.values()}
    assert owners == {"b", "c"}
