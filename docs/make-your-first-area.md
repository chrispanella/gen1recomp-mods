# Make your first area (step by step)

A hands-on walkthrough for adding a **new room/house/town** and filling it
with content. It uses the [`new_area_clubhouse`](../new_area_clubhouse/) mod
as the worked example: a small room off Pallet Town with an NPC that gives a
gift. Read [authoring-maps-with-tiled.md](authoring-maps-with-tiled.md) first
for the tooling; this is the tutorial that ties it together.

There are two halves: **draw the map** (Tiled), then **wire up the content**
(a mod). You can also skip Tiled entirely and clone a room in code, which is
exactly what `new_area_clubhouse` does.

## A. Draw the map in Tiled

1. Build and open the workspace (`build/tiled/gen1.tiled-project`) in the
   gen1recomp build of Tiled.
2. **Make the room.** Easiest start: open a small interior like
   `maps/BLUES_HOUSE.tmj`, `File > Save As` a new name (e.g. `MY_ROOM.tmj`),
   and repaint the tile layer to taste. A Tiled tile is a 32x32 map block;
   paint from the HOUSE tileset. Keep a two-tile doormat on the bottom row.
3. **Place the door back out.** On the warp object layer, put a warp on the
   doormat tiles. Its target is `LAST_MAP` (return to wherever the player
   entered from).
4. **Place NPCs.** On the object layer, drop an NPC where you want it, give
   it a sprite and a `text` id like `TEXT_MY_ROOM_HOST` (you will script that
   id in the mod).
5. **Add the entrance on the town.** Open `PALLET_TOWN.tmj`, and on its warp
   layer add a warp on a **walkable door/edge tile** whose target is your new
   map. Turn on `View > Show Tile Collision Shapes` so you pick a reachable
   tile.
6. **Export** with the `gen1-mod-export` extension (a whole mod folder). A new
   map exports as `mod.content.maps:register`; the Pallet change exports as a
   `mod.content.maps:patch`.

## B. Wire up the content (the mod)

Whether you exported from Tiled or cloned a room in code, the content code is
the same shape. Here is the whole of `new_area_clubhouse` boiled down:

```lua
return function(mod)
  -- the new room (cloned layout renders correctly)
  mod.content.maps:register("FUN_CLUBHOUSE", {
    id = "FUN_CLUBHOUSE", index = 1000, tileset = "HOUSE",
    width = 4, height = 4, borderBlock = 10,
    blocks = { 4, 14, 5, 9, 15, 1, 2, 15, 15, 12, 13, 15, 6, 11, 15, 7 },
    warps = {
      { destMap = "LAST_MAP", destWarp = 4, x = 2, y = 7 },
      { destMap = "LAST_MAP", destWarp = 4, x = 3, y = 7 },
    },
    objects = {
      { index = 1, name = "FUN_CLUBHOUSE_HOST", sprite = "SPRITE_GENTLEMAN",
        text = "TEXT_FUN_CLUBHOUSE_HOST", movement = "STAY", range = "NONE", x = 3, y = 3 },
    },
  })

  -- the entrance: one warp appended to Pallet (its warp #4, hence destWarp=4 above)
  mod.content.maps:patch("PALLET_TOWN", {
    warps = { __append = { { destMap = "FUN_CLUBHOUSE", destWarp = 1, x = 4, y = 8 } } },
  })

  -- the content: the host's dialogue + a one-time gift
  mod.content.map_scripts:register("FUN_CLUBHOUSE", {
    talk = { ["TEXT_FUN_CLUBHOUSE_HOST"] = {
      { "check_flag", "MOD_CLUBHOUSE_GIFT" }, { "jump_if_true", "after" },
      { "show_text", "Welcome! Here, a\ngift for visiting!" },
      { "give_item", "RARE_CANDY" }, { "set_flag", "MOD_CLUBHOUSE_GIFT" },
      { "jump", "end" },
      { "label", "after" }, { "show_text", "Make yourself at\nhome!" },
    } },
  })
end
```

Key points:

- **New map id** is your own string; **index** must be 1000+.
- **`LAST_MAP`** as a warp `destMap` returns the player to the map they came
  from. `destWarp` is the 1-based index of the entrance warp on that map (the
  clubhouse uses 4 because the Pallet warp we append becomes Pallet's 4th).
- **NPCs** are objects on the map; their `text` id is what you key the
  `map_scripts` `talk` table on. From there it is the same script VM the
  quest and trainer mods use, so you can add battles (`start_battle`),
  branching choices (`choice`), fetch quests (`check_item` / `give_item`),
  and flags.

## C. Ship it

```bash
cd path/to/gen1recomp
cp -r yellow/data/generated/*.lua data/generated/        # once, Yellow gotcha
cp -r yellow/assets/generated/*   assets/generated/      # once
MODKIT_LUAJIT="C:\Users\YourF\AppData\Local\Programs\LuaJIT\bin\luajit.exe" \
  python tools/modkit.py validate mods/my_area --base imported   # checks the map + warps
python tools/build_index.py    # from the mods repo, to publish it on the feed
```

Then verify the entrance in game (warp to the town and walk onto the door
tile). If the tile is not reachable, nudge the warp's `x`/`y`, or place the
door properly in Tiled. Everything else is checked by the loader.
