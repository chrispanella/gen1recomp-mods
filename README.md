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

All the mods below will appear; install any of them and enable it.

Prefer a manual install? Grab a single mod's installable `.zip` either from
the [**Releases**](https://github.com/chrispanella/gen1recomp-mods/releases)
page (one versioned release per mod) or from [`site/mods/`](site/mods/), then
use **MODS -> Import mod .zip** in-game.

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

**Weekly rewards and quality-of-life:**

| Mod | What it adds |
|---|---|
| [`world_clock`](world_clock/) | An in-game playtime clock that persists with the save and publishes time + day/hour events for other mods. |
| [`autosave`](autosave/) | Autosaves on events (catch, level up, evolve, trainer/gym battle) or a timer (1-30 min, configurable) - your choice in OPTIONS. |
| [`lottery`](lottery/) | A lottery vendor outside every town's mart. Buy a cheap ticket, lock in a number from 1 to 100; draws happen every WEDNESDAY and SATURDAY. Match the drawn number and collect the jackpot from any vendor. |
| [`daily_gift`](daily_gift/) | A Pewter NPC gives a free item once per real week. |
| [`wonder_trader`](wonder_trader/) | A rare Pokemon once per real week from a Celadon NPC. |
| [`berry_grove`](berry_grove/) | A healing item once per real week from a Cerulean guard. |
| [`daily_coins`](daily_coins/) | Game Corner coins once per real week from a Cerulean NPC. |
| [`starter_pack`](starter_pack/) | A one-time welcome kit from an NPC in Pewter that disappears for good once you claim it. |
| [`veteran`](veteran/) | A re-battleable trainer in Viridian for grinding. |
| [`type_sage`](type_sage/) | A rotating weekly type-matchup tip. |

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
