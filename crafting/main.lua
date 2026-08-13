-- crafting
-- ------------------------------------------------------------------
-- A crafting HUB you open at a bench. The main menu branches into four
-- disciplines, each with its own LEVEL that rises as you craft and unlocks
-- better recipes:
--
--   ALCHEMY      - potions and status heals from herbs
--   COOKING      - drinks and food from berries (buff food comes later)
--   ENGINEERING  - Poke/Great/Ultra Balls, fishing rods, and a bicycle
--   GATHERING    - a read-only look at your materials; its level raises how
--                  much each foraging spot yields
--
-- Materials come from foraging spots on routes (refill weekly) and a chance
-- drop after winning a wild battle. Both also grant GATHERING xp.

local Commands = require("src.script.Commands")
local Bag = require("src.inventory.Bag")

-- ---- materials (custom stackable bag items) ---------------------------------
local MATS = {
  { id = "RED_APRICORN", name = "RED APRICORN", short = "RED" },
  { id = "BLU_APRICORN", name = "BLU APRICORN", short = "BLU" },
  { id = "YLW_APRICORN", name = "YLW APRICORN", short = "YLW" },
  { id = "ORAN_HERB",    name = "ORAN HERB",    short = "ORAN" },
  { id = "MYSTIC_HERB",  name = "MYSTIC HERB",  short = "MYS" },
  { id = "PECHA_LEAF",   name = "PECHA LEAF",   short = "PECHA" },
  { id = "CHERI_LEAF",   name = "CHERI LEAF",   short = "CHERI" },
  { id = "RAWST_LEAF",   name = "RAWST LEAF",   short = "RAWST" },
  { id = "CHESTO_LEAF",  name = "CHESTO LEAF",  short = "CHESTO" },
  { id = "FRESH_BERRY",  name = "FRESH BERRY",  short = "BERRY" },
  { id = "SCRAP",        name = "SCRAP METAL",  short = "SCRAP" },
  { id = "SPRING",       name = "COIL SPRING",  short = "SPRING" },
  { id = "TECH_SHARD",   name = "TECH SHARD",   short = "TECH" },
  { id = "PEARL",        name = "PEARL",        short = "PEARL" },
  { id = "KELP",         name = "KELP",         short = "KELP" },
}
local SHORT = {}
for _, m in ipairs(MATS) do SHORT[m.id] = m.short end

-- ---- discipline levels ------------------------------------------------------
local XP_CUM = { 0, 30, 80, 160, 280, 450, 700 } -- cumulative xp for level 1..7
local function levelFor(xp)
  local lv = 1
  for i = #XP_CUM, 1, -1 do if xp >= XP_CUM[i] then lv = i; break end end
  return lv
end

