-- TWRA Sync & Announce Options Module
TWRA = TWRA or {}
TWRA.OPTIONS = TWRA.OPTIONS or {}

-- Create Sync and Announcements options panel
function TWRA.OPTIONS:CreateSyncAndAnnounceOptions(parent)
    -- Better parent handling using the utility function
    if not parent then
        parent = TWRA.UI:GetOptionsContainer()
        
        if not parent then
            TWRA:Debug("error", "No parent frame provided for SyncAndAnnounceOptions")
            -- Create a minimal placeholder frame so the function doesn't fail
            local placeholder = CreateFrame("Frame")
            placeholder:Hide()
            return placeholder
        end
    end
    
    -- Make sure parent is valid and has GetWidth
    if not parent.GetWidth then
        TWRA:Debug("error", "Invalid parent for SyncAndAnnounceOptions")
        local placeholder = CreateFrame("Frame")
        placeholder:Hide()
        return placeholder
    end
    
    -- Create a properly anchored container frame
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints(parent)
    
    -- Calculate available width
    local availableWidth = parent:GetWidth() - 10
    
    -- Remove redundant title and start with the first checkbox directly
    -- Live Sync Option - first checkbox with proper spacing from top
    local liveSync, liveSyncText = TWRA.UI:CreateCheckbox(
        frame, 
        "Live Section Sync", 
        TWRA_SavedVariables.options.liveSync,
        frame, "TOPLEFT", 10, -10  -- Position from top-left of frame with proper margin
    )
    
    -- Set OnClick script
    liveSync:SetScript("OnClick", function()
        local isChecked = liveSync:GetChecked()
        TWRA:SaveOption("liveSync", isChecked)
        TWRA:Debug("sync", "Live Section Sync " .. (isChecked and "enabled" or "disabled"))
    end)
    
    -- Tank Sync Option (indented)
    local tankSync, tankSyncText = TWRA.UI:CreateCheckbox(
        frame, 
        "Tank Sync", 
        TWRA_SavedVariables.options.tankSync,
        liveSync, "BOTTOMLEFT", 20, -15
    )
    
    -- Set OnClick script
    tankSync:SetScript("OnClick", function()
        local isChecked = tankSync:GetChecked()
        TWRA:SaveOption("tankSync", isChecked)
        TWRA:Debug("sync", "Tank Sync " .. (isChecked and "enabled" or "disabled"))
    end)
    
    -- Auto-Navigate Option with space after previous group
    local autoNav, autoNavText = TWRA.UI:CreateCheckbox(
        frame,
        "Auto-Navigate to Target",
        TWRA_SavedVariables.options.autoNavigate,
        tankSync, "BOTTOMLEFT", -20, -20
    )
    
    autoNav:SetScript("OnClick", function()
        local isChecked = autoNav:GetChecked()
        TWRA:SaveOption("autoNavigate", isChecked)
        TWRA:Debug("sync", "Auto-Navigate " .. (isChecked and "enabled" or "disabled"))
        
        -- Update scan frequency slider state
        if scanFreq then
            if isChecked then
                scanFreq:SetAlpha(1.0)
            else
                scanFreq:SetAlpha(0.5)
            end
        end
    end)
    
    -- Scan Frequency Slider with proper spacing
    local scanFreq = TWRA.UI:CreateSlider(
        frame,
        "Scan Frequency: %.1f",
        0.5, 3.0, 0.1,
        TWRA_SavedVariables.options.scanFrequency or 1.0,
        autoNav, "BOTTOMLEFT", 20, -20
    )
    
    -- Set initial alpha based on auto-navigate state
    if not TWRA_SavedVariables.options.autoNavigate then
        scanFreq:SetAlpha(0.5)
    end
    
    scanFreq:SetScript("OnValueChanged", function()
        local value = math.floor(scanFreq:GetValue() * 10) / 10  -- Round to 1 decimal place
        getglobal(scanFreq:GetName() .. "Text"):SetText("Scan Frequency: " .. string.format("%.1f", value))
        TWRA:SaveOption("scanFrequency", value)
    end)
    
    -- Create announcements section with good separator spacing
    local announceHeader = TWRA.UI:CreateSectionHeader(frame, "Announcements", 0, -30)
    
    -- Channel dropdown with proper label and spacing
    local channelLabel = TWRA.UI:CreateLabel(frame, "Announce Channel:", announceHeader, "BOTTOMLEFT", 0, -10)
    
    -- Channel values
    local channels = {"GROUP", "RAID", "RAID_WARNING", "SAY", "PARTY", "CHANNEL"}
    local channelLabels = {"Group", "Raid", "Raid Warning", "Say", "Party", "Custom Channel"}
    
    -- Create channel dropdown with appropriate spacing from label
    local channelDropdown = CreateFrame("Frame", "TWRA_ChannelDropdown", frame, "UIDropDownMenuTemplate")
    channelDropdown:SetPoint("TOPLEFT", channelLabel, "BOTTOMLEFT", -15, -5)
    UIDropDownMenu_SetWidth(math.min(160, availableWidth - 20), channelDropdown)
    
    local selectedChannel = TWRA_SavedVariables.options.announceChannel or "GROUP"
    
    -- Create custom channel input with proper vertical spacing
    local customChannelLabel = TWRA.UI:CreateLabel(frame, "Custom Channel Name:", channelDropdown, "BOTTOMLEFT", 15, -10)
    
    -- Create custom channel input box with adequate height
    local customChannelInput = CreateFrame("EditBox", "TWRA_CustomChannelInput", frame, "InputBoxTemplate")
    customChannelInput:SetPoint("TOPLEFT", customChannelLabel, "BOTTOMLEFT", 0, -5)
    customChannelInput:SetWidth(math.min(150, availableWidth - 20))
    customChannelInput:SetHeight(20)
    customChannelInput:SetAutoFocus(false)
    customChannelInput:SetText(TWRA_SavedVariables.options.customChannel or "")

    -- Fix for cursor position error - Only set cursor position after setting text
    if customChannelInput.SetCursorPosition then
        customChannelInput:SetCursorPosition(0)
    end

    -- Only show custom channel input if custom channel is selected
    if selectedChannel ~= "CHANNEL" then
        customChannelLabel:Hide()
        customChannelInput:Hide()
    end
    
    -- Channel dropdown initialization
    UIDropDownMenu_Initialize(channelDropdown, function()
        local info = {}
        for i, channelValue in ipairs(channels) do
            info.text = channelLabels[i]
            info.value = channelValue
            info.func = function()
                UIDropDownMenu_SetSelectedValue(channelDropdown, this.value)
                TWRA:SaveOption("announceChannel", this.value)
                
                -- Show/hide custom channel input based on selection
                if this.value == "CHANNEL" then
                    customChannelLabel:Show()
                    customChannelInput:Show()
                else
                    customChannelLabel:Hide()
                    customChannelInput:Hide()
                end
                
                TWRA:Debug("sync", "Announce channel set to " .. channelLabels[i])
            end
            
            if channelValue == selectedChannel then
                info.checked = true
            else
                info.checked = false
            end
            
            UIDropDownMenu_AddButton(info)
        end
    end)
    
    -- Set initial selection
    UIDropDownMenu_SetSelectedValue(channelDropdown, selectedChannel)
    
    -- Custom channel input save handler
    customChannelInput:SetScript("OnEnterPressed", function()
        local text = this:GetText()
        TWRA:SaveOption("customChannel", text)
        TWRA:Debug("sync", "Custom channel set to: " .. text)
        this:ClearFocus()
    end)
    
    customChannelInput:SetScript("OnEscapePressed", function()
        this:ClearFocus()
    end)
    
    return frame
end
