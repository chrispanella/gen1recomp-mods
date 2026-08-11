-- rocket_recruits
-- ------------------------------------------------------------------
-- A gang of Team Rocket "recruits" roams a city each day as a DAILY
-- CHALLENGE. They move TOGETHER as a formation. Beat the gang (one scaled
-- trainer battle) for a level-appropriate, CAPPED cash reward plus a
-- rotating item. The gang moves between cities and its reward rotates on
-- REAL-WORLD days.
--
-- Design notes:
--   * The recruit trainer's baseMoney is 0, so the engine pays nothing
--     automatically; the mod hands out its OWN reward, scaled to the
--     player's average party level and CAPPED, so you never earn an absurd
--     amount no matter how strong you are.
--   * The battle party is picked from tiers by the player's level.
--   * The gang spawns as a contiguous line and paces as a block, every step
--     collision-checked against mapOverview so it never clips.
--   * Runtime world API (spawnNpc/removeNpc); no map edits. Beaten once, the
--     gang won't rebattle until the next real day.

local CITIES = {
  "CERULEAN_CITY", "VERMILION_CITY", "CELADON_CITY",
  "SAFFRON_CITY", "FUCHSIA_CITY", "LAVENDER_TOWN",
}
local GRUNT_SPRITE = "SPRITE_ROCKET"
local GRUNT_TEXT = "TEXT_ROCKET_RECRUIT"
local TRAINER = "OPP_ROCKET_RECRUIT"
local GANG_SIZE = 3

local TIERS = {
  { { level = 8, species = "RATTATA" }, { level = 9, species = "EKANS" } },
  { { level = 15, species = "ZUBAT" }, { level = 15, species = "RATTATA" }, { level = 16, species = "EKANS" } },
  { { level = 23, species = "RATICATE" }, { level = 24, species = "GOLBAT" }, { level = 24, species = "KOFFING" } },
  { { level = 32, species = "ARBOK" }, { level = 33, species = "GOLBAT" }, { level = 33, species = "WEEZING" }, { level = 32, species = "SANDSLASH" } },
  { { level = 41, species = "ARBOK" }, { level = 42, species = "GOLBAT" }, { level = 43, species = "WEEZING" }, { level = 42, species = "MUK" }, { level = 42, species = "SANDSLASH" } },
  { { level = 49, species = "ARBOK" }, { level = 50, species = "GOLBAT" }, { level = 51, species = "WEEZING" }, { level = 50, species = "MUK" }, { level = 50, species = "SANDSLASH" }, { level = 52, species = "RATICATE" } },
}

local REWARD_POOL = {
  "RARE_CANDY", "NUGGET", "MAX_REVIVE", "MAX_ETHER", "PP_UP",
  "MAX_ELIXER", "FULL_RESTORE", "GUARD_SPEC", "TM_ROCK_SLIDE", "TM_TOXIC",
}

