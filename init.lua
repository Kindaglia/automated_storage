local S = minetest.get_translator("automated_chest")
local F = minetest.formspec_escape
local C = minetest.colorize

-- Global state for player search queries
local player_search_state = {}

-- Initialize detached inventory for a player
local function init_player_detached_inv(player_name)
    local inv_name = "automated_chest_filter_" .. player_name
    if minetest.get_inventory({ type = "detached", name = inv_name }) then
        return -- Already exists
    end

    minetest.create_detached_inventory(inv_name, {
        allow_move = function(inv, from_list, from_index, to_list, to_index, count, player)
            return 0 -- Disable moving within filtered view to keep things simple
        end,
        allow_put = function(inv, listname, index, stack, player)
            local pos = player_search_state[player:get_player_name()].pos
            if not pos then return 0 end
            local node_meta = minetest.get_meta(pos)
            local node_inv = node_meta:get_inventory()

            if node_inv:room_for_item("main", stack) then
                return stack:get_count()
            end
            return 0
        end,
        allow_take = function(inv, listname, index, stack, player)
            return stack:get_count()
        end,
        on_put = function(inv, listname, index, stack, player)
            local state = player_search_state[player:get_player_name()]
            if not state or not state.pos then return end

            local node_meta = minetest.get_meta(state.pos)
            local node_inv = node_meta:get_inventory()

            -- Add to real inventory
            local leftover = node_inv:add_item("main", stack)

            -- If for some reason it failed (race condition), give back to player
            if not leftover:is_empty() then
                minetest.add_item(player:get_pos(), leftover)
            end

            -- Refresh view
            state.refresh_func(player, state.pos, state.query)
        end,
        on_take = function(inv, listname, index, stack, player)
            local state = player_search_state[player:get_player_name()]
            if not state or not state.pos then return end

            local node_meta = minetest.get_meta(state.pos)
            local node_inv = node_meta:get_inventory()

            -- Remove from real inventory
            -- We use remove_item which finds the item anywhere in the list
            node_inv:remove_item("main", stack)

            -- Refresh view
            state.refresh_func(player, state.pos, state.query)
        end,
    }, player_name)
end

minetest.register_on_joinplayer(function(player)
    init_player_detached_inv(player:get_player_name())
end)

minetest.register_on_leaveplayer(function(player)
    player_search_state[player:get_player_name()] = nil
end)

-- Filter items based on query
local function get_filtered_items(inv, query)
    local filtered = {}
    local query_lower = string.lower(query)
    for i = 1, inv:get_size("main") do
        local stack = inv:get_stack("main", i)
        if not stack:is_empty() then
            local def = stack:get_definition()
            local desc = def.description or ""
            local name = stack:get_name()

            -- Clean description (remove color codes)
            desc = minetest.strip_colors(desc)

            if string.find(string.lower(desc), query_lower, 1, true) or
                string.find(string.lower(name), query_lower, 1, true) then
                table.insert(filtered, stack)
            end
        end
    end
    return filtered
end

