# Quest Tracker

Adds a **QUESTS** entry to the START menu that opens a quest log tracking
every quest in this mod pack, so players can see what they have started,
finished, and which ending they took.

## What it tracks

| Source mod | Quests |
|---|---|
| `quest_glow_shard` | Glow Shard |
| `town_quests` | Keepsake, Lost Letter, Rare Herb, Luck Charm |
| `branching_quests` | Secret Map, Amber Shard, Whistleblower, Two Brothers, Rocker Guitar |

Each row shows a status: `- -` (not started), `ACTIVE`, `DONE`, or the name
of the **ending** you chose for a branching quest (e.g. `EXPOSED` vs
`COVERED`).

## How it works

The log reads the quests' `MOD_` event flags straight from the save, so it
needs no cooperation from the quest mods and works even if only some of them
are installed - a quest whose flags never appear just reads "not started". It
adds the menu entry with the `ui.start_menu.items` hook and shows the list
with a `screens:register` screen. No engine files edited, no maps changed.

## Adding a quest

Add a row to the `QUESTS` table in `main.lua` with the quest's name and its
`started` / `done` flag names (and optional `endings`).
