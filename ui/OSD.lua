-- TWRA On-Screen Display (OSD) module
-- Handles frame creation, layout and visibility
TWRA = TWRA or {}

-- Initialize OSD settings
TWRA.OSD = TWRA.OSD or {
    isVisible = false,
    autoHideTimer = nil,
    duration = 2,
    scale = 1.0,
    locked = false,
    enabled = true,
    showOnNavigation = true,
    point = "CENTER",
    xOffset = 0,
    yOffset = 100
}

-- Initialize the OSD system
function TWRA:InitOSD()
    self:Debug("osd", "Initializing OSD system")
    
    -- Apply saved settings if they exist
    if TWRA_SavedVariables and TWRA_SavedVariables.options and TWRA_SavedVariables.options.osd then
        local savedSettings = TWRA_SavedVariables.options.osd
        
        -- Apply each saved setting to the runtime settings
        for key, value in pairs(savedSettings) do
            -- Convert any 0/1 values to proper booleans
            if key == "enabled" or key == "showOnNavigation" or key == "locked" then
                self.OSD[key] = (value == true or value == 1)
            else
                self.OSD[key] = value
            end
        end
        self:Debug("osd", "Loaded saved OSD settings")
    end
    
    -- Register for section change message to show OSD
    self:RegisterMessageHandler("SECTION_CHANGED", function(sectionName, sectionIndex, totalSections, context)
        -- Only show OSD if enabled and we should show on navigation
        if not self.OSD.enabled or not self.OSD.showOnNavigation then
            self:Debug("osd", "OSD skipped - not enabled or not set to show on navigation")
            return
        end
        
        -- Handle the section change
        self:ShowOSD(self.OSD.duration)
        self:UpdateOSDContent(sectionName, sectionIndex, totalSections)
        self:Debug("osd", "OSD shown for section: " .. (sectionName or "unknown"))
    end)
    
    self.OSD.initialized = true
    self:Debug("osd", "OSD system initialized")
    return true
end

