-- ambient_motes: soft glowing motes drifting over the world (menus stay clear).
-- OPTIONS: OFF / FEW / SOME / MANY.
local LEVELS = { "OFF", "FEW", "SOME", "MANY" }
local COUNT = { 24, 48, 90 }

return function(mod)
  local out, n, t = nil, 0, 0
  local function ensure(w, h)
    if not out or out:getWidth() ~= w or out:getHeight() ~= h then
      if out then out:release() end
      out = love.graphics.newCanvas(w, h)
    end
    return out
  end
  mod.content.render_pipelines:register("ambient_motes", {
    label = "MOTES",
    levels = LEVELS,
    priority = 7,
    available = function() return love and love.graphics and love.graphics.newCanvas ~= nil end,
    update = function(dt, level) n = COUNT[level] or 0; t = t + (dt or 0) end,
    worldPresent = function(canvas, ctx)
      if canvas == nil or n <= 0 then return canvas end
      local w, h = canvas:getWidth(), canvas:getHeight()
      local o = ensure(w, h)
      love.graphics.push("all")
      love.graphics.setCanvas(o)
      love.graphics.clear(0, 0, 0, 0)
      love.graphics.setBlendMode("alpha", "premultiplied")
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.draw(canvas)
      love.graphics.setBlendMode("add")
      local r = math.max(1, h / 240)
      for i = 1, n do
        local x = ((i * 71) + math.sin(t * 0.5 + i) * 14) % w
        local y = (h - (i * 37 + t * 18) % h)
        local a = 0.15 + 0.15 * (0.5 + 0.5 * math.sin(t * 2 + i))
        love.graphics.setColor(1.0, 0.98, 0.8, a)
        love.graphics.circle("fill", x, y, r)
      end
      love.graphics.pop()
      return o
    end,
  })
end
