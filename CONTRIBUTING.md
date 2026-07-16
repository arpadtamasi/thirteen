# Contributing

Thanks! The bar is low and the welcome is warm.

**Most wanted**

- **Adapters** for other agents/tools (~50 lines: see
  [docs/adapter-guide.md](docs/adapter-guide.md)). Keep the device dumb —
  agent knowledge belongs in the adapter, never in firmware.
- **Hardware test reports.** The code paths marked `TODO(hw-test)` need
  eyes on real boards, especially ESP32-S3 SuperMini clones. Open an issue
  with your board + what happened.
- **Case remixes** — MX variant, tenting, whatever. Keep it parametric.

**Ground rules**

- Protocol changes must update `protocol/PROTOCOL.md` in the same PR;
  additive changes preferred, breaking changes bump the version.
- Host code: Python ≥3.11, no new runtime deps without a reason,
  `pytest` must pass (`pip install -e host[dev] && pytest host`).
- Firmware: must build for both envs (`pio run` and `pio run -e supermini`).
- English throughout; no personal or machine-specific paths in examples
  (use `/dev/ttyACM0` and `COM3`).

**Process:** fork → branch → PR. Small PRs merge fast. For anything
architectural, open an issue first so nobody wastes an evening.
