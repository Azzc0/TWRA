-- Boss Ability database for TWRA
TWRA = TWRA or {}
TWRA.Abilities = TWRA.Abilities or {}

-- Lookup tables for abilities by ID and name
TWRA.ABILITY_ID_LOOKUP = TWRA.ABILITY_ID_LOOKUP or {}
TWRA.ABILITY_NAME_LOOKUP = TWRA.ABILITY_NAME_LOOKUP or {}

-- Database for boss abilities with tooltip info using the new format
-- Format: Each ability entry contains an ordered list for tooltip lines
-- [1] = {r, g, b, "title"} -- Title line (SetText)
-- [2..n] = {r, g, b, "text"} -- Regular line (AddLine)
-- [n] = " " -- Spacer (AddLine with a space)
-- [n] = {r1, g1, b1, "left text", r2, g2, b2, "right text"} -- Double line (AddDoubleLine)
-- ["icon"] = "path/to/icon" -- Icon to add to tooltip
TWRA.ABILITY_DATABASE = {
    ["Boss Ability:1000001"] = {
        [1] = {1, 0.5, 0, "Boss Ability"}, -- Title with orange color
        [2] = " ", -- Spacer
        [3] = {1, 0.82, 0, "Deals X damage per second for 10 seconds."}, -- Description
        [4] = " ", -- Spacer
        [5] = {0.7, 0.7, 0.7, "Ability ID: 1000001"}, -- ID info
        ["icon"] = "Interface\\Icons\\Spell_Shadow_ShadowBolt" -- Icon
    },
    ["Flame Breath:1000002"] = {
        [1] = {1, 0.25, 0, "Flame Breath"}, -- Reddish title
        [2] = " ", -- Spacer
        [3] = {1, 0.82, 0, "Frontal cone attack that deals 2000-3000 fire damage."}, -- Description line 1
        [4] = {1, 0.82, 0, "Affected targets receive a DoT that deals 500 damage every 3 seconds for 12 seconds."}, -- Description line 2
        [5] = " ", -- Spacer
        [6] = {0.7, 0.7, 0.7, "Ability ID: 1000002"}, -- ID info
        ["icon"] = "Interface\\Icons\\Spell_Fire_Fire" -- Icon
    },
    ["Shadow Word: Pain:589"] = {
        [1] = {0.64, 0.21, 0.93, "Shadow Word: Pain"}, -- Epic purple
        [2] = " ", -- Spacer
        [3] = {1, 0.82, 0, "Afflicts the target with pain, causing 350 Shadow damage over 18 sec."}, -- Description
        [4] = " ", -- Spacer
        [5] = {0.7, 0.7, 0.7, "Ability ID: 589"}, -- ID info
        ["icon"] = "Interface\\Icons\\Spell_Shadow_ShadowWordPain" -- Icon
    },
    ["Conflagrate:17962"] = {
        [1] = {1, 0.25, 0, "Conflagrate"}, -- Reddish title
        [2] = " ", -- Spacer
        [3] = {1, 0.82, 0, "Burns the target for 4000 Fire damage over 10 seconds."}, -- Description line 1
        [4] = {1, 0.82, 0, "Can be dispelled."}, -- Description line 2
        [5] = " ", -- Spacer
        [6] = {0.7, 0.7, 0.7, "Ability ID: 17962"}, -- ID info
        ["icon"] = "Interface\\Icons\\Spell_Fire_Fireball" -- Icon
    },
    ["Void Zone:28865"] = {
        [1] = {0.5, 0, 1, "Void Zone"}, -- Purple title
        [2] = " ", -- Spacer
        [3] = {1, 0.82, 0, "Creates a void zone that deals 1000 shadow damage per second to anyone standing in it."}, -- Description line 1
        [4] = {1, 0.82, 0, "Lasts 45 seconds."}, -- Description line 2
        [5] = " ", -- Spacer
        [6] = {0.7, 0.7, 0.7, "Ability ID: 28865"}, -- ID info
        ["icon"] = "Interface\\Icons\\Spell_Shadow_SummonVoidWalker" -- Icon
    },
    ["Arcane Prison:51107"] = {
        [1] = {0.44, 0.83, 1, "Arcane Prison"}, -- Arcane blue title
        [2] = " ", -- Spacer
        [3] = {1, 0.82, 0, "Immobilizes the target in an arcane prison for 10 sec."}, -- Description line 1
        [4] = {1, 0.82, 0, "Cannot be dispelled."}, -- Description line 2 
        [5] = " ", -- Spacer
        [6] = {0.7, 0.7, 0.7, "Ability ID: 51107"}, -- ID info
        ["icon"] = "Interface\\Icons\\Spell_Nature_StrangleVines" -- Icon
    },
    ["Arcane Prison:12345"] = {
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
    ["Fire Blast:23456"] = {
        {1, 0.3, 0, "Fire Blast"}, -- Title with fiery color
        {1, 1, 1, "40 yd range", 0, 1, 0, "Instant"}, -- Range and cast time
        "", -- Empty line for spacing
        {1, 1, 1, "Deals 2000 fire damage to the target and all enemies within 10 yards."}, -- Description
        "", -- Empty line for spacing
        {1, 0.5, 0, "School: Fire"}, -- School info
        icon = "Interface\\Icons\\Spell_Fire_Fireball"
    }
}

-- Debug function to initialize and test the ability database
function TWRA:InitializeAbilityDatabase()
    -- Initialize lookup tables from the database
    TWRA.ABILITY_NAME_LOOKUP = {}
    TWRA.ABILITY_ID_LOOKUP = {}
    
    -- Direct debug output to chat
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000TWRA:|r Initializing ability database...")
    
    -- Populate lookup tables
    for key, _ in pairs(TWRA.ABILITY_DATABASE) do
        local name, id = TWRA.SafeHelpers.ExtractNameAndID(key)
        if name and id then
            TWRA.ABILITY_NAME_LOOKUP[name] = id
            TWRA.ABILITY_ID_LOOKUP[id] = name
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000TWRA:|r Added lookup for " .. name .. " with ID " .. id)
        end
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000TWRA:|r Ability database initialized.")
    return true
end

-- Debug function to list all abilities in the database
function TWRA:ListAbilityDatabase()
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000TWRA:|r Listing all abilities in database:")
    local count = 0
    for key, _ in pairs(TWRA.ABILITY_DATABASE) do
        count = count + 1
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000TWRA:|r " .. count .. ". " .. key)
    end
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000TWRA:|r Total abilities: " .. count)
    return count
end

-- Debug function to add direct ability lookup
function TWRA:GetAbilityTooltip(key)
    if not TWRA.ABILITY_DATABASE then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000TWRA:|r ABILITY_DATABASE is nil!")
        return
    end
    
    local tooltipData = TWRA.ABILITY_DATABASE[key]
    if not tooltipData then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000TWRA:|r No tooltip data found for key: " .. key)
        return
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000TWRA:|r Found tooltip data for: " .. key)
    return tooltipData
end

-- Register for addon loaded event to initialize database
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, addon)
    if addon == "TWRA" then
        TWRA:InitializeAbilityDatabase()
        TWRA:ListAbilityDatabase() -- Debug listing of abilities
    end
end)

-- Update ExtractNameAndID function to use colon instead of pipe
function TWRA.SafeHelpers.ExtractNameAndID(input)
    if not input then return nil, nil end
    
    local colonPos = nil
    for i = 1, string.len(input) do
        local c = string.sub(input, i, i)
        if c == ":" then
            colonPos = i
            break
        end
    end
    
    if not colonPos then
        -- No colon found, return the whole input as the name
        return input, nil
    end
    
    local name = string.sub(input, 1, colonPos - 1)
    local id = string.sub(input, colonPos + 1)
    
    -- Check if ID is numeric
    local isNumeric = true
    for i = 1, string.len(id) do
        local c = string.sub(id, i, i)
        if c < "0" or c > "9" then
            isNumeric = false
            break
        end
    end
    
    if isNumeric and string.len(id) > 0 then
        return name, id
    else
        return input, nil
    end
end