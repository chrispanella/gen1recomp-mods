-- battles
-- ------------------------------------------------------------------
-- Every optional battle challenge in one mod (formerly rocket_recruits,
-- roaming_boss, legendary_shrine, fun_trainer_ace, veteran):
--
--   Wandering Trainers - eight townsfolk who ask YES/NO before a fight
--   Veteran            - a re-battleable sparring trainer in Viridian
--   Team Rocket gang   - a daily formation that roams a city; beat the block
--   Roaming Champion   - a tough boss that moves cities every few days
--   Legendary Shrine   - a daily rotating legendary wild battle on Route 10
--
-- All of them read the tweaks BATTLE DIFF setting when it is installed: the
-- roaming/rocket/legendary battles scale live per encounter; the fixed-team
-- trainers (wanderers, veteran) scale at load.
--
-- Because several features live in the same city, every map is registered ONCE
-- with all its talk entries, onEnter handlers and roam scripts combined.

-- ---- real-world day + arithmetic-only determinism -------------------
local function realDay()
  local ok, t = pcall(os.date, "*t")
  if ok and type(t) == "table" and t.year and t.yday then return t.year * 366 + t.yday end
  return math.floor((os.time and os.time() or 0) / 86400)
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
local DELTA = { left = { -1, 0 }, right = { 1, 0 }, up = { 0, -1 }, down = { 0, 1 } }

-- ===== wandering trainers =====
local FT_TRAINERS = {
  { town = "VIRIDIAN_CITY", npc = "TEXT_VIRIDIANCITY_GAMBLER1",
    id = "OPP_FUN_ACE_LEO", name = "ACE LEO", money = 60,
    party = { { level = 15, species = "NIDORINO" }, { level = 16, species = "KADABRA" }, { level = 17, species = "GROWLITHE" } },
    ask = "You there!\nThose are some\vfine POKéMON.\fCare to battle?",
    win = "Whoa! You're the\nreal deal. Nice\vwork!",
    refuse = "No? Come find me\nwhen you feel\vbrave.",
    after = "That was a great\nmatch, {PLAYER}!" },
  { town = "PEWTER_CITY", npc = "TEXT_PEWTERCITY_COOLTRAINER_M",
    id = "OPP_FUN_ROCKY", name = "HIKER ROCKY", money = 40,
    party = { { level = 12, species = "GEODUDE" }, { level = 13, species = "SANDSHREW" }, { level = 14, species = "MACHOP" } },
    ask = "These rocks made\nme tough!\fWanna test your\nteam on me?",
    win = "Rock solid! You\nbeat me fair.",
    refuse = "Bah. Come back\nwhen you mean it.",
    after = "Keep climbing,\nkid!" },
  { town = "CERULEAN_CITY", npc = "TEXT_CERULEANCITY_COOLTRAINER_M",
    id = "OPP_FUN_DORIAN", name = "COOLTRAINER DORIAN", money = 50,
    party = { { level = 18, species = "PIDGEOTTO" }, { level = 19, species = "RATICATE" }, { level = 20, species = "KADABRA" } },
    ask = "You've got a\nconfident look.\fShall we battle?",
    win = "Impressive! You've\nreally trained.",
    refuse = "Another time,\nthen.",
    after = "Sharp as ever,\nI see." },
  { town = "VERMILION_CITY", npc = "TEXT_VERMILIONCITY_BEAUTY",
    id = "OPP_FUN_BLAZE", name = "BEAUTY BLAZE", money = 55,
    party = { { level = 22, species = "VULPIX" }, { level = 23, species = "PONYTA" }, { level = 24, species = "GROWLITHE" } },
    ask = "My fire types\nburn bright!\fDare to face them?",
    win = "Ooh, you snuffed\nmy flames!",
    refuse = "Too hot for you?\nHee hee.",
    after = "Still smoldering\nover that loss!" },
  { town = "CELADON_CITY", npc = "TEXT_CELADONCITY_FISHER",
    id = "OPP_FUN_MARINA", name = "FISHER MARINA", money = 45,
    party = { { level = 28, species = "SEADRA" }, { level = 29, species = "KINGLER" }, { level = 30, species = "TENTACRUEL" } },
    ask = "Reeled in a fine\nteam today.\fCare to battle?",
    win = "You slipped the\nnet! Well done.",
    refuse = "The tide will\nturn, hah!",
    after = "Nice catch of a\nwin you had." },
  { town = "LAVENDER_TOWN", npc = "TEXT_LAVENDERTOWN_COOLTRAINER_M",
    id = "OPP_FUN_SPECTRA", name = "MEDIUM SPECTRA", money = 55,
    party = { { level = 30, species = "HAUNTER" }, { level = 32, species = "MAROWAK" }, { level = 33, species = "HAUNTER" } },
    ask = "The spirits are\nrestless...\fDare you battle?",
    win = "The spirits are\nquiet now. You\vwin.",
    refuse = "The dead can\nwait. Can you?",
    after = "The tower still\nwhispers of you." },
  { town = "FUCHSIA_CITY", npc = "TEXT_FUCHSIACITY_YOUNGSTER1",
    id = "OPP_FUN_VENOM", name = "JUGGLER VENOM", money = 50,
    party = { { level = 34, species = "ARBOK" }, { level = 35, species = "WEEZING" }, { level = 36, species = "MUK" } },
    ask = "My poisons never\nmiss!\fWant a taste of\nbattle?",
    win = "Ack! You resisted\nit all!",
    refuse = "Afraid of a\nlittle poison?",
    after = "Still stinging\nfrom that loss." },
  { town = "CINNABAR_ISLAND", npc = "TEXT_CINNABARISLAND_GAMBLER",
    id = "OPP_FUN_EMBER", name = "BLAINE FAN EMBER", money = 70,
    party = { { level = 40, species = "RAPIDASH" }, { level = 42, species = "ARCANINE" }, { level = 44, species = "FLAREON" } },
    ask = "This island runs\nhot!\fThink you can\nhandle my fire?",
    win = "Blazing battle!\nYou earned it.",
    refuse = "Cold feet? Come\nback when you're\vfired up.",
    after = "That match was\none for the ages!" },
}

