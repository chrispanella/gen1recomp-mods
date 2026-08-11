-- fun_trainer_ace
-- ------------------------------------------------------------------
-- A proof-of-concept CONTENT mod: it adds one brand-new battle trainer,
-- ACE TRAINER LEO, and places him on a real Viridian City NPC.
--
-- Two moving parts, both pure registry content -- no engine file is
-- edited and no map is changed:
--
--   1. mod.content.trainers:register(...) defines WHO the trainer is:
--      his name, prize money, and his party (`parties` is a list of
--      parties; each party is a list of { level = N, species = "ID" }).
--
--   2. mod.content.map_scripts:register("VIRIDIAN_CITY", { talk = ... })
--      overrides the talk handler of a vanilla NPC so that talking to
--      him challenges you to that trainer battle exactly once, the way
--      a normal in-game trainer works.
--
-- The battle itself is fired by the `start_battle` script verb:
--   { "start_battle", "trainer", <trainer id>, <party index> }
-- After it runs, ctx.lastCheck is true on a win, so `jump_if_false`
-- lets us branch on the outcome.

local TRAINER_ID = "OPP_FUN_ACE_LEO"

-- Mod-authored save flags are MOD_-prefixed by convention so they can
-- never collide with the engine's own pokered event flags.
local BEATEN = "MOD_FUN_TRAINER_ACE_BEATEN"

-- The vanilla NPC we attach to. TEXT_VIRIDIANCITY_GAMBLER1 is a real
-- Viridian City object (the same map/NPC the shipped lost_parcel example
-- uses), so this works on an unmodified game with no map editing.
local HOST_NPC = "TEXT_VIRIDIANCITY_GAMBLER1"

return function(mod)
  -- ------- 1. WHO the trainer is ---------------------------------------

  mod.content.trainers:register(TRAINER_ID, {
    id = TRAINER_ID,
    name = "ACE TRAINER LEO",
    baseMoney = 1200, -- prize money scales off this the vanilla way
    parties = {
      -- party index 1 -- referenced by start_battle below
      {
        { level = 15, species = "NIDORINO" },
        { level = 16, species = "KADABRA" },
        { level = 17, species = "GROWLITHE" },
      },
    },
  })

  -- ------- 2. WHERE you meet him ---------------------------------------

  mod.content.map_scripts:register("VIRIDIAN_CITY", {
    talk = {
      [HOST_NPC] = {
        -- already beaten? go straight to the rematch flavor line
        { "check_flag", BEATEN },
        { "jump_if_true", "already" },

        -- the challenge
        { "show_text", "You there!\nThose are some\vfine POKeMON.\fLet's see how you\nhandle a real\vtrainer!" },
        { "start_battle", "trainer", TRAINER_ID, 1 },

        -- a trainer loss blacks you out; on the resume, bail quietly
        { "jump_if_false", "end" },

        -- win path
        { "set_flag", BEATEN },
        { "show_text", "Whoa! You're the\nreal deal. Take\vpride in that win!" },
        { "jump", "end" },

        -- post-battle / rematch line
        { "label", "already" },
        { "show_text", "That was a great\nbattle, {PLAYER}.\fKeep training!" },
      },
    },
  })

  -- ------- optional: announce the win to any other mods listening ------

  mod.events:on("flag.changed", function(ev)
    if ev.name == BEATEN and ev.value then
      mod.events:emit("mod.fun_trainer_ace.defeated", { trainer = TRAINER_ID })
    end
  end)
end
