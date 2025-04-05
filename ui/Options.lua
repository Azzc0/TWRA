-- TWRA Options Module
TWRA = TWRA or {}

-- Helper function to safely enable/disable UI elements with null checking
function TWRA:SafeToggleUIElement(element, enabled, textElement)
    if not element then return end
    
    if enabled then
        -- Enable element
        if element.SetEnabled then
            element:SetEnabled(true)
        else
            -- Manual enable for various element types
            element:EnableMouse(true)
            element:SetAlpha(1.0)
        end
        
        -- Update text color
        if textElement then
            if textElement.SetTextColor then
                textElement:SetTextColor(1, 1, 1)
            end
        end
    else
        -- Disable element
        if element.SetEnabled then
            element:SetEnabled(false)
        else
            -- Manual disable for various element types
            element:EnableMouse(false)
            element:SetAlpha(0.5)
        end
        
        -- Update text color
        if textElement then
            if textElement.SetTextColor then
                textElement:SetTextColor(0.5, 0.5, 0.5)
            end
        end
    end
end

-- Initialize options with defaults if they don't exist
function TWRA:InitOptions()
    if not TWRA_SavedVariables.options then
        TWRA_SavedVariables.options = {
            liveSync = false,
            tankSync = true,
            autoNavigate = false,
            scanFrequency = 3,
            announceChannel = "GROUP",
            customChannel = ""
        }
    else
        -- Make sure new settings are initialized if they don't exist
        if TWRA_SavedVariables.options.liveSync == nil then
            TWRA_SavedVariables.options.liveSync = false
        end
        if TWRA_SavedVariables.options.tankSync == nil then
            TWRA_SavedVariables.options.tankSync = true
        end
        if TWRA_SavedVariables.options.autoNavigate == nil then
            TWRA_SavedVariables.options.autoNavigate = false
        end
        if TWRA_SavedVariables.options.scanFrequency == nil then
            TWRA_SavedVariables.options.scanFrequency = 3
        end
        if TWRA_SavedVariables.options.announceChannel == nil then
            TWRA_SavedVariables.options.announceChannel = "GROUP"
        end
        if TWRA_SavedVariables.options.customChannel == nil then
            TWRA_SavedVariables.options.customChannel = ""
        end
    end
    
    -- Ensure SYNC table exists
    if not self.SYNC then self.SYNC = {} end
    
    -- Sync in-memory options with saved options
    self.SYNC.liveSync = TWRA_SavedVariables.options.liveSync
    self.SYNC.tankSync = TWRA_SavedVariables.options.tankSync
    
    -- Debug message to verify sync state is loaded
    TWRA:Debug("sync"," Initialized with liveSync = " .. 
                                 (self.SYNC.liveSync and "enabled" or "disabled"))
    
    -- Initialize AutoMarker options
    if not self.AUTONAVIGATE then 
        self.AUTONAVIGATE = {
            enabled = false,
            scanFreq = 3
        }
    end
    
    -- Sync AutoMarker settings with saved options
    self.AUTONAVIGATE.enabled = TWRA_SavedVariables.options.autoNavigate
    self.AUTONAVIGATE.scanFreq = TWRA_SavedVariables.options.scanFrequency

    -- Initialize OSD settings if they don't exist
    if not TWRA_SavedVariables.options.osdPoint then
        TWRA_SavedVariables.options.osdPoint = "CENTER"
        TWRA_SavedVariables.options.osdXOffset = 0
        TWRA_SavedVariables.options.osdYOffset = 100
        TWRA_SavedVariables.options.osdScale = 1.0
        TWRA_SavedVariables.options.osdDuration = 2
        TWRA_SavedVariables.options.osdLocked = false
    end

    -- Initialize OSD module
    if self.InitOSD then 
        self:InitOSD() 
    end
end

