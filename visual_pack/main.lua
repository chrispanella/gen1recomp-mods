-- visual_pack
-- ------------------------------------------------------------------
-- One mod bundling every visual enhancement. Each effect is still its own
-- render pipeline, so the engine gives each its own OPTIONS row + on/off
-- ladder, and they STACK - turn on as many as you like. Nothing here edits
-- the engine; a pipeline that ever throws is safely retired to flat 2D.
--
-- Effects: DAY/NIGHT lighting, CRT lines, vignette, letterbox, weather,
-- ambient motes, RGB split, film grain, night stars, color grade, duotone.

-- ------- shared helpers -------------------------------------------
local function canvasCache()
  local c
  return function(w, h)
    if not c or c:getWidth() ~= w or c:getHeight() ~= h then
      if c then c:release() end
      c = love.graphics.newCanvas(w, h)
    end
    return c
  end
end

local function currentHour(mod)
  local wc = mod.find("world_clock")
  if wc and wc.exports and wc.exports.clock then
    local ok, c = pcall(wc.exports.clock)
    if ok and type(c) == "table" and c.hour then return c.hour end
  end
  local ok, t = pcall(os.date, "*t")
  if ok and type(t) == "table" and t.hour then return t.hour end
  return 12
end

local function haveCanvas() return love and love.graphics and love.graphics.newCanvas ~= nil end
local function haveShader() return love and love.graphics and love.graphics.newShader ~= nil end

local GRADE_SRC = [[
extern number amt;
vec4 effect(vec4 color, Image tex, vec2 uv, vec2 sc) {
  vec4 p = Texel(tex, uv);
  vec3 rgb = p.rgb;
  float l = dot(rgb, vec3(0.299, 0.587, 0.114));
  rgb = mix(vec3(l), rgb, 1.0 + 0.6 * amt);
  rgb = mix(vec3(0.5), rgb, 1.0 + 0.22 * amt);
  return vec4(clamp(rgb, 0.0, 1.0), p.a) * color;
}
]]
local DUO_SRC = [[
extern vec3 lo; extern vec3 hi; extern number amt;
vec4 effect(vec4 color, Image tex, vec2 uv, vec2 sc) {
  vec4 p = Texel(tex, uv);
  float l = dot(p.rgb, vec3(0.299, 0.587, 0.114));
  vec3 duo = mix(lo, hi, l);
  return vec4(mix(p.rgb, duo, amt), p.a) * color;
}
]]
local DUO_RAMP = {
  { { 0.06, 0.22, 0.06 }, { 0.61, 0.74, 0.06 } },
  { { 0.20, 0.12, 0.05 }, { 0.98, 0.86, 0.62 } },
  { { 0.03, 0.03, 0.05 }, { 0.95, 0.95, 0.98 } },
}

-- ===== settings hub (merged from the old tweaks mod) =========================
-- The shared popup style + BATTLE DIFF + RESET GRAPHICS live here now. Other
-- mods read them via mod.find("visual_pack").exports and degrade gracefully
-- when this pack is not installed.
local COLORS = {
  { name = "GREEN", rgb = { 0.60, 1.00, 0.55 } },
  { name = "WHITE", rgb = { 1.00, 1.00, 1.00 } },
  { name = "GOLD",  rgb = { 1.00, 0.85, 0.30 } },
  { name = "CYAN",  rgb = { 0.50, 0.90, 1.00 } },
  { name = "RED",   rgb = { 1.00, 0.50, 0.50 } },
  { name = "PINK",  rgb = { 1.00, 0.62, 0.85 } },
}
local MODES = { "FULL", "TEXT", "OFF" }
local SIZE_ORDER = { "SMALL", "MED", "LARGE" }
local SIZE_MULT  = { SMALL = 1.0, MED = 1.5, LARGE = 2.0 }
local TIME_ORDER = { "SHORT", "MED", "LONG" }
local TIME_FRAMES = { SHORT = 120, MED = 240, LONG = 420 }
local DIFFS = {
  { name = "NORMAL", tierBump = 0, levelMult = 1.00 },
  { name = "HARD",   tierBump = 1, levelMult = 1.15 },
  { name = "BRUTAL", tierBump = 2, levelMult = 1.30 },
}
local SOUND_NAME = "Get_Key_Item"

