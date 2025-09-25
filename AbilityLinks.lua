-- AbilityLinks.lua - Contains the ability database structure

-- Ensure TWRA namespace exists
TWRA = TWRA or {}

-- Initialize empty lookup tables
TWRA.ABILITY_ID_LOOKUP = {}
TWRA.ABILITY_NAME_LOOKUP = {}

-- Ability database following the new format described in the docs
TWRA.ABILITY_DATABASE = {
    ["Arcane Prison#12345"] = {
        {0.5, 0, 1, "Arcane Prison"}, -- Title with purple color
        {1, 1, 1, "100 yd range", 0, 1, 0, "Instant"}, -- Range and cast time
        "", -- Empty line for spacing
        {1, 1, 1, "Stuns the target, dealing 1200 damage", 
                 "and draining 500 mana per sec for 10 sec."}, -- Description lines with same color
        "", -- Empty line for spacing
        {0.8, 0.8, 1, "School: Arcane"}, -- School info
        {0.2, 0.6, 1, "Dispel Type: Magic"}, -- Dispel type info
        icon = "Interface\\Icons\\Spell_Arcane_PrismaticCloak"
    },
    
    -- More abilities would be added here
}