-- Function to update OSD display with the formatted data
function TWRA:UpdateOSDWithFormattedData()
    -- Create or get OSD frame
    local frame = self:GetOSDFrame()
    
    -- Get current section name
    local sectionName = nil
    if self.navigation and self.navigation.handlers and self.navigation.currentIndex then
        sectionName = self.navigation.handlers[self.navigation.currentIndex]
    end
    
    if not sectionName then
        self:Debug("osd", "No section name available")
        return false
    end
    
    -- Make sure we are using the original background style
    if not frame.bg then
        -- Add background with transparency
        local bg = frame:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetTexture(0, 0, 0, 0.5) -- Main background
        frame.bg = bg
        
        -- Add border
        local border = CreateFrame("Frame", nil, frame)
        border:SetPoint("TOPLEFT", -2, 2)
        border:SetPoint("BOTTOMRIGHT", 2, -2)
        border:SetBackdrop({
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        frame.border = border
        
        -- Remove any previous backdrop
        frame:SetBackdrop(nil)
    end
    
    -- COMPLETELY REMOVE the footerContainer and create a fresh one
    if frame.footerContainer then
        -- First, delete all child frames
        local children = {frame.footerContainer:GetChildren()}
        for _, child in pairs(children) do
            child:SetParent(nil)
            child:Hide()
        end
        
        -- Delete all textures and regions
        local regions = {frame.footerContainer:GetRegions()}
        for _, region in pairs(regions) do
            region:SetParent(nil)
            region:Hide()
        end
        
        -- Delete the container itself
        frame.footerContainer:SetParent(nil)
        frame.footerContainer:Hide()
        frame.footerContainer = nil
        
        self:Debug("osd", "Completely removed old footer container")
    end
    
    -- Call DatarowsOSD to create/update the data rows directly in contentContainer
    local dataRowsHeight = 0
    if self.DatarowsOSD then
        dataRowsHeight = self:DatarowsOSD(frame.contentContainer, sectionName) or 0
        self:Debug("osd", "DatarowsOSD returned height: " .. dataRowsHeight)
    else
        self:Debug("osd", "DatarowsOSD function not found")
    end
    
    -- Create a brand new footerContainer
    local footerContainer = CreateFrame("Frame", nil, frame)
    footerContainer:SetPoint("TOPLEFT", frame.contentContainer, "BOTTOMLEFT", 0, -5)
    footerContainer:SetPoint("TOPRIGHT", frame.contentContainer, "BOTTOMRIGHT", 0, -5)
    footerContainer:SetHeight(1) -- Default minimal height
    frame.footerContainer = footerContainer
    
    -- Call UpdateOSDFooters to add content to the new footer container
    local footerHeight = 0
    if self.UpdateOSDFooters then
        footerHeight = self:UpdateOSDFooters(frame.footerContainer, sectionName) or 0
        self:Debug("osd", "UpdateOSDFooters returned height: " .. footerHeight)
    else
        self:Debug("osd", "UpdateOSDFooters function not found")
    end
    
    -- Update content container height
    frame.contentContainer:SetHeight(dataRowsHeight)
    
    -- Calculate total frame height including padding
    local totalFrameHeight = frame.infoContainer:GetHeight() + dataRowsHeight + footerHeight + 5 + 18 -- Verified to look good in-game do not adjust the +23 here
    -- Height calculation includes:
    -- - infoContainer height
    -- - contentContainer height (dataRowsHeight)
    -- - footerContainer height (footerHeight)
    -- - 5px padding between contentContainer and footerContainer 
    -- - 6px extra padding at the bottom of the frame
    
    -- Set minimum height
    if totalFrameHeight < 60 then 
        totalFrameHeight = 60
    end
    
    -- Debug the height calculation
    self:Debug("osd", "Frame height calculation: infoHeight(" .. frame.infoContainer:GetHeight() .. 
                      ") + contentHeight(" .. dataRowsHeight .. 
                      ") + padding(5) + footers(" .. footerHeight .. 
                      ") + extraPadding(6) = " .. totalFrameHeight)
    
    -- Update frame height
    frame:SetHeight(totalFrameHeight)
    
    -- Make sure the frame is shown
    frame:Show()
    self.OSD.isVisible = true
    
    return true
end

-- Create or get the OSD frame
function TWRA:GetOSDFrame()
    if self.OSDFrame then
        return self.OSDFrame
    end
    
    -- Create the main OSD frame
    local frame = CreateFrame("Frame", "TWRAOSDFrame", UIParent)
    frame:SetFrameStrata("DIALOG")
    frame:SetWidth(400)
    frame:SetHeight(200) -- Initial height, will be adjusted
    
    -- Position the frame
    frame:ClearAllPoints()
    frame:SetPoint(self.OSD.point, UIParent, self.OSD.point, self.OSD.xOffset, self.OSD.yOffset)
    frame:SetScale(self.OSD.scale or 1.0)
    
    -- Add background with transparency (original style)
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture(0, 0, 0, 0.5) -- Main background
    frame.bg = bg
    
    -- Add border
    local border = CreateFrame("Frame", nil, frame)
    border:SetPoint("TOPLEFT", -2, 2)
    border:SetPoint("BOTTOMRIGHT", 2, -2)
    border:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    frame.border = border
    
    -- Make the frame movable if not locked
    frame:SetMovable(not self.OSD.locked)
    frame:EnableMouse(not self.OSD.locked)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function() this:StartMoving() end)
    frame:SetScript("OnDragStop", function()
        this:StopMovingOrSizing()
        -- Save position
        local point, _, _, xOffset, yOffset = this:GetPoint()
        TWRA.OSD.point = point
        TWRA.OSD.xOffset = xOffset
        TWRA.OSD.yOffset = yOffset
        
        -- Update saved variables
        if TWRA_SavedVariables and TWRA_SavedVariables.options and TWRA_SavedVariables.options.osd then
            TWRA_SavedVariables.options.osd.point = point
            TWRA_SavedVariables.options.osd.xOffset = xOffset
            TWRA_SavedVariables.options.osd.yOffset = yOffset
        end
    end)
    
    -- Create header container (for title) - with minimal top padding
    local headerContainer = CreateFrame("Frame", nil, frame)
    headerContainer:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -5) -- Reduced top padding to 5px
    headerContainer:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -5)
    headerContainer:SetHeight(25)
    frame.infoContainer = headerContainer  -- Using infoContainer as the name for consistency
    
    -- Create title text
    local titleText = headerContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleText:SetPoint("TOP", headerContainer, "TOP", 0, 0)
    titleText:SetPoint("LEFT", headerContainer, "LEFT", 10, 0) -- Added left padding to text instead
    titleText:SetPoint("RIGHT", headerContainer, "RIGHT", -10, 0) -- Added right padding to text instead
    titleText:SetHeight(25)
    titleText:SetJustifyH("CENTER")
    titleText:SetText("Current Section")
    frame.titleText = titleText
    
    -- Create content container (for data rows) - with padding only at the top
    local contentContainer = CreateFrame("Frame", nil, frame)
    contentContainer:SetPoint("TOPLEFT", headerContainer, "BOTTOMLEFT", 0, -5) -- 5px space after title
    contentContainer:SetPoint("TOPRIGHT", headerContainer, "BOTTOMRIGHT", 0, -5)
    contentContainer:SetHeight(50) -- Initial height, will be adjusted
    frame.contentContainer = contentContainer
    
    -- Create footer container (for warnings/notes) - NO padding, directly below content
    local footerContainer = CreateFrame("Frame", nil, frame)
    footerContainer:SetPoint("TOPLEFT", contentContainer, "BOTTOMLEFT", 0, -10) -- Add 10px padding above footer
    footerContainer:SetPoint("TOPRIGHT", contentContainer, "BOTTOMRIGHT", 0, 0) -- Full width
    footerContainer:SetHeight(1) -- Initial height (will be adjusted)
    frame.footerContainer = footerContainer
    
    -- Set initial visibility
    frame:Hide()
    self.OSDFrame = frame
    
    self:Debug("osd", "OSD frame created with original background style")
    return frame
