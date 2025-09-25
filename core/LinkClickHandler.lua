-- TWRA Link Click Handler with ability database integration
-- Uses direct tooltip manipulation based on database entries

TWRA = TWRA or {}

-- Store the original function reference
local originalSetItemRef = SetItemRef

-- Format ability links to hide spell IDs in the displayed text
function TWRA:FormatAbilityLink(abilityName, abilityID)
    -- Always use the name without ID for display
    local displayText = abilityName
    
    -- But keep the ID in the actual link data for proper identification
    local linkData = "twra:" .. abilityName .. ":" .. (abilityID or "0")
    
    -- Use the standard ability color (light blue) for display
    local colorHex = "71d5ff" -- Light blue color for abilities
    
    -- Format the link with hidden ID but properly colored
    return "|cff" .. colorHex .. "|H" .. linkData .. "|h[" .. displayText .. "]|h|r"
end

-- Helper function to detect if text is an item link
function TWRA:IsItemLink(text)
    -- Check for standard item link pattern - the pattern needs to match the full colored item links
    return text and type(text) == "string" and string.find(text, "|c%x+|Hitem:[^|]+|h%[[^%]]+%]|h|r") ~= nil
end

-- Process text to replace ability name patterns with ability links
function TWRA:ProcessTextForAbilityLinks(text)
    if not text or type(text) ~= "string" then
        return text or ""
    end
    
    -- For mixed content with item links, we need to process each part separately
    local result = ""
    local lastPos = 1
    local itemStart, itemEnd = string.find(text, "|c%x+|Hitem:[^|]+|h%[[^%]]+%]|h|r", lastPos)
    
    -- If no item links found, just process the whole text
    if not itemStart then
        -- Look for [AbilityName] patterns
        text = string.gsub(text, "%[([^%]:]+)%]", function(abilityName)
            -- Skip if this is part of an existing link
            if string.find(abilityName, "|H") then
                return "[" .. abilityName .. "]"
            end
            -- Simple ability name without ID
            return "|cff71d5ff|Htwra:" .. abilityName .. ":0|h[" .. abilityName .. "]|h|r"
        end)
        
        -- Look for [AbilityName:ID] patterns and replace with [AbilityName] visually
        text = string.gsub(text, "%[([^%]]+):(%d+)%]", function(abilityName, abilityID)
            -- Skip if this is part of an existing link
            if string.find(abilityName, "|H") then
                return "[" .. abilityName .. ":" .. abilityID .. "]"
            end
            return "|cff71d5ff|Htwra:" .. abilityName .. ":" .. abilityID .. "|h[" .. abilityName .. "]|h|r"
        end)
        
        return text
    end
    
    -- Process text with item links - split into segments
    while itemStart do
        -- Process text before the item link
        local beforeItem = string.sub(text, lastPos, itemStart - 1)
        beforeItem = string.gsub(beforeItem, "%[([^%]:]+)%]", function(abilityName)
            -- Skip if this is part of an existing link
            if string.find(abilityName, "|H") then
                return "[" .. abilityName .. "]"
            end
            -- Simple ability name without ID
            return "|cff71d5ff|Htwra:" .. abilityName .. ":0|h[" .. abilityName .. "]|h|r"
        end)
        
        beforeItem = string.gsub(beforeItem, "%[([^%]]+):(%d+)%]", function(abilityName, abilityID)
            -- Skip if this is part of an existing link
            if string.find(abilityName, "|H") then
                return "[" .. abilityName .. ":" .. abilityID .. "]"
            end
            return "|cff71d5ff|Htwra:" .. abilityName .. ":" .. abilityID .. "|h[" .. abilityName .. "]|h|r"
        end)
        
        -- Add the processed text before the item and the item itself
        result = result .. beforeItem .. string.sub(text, itemStart, itemEnd)
        
        -- Move past this item link
        lastPos = itemEnd + 1
        
        -- Look for next item link
        itemStart, itemEnd = string.find(text, "|c%x+|Hitem:[^|]+|h%[[^%]]+%]|h|r", lastPos)
    end
    
    -- Process any remaining text after the last item link
    if lastPos <= string.len(text) then
        local afterItems = string.sub(text, lastPos)
        afterItems = string.gsub(afterItems, "%[([^%]:]+)%]", function(abilityName)
            -- Skip if this is part of an existing link
            if string.find(abilityName, "|H") then
                return "[" .. abilityName .. "]"
            end
            -- Simple ability name without ID
            return "|cff71d5ff|Htwra:" .. abilityName .. ":0|h[" .. abilityName .. "]|h|r"
        end)
        
        afterItems = string.gsub(afterItems, "%[([^%]]+):(%d+)%]", function(abilityName, abilityID)
            -- Skip if this is part of an existing link
            if string.find(abilityName, "|H") then
                return "[" .. abilityName .. ":" .. abilityID .. "]"
            end
            return "|cff71d5ff|Htwra:" .. abilityName .. ":" .. abilityID .. "|h[" .. abilityName .. "]|h|r"
        end)
        
        result = result .. afterItems
    end
    
    return result
