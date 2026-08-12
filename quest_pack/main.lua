-- quest_pack
-- ------------------------------------------------------------------
-- Every quest in one mod: the Glow Shard, four Town Quests, and five
-- Branching Quests (with multiple endings), plus a QUESTS entry in the
-- START menu that tracks them all. Flags and item ids are unchanged from
-- the older separate mods, so existing saves carry over.
--
-- All quest content is map-script data (no engine files edited). The tracker
-- reads the quests' own save flags, so it always reflects your progress.

-- ================= GLOW SHARD ====================================
local GLOW_SHARD = "QUEST_GLOW_SHARD_ITEM"
local GLOW_STARTED, GLOW_TAKEN, GLOW_DONE =
  "MOD_QUEST_GLOW_SHARD_STARTED", "MOD_QUEST_GLOW_SHARD_TAKEN", "MOD_QUEST_GLOW_SHARD_DONE"

local function glowGiver()
  return {
    { "check_flag", GLOW_DONE }, { "jump_if_true", "after" },
    { "check_flag", GLOW_STARTED }, { "jump_if_true", "pending" },
    { "show_text", "I collect rare\nminerals!\fWord is a glowing\nrock turned up in\vLAVENDER TOWN.\fBring it to me?" },
    { "choice", { "SURE", "NO THANKS" } },
    { "jump_if_false", "refused" },
    { "set_flag", GLOW_STARTED },
    { "show_text", "Excellent! Ask\naround LAVENDER\vTOWN. I'll reward\vyou well!" },
    { "jump", "end" },
    { "label", "pending" },
    { "check_item", GLOW_SHARD }, { "jump_if_false", "remind" },
    { "take_item", GLOW_SHARD },
    { "give_item", "RARE_CANDY" },
    { "set_flag", GLOW_DONE },
    { "emote", "player", "happy", 45 },
    { "show_text", "The GLOW SHARD!\nMagnificent!\fHere, this is the\nleast I can do." },
    { "jump", "end" },
    { "label", "remind" }, { "show_text", "Any luck? The\nGLOW SHARD, in\vLAVENDER TOWN!" }, { "jump", "end" },
    { "label", "refused" }, { "show_text", "No? Come back if\nyou change your\vmind." }, { "jump", "end" },
    { "label", "after" }, { "show_text", "The GLOW SHARD is\nthe pride of my\vcollection now!" },
  }
end
local function glowHolder()
  return {
    { "check_flag", GLOW_STARTED }, { "jump_if_false", "idle" },
    { "check_flag", GLOW_TAKEN }, { "jump_if_true", "idle" },
    { "show_text", "This glowing rock?\nFound it by the\vTOWER. Gives me the\vchills. Take it!" },
    { "give_item", GLOW_SHARD, 1, false },
    { "set_flag", GLOW_TAKEN },
    { "show_text", "{PLAYER} got the\nGLOW SHARD!" },
    { "jump", "end" },
    { "label", "idle" }, { "show_text", "This town is spooky\nafter dark, you\vknow." },
  }
end

