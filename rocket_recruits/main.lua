-- rocket_recruits
-- ------------------------------------------------------------------
-- A gang of Team Rocket "recruits" hangs out in a city each day as a
-- DAILY CHALLENGE. Beat the gang (one scaled trainer battle) for a
-- level-appropriate cash reward plus a rotating item. The gang roams
-- between cities and its reward rotates on REAL-WORLD days.
--
-- Design notes:
--   * The recruit trainer's baseMoney is 0, so the engine pays nothing
--     automatically; the mod hands out its OWN reward, scaled to the
--     player's average party level and CAPPED, so you never earn an
--     absurd amount no matter how strong you are.
--   * The battle party is picked from tiers by the player's level, so the
--     fight stays a real challenge instead of a pushover.
--   * Built on the runtime world API (spawnNpc/removeNpc) + collision
--     (mapOverview); no map edits. Once beaten, the gang won't rebattle
--     until the next real day.

local CITIES = {
  "CERULEAN_CITY", "VERMILION_CITY", "CELADON_CITY",
  "SAFFRON_CITY", "FUCHSIA_CITY", "LAVENDER_TOWN",
}
local GRUNT_SPRITE = "SPRITE_ROCKET"
local GRUNT_TEXT = "TEXT_ROCKET_RECRUIT"
local TRAINER = "OPP_ROCKET_RECRUIT"

-- battle tiers, chosen by the player's average party level; each is a
-- list of { level, species }. Kept a touch under the player so it's a
-- winnable-but-real fight.
local TIERS = {
  { { level = 8, species = "RATTATA" }, { level = 9, species = "EKANS" } },
  { { level = 15, species = "ZUBAT" }, { level = 15, species = "RATTATA" }, { level = 16, species = "EKANS" } },
  { { level = 23, species = "RATICATE" }, { level = 24, species = "GOLBAT" }, { level = 24, species = "KOFFING" } },
  { { level = 32, species = "ARBOK" }, { level = 33, species = "GOLBAT" }, { level = 33, species = "WEEZING" }, { level = 32, species = "SANDSLASH" } },
  { { level = 41, species = "ARBOK" }, { level = 42, species = "GOLBAT" }, { level = 43, species = "WEEZING" }, { level = 42, species = "MUK" }, { level = 42, species = "SANDSLASH" } },
  { { level = 49, species = "ARBOK" }, { level = 50, species = "GOLBAT" }, { level = 51, species = "WEEZING" }, { level = 50, species = "MUK" }, { level = 50, species = "SANDSLASH" }, { level = 52, species = "RATICATE" } },
}

-- rotating reward item pool (daily); give_item works regardless of price
local REWARD_POOL = {
  "RARE_CANDY", "NUGGET", "MAX_REVIVE", "MAX_ETHER", "PP_UP",
  "MAX_ELIXER", "FULL_RESTORE", "GUARD_SPEC", "TM_ROCK_SLIDE", "TM_TOXIC",
}

-- ------- real-world day + arithmetic-only determinism -------------

local function realDay()
  local ok, t = pcall(os.date, "*t")
  if ok and type(t) == "table" and t.year and t.yday then return t.year * 366 + t.yday end
  local ok2, s = pcall(os.time)
  if ok2 and s then return math.floor(s / 86400) end
  return 1
end
local function seedFrom(a, b)
  local s, str = 5381, tostring(a) .. "|" .. tostring(b)
  for i = 1, #str do s = (s * 33 + str:byte(i)) % 2147483647 end
  return s
