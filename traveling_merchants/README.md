# Traveling Merchants

A dedicated merchant NPC that appears **out on the routes** (not in towns,
which already have marts), travels route-to-route by in-game day, and
**moves under real collision** — it never walks through walls or water.
Built on [`world_clock`](../world_clock/).

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

## Roadmap

- **Stage 2** — Rare wares: the Mt. Moon fossil you didn't take, Old Amber,
  Moon Stone, Nuggets, a rotating TM.
- **Stage 3** — Pokémon for sale (never common species).
- **Stage 4** — Multiple merchants with distinct route styles (short
  shuttles vs long hauls), and longer patrol paths.

## Notes / limits

- The merchant "travels" by appearing on a different route each day; an NPC
  can't physically walk *between* maps (they're per-map objects), so
  cross-route walking isn't possible — but within a route it patrols for
  real.
- Runtime-spawned NPCs aren't saved, so the merchant re-spawns on entry;
  that's intentional.
