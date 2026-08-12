-- visual_enhance
-- ------------------------------------------------------------------
-- A visual-enhancement display mode built on the engine's render
-- pipelines. Version 1 adds DYNAMIC DAY/NIGHT LIGHTING: the overworld is
-- tinted by the time of day - cool blue at night, warm at dawn and dusk,
-- neutral at midday. If world_clock is installed it follows the in-game
-- clock; otherwise it follows your real-world local time.
--
-- It runs in the `worldPresent` stage, which colors the WORLD only and
-- leaves menus and text boxes crisp. It uses plain color-modulated drawing
-- (no custom shader), so it is light and safe: if anything ever throws, the
-- engine simply retires the mode and falls back to the flat 2D world.
--
-- Toggle intensity with hotkey 7, or from OPTIONS' display-mode row:
--   OFF / SUBTLE / MEDIUM / STRONG.
--
-- ROADMAP (needs in-game tuning): a color-grade/saturation pass, a soft
-- vignette, an optional CRT/scanline mode, and weather tints.

local LEVELS = { "OFF", "SUBTLE", "MEDIUM", "STRONG" }
local STRENGTH = { 0.35, 0.65, 1.0 } -- indexed by level 1..3

-- ambient tint (a multiply color) for an hour of the day
local function tintForHour(h)
  if h < 5 or h >= 21 then
    return 0.52, 0.58, 0.85 -- night: cool blue
  elseif h < 8 then
    return 0.98, 0.86, 0.90 -- dawn: soft rose
  elseif h < 18 then
    return 1.00, 1.00, 1.00 -- day: neutral
  else
    return 1.00, 0.80, 0.62 -- dusk: warm orange
  end
end

return function(mod)
  local outCanvas
  local tr, tg, tb, intensity = 1, 1, 1, 0

  local function currentHour()
    local wc = mod.find("world_clock")
    if wc and wc.exports and wc.exports.clock then
      local ok, c = pcall(wc.exports.clock)
      if ok and type(c) == "table" and c.hour then return c.hour end
    end
    local ok, t = pcall(os.date, "*t")
    if ok and type(t) == "table" and t.hour then return t.hour end
    return 12
  end

  local function ensureCanvas(w, h)
    if not outCanvas or outCanvas:getWidth() ~= w or outCanvas:getHeight() ~= h then
      if outCanvas then outCanvas:release() end
      outCanvas = love.graphics.newCanvas(w, h)
    end
    return outCanvas
  end

  mod.content.render_pipelines:register("fun_daynight", {
    label = "DAY/NIGHT",
    levels = LEVELS,
    hotkey = "7",
    priority = 10,

    available = function()
      return love ~= nil and love.graphics ~= nil and love.graphics.newCanvas ~= nil
    end,

    -- recompute the effective tint each frame from the level + time of day
    update = function(dt, level)
      intensity = STRENGTH[level] or 0
      local r, g, b = tintForHour(currentHour())
      tr = 1 + (r - 1) * intensity -- lerp white -> tint by intensity
      tg = 1 + (g - 1) * intensity
      tb = 1 + (b - 1) * intensity
    end,

    -- color the world (not the UI), by drawing it modulated by the tint
    worldPresent = function(canvas, ctx)
      if canvas == nil or intensity <= 0 then return canvas end
      local w, h = canvas:getWidth(), canvas:getHeight()
      local out = ensureCanvas(w, h)
      love.graphics.push("all")
      love.graphics.setCanvas(out)
      love.graphics.clear(0, 0, 0, 0)
      love.graphics.setBlendMode("alpha", "premultiplied")
      love.graphics.setColor(tr, tg, tb, 1)
      love.graphics.draw(canvas)
      love.graphics.pop()
      return out
    end,
  })
end
