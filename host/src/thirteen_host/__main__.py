"""CLI entry point: `thirteen-host [-c CONFIG] [-v]`."""

from __future__ import annotations

import argparse
import asyncio
import logging
import sys
from pathlib import Path

from .config import load_config
from .daemon import Daemon


def main() -> None:
    parser = argparse.ArgumentParser(
        prog="thirteen-host",
        description="Host daemon for the thirteen agent macropad",
    )
    parser.add_argument("-c", "--config", type=Path, default=None,
                        help="path to thirteen.toml (default: ./thirteen.toml "
                             "or ~/.config/thirteen/thirteen.toml)")
    parser.add_argument("-v", "--verbose", action="store_true")
    args = parser.parse_args()

    logging.basicConfig(
        level=logging.DEBUG if args.verbose else logging.INFO,
        format="%(asctime)s %(name)s %(levelname)s %(message)s",
    )

    try:
        config = load_config(args.config)
    except (FileNotFoundError, ValueError) as e:
        print(f"error: {e}", file=sys.stderr)
        sys.exit(1)

    try:
        asyncio.run(Daemon(config).run())
    except KeyboardInterrupt:
        pass


if __name__ == "__main__":
    main()
