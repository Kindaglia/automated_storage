core.register_craft({
    output = "automated_chest:chest",
    recipe = {
        { "group:wood", "group:wood",       "group:wood" },
        { "group:wood", "mcl_chests:chest", "group:wood" },
        { "group:wood", "group:wood",       "group:wood" },
    }
})

core.register_craft({
    output = "automated_chest:chest_crafting",
    recipe = {
        { "mcl_crafting_table:crafting_table" },
        { "automated_chest:chest" },
    }
})
