# Visual Enhance: Day/Night

A visual-enhancement display mode built on the engine's **render pipelines**.
Version 1 adds **dynamic day/night lighting**: the overworld is tinted by the
time of day.

| Time | Look |
|---|---|
| Night (21:00-05:00) | cool blue |
| Dawn (05:00-08:00) | soft rose |
| Day (08:00-18:00) | neutral |
| Dusk (18:00-21:00) | warm orange |

If [`world_clock`](../world_clock/) is installed it follows the **in-game
clock**; otherwise it follows your **real-world local time**.

## How it works

It registers a render pipeline that runs in the `worldPresent` stage, which
colors the **world only** and leaves menus and text boxes crisp. The tint is
applied by plain color-modulated drawing (no custom shader), so it is light
and safe - if a callback ever throws, the engine retires the mode and falls
back to the flat 2D world.

Toggle intensity with **hotkey 7** (or the display-mode row in OPTIONS):
`OFF / SUBTLE / MEDIUM / STRONG`.

## About the big picture

This is deliberately **not** a voxel/3D renderer (that is a huge GPU project).
It is a lightweight 2D post-processing enhancement that pairs especially well
with `world_clock`. Planned next passes, each needing in-game tuning: a
color-grade/saturation pass, a soft vignette, an optional CRT/scanline mode,
and weather tints.

## Testing

Enable the mod, press **7** to cycle intensity, and watch the overworld tint.
With `world_clock` on, let the clock roll (or nudge `MINUTES_PER_SECOND` up)
to see it shift from day to dusk to night. Menus should stay untinted.
