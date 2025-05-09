-- TWRA Options Module
-- Streamlined implementation with improved structure
TWRA = TWRA or {}

-- Initialize options with defaults if they don't exist
function TWRA:InitOptions()
    -- Ensure saved variables structure exists
    TWRA_SavedVariables = TWRA_SavedVariables or {}
    TWRA_SavedVariables.options = TWRA_SavedVariables.options or {}
    
    -- Get default values from Constants
    local defaults = self.DEFAULT_OPTIONS or {
        liveSync = false,
        tankSync = true,
        autoNavigate = false,
        scanFrequency = 3,
        announceChannel = "GROUP",
        customChannel = ""
    }
    
    -- Apply defaults for any missing options
    local options = TWRA_SavedVariables.options
    for key, defaultValue in pairs(defaults) do
        if options[key] == nil then
            options[key] = defaultValue
        end
    end
    
    -- Ensure OSD settings exist and have defaults
    options.osd = options.osd or {}
    local osd = options.osd
    
    local osdDefaults = self.DEFAULT_OSD_SETTINGS or {
        point = "CENTER",
        xOffset = 0,
        yOffset = 100,
        scale = 1.0,
        duration = 2,
        locked = false,
        enabled = true,
        showNotes = true,
        showOnNavigation = true
    }
    
    for key, defaultValue in pairs(osdDefaults) do
        if osd[key] == nil then
            osd[key] = defaultValue
        end
    end
    
    -- Set up sync module
    self.SYNC = self.SYNC or {}
    self.SYNC.liveSync = options.liveSync
    self.SYNC.tankSync = options.tankSync
    
    -- Set up auto-navigate module
    self.AUTONAVIGATE = self.AUTONAVIGATE or {}
    self.AUTONAVIGATE.enabled = options.autoNavigate
    
    -- Initialize OSD if needed
    if self.InitOSD then
        self:InitOSD()
    end
    
    -- Apply settings to activate features based on saved variables
    self:ApplyInitialSettings()
    
    self:Debug("general", "Options initialized")
    return true
end

-- Helper function to update slider text and state
function TWRA:UpdateSliderState(slider, enabled)
    if not slider then return end
    
    -- Set mouse interaction
    slider:EnableMouse(enabled)
    
    -- Update text colors
    local color = enabled and 1.0 or 0.5
    
    local sliderText = getglobal(slider:GetName() .. "Text")
    local sliderLow = getglobal(slider:GetName() .. "Low")
    local sliderHigh = getglobal(slider:GetName() .. "High")
    
    if sliderText then sliderText:SetTextColor(color, color, color) end
    if sliderLow then sliderLow:SetTextColor(color, color, color) end
    if sliderHigh then sliderHigh:SetTextColor(color, color, color) end
end

-- Helper function to create a checkbox with label
function TWRA:CreateCheckbox(parent, text, point, relativeFrame, relativePoint, x, y)
    local checkbox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    checkbox:SetWidth(24)
    checkbox:SetHeight(24)
    checkbox:SetPoint(point or "TOPLEFT", relativeFrame or parent, relativePoint or (point or "TOPLEFT"), x or 0, y or 0)
    
    -- Create text element explicitly
    local checkboxText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    checkboxText:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
    checkboxText:SetText(text)
    
    -- Attach text reference to checkbox for easy access
    checkbox.textElement = checkboxText
    
    return checkbox, checkboxText
end

