-- veteran: a re-battleable trainer in Viridian for grinding. Ask any time,
-- battle a fixed team, earn modest prize money. No one-time flag - come back
-- as often as you like.
return function(mod)
  -- optional tweaks BATTLE DIFF scales the team's levels (read once at load;
  -- changing the setting takes effect after a reload)
  local tw = mod.find("tweaks")
  local mult = (tw and tw.exports and tw.exports.difficulty and tw.exports.difficulty().levelMult) or 1
  local function lv(l) return math.min(100, math.floor(l * mult)) end
  mod.content.trainers:register("OPP_FUN_VETERAN", {
    id = "OPP_FUN_VETERAN", name = "VETERAN JODY", baseMoney = 55,
    parties = { {
      { level = lv(30), species = "PIDGEOTTO" },
      { level = lv(31), species = "RATICATE" },
      { level = lv(32), species = "KADABRA" },
      { level = lv(33), species = "MACHOKE" },
    } },
  })
  mod.content.map_scripts:register("VIRIDIAN_CITY", {
    talk = {
      TEXT_VIRIDIANCITY_YOUNGSTER2 = {
        { "show_text", "Want to spar again?\nMy team's always\vready to train!" },
        { "choice", { "YES", "NO" } },
        { "jump_if_false", "no" },
        { "start_battle", "trainer", "OPP_FUN_VETERAN", 1 },
        { "jump", "end" },
        { "label", "no" },
        { "show_text", "Come back when you\nwant a good spar!" },
      },
    },
  })
end
