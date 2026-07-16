# thirteen-host

Python daemon that bridges the thirteen macropad to your agents.

```sh
pip install -e .                 # from this directory
cp config/thirteen.example.toml thirteen.toml
# edit thirteen.toml: set your serial port (/dev/ttyACM0, COM3, ...)
thirteen-host
```

Quick LED test without any agent: enable `[adapters.demo]` in the config
and watch the bottom row cycle through the state colors.

Quick test from a shell (generic_stdin adapter):

```sh
echo '{"agent_id":"hello","state":"waiting"}' | thirteen-host
```

Claude Code integration: install the `thirteen-hook` script into your hooks
(see `docs/adapter-guide.md`), then just use Claude Code — each session
claims a key and its LED tracks thinking / running / waiting / done.

Run tests:

```sh
pip install -e .[dev]
pytest
```
