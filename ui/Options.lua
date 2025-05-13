-- TWRA Options Module
-- Streamlined implementation with improved structure
TWRA = TWRA or {}

-- Initialize options system
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
    
    -- Load options components
    self:LoadOptionsComponents()
    
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

-- Load all options component modules
function TWRA:LoadOptionsComponents()
    self:Debug("general", "Loading options component modules")
    
    -- Initialize component system
    self.optionsComponents = self.optionsComponents or {}
    
    -- Load General component (left column)
    if self.LoadOptionsGeneral then
        self:LoadOptionsGeneral()
        self:Debug("general", "Loaded Options-General component")
    else
        self:Debug("error", "Options-General component not available")
    end
    
    -- Load OSD component (middle column)
    if self.LoadOptionsOSD then
        self:LoadOptionsOSD()
        self:Debug("general", "Loaded Options-OSD component")
    else
        self:Debug("error", "Options-OSD component not available")
    end
    
    -- Load Import component (right column)
    if self.LoadOptionsImport then
        self:LoadOptionsImport()
        self:Debug("general", "Loaded Options-Import component")
    else
        self:Debug("error", "Options-Import component not available")
    end
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
    
    -- Store column references for component access
    self.optionsLeftColumn = leftColumn
    self.optionsMiddleColumn = middleColumn
    self.optionsRightColumn = rightColumn
    
    -- Create components in each column
    self:CreateOptionsGeneralColumn(leftColumn)
    self:CreateOptionsOSDColumn(middleColumn)
    self:CreateOptionsImportColumn(rightColumn)
    
    -- Return options elements
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