end
local function pick1(pool, day, salt)
  local st = seedFrom(salt, day) % 2147483647
  if st <= 0 then st = st + 2147483646 end
  st = (st * 16807) % 2147483647
  return pool[math.floor((st / 2147483647) * #pool) + 1]
end

local function todayCity() return CITIES[(realDay() % #CITIES) + 1] end
local function tierForAvg(avg)
  if avg < 12 then return 1 elseif avg < 20 then return 2
  elseif avg < 28 then return 3 elseif avg < 38 then return 4
  elseif avg < 48 then return 5 else return 6 end
end

return function(mod)
  local Commands = require("src.script.Commands")

  -- the recruit trainer: no auto payout, inherits the Rocket battle sprite
  mod.content.trainers:register(TRAINER, {
    id = TRAINER, name = "RECRUIT", baseMoney = 0, basePic = "OPP_ROCKET",
    parties = TIERS,
  })

  local function avgLevel(ctx)
    local party = ctx.save and ctx.save.party
    if not party or #party == 0 then return 5 end
    local sum, n = 0, 0
    for _, mon in ipairs(party) do
      if mon and mon.level then sum = sum + mon.level; n = n + 1 end
    end
    if n == 0 then return 5 end
    return math.floor(sum / n)
  end

  -- reward = level-scaled but CAPPED, so it never gets absurd
  local function rewardCash(avg) return math.max(300, math.min(3000, avg * 50)) end
  local lastCash = 0
  mod.content.tokens:register("ROCKET_CASH", function() return ("¥%d"):format(lastCash) end)

  local function doneKey(mapId) return "done_" .. tostring(mapId) end

  -- ------- collision helpers ---------------------------------------
  local function overview()
    if not mod.world then return nil end
    local ok, ov = pcall(function() return mod.world:mapOverview() end)
    return ok and ov or nil
  end
  local function walkableAt(ov, x, y)
    if not ov or x < 0 or y < 0 or x >= ov.width or y >= ov.height then return false end
    local row = ov.rows[y + 1]
    return row and row:sub(x + 1, x + 1) == "."
  end

  -- ================= CHALLENGE COMMANDS ============================

  mod.content.commands:register("rocket_recruits:check_done", {
    foreground = true,
    fn = function(ctx)
      local mapId = ctx.overworld and ctx.overworld.map and ctx.overworld.map.id
      ctx.lastCheck = mapId ~= nil and (mod.save:get(doneKey(mapId), -1) == realDay())
    end,
  })

  mod.content.commands:register("rocket_recruits:battle", {
    foreground = true,
    fn = function(ctx)
      Commands.start_battle(ctx, "trainer", TRAINER, tierForAvg(avgLevel(ctx)))
      -- ctx.lastCheck is the win/lose result afterwards
    end,
  })

  mod.content.commands:register("rocket_recruits:reward", {
    foreground = true,
    fn = function(ctx)
      lastCash = rewardCash(avgLevel(ctx))
      Commands.give_money(ctx, lastCash)
      Commands.give_item(ctx, pick1(REWARD_POOL, realDay(), "reward"), 1, true)
      local mapId = ctx.overworld and ctx.overworld.map and ctx.overworld.map.id
      if mapId then mod.save:set(doneKey(mapId), realDay()) end
    end,
  })

  -- march the loitering grunts in place (a gang hanging out)
  mod.content.commands:register("rocket_recruits:loiter", {
    fn = function(ctx)
      local ow = ctx.overworld
      if not ow then return end
      for _, n in ipairs(ow.npcs or {}) do
        if n.def and n.def.runtime and n.def.text == GRUNT_TEXT then
          Commands.march_in_place(ctx, n.def.index, true)
        end
      end
    end,
  })

  local challenge = {
    { "rocket_recruits:check_done" },
    { "jump_if_true", "already" },
    { "show_text", "Hey, twerp! Team\nROCKET runs this\vtown today.\fThink you can take\nthe whole gang?" },
    { "rocket_recruits:battle" },
    { "jump_if_false", "end" }, -- a loss blacks you out; bail quietly
    { "show_text", "Ngaah! The boss\nwill hear of this!" },
    { "rocket_recruits:reward" },
    { "show_text", "The recruits\nscattered and\vdropped {ROCKET_CASH}!" },
    { "jump", "end" },
    { "label", "already" },
    { "show_text", "You already routed\nus today, kid.\vWe'll be back..." },
  }

  -- ================= GANG SPAWN LIFECYCLE ==========================

  local gang = { ids = nil, map = nil }

  local function despawnGang()
    if gang.ids and mod.world then
      for _, id in ipairs(gang.ids) do pcall(function() mod.world:removeNpc(id) end) end
    end
    gang.ids, gang.map = nil, nil
  end

  -- a small cluster of reachable tiles near the player (flood-fill, so the
  -- gang is always reachable on foot)
  local function pickGangCells(ov, ow, n)
    local px = ow.player and ow.player.cellX
    local py = ow.player and ow.player.cellY
    if not px or not py then return {} end
    local W = ov.width
    local seen, q, head = {}, { { px, py } }, 1
    seen[py * W + px] = true
    local reach = {}
    while head <= #q and head < 4000 do
      local c = q[head]; head = head + 1
      if math.abs(c[1] - px) + math.abs(c[2] - py) >= 2 then reach[#reach + 1] = c end
      for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
        local nx, ny = c[1] + d[1], c[2] + d[2]
        if walkableAt(ov, nx, ny) and not seen[ny * W + nx] then
          seen[ny * W + nx] = true
          q[#q + 1] = { nx, ny }
        end
      end
    end
    if #reach == 0 then return {} end
    local anchor
    for _, c in ipairs(reach) do
      local d = math.abs(c[1] - px) + math.abs(c[2] - py)
      if d >= 3 and d <= 9 then anchor = c; break end
    end
    anchor = anchor or reach[1]
    local out, used = { anchor }, { [anchor[2] * W + anchor[1]] = true }
    for _, c in ipairs(reach) do
      if #out >= n then break end
      local k = c[2] * W + c[1]
      local dA = math.abs(c[1] - anchor[1]) + math.abs(c[2] - anchor[2])
      if not used[k] and dA >= 1 and dA <= 4 then out[#out + 1] = c; used[k] = true end
    end
    return out
  end

  local function ensureGang(city, ow)
    local target = todayCity()
    if gang.ids and (gang.map ~= city or city ~= target) then despawnGang() end
    if city ~= target or gang.ids then return end

    local ov = overview()
    if not ov then return end
    local cells = pickGangCells(ov, ow, 3)
    if #cells == 0 then return end

    local ids = {}
    for _, c in ipairs(cells) do
      local id = mod.world:spawnNpc(city, {
        sprite = GRUNT_SPRITE, text = GRUNT_TEXT, movement = "STAY", range = "NONE",
        x = c[1], y = c[2],
      })
      if id then ids[#ids + 1] = id end
    end
    if #ids == 0 then return end
    gang.ids, gang.map = ids, city
    ow:queueScript({ { "rocket_recruits:loiter" } })
  end

  -- ------- attach to each city -------------------------------------
  for _, city in ipairs(CITIES) do
    mod.content.map_scripts:register(city, {
      talk = { [GRUNT_TEXT] = challenge },
      onEnter = function(game, ow) ensureGang(city, ow) end,
    })
  end
end