-- Create options content using a three-column layout
function TWRA:CreateOptionsInMainFrame()
    -- Clear any existing options UI
    if self.optionsElements then
        for _, element in pairs(self.optionsElements) do
            if element.Hide then
                element:Hide()
                element:SetParent(nil)
            end
        end
    end
    
    -- Create a container for all options elements to track them
    self.optionsElements = {}
    
    -- Make sure main frame exists
    if not self.mainFrame then
        return
    end
    
    -- Set current view state
    self.currentView = "options"
    
    -- Reset the frame height to default value for options screen
    self.mainFrame:SetHeight(300)
    
    -- Create main title at the top
    local title = self.mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", self.mainFrame, "TOP", 0, -30)
    title:SetText("Options")
    table.insert(self.optionsElements, title)
    
    -- Create left column (Sync settings)
    local leftColumn = CreateFrame("Frame", nil, self.mainFrame)
    leftColumn:SetPoint("TOPLEFT", self.mainFrame, "TOPLEFT", 20, -50)
    leftColumn:SetWidth(240)
    leftColumn:SetHeight(400)
    table.insert(self.optionsElements, leftColumn)
    
    -- Create middle column (OSD settings)
    local middleColumn = CreateFrame("Frame", nil, self.mainFrame)
    middleColumn:SetPoint("TOP", self.mainFrame, "TOP", 0, -50)
    middleColumn:SetWidth(240)
    middleColumn:SetHeight(400)
    table.insert(self.optionsElements, middleColumn)
    
    -- Create right column (Import functionality)
    local rightColumn = CreateFrame("Frame", nil, self.mainFrame)
    rightColumn:SetPoint("TOPRIGHT", self.mainFrame, "TOPRIGHT", -20, -50)
    rightColumn:SetWidth(240)
    rightColumn:SetHeight(400)
    table.insert(self.optionsElements, rightColumn)
    
    -- Add column dividers
    local leftDivider = self.mainFrame:CreateTexture(nil, "BACKGROUND")
    leftDivider:SetTexture(0.3, 0.3, 0.3, 0.7)
    leftDivider:SetWidth(1)
    leftDivider:SetPoint("TOP", self.mainFrame, "TOP", -120, -60)
    leftDivider:SetPoint("BOTTOM", self.mainFrame, "BOTTOM", -120, 20)
    table.insert(self.optionsElements, leftDivider)
    
    local rightDivider = self.mainFrame:CreateTexture(nil, "BACKGROUND")
    rightDivider:SetTexture(0.3, 0.3, 0.3, 0.7)
    rightDivider:SetWidth(1)
    rightDivider:SetPoint("TOP", self.mainFrame, "TOP", 120, -60)
    rightDivider:SetPoint("BOTTOM", self.mainFrame, "BOTTOM", 120, 20)
    table.insert(self.optionsElements, rightDivider)
    
    -- ====================== LEFT COLUMN: SYNC & FEATURES ======================
    -- Column title
    local syncTitle = leftColumn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    syncTitle:SetPoint("TOPLEFT", leftColumn, "TOPLEFT", 0, 0)
    syncTitle:SetText("Synchronization & Features")
    table.insert(self.optionsElements, syncTitle)
    
    -- Live Sync Option
    local liveSync = CreateFrame("CheckButton", nil, leftColumn, "UICheckButtonTemplate")
    liveSync:SetPoint("TOPLEFT", syncTitle, "BOTTOMLEFT", 0, -10)
    liveSync:SetWidth(24)
    liveSync:SetHeight(24)
    table.insert(self.optionsElements, liveSync)
    
    local liveSyncText = leftColumn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    liveSyncText:SetPoint("LEFT", liveSync, "RIGHT", 5, 0)
    liveSyncText:SetText("Live Section Sync")
    table.insert(self.optionsElements, liveSyncText)
    
    -- Tank Sync Option (indented)
    local tankSyncCheckbox = CreateFrame("CheckButton", nil, leftColumn, "UICheckButtonTemplate")
    tankSyncCheckbox:SetPoint("TOPLEFT", liveSync, "BOTTOMLEFT", 20, -5)
    tankSyncCheckbox:SetWidth(24)
    tankSyncCheckbox:SetHeight(24)
    table.insert(self.optionsElements, tankSyncCheckbox)
    
    local tankSyncText = leftColumn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    tankSyncText:SetPoint("LEFT", tankSyncCheckbox, "RIGHT", 5, 0)
    tankSyncText:SetText("Tank Sync")
    table.insert(self.optionsElements, tankSyncText)
    
    -- Add info icon for tank sync with tooltip
    local tankSyncIcon, tankSyncIconFrame = self.UI:CreateIconWithTooltip(
        leftColumn, 
        "Interface\\TutorialFrame\\TutorialFrame-QuestionMark",
        "Tank Sync requires oRA2",
        "Automatically updates oRA2 tank assignments when navigating between sections",
        tankSyncText,
        0, 
        20, 20
    )
    table.insert(self.optionsElements, tankSyncIcon)
    table.insert(self.optionsElements, tankSyncIconFrame)
    
    -- AutoNavigate Option (reduced spacing)
    local autoNavigate = CreateFrame("CheckButton", nil, leftColumn, "UICheckButtonTemplate")
    autoNavigate:SetPoint("TOPLEFT", tankSyncCheckbox, "BOTTOMLEFT", -20, -8)
    autoNavigate:SetWidth(24)
    autoNavigate:SetHeight(24)
    table.insert(self.optionsElements, autoNavigate)
    
    local autoNavigateText = leftColumn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    autoNavigateText:SetPoint("LEFT", autoNavigate, "RIGHT", 5, 0)
    autoNavigateText:SetText("AutoNavigate")
    table.insert(self.optionsElements, autoNavigateText)
    
    -- Add info icon for autonavigate with tooltip
    local autoNavIcon, autoNavIconFrame = self.UI:CreateIconWithTooltip(
        leftColumn, 
        "Interface\\TutorialFrame\\TutorialFrame-QuestionMark",
        "Requires SuperWoW API",
        "Automatically navigates to sections when mobs are marked with raid targets",
        autoNavigateText,
        0,
        20, 20
    )
    table.insert(self.optionsElements, autoNavIcon)
    table.insert(self.optionsElements, autoNavIconFrame)
    
    -- Scan frequency slider (indented)
    local scanSlider = CreateFrame("Slider", "TWRA_ScanFrequencySlider", leftColumn, "OptionsSliderTemplate")
    scanSlider:SetPoint("TOPLEFT", autoNavigate, "BOTTOMLEFT", 20, -10)
    scanSlider:SetWidth(160)
    scanSlider:SetHeight(16)
    scanSlider:SetMinMaxValues(1, 10)
    scanSlider:SetValueStep(1)
    scanSlider:SetValue(self.AUTONAVIGATE.scanFreq or 3)
    scanSlider:SetOrientation("HORIZONTAL")
    table.insert(self.optionsElements, scanSlider)
    
    -- Set slider text
    getglobal(scanSlider:GetName() .. "Low"):SetText("Fast")
    getglobal(scanSlider:GetName() .. "High"):SetText("Slow")
    getglobal(scanSlider:GetName() .. "Text"):SetText("Scan: " .. (self.AUTONAVIGATE.scanFreq or 3) .. "s")
    
    -- Announcement section
    local announceTitle = leftColumn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    announceTitle:SetPoint("TOPLEFT", scanSlider, "BOTTOMLEFT", -20, -20)
    announceTitle:SetText("Announcement Channel")
    table.insert(self.optionsElements, announceTitle)
    
    -- Group Radio Button
    local groupRadio = CreateFrame("CheckButton", nil, leftColumn, "UIRadioButtonTemplate")
    groupRadio:SetPoint("TOPLEFT", announceTitle, "BOTTOMLEFT", 0, -10)
    groupRadio:SetWidth(16)
    groupRadio:SetHeight(16)
    table.insert(self.optionsElements, groupRadio)
    
    local groupText = leftColumn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    groupText:SetPoint("LEFT", groupRadio, "RIGHT", 5, 0)
    groupText:SetText("Group")
    table.insert(self.optionsElements, groupText)
    
    -- Add info icon for group option with tooltip
    local groupIcon, groupIconFrame = self.UI:CreateIconWithTooltip(
        leftColumn, 
        "Interface\\TutorialFrame\\TutorialFrame-QuestionMark",
        "Group Chat",
        "Uses PARTY or RAID chat depending on your current group type",
        groupText,
        0,
        20, 20
    )
    table.insert(self.optionsElements, groupIcon)
    table.insert(self.optionsElements, groupIconFrame)
    
    -- Channel Radio Button
    local channelRadio = CreateFrame("CheckButton", nil, leftColumn, "UIRadioButtonTemplate")
    channelRadio:SetPoint("TOPLEFT", groupRadio, "BOTTOMLEFT", 0, -5)
    channelRadio:SetWidth(16)
    channelRadio:SetHeight(16)
    table.insert(self.optionsElements, channelRadio)
    
    local channelText = leftColumn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    channelText:SetPoint("LEFT", channelRadio, "RIGHT", 5, 0)
    channelText:SetText("Channel:")
    table.insert(self.optionsElements, channelText)
    
    -- Make channel input wider
    -- Channel number input box - WIDER
    local channelInput = CreateFrame("EditBox", nil, leftColumn, "InputBoxTemplate")
    channelInput:SetWidth(160) -- Much wider
    channelInput:SetHeight(20)
    channelInput:SetPoint("LEFT", channelText, "RIGHT", 5, 0)
    channelInput:SetNumeric(false) -- Allow channel names
    channelInput:SetAutoFocus(false)
    channelInput:SetMaxLetters(20) -- Allow longer channel names
    channelInput:SetText(TWRA_SavedVariables.options.customChannel or "")
    channelInput:SetScript("OnEnterPressed", function() channelInput:ClearFocus() end)
    channelInput:SetScript("OnEscapePressed", function() channelInput:ClearFocus() end)
    channelInput:SetScript("OnTextChanged", function()
        TWRA_SavedVariables.options.customChannel = channelInput:GetText()
    end)
    table.insert(self.optionsElements, channelInput)
    
    -- Set initial radio button states
    local currentChannel = TWRA_SavedVariables.options.announceChannel or "GROUP"
    groupRadio:SetChecked(currentChannel == "GROUP")
    channelRadio:SetChecked(currentChannel == "CHANNEL")
    
    -- Enable/disable channel input based on selection
    if currentChannel ~= "CHANNEL" then
        -- Use EnableMouse instead of Disable
        channelInput:EnableMouse(false)
        channelInput:SetTextColor(0.5, 0.5, 0.5)
    else
        channelInput:EnableMouse(true)
        channelInput:SetTextColor(1, 1, 1)
    end
    
    -- ====================== MIDDLE COLUMN: OSD SETTINGS ======================
    -- Column title
    local osdTitle = middleColumn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    osdTitle:SetPoint("TOPLEFT", middleColumn, "TOPLEFT", 10, 0) -- Added 10 padding on left
    osdTitle:SetText("On-Screen Display")
    table.insert(self.optionsElements, osdTitle)
    
    -- Lock Position checkbox
    local lockOSD = CreateFrame("CheckButton", nil, middleColumn, "UICheckButtonTemplate")
    lockOSD:SetPoint("TOPLEFT", osdTitle, "BOTTOMLEFT", 0, -10)
    lockOSD:SetWidth(24)
    lockOSD:SetHeight(24)
    table.insert(self.optionsElements, lockOSD)
    
    local lockOSDText = middleColumn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lockOSDText:SetPoint("LEFT", lockOSD, "RIGHT", 5, 0)
    lockOSDText:SetText("Lock Position")
    table.insert(self.optionsElements, lockOSDText)
    
    -- OSD Duration
    local durationSlider = CreateFrame("Slider", "TWRA_OSDDurationSlider", middleColumn, "OptionsSliderTemplate")
    durationSlider:SetPoint("TOPLEFT", lockOSD, "BOTTOMLEFT", 0, -20)
    durationSlider:SetWidth(180)
    durationSlider:SetHeight(16)
    durationSlider:SetMinMaxValues(1, 10)
    durationSlider:SetValueStep(0.5)
    durationSlider:SetValue(TWRA_SavedVariables.options.osdDuration or 2)
    durationSlider:SetOrientation("HORIZONTAL")
    table.insert(self.optionsElements, durationSlider)
    
    -- Set slider text
    getglobal(durationSlider:GetName() .. "Low"):SetText("1s")
    getglobal(durationSlider:GetName() .. "High"):SetText("10s")
    getglobal(durationSlider:GetName() .. "Text"):SetText("Display Duration: " .. 
                                            (TWRA_SavedVariables.options.osdDuration or 2) .. " seconds")
    
    -- OSD Scale
    local scaleSlider = CreateFrame("Slider", "TWRA_OSDScaleSlider", middleColumn, "OptionsSliderTemplate")
    scaleSlider:SetPoint("TOPLEFT", durationSlider, "BOTTOMLEFT", 0, -20)
    scaleSlider:SetWidth(180)
    scaleSlider:SetHeight(16)
    scaleSlider:SetMinMaxValues(0.5, 2.0)
    scaleSlider:SetValueStep(0.1)
    scaleSlider:SetValue(TWRA_SavedVariables.options.osdScale or 1.0)
    scaleSlider:SetOrientation("HORIZONTAL")
    table.insert(self.optionsElements, scaleSlider)
    
    -- Set slider text
    getglobal(scaleSlider:GetName() .. "Low"):SetText("Small")
    getglobal(scaleSlider:GetName() .. "High"):SetText("Large")
    getglobal(scaleSlider:GetName() .. "Text"):SetText("Scale: " .. 
                                            (TWRA_SavedVariables.options.osdScale or 1.0))
    
    -- OSD action buttons in a row
    local testOSDBtn = CreateFrame("Button", nil, middleColumn, "UIPanelButtonTemplate")
    testOSDBtn:SetWidth(80)  -- Reduced width
    testOSDBtn:SetHeight(22)
    testOSDBtn:SetPoint("TOPLEFT", scaleSlider, "BOTTOMLEFT", 0, -15)
    testOSDBtn:SetText("Test")
    table.insert(self.optionsElements, testOSDBtn)
    
    local resetPosBtn = CreateFrame("Button", nil, middleColumn, "UIPanelButtonTemplate")
    resetPosBtn:SetWidth(80)  -- Reduced width
    resetPosBtn:SetHeight(22)
    resetPosBtn:SetPoint("LEFT", testOSDBtn, "RIGHT", 10, 0)
    resetPosBtn:SetText("Reset")
    table.insert(self.optionsElements, resetPosBtn)
    
    -- ====================== RIGHT COLUMN: IMPORT ======================
    -- Column title
    local importTitle = rightColumn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    importTitle:SetPoint("TOPLEFT", rightColumn, "TOPLEFT", 0, 0)
    importTitle:SetText("Import Assignments")
    table.insert(self.optionsElements, importTitle)
    
    -- Create import box container
    local container = CreateFrame("Frame", nil, rightColumn)
    container:SetWidth(220)
    container:SetHeight(160)
    container:SetPoint("TOPLEFT", importTitle, "BOTTOMLEFT", 0, -10)
    table.insert(self.optionsElements, container)
    
    -- Create a simple ScrollFrame with no visible scrollbar
    local scrollFrame = CreateFrame("ScrollFrame", nil, container)
    scrollFrame:SetAllPoints(container)
    table.insert(self.optionsElements, scrollFrame)
    
    -- Create the edit box
    local importBox = CreateFrame("EditBox", nil, scrollFrame)
    importBox:SetWidth(220)  -- Match container width
    importBox:SetFontObject(ChatFontNormal)
    importBox:SetMultiLine(true)
    importBox:SetAutoFocus(false)
    importBox:EnableMouse(true)
    importBox:SetScript("OnEscapePressed", function() importBox:ClearFocus() end)
    scrollFrame:SetScrollChild(importBox)
    table.insert(self.optionsElements, importBox)
    
    -- Add backdrop to container
    local scrollBg = CreateFrame("Frame", nil, container)
    scrollBg:SetPoint("TOPLEFT", -5, 5)
    scrollBg:SetPoint("BOTTOMRIGHT", 5, -5)
    scrollBg:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    scrollBg:SetBackdropColor(0, 0, 0, 0.6)
    table.insert(self.optionsElements, scrollBg)
    
    -- Create import buttons
    local importBtn = CreateFrame("Button", nil, rightColumn, "UIPanelButtonTemplate")
    importBtn:SetWidth(80)
    importBtn:SetHeight(22)
    importBtn:SetPoint("TOPLEFT", container, "BOTTOMLEFT", 0, -10)
    importBtn:SetText("Import")
    table.insert(self.optionsElements, importBtn)
    
    local clearBtn = CreateFrame("Button", nil, rightColumn, "UIPanelButtonTemplate")
    clearBtn:SetWidth(70)  -- Reduced width
    clearBtn:SetHeight(22)
    clearBtn:SetPoint("LEFT", importBtn, "RIGHT", 5, 0)
    clearBtn:SetText("Clear")
    table.insert(self.optionsElements, clearBtn)
    
    local exampleBtn = CreateFrame("Button", nil, rightColumn, "UIPanelButtonTemplate")
    exampleBtn:SetWidth(70)  -- Reduced width
    exampleBtn:SetHeight(22)
    exampleBtn:SetPoint("LEFT", clearBtn, "RIGHT", 5, 0)
    exampleBtn:SetText("Example")
    table.insert(self.optionsElements, exampleBtn)
    
    -- ====================== WIRE UP BEHAVIORS ======================
    
    -- Live Sync checkbox behavior
    liveSync:SetChecked(self.SYNC.liveSync)
    liveSync:SetScript("OnClick", function()
        self.SYNC.liveSync = liveSync:GetChecked()
        TWRA_SavedVariables.options.liveSync = self.SYNC.liveSync
        
        -- Update tank sync UI state - tank sync depends on live sync
        if not self.SYNC.liveSync then
            -- If turning off Live Sync, also turn off Tank Sync
            tankSyncCheckbox:SetChecked(false)
            self.SYNC.tankSync = false
            TWRA_SavedVariables.options.tankSync = false
            
            -- Disable the Tank Sync UI
            self:SafeToggleUIElement(tankSyncCheckbox, false, tankSyncText)
        else
            -- Re-enable the Tank Sync UI when Live Sync is turned on
            self:SafeToggleUIElement(tankSyncCheckbox, true, tankSyncText)
        end
    end)
    
    -- Tank Sync checkbox behavior
    local oRA2Available = self:IsORA2Available()
    tankSyncCheckbox:SetChecked(self.SYNC.tankSync)
    tankSyncCheckbox:SetScript("OnClick", function()
        if not oRA2Available then
            tankSyncCheckbox:SetChecked(false)
            DEFAULT_CHAT_FRAME:AddMessage("TWRA: Tank sync requires oRA2, which is not installed.")
            return
        end
        
        if not self.SYNC.liveSync then
            tankSyncCheckbox:SetChecked(false)
            DEFAULT_CHAT_FRAME:AddMessage("TWRA: Tank sync requires Live Sync to be enabled.")
            return
        end
        
        self.SYNC.tankSync = tankSyncCheckbox:GetChecked()
        TWRA_SavedVariables.options.tankSync = self.SYNC.tankSync
    end)
    
    -- Update initial Tank Sync state based on Live Sync
    if not self.SYNC.liveSync or not oRA2Available then
        self:SafeToggleUIElement(tankSyncCheckbox, false, tankSyncText)
    else
        self:SafeToggleUIElement(tankSyncCheckbox, true, tankSyncText)
    end
    
    -- AutoNavigate checkbox behavior
    local superWowAvailable = self:CheckSuperWoWSupport(true)
    autoNavigate:SetChecked(self.AUTONAVIGATE.enabled)
    autoNavigate:SetScript("OnClick", function()
        -- Toggle AutoNavigate without opening main window
        self:ToggleAutoNavigate(autoNavigate:GetChecked())
    end)
    
    -- Update AutoNavigate UI state
    if not superWowAvailable then
        autoNavigateText:SetTextColor(0.5, 0.5, 0.5)
        getglobal(scanSlider:GetName() .. "Text"):SetTextColor(0.5, 0.5, 0.5)
        getglobal(scanSlider:GetName() .. "Low"):SetTextColor(0.5, 0.5, 0.5)
        getglobal(scanSlider:GetName() .. "High"):SetTextColor(0.5, 0.5, 0.5)
        scanSlider:EnableMouse(false)
    elseif not self.AUTONAVIGATE.enabled then
        getglobal(scanSlider:GetName() .. "Text"):SetTextColor(0.5, 0.5, 0.5)
        getglobal(scanSlider:GetName() .. "Low"):SetTextColor(0.5, 0.5, 0.5)
        getglobal(scanSlider:GetName() .. "High"):SetTextColor(0.5, 0.5, 0.5)
        scanSlider:EnableMouse(false)
    end
    
    -- Scan frequency slider behavior
    scanSlider:SetScript("OnValueChanged", function()
        local value = math.floor(scanSlider:GetValue())
        self.AUTONAVIGATE.scanFreq = value
        TWRA_SavedVariables.options.scanFrequency = value
        getglobal(scanSlider:GetName() .. "Text"):SetText("Scan: " .. value .. "s")
        
        -- Restart AutoNavigate timer with new frequency if enabled
        if self.AUTONAVIGATE.enabled then
            self:StartAutoNavigate()
        end
    end)
    
    -- Radio button behaviors for announcement channels - fixed radio button behavior
    groupRadio:SetScript("OnClick", function()
        if not groupRadio:GetChecked() then
            groupRadio:SetChecked(true)
        end
        channelRadio:SetChecked(false)
        TWRA_SavedVariables.options.announceChannel = "GROUP"
        
        -- Disable channel input
        channelInput:SetTextColor(0.5, 0.5, 0.5)
        channelInput:EnableMouse(false)
    end)
    
    channelRadio:SetScript("OnClick", function()
        if not channelRadio:GetChecked() then
            channelRadio:SetChecked(true)
        end
        groupRadio:SetChecked(false)
        TWRA_SavedVariables.options.announceChannel = "CHANNEL"
        
        -- Enable channel input
        channelInput:SetTextColor(1, 1, 1)
        channelInput:EnableMouse(true)
    end)
    
    -- Save channel number when it changes
    channelInput:SetScript("OnTextChanged", function()
        local num = tonumber(channelInput:GetText())
        if num then
            TWRA_SavedVariables.options.channelNumber = num
        end
    end)
    
    -- OSD Lock checkbox behavior
    lockOSD:SetChecked(self.OSD.locked)
    lockOSD:SetScript("OnClick", function()
        TWRA_SavedVariables.options.osdLocked = lockOSD:GetChecked()
        self.OSD.locked = lockOSD:GetChecked()
    end)
    
    -- Duration slider behavior
    durationSlider:SetScript("OnValueChanged", function()
        local value = math.floor(durationSlider:GetValue() * 2) / 2  -- Round to nearest 0.5
        TWRA_SavedVariables.options.osdDuration = value
        self.OSD.duration = value
        getglobal(durationSlider:GetName() .. "Text"):SetText("Display Duration: " .. value .. " seconds")
    end)
    
    -- Scale slider behavior
    scaleSlider:SetScript("OnValueChanged", function()
        local value = math.floor(scaleSlider:GetValue() * 10) / 10  -- Round to nearest 0.1
        TWRA_SavedVariables.options.osdScale = value
        self.OSD.scale = value
        getglobal(scaleSlider:GetName() .. "Text"):SetText("Scale: " .. value)
        
        -- Apply scale to overlay if it exists
        if self.sectionOverlay then
            self.sectionOverlay:SetScale(value)
        end
    end)
    
    -- OSD Test button behavior
    testOSDBtn:SetScript("OnClick", function()
        self:TestOSD()
    end)
    
    -- OSD Reset button behavior
    resetPosBtn:SetScript("OnClick", function()
        self:ResetOSDPosition()
    end)
    
    -- Import button behavior - simplified approach
    importBtn:SetScript("OnClick", function()
        local importText = importBox:GetText()
        if not importText or importText == "" then
            TWRA:Debug("data", "No data to import")
            return
        end
        
        -- Check if we have navigation information
        local currentSectionName = nil
        local currentSectionIndex = 1
        
        -- Capture current section info before import
        if TWRA_SavedVariables and TWRA_SavedVariables.assignments then
            currentSectionName = TWRA_SavedVariables.assignments.currentSectionName
            currentSectionIndex = TWRA_SavedVariables.assignments.currentSection or 1
            TWRA:Debug("data", "Import with saved section: " .. 
                       (currentSectionName or "unnamed") .. " (" .. currentSectionIndex .. ")")
        end
        
        -- Try to decode the data first
        local decodedData = TWRA:DecodeBase64(importText)
        if not decodedData then
            TWRA:Debug("data","Failed to decode data")
            return
        end
        
        -- Only clear data after successful decode
        TWRA:ClearData()
        
        -- Save the data (will rebuild navigation)
        TWRA:SaveAssignments(decodedData, importText)
        
        -- Now restore section preference based on saved info
        if TWRA.navigation and TWRA.navigation.handlers then
            local sectionFound = false
            
            -- First try to find by name (more reliable)
            if currentSectionName then
                for i, name in ipairs(TWRA.navigation.handlers) do
                    if name == currentSectionName then
                        TWRA.navigation.currentIndex = i
                        TWRA:SaveCurrentSection()
                        TWRA:Debug("data", "Restored section by name: " .. name .. " (index: " .. i .. ")")
                        sectionFound = true
                        break
                    end
                end
            end
            
            -- If not found by name, try by index as fallback
            if not sectionFound and currentSectionIndex then
                local maxIndex = table.getn(TWRA.navigation.handlers)
                if maxIndex > 0 then
                    local safeIndex = math.min(currentSectionIndex, maxIndex)
                    TWRA.navigation.currentIndex = safeIndex
                    TWRA:SaveCurrentSection()
                    TWRA:Debug("data", "Restored section by index: " .. safeIndex)
                end
            end
        end
        
        TWRA:Debug("data", "Assignment data imported successfully")
        importBox:SetText("")
        
        -- Switch to main view to show the imported data
        TWRA:ShowMainView()
    end)
    
    -- Clear button behavior
    clearBtn:SetScript("OnClick", function()
        importBox:SetText("")
    end)
    
    -- Example button behavior
    exampleBtn:SetScript("OnClick", function()
        self:LoadExampleData()
        TWRA:Debug("data", "Example data loaded successfully!")
        self:ShowMainView()
        self.optionsButton:SetText("Options")
    end)