-- Create options content in the main frame - PRIMARY OPTIONS FUNCTION
function TWRA:CreateOptionsInMainFrame()
    if self.optionsElements then
        return self.optionsElements
    end
    
    -- Clear any existing options UI
    if self.optionsElements then
        for _, element in pairs(self.optionsElements) do
            if element.Hide then
                element:Hide()
                element:SetParent(nil)
            end
        end
    end
    
    -- Create a container for all options elements
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
    
    -- Create the three columns
    local leftColumn = CreateFrame("Frame", nil, self.mainFrame)
    leftColumn:SetPoint("TOPLEFT", self.mainFrame, "TOPLEFT", 20, -50)
    leftColumn:SetWidth(240)
    leftColumn:SetHeight(400)
    table.insert(self.optionsElements, leftColumn)
    
    local middleColumn = CreateFrame("Frame", nil, self.mainFrame)
    middleColumn:SetPoint("TOP", self.mainFrame, "TOP", 0, -50)
    middleColumn:SetWidth(240)
    middleColumn:SetHeight(400)
    table.insert(self.optionsElements, middleColumn)
    
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
    local liveSync, liveSyncText = self:CreateCheckbox(leftColumn, "Live Section Sync", "TOPLEFT", syncTitle, "BOTTOMLEFT", 0, -10)
    table.insert(self.optionsElements, liveSync)
    table.insert(self.optionsElements, liveSyncText)
    
    -- Tank Sync Option
    local tankSyncCheckbox, tankSyncText = self:CreateCheckbox(leftColumn, "Tank Sync", "TOPLEFT", liveSync, "BOTTOMLEFT", 0, -10)
    table.insert(self.optionsElements, tankSyncCheckbox)
    table.insert(self.optionsElements, tankSyncText)
    
    -- Add info icon for tank sync
    local tankSyncIcon, tankSyncIconFrame = self.UI:CreateIconWithTooltip(
        leftColumn,
        "Interface\\TutorialFrame\\TutorialFrame-QuestionMark",
        "Tank Sync",
        "When enabled, tanks will be automatically assigned in oRA2 based on the currently selected section.",
        tankSyncText,
        5, 22, 22
    )
    
    tankSyncIcon:ClearAllPoints()
    tankSyncIcon:SetPoint("LEFT", tankSyncText, "RIGHT", 5, 0)
    
    table.insert(self.optionsElements, tankSyncIcon)
    table.insert(self.optionsElements, tankSyncIconFrame)
    
    -- AutoNavigate Option
    local autoNavigate, autoNavigateText = self:CreateCheckbox(leftColumn, "AutoNavigate", "TOPLEFT", tankSyncCheckbox, "BOTTOMLEFT", 0, -10)
    table.insert(self.optionsElements, autoNavigate)
    table.insert(self.optionsElements, autoNavigateText)
    
    -- Add info icon for autonavigate
    local autoNavIcon, autoNavIconFrame = self.UI:CreateIconWithTooltip(
        leftColumn,
        "Interface\\TutorialFrame\\TutorialFrame-QuestionMark",
        "AutoNavigate",
        "Automatically navigate to the appropriate section based on raid markers or target selection.",
        autoNavigateText,
        5, 22, 22
    )
    
    autoNavIcon:ClearAllPoints()
    autoNavIcon:SetPoint("LEFT", autoNavigateText, "RIGHT", 5, 0)
    
    table.insert(self.optionsElements, autoNavIcon)
    table.insert(self.optionsElements, autoNavIconFrame)
    
    -- Announcement section
    local announceTitle = leftColumn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    announceTitle:SetPoint("TOPLEFT", autoNavigate, "BOTTOMLEFT", 0, -20)
    announceTitle:SetText("Announcement Channel")
    table.insert(self.optionsElements, announceTitle)
    
    -- Group Radio Button
    local groupRadio = CreateFrame("CheckButton", "TWRA_GroupRadioButton", leftColumn, "UIRadioButtonTemplate")
    groupRadio:SetPoint("TOPLEFT", announceTitle, "BOTTOMLEFT", 0, -10)
    groupRadio:SetWidth(16)
    groupRadio:SetHeight(16)
    
    local groupText = leftColumn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    groupText:SetPoint("LEFT", groupRadio, "RIGHT", 5, 0)
    groupText:SetText("Group")
    
    table.insert(self.optionsElements, groupRadio)
    table.insert(self.optionsElements, groupText)
    
    -- Channel Radio Button
    local channelRadio = CreateFrame("CheckButton", "TWRA_ChannelRadioButton", leftColumn, "UIRadioButtonTemplate")
    channelRadio:SetPoint("TOPLEFT", groupRadio, "BOTTOMLEFT", 0, -5)
    channelRadio:SetWidth(16)
    channelRadio:SetHeight(16)
    
    local channelText = leftColumn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    channelText:SetPoint("LEFT", channelRadio, "RIGHT", 5, 0)
    channelText:SetText("Channel:")
    
    table.insert(self.optionsElements, channelRadio)
    table.insert(self.optionsElements, channelText)
    
    -- Add info icon for group option
    local groupIcon, groupIconFrame = self.UI:CreateIconWithTooltip(
        leftColumn,
        "Interface\\TutorialFrame\\TutorialFrame-QuestionMark",
        "Group Channel",
        "Announcements will be sent to your current group or raid. Raid warnings will be used for warnings when in a raid.",
        groupText,
        5, 22, 22
    )
    
    groupIcon:ClearAllPoints()
    groupIcon:SetPoint("LEFT", groupText, "RIGHT", 5, 0)
    
    table.insert(self.optionsElements, groupIcon)
    table.insert(self.optionsElements, groupIconFrame)
    
    -- Channel input box
    local channelInput = CreateFrame("EditBox", nil, leftColumn, "InputBoxTemplate")
    channelInput:SetWidth(160)
    channelInput:SetHeight(20)
    channelInput:SetPoint("LEFT", channelText, "RIGHT", 5, 0)
    channelInput:SetNumeric(false)
    channelInput:SetAutoFocus(false)
    channelInput:SetMaxLetters(20)
    table.insert(self.optionsElements, channelInput)
    
    -- ====================== MIDDLE COLUMN: OSD SETTINGS ======================
    -- Column title
    local osdTitle = middleColumn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    osdTitle:SetPoint("TOPLEFT", middleColumn, "TOPLEFT", 10, 0)
    osdTitle:SetText("On-Screen Display")
    table.insert(self.optionsElements, osdTitle)
    
    -- Show Notes in OSD checkbox (replacing Enable OSD)
    local showNotesInOSD, showNotesInOSDText = self:CreateCheckbox(middleColumn, "Show Notes in OSD", "TOPLEFT", osdTitle, "BOTTOMLEFT", 0, -10)
    table.insert(self.optionsElements, showNotesInOSD)
    table.insert(self.optionsElements, showNotesInOSDText)
    
    -- Add info icon for show notes option
    local notesIcon, notesIconFrame = self.UI:CreateIconWithTooltip(
        middleColumn,
        "Interface\\TutorialFrame\\TutorialFrame-QuestionMark",
        "Show Notes in OSD",
        "When enabled, notes will be displayed in the OSD alongside warnings. Notes are shown with blue background.",
        showNotesInOSDText,
        5, 22, 22
    )
    
    notesIcon:ClearAllPoints()
    notesIcon:SetPoint("LEFT", showNotesInOSDText, "RIGHT", 5, 0)
    
    table.insert(self.optionsElements, notesIcon)
    table.insert(self.optionsElements, notesIconFrame)
    
    -- OSD on Navigation checkbox
    local showOnNavOSD, showOnNavOSDText = self:CreateCheckbox(middleColumn, "Show on Navigation", "TOPLEFT", showNotesInOSD, "BOTTOMLEFT", 0, -5)
    table.insert(self.optionsElements, showOnNavOSD)
    table.insert(self.optionsElements, showOnNavOSDText)
    
    -- Lock Position checkbox
    local lockOSD, lockOSDText = self:CreateCheckbox(middleColumn, "Lock Position", "TOPLEFT", showOnNavOSD, "BOTTOMLEFT", 0, -10)
    table.insert(self.optionsElements, lockOSD)
    table.insert(self.optionsElements, lockOSDText)
    
    -- OSD Duration slider
    local durationSlider = CreateFrame("Slider", "TWRA_OSDDurationSlider", middleColumn, "OptionsSliderTemplate")
    durationSlider:SetPoint("TOPLEFT", lockOSD, "BOTTOMLEFT", 0, -20)
    durationSlider:SetWidth(180)
    durationSlider:SetHeight(16)
    durationSlider:SetMinMaxValues(1, 10)
    durationSlider:SetValueStep(0.5)
    durationSlider:SetOrientation("HORIZONTAL")
    table.insert(self.optionsElements, durationSlider)
    
    -- Set slider text
    getglobal(durationSlider:GetName() .. "Low"):SetText("1s")
    getglobal(durationSlider:GetName() .. "High"):SetText("10s")
    
    -- OSD Scale slider
    local scaleSlider = CreateFrame("Slider", "TWRA_OSDScaleSlider", middleColumn, "OptionsSliderTemplate")
    scaleSlider:SetPoint("TOPLEFT", durationSlider, "BOTTOMLEFT", 0, -20)
    scaleSlider:SetWidth(180)
    scaleSlider:SetHeight(16)
    scaleSlider:SetMinMaxValues(0.5, 2.0)
    scaleSlider:SetValueStep(0.1)
    scaleSlider:SetOrientation("HORIZONTAL")
    table.insert(self.optionsElements, scaleSlider)
    
    -- Set slider text
    getglobal(scaleSlider:GetName() .. "Low"):SetText("Small")
    getglobal(scaleSlider:GetName() .. "High"):SetText("Large")
    
    -- OSD action buttons
    local testOSDBtn = CreateFrame("Button", nil, middleColumn, "UIPanelButtonTemplate")
    testOSDBtn:SetWidth(80)
    testOSDBtn:SetHeight(22)
    testOSDBtn:SetPoint("TOPLEFT", scaleSlider, "BOTTOMLEFT", 0, -15)
    testOSDBtn:SetText("Show OSD")
    testOSDBtn:SetScript("OnClick", function()
        -- Use ToggleOSD to properly toggle visibility
        local isVisible = TWRA:ToggleOSD()
        
        -- Update button text to reflect current state
        if isVisible then
            testOSDBtn:SetText("Hide OSD")
            
            -- Update current section content if available
            if TWRA.navigation and TWRA.navigation.currentIndex and TWRA.navigation.handlers then
                local sectionName = TWRA.navigation.handlers[TWRA.navigation.currentIndex]
                local currentIndex = TWRA.navigation.currentIndex
                local totalSections = table.getn(TWRA.navigation.handlers)
                
                -- Update OSD content with current section data
                TWRA:UpdateOSDContent(sectionName, currentIndex, totalSections)
            end
        else
            testOSDBtn:SetText("Show OSD")
        end
        
        -- Debug output
        TWRA:Debug("osd", "OSD " .. (isVisible and "shown" or "hidden") .. " from options panel")
    end)
    table.insert(self.optionsElements, testOSDBtn)
    
    local resetPosBtn = CreateFrame("Button", nil, middleColumn, "UIPanelButtonTemplate")
    resetPosBtn:SetWidth(80)
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
    importBox:SetWidth(220)
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
    clearBtn:SetWidth(70)
    clearBtn:SetHeight(22)
    clearBtn:SetPoint("LEFT", importBtn, "RIGHT", 5, 0)
    clearBtn:SetText("Clear")
    table.insert(self.optionsElements, clearBtn)
    
    local exampleBtn = CreateFrame("Button", nil, rightColumn, "UIPanelButtonTemplate")
    exampleBtn:SetWidth(70)
    exampleBtn:SetHeight(22)
    exampleBtn:SetPoint("LEFT", clearBtn, "RIGHT", 5, 0)
    exampleBtn:SetText("Example")
    table.insert(self.optionsElements, exampleBtn)
    
    -- ====================== LOAD SAVED VALUES ======================
    -- Get saved options and apply them to the UI elements
    local options = TWRA_SavedVariables.options or {}
    
    -- Make sure options.osd exists to avoid nil errors
    options.osd = options.osd or {}
    
    -- Live Sync checkbox
    local liveSyncEnabled = self.SYNC and self.SYNC.liveSync or false
    if options.liveSync ~= nil then
        liveSyncEnabled = options.liveSync
    end
    liveSync:SetChecked(liveSyncEnabled)
    
    -- Tank Sync checkbox
    local tankSyncEnabled = self.SYNC and self.SYNC.tankSync or false
    if options.tankSync ~= nil then
        tankSyncEnabled = options.tankSync
    end
    tankSyncCheckbox:SetChecked(tankSyncEnabled)
    
    -- AutoNavigate checkbox
    local autoNavEnabled = self.AUTONAVIGATE and self.AUTONAVIGATE.enabled or false
    if options.autoNavigate ~= nil then
        autoNavEnabled = options.autoNavigate
    end
    autoNavigate:SetChecked(autoNavEnabled)
    
    -- Announcement channel radio buttons
    local announceChannel = options.announceChannel or "GROUP"
    groupRadio:SetChecked(announceChannel == "GROUP")
    channelRadio:SetChecked(announceChannel == "CHANNEL")
    
    -- Custom channel input
    local customChannel = options.customChannel or ""
    channelInput:SetText(customChannel)
    
    -- Enable/disable channel input based on selection
    if announceChannel ~= "CHANNEL" then
        channelInput:EnableMouse(false)
        channelInput:SetTextColor(0.5, 0.5, 0.5)
    else
        channelInput:EnableMouse(true)
        channelInput:SetTextColor(1, 1, 1)
    end
    
    -- Show Notes in OSD checkbox
    local showNotesEnabled = true
    if options.osd and options.osd.showNotes ~= nil then
        showNotesEnabled = options.osd.showNotes
    elseif self.OSD and self.OSD.showNotes ~= nil then
        showNotesEnabled = self.OSD.showNotes
    end
    showNotesInOSD:SetChecked(showNotesEnabled)
    
    -- OSD Navigation checkbox
    local osdNavEnabled = true
    if options.osd and options.osd.showOnNavigation ~= nil then
        osdNavEnabled = options.osd.showOnNavigation
    elseif self.OSD and self.OSD.showOnNavigation ~= nil then
        osdNavEnabled = self.OSD.showOnNavigation
    end
    showOnNavOSD:SetChecked(osdNavEnabled)
    
    -- Lock Position checkbox
    local osdLocked = false
    if options.osd and options.osd.locked ~= nil then
        osdLocked = options.osd.locked
    elseif self.OSD and self.OSD.locked ~= nil then
        osdLocked = self.OSD.locked
    end
    lockOSD:SetChecked(osdLocked)
    
    -- Duration slider
    local osdDuration = 2
    if options.osd and options.osd.duration ~= nil then
        osdDuration = options.osd.duration
    elseif self.OSD and self.OSD.duration ~= nil then
        osdDuration = self.OSD.duration
    end
    durationSlider:SetValue(osdDuration)
    getglobal(durationSlider:GetName() .. "Text"):SetText("Display Duration: " .. osdDuration .. " seconds")
    
    -- Scale slider
    local osdScale = 1.0
    if options.osd and options.osd.scale ~= nil then
        osdScale = options.osd.scale
    elseif self.OSD and self.OSD.scale ~= nil then
        osdScale = self.OSD.scale
    end
    scaleSlider:SetValue(osdScale)
    getglobal(scaleSlider:GetName() .. "Text"):SetText("Scale: " .. osdScale)
    
    -- ====================== WIRE UP BEHAVIORS ======================
    
    -- Live Sync checkbox behavior
    liveSync:SetScript("OnClick", function()
        local isChecked = (this:GetChecked() == 1)
        TWRA_SavedVariables.options.liveSync = isChecked
        
        -- Update memory value
        if self.SYNC then
            self.SYNC.liveSync = isChecked
        end
        
        -- Debug output
        self:Debug("sync", "Option 'Live Section Sync' set to " .. (isChecked and "ON" or "OFF"))
    end)
    
    -- Tank Sync checkbox behavior
    tankSyncCheckbox:SetScript("OnClick", function()
        local isChecked = (this:GetChecked() == 1)
        TWRA_SavedVariables.options.tankSync = isChecked
        
        -- Update memory value
        if self.SYNC then
            self.SYNC.tankSync = isChecked
        end
        
        -- Debug output
        self:Debug("tank", "Option 'Tank Sync' set to " .. (isChecked and "ON" or "OFF"))
        
        -- Initialize tank sync if it was just enabled
        if isChecked and self.InitializeTankSync then
            self:InitializeTankSync()
        end
    end)
    
    -- AutoNavigate checkbox behavior
    autoNavigate:SetScript("OnClick", function()
        local isChecked = (this:GetChecked() == 1)
        TWRA_SavedVariables.options.autoNavigate = isChecked
        self.AUTONAVIGATE.enabled = isChecked
        
        -- Debug output
        self:Debug("nav", "Option 'AutoNavigate' set to " .. (isChecked and "ON" or "OFF"))
        
        -- Enable or disable scanning based on checkbox state
        if isChecked then
            if self.StartAutoNavigateScan then
                self:StartAutoNavigateScan()
                self:Debug("nav", "AutoNavigate scanning started")
            end
        else
            if self.StopAutoNavigateScan then
                self:StopAutoNavigateScan()
                self:Debug("nav", "AutoNavigate scanning stopped")
            end
        end
    end)
    
    -- Update initial AutoNavigate UI state
    if not SUPERWOW_VERSION then
        -- SuperWoW not available, gray out everything
        autoNavigateText:SetTextColor(0.5, 0.5, 0.5)
        autoNavigate:EnableMouse(false)
    else
        -- SuperWoW is available, ensure AutoNavigate text is normal color
        autoNavigateText:SetTextColor(1, 1, 1)
        autoNavigate:EnableMouse(true)
    end
    
    -- Radio button behaviors for announcement channels
    groupRadio:SetScript("OnClick", function()
        groupRadio:SetChecked(true)
        channelRadio:SetChecked(false)
        TWRA_SavedVariables.options.announceChannel = "GROUP"
        
        -- Disable channel input
        channelInput:SetTextColor(0.5, 0.5, 0.5)
        channelInput:EnableMouse(false)
    end)
    
    channelRadio:SetScript("OnClick", function()
        channelRadio:SetChecked(true)
        groupRadio:SetChecked(false)
        TWRA_SavedVariables.options.announceChannel = "CHANNEL"
        
        -- Enable channel input
        channelInput:SetTextColor(1, 1, 1)
        channelInput:EnableMouse(true)
    end)
    
    -- Channel input behaviors
    channelInput:SetScript("OnTextChanged", function()
        TWRA_SavedVariables.options.customChannel = this:GetText()
    end)
    
    channelInput:SetScript("OnEnterPressed", function() 
        this:ClearFocus()
    end)
    
    channelInput:SetScript("OnEscapePressed", function() 
        this:ClearFocus()
    end)
    
    -- OSD Notes in OSD checkbox behavior
    showNotesInOSD:SetScript("OnClick", function()
        local isChecked = (this:GetChecked() == 1)
        
        -- Ensure OSD settings structure exists
        if not TWRA_SavedVariables.options.osd then 
            TWRA_SavedVariables.options.osd = {} 
        end
        
        -- Save setting
        TWRA_SavedVariables.options.osd.showNotes = isChecked
        
        -- Update runtime value
        if self.OSD then
            self.OSD.showNotes = isChecked
        end
        
        -- Debug output
        self:Debug("osd", "Option 'Show Notes in OSD' set to " .. (isChecked and "ON" or "OFF"))
        
        -- Update OSD if visible
        if self.OSD and self.OSD.isVisible and self.UpdateOSDContent then
            if self.navigation and self.navigation.currentIndex and self.navigation.handlers then
                local sectionName = self.navigation.handlers[self.navigation.currentIndex]
                local currentIndex = self.navigation.currentIndex
                local totalSections = table.getn(self.navigation.handlers)
                self:UpdateOSDContent(sectionName, currentIndex, totalSections)
            end
        end
    end)
    
    -- OSD on Navigation checkbox behavior
    showOnNavOSD:SetScript("OnClick", function()
        local isChecked = (this:GetChecked() == 1)
        
        -- Ensure OSD settings structure exists
        if not TWRA_SavedVariables.options.osd then 
            TWRA_SavedVariables.options.osd = {} 
        end
        
        -- Save setting
        TWRA_SavedVariables.options.osd.showOnNavigation = isChecked
        
        -- Update runtime value
        if self.OSD then
            self.OSD.showOnNavigation = isChecked
        end
        
        -- Debug output
        self:Debug("osd", "Option 'Show on Navigation' set to " .. (isChecked and "ON" or "OFF"))
        
        -- Call the toggle function if it exists
        if self.ToggleOSDOnNavigation then
            self:ToggleOSDOnNavigation(isChecked)
        end
    end)
    
    -- OSD Lock checkbox behavior
    lockOSD:SetScript("OnClick", function()
        local isChecked = (this:GetChecked() == 1)
        
        -- Ensure OSD settings structure exists
        if not TWRA_SavedVariables.options.osd then 
            TWRA_SavedVariables.options.osd = {} 
        end
        
        -- Save setting
        TWRA_SavedVariables.options.osd.locked = isChecked
        
        -- Update runtime value
        if self.OSD then
            self.OSD.locked = isChecked
        end
        
        -- Debug output
        self:Debug("osd", "Option 'Lock Position' set to " .. (isChecked and "ON" or "OFF"))
        
        -- Update OSD frame if needed
        if self.UpdateOSDSettings then
            self:UpdateOSDSettings()
        end
    end)
    
    -- Duration slider behavior
    durationSlider:SetScript("OnValueChanged", function()
        local value = math.floor(this:GetValue() * 2) / 2  -- Round to nearest 0.5
        
        -- Ensure OSD settings structure exists
        if not TWRA_SavedVariables.options.osd then 
            TWRA_SavedVariables.options.osd = {} 
        end
        
        -- Save setting
        TWRA_SavedVariables.options.osd.duration = value
        
        -- Update runtime value
        if self.OSD then
            self.OSD.duration = value
        end
        
        -- Update display text
        getglobal(this:GetName() .. "Text"):SetText("Display Duration: " .. value .. " seconds")
    end)
    
    -- Scale slider behavior
    scaleSlider:SetScript("OnValueChanged", function()
        local value = math.floor(this:GetValue() * 10) / 10  -- Round to nearest 0.1
        
        -- Ensure OSD settings structure exists
        if not TWRA_SavedVariables.options.osd then 
            TWRA_SavedVariables.options.osd = {} 
        end
        
        -- Save setting
        TWRA_SavedVariables.options.osd.scale = value
        
        -- Update runtime value
        if self.OSD then
            self.OSD.scale = value
        end
        
        -- Update display text
        getglobal(this:GetName() .. "Text"):SetText("Scale: " .. value)
        
        -- Update OSD frame if needed
        if self.UpdateOSDSettings then
            self:UpdateOSDSettings()
        end
    end)
    
    -- Reset OSD position button behavior
    resetPosBtn:SetScript("OnClick", function()
        if self.ResetOSDPosition then
            self:ResetOSDPosition()
        end
        
        -- Update OSD settings if needed
        if self.UpdateOSDSettings then
            self:UpdateOSDSettings()
        end
    end)
    
    -- Import button behavior
    importBtn:SetScript("OnClick", function()
        local importText = importBox:GetText()
        if not importText or importText == "" then
            self:Debug("data", "No data to import")
            return
        end
        
        self:Debug("data", "Importing data")
                
        -- Import using the new format
        local success = self:DirectImport(importText)
        
        if success then
            -- Clear the import box and remove focus
            importBox:SetText("")
            importBox:ClearFocus()
            
            -- CRITICAL: Process each section to explicitly establish Group Rows metadata
            -- This ensures Group Rows are properly identified
            if TWRA_Assignments and TWRA_Assignments.data then
                self:Debug("data", "Explicitly establishing Group Rows metadata for all sections")
                local sectionsWithGroupRows = 0
                local totalGroupRows = 0
                
                for sectionIdx, section in pairs(TWRA_Assignments.data) do
                    if type(section) == "table" and section["Section Rows"] then
                        -- Initialize Section Metadata if not present
                        section["Section Metadata"] = section["Section Metadata"] or {}
                        
                        -- Explicitly force generation of Group Rows metadata
                        section["Section Metadata"]["Group Rows"] = self:GetAllGroupRowsForSection(section)
                        
                        local groupRowCount = table.getn(section["Section Metadata"]["Group Rows"] or {})
                        totalGroupRows = totalGroupRows + groupRowCount
                        
                        if groupRowCount > 0 then
                            sectionsWithGroupRows = sectionsWithGroupRows + 1
                        end
                        
                        self:Debug("data", "Section '" .. (section["Section Name"] or tostring(sectionIdx)) .. 
                                 "': Established " .. groupRowCount .. " group rows")
                    end
                end
                
                self:Debug("data", "Established Group Rows metadata for " .. sectionsWithGroupRows .. 
                         " sections with a total of " .. totalGroupRows .. " group rows")
            end
            
            -- Apply ProcessImportedData for any other metadata processing
            if self.ProcessImportedData then
                self:Debug("data", "Applying ProcessImportedData for additional metadata processing")
                TWRA_Assignments.data = self:ProcessImportedData(TWRA_Assignments)
            end
            
            -- CRITICAL: Store compressed data immediately after establishing metadata
            -- but BEFORE processing player-specific info
            if self.StoreCompressedData then
                self:Debug("data", "Storing compressed data with established metadata")
                self:StoreCompressedData()
            elseif self.StoreSegmentedData then
                self:Debug("data", "Storing segmented data with established metadata")
                self:StoreSegmentedData()
            end
            
            -- Verify metadata was properly stored in compressed data
            if TWRA_Assignments and TWRA_Assignments.data then
                local groupRowsCheck = 0
                for sectionIdx, section in pairs(TWRA_Assignments.data) do
                    if type(section) == "table" and section["Section Metadata"] and 
                       section["Section Metadata"]["Group Rows"] and 
                       table.getn(section["Section Metadata"]["Group Rows"]) > 0 then
                        groupRowsCheck = groupRowsCheck + 1
                    end
                end
                self:Debug("data", "Verification: " .. groupRowsCheck .. " sections have Group Rows metadata after compression")
            end
            
            -- NOW process player info (this is client-specific and should happen after compression)
            if self.ProcessPlayerInfo then
                self:Debug("data", "Processing player-specific info after import")
                -- Process player info with error handling
                pcall(function() self:ProcessPlayerInfo() end)
            end
            
            -- Update OSD if it's showing
            if self.OSD and self.OSD.isVisible and self.UpdateOSDContent then
                self:UpdateOSDContent()
            end
                        
            -- Switch to main view
            if self.ShowMainView then
                self:ShowMainView()
            end
        else
            -- Import failed
            self:Debug("error", "Failed to import data - invalid format")
        end
    end)
    
    -- Example button behavior
    exampleBtn:SetScript("OnClick", function()
        TWRA:LoadExampleDataAndShow()
    end)
    
    -- Clear button behavior
    clearBtn:SetScript("OnClick", function()
        -- Clear the import box content
        importBox:SetText("")
        -- Remove focus from the import box
        importBox:ClearFocus()
        -- Debug log
        self:Debug("ui", "Import box cleared")
    end)
    
    return self.optionsElements
