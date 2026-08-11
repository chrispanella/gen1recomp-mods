-- quest_glow_shard
-- ------------------------------------------------------------------
-- A self-contained fetch quest across two towns, built only from
-- registry content -- no engine file edited, no map changed:
--
--   * A collector NPC in CERULEAN CITY (the super nerd) gives the quest
--     with a YES/NO choice and tracks it with MOD_ flags.
--   * An NPC in LAVENDER TOWN (the super nerd) hands over a custom key
--     item, the GLOW SHARD, but only while the quest is active.
--   * Returning the shard to the collector pays out a RARE CANDY.
--
-- Everything runs on the map-script VM: show_text, choice, check_flag /
-- set_flag, check_item / take_item / give_item, emote, and label/jump.
-- `check_item` and `choice` leave their result in ctx.lastCheck, which is
-- what `jump_if_false` branches on.
--
-- Note: this fully OWNS the two NPCs' dialogue (their vanilla lines are
-- replaced). That keeps the mod simple and permission-free. To instead
-- preserve the original conversation on the branches the quest does not
-- use, see the shipped `example_lost_parcel` mod, which calls back into
-- MapScripts.baseTalk (and declares the engine_internals permission).

local SHARD = "QUEST_GLOW_SHARD_ITEM"
local REWARD = "RARE_CANDY"

-- MOD_-prefixed so quest flags never collide with the engine's own
-- pokered event namespace.
local STARTED = "MOD_QUEST_GLOW_SHARD_STARTED"
local TAKEN = "MOD_QUEST_GLOW_SHARD_TAKEN"
local DONE = "MOD_QUEST_GLOW_SHARD_DONE"

-- Real Yellow NPC objects (verified against the extracted map data).
local COLLECTOR = "TEXT_CERULEANCITY_SUPER_NERD1"
local HOLDER = "TEXT_LAVENDERTOWN_SUPER_NERD"

return function(mod)
  -- ------- the quest item -------------------------------------------

  mod.content.items:register(SHARD, {
    id = SHARD,
    name = "GLOW SHARD",
    price = 0,
    keyItem = true,
    tossable = false,
  })

  -- ------- CERULEAN CITY: the collector who gives (and completes) it --

  mod.content.map_scripts:register("CERULEAN_CITY", {
    talk = {
      [COLLECTOR] = {
        { "check_flag", DONE },
        { "jump_if_true", "after" },
        { "check_flag", STARTED },
        { "jump_if_true", "pending" },

        -- first meeting: offer the quest
        { "show_text", "I collect rare\nminerals!\fWord is a glowing\nrock turned up in\vLAVENDER TOWN.\fBring it to me?" },
        { "choice", { "SURE", "NO THANKS" } },
        { "jump_if_false", "refused" },
        { "set_flag", STARTED },
        { "show_text", "Excellent! Ask\naround LAVENDER\vTOWN. I'll reward\vyou well!" },
        { "jump", "end" },

        -- quest active: check whether the player has the shard yet
        { "label", "pending" },
        { "check_item", SHARD },
        { "jump_if_false", "remind" },
        { "take_item", SHARD },
        { "give_item", REWARD },
        { "set_flag", DONE },
        { "emote", "player", "happy", 45 },
        { "show_text", "The GLOW SHARD!\nMagnificent!\fHere, this is the\nleast I can do." },
        { "jump", "end" },

        { "label", "remind" },
        { "show_text", "Any luck? The\nGLOW SHARD, in\vLAVENDER TOWN!" },
        { "jump", "end" },

        { "label", "refused" },
        { "show_text", "No? Come back if\nyou change your\vmind." },
        { "jump", "end" },

        { "label", "after" },
        { "show_text", "The GLOW SHARD is\nthe pride of my\vcollection now!" },
      },
    },
  })

  -- ------- LAVENDER TOWN: the NPC holding the shard ------------------

  mod.content.map_scripts:register("LAVENDER_TOWN", {
    talk = {
      [HOLDER] = {
        { "check_flag", STARTED },
        { "jump_if_false", "idle" },
        { "check_flag", TAKEN },
        { "jump_if_true", "idle" },

        { "show_text", "This glowing rock?\nFound it by the\vTOWER. Gives me the\vchills. Take it!" },
        { "give_item", SHARD, 1, false },
        { "set_flag", TAKEN },
        { "show_text", "{PLAYER} got the\nGLOW SHARD!" },
        { "jump", "end" },

        { "label", "idle" },
        { "show_text", "This town is spooky\nafter dark, you\vknow." },
      },
    },
  })

  -- ------- announce completion to any other mods --------------------

  mod.events:on("flag.changed", function(ev)
    if ev.name == DONE and ev.value then
      mod.events:emit("mod.quest_glow_shard.completed", { reward = REWARD })
    end
  end)
end
