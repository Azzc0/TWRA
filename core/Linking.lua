-- TWRA Unified Linking System
-- Handles both item links and ability links in a consistent manner

TWRA = TWRA or {}
TWRA.Links = TWRA.Links or {}
TWRA.Items = TWRA.Items or {}
TWRA.Abilities = TWRA.Abilities or {} -- Initialize the Abilities table

-- Safe string pattern matching helpers that don't rely on the string library
TWRA.SafeHelpers = TWRA.SafeHelpers or {}

-- Safe string find function that doesn't rely on string.find
function TWRA.SafeHelpers.Find(str, pattern)
    if not str or not pattern then return nil end
    
    -- Basic implementation for specific patterns we need
    if pattern == "|Htwra:" then
        for i = 1, string.len(str) - 6 do
            if string.sub(str, i, i + 6) == "|Htwra:" then
                return i
            end
        end
        return nil
    elseif pattern == "|Hitem:" then
        for i = 1, string.len(str) - 7 do
            if string.sub(str, i, i + 7) == "|Hitem:" then
                return i
            end
        end
        return nil
    end
    
    -- Fallback to standard find if available
    if string and string.find then
        return string.find(str, pattern)
    end
    
    return nil
end

-- Safe split function to extract parts
function TWRA.SafeHelpers.SplitByChar(str, char)
    if not str or not char then return nil end
    
    local result = {}
    local current = ""
    
    for i = 1, string.len(str) do
        local c = string.sub(str, i, i)
        if c == char then
            table.insert(result, current)
            current = ""
        else
            current = current .. c
        end
    end
    
    table.insert(result, current)
    return result
end

-- Safe function to extract ability name and ID from format "Name|ID"
function TWRA.SafeHelpers.ExtractNameAndID(input)
    if not input then return nil, nil end
    
    local pipePos = nil
    for i = 1, string.len(input) do
        local c = string.sub(input, i, i)
        if c == "|" then
            pipePos = i
            break
        end
    end
    
    if not pipePos then
        -- No pipe found, return the whole input as the name
        return input, nil
    end
    
    local name = string.sub(input, 1, pipePos - 1)
    local id = string.sub(input, pipePos + 1)
    
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

-- Safe function to extract parts from a link pattern
function TWRA.SafeHelpers.ExtractLinkParts(link)
    if not link or string.len(link) == 0 then return nil, nil end
    
    -- Find the first colon
    local colonPos = nil
    for i = 1, string.len(link) do
        local c = string.sub(link, i, i)
        if c == ":" then
            colonPos = i
            break
        end
    end
    
    if not colonPos then
        return nil, nil
    end
    
    local linkType = string.sub(link, 1, colonPos - 1)
    local linkData = string.sub(link, colonPos + 1)
    
    return linkType, linkData
end

-- Add a helper function to count table elements safely
function TWRA.SafeHelpers.CountTableElements(tbl)
    if not tbl or type(tbl) ~= "table" then return 0 end
    
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end

-- Initialize the linking system
function TWRA:InitializeLinks()
    -- Set up a lookup table of registered link handlers
    self.Links.handlers = {
        ["item"] = self.Items,      -- Standard WoW item links
        ["twra"] = self.Abilities   -- Short format for ability links (was "twraability")
    }

    self:Debug("links", "Unified linking system initialized")
    return true
end

-- Create a custom link with consistent formatting
function TWRA.Links:CreateLink(linkType, linkData, displayText, colorHex)
    if not linkType or not linkData or not displayText then
        TWRA:Debug("links", "CreateLink called with missing parameters")
        return displayText
    end
    
    -- Default color if not provided
    colorHex = colorHex or "ffffff"
    
    -- Sanitize inputs to prevent issues
    linkType = TWRA:SafeToString(linkType)
    linkData = TWRA:SafeToString(linkData)
    displayText = TWRA:SafeToString(displayText)
    
    -- Create and return the link
    return "|cff" .. colorHex .. "|H" .. linkType .. ":" .. linkData .. "|h[" .. displayText .. "]|h|r"
end

