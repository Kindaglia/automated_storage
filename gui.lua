local S = minetest.get_translator("automated_chest")
local F = minetest.formspec_escape

function automated_chest.show_chest_formspec(player, pos, query)
    local player_name = player:get_player_name()
    local spos = pos.x .. "," .. pos.y .. "," .. pos.z

    -- Save state
    automated_chest.player_search_state[player_name] = {
        pos = pos,
        query = query,
        refresh_func = function(p, po, q)
            -- Only refresh if the user is still looking at this formspec
            automated_chest.show_chest_formspec(p, po, q)
        end
    }

    local is_filtered = query and query ~= ""
    -- Fix: Use explicit nodemeta syntax instead of 'context' which only works for node-triggered formspecs
    local list_name = "nodemeta:" .. spos
    local list_loc = list_name

    -- Get actual inventory size
    local node_meta = minetest.get_meta(pos)
    local inv = node_meta:get_inventory()
    local inv_size = inv:get_size("main")

    -- Calculate rows
    local rows_total = math.ceil(inv_size / 9)
    if is_filtered then
        local size = automated_chest.update_filtered_view(player, pos, query)
        rows_total = math.ceil(size / 9)
        list_name = "detached:automated_chest_filter_" .. player_name
        list_loc = list_name -- For listring
    end

    -- Formspec dimensions
    local width = 22.5
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



    -- Crafting Positions

    local craft_x = 13.5

    local craft_y = 0.75

    local grid_width = 3 * 1.25                 -- 3.75

    local arrow_x = craft_x + grid_width + 0.25 -- 17.5

    local arrow_y = craft_y + 1.375             -- 2.125 (Centered)

    local result_x = arrow_x + 1.0 + 0.25       -- 18.75

    local result_y = craft_y + 1.25             -- 2.0



    -- Ensure background covers at least visible area or total rows if smaller (unlikely with min size logic)

    local bg_rows = math.max(rows_visible, rows_total)



    local formspec = table.concat({

        "formspec_version[4]",

        "size[", width, ",", height, "]",



        "label[", padding, ",", padding, ";", F(S("Automated Chest")), "]",



        -- Search Bar (Aligned with Craft Grid)

        "field[", craft_x, ",", 0.1, ";4.0,0.6;search;;", F(query or ""), "]",

        "field_close_on_enter[search;false]",



        -- Sort Button (Right Aligned)

        "button[", (width - 1.75 - padding), ",", 0.1, ";1.75,0.6;sort;", F(S("Sort")), "]",



        -- Scroll Container

        "scroll_container[", inv_x, ",", inv_y, ";", (cols * slot_size), ",", scroll_height, ";scroll;vertical;1.25]",

        -- Content

        mcl_formspec.get_itemslot_bg_v4(0, 0, cols, bg_rows),

        "list[", list_name, ";main;0,0;", cols, ",", bg_rows, ";]",

        "scroll_container_end[]",



        -- Scrollbar

        "scrollbaroptions[min=0;max=", math.max(0, rows_total - rows_visible), ";smallstep=1;largestep=1;arrows=on]",
        "scrollbar[", scrollbar_x, ",", inv_y, ";0.75,", scroll_height, ";vertical;scroll;0]",

        -- Crafting UI
        "label[", craft_x, ",", padding, ";", F(S("Crafting")), "]",

        -- Craft Grid
        mcl_formspec.get_itemslot_bg_v4(craft_x, craft_y, 3, 3),
        "list[nodemeta:", spos, ";craft;", craft_x, ",", craft_y, ";3,3;]",

        -- Tools Column
        -- Recipe Book
        "item_image_button[", arrow_x, ",", (craft_y + 0.125), ";1,1;mcl_books:book;recipe_book;]",
        "tooltip[recipe_book;", F(S("Recipe Book")), "]",

        -- Arrow
        "image[", arrow_x, ",", arrow_y, ";1,1;gui_crafting_arrow.png]",

        -- Refill Button
        "image_button[", arrow_x, ",", (arrow_y + 1.25), ";1,1;mcl_crafting_table_inv_fill.png;refill;]",
        "tooltip[refill;", F(S("Refill from Chest")), "]",

        -- Craft Result
        mcl_formspec.get_itemslot_bg_v4(result_x, result_y, 1, 1),
        "list[nodemeta:", spos, ";craftresult;", result_x, ",", result_y, ";1,1;]",

        -- Player Inventory Label
        "label[", padding, ",", (player_inv_y - 0.4), ";", F(S("Inventory")), "]",

        -- Player Inventory
        mcl_formspec.get_itemslot_bg_v4(inv_x, player_inv_y, 9, 3),
        "list[current_player;main;", inv_x, ",", player_inv_y, ";9,3;9]",

        -- Player Hotbar
        mcl_formspec.get_itemslot_bg_v4(inv_x, hotbar_y, 9, 1),
        "list[current_player;main;", inv_x, ",", hotbar_y, ";9,1;]",

        -- Listrings (Prioritize Player -> Chest)
        "listring[nodemeta:", spos, ";craft]",
        "listring[current_player;main]",
        "listring[", list_loc, ";main]",
        "listring[current_player;main]",
        "listring[nodemeta:", spos, ";craftresult]",
        "listring[current_player;main]",
    })
    minetest.show_formspec(player_name, "automated_chest:chest_fs", formspec)
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= "automated_chest:chest_fs" then return end

    local state = automated_chest.player_search_state[player:get_player_name()]
    if not state then return end

    -- Handle Search
    if fields.search or (fields.key_enter_field == "search") then
        local query = fields.search or ""
        automated_chest.show_chest_formspec(player, state.pos, query)
    end

    -- Handle Sort
    if fields.sort then
        automated_chest.sort_inventory(state.pos)
        automated_chest.show_chest_formspec(player, state.pos, state.query)
    end

    -- Handle Recipe Book
    if fields.recipe_book then
        if mcl_craftguide and mcl_craftguide.show then
            mcl_craftguide.show(player:get_player_name())
        end
    end

    -- Handle Refill
    if fields.refill then
        automated_chest.refill_craft_grid(state.pos)
        automated_chest.show_chest_formspec(player, state.pos, state.query)
    end
end)
