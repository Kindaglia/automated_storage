local S = minetest.get_translator("automated_chest")
local F = minetest.formspec_escape
local C = minetest.colorize

-- Function to generate the formspec (UI)
local function get_chest_formspec(pos)
    -- Using 'context' allows the formspec to work even if the node is moved
    -- 'pos' argument is kept for compatibility/potential future use but not strictly needed with 'context'

    -- Formspec dimensions
    local width = 13
    local height = 14.25

    -- Inventory grid config
    local rows_visible = 6
    local rows_total = 12
    local cols = 9
    local slot_size = 1.25                         -- Standard slot size in MCL2 formspec v4
    local scroll_height = rows_visible * slot_size -- 7.5

    -- Positions
    local padding = 0.375
    local inv_x = padding
    local inv_y = 0.75
    local scrollbar_x = inv_x + (cols * slot_size) + 0.125 -- 11.75
    local player_inv_y = inv_y + scroll_height + 0.75      -- 9.0
    local hotbar_y = player_inv_y + (3 * slot_size) + 0.2  -- 12.95

    local formspec = table.concat({
        "formspec_version[4]",
        "size[", width, ",", height, "]",

        "label[", padding, ",", padding, ";", F(S("Automated Chest")), "]",

        -- Scroll Container for Chest Inventory
        "scroll_container[", inv_x, ",", inv_y, ";", (cols * slot_size), ",", scroll_height, ";scroll;vertical;1.25]",
        -- Content (Background + List)
        mcl_formspec.get_itemslot_bg_v4(0, 0, cols, rows_total),
        "list[context;main;0,0;", cols, ",", rows_total, ";]",
        "scroll_container_end[]",

        -- Scrollbar
        -- max = total_rows - visible_rows
        "scrollbaroptions[min=0;max=", (rows_total - rows_visible), ";smallstep=1;largestep=1;arrows=on]",
        "scrollbar[", scrollbar_x, ",", inv_y, ";0.75,", scroll_height, ";vertical;scroll;0]",

        -- Player Inventory Label
        "label[", padding, ",", (player_inv_y - 0.4), ";", F(S("Inventory")), "]",

        -- Player Inventory
        mcl_formspec.get_itemslot_bg_v4(inv_x, player_inv_y, 9, 3),
        "list[current_player;main;", inv_x, ",", player_inv_y, ";9,3;9]",

        -- Player Hotbar
        mcl_formspec.get_itemslot_bg_v4(inv_x, hotbar_y, 9, 1),
        "list[current_player;main;", inv_x, ",", hotbar_y, ";9,1;]",

        -- Listrings for quick move
        "listring[context;main]",
        "listring[current_player;main]",
    })

    return formspec
end

minetest.register_node("automated_chest:chest", {
    description = S("Automated Chest"),
    -- Reusing standard chest textures
    tiles = {
        "mcl_chests_chest_top.png",
        "mcl_chests_chest_top.png",
        "mcl_chests_chest_side.png",
        "mcl_chests_chest_side.png",
        "mcl_chests_chest_side.png",
        "mcl_chests_chest_front.png"
    },
    paramtype2 = "facedir",
    groups = { pickaxey = 1, container = 2, material_wood = 1, flammable = 1, axey = 1 },
    sounds = mcl_sounds.node_sound_wood_defaults(),

    -- Initialize inventory
    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        inv:set_size("main", 9 * 12) -- 108 slots
        meta:set_string("formspec", get_chest_formspec(pos))
    end,

    -- Prevent digging if not empty
    can_dig = function(pos, player)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        return inv:is_empty("main")
    end,

    -- Standard permissions allow automation (Hoppers/Pipes)
    allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
        return count
    end,
    allow_metadata_inventory_put = function(pos, listname, index, stack, player)
        return stack:get_count()
    end,
    allow_metadata_inventory_take = function(pos, listname, index, stack, player)
        return stack:get_count()
    end,
})

-- Crafting recipe
minetest.register_craft({
    output = "automated_chest:chest",
    recipe = {
        { "group:wood", "group:wood",       "group:wood" },
        { "group:wood", "mcl_chests:chest", "group:wood" },
        { "group:wood", "group:wood",       "group:wood" },
    }
})

-- LBM to upgrade existing chests
minetest.register_lbm({
    label = "Upgrade automated chests to 108 slots",
    name = "automated_chest:upgrade_v2",
    nodenames = { "automated_chest:chest" },
    run_at_every_load = true,
    action = function(pos, node)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        -- Ensure size is correct (108 slots)
        if inv:get_size("main") ~= 108 then
            inv:set_size("main", 108)
        end
        -- Always update the formspec to the new layout
        meta:set_string("formspec", get_chest_formspec(pos))
    end,
})
