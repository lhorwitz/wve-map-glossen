# tools

Dev tooling for the map. Both scripts need `lupa`, which provides a real
Lua 5.1 parser — the same Lua version Civ V embeds.

## Setup (once per clone)

From the repo root:

```
python -m venv .venv
.venv\Scripts\python.exe -m pip install -r tools/requirements.txt
```

`.venv/` is gitignored.

## luacheck.py — syntax-check

```
.venv\Scripts\python.exe tools/luacheck.py
```

Checks every `.lua` in the repo and exits non-zero if any fails to parse.
Pass paths to check specific files instead.

This catches the parse errors the game would hit on load — the "missing
`end` somewhere in 10k lines" class. It cannot catch runtime errors:
`Map`, `GameInfo`, `PlotTypes` and friends only exist inside the game.

## bump.py — build a release

```
.venv\Scripts\python.exe tools/bump.py 11.0.6
```

Copies every `.lua` to `../wve_map_glossen_v11.0.6/`, renames the map
script, stamps the version into it, syntax-checks the result, and writes
`../wve_map_glossen_v11.0.6.zip`. If anything fails to parse it deletes
the folder and ships nothing.

Flags:

- `--only-map` — exclude `oceanwve v2.0.lua` (a separate map script that
  shares the DEF modules)
- `--force` — overwrite an existing release folder/zip
- `--out DIR` — write somewhere other than the parent directory

The full release procedure is in [../VERSION-BUMP.txt](../VERSION-BUMP.txt).
