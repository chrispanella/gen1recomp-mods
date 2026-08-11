# gen1-fun-mods

Content mods for [**gen1recomp**](https://github.com/bryanthaboi/gen1recomp) —
a hand-written Lua/LÖVE2D recreation of Pokémon Red/Blue/Yellow/Gold with a
native modding system. These mods add content (trainers, NPCs, quests, …)
to make the game more fun. They do not modify the engine.

## Mods in this repo

| Mod | What it adds |
|---|---|
| [`fun_trainer_ace`](fun_trainer_ace/) | ACE TRAINER LEO — an optional battle trainer in Viridian City. Proof-of-concept for adding new trainers. |
| [`quest_glow_shard`](quest_glow_shard/) | THE GLOW SHARD — a two-town fetch quest (Cerulean → Lavender), with a custom key item, branching dialogue, and a Rare Candy reward. Proof-of-concept for quest NPCs. |
| [`world_clock`](world_clock/) | An in-game playtime clock that persists with the save and publishes time + day/hour events for other mods to build on. Foundation for time-based content. |
| [`traveling_merchants`](traveling_merchants/) | A merchant that travels town-to-town by in-game day (built on `world_clock`), with a route mode you pick in OPTIONS (3-loop / 5-loop / random) and a daily-rotating supplies shop. Stage 1 of an expanding merchant system. |

## Installing / testing a mod

Each folder here is a self-contained mod (a `manifest.json` + `main.lua`).
To try one in the game:

1. Get a working gen1recomp checkout and a legally-supplied Gen-1 ROM
   (the engine verifies the ROM by SHA-1, extracts data, then releases it).
2. Copy (or symlink) a mod folder from this repo into the game's `mods/`
   directory, e.g. `gen1recomp/mods/fun_trainer_ace/`.
3. Launch the game in developer mode to get hot-reload and the console:

   ```sh
   love . --developer
   ```

4. Enable the mod in the in-game **mod manager**, then press `F5` to
   hot-reload after any edit. The backtick key opens a Lua console
   (`warp VIRIDIAN_CITY` jumps you straight to the test location).

## Repo layout

```
gen1-fun-mods/
  README.md
  fun_trainer_ace/
    manifest.json      # id, api version, entry point, metadata
    main.lua           # the mod: registers content on load
    README.md
```

## License

Mod code here is provided for use with gen1recomp. It contains no
copyrighted game assets; all Pokémon/species data comes from the ROM you
supply at runtime.
