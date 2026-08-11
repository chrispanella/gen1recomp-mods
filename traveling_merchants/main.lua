-- traveling_merchants  (STAGE 1 — route edition)
-- ------------------------------------------------------------------
-- A dedicated merchant NPC that appears out ON THE ROUTES (not in towns,
-- which already have marts), travels route-to-route by in-game day, and
-- moves around under real collision.
--
-- How it works, and why it needs no map edits or NPC hijacking:
--   * mod.world:spawnNpc(routeId, {...}) drops a real CLERK NPC onto the
--     route the merchant is visiting today; removeNpc takes it away when
--     it moves on. (The engine's own runtime-object API.)
--   * mod.world:mapOverview() returns the engine's real collision grid
--     ("." walkable, " " wall, "~" water, "+" warp). We place the merchant
--     on a walkable tile and only ever step it onto walkable tiles, so it
--     never clips through scenery — collision is read from the game, not
--     guessed. (scriptMove itself does NOT check collision, so WE check.)
--   * A dedicated sprite + custom text constant, dispatched to our talk
--     script via map_scripts (talkScript resolves it, engine side).
--
-- Route mode (OPTIONS): 3-ROUTE / 5-ROUTE / RANDOM (random re-rolls daily).

local ROUTES5 = { "ROUTE_1", "ROUTE_2", "ROUTE_3", "ROUTE_4", "ROUTE_5" }
local ROUTES3 = { "ROUTE_1", "ROUTE_2", "ROUTE_3" }

local MERCHANT_SPRITE = "SPRITE_CLERK"
local MERCHANT_TEXT = "TEXT_TM_MERCHANT" -- our own const; talk wired via map_scripts

local MODES = { "THREE", "FIVE", "RANDOM" }
local MODE_LABEL = { THREE = "3-ROUTE LOOP", FIVE = "5-ROUTE LOOP", RANDOM = "RANDOM" }

-- ------- supplies pools (verified real Yellow item ids) ------------

local STAPLES = { "POTION", "SUPER_POTION" }
local HEALING = { "HYPER_POTION", "ANTIDOTE", "PARLYZ_HEAL", "BURN_HEAL",
                  "ICE_HEAL", "AWAKENING", "FULL_HEAL", "REVIVE" }
local DRINKS = { "FRESH_WATER", "SODA_POP", "LEMONADE" }
local VITAMINS = { "HP_UP", "PROTEIN", "IRON", "CARBOS", "CALCIUM", "PP_UP", "RARE_CANDY" }

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
    local nextR = rng(seedFrom("route", day))
    return ROUTES5[math.floor(nextR() * #ROUTES5) + 1]
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

return function(mod)
  local Commands = require("src.script.Commands")

  -- ------- route-mode setting (persisted in this mod's save) --------
  local function getMode() return mod.save:get("route_mode", "THREE") end
  local function cycleMode()
    local cur, idx = getMode(), 1
    for i, v in ipairs(MODES) do if v == cur then idx = i end end
    mod.save:set("route_mode", MODES[(idx % #MODES) + 1])
  end

  -- ------- clock + today's route -----------------------------------
  local function currentDay()
    local wc = mod.find("world_clock")
    if wc and wc.exports and wc.exports.clock then
      local ok, c = pcall(wc.exports.clock)
      if ok and type(c) == "table" and c.day then return c.day end
    end
    return 1
  end
  local function targetRoute() return routeForDay(currentDay(), getMode()) end

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

  -- ------- find our live merchant NPC on the active map ------------
  local function liveMerchant(ow)
    for _, n in ipairs(ow.npcs or {}) do
      if n.def and n.def.runtime and n.def.text == MERCHANT_TEXT then return n end
    end
    return nil
  end

  -- ------- the shop (daily-rotating supplies) ----------------------
  mod.content.commands:register("traveling_merchants:open_supplies", {
    foreground = true,
    fn = function(ctx)
      local routeId = ctx.overworld and ctx.overworld.map and ctx.overworld.map.id or "ROUTE_1"
      Commands.push_screen(ctx, "ShopMenu", suppliesStockFor(currentDay(), routeId))
    end,
  })

  -- ------- one patrol beat: step onto a walkable tile and back -----
  -- Background-legal (blocking, not foreground). Reads collision every
  -- beat, so it can never walk the merchant into a wall or the water.
  mod.content.commands:register("traveling_merchants:patrol_beat", {
    fn = function(ctx)
      local ow = ctx.overworld
      if not ow then return end
      local m = liveMerchant(ow)
      if not m then return end
      local ov = overview()
      if not ov then return end
      local cx, cy = m.cellX, m.cellY
      -- prefer pacing along the route (horizontal), then vertical
      local tries = {
        { "left", -1, 0, "right" }, { "right", 1, 0, "left" },
        { "up", 0, -1, "down" }, { "down", 0, 1, "up" },
      }
      for _, d in ipairs(tries) do
        if walkableAt(ov, cx + d[2], cy + d[3]) then
          Commands.walk_npc(ctx, m.def.index, { d[1] })       -- out (verified open)
          Commands.walk_npc(ctx, m.def.index, { d[4] })       -- back home
          return
        end
      end
    end,
  })

  -- ------- the merchant's dialogue ---------------------------------
  local function merchantTalk()
    return {
      { "show_text", "A traveling\nmerchant, out here\von the road!\fCare to see my\nwares?" },
      { "choice", { "SUPPLIES", "NEVER MIND" } },
      { "jump_if_false", "bye" },
      { "traveling_merchants:open_supplies" },
      { "label", "bye" },
      { "show_text", "Safe travels,\n{PLAYER}!" },
    }
  end

  -- ------- spawn / despawn lifecycle -------------------------------
  local spawn = { id = nil, map = nil }

  local function despawn()
    if spawn.id and mod.world then
      pcall(function() mod.world:removeNpc(spawn.id) end)
    end
    spawn.id, spawn.map = nil, nil
  end

  -- a walkable tile a few steps from the player, so the merchant is seen
  local function pickSpawnCell(ov, ow)
    local px = ow.player and ow.player.cellX or math.floor(ov.width / 2)
    local py = ow.player and ow.player.cellY or math.floor(ov.height / 2)
    for r = 2, 7 do
      for _, o in ipairs({ { r, 0 }, { -r, 0 }, { 0, r }, { 0, -r },
                           { r, r }, { -r, -r }, { r, -r }, { -r, r } }) do
        local x, y = px + o[1], py + o[2]
        if walkableAt(ov, x, y) then return x, y end
      end
    end
    return nil
  end

  local function ensureMerchant(routeId, ow)
    local target = targetRoute()
    -- clear a stale spawn (moved on to another route, or a new day)
    if spawn.id and (spawn.map ~= routeId or routeId ~= target) then despawn() end
    if routeId ~= target or spawn.id then return end

    local ov = overview()
    if not ov then return end
    local x, y = pickSpawnCell(ov, ow)
    if not x then return end

    local id = mod.world:spawnNpc(routeId, {
      sprite = MERCHANT_SPRITE, text = MERCHANT_TEXT,
      movement = "STAY", range = "NONE", x = x, y = y,
    })
    if not id then return end
    spawn.id, spawn.map = id, routeId
    -- start the collision-aware patrol loop
    ow:queueScript({ { "run_parallel", routeId .. "/tm_patrol" } })
  end

  -- ------- attach to each route in the circuit ---------------------
  for _, routeId in ipairs(ROUTES5) do
    mod.content.map_scripts:register(routeId, {
      talk = { [MERCHANT_TEXT] = merchantTalk() },
      onEnter = function(game, ow) ensureMerchant(routeId, ow) end,
      scripts = {
        tm_patrol = {
          { "label", "top" },
          { "traveling_merchants:patrol_beat" },
          { "wait", 40 },
          { "jump", "top" },
        },
      },
    })
  end

  -- ------- OPTIONS row: route mode ---------------------------------
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
