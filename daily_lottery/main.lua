-- daily_lottery: pick a lucky number once a day; match the draw for a prize.
local PRIZES = { "NUGGET", "RARE_CANDY", "PP_UP", "MAX_ETHER", "FULL_RESTORE" }

local function realDay()
  local ok, t = pcall(os.date, "*t")
  if ok and type(t) == "table" and t.year and t.yday then return t.year * 366 + t.yday end
  return math.floor((os.time and os.time() or 0) / 86400)
end
local function winningNumber(day)
  local s = 5381
  local str = "lotto" .. tostring(day)
  for i = 1, #str do s = (s * 33 + str:byte(i)) % 2147483647 end
  return (s % 3) + 1
end

return function(mod)
  local Commands = require("src.script.Commands")
  mod.content.commands:register("daily_lottery:check", {
    foreground = true,
    fn = function(ctx) ctx.lastCheck = (mod.save:get("last", -1) ~= realDay()) end,
  })
  mod.content.commands:register("daily_lottery:result", {
    foreground = true,
    fn = function(ctx)
      local today = realDay()
      mod.save:set("last", today)
      local pick = ctx.lastChoice and ctx.lastChoice.index or 1
      if pick == winningNumber(today) then
        Commands.show_text(ctx, "A winner! The\nnumbers match!\vHere's your prize!")
        Commands.give_item(ctx, PRIZES[(today % #PRIZES) + 1], 1, true)
      else
        Commands.show_text(ctx, "Ooh, so close!\nBetter luck\vtomorrow!")
      end
    end,
  })
  mod.content.map_scripts:register("VERMILION_CITY", {
    talk = {
      TEXT_VERMILIONCITY_OFFICER_JENNY = {
        { "daily_lottery:check" },
        { "jump_if_false", "played" },
        { "show_text", "Daily LOTTERY!\nPick a lucky\vnumber!" },
        { "choice", { "1", "2", "3" } },
        { "daily_lottery:result" },
        { "jump", "end" },
        { "label", "played" },
        { "show_text", "One draw per day!\nCome back tomorrow." },
      },
    },
  })
end
