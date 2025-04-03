-- TWRA OSD Options Module
TWRA = TWRA or {}
TWRA.OPTIONS = TWRA.OPTIONS or {}

-- Create OSD options panel
function TWRA.OPTIONS:CreateOSDOptions(parent)
    -- Better parent handling using the utility function
    if not parent then
        parent = TWRA.UI:GetOptionsContainer()
        
        if not parent then
            TWRA:Debug("error", "No parent frame provided for OSDOptions")
            -- Create a minimal placeholder frame so the function doesn't fail
            local placeholder = CreateFrame("Frame")
            placeholder:Hide()
            return placeholder
        end
    end
    
    -- Make sure parent is valid and has GetWidth
    if not parent.GetWidth then
        TWRA:Debug("error", "Invalid parent for OSDOptions")
        local placeholder = CreateFrame("Frame")
        placeholder:Hide()
        return placeholder
    end
    
    -- Create a properly anchored container frame
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints(parent)
    
    -- Set max width to ensure content doesn't overflow
    local maxWidth = parent:GetWidth() - 10 -- Account for padding
    
    -- OSD Lock Option using UIUtils with proper vertical spacing from top
    local osdLock, osdLockText = TWRA.UI:CreateCheckbox(
        frame, 
        "Lock OSD Position", 
        TWRA_SavedVariables.options.osdLocked,
        frame, "TOPLEFT", 10, -10  -- Position from top-left with proper margin
    )
    
    -- Set OnClick script
    osdLock:SetScript("OnClick", function()
        local isChecked = osdLock:GetChecked()
        TWRA:SaveOption("osdLocked", isChecked)
        
        -- Update the actual OSD system if it exists
        if TWRA.OSD then
            TWRA.OSD.locked = isChecked
            if TWRA.UpdateOSDLock then
                TWRA:UpdateOSDLock()
            end
        end
        
        TWRA:Debug("osd", "OSD Position " .. (isChecked and "locked" or "unlocked"))
    end)
    
    -- Show Main Frame By Default checkbox with consistent spacing
    local showFrame, showFrameText = TWRA.UI:CreateCheckbox(
        frame, 
        "Show Main Window by Default", 
        not TWRA_SavedVariables.options.hideFrameByDefault,
        osdLock, "BOTTOMLEFT", 0, -15
    )
    
    -- Set OnClick script
    showFrame:SetScript("OnClick", function()
        local isChecked = showFrame:GetChecked()
        TWRA:SaveOption("hideFrameByDefault", not isChecked)
        TWRA:Debug("ui", "Main window will " .. 
                      (isChecked and "be visible" or "be hidden") .. 
                      " by default (takes effect after restart)")
    end)
    
    -- Hide Minimap Button checkbox with consistent spacing
    local hideMinimapBtn, hideMinimapText = TWRA.UI:CreateCheckbox(
        frame, 
        "Hide Minimap Button", 
        TWRA_SavedVariables.options.hideMinimapButton,
        showFrame, "BOTTOMLEFT", 0, -15
    )
    
    -- Set OnClick script
    hideMinimapBtn:SetScript("OnClick", function()
        local isChecked = hideMinimapBtn:GetChecked()
        TWRA:SaveOption("hideMinimapButton", isChecked)
        
        -- Update minimap button visibility immediately
        if TWRA.minimapButton then
            if isChecked then
                TWRA.minimapButton:Hide()
            else
                TWRA.minimapButton:Show()
            end
        end
        
        TWRA:Debug("osd", "Minimap button will " .. 
                       (isChecked and "be hidden" or "be shown"))
    end)
    
    -- Add OSD Scale slider with increased spacing for new section
    local osdScaleSlider = TWRA.UI:CreateSlider(
        frame,
        "OSD Scale: %.1f",
        0.5, 2.0, 0.1,
        TWRA_SavedVariables.options.osdScale or 1.0,
        hideMinimapBtn, "BOTTOMLEFT", 0, -25
    )
    
    osdScaleSlider:SetScript("OnValueChanged", function()
        local value = math.floor(osdScaleSlider:GetValue() * 10) / 10  -- Round to 1 decimal place
        getglobal(osdScaleSlider:GetName() .. "Text"):SetText("OSD Scale: " .. string.format("%.1f", value))
        TWRA:SaveOption("osdScale", value)
        
        -- Update OSD scale in real-time if it exists
        if TWRA.OSD and TWRA.sectionOverlay then
            TWRA.OSD.scale = value
            TWRA.sectionOverlay:SetScale(value)
        end
    end)
    
    -- Add OSD Duration slider with consistent spacing between sliders
    local osdDurationSlider = TWRA.UI:CreateSlider(
        frame,
        "OSD Duration: %d sec",
        1, 10, 1,
        TWRA_SavedVariables.options.osdDuration or 2,
        osdScaleSlider, "BOTTOMLEFT", 0, -30
    )
    
    osdDurationSlider:SetScript("OnValueChanged", function()
        local value = math.floor(osdDurationSlider:GetValue())
        getglobal(osdDurationSlider:GetName() .. "Text"):SetText("OSD Duration: " .. value .. " sec")
        TWRA:SaveOption("osdDuration", value)
        
        -- Update OSD duration in real-time if it exists
        if TWRA.OSD then
            TWRA.OSD.duration = value
        end
    end)
    
    -- Create button row for OSD controls with proper spacing
    local buttonRow = CreateFrame("Frame", nil, frame)
    buttonRow:SetWidth(math.min(220, maxWidth - 10))
    buttonRow:SetHeight(30)
    buttonRow:SetPoint("TOPLEFT", osdDurationSlider, "BOTTOMLEFT", 0, -20)
    
    -- Add OSD test button
    local testOSDBtn = CreateFrame("Button", nil, buttonRow, "UIPanelButtonTemplate")
    testOSDBtn:SetWidth(100)
    testOSDBtn:SetHeight(25)
    testOSDBtn:SetPoint("LEFT", buttonRow, "LEFT", 0, 0)
    testOSDBtn:SetText("Test OSD")
    
    testOSDBtn:SetScript("OnClick", function()
        if TWRA.TestOSD then
            TWRA:TestOSD()
        elseif TWRA.ToggleOSD then
            TWRA:ToggleOSD(true)
        end
    end)
    
    -- Add OSD reset position button
    local resetPosBtn = CreateFrame("Button", nil, buttonRow, "UIPanelButtonTemplate")
    resetPosBtn:SetWidth(120)
    resetPosBtn:SetHeight(25)
    resetPosBtn:SetPoint("LEFT", testOSDBtn, "RIGHT", 0, 0)
    resetPosBtn:SetText("Reset Position")
    
    resetPosBtn:SetScript("OnClick", function()
        if TWRA.ResetOSDPosition then
            TWRA:ResetOSDPosition()
        end
    end)
    
    -- Resize buttons to fit if needed
    if maxWidth < 240 then
        testOSDBtn:SetWidth(math.min(100, maxWidth/2 - 10))
        resetPosBtn:SetWidth(math.min(120, maxWidth/2 - 10))
    end
    
    return frame
end
