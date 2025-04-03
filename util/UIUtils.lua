-- TWRA UI Utilities
TWRA = TWRA or {}
TWRA.UI = TWRA.UI or {}

-- Used in: Frame.lua, OSD.lua, ui/Options/DebugOptions.lua
-- Apply class coloring to a player's name based on status
function TWRA.UI:ApplyClassColoring(textObj, playerName, playerClass, isInRaid, isOnline)
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

-- Used in: Options.lua, Options/SyncAndAnnounceOptions.lua, Frame.lua
-- UI Helper: Create a divider line (both horizontal and vertical versions)
function TWRA.UI:CreateDivider(parent, width, offsetX, offsetY, anchorPoint, relativePoint, isVertical)
    local divider = parent:CreateTexture(nil, "ARTWORK")
    divider:SetTexture(0.5, 0.5, 0.5, 0.8)
    
    -- Handle vertical dividers
    if isVertical then
        divider:SetWidth(1)
        divider:SetHeight(width or parent:GetHeight() - 20)
        
        -- Default anchor points for vertical divider
        anchorPoint = anchorPoint or "LEFT" 
        relativePoint = relativePoint or "LEFT"
    else
        -- Horizontal divider (default)
        divider:SetHeight(1)
        divider:SetWidth(width or parent:GetWidth() - 20)
        
        -- Default anchor points if not specified
        anchorPoint = anchorPoint or "TOP"
        relativePoint = relativePoint or "TOP"
    end
    
    divider:SetPoint(anchorPoint, parent, relativePoint, offsetX or 0, offsetY or 0)
    
    return divider
end

-- Used in: Options/SyncAndAnnounceOptions.lua, Options/OSDOptions.lua, Options/ImportOptions.lua, Options/DebugOptions.lua
-- UI Helper: Create a section header with underline
function TWRA.UI:CreateSectionHeader(parent, text, offsetX, offsetY)
    local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    header:SetPoint("TOPLEFT", parent, "TOPLEFT", offsetX or 10, offsetY or -10)
    header:SetText(text)
    
    -- Add underline
    local underline = parent:CreateTexture(nil, "ARTWORK")
    underline:SetTexture(0.3, 0.3, 0.8, 0.8)  -- Slightly blue tint for headers
    underline:SetHeight(1)
    underline:SetWidth(header:GetWidth() * 1.2)
    underline:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -2)
    
    -- Store reference to underline
    header.underline = underline
    
    return header
end

-- Used in: Options/SyncAndAnnounceOptions.lua, Options/OSDOptions.lua, Options/DebugOptions.lua, Frame.lua, Options.lua
-- UI Helper: Create a checkbox with label
function TWRA.UI:CreateCheckbox(parent, labelText, initialValue, anchorFrame, anchorPoint, offsetX, offsetY)
    local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    check:SetChecked(initialValue)
    
    -- Determine anchor points
    if anchorFrame and anchorPoint then
        check:SetPoint(anchorPoint, anchorFrame, anchorPoint, offsetX or 0, offsetY or 0)
    else
        check:SetPoint("TOPLEFT", parent, "TOPLEFT", offsetX or 10, offsetY or -10)
    end
    
    -- Add label
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("LEFT", check, "RIGHT", 5, 0)
    label:SetText(labelText)
    
    return check, label
end

-- Used in: Options/SyncAndAnnounceOptions.lua, Options/OSDOptions.lua, Options/DebugOptions.lua
-- UI Helper: Create a standard slider with labels and value text
function TWRA.UI:CreateSlider(parent, textFormat, minValue, maxValue, step, initialValue, anchorFrame, anchorPoint, offsetX, offsetY)
    -- Generate a unique name for the slider using time instead of table reference
    local sliderName = "TWRA_Slider_" .. tostring(GetTime() * 1000)
    
    local slider = CreateFrame("Slider", sliderName, parent, "OptionsSliderTemplate")
    slider:SetWidth(180)
    slider:SetHeight(16)
    slider:SetMinMaxValues(minValue, maxValue)
    slider:SetValueStep(step)
    slider:SetValue(initialValue)
    slider:SetOrientation("HORIZONTAL")
    
    -- Determine anchor points
    if anchorFrame and anchorPoint then
        slider:SetPoint(anchorPoint, anchorFrame, anchorPoint, offsetX or 0, offsetY or 0)
    else
        slider:SetPoint("TOPLEFT", parent, "TOPLEFT", offsetX or 10, offsetY or -30)
    end
    
    -- Set text using format string
    local sliderText = getglobal(slider:GetName() .. "Text")
    if sliderText then
        sliderText:SetText(string.format(textFormat, initialValue))
    end
    
    -- Set min/max labels
    local lowText = getglobal(slider:GetName() .. "Low")
    local highText = getglobal(slider:GetName() .. "High")
    if lowText then lowText:SetText(minValue) end
    if highText then highText:SetText(maxValue) end
    
    -- Update text when value changes
    slider:SetScript("OnValueChanged", function()
        local value = math.floor(slider:GetValue() * (1/step)) / (1/step) -- Round to step
        if sliderText then
            sliderText:SetText(string.format(textFormat, value))
        end
    end)
    
    return slider
