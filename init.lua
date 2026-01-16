-- Automated Chest Mod
-- Author: Kindaglia
-- License: See LICENSE

-- Define global mod namespace
automated_chest = {}

local mod_path = core.get_modpath("automated_chest")

local function load_file(filename)
    local f = loadfile(mod_path .. "/" .. filename)
    if f then
        f()
    else
        core.log("error", "[automated_chest] Failed to load " .. filename)
    end
end

-- Load components
load_file("functions.lua") -- Core logic and inventory handling
load_file("gui.lua")       -- Formspec and UI handling
load_file("nodes.lua")     -- Node definitions
load_file("crafting.lua")  -- Crafting recipes

core.log("action", "[automated_chest] Mod loaded successfully")