-- Update the detached inventory with filtered items
local function update_filtered_view(player, pos, query)
    local player_name = player:get_player_name()
    local inv_name = "automated_chest_filter_" .. player_name
    local detached_inv = minetest.get_inventory({ type = "detached", name = inv_name })

    if not detached_inv then
        init_player_detached_inv(player_name)
        detached_inv = minetest.get_inventory({ type = "detached", name = inv_name })
    end

    local node_meta = minetest.get_meta(pos)
    local node_inv = node_meta:get_inventory()

    local items = get_filtered_items(node_inv, query)

    -- Resize detached inventory to fit items (or at least 9x1 for looks)
    local size = math.max(9, math.ceil(#items / 9) * 9)
    detached_inv:set_size("main", size)
    detached_inv:set_list("main", items)

    return size
end

local function show_chest_formspec(player, pos, query)
    local player_name = player:get_player_name()
    local spos = pos.x .. "," .. pos.y .. "," .. pos.z

    -- Save state
    player_search_state[player_name] = {
        pos = pos,
        query = query,
        refresh_func = function(p, po, q)
            -- Only refresh if the user is still looking at this formspec
            show_chest_formspec(p, po, q)
        end
    }

    local is_filtered = query and query ~= ""
    -- Fix: Use explicit nodemeta syntax instead of 'context' which only works for node-triggered formspecs
    local list_name = "nodemeta:" .. spos
    local list_loc = list_name

    -- Calculate rows
    local rows_total = 12
    if is_filtered then
        local size = update_filtered_view(player, pos, query)
        rows_total = math.ceil(size / 9)
        list_name = "detached:automated_chest_filter_" .. player_name
        list_loc = list_name -- For listring
    end

    -- Formspec dimensions
    local width = 13
    local height = 14.25

    -- Inventory grid config
    local rows_visible = 6
    local cols = 9
    local slot_size = 1.25
    local scroll_height = rows_visible * slot_size

    -- Positions
    local padding = 0.375
    local inv_x = padding
    local inv_y = 0.75
    local scrollbar_x = inv_x + (cols * slot_size) + 0.125
    local player_inv_y = inv_y + scroll_height + 0.75
    local hotbar_y = player_inv_y + (3 * slot_size) + 0.2

    -- Ensure background covers at least visible area or total rows if smaller (unlikely with min size logic)
    local bg_rows = math.max(rows_visible, rows_total)

    local formspec = table.concat({
        "formspec_version[4]",
        "size[", width, ",", height, "]",

        "label[", padding, ",", padding, ";", F(S("Automated Chest")), "]",

        -- Search Bar
        "field[", (width - 4 - padding), ",", 0.1, ";4,0.6;search;;", F(query or ""), "]",
        "field_close_on_enter[search;false]",

        -- Scroll Container
        "scroll_container[", inv_x, ",", inv_y, ";", (cols * slot_size), ",", scroll_height, ";scroll;vertical;1.25]",
        -- Content
        mcl_formspec.get_itemslot_bg_v4(0, 0, cols, bg_rows),
        "list[", list_name, ";main;0,0;", cols, ",", bg_rows, ";]",
        "scroll_container_end[]",

        -- Scrollbar
        "scrollbaroptions[min=0;max=", math.max(0, rows_total - rows_visible), ";smallstep=1;largestep=1;arrows=on]",
        "scrollbar[", scrollbar_x, ",", inv_y, ";0.75,", scroll_height, ";vertical;scroll;0]",

        -- Player Inventory Label
        "label[", padding, ",", (player_inv_y - 0.4), ";", F(S("Inventory")), "]",

        -- Player Inventory
        mcl_formspec.get_itemslot_bg_v4(inv_x, player_inv_y, 9, 3),
        "list[current_player;main;", inv_x, ",", player_inv_y, ";9,3;9]",

        -- Player Hotbar
        mcl_formspec.get_itemslot_bg_v4(inv_x, hotbar_y, 9, 1),
        "list[current_player;main;", inv_x, ",", hotbar_y, ";9,1;]",

        -- Listrings
        "listring[", list_loc, ";main]",
        "listring[current_player;main]",
    })

    minetest.show_formspec(player_name, "automated_chest:chest_fs", formspec)
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
        inv:set_size("main", 9 * 12)    -- 108 slots
        meta:set_string("formspec", "") -- Clear formspec to force manual show
    end,

    can_dig = function(pos, player)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        return inv:is_empty("main")
    end,

    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
        show_chest_formspec(clicker, pos, "")
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

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "automated_chest:chest_fs" then return end

    local state = player_search_state[player:get_player_name()]
    if not state then return end

    -- Handle Search
    if fields.search or (fields.key_enter_field == "search") then
        local query = fields.search or ""
        show_chest_formspec(player, state.pos, query)
    end
end)

minetest.register_craft({
    output = "automated_chest:chest",
    recipe = {
        { "group:wood", "group:wood",       "group:wood" },
        { "group:wood", "mcl_chests:chest", "group:wood" },
        { "group:wood", "group:wood",       "group:wood" },
    }
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
