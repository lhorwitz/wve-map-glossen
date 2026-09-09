# wve-map-glossen

A Civilization V team map script. Two mirrored halves separated by a central
barrier, built for symmetric team play — both sides get identical land, so the
map never decides the game.

In-game the map appears as **WvE Map X.Y.Z**.

## Credits

- Ashwin Trisal
- Megawac
- Hoipolloi
- Cirra
- Meota

This repository is a detached copy of
[brunotho/Weevee-v11.0.5-Map](https://github.com/brunotho/Weevee-v11.0.5-Map)
(Hoipolloi), taken at v11.0.5 and developed independently from there. The
commit history from that project is preserved here with original authorship
intact.

The script descends from Firaxis's `West_vs_East.lua` by Bob Thomas
(Copyright © 2010 Firaxis Games, Inc.), and the plot-mirroring routine is
derived from work by Leszek Deska (Copyright © 2010).

## Installing

Unzip `wve_map_glossen_vX.Y.Z.zip` and drop the resulting folder into either:

```
<Steam>\steamapps\common\Sid Meier's Civilization V\Assets\Maps\
```

or, to leave the game files alone:

```
<Documents>\My Games\Sid Meier's Civilization 5\Maps\
```

Then pick **WvE Map X.Y.Z** from the map list when starting a game.

Everyone in a multiplayer game must be on the same version. The folder name
carries the version — if it doesn't match what the lobby agreed on, it's the
wrong copy.

## Map options

**Climate** — chooses the terrain theme for the whole map, including the
central barrier:

| Option | Barrier |
|---|---|
| Snow (Legacy) | original snow wall, ignores the wrap setting |
| Standard | snow |
| Murky | wetland: marsh and forest bands |
| Oasis | desert with oases |
| Wasteland | tundra and desert, fallout |
| Peaky | plains with mountain massifs |
| Frosty | tundra with snow bleed, fjords, snow furs |
| Random (sans Snow) | rolls one of the above, excluding Snow (Legacy) |

**Barrier Width** — thickness of the dividing barrier: 0, 2, 4, 6, or random.

**World Wrap** — whether the map wraps east-west. With wrap on, a second
barrier is placed at the seam so neither team can walk around the back.

**Front Mountain %** — mountain density along the barrier's inner edge,
20% to 50%.

**Canvas Shrink** — randomly trims the map dimensions for variety.

**Explo Balance** — narrows the map and cuts back the rear coastline, so
exploration matters less relative to the front.

## Layout

| File | Role |
|---|---|
| `Weevee - v11.0.5.lua` | the map script — all generation logic |
| `DEFMapGeneratorW8.lua` | pipeline entry, pulls in the start-plot system |
| `DEFAssignStartingPlotsW8.lua` | starts, regions, resources, natural wonders |
| `DEFMultilayeredFractalW.lua` | landmass fractal layers |
| `DEFTerrainGeneratorW.lua` | terrain by latitude |
| `DEFFeatureGeneratorW.lua` | forests, jungle, marsh, ice |
| `DEFMapmakerUtilitiesW.lua` | shared helpers |
| `oceanwve v2.0.lua` | a separate map script sharing the same modules |

`DEFMapGeneratorW.lua` and `DEFAssignStartingPlotsW.lua` are the non-W8
variants and are not loaded by this map.

The main script generates the **west half only**, then mirrors it east at the
end of `StartPlotSystem`. New terrain code should write west-only and let the
mirror propagate it.

## Developing

Set up the tooling once per clone, from the repo root:

```
python -m venv .venv
.venv\Scripts\python.exe -m pip install -r tools/requirements.txt
```

Then syntax-check your changes before loading the game:

```
.venv\Scripts\python.exe tools/luacheck.py
```

That runs a real Lua 5.1 parser — the version Civ V embeds — so it catches
the errors the game would hit on load. It can't catch runtime errors, since
`Map`, `GameInfo` and friends only exist in-game.

## Releasing

```
.venv\Scripts\python.exe tools/bump.py X.Y.Z
```

This repo is never renamed or version-stamped. The build writes a standalone
`wve_map_glossen_vX.Y.Z` folder and zip into the parent directory, stamping
the version into the copy. See [VERSION-BUMP.txt](VERSION-BUMP.txt) for the
full procedure and [tools/README.md](tools/README.md) for the scripts.
