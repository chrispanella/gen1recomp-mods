-- berry_grove: a helpful guard in Cerulean shares a healing item each week.
local ITEMS = { "SUPER_POTION", "HYPER_POTION", "FULL_HEAL", "REVIVE",
                "FRESH_WATER", "SODA_POP", "LEMONADE", "MAX_POTION" }

local function realWeek()
  return math.floor((os.time and os.time() or 0) / 604800) -- 7-day period
end

return function(mod)
  local Commands = require("src.script.Commands")
  mod.content.commands:register("berry_grove:give", {
    foreground = true,
    fn = function(ctx)
      local today = realWeek()
      if mod.save:get("last", -1) == today then
        Commands.show_text(ctx, "Stay safe out\nthere. Come back\vnext week!")
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
