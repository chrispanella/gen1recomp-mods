-- traveling_merchants
-- ------------------------------------------------------------------
-- A roster of distinct merchant NPCs who appear OUT ON THE ROUTES, each
-- with their own look, personality, specialty wares, patrol style, and
-- pair of routes. Everything rotates on REAL-WORLD days: which route a
-- merchant is on, and what's in stock, both change at local midnight.
--
-- No in-game clock needed -- merchants don't roam with the time of day,
-- so the day counter comes straight from the real date (os.date). This
-- mod no longer depends on world_clock.
--
-- Built entirely on registry content + the runtime world API:
--   * mod.world:spawnNpc / removeNpc  -- dedicated NPCs, no map edits
--   * mod.world:mapOverview           -- real collision (place + patrol)
-- LuaJIT (Lua 5.1): no bitops, so daily randomness is arithmetic-only.

-- ------- item pools (verified real Yellow ids, all priced) --------

local STAPLES = { "POTION", "SUPER_POTION" }
local HEALING = { "HYPER_POTION", "ANTIDOTE", "PARLYZ_HEAL", "BURN_HEAL",
                  "ICE_HEAL", "AWAKENING", "FULL_HEAL", "REVIVE" }
local DRINKS = { "FRESH_WATER", "SODA_POP", "LEMONADE" }
local VITAMINS = { "HP_UP", "PROTEIN", "IRON", "CARBOS", "CALCIUM" } -- PP_UP is priceless, omit
local STONES = { "FIRE_STONE", "WATER_STONE", "THUNDER_STONE", "LEAF_STONE" }
local TM_POOL = {
  "TM_ICE_BEAM", "TM_THUNDERBOLT", "TM_THUNDER", "TM_PSYCHIC_M", "TM_EARTHQUAKE",
  "TM_ROCK_SLIDE", "TM_BODY_SLAM", "TM_SUBMISSION", "TM_FIRE_BLAST", "TM_BLIZZARD",
  "TM_SOLARBEAM", "TM_DIG", "TM_SWORDS_DANCE", "TM_REFLECT", "TM_TOXIC",
  "TM_DOUBLE_EDGE", "TM_MEGA_KICK", "TM_MEGA_PUNCH",
}
-- daily rare Pokemon: rares/one-offs only, never a common species
local MON_POOL = {
  { s = "OMANYTE", lv = 20, p = 6000 }, { s = "KABUTO", lv = 20, p = 6000 },
  { s = "AERODACTYL", lv = 25, p = 9000 }, { s = "DRATINI", lv = 18, p = 8000 },
  { s = "LAPRAS", lv = 22, p = 9000 }, { s = "EEVEE", lv = 20, p = 7000 },
  { s = "SCYTHER", lv = 22, p = 7000 }, { s = "PINSIR", lv = 22, p = 7000 },
  { s = "TAUROS", lv = 21, p = 6500 }, { s = "CHANSEY", lv = 20, p = 9000 },
  { s = "PORYGON", lv = 20, p = 8000 }, { s = "SNORLAX", lv = 25, p = 9000 },
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
local function rng(seed)
  local state = seed % 2147483647
  if state <= 0 then state = state + 2147483646 end
  return function()
    state = (state * 16807) % 2147483647
    return state / 2147483647
  end
end
local function pick1(pool, day, salt) return pool[math.floor(rng(seedFrom(salt, day))() * #pool) + 1] end
local function pickDistinct(nextR, pool, k)
  local copy = {}
  for i = 1, #pool do copy[i] = pool[i] end
  local out = {}
  for _ = 1, math.min(k, #copy) do
    local j = math.floor(nextR() * #copy) + 1
    if j > #copy then j = #copy end
    out[#out + 1] = table.remove(copy, j)
  end
  return out
end
local function todaysMon(day) return pick1(MON_POOL, day, "mon") end

-- ------- daily stock builders (one per specialty) -----------------

local function bSupplies(day)
  local r = rng(seedFrom(day, "sup"))
  local s = { STAPLES[1], STAPLES[2] }
  for _, id in ipairs(pickDistinct(r, HEALING, 3)) do s[#s + 1] = id end
  for _, id in ipairs(pickDistinct(r, DRINKS, 1)) do s[#s + 1] = id end
  for _, id in ipairs(pickDistinct(r, VITAMINS, 1)) do s[#s + 1] = id end
  return s
end
local function bFossils(day, ctx)
  local inv = (ctx and ctx.save and ctx.save.inventory) or {}
  local function miss(id) return (inv[id] or 0) <= 0 end
  local s = {}
  if miss("DOME_FOSSIL") then s[#s + 1] = "DOME_FOSSIL" end
  if miss("HELIX_FOSSIL") then s[#s + 1] = "HELIX_FOSSIL" end
  if miss("OLD_AMBER") then s[#s + 1] = "OLD_AMBER" end
  s[#s + 1] = "MOON_STONE"
  for _, id in ipairs(pickDistinct(rng(seedFrom(day, "stone")), STONES, 2)) do s[#s + 1] = id end
  return s
end
local function bHerbs(day)
  local r = rng(seedFrom(day, "herb"))
  local s = {}
  for _, id in ipairs(pickDistinct(r, VITAMINS, 2)) do s[#s + 1] = id end
  s[#s + 1] = "RARE_CANDY"
  for _, id in ipairs(pickDistinct(r, HEALING, 2)) do s[#s + 1] = id end
  return s
end
local function bTMs(day) return pickDistinct(rng(seedFrom(day, "tm")), TM_POOL, 4) end
local function bCurios(day)
  local s = { "NUGGET" }
  for _, id in ipairs(pickDistinct(rng(seedFrom(day, "cur")), STONES, 1)) do s[#s + 1] = id end
  return s
end

local DELTA = { left = { -1, 0 }, right = { 1, 0 }, up = { 0, -1 }, down = { 0, 1 } }

return function(mod)
  local Commands = require("src.script.Commands")

  -- rare/stone/fossil items priced for the shop UI (key-item fossils/amber
  -- stay unsellable; Moon Stone gets a buy price). Stones/TMs already priced.
  for id, price in pairs({ DOME_FOSSIL = 6000, HELIX_FOSSIL = 6000, OLD_AMBER = 8000, MOON_STONE = 3000 }) do
    mod.content.items:patch(id, { price = price })
  end

  -- ------- the merchant roster (each one distinct) -----------------
  local MERCHANTS = {
    { id = "peddler", sprite = "SPRITE_CLERK", text = "TEXT_TM_PEDDLER",
      routes = { "ROUTE_1", "ROUTE_2", "ROUTE_3" }, range = 3, idle = 0.30,
      greeting = "A traveling\nmerchant, at your\vservice! Wares?",
      stock = bSupplies, pokemon = false },
    { id = "digger", sprite = "SPRITE_SUPER_NERD", text = "TEXT_TM_DIGGER",
      routes = { "ROUTE_4", "ROUTE_5" }, range = 2, idle = 0.50,
      greeting = "Fossils! Stones!\nStraight from the\vdig site. Browse?",
      stock = bFossils, pokemon = false },
    { id = "herbalist", sprite = "SPRITE_NURSE", text = "TEXT_TM_HERBALIST",
      routes = { "ROUTE_6", "ROUTE_7" }, range = 2, idle = 0.40,
      greeting = "Tonics and\nvitamins, dearie.\vHave a look?",
      stock = bHerbs, pokemon = false },
    { id = "techie", sprite = "SPRITE_SCIENTIST", text = "TEXT_TM_TECHIE",
      routes = { "ROUTE_8", "ROUTE_9" }, range = 4, idle = 0.25,
      greeting = "Fresh TMs, hot off\nthe machine!\vTake a look?",
      stock = bTMs, pokemon = false },
    { id = "tamer", sprite = "SPRITE_GENTLEMAN", text = "TEXT_TM_TAMER",
      routes = { "ROUTE_10", "ROUTE_11" }, range = 1, idle = 0.60,
      greeting = "Ah, a discerning\ntrainer. I deal in\vrare specimens.",
      stock = bCurios, pokemon = true },
  }
  local byText = {}
  for _, m in ipairs(MERCHANTS) do byText[m.text] = m end

  -- ------- collision helpers (engine's own grid) -------------------
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
  local function liveByText(ow, text)
    for _, n in ipairs(ow.npcs or {}) do
      if n.def and n.def.runtime and n.def.text == text then return n end
    end
    return nil
  end

  -- ================= WARES =========================================

  -- open a merchant's daily shop (the merchant is identified by the NPC
  -- being talked to, so one command serves every merchant)
  mod.content.commands:register("traveling_merchants:open_wares", {
    foreground = true,
    fn = function(ctx)
      local text = ctx.npc and ctx.npc.def and ctx.npc.def.text
      local m = text and byText[text]
      if not m or not m.stock then return end
      local stock = m.stock(realDay(), ctx)
      if stock and #stock > 0 then Commands.push_screen(ctx, "ShopMenu", stock) end
    end,
  })

  -- daily rare Pokemon (name/price via tokens)
  mod.content.tokens:register("MERCHANT_MON", function(game)
    local m = todaysMon(realDay())
    local d = game and game.data and game.data.pokemon and game.data.pokemon[m.s]
    return (d and d.name) or m.s
  end)
  mod.content.tokens:register("MERCHANT_MON_PRICE", function()
    return ("¥%d"):format(todaysMon(realDay()).p)
  end)
  mod.content.commands:register("traveling_merchants:can_afford_mon", {
    foreground = true,
    fn = function(ctx) ctx.lastCheck = (ctx.save.money or 0) >= todaysMon(realDay()).p end,
  })
  mod.content.commands:register("traveling_merchants:buy_mon", {
    foreground = true,
    fn = function(ctx)
      local deal = todaysMon(realDay())
      if (ctx.save.money or 0) < deal.p then ctx.lastCheck = false; return end
      Commands.give_pokemon(ctx, deal.s, deal.lv, true)
      if ctx.lastCheck then Commands.give_money(ctx, -deal.p) end
    end,
  })
  mod.content.commands:register("traveling_merchants:sel", {
    foreground = true,
    fn = function(ctx, n) ctx.lastCheck = (ctx.lastChoice and ctx.lastChoice.index == n) end,
  })

  -- build a merchant's talk from what it offers
  local function merchantTalk(m)
    local opts = {}
    if m.stock then opts[#opts + 1] = "wares" end
    if m.pokemon then opts[#opts + 1] = "poke" end

    local s = {}
    local function add(r) s[#s + 1] = r end
    add({ "show_text", m.greeting })

    if #opts > 1 then
      local labelFor = { wares = "WARES", poke = "POKéMON" }
      local labels = {}
      for _, o in ipairs(opts) do labels[#labels + 1] = labelFor[o] end
      labels[#labels + 1] = "NEVER MIND"
      add({ "choice", labels })
      for i, o in ipairs(opts) do
        add({ "traveling_merchants:sel", i })
        add({ "jump_if_true", o })
      end
      add({ "jump", "bye" })
    end

    if m.stock then
      if #opts > 1 then add({ "label", "wares" }) end
      add({ "traveling_merchants:open_wares" })
      add({ "jump", "bye" })
    end
    if m.pokemon then
      if #opts > 1 then add({ "label", "poke" }) end
      add({ "show_text", "Today's rare find:\na {MERCHANT_MON}!\fYours for\n{MERCHANT_MON_PRICE}." })
      add({ "choice", { "BUY", "NO" } })
      add({ "jump_if_false", "bye" })
      add({ "traveling_merchants:can_afford_mon" })
      add({ "jump_if_false", "poor" })
      add({ "traveling_merchants:buy_mon" })
      add({ "show_text", "A fine choice.\nTreat it well." })
      add({ "jump", "bye" })
      add({ "label", "poor" })
      add({ "show_text", "Not enough money,\nI'm afraid." })
      add({ "jump", "bye" })
    end
    add({ "label", "bye" })
    add({ "show_text", "Safe travels,\n{PLAYER}!" })
    return s
  end

  -- ================= MOVEMENT (collision-aware stroll) =============

  local patrolState = {} -- keyed by merchant text

  mod.content.commands:register("traveling_merchants:patrol", {
    fn = function(ctx, text)
      local ow = ctx.overworld
      if not ow then Commands.wait(ctx, 60); return end
      local m = liveByText(ow, text)
      local st = patrolState[text]
      if not m or not st then Commands.wait(ctx, 60); return end
      local ov = overview()
      if not ov then Commands.wait(ctx, 60); return end

      if math.random() < (st.idle or 0.35) then
        Commands.wait(ctx, math.random(70, 180)); return
      end

      local dir = st.travel > 0 and st.pos or st.neg
      local dd = DELTA[dir]
      local nextOffset = st.offset + st.travel
      local nx, ny = m.cellX + dd[1], m.cellY + dd[2]
      if math.abs(nextOffset) > st.range or not walkableAt(ov, nx, ny) then
        st.travel = -st.travel
        dir = st.travel > 0 and st.pos or st.neg
        dd = DELTA[dir]
        nextOffset = st.offset + st.travel
        nx, ny = m.cellX + dd[1], m.cellY + dd[2]
      end
      if math.abs(nextOffset) <= st.range and walkableAt(ov, nx, ny) then
        Commands.walk_npc(ctx, m.def.index, { dir })
        st.offset = nextOffset
      end
      Commands.wait(ctx, math.random(35, 85))
    end,
  })

  -- ================= SPAWN / TRAVEL LIFECYCLE =====================

  local spawn = {}
  for _, m in ipairs(MERCHANTS) do spawn[m.id] = { id = nil, map = nil } end

  local function despawn(m)
    local slot = spawn[m.id]
    if slot.id and mod.world then pcall(function() mod.world:removeNpc(slot.id) end) end
    slot.id, slot.map = nil, nil
    patrolState[m.text] = nil
  end

  -- flood-fill from the player over walkable tiles, so the merchant is only
  -- placed somewhere reachable on foot (never fenced off across a hedge/pond)
  local function pickSpawnCell(ov, ow)
    local px = ow.player and ow.player.cellX
    local py = ow.player and ow.player.cellY
    if not px or not py then return nil end
    local W = ov.width
    local seen, q, head = {}, { { px, py } }, 1
    seen[py * W + px] = true
    local best, nearFallback
    while head <= #q and head < 4000 do
      local c = q[head]; head = head + 1
      local cx, cy = c[1], c[2]
      local dist = math.abs(cx - px) + math.abs(cy - py)
      if dist >= 1 and not nearFallback then nearFallback = { cx, cy } end
      if dist >= 3 and dist <= 9 and not best then
        if walkableAt(ov, cx - 1, cy) or walkableAt(ov, cx + 1, cy)
           or walkableAt(ov, cx, cy - 1) or walkableAt(ov, cx, cy + 1) then
          best = { cx, cy }
        end
      end
      for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
        local nx, ny = cx + d[1], cy + d[2]
        if walkableAt(ov, nx, ny) and not seen[ny * W + nx] then
          seen[ny * W + nx] = true
          q[#q + 1] = { nx, ny }
        end
      end
    end
    local pick = best or nearFallback
    if pick then return pick[1], pick[2] end
    return nil
  end

  local function ensureMerchant(m, routeId, ow)
    local target = m.routes[(realDay() % #m.routes) + 1]
    local slot = spawn[m.id]
    if slot.id and (slot.map ~= routeId or routeId ~= target) then despawn(m) end
    if routeId ~= target or slot.id then return end

    local ov = overview()
    if not ov then return end
    local x, y = pickSpawnCell(ov, ow)
    if not x then return end

    local id = mod.world:spawnNpc(routeId, {
      sprite = m.sprite, text = m.text, movement = "STAY", range = "NONE", x = x, y = y,
    })
    if not id then return end
    slot.id, slot.map = id, routeId

    local hOpen = (walkableAt(ov, x - 1, y) and 1 or 0) + (walkableAt(ov, x + 1, y) and 1 or 0)
    local vOpen = (walkableAt(ov, x, y - 1) and 1 or 0) + (walkableAt(ov, x, y + 1) and 1 or 0)
    patrolState[m.text] = {
      offset = 0, travel = 1, range = m.range or 2, idle = m.idle or 0.35,
      pos = hOpen >= vOpen and "right" or "down",
      neg = hOpen >= vOpen and "left" or "up",
    }
    ow:queueScript({ { "run_parallel", routeId .. "/tm_patrol_" .. m.id } })
  end

  -- ------- register each route the merchants can appear on ---------
  local routeMerchants = {}
  for _, m in ipairs(MERCHANTS) do
    for _, r in ipairs(m.routes) do
      routeMerchants[r] = routeMerchants[r] or {}
      table.insert(routeMerchants[r], m)
    end
  end
  for routeId, mlist in pairs(routeMerchants) do
    local talk, scripts = {}, {}
    for _, m in ipairs(mlist) do
      talk[m.text] = merchantTalk(m)
      scripts["tm_patrol_" .. m.id] = {
        { "label", "top" },
        { "traveling_merchants:patrol", m.text },
        { "jump", "top" },
      }
    end
    mod.content.map_scripts:register(routeId, {
      talk = talk,
      onEnter = function(game, ow)
        for _, m in ipairs(mlist) do ensureMerchant(m, routeId, ow) end
      end,
      scripts = scripts,
    })
  end
end
