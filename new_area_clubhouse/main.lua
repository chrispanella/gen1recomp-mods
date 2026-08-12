-- new_area_clubhouse  (EXPERIMENTAL: a brand-new map added by a mod)
-- ------------------------------------------------------------------
-- Demonstrates adding a NEW interior area and populating it. The room
-- layout is cloned from a vanilla one-room house so it renders correctly;
-- a warp is added to PALLET TOWN that leads inside; and the room has its
-- own NPC with a small reward.
--
-- HEADS UP: the Pallet entrance tile (4,8) is a best guess -- verify in
-- game that it is a reachable tile and move it if not (one line below), or
-- place a proper door with the Tiled workflow. Everything else validates
-- through the loader; the entrance is the only thing that needs your eyes.

local HOST_TEXT = "TEXT_FUN_CLUBHOUSE_HOST"
local GIFT_FLAG = "MOD_CLUBHOUSE_GIFT"

return function(mod)
  -- 1) Register a new interior map. blocks/width/height/tileset/borderBlock
  -- are cloned from BLUES_HOUSE, so the room draws correctly. New maps use
  -- an index >= 1000 to avoid colliding with the vanilla map numbers.
  mod.content.maps:register("FUN_CLUBHOUSE", {
    id = "FUN_CLUBHOUSE",
    index = 1000,
    label = "FunClubhouse",
    tileset = "HOUSE",
    width = 4,
    height = 4,
    borderBlock = 10,
    blocks = { 4, 14, 5, 9, 15, 1, 2, 15, 15, 12, 13, 15, 6, 11, 15, 7 },
    -- two-tile doormat at the bottom; LAST_MAP returns to whatever map you
    -- entered from, at that map's warp #4 (the Pallet warp we append below).
    warps = {
      { destMap = "LAST_MAP", destWarp = 4, x = 2, y = 7 },
      { destMap = "LAST_MAP", destWarp = 4, x = 3, y = 7 },
    },
    objects = {
      { index = 1, name = "FUN_CLUBHOUSE_HOST", sprite = "SPRITE_GENTLEMAN",
        text = HOST_TEXT, movement = "STAY", range = "NONE", x = 3, y = 3 },
    },
    signs = {},
    connections = {},
  })

  -- 2) Add the entrance: append a warp to PALLET_TOWN leading inside. This
  -- becomes Pallet's warp #4 (3 vanilla + this), which is why the room's
  -- exits use destWarp = 4. Change x/y if (4,8) is not walkable in game.
  mod.content.maps:patch("PALLET_TOWN", {
    warps = { __append = { { destMap = "FUN_CLUBHOUSE", destWarp = 1, x = 4, y = 8 } } },
  })

  -- 3) Populate it: the host gives a one-time welcome gift.
  mod.content.map_scripts:register("FUN_CLUBHOUSE", {
    talk = {
      [HOST_TEXT] = {
        { "check_flag", GIFT_FLAG },
        { "jump_if_true", "after" },
        { "show_text", "Welcome to the\nFUN CLUBHOUSE!\fA modded room all\nour own. Here, a\vgift for visiting!" },
        { "give_item", "RARE_CANDY" },
        { "set_flag", GIFT_FLAG },
        { "jump", "end" },
        { "label", "after" },
        { "show_text", "Make yourself at\nhome, {PLAYER}!" },
      },
    },
  })
end
