-- town_quests
-- ------------------------------------------------------------------
-- A set of small fetch quests between NPCs in different towns. Each quest:
-- a GIVER in one town asks you to find a thing; a HOLDER in another town
-- hands it over once the quest is active; return it to the giver for a
-- reward. Modeled on the shipped example_lost_parcel pattern.
--
-- All registry content: a custom key item + talk branches on two real NPCs
-- per quest, tracked with MOD_ flags. No engine files edited, no map changed.

local QUESTS = {
  {
    id = "keepsake", item = "TQ_KEEPSAKE", itemName = "KEEPSAKE", reward = "POKE_DOLL",
    giver = { map = "PALLET_TOWN", npc = "TEXT_PALLETTOWN_GIRL" },
    holder = { map = "VIRIDIAN_CITY", npc = "TEXT_VIRIDIANCITY_GIRL" },
    offer = "Oh no... I lost my\nKEEPSAKE up in\vVIRIDIAN CITY.\fCould you look\nfor it?",
    accept = "Thank you so\nmuch! It means\vthe world to me.",
    remind = "Any sign of my\nKEEPSAKE in\vVIRIDIAN CITY?",
    reward_line = "My KEEPSAKE!\nYou found it!\fPlease, take this\nas thanks!",
    refuse = "Oh... okay. Maybe\nsomeone else.",
    after = "Thank you again\nfor my KEEPSAKE!",
    holder_give = "Hm? Someone\ndropped this.\fA KEEPSAKE -- take\nit, it's not mine.",
    holder_idle = "Lovely breeze in\nVIRIDIAN today.",
  },
  {
    id = "letter", item = "TQ_LETTER", itemName = "LETTER", reward = "RARE_CANDY",
    giver = { map = "CERULEAN_CITY", npc = "TEXT_CERULEANCITY_COOLTRAINER_F1" },
    holder = { map = "VERMILION_CITY", npc = "TEXT_VERMILIONCITY_SAILOR1" },
    offer = "My pen pal, a\nSAILOR in\vVERMILION, has a\vLETTER for me.\fFetch it?",
    accept = "You're a dear!\nHe'll be by the\vdocks.",
    remind = "Has that SAILOR\nin VERMILION got\vmy LETTER?",
    reward_line = "My LETTER, at\nlast! Here, a\vsweet reward!",
    refuse = "No? The mail can\nwait, I suppose.",
    after = "His LETTER made\nmy whole week!",
    holder_give = "You're here for\nthe LETTER?\fAye, take it to\nCERULEAN for me.",
    holder_idle = "The sea's calm\ntoday, matey.",
  },
  {
    id = "herb", item = "TQ_HERB", itemName = "RARE HERB", reward = "MAX_ETHER",
    giver = { map = "CELADON_CITY", npc = "TEXT_CELADONCITY_GIRL" },
    holder = { map = "FUCHSIA_CITY", npc = "TEXT_FUCHSIACITY_YOUNGSTER2" },
    offer = "A kid in FUCHSIA\nfound a RARE HERB\vmy gran needs.\fCould you get it?",
    accept = "Bless you! Gran\nwill be so glad.",
    remind = "That RARE HERB in\nFUCHSIA -- any\vluck?",
    reward_line = "The RARE HERB!\nGran thanks you.\fTake this, please!",
    refuse = "Oh... get well\nsoon, gran.",
    after = "Gran's feeling\nmuch better now!",
    holder_give = "This weird plant?\nI don't want it.\fA RARE HERB -- all\nyours!",
    holder_idle = "SAFARI ZONE's\nthis way, ya know.",
  },
  {
    id = "charm", item = "TQ_CHARM", itemName = "LUCK CHARM", reward = "NUGGET",
    giver = { map = "LAVENDER_TOWN", npc = "TEXT_LAVENDERTOWN_LITTLE_GIRL" },
    holder = { map = "PEWTER_CITY", npc = "TEXT_PEWTERCITY_YOUNGSTER" },
    offer = "A boy in PEWTER\nhas my LUCK CHARM.\fThis town scares\nme... please help?",
    accept = "Thank you! I'll\nfeel safe with it\vback.",
    remind = "Did you find my\nLUCK CHARM in\vPEWTER?",
    reward_line = "My LUCK CHARM!\nNow the ghosts\vwon't get me!\fHere, for you!",
    refuse = "Oh... it's so\nspooky here.",
    after = "I sleep soundly\nnow. Thank you!",
    holder_give = "Found this shiny\nthing by the gym.\fA LUCK CHARM --\ntake it!",
    holder_idle = "BROCK is tough,\nlet me tell you.",
  },
}

local function flag(id, suffix) return "MOD_TQ_" .. id .. "_" .. suffix end

local function giverTalk(q)
  local STARTED, TAKEN, DONE = flag(q.id, "STARTED"), flag(q.id, "TAKEN"), flag(q.id, "DONE")
  return {
    { "check_flag", DONE },
    { "jump_if_true", "after" },
    { "check_flag", STARTED },
    { "jump_if_true", "pending" },

    { "show_text", q.offer },
    { "choice", { "SURE", "NO" } },
    { "jump_if_false", "refuse" },
    { "set_flag", STARTED },
    { "show_text", q.accept },
    { "jump", "end" },

    { "label", "pending" },
    { "check_item", q.item },
    { "jump_if_false", "remind" },
    { "take_item", q.item },
    { "give_item", q.reward },
    { "set_flag", DONE },
    { "emote", "player", "happy", 45 },
    { "show_text", q.reward_line },
    { "jump", "end" },

    { "label", "remind" },
    { "show_text", q.remind },
    { "jump", "end" },

    { "label", "refuse" },
    { "show_text", q.refuse },
    { "jump", "end" },

    { "label", "after" },
    { "show_text", q.after },
  }
end

local function holderTalk(q)
  local STARTED, TAKEN = flag(q.id, "STARTED"), flag(q.id, "TAKEN")
  return {
    { "check_flag", STARTED },
    { "jump_if_false", "idle" },
    { "check_flag", TAKEN },
    { "jump_if_true", "idle" },

    { "show_text", q.holder_give },
    { "give_item", q.item, 1, true },
    { "set_flag", TAKEN },
    { "jump", "end" },

    { "label", "idle" },
    { "show_text", q.holder_idle },
  }
end

return function(mod)
  -- collect talk entries per map so quests that share a town compose
  local byMap = {}
  local function put(map, npc, talk)
    byMap[map] = byMap[map] or {}
    byMap[map][npc] = talk
  end

  for _, q in ipairs(QUESTS) do
    mod.content.items:register(q.item, {
      id = q.item, name = q.itemName, price = 0, keyItem = true, tossable = false,
    })
    put(q.giver.map, q.giver.npc, giverTalk(q))
    put(q.holder.map, q.holder.npc, holderTalk(q))

    -- announce completion for any other mod that cares
    mod.events:on("flag.changed", function(ev)
      if ev.name == flag(q.id, "DONE") and ev.value then
        mod.events:emit("mod.town_quests." .. q.id .. ".completed", { reward = q.reward })
      end
    end)
  end

  for map, talk in pairs(byMap) do
    mod.content.map_scripts:register(map, { talk = talk })
  end
end