-- ================= TOWN QUESTS ===================================
local TOWN_QUESTS = {
  { id = "keepsake", item = "TQ_KEEPSAKE", itemName = "KEEPSAKE", reward = "POKE_DOLL",
    giver = { map = "PALLET_TOWN", npc = "TEXT_PALLETTOWN_GIRL" },
    holder = { map = "VIRIDIAN_CITY", npc = "TEXT_VIRIDIANCITY_GIRL" },
    offer = "Oh no... I lost my\nKEEPSAKE up in\vVIRIDIAN CITY.\fCould you look\nfor it?",
    accept = "Thank you so\nmuch! It means\vthe world to me.",
    remind = "Any sign of my\nKEEPSAKE in\vVIRIDIAN CITY?",
    reward_line = "My KEEPSAKE!\nYou found it!\fPlease, take this\nas thanks!",
    refuse = "Oh... okay. Maybe\nsomeone else.",
    after = "Thank you again\nfor my KEEPSAKE!",
    holder_give = "Hm? Someone\ndropped this.\fA KEEPSAKE -- take\nit, it's not mine.",
    holder_idle = "Lovely breeze in\nVIRIDIAN today." },
  { id = "letter", item = "TQ_LETTER", itemName = "LETTER", reward = "RARE_CANDY",
    giver = { map = "CERULEAN_CITY", npc = "TEXT_CERULEANCITY_COOLTRAINER_F1" },
    holder = { map = "VERMILION_CITY", npc = "TEXT_VERMILIONCITY_SAILOR1" },
    offer = "My pen pal, a\nSAILOR in\vVERMILION, has a\vLETTER for me.\fFetch it?",
    accept = "You're a dear!\nHe'll be by the\vdocks.",
    remind = "Has that SAILOR\nin VERMILION got\vmy LETTER?",
    reward_line = "My LETTER, at\nlast! Here, a\vsweet reward!",
    refuse = "No? The mail can\nwait, I suppose.",
    after = "His LETTER made\nmy whole week!",
    holder_give = "You're here for\nthe LETTER?\fAye, take it to\nCERULEAN for me.",
    holder_idle = "The sea's calm\ntoday, matey." },
  { id = "herb", item = "TQ_HERB", itemName = "RARE HERB", reward = "MAX_ETHER",
    giver = { map = "CELADON_CITY", npc = "TEXT_CELADONCITY_GIRL" },
    holder = { map = "FUCHSIA_CITY", npc = "TEXT_FUCHSIACITY_YOUNGSTER2" },
    offer = "A kid in FUCHSIA\nfound a RARE HERB\vmy gran needs.\fCould you get it?",
    accept = "Bless you! Gran\nwill be so glad.",
    remind = "That RARE HERB in\nFUCHSIA -- any\vluck?",
    reward_line = "The RARE HERB!\nGran thanks you.\fTake this, please!",
    refuse = "Oh... get well\nsoon, gran.",
    after = "Gran's feeling\nmuch better now!",
    holder_give = "This weird plant?\nI don't want it.\fA RARE HERB -- all\nyours!",
    holder_idle = "SAFARI ZONE's\nthis way, ya know." },
  { id = "charm", item = "TQ_CHARM", itemName = "LUCK CHARM", reward = "NUGGET",
    giver = { map = "LAVENDER_TOWN", npc = "TEXT_LAVENDERTOWN_LITTLE_GIRL" },
    holder = { map = "PEWTER_CITY", npc = "TEXT_PEWTERCITY_YOUNGSTER" },
    offer = "A boy in PEWTER\nhas my LUCK CHARM.\fThis town scares\nme... please help?",
    accept = "Thank you! I'll\nfeel safe with it\vback.",
    remind = "Did you find my\nLUCK CHARM in\vPEWTER?",
    reward_line = "My LUCK CHARM!\nNow the ghosts\vwon't get me!\fHere, for you!",
    refuse = "Oh... it's so\nspooky here.",
    after = "I sleep soundly\nnow. Thank you!",
    holder_give = "Found this shiny\nthing by the gym.\fA LUCK CHARM --\ntake it!",
    holder_idle = "BROCK is tough,\nlet me tell you." },
}
local function tqFlag(id, suffix) return "MOD_TQ_" .. id .. "_" .. suffix end
local function tqGiver(q)
  local STARTED, DONE = tqFlag(q.id, "STARTED"), tqFlag(q.id, "DONE")
  return {
    { "check_flag", DONE }, { "jump_if_true", "after" },
    { "check_flag", STARTED }, { "jump_if_true", "pending" },
    { "show_text", q.offer },
    { "choice", { "SURE", "NO" } },
    { "jump_if_false", "refuse" },
    { "set_flag", STARTED },
    { "show_text", q.accept },
    { "jump", "end" },
    { "label", "pending" },
    { "check_item", q.item }, { "jump_if_false", "remind" },
    { "take_item", q.item },
    { "give_item", q.reward },
    { "set_flag", DONE },
    { "emote", "player", "happy", 45 },
    { "show_text", q.reward_line },
    { "jump", "end" },
    { "label", "remind" }, { "show_text", q.remind }, { "jump", "end" },
    { "label", "refuse" }, { "show_text", q.refuse }, { "jump", "end" },
    { "label", "after" }, { "show_text", q.after },
  }
end
local function tqHolder(q)
  local STARTED, TAKEN = tqFlag(q.id, "STARTED"), tqFlag(q.id, "TAKEN")
  return {
    { "check_flag", STARTED }, { "jump_if_false", "idle" },
    { "check_flag", TAKEN }, { "jump_if_true", "idle" },
    { "show_text", q.holder_give },
    { "give_item", q.item, 1, true },
    { "set_flag", TAKEN },
    { "jump", "end" },
    { "label", "idle" }, { "show_text", q.holder_idle },
  }
end