end

-- Function to restart the AutoNavigate timer when settings change
function TWRA:RestartAutoNavigateTimer()
    -- Ensure AutoNavigate table exists
    if not self.AUTONAVIGATE then
        self.AUTONAVIGATE = {
            enabled = false,
            timer = nil
        }
        return
    end
    
    -- Stop existing timer if any
    if self.AUTONAVIGATE.timer then
        self:CancelTimer(self.AUTONAVIGATE.timer)
        self.AUTONAVIGATE.timer = nil
    end
    
    -- Start a new timer if enabled
    if self.AUTONAVIGATE.enabled then
        if self.StartAutoNavigate then
            self:Debug("auto", "Restarting AutoNavigate timer")
            self:StartAutoNavigate()
        end
    else
        self:Debug("auto", "AutoNavigate is disabled, timer not restarted")
    end
end

-- Helper function to apply saved settings on load
function TWRA:ApplyInitialSettings()
    self:Debug("general", "Applying initial settings from saved variables")
    
    -- Get saved options
    local options = TWRA_SavedVariables.options
    if not options then
        self:Debug("general", "No saved options found, using defaults")
        return
    end
    
    -- Ensure options.osd exists to avoid nil errors in the rest of the function
    options.osd = options.osd or {}
    
    -- Apply Live Section Sync setting
    if options.liveSync then
        self:Debug("sync", "Initializing Live Section Sync: ENABLED")
        -- Make sure SYNC module exists
        self.SYNC = self.SYNC or {}
        self.SYNC.liveSync = true
        
        -- Activate live sync functionality
        if self.ActivateLiveSync then
            self:ActivateLiveSync()
            self:Debug("sync", "Live Section Sync activated on init")
        else
            self:Debug("sync", "Live Section Sync enabled but ActivateLiveSync function not found")
        end
    else
        self:Debug("sync", "Live Section Sync disabled in settings")
        -- Make sure it's deactivated
        if self.SYNC and self.SYNC.isActive and self.DeactivateLiveSync then
            self:DeactivateLiveSync()
        end
    end

    -- Apply Tank Sync setting
    if options.tankSync then
        self:Debug("tank", "Initializing Tank Sync: ENABLED")
        -- Make sure SYNC module exists
        self.SYNC = self.SYNC or {} 
        self.SYNC.tankSync = true
        
        if self:IsORA2Available() then
            self:Debug("tank", "oRA2 available, Tank Sync active")
        else
            self:Debug("tank", "oRA2 not available, Tank Sync will activate when available")
        end
    else
        self:Debug("tank", "Tank Sync disabled in settings")
    end
    
    -- Apply AutoNavigate setting
    if options.autoNavigate then
        self:Debug("nav", "Initializing AutoNavigate: ENABLED")
        -- Start the AutoNavigate scan if SuperWoW is available
        if SUPERWOW_VERSION and self.StartAutoNavigateScan then
            self.AUTONAVIGATE = self.AUTONAVIGATE or {}
            self.AUTONAVIGATE.enabled = true
            self:StartAutoNavigateScan()
            self:Debug("nav", "AutoNavigate activated")
        else
            self:Debug("nav", "SuperWoW not available, AutoNavigate remains disabled")
        end
    else
        self:Debug("nav", "AutoNavigate disabled in settings")
    end
