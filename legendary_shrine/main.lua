-- legendary_shrine: a mysterious shrine keeper appears on Route 10 each real
-- day. Speak to face a rotating legendary in a wild battle - once per day, so
-- catch it or lose your chance until tomorrow.
local MAP = "ROUTE_10"
local KTEXT = "TEXT_FUN_SHRINE"
local SPRITE = "SPRITE_GAMBLER"
local LEGENDS = {
  { "ARTICUNO", 50 }, { "ZAPDOS", 50 }, { "MOLTRES", 50 },
  { "DRATINI", 30 }, { "LAPRAS", 40 }, { "SNORLAX", 40 }, { "MEWTWO", 60 },
}

local function realDay()
  local ok, t = pcall(os.date, "*t")
  if ok and type(t) == "table" and t.year and t.yday then return t.year * 366 + t.yday end
  return math.floor((os.time and os.time() or 0) / 86400)
end

return function(mod)
  local Commands = require("src.script.Commands")

  local function todaysLegend() return LEGENDS[(realDay() % #LEGENDS) + 1] end

  local function overview()
    if not mod.world then return nil end
    local ok, ov = pcall(function() return mod.world:mapOverview() end)
    return ok and ov or nil
  end
  local function walkable(ov, x, y)
    if not ov or x < 0 or y < 0 or x >= ov.width or y >= ov.height then return false end
    local row = ov.rows[y + 1]
    return row and row:sub(x + 1, x + 1) == "."
  end
  local function pickCell(ov, ow)
    local px, py = ow.player and ow.player.cellX, ow.player and ow.player.cellY
    if not px then return nil end
    local W, seen, q, head = ov.width, {}, { { px, py } }, 1
    seen[py * W + px] = true
    local best
    while head <= #q and head < 4000 do
      local c = q[head]; head = head + 1
      local d = math.abs(c[1] - px) + math.abs(c[2] - py)
      if d >= 3 and d <= 9 and not best then best = c end
      for _, dd in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
        local nx, ny = c[1] + dd[1], c[2] + dd[2]
        if walkable(ov, nx, ny) and not seen[ny * W + nx] then seen[ny * W + nx] = true; q[#q + 1] = { nx, ny } end
      end
    end
    return best
  end

  local spawn = { id = nil }
  local function ensure(ow)
    if spawn.id then return end
    local ov = overview(); if not ov then return end
    local cell = pickCell(ov, ow); if not cell then return end
    local id = mod.world:spawnNpc(MAP, { sprite = SPRITE, text = KTEXT, movement = "STAY", range = "NONE", x = cell[1], y = cell[2] })
    if id then spawn.id = id end
  end

  mod.content.commands:register("legendary_shrine:face", {
    foreground = true,
    fn = function(ctx)
      local today = realDay()
      if mod.save:get("last", -1) == today then
        Commands.show_text(ctx, "The shrine is quiet\nnow. Return when the\vsun rises anew.")
        return
      end
      mod.save:set("last", today)
      local l = todaysLegend()
      Commands.show_text(ctx, "A great presence\nstirs at the shrine...")
      Commands.start_battle(ctx, "wild", l[1], l[2])
    end,
  })

  mod.content.map_scripts:register(MAP, {
    talk = { [KTEXT] = { { "legendary_shrine:face" } } },
    onEnter = function(game, ow) ensure(ow) end,
  })
end
