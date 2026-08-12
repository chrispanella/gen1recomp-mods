# Wandering Trainers

Sprinkles **eight optional battle trainers** across the towns. Each one is an
existing townsperson who now **asks if you'd like to battle** (YES/NO) before
any fight, so they are purely optional. Beat one and it greets you with a
rematch line afterward, just like a real trainer.

## The trainers

| Town | Trainer | Team level |
|---|---|---|
| Viridian | Ace Leo | ~15 |
| Pewter | Hiker Rocky | ~13 |
| Cerulean | Cooltrainer Dorian | ~19 |
| Vermilion | Beauty Blaze (fire) | ~23 |
| Celadon | Fisher Marina (water) | ~29 |
| Lavender | Medium Spectra (ghost) | ~31 |
| Fuchsia | Juggler Venom (poison) | ~35 |
| Cinnabar | Ember (fire) | ~42 |

Parties scale by town progression, each trainer has its own flavor, prize
money is modest, and a beaten trainer switches to a friendly rematch greeting.

## How it works

Each entry registers a trainer (`mod.content.trainers`) and places it on a
real NPC via a `map_scripts` talk script. Talking runs a `check_flag` for the
beaten state, a `choice` for the YES/NO prompt, then `start_battle`; a win
sets the beaten flag. All registry content - no engine files edited, no maps
changed.

## Extending it

Add a row to the `TRAINERS` table in `main.lua`: a town map, an NPC `TEXT_`
constant, a party (a list of `{ level, species }`), prize money, and the
dialogue lines.
