-- traveling_merchants
-- ------------------------------------------------------------------
-- Dedicated merchant NPCs that appear OUT ON THE ROUTES, travel by
-- in-game day (world_clock), and move under real collision (mapOverview).
--
-- Merchants are data-driven (the MERCHANTS list): each has its own sprite,
-- route style, patrol range, and set of wares. Ships with two:
--   * PEDDLER  — roams ROUTE 1-5 (mode: 3/5/random in OPTIONS), sells
--                supplies, rare wares, and a daily rare Pokemon.
--   * TRADER   — a fixed shuttle on ROUTE 11 <-> 12, sells supplies + rare.
--
-- Wares:
--   SUPPLIES   — daily-rotating potions / heals / drinks / a vitamin.
--   RARE WARES — the Mt. Moon fossil you DIDN'T take (auto-detected),
--                Old Amber, Moon Stone, a Nugget, and a rotating TM.
--   POKeMON    — one daily rare species (never a common one), for a price.
--
-- Everything is registry content + the runtime world API; no map edits.
-- LuaJIT (Lua 5.1) has no bitops, so daily randomness is arithmetic-only.

local ROUTES5 = { "ROUTE_1", "ROUTE_2", "ROUTE_3", "ROUTE_4", "ROUTE_5" }
local ROUTES3 = { "ROUTE_1", "ROUTE_2", "ROUTE_3" }
local TRADER_ROUTES = { "ROUTE_11", "ROUTE_12" }

local MODES = { "THREE", "FIVE", "RANDOM" }
local MODE_LABEL = { THREE = "3-ROUTE LOOP", FIVE = "5-ROUTE LOOP", RANDOM = "RANDOM" }

-- ------- item pools (verified real Yellow ids) --------------------

local STAPLES = { "POTION", "SUPER_POTION" }
local HEALING = { "HYPER_POTION", "ANTIDOTE", "PARLYZ_HEAL", "BURN_HEAL",
                  "ICE_HEAL", "AWAKENING", "FULL_HEAL", "REVIVE" }
local DRINKS = { "FRESH_WATER", "SODA_POP", "LEMONADE" }
local VITAMINS = { "HP_UP", "PROTEIN", "IRON", "CARBOS", "CALCIUM", "PP_UP", "RARE_CANDY" }
local TM_POOL = { "TM_ICE_BEAM", "TM_ROCK_SLIDE", "TM_SOLARBEAM",
                  "TM_EARTHQUAKE", "TM_SUBMISSION", "TM_FIRE_BLAST" }

-- daily rare Pokemon pool: rares and one-offs only, never common species
local MON_POOL = {
  { s = "OMANYTE", lv = 20, p = 6000 }, { s = "KABUTO", lv = 20, p = 6000 },
  { s = "AERODACTYL", lv = 25, p = 9000 }, { s = "DRATINI", lv = 18, p = 8000 },
  { s = "LAPRAS", lv = 22, p = 9000 }, { s = "EEVEE", lv = 20, p = 7000 },
  { s = "SCYTHER", lv = 22, p = 7000 }, { s = "PINSIR", lv = 22, p = 7000 },
  { s = "TAUROS", lv = 21, p = 6500 }, { s = "CHANSEY", lv = 20, p = 9000 },
  { s = "PORYGON", lv = 20, p = 8000 }, { s = "SNORLAX", lv = 25, p = 9000 },
}