end

-- Used in: Options/SyncAndAnnounceOptions.lua, Options/OSDOptions.lua, Options/ImportOptions.lua, Frame.lua
-- UI Helper: Create a simple label with configurable justification
function TWRA.UI:CreateLabel(parent, text, anchorFrame, anchorPoint, offsetX, offsetY, justifyH)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    
    -- Determine anchor points
    if anchorFrame and anchorPoint then
        label:SetPoint(anchorPoint, anchorFrame, anchorPoint, offsetX or 0, offsetY or 0)
    else
        label:SetPoint("TOPLEFT", parent, "TOPLEFT", offsetX or 10, offsetY or -10)
    end
    
    label:SetText(text)
    
    -- Set justification if provided
    if justifyH then
        label:SetJustifyH(justifyH)
    end
    
    return label
end

-- Used in: Options.lua, Options/SyncAndAnnounceOptions.lua, Options/OSDOptions.lua, Options/ImportOptions.lua, Options/DebugOptions.lua
-- UI Helper: Get options container frame
function TWRA.UI:GetOptionsContainer()
    if TWRA.optionsTabFrame then
        return TWRA.optionsTabFrame
    elseif TWRA.optionsFrame then
        return TWRA.optionsFrame
    end
    TWRA:Debug("error", "Options container frame not found")
    return nil
end

-- Used in: ImportOptions.lua, ExportOptions.lua
-- UI Helper: Safely set cursor position with nil checks
function TWRA.UI:SafeSetCursorPosition(editBox, position)
    if not editBox then return end
    if editBox.SetCursorPosition then
        editBox:SetCursorPosition(position)
    end
end

-- Used in: ImportOptions.lua, ExportOptions.lua  
-- UI Helper: Safely highlight text with nil checks
function TWRA.UI:SafeHighlightText(editBox, start, finish)
    if not editBox then return end
    if editBox.HighlightText then
        if start and finish then
            editBox:HighlightText(start, finish)
        else
            editBox:HighlightText()
        end
    end
end

-- Used in: Options.lua, Frame.lua, multiple UI modules
-- UI Helper: Create a standard button with consistent styling
function TWRA.UI:CreateButton(parent, text, width, height, anchorFrame, anchorPoint, offsetX, offsetY, template, callback)
    -- Use provided template or default to standard button
    template = template or "UIPanelButtonTemplate"
    
    local button = CreateFrame("Button", nil, parent, template)
    button:SetWidth(width or 100)
    button:SetHeight(height or 22)
    
    -- Determine anchor points
    if anchorFrame and anchorPoint then
        button:SetPoint(anchorPoint, anchorFrame, anchorPoint, offsetX or 0, offsetY or 0)
    else
        button:SetPoint("TOPLEFT", parent, "TOPLEFT", offsetX or 10, offsetY or -10)
    end
    
    -- Set text if provided
    if text then
        button:SetText(text)
    end
    
    -- Set callback if provided
    if callback then
        button:SetScript("OnClick", callback)
    end
    
    return button
end

-- Used in: Frame.lua, Options.lua
-- UI Helper: Create an input box (edit box) with standard styling
function TWRA.UI:CreateInputBox(parent, width, height, anchorFrame, anchorPoint, offsetX, offsetY, initialText, multiLine)
    -- Create the backdrop frame for the input box
    local backdropFrame = CreateFrame("Frame", nil, parent)
    backdropFrame:SetWidth(width or 150)
    backdropFrame:SetHeight(height or 22)
    
    -- Determine anchor points
    if anchorFrame and anchorPoint then
        backdropFrame:SetPoint(anchorPoint, anchorFrame, anchorPoint, offsetX or 0, offsetY or 0)
    else
        backdropFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", offsetX or 10, offsetY or -10)
    end
    
    -- Add backdrop
    backdropFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    
    -- Create the edit box inside the backdrop
    local editBox = CreateFrame("EditBox", nil, backdropFrame)
    editBox:SetPoint("TOPLEFT", backdropFrame, "TOPLEFT", 8, -8)
    editBox:SetPoint("BOTTOMRIGHT", backdropFrame, "BOTTOMRIGHT", -8, 8)
    editBox:SetFontObject(ChatFontNormal)
    
    -- Configure based on multiline setting
    if multiLine then
        editBox:SetMultiLine(true)
        editBox:SetAutoFocus(false)
        editBox:EnableMouse(true)
        editBox:SetMaxLetters(9999)
    else
        editBox:SetAutoFocus(false)
        editBox:SetMaxLetters(256)
    end
    
    -- Set initial text if provided
    if initialText then
        editBox:SetText(initialText)
    end
    
    -- Add standard scripts
    editBox:SetScript("OnEscapePressed", function() this:ClearFocus() end)
    editBox:SetScript("OnTabPressed", function() this:ClearFocus() end)
    
    -- Store the backdrop frame reference
    editBox.backdropFrame = backdropFrame
    
    return editBox
