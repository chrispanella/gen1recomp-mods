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
| [`battles`](battles/) | **Every battle challenge in one mod:** eight wandering trainers who ask before a fight, a re-battleable veteran in Viridian, a daily roaming Team Rocket gang that moves as a formation, a Champion that roams the cities every few days, and a daily rotating legendary on Route 10. |
| [`new_area_clubhouse`](new_area_clubhouse/) | Example of adding a brand-new map: a Clubhouse off Pallet Town with its own NPC. A template for new areas; see [docs/make-your-first-area.md](docs/make-your-first-area.md). |
| [`traveling_merchants`](traveling_merchants/) | Five distinct merchant NPCs out on the routes, each with its own sprite, specialty wares, route pair, and patrol style. Locations and stock rotate on real-world days. |
| [`crafting`](crafting/) | Gather materials (apricorns, herbs) from foraging spots on routes and wild-battle drops, then craft at two benches: a BALL WORKSHOP (apricorns to Poke/Great/Ultra Balls) and an ALCHEMY LAB (herbs to Potions and status heals), each an interactive menu. |
| [`friendships`](friendships/) | Build relationships with six townsfolk over real-world days - warmer greetings and gifts as bonds grow, with a FRIENDS menu tracker. |

> **Battle difficulty:** [`battles`](battles/) reads the BATTLE DIFF setting from [`tweaks`](tweaks/) when it is installed, so NORMAL / HARD / BRUTAL makes every challenge's team tougher. The roaming/rocket/legendary battles apply it live at each encounter; the fixed-team trainers (wanderers, veteran) apply it at load, so changing the setting for those takes effect after a reload.

**Weekly rewards and quality-of-life:**

| Mod | What it adds |
|---|---|
| [`tweaks`](tweaks/) | A shared settings panel in OPTIONS: control the on-screen popups every mod uses (off / text-only / full bar, plus color, size, bold, duration, sound) and a BATTLE DIFF (Normal/Hard/Brutal) the challenge mods read. Other mods use it when present and fall back to their own defaults otherwise. |
| [`world_clock`](world_clock/) | An in-game playtime clock that persists with the save and publishes time + day/hour events for other mods. |
| [`autosave`](autosave/) | Autosaves on events (catch, level up, evolve, trainer/gym battle) or a timer (1-30 min, configurable) - your choice in OPTIONS. |
| [`lottery`](lottery/) | A lottery vendor outside every town's mart. Buy a cheap ticket, lock in a number from 1 to 100; draws happen every WEDNESDAY and SATURDAY. Match the drawn number and collect the jackpot from any vendor. |
| [`town_gifts`](town_gifts/) | **Friendly townsfolk in one mod:** weekly gifts (a free item in Pewter, a rare Pokemon in Celadon, a healing item and Game Corner coins in Cerulean), a rotating weekly type tip, and a one-time welcome kit from a spawned Pewter NPC that leaves for good once claimed. |

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