-- Process text to convert all known link formats
function TWRA.Links:ProcessAllLinks(text)
    if not text then return "" end
    
    -- Ensure text is a string
    if type(text) == "table" then
        TWRA:Debug("error", "ProcessAllLinks received a table instead of a string")
        return TWRA:SafeToString(text)
    end
    
    -- Skip if the text already contains ability links
    if TWRA.SafeHelpers.Find(text, "|Htwra:") then
        TWRA:Debug("links", "Text already contains ability links, preserving as-is")
        return text
    end

    -- First, try to process with the ability processor
    local result = text
    if TWRA.Abilities and TWRA.Abilities.ProcessText then
        result = TWRA.Abilities:ProcessText(result)
        TWRA:Debug("links", "Processed text with ability linker")
    end

    -- Then, process with the item processor
    -- Note that item processor should respect existing ability links
    if TWRA.Items and TWRA.Items.ProcessText then
        result = TWRA.Items:ProcessText(result)
        TWRA:Debug("links", "Processed text with item linker")
    end

    -- If we have a ProcessConsumables function, use it too
    if TWRA.Items and TWRA.Items.ProcessConsumables then
        result = TWRA.Items:ProcessConsumables(result)
        TWRA:Debug("links", "Processed text for consumables")
    end

    return result
end

-- Handle click on a link
function TWRA.Links:HandleLinkClick(linkType, linkData, button)
    -- Check if we have a registered handler for this link type
    local handler = self.handlers[linkType]
    if handler and handler.HandleLink then
        return handler:HandleLink(linkData, button)
    else
        TWRA:Debug("links", "No handler found for link type: " .. linkType)
        return false
    end
end

-- Hook the SetItemRef function to handle our custom links
function TWRA.Links:DisableLinkHook()
    -- This implementation is disabled - we now use the focused implementation in LinkClickHandler.lua
    TWRA:Debug("links", "SetItemRef hook in Linking.lua is disabled - using LinkClickHandler.lua instead")
    return true
end

-- Instead of hooking, just initialize the link system
if not TWRA.linksInitialized then
    TWRA:InitializeLinks()
    TWRA.linksInitialized = true
    TWRA:Debug("links", "Link system initialized without hooking SetItemRef")
end

-- ===============================
-- Item Link Functions 
-- ===============================

-- Get a proper item link for the given item name
function TWRA.Items:GetLinkByName(itemName)
    if not itemName then return nil end
    
    local itemData = TWRA.ITEM_DATABASE[itemName]
    if not itemData then 
        -- Use SafeToString to handle the case where itemName might be a table
        TWRA:Debug("items", "Item not found in database: " .. TWRA:SafeToString(itemName))
        return nil
    end
    
    -- Get the item's color based on quality
    local colorHex = TWRA.ITEM_QUALITY_COLORS[itemData.quality] or TWRA.ITEM_QUALITY_COLORS["Common"]
    
    -- Create a proper WoW item link format that will be clickable in chat
    -- Format should be: |cCOLOR|Hitem:ID:0:0:0:0:0:0:0|h[NAME]|h|r
    return "|cff" .. colorHex .. "|Hitem:" .. itemData.id .. ":0:0:0:0:0:0:0|h[" .. TWRA:SafeToString(itemName) .. "]|h|r"
end

-- Process text to replace item name patterns with item links
function TWRA.Items:ProcessText(text)
    -- Use SafeToString to handle the case where text might be a table
    if not text then return "" end
    
    -- Convert text to string if it's a table
    if type(text) == "table" then
        TWRA:Debug("error", "ProcessText received a table instead of a string")
        return TWRA:SafeToString(text)
    end
    
    -- IMPORTANT FIX: First check if the text already contains item links (|Hitem:)
    -- If it does, don't try to process further to avoid breaking existing links
    if TWRA.SafeHelpers.Find(text, "|Hitem:") then
        TWRA:Debug("items", "Text already contains item links, preserving as-is")
        return text
    end
    
    -- Skip processing square brackets if text already contains ability links
    if not TWRA.SafeHelpers.Find(text, "|Htwra:") then
        -- Look for [ItemName] patterns and replace with links
        text = string.gsub(text, "%[([^%]]+)%]", function(itemName)
            -- First check if this is an ability
            if TWRA.Abilities and TWRA.ABILITY_DATABASE and TWRA.ABILITY_DATABASE[itemName] then
                -- Let the ability processor handle this
                return "[" .. TWRA:SafeToString(itemName) .. "]"
            end
            
            -- Process as an item link
            local link = self:GetLinkByName(itemName)
            if link then
                return link
            else
                -- Keep the original bracketed text if no item found
                return "[" .. TWRA:SafeToString(itemName) .. "]"
            end
        end)
    end
            
    -- Also process plain text items that don't have brackets
    for itemName, _ in pairs(TWRA.ITEM_DATABASE or {}) do
        -- Avoid replacing text that's already part of a link
        -- Look for the item name with word boundaries (not within other words)
        local pattern = "([^|])(" .. itemName .. ")([^%]|])"
        text = string.gsub(text, pattern, function(prefix, matched, suffix)
            local link = self:GetLinkByName(matched)
            if link then
                return prefix .. link .. suffix
            else
                return prefix .. matched .. suffix
            end
        end)
    end

    return text
