-- autosave
-- ------------------------------------------------------------------
-- Automatically saves your game, on a schedule you choose in OPTIONS:
--
--   ON EVENTS   - after catching a Pokemon, a level up, an evolution, or a
--                 trainer/gym battle (the moments you don't want to lose).
--   EVERY 5 MIN - a plain timed autosave.
--   OFF         - never (the vanilla behavior).
--
-- Saves are DEFERRED to the moment you are back in free-roam overworld with
-- nothing on top (no battle, menu, or text box), so a save never lands mid
-- battle. It uses the engine's own Game:writeSave (the same one the SAVE
-- menu calls), so an autosave is identical to a manual one.

local MODES = { "EVENTS", "TIMED", "OFF" }
local MODE_LABEL = { EVENTS = "ON EVENTS", TIMED = "TIMED", OFF = "OFF" }
local INTERVALS = { 1, 2, 3, 5, 10, 15, 20, 30 } -- timed-mode choices, minutes
local FLASH_FRAMES = 100     -- how long "AUTOSAVED" stays on screen
local SHOW_INDICATOR = true

return function(mod)
  local pending = false -- a save is wanted; performed when it's safe
  local timer = 0       -- timed-mode accumulator (seconds)
  local flash = 0       -- frames left to show the indicator

  local function getMode() return mod.save:get("autosave_mode", "EVENTS") end
  local function cycleMode()
    local cur, idx = getMode(), 1
    for i, v in ipairs(MODES) do if v == cur then idx = i end end
    mod.save:set("autosave_mode", MODES[(idx % #MODES) + 1])
  end

  local function getInterval() return mod.save:get("autosave_interval", 5) end -- minutes
  local function cycleInterval()
    local cur, idx = getInterval(), 1
    for i, v in ipairs(INTERVALS) do if v == cur then idx = i end end
    mod.save:set("autosave_interval", INTERVALS[(idx % #INTERVALS) + 1])
  end

  -- ------- the progress moments (EVENTS mode) ----------------------
  -- Any of these just requests a save; it happens once we're safe.
  mod.events:on("pokemon.caught", function() if getMode() == "EVENTS" then pending = true end end)
  mod.events:on("pokemon.level_up", function() if getMode() == "EVENTS" then pending = true end end)
  mod.events:on("pokemon.evolved", function() if getMode() == "EVENTS" then pending = true end end)
  mod.events:on("battle.ended", function(ev)
    if getMode() == "EVENTS" and ev and ev.battle and ev.battle.kind == "trainer" then
      pending = true
    end
  end)

  -- ------- perform the save when it's safe -------------------------
  mod.hooks:wrap("core.update", function(next, game, dt)
    local result = next(game, dt)
    if not (game and game.save) then return result end

    local mode = getMode()
    if mode == "TIMED" and type(dt) == "number" then
      timer = timer + dt
      if timer >= getInterval() * 60 then timer = 0; pending = true end
    elseif mode == "OFF" then
      pending = false
    end

    if pending then
      local top = game.stack and game.stack.top and game.stack:top()
      if top and top.isOverworld then -- free roam, nothing on top
        pending = false
        local ok = pcall(function() return game:writeSave() end)
        if ok then
          -- prefer the shared tweaks popup (styled + configurable); else flash
          local tw = mod.find("tweaks")
          if tw and tw.exports and tw.exports.push then
            tw.exports.push("AUTOSAVED")
          else
            flash = FLASH_FRAMES
          end
        end
      end
    end

    if flash > 0 then flash = flash - 1 end
    return result
  end)

  -- ------- a brief on-screen confirmation --------------------------
  if SHOW_INDICATOR then
    mod.hooks:wrap("render.hud", function(next, game, viewport)
      local r = next(game, viewport)
      if flash > 0 then
        local s = math.max(1, math.floor((viewport and viewport.scale) or 2))
        local label = "AUTOSAVED"
        local w = (viewport and viewport.width) or 240
        local x = w - #label * 6 * s - 4 * s
        local y = ((viewport and viewport.gameY) or 0) + 3 * s
        love.graphics.push("all")
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.print(label, x + s, y + s, 0, s, s)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(label, x, y, 0, s, s)
        love.graphics.pop()
      end
      return r
    end)
  end

  -- ------- OPTIONS row: pick the mode ------------------------------
  mod.hooks:wrap("ui.options.rows", function(next, game, rows)
    local out = next(game, rows)
    if type(out) ~= "table" then return out end
    out[#out + 1] = {
      id = "autosave_mode",
      label = "AUTOSAVE",
      value = function() return MODE_LABEL[getMode()] or "?" end,
      activate = function() cycleMode() end,
    }
    -- interval selector; only meaningful in TIMED mode
    out[#out + 1] = {
      id = "autosave_interval",
      label = "SAVE EVERY",
      value = function()
        if getMode() ~= "TIMED" then return "-" end
        return getInterval() .. " MIN"
      end,
      activate = function() cycleInterval() end,
    }
    return out
  end)
end
