local S = minetest.get_translator("automated_chest")

-- Function to generate the formspec (UI)
local function get_chest_formspec(pos)
    local formspec =
        "size[9,9]" ..
        "label[0,0;" .. S("Automated Chest") .. "]" .. -- Changed Label

        -- Chest Inventory (4 rows x 9 columns)
        "list[context;main;0,0.5;9,4;]" ..
        mcl_formspec.get_itemslot_bg(0, 0.5, 9, 4) ..

        -- Player Inventory (standard 3 rows)
        "list[current_player;main;0,5.0;9,3;9]" ..
        mcl_formspec.get_itemslot_bg(0, 5.0, 9, 3) ..

        -- Player Hotbar (1 row)
        "list[current_player;main;0,8.2;9,1;]" ..
        mcl_formspec.get_itemslot_bg(0, 8.2, 9, 1)

    return formspec
end

minetest.register_node("automated_chest:chest", { -- Changed Node ID
    description = S("Automated Chest"),           -- Changed Description
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
    groups = {pickaxey=1, container=2, material_wood=1, flammable=1, axey=1},
    sounds = mcl_sounds.node_sound_wood_defaults(),

    -- Initialize inventory
    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        inv:set_size("main", 9*4) -- 36 slots
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
        {"group:wood", "group:wood", "group:wood"},
        {"group:wood", "mcl_chests:chest", "group:wood"},
        {"group:wood", "group:wood", "group:wood"},
    }
})
