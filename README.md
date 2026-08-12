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

**Packs** (bundle many features in one mod):

| Mod | What it adds |
|---|---|
| [`quest_pack`](quest_pack/) | Every quest in one mod: the Glow Shard, four Town Quests, and five Branching Quests with multiple endings, plus a QUESTS entry in the START menu that tracks them all. |
| [`visual_pack`](visual_pack/) | Every visual enhancement in one mod: day/night lighting, CRT lines, vignette, letterbox, weather, ambient motes, RGB split, film grain, night stars, color grade, duotone. Each is its own OPTIONS row and they stack. |

**Content, world, and challenges:**

| Mod | What it adds |
|---|---|
| [`fun_trainer_ace`](fun_trainer_ace/) | **Wandering Trainers** - eight optional battle trainers across the towns, each asking YES/NO before the fight, with a rematch greeting once beaten. |
| [`new_area_clubhouse`](new_area_clubhouse/) | Example of adding a brand-new map: a Clubhouse off Pallet Town with its own NPC. A template for new areas; see [docs/make-your-first-area.md](docs/make-your-first-area.md). |
| [`traveling_merchants`](traveling_merchants/) | Five distinct merchant NPCs out on the routes, each with its own sprite, specialty wares, route pair, and patrol style. Locations and stock rotate on real-world days. |
| [`rocket_recruits`](rocket_recruits/) | A roaming Team Rocket gang: a daily challenge in a different city each real day, with a level-scaled, capped reward. |
| [`roaming_boss`](roaming_boss/) | A tough Champion roams the cities every few days; beat their level-scaled team for a big prize. |
| [`legendary_shrine`](legendary_shrine/) | A daily rotating legendary wild battle on Route 10. |
| [`friendships`](friendships/) | Build relationships with six townsfolk over real-world days - warmer greetings and gifts as bonds grow, with a FRIENDS menu tracker. |

**Daily rewards and quality-of-life:**

| Mod | What it adds |
|---|---|
| [`world_clock`](world_clock/) | An in-game playtime clock that persists with the save and publishes time + day/hour events for other mods. |
| [`autosave`](autosave/) | Autosaves on events (catch, level up, evolve, trainer/gym battle) or a timer (1-30 min, configurable) - your choice in OPTIONS. |
| [`daily_gift`](daily_gift/) | A Pewter NPC gives a free item once per real day. |
| [`wonder_trader`](wonder_trader/) | A daily rare Pokemon from a Celadon NPC. |
| [`daily_lottery`](daily_lottery/) | Pick a number once a day in Vermilion for a prize. |
| [`berry_grove`](berry_grove/) | A daily healing item from a Cerulean guard. |
| [`daily_coins`](daily_coins/) | Daily Game Corner coins from a Cerulean NPC. |
| [`starter_pack`](starter_pack/) | A one-time item kit for new trainers. |
| [`veteran`](veteran/) | A re-battleable trainer in Viridian for grinding. |
| [`type_sage`](type_sage/) | A rotating daily type-matchup tip. |

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
