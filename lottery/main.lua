-- lottery
-- ------------------------------------------------------------------
-- A lottery vendor stands outside the mart in every town. Buy a cheap
-- ticket and lock in a number from 1 to 100 (roll and reroll until you
-- like it). Draws happen every WEDNESDAY and SATURDAY; match the drawn
-- number to win the jackpot. Collect winnings by talking to ANY vendor
-- after the draw.
--
-- The winning number is derived from the draw's date, so it is the same no
-- matter which vendor you check or when you check. One ticket at a time.

local TOWNS = {
  { map = "VIRIDIAN_CITY", tx = 29, ty = 20 },
  { map = "PEWTER_CITY",   tx = 23, ty = 18 },
  { map = "CERULEAN_CITY", tx = 25, ty = 26 },
  { map = "VERMILION_CITY", tx = 23, ty = 14 },
  { map = "LAVENDER_TOWN", tx = 15, ty = 14 },
  { map = "CELADON_CITY",  tx = 9,  ty = 14 },
  { map = "FUCHSIA_CITY",  tx = 5,  ty = 14 },
  { map = "SAFFRON_CITY",  tx = 25, ty = 12 },
  { map = "CINNABAR_ISLAND", tx = 15, ty = 12 },
}
local VTEXT = "TEXT_LOTTERY_VENDOR"
local VSPRITE = "SPRITE_GAMBLER"
local PRICE = 100
local JACKPOT = 50000

local function nowDay() return math.floor((os.time and os.time() or 0) / 86400) end
local function wday()
  local ok, t = pcall(os.date, "*t")
  return (ok and type(t) == "table" and t.wday) or 1 -- 1=Sun .. 7=Sat
end
-- the day-number of the next Wednesday or Saturday (today counts)
local function nextDrawDay()
  local w = wday()
  local dW, dS = (4 - w) % 7, (7 - w) % 7 -- Wed=4, Sat=7
  return nowDay() + math.min(dW, dS)
end
local function winningFor(drawDay)
  local s, str = 5381, "draw" .. tostring(drawDay)
  for i = 1, #str do s = (s * 33 + str:byte(i)) % 2147483647 end
  return (s % 100) + 1
end

