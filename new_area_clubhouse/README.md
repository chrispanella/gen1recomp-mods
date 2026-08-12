# New Area: Clubhouse (experimental)

A worked example of **adding a brand-new map with a mod** and populating it.
It registers a new interior (the FUN CLUBHOUSE), warps into it from Pallet
Town, and puts a host NPC inside who gives a one-time gift.

## What it does

1. **Registers a new map** `FUN_CLUBHOUSE` with `mod.content.maps:register`.
   The `blocks` / `width` / `height` / `tileset` / `borderBlock` are cloned
   from a vanilla one-room house, so the room draws correctly. New maps use
   an index of 1000+ so they don't collide with vanilla map numbers.
2. **Adds an entrance** by patching one warp onto `PALLET_TOWN`
   (`maps:patch` with a `{ warps = { __append = { ... } } }`). The room's
   own exit warps use `LAST_MAP`, the engine's "return to wherever you came
   from" token.
3. **Populates it** with a host NPC (`map_scripts` talk) that hands over a
   Rare Candy the first time you visit.

Validated through the loader with `modkit validate --base imported` (map,
warp patch, and NPC all check out) and `lint`.

## The one thing to verify in game

The Pallet entrance warp is placed at tile **(4, 8)**, a best guess at a
walkable spot. Warp there and confirm you can reach it and that it takes you
inside. If the tile is blocked, change the single `x` / `y` in `main.lua`, or
place a proper door with the Tiled workflow (see
`docs/authoring-maps-with-tiled.md`). Everything else is structurally sound.

## Use it as a template

Copy this mod to start your own area: swap the `blocks` for a layout you
author in Tiled (or clone a different vanilla room), point the entrance warp
at your chosen town/tile, and fill the room with NPCs, trainers, and quests
using the same registry patterns as the other mods here.
