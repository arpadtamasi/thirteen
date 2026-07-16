"""TOML configuration loading.

One file configures everything: serial port, state colors, key bindings,
and adapter settings. See host/config/thirteen.example.toml.
"""

from __future__ import annotations

import tomllib
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

DEFAULT_CONFIG_PATHS = (
    Path("thirteen.toml"),
    Path.home() / ".config" / "thirteen" / "thirteen.toml",
)

# Default color scheme; any [colors.<state>] table in the config overrides.
DEFAULT_COLORS: dict[str, dict[str, str]] = {
    "idle":     {"color": "#101010", "mode": "solid"},
    "thinking": {"color": "#8A2BE2", "mode": "pulse"},
    "running":  {"color": "#00A0FF", "mode": "pulse"},
    "waiting":  {"color": "#FFB000", "mode": "blink"},
    "done":     {"color": "#00C853", "mode": "solid"},
    "error":    {"color": "#FF1744", "mode": "blink"},
}


@dataclass
class LedStyle:
    color: str = "#000000"
    mode: str = "solid"


@dataclass
class Binding:
    """Action bound to a device input (key press, encoder, joystick)."""

    type: str  # "shell" | "adapter" | "led"
    params: dict[str, Any] = field(default_factory=dict)


@dataclass
class Config:
    port: str = "/dev/ttyACM0"  # "COM3" on Windows
    baud: int = 115200
    colors: dict[str, LedStyle] = field(default_factory=dict)
    # input name -> binding. Keys are "key.0".."key.12", "enc.cw", "enc.ccw",
    # "enc.btn", "joy.up", "joy.down", "joy.left", "joy.right", "joy.press".
    bindings: dict[str, Binding] = field(default_factory=dict)
    adapters: dict[str, dict[str, Any]] = field(default_factory=dict)

    def style_for(self, state: str) -> LedStyle:
        return self.colors.get(state, LedStyle())


def _parse_binding(raw: dict[str, Any]) -> Binding:
    btype = raw.get("type")
    if btype not in ("shell", "adapter", "led"):
        raise ValueError(f"unknown binding type: {btype!r}")
    params = {k: v for k, v in raw.items() if k != "type"}
    return Binding(type=btype, params=params)


def load_config(path: Path | None = None) -> Config:
    if path is None:
        for candidate in DEFAULT_CONFIG_PATHS:
            if candidate.exists():
                path = candidate
                break
        else:
            raise FileNotFoundError(
                "no config found; copy host/config/thirteen.example.toml "
                "to ./thirteen.toml or ~/.config/thirteen/thirteen.toml"
            )
    with open(path, "rb") as f:
        raw = tomllib.load(f)

    cfg = Config()
    serial = raw.get("serial", {})
    cfg.port = serial.get("port", cfg.port)
    cfg.baud = int(serial.get("baud", cfg.baud))

    colors = {**DEFAULT_COLORS, **raw.get("colors", {})}
    for state, style in colors.items():
        cfg.colors[state] = LedStyle(
            color=style.get("color", "#000000"),
            mode=style.get("mode", "solid"),
        )

    for section, prefix in (("keys", "key"), ("enc", "enc"), ("joy", "joy")):
        for name, raw_binding in raw.get(section, {}).items():
            cfg.bindings[f"{prefix}.{name}"] = _parse_binding(raw_binding)

    cfg.adapters = raw.get("adapters", {})
    return cfg