return function(mod)
  local Commands = require("src.script.Commands")
  local pending = 0 -- the number currently shown while buying / stored ticket

  mod.content.tokens:register("LOTTERY_NUM", function() return tostring(pending) end)

  -- state checks (no yields)
  mod.content.commands:register("lottery:has_result", {
    foreground = true,
    fn = function(ctx)
      local num = mod.save:get("ticket_num", 0)
      ctx.lastCheck = (num > 0 and nowDay() > mod.save:get("ticket_draw", -1))
    end,
  })
  mod.content.commands:register("lottery:has_pending", {
    foreground = true,
    fn = function(ctx)
      local num = mod.save:get("ticket_num", 0)
      local isP = (num > 0 and nowDay() <= mod.save:get("ticket_draw", -1))
      if isP then pending = num end
      ctx.lastCheck = isP
    end,
  })
  mod.content.commands:register("lottery:can_afford", {
    foreground = true,
    fn = function(ctx) ctx.lastCheck = (ctx.save.money or 0) >= PRICE end,
  })
  mod.content.commands:register("lottery:roll", {
    foreground = true,
    fn = function() pending = math.random(1, 100) end,
  })
  mod.content.commands:register("lottery:buy", {
    foreground = true,
    fn = function(ctx)
      Commands.give_money(ctx, -PRICE)
      mod.save:set("ticket_num", pending)
      mod.save:set("ticket_draw", nextDrawDay())
    end,
  })
  mod.content.commands:register("lottery:reveal", {
    foreground = true,
    fn = function(ctx)
      local num = mod.save:get("ticket_num", 0)
      local draw = mod.save:get("ticket_draw", -1)
      local win = winningFor(draw)
      mod.save:set("ticket_num", 0)
      mod.save:set("ticket_draw", -1)
      if num == win then
        Commands.show_text(ctx, ("JACKPOT!! Your\nnumber %d hit the\vdraw!\fHere is your\nprize!"):format(num))
        Commands.give_money(ctx, JACKPOT)
      else
        Commands.show_text(ctx, ("The winning number\nwas %d.\fYour %d missed.\nBetter luck next\vdraw!"):format(win, num))
      end
    end,
  })

  local talk = {
    { "lottery:has_result" }, { "jump_if_true", "reveal" },
    { "lottery:has_pending" }, { "jump_if_true", "pending" },
    { "show_text", "Step right up!\nThe LOTTERY draws\vevery WED and SAT.\fA ticket is ¥100.\nBuy one?" },
    { "choice", { "YES", "NO" } }, { "jump_if_false", "no" },
    { "lottery:can_afford" }, { "jump_if_false", "poor" },
    { "lottery:roll" },
    { "label", "offer" },
    { "show_text", "Your number is\n#{LOTTERY_NUM}.\fKeep it?" },
    { "choice", { "KEEP IT", "REROLL" } }, { "jump_if_false", "reroll" },
    { "lottery:buy" },
    { "show_text", "Ticket #{LOTTERY_NUM}\nlocked in!\fCome see any vendor\nafter the draw.\vGood luck!" },
    { "jump", "end" },
    { "label", "reroll" }, { "lottery:roll" }, { "jump", "offer" },
    { "label", "poor" }, { "show_text", "You haven't got\n¥100 for a ticket." }, { "jump", "end" },
    { "label", "no" }, { "show_text", "Come back if you\nfeel lucky!" }, { "jump", "end" },
    { "label", "pending" }, { "show_text", "Your ticket #{LOTTERY_NUM}\nis in the draw.\fCheck back after\nWED or SAT!" }, { "jump", "end" },
    { "label", "reveal" }, { "lottery:reveal" },
  }

  -- ------- spawn a vendor just outside each town's mart -------------
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
  -- A reachable tile BESIDE the mart entrance, not on the doormat. We take the
  -- nearest reachable cell that is at least 2 tiles from the door and off the
  -- door's own column, so the vendor flanks the entrance instead of blocking
  -- it. Falls back to the plain nearest cell only if a map is too cramped to
  -- offer one (so we never fail to spawn).
  local function pickNear(ov, ow, tx, ty)
    local px, py = ow.player and ow.player.cellX, ow.player and ow.player.cellY
    if not px then return nil end
    local W, seen, q, head = ov.width, {}, { { px, py } }, 1
    seen[py * W + px] = true
    local best, bestScore, fallback, fallbackD
    while head <= #q and head < 6000 do
      local c = q[head]; head = head + 1
      local doorD = math.abs(c[1] - tx) + math.abs(c[2] - ty)
      if math.abs(c[1] - px) + math.abs(c[2] - py) >= 1 then
        -- keep the doormat and the tile right in front of it clear
        if doorD >= 2 then
          -- prefer a tile off the door's column so it stands to one side
          local score = doorD + (c[1] == tx and 4 or 0)
          if not best or score < bestScore then best, bestScore = c, score end
        end
        if not fallback or doorD < fallbackD then fallback, fallbackD = c, doorD end
      end
      for _, dd in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
        local nx, ny = c[1] + dd[1], c[2] + dd[2]
        if walkable(ov, nx, ny) and not seen[ny * W + nx] then seen[ny * W + nx] = true; q[#q + 1] = { nx, ny } end
      end
    end
    return best or fallback
  end

  local spawned = {}
  local function ensure(town, ow)
    if spawned[town.map] then return end
    local ov = overview(); if not ov then return end
    local cell = pickNear(ov, ow, town.tx, town.ty); if not cell then return end
    local id = mod.world:spawnNpc(town.map, { sprite = VSPRITE, text = VTEXT, movement = "STAY", range = "NONE", x = cell[1], y = cell[2] })
    if id then spawned[town.map] = true end
  end

  for _, town in ipairs(TOWNS) do
    mod.content.map_scripts:register(town.map, {
      talk = { [VTEXT] = talk },
      onEnter = function(game, ow) ensure(town, ow) end,
    })
  end
end
