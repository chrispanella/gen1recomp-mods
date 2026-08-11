# Traveling Merchants (Stage 1)

A merchant who **travels between towns by in-game day** and sells a
daily-rotating stock of supplies. Built on [`world_clock`](../world_clock/).

## What Stage 1 does

- **Travels:** each in-game day (from `world_clock`) the merchant is in one
  town. Reuses one existing NPC per town as the "stall"; when the merchant
  is elsewhere that NPC talks normally (vanilla dialogue preserved).
- **Player-selectable route** in the **OPTIONS** menu (`MERCHANT ROUTE`):
  - `3-TOWN LOOP` — Pewter → Cerulean → Vermilion
  - `5-TOWN LOOP` — + Celadon + Fuchsia
  - `RANDOM` — a pseudo-random town each day; re-rolls daily but stays put
    within a day and across save/load (seeded by the day number).
- **Supplies shop:** a daily-rotating mix of potions, status heals, drinks,
  and a vitamin — real items at real prices, sold through the normal shop UI.
- **Findable:** while the merchant is in a town, a recurring **"!" bubble**
  floats over the stall NPC so you can spot it on sight.

## Host NPCs (which sprite is the merchant)

| Town | NPC |
|---|---|
| Pewter City | Cool Trainer ♂ |
| Cerulean City | Cool Trainer ♂ |
| Vermilion City | Gambler (2nd) |
| Celadon City | Gramps (2nd) |
| Fuchsia City | Gambler |

## Testing

1. Enable `world_clock` **and** `traveling_merchants`.
2. Console (`` ` ``): `warp PEWTER_CITY`, talk to the Cool Trainer ♂. On Day 1
   with the default 3-town loop the merchant is in **Pewter**.
3. Change the route in **OPTIONS → MERCHANT ROUTE**.
4. Let the clock roll to the next day (~24 real min, or bump it for testing
   by raising `MINUTES_PER_SECOND` in `world_clock/main.lua`) and the merchant
   moves on; the Pewter NPC returns to its normal line.

## Roadmap (next stages)

- **Stage 2** — Rare wares: the Mt. Moon fossil you *didn't* take, Old Amber,
  Moon Stone, Nuggets, a rotating TM.
- **Stage 3** — Pokémon for sale: a daily rare mon (never common species).
- **Stage 4** — Multiple merchants with distinct wander styles (2-town
  shuttles, long hauls through routes and caves).

## How it works (for modders)

`world_clock` supplies the day via `mod.find("world_clock").exports.clock()`.
A per-NPC talk script calls a `traveling_merchants:present` verb that sets
`lastCheck` to whether the merchant is in that town today; if not, a
`traveling_merchants:base` verb replays the vanilla handler
(`MapScripts.baseTalk`). The shop opens via `push_screen("ShopMenu", stock)`,
where `stock` is a list of item ids priced from the item registry. Daily
variation is deterministic (arithmetic hash + LCG — no bitwise ops, since
LÖVE runs LuaJIT/Lua 5.1).
