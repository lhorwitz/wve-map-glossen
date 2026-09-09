#!/usr/bin/env python
"""Syntax-check the map's Lua against a real Lua 5.1 parser.

Civ V embeds Lua 5.1, so this catches exactly the parse errors the game would
hit on load. It does NOT catch runtime errors: Map, GameInfo, PlotTypes,
TerrainTypes and friends only exist inside the game.

Usage:
    python tools/luacheck.py              # every .lua in the repo
    python tools/luacheck.py <path> [...] # specific files or directories
"""

import pathlib
import sys

from lupa.lua51 import LuaRuntime, LuaSyntaxError

REPO_ROOT = pathlib.Path(__file__).resolve().parent.parent


def check(path):
    """Return None if the file parses, else an error string."""
    source = path.read_text(encoding="utf-8", errors="replace")
    # Strip a UTF-8 BOM; Lua 5.1 chokes on it but Civ V's loader tolerates it.
    if source.startswith("﻿"):
        source = source[1:]
    try:
        LuaRuntime().compile(source)
    except LuaSyntaxError as err:
        return str(err).strip()
    return None


def collect(args):
    paths = []
    for arg in args:
        p = pathlib.Path(arg)
        if p.is_dir():
            paths.extend(sorted(p.rglob("*.lua")))
        else:
            paths.append(p)
    return paths


def main():
    if sys.argv[1:]:
        targets = collect(sys.argv[1:])
    else:
        targets = sorted(REPO_ROOT.glob("*.lua"))

    if not targets:
        print("no .lua files found")
        return 0

    failed = 0
    for path in targets:
        error = check(path)
        if error is None:
            print(f"  OK    {path.name}")
        else:
            failed += 1
            print(f"  FAIL  {path.name}")
            for line in error.splitlines():
                print(f"          {line}")

    print(f"\n{len(targets) - failed}/{len(targets)} parsed clean")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
