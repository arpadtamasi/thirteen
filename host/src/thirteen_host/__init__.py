"""thirteen-host — host daemon for the thirteen agent macropad.

The device knows nothing about any specific agent. All intelligence lives
here: adapters translate agent activity into status events, the daemon maps
status to per-key LEDs and routes key presses to actions.
"""

__version__ = "0.1.0"

PROTO_VERSION = 1
