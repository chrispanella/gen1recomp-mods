-- quest_tracker
-- ------------------------------------------------------------------
-- Adds a QUESTS entry to the START menu that opens a quest log, so players
-- can track every quest from this mod pack in one place. Status is read
-- from the save's event flags (the MOD_ flags each quest sets), so it needs
-- no cooperation from the quest mods and works whether or not they are all
-- installed - a quest whose flags never appear simply reads "not started".
--
-- To track a new quest, add a row to QUESTS below.

local QUESTS = {
  { name = "GLOW SHARD",      started = "MOD_QUEST_GLOW_SHARD_STARTED", done = "MOD_QUEST_GLOW_SHARD_DONE" },
  { name = "KEEPSAKE",        started = "MOD_TQ_keepsake_STARTED",      done = "MOD_TQ_keepsake_DONE" },
  { name = "LOST LETTER",     started = "MOD_TQ_letter_STARTED",        done = "MOD_TQ_letter_DONE" },
  { name = "RARE HERB",       started = "MOD_TQ_herb_STARTED",          done = "MOD_TQ_herb_DONE" },
  { name = "LUCK CHARM",      started = "MOD_TQ_charm_STARTED",         done = "MOD_TQ_charm_DONE" },
  { name = "SECRET MAP",      started = "MOD_BQ1_STARTED",              done = "MOD_BQ1_DONE",
    endings = { { "MOD_BQ1_END_SCI", "SCIENCE" }, { "MOD_BQ1_END_FOR", "GOLD" } } },
  { name = "AMBER SHARD",     started = "MOD_BQ2_STARTED",              done = "MOD_BQ2_DONE",
    endings = { { "MOD_BQ2_END_CONS", "SAVED" }, { "MOD_BQ2_END_PROFIT", "BRIBED" } } },
  { name = "WHISTLEBLOWER",   started = "MOD_BQ3_STARTED",              done = "MOD_BQ3_DONE",
    endings = { { "MOD_BQ3_END_HERO", "EXPOSED" }, { "MOD_BQ3_END_GREED", "COVERED" } } },
  { name = "TWO BROTHERS",    started = "MOD_BQ4_STARTED",              done = "MOD_BQ4_DONE",
    endings = { { "MOD_BQ4_SIDE3", "SIDED A" }, { "MOD_BQ4_SIDE2", "SIDED B" } } },
  { name = "ROCKER GUITAR",   started = "MOD_BQ5_STARTED",              done = "MOD_BQ5_DONE",
    endings = { { "MOD_BQ5_END_MUSIC", "RETURNED" }, { "MOD_BQ5_END_SELL", "SOLD" } } },
}

local SCREEN = "QuestLog"

return function(mod)
  local function isSet(game, name)
    return name and game.save and game.save.flags and game.save.flags[name] and true or false
  end

  local function status(game, q)
    if isSet(game, q.done) then
      if q.endings then
        for _, e in ipairs(q.endings) do
          if isSet(game, e[1]) then return e[2] end
        end
      end
      return "DONE"
    elseif isSet(game, q.started) then
      return "ACTIVE"
    end
    return "- -"
  end

  mod.content.screens:register(SCREEN, {
    new = function(game)
      local items = {}
      for _, q in ipairs(QUESTS) do
        items[#items + 1] = { label = q.name, right = status(game, q), value = q.name }
      end
      return mod.ui.ListMenu.new(game, "QUESTS", items, {
        onChoose = function(_, menu) menu:close() end,
      })
    end,
  })

  -- add a QUESTS entry to the start menu, just above SAVE
  mod.hooks:wrap("ui.start_menu.items", function(next, game, items)
    local out = next(game, items)
    if type(out) ~= "table" then return out end
    return mod.ui.insertBefore(out, "SAVE", {
      label = "QUESTS",
      onSelect = function() mod.ui.push(game, SCREEN) end,
    })
  end)
end
