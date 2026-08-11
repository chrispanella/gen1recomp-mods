# The Glow Shard

A small fetch quest that spans two towns.

A **collector** in Cerulean City (the super nerd) has heard that a strange
glowing rock surfaced in Lavender Town. Agree to help, travel to Lavender
Town, and the nervous **super nerd** there hands you the **GLOW SHARD**.
Bring it back to the collector for a **RARE CANDY**.

## What this demonstrates

The core of "an NPC with a quest," using only registry content:

| Piece | How |
|---|---|
| Custom key item | `mod.content.items:register("QUEST_GLOW_SHARD_ITEM", {...})` |
| Quest giver + payout | `map_scripts` `talk` on the Cerulean NPC, with a `choice`, `check_item`, `take_item`, `give_item`. |
| Item source | `map_scripts` `talk` on the Lavender NPC, gated by quest flags. |
| Progress tracking | `MOD_`-prefixed event flags (`STARTED` / `TAKEN` / `DONE`). |
| Branching | `check_flag` / `check_item` set `ctx.lastCheck`; `jump_if_true` / `jump_if_false` branch on it; `label` / `jump` structure the flow. |

No engine files are edited and no map is changed.

## Testing quickly

Launch in developer mode and use the console (backtick):

```
warp CERULEAN_CITY
```

Talk to the super nerd, accept, then `warp LAVENDER_TOWN`, take the shard,
and `warp CERULEAN_CITY` to hand it in. `flag MOD_QUEST_GLOW_SHARD_DONE`
reads the completion flag.

## A note on vanilla dialogue

This mod replaces the two NPCs' normal lines outright. If you want the
original conversation preserved on the branches the quest doesn't use,
follow the `example_lost_parcel` pattern in the engine repo: it calls
`MapScripts.baseTalk(...)` to re-enter the vanilla handler and declares
the `engine_internals` permission in its manifest.
