-- UI Helper functions for TWRA
TWRA = TWRA or {}
TWRA.UI = {}

-- Create a standard frame background with consistent styling
function TWRA.UI:CreateBackground(parent, r, g, b, a)
    local bg = parent:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture(r or 0.1, g or 0.1, b or 0.1, a or 0.3)
    bg:SetAllPoints()
    return bg
end


-- Create a text element with standard options - FIXED TEXT COLOR TO BE WHITE BY DEFAULT
function TWRA.UI:CreateText(parent, text, fontStyle, justifyH, r, g, b)
    local textObj = parent:CreateFontString(nil, "OVERLAY", fontStyle or "GameFontNormal")
    textObj:SetText(text or "")
    if justifyH then textObj:SetJustifyH(justifyH) end
    textObj:SetTextColor(r or 1, g or 1, b or 1) -- Default to white
    return textObj
end

-- Create a standard button with consistent styling
function TWRA.UI:CreateButton(parent, text, width, height, point, relFrame, relPoint, x, y, onClick)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetWidth(width or 100)
    button:SetHeight(height or 22)
    button:SetPoint(point or "CENTER", relFrame or parent, relPoint or "CENTER", x or 0, y or 0)
    button:SetText(text or "Button")
    
    if onClick then
        button:SetScript("OnClick", onClick)
    end
    
    return button
end

-- Create a section header with a title
function TWRA.UI:CreateSectionHeader(parent, text, yOffset)
    local section = CreateFrame("Frame", nil, parent)
    section:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset or 0)
    section:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -10, yOffset or 0)
    section:SetHeight(30)
    
    local title = self:CreateText(section, text, "GameFontNormalLarge", "LEFT")
    title:SetPoint("TOPLEFT", 0, 0)
    
    -- Add a subtle separator line below the header
    local line = section:CreateTexture(nil, "ARTWORK")
    line:SetTexture(0.5, 0.5, 0.5, 0.3)
    line:SetHeight(1)
    line:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -2)
    line:SetPoint("TOPRIGHT", section, "TOPRIGHT", 0, -2)
    
    section.title = title
    section.line = line
    
    return section
end

-- Create a checkbox with label
function TWRA.UI:CreateCheckbox(parent, text, point, relFrame, relPoint, x, y, initialValue, onClick)
    local checkbox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    checkbox:SetPoint(point or "TOPLEFT", relFrame or parent, relPoint or "TOPLEFT", x or 0, y or 0)
    checkbox:SetWidth(24)
    checkbox:SetHeight(24)
    
    local label = self:CreateText(parent, text, "GameFontNormal")
    label:SetPoint("LEFT", checkbox, "RIGHT", 2, 0)
    
    -- Set initial state
    if initialValue ~= nil then
        checkbox:SetChecked(initialValue)
    end
    
    -- Set click handler
    if onClick then
        checkbox:SetScript("OnClick", function()
            onClick(checkbox:GetChecked())
        end)
    end
    
    checkbox.label = label
    return checkbox
end

-- Create a scrollframe with editbox for multiline text input
function TWRA.UI:CreateScrollingEditBox(parent, width, height, point, relFrame, relPoint, x, y)
    -- Create ScrollFrame
    local scrollFrame = CreateFrame("ScrollFrame", nil, parent)
    scrollFrame:SetWidth(width or 200)
    scrollFrame:SetHeight(height or 100)
    scrollFrame:SetPoint(point or "CENTER", relFrame or parent, relPoint or "CENTER", x or 0, y or 0)
    
    -- Create EditBox
    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetMultiLine(true)
    editBox:SetWidth(scrollFrame:GetWidth() - 5)
    editBox:SetHeight(scrollFrame:GetHeight())
    editBox:SetAutoFocus(false)
    editBox:EnableMouse(true)
    editBox:SetScript("OnEscapePressed", function() editBox:ClearFocus() end)
    
    -- Add background for edit area
    local bg = parent:CreateTexture(nil, "BACKGROUND")
    bg:SetTexture(0, 0, 0, 0.5)
    bg:SetPoint("TOPLEFT", scrollFrame, "TOPLEFT", -5, 5)
    bg:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMRIGHT", 5, -5)
    
    -- Set up scrolling
    scrollFrame:SetScrollChild(editBox)
    
    -- Store references
    scrollFrame.editBox = editBox
    scrollFrame.background = bg
    
    return scrollFrame
