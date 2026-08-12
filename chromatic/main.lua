-- chromatic: retro RGB-split (chromatic aberration), no shader - the color
-- channels are drawn at small offsets. OPTIONS: OFF / SUBTLE / MEDIUM / STRONG.
local LEVELS = { "OFF", "SUBTLE", "MEDIUM", "STRONG" }
local OFFSET = { 1, 2, 3 } -- device-pixel split

return function(mod)
  local out, off = nil, 0
  local function ensure(w, h)
    if not out or out:getWidth() ~= w or out:getHeight() ~= h then
      if out then out:release() end
      out = love.graphics.newCanvas(w, h)
    end
    return out
  end
  mod.content.render_pipelines:register("chromatic", {
    label = "RGB SPLIT",
    levels = LEVELS,
    priority = 2,
    available = function() return love and love.graphics and love.graphics.newCanvas ~= nil end,
    update = function(dt, level) off = OFFSET[level] or 0 end,
    present = function(canvas, ctx)
      if canvas == nil or off <= 0 then return canvas end
      local w, h = canvas:getWidth(), canvas:getHeight()
      local o = ensure(w, h)
      local d = off * math.max(1, math.floor(h / 240))
      love.graphics.push("all")
      love.graphics.setCanvas(o)
      love.graphics.clear(0, 0, 0, 1)
      love.graphics.setBlendMode("add", "premultiplied")
      love.graphics.setColor(1, 0, 0, 1); love.graphics.draw(canvas, -d, 0) -- red left
      love.graphics.setColor(0, 1, 0, 1); love.graphics.draw(canvas, 0, 0)  -- green center
      love.graphics.setColor(0, 0, 1, 1); love.graphics.draw(canvas, d, 0)  -- blue right
      love.graphics.pop()
      return o
    end,
  })
end
