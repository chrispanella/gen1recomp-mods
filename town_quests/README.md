# Town Quests

Four small **fetch quests** between NPCs in different towns. Each: a giver
asks you to find something an NPC in another town is holding; bring it back
for a reward.

| Quest | Giver -> Holder | Item | Reward |
|---|---|---|---|
| Keepsake | Pallet girl -> Viridian girl | KEEPSAKE | Poké Doll |
| Letter | Cerulean cooltrainer -> Vermilion sailor | LETTER | Rare Candy |
| Rare Herb | Celadon girl -> Fuchsia youngster | RARE HERB | Max Ether |
| Luck Charm | Lavender little girl -> Pewter youngster | LUCK CHARM | Nugget |

## How it works

Each quest owns two NPCs' dialogue: the **giver** offers the quest with a
YES/NO accept and later pays out; the **holder** hands over a custom key
item once the quest is active. Progress is tracked with `MOD_` flags
(`STARTED` / `TAKEN` / `DONE`), so it survives saves and can't be repeated.

## Testing quickly

Developer console (backtick): `warp PALLET_TOWN`, talk to the girl, accept,
then `warp VIRIDIAN_CITY`, take the keepsake, and `warp PALLET_TOWN` to hand
it in. `flag MOD_TQ_keepsake_DONE` reads a quest's completion flag.

All registry content - no engine files edited, no maps changed.
