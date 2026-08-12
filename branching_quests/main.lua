-- branching_quests
-- ------------------------------------------------------------------
-- Two questlines with real choices and multiple endings. Which faction
-- you side with changes the reward AND how the other NPCs treat you
-- afterward. All script-VM content: choices set MOD_ flags, and every
-- NPC branches on those flags. No engine files edited, no maps changed.
--
--   1) THE SECRET MAP -- a sailor hands you a map two people want. Give it
--      to the SCIENTIST (Saffron) for knowledge, or the GAMBLER (Fuchsia)
--      for gold. Each ending locks out the other and both react to it.
--   2) THE POACHER'S BARGAIN -- a researcher sends you after a poacher.
--      Take back the AMBER SHARD for the researcher's reward, or pocket
--      the poacher's bribe and let him go.

-- ------- items -----------------------------------------------------
local MAP_ITEM = "BQ_SECRET_MAP"
local SHARD_ITEM = "BQ_AMBER_SHARD"

-- ------- Quest 1: The Secret Map -----------------------------------
local Q1 = { STARTED = "MOD_BQ1_STARTED", DONE = "MOD_BQ1_DONE",
             SCI = "MOD_BQ1_END_SCI", FOR = "MOD_BQ1_END_FOR" }

local function q1_sailor()
  return {
    { "check_flag", Q1.DONE }, { "jump_if_true", "resolved" },
    { "check_flag", Q1.STARTED }, { "jump_if_true", "waiting" },
    { "show_text", "Arr! I fished up\nthis SECRET MAP.\fTwo folk want it:\na SCIENTIST in\vSAFFRON, a GAMBLER\vin FUCHSIA.\fYou decide who\ngets it." },
    { "give_item", MAP_ITEM, 1, true },
    { "set_flag", Q1.STARTED },
    { "jump", "end" },
    { "label", "waiting" },
    { "show_text", "Still holdin' that\nmap? SAFFRON's\vSCIENTIST or\vFUCHSIA's GAMBLER.\fYour call, sailor." },
    { "jump", "end" },
    { "label", "resolved" },
    { "check_flag", Q1.SCI }, { "jump_if_true", "res_sci" },
    { "show_text", "Sold it to the\nGAMBLER, eh? Gold's\vgold, I s'pose." },
    { "jump", "end" },
    { "label", "res_sci" },
    { "show_text", "Gave it to the\nSCIENTIST. Knowledge\vover coin -- good\non ya." },
  }
end

local function q1_scientist()
  return {
    { "check_flag", Q1.DONE }, { "jump_if_true", "after" },
    { "check_flag", Q1.STARTED }, { "jump_if_false", "idle" },
    { "check_item", MAP_ITEM }, { "jump_if_false", "idle" },
    { "show_text", "That SECRET MAP!\nFor my research,\vwould you part\vwith it?\fI'll reward you\nwith a rare TM." },
    { "choice", { "GIVE IT", "NOT YET" } },
    { "jump_if_false", "notyet" },
    { "take_item", MAP_ITEM },
    { "give_item", "TM_PSYCHIC_M" },
    { "set_flag", Q1.DONE }, { "set_flag", Q1.SCI },
    { "show_text", "Astounding! This\nfills a gap in my\vwork. Thank you!" },
    { "jump", "end" },
    { "label", "notyet" }, { "show_text", "Take your time to\ndecide." }, { "jump", "end" },
    { "label", "idle" }, { "show_text", "I chart the wild\ncorners of KANTO." }, { "jump", "end" },
    { "label", "after" },
    { "check_flag", Q1.SCI }, { "jump_if_true", "after_sci" },
    { "show_text", "You gave the map\naway... a loss for\vscience." }, { "jump", "end" },
    { "label", "after_sci" },
    { "show_text", "My research soars\nthanks to that map!" },
  }
end

