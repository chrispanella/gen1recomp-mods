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
| [`visual_pack`](visual_pack/) | Every visual enhancement in one mod (all default OFF): a unified **SKY & WEATHER** system (time-of-day lighting, night stars, and weather that varies by city/route and by day), plus CRT lines, vignette, letterbox, motes, RGB split, film grain, color grade, duotone. Pure graphics - archive it freely; the settings live in [`settings`](settings/). |

**Content, world, and challenges:**

| Mod | What it adds |
|---|---|
| [`battles`](battles/) | **Every battle challenge in one mod:** eight wandering trainers who ask before a fight, a re-battleable veteran in Viridian, a daily roaming Team Rocket gang that moves as a formation, a Champion that roams the cities every few days, and a daily rotating legendary on Route 10. |
| [`new_area_clubhouse`](new_area_clubhouse/) | Example of adding a brand-new map: a Clubhouse off Pallet Town with its own NPC. A template for new areas; see [docs/make-your-first-area.md](docs/make-your-first-area.md). |
| [`traveling_merchants`](traveling_merchants/) | Five distinct merchant NPCs out on the routes, each with its own sprite, specialty wares, route pair, and patrol style. Locations and stock rotate on real-world days. |
| [`crafting`](crafting/) | **A full crafting system:** a bench opens a hub with ALCHEMY, COOKING, ENGINEERING, a TM LAB, and GATHERING, each with its own level that unlocks better recipes. Gather materials from off-path foraging spots and area/water-specific wild-battle drops. See [Crafting in depth](#crafting-in-depth) below. |
| [`friendships`](friendships/) | Build relationships with six townsfolk over real-world days - warmer greetings and gifts as bonds grow, with a FRIENDS menu tracker. |

> **Battle difficulty:** [`battles`](battles/) reads the BATTLE DIFF setting from [`settings`](settings/) when it is installed, so NORMAL / HARD / BRUTAL makes every challenge's team tougher. The roaming/rocket/legendary battles apply it live at each encounter; the fixed-team trainers (wanderers, veteran) apply it at load, so changing the setting for those takes effect after a reload.

**Weekly rewards and quality-of-life:**

| Mod | What it adds |
|---|---|
| [`settings`](settings/) | A shared settings panel in OPTIONS: the on-screen popup style every mod uses (off / text-only / full bar, plus color, size, bold, duration, sound), a BATTLE DIFF (Normal/Hard/Brutal) the challenge mods read, and a one-tap RESET GRAPHICS. Independent of the graphics pack. |
| [`world_clock`](world_clock/) | An in-game playtime clock that persists with the save and publishes time + day/hour events for other mods. |
| [`autosave`](autosave/) | Autosaves on events (catch, level up, evolve, trainer/gym battle) or a timer (1-30 min, configurable) - your choice in OPTIONS. |
| [`lottery`](lottery/) | A lottery vendor outside every town's mart. Buy a cheap ticket, lock in a number from 1 to 100; draws happen every WEDNESDAY and SATURDAY. Match the drawn number and collect the jackpot from any vendor. |
| [`town_gifts`](town_gifts/) | **Friendly townsfolk in one mod:** weekly gifts (a free item in Pewter, a rare Pokemon in Celadon, a healing item and Game Corner coins in Cerulean), a rotating weekly type tip, and a one-time welcome kit from a spawned Pewter NPC that leaves for good once claimed. |

## Crafting in depth

The [`crafting`](crafting/) mod is a full crafting system. Talk to a crafting
bench (a craftsman spawns in **Cerulean**, an alchemist in **Celadon**) to open
the **CRAFTING** hub, which branches into five disciplines. Each discipline has
its own **level** that rises as you craft and unlocks better recipes; a locked
recipe shows its requirement (`Lv N`, or `Bg N` badges for cooking) instead of
its cost.

| Discipline | What you make | Gated by |
|---|---|---|
| **ALCHEMY** | Potions and status heals - Potion up through Full Restore, plus Antidote / Parlyz Heal / Burn Heal / Awakening | discipline level (1-5) |
| **COOKING** | **Buff food** - dishes that raise a Pokemon's stats (see below). Better dishes each region | **badge count** (0-7) |
| **ENGINEERING** | Poke / Great / Ultra Balls, then Old / Good / Super Rod and a Bicycle - all real, working items (a better rod really does catch better fish) | discipline level (1-5) |
| **TM LAB** | Twelve TMs (Body Slam, Thunderbolt, Ice Beam, Earthquake, Fire Blast, Hyper Beam, ...) and three HMs, built from **Tech Shards** | discipline level (1-6) |
| **GATHERING** | A read-only look at your materials; its level raises how much each foraging spot yields | rises as you forage |

### Buff food (Cooking)

Which dishes you can cook is gated by **badge count** - each region unlocks a
better meal, the same way your Pokemon obey you further as you earn badges
(Berry Juice at 0 badges up to a Grand Feast at 7 that raises all four stats).
A dish can be used two ways:

- **In battle** - eaten during a fight, it boosts the active Pokemon's stat
  stages for the rest of that battle (like a multi-stat X-item).
- **In the field** - eaten from the bag, it prepares a meal that buffs your
  **lead at the start of your next battle**, persisting in the save until then.

### Materials and gathering

Materials come from two places, and both raise your Gathering level:

- **Foraging spots** - a searchable node (a rock/brush clump) appears on
  several routes, biased to off-path edge tiles so it never blocks the way.
  Searching yields area-appropriate materials and refills once per real week.
- **Wild-battle drops** - a chance to find a material after winning a wild
  battle. **Water-type foes** drop water materials (Kelp, Pearls); otherwise
  the **region** decides - forests favor herbs and berries, caves and mountains
  favor scrap, springs, and Tech Shards.

Some moves aren't craftable at all: three **Move Tutors** in [`quest_pack`](quest_pack/)
teach signature TMs (Submission, Dream Eater, Sky Attack) when you beat them.

If [`settings`](settings/) is installed, the "found a material" popup follows
your popup style settings there.

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
