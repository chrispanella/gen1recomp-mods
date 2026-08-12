-- daily_coins: a trainer in Cerulean slips you some Game Corner coins each day.
local function realDay()
  local ok, t = pcall(os.date, "*t")
  if ok and type(t) == "table" and t.year and t.yday then return t.year * 366 + t.yday end
  return math.floor((os.time and os.time() or 0) / 86400)
end

return function(mod)
  local Commands = require("src.script.Commands")
  mod.content.commands:register("daily_coins:give", {
    foreground = true,
    fn = function(ctx)
      local today = realDay()
      if mod.save:get("last", -1) == today then
        Commands.show_text(ctx, "Spent your luck\nfor today! Back\vtomorrow, pal.")
        return
      end
      mod.save:set("last", today)
      Commands.show_text(ctx, "Feelin' lucky?\nHere's some COINS\vfor the corner!")
      Commands.give_item(ctx, "COIN", 50, true)
    end,
  })
  mod.content.map_scripts:register("CERULEAN_CITY", {
    talk = { TEXT_CERULEANCITY_COOLTRAINER_F2 = { { "daily_coins:give" } } },
  })
end
