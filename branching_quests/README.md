# Branching Quests

Two questlines where your **choices change the ending** and the NPCs
remember what you did.

## The Secret Map

A sailor in **Vermilion** fishes up a SECRET MAP that two people want. You
decide who gets it:

- Give it to the **Scientist** in Saffron for a rare **TM** (knowledge ending).
- Sell it to the **Gambler** in Fuchsia for a **Nugget + cash** (gold ending).

Each ending locks out the other, and afterward all three NPCs (sailor,
scientist, gambler) react to the side you chose.

## The Poacher's Bargain

A **researcher** in Cerulean sends you after a poacher hiding in **Fuchsia**
who stole an AMBER SHARD. At the poacher you choose:

- **Take the shard** back and return it to the researcher for an **Old Amber**
  (conservation ending).
- **Take the bribe** and let the poacher go for a **Nugget + cash** (profit
  ending). The researcher is not pleased.

## How it works

Choices set `MOD_` flags (`END_SCI` / `END_FOR`, `END_CONS` / `END_PROFIT`),
and every NPC branches on those flags for its after-quest lines. Custom key
items (SECRET MAP, AMBER SHARD) drive each quest. All script-VM content, no
engine files edited, no maps changed.

## Testing

Console: `warp VERMILION_CITY`, talk to the sailor, then `warp SAFFRON_CITY`
(scientist) or `warp FUCHSIA_CITY` (gambler) to pick an ending. For quest 2,
`warp CERULEAN_CITY` (researcher) then `warp FUCHSIA_CITY` (Erik the poacher).
`flag MOD_BQ1_END_SCI` reads an ending flag.
