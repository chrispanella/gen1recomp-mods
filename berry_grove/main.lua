-- berry_grove: a helpful guard in Cerulean shares a healing item each real day.
local ITEMS = { "SUPER_POTION", "HYPER_POTION", "FULL_HEAL", "REVIVE",
                "FRESH_WATER", "SODA_POP", "LEMONADE", "MAX_POTION" }

local function realDay()
  local ok, t = pcall(os.date, "*t")
  if ok and type(t) == "table" and t.year and t.yday then return t.year * 366 + t.yday end
  return math.floor((os.time and os.time() or 0) / 86400)
end

return function(mod)
  local Commands = require("src.script.Commands")
  mod.content.commands:register("berry_grove:give", {
    foreground = true,
    fn = function(ctx)
      local today = realDay()
      if mod.save:get("last", -1) == today then
        Commands.show_text(ctx, "Stay safe out\nthere. Come back\vtomorrow!")
        return
      end
      mod.save:set("last", today)
      Commands.show_text(ctx, "Here, for the\nroad. On the\vhouse, trainer.")
      Commands.give_item(ctx, ITEMS[(today % #ITEMS) + 1], 1, true)
    end,
  })
  mod.content.map_scripts:register("CERULEAN_CITY", {
    talk = { TEXT_CERULEANCITY_GUARD1 = { { "berry_grove:give" } } },
  })
end