-- ================= BRANCHING QUESTS ==============================
local MAP_ITEM, SHARD_ITEM, NOTE_ITEM, GUITAR_ITEM = "BQ_SECRET_MAP", "BQ_AMBER_SHARD", "BQ_CHALLENGE_NOTE", "BQ_GUITAR"
local Q1 = { STARTED = "MOD_BQ1_STARTED", DONE = "MOD_BQ1_DONE", SCI = "MOD_BQ1_END_SCI", FOR = "MOD_BQ1_END_FOR" }
local Q2 = { STARTED = "MOD_BQ2_STARTED", DONE = "MOD_BQ2_DONE", CONS = "MOD_BQ2_END_CONS", PROFIT = "MOD_BQ2_END_PROFIT" }
local Q3 = { STARTED = "MOD_BQ3_STARTED", C1 = "MOD_BQ3_CLUE1", C2 = "MOD_BQ3_CLUE2", DONE = "MOD_BQ3_DONE", HERO = "MOD_BQ3_END_HERO", GREED = "MOD_BQ3_END_GREED" }
local Q4 = { STARTED = "MOD_BQ4_STARTED", DONE = "MOD_BQ4_DONE", SIDE3 = "MOD_BQ4_SIDE3", SIDE2 = "MOD_BQ4_SIDE2" }
local Q5 = { STARTED = "MOD_BQ5_STARTED", DONE = "MOD_BQ5_DONE", MUSIC = "MOD_BQ5_END_MUSIC", SELL = "MOD_BQ5_END_SELL" }