end

-- Used in: Frame.lua
-- UI Helper: Create a panel with consistent styling
function TWRA.UI:CreatePanel(parent, width, height, anchorPoint, relativeFrame, relativePoint, xOffset, yOffset)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetWidth(width or 300)
    panel:SetHeight(height or 200)
    
    -- Set position
    if anchorPoint and relativeFrame and relativePoint then
        panel:SetPoint(anchorPoint, relativeFrame, relativePoint, xOffset or 0, yOffset or 0)
    else
        panel:SetPoint("CENTER", parent, "CENTER")
    end
    
    -- Add backdrop
    panel:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    
    return panel
end

-- Used in: Frame.lua, Options.lua
-- UI Helper: Create a scrollframe with content
function TWRA.UI:CreateScrollFrame(parent, width, height, anchorPoint, relativeFrame, relativePoint, xOffset, yOffset)
    -- Create the scroll frame
    local scrollFrame = CreateFrame("ScrollFrame", nil, parent)
    scrollFrame:SetWidth(width or 300)
    scrollFrame:SetHeight(height or 200)
    
    -- Set position
    if anchorPoint and relativeFrame and relativePoint then
        scrollFrame:SetPoint(anchorPoint, relativeFrame, relativePoint, xOffset or 0, yOffset or 0)
    else
        scrollFrame:SetPoint("CENTER", parent, "CENTER")
    end
    
    -- Create the scrollbar
    local scrollbar = CreateFrame("Slider", nil, scrollFrame, "UIPanelScrollBarTemplate")
    scrollbar:SetPoint("TOPRIGHT", scrollFrame, "TOPRIGHT", 0, -16)
    scrollbar:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMRIGHT", 0, 16)
    scrollbar:SetMinMaxValues(0, 0)
    scrollbar:SetValueStep(1)
    scrollbar:SetValue(0)
    scrollbar:SetWidth(16)
    scrollbar:SetScript("OnValueChanged", function()
        scrollFrame:SetVerticalScroll(scrollbar:GetValue())
    end)
    
    -- Create content frame
    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetWidth(width - 16)  -- Account for scrollbar width
    content:SetHeight(height)
    
    -- Set initial content size (will typically be reset by user)
    scrollFrame:SetScrollChild(content)
    
    -- Store references
    scrollFrame.content = content
    scrollFrame.scrollbar = scrollbar
    
    -- Update scrollbar method
    function scrollFrame:UpdateScrollbarValues()
        local contentHeight = self.content:GetHeight()
        local frameHeight = self:GetHeight()
        
        if contentHeight > frameHeight then
            self.scrollbar:SetMinMaxValues(0, contentHeight - frameHeight)
            self.scrollbar:Enable()
        else
            self.scrollbar:SetMinMaxValues(0, 0)
            self.scrollbar:Disable()
        end
    end
    
    return scrollFrame
end

-- UI Helper: Toggle between main and options view
function TWRA.UI:ToggleView()
    if not TWRA.mainFrame then
        TWRA:Debug("error", "Cannot toggle view - main frame does not exist")
        return
    end
    
    if TWRA.currentView == "main" then
        TWRA:Debug("ui", "Switching to options view")
        TWRA:ShowOptionsView()
    else
        TWRA:Debug("ui", "Switching to main view")
        TWRA:ShowMainView()
    end
end

-- Used in: Options.lua, Frame.lua
-- UI Helper: Create an icon with tooltip
function TWRA.UI:CreateIconWithTooltip(parent, texturePath, tooltipTitle, tooltipText, anchorFrame, offsetX, width, height)
    -- Create a container frame for the icon
    local iconFrame = CreateFrame("Frame", nil, parent)
    iconFrame:SetWidth(width or 16)
    iconFrame:SetHeight(height or 16)
    
    -- Position the frame
    if anchorFrame then
        iconFrame:SetPoint("LEFT", anchorFrame, "RIGHT", offsetX or 0, 0)
    else
        iconFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    end
    
    -- Create the texture
    local icon = iconFrame:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexture(texturePath)
    
    -- Add tooltip functionality
    iconFrame:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
        GameTooltip:SetText(tooltipTitle, 1, 1, 1)
        if tooltipText then
            GameTooltip:AddLine(tooltipText, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true)
        end
        GameTooltip:Show()
    end)
    
    iconFrame:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    return icon, iconFrame
end