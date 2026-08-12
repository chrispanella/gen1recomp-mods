-- weather_fx: animated weather over the world (menus stay clear).
-- OPTIONS picks the weather: OFF / RAIN / SNOW / FOG.
local LEVELS = { "OFF", "RAIN", "SNOW", "FOG" }

return function(mod)
  local out, mode, t = nil, 0, 0
  local function ensure(w, h)
    if not out or out:getWidth() ~= w or out:getHeight() ~= h then
      if out then out:release() end
      out = love.graphics.newCanvas(w, h)
    end
    return out
  end
  mod.content.render_pipelines:register("weather_fx", {
    label = "WEATHER",
    levels = LEVELS,
    priority = 8,
    available = function() return love and love.graphics and love.graphics.newCanvas ~= nil end,
    update = function(dt, level) mode = level or 0; t = t + (dt or 0) end,
    worldPresent = function(canvas, ctx)
      if canvas == nil or mode <= 0 then return canvas end
      local w, h = canvas:getWidth(), canvas:getHeight()
      local o = ensure(w, h)
      love.graphics.push("all")
      love.graphics.setCanvas(o)
      love.graphics.clear(0, 0, 0, 0)
      love.graphics.setBlendMode("alpha", "premultiplied")
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.draw(canvas)
      love.graphics.setBlendMode("alpha")
      local px = math.max(1, h / 260)
      if mode == 1 then       -- rain
        love.graphics.setColor(0.6, 0.72, 1.0, 0.5)
        love.graphics.setLineWidth(px)
        for i = 1, 90 do
          local x = (i * 41) % w
          local y = (i * 67 + t * 520) % h
          love.graphics.line(x, y, x - px * 4, y + px * 10)
        end
      elseif mode == 2 then   -- snow
        love.graphics.setColor(1, 1, 1, 0.85)
        for i = 1, 100 do
          local x = ((i * 53) + math.sin(t * 0.8 + i) * 8) % w
          local y = (i * 61 + t * 130) % h
          love.graphics.circle("fill", x, y, px)
        end
      else                    -- fog
        love.graphics.setColor(0.82, 0.84, 0.88, 0.22 + 0.06 * (0.5 + 0.5 * math.sin(t * 0.4)))
        love.graphics.rectangle("fill", 0, 0, w, h)
      end
      love.graphics.pop()
      return o
    end,
  })
end