local function q1_sailor() return {
  { "check_flag", Q1.DONE }, { "jump_if_true", "resolved" },
  { "check_flag", Q1.STARTED }, { "jump_if_true", "waiting" },
  { "show_text", "Arr! I fished up\nthis SECRET MAP.\fTwo folk want it:\na SCIENTIST in\vSAFFRON, a GAMBLER\vin FUCHSIA.\fYou decide who\ngets it." },
  { "give_item", MAP_ITEM, 1, true }, { "set_flag", Q1.STARTED }, { "jump", "end" },
  { "label", "waiting" }, { "show_text", "Still holdin' that\nmap? SAFFRON's\vSCIENTIST or\vFUCHSIA's GAMBLER.\fYour call, sailor." }, { "jump", "end" },
  { "label", "resolved" }, { "check_flag", Q1.SCI }, { "jump_if_true", "res_sci" },
  { "show_text", "Sold it to the\nGAMBLER, eh? Gold's\vgold, I s'pose." }, { "jump", "end" },
  { "label", "res_sci" }, { "show_text", "Gave it to the\nSCIENTIST. Knowledge\vover coin -- good\non ya." },
} end
local function q1_scientist() return {
  { "check_flag", Q1.DONE }, { "jump_if_true", "after" },
  { "check_flag", Q1.STARTED }, { "jump_if_false", "idle" },
  { "check_item", MAP_ITEM }, { "jump_if_false", "idle" },
  { "show_text", "That SECRET MAP!\nFor my research,\vwould you part\vwith it?\fI'll reward you\nwith a rare TM." },
  { "choice", { "GIVE IT", "NOT YET" } }, { "jump_if_false", "notyet" },
  { "take_item", MAP_ITEM }, { "give_item", "TM_PSYCHIC_M" },
  { "set_flag", Q1.DONE }, { "set_flag", Q1.SCI },
  { "show_text", "Astounding! This\nfills a gap in my\vwork. Thank you!" }, { "jump", "end" },
  { "label", "notyet" }, { "show_text", "Take your time to\ndecide." }, { "jump", "end" },
  { "label", "idle" }, { "show_text", "I chart the wild\ncorners of KANTO." }, { "jump", "end" },
  { "label", "after" }, { "check_flag", Q1.SCI }, { "jump_if_true", "after_sci" },
  { "show_text", "You gave the map\naway... a loss for\vscience." }, { "jump", "end" },
  { "label", "after_sci" }, { "show_text", "My research soars\nthanks to that map!" },
} end
local function q1_gambler() return {
  { "check_flag", Q1.DONE }, { "jump_if_true", "after" },
  { "check_flag", Q1.STARTED }, { "jump_if_false", "idle" },
  { "check_item", MAP_ITEM }, { "jump_if_false", "idle" },
  { "show_text", "Ooh, a SECRET MAP!\nTreasure, I'd wager.\fSell it to me? I'll\npay handsomely!" },
  { "choice", { "SELL IT", "NO DEAL" } }, { "jump_if_false", "nodeal" },
  { "take_item", MAP_ITEM }, { "give_item", "NUGGET" }, { "give_money", 3000 },
  { "set_flag", Q1.DONE }, { "set_flag", Q1.FOR },
  { "show_text", "Hehe! X marks the\nspot. Pleasure\vdoing business!" }, { "jump", "end" },
  { "label", "nodeal" }, { "show_text", "Cold feet? My\noffer stands." }, { "jump", "end" },
  { "label", "idle" }, { "show_text", "I bet on treasure,\nnot on POKéMON." }, { "jump", "end" },
  { "label", "after" }, { "check_flag", Q1.FOR }, { "jump_if_true", "after_for" },
  { "show_text", "You handed my\ntreasure to that\vegghead? Bah!" }, { "jump", "end" },
  { "label", "after_for" }, { "show_text", "That map paid off\nbig. We should deal\vagain!" },
} end
local function q2_researcher() return {
  { "check_flag", Q2.DONE }, { "jump_if_true", "after" },
  { "check_flag", Q2.STARTED }, { "jump_if_true", "pending" },
  { "show_text", "A poacher stole a\nrare AMBER SHARD!\fHe's hiding in\nFUCHSIA. Get it\vback for me?" },
  { "choice", { "I WILL", "NO" } }, { "jump_if_false", "refuse" },
  { "set_flag", Q2.STARTED }, { "show_text", "Bless you! Bring\nit here safely." }, { "jump", "end" },
  { "label", "pending" }, { "check_item", SHARD_ITEM }, { "jump_if_false", "remind" },
  { "take_item", SHARD_ITEM }, { "give_item", "OLD_AMBER" },
  { "set_flag", Q2.DONE }, { "set_flag", Q2.CONS }, { "emote", "player", "happy", 45 },
  { "show_text", "You saved it! Take\nthis OLD AMBER as\vthanks -- preserve\nthe past!" }, { "jump", "end" },
  { "label", "remind" }, { "show_text", "The poacher in\nFUCHSIA still has\vthe AMBER SHARD." }, { "jump", "end" },
  { "label", "refuse" }, { "show_text", "Oh... please\nreconsider." }, { "jump", "end" },
  { "label", "after" }, { "check_flag", Q2.CONS }, { "jump_if_true", "after_cons" },
  { "show_text", "You let the poacher\nbuy you off? That\vshard is lost now..." }, { "jump", "end" },
  { "label", "after_cons" }, { "show_text", "The AMBER SHARD is\nsafe in my lab.\vThank you!" },
} end
local function q2_poacher() return {
  { "check_flag", Q2.DONE }, { "jump_if_true", "after" },
  { "check_flag", Q2.STARTED }, { "jump_if_false", "idle" },
  { "show_text", "Heh, the egghead\nsent you for the\vAMBER SHARD?\fTell you what --\ntake it, OR take a\vbribe and forget\nme." },
  { "choice", { "TAKE SHARD", "TAKE BRIBE" } }, { "jump_if_false", "bribe" },
  { "give_item", SHARD_ITEM, 1, true }, { "show_text", "Tch. Fine. Run it\nback to the lab,\vhero." }, { "jump", "end" },
  { "label", "bribe" }, { "give_item", "NUGGET" }, { "give_money", 4000 },
  { "set_flag", Q2.DONE }, { "set_flag", Q2.PROFIT },
  { "show_text", "Smart kid. Not a\nword, now. Beat it!" }, { "jump", "end" },
  { "label", "idle" }, { "show_text", "What? I'm just\nfishin', honest." }, { "jump", "end" },
  { "label", "after" }, { "check_flag", Q2.PROFIT }, { "jump_if_true", "after_profit" },
  { "show_text", "You ratted me out.\nGet lost." }, { "jump", "end" },
  { "label", "after_profit" }, { "show_text", "Pleasure doin'\nshady business!" },
} end
local function q3_gentleman() return {
  { "check_flag", Q3.DONE }, { "jump_if_true", "after" },
  { "check_flag", Q3.STARTED }, { "jump_if_true", "pending" },
  { "show_text", "Psst... I work at\nSILPH. Something's\vwrong in there.\fGather proof for\nme? Two people\vcould help." },
  { "choice", { "I'LL HELP", "NO" } }, { "jump_if_false", "refuse" },
  { "set_flag", Q3.STARTED }, { "show_text", "A retiree in\nCELADON, a dock\vworker in\vVERMILION.\fBe discreet!" }, { "jump", "end" },
  { "label", "pending" }, { "check_flag", Q3.C1 }, { "jump_if_false", "remind" },
  { "check_flag", Q3.C2 }, { "jump_if_false", "remind" },
  { "show_text", "You have it all?\nThen it's your\vcall...\fExpose SILPH, or\nsell them their\vsilence?" },
  { "choice", { "EXPOSE THEM", "SELL SILENCE" } }, { "jump_if_false", "greed" },
  { "set_flag", Q3.DONE }, { "set_flag", Q3.HERO }, { "give_item", "TM_TOXIC" },
  { "show_text", "You brave soul!\nTake this -- and\vwatch your back." }, { "jump", "end" },
  { "label", "greed" }, { "set_flag", Q3.DONE }, { "set_flag", Q3.GREED },
  { "give_item", "NUGGET" }, { "give_money", 6000 },
  { "show_text", "Heh. We both\nretire rich. Not\va word, now." }, { "jump", "end" },
  { "label", "remind" }, { "show_text", "The CELADON retiree\nand the VERMILION\vdock worker. Find\nthem both." }, { "jump", "end" },
  { "label", "refuse" }, { "show_text", "I understand. It\nis dangerous." }, { "jump", "end" },
  { "label", "after" }, { "check_flag", Q3.HERO }, { "jump_if_true", "after_hero" },
  { "show_text", "Our little secret\nkeeps us both\vcomfortable, hm?" }, { "jump", "end" },
  { "label", "after_hero" }, { "show_text", "The truth is out.\nTerrifying, but\vright. Thank you." },
} end
local function q3_retiree() return {
  { "check_flag", Q3.STARTED }, { "jump_if_false", "idle" },
  { "check_flag", Q3.C1 }, { "jump_if_true", "told" },
  { "show_text", "SILPH? I gave them\n30 years.\fThey hid crates in\nthe basement. That\vis your proof." },
  { "set_flag", Q3.C1 }, { "jump", "end" },
  { "label", "told" }, { "show_text", "Tell no one I\nspoke, you hear?" }, { "jump", "end" },
  { "label", "idle" }, { "show_text", "Retirement is dull,\nbut safe." },
} end
local function q3_dockworker() return {
  { "check_flag", Q3.STARTED }, { "jump_if_false", "idle" },
  { "check_flag", Q3.C2 }, { "jump_if_true", "told" },
  { "show_text", "SILPH crates? I\nload 'em.\fHeavy and unmarked,\nall of 'em. Fishy.\vThere's your proof." },
  { "set_flag", Q3.C2 }, { "jump", "end" },
  { "label", "told" }, { "show_text", "I said what I saw.\nLeave me out of it." }, { "jump", "end" },
  { "label", "idle" }, { "show_text", "Long day at the\ndocks, pal." },
} end
local function q4_gramps2() return {
  { "check_flag", Q4.DONE }, { "jump_if_true", "after" },
  { "check_flag", Q4.STARTED }, { "jump_if_true", "pending" },
  { "show_text", "My fool brother\nswears HE caught\vthe bigger MAGIKARP!\fTake him this NOTE\nand settle it!" },
  { "give_item", NOTE_ITEM, 1, true }, { "set_flag", Q4.STARTED }, { "jump", "end" },
  { "label", "pending" }, { "show_text", "Has that stubborn\nbrother read my\vNOTE yet?" }, { "jump", "end" },
  { "label", "after" }, { "check_flag", Q4.SIDE2 }, { "jump_if_true", "after_win" },
  { "show_text", "You sided with HIM?!\nSome judge YOU are!" }, { "jump", "end" },
  { "label", "after_win" }, { "show_text", "HA! Told you I was\nright! Good on ya!" },
} end
local function q4_gramps3() return {
  { "check_flag", Q4.DONE }, { "jump_if_true", "idle" },
  { "check_flag", Q4.STARTED }, { "jump_if_false", "idle" },
  { "check_item", NOTE_ITEM }, { "jump_if_false", "idle" },
  { "show_text", "My brother's NOTE?\nBah. So, judge --\vwho caught the\vbigger MAGIKARP?" },
  { "choice", { "YOU DID", "YOUR BROTHER" } }, { "jump_if_false", "sidebro" },
  { "take_item", NOTE_ITEM }, { "give_item", "RARE_CANDY" },
  { "set_flag", Q4.DONE }, { "set_flag", Q4.SIDE3 },
  { "show_text", "Finally, sense!\nHere, for your\vfine judgment!" }, { "jump", "end" },
  { "label", "sidebro" }, { "take_item", NOTE_ITEM }, { "give_item", "MAX_ELIXER" },
  { "set_flag", Q4.DONE }, { "set_flag", Q4.SIDE2 },
  { "show_text", "Hmph! Fine, HE\nwins. Take this and\vgo, then." }, { "jump", "end" },
  { "label", "idle" }, { "show_text", "Fishin' beats\narguin', most days." },
} end
local function q5_rocker() return {
  { "check_flag", Q5.DONE }, { "jump_if_true", "after" },
  { "check_flag", Q5.STARTED }, { "jump_if_true", "pending" },
  { "show_text", "Some punk swiped\nmy GUITAR! It's in\vVIRIDIAN.\fGet it back and\nI'll make you a\vSTAR!" },
  { "choice", { "ROCK ON", "NAH" } }, { "jump_if_false", "refuse" },
  { "set_flag", Q5.STARTED }, { "show_text", "You rock! Find\nthat thief in\vVIRIDIAN CITY." }, { "jump", "end" },
  { "label", "pending" }, { "check_item", GUITAR_ITEM }, { "jump_if_false", "remind" },
  { "take_item", GUITAR_ITEM }, { "give_item", "TM_SWORDS_DANCE" },
  { "set_flag", Q5.DONE }, { "set_flag", Q5.MUSIC }, { "emote", "player", "happy", 45 },
  { "show_text", "My axe! Learn this\nmove, you earned\vit, STAR!" }, { "jump", "end" },
  { "label", "remind" }, { "show_text", "That thief in\nVIRIDIAN still has\vmy GUITAR!" }, { "jump", "end" },
  { "label", "refuse" }, { "show_text", "Aw, don't leave me\nhangin'..." }, { "jump", "end" },
  { "label", "after" }, { "check_flag", Q5.MUSIC }, { "jump_if_true", "after_music" },
  { "show_text", "You SOLD my GUITAR?\nThat's ice cold,\vman..." }, { "jump", "end" },
  { "label", "after_music" }, { "show_text", "We gotta jam\nsometime, STAR!" },
} end
local function q5_thief() return {
  { "check_flag", Q5.DONE }, { "jump_if_true", "idle" },
  { "check_flag", Q5.STARTED }, { "jump_if_false", "idle" },
  { "check_item", GUITAR_ITEM }, { "jump_if_true", "idle" },
  { "show_text", "Heh, this GUITAR?\nThe ROCKER wants\vit back?\fTake it to him...\nOR help me sell it.\vBig cut for you." },
  { "choice", { "TAKE GUITAR", "SELL IT" } }, { "jump_if_false", "sell" },
  { "give_item", GUITAR_ITEM, 1, true }, { "show_text", "Tch. Fine. Run it\nback, hero." }, { "jump", "end" },
  { "label", "sell" }, { "give_item", "NUGGET" }, { "give_money", 4000 },
  { "set_flag", Q5.DONE }, { "set_flag", Q5.SELL },
  { "show_text", "Smart. Easy money,\nno questions asked." }, { "jump", "end" },
  { "label", "idle" }, { "show_text", "Nothin' to see\nhere. Move along." },
} end