-- ---- recipes per discipline (out = real game item; lvl = level to unlock) ----
local ALCHEMY = {
  { out = "POTION",       name = "POTION",       lvl = 1, xp = 6,  mats = { { "ORAN_HERB", 2 } } },
  { out = "ANTIDOTE",     name = "ANTIDOTE",     lvl = 1, xp = 5,  mats = { { "PECHA_LEAF", 1 } } },
  { out = "PARLYZ_HEAL",  name = "PARLYZ HEAL",  lvl = 1, xp = 5,  mats = { { "CHERI_LEAF", 1 } } },
  { out = "BURN_HEAL",    name = "BURN HEAL",    lvl = 2, xp = 5,  mats = { { "RAWST_LEAF", 1 } } },
  { out = "AWAKENING",    name = "AWAKENING",    lvl = 2, xp = 5,  mats = { { "CHESTO_LEAF", 1 } } },
  { out = "SUPER_POTION", name = "SUPER POTION", lvl = 2, xp = 9,  mats = { { "ORAN_HERB", 2 }, { "MYSTIC_HERB", 1 } } },
  { out = "FULL_HEAL",    name = "FULL HEAL",    lvl = 3, xp = 12, mats = { { "PECHA_LEAF", 1 }, { "CHERI_LEAF", 1 }, { "RAWST_LEAF", 1 } } },
  { out = "HYPER_POTION", name = "HYPER POTION", lvl = 3, xp = 14, mats = { { "ORAN_HERB", 2 }, { "MYSTIC_HERB", 2 } } },
  { out = "MAX_POTION",   name = "MAX POTION",   lvl = 4, xp = 20, mats = { { "ORAN_HERB", 3 }, { "MYSTIC_HERB", 3 } } },
  { out = "FULL_RESTORE", name = "FULL RESTORE", lvl = 5, xp = 28, mats = { { "MYSTIC_HERB", 3 }, { "ORAN_HERB", 2 }, { "CHESTO_LEAF", 1 } } },
}
-- COOKING makes BUFF FOOD: custom items that, eaten in battle, raise the active
-- Pokemon's stat stages for the rest of the fight (a multi-stat X-item). Which
-- dishes you can cook is gated by BADGES, so each region unlocks a better meal -
-- the same way your Pokemon obey you further as you earn badges.
local STAT_LABEL = { attack = "ATK", defense = "DEF", speed = "SPD", special = "SPC" }
local FOODS = {
  { id = "BERRY_JUICE", name = "BERRY JUICE", badges = 0, xp = 6,  mats = { { "FRESH_BERRY", 2 } },                        buff = { { "speed", 1 } } },
  { id = "RICE_BALL",   name = "RICE BALL",   badges = 1, xp = 8,  mats = { { "FRESH_BERRY", 3 } },                        buff = { { "attack", 1 } } },
  { id = "VEGGIE_WRAP", name = "VEGGIE WRAP", badges = 2, xp = 9,  mats = { { "FRESH_BERRY", 3 }, { "ORAN_HERB", 1 } },    buff = { { "defense", 1 } } },
  { id = "SPICY_CURRY", name = "SPICY CURRY", badges = 3, xp = 12, mats = { { "FRESH_BERRY", 4 }, { "ORAN_HERB", 1 } },    buff = { { "attack", 1 }, { "speed", 1 } } },
  { id = "SUSHI_ROLL",  name = "SUSHI ROLL",  badges = 3, xp = 13, mats = { { "KELP", 2 }, { "FRESH_BERRY", 2 } },        buff = { { "speed", 1 }, { "special", 1 } } },
  { id = "HEARTY_STEW", name = "HEARTY STEW", badges = 4, xp = 14, mats = { { "FRESH_BERRY", 4 }, { "MYSTIC_HERB", 1 } },  buff = { { "defense", 1 }, { "special", 1 } } },
  { id = "GLORY_BOWL",  name = "GLORY BOWL",  badges = 5, xp = 18, mats = { { "FRESH_BERRY", 5 }, { "MYSTIC_HERB", 1 } },  buff = { { "attack", 1 }, { "defense", 1 }, { "speed", 1 } } },
  { id = "SAGE_FEAST",  name = "SAGE FEAST",  badges = 6, xp = 22, mats = { { "FRESH_BERRY", 5 }, { "MYSTIC_HERB", 2 } },  buff = { { "special", 2 } } },
  { id = "GRAND_FEAST", name = "GRAND FEAST", badges = 7, xp = 30, mats = { { "FRESH_BERRY", 6 }, { "MYSTIC_HERB", 3 } },  buff = { { "attack", 1 }, { "defense", 1 }, { "speed", 1 }, { "special", 1 } } },
}
local COOKING = {}
for _, f in ipairs(FOODS) do
  COOKING[#COOKING + 1] = { out = f.id, name = f.name, badges = f.badges, xp = f.xp, mats = f.mats }
end
local ENGINEERING = {
  { out = "POKE_BALL",  name = "POKe BALL",  lvl = 1, xp = 6,  mats = { { "RED_APRICORN", 2 } } },
  { out = "GREAT_BALL", name = "GREAT BALL", lvl = 2, xp = 9,  mats = { { "BLU_APRICORN", 2 } } },
  { out = "OLD_ROD",    name = "OLD ROD",    lvl = 2, xp = 12, mats = { { "SCRAP", 3 } } },
  { out = "ULTRA_BALL", name = "ULTRA BALL", lvl = 3, xp = 14, mats = { { "YLW_APRICORN", 2 }, { "RED_APRICORN", 1 } } },
  { out = "GOOD_ROD",   name = "GOOD ROD",   lvl = 3, xp = 18, mats = { { "SCRAP", 4 }, { "SPRING", 1 } } },
  { out = "SUPER_ROD",  name = "SUPER ROD",  lvl = 4, xp = 24, mats = { { "SCRAP", 6 }, { "SPRING", 2 } } },
  { out = "BICYCLE",    name = "BICYCLE",    lvl = 5, xp = 40, mats = { { "SCRAP", 10 }, { "SPRING", 4 } } },
}
-- TM LAB: craft Technical Machines (and, at the top, a few HMs) from TECH SHARD.
-- The move works natively once the TM is used; HMs still need the right badge to
-- be used, so crafting one early is safe.
local TM_LAB = {
  { out = "TM_MEGA_PUNCH",  name = "TM MEGA PUNCH",  lvl = 1, xp = 10, mats = { { "TECH_SHARD", 2 } } },
  { out = "TM_SWIFT",       name = "TM SWIFT",       lvl = 1, xp = 10, mats = { { "TECH_SHARD", 2 } } },
  { out = "TM_BODY_SLAM",   name = "TM BODY SLAM",   lvl = 2, xp = 14, mats = { { "TECH_SHARD", 3 } } },
  { out = "TM_BUBBLEBEAM",  name = "TM BUBBLEBEAM",  lvl = 2, xp = 14, mats = { { "TECH_SHARD", 3 } } },
  { out = "TM_ROCK_SLIDE",  name = "TM ROCK SLIDE",  lvl = 2, xp = 14, mats = { { "TECH_SHARD", 3 }, { "SCRAP", 2 } } },
  { out = "TM_THUNDERBOLT", name = "TM THUNDERBOLT", lvl = 3, xp = 20, mats = { { "TECH_SHARD", 4 }, { "SPRING", 1 } } },
  { out = "TM_ICE_BEAM",    name = "TM ICE BEAM",    lvl = 3, xp = 20, mats = { { "TECH_SHARD", 4 } } },
  { out = "TM_PSYCHIC_M",   name = "TM PSYCHIC",     lvl = 4, xp = 26, mats = { { "TECH_SHARD", 5 }, { "MYSTIC_HERB", 2 } } },
  { out = "TM_EARTHQUAKE",  name = "TM EARTHQUAKE",  lvl = 4, xp = 26, mats = { { "TECH_SHARD", 5 }, { "SCRAP", 3 } } },
  { out = "TM_FIRE_BLAST",  name = "TM FIRE BLAST",  lvl = 5, xp = 32, mats = { { "TECH_SHARD", 6 } } },
  { out = "TM_BLIZZARD",    name = "TM BLIZZARD",    lvl = 5, xp = 32, mats = { { "TECH_SHARD", 6 } } },
  { out = "TM_HYPER_BEAM",  name = "TM HYPER BEAM",  lvl = 6, xp = 45, mats = { { "TECH_SHARD", 8 }, { "SPRING", 2 } } },
  { out = "HM_CUT",         name = "HM CUT",         lvl = 4, xp = 20, mats = { { "TECH_SHARD", 4 }, { "SCRAP", 2 } } },
  { out = "HM_STRENGTH",    name = "HM STRENGTH",    lvl = 5, xp = 24, mats = { { "TECH_SHARD", 5 }, { "SCRAP", 4 } } },
  { out = "HM_SURF",        name = "HM SURF",        lvl = 6, xp = 30, mats = { { "TECH_SHARD", 7 }, { "SPRING", 2 }, { "PEARL", 1 } } },
}
local DISCIPLINES = {
  { key = "alchemy",     label = "ALCHEMY",     recipes = ALCHEMY },
  { key = "cooking",     label = "COOKING",     recipes = COOKING },
  { key = "engineering", label = "ENGINEERING", recipes = ENGINEERING },
  { key = "tinkering",   label = "TM LAB",      recipes = TM_LAB },
}

-- ---- foraging + wild drops --------------------------------------------------
local FORAGE = {
  { map = "ROUTE_1",  tier = 1 }, { map = "ROUTE_2",  tier = 1 },
  { map = "ROUTE_3",  tier = 2 }, { map = "ROUTE_4",  tier = 2 },
  { map = "ROUTE_24", tier = 2 }, { map = "ROUTE_25", tier = 3 },
  { map = "ROUTE_10", tier = 3 }, { map = "ROUTE_11", tier = 3 },
}
local TIER_MATS = {
  [1] = { "RED_APRICORN", "ORAN_HERB", "PECHA_LEAF", "FRESH_BERRY" },
  [2] = { "BLU_APRICORN", "CHERI_LEAF", "RAWST_LEAF", "ORAN_HERB", "SCRAP", "FRESH_BERRY" },
  [3] = { "YLW_APRICORN", "CHESTO_LEAF", "MYSTIC_HERB", "BLU_APRICORN", "SCRAP", "SPRING", "TECH_SHARD" },
}
local FORAGE_TEXT, FORAGE_SPRITE = "TEXT_FORAGE_SPOT", "SPRITE_BOULDER"
-- Wild-battle drops depend on WHERE you are and WHAT you beat. A defeated
-- Water-type rolls the water table; otherwise the current map's region decides.
local DEFAULT_DROPS = {
  { "RED_APRICORN", 26 }, { "ORAN_HERB", 26 }, { "PECHA_LEAF", 12 }, { "FRESH_BERRY", 14 },
  { "BLU_APRICORN", 10 }, { "SCRAP", 10 }, { "CHERI_LEAF", 7 }, { "MYSTIC_HERB", 5 }, { "TECH_SHARD", 4 },
}
local REGION_DROPS = {
  forest  = { { "ORAN_HERB", 26 }, { "FRESH_BERRY", 24 }, { "PECHA_LEAF", 16 }, { "RED_APRICORN", 18 }, { "CHESTO_LEAF", 8 } },
  cave    = { { "SCRAP", 30 }, { "TECH_SHARD", 20 }, { "SPRING", 16 }, { "MYSTIC_HERB", 8 }, { "YLW_APRICORN", 8 } },
  default = DEFAULT_DROPS,
}
local WATER_DROPS = {
  { "KELP", 30 }, { "PEARL", 24 }, { "BLU_APRICORN", 16 }, { "FRESH_BERRY", 16 }, { "MYSTIC_HERB", 8 },
}
local DROP_CHANCE, WATER_CHANCE = 14, 22 -- percent; water foes drop a bit more often
local function regionFor(mapId)
  mapId = mapId or ""
  if mapId:find("FOREST") then return "forest" end
  if mapId:find("MT_") or mapId:find("ROCK_TUNNEL") or mapId:find("CAVE")
     or mapId:find("MANSION") or mapId:find("VICTORY_ROAD") or mapId:find("SEAFOAM")
     or mapId:find("POWER_PLANT") then return "cave" end
  return "default"
end
local function enemyIsWater(ev, data)
  local enemy = ev.battle and ev.battle.enemy
  local species = enemy and enemy.mon and enemy.mon.species
  local def = species and data and data.pokemon and data.pokemon[species]
  if not def then return false end
  for _, t in ipairs(def.types or {}) do if t == "WATER" then return true end end
  return false
end

-- ---- benches (both open the full hub) ---------------------------------------
local BENCHES = {
  { map = "CERULEAN_CITY", sprite = "SPRITE_GRAMPS",    text = "TEXT_CRAFT_BENCH_A", tx = 25, ty = 15 },
  { map = "CELADON_CITY",  sprite = "SPRITE_SCIENTIST", text = "TEXT_CRAFT_BENCH_B", tx = 20, ty = 20 },
}

local function realWeek() return math.floor((os.time and os.time() or 0) / 604800) end
local function weightedPick(tbl)
  local total = 0
  for _, e in ipairs(tbl) do total = total + e[2] end
  local r = math.random(total)
  for _, e in ipairs(tbl) do r = r - e[2]; if r <= 0 then return e[1] end end
  return tbl[1][1]
end

return function(mod)
  for _, m in ipairs(MATS) do
    mod.content.items:register(m.id, { id = m.id, name = m.name, price = 100, keyItem = false, tossable = true })
  end

  -- buff-food items. Eaten IN battle, they boost the active Pokemon's stat
  -- stages for the rest of the fight. Eaten in the FIELD, they prepare a meal
  -- that buffs your lead at the START of your next battle (persists in the save
  -- until that battle happens).
  local function applyBuff(b, buff)
    local raised = {}
    for _, s in ipairs(buff) do
      local cur = b.stages[s[1]] or 0
      if cur < 6 then
        b.stages[s[1]] = math.min(6, cur + s[2])
        raised[#raised + 1] = STAT_LABEL[s[1]]
      end
    end
    return raised
  end
  local function foodEffect(food)
    return function(ctx)
      if ctx.battle and ctx.battle.player then
        local b = ctx.battle.player
        local raised = applyBuff(b, food.buff)
        local who = b.name or "POKeMON"
        if #raised == 0 then return "consumed", { who .. " is already\npumped up!" } end
        return "consumed", { who .. " ate the\n" .. food.name .. "!", table.concat(raised, " ") .. " rose!" }
      end
      -- field use: store the prepared meal for the next battle (one battle)
      mod.save:set("pending_food", food.id)
      return "consumed", { "Your team enjoyed\nthe " .. food.name .. "!", "They are pumped for\nthe next battle!" }
    end
  end
  for _, food in ipairs(FOODS) do
    mod.content.items:register(food.id, { id = food.id, name = food.name, price = 200, keyItem = false, tossable = true, effect = food.id })
    mod.content.item_effects:register(food.id, { use = foodEffect(food), battle = true, field = true })
  end

  -- apply a prepared meal to the lead at the start of the next battle
  mod.events:on("battle.started", function(ev)
    local fid = mod.save:get("pending_food", nil)
    if not fid then return end
    mod.save:set("pending_food", nil) -- consumed by this battle
    local food
    for _, f in ipairs(FOODS) do if f.id == fid then food = f end end
    local b = ev and ev.battle and ev.battle.player
    if not (food and b and b.stages) then return end
    applyBuff(b, food.buff)
    local tw = mod.find("tweaks")
    if tw and tw.exports and tw.exports.push then tw.exports.push("Your meal kicked in!") end
  end)

  -- ---- levels ----
  local function xpOf(disc) return mod.save:get("xp_" .. disc, 0) end
  local function levelOf(disc) return levelFor(xpOf(disc)) end
  local function addXP(disc, n) mod.save:set("xp_" .. disc, xpOf(disc) + n) end
  local function badgeCount(save)
    local ok, n = pcall(function() return require("src.inventory.Badges").count(nil, save) end)
    return (ok and type(n) == "number") and n or 0
  end
  -- returns (unlocked, lockLabel); cooking recipes gate on BADGES, others on level
  local function gateInfo(save, disc, r)
    if r.badges ~= nil then
      return badgeCount(save) >= r.badges, "Bg " .. r.badges
    end
    return levelOf(disc) >= (r.lvl or 1), "Lv " .. (r.lvl or 1)
  end

  -- ---- crafting maths ----
  local function count(save, id) return save.inventory[id] or 0 end
  local function haveMats(save, r)
    for _, m in ipairs(r.mats) do if count(save, m[1]) < m[2] then return false end end
    return true
  end
  local function costText(r)
    local parts = {}
    for _, m in ipairs(r.mats) do parts[#parts + 1] = m[2] .. SHORT[m[1]] end
    return table.concat(parts, "+")
  end
  local function doCraft(game, disc, r)
    if not gateInfo(game.save, disc, r) then return false, "gate" end
    if not haveMats(game.save, r) then return false, "mats" end
    for _, m in ipairs(r.mats) do Bag.remove(game.save, m[1], m[2]) end
    if not Bag.add(game.save, r.out, 1, game.data) then
      for _, m in ipairs(r.mats) do Bag.add(game.save, m[1], m[2], game.data) end
      return false, "full"
    end
    local before = levelOf(disc)
    addXP(disc, r.xp or 6)
    return true, (levelOf(disc) > before) and "levelup" or "ok"
  end

  -- ---- discipline recipe screens ----
  local function makeDiscScreen(disc, label, recipes)
    local function rows(game)
      local out = {}
      for _, r in ipairs(recipes) do
        local ok, lock = gateInfo(game.save, disc, r)
        out[#out + 1] = { label = r.name, right = ok and costText(r) or lock, recipe = r }
      end
      out[#out + 1] = { label = "BACK" }
      return out
    end
    mod.content.screens:register("CRAFT_" .. disc:upper(), {
      new = function(game)
        local menu
        menu = mod.ui.ListMenu.new(game, label .. " Lv " .. levelOf(disc), rows(game), {
          footer = "Pick something to make.",
          onChoose = function(item, m)
            if not item.recipe then m:close(); return end
            local ok, why = doCraft(game, disc, item.recipe)
            if ok and why == "levelup" then
              m.footer = label .. " is now Lv " .. levelOf(disc) .. "!"
            elseif ok then
              m.footer = "Made a " .. item.recipe.name .. "!"
            elseif why == "gate" then
              if item.recipe.badges ~= nil then
                m.footer = "Needs " .. item.recipe.badges .. " badges."
              else
                m.footer = "Reach " .. label .. " Lv " .. item.recipe.lvl .. " first."
              end
            elseif why == "full" then
              m.footer = "Your bag is full."
            else
              m.footer = "Not enough materials."
            end
            m.title = label .. " Lv " .. levelOf(disc)
            m.items = rows(game)
            if m.index > #m.items then m.index = #m.items end
          end,
        })
        return menu
      end,
    })
  end
  for _, d in ipairs(DISCIPLINES) do makeDiscScreen(d.key, d.label, d.recipes) end

  -- ---- gathering view (read-only materials list) ----
  mod.content.screens:register("CRAFT_GATHER", {
    new = function(game)
      local rows = {}
      for _, mt in ipairs(MATS) do
        local c = count(game.save, mt.id)
        if c > 0 then rows[#rows + 1] = { label = mt.name, right = "x" .. c } end
      end
      if #rows == 0 then rows[#rows + 1] = { label = "(nothing gathered yet)" } end
      rows[#rows + 1] = { label = "BACK" }
      return mod.ui.ListMenu.new(game, "GATHERING Lv " .. levelOf("gathering"), rows, {
        footer = "Higher level yields more per forage.",
        onChoose = function(_, m) m:close() end,
      })
    end,
  })

  -- ---- the hub ----
  mod.content.screens:register("CRAFT_HUB", {
    new = function(game)
      local function rows()
        return {
          { label = "ALCHEMY",     right = "Lv " .. levelOf("alchemy"),     sub = "CRAFT_ALCHEMY" },
          { label = "COOKING",     right = "Lv " .. levelOf("cooking"),     sub = "CRAFT_COOKING" },
          { label = "ENGINEERING", right = "Lv " .. levelOf("engineering"), sub = "CRAFT_ENGINEERING" },
          { label = "TM LAB",      right = "Lv " .. levelOf("tinkering"),   sub = "CRAFT_TINKERING" },
          { label = "GATHERING",   right = "Lv " .. levelOf("gathering"),   sub = "CRAFT_GATHER" },
          { label = "DONE" },
        }
      end
      local menu
      menu = mod.ui.ListMenu.new(game, "CRAFTING", rows(), {
        footer = "What will you make?",
        onChoose = function(item, m)
          if not item.sub then m:close(); return end
          m.items = rows()             -- freshen the level readouts
          mod.ui.push(game, item.sub)
        end,
      })
      return menu
    end,
  })

  mod.content.commands:register("crafting:open", {
    foreground = true, fn = function(ctx) Commands.push_screen(ctx, "CRAFT_HUB") end,
  })

  -- a CRAFT entry in the START menu (next to QUESTS), so the hub is always
  -- reachable without finding a bench
  mod.hooks:wrap("ui.start_menu.items", function(next, game, items)
    local out = next(game, items)
    if type(out) ~= "table" then return out end
    return mod.ui.insertBefore(out, "SAVE", {
      label = "CRAFT",
      onSelect = function() mod.ui.push(game, "CRAFT_HUB") end,
    })
  end)

  -- ===== reachable placement (benches + forage nodes) ========================
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
  -- count walkable orthogonal neighbours: fewer = more off to the side, so a
  -- foraging node lands against scenery instead of in the middle of the path
  local function openness(ov, x, y)
    local n = 0
    for _, d in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
      if walkable(ov, x + d[1], y + d[2]) then n = n + 1 end
    end
    return n
  end
  local function pickCell(ov, ow, tx, ty, offPath)
    local px, py = ow.player and ow.player.cellX, ow.player and ow.player.cellY
    if not px then return nil end
    local W, seen, q, head = ov.width, {}, { { px, py } }, 1
    seen[py * W + px] = true
    local best, bestScore, any, anyD
    while head <= #q and head < 6000 do
      local c = q[head]; head = head + 1
      local far = math.abs(c[1] - px) + math.abs(c[2] - py)
      if far >= 1 then
        if tx then
          local score = math.abs(c[1] - tx) + math.abs(c[2] - ty)
          if not best or score < bestScore then best, bestScore = c, score end
        elseif far >= 4 and far <= 10 then
          -- prefer low-openness (edge/corner) tiles so nodes stay off the path
          local score = openness(ov, c[1], c[2]) * 100 - far
          if not best or score < bestScore then best, bestScore = c, score end
        end
        if not any or far < anyD then any, anyD = c, far end
      end
      for _, dd in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
        local nx, ny = c[1] + dd[1], c[2] + dd[2]
        if walkable(ov, nx, ny) and not seen[ny * W + nx] then seen[ny * W + nx] = true; q[#q + 1] = { nx, ny } end
      end
    end
    return best or any
  end

  -- ===== bench NPCs ==========================================================
  local benchSpawned = {}
  for _, b in ipairs(BENCHES) do
    mod.content.map_scripts:register(b.map, {
      talk = { [b.text] = { { "crafting:open" } } },
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
  local forageId, forageTier, currentForageMap = {}, {}, nil
  mod.content.commands:register("crafting:forage", {
    foreground = true,
    fn = function(ctx)
      local map = currentForageMap
      local tier = (map and forageTier[map]) or 1
      Commands.show_text(ctx, "You search the\nbrush and rocks...")
      local mat = TIER_MATS[tier][math.random(#TIER_MATS[tier])]
      local qty = math.random(1, 3) + math.floor(levelOf("gathering") / 2)
      Commands.give_item(ctx, mat, qty, true)
      addXP("gathering", 4)
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
        if mod.save:get("forage_wk_" .. f.map, -1) == realWeek() then return end
        local ov = overview(); if not ov then return end
        local cell = pickCell(ov, ow, nil, nil, true); if not cell then return end
        local id = mod.world:spawnNpc(f.map, { sprite = FORAGE_SPRITE, text = FORAGE_TEXT, movement = "STAY", range = "NONE", x = cell[1], y = cell[2] })
        if id then forageId[f.map] = id end
      end,
    })
  end

  -- ===== wild-battle drops ===================================================
  local G, dropMsg, dropT = nil, "", 0
  mod.hooks:wrap("core.update", function(next, game, dt)
    local r = next(game, dt); G = game
    if dropT > 0 then dropT = dropT - 1 end
    return r
  end)
  mod.events:on("battle.ended", function(ev)
    if not (ev and ev.result == "win" and ev.battle and ev.battle.kind == "wild") then return end
    if not (G and G.save) then return end
    local water = enemyIsWater(ev, G.data)
    if math.random(100) > (water and WATER_CHANCE or DROP_CHANCE) then return end
    local tbl = water and WATER_DROPS
                or (REGION_DROPS[regionFor(G.save.player and G.save.player.map)] or DEFAULT_DROPS)
    local mat = weightedPick(tbl)
    if Bag.add(G.save, mat, 1, G.data) then
      addXP("gathering", 2)
      local nm = "material"
      for _, m in ipairs(MATS) do if m.id == mat then nm = m.name end end
      local msg = "Found a " .. nm .. "!"
      local tw = mod.find("tweaks")
      if tw and tw.exports and tw.exports.push then tw.exports.push(msg)
      else dropMsg, dropT = msg, 240 end
    end
  end)
  mod.hooks:wrap("render.hud", function(next, game, viewport)
    local r = next(game, viewport)
    if dropT > 0 then
      local vp = viewport or {}
      local s = math.max(1, math.floor(vp.scale or 2))
      local x, y = 4 * s, (vp.gameY or 0) + 4 * s
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
