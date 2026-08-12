-- friendships
-- ------------------------------------------------------------------
-- Build relationships with townsfolk over time. Talking to a befriendable
-- NPC once a (real-world) day raises your bond; their greeting warms up as
-- you climb from STRANGER to BEST PAL, and they hand you a gift each time
-- you reach a new level. A FRIENDS entry in the START menu tracks every
-- bond.
--
-- Friendship is stored in mod.save (so it travels with the Pokemon save).
-- The once-a-day gate means bonds grow like real ones - come back tomorrow.
-- Gym leaders are not here yet: their NPC triggers the gym battle, so
-- befriending them safely needs the vanilla-preserving baseTalk pattern.

local ORDER = { "angler", "riverman", "climber", "gadgeteer", "roller", "isle" }

local NPCS = {
  angler = { map = "PALLET_TOWN", npc = "TEXT_PALLETTOWN_FISHER", name = "OLD ANGLER",
    lines = {
      "Hah, a stranger.\nMind the tide.",
      "You again? Decent\ncompany, I'll say.",
      "Good to see a\nfriend on my dock!",
      "My best fishin'\nbuddy! Here, take\vthis!",
    },
    gifts = { [2] = "ETHER", [3] = "RARE_CANDY", [4] = "NUGGET" } },

  riverman = { map = "VIRIDIAN_CITY", npc = "TEXT_VIRIDIANCITY_FISHER", name = "RIVERMAN",
    lines = {
      "Hm? Do I know\nyou, traveler?",
      "Back by the river,\neh? Welcome.",
      "A friendly face!\nThe fish are biting.",
      "My river pal!\nThis is for you.",
    },
    gifts = { [2] = "POKE_DOLL", [3] = "ELIXER", [4] = "PP_UP" } },

  climber = { map = "PEWTER_CITY", npc = "TEXT_PEWTERCITY_COOLTRAINER_F", name = "CLIMBER",
    lines = {
      "Oh, hello. New\naround here?",
      "You come by a lot.\nI like that.",
      "A real friend!\nThe peaks await us.",
      "My climbing\npartner! Catch!",
    },
    gifts = { [2] = "ETHER", [3] = "TM_ROCK_SLIDE", [4] = "NUGGET" } },

  gadgeteer = { map = "CERULEAN_CITY", npc = "TEXT_CERULEANCITY_SUPER_NERD3", name = "GADGETEER",
    lines = {
      "Busy, busy. What\ndo you need?",
      "Ah, my repeat\nvisitor. Hello!",
      "A friend of\nscience! Splendid.",
      "My lab's best\nfriend! A prototype\vfor you!",
    },
    gifts = { [2] = "ETHER", [3] = "TM_ICE_BEAM", [4] = "RARE_CANDY" } },

  roller = { map = "VERMILION_CITY", npc = "TEXT_VERMILIONCITY_GAMBLER2", name = "HIGH ROLLER",
    lines = {
      "You feelin' lucky,\nstranger?",
      "Ha, a regular! The\nhouse likes you.",
      "A pal at the\ntable! Good fortune!",
      "My lucky charm!\nJackpot -- for you!",
    },
    gifts = { [2] = "POKE_DOLL", [3] = "NUGGET", [4] = "RARE_CANDY" } },

  isle = { map = "CINNABAR_ISLAND", npc = "TEXT_CINNABARISLAND_GIRL", name = "ISLE GIRL",
    lines = {
      "Oh! A visitor to\nour island.",
      "You keep coming\nback. That's sweet.",
      "A dear friend!\nThe volcano's calm\vtoday.",
      "My island best\npal! A gift from\vthe shore!",
    },
    gifts = { [2] = "POKE_DOLL", [3] = "MAX_ETHER", [4] = "RARE_CANDY" } },
}

local LEVELS = { "STRANGER", "ACQUAINTED", "FRIEND", "BEST PAL" }

local function levelOf(pts)
  if pts <= 1 then return 1
  elseif pts <= 3 then return 2
  elseif pts <= 6 then return 3
  end
  return 4
end

local function realDay()
  local ok, t = pcall(os.date, "*t")
  if ok and type(t) == "table" and t.year and t.yday then return t.year * 366 + t.yday end
  local ok2, s = pcall(os.time)
  if ok2 and s then return math.floor(s / 86400) end
  return 1
end

return function(mod)
  local Commands = require("src.script.Commands")

  -- greet an NPC: raise the bond once per day, show a level-appropriate
  -- line, and hand over a gift the first time you reach a new level
  mod.content.commands:register("friendships:greet", {
    foreground = true,
    fn = function(ctx, key)
      local n = NPCS[key]
      if not n then return end
      local today = realDay()
      local pts = mod.save:get("fr_" .. key, 0)
      if mod.save:get("frd_" .. key, -1) ~= today then
        pts = pts + 1
        mod.save:set("fr_" .. key, pts)
        mod.save:set("frd_" .. key, today)
      end
      local lvl = levelOf(pts)
      Commands.show_text(ctx, n.lines[lvl])
      local gifted = mod.save:get("frg_" .. key, 1)
      if lvl > gifted then
        mod.save:set("frg_" .. key, lvl)
        local gift = n.gifts[lvl]
        if gift then Commands.give_item(ctx, gift, 1, true) end
      end
    end,
  })

  -- FRIENDS screen: every bond and its level
  mod.content.screens:register("FriendsList", {
    new = function(game)
      local items = {}
      for _, key in ipairs(ORDER) do
        local n = NPCS[key]
        local pts = mod.save:get("fr_" .. key, 0)
        items[#items + 1] = { label = n.name, right = LEVELS[levelOf(pts)], value = key }
      end
      return mod.ui.ListMenu.new(game, "FRIENDS", items, {
        onChoose = function(_, menu) menu:close() end,
      })
    end,
  })

  mod.hooks:wrap("ui.start_menu.items", function(next, game, items)
    local out = next(game, items)
    if type(out) ~= "table" then return out end
    return mod.ui.insertBefore(out, "SAVE", {
      label = "FRIENDS",
      onSelect = function() mod.ui.push(game, "FriendsList") end,
    })
  end)

  -- attach the greeter to each befriendable NPC (compose per map)
  local byMap = {}
  for key, n in pairs(NPCS) do
    byMap[n.map] = byMap[n.map] or {}
    byMap[n.map][n.npc] = { { "friendships:greet", key } }
  end
  for map, talk in pairs(byMap) do
    mod.content.map_scripts:register(map, { talk = talk })
  end
end
