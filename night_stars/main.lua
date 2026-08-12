-- night_stars: twinkling stars over the upper sky at night (menus stay clear).
-- Follows world_clock's in-game hour if present, else your real local time.
-- OPTIONS: OFF / DIM / BRIGHT.
local LEVELS = { "OFF", "DIM", "BRIGHT" }
local BRIGHT = { 0.5, 1.0 }

return function(mod)
  local out, bright, t = nil, 0, 0
  local function ensure(w, h)
    if not out or out:getWidth() ~= w or out:getHeight() ~= h then
      if out then out:release() end
      out = love.graphics.newCanvas(w, h)
    end
    return out
  end
  local function isNight()
    local h
    local wc = mod.find("world_clock")
    if wc and wc.exports and wc.exports.clock then
      local ok, c = pcall(wc.exports.clock)
      if ok and type(c) == "table" and c.hour then h = c.hour end
    end
    if not h then
      local ok, d = pcall(os.date, "*t")
      if ok and type(d) == "table" then h = d.hour end
    end
    h = h or 12
    return h < 6 or h >= 20
  end
  mod.content.render_pipelines:register("night_stars", {
    label = "NIGHT STARS",
    levels = LEVELS,
    priority = 9,
    available = function() return love and love.graphics and love.graphics.newCanvas ~= nil end,
    update = function(dt, level) bright = BRIGHT[level] or 0; t = t + (dt or 0) end,
    worldPresent = function(canvas, ctx)
      if canvas == nil or bright <= 0 or not isNight() then return canvas end
      local w, h = canvas:getWidth(), canvas:getHeight()
      local o = ensure(w, h)
      love.graphics.push("all")
      love.graphics.setCanvas(o)
      love.graphics.clear(0, 0, 0, 0)
      love.graphics.setBlendMode("alpha", "premultiplied")
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.draw(canvas)
      love.graphics.setBlendMode("add")
      local r = math.max(1, h / 320)
      for i = 1, 60 do
        local x = (i * 97) % w
        local y = ((i * 43) % math.floor(h * 0.45))
        local tw = 0.35 + 0.35 * (0.5 + 0.5 * math.sin(t * 2 + i * 1.7))
        love.graphics.setColor(1, 1, 0.95, tw * bright)
        love.graphics.circle("fill", x, y, r)
      end
      love.graphics.pop()
      return o
    end,
  })
end
