# gen1-fun-mods

Content mods for [**gen1recomp**](https://github.com/bryanthaboi/gen1recomp) -
a hand-written Lua/LÖVE2D recreation of Pokémon Red/Blue/Yellow/Gold with a
native modding system. These mods add content (trainers, NPCs, quests, ...)
to make the game more fun. They do not modify the engine.

## Install in-game (mod index)

This repo is an installable **mod index**. In gen1recomp, open the mod
manager (**F10**) -> add a mod index -> enter:

```
chrispanella/gen1recomp-mods
```

All the mods below will appear; install any of them and enable it. (You can
also grab a single mod's `.zip` from [`site/mods/`](site/mods/) and use
**MODS -> Import mod .zip**.)

> The index feed lives at `site/data/index.json`; the game reads it from
> GitHub Pages, falling back to the raw file, so it works as soon as this
> repo is public.

## Mods in this repo

| Mod | What it adds |
|---|---|
| [`fun_trainer_ace`](fun_trainer_ace/) | **Wandering Trainers** - eight optional battle trainers sprinkled across the towns, each asking YES/NO before the fight, with a rematch greeting once beaten. |
| [`quest_glow_shard`](quest_glow_shard/) | THE GLOW SHARD - a two-town fetch quest (Cerulean -> Lavender), with a custom key item, branching dialogue, and a Rare Candy reward. |
| [`town_quests`](town_quests/) | Four cross-town fetch quests (keepsake, letter, rare herb, luck charm) between NPCs in different towns, each with a custom key item and a reward. |
| [`world_clock`](world_clock/) | An in-game playtime clock that persists with the save and publishes time + day/hour events for other mods to build on. Foundation for time-based content. |
| [`traveling_merchants`](traveling_merchants/) | Five distinct merchant NPCs out on the routes (Peddler, Digger, Herbalist, Techie, Tamer), each with its own sprite, specialty wares, route pair, and patrol style. Locations and stock rotate on real-world days. |
| [`rocket_recruits`](rocket_recruits/) | A roaming Team Rocket gang that appears in a different city each real-world day as a daily challenge - one level-scaled battle for a capped cash reward + a rotating item. |

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