local function q1_gambler()
  return {
    { "check_flag", Q1.DONE }, { "jump_if_true", "after" },
    { "check_flag", Q1.STARTED }, { "jump_if_false", "idle" },
    { "check_item", MAP_ITEM }, { "jump_if_false", "idle" },
    { "show_text", "Ooh, a SECRET MAP!\nTreasure, I'd wager.\fSell it to me? I'll\npay handsomely!" },
    { "choice", { "SELL IT", "NO DEAL" } },
    { "jump_if_false", "nodeal" },
    { "take_item", MAP_ITEM },
    { "give_item", "NUGGET" },
    { "give_money", 3000 },
    { "set_flag", Q1.DONE }, { "set_flag", Q1.FOR },
    { "show_text", "Hehe! X marks the\nspot. Pleasure\vdoing business!" },
    { "jump", "end" },
    { "label", "nodeal" }, { "show_text", "Cold feet? My\noffer stands." }, { "jump", "end" },
    { "label", "idle" }, { "show_text", "I bet on treasure,\nnot on POKéMON." }, { "jump", "end" },
    { "label", "after" },
    { "check_flag", Q1.FOR }, { "jump_if_true", "after_for" },
    { "show_text", "You handed my\ntreasure to that\vegghead? Bah!" }, { "jump", "end" },
    { "label", "after_for" },
    { "show_text", "That map paid off\nbig. We should deal\vagain!" },
  }
end

-- ------- Quest 2: The Poacher's Bargain ----------------------------
local Q2 = { STARTED = "MOD_BQ2_STARTED", DONE = "MOD_BQ2_DONE",
             CONS = "MOD_BQ2_END_CONS", PROFIT = "MOD_BQ2_END_PROFIT" }

local function q2_researcher()
  return {
    { "check_flag", Q2.DONE }, { "jump_if_true", "after" },
    { "check_flag", Q2.STARTED }, { "jump_if_true", "pending" },
    { "show_text", "A poacher stole a\nrare AMBER SHARD!\fHe's hiding in\nFUCHSIA. Get it\vback for me?" },
    { "choice", { "I WILL", "NO" } },
    { "jump_if_false", "refuse" },
    { "set_flag", Q2.STARTED },
    { "show_text", "Bless you! Bring\nit here safely." },
    { "jump", "end" },
    { "label", "pending" },
    { "check_item", SHARD_ITEM }, { "jump_if_false", "remind" },
    { "take_item", SHARD_ITEM },
    { "give_item", "OLD_AMBER" },
    { "set_flag", Q2.DONE }, { "set_flag", Q2.CONS },
    { "emote", "player", "happy", 45 },
    { "show_text", "You saved it! Take\nthis OLD AMBER as\vthanks -- preserve\nthe past!" },
    { "jump", "end" },
    { "label", "remind" }, { "show_text", "The poacher in\nFUCHSIA still has\vthe AMBER SHARD." }, { "jump", "end" },
    { "label", "refuse" }, { "show_text", "Oh... please\nreconsider." }, { "jump", "end" },
    { "label", "after" },
    { "check_flag", Q2.CONS }, { "jump_if_true", "after_cons" },
    { "show_text", "You let the poacher\nbuy you off? That\vshard is lost now..." }, { "jump", "end" },
    { "label", "after_cons" },
    { "show_text", "The AMBER SHARD is\nsafe in my lab.\vThank you!" },
  }
end

local function q2_poacher()
  return {
    { "check_flag", Q2.DONE }, { "jump_if_true", "after" },
    { "check_flag", Q2.STARTED }, { "jump_if_false", "idle" },
    { "show_text", "Heh, the egghead\nsent you for the\vAMBER SHARD?\fTell you what --\ntake it, OR take a\vbribe and forget\nme." },
    { "choice", { "TAKE SHARD", "TAKE BRIBE" } },
    { "jump_if_false", "bribe" },
    { "give_item", SHARD_ITEM, 1, true },
    { "show_text", "Tch. Fine. Run it\nback to the lab,\vhero." },
    { "jump", "end" },
    { "label", "bribe" },
    { "give_item", "NUGGET" },
    { "give_money", 4000 },
    { "set_flag", Q2.DONE }, { "set_flag", Q2.PROFIT },
    { "show_text", "Smart kid. Not a\nword, now. Beat it!" },
    { "jump", "end" },
    { "label", "idle" }, { "show_text", "What? I'm just\nfishin', honest." }, { "jump", "end" },
    { "label", "after" },
    { "check_flag", Q2.PROFIT }, { "jump_if_true", "after_profit" },
    { "show_text", "You ratted me out.\nGet lost." }, { "jump", "end" },
    { "label", "after_profit" },
    { "show_text", "Pleasure doin'\nshady business!" },
  }