end

-- Display a tooltip for an ability using database information
function TWRA:DisplayAbilityTooltipFromDB(abilityName, abilityID)
    -- Find the ability entry in database
    local key = abilityName
    if abilityID then
        key = abilityName .. ":" .. abilityID
    end
    
    -- Try to find the ability in the database
    local abilityData = TWRA.ABILITY_DATABASE[key]
    
    -- If not found with exact key, try to find by name only
    if not abilityData and TWRA.ABILITY_NAME_LOOKUP and TWRA.ABILITY_NAME_LOOKUP[abilityName] then
        local id = TWRA.ABILITY_NAME_LOOKUP[abilityName]
        key = abilityName .. ":" .. id
        abilityData = TWRA.ABILITY_DATABASE[key]
    end
    
    -- If still not found, show a simple tooltip as fallback
    if not abilityData then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000TWRA:|r Ability not found in database: " .. key)
        return TWRA:ForceBasicTooltip(abilityName, "Ability ID: " .. (abilityID or "unknown") .. "\n\nThis ability is not in our database.", 0.8, 0.2, 0.2)
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000TWRA:|r Found ability in database: " .. key)
    
    -- Prepare the tooltip
    ItemRefTooltip:ClearLines()
    ItemRefTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE")
    
    -- Process entries in the database
    for i = 1, 20 do -- Arbitrary limit to prevent infinite loops
        local entry = abilityData[i]
        if not entry then break end
        
        -- Handle different entry types
        if type(entry) == "string" then
            -- Simple string - add as spacer
            ItemRefTooltip:AddLine(entry)
        elseif type(entry) == "table" then
            -- Count elements to determine format
            local count = 0
            for _ in pairs(entry) do count = count + 1 end
            
            if i == 1 then
                -- First entry is always the title
                if count >= 4 then
                    ItemRefTooltip:SetText(entry[4], entry[1], entry[2], entry[3])
                end
            elseif count == 4 then
                -- Simple colored text: {r, g, b, "text"}
                ItemRefTooltip:AddLine(entry[4], entry[1], entry[2], entry[3])
            elseif count == 8 then
                -- Double line: {r1, g1, b1, "leftText", r2, g2, b2, "rightText"}
                ItemRefTooltip:AddDoubleLine(entry[4], entry[8], entry[1], entry[2], entry[3], entry[5], entry[6], entry[7])
            elseif count > 4 then
                -- Multiple lines with same color: {r, g, b, "text1", "text2"...}
                ItemRefTooltip:AddLine(entry[4], entry[1], entry[2], entry[3])
                for j = 5, count do
                    if type(entry[j]) == "string" then
                        ItemRefTooltip:AddLine(entry[j], entry[1], entry[2], entry[3])
                    end
                end
            end
        end
    end
    ItemRefTooltip:Show()
    -- Add icon if available
    if abilityData["icon"] then
        ItemRefTooltip:AddTexture(abilityData["icon"])
    end
    
    -- Make the panel visible
    ShowUIPanel(ItemRefTooltip)
    
    -- Critical line: Show the tooltip to update its size properly
    ItemRefTooltip:Show()
    
    return true
end

-- Force a basic tooltip display without any fancy logic
function TWRA:ForceBasicTooltip(title, text, r, g, b)
    -- Clear existing tooltip
    ItemRefTooltip:ClearLines()
    ItemRefTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE")
    
    -- Set title with color
    ItemRefTooltip:SetText(title, r or 1, g or 1, b or 1)
    
    -- Add some basic text
    ItemRefTooltip:AddLine(text or "No description available", 1, 0.82, 0)
    
    -- Show the tooltip
    ShowUIPanel(ItemRefTooltip)
    ItemRefTooltip:Show()
    
    -- Debug message
    DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000TWRA:|r Displayed basic tooltip for: " .. title)
    return true
