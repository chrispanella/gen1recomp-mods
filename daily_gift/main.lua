-- daily_gift: a friendly NPC in Pewter hands you a free item once per real day.
local ITEMS = { "POKE_DOLL", "ETHER", "RARE_CANDY", "NUGGET", "MAX_POTION",
                "ELIXER", "PP_UP", "FULL_RESTORE", "MAX_ETHER", "GUARD_SPEC" }

local function realDay()
  local ok, t = pcall(os.date, "*t")
  if ok and type(t) == "table" and t.year and t.yday then return t.year * 366 + t.yday end
  return math.floor((os.time and os.time() or 0) / 86400)
end

return function(mod)
  local Commands = require("src.script.Commands")
  mod.content.commands:register("daily_gift:give", {
    foreground = true,
    fn = function(ctx)
      local today = realDay()
      if mod.save:get("last", -1) == today then
        Commands.show_text(ctx, "That's all for\ntoday! Come back\vtomorrow, friend.")
        return
      end
      mod.save:set("last", today)
      Commands.show_text(ctx, "A little something\nfor visiting today.\vTake care!")
      Commands.give_item(ctx, ITEMS[(today % #ITEMS) + 1], 1, true)
    end,
  })
  mod.content.map_scripts:register("PEWTER_CITY", {
    talk = { TEXT_PEWTERCITY_SUPER_NERD2 = { { "daily_gift:give" } } },
  })
end
