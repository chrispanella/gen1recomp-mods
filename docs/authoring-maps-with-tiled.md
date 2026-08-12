# Authoring new maps and towns with Tiled

gen1recomp's map data is plain Lua, so maps can be edited in the
[Tiled](https://www.mapeditor.org) map editor and exported back out as a mod.
This is how you make **new towns, new areas, new interiors** and edits to
existing maps. It is a visual workflow you drive in the editor; this guide
gets you set up and points at the moving parts.

## What you need

1. **Python 3 + Pillow** (already used to import the ROM).
2. **LuaJIT on PATH.** Installed at
   `C:\Users\YourF\AppData\Local\Programs\LuaJIT\bin`. If `luajit -v` fails in
   a shell, add that folder to PATH first.
3. **The gen1recomp build of Tiled** from
   [bryanthaboi/tiled_gen1recomp releases](https://github.com/bryanthaboi/tiled_gen1recomp/releases).
   Regular Tiled can open the workspace but **cannot export a mod** - only that
   build ships the `gen1-mod-export` extension.

## One-time gotcha for a Yellow setup

`tools/tiled_export.py` (and the other dev tools) look for the data/graphics
under the **unprefixed** `data/generated/` and `assets/generated/`, but a
Yellow import writes them under `yellow/`. So copy them across once, from the
`gen1recomp` folder:

```bash
cp yellow/data/generated/*.lua    data/generated/
cp -r yellow/assets/generated/*   assets/generated/
```

## Build the workspace

From the `gen1recomp` folder:

```bash
python tools/tiled_export.py            # -> build/tiled/  (all 222 maps)
```

This has already been run for you - the workspace is at
`gen1recomp/build/tiled/`. Open `build/tiled/gen1.tiled-project` in the
gen1recomp build of Tiled.

## Understanding the workspace

- **The overworld is one surface.** `kanto.world` places the 36 connected
  overworld maps at their real offsets, so opening any one draws its neighbors
  around it and you can edit across the seams.
- **A Tiled tile *is* a gen1 block** (a 32x32 block from a tileset). A tile
  layer is literally the map's `blocks` array. Paint with the tileset palette
  to build terrain.
- **Warps, signs and objects** live on object layers on the 16px cell grid -
  the same grid the engine addresses them on. This is where you place NPCs,
  doors, and signs.
- **See collision:** View > Show Tile Collision Shapes draws the real
  walkability (a box over each non-walkable cell). Use it so players can
  actually reach everything.
- **Real colors:** each map is shown in the SGB palette it renders with.

## Making a new town or area

- **A new outdoor area:** hook it onto an existing map with a **connection**
  (drag it against a base map's edge in the world). The editor wires *both
  ends* automatically - it emits the return connection as a patch on the base
  map, so Kanto's other directions stay intact. This is how you grow the map.
- **A new interior** (house/shop/cave): create a new map with an interior
  tileset (HOUSE, INTERIOR, MART, CLUB, LAB, LOBBY, CAVERN, GYM...), put a warp
  on it back out, and add a matching warp (a door) on the town map that points
  into it.
- **New blocks/tilesets:** `blocksets/*.tmj` show a tileset's blocks as raw
  8x8 tiles (4x4) so you can compose new blocks; per-tile flags on
  `tilesets/tiles_*.tsj` set `walkable`, `doorTiles`, `waterTiles`, etc.

## Export as a mod

With a map selected, run the **gen1-mod-export** extension. It writes either a
single map file or a whole loadable mod folder:

- an **edited vanilla map** diffs against the base and emits
  `mod.content.maps:patch` with only the fields that changed;
- a **new map** emits `mod.content.maps:register` (index >= 1000);
- an unchanged map exports nothing.

Exported mods already pass `modkit validate` and `lint`.

## Fold it into this repo

1. Drop the exported mod folder into this repo (a sibling of the other mods).
2. Add its `manifest.json` `github` field and a `mod.card` (match the other
   mods).
3. Validate:

   ```bash
   cd path/to/gen1recomp
   MODKIT_LUAJIT="C:\Users\YourF\AppData\Local\Programs\LuaJIT\bin\luajit.exe" \
     python tools/modkit.py validate mods/<your_map_mod> --base imported
   ```
4. Rebuild the index so it ships on the feed:

   ```bash
   python tools/build_index.py
   ```

Then commit - it publishes to the `chrispanella/gen1recomp-mods` index like the
rest. Populate your new town with NPCs, trainers, and quests using the same
registry patterns as the mods in this repo.

## Reference

- `gen1recomp/docs/tiled-map-editing.md` - the engine's own writeup.
- `gen1recomp/docs/new-features.md` - map editing feature notes.
- The `README.md` inside `build/tiled/` - workspace-specific notes.
