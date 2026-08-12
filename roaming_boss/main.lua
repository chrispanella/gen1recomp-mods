-- roaming_boss: a tough "Champion in disguise" appears in a different city
-- every few real days. Beat their level-scaled team for a big prize; each
-- appearance can be beaten once.
local CITIES = { "PEWTER_CITY", "CERULEAN_CITY", "VERMILION_CITY",
                 "CELADON_CITY", "FUCHSIA_CITY", "SAFFRON_CITY" }
local SPRITE = "SPRITE_GENTLEMAN"
local BTEXT = "TEXT_FUN_BOSS"
local TRAINER = "OPP_FUN_BOSS"
local PERIOD_DAYS = 3 -- the boss stays in one city this many real days

-- level-tiered teams, picked by the player's average party level
local TIERS = {
  { { level = 16, species = "PIDGEOTTO" }, { level = 17, species = "KADABRA" }, { level = 18, species = "GROWLITHE" } },
  { { level = 26, species = "PIDGEOT" }, { level = 27, species = "KADABRA" }, { level = 28, species = "ARCANINE" }, { level = 28, species = "GYARADOS" } },
  { { level = 36, species = "PIDGEOT" }, { level = 37, species = "ALAKAZAM" }, { level = 38, species = "ARCANINE" }, { level = 38, species = "GYARADOS" }, { level = 39, species = "SNORLAX" } },
  { { level = 48, species = "PIDGEOT" }, { level = 49, species = "ALAKAZAM" }, { level = 50, species = "ARCANINE" }, { level = 51, species = "GYARADOS" }, { level = 52, species = "SNORLAX" }, { level = 53, species = "DRAGONITE" } },
}
local REWARDS = { "RARE_CANDY", "NUGGET", "PP_UP", "MAX_ELIXER" }

local DELTA = { left = { -1, 0 }, right = { 1, 0 }, up = { 0, -1 }, down = { 0, 1 } }
local function realDay()
  local ok, t = pcall(os.date, "*t")
  if ok and type(t) == "table" and t.year and t.yday then return t.year * 366 + t.yday end
  return math.floor((os.time and os.time() or 0) / 86400)
end
local function tierForAvg(a)
  if a < 22 then return 1 elseif a < 32 then return 2 elseif a < 44 then return 3 end
  return 4
end

return function(mod)
  local Commands = require("src.script.Commands")

  mod.content.trainers:register(TRAINER, {
    id = TRAINER, name = "CHAMPION X", baseMoney = 0, basePic = "OPP_BLACKBELT", parties = TIERS,
  })

  local function period() return math.floor(realDay() / PERIOD_DAYS) end
  local function cityNow() return CITIES[(period() % #CITIES) + 1] end
  local function avgLevel(ctx)
    local p = ctx.save and ctx.save.party
    if not p or #p == 0 then return 10 end
    local s, n = 0, 0
    for _, m in ipairs(p) do if m and m.level then s = s + m.level; n = n + 1 end end
    return n > 0 and math.floor(s / n) or 10
  end

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

  local spawn = { id = nil, map = nil }
  local function despawn()
    if spawn.id and mod.world then pcall(function() mod.world:removeNpc(spawn.id) end) end
    spawn.id, spawn.map = nil, nil
  end
  local function ensure(map, ow)
    local target = cityNow()
    if spawn.id and (spawn.map ~= map or map ~= target) then despawn() end
    if map ~= target or spawn.id then return end
    local ov = overview(); if not ov then return end
    local cell = pickCell(ov, ow); if not cell then return end
    local id = mod.world:spawnNpc(map, { sprite = SPRITE, text = BTEXT, movement = "STAY", range = "NONE", x = cell[1], y = cell[2] })
    if id then spawn.id, spawn.map = id, map end
  end

  mod.content.commands:register("roaming_boss:fight", {
    foreground = true,
    fn = function(ctx)
      if mod.save:get("done", -1) == period() then
        Commands.show_text(ctx, "You bested me this\ntime. I'll roam on...\vwe'll meet again!")
        return
      end
      Commands.show_text(ctx, "So you found me.\nShow me your\vstrongest team!")
      -- tweaks BATTLE DIFF bumps the tier up (harder team) when installed
      local tw = mod.find("tweaks")
      local bump = (tw and tw.exports and tw.exports.difficulty and tw.exports.difficulty().tierBump) or 0
      Commands.start_battle(ctx, "trainer", TRAINER, math.min(#TIERS, tierForAvg(avgLevel(ctx)) + bump))
      if ctx.lastCheck then
        mod.save:set("done", period())
        Commands.show_text(ctx, "Magnificent! Take\nthis, champion.")
        Commands.give_item(ctx, REWARDS[(period() % #REWARDS) + 1], 1, true)
        Commands.give_money(ctx, 5000)
      end
    end,
  })

  for _, city in ipairs(CITIES) do
    mod.content.map_scripts:register(city, {
      talk = { [BTEXT] = { { "roaming_boss:fight" } } },
      onEnter = function(game, ow) ensure(city, ow) end,
    })
  end
end
