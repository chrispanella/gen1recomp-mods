# Rocket Recruits

A gang of **Team Rocket recruits** hangs out in a city each day as a
**daily challenge**. Beat them for a reward — then they move on to another
city tomorrow.

## How it works

- **Roams between cities** by real-world day: Cerulean → Vermilion → Celadon
  → Saffron → Fuchsia → Lavender (`cities[realDay mod 6]`).
- **A gang** of three grunts loiters in the day's city (spawned on tiles you
  can actually reach — flood-filled from your position).
- **One scaled battle:** talk to any grunt to take on the gang. The enemy
  party is picked from tiers by your **average party level**, so it stays a
  real fight (a 2-mon squad early, a 6-mon crew late).
- **Reward = level-scaled but capped.** You get `avg_level × 50` cash,
  clamped to **₽300–₽3000**, so you never earn an absurd amount no matter how
  strong you are — plus a **daily-rotating item** (Rare Candy, Nugget, Max
  Revive, a TM, …).
- **Once per day:** after you win, that day's gang won't rebattle until the
  next real day.

## Testing

1. Enable the mod, `F5`.
2. Warp to the day's city (it rotates daily; try `warp CERULEAN_CITY`,
   `warp VERMILION_CITY`, … until you find the grunts):

   ```
   warp CELADON_CITY
   ```
3. Talk to a **Rocket grunt** → take the challenge. Win → cash + item;
   the message shows the cash you grabbed.
4. Talk again → "you already routed us today." Come back tomorrow (or nudge
   your system clock) for a new city + reward.

## Design notes

The recruit trainer's `baseMoney` is 0, so the engine pays nothing
automatically — the mod hands out its own capped, level-scaled reward
instead. The battle sprite is inherited from the vanilla Rocket class via
`basePic`. Nothing here edits a map or hijacks an existing NPC.