end

-- Create a radio button with label
function TWRA.UI:CreateRadioButton(parent, text, point, relFrame, relPoint, x, y, initialValue, onClick)
    local radio = CreateFrame("CheckButton", nil, parent, "UIRadioButtonTemplate")
    radio:SetPoint(point or "TOPLEFT", relFrame or parent, relPoint or "TOPLEFT", x or 0, y or 0)
    radio:SetWidth(16)
    radio:SetHeight(16)
    
    local label = self:CreateText(parent, text, "GameFontNormal")
    label:SetPoint("LEFT", radio, "RIGHT", 2, 0)
    
    -- Set initial state
    if initialValue ~= nil then
        radio:SetChecked(initialValue)
    end
    
    -- Set click handler
    if onClick then
        radio:SetScript("OnClick", onClick)
    end
    
    radio.label = label
    return radio
end

-- Create a standard input box
function TWRA.UI:CreateInputBox(parent, width, height, point, relFrame, relPoint, x, y)
    local input = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    input:SetWidth(width or 120)
    input:SetHeight(height or 20)
    input:SetPoint(point or "TOPLEFT", relFrame or parent, relPoint or "TOPLEFT", x or 0, y or 0)
    input:SetAutoFocus(false)
    
    input:SetScript("OnEnterPressed", function() input:ClearFocus() end)
    input:SetScript("OnEscapePressed", function() input:ClearFocus() end)
    
    return input
end

-- Create a group of radio buttons that work together (only one can be selected)
function TWRA.UI:CreateRadioGroup(parent, options, selected, startY, xOffset)
    local radioButtons = {}
    local yOffset = startY or 0
    
    for i, option in ipairs(options) do
        local radio = self:CreateRadioButton(
            parent,
            option.text,
            "TOPLEFT", parent, "TOPLEFT",
            xOffset or 10, yOffset,
            option.value == selected
        )
        
        -- Common click handler for all radio buttons
        radio.value = option.value
        radio:SetScript("OnClick", function()
            -- Uncheck all others
            for j, otherRadio in ipairs(radioButtons) do
                if j ~= i then
                    otherRadio:SetChecked(false)
                end
            end
            
            -- Call the option's click handler if it exists
            if option.onClick then
                option.onClick(option.value)
            end
        end)
        
        table.insert(radioButtons, radio)
        yOffset = yOffset - 25 -- Standard spacing between radio buttons
    end
    
    return radioButtons
end

-- Apply class coloring to text elements
function TWRA.UI:ApplyClassColoring(textElement, playerNameOrClass)
    -- If empty name, just return
    if not playerNameOrClass or playerNameOrClass == "" then return end
    
    -- Handle class groups (like "MAGE" or "WARLOCK")
    if TWRA.CLASS_GROUP_NAMES and TWRA.CLASS_GROUP_NAMES[playerNameOrClass] then
        local className = TWRA.CLASS_GROUP_NAMES[playerNameOrClass]
        local isClassInRaid = TWRA:HasClassInRaid(className)
        
        if isClassInRaid then
            -- Use class color
            if TWRA.VANILLA_CLASS_COLORS and TWRA.VANILLA_CLASS_COLORS[className] then
                local color = TWRA.VANILLA_CLASS_COLORS[className]
                textElement:SetTextColor(color.r, color.g, color.b)
            end
        else
            -- Red for missing class
            textElement:SetTextColor(1, 0.3, 0.3)
        end
    else
        -- Handle individual players
        local inRaid, online = TWRA:GetPlayerStatus(playerNameOrClass)
        
        if inRaid then
            if not online then
                -- Gray for offline players
                textElement:SetTextColor(0.5, 0.5, 0.5)
            else
                -- Get player's class for coloring
                local playerClass = TWRA:GetPlayerClass(playerNameOrClass)
                
                if playerClass and TWRA.VANILLA_CLASS_COLORS then
                    playerClass = string.upper(playerClass)
                    local color = TWRA.VANILLA_CLASS_COLORS[playerClass]
                    if color then
                        textElement:SetTextColor(color.r, color.g, color.b)
                    else
                        textElement:SetTextColor(1, 1, 1)  -- White if no color found
                    end
                else
                    textElement:SetTextColor(1, 1, 1)  -- White if no class found
                end
            end
        else
            -- Red for players not in raid
            textElement:SetTextColor(1, 0.3, 0.3)
        end
    end