end

-- Test function accessible from /run TWRA:TestSimpleTooltip()
function TWRA:TestSimpleTooltip()
    self:ForceBasicTooltip("Test Tooltip", "This is a test tooltip that should definitely work", 0.5, 0, 1)
    return true
end

-- Test function to test database tooltips directly
function TWRA:TestDBTooltip(abilityName, abilityID)
    abilityName = abilityName or "Boss Ability"
    abilityID = abilityID or "1000001"
    return self:DisplayAbilityTooltipFromDB(abilityName, abilityID)
end

-- Test function to demonstrate proper tooltip formatting
function TWRA:TestAbilityLinkFormatting()
    local text = "Testing links: [Arcane Prison] and [Flame Breath:1000002]"
    local processed = self:ProcessAbilityLinks(text)
    DEFAULT_CHAT_FRAME:AddMessage("Original: " .. text)
    DEFAULT_CHAT_FRAME:AddMessage("Processed: " .. processed)
    return processed
end

-- Replace the default SetItemRef function with our improved implementation
SetItemRef = function(link, text, button, chatFrame)
    -- Only process TWRA links, pass everything else to original handler
    if link and string.sub(link, 1, 5) == "twra:" then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000TWRA Debug:|r Link clicked: " .. tostring(link))
        
        -- Extract ability name and ID without strsplit
        local abilityName, abilityID = "Unknown Ability", nil
        
        -- Try to extract from the format "twra:Name:ID"
        local colonPos1 = string.find(link, ":", 1, true)
        if colonPos1 then
            local colonPos2 = string.find(link, ":", colonPos1 + 1, true)
            if colonPos2 then
                abilityName = string.sub(link, colonPos1 + 1, colonPos2 - 1)
                abilityID = string.sub(link, colonPos2 + 1)
            end
        end
        
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000TWRA:|r Found ability: " .. abilityName .. " (ID: " .. (abilityID or "none") .. ")")
        
        -- Check if tooltip is already showing this ability
        if ItemRefTooltip:IsVisible() then
            local firstLine = _G["ItemRefTooltipTextLeft1"]
            local currentText = firstLine and firstLine:GetText()
            
            if currentText == abilityName then
                -- If tooltip is already showing this ability, hide it (toggle behavior)
                DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000TWRA:|r Hiding tooltip (already showing)")
                HideUIPanel(ItemRefTooltip)
                return true
            end
        end
        
        -- Support shift-clicking to insert link into chat
        if IsShiftKeyDown() and ChatFrameEditBox:IsVisible() then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000TWRA:|r Shift-click detected, inserting link to chat")
            
            -- Format a clean link for chat insertion without showing ID in display text
            local cleanLink = TWRA:FormatAbilityLink(abilityName, abilityID)
            ChatFrameEditBox:Insert(cleanLink)
            return true
        end
        
        -- Show tooltip from database
        TWRA:DisplayAbilityTooltipFromDB(abilityName, abilityID)
        -- Important! Return true to prevent other handlers
        return true
    end
    
    -- Pass non-TWRA links to the original handler
    return originalSetItemRef(link, text, button, chatFrame)
end

-- Add a test command to verify tooltip functionality
SLASH_TWRATOOLTIPTEST1 = "/tooltiptest"
SlashCmdList["TWRATOOLTIPTEST"] = function(arg)
    local abilityName, abilityID = "Boss Ability", "1000001"
    
    if arg and arg ~= "" then
        -- Parse arguments
        local parts = {}
        for part in string.gmatch(arg, "%S+") do
            table.insert(parts, part)
        end
        
        if parts[1] then abilityName = parts[1] end
        if parts[2] then abilityID = parts[2] end
    end
    
    TWRA:TestDBTooltip(abilityName, abilityID)
end

-- Add a command to test link formatting
SLASH_TWRALINKTEST1 = "/linktest"
SlashCmdList["TWRALINKTEST"] = function(arg)
    TWRA:TestAbilityLinkFormatting()
end

DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000TWRA:|r Link click handler installed with improved presentation")