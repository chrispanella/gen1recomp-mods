# World Clock

An in-game **playtime clock** that other mods can build on.

It advances while you play, **persists with your save**, and resumes at the
exact same time when you load back in. There's a small on-screen readout
(`DAY 1 08:15`) in the top-left, and it publishes the current time plus
day/hour-change events so other mods (e.g. traveling merchants) can react.

## Why a playtime clock (not real-world time)

The time total is stored in `mod.save`, which is serialized into the normal
Pokémon save. That means:

- The clock only ticks while you're actually playing.
- Closing the game pauses it; loading resumes from where you saved.
- Different save files keep independent clocks.

If you'd instead want the world to advance by *real* calendar time (so it
"moves on" while the game is closed), that's a one-line swap to `os.time()`
— ask and I'll add it as an option.

## Tuning (top of `main.lua`)

| Constant | Default | Meaning |
|---|---|---|
| `MINUTES_PER_SECOND` | `1` | 1 real second = 1 game minute (a game-day ≈ 24 real min). |
| `START_MINUTES` | `480` | New games start at Day 1, 08:00. |
| `SHOW_CLOCK_HUD` | `true` | Draw the on-screen readout. |

## Using it from another mod

```lua
-- in your mod's main.lua
local wc = mod.find("world_clock")
if wc then
  local t = wc.exports.clock()      -- { day = 3, hour = 14, minute = 5, total = ... }
  local phase = wc.exports.phase()  -- "morning" | "day" | "evening" | "night"
end

-- or react to time passing:
mod.events:on("mod.world_clock.day_changed", function(c)
  -- c = { day, hour, minute, total }
end)
mod.events:on("mod.world_clock.hour_changed", function(c) end)
```

Declare it in your manifest so load order is right:

```json
"dependencies": ["world_clock"]
```

## Testing

Launch in developer mode, load any save, and watch the top-left readout
tick. At the default rate an in-game hour passes each real minute. Save,
quit, relaunch, and load — the clock resumes where you left it.
