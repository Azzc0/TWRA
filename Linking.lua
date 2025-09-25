-- Linking.lua - Functions for working with ability links

-- Ensure TWRA namespace exists
TWRA = TWRA or {}
TWRA.Abilities = TWRA.Abilities or {}

-- Initialize lookup tables for abilities
function TWRA.Abilities:InitializeLookups()
    -- Clear existing lookups
    TWRA.ABILITY_ID_LOOKUP = {}
    TWRA.ABILITY_NAME_LOOKUP = {}
    
    -- Populate the lookups using string.find and string.sub instead of string.match
    for key, _ in pairs(TWRA.ABILITY_DATABASE) do
        local hashPos = string.find(key, "#")
        if hashPos then
            local name = string.sub(key, 1, hashPos - 1)
            local id = string.sub(key, hashPos + 1)
            TWRA.ABILITY_ID_LOOKUP[id] = name
            TWRA.ABILITY_NAME_LOOKUP[name] = id
        end
    end
end

-- Helper function to get an ability key from name and ID
function TWRA.Abilities:GetAbilityKey(abilityName, abilityID)
    return abilityName .. "#" .. abilityID
end

-- Get a proper ability link for the given ability name using our custom format
function TWRA.Abilities:GetLinkByName(abilityName)
    local abilityID = TWRA.ABILITY_NAME_LOOKUP[abilityName]
    if not abilityID then return abilityName end
    
    -- Format the link with custom TWRA protocol
    local link = "|cffA335ED|Htwra:ability:" .. abilityID .. "|h[" .. abilityName .. "]|h|r"
    return link
end

-- Process text to replace ability name patterns with custom twra links
function TWRA.Abilities:ProcessText(text)
    if not text then return "" end
    
    -- Use string.gsub with pattern matching instead of string.match
    local result = text
    local startPos, endPos = 1, 0
    
    -- Find patterns like [Ability Name] and replace with links
    while true do
        local s, e = string.find(result, "%[.-%]", startPos)
        if not s then break end
        
        local abilityName = string.sub(result, s + 1, e - 1)
        local abilityLink = self:GetLinkByName(abilityName)
        
        -- Replace the bracketed text with the link
        local before = string.sub(result, 1, s - 1)
        local after = string.sub(result, e + 1)
        result = before .. abilityLink .. after
        
        startPos = s + string.len(abilityLink)
    end
    
    return result
end

-- Register for events
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, addon)
    if addon == "TWRA" then
        TWRA.Abilities:InitializeLookups()
    end
end)
