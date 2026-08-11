-- traveling_merchants  (STAGE 1)
-- ------------------------------------------------------------------
-- A merchant that moves from town to town by in-game day, sells a
-- daily-rotating stock of supplies, and lets the player choose how the
-- merchant wanders from the OPTIONS menu.
--
-- Built on the `world_clock` mod: the current day drives where the
-- merchant is. Each town reuses one existing NPC as the merchant's
-- "stall"; when the merchant isn't in that town, the NPC's normal
-- vanilla dialogue plays instead (the baseTalk pattern, same as the
-- shipped example_lost_parcel mod).
--
-- Route modes (player-selectable in OPTIONS):
--   3-TOWN LOOP : Pewter -> Cerulean -> Vermilion, by day.
--   5-TOWN LOOP : all five towns, by day.
--   RANDOM      : a pseudo-random town each day (re-rolls daily, but is
--                 stable within a day and across save/load because it's
--                 seeded purely by the day number).
--
-- NOTE: LOVE runs LuaJIT (Lua 5.1), which has NO bitwise operators, so
-- the daily randomness below is arithmetic-only (djb2 hash + a
-- Park-Miller LCG). Determinism = "same day always yields the same
-- result," which is what keeps the merchant from teleporting mid-day.

-- ------- the merchant's towns (host NPC verified in Yellow data) ----

-- `index` is the host NPC's object index on its map (targets the
-- march/patrol). `patrol` (optional) is a list of step directions the
-- merchant paces while in town; the mod walks it out and back so the NPC
-- returns to its home tile every loop. Towns WITHOUT a patrol just march
-- in place. Patrols are set only where the NPC's vanilla sight `range`
-- hints an open direction, since scripted moves ignore collision.
local TOWNS = {
  PEWTER    = { map = "PEWTER_CITY",    npc = "TEXT_PEWTERCITY_COOLTRAINER_M",   label = "PEWTER CITY",    index = 2 },
  CERULEAN  = { map = "CERULEAN_CITY",  npc = "TEXT_CERULEANCITY_COOLTRAINER_M", label = "CERULEAN CITY",  index = 3, patrol = { "down", "down" } },
  VERMILION = { map = "VERMILION_CITY", npc = "TEXT_VERMILIONCITY_GAMBLER2",     label = "VERMILION CITY", index = 4 },
  CELADON   = { map = "CELADON_CITY",   npc = "TEXT_CELADONCITY_GRAMPS2",        label = "CELADON CITY",   index = 4, patrol = { "down", "down" } },
  FUCHSIA   = { map = "FUCHSIA_CITY",   npc = "TEXT_FUCHSIACITY_GAMBLER",        label = "FUCHSIA CITY",   index = 2, patrol = { "right", "right" } },
}

-- turn a patrol into its return trip (reverse order, opposite each step)
local OPPOSITE = { up = "down", down = "up", left = "right", right = "left" }
local function returnTrip(dirs)
  local r = {}
  for i = #dirs, 1, -1 do r[#r + 1] = OPPOSITE[dirs[i]] end
  return r
end

-- the ambient behavior for a town's stall NPC while the merchant is here
local function indicatorScript(t)
  if t.patrol then
    return {
      { "label", "top" },
      { "walk_npc", t.index, t.patrol },              -- pace out
      { "walk_npc", t.index, returnTrip(t.patrol) },  -- and back home
      { "wait", 45 },
      { "jump", "top" },
    }
  end
  -- no verified-open direction: just animate in place (non-blocking)
  return { { "march_in_place", t.index, true } }
end
local ORDER5 = { "PEWTER", "CERULEAN", "VERMILION", "CELADON", "FUCHSIA" }
local ORDER3 = { "PEWTER", "CERULEAN", "VERMILION" }

-- ------- route modes ----------------------------------------------

local MODES = { "THREE", "FIVE", "RANDOM" }
local MODE_LABEL = { THREE = "3-TOWN LOOP", FIVE = "5-TOWN LOOP", RANDOM = "RANDOM" }

-- ------- supplies pools (all verified real Yellow item ids) --------

local STAPLES = { "POTION", "SUPER_POTION" }
local HEALING = { "HYPER_POTION", "ANTIDOTE", "PARLYZ_HEAL", "BURN_HEAL",
                  "ICE_HEAL", "AWAKENING", "FULL_HEAL", "REVIVE" }
local DRINKS = { "FRESH_WATER", "SODA_POP", "LEMONADE" }
local VITAMINS = { "HP_UP", "PROTEIN", "IRON", "CARBOS", "CALCIUM", "PP_UP", "RARE_CANDY" }

-- ------- arithmetic-only determinism (no bitops on LuaJIT) ---------

local function seedFrom(a, b)
  local s = 5381
  local str = tostring(a) .. "|" .. tostring(b)
  for i = 1, #str do
    s = (s * 33 + str:byte(i)) % 2147483647
  end
  return s
