-- LinkClickHandler.lua - Handles click events for ability links

-- Ensure TWRA namespace exists
TWRA = TWRA or {}
TWRA.Abilities = TWRA.Abilities or {}

-- Initialize the tooltip handler
function TWRA.Abilities:InitializeTooltipHandler()
    -- Register for link click events
    hooksecurefunc("SetItemRef", function(link, text, button)
        -- Check if this is our custom link
        local linkType, abilityID = string.match(link, "twra:(%w+):(%d+)")
        if linkType == "ability" then
            TWRA.Abilities:ShowTooltipForAbility(abilityID, button)
            return
        end
    end)
end

-- Display tooltip for a specific ability
function TWRA.Abilities:ShowTooltipForAbility(abilityID, button)
    -- Check if tooltip is already showing this ability
    local isVisible = ItemRefTooltip:IsVisible()
    local currentText = isVisible and getglobal("ItemRefTooltipTextLeft1") and getglobal("ItemRefTooltipTextLeft1"):GetText() or "none"
    
    local abilityName = TWRA.ABILITY_ID_LOOKUP[abilityID]
    if not abilityName then return end
    
    local abilityKey = self:GetAbilityKey(abilityName, abilityID)
    local abilityData = TWRA.ABILITY_DATABASE[abilityKey]
    if not abilityData then return end
    
    -- If the tooltip is showing the same ability, toggle it off
    if isVisible and currentText == abilityName then
        ItemRefTooltip:Hide()
        return
    end
    
    -- Display the tooltip with ability info
    self:RenderAbilityTooltip(abilityData)
end

-- Render the ability tooltip using the new database structure
function TWRA.Abilities:RenderAbilityTooltip(abilityData)
    -- Clear existing content
    ItemRefTooltip:ClearLines()
    ItemRefTooltip:SetOwner(UIParent, "ANCHOR_PRESERVE")
    
    -- Process each line according to the format in the database
    for lineIndex, lineData in ipairs(abilityData) do
        if type(lineData) == "string" and lineData == "" then
            -- Empty string indicates a separator
            ItemRefTooltip:AddLine(" ")
        elseif type(lineData) == "table" then
            if #lineData == 4 then
                -- Basic line with one color: {r, g, b, "text"}
                local r, g, b, text = unpack(lineData)
                if lineIndex == 1 then
                    -- First line is the title
                    ItemRefTooltip:SetText(text, r, g, b)
                else
                    ItemRefTooltip:AddLine(text, r, g, b)
                end
            elseif #lineData == 8 then
                -- Double line: {r1, g1, b1, "text1", r2, g2, b2, "text2"}
                local r1, g1, b1, text1, r2, g2, b2, text2 = unpack(lineData)
                ItemRefTooltip:AddDoubleLine(text1, text2, r1, g1, b1, r2, g2, b2)
            elseif #lineData > 4 then
                -- Multiple lines with same color
                local r, g, b = lineData[1], lineData[2], lineData[3]
                for i = 4, #lineData do
                    ItemRefTooltip:AddLine(lineData[i], r, g, b)
                end
            end
        end
    end
    
    -- Show the updated tooltip
    ItemRefTooltip:Show()
end

-- Register for events
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, addon)
    if addon == "TWRA" then
        TWRA.Abilities:InitializeTooltipHandler()
    end
end)
