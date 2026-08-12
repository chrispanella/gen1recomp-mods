-- crafting
-- ------------------------------------------------------------------
-- Gather materials out in the world, then craft with them at two benches:
--
--   BALL WORKSHOP  (a craftsman in Cerulean) - APRICORNS -> POKe/GREAT/ULTRA BALLs
--   ALCHEMY LAB    (an alchemist in Celadon) - HERBS -> POTIONs and status heals
--
-- Materials come from two places:
--   * FORAGING SPOTS - searchable clumps (a rock/brush node) on several routes.
--     Each yields a random material for its area and refills once per real week.
--   * WILD DROPS - a chance to find a material after winning a wild battle.
--
-- The benches are ListMenu screens: each recipe shows its cost, you pick one to
-- craft, the materials are spent from your bag and the finished item is added.

local Commands = require("src.script.Commands")
local Bag = require("src.inventory.Bag")

-- ---- custom material items --------------------------------------------------
local MATS = {
  { id = "RED_APRICORN",  name = "RED APRICORN",  short = "RED" },
  { id = "BLU_APRICORN",  name = "BLU APRICORN",  short = "BLU" },
  { id = "YLW_APRICORN",  name = "YLW APRICORN",  short = "YLW" },
  { id = "ORAN_HERB",     name = "ORAN HERB",     short = "ORAN" },
  { id = "MYSTIC_HERB",   name = "MYSTIC HERB",   short = "MYS" },
  { id = "PECHA_LEAF",    name = "PECHA LEAF",    short = "PECHA" },
  { id = "CHERI_LEAF",    name = "CHERI LEAF",    short = "CHERI" },
  { id = "RAWST_LEAF",    name = "RAWST LEAF",    short = "RAWST" },
  { id = "CHESTO_LEAF",   name = "CHESTO LEAF",   short = "CHESTO" },
}
local SHORT = {}
for _, m in ipairs(MATS) do SHORT[m.id] = m.short end

-- ---- recipes (out = real game item id, mats = gathered materials) ------------
local BALL_RECIPES = {
  { out = "POKE_BALL",  name = "POKe BALL",  mats = { { id = "RED_APRICORN", qty = 2 } } },
  { out = "GREAT_BALL", name = "GREAT BALL", mats = { { id = "BLU_APRICORN", qty = 2 } } },
  { out = "ULTRA_BALL", name = "ULTRA BALL", mats = { { id = "YLW_APRICORN", qty = 2 }, { id = "RED_APRICORN", qty = 1 } } },
}
local ALCHEMY_RECIPES = {
  { out = "POTION",       name = "POTION",       mats = { { id = "ORAN_HERB", qty = 2 } } },
  { out = "SUPER_POTION", name = "SUPER POTION", mats = { { id = "ORAN_HERB", qty = 2 }, { id = "MYSTIC_HERB", qty = 1 } } },
  { out = "ANTIDOTE",     name = "ANTIDOTE",     mats = { { id = "PECHA_LEAF", qty = 1 } } },
  { out = "PARLYZ_HEAL",  name = "PARLYZ HEAL",  mats = { { id = "CHERI_LEAF", qty = 1 } } },
  { out = "BURN_HEAL",    name = "BURN HEAL",    mats = { { id = "RAWST_LEAF", qty = 1 } } },
  { out = "AWAKENING",    name = "AWAKENING",    mats = { { id = "CHESTO_LEAF", qty = 1 } } },
}

-- ---- foraging: which routes have a spot, and the material tier of each -------
local FORAGE = {
  { map = "ROUTE_1",  tier = 1 }, { map = "ROUTE_2",  tier = 1 },
  { map = "ROUTE_3",  tier = 2 }, { map = "ROUTE_4",  tier = 2 },
  { map = "ROUTE_24", tier = 2 }, { map = "ROUTE_25", tier = 3 },
  { map = "ROUTE_10", tier = 3 }, { map = "ROUTE_11", tier = 3 },
}
local TIER_MATS = {
  [1] = { "RED_APRICORN", "ORAN_HERB", "PECHA_LEAF" },
  [2] = { "BLU_APRICORN", "CHERI_LEAF", "RAWST_LEAF", "ORAN_HERB" },
  [3] = { "YLW_APRICORN", "CHESTO_LEAF", "MYSTIC_HERB", "BLU_APRICORN" },
}
local FORAGE_TEXT, FORAGE_SPRITE = "TEXT_FORAGE_SPOT", "SPRITE_BOULDER"

-- ---- wild-battle drop table (weighted) --------------------------------------
local WILD_DROPS = {
  { "RED_APRICORN", 30 }, { "ORAN_HERB", 30 }, { "PECHA_LEAF", 15 },
  { "BLU_APRICORN", 12 }, { "CHERI_LEAF", 8 }, { "MYSTIC_HERB", 5 },
}
local DROP_CHANCE = 14 -- percent chance on a wild win

