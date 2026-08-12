-- town_gifts
-- ------------------------------------------------------------------
-- Friendly townsfolk who hand out gifts. One mod, six NPCs (formerly the
-- daily_gift / wonder_trader / berry_grove / daily_coins / type_sage /
-- starter_pack mods):
--
--   PEWTER   super_nerd2  - a free item once per real week
--   PEWTER   (spawned)    - a ONE-TIME welcome kit; the NPC leaves for good
--                           once you claim it
--   CELADON  little_girl  - a rare Pokemon once per real week
--   CERULEAN guard1        - a healing item once per real week
--   CERULEAN cooltrainer_f2- Game Corner coins once per real week
--   CERULEAN guard2        - a rotating weekly type-matchup tip
--
-- Each weekly gift has its own save key so they refresh independently.

local function realWeek() return math.floor((os.time and os.time() or 0) / 604800) end

local GIFT_ITEMS = { "POKE_DOLL", "ETHER", "RARE_CANDY", "NUGGET", "MAX_POTION",
                     "ELIXER", "PP_UP", "FULL_RESTORE", "MAX_ETHER", "GUARD_SPEC" }
local TRADE_MONS = { { "OMANYTE", 18 }, { "KABUTO", 18 }, { "DRATINI", 15 }, { "EEVEE", 18 },
                     { "SCYTHER", 20 }, { "PINSIR", 20 }, { "LAPRAS", 20 }, { "PORYGON", 18 },
                     { "CHANSEY", 18 }, { "TAUROS", 20 } }
local BERRY_ITEMS = { "SUPER_POTION", "HYPER_POTION", "FULL_HEAL", "REVIVE",
                      "FRESH_WATER", "SODA_POP", "LEMONADE", "MAX_POTION" }
local TIPS = {
  "WATER douses FIRE,\nGROUND and ROCK.",
  "ELECTRIC zaps\nWATER and FLYING.",
  "GRASS drinks up\nWATER and GROUND.",
  "FIRE melts GRASS,\nICE and BUG.",
  "GROUND grounds\nELECTRIC and FIRE.",
  "PSYCHIC rattles\nFIGHTING and POISON.",
  "ICE chills GRASS,\nGROUND and FLYING.",
  "FIGHTING floors\nNORMAL and ICE.",
  "GHOST spooks\nPSYCHIC... in theory.",
  "ROCK crushes FIRE,\nFLYING and BUG.",
}

local STARTER_MAP = "PEWTER_CITY"
local STARTER_TEXT, STARTER_SPRITE = "TEXT_STARTER_PACK", "SPRITE_SUPER_NERD"
local STARTER_TX, STARTER_TY = 16, 24

