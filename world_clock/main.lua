-- world_clock
-- ------------------------------------------------------------------
-- A small in-game clock other mods can build on.
--
-- HOW IT WORKS
--   * core.update(next, game, dt) runs every frame; dt is real seconds.
--     We convert that to game-minutes and accumulate a running total.
--   * The total lives in mod.save, which is serialized into the normal
--     Pokemon save. So the clock is a PLAYTIME clock: it advances while
--     you play, pauses when the game is closed, and resumes at the exact
--     same time when you load the save back up.
--   * Other mods read the time and react to it through this mod's
--     `exports` table (mod.find("world_clock").exports) and through the
--     day/hour-change events emitted on the shared event bus.
--
-- TUNING (all safe to change):
local MINUTES_PER_SECOND = 1      -- 1 real second = 1 game minute
                                  -- => a full 24h game-day = 24 real minutes
local START_MINUTES = 8 * 60      -- new games begin at Day 1, 08:00
local SHOW_CLOCK_HUD = true       -- small on-screen "DAY 1 08:15" readout

local MINUTES_PER_DAY = 24 * 60

-- ------- pure time helpers ----------------------------------------

local function clockFromTotal(total)
  total = math.max(0, math.floor(total or 0))
  local intoDay = total % MINUTES_PER_DAY
  return {
    day = math.floor(total / MINUTES_PER_DAY) + 1, -- Day 1 is the first day
    hour = math.floor(intoDay / 60),
    minute = intoDay % 60,
    total = total,
  }
end

local function phaseFor(hour)
  if hour >= 5 and hour < 10 then return "morning"
  elseif hour >= 10 and hour < 18 then return "day"
  elseif hour >= 18 and hour < 21 then return "evening"
  else return "night" end
end

return function(mod)
  -- sub-minute accumulator; in-memory only (losing <1 game-minute across a
  -- reload is irrelevant, and keeping it out of the save avoids churn)
  local frac = 0

  -- Read/write the authoritative total through mod.save so the value always
  -- belongs to whichever save is currently active, and persists with it.
  local function getTotal()
    return mod.save:get("total_minutes", START_MINUTES)
  end
  local function setTotal(v)
    mod.save:set("total_minutes", v)
  end

  -- ------- the tick: advance time each frame -----------------------

  mod.hooks:wrap("core.update", function(next, game, dt)
    -- Always let the game update first, unconditionally -- never pause the
    -- simulation. The clock only advances when a save is actually active
    -- (not on the launcher / title screen, where mod.save has no home).
    local result = next(game, dt)

    if game and game.save and type(dt) == "number" and dt > 0 then
      frac = frac + dt * MINUTES_PER_SECOND
      if frac >= 1 then
        local add = math.floor(frac)
        frac = frac - add

        local before = clockFromTotal(getTotal())
        local total = before.total + add
        setTotal(total)
        local after = clockFromTotal(total)

        -- Fire boundary events so listeners (merchants, day/night, ...)
        -- can react. Emitted under this mod's own namespace.
        if after.hour ~= before.hour or after.day ~= before.day then
          mod.events:emit("mod.world_clock.hour_changed", after)
        end
        if after.day ~= before.day then
          mod.events:emit("mod.world_clock.day_changed", after)
        end
      end
    end

    return result
  end)

  -- ------- optional on-screen readout ------------------------------

  if SHOW_CLOCK_HUD then
    mod.hooks:wrap("render.hud", function(next, game, viewport)
      local r = next(game, viewport)
      if game and game.save then
        local c = clockFromTotal(getTotal())
        local label = string.format("DAY %d  %02d:%02d", c.day, c.hour, c.minute)
        local s = math.max(1, math.floor((viewport and viewport.scale) or 2))
        local x = ((viewport and viewport.gameX) or 0) + 3 * s
        local y = ((viewport and viewport.gameY) or 0) + 3 * s
        love.graphics.push("all")
        -- drop shadow for legibility over any background, no font asset needed
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.print(label, x + s, y + s, 0, s, s)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(label, x, y, 0, s, s)
        love.graphics.pop()
      end
      return r
    end)
  end

  -- ------- public API for other mods -------------------------------
  -- Read with: local wc = mod.find("world_clock"); wc.exports.clock()

  mod.exports = {
    version = 1,
    -- total elapsed game-minutes since Day 1 00:00
    totalMinutes = function() return clockFromTotal(getTotal()).total end,
    -- { day, hour, minute, total }
    clock = function() return clockFromTotal(getTotal()) end,
    -- "morning" | "day" | "evening" | "night"
    phase = function() return phaseFor(clockFromTotal(getTotal()).hour) end,
    isDaytime = function()
      local h = clockFromTotal(getTotal()).hour
      return h >= 6 and h < 20
    end,
  }
end
