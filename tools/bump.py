#!/usr/bin/env python
"""Build a distributable wve_map_glossen release from the map repo.

The repo is the source of truth and is never renamed or restamped. This script
copies the playable files out, stamps the version into the copy, syntax-checks
it against Lua 5.1, and zips it.

Usage:
    python tools/bump.py 11.0.6
    python tools/bump.py 11.0.6 --only-map   # omit the separate oceanwve script
    python tools/bump.py 11.0.6 --force      # overwrite an existing release
"""

import argparse
import pathlib
import re
import shutil
import sys
import zipfile

from lupa.lua51 import LuaRuntime, LuaSyntaxError

REPO_ROOT = pathlib.Path(__file__).resolve().parent.parent

# The repo's map script never gets renamed, so this glob stays valid across bumps.
MAP_LUA_GLOB = "Weevee - v*.lua"
# Separate map script that shares the DEF modules; not part of the glossen map.
SEPARATE_SCRIPTS = ["oceanwve v2.0.lua"]

VERSION_RE = re.compile(r"^\d+\.\d+\.\d+$")


def release_name(version):
    return f"wve_map_glossen_v{version}"


def stamp(source, version):
    """Rewrite the version-bearing strings. Returns (text, replacements_made)."""
    # In-game title + the load banner: "Weevee Map 11.0.5" -> "WvE Map 11.0.6".
    source, title_hits = re.subn(r"(?:Weevee|WvE) Map \d+\.\d+\.\d+",
                                 f"WvE Map {version}", source)
    # Debug log banner: WeeveeDbg("script loaded 11.0.5").
    source, banner_hits = re.subn(r"script loaded \d+\.\d+\.\d+",
                                  f"script loaded {version}", source)
    if title_hits == 0:
        raise SystemExit(
            "ERROR: found no 'Weevee Map X.Y.Z' / 'WvE Map X.Y.Z' string to stamp.\n"
            "       The map would ship without a version in its name. Fix the\n"
            "       pattern in tools/bump.py before releasing."
        )
    return source, title_hits + banner_hits


def syntax_check(paths):
    bad = []
    for path in paths:
        text = path.read_text(encoding="utf-8", errors="replace")
        if text.startswith("﻿"):
            text = text[1:]
        try:
            LuaRuntime().compile(text)
        except LuaSyntaxError as err:
            bad.append((path, str(err).strip()))
    return bad


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("version", help="new version, e.g. 11.0.6")
    ap.add_argument("--repo", default=None,
                    help="repo dir (default: the repo this script lives in)")
    ap.add_argument("--out", default=None,
                    help="where to write the release (default: parent of repo)")
    ap.add_argument("--only-map", action="store_true",
                    help="exclude the separate oceanwve script from the release")
    ap.add_argument("--force", action="store_true",
                    help="overwrite an existing release folder/zip")
    args = ap.parse_args()

    if not VERSION_RE.match(args.version):
        raise SystemExit(f"ERROR: version must look like 11.0.6, got {args.version!r}")

    repo = pathlib.Path(args.repo).resolve() if args.repo else REPO_ROOT
    out = pathlib.Path(args.out).resolve() if args.out else repo.parent

    map_luas = sorted(repo.glob(MAP_LUA_GLOB))
    if len(map_luas) != 1:
        raise SystemExit(
            f"ERROR: expected exactly one {MAP_LUA_GLOB!r} in {repo}, found {len(map_luas)}"
        )
    map_lua = map_luas[0]

    skip = set(SEPARATE_SCRIPTS) if args.only_map else set()
    sources = [p for p in sorted(repo.glob("*.lua")) if p.name not in skip]

    name = release_name(args.version)
    dest = out / name
    zip_path = out / f"{name}.zip"

    for target in (dest, zip_path):
        if target.exists():
            if not args.force:
                raise SystemExit(f"ERROR: {target} already exists (use --force to overwrite)")
            if target.is_dir():
                shutil.rmtree(target)
            else:
                target.unlink()

    dest.mkdir(parents=True)
    print(f"Building {name}")
    print(f"  repo: {repo}")
    print(f"  out:  {dest}")

    stamped_name = f"{name}.lua"
    for src in sources:
        if src == map_lua:
            text, hits = stamp(src.read_text(encoding="utf-8"), args.version)
            (dest / stamped_name).write_text(text, encoding="utf-8")
            print(f"  stamp {src.name} -> {stamped_name}  ({hits} version strings)")
        else:
            shutil.copy2(src, dest / src.name)
            print(f"  copy  {src.name}")

    print("\nSyntax-checking release (Lua 5.1)...")
    bad = syntax_check(sorted(dest.glob("*.lua")))
    if bad:
        for path, err in bad:
            print(f"  FAIL  {path.name}: {err}")
        shutil.rmtree(dest)
        raise SystemExit("ERROR: release did not parse; folder removed, nothing shipped.")
    print(f"  all {len(list(dest.glob('*.lua')))} files parsed clean")

    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as zf:
        for path in sorted(dest.glob("*.lua")):
            zf.write(path, f"{name}/{path.name}")
    size_kb = zip_path.stat().st_size / 1024
    print(f"\nWrote {zip_path}  ({size_kb:.0f} KB)")

    print(f"\nDone. In-game name is now: WvE Map {args.version}")
    print(f"Update the ledger line in {repo / 'VERSION-BUMP.txt'}.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