return function(mod)
  local Commands = require("src.script.Commands")

  local function claimed(key) return mod.save:get(key, -1) == realWeek() end
  local function mark(key) mod.save:set(key, realWeek()) end

  -- ---- weekly gifts -------------------------------------------------
  mod.content.commands:register("town_gifts:gift", {
    foreground = true,
    fn = function(ctx)
      if claimed("gift_last") then
        Commands.show_text(ctx, "That's all for\nthis week! Come\vback next week.")
        return
      end
      mark("gift_last")
      Commands.show_text(ctx, "A little something\nfor stopping by.\vTake care!")
      Commands.give_item(ctx, GIFT_ITEMS[(realWeek() % #GIFT_ITEMS) + 1], 1, true)
    end,
  })
  mod.content.commands:register("town_gifts:trade", {
    foreground = true,
    fn = function(ctx)
      if claimed("trade_last") then
        Commands.show_text(ctx, "I've no more to\nspare this week. Visit\vnext week!")
        return
      end
      mark("trade_last")
      local m = TRADE_MONS[(realWeek() % #TRADE_MONS) + 1]
      Commands.show_text(ctx, "My weekly surprise\nPOKeMON... this one\vis for you!")
      Commands.give_pokemon(ctx, m[1], m[2], true)
    end,
  })
  mod.content.commands:register("town_gifts:berry", {
    foreground = true,
    fn = function(ctx)
      if claimed("berry_last") then
        Commands.show_text(ctx, "Stay safe out\nthere. Come back\vnext week!")
        return
      end
      mark("berry_last")
      Commands.show_text(ctx, "Here, for the\nroad. On the\vhouse, trainer.")
      Commands.give_item(ctx, BERRY_ITEMS[(realWeek() % #BERRY_ITEMS) + 1], 1, true)
    end,
  })
  mod.content.commands:register("town_gifts:coins", {
    foreground = true,
    fn = function(ctx)
      if claimed("coins_last") then
        Commands.show_text(ctx, "Spent your luck\nthis week! Back\vnext week, pal.")
        return
      end
      mark("coins_last")
      Commands.show_text(ctx, "Feelin' lucky?\nHere's some COINS\vfor the corner!")
      Commands.give_item(ctx, "COIN", 50, true)
    end,
  })
  mod.content.commands:register("town_gifts:tip", {
    foreground = true,
    fn = function(ctx)
      Commands.show_text(ctx, "Type tip of the\nweek:\f" .. TIPS[(realWeek() % #TIPS) + 1])
    end,
  })

  -- ---- one-time starter kit (spawned NPC that leaves once claimed) ---
  local starterId = nil
  mod.content.commands:register("town_gifts:starter", {
    foreground = true,
    fn = function(ctx)
      if mod.save:get("starter_claimed", false) then
        Commands.show_text(ctx, "You've got your\nkit already. Go\vget 'em!")
        return
      end
      Commands.show_text(ctx, "Every new trainer\nneeds a good kit.\vThis one's yours!")
      Commands.give_item(ctx, "POTION", 5, true)
      Commands.give_item(ctx, "SUPER_POTION", 2, false)
      Commands.give_item(ctx, "ANTIDOTE", 2, false)
      Commands.give_item(ctx, "PARLYZ_HEAL", 2, false)
      Commands.give_item(ctx, "RARE_CANDY", 1, false)
      Commands.show_text(ctx, "That's everything.\nOff you go, and\vgood luck out there!")
      mod.save:set("starter_claimed", true)
      if starterId and mod.world then
        pcall(function() mod.world:removeNpc(starterId) end)
        starterId = nil
      end
    end,
  })

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
  local function pickNear(ov, ow)
    local px, py = ow.player and ow.player.cellX, ow.player and ow.player.cellY
    if not px then return nil end
    local W, seen, q, head = ov.width, {}, { { px, py } }, 1
    seen[py * W + px] = true
    local best, bestd
    while head <= #q and head < 6000 do
      local c = q[head]; head = head + 1
      if math.abs(c[1] - px) + math.abs(c[2] - py) >= 1 then
        local d = math.abs(c[1] - STARTER_TX) + math.abs(c[2] - STARTER_TY)
        if not best or d < bestd then best, bestd = c, d end
      end
      for _, dd in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
        local nx, ny = c[1] + dd[1], c[2] + dd[2]
        if walkable(ov, nx, ny) and not seen[ny * W + nx] then seen[ny * W + nx] = true; q[#q + 1] = { nx, ny } end
      end
    end
    return best
  end
  local function ensureStarter(ow)
    if starterId then return end
    if mod.save:get("starter_claimed", false) then return end
    local ov = overview(); if not ov then return end
    local cell = pickNear(ov, ow); if not cell then return end
    local id = mod.world:spawnNpc(STARTER_MAP, {
      sprite = STARTER_SPRITE, text = STARTER_TEXT, movement = "STAY", range = "NONE",
      x = cell[1], y = cell[2],
    })
    if id then starterId = id end
  end

  -- ---- attach to maps (one register per map, talk entries aggregated) -
  mod.content.map_scripts:register("PEWTER_CITY", {
    talk = {
      TEXT_PEWTERCITY_SUPER_NERD2 = { { "town_gifts:gift" } },
      [STARTER_TEXT] = { { "town_gifts:starter" } },
    },
    onEnter = function(game, ow) ensureStarter(ow) end,
  })
  mod.content.map_scripts:register("CELADON_CITY", {
    talk = { TEXT_CELADONCITY_LITTLE_GIRL = { { "town_gifts:trade" } } },
  })
  mod.content.map_scripts:register("CERULEAN_CITY", {
    talk = {
      TEXT_CERULEANCITY_GUARD1 = { { "town_gifts:berry" } },
      TEXT_CERULEANCITY_COOLTRAINER_F2 = { { "town_gifts:coins" } },
      TEXT_CERULEANCITY_GUARD2 = { { "town_gifts:tip" } },
    },
  })
end
