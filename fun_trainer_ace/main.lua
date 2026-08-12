-- fun_trainer_ace  (a roster of optional trainers)
-- ------------------------------------------------------------------
-- Sprinkles battle trainers across the towns. Each one is an existing
-- townsperson who now ASKS if you'd like to battle (YES/NO) before any
-- fight, so they're purely optional. Beat one and it greets you for a
-- rematch line afterward, the way a real trainer would.
--
-- All registry content: a trainer per entry (trainers registry) placed on
-- a real NPC via a map talk script. No engine files edited, no map changed.
-- The battle fires with the `start_battle` verb; lastCheck is true on a win.

local TRAINERS = {
  { town = "VIRIDIAN_CITY", npc = "TEXT_VIRIDIANCITY_GAMBLER1",
    id = "OPP_FUN_ACE_LEO", name = "ACE LEO", money = 60,
    party = { { level = 15, species = "NIDORINO" }, { level = 16, species = "KADABRA" }, { level = 17, species = "GROWLITHE" } },
    ask = "You there!\nThose are some\vfine POKéMON.\fCare to battle?",
    win = "Whoa! You're the\nreal deal. Nice\vwork!",
    refuse = "No? Come find me\nwhen you feel\vbrave.",
    after = "That was a great\nmatch, {PLAYER}!" },

  { town = "PEWTER_CITY", npc = "TEXT_PEWTERCITY_COOLTRAINER_M",
    id = "OPP_FUN_ROCKY", name = "HIKER ROCKY", money = 40,
    party = { { level = 12, species = "GEODUDE" }, { level = 13, species = "SANDSHREW" }, { level = 14, species = "MACHOP" } },
    ask = "These rocks made\nme tough!\fWanna test your\nteam on me?",
    win = "Rock solid! You\nbeat me fair.",
    refuse = "Bah. Come back\nwhen you mean it.",
    after = "Keep climbing,\nkid!" },

  { town = "CERULEAN_CITY", npc = "TEXT_CERULEANCITY_COOLTRAINER_M",
    id = "OPP_FUN_DORIAN", name = "COOLTRAINER DORIAN", money = 50,
    party = { { level = 18, species = "PIDGEOTTO" }, { level = 19, species = "RATICATE" }, { level = 20, species = "KADABRA" } },
    ask = "You've got a\nconfident look.\fShall we battle?",
    win = "Impressive! You've\nreally trained.",
    refuse = "Another time,\nthen.",
    after = "Sharp as ever,\nI see." },

  { town = "VERMILION_CITY", npc = "TEXT_VERMILIONCITY_BEAUTY",
    id = "OPP_FUN_BLAZE", name = "BEAUTY BLAZE", money = 55,
    party = { { level = 22, species = "VULPIX" }, { level = 23, species = "PONYTA" }, { level = 24, species = "GROWLITHE" } },
    ask = "My fire types\nburn bright!\fDare to face them?",
    win = "Ooh, you snuffed\nmy flames!",
    refuse = "Too hot for you?\nHee hee.",
    after = "Still smoldering\nover that loss!" },

  { town = "CELADON_CITY", npc = "TEXT_CELADONCITY_FISHER",
    id = "OPP_FUN_MARINA", name = "FISHER MARINA", money = 45,
    party = { { level = 28, species = "SEADRA" }, { level = 29, species = "KINGLER" }, { level = 30, species = "TENTACRUEL" } },
    ask = "Reeled in a fine\nteam today.\fCare to battle?",
    win = "You slipped the\nnet! Well done.",
    refuse = "The tide will\nturn, hah!",
    after = "Nice catch of a\nwin you had." },

  { town = "LAVENDER_TOWN", npc = "TEXT_LAVENDERTOWN_COOLTRAINER_M",
    id = "OPP_FUN_SPECTRA", name = "MEDIUM SPECTRA", money = 55,
    party = { { level = 30, species = "HAUNTER" }, { level = 32, species = "MAROWAK" }, { level = 33, species = "HAUNTER" } },
    ask = "The spirits are\nrestless...\fDare you battle?",
    win = "The spirits are\nquiet now. You\vwin.",
    refuse = "The dead can\nwait. Can you?",
    after = "The tower still\nwhispers of you." },

  { town = "FUCHSIA_CITY", npc = "TEXT_FUCHSIACITY_YOUNGSTER1",
    id = "OPP_FUN_VENOM", name = "JUGGLER VENOM", money = 50,
    party = { { level = 34, species = "ARBOK" }, { level = 35, species = "WEEZING" }, { level = 36, species = "MUK" } },
    ask = "My poisons never\nmiss!\fWant a taste of\nbattle?",
    win = "Ack! You resisted\nit all!",
    refuse = "Afraid of a\nlittle poison?",
    after = "Still stinging\nfrom that loss." },

  { town = "CINNABAR_ISLAND", npc = "TEXT_CINNABARISLAND_GAMBLER",
    id = "OPP_FUN_EMBER", name = "BLAINE FAN EMBER", money = 70,
    party = { { level = 40, species = "RAPIDASH" }, { level = 42, species = "ARCANINE" }, { level = 44, species = "FLAREON" } },
    ask = "This island runs\nhot!\fThink you can\nhandle my fire?",
    win = "Blazing battle!\nYou earned it.",
    refuse = "Cold feet? Come\nback when you're\vfired up.",
    after = "That match was\none for the ages!" },
}

local function flagFor(id) return "MOD_FT_" .. id .. "_BEATEN" end

local function trainerTalk(t)
  return {
    { "check_flag", flagFor(t.id) },
    { "jump_if_true", "after" },
    { "show_text", t.ask },
    { "choice", { "YES", "NO" } },
    { "jump_if_false", "refuse" },
    { "start_battle", "trainer", t.id, 1 },
    { "jump_if_false", "end" }, -- a loss blacks you out; bail quietly
    { "set_flag", flagFor(t.id) },
    { "show_text", t.win },
    { "jump", "end" },
    { "label", "refuse" },
    { "show_text", t.refuse },
    { "jump", "end" },
    { "label", "after" },
    { "show_text", t.after },
  }
end

return function(mod)
  -- optional tweaks BATTLE DIFF scales every team's levels. Parties are static
  -- (registered here at load), so this is read once; changing the setting takes
  -- effect after a reload.
  local tw = mod.find("tweaks")
  local mult = (tw and tw.exports and tw.exports.difficulty and tw.exports.difficulty().levelMult) or 1
  local function scaleParty(p)
    local out = {}
    for i, mon in ipairs(p) do
      out[i] = { level = math.min(100, math.floor(mon.level * mult)), species = mon.species }
    end
    return out
  end
  -- register every trainer, and collect talk entries per map so several
  -- trainers on one map compose instead of overwriting
  local byMap = {}
  for _, t in ipairs(TRAINERS) do
    mod.content.trainers:register(t.id, {
      id = t.id, name = t.name, baseMoney = t.money, parties = { scaleParty(t.party) },
    })
    byMap[t.town] = byMap[t.town] or {}
    byMap[t.town][t.npc] = trainerTalk(t)
  end
  for map, talk in pairs(byMap) do
    mod.content.map_scripts:register(map, { talk = talk })
  end
end
