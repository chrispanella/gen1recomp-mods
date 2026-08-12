# Autosave

Automatically saves your game, on a schedule **you pick in OPTIONS**.

## Modes (OPTIONS -> AUTOSAVE)

| Mode | When it saves |
|---|---|
| `ON EVENTS` | after catching a Pokemon, a level up, an evolution, or a trainer/gym battle |
| `TIMED` | on a timer; a second row, **SAVE EVERY**, picks the interval: 1, 2, 3, 5, 10, 15, 20, or 30 minutes |
| `OFF` | never (vanilla behavior) |

## How it works

- Event mode hooks the engine's `pokemon.caught`, `pokemon.level_up`,
  `pokemon.evolved`, and `battle.ended` (trainer/gym only) events - the
  moments you don't want to lose.
- A save is **deferred** until you are back in the **free-roam overworld**
  with nothing on top (`game.stack:top().isOverworld`), so an autosave never
  lands mid-battle or mid-menu. It fires the instant you leave the battle.
- It calls the engine's own `Game:writeSave`, so an autosave is identical to
  a manual one.
- A brief **AUTOSAVED** indicator flashes to confirm each save.

The chosen mode persists in the mod's save data. Default is `ON EVENTS`;
switch it in OPTIONS.

## Testing

Enable the mod, open OPTIONS and confirm the AUTOSAVE row cycles
`ON EVENTS / EVERY 5 MIN / OFF`. In `ON EVENTS`, catch a Pokemon or win a
trainer battle and watch for the AUTOSAVED flash once you're back walking
around. Reset without manually saving and confirm your progress is kept.