end

-- Helper function to convert specific potion/consumable names in a message
function TWRA.Items:ProcessConsumables(text)
    if not text then return text end
    
    -- For safety: convert tables to strings to prevent errors
    if type(text) == "table" then
        TWRA:Debug("error", "ProcessConsumables received a table instead of a string")
        return TWRA:SafeToString(text)
    end
    
    -- Common consumables that might appear in raid instructions
    local consumables = {
        ["fire prot"] = "Greater Fire Protection Potion",
        ["fire protection"] = "Greater Fire Protection Potion",
        ["nature prot"] = "Greater Nature Protection Potion",
        ["nature protection"] = "Greater Nature Protection Potion",
        ["shadow prot"] = "Greater Shadow Protection Potion",
        ["shadow protection"] = "Greater Shadow Protection Potion",
        ["frost prot"] = "Greater Frost Protection Potion",
        ["frost protection"] = "Greater Frost Protection Potion",
        ["arcane prot"] = "Greater Arcane Protection Potion",
        ["arcane protection"] = "Greater Arcane Protection Potion",
        ["poison resist"] = "Elixir of Poison Resistance",
        ["poison resistance"] = "Elixir of Poison Resistance"
    }
    
    -- Replace common abbreviations with full item links
    for shortName, fullName in pairs(consumables) do
        local pattern = "([^|])(" .. shortName .. ")([^%]|])"
        text = string.gsub(text, pattern, function(prefix, matched, suffix)
            local link = self:GetLinkByName(fullName)
            if link then
                return prefix .. link .. suffix
            else
                return prefix .. matched .. suffix
            end
        end)
    end

    return text
end

-- ===============================
-- Ability Tooltip Functions
-- ===============================

-- Display a tooltip for an ability using the new ABILITY_DATABASE structure
function TWRA.Abilities:DisplayAbilityTooltip(abilityNameWithID)
    if not abilityNameWithID or not TWRA.ABILITY_DATABASE then
        return false
    end
    
    local abilityData = TWRA.ABILITY_DATABASE[abilityNameWithID]
    if not abilityData then
        TWRA:Debug("abilities", "Ability not found in database: " .. TWRA:SafeToString(abilityNameWithID))
        return false
    end
    
    -- Clear existing tooltip content
    ItemRefTooltip:ClearLines()
    ItemRefTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE")
    
    -- Process each line according to its type
    for i = 1, 20 do  -- Arbitrary limit to prevent infinite loops
        local lineData = abilityData[i]
        if not lineData then break end
        
        if type(lineData) == "string" then
            -- Simple string entry - treat as a spacer
            ItemRefTooltip:AddLine(lineData)
        elseif type(lineData) == "table" then
            if TWRA.SafeHelpers.CountTableElements(lineData) == 4 then
                -- Single line: {r, g, b, "text"}
                if i == 1 then
                    -- First line is the title
                    ItemRefTooltip:SetText(lineData[4], lineData[1], lineData[2], lineData[3])
                else
                    -- Regular line
                    ItemRefTooltip:AddLine(lineData[4], lineData[1], lineData[2], lineData[3])
                end
            elseif TWRA.SafeHelpers.CountTableElements(lineData) == 8 then
                -- Double line: {r1, g1, b1, "left text", r2, g2, b2, "right text"}
                ItemRefTooltip:AddDoubleLine(lineData[4], lineData[8], lineData[1], lineData[2], lineData[3], lineData[5], lineData[6], lineData[7])
            else
                TWRA:Debug("abilities", "Invalid line data format in ability tooltip")
            end
        end
    end
    
    -- Add the icon if specified
    if abilityData["icon"] then
        ItemRefTooltip:AddTexture(abilityData["icon"])
    end
    
    -- Show the updated tooltip
    ItemRefTooltip:Show()
    return true
end