-- ================= MOVE TUTORS ==================================
-- Spawned masters out on quiet routes. Beat their team once and they teach your
-- trainer a signature move (a TM you cannot craft), then move on. Learned once.
local TUTORS = {
  { key = "goro", map = "ROUTE_22", sprite = "SPRITE_HIKER", text = "TEXT_MOVE_TUTOR_GORO",
    trainer = "OPP_TUTOR_GORO", name = "MASTER GORO", tm = "TM_SUBMISSION",
    party = { { level = 24, species = "PRIMEAPE" }, { level = 26, species = "MACHOKE" } },
    intro = "I am MASTER GORO.\nBest my POKeMON and\vI will teach you\vthe art of SUBMISSION!",
    teach = "Well fought! The\nway of SUBMISSION\vis yours now.",
    after = "Keep body and\nspirit strong!" },
  { key = "oracle", map = "ROUTE_13", sprite = "SPRITE_GAMBLER", text = "TEXT_MOVE_TUTOR_ORACLE",
    trainer = "OPP_TUTOR_ORACLE", name = "SAGE ORACLE", tm = "TM_DREAM_EATER",
    party = { { level = 30, species = "HYPNO" }, { level = 32, species = "ALAKAZAM" } },
    intro = "I walk in dreams.\nDefeat me and I\vshall teach you\vDREAM EATER.",
    teach = "Your mind is\nready. DREAM EATER\vis yours.",
    after = "Sleep well,\ntraveler." },
  { key = "sky", map = "ROUTE_15", sprite = "SPRITE_FISHING_GURU", text = "TEXT_MOVE_TUTOR_SKY",
    trainer = "OPP_TUTOR_SKY", name = "TAMER SKY", tm = "TM_SKY_ATTACK",
    party = { { level = 33, species = "FEAROW" }, { level = 35, species = "PIDGEOT" } },
    intro = "My birds rule the\nsky! Beat them to\vlearn SKY ATTACK.",
    teach = "Magnificent! SKY\nATTACK is yours to\vcommand.",
    after = "Soar high, my\nfriend!" },
}
local function tutorFlag(t) return "MOD_TUTOR_" .. t.key .. "_LEARNED" end
local function tutorTalk(t)
  local LEARNED = tutorFlag(t)
  return {
    { "check_flag", LEARNED }, { "jump_if_true", "after" },
    { "show_text", t.intro },
    { "choice", { "BATTLE", "LATER" } }, { "jump_if_false", "later" },
    { "start_battle", "trainer", t.trainer, 1 },
    { "jump_if_false", "end" }, -- a loss blacks you out; bail quietly
    { "give_item", t.tm, 1, true },
    { "set_flag", LEARNED },
    { "show_text", t.teach },
    { "jump", "end" },
    { "label", "later" }, { "show_text", "Come back when\nyou are ready." }, { "jump", "end" },
    { "label", "after" }, { "show_text", t.after },
  }
