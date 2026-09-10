#!/usr/bin/env python
"""Report globals that are called but never defined anywhere in the map's files.

Lua resolves globals at call time, so a missing or mistyped function parses
clean and only fails when that branch is first taken - and silently, if a
pcall wrapper swallows the error. luacheck cannot see this; this can.

Usage:
    .venv\\Scripts\\python.exe tools/symcheck.py
"""
import io
import pathlib
import re
import sys

REPO_ROOT = pathlib.Path(__file__).resolve().parent.parent

# Supplied by the game engine or the Lua standard library.
ENGINE = {
    "print", "pairs", "ipairs", "type", "tostring", "tonumber", "table", "math",
    "string", "pcall", "xpcall", "unpack", "select", "setmetatable", "rawget",
    "getmetatable", "rawset", "os", "io", "require", "include", "assert",
    "error", "next", "collectgarbage", "loadstring", "dofile", "loadfile",
    "Map", "Game", "Players", "GameInfo", "GameInfoTypes", "GameDefines",
    "PlotTypes", "TerrainTypes", "FeatureTypes", "DirectionTypes", "Fractal",
    "ResourceUsageTypes", "FlowDirectionTypes", "YieldTypes", "ImprovementTypes",
    "ResourceClassTypes", "MinorCivTraitTypes", "PlayerTypes", "TeamTypes",
    "Locale", "ContextPtr", "UI", "Events", "Modding", "PreGame",
    # From the game's own NaturalWondersCustomMethods include.
    "NWCustomEligibility", "NWCustomPlacement",
}

KEYWORDS = {
    "function", "if", "elseif", "while", "return", "and", "or", "not", "for",
    "until", "end", "then", "do", "local", "in", "true", "false", "nil", "repeat",
}


def strip(src):
    """Remove long comments, line comments and string literals."""
    src = re.sub(r"--\[(=*)\[.*?\]\1\]", " ", src, flags=re.S)
    src = re.sub(r"--[^\n]*", " ", src)
    src = re.sub(r"\[(=*)\[.*?\]\1\]", '""', src, flags=re.S)
    src = re.sub(r'"(?:\\.|[^"\\\n])*"', '""', src)
    src = re.sub(r"'(?:\\.|[^'\\\n])*'", "''", src)
    return src


def definitions(src):
    """Names bound in this chunk: functions, locals, and function parameters."""
    names = set()
    names |= set(re.findall(r"function\s+([A-Za-z_]\w*)\s*[(.:]", src))
    names |= set(re.findall(r"local\s+function\s+([A-Za-z_]\w*)", src))
    for m in re.finditer(r"local\s+([^=\n]+?)\s*(?:=|$)", src, re.M):
        for n in m.group(1).split(","):
            n = n.strip()
            if re.fullmatch(r"[A-Za-z_]\w*", n):
                names.add(n)
    # for-loop bindings are locals, and are routinely callbacks.
    for m in re.finditer(r"for\s+([^=\n]+?)\s+in\s", src):
        for n in m.group(1).split(","):
            n = n.strip()
            if re.fullmatch(r"[A-Za-z_]\w*", n):
                names.add(n)
    names |= set(re.findall(r"for\s+([A-Za-z_]\w*)\s*=", src))
    # Parameters are locals too, and callbacks get called by name.
    for m in re.finditer(r"function[^(\n]*\(([^)]*)\)", src):
        for n in m.group(1).split(","):
            n = n.strip()
            if re.fullmatch(r"[A-Za-z_]\w*", n):
                names.add(n)
    return names


def main():
    files = sorted(REPO_ROOT.glob("*.lua"))
    if not files:
        print("no .lua files found")
        return 0

    stripped = {}
    for f in files:
        stripped[f] = strip(io.open(f, encoding="utf-8", errors="replace").read())

    defined = set(ENGINE)
    for src in stripped.values():
        defined |= definitions(src)

    failed = 0
    for f, src in stripped.items():
        missing = {}
        for m in re.finditer(r"(?<![.:\w])([A-Za-z_]\w*)\s*\(", src):
            name = m.group(1)
            if name in defined or name in KEYWORDS:
                continue
            missing.setdefault(name, src.count("\n", 0, m.start()) + 1)
        if missing:
            failed += 1
            print(f"  FAIL  {f.name}")
            for name, line in sorted(missing.items(), key=lambda kv: kv[1]):
                print(f"          line {line}: {name}()")
        else:
            print(f"  OK    {f.name}")

    print(f"\n{len(files) - failed}/{len(files)} clean")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
