-- TWRA Link Click Handler with ability database integration
-- Uses direct tooltip manipulation based on database entries

TWRA = TWRA or {}

-- Store the original function reference
local originalSetItemRef = SetItemRef

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
            ChatFrameEditBox:Insert(text)
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

DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000TWRA:|r Link click handler installed")