-- ===== rocket gang =====
local RK_CITIES = { "CERULEAN_CITY", "VERMILION_CITY", "CELADON_CITY",
                    "SAFFRON_CITY", "FUCHSIA_CITY", "LAVENDER_TOWN" }
local RK_SPRITE, RK_TEXT, RK_TRAINER, RK_SIZE = "SPRITE_ROCKET", "TEXT_ROCKET_RECRUIT", "OPP_ROCKET_RECRUIT", 3
local RK_TIERS = {
  { { level = 8, species = "RATTATA" }, { level = 9, species = "EKANS" } },
  { { level = 15, species = "ZUBAT" }, { level = 15, species = "RATTATA" }, { level = 16, species = "EKANS" } },
  { { level = 23, species = "RATICATE" }, { level = 24, species = "GOLBAT" }, { level = 24, species = "KOFFING" } },
  { { level = 32, species = "ARBOK" }, { level = 33, species = "GOLBAT" }, { level = 33, species = "WEEZING" }, { level = 32, species = "SANDSLASH" } },
  { { level = 41, species = "ARBOK" }, { level = 42, species = "GOLBAT" }, { level = 43, species = "WEEZING" }, { level = 42, species = "MUK" }, { level = 42, species = "SANDSLASH" } },
  { { level = 49, species = "ARBOK" }, { level = 50, species = "GOLBAT" }, { level = 51, species = "WEEZING" }, { level = 50, species = "MUK" }, { level = 50, species = "SANDSLASH" }, { level = 52, species = "RATICATE" } },
}
local RK_REWARDS = { "RARE_CANDY", "NUGGET", "MAX_REVIVE", "MAX_ETHER", "PP_UP",
                     "MAX_ELIXER", "FULL_RESTORE", "GUARD_SPEC", "TM_ROCK_SLIDE", "TM_TOXIC" }