local DELTA = { left = { -1, 0 }, right = { 1, 0 }, up = { 0, -1 }, down = { 0, 1 } }

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
  local function liveGrunts(ow)
    local out = {}
    for _, n in ipairs(ow.npcs or {}) do
      if n.def and n.def.runtime and n.def.text == GRUNT_TEXT then out[#out + 1] = n end
    end
    return out
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

  -- ================= MOVE AS A FORMATION ==========================
  -- The whole gang steps in the same direction each beat (block movement),
  -- ping-ponging within a few tiles of where it spawned. A step happens
  -- only if EVERY grunt's target tile is walkable, so the formation never
  -- clips and never splits.
  local gang = { ids = nil, map = nil, roam = nil }

  mod.content.commands:register("rocket_recruits:roam", {
    fn = function(ctx)
      local ow = ctx.overworld
      if not ow then Commands.wait(ctx, 60); return end
      local grunts = liveGrunts(ow)
      local st = gang.roam
      if #grunts == 0 or not st then Commands.wait(ctx, 60); return end
      local ov = overview()
      if not ov then Commands.wait(ctx, 60); return end

      if math.random() < 0.40 then -- the gang loiters a while
        Commands.wait(ctx, math.random(60, 160)); return
      end

      local function allClear(delta)
        for _, g in ipairs(grunts) do
          if not walkableAt(ov, g.cellX + delta[1], g.cellY + delta[2]) then return false end
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
          Commands.walk_npc(ctx, g.def.index, { dir }, { wait = false }) -- all step at once
        end
        st.offset = nextOffset
        Commands.wait(ctx, 18) -- let the simultaneous step land
      else
        Commands.wait(ctx, 30)
      end
      Commands.wait(ctx, math.random(20, 45))
    end,
  })

  -- ================= GANG SPAWN LIFECYCLE ==========================

  local function despawnGang()
    if gang.ids and mod.world then
      for _, id in ipairs(gang.ids) do pcall(function() mod.world:removeNpc(id) end) end
    end
    gang.ids, gang.map, gang.roam = nil, nil, nil
  end

  -- Flood-fill the reachable area from the player, then lay the gang out as
  -- a contiguous line so they read as a group; pace perpendicular to the
  -- line so the whole formation slides together.
  local function planGang(ov, ow, n)
    local px = ow.player and ow.player.cellX
    local py = ow.player and ow.player.cellY
    if not px or not py then return nil end
    local W = ov.width
    local seen, q, head = {}, { { px, py } }, 1
    seen[py * W + px] = true
    local reach = {}
    while head <= #q and head < 4000 do
      local c = q[head]; head = head + 1
      reach[#reach + 1] = c
      for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
        local nx, ny = c[1] + d[1], c[2] + d[2]
        if walkableAt(ov, nx, ny) and not seen[ny * W + nx] then
          seen[ny * W + nx] = true
          q[#q + 1] = { nx, ny }
        end
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

    -- try to extend a line of n reachable cells along some direction
    for _, d in ipairs({ { 1, 0, "right", "left" }, { 0, 1, "down", "up" },
                         { -1, 0, "left", "right" }, { 0, -1, "up", "down" } }) do
      local line, cx, cy, ok = { anchor }, anchor[1], anchor[2], true
      for _ = 2, n do
        cx, cy = cx + d[1], cy + d[2]
        if reachable(cx, cy) then line[#line + 1] = { cx, cy } else ok = false; break end
      end
      if ok and #line == n then
        -- pace perpendicular to the line so the block slides sideways
        local perp = d[1] ~= 0 and { "down", "up" } or { "right", "left" }
        return { cells = line, pos = perp[1], neg = perp[2] }
      end
    end
    return { cells = { anchor }, pos = "right", neg = "left" }
  end

  local function ensureGang(city, ow)
    local target = todayCity()
    if gang.ids and (gang.map ~= city or city ~= target) then despawnGang() end
    if city ~= target or gang.ids then return end

    local ov = overview()
    if not ov then return end
    local plan = planGang(ov, ow, GANG_SIZE)
    if not plan then return end

    local ids = {}
    for _, c in ipairs(plan.cells) do
      local id = mod.world:spawnNpc(city, {
        sprite = GRUNT_SPRITE, text = GRUNT_TEXT, movement = "STAY", range = "NONE",
        x = c[1], y = c[2],
      })
      if id then ids[#ids + 1] = id end
    end
    if #ids == 0 then return end
    gang.ids, gang.map = ids, city
    gang.roam = { offset = 0, travel = 1, range = 3, pos = plan.pos, neg = plan.neg }
    ow:queueScript({ { "run_parallel", city .. "/gang_roam" } })
  end

  -- ------- attach to each city -------------------------------------
  for _, city in ipairs(CITIES) do
    mod.content.map_scripts:register(city, {
      talk = { [GRUNT_TEXT] = challenge },
      onEnter = function(game, ow) ensureGang(city, ow) end,
      scripts = {
        gang_roam = {
          { "label", "top" },
          { "rocket_recruits:roam" },
          { "jump", "top" },
        },
      },
    })
  end
end