end

-- ------- Quest 3: The Silph Whistleblower (multi-step) -------------
-- A three-town investigation: gather two clues, then choose to expose the
-- wrongdoing or sell your silence. Clues are tracked with flags only.
local Q3 = { STARTED = "MOD_BQ3_STARTED", C1 = "MOD_BQ3_CLUE1", C2 = "MOD_BQ3_CLUE2",
             DONE = "MOD_BQ3_DONE", HERO = "MOD_BQ3_END_HERO", GREED = "MOD_BQ3_END_GREED" }

local function q3_gentleman()
  return {
    { "check_flag", Q3.DONE }, { "jump_if_true", "after" },
    { "check_flag", Q3.STARTED }, { "jump_if_true", "pending" },
    { "show_text", "Psst... I work at\nSILPH. Something's\vwrong in there.\fGather proof for\nme? Two people\vcould help." },
    { "choice", { "I'LL HELP", "NO" } },
    { "jump_if_false", "refuse" },
    { "set_flag", Q3.STARTED },
    { "show_text", "A retiree in\nCELADON, a dock\vworker in\vVERMILION.\fBe discreet!" },
    { "jump", "end" },
    { "label", "pending" },
    { "check_flag", Q3.C1 }, { "jump_if_false", "remind" },
    { "check_flag", Q3.C2 }, { "jump_if_false", "remind" },
    { "show_text", "You have it all?\nThen it's your\vcall...\fExpose SILPH, or\nsell them their\vsilence?" },
    { "choice", { "EXPOSE THEM", "SELL SILENCE" } },
    { "jump_if_false", "greed" },
    { "set_flag", Q3.DONE }, { "set_flag", Q3.HERO },
    { "give_item", "TM_TOXIC" },
    { "show_text", "You brave soul!\nTake this -- and\vwatch your back." },
    { "jump", "end" },
    { "label", "greed" },
    { "set_flag", Q3.DONE }, { "set_flag", Q3.GREED },
    { "give_item", "NUGGET" }, { "give_money", 6000 },
    { "show_text", "Heh. We both\nretire rich. Not\va word, now." },
    { "jump", "end" },
    { "label", "remind" },
    { "show_text", "The CELADON retiree\nand the VERMILION\vdock worker. Find\nthem both." },
    { "jump", "end" },
    { "label", "refuse" }, { "show_text", "I understand. It\nis dangerous." }, { "jump", "end" },
    { "label", "after" },
    { "check_flag", Q3.HERO }, { "jump_if_true", "after_hero" },
    { "show_text", "Our little secret\nkeeps us both\vcomfortable, hm?" }, { "jump", "end" },
    { "label", "after_hero" },
    { "show_text", "The truth is out.\nTerrifying, but\vright. Thank you." },
  }
end

local function q3_retiree()
  return {
    { "check_flag", Q3.STARTED }, { "jump_if_false", "idle" },
    { "check_flag", Q3.C1 }, { "jump_if_true", "told" },
    { "show_text", "SILPH? I gave them\n30 years.\fThey hid crates in\nthe basement. That\vis your proof." },
    { "set_flag", Q3.C1 },
    { "jump", "end" },
    { "label", "told" }, { "show_text", "Tell no one I\nspoke, you hear?" }, { "jump", "end" },
    { "label", "idle" }, { "show_text", "Retirement is dull,\nbut safe." },
  }
end

local function q3_dockworker()
  return {
    { "check_flag", Q3.STARTED }, { "jump_if_false", "idle" },
    { "check_flag", Q3.C2 }, { "jump_if_true", "told" },
    { "show_text", "SILPH crates? I\nload 'em.\fHeavy and unmarked,\nall of 'em. Fishy.\vThere's your proof." },
    { "set_flag", Q3.C2 },
    { "jump", "end" },
    { "label", "told" }, { "show_text", "I said what I saw.\nLeave me out of it." }, { "jump", "end" },
    { "label", "idle" }, { "show_text", "Long day at the\ndocks, pal." },
  }
end

-- ------- Quest 4: Two Brothers (a lighter choice) ------------------
local NOTE_ITEM = "BQ_CHALLENGE_NOTE"
local Q4 = { STARTED = "MOD_BQ4_STARTED", DONE = "MOD_BQ4_DONE",
             SIDE3 = "MOD_BQ4_SIDE3", SIDE2 = "MOD_BQ4_SIDE2" }

