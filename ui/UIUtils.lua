-- UI Helper functions for TWRA
TWRA = TWRA or {}
TWRA.UI = {}

-- Apply class coloring to text elements
function TWRA.UI:ApplyClassColoring(textObj, playerName, playerClass, isInRaid, isOnline)
    -- Safety check for text object
    if not textObj or not textObj.SetTextColor then 
        TWRA:Debug("error", "Invalid text object in ApplyClassColoring")
        return
    end
    
    -- For backward compatibility: if playerName is passed as the only parameter,
    -- try to determine class and status from the raid roster or example data
    if playerName and not playerClass then
        -- Check if this is a class group name
        local classFromGroup = TWRA.CLASS_GROUP_NAMES and TWRA.CLASS_GROUP_NAMES[playerName]
  
        -- Use direct class coloring for class groups
        playerClass = classFromGroup
        isInRaid = true
        isOnline = true
    end
    
    -- Default colors
    local r, g, b = 1, 1, 1 -- Default white
    
    -- Apply coloring based on status
    if not isInRaid then
        -- Red for not in raid
        r, g, b = 1, 0.3, 0.3
    elseif not isOnline then
        -- Gray for offline
        r, g, b = 0.5, 0.5, 0.5
    elseif playerClass and TWRA.VANILLA_CLASS_COLORS then
        -- Ensure class name is uppercase for lookup
        local upperClass = string.upper(playerClass)
        
        if TWRA.VANILLA_CLASS_COLORS[upperClass] then
            -- Class color based on the table
            local color = TWRA.VANILLA_CLASS_COLORS[upperClass]
            r, g, b = color.r, color.g, color.b
        else
            TWRA:Debug("error", "Unknown class: " .. tostring(playerClass))
        end
    end
    
    -- Finally apply the color
    textObj:SetTextColor(r, g, b)
end

-- Create an icon with tooltip - improve positioning logic
function TWRA.UI:CreateIconWithTooltip(parent, iconTexture, tooltipTitle, tooltipText, relativeObject, xOffset, width, height)
    local icon = parent:CreateTexture(nil, "OVERLAY")
    icon:SetTexture(iconTexture)
    icon:SetWidth(width or 22)  -- Default to 22px now
    icon:SetHeight(height or 22)  -- Default to 22px now
    
    -- If relativeObject is a frame or fontstring, position relative to it
    if type(relativeObject) == "table" and relativeObject.GetWidth then
        -- Position icon to the right of the relative object
        icon:SetPoint("LEFT", relativeObject, "RIGHT", xOffset or 5, 0)
    else
        -- Fall back to old behavior if relativeObject is just a number
        local x = relativeObject
        local y = xOffset
        icon:SetPoint("LEFT", parent, "LEFT", x or 0, y or 0)
    end
    
    -- Create a frame over the icon to handle mouse events
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetWidth(width or 22)  -- Match icon size
    frame:SetHeight(height or 22)  -- Match icon size
    frame:SetPoint("CENTER", icon, "CENTER", 0, 0)
    
    -- Set up the tooltip
    frame:EnableMouse(true)
    frame:SetScript("OnEnter", function()
        GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
        GameTooltip:ClearLines()
        if tooltipTitle then
            GameTooltip:SetText(tooltipTitle)
        end
        if tooltipText then
            GameTooltip:AddLine(tooltipText, 1, 1, 1, true)
        end
        GameTooltip:Show()
    end)
    
    frame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    return icon, frame
end