end

-- Function to toggle OSD visibility
function TWRA:ToggleOSD()
    -- Make sure OSD is initialized
    if not self.OSD then
        self:InitOSD()
    end
    
    if self.OSD.isVisible then
        self:HideOSD()
    else
        self:ShowOSDPermanent()
    end
    
    return self.OSD.isVisible
end

-- Show the OSD permanently (no auto-hide)
function TWRA:ShowOSDPermanent()
    -- Skip if OSD is disabled
    if not self.OSD or not self.OSD.enabled then
        self:Debug("osd", "OSD is disabled, cannot show permanently")
        return false
    end
    
    -- Create or ensure the frame exists
    local frame = self:GetOSDFrame()
    if not frame then
        self:Debug("osd", "Failed to get or create OSD frame")
        return false
    end
    
    -- Make sure the frame exists and is valid before trying to show it
    if frame.Show then
        -- Update the OSD content
        self:RefreshOSDContent()
        
        -- Show the frame
        frame:Show()
        
        -- Clear any existing hide timer
        if self.OSD.hideTimer then
            self:CancelTimer(self.OSD.hideTimer)
            self.OSD.hideTimer = nil
        end
        
        -- Mark as visible
        self.OSD.isVisible = true
        
        self:Debug("osd", "OSD shown permanently")
        return true
    else
        self:Debug("osd", "Invalid OSD frame, cannot show")
        return false
    end
end

-- Show the OSD with optional auto-hide
function TWRA:ShowOSD(duration)
    -- Skip if OSD is disabled
    if not self.OSD or not self.OSD.enabled then
        self:Debug("osd", "OSD is disabled, cannot show")
        return false
    end
    
    -- Get or create the OSD frame
    local frame = self:GetOSDFrame()
    if not frame then
        self:Debug("osd", "Failed to get or create OSD frame")
        return false
    end
    
    -- Make sure the frame exists and is valid before trying to show it
    if frame.Show then
        -- Update the OSD content
        self:RefreshOSDContent()
        
        -- Show the frame
        frame:Show()
        
        -- Clear any existing hide timer
        if self.OSD.hideTimer then
            self:CancelTimer(self.OSD.hideTimer)
            self.OSD.hideTimer = nil
        end
        
        -- Set up auto-hide if duration is provided
        local hideDuration = duration or self.OSD.duration or 2
        if hideDuration > 0 then
            self.OSD.hideTimer = self:ScheduleTimer(function()
                self:HideOSD()
            end, hideDuration)
            
            self:Debug("osd", "OSD shown with auto-hide in " .. hideDuration .. " seconds")
        else
            self:Debug("osd", "OSD shown")
        end
        
        -- Mark as visible
        self.OSD.isVisible = true
        
        return true
    else
        self:Debug("osd", "Invalid OSD frame, cannot show")
        return false
    end
end