end

-- Park-Miller minimal-standard LCG; returns a function yielding (0,1).
local function rng(seed)
  local state = seed % 2147483647
  if state <= 0 then state = state + 2147483646 end
  return function()
    state = (state * 16807) % 2147483647
    return state / 2147483647
  end
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

local function townForDay(day, mode)
  if mode == "FIVE" then
    return ORDER5[((day - 1) % #ORDER5) + 1]
  elseif mode == "RANDOM" then
    local nextR = rng(seedFrom("town", day))
    return ORDER5[math.floor(nextR() * #ORDER5) + 1]
  end
  return ORDER3[((day - 1) % #ORDER3) + 1]
end

-- The daily supplies stock: two staples plus a rotating pick, seeded by
-- day and town so it's stable within a day but differs day to day.
local function suppliesStockFor(day, townKey)
  local nextR = rng(seedFrom(day, townKey .. "supplies"))
  local stock = { STAPLES[1], STAPLES[2] }
  for _, id in ipairs(pickDistinct(nextR, HEALING, 3)) do stock[#stock + 1] = id end
  for _, id in ipairs(pickDistinct(nextR, DRINKS, 1)) do stock[#stock + 1] = id end
  for _, id in ipairs(pickDistinct(nextR, VITAMINS, 1)) do stock[#stock + 1] = id end
  return stock
end

-- ------- the per-NPC talk script ----------------------------------

local function buildTalk(townKey, map, npc)
  return {
    { "traveling_merchants:present", townKey }, -- lastCheck = merchant here today?
    { "jump_if_false", "away" },

    { "show_text", "A traveling\nmerchant! Care to\vsee my wares?" },
    { "choice", { "SUPPLIES", "NEVER MIND" } },
    { "jump_if_false", "bye" },
    { "traveling_merchants:open_supplies", townKey },

    { "label", "bye" },
    { "show_text", "Come back any\ntime, {PLAYER}!" },
    { "jump", "end" },

    -- merchant is elsewhere: play the NPC's real vanilla conversation
    { "label", "away" },
    { "traveling_merchants:base", map, npc },
  }
end

return function(mod)
  local Commands = require("src.script.Commands")
  local MapScripts = require("src.script.MapScripts")

  -- ------- route-mode setting (persisted in this mod's save) --------

  local function getMode() return mod.save:get("route_mode", "THREE") end
  local function cycleMode()
    local cur, idx = getMode(), 1
    for i, v in ipairs(MODES) do if v == cur then idx = i end end
    mod.save:set("route_mode", MODES[(idx % #MODES) + 1])
  end

  -- ------- where is the merchant today? -----------------------------

  local function currentDay()
    local wc = mod.find("world_clock")
    if wc and wc.exports and wc.exports.clock then
      local ok, c = pcall(wc.exports.clock)
      if ok and type(c) == "table" and c.day then return c.day end
    end
    return 1 -- world_clock absent: merchant sits in the first town
  end

  local function currentTown()
    return townForDay(currentDay(), getMode())
  end

  -- ------- script verbs this mod owns -------------------------------

  mod.content.commands:register("traveling_merchants:present", {
    foreground = true,
    fn = function(ctx, townKey)
      ctx.lastCheck = (currentTown() == townKey)
    end,
  })

  mod.content.commands:register("traveling_merchants:open_supplies", {
    foreground = true,
    fn = function(ctx, townKey)
      local stock = suppliesStockFor(currentDay(), townKey)
      -- one screen push + yield, exactly like the engine's open_mart
      Commands.push_screen(ctx, "ShopMenu", stock)
    end,
  })

  mod.content.commands:register("traveling_merchants:base", {
    foreground = true,
    fn = function(ctx, map, npc)
      local base = MapScripts.baseTalk(map, npc)
      if not base then return end
      local runner = ctx.runner
      base(ctx.game, ctx.overworld, ctx.npc, function() runner:resume() end)
      runner:yield()
    end,
  })

  -- ------- attach the merchant to each town's host NPC --------------

  for townKey, t in pairs(TOWNS) do
    mod.content.map_scripts:register(t.map, {
      talk = { [t.npc] = buildTalk(townKey, t.map, t.npc) },

      -- On entering the town, if the merchant is here today, start its
      -- ambient behavior (a deliberate patrol where we have a verified-open
      -- direction, otherwise march-in-place). Both are non-freezing, unlike
      -- the "!" emote. onEnter composes with the engine's own; the parallel
      -- script dies on map exit.
      onEnter = function(game, ow)
        if currentTown() == townKey then
          ow:queueScript({ { "run_parallel", t.map .. "/tm_indicator" } })
        end
      end,
      scripts = {
        tm_indicator = indicatorScript(t),
      },
    })
  end

  -- ------- OPTIONS row: pick the route mode -------------------------

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
