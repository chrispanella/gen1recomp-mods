# Ace Trainer Leo

Adds an optional battle trainer — **ACE TRAINER LEO** — to Viridian City.

Talk to the gambler NPC in Viridian City and he'll challenge you to a
battle (Nidorino 15 / Kadabra 16 / Growlithe 17). Beat him once and he
switches to a friendly rematch line, just like a vanilla trainer.

## What this demonstrates

This is a minimal, self-contained example of the two registries you use
for almost all "new trainer" content:

| Registry | Role |
|---|---|
| `mod.content.trainers` | Defines the trainer: name, prize money, party. |
| `mod.content.map_scripts` | Places the battle on a map NPC via a `talk` script. |

The battle is triggered by the `start_battle` script verb; `lastCheck`
is `true` after a win, so the script branches on the outcome with
`jump_if_false`. No engine files are edited and no map is changed.

## How to extend it

- **Different party / levels** — edit the `parties` table in `main.lua`.
- **Multiple parties on one trainer** — add more entries to `parties` and
  select them with the party-index argument to `start_battle`.
- **A different location** — change `"VIRIDIAN_CITY"` and `HOST_NPC` to
  another map id and one of its `TEXT_*` NPC constants.
- **A truly new NPC** (not an override of an existing one) — author the
  map in Tiled and export it as a map mod; see the engine's
  `docs/tiled-map-editing.md`.