end

-- ================= TRACKER (QUESTS menu) =========================
local LOG = {
  { name = "GLOW SHARD", started = GLOW_STARTED, done = GLOW_DONE },
  { name = "KEEPSAKE", started = "MOD_TQ_keepsake_STARTED", done = "MOD_TQ_keepsake_DONE" },
  { name = "LOST LETTER", started = "MOD_TQ_letter_STARTED", done = "MOD_TQ_letter_DONE" },
  { name = "RARE HERB", started = "MOD_TQ_herb_STARTED", done = "MOD_TQ_herb_DONE" },
  { name = "LUCK CHARM", started = "MOD_TQ_charm_STARTED", done = "MOD_TQ_charm_DONE" },
  { name = "SECRET MAP", started = Q1.STARTED, done = Q1.DONE, endings = { { Q1.SCI, "SCIENCE" }, { Q1.FOR, "GOLD" } } },
  { name = "AMBER SHARD", started = Q2.STARTED, done = Q2.DONE, endings = { { Q2.CONS, "SAVED" }, { Q2.PROFIT, "BRIBED" } } },
  { name = "WHISTLEBLOWER", started = Q3.STARTED, done = Q3.DONE, endings = { { Q3.HERO, "EXPOSED" }, { Q3.GREED, "COVERED" } } },
  { name = "TWO BROTHERS", started = Q4.STARTED, done = Q4.DONE, endings = { { Q4.SIDE3, "SIDED A" }, { Q4.SIDE2, "SIDED B" } } },
  { name = "ROCKER GUITAR", started = Q5.STARTED, done = Q5.DONE, endings = { { Q5.MUSIC, "RETURNED" }, { Q5.SELL, "SOLD" } } },
  { name = "MASTER GORO", started = "MOD_TUTOR_goro_LEARNED", done = "MOD_TUTOR_goro_LEARNED" },
  { name = "SAGE ORACLE", started = "MOD_TUTOR_oracle_LEARNED", done = "MOD_TUTOR_oracle_LEARNED" },
  { name = "TAMER SKY", started = "MOD_TUTOR_sky_LEARNED", done = "MOD_TUTOR_sky_LEARNED" },
}
local SCREEN = "QuestLog"

