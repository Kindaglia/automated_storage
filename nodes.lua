local S = minetest.get_translator("automated_chest")

minetest.register_node("automated_chest:chest", {
    description = S("Automated Chest"),
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

    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        inv:set_size("main", 9 * 12)    -- 108 slots
        meta:set_string("formspec", "") -- Clear formspec to force manual show
    end,

    can_dig = function(pos, player)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        return inv:is_empty("main")
    end,

    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
        automated_chest.show_chest_formspec(clicker, pos, "")
    end,

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

minetest.register_lbm({
    label = "Upgrade automated chests to 108 slots",
    name = "automated_chest:upgrade_v3",
    nodenames = { "automated_chest:chest" },
    run_at_every_load = true,
    action = function(pos, node)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        if inv:get_size("main") ~= 108 then
            inv:set_size("main", 108)
        end
        -- Remove static formspec to enable dynamic one
        meta:set_string("formspec", "")
    end,
})