end

-- Options panel for TWRA
TWRA = TWRA or {}

-- Create the options panel
function TWRA:CreateOptionsPanel()
    if self.optionsPanel then
        return self.optionsPanel
    end
    
    self:Debug("ui", "Creating options panel")
    
    -- Create the main options panel with error handling
    local panel = nil
    local success = pcall(function()
        panel = CreateFrame("Frame", nil, self.mainFrame)
        panel:SetPoint("TOPLEFT", 10, -30)
        panel:SetPoint("BOTTOMRIGHT", -10, 10)
    end)
    
    if not success or not panel then
        self:Error("Failed to create options panel frame")
        return nil
    end
    
    -- Create title
    local title = nil
    success = pcall(function()
        title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOP", 0, 0)
        title:SetText("Options")
    end)
    
    if not success then
        self:Error("Failed to create options panel title")
    end
    
    -- Create left column (Sync settings)
    local leftColumn = CreateFrame("Frame", nil, panel)
    leftColumn:SetWidth(240)
    leftColumn:SetPoint("TOPLEFT", panel, "TOPLEFT", 20, -30)
    leftColumn:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 20, 10)
    
    -- Create middle column (OSD settings)
    local middleColumn = CreateFrame("Frame", nil, panel)
    middleColumn:SetWidth(240)
    middleColumn:SetPoint("TOP", panel, "TOP", 0, -30)
    middleColumn:SetPoint("BOTTOM", panel, "BOTTOM", 0, 10)
    
    -- Create right column (Import functionality)
    local rightColumn = CreateFrame("Frame", nil, panel)
    rightColumn:SetWidth(240)
    rightColumn:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -20, -30)
    rightColumn:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -20, 10)
    
    -- Add column dividers
    local leftDivider = panel:CreateTexture(nil, "BACKGROUND")
    leftDivider:SetTexture(0.3, 0.3, 0.3, 0.7)
    leftDivider:SetWidth(1)
    leftDivider:SetPoint("TOP", panel, "TOP", -120, -40)
    leftDivider:SetPoint("BOTTOM", panel, "BOTTOM", -120, 20)
    
    local rightDivider = panel:CreateTexture(nil, "BACKGROUND")
    rightDivider:SetTexture(0.3, 0.3, 0.3, 0.7)
    rightDivider:SetWidth(1)
    rightDivider:SetPoint("TOP", panel, "TOP", 120, -40)
    rightDivider:SetPoint("BOTTOM", panel, "BOTTOM", 120, 20)
    
    -- ====================== LEFT COLUMN: SYNC & FEATURES ======================
    -- Column title
    local syncTitle = leftColumn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    syncTitle:SetPoint("TOPLEFT", leftColumn, "TOPLEFT", 0, 0)
    syncTitle:SetText("Synchronization & Features")
    
    -- Live Sync Option
    local liveSync = CreateFrame("CheckButton", nil, leftColumn, "UICheckButtonTemplate")
    liveSync:SetPoint("TOPLEFT", syncTitle, "BOTTOMLEFT", 0, -10)
    liveSync:SetWidth(24)
    liveSync:SetHeight(24)
    
    local liveSyncText = leftColumn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    liveSyncText:SetPoint("LEFT", liveSync, "RIGHT", 5, 0)
    liveSyncText:SetText("Live Section Sync")
    
    -- Tank Sync Option (indented)
    local tankSyncCheckbox = CreateFrame("CheckButton", nil, leftColumn, "UICheckButtonTemplate")
    tankSyncCheckbox:SetPoint("TOPLEFT", liveSync, "BOTTOMLEFT", 20, -5)
    tankSyncCheckbox:SetWidth(24)
    tankSyncCheckbox:SetHeight(24)
    
    local tankSyncText = leftColumn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    tankSyncText:SetPoint("LEFT", tankSyncCheckbox, "RIGHT", 5, 0)
    tankSyncText:SetText("Tank Sync")
    
    -- Add info icon for tank sync with tooltip
    local tankSyncIcon, tankSyncIconFrame = self.UI:CreateIconWithTooltip(
        leftColumn, 
        "Interface\\TutorialFrame\\TutorialFrame-QuestionMark",
        "Tank Sync requires oRA2",
        "Automatically updates oRA2 tank assignments when navigating between sections",
        tankSyncText,
        0, 
        20, 20
    )
    
    -- AutoNavigate Option (reduced spacing)
    local autoNavigate = CreateFrame("CheckButton", nil, leftColumn, "UICheckButtonTemplate")
    autoNavigate:SetPoint("TOPLEFT", tankSyncCheckbox, "BOTTOMLEFT", -20, -8)
    autoNavigate:SetWidth(24)
    autoNavigate:SetHeight(24)
    
    local autoNavigateText = leftColumn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    autoNavigateText:SetPoint("LEFT", autoNavigate, "RIGHT", 5, 0)
    autoNavigateText:SetText("AutoNavigate")
    
    -- Add info icon for autonavigate with tooltip
    local autoNavIcon, autoNavIconFrame = self.UI:CreateIconWithTooltip(
        leftColumn, 
        "Interface\\TutorialFrame\\TutorialFrame-QuestionMark",
        "Requires SuperWoW API",
        "Automatically navigates to sections when mobs are marked with raid targets",
        autoNavigateText,
        0,
        20, 20
    )
    
    -- Scan frequency slider (indented)
    local scanSlider = CreateFrame("Slider", "TWRA_ScanFrequencySlider", leftColumn, "OptionsSliderTemplate")
    scanSlider:SetPoint("TOPLEFT", autoNavigate, "BOTTOMLEFT", 20, -10)
    scanSlider:SetWidth(160)
    scanSlider:SetHeight(16)
    scanSlider:SetMinMaxValues(1, 10)
    scanSlider:SetValueStep(1)
    scanSlider:SetValue(self.AUTONAVIGATE.scanFreq or 3)
    scanSlider:SetOrientation("HORIZONTAL")
    
    -- Set slider text
    getglobal(scanSlider:GetName() .. "Low"):SetText("Fast")
    getglobal(scanSlider:GetName() .. "High"):SetText("Slow")
    getglobal(scanSlider:GetName() .. "Text"):SetText("Scan: " .. (self.AUTONAVIGATE.scanFreq or 3) .. "s")
    
    -- Announcement section
    local announceTitle = leftColumn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    announceTitle:SetPoint("TOPLEFT", scanSlider, "BOTTOMLEFT", -20, -20)
    announceTitle:SetText("Announcement Channel")
    
    -- Group Radio Button
    local groupRadio = CreateFrame("CheckButton", nil, leftColumn, "UIRadioButtonTemplate")
    groupRadio:SetPoint("TOPLEFT", announceTitle, "BOTTOMLEFT", 0, -10)
    groupRadio:SetWidth(16)
    groupRadio:SetHeight(16)
    
    local groupText = leftColumn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    groupText:SetPoint("LEFT", groupRadio, "RIGHT", 5, 0)
    groupText:SetText("Group")
    
    -- Add info icon for group option with tooltip
    local groupIcon, groupIconFrame = self.UI:CreateIconWithTooltip(
        leftColumn, 
        "Interface\\TutorialFrame\\TutorialFrame-QuestionMark",
        "Group Chat",
        "Uses PARTY or RAID chat depending on your current group type",
        groupText,
        0,
        20, 20
    )
    
    -- Channel Radio Button
    local channelRadio = CreateFrame("CheckButton", nil, leftColumn, "UIRadioButtonTemplate")
    channelRadio:SetPoint("TOPLEFT", groupRadio, "BOTTOMLEFT", 0, -5)
    channelRadio:SetWidth(16)
    channelRadio:SetHeight(16)
    
    local channelText = leftColumn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    channelText:SetPoint("LEFT", channelRadio, "RIGHT", 5, 0)
    channelText:SetText("Channel:")
    
    -- Make channel input wider
    -- Channel number input box - WIDER
    local channelInput = CreateFrame("EditBox", nil, leftColumn, "InputBoxTemplate")
    channelInput:SetWidth(160) -- Much wider
    channelInput:SetHeight(20)
    channelInput:SetPoint("LEFT", channelText, "RIGHT", 5, 0)
    channelInput:SetNumeric(false) -- Allow channel names
    channelInput:SetAutoFocus(false)
    channelInput:SetMaxLetters(20) -- Allow longer channel names
    channelInput:SetText(TWRA_SavedVariables.options.customChannel or "")
    channelInput:SetScript("OnEnterPressed", function() channelInput:ClearFocus() end)
    channelInput:SetScript("OnEscapePressed", function() channelInput:ClearFocus() end)
    channelInput:SetScript("OnTextChanged", function()
        TWRA_SavedVariables.options.customChannel = channelInput:GetText()
    end)
    
    -- Set initial radio button states
    local currentChannel = TWRA_SavedVariables.options.announceChannel or "GROUP"
    groupRadio:SetChecked(currentChannel == "GROUP")
    channelRadio:SetChecked(currentChannel == "CHANNEL")
    
    -- Enable/disable channel input based on selection
    if currentChannel ~= "CHANNEL" then
        -- Use EnableMouse instead of Disable
        channelInput:EnableMouse(false)
        channelInput:SetTextColor(0.5, 0.5, 0.5)
    else
        channelInput:EnableMouse(true)
        channelInput:SetTextColor(1, 1, 1)
    end
    
    -- ====================== MIDDLE COLUMN: OSD SETTINGS ======================
    -- Column title
    local osdTitle = middleColumn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    osdTitle:SetPoint("TOPLEFT", middleColumn, "TOPLEFT", 10, 0) -- Added 10 padding on left
    osdTitle:SetText("On-Screen Display")
    
    -- Lock Position checkbox
    local lockOSD = CreateFrame("CheckButton", nil, middleColumn, "UICheckButtonTemplate")
    lockOSD:SetPoint("TOPLEFT", osdTitle, "BOTTOMLEFT", 0, -10)
    lockOSD:SetWidth(24)
    lockOSD:SetHeight(24)
    
    local lockOSDText = middleColumn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lockOSDText:SetPoint("LEFT", lockOSD, "RIGHT", 5, 0)
    lockOSDText:SetText("Lock Position")
    
    -- OSD Duration
    local durationSlider = CreateFrame("Slider", "TWRA_OSDDurationSlider", middleColumn, "OptionsSliderTemplate")
    durationSlider:SetPoint("TOPLEFT", lockOSD, "BOTTOMLEFT", 0, -20)
    durationSlider:SetWidth(180)
    durationSlider:SetHeight(16)
    durationSlider:SetMinMaxValues(1, 10)
    durationSlider:SetValueStep(0.5)
    durationSlider:SetValue(TWRA_SavedVariables.options.osdDuration or 2)
    durationSlider:SetOrientation("HORIZONTAL")
    
    -- Set slider text
    getglobal(durationSlider:GetName() .. "Low"):SetText("1s")
    getglobal(durationSlider:GetName() .. "High"):SetText("10s")
    getglobal(durationSlider:GetName() .. "Text"):SetText("Display Duration: " .. 
                                            (TWRA_SavedVariables.options.osdDuration or 2) .. " seconds")
    
    -- OSD Scale
    local scaleSlider = CreateFrame("Slider", "TWRA_OSDScaleSlider", middleColumn, "OptionsSliderTemplate")
    scaleSlider:SetPoint("TOPLEFT", durationSlider, "BOTTOMLEFT", 0, -20)
    scaleSlider:SetWidth(180)
    scaleSlider:SetHeight(16)
    scaleSlider:SetMinMaxValues(0.5, 2.0)
    scaleSlider:SetValueStep(0.1)
    scaleSlider:SetValue(TWRA_SavedVariables.options.osdScale or 1.0)
    scaleSlider:SetOrientation("HORIZONTAL")
    
    -- Set slider text
    getglobal(scaleSlider:GetName() .. "Low"):SetText("Small")
    getglobal(scaleSlider:GetName() .. "High"):SetText("Large")
    getglobal(scaleSlider:GetName() .. "Text"):SetText("Scale: " .. 
                                            (TWRA_SavedVariables.options.osdScale or 1.0))
    
    -- OSD action buttons in a row
    local testOSDBtn = CreateFrame("Button", nil, middleColumn, "UIPanelButtonTemplate")
    testOSDBtn:SetWidth(80)  -- Reduced width
    testOSDBtn:SetHeight(22)
    testOSDBtn:SetPoint("TOPLEFT", scaleSlider, "BOTTOMLEFT", 0, -15)
    testOSDBtn:SetText("Test")
    
    local resetPosBtn = CreateFrame("Button", nil, middleColumn, "UIPanelButtonTemplate")
    resetPosBtn:SetWidth(80)  -- Reduced width
    resetPosBtn:SetHeight(22)
    resetPosBtn:SetPoint("LEFT", testOSDBtn, "RIGHT", 10, 0)
    resetPosBtn:SetText("Reset")
    
    -- ====================== RIGHT COLUMN: IMPORT ======================
    -- Column title
    local importTitle = rightColumn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    importTitle:SetPoint("TOPLEFT", rightColumn, "TOPLEFT", 0, 0)
    importTitle:SetText("Import Assignments")
    
    -- Create import box container
    local container = CreateFrame("Frame", nil, rightColumn)
    container:SetWidth(220)
    container:SetHeight(160)
    container:SetPoint("TOPLEFT", importTitle, "BOTTOMLEFT", 0, -10)
    
    -- Create a simple ScrollFrame with no visible scrollbar
    local scrollFrame = CreateFrame("ScrollFrame", nil, container)
    scrollFrame:SetAllPoints(container)
    
    -- Create the edit box
    local importBox = CreateFrame("EditBox", nil, scrollFrame)
    importBox:SetWidth(220)  -- Match container width
    importBox:SetFontObject(ChatFontNormal)
    importBox:SetMultiLine(true)
    importBox:SetAutoFocus(false)
    importBox:EnableMouse(true)
    importBox:SetScript("OnEscapePressed", function() importBox:ClearFocus() end)
    scrollFrame:SetScrollChild(importBox)
    
    -- Add backdrop to container
    local scrollBg = CreateFrame("Frame", nil, container)
    scrollBg:SetPoint("TOPLEFT", -5, 5)
    scrollBg:SetPoint("BOTTOMRIGHT", 5, -5)
    scrollBg:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    scrollBg:SetBackdropColor(0, 0, 0, 0.6)
    
    -- Create import buttons
    local importBtn = CreateFrame("Button", nil, rightColumn, "UIPanelButtonTemplate")
    importBtn:SetWidth(80)
    importBtn:SetHeight(22)
    importBtn:SetPoint("TOPLEFT", container, "BOTTOMLEFT", 0, -10)
    importBtn:SetText("Import")
    
    local clearBtn = CreateFrame("Button", nil, rightColumn, "UIPanelButtonTemplate")
    clearBtn:SetWidth(70)  -- Reduced width
    clearBtn:SetHeight(22)
    clearBtn:SetPoint("LEFT", importBtn, "RIGHT", 5, 0)
    clearBtn:SetText("Clear")
    
    local exampleBtn = CreateFrame("Button", nil, rightColumn, "UIPanelButtonTemplate")
    exampleBtn:SetWidth(70)  -- Reduced width
    exampleBtn:SetHeight(22)
    exampleBtn:SetPoint("LEFT", clearBtn, "RIGHT", 5, 0)
    exampleBtn:SetText("Example")
    
    -- ====================== WIRE UP BEHAVIORS ======================
    
    -- Live Sync checkbox behavior
    liveSync:SetChecked(self.SYNC.liveSync)
    liveSync:SetScript("OnClick", function()
        self.SYNC.liveSync = liveSync:GetChecked()
        TWRA_SavedVariables.options.liveSync = self.SYNC.liveSync
        
        -- Update tank sync UI state - tank sync depends on live sync
        if not self.SYNC.liveSync then
            -- If turning off Live Sync, also turn off Tank Sync
            tankSyncCheckbox:SetChecked(false)
            self.SYNC.tankSync = false
            TWRA_SavedVariables.options.tankSync = false
            
            -- Disable the Tank Sync UI
            self:SafeToggleUIElement(tankSyncCheckbox, false, tankSyncText)
        else
            -- Re-enable the Tank Sync UI when Live Sync is turned on
            self:SafeToggleUIElement(tankSyncCheckbox, true, tankSyncText)
        end
    end)
    
    -- Tank Sync checkbox behavior
    local oRA2Available = self:IsORA2Available()
    tankSyncCheckbox:SetChecked(self.SYNC.tankSync)
    tankSyncCheckbox:SetScript("OnClick", function()
        if not oRA2Available then
            tankSyncCheckbox:SetChecked(false)
            self:Debug("error", "Tank sync requires oRA2, which is not installed.")
            return
        end
        
        if not self.SYNC.liveSync then
            tankSyncCheckbox:SetChecked(false)
            self:Debug("error", "Tank sync requires Live Sync to be enabled.")
            return
        end
        
        self.SYNC.tankSync = tankSyncCheckbox:GetChecked()
        TWRA_SavedVariables.options.tankSync = self.SYNC.tankSync
    end)
    
    -- Update initial Tank Sync state based on Live Sync
    if not self.SYNC.liveSync or not oRA2Available then
        self:SafeToggleUIElement(tankSyncCheckbox, false, tankSyncText)
    else
        self:SafeToggleUIElement(tankSyncCheckbox, true, tankSyncText)
    end
    
    -- AutoNavigate checkbox behavior
    local superWowAvailable = (SUPERWOW_VERSION ~= nil)
    autoNavigate:SetChecked(self.AUTONAVIGATE and self.AUTONAVIGATE.enabled)
    autoNavigate:SetScript("OnClick", function()
        -- Check if SuperWoW is available
        if not superWowAvailable then
            autoNavigate:SetChecked(false)
            self:Debug("error", "AutoNavigate requires SuperWoW API, which is not available.")
            return
        end
        
        -- Update AutoNavigate settings
        if self.AUTONAVIGATE then
            self.AUTONAVIGATE.enabled = autoNavigate:GetChecked()
            TWRA_SavedVariables.options.autoNavigate = self.AUTONAVIGATE.enabled
            
            -- Enable/disable scan frequency slider
            if self.AUTONAVIGATE.enabled then
                scanSlider:EnableMouse(true)
                getglobal(scanSlider:GetName() .. "Text"):SetTextColor(1, 1, 1)
                getglobal(scanSlider:GetName() .. "Low"):SetTextColor(1, 1, 1)
                getglobal(scanSlider:GetName() .. "High"):SetTextColor(1, 1, 1)
            else
                scanSlider:EnableMouse(false)
                getglobal(scanSlider:GetName() .. "Text"):SetTextColor(0.5, 0.5, 0.5)
                getglobal(scanSlider:GetName() .. "Low"):SetTextColor(0.5, 0.5, 0.5)
                getglobal(scanSlider:GetName() .. "High"):SetTextColor(0.5, 0.5, 0.5)
            end
        end
    end)
    
    -- Update AutoNavigate UI state
    if not superWowAvailable then
        autoNavigateText:SetTextColor(0.5, 0.5, 0.5)
        getglobal(scanSlider:GetName() .. "Text"):SetTextColor(0.5, 0.5, 0.5)
        getglobal(scanSlider:GetName() .. "Low"):SetTextColor(0.5, 0.5, 0.5)
        getglobal(scanSlider:GetName() .. "High"):SetTextColor(0.5, 0.5, 0.5)
        scanSlider:EnableMouse(false)
    elseif not (self.AUTONAVIGATE and self.AUTONAVIGATE.enabled) then
        getglobal(scanSlider:GetName() .. "Text"):SetTextColor(0.5, 0.5, 0.5)
        getglobal(scanSlider:GetName() .. "Low"):SetTextColor(0.5, 0.5, 0.5)
        getglobal(scanSlider:GetName() .. "High"):SetTextColor(0.5, 0.5, 0.5)
        scanSlider:EnableMouse(false)
    end
    
    -- Scan frequency slider behavior
    scanSlider:SetScript("OnValueChanged", function()
        local value = math.floor(scanSlider:GetValue())
        if self.AUTONAVIGATE then
            self.AUTONAVIGATE.scanFreq = value
        end
        TWRA_SavedVariables.options.scanFrequency = value
        getglobal(scanSlider:GetName() .. "Text"):SetText("Scan: " .. value .. "s")
        
        -- Restart AutoNavigate timer with new frequency if enabled
        if self.AUTONAVIGATE and self.AUTONAVIGATE.enabled then
            self:RestartAutoNavigateTimer()
        end
    end)
    
    -- Radio button behaviors for announcement channels
    groupRadio:SetScript("OnClick", function()
        if not groupRadio:GetChecked() then
            groupRadio:SetChecked(true)
        end
        channelRadio:SetChecked(false)
        TWRA_SavedVariables.options.announceChannel = "GROUP"
        
        -- Disable channel input
        channelInput:SetTextColor(0.5, 0.5, 0.5)
        channelInput:EnableMouse(false)
    end)
    
    channelRadio:SetScript("OnClick", function()
        if not channelRadio:GetChecked() then
            channelRadio:SetChecked(true)
        end
        groupRadio:SetChecked(false)
        TWRA_SavedVariables.options.announceChannel = "CHANNEL"
        
        -- Enable channel input
        channelInput:SetTextColor(1, 1, 1)
        channelInput:EnableMouse(true)
    end)
    
    -- OSD Lock checkbox behavior
    lockOSD:SetChecked(self.OSD and self.OSD.locked)
    lockOSD:SetScript("OnClick", function()
        TWRA_SavedVariables.options.osdLocked = lockOSD:GetChecked()
        if self.OSD then
            self.OSD.locked = lockOSD:GetChecked()
        end
    end)
    
    -- Duration slider behavior
    durationSlider:SetScript("OnValueChanged", function()
        local value = math.floor(durationSlider:GetValue() * 2) / 2  -- Round to nearest 0.5
        TWRA_SavedVariables.options.osdDuration = value
        if self.OSD then
            self.OSD.duration = value
        end
        getglobal(durationSlider:GetName() .. "Text"):SetText("Display Duration: " .. value .. " seconds")
    end)
    
    -- Scale slider behavior
    scaleSlider:SetScript("OnValueChanged", function()
        local value = math.floor(scaleSlider:GetValue() * 10) / 10  -- Round to nearest 0.1
        TWRA_SavedVariables.options.osdScale = value
        if self.OSD then
            self.OSD.scale = value
        end
        getglobal(scaleSlider:GetName() .. "Text"):SetText("Scale: " .. value)
        
        -- Apply scale to overlay if it exists
        if self.sectionOverlay then
            self.sectionOverlay:SetScale(value)
        end
    end)
    
    -- OSD Test button behavior
    testOSDBtn:SetScript("OnClick", function()
        self:TestOSD()
    end)
    
    -- OSD Reset button behavior
    resetPosBtn:SetScript("OnClick", function()
        self:ResetOSDPosition()
    end)
    
    -- Import button behavior - simplified approach
    importBtn:SetScript("OnClick", function()
        local importText = importBox:GetText()
        if not importText or importText == "" then
            TWRA:Debug("data", "No data to import")
            return
        end
        
        -- Check if we have navigation information
        local currentSectionName = nil
        local currentSectionIndex = 1
        
        -- Capture current section info before import
        if TWRA_SavedVariables and TWRA_SavedVariables.assignments then
            currentSectionName = TWRA_SavedVariables.assignments.currentSectionName
            currentSectionIndex = TWRA_SavedVariables.assignments.currentSection or 1
            TWRA:Debug("data", "Import with saved section: " .. 
                       (currentSectionName or "unnamed") .. " (" .. currentSectionIndex .. ")")
        end
        
        -- Try to decode the data first
        local decodedData = TWRA:DecodeBase64(importText)
        if not decodedData then
            TWRA:Debug("data", "Failed to decode data")
            return
        end
        
        -- Only clear data after successful decode
        TWRA:ClearData()
        
        -- Save the data (will rebuild navigation)
        TWRA:SaveAssignments(decodedData, importText)
        
        -- Now restore section preference based on saved info
        if TWRA.navigation and TWRA.navigation.handlers then
            local sectionFound = false
            
            -- First try to find by name (more reliable)
            if currentSectionName then
                for i, name in ipairs(TWRA.navigation.handlers) do
                    if name == currentSectionName then
                        TWRA.navigation.currentIndex = i
                        TWRA:SaveCurrentSection()
                        TWRA:Debug("data", "Restored section by name: " .. name .. " (index: " .. i .. ")")
                        sectionFound = true
                        break
                    end
                end
            end
            
            -- If not found by name, try by index as fallback
            if not sectionFound and currentSectionIndex then
                local maxIndex = table.getn(TWRA.navigation.handlers)
                if maxIndex > 0 then
                    local safeIndex = math.min(currentSectionIndex, maxIndex)
                    TWRA.navigation.currentIndex = safeIndex
                    TWRA:SaveCurrentSection()
                    TWRA:Debug("data", "Restored section by index: " .. safeIndex)
                end
            end
        end
        
        TWRA:Debug("data", "Assignment data imported successfully")
        importBox:SetText("")
        
        -- Switch to main view to show the imported data
        TWRA:ShowMainView()
    end)
    
    -- Clear button behavior
    clearBtn:SetScript("OnClick", function()
        importBox:SetText("")
    end)
    
    -- Example button behavior
    exampleBtn:SetScript("OnClick", function()
        -- Clear any previous data
        self:ClearData()
        
        -- Load example data
        if self.LoadExampleData then
            if self:LoadExampleData() then
                -- Save the example assignments
                self:SaveAssignments(self.EXAMPLE_DATA, "example_data", nil, true)
                
                self:Debug("ui", "Example data loaded successfully!")
                
                -- Switch to main view to show the example data
                self:ShowMainView()
            else
                self:Debug("error", "Failed to load example data")
            end
        else
            self:Debug("error", "LoadExampleData function not found")
        end
    end)
    
    if not success or not exampleButton then
        self:Debug("ui", "Failed to create example button")
    end
    
    -- Store references to the panel
    self.optionsPanel = panel
    
    -- Hide initially
    panel:Hide()
    
    return panel