return function(mod)
  -- all quest items
  mod.content.items:register(GLOW_SHARD, { id = GLOW_SHARD, name = "GLOW SHARD", price = 0, keyItem = true, tossable = false })
  for _, q in ipairs(TOWN_QUESTS) do
    mod.content.items:register(q.item, { id = q.item, name = q.itemName, price = 0, keyItem = true, tossable = false })
  end
  mod.content.items:register(MAP_ITEM, { id = MAP_ITEM, name = "SECRET MAP", price = 0, keyItem = true, tossable = false })
  mod.content.items:register(SHARD_ITEM, { id = SHARD_ITEM, name = "AMBER SHARD", price = 0, keyItem = true, tossable = false })
  mod.content.items:register(NOTE_ITEM, { id = NOTE_ITEM, name = "NOTE", price = 0, keyItem = true, tossable = false })
  mod.content.items:register(GUITAR_ITEM, { id = GUITAR_ITEM, name = "GUITAR", price = 0, keyItem = true, tossable = false })

  -- one talk table per map, so quests sharing a town compose
  local byMap = {}
  local function put(map, npc, talk)
    byMap[map] = byMap[map] or {}
    byMap[map][npc] = talk
  end

  put("CERULEAN_CITY", "TEXT_CERULEANCITY_SUPER_NERD1", glowGiver())
  put("LAVENDER_TOWN", "TEXT_LAVENDERTOWN_SUPER_NERD", glowHolder())

  for _, q in ipairs(TOWN_QUESTS) do
    put(q.giver.map, q.giver.npc, tqGiver(q))
    put(q.holder.map, q.holder.npc, tqHolder(q))
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
  put("SAFFRON_CITY", "TEXT_SAFFRONCITY_ROCKER", q5_rocker())
  put("VIRIDIAN_CITY", "TEXT_VIRIDIANCITY_YOUNGSTER1", q5_thief())

  for map, talk in pairs(byMap) do
    mod.content.map_scripts:register(map, { talk = talk })
  end

  -- ------- move tutors: spawn a master on a route until you learn from them ---
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
  local function pickCell(ov, ow)
    local px, py = ow.player and ow.player.cellX, ow.player and ow.player.cellY
    if not px then return nil end
    local W, seen, q, head = ov.width, {}, { { px, py } }, 1
    seen[py * W + px] = true
    local best
    while head <= #q and head < 4000 do
      local c = q[head]; head = head + 1
      local d = math.abs(c[1] - px) + math.abs(c[2] - py)
      if d >= 3 and d <= 9 and not best then best = c end
      for _, dd in ipairs({ { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 } }) do
        local nx, ny = c[1] + dd[1], c[2] + dd[2]
        if walkable(ov, nx, ny) and not seen[ny * W + nx] then seen[ny * W + nx] = true; q[#q + 1] = { nx, ny } end
      end
    end
    return best
  end

  local tutorSpawned = {}
  for _, t in ipairs(TUTORS) do
    mod.content.trainers:register(t.trainer, {
      id = t.trainer, name = t.name, baseMoney = 50, parties = { t.party },
    })
    mod.content.map_scripts:register(t.map, {
      talk = { [t.text] = tutorTalk(t) },
      onEnter = function(game, ow)
        if tutorSpawned[t.map] then return end
        if game.save and game.save.flags and game.save.flags[tutorFlag(t)] then return end -- already learned
        local ov = overview(); if not ov then return end
        local cell = pickCell(ov, ow); if not cell then return end
        local id = mod.world:spawnNpc(t.map, { sprite = t.sprite, text = t.text, movement = "STAY", range = "NONE", x = cell[1], y = cell[2] })
        if id then tutorSpawned[t.map] = true end
      end,
    })
  end

  -- ------- the quest log ------------------------------------------
  local function isSet(game, name)
    return name and game.save and game.save.flags and game.save.flags[name] and true or false
  end
  local function status(game, q)
    if isSet(game, q.done) then
      if q.endings then
        for _, e in ipairs(q.endings) do if isSet(game, e[1]) then return e[2] end end
      end
      return "DONE"
    elseif isSet(game, q.started) then
      return "ACTIVE"
    end
    return "- -"
  end
  mod.content.screens:register(SCREEN, {
    new = function(game)
      local items = {}
      for _, q in ipairs(LOG) do
        items[#items + 1] = { label = q.name, right = status(game, q), value = q.name }
      end
      return mod.ui.ListMenu.new(game, "QUESTS", items, { onChoose = function(_, menu) menu:close() end })
    end,
  })
  mod.hooks:wrap("ui.start_menu.items", function(next, game, items)
    local out = next(game, items)
    if type(out) ~= "table" then return out end
    return mod.ui.insertBefore(out, "SAVE", {
      label = "QUESTS",
      onSelect = function() mod.ui.push(game, SCREEN) end,
    })
  end)
end
