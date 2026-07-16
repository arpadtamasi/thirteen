import textwrap
from pathlib import Path

import pytest

from thirteen_host.config import DEFAULT_COLORS, load_config


def write(tmp_path: Path, body: str) -> Path:
    p = tmp_path / "thirteen.toml"
    p.write_text(textwrap.dedent(body))
    return p


def test_defaults_and_overrides(tmp_path):
    cfg = load_config(write(tmp_path, """
        [serial]
        port = "COM3"

        [colors.waiting]
        color = "#123456"
        mode = "blink"
    """))
    assert cfg.port == "COM3"
    assert cfg.baud == 115200
    assert cfg.style_for("waiting").color == "#123456"
    # untouched states keep built-in defaults
    assert cfg.style_for("done").color == DEFAULT_COLORS["done"]["color"]
    # unknown state falls back to black/solid
    assert cfg.style_for("nonsense").color == "#000000"


def test_bindings(tmp_path):
    cfg = load_config(write(tmp_path, """
        [keys]
        12 = { type = "adapter", adapter = "claude_code", action = "clear" }

        [enc]
        cw = { type = "shell", command = "true" }

        [joy]
        press = { type = "led", key = 3, color = "#FF00FF", mode = "solid" }
    """))
    assert cfg.bindings["key.12"].type == "adapter"
    assert cfg.bindings["key.12"].params["action"] == "clear"
    assert cfg.bindings["enc.cw"].type == "shell"
    assert cfg.bindings["joy.press"].params["key"] == 3


def test_bad_binding_type(tmp_path):
    with pytest.raises(ValueError):
        load_config(write(tmp_path, """
            [keys]
            0 = { type = "teleport" }
        """))
