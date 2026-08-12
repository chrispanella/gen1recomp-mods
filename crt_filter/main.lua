-- crt_filter: scanline / CRT look over the whole frame.
-- Configurable in OPTIONS (the engine adds a row for each render pipeline):
-- OFF / SUBTLE / MEDIUM / HEAVY.
local LEVELS = { "OFF", "SUBTLE", "MEDIUM", "HEAVY" }
local STRENGTH = { 0.15, 0.28, 0.45 }

return function(mod)
  local out, intensity = nil, 0
  local function ensure(w, h)
    if not out or out:getWidth() ~= w or out:getHeight() ~= h then
      if out then out:release() end
      out = love.graphics.newCanvas(w, h)
    end
    return out
  end
  mod.content.render_pipelines:register("crt_scanlines", {
    label = "CRT LINES",
    levels = LEVELS,
    hotkey = "8",
    priority = 5,
    available = function() return love and love.graphics and love.graphics.newCanvas ~= nil end,
    update = function(dt, level) intensity = STRENGTH[level] or 0 end,
    present = function(canvas, ctx)
      if canvas == nil or intensity <= 0 then return canvas end
      local w, h = canvas:getWidth(), canvas:getHeight()
      local o = ensure(w, h)
      love.graphics.push("all")
      love.graphics.setCanvas(o)
      love.graphics.clear(0, 0, 0, 0)
      love.graphics.setBlendMode("alpha", "premultiplied")
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.draw(canvas)
      love.graphics.setBlendMode("alpha")
      love.graphics.setColor(0, 0, 0, intensity)
      local step = math.max(2, math.floor(h / 220) * 2) -- ~1 dark line per 2 device px
      for y = 0, h - 1, step do
        love.graphics.rectangle("fill", 0, y, w, math.max(1, step / 2))
      end
      love.graphics.pop()
      return o
    end,
  })
end
