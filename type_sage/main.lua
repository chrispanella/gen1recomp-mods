-- type_sage: a guard in Cerulean shares a rotating type-matchup tip each day.
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

local function realDay()
  local ok, t = pcall(os.date, "*t")
  if ok and type(t) == "table" and t.year and t.yday then return t.year * 366 + t.yday end
  return math.floor((os.time and os.time() or 0) / 86400)
end

return function(mod)
  local Commands = require("src.script.Commands")
  mod.content.commands:register("type_sage:tip", {
    foreground = true,
    fn = function(ctx)
      Commands.show_text(ctx, "Type tip of the\nday:\f" .. TIPS[(realDay() % #TIPS) + 1])
    end,
  })
  mod.content.map_scripts:register("CERULEAN_CITY", {
    talk = { TEXT_CERULEANCITY_GUARD2 = { { "type_sage:tip" } } },
  })
end