local function rkTodayCity() return RK_CITIES[(realDay() % #RK_CITIES) + 1] end
local function rkTierForAvg(a)
  if a < 12 then return 1 elseif a < 20 then return 2 elseif a < 28 then return 3
  elseif a < 38 then return 4 elseif a < 48 then return 5 else return 6 end
end

-- ===== roaming boss =====
local RB_CITIES = { "PEWTER_CITY", "CERULEAN_CITY", "VERMILION_CITY",
                    "CELADON_CITY", "FUCHSIA_CITY", "SAFFRON_CITY" }
local RB_SPRITE, RB_TEXT, RB_TRAINER, RB_PERIOD = "SPRITE_GENTLEMAN", "TEXT_FUN_BOSS", "OPP_FUN_BOSS", 3
local RB_TIERS = {
  { { level = 16, species = "PIDGEOTTO" }, { level = 17, species = "KADABRA" }, { level = 18, species = "GROWLITHE" } },
  { { level = 26, species = "PIDGEOT" }, { level = 27, species = "KADABRA" }, { level = 28, species = "ARCANINE" }, { level = 28, species = "GYARADOS" } },
  { { level = 36, species = "PIDGEOT" }, { level = 37, species = "ALAKAZAM" }, { level = 38, species = "ARCANINE" }, { level = 38, species = "GYARADOS" }, { level = 39, species = "SNORLAX" } },
  { { level = 48, species = "PIDGEOT" }, { level = 49, species = "ALAKAZAM" }, { level = 50, species = "ARCANINE" }, { level = 51, species = "GYARADOS" }, { level = 52, species = "SNORLAX" }, { level = 53, species = "DRAGONITE" } },
}
local RB_REWARDS = { "RARE_CANDY", "NUGGET", "PP_UP", "MAX_ELIXER" }
local function rbTierForAvg(a)
  if a < 22 then return 1 elseif a < 32 then return 2 elseif a < 44 then return 3 end
  return 4
end

-- ===== legendary shrine =====
local LS_MAP, LS_TEXT, LS_SPRITE = "ROUTE_10", "TEXT_FUN_SHRINE", "SPRITE_GAMBLER"
local LS_LEGENDS = {
  { "ARTICUNO", 50 }, { "ZAPDOS", 50 }, { "MOLTRES", 50 },
  { "DRATINI", 30 }, { "LAPRAS", 40 }, { "SNORLAX", 40 }, { "MEWTWO", 60 },
}

return function(mod)
  local Commands = require("src.script.Commands")

  -- ---- shared helpers ----------------------------------------------
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
  local function pickCell(ov, ow) -- one reachable tile 3-9 steps from the player
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
  local function avgLevel(ctx, dflt)
    local p = ctx.save and ctx.save.party
    if not p or #p == 0 then return dflt end
    local s, n = 0, 0
    for _, m in ipairs(p) do if m and m.level then s = s + m.level; n = n + 1 end end
    return n > 0 and math.floor(s / n) or dflt
  end
  local function tierBump()
    local tw = mod.find("tweaks")
    return (tw and tw.exports and tw.exports.difficulty and tw.exports.difficulty().tierBump) or 0
  end
  local function levelMult()
    local tw = mod.find("tweaks")
    return (tw and tw.exports and tw.exports.difficulty and tw.exports.difficulty().levelMult) or 1
  end

  -- ---- per-map aggregation -----------------------------------------
  local maps = {}
  local function M(id)
    maps[id] = maps[id] or { talk = {}, enters = {}, scripts = {} }
    return maps[id]
  end

  -- ================= WANDERING TRAINERS =============================
  do
    local mult = levelMult()
    local function scaleParty(p)
      local out = {}
      for i, mon in ipairs(p) do out[i] = { level = math.min(100, math.floor(mon.level * mult)), species = mon.species } end
      return out
    end
    local function ftFlag(id) return "MOD_FT_" .. id .. "_BEATEN" end
    local function ftTalk(t)
      return {
        { "check_flag", ftFlag(t.id) }, { "jump_if_true", "after" },
        { "show_text", t.ask }, { "choice", { "YES", "NO" } }, { "jump_if_false", "refuse" },
        { "start_battle", "trainer", t.id, 1 }, { "jump_if_false", "end" },
        { "set_flag", ftFlag(t.id) }, { "show_text", t.win }, { "jump", "end" },
        { "label", "refuse" }, { "show_text", t.refuse }, { "jump", "end" },
        { "label", "after" }, { "show_text", t.after },
      }
    end
    for _, t in ipairs(FT_TRAINERS) do
      mod.content.trainers:register(t.id, {
        id = t.id, name = t.name, baseMoney = t.money, parties = { scaleParty(t.party) },
      })
      M(t.town).talk[t.npc] = ftTalk(t)
    end
  end

  -- ================= VETERAN ========================================
  do
    local mult = levelMult()
    local function lv(l) return math.min(100, math.floor(l * mult)) end
    mod.content.trainers:register("OPP_FUN_VETERAN", {
      id = "OPP_FUN_VETERAN", name = "VETERAN JODY", baseMoney = 55,
      parties = { {
        { level = lv(30), species = "PIDGEOTTO" }, { level = lv(31), species = "RATICATE" },
        { level = lv(32), species = "KADABRA" }, { level = lv(33), species = "MACHOKE" },
      } },
    })
    M("VIRIDIAN_CITY").talk.TEXT_VIRIDIANCITY_YOUNGSTER2 = {
      { "show_text", "Want to spar again?\nMy team's always\vready to train!" },
      { "choice", { "YES", "NO" } }, { "jump_if_false", "no" },
      { "start_battle", "trainer", "OPP_FUN_VETERAN", 1 }, { "jump", "end" },
      { "label", "no" }, { "show_text", "Come back when you\nwant a good spar!" },
    }
  end

  -- ================= LEGENDARY SHRINE ===============================
  do
    local function todaysLegend() return LS_LEGENDS[(realDay() % #LS_LEGENDS) + 1] end
    local spawnId
    local function ensure(ow)
      if spawnId then return end
      local ov = overview(); if not ov then return end
      local cell = pickCell(ov, ow); if not cell then return end
      local id = mod.world:spawnNpc(LS_MAP, { sprite = LS_SPRITE, text = LS_TEXT, movement = "STAY", range = "NONE", x = cell[1], y = cell[2] })
      if id then spawnId = id end
    end
    mod.content.commands:register("battles:shrine", {
      foreground = true,
      fn = function(ctx)
        local today = realDay()
        if mod.save:get("ls_last", -1) == today then
          Commands.show_text(ctx, "The shrine is quiet\nnow. Return when the\vsun rises anew.")
          return
        end
        mod.save:set("ls_last", today)
        local l = todaysLegend()
        Commands.show_text(ctx, "A great presence\nstirs at the shrine...")
        Commands.start_battle(ctx, "wild", l[1], math.min(100, math.floor(l[2] * levelMult())))
      end,
    })
    M(LS_MAP).talk[LS_TEXT] = { { "battles:shrine" } }
    M(LS_MAP).enters[#M(LS_MAP).enters + 1] = function(game, ow) ensure(ow) end
  end

  -- ================= ROAMING BOSS ===================================
  do
    mod.content.trainers:register(RB_TRAINER, {
      id = RB_TRAINER, name = "CHAMPION X", baseMoney = 0, basePic = "OPP_BLACKBELT", parties = RB_TIERS,
    })
    local function period() return math.floor(realDay() / RB_PERIOD) end
    local function cityNow() return RB_CITIES[(period() % #RB_CITIES) + 1] end
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
      local id = mod.world:spawnNpc(map, { sprite = RB_SPRITE, text = RB_TEXT, movement = "STAY", range = "NONE", x = cell[1], y = cell[2] })
      if id then spawn.id, spawn.map = id, map end
    end
    mod.content.commands:register("battles:boss", {
      foreground = true,
      fn = function(ctx)
        if mod.save:get("rb_done", -1) == period() then
          Commands.show_text(ctx, "You bested me this\ntime. I'll roam on...\vwe'll meet again!")
          return
        end
        Commands.show_text(ctx, "So you found me.\nShow me your\vstrongest team!")
        Commands.start_battle(ctx, "trainer", RB_TRAINER, math.min(#RB_TIERS, rbTierForAvg(avgLevel(ctx, 10)) + tierBump()))
        if ctx.lastCheck then
          mod.save:set("rb_done", period())
          Commands.show_text(ctx, "Magnificent! Take\nthis, champion.")
          Commands.give_item(ctx, RB_REWARDS[(period() % #RB_REWARDS) + 1], 1, true)
          Commands.give_money(ctx, 5000)
        end
      end,
    })
    for _, city in ipairs(RB_CITIES) do
      M(city).talk[RB_TEXT] = { { "battles:boss" } }
      M(city).enters[#M(city).enters + 1] = function(game, ow) ensure(city, ow) end
    end
  end

  -- ================= TEAM ROCKET GANG ===============================
  do
    mod.content.trainers:register(RK_TRAINER, {
      id = RK_TRAINER, name = "RECRUIT", baseMoney = 0, basePic = "OPP_ROCKET", parties = RK_TIERS,
    })
    local lastCash = 0
    mod.content.tokens:register("ROCKET_CASH", function() return ("¥%d"):format(lastCash) end)
    local function rewardCash(avg) return math.max(300, math.min(3000, avg * 50)) end
    local function doneKey(mapId) return "rk_done_" .. tostring(mapId) end
    local function liveGrunts(ow)
      local out = {}
      for _, n in ipairs(ow.npcs or {}) do
        if n.def and n.def.runtime and n.def.text == RK_TEXT then out[#out + 1] = n end
      end
      return out
    end

    mod.content.commands:register("battles:rk_check", {
      foreground = true,
      fn = function(ctx)
        local mapId = ctx.overworld and ctx.overworld.map and ctx.overworld.map.id
        ctx.lastCheck = mapId ~= nil and (mod.save:get(doneKey(mapId), -1) == realDay())
      end,
    })
    mod.content.commands:register("battles:rk_battle", {
      foreground = true,
      fn = function(ctx)
        Commands.start_battle(ctx, "trainer", RK_TRAINER, math.min(#RK_TIERS, rkTierForAvg(avgLevel(ctx, 5)) + tierBump()))
      end,
    })
    mod.content.commands:register("battles:rk_reward", {
      foreground = true,
      fn = function(ctx)
        lastCash = rewardCash(avgLevel(ctx, 5))
        Commands.give_money(ctx, lastCash)
        Commands.give_item(ctx, pick1(RK_REWARDS, realDay(), "reward"), 1, true)
        local mapId = ctx.overworld and ctx.overworld.map and ctx.overworld.map.id
        if mapId then mod.save:set(doneKey(mapId), realDay()) end
      end,
    })

    local challenge = {
      { "battles:rk_check" }, { "jump_if_true", "already" },
      { "show_text", "Hey, twerp! Team\nROCKET runs this\vtown today.\fThink you can take\nthe whole gang?" },
      { "battles:rk_battle" }, { "jump_if_false", "end" },
      { "show_text", "Ngaah! The boss\nwill hear of this!" },
      { "battles:rk_reward" },
      { "show_text", "The recruits\nscattered and\vdropped {ROCKET_CASH}!" },
      { "jump", "end" },
      { "label", "already" }, { "show_text", "You already routed\nus today, kid.\vWe'll be back..." },
    }

    local gang = { ids = nil, map = nil, roam = nil }
    mod.content.commands:register("battles:rk_roam", {
      fn = function(ctx)
        local ow = ctx.overworld
        if not ow then Commands.wait(ctx, 60); return end
        local grunts = liveGrunts(ow)
        local st = gang.roam
        if #grunts == 0 or not st then Commands.wait(ctx, 60); return end
        local ov = overview()
        if not ov then Commands.wait(ctx, 60); return end
        if math.random() < 0.40 then Commands.wait(ctx, math.random(60, 160)); return end
        local function allClear(delta)
          for _, g in ipairs(grunts) do
            if not walkable(ov, g.cellX + delta[1], g.cellY + delta[2]) then return false end
          end
          return true
        end
        local dir = st.travel > 0 and st.pos or st.neg
        local nextOffset = st.offset + st.travel
        if math.abs(nextOffset) > st.range or not allClear(DELTA[dir]) then
          st.travel = -st.travel
          dir = st.travel > 0 and st.pos or st.neg
          nextOffset = st.offset + st.travel
        end
        if math.abs(nextOffset) <= st.range and allClear(DELTA[dir]) then
          for _, g in ipairs(grunts) do
            Commands.walk_npc(ctx, g.def.index, { dir }, { wait = false })
          end
          st.offset = nextOffset
          Commands.wait(ctx, 18)
        else
          Commands.wait(ctx, 30)
        end
        Commands.wait(ctx, math.random(20, 45))
      end,
    })

    local function despawnGang()
      if gang.ids and mod.world then
        for _, id in ipairs(gang.ids) do pcall(function() mod.world:removeNpc(id) end) end
      end
      gang.ids, gang.map, gang.roam = nil, nil, nil
    end
    local function planGang(ov, ow, n)
      local px, py = ow.player and ow.player.cellX, ow.player and ow.player.cellY
      if not px or not py then return nil end
      local W, seen, q, head = ov.width, {}, { { px, py } }, 1
      seen[py * W + px] = true
      local reach = {}
      while head <= #q and head < 4000 do
        local c = q[head]; head = head + 1
        reach[#reach + 1] = c
        for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
          local nx, ny = c[1] + d[1], c[2] + d[2]
          if walkable(ov, nx, ny) and not seen[ny * W + nx] then seen[ny * W + nx] = true; q[#q + 1] = { nx, ny } end
        end
      end
      local function reachable(x, y) return seen[y * W + x] end
      local anchor
      for _, c in ipairs(reach) do
        local d = math.abs(c[1] - px) + math.abs(c[2] - py)
        if d >= 3 and d <= 9 then anchor = c; break end
      end
      anchor = anchor or reach[2] or reach[1]
      if not anchor then return nil end
      for _, d in ipairs({ { 1, 0, "right", "left" }, { 0, 1, "down", "up" },
                           { -1, 0, "left", "right" }, { 0, -1, "up", "down" } }) do
        local line, cx, cy, ok = { anchor }, anchor[1], anchor[2], true
        for _ = 2, n do
          cx, cy = cx + d[1], cy + d[2]
          if reachable(cx, cy) then line[#line + 1] = { cx, cy } else ok = false; break end
        end
        if ok and #line == n then
          local perp = d[1] ~= 0 and { "down", "up" } or { "right", "left" }
          return { cells = line, pos = perp[1], neg = perp[2] }
        end
      end
      return { cells = { anchor }, pos = "right", neg = "left" }
    end
    local function ensureGang(city, ow)
      local target = rkTodayCity()
      if gang.ids and (gang.map ~= city or city ~= target) then despawnGang() end
      if city ~= target or gang.ids then return end
      local ov = overview(); if not ov then return end
      local plan = planGang(ov, ow, RK_SIZE); if not plan then return end
      local ids = {}
      for _, c in ipairs(plan.cells) do
        local id = mod.world:spawnNpc(city, { sprite = RK_SPRITE, text = RK_TEXT, movement = "STAY", range = "NONE", x = c[1], y = c[2] })
        if id then ids[#ids + 1] = id end
      end
      if #ids == 0 then return end
      gang.ids, gang.map = ids, city
      gang.roam = { offset = 0, travel = 1, range = 3, pos = plan.pos, neg = plan.neg }
      ow:queueScript({ { "run_parallel", city .. "/gang_roam" } })
    end

    for _, city in ipairs(RK_CITIES) do
      M(city).talk[RK_TEXT] = challenge
      M(city).enters[#M(city).enters + 1] = function(game, ow) ensureGang(city, ow) end
      M(city).scripts.gang_roam = {
        { "label", "top" }, { "battles:rk_roam" }, { "jump", "top" },
      }
    end
  end

  -- ================= register every map once ========================
  for id, m in pairs(maps) do
    local onEnter
    if #m.enters > 0 then
      onEnter = function(game, ow)
        for _, f in ipairs(m.enters) do f(game, ow) end
      end
    end
    mod.content.map_scripts:register(id, {
      talk = next(m.talk) and m.talk or nil,
      onEnter = onEnter,
      scripts = next(m.scripts) and m.scripts or nil,
    })
  end
end
