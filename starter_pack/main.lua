-- starter_pack: an NPC in Pewter hands new trainers a one-time kit of useful
-- items to get going.
return function(mod)
  local Commands = require("src.script.Commands")
  mod.content.commands:register("starter_pack:give", {
    foreground = true,
    fn = function(ctx)
      if mod.save:get("claimed", false) then
        Commands.show_text(ctx, "You've got your\nkit already. Go\vget 'em!")
        return
      end
      mod.save:set("claimed", true)
      Commands.show_text(ctx, "Every trainer needs\na good kit. Here!")
      Commands.give_item(ctx, "POTION", 5, true)
      Commands.give_item(ctx, "SUPER_POTION", 2, false)
      Commands.give_item(ctx, "ANTIDOTE", 2, false)
      Commands.give_item(ctx, "PARLYZ_HEAL", 2, false)
      Commands.give_item(ctx, "RARE_CANDY", 1, false)
    end,
  })
  mod.content.map_scripts:register("PEWTER_CITY", {
    talk = { TEXT_PEWTERCITY_SUPER_NERD1 = { { "starter_pack:give" } } },
  })
end
