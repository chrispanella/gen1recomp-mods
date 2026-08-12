-- starter_pack
-- ------------------------------------------------------------------
-- A one-time welcome NPC waits in Pewter City and hands new trainers a
-- starter kit of useful items. The moment you claim it the NPC waves you
-- off and disappears for good (it never spawns again on this save).

local MAP = "PEWTER_CITY"
local TARGET_X, TARGET_Y = 16, 24 -- rough town-center target; BFS snaps to a reachable tile
local STEXT = "TEXT_STARTER_PACK"
local SSPRITE = "SPRITE_SUPER_NERD"

return function(mod)
  local Commands = require("src.script.Commands")
  local spawnedId = nil

  mod.content.commands:register("starter_pack:give", {
    foreground = true,
    fn = function(ctx)
      if mod.save:get("claimed", false) then
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
      mod.save:set("claimed", true)
      -- the welcome NPC has done its job; retire it for good
      if spawnedId and mod.world then
        pcall(function() mod.world:removeNpc(spawnedId) end)
        spawnedId = nil
      end
    end,
  })

  -- ------- spawn the welcome NPC once, only while unclaimed ---------
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
  -- the reachable tile nearest the target, so the player can always walk up
  local function pickNear(ov, ow)
    local px, py = ow.player and ow.player.cellX, ow.player and ow.player.cellY
    if not px then return nil end
    local W, seen, q, head = ov.width, {}, { { px, py } }, 1
    seen[py * W + px] = true
    local best, bestd
    while head <= #q and head < 6000 do
      local c = q[head]; head = head + 1
      if math.abs(c[1] - px) + math.abs(c[2] - py) >= 1 then
        local d = math.abs(c[1] - TARGET_X) + math.abs(c[2] - TARGET_Y)
        if not best or d < bestd then best, bestd = c, d end
      end
      for _, dd in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
        local nx, ny = c[1] + dd[1], c[2] + dd[2]
        if walkable(ov, nx, ny) and not seen[ny * W + nx] then
          seen[ny * W + nx] = true; q[#q + 1] = { nx, ny }
        end
      end
    end
    return best
  end

  local function ensure(ow)
    if spawnedId then return end                  -- already standing this session
    if mod.save:get("claimed", false) then return end -- claimed for good
    local ov = overview(); if not ov then return end
    local cell = pickNear(ov, ow); if not cell then return end
    local id = mod.world:spawnNpc(MAP, {
      sprite = SSPRITE, text = STEXT, movement = "STAY", range = "NONE",
      x = cell[1], y = cell[2],
    })
    if id then spawnedId = id end
  end

  mod.content.map_scripts:register(MAP, {
    talk = { [STEXT] = { { "starter_pack:give" } } },
    onEnter = function(game, ow) ensure(ow) end,
  })
end