local function q4_gramps2()
  return {
    { "check_flag", Q4.DONE }, { "jump_if_true", "after" },
    { "check_flag", Q4.STARTED }, { "jump_if_true", "pending" },
    { "show_text", "My fool brother\nswears HE caught\vthe bigger MAGIKARP!\fTake him this NOTE\nand settle it!" },
    { "give_item", NOTE_ITEM, 1, true },
    { "set_flag", Q4.STARTED },
    { "jump", "end" },
    { "label", "pending" },
    { "show_text", "Has that stubborn\nbrother read my\vNOTE yet?" },
    { "jump", "end" },
    { "label", "after" },
    { "check_flag", Q4.SIDE2 }, { "jump_if_true", "after_win" },
    { "show_text", "You sided with HIM?!\nSome judge YOU are!" }, { "jump", "end" },
    { "label", "after_win" },
    { "show_text", "HA! Told you I was\nright! Good on ya!" },
  }
end

local function q4_gramps3()
  return {
    { "check_flag", Q4.DONE }, { "jump_if_true", "idle" },
    { "check_flag", Q4.STARTED }, { "jump_if_false", "idle" },
    { "check_item", NOTE_ITEM }, { "jump_if_false", "idle" },
    { "show_text", "My brother's NOTE?\nBah. So, judge --\vwho caught the\vbigger MAGIKARP?" },
    { "choice", { "YOU DID", "YOUR BROTHER" } },
    { "jump_if_false", "sidebro" },
    { "take_item", NOTE_ITEM },
    { "give_item", "RARE_CANDY" },
    { "set_flag", Q4.DONE }, { "set_flag", Q4.SIDE3 },
    { "show_text", "Finally, sense!\nHere, for your\vfine judgment!" },
    { "jump", "end" },
    { "label", "sidebro" },
    { "take_item", NOTE_ITEM },
    { "give_item", "MAX_ELIXER" },
    { "set_flag", Q4.DONE }, { "set_flag", Q4.SIDE2 },
    { "show_text", "Hmph! Fine, HE\nwins. Take this and\vgo, then." },
    { "jump", "end" },
    { "label", "idle" }, { "show_text", "Fishin' beats\narguin', most days." },
  }
end

return function(mod)
  mod.content.items:register(MAP_ITEM, { id = MAP_ITEM, name = "SECRET MAP", price = 0, keyItem = true, tossable = false })
  mod.content.items:register(SHARD_ITEM, { id = SHARD_ITEM, name = "AMBER SHARD", price = 0, keyItem = true, tossable = false })
  mod.content.items:register(NOTE_ITEM, { id = NOTE_ITEM, name = "NOTE", price = 0, keyItem = true, tossable = false })

  -- collect talk per map so multiple quest NPCs on one town compose
  local byMap = {}
  local function put(map, npc, talk)
    byMap[map] = byMap[map] or {}
    byMap[map][npc] = talk
  end

  put("VERMILION_CITY", "TEXT_VERMILIONCITY_SAILOR2", q1_sailor())
  put("SAFFRON_CITY", "TEXT_SAFFRONCITY_SCIENTIST", q1_scientist())
  put("FUCHSIA_CITY", "TEXT_FUCHSIACITY_GAMBLER", q1_gambler())
  put("CERULEAN_CITY", "TEXT_CERULEANCITY_SUPER_NERD2", q2_researcher())
  put("FUCHSIA_CITY", "TEXT_FUCHSIACITY_ERIK", q2_poacher())

  put("SAFFRON_CITY", "TEXT_SAFFRONCITY_GENTLEMAN", q3_gentleman())
  put("CELADON_CITY", "TEXT_CELADONCITY_GRAMPS1", q3_retiree())
  put("VERMILION_CITY", "TEXT_VERMILIONCITY_GAMBLER1", q3_dockworker())

  put("CELADON_CITY", "TEXT_CELADONCITY_GRAMPS2", q4_gramps2())
  put("CELADON_CITY", "TEXT_CELADONCITY_GRAMPS3", q4_gramps3())

  for map, talk in pairs(byMap) do
    mod.content.map_scripts:register(map, { talk = talk })
  end
end