-- Handle link clicks (called when a player clicks on one of our ability links)
function TWRA.Abilities:HandleLink(linkData, button)
    -- Extract ability name and ID from the link data using our safe functions
    local abilityName, spellID = linkData, nil
    local colonPos = string.find(linkData or "", ":")
    
    -- If we found a colon, split the name and ID parts
    if colonPos then
        abilityName = string.sub(linkData, 1, colonPos - 1)
        spellID = string.sub(linkData, colonPos + 1)
        
        -- Make sure the ID part is actually numeric
        if spellID and spellID ~= "" then
            local isNumeric = true
            for i = 1, string.len(spellID) do
                local char = string.sub(spellID, i, i)
                if char < "0" or char > "9" then
                    isNumeric = false
                    break
                end
            end
            if not isNumeric then
                spellID = nil
            end
        else
            spellID = nil
        end
    end
    
    -- If spell ID was provided, check if we have this spell
    if spellID then
        local lookupName = TWRA.ABILITY_ID_LOOKUP[spellID]
        if lookupName then
            -- We found the ability by ID
            abilityName = lookupName
        else
            -- We don't have this specific ID in our database
            TWRA:Debug("abilities", "Spell ID not found in database: " .. spellID)
            -- Continue with the name portion, it might exist without the ID
        end
    end
    
    local abilityData = TWRA.ABILITY_DATABASE[abilityName]
    if not abilityData then 
        TWRA:Debug("abilities", "Ability not found in database: " .. TWRA:SafeToString(abilityName))
        return nil
    end
    
    -- Use the specified color or default to arcane blue
    local colorHex = abilityData.color or "71d5ff"
    
    -- Store the ability ID in the link data (either from database or provided)
    local finalId = spellID or abilityData.id or "1"
    
    -- Format the link using the unified linking system
    return self:CreateLink("twra", abilityName .. ":" .. finalId, abilityName, colorHex)
end

-- Get a link for a boss ability by name and optional ID
function TWRA.Links:GetAbilityLink(input)
    if not input then return nil end
    
    -- Check if the input contains a spell ID using string.find instead of string.match
    local abilityName, spellID = input, nil
    local colonPos = string.find(input, ":")
    
    -- If we found a colon, split the name and ID parts
    if colonPos then
        abilityName = string.sub(input, 1, colonPos - 1)
        spellID = string.sub(input, colonPos + 1)
        
        -- Make sure the ID part is actually numeric
        if spellID and spellID ~= "" then
            local isNumeric = true
            for i = 1, string.len(spellID) do
                local char = string.sub(spellID, i, i)
                if char < "0" or char > "9" then
                    isNumeric = false
                    break
                end
            end
            
            if not isNumeric then
                abilityName = input
                spellID = nil
            end
        else
            spellID = nil
        end
    end
    
    -- If spell ID was provided, check if we have this spell
    if spellID then
        local lookupName = TWRA.ABILITY_ID_LOOKUP[spellID]
        if lookupName then
            -- We found the ability by ID
            abilityName = lookupName
        else
            -- We don't have this specific ID in our database
            TWRA:Debug("abilities", "Spell ID not found in database: " .. spellID)
            -- Continue with the name portion, it might exist without the ID
        end
    end
    
    -- Construct the ability key for database lookup
    local abilityKey = abilityName
    if spellID then
        abilityKey = abilityName .. ":" .. spellID
    end
    
    local abilityData = TWRA.ABILITY_DATABASE[abilityKey]
    if not abilityData then 
        TWRA:Debug("abilities", "Ability not found in database: " .. TWRA:SafeToString(abilityName))
        return nil 
    end
    
    -- Use the TWRA:FormatAbilityLink function from LinkClickHandler to format the link
    if TWRA.FormatAbilityLink then
        return TWRA:FormatAbilityLink(abilityName, spellID or abilityData.id)
    else
        -- Fallback to old method if FormatAbilityLink isn't available
        -- Use the specified color or default to arcane blue
        local colorHex = abilityData.color or "71d5ff"
        
        -- Store the ability ID in the link data (either from database or provided)
        local finalId = spellID or abilityData.id or "1"
        
        -- Format the link using the unified linking system
        return self:CreateLink("twra", abilityName .. ":" .. finalId, abilityName, colorHex)
    end
end

-- Function to get the ability key from name and ID
function TWRA.Abilities:GetAbilityKey(abilityName, abilityID)
    if not abilityName then return nil end
    
    -- If ID is provided, try constructing the key with it
    if abilityID then
        local key = abilityName .. "|" .. abilityID
        if TWRA.ABILITY_DATABASE[key] then
            return key
        end
    end
    
    -- If no key was found with the ID, check if the name exists directly
    if TWRA.ABILITY_DATABASE[abilityName] then
        return abilityName
    end
    
    -- Try to find ability by name in lookup table
    if TWRA.ABILITY_NAME_LOOKUP and TWRA.ABILITY_NAME_LOOKUP[abilityName] then
        local id = TWRA.ABILITY_NAME_LOOKUP[abilityName]
        local key = abilityName .. "|" .. id
        if TWRA.ABILITY_DATABASE[key] then
            return key
        end
    end
    
    return nil
end

-- Initialize the linking system when the addon loads
if not TWRA.linksInitialized then
    TWRA:InitializeLinks()
    TWRA.linksInitialized = true
    TWRA:Debug("items", "Item linking system initialized")
end