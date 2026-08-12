# Friendships

Build relationships with townsfolk over time. Talk to a befriendable NPC
once a real-world day and your bond grows; their greeting warms up and they
give you a gift each time you reach a new level. A **FRIENDS** entry in the
START menu tracks every bond.

## The friends

| NPC | Town |
|---|---|
| Old Angler | Pallet |
| Riverman | Viridian |
| Climber | Pewter |
| Gadgeteer | Cerulean |
| High Roller | Vermilion |
| Isle Girl | Cinnabar |

## Levels

`STRANGER` -> `ACQUAINTED` -> `FRIEND` -> `BEST PAL`. Each time you reach a
new level the NPC hands over a gift (an Ether, a TM, a Nugget, and so on).
Because the bond only rises **once per real day**, friendships build like
real ones - come back tomorrow. (To see it move quickly, nudge your system
clock, the same as the daily merchants and Rocket gang.)

## How it works

Friendship points live in `mod.save`, so they travel with the Pokemon save.
Talking runs a `friendships:greet` command that raises the bond (day-gated),
shows a level-appropriate line, and gives the milestone gift. The FRIENDS
menu is a `screens:register` screen added with the `ui.start_menu.items`
hook. No engine files edited, no maps changed.

## Not yet: gym leaders

Gym leaders are a planned follow-up. Their overworld NPC triggers the gym
battle, so befriending them safely means preserving the vanilla battle with
the `baseTalk` pattern and only layering friendship on after you have earned
their badge.
