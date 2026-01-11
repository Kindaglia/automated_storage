local S = minetest.get_translator("automated_chest")

-- Global state for player search queries
automated_chest.player_search_state = {}

-- Filter items based on query
function automated_chest.get_filtered_items(inv, query)
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

-- Initialize detached inventory for a player
function automated_chest.init_player_detached_inv(player_name)
    local inv_name = "automated_chest_filter_" .. player_name
    if minetest.get_inventory({ type = "detached", name = inv_name }) then
        return -- Already exists
    end

    minetest.create_detached_inventory(inv_name, {
        allow_move = function(inv, from_list, from_index, to_list, to_index, count, player)
            return 0 -- Disable moving within filtered view to keep things simple
        end,
        allow_put = function(inv, listname, index, stack, player)
            local pos = automated_chest.player_search_state[player:get_player_name()].pos
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
            local state = automated_chest.player_search_state[player:get_player_name()]
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
            if state.refresh_func then
                state.refresh_func(player, state.pos, state.query)
            end
        end,
        on_take = function(inv, listname, index, stack, player)
            local state = automated_chest.player_search_state[player:get_player_name()]
            if not state or not state.pos then return end

            local node_meta = minetest.get_meta(state.pos)
            local node_inv = node_meta:get_inventory()

            -- Remove from real inventory
            -- We use remove_item which finds the item anywhere in the list
            node_inv:remove_item("main", stack)

            -- Refresh view
            if state.refresh_func then
                state.refresh_func(player, state.pos, state.query)
            end
        end,
    }, player_name)
end

-- Update the detached inventory with filtered items
function automated_chest.update_filtered_view(player, pos, query)
    local player_name = player:get_player_name()
    local inv_name = "automated_chest_filter_" .. player_name
    local detached_inv = minetest.get_inventory({ type = "detached", name = inv_name })

    if not detached_inv then
        automated_chest.init_player_detached_inv(player_name)
        detached_inv = minetest.get_inventory({ type = "detached", name = inv_name })
    end

    local node_meta = minetest.get_meta(pos)
    local node_inv = node_meta:get_inventory()

    local items = automated_chest.get_filtered_items(node_inv, query)

    -- Resize detached inventory to fit items (or at least 9x1 for looks)
    local size = math.max(9, math.ceil(#items / 9) * 9)
    detached_inv:set_size("main", size)
    detached_inv:set_list("main", items)

    return size
end

minetest.register_on_joinplayer(function(player)
    automated_chest.init_player_detached_inv(player:get_player_name())
end)

minetest.register_on_leaveplayer(function(player)
    automated_chest.player_search_state[player:get_player_name()] = nil
end)

-- Sort the inventory
function automated_chest.sort_inventory(pos)
    local meta = minetest.get_meta(pos)
    local inv = meta:get_inventory()
    local size = inv:get_size("main")
    local items = {}

    -- Collect all items
    for i = 1, size do
        local stack = inv:get_stack("main", i)
        if not stack:is_empty() then
            table.insert(items, stack)
        end
    end

    -- Clear inventory
    inv:set_list("main", {})

    -- Stack items logically
    -- We can just add them back to the inventory one by one using add_item,
    -- which handles stacking automatically. However, we want them sorted first.
    -- To sort *and* stack, we should probably consolidate first.

    local consolidated = {}
    for _, stack in ipairs(items) do
        local name = stack:get_name()
        if not consolidated[name] then
            consolidated[name] = stack
        else
            -- Check if compatible (metadata, etc - simple check for now)
            if consolidated[name]:get_free_space() > 0 then
                -- This is a simple merge. A more robust one might be needed for intricate metadata.
                -- For now, let's just use a temporary inventory to stack everything cleanly.
                local temp_inv = minetest.create_detached_inventory("temp_sorter", {
                    allow_move = function() return 0 end,
                    allow_put = function() return 0 end,
                    allow_take = function() return 0 end,
                })
                temp_inv:set_size("main", size)
                temp_inv:add_item("main", consolidated[name])
                temp_inv:add_item("main", stack)
                -- Re-read the stack(s) - might be split if max stack size reached
                local list = temp_inv:get_list("main")
                consolidated[name] = list[1] -- Keep the first full/partial stack
                -- If there are leftovers (overflow), we need to handle them.
                -- A simple consolidated table isn't enough for overflows.
            end
        end
    end

    -- Simpler approach:
    -- 1. Create a list of all itemstrings.
    -- 2. Sort the list by name.
    -- 3. Clear inventory.
    -- 4. Add items back in sorted order. Minetest's add_item handles stacking.

    table.sort(items, function(a, b)
        local name_a = a:get_name()
        local name_b = b:get_name()
        if name_a == name_b then
            return a:get_count() > b:get_count() -- Sort same items by count descending
        end
        return name_a < name_b
    end)

    -- Re-populate
    for _, stack in ipairs(items) do
        inv:add_item("main", stack)
    end
end