end

-- Add this function to handle direct import of new format data
function TWRA:DirectImport(importText)
    self:Debug("data", "Starting direct import of new format data")
    
    -- CRITICAL FIX: Completely regenerate TWRA_CompressedAssignments from scratch
    -- The issue is that setting TWRA_CompressedAssignments.sections = {} isn't sufficient
    -- Create a completely new global variable instead
    
    -- Log the state before clearing
    local oldSectionCount = 0
    if TWRA_CompressedAssignments and TWRA_CompressedAssignments.sections then
        for _, _ in pairs(TWRA_CompressedAssignments.sections) do
            oldSectionCount = oldSectionCount + 1
        end
    end
    self:Debug("data", "Found " .. oldSectionCount .. " sections in TWRA_CompressedAssignments.sections before clearing")
    
    -- AGGRESSIVE FIX: Create a completely new table, don't try to modify the existing one
    -- This ensures no references to the old data persist
    TWRA_CompressedAssignments = {
        sections = {},
        structure = nil,
        timestamp = nil,
        useSectionCompression = true
    }
    self:Debug("data", "Created completely new TWRA_CompressedAssignments table")
    
    -- Step 1: Decode the Base64 string
    local decodedString = self:DecodeBase64(importText)
    
    if not decodedString then
        self:Debug("error", "Failed to decode Base64 string", true)
        return false
    end
    
    -- Debug the decoded string beginning (only for diagnostics)
    self:Debug("data", "Decoded string length: " .. string.len(decodedString))
    
    -- Step 2: Create a temporary environment to evaluate the string safely
    local env = {}
    
    -- Step 3: Create a modified script that loads into our temp environment
    local script = "local TWRA_ImportString; " .. decodedString .. "; return TWRA_ImportString"
    
    -- Execute the script
    local func, err = loadstring(script)
    if not func then
        self:Debug("error", "Error in loadstring: " .. tostring(err), true)
        return false
    end
    
    -- Create a safe environment
    setfenv(func, env)
    
    -- Execute and get result
    local success, importData = pcall(func)
    if not success or not importData then
        self:Debug("error", "Error executing import script: " .. tostring(importData or "unknown error"), true)
        return false
    end
    
    -- Step 4: Check if the format matches our expected structure
    if not importData.data or type(importData.data) ~= "table" then
        self:Debug("data", "Not in new format - missing data field or wrong type")
        return false
    end
    
    -- Step 5: Check for our sections structure
    local isNewFormat = false
    local sectionCount = 0
    
    for idx, section in pairs(importData.data) do
        sectionCount = sectionCount + 1
        if type(section) == "table" and 
           section["Section Name"] and 
           section["Section Header"] and 
           section["Section Rows"] then
            isNewFormat = true
            self:Debug("data", "Found section with new format: " .. section["Section Name"])
            break
        end
    end
    
    if not isNewFormat then
        self:Debug("data", "Not in new format - no sections with correct structure found")
        return false
    end
    
    self:Debug("data", "Verified new data format structure with " .. sectionCount .. " sections")
    
    -- Step 6: Create a completely new TWRA_Assignments with just the imported data
    local timestamp = time()
    
    TWRA_Assignments = {
        data = importData.data,
        timestamp = timestamp,
        version = 2, -- Mark as new format
        currentSection = 1
    }
    
    self:Debug("data", "Successfully created new TWRA_Assignments")
    
    -- Step 7: Build navigation from the imported data
    self.navigation = self.navigation or { handlers = {}, currentIndex = 1 }
    self.navigation.handlers = {}
    self.navigation.currentIndex = 1
    
    -- Add sections to navigation
    local sections = {}
    for idx, section in pairs(importData.data) do
        if type(section) == "table" and section["Section Name"] then
            table.insert(self.navigation.handlers, section["Section Name"])
            table.insert(sections, section["Section Name"])
        end
    end
    
    -- Log what we found
    local sectionCount = table.getn(self.navigation.handlers)
    self:Debug("nav", "Built " .. sectionCount .. " sections")
    
    if sectionCount > 0 and table.getn(sections) > 0 then
        self:Debug("nav", "Section names: " .. table.concat(sections, ", "))
    end
    
    -- Step 8: Force generation of new compressed data
    if self.StoreSegmentedData then
        self:Debug("data", "Generating segmented compressed data for new assignments")
        self:StoreSegmentedData()
    elseif self.StoreCompressedData then
        self:Debug("data", "Generating compressed data for new assignments")
        self:StoreCompressedData()
    end
    
    -- Step 8.5: Verify compressed sections were correctly generated
    if TWRA_CompressedAssignments and TWRA_CompressedAssignments.sections then
        local compressedSectionCount = 0
        for _, _ in pairs(TWRA_CompressedAssignments.sections) do
            compressedSectionCount = compressedSectionCount + 1
        end
        self:Debug("data", "Verified compressed sections: " .. compressedSectionCount .. " (should match: " .. sectionCount .. ")")
        
        -- Double check in case of mismatch
        if compressedSectionCount ~= sectionCount then
            self:Debug("error", "Mismatch between compressed sections and assignments - forcing regeneration")
            -- Create a completely new TWRA_CompressedAssignments again to ensure clean state
            TWRA_CompressedAssignments = {
                sections = {},
                structure = nil,
                timestamp = timestamp,
                useSectionCompression = true
            }
            
            -- Force regeneration of compressed data
            if self.StoreSegmentedData then
                self:StoreSegmentedData()
            elseif self.StoreCompressedData then
                self:StoreCompressedData()
            end
            
            -- Verify again
            compressedSectionCount = 0
            for _, _ in pairs(TWRA_CompressedAssignments.sections) do
                compressedSectionCount = compressedSectionCount + 1
            end
            self:Debug("data", "After forced regeneration: " .. compressedSectionCount .. " compressed sections")
        end
    end
    
    -- Step 9: Process player-specific info 
    if self.ProcessPlayerInfo then
        self:Debug("data", "Processing player-specific info after import")
        pcall(function() self:ProcessPlayerInfo() end)
    end
    
    -- Store the current section name if it exists in the imported data
    local currentSectionName = nil
    if importData.currentSection and importData.data and importData.data[importData.currentSection] then
        currentSectionName = importData.data[importData.currentSection]["Section Name"]
        self:Debug("nav", "Found current section in imported data: " .. (currentSectionName or "unknown"))
    end

    -- Find the index of the current section name in our navigation handlers
    local targetSectionIndex = 1
    if currentSectionName then
        for idx, name in ipairs(self.navigation.handlers) do
            if name == currentSectionName then
                targetSectionIndex = idx
                self:Debug("nav", "Will navigate to imported current section: " .. name .. " (index " .. idx .. ")")
                break
            end
        end
    end
    
    -- Store the target section in TWRA_Assignments so other processes don't reset it
    TWRA_Assignments.currentSection = targetSectionIndex
    self:Debug("nav", "Set TWRA_Assignments.currentSection to " .. targetSectionIndex)
    
    -- Step 10: Update UI
    if self.DisplayCurrentSection then
        self:Debug("ui", "Updating display with new data with sync suppressed")
        
        -- Set a flag indicating we're in an import operation to completely suppress sync
        -- This flag should be checked in navigation and sync functions
        self.isImportingData = true
        
        -- Prevent rebuilding navigation after import from resetting to section 1
        self.preventAutoNavigation = true
        
        -- Display the target section without triggering sync
        self:DisplayCurrentSection(targetSectionIndex, true) -- Pass the target section index with fromImport=true
        
        -- Clear the flags after a short delay to allow rendering to complete
        self:ScheduleTimer(function()
            self.isImportingData = nil
            self.preventAutoNavigation = nil
            self:Debug("data", "Import operation completed, normal sync operations resumed")
        end, 0.5) -- Increased delay to ensure all processes complete
    end

    -- Step 11: Send all sections in bulk to other players in the raid ONLY if we're in a group
    -- Always sync after import when in a group, regardless of liveSync setting
    if GetNumRaidMembers() > 0 or GetNumPartyMembers() > 0 then
        self:Debug("sync", "Import complete - preparing to send all sections to group members")
        
        if self.SendAllSections then
            -- Create a longer delay to ensure all processing is fully complete
            -- and that isImportingData and preventAutoNavigation flags have been cleared
            self:ScheduleTimer(function()
                -- Double-check that we're still on the correct section before syncing
                if self.navigation and self.navigation.currentIndex ~= targetSectionIndex then
                    self:Debug("nav", "Section changed during import processing - restoring to " .. targetSectionIndex)
                    self.isImportingData = true
                    self:DisplayCurrentSection(targetSectionIndex, true)
                    self:ScheduleTimer(function() self.isImportingData = nil end, 0.2)
                end
                
                self:Debug("sync", "Executing SendAllSections as the final step of import")
                -- Use direct modern sync method only
                self:SendAllSections()
            end, 1.0) -- 1.0 second delay to ensure all flags have been cleared
        else
            self:Debug("sync", "SendAllSections function not available")
        end
    else
        self:Debug("sync", "Not in a group - skipping bulk sync after import")
    end
    
    -- Success message
    DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA:|r Successfully imported new format data with " .. 
        sectionCount .. " sections")
    
    return true
end