-- ------- arithmetic-only determinism (LuaJIT has no bitops) --------

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
local function pick1(pool, day, salt)
  return pool[math.floor(rng(seedFrom(salt, day))() * #pool) + 1]
end
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

local function routeForDay(day, mode)
  if mode == "FIVE" then
    return ROUTES5[((day - 1) % #ROUTES5) + 1]
  elseif mode == "RANDOM" then
    return ROUTES5[math.floor(rng(seedFrom("route", day))() * #ROUTES5) + 1]
  end
  return ROUTES3[((day - 1) % #ROUTES3) + 1]
end

local function suppliesStockFor(day, routeId)
  local nextR = rng(seedFrom(day, routeId .. "supplies"))
  local stock = { STAPLES[1], STAPLES[2] }
  for _, id in ipairs(pickDistinct(nextR, HEALING, 3)) do stock[#stock + 1] = id end
  for _, id in ipairs(pickDistinct(nextR, DRINKS, 1)) do stock[#stock + 1] = id end
  for _, id in ipairs(pickDistinct(nextR, VITAMINS, 1)) do stock[#stock + 1] = id end
  return stock
end
local function todaysMon(day) return pick1(MON_POOL, day, "mon") end
local function todaysTM(day) return pick1(TM_POOL, day, "tm") end

local DELTA = { left = { -1, 0 }, right = { 1, 0 }, up = { 0, -1 }, down = { 0, 1 } }

return function(mod)
  local Commands = require("src.script.Commands")

  -- rare wares are sold through the normal shop UI, which reads item.price;
  -- give the key-item fossils/amber a buy price (they stay unsellable), and
  -- a price to Moon Stone. Nugget and TMs already have prices.
  mod.content.items:patch("DOME_FOSSIL", { price = 6000 })
  mod.content.items:patch("HELIX_FOSSIL", { price = 6000 })
  mod.content.items:patch("OLD_AMBER", { price = 8000 })
  mod.content.items:patch("MOON_STONE", { price = 3000 })

  -- ------- route-mode setting (OPTIONS, drives the Peddler) --------
  local function getMode() return mod.save:get("route_mode", "THREE") end
  local function cycleMode()
    local cur, idx = getMode(), 1
    for i, v in ipairs(MODES) do if v == cur then idx = i end end
    mod.save:set("route_mode", MODES[(idx % #MODES) + 1])
  end

  local function currentDay()
    local wc = mod.find("world_clock")
    if wc and wc.exports and wc.exports.clock then
      local ok, c = pcall(wc.exports.clock)
      if ok and type(c) == "table" and c.day then return c.day end
    end
    return 1
  end

  -- ------- the merchant roster (data-driven) -----------------------
  local MERCHANTS = {
    {
      id = "peddler", sprite = "SPRITE_CLERK", text = "TEXT_TM_PEDDLER",
      routes = ROUTES5, range = 3,
      routeToday = function(day) return routeForDay(day, getMode()) end,
      wares = { supplies = true, rare = true, pokemon = true },
      greeting = "A traveling\nmerchant, out here\von the road!",
    },
    {
      id = "trader", sprite = "SPRITE_GENTLEMAN", text = "TEXT_TM_TRADER",
      routes = TRADER_ROUTES, range = 2,
      routeToday = function(day) return TRADER_ROUTES[((day - 1) % 2) + 1] end,
      wares = { supplies = true, rare = true, pokemon = false },
      greeting = "Ah! A customer\nout on the trail.",
    },
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

  -- SUPPLIES
  mod.content.commands:register("traveling_merchants:open_supplies", {
    foreground = true,
    fn = function(ctx)
      local routeId = ctx.overworld and ctx.overworld.map and ctx.overworld.map.id or "ROUTE_1"
      Commands.push_screen(ctx, "ShopMenu", suppliesStockFor(currentDay(), routeId))
    end,
  })

  -- RARE WARES: the fossil(s) you don't have + amber + moonstone + nugget + a TM
  mod.content.commands:register("traveling_merchants:open_rare", {
    foreground = true,
    fn = function(ctx)
      local inv = ctx.save.inventory or {}
      local function missing(id) return (inv[id] or 0) <= 0 end
      local stock = {}
      if missing("DOME_FOSSIL") then stock[#stock + 1] = "DOME_FOSSIL" end
      if missing("HELIX_FOSSIL") then stock[#stock + 1] = "HELIX_FOSSIL" end
      if missing("OLD_AMBER") then stock[#stock + 1] = "OLD_AMBER" end
      stock[#stock + 1] = "MOON_STONE"
      stock[#stock + 1] = "NUGGET"
      stock[#stock + 1] = todaysTM(currentDay())
      Commands.push_screen(ctx, "ShopMenu", stock)
    end,
  })

  -- POKeMON: today's rare mon (name/price shown via tokens below)
  mod.content.tokens:register("MERCHANT_MON", function(game)
    local m = todaysMon(currentDay())
    local d = game and game.data and game.data.pokemon and game.data.pokemon[m.s]
    return (d and d.name) or m.s
  end)
  mod.content.tokens:register("MERCHANT_MON_PRICE", function()
    return ("¥%d"):format(todaysMon(currentDay()).p)
  end)
  mod.content.commands:register("traveling_merchants:can_afford_mon", {
    foreground = true,
    fn = function(ctx) ctx.lastCheck = (ctx.save.money or 0) >= todaysMon(currentDay()).p end,
  })
  mod.content.commands:register("traveling_merchants:buy_mon", {
    foreground = true,
    fn = function(ctx)
      local deal = todaysMon(currentDay())
      if (ctx.save.money or 0) < deal.p then ctx.lastCheck = false; return end
      Commands.give_pokemon(ctx, deal.s, deal.lv, true) -- skip nickname prompt
      if ctx.lastCheck then Commands.give_money(ctx, -deal.p) end -- pay only on success
    end,
  })

  -- selector helper: lastCheck = (the player's menu choice was option n)
  mod.content.commands:register("traveling_merchants:sel", {
    foreground = true,
    fn = function(ctx, n) ctx.lastCheck = (ctx.lastChoice and ctx.lastChoice.index == n) end,
  })

  -- ------- build a merchant's talk script from its wares -----------
  local function merchantTalk(m)
    local opts = {}
    if m.wares.supplies then opts[#opts + 1] = { "SUPPLIES", "supplies" } end
    if m.wares.rare then opts[#opts + 1] = { "RARE WARES", "rare" } end
    if m.wares.pokemon then opts[#opts + 1] = { "POKéMON", "poke" } end
    local labels = {}
    for _, o in ipairs(opts) do labels[#labels + 1] = o[1] end
    labels[#labels + 1] = "NEVER MIND"

    local s = {}
    local function add(r) s[#s + 1] = r end
    add({ "show_text", m.greeting .. "\fCare to see my\nwares?" })
    add({ "choice", labels })
    for i, o in ipairs(opts) do
      add({ "traveling_merchants:sel", i })
      add({ "jump_if_true", o[2] })
    end
    add({ "jump", "bye" })
    if m.wares.supplies then
      add({ "label", "supplies" }); add({ "traveling_merchants:open_supplies" }); add({ "jump", "bye" })
    end
    if m.wares.rare then
      add({ "label", "rare" }); add({ "traveling_merchants:open_rare" }); add({ "jump", "bye" })
    end
    if m.wares.pokemon then
      add({ "label", "poke" })
      add({ "show_text", "Today's rare find:\na {MERCHANT_MON}!\fYours for\n{MERCHANT_MON_PRICE}." })
      add({ "choice", { "BUY", "NO" } })
      add({ "jump_if_false", "bye" })
      add({ "traveling_merchants:can_afford_mon" })
      add({ "jump_if_false", "poor" })
      add({ "traveling_merchants:buy_mon" })
      add({ "show_text", "A fine choice!\nTreat it well." })
      add({ "jump", "bye" })
      add({ "label", "poor" })
      add({ "show_text", "Not enough money,\nfriend. Come back!" })
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

      if math.random() < 0.35 then -- sometimes stand still a while
        Commands.wait(ctx, math.random(70, 170)); return
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
      Commands.wait(ctx, math.random(35, 80))
    end,
  })

  -- ================= SPAWN / TRAVEL LIFECYCLE =====================

  local spawn = {} -- keyed by merchant id -> { id, map }
  for _, m in ipairs(MERCHANTS) do spawn[m.id] = { id = nil, map = nil } end

  local function despawn(m)
    local slot = spawn[m.id]
    if slot.id and mod.world then pcall(function() mod.world:removeNpc(slot.id) end) end
    slot.id, slot.map = nil, nil
    patrolState[m.text] = nil
  end

  -- Flood-fill from the player over walkable tiles, so the merchant is only
  -- ever placed somewhere the player can actually WALK to (not a walkable
  -- patch fenced off on the other side of a hedge/pond). Prefer a spot a few
  -- tiles away with open horizontal room to pace.
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
          best = { cx, cy } -- reachable, with room to move
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
    local target = m.routeToday(currentDay())
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
      home = { x = x, y = y }, offset = 0, travel = 1, range = m.range or 2,
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

  -- ------- OPTIONS row: route mode (Peddler) -----------------------
  mod.hooks:wrap("ui.options.rows", function(next, game, rows)
    local out = next(game, rows)
    if type(out) ~= "table" then return out end
    out[#out + 1] = {
      id = "traveling_merchants_route",
      label = "MERCHANT ROUTE",
      value = function() return MODE_LABEL[getMode()] or "?" end,
      activate = function() cycleMode() end,
    }
    return out
  end)
end
