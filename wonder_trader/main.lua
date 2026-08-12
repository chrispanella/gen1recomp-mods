-- wonder_trader: a girl in Celadon gives you one rare Pokemon per real day
-- (never a common species). A daily surprise for your box.
local MONS = {
  { "OMANYTE", 18 }, { "KABUTO", 18 }, { "DRATINI", 15 }, { "EEVEE", 18 },
  { "SCYTHER", 20 }, { "PINSIR", 20 }, { "LAPRAS", 20 }, { "PORYGON", 18 },
  { "CHANSEY", 18 }, { "TAUROS", 20 },
}

local function realDay()
  local ok, t = pcall(os.date, "*t")
  if ok and type(t) == "table" and t.year and t.yday then return t.year * 366 + t.yday end
  return math.floor((os.time and os.time() or 0) / 86400)
end

return function(mod)
  local Commands = require("src.script.Commands")
  mod.content.commands:register("wonder_trader:trade", {
    foreground = true,
    fn = function(ctx)
      local today = realDay()
      if mod.save:get("last", -1) == today then
        Commands.show_text(ctx, "I've no more to\nspare today. Visit\vtomorrow!")
        return
      end
      mod.save:set("last", today)
      local m = MONS[(today % #MONS) + 1]
      Commands.show_text(ctx, "My daily surprise\nPOKeMON... this one\vis for you!")
      Commands.give_pokemon(ctx, m[1], m[2], true)
    end,
  })
  mod.content.map_scripts:register("CELADON_CITY", {
    talk = { TEXT_CELADONCITY_LITTLE_GIRL = { { "wonder_trader:trade" } } },
  })
end
