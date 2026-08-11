# Traveling Merchants

Five distinct merchant NPCs who appear **out on the routes** (not in towns,
which already have marts). Each has its own look, personality, specialty,
route pair, and patrol style, and **moves under real collision** — none of
them walk through walls or water. Their **locations and stock rotate on
real-world days** (they change at your local midnight).

No in-game clock required — since merchants don't roam with the time of day,
the day just comes from the real date. (`world_clock` is now optional and
can be disabled.)

## How it works

- **Dedicated NPC, spawned at runtime.** `mod.world:spawnNpc(routeId, …)`
  drops a real CLERK onto the route the merchant is visiting today;
  `removeNpc` takes it away when it moves on. No map files edited, no
  townsperson hijacked.
- **Real collision, read from the engine.** `mod.world:mapOverview()`
  returns the game's own walkability grid (`.` walkable, ` ` wall, `~`
  water, `+` warp). The merchant is placed on a walkable tile and only ever
  steps onto walkable tiles — collision is *read from the game, not
  guessed*. (The engine's scripted move doesn't enforce collision itself,
  so the mod checks the grid before every step.)
- **Deliberate movement.** It paces a short route (prefers along the path),
  not the random wander of vanilla NPCs.
- **Travels by day** (`world_clock`), on a route circuit you choose in
  **OPTIONS → MERCHANT ROUTE**: `3-ROUTE LOOP`, `5-ROUTE LOOP`, or `RANDOM`
  (re-rolls each day, stable within a day and across save/load).
- **Supplies shop:** a daily-rotating mix of potions, status heals, drinks,
  and a vitamin, at real prices.

## Testing

1. Enable `world_clock` **and** `traveling_merchants`, then `F5`.
2. Set **OPTIONS → MERCHANT ROUTE** to `3-ROUTE LOOP`.
3. Check the clock's `DAY N` and warp to the matching route:
   `(DAY−1) mod 3` → 0 = `ROUTE_1`, 1 = `ROUTE_2`, 2 = `ROUTE_3`.

   ```
   warp ROUTE_1
   ```
4. A **clerk** should appear a few tiles from you and pace back and forth.
   Talk to it → *"A traveling merchant, out here on the road!"* → **SUPPLIES**
   opens the shop.

If the clerk doesn't appear or clips into scenery, tell me what you see in
the `lovec` console — placement and collision are read live, so this is
where I'd tune.

## Wares

- **SUPPLIES** — daily-rotating potions, status heals, a drink, a vitamin.
- **RARE WARES** — the Mt. Moon fossil you **didn't** take (auto-detected
  from your bag), Old Amber, Moon Stone, a Nugget, and a **rotating TM**.
  Sold through the normal shop UI; fossils/amber get a buy price (they stay
  unsellable key items).
- **POKéMON** (Peddler only) — one **daily rare species** for a price, drawn
  from a curated pool (Omanyte, Kabuto, Aerodactyl, Dratini, Lapras, Eevee,
  Scyther, Pinsir, Tauros, Chansey, Porygon, Snorlax) — **never** a common
  species. Bought mons go to your party (or a PC box if it's full).

## The merchants

Each rotates between its two/three routes by real-world day, and its stock
rerolls daily.

| Merchant | Sprite | Routes | Style | Sells |
|---|---|---|---|---|
| **Peddler** | Clerk | 1 · 2 · 3 | roams (range 3) | daily supplies |
| **Digger** | Super Nerd | 4 · 5 | stops a lot (range 2) | the fossil you missed, Old Amber, Moon Stone, daily evolution stones |
| **Herbalist** | Nurse | 6 · 7 | ambles (range 2) | vitamins, Rare Candy, heals |
| **Techie** | Scientist | 8 · 9 | paces widely (range 4) | 4 daily-rotating TMs |
| **Tamer** | Gentleman | 10 · 11 | mostly stands (range 1) | a daily rare Pokémon + curios (Nugget, a stone) |

To find who's where today, warp to a route and look for the strolling NPC;
each is on `routes[realDay mod N]`.

## Roadmap

- Longer/varied patrol shapes, more merchants, price haggling / reputation.

## Notes / limits

- The merchant "travels" by appearing on a different route each day; an NPC
  can't physically walk *between* maps (they're per-map objects), so
  cross-route walking isn't possible — but within a route it patrols for
  real.
- Runtime-spawned NPCs aren't saved, so the merchant re-spawns on entry;
  that's intentional.
