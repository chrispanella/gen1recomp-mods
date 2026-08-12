-- type_sage: a guard in Cerulean shares a rotating type-matchup tip each week.
local TIPS = {
  "WATER douses FIRE,\nGROUND and ROCK.",
  "ELECTRIC zaps\nWATER and FLYING.",
  "GRASS drinks up\nWATER and GROUND.",
  "FIRE melts GRASS,\nICE and BUG.",
  "GROUND grounds\nELECTRIC and FIRE.",
  "PSYCHIC rattles\nFIGHTING and POISON.",
  "ICE chills GRASS,\nGROUND and FLYING.",
  "FIGHTING floors\nNORMAL and ICE.",
  "GHOST spooks\nPSYCHIC... in theory.",
  "ROCK crushes FIRE,\nFLYING and BUG.",
}

local function realWeek()
  return math.floor((os.time and os.time() or 0) / 604800) -- 7-day period
end

return function(mod)
  local Commands = require("src.script.Commands")
  mod.content.commands:register("type_sage:tip", {
    foreground = true,
    fn = function(ctx)
      Commands.show_text(ctx, "Type tip of the\nweek:\f" .. TIPS[(realWeek() % #TIPS) + 1])
    end,
  })
  mod.content.map_scripts:register("CERULEAN_CITY", {
    talk = { TEXT_CERULEANCITY_GUARD2 = { { "type_sage:tip" } } },
  })
end