end

-- Add tooltip to any frame
function TWRA.UI:AddTooltip(frame, title, text)
    frame:SetScript("OnEnter", function()
        GameTooltip:SetOwner(frame, "ANCHOR_RIGHT")
        if title then
            GameTooltip:AddLine(title, 1, 1, 1)
        end
        GameTooltip:AddLine(text, 1, 0.82, 0, true)
        GameTooltip:Show()
    end)
    
    frame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

-- Create an icon with tooltip
function TWRA.UI:CreateIconWithTooltip(parent, iconTexture, tooltipTitle, tooltipText, x, y, width, height)
    local icon = parent:CreateTexture(nil, "OVERLAY")
    icon:SetTexture(iconTexture)
    icon:SetWidth(width or 20)  -- Increased default size from 16 to 20
    icon:SetHeight(height or 20)  -- Increased default size from 16 to 20
    
    -- If x is a frame or fontstring, position relative to it
    if type(x) == "table" and x.GetWidth then
        icon:SetPoint("LEFT", x, "RIGHT", 5, 0)
    else
        icon:SetPoint("LEFT", parent, "LEFT", x or 0, y or 0)
    end
    
    -- Create a frame over the icon to handle mouse events
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetWidth(width or 20)  -- Match icon size
    frame:SetHeight(height or 20)  -- Match icon size
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

-- Create a hidden scroll frame with functional scrolling but invisible scrollbar
function TWRA.UI:CreateHiddenScrollFrame(parent, width, height, point, relFrame, relPoint, x, y)
    -- Check all required parameters
    if not parent then
        DEFAULT_CHAT_FRAME:AddMessage("TWRA Error: Missing parent for CreateHiddenScrollFrame")
        return
    end
    
    -- Default values if not provided
    width = width or 200
    height = height or 150
    point = point or "TOPLEFT"
    relFrame = relFrame or parent
    relPoint = relPoint or "TOPLEFT"
    x = x or 0
    y = y or 0
    
    -- Create a container frame that clips children
    local container = CreateFrame("Frame", nil, parent)
    container:SetWidth(width)
    container:SetHeight(height)
    container:SetPoint(point, relFrame, relPoint, x, y)
    
    -- Set ClipsChildren if the API supports it (using pcall to safely attempt)
    local success = pcall(function() container:SetClipsChildren(true) end)
    if not success then
        -- Alternative approach if SetClipsChildren is not available
        -- Create a mask texture that covers only the visible area
        local mask = container:CreateTexture(nil, "OVERLAY")
        mask:SetAllPoints(container)
        mask:SetTexture(1, 1, 1, 1)
        container.mask = mask
    end
    
    -- Create the actual scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", nil, container, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 0, 0)
    scrollFrame:SetPoint("BOTTOMRIGHT", 0, 0)
    
    -- Hide the scroll bar
    local scrollbar = getglobal(scrollFrame:GetName().."ScrollBar")
    if scrollbar then
        scrollbar:Hide()
        scrollbar:SetWidth(0.1)
    end
    
    -- Create the edit box
    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetWidth(width - 20) -- Subtract some width to ensure no overlap
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:EnableMouse(true)
    editBox:SetScript("OnEscapePressed", function() editBox:ClearFocus() end)
    scrollFrame:SetScrollChild(editBox)
    
    -- Add backdrop to container
    local bg = CreateFrame("Frame", nil, container)
    bg:SetPoint("TOPLEFT", -5, 5)
    bg:SetPoint("BOTTOMRIGHT", 5, -5)
    bg:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    bg:SetBackdropColor(0, 0, 0, 0.6)
    
    return container, scrollFrame, editBox, bg
end
TWRA:Debug("general", "UI Utils module loaded")