end

-- Safe function to show or hide options panel
function TWRA:ToggleOptionsPanel()
    if not self.optionsPanel then
        self:CreateOptionsPanel()
    end
    
    if self.optionsPanel:IsShown() then
        self.optionsPanel:Hide()
        self:ShowMainView()
    else
        self:ShowOptionsView()
    end
end

-- Helper function to create a section header
function TWRA:CreateSectionHeader(parent, text, yOffset)
    if not parent then
        self:Error("Cannot create section header: parent is nil")
        return nil
    end
    
    local section = nil
    local success = pcall(function()
        section = CreateFrame("Frame", nil, parent)
        section:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, yOffset or 0)
        section:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -10, yOffset or 0)
        section:SetHeight(30)
        
        local title = section:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOPLEFT", 0, 0)
        title:SetText(text)
        
        -- Add a subtle separator line below the header
        local line = section:CreateTexture(nil, "ARTWORK")
        line:SetTexture(0.5, 0.5, 0.5, 0.3)
        line:SetHeight(1)
        line:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -2)
        line:SetPoint("TOPRIGHT", section, "TOPRIGHT", 0, -2)
        
        section.title = title
        section.line = line
    end)
    
    if not success then
        self:Error("Failed to create section header: " .. text)
        return nil
    end
    
    return section
end

-- Function to restart the AutoNavigate timer when settings change
function TWRA:RestartAutoNavigateTimer()
    -- Ensure AutoNavigate table exists
    if not self.AUTONAVIGATE then
        self.AUTONAVIGATE = {
            enabled = false,
            scanFreq = 3,
            timer = nil
        }
        return
    end
    
    -- Stop existing timer if any
    if self.AUTONAVIGATE.timer then
        self:CancelTimer(self.AUTONAVIGATE.timer)
        self.AUTONAVIGATE.timer = nil
    end
    
    -- Start a new timer if enabled and StartAutoNavigate function exists
    if self.AUTONAVIGATE.enabled and self.StartAutoNavigate then
        self:Debug("auto", "Restarting AutoNavigate timer with frequency: " .. self.AUTONAVIGATE.scanFreq)
        self:StartAutoNavigate()
    else
        self:Debug("auto", "AutoNavigate is disabled, timer not restarted")
    end
end