-- per-map, per-day weather: each map gets a deterministic condition that changes
-- every real day (Pewter rainy today, clear tomorrow; Pallet clear today, foggy
-- tomorrow). Weighted toward clear. 0 clear / 1 rain / 2 snow / 3 fog.
local WEATHER_TYPES = { "clear", "rain", "clear", "snow", "clear", "fog", "rain", "clear" }
local WEATHER_CODE = { clear = 0, rain = 1, snow = 2, fog = 3 }
local function wxRealDay() return math.floor((os.time and os.time() or 0) / 86400) end
local function weatherFor(map, day)
  if not map then return 0 end
  local s, str = 5381, tostring(map) .. "|" .. tostring(day)
  for i = 1, #str do s = (s * 33 + str:byte(i)) % 2147483647 end
  return WEATHER_CODE[WEATHER_TYPES[(s % #WEATHER_TYPES) + 1]] or 0
end

return function(mod)
  local P = mod.content.render_pipelines
  local G -- latest game handle (set by core.update below), shared by weather + popups

  -- draw the frame into an out-canvas (premultiplied) so overlays can follow
  local function base(ensure, canvas)
    local w, h = canvas:getWidth(), canvas:getHeight()
    local o = ensure(w, h)
    love.graphics.push("all")
    love.graphics.setCanvas(o)
    love.graphics.clear(0, 0, 0, 0)
    love.graphics.setBlendMode("alpha", "premultiplied")
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(canvas)
    love.graphics.setBlendMode("alpha")
    return o, w, h
  end

  -- ===== SKY & WEATHER ===========================================
  -- One "living sky" system under a single toggle: time-of-day lighting,
  -- twinkling stars at night, and weather that varies by map and by real day.
  do
    local ensure = canvasCache()
    local tr, tg, tb, intensity, mode, t = 1, 1, 1, 0, 0, 0
    local STR = { 0.35, 0.65, 1.0 }
    local function tintFor(hh)
      if hh < 5 or hh >= 21 then return 0.52, 0.58, 0.85
      elseif hh < 8 then return 0.98, 0.86, 0.90
      elseif hh < 18 then return 1, 1, 1
      else return 1.0, 0.80, 0.62 end
    end
    P:register("vp_sky", {
      label = "SKY & WEATHER", levels = { "OFF", "SUBTLE", "MEDIUM", "STRONG" }, priority = 10,
      available = haveCanvas,
      update = function(dt, level)
        t = t + (dt or 0)
        intensity = STR[level] or 0
        if intensity <= 0 then mode = 0; return end
        local r, g, b = tintFor(currentHour(mod))
        tr, tg, tb = 1 + (r - 1) * intensity, 1 + (g - 1) * intensity, 1 + (b - 1) * intensity
        mode = weatherFor(G and G.save and G.save.player and G.save.player.map, wxRealDay())
      end,
      worldPresent = function(canvas, ctx)
        if canvas == nil or intensity <= 0 then return canvas end
        local w, h = canvas:getWidth(), canvas:getHeight()
        local o = ensure(w, h)
        love.graphics.push("all")
        love.graphics.setCanvas(o); love.graphics.clear(0, 0, 0, 0)
        -- 1) time-of-day tinted world
        love.graphics.setBlendMode("alpha", "premultiplied")
        love.graphics.setColor(tr, tg, tb, 1); love.graphics.draw(canvas)
        love.graphics.setBlendMode("alpha")
        -- 2) twinkling stars at night
        local hh = currentHour(mod)
        if hh < 6 or hh >= 20 then
          love.graphics.setBlendMode("add")
          local r = math.max(1, h / 320)
          for i = 1, 60 do
            local x = (i * 97) % w
            local y = (i * 43) % math.floor(h * 0.45)
            local tw = 0.35 + 0.35 * (0.5 + 0.5 * math.sin(t * 2 + i * 1.7))
            love.graphics.setColor(1, 1, 0.95, tw * intensity); love.graphics.circle("fill", x, y, r)
          end
          love.graphics.setBlendMode("alpha")
        end
        -- 3) weather (per map, per real day)
        if mode > 0 then
          local px = math.max(1, h / 260)
          if mode == 1 then
            love.graphics.setColor(0.6, 0.72, 1.0, 0.5); love.graphics.setLineWidth(px)
            for i = 1, 90 do local x = (i * 41) % w; local y = (i * 67 + t * 520) % h; love.graphics.line(x, y, x - px * 4, y + px * 10) end
          elseif mode == 2 then
            love.graphics.setColor(1, 1, 1, 0.85)
            for i = 1, 100 do local x = ((i * 53) + math.sin(t * 0.8 + i) * 8) % w; local y = (i * 61 + t * 130) % h; love.graphics.circle("fill", x, y, px) end
          else
            love.graphics.setColor(0.82, 0.84, 0.88, 0.22 + 0.06 * (0.5 + 0.5 * math.sin(t * 0.4))); love.graphics.rectangle("fill", 0, 0, w, h)
          end
        end
        love.graphics.pop()
        return o
      end,
    })
  end

  -- ===== AMBIENT MOTES ===========================================
  do
    local ensure = canvasCache()
    local n, t = 0, 0
    local CT = { 24, 48, 90 }
    P:register("vp_motes", {
      label = "MOTES", levels = { "OFF", "FEW", "SOME", "MANY" }, priority = 7,
      available = haveCanvas,
      update = function(dt, level) n = CT[level] or 0; t = t + (dt or 0) end,
      worldPresent = function(canvas, ctx)
        if canvas == nil or n <= 0 then return canvas end
        local o, w, h = base(ensure, canvas)
        love.graphics.setBlendMode("add")
        local r = math.max(1, h / 240)
        for i = 1, n do
          local x = ((i * 71) + math.sin(t * 0.5 + i) * 14) % w
          local y = (h - (i * 37 + t * 18) % h)
          local a = 0.15 + 0.15 * (0.5 + 0.5 * math.sin(t * 2 + i))
          love.graphics.setColor(1.0, 0.98, 0.8, a); love.graphics.circle("fill", x, y, r)
        end
        love.graphics.pop()
        return o
      end,
    })
  end

  -- ===== COLOR GRADE (shader) ====================================
  do
    local ensure = canvasCache()
    local amt, shader = 0, nil
    local AMT = { 0.35, 0.7, 1.0 }
    P:register("vp_grade", {
      label = "COLOR GRADE", levels = { "OFF", "SOFT", "RICH", "MAX" }, priority = 6,
      available = haveShader,
      update = function(dt, level) amt = AMT[level] or 0 end,
      present = function(canvas, ctx)
        if canvas == nil or amt <= 0 then return canvas end
        if shader == nil then local ok, s = pcall(love.graphics.newShader, GRADE_SRC); shader = ok and s or false end
        if not shader then return canvas end
        local w, h = canvas:getWidth(), canvas:getHeight()
        local o = ensure(w, h)
        love.graphics.push("all")
        love.graphics.setCanvas(o); love.graphics.clear(0, 0, 0, 0)
        love.graphics.setBlendMode("alpha", "premultiplied")
        shader:send("amt", amt); love.graphics.setShader(shader)
        love.graphics.setColor(1, 1, 1, 1); love.graphics.draw(canvas)
        love.graphics.pop()
        return o
      end,
    })
  end

  -- ===== DUOTONE (shader) ========================================
  do
    local ensure = canvasCache()
    local ramp, shader = nil, nil
    P:register("vp_duotone", {
      label = "DUOTONE", levels = { "OFF", "GB GREEN", "SEPIA", "NOIR" }, priority = 6,
      available = haveShader,
      update = function(dt, level) ramp = DUO_RAMP[level] or nil end,
      present = function(canvas, ctx)
        if canvas == nil or ramp == nil then return canvas end
        if shader == nil then local ok, s = pcall(love.graphics.newShader, DUO_SRC); shader = ok and s or false end
        if not shader then return canvas end
        local w, h = canvas:getWidth(), canvas:getHeight()
        local o = ensure(w, h)
        love.graphics.push("all")
        love.graphics.setCanvas(o); love.graphics.clear(0, 0, 0, 0)
        love.graphics.setBlendMode("alpha", "premultiplied")
        shader:send("lo", ramp[1]); shader:send("hi", ramp[2]); shader:send("amt", 1.0)
        love.graphics.setShader(shader)
        love.graphics.setColor(1, 1, 1, 1); love.graphics.draw(canvas)
        love.graphics.pop()
        return o
      end,
    })
  end

  -- ===== CRT LINES ===============================================
  do
    local ensure = canvasCache()
    local intensity = 0
    local STR = { 0.15, 0.28, 0.45 }
    P:register("vp_crt", {
      label = "CRT LINES", levels = { "OFF", "SUBTLE", "MEDIUM", "HEAVY" }, priority = 5,
      available = haveCanvas,
      update = function(dt, level) intensity = STR[level] or 0 end,
      present = function(canvas, ctx)
        if canvas == nil or intensity <= 0 then return canvas end
        local o, w, h = base(ensure, canvas)
        love.graphics.setColor(0, 0, 0, intensity)
        local step = math.max(2, math.floor(h / 220) * 2)
        for y = 0, h - 1, step do love.graphics.rectangle("fill", 0, y, w, math.max(1, step / 2)) end
        love.graphics.pop()
        return o
      end,
    })
  end

  -- ===== VIGNETTE ================================================
  do
    local ensure = canvasCache()
    local vig, vigW, vigH, intensity = nil, 0, 0, 0
    local STR = { 0.35, 0.6, 0.9 }
    local function ensureVig(w, h)
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
    P:register("vp_vignette", {
      label = "VIGNETTE", levels = { "OFF", "SUBTLE", "MEDIUM", "STRONG" }, priority = 4,
      available = function() return haveCanvas() and love.image ~= nil end,
      update = function(dt, level) intensity = STR[level] or 0 end,
      present = function(canvas, ctx)
        if canvas == nil or intensity <= 0 then return canvas end
        local o, w, h = base(ensure, canvas)
        love.graphics.setColor(1, 1, 1, intensity); love.graphics.draw(ensureVig(w, h))
        love.graphics.pop()
        return o
      end,
    })
  end

  -- ===== LETTERBOX ===============================================
  do
    local ensure = canvasCache()
    local frac = 0
    local FR = { 0.07, 0.12, 0.18 }
    P:register("vp_letterbox", {
      label = "LETTERBOX", levels = { "OFF", "THIN", "WIDE", "EPIC" }, priority = 3,
      available = haveCanvas,
      update = function(dt, level) frac = FR[level] or 0 end,
      present = function(canvas, ctx)
        if canvas == nil or frac <= 0 then return canvas end
        local o, w, h = base(ensure, canvas)
        local bar = math.floor(h * frac)
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.rectangle("fill", 0, 0, w, bar)
        love.graphics.rectangle("fill", 0, h - bar, w, bar)
        love.graphics.pop()
        return o
      end,
    })
  end

  -- ===== RGB SPLIT ===============================================
  do
    local ensure = canvasCache()
    local off = 0
    local OFS = { 1, 2, 3 }
    P:register("vp_chromatic", {
      label = "RGB SPLIT", levels = { "OFF", "SUBTLE", "MEDIUM", "STRONG" }, priority = 2,
      available = haveCanvas,
      update = function(dt, level) off = OFS[level] or 0 end,
      present = function(canvas, ctx)
        if canvas == nil or off <= 0 then return canvas end
        local w, h = canvas:getWidth(), canvas:getHeight()
        local o = ensure(w, h)
        local d = off * math.max(1, math.floor(h / 240))
        love.graphics.push("all")
        love.graphics.setCanvas(o); love.graphics.clear(0, 0, 0, 1)
        love.graphics.setBlendMode("add", "premultiplied")
        love.graphics.setColor(1, 0, 0, 1); love.graphics.draw(canvas, -d, 0)
        love.graphics.setColor(0, 1, 0, 1); love.graphics.draw(canvas, 0, 0)
        love.graphics.setColor(0, 0, 1, 1); love.graphics.draw(canvas, d, 0)
        love.graphics.pop()
        return o
      end,
    })
  end

  -- ===== FILM GRAIN ==============================================
  do
    local ensure = canvasCache()
    local amt = 0
    local AMT = { 0.04, 0.08, 0.14 }
    P:register("vp_grain", {
      label = "FILM GRAIN", levels = { "OFF", "LIGHT", "MEDIUM", "HEAVY" }, priority = 1,
      available = haveCanvas,
      update = function(dt, level) amt = AMT[level] or 0 end,
      present = function(canvas, ctx)
        if canvas == nil or amt <= 0 then return canvas end
        local o, w, h = base(ensure, canvas)
        local count = math.floor(w * h / 900)
        for _ = 1, count do
          local x = math.floor(math.random() * w)
          local y = math.floor(math.random() * h)
          local v = math.random() < 0.5 and 0 or 1
          love.graphics.setColor(v, v, v, amt); love.graphics.rectangle("fill", x, y, 1, 1)
        end
        love.graphics.pop()
        return o
      end,
    })
  end

  -- ===== settings hub body ===================================================
  local function get(k, d) return mod.save:get(k, d) end
  local function set(k, v) mod.save:set(k, v) end
  local function cycleStr(k, list, default)
    local cur, idx = get(k, default), 1
    for i, v in ipairs(list) do if v == cur then idx = i end end
    set(k, list[(idx % #list) + 1])
  end
  local function colorIdx() return get("popup_color", 1) end

  local toastText, toastT = "", 0

  mod.exports = {
    push = function(text)
      if get("popup_mode", "FULL") == "OFF" then return end
      toastText = tostring(text or "")
      toastT = TIME_FRAMES[get("popup_time", "MED")] or 240
      if get("popup_sound", "ON") == "ON" and G and G.data then
        pcall(function() require("src.core.Sound").play(G.data, SOUND_NAME) end)
      end
    end,
    difficulty = function()
      local d = DIFFS[get("difficulty_idx", 1)] or DIFFS[1]
      return { name = d.name, tierBump = d.tierBump, levelMult = d.levelMult }
    end,
    popupsOn = function() return get("popup_mode", "FULL") ~= "OFF" end,
  }

  mod.hooks:wrap("core.update", function(next, game, dt)
    local r = next(game, dt); G = game
    if toastT > 0 then toastT = toastT - 1 end
    return r
  end)

  mod.hooks:wrap("render.hud", function(next, game, viewport)
    local r = next(game, viewport)
    local mode = get("popup_mode", "FULL")
    if toastT > 0 and mode ~= "OFF" then
      local vp = viewport or {}
      local baseS = math.max(1, math.floor(vp.scale or 2))
      local s = math.max(1, math.floor(baseS * (SIZE_MULT[get("popup_size", "MED")] or 1.5)))
      local w = vp.width or 240
      local col = COLORS[colorIdx()] or COLORS[1]
      local a = math.min(1, toastT / 45)
      local bold = get("popup_bold", "OFF") == "ON"
      local y = (vp.gameY or 0) + 5 * baseS
      local tw = #toastText * 6 * s
      local tx
      love.graphics.push("all")
      if mode == "FULL" then
        love.graphics.setColor(0, 0, 0, 0.72 * a)
        love.graphics.rectangle("fill", 0, y, w, 9 * s)
        love.graphics.setColor(col.rgb[1], col.rgb[2], col.rgb[3], a)
        love.graphics.rectangle("fill", 0, y, w, math.max(1, math.floor(s / 2)))
        tx = math.floor((w - tw) / 2)
        y = y + 2 * s
      else
        tx = 4 * baseS
      end
      love.graphics.setColor(0, 0, 0, a)
      love.graphics.print(toastText, tx + s, y + s, 0, s, s)
      love.graphics.setColor(col.rgb[1], col.rgb[2], col.rgb[3], a)
      love.graphics.print(toastText, tx, y, 0, s, s)
      if bold then love.graphics.print(toastText, tx + 1, y, 0, s, s) end
      love.graphics.pop()
    end
    return r
  end)

  local function gated(k, d)
    return function()
      if get("popup_mode", "FULL") == "OFF" then return "-" end
      return get(k, d)
    end
  end
  mod.hooks:wrap("ui.options.rows", function(next, game, rows)
    local out = next(game, rows)
    if type(out) ~= "table" then return out end
    local function add(id, label, valfn, actfn)
      out[#out + 1] = { id = id, label = label, value = valfn, activate = actfn }
    end
    add("tw_popup", "POPUPS", function() return get("popup_mode", "FULL") end,
        function() cycleStr("popup_mode", MODES, "FULL") end)
    add("tw_color", "POPUP COLOR",
        function()
          if get("popup_mode", "FULL") == "OFF" then return "-" end
          return (COLORS[colorIdx()] or COLORS[1]).name
        end,
        function() set("popup_color", (colorIdx() % #COLORS) + 1) end)
    add("tw_size", "POPUP SIZE", gated("popup_size", "MED"),
        function() cycleStr("popup_size", SIZE_ORDER, "MED") end)
    add("tw_bold", "POPUP BOLD", gated("popup_bold", "OFF"),
        function() cycleStr("popup_bold", { "OFF", "ON" }, "OFF") end)
    add("tw_time", "POPUP TIME", gated("popup_time", "MED"),
        function() cycleStr("popup_time", TIME_ORDER, "MED") end)
    add("tw_sound", "POPUP SOUND", gated("popup_sound", "ON"),
        function() cycleStr("popup_sound", { "ON", "OFF" }, "ON") end)
    add("tw_diff", "BATTLE DIFF",
        function() return (DIFFS[get("difficulty_idx", 1)] or DIFFS[1]).name end,
        function() set("difficulty_idx", (get("difficulty_idx", 1) % #DIFFS) + 1) end)
    local nPipes = 0
    pcall(function() nPipes = #require("src.render.Pipelines").list() end)
    if nPipes > 0 then
      add("tw_gfxreset", "RESET GRAPHICS",
          function()
            local on = 0
            pcall(function()
              local Pl = require("src.render.Pipelines")
              for _, e in ipairs(Pl.list()) do if Pl.level(e.id) > 0 then on = on + 1 end end
            end)
            return on > 0 and (on .. " ON") or "ALL OFF"
          end,
          function()
            pcall(function()
              local Pl = require("src.render.Pipelines")
              for _, e in ipairs(Pl.list()) do Pl.setLevel(e.id, 0) end
              pcall(function() require("src.render.Tilt").setLevel(0) end)
              local opts = game.save and game.save.options
              if opts then Pl.syncOptions(opts); opts.tilt = 0 end
            end)
            if mod.exports and mod.exports.push then mod.exports.push("Graphics reset to OFF.") end
          end)
    end
    return out
  end)
end
