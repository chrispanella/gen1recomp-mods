-- vignette: soft darkening toward the screen edges. OPTIONS: OFF/SUBTLE/MEDIUM/STRONG.
local LEVELS = { "OFF", "SUBTLE", "MEDIUM", "STRONG" }
local STRENGTH = { 0.35, 0.6, 0.9 }

return function(mod)
  local out, vig, vigW, vigH, intensity = nil, nil, 0, 0, 0

  local function ensure(w, h)
    if not out or out:getWidth() ~= w or out:getHeight() ~= h then
      if out then out:release() end
      out = love.graphics.newCanvas(w, h)
    end
    return out
  end

  -- a black-to-transparent radial overlay, built once per size
  local function ensureVignette(w, h)
    if vig and vigW == w and vigH == h then return vig end
    if vig then vig:release() end
    local id = love.image.newImageData(w, h)
    local cx, cy = w / 2, h / 2
    local maxd = math.sqrt(cx * cx + cy * cy)
    id:mapPixel(function(x, y)
      local dx, dy = x - cx, y - cy
      local d = math.sqrt(dx * dx + dy * dy) / maxd
      local a = math.max(0, (d - 0.45)) / 0.55
      return 0, 0, 0, math.min(1, a * a)
    end)
    vig, vigW, vigH = love.graphics.newImage(id), w, h
    return vig
  end

  mod.content.render_pipelines:register("vignette", {
    label = "VIGNETTE",
    levels = LEVELS,
    hotkey = "9",
    priority = 4,
    available = function() return love and love.graphics and love.image ~= nil end,
    update = function(dt, level) intensity = STRENGTH[level] or 0 end,
    present = function(canvas, ctx)
      if canvas == nil or intensity <= 0 then return canvas end
      local w, h = canvas:getWidth(), canvas:getHeight()
      local o = ensure(w, h)
      local v = ensureVignette(w, h)
      love.graphics.push("all")
      love.graphics.setCanvas(o)
      love.graphics.clear(0, 0, 0, 0)
      love.graphics.setBlendMode("alpha", "premultiplied")
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.draw(canvas)
      love.graphics.setBlendMode("alpha")
      love.graphics.setColor(1, 1, 1, intensity)
      love.graphics.draw(v)
      love.graphics.pop()
      return o
    end,
  })
end
