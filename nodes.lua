local S = minetest.get_translator("automated_chest")

local function update_craft_result(pos)
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    local craft_list = inv:get_list("craft")

    local result, decremented_input = minetest.get_craft_result({
        method = "normal",
        width = 3,
        items = craft_list
    })
    inv:set_stack("craftresult", 1, result.item)
end

local function consume_craft_materials(pos)
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    local craft_list = inv:get_list("craft")

    -- Consume items
    local result, decremented_input = minetest.get_craft_result({
        method = "normal",
        width = 3,
        items = craft_list
    })

    inv:set_list("craft", decremented_input.items)

    -- Handle replacements (e.g., empty buckets)
    for _, item in ipairs(result.replacements) do
        if not item:is_empty() then
            if inv:room_for_item("main", item) then
                inv:add_item("main", item)
            else
                minetest.add_item(pos, item)
            end
        end
    end

    update_craft_result(pos)
end

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
        inv:set_size("main", 1000)      -- 1000 slots
        inv:set_size("craft", 9)        -- 3x3 crafting grid
        inv:set_size("craftresult", 1)  -- Crafting output
        meta:set_string("formspec", "") -- Clear formspec to force manual show
    end,

    can_dig = function(pos, player)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        return inv:is_empty("main") and inv:is_empty("craft") and inv:is_empty("craftresult")
    end,

    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
        automated_chest.show_chest_formspec(clicker, pos, "")
    end,

    allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
        if to_list == "craftresult" then return 0 end
        if from_list == "craftresult" and to_list == "craft" then return 0 end
        return count
    end,
    allow_metadata_inventory_put = function(pos, listname, index, stack, player)
        if listname == "craftresult" then return 0 end
        return stack:get_count()
    end,
    allow_metadata_inventory_take = function(pos, listname, index, stack, player)
        return stack:get_count()
    end,

    on_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
        if from_list == "craftresult" then
            consume_craft_materials(pos)
        elseif from_list == "craft" or to_list == "craft" then
            update_craft_result(pos)
        end
    end,

    on_metadata_inventory_put = function(pos, listname, index, stack, player)
        if listname == "craft" then
            update_craft_result(pos)
        end
    end,

    on_metadata_inventory_take = function(pos, listname, index, stack, player)
        if listname == "craft" then
            update_craft_result(pos)
        elseif listname == "craftresult" then
            consume_craft_materials(pos)
        end
    end,
})
minetest.register_lbm({
    label = "Upgrade automated chests to 1000 slots",
    name = "automated_chest:upgrade_v6",
    nodenames = { "automated_chest:chest" },
    run_at_every_load = true,
    action = function(pos, node)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        if inv:get_size("main") ~= 1000 then
            inv:set_size("main", 1000)
        end
        if inv:get_size("craft") ~= 9 then
            inv:set_size("craft", 9)
        end
        if inv:get_size("craftresult") ~= 1 then
            inv:set_size("craftresult", 1)
        end
        -- Remove static formspec to enable dynamic one
        meta:set_string("formspec", "")
    end,
})
