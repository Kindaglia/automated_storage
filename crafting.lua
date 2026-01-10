minetest.register_craft({
    output = "automated_chest:chest",
    recipe = {
        { "group:wood", "group:wood",       "group:wood" },
        { "group:wood", "mcl_chests:chest", "group:wood" },
        { "group:wood", "group:wood",       "group:wood" },
    }
})