-- Hide the OSD
function TWRA:HideOSD()
    -- Skip if there's no OSD or it's already hidden
    if not self.OSD then return false end
    
    -- Clear any existing hide timer
    if self.OSD.hideTimer then
        self:CancelTimer(self.OSD.hideTimer)
        self.OSD.hideTimer = nil
    end
    
    -- Mark as hidden first (even if we can't find the frame)
    self.OSD.isVisible = false
    
    -- Check if the frame exists and hide it safely
    if self.OSDFrame then
        -- Safety check before hiding
        if self.OSDFrame.Hide then
            self.OSDFrame:Hide()
            self:Debug("osd", "OSD hidden")
        else
            self:Debug("osd", "Invalid OSD frame, cannot hide")
        end
    end
    
    return true
end

-- Update OSD content with section information
function TWRA:UpdateOSDContent(sectionName, sectionIndex)
    -- Get or create the OSD frame
    local frame = self:GetOSDFrame()
    if not frame then
        self:Debug("osd", "Failed to get or create OSD frame")
        return false
    end
    
    -- Update section title
    if frame.titleText then
        frame.titleText:SetText(sectionName or "Unknown Section")
    end
    
    -- Call the function to update the OSD with formatted data
    return self:UpdateOSDWithFormattedData()
end

-- Helper function to adjust frame height based on content
function TWRA:AdjustOSDFrameHeight()
    local frame = self.OSDFrame
    if not frame then return false end
    
    -- Calculate total height based on container heights
    local totalHeight = 0
    
    -- Add header height
    if frame.headerContainer then
        totalHeight = totalHeight + frame.headerContainer:GetHeight()
    end
    
    -- Add content height
    if frame.contentContainer then
        totalHeight = totalHeight + frame.contentContainer:GetHeight()
    end
    
    -- Add footer height if it has content
    if frame.footerContainer then
        if frame.footerContainer:GetHeight() > 0 then
            totalHeight = totalHeight + frame.footerContainer:GetHeight()
        end
    end
    
    
    -- Add padding
    totalHeight = totalHeight + 36 -- Add some padding
    
    -- Set minimum height
    if totalHeight < 100 then
        totalHeight = 100
    end
    
    -- Update frame height
    frame:SetHeight(totalHeight)
    self:Debug("osd", "Adjusted OSD frame height to " .. totalHeight)
    
    return true
end

-- Function to refresh the OSD content with current section information
function TWRA:RefreshOSDContent()
    -- Skip if OSD isn't initialized or not enabled
    if not self.OSD or not self.OSD.enabled then
        self:Debug("osd", "OSD not enabled, cannot refresh")
        return false
    end
    
    -- Ensure we have navigation data
    if not self.navigation or not self.navigation.handlers or not self.navigation.currentIndex then
        self:Debug("osd", "Navigation not initialized, cannot refresh OSD")
        return false
    end
    
    -- Get current section information
    local currentIndex = self.navigation.currentIndex
    local sectionName = self.navigation.handlers[currentIndex]
    
    if not sectionName then
        self:Debug("osd", "No section name available for index: " .. currentIndex)
        return false
    end
    
    -- Update the OSD with section information
    self:UpdateOSDContent(sectionName, currentIndex)
    
    self:Debug("osd", "OSD refreshed with section: " .. sectionName)
    return true
end

-- Test function to show example OSD content
function TWRA:TestOSD()
    self:Debug("osd", "Testing OSD display")
    
    -- Create some fake data for testing
    local testSectionName = "Test Section"
    local testSectionIndex = 1
    local testTotalSections = 3
    
    -- Show the OSD with test data
    self:ShowOSD(5) -- Auto-hide after 5 seconds
    self:UpdateOSDContent(testSectionName, testSectionIndex, testTotalSections)
    
    return true
end

-- Toggle OSD enabled state
function TWRA:ToggleOSDEnabled(enabled)
    -- Set the state
    if enabled ~= nil then
        self.OSD.enabled = enabled
    else
        self.OSD.enabled = not self.OSD.enabled
    end
    
    -- Update saved settings
    if TWRA_SavedVariables and TWRA_SavedVariables.options then
        TWRA_SavedVariables.options.osd = TWRA_SavedVariables.options.osd or {}
        TWRA_SavedVariables.options.osd.enabled = self.OSD.enabled
    end
    
    self:Debug("osd", "OSD " .. (self.OSD.enabled and "enabled" or "disabled"))
    return self.OSD.enabled
end

-- Toggle OSD on navigation
function TWRA:ToggleOSDOnNavigation(enabled)
    -- Set the state
    if enabled ~= nil then
        self.OSD.showOnNavigation = enabled
    else
        self.OSD.showOnNavigation = not self.OSD.showOnNavigation
    end
    
    -- Update saved settings
    if TWRA_SavedVariables and TWRA_SavedVariables.options then
        TWRA_SavedVariables.options.osd = TWRA_SavedVariables.options.osd or {}
        TWRA_SavedVariables.options.osd.showOnNavigation = self.OSD.showOnNavigation
    end
    
    self:Debug("osd", "OSD on navigation " .. (self.OSD.showOnNavigation and "enabled" or "disabled"))
    return self.OSD.showOnNavigation
end

-- Update OSD settings (scale, position, lock state)
function TWRA:UpdateOSDSettings()
    local frame = self.OSDFrame
    if not frame then return false end
    
    -- Update scale
    frame:SetScale(self.OSD.scale or 1.0)
    
    -- Update position
    frame:ClearAllPoints()
    frame:SetPoint(self.OSD.point, UIParent, self.OSD.point, self.OSD.xOffset, self.OSD.yOffset)
    
    -- Update movable state
    frame:SetMovable(not self.OSD.locked)
    frame:EnableMouse(not self.OSD.locked)
    
    self:Debug("osd", "OSD settings updated")
    return true
end

-- Reset OSD position to center
function TWRA:ResetOSDPosition()
    -- Reset position values
    self.OSD.point = "CENTER"
    self.OSD.xOffset = 0
    self.OSD.yOffset = 100
    
    -- Update saved settings
    if TWRA_SavedVariables and TWRA_SavedVariables.options then
        TWRA_SavedVariables.options.osd = TWRA_SavedVariables.options.osd or {}
        TWRA_SavedVariables.options.osd.point = self.OSD.point
        TWRA_SavedVariables.options.osd.xOffset = self.OSD.xOffset
        TWRA_SavedVariables.options.osd.yOffset = self.OSD.yOffset
    end
    
    -- Apply the position reset
    if self.OSDFrame then
        self.OSDFrame:ClearAllPoints()
        self.OSDFrame:SetPoint(self.OSD.point, UIParent, self.OSD.point, self.OSD.xOffset, self.OSD.yOffset)
    end
    
    self:Debug("osd", "OSD position reset to center")
    return true
end

-- Show section name in an overlay temporarily
function TWRA:ShowSectionNameOverlay(sectionName, sectionIndex, totalSections)
    if not sectionName then return false end
    
    -- Use the standard OSD to show section info
    self:ShowOSD(self.OSD.duration)
    self:UpdateOSDContent(sectionName, sectionIndex, totalSections)
    
    return true
end

-- Helper function to debug OSD elements
function TWRA:DebugOSDElements()
    -- Get frame
    local frame = self:GetOSDFrame()
    if not frame then
        self:Debug("osd", "No OSD frame available")
        return
    end

    -- Debug assignment data
    if self.assignments then
        if self.assignments.warnings then
            self:Debug("osd", "Warnings count: " .. table.getn(self.assignments.warnings))
            for i, warning in ipairs(self.assignments.warnings) do
                self:Debug("osd", "  Warning " .. i .. ": " .. warning)
            end
        else
            self:Debug("osd", "No warnings data")
        end

        if self.assignments.notes then
            self:Debug("osd", "Notes count: " .. table.getn(self.assignments.notes))
            for i, note in ipairs(self.assignments.notes) do
                self:Debug("osd", "  Note " .. i .. ": " .. note)
            end
        else
            self:Debug("osd", "No notes data")
        end
    else
        self:Debug("osd", "No assignments data available")
    end

    -- Check if containers exist
    self:Debug("osd", "Warning container exists: " .. tostring(frame.warningContainer ~= nil))
    self:Debug("osd", "Note container exists: " .. tostring(frame.noteContainer ~= nil))

    -- Check visibility
    if frame.warningContainer then
        self:Debug("osd", "Warning container is shown: " .. tostring(frame.warningContainer:IsShown()))
    end
    
    if frame.noteContainer then
        self:Debug("osd", "Note container is shown: " .. tostring(frame.noteContainer:IsShown()))
    end

    -- Check content container
    self:Debug("osd", "Content container height: " .. frame.contentContainer:GetHeight())
    self:Debug("osd", "Frame total height: " .. frame:GetHeight())
end