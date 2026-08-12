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

## The Silph Whistleblower (multi-step)

A nervous exec in **Saffron** asks you to gather proof of wrongdoing. Track
down two witnesses - a **retiree** in Celadon and a **dock worker** in
Vermilion - then return to choose:

- **Expose them** for a TM (and a warning to watch your back).
- **Sell your silence** for a Nugget + a big payout.

Both witnesses and the exec react to how it ends.

## Two Brothers

Two old men in **Celadon** are feuding over who caught the bigger Magikarp.
Carry a NOTE between them and pick a side - whoever you back is delighted,
the other sulks.

## The Rocker's Guitar

A **rocker** in Saffron had his guitar stolen by a thief in **Viridian**. At
the thief you choose:

- **Take the guitar** back for the rocker and a rare TM (music ending).
- **Sell it** with the thief for a Nugget + cash (sellout ending). The rocker
  is heartbroken.

## How it works

Choices set `MOD_` flags, and every NPC branches on those flags for its
after-quest lines. Custom key items (SECRET MAP, AMBER SHARD, NOTE) drive the
quests. All script-VM content, no engine files edited, no maps changed.

## Testing

Console: `warp VERMILION_CITY`, talk to the sailor, then `warp SAFFRON_CITY`
(scientist) or `warp FUCHSIA_CITY` (gambler) to pick an ending. For quest 2,
`warp CERULEAN_CITY` (researcher) then `warp FUCHSIA_CITY` (Erik the poacher).
`flag MOD_BQ1_END_SCI` reads an ending flag.
