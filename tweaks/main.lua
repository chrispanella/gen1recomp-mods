-- tweaks
-- ------------------------------------------------------------------
-- A shared settings hub. Other mods read it (mod.find("tweaks").exports) so a
-- single OPTIONS panel controls how every mod behaves. Two things live here:
--
--   POPUPS  - the style of the little on-screen messages mods show (material
--             finds, the lottery draw, etc.): OFF / TEXT-only / FULL bar, plus
--             color, size, bold, how long it stays, and a sound on/off.
--   BATTLE DIFF - NORMAL / HARD / BRUTAL, which the challenge mods read to make
--             their teams tougher (a tier bump and a level multiplier).
--
-- Nothing here is required: a mod that finds tweaks missing just falls back to
-- its own defaults, so every mod still works on its own.

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

return function(mod)
  local function get(k, d) return mod.save:get(k, d) end
  local function set(k, v) mod.save:set(k, v) end
  local function cycleStr(k, list, default)
    local cur, idx = get(k, default), 1
    for i, v in ipairs(list) do if v == cur then idx = i end end
    set(k, list[(idx % #list) + 1])
  end
  local function colorIdx() return get("popup_color", 1) end

  -- ---- shared state + exports --------------------------------------
  local G                        -- latest game handle (for Sound + data)
  local toastText, toastT = "", 0

  mod.exports = {
    -- show a popup with the player's chosen style; no-op when popups are OFF
    push = function(text)
      if get("popup_mode", "FULL") == "OFF" then return end
      toastText = tostring(text or "")
      toastT = TIME_FRAMES[get("popup_time", "MED")] or 240
      if get("popup_sound", "ON") == "ON" and G and G.data then
        pcall(function() require("src.core.Sound").play(G.data, SOUND_NAME) end)
      end
    end,
    -- read by the challenge mods: { name, tierBump, levelMult }
    difficulty = function()
      local d = DIFFS[get("difficulty_idx", 1)] or DIFFS[1]
      return { name = d.name, tierBump = d.tierBump, levelMult = d.levelMult }
    end,
    popupsOn = function() return get("popup_mode", "FULL") ~= "OFF" end,
  }

  -- ---- lifecycle: tick the timer, keep the game handle -------------
  mod.hooks:wrap("core.update", function(next, game, dt)
    local r = next(game, dt); G = game
    if toastT > 0 then toastT = toastT - 1 end
    return r
  end)

  -- ---- draw the current popup in the chosen style -----------------
  mod.hooks:wrap("render.hud", function(next, game, viewport)
    local r = next(game, viewport)
    local mode = get("popup_mode", "FULL")
    if toastT > 0 and mode ~= "OFF" then
      local vp = viewport or {}
      local base = math.max(1, math.floor(vp.scale or 2))
      local s = math.max(1, math.floor(base * (SIZE_MULT[get("popup_size", "MED")] or 1.5)))
      local w = vp.width or 240
      local col = COLORS[colorIdx()] or COLORS[1]
      local a = math.min(1, toastT / 45)                 -- fade over the last ~0.75s
      local bold = get("popup_bold", "OFF") == "ON"
      local y = (vp.gameY or 0) + 5 * base
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
      else                                               -- TEXT only
        tx = 4 * base
      end
      love.graphics.setColor(0, 0, 0, a)                 -- shadow
      love.graphics.print(toastText, tx + s, y + s, 0, s, s)
      love.graphics.setColor(col.rgb[1], col.rgb[2], col.rgb[3], a)
      love.graphics.print(toastText, tx, y, 0, s, s)
      if bold then love.graphics.print(toastText, tx + 1, y, 0, s, s) end -- faux bold
      love.graphics.pop()
    end
    return r
  end)

  -- ---- one OPTIONS panel for every mod ----------------------------
  local function gated(k, d)                              -- "-" while popups OFF
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
    add("tw_popup", "POPUPS",
        function() return get("popup_mode", "FULL") end,
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
    return out
  end)
end