-- ---- benches ----------------------------------------------------------------
local BENCHES = {
  { map = "CERULEAN_CITY", sprite = "SPRITE_GRAMPS",    text = "TEXT_CRAFT_BALLS",   screen = "CRAFT_BALLS",   tx = 25, ty = 15 },
  { map = "CELADON_CITY",  sprite = "SPRITE_SCIENTIST", text = "TEXT_CRAFT_ALCHEMY", screen = "CRAFT_ALCHEMY", tx = 20, ty = 20 },
}

local function realWeek() return math.floor((os.time and os.time() or 0) / 604800) end
local function weightedPick(tbl)
  local total = 0
  for _, e in ipairs(tbl) do total = total + e[2] end
  local r = math.random(total)
  for _, e in ipairs(tbl) do
    r = r - e[2]
    if r <= 0 then return e[1] end
  end
  return tbl[1][1]
end

return function(mod)
  -- register the gathered materials as ordinary stackable bag items
  for _, m in ipairs(MATS) do
    mod.content.items:register(m.id, { id = m.id, name = m.name, price = 100, keyItem = false, tossable = true })
  end

  -- ===== crafting maths ======================================================
  local function haveEnough(save, r)
    for _, m in ipairs(r.mats) do
      if (save.inventory[m.id] or 0) < m.qty then return false end
    end
    return true
  end
  local function costText(r)
    local parts = {}
    for _, m in ipairs(r.mats) do parts[#parts + 1] = m.qty .. SHORT[m.id] end
    return table.concat(parts, "+")
  end
  local function doCraft(game, r)
    local save = game.save
    if not haveEnough(save, r) then return false, "short" end
    for _, m in ipairs(r.mats) do Bag.remove(save, m.id, m.qty) end
    if not Bag.add(save, r.out, 1, game.data) then
      for _, m in ipairs(r.mats) do Bag.add(save, m.id, m.qty, game.data) end -- refund
      return false, "full"
    end
    return true
  end

  -- ===== the two bench screens ===============================================
  local function rowsFor(game, recipes)
    local rows = {}
    for _, r in ipairs(recipes) do
      rows[#rows + 1] = { label = r.name, right = costText(r), recipe = r }
    end
    rows[#rows + 1] = { label = "DONE" }
    return rows
  end
  local function makeScreen(id, title, recipes, footer)
    mod.content.screens:register(id, {
      new = function(game)
        local menu
        menu = mod.ui.ListMenu.new(game, title, rowsFor(game, recipes), {
          footer = footer,
          onChoose = function(item, m)
            if not item.recipe then m:close(); return end
            local ok, why = doCraft(game, item.recipe)
            if ok then
              m.footer = "Made a " .. item.recipe.name .. "!"
            elseif why == "full" then
              m.footer = "Your bag is full."
            else
              m.footer = "Not enough materials."
            end
            m.items = rowsFor(game, recipes)          -- refresh the counts
            if m.index > #m.items then m.index = #m.items end
          end,
        })
        return menu
      end,
    })
  end
  makeScreen("CRAFT_BALLS", "BALL WORKSHOP", BALL_RECIPES, "Craft BALLs from APRICORNS.")
  makeScreen("CRAFT_ALCHEMY", "ALCHEMY LAB", ALCHEMY_RECIPES, "Mix HERBS into medicine.")

  -- open a bench from its NPC
  mod.content.commands:register("crafting:balls", {
    foreground = true, fn = function(ctx) Commands.push_screen(ctx, "CRAFT_BALLS") end,
  })
  mod.content.commands:register("crafting:alchemy", {
    foreground = true, fn = function(ctx) Commands.push_screen(ctx, "CRAFT_ALCHEMY") end,
  })

  -- ===== reachable placement (shared by benches and forage nodes) ============
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
  -- BFS from the player; return the reachable tile nearest a target (or, when no
  -- target, a tile a handful of steps away so a spot lands on the path ahead)
  local function pickCell(ov, ow, tx, ty)
    local px, py = ow.player and ow.player.cellX, ow.player and ow.player.cellY
    if not px then return nil end
    local W, seen, q, head = ov.width, {}, { { px, py } }, 1
    seen[py * W + px] = true
    local best, bestScore, mid, midD
    while head <= #q and head < 6000 do
      local c = q[head]; head = head + 1
      local far = math.abs(c[1] - px) + math.abs(c[2] - py)
      if far >= 1 then
        if tx then
          local score = math.abs(c[1] - tx) + math.abs(c[2] - ty)
          if not best or score < bestScore then best, bestScore = c, score end
        end
        -- fallback / no-target: a tile 4-9 steps out on the walkable path
        if far >= 4 and far <= 9 and (not mid or far < midD) then mid, midD = c, far end
      end
      for _, dd in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
        local nx, ny = c[1] + dd[1], c[2] + dd[2]
        if walkable(ov, nx, ny) and not seen[ny * W + nx] then seen[ny * W + nx] = true; q[#q + 1] = { nx, ny } end
      end
    end
    return best or mid
  end

  -- ===== benches: spawn each craftsman once per map ==========================
  local benchSpawned = {}
  for _, b in ipairs(BENCHES) do
    mod.content.map_scripts:register(b.map, {
      talk = { [b.text] = { { b.screen == "CRAFT_BALLS" and "crafting:balls" or "crafting:alchemy" } } },
      onEnter = function(game, ow)
        if benchSpawned[b.map] then return end
        local ov = overview(); if not ov then return end
        local cell = pickCell(ov, ow, b.tx, b.ty); if not cell then return end
        local id = mod.world:spawnNpc(b.map, { sprite = b.sprite, text = b.text, movement = "STAY", range = "NONE", x = cell[1], y = cell[2] })
        if id then benchSpawned[b.map] = true end
      end,
    })
  end

  -- ===== foraging nodes ======================================================
  local forageId = {}       -- map -> spawned node id (this session)
  local forageTier = {}     -- map -> tier
  local currentForageMap    -- the forage map most recently entered = the one we're on

  mod.content.commands:register("crafting:forage", {
    foreground = true,
    fn = function(ctx)
      -- you can only talk to a node on the map you are standing on, and that
      -- map's onEnter set currentForageMap last, so it is the right area
      local map = currentForageMap
      local tier = (map and forageTier[map]) or 1
      Commands.show_text(ctx, "You search the\nbrush and rocks...")
      local mat = TIER_MATS[tier][math.random(#TIER_MATS[tier])]
      local qty = math.random(1, 3)
      Commands.give_item(ctx, mat, qty, true)
      if map then
        mod.save:set("forage_wk_" .. map, realWeek())
        if forageId[map] and mod.world then
          pcall(function() mod.world:removeNpc(forageId[map]) end)
          forageId[map] = nil
        end
      end
    end,
  })

  for _, f in ipairs(FORAGE) do
    mod.content.map_scripts:register(f.map, {
      talk = { [FORAGE_TEXT] = { { "crafting:forage" } } },
      onEnter = function(game, ow)
        forageTier[f.map] = f.tier
        currentForageMap = f.map
        if forageId[f.map] then return end
        if mod.save:get("forage_wk_" .. f.map, -1) == realWeek() then return end -- picked this week
        local ov = overview(); if not ov then return end
        local cell = pickCell(ov, ow); if not cell then return end
        local id = mod.world:spawnNpc(f.map, { sprite = FORAGE_SPRITE, text = FORAGE_TEXT, movement = "STAY", range = "NONE", x = cell[1], y = cell[2] })
        if id then forageId[f.map] = id end
      end,
    })
  end

  -- ===== wild-battle drops ===================================================
  local G           -- latest game handle, captured from core.update
  local dropMsg, dropT = "", 0
  mod.hooks:wrap("core.update", function(next, game, dt)
    local r = next(game, dt)
    G = game
    if dropT > 0 then dropT = dropT - 1 end
    return r
  end)
  mod.events:on("battle.ended", function(ev)
    if not (ev and ev.result == "win" and ev.battle and ev.battle.kind == "wild") then return end
    if math.random(100) > DROP_CHANCE then return end
    if not (G and G.save) then return end
    local mat = weightedPick(WILD_DROPS)
    if Bag.add(G.save, mat, 1, G.data) then
      local nm = "material"
      for _, m in ipairs(MATS) do if m.id == mat then nm = m.name end end
      local msg = "Found a " .. nm .. "!"
      -- prefer the shared tweaks popup (styled + configurable); else fall back
      local tw = mod.find("tweaks")
      if tw and tw.exports and tw.exports.push then
        tw.exports.push(msg)
      else
        dropMsg, dropT = msg, 240
      end
    end
  end)
  mod.hooks:wrap("render.hud", function(next, game, viewport)
    local r = next(game, viewport)
    if dropT > 0 then
      local vp = viewport or {}
      local s = math.max(1, math.floor(vp.scale or 2))
      local w = vp.width or 240
      local x = 4 * s
      local y = ((vp.gameY or 0) + 4 * s)
      local a = math.min(1, dropT / 45)
      love.graphics.push("all")
      love.graphics.setColor(0, 0, 0, 0.7 * a)
      love.graphics.print(dropMsg, x + s, y + s, 0, s, s)
      love.graphics.setColor(0.6, 1, 0.6, a)
      love.graphics.print(dropMsg, x, y, 0, s, s)
      love.graphics.pop()
    end
    return r
  end)
end
