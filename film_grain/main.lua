-- film_grain: a light animated grain over the whole frame.
-- OPTIONS: OFF / LIGHT / MEDIUM / HEAVY.
local LEVELS = { "OFF", "LIGHT", "MEDIUM", "HEAVY" }
local AMT = { 0.04, 0.08, 0.14 }

return function(mod)
  local out, amt = nil, 0
  local function ensure(w, h)
    if not out or out:getWidth() ~= w or out:getHeight() ~= h then
      if out then out:release() end
      out = love.graphics.newCanvas(w, h)
    end
    return out
  end
  mod.content.render_pipelines:register("film_grain", {
    label = "FILM GRAIN",
    levels = LEVELS,
    priority = 1,
    available = function() return love and love.graphics and love.graphics.newCanvas ~= nil end,
    update = function(dt, level) amt = AMT[level] or 0 end,
    present = function(canvas, ctx)
      if canvas == nil or amt <= 0 then return canvas end
      local w, h = canvas:getWidth(), canvas:getHeight()
      local o = ensure(w, h)
      love.graphics.push("all")
      love.graphics.setCanvas(o)
      love.graphics.clear(0, 0, 0, 0)
      love.graphics.setBlendMode("alpha", "premultiplied")
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.draw(canvas)
      love.graphics.setBlendMode("alpha")
      local count = math.floor(w * h / 900)
      for _ = 1, count do
        local x = math.floor(math.random() * w)
        local y = math.floor(math.random() * h)
        local v = math.random() < 0.5 and 0 or 1
        love.graphics.setColor(v, v, v, amt)
        love.graphics.rectangle("fill", x, y, 1, 1)
      end
      love.graphics.pop()
      return o
    end,
  })
end
