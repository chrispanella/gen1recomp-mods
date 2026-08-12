-- letterbox: cinematic black bars top and bottom. OPTIONS: OFF/THIN/WIDE/EPIC.
local LEVELS = { "OFF", "THIN", "WIDE", "EPIC" }
local FRAC = { 0.07, 0.12, 0.18 } -- bar height as a fraction of the frame

return function(mod)
  local out, frac = nil, 0
  local function ensure(w, h)
    if not out or out:getWidth() ~= w or out:getHeight() ~= h then
      if out then out:release() end
      out = love.graphics.newCanvas(w, h)
    end
    return out
  end
  mod.content.render_pipelines:register("letterbox", {
    label = "LETTERBOX",
    levels = LEVELS,
    priority = 3,
    available = function() return love and love.graphics and love.graphics.newCanvas ~= nil end,
    update = function(dt, level) frac = FRAC[level] or 0 end,
    present = function(canvas, ctx)
      if canvas == nil or frac <= 0 then return canvas end
      local w, h = canvas:getWidth(), canvas:getHeight()
      local o = ensure(w, h)
      local bar = math.floor(h * frac)
      love.graphics.push("all")
      love.graphics.setCanvas(o)
      love.graphics.clear(0, 0, 0, 0)
      love.graphics.setBlendMode("alpha", "premultiplied")
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.draw(canvas)
      love.graphics.setBlendMode("alpha")
      love.graphics.setColor(0, 0, 0, 1)
      love.graphics.rectangle("fill", 0, 0, w, bar)
      love.graphics.rectangle("fill", 0, h - bar, w, bar)
      love.graphics.pop()
      return o
    end,
  })
end
