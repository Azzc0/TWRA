-- TWRA On-Screen Display Module
-- Handles displaying player-relevant assignments when navigating between sections

TWRA = TWRA or {}
TWRA.OSD = TWRA.OSD or {}

-- Initialize the OSD system
function TWRA:InitOSD()
    self:Debug("osd", "Initializing On-Screen Display system")
    
    -- Ensure OSD namespace exists
    self.OSD = self.OSD or {}
    
    -- Load default settings if they don't exist
    TWRA_SavedVariables.options = TWRA_SavedVariables.options or {}
    
    if not TWRA_SavedVariables.options.osd then
        TWRA_SavedVariables.options.osd = {
            point = "CENTER",
            xOffset = 0,
            yOffset = 100,
            scale = 1.0,
            duration = 2,
            locked = 0,
            enabled = 1,           -- Master toggle for OSD functionality (1 = enabled)
            showOnNavigation = 1   -- NEW: Separate option for auto-display on navigation (1 = enabled)
        }
    end
    
    -- Ensure new properties exist (might be missing in existing settings)
    if TWRA_SavedVariables.options.osd.enabled == nil then
        TWRA_SavedVariables.options.osd.enabled = 1
    end
    
    -- Add the new showOnNavigation option if it doesn't exist
    if TWRA_SavedVariables.options.osd.showOnNavigation == nil then
        TWRA_SavedVariables.options.osd.showOnNavigation = 1
    end
    
    -- Apply settings to OSD module, converting 0/1 to boolean for internal use
    local osdSettings = TWRA_SavedVariables.options.osd
    self.OSD.point = osdSettings.point
    self.OSD.xOffset = osdSettings.xOffset
    self.OSD.yOffset = osdSettings.yOffset
    self.OSD.scale = osdSettings.scale
    self.OSD.duration = osdSettings.duration
    self.OSD.locked = osdSettings.locked == 1
    self.OSD.enabled = osdSettings.enabled == 1
    self.OSD.showOnNavigation = osdSettings.showOnNavigation == 1
    
    -- Create the OSD frame if needed
    if not self.osdFrame then
        self:CreateOSDFrame()
    end
    
    -- Register for section changed events - FIXED
    self:RegisterMessageHandler("SECTION_CHANGED", function(sectionName, sectionIndex, totalSections, context)
        -- Always update the OSD content regardless of visibility
        self:UpdateOSDContent(sectionName, sectionIndex, totalSections)
        
        -- Only show OSD if auto-display is enabled and conditions are met
        if self.OSD.enabled and self.OSD.showOnNavigation then
            -- Determine if we should show the OSD based on context
            local shouldShow = false
            
            -- If context is provided, use it to determine visibility
            if context then
                -- Show when:
                -- 1. Main frame is not visible OR
                -- 2. We're in the options view OR
                -- 3. Navigation came from sync
                shouldShow = not context.isMainFrameVisible or context.inOptionsView or context.fromSync
            else
                -- Fallback - if no context, check window visibility directly
                shouldShow = not self.mainFrame or not self.mainFrame:IsShown() or self.currentView == "options"
            end
            
            if shouldShow then
                self:ShowOSD(sectionName, sectionIndex, totalSections)
            end
        end
    end)
    
    -- Make sure GetPlayerRelevantRows exists
    if not self.GetPlayerRelevantRows then
        self.GetPlayerRelevantRows = function(sectionData)
            local relevantRows = {}
            local playerName = UnitName("player")
            
            for rowIndex, row in ipairs(sectionData) do
                if row[2] ~= "Icon" and row[2] ~= "Note" and row[2] ~= "Warning" then
                    for _, cellData in ipairs(row) do
                        if cellData == playerName then
                            table.insert(relevantRows, rowIndex)
                            break
                        end
                    end
                end
            end
            
            return relevantRows
        end
    end
    
    -- Update OSD after initialization with the current section
    -- This ensures OSD is up to date after a UI reload
    self:ScheduleTimer(function()
        if self.navigation and self.navigation.currentIndex and self.navigation.handlers then
            local currentIndex = self.navigation.currentIndex
            local totalSections = table.getn(self.navigation.handlers)
            if totalSections > 0 and currentIndex <= totalSections then
                local sectionName = self.navigation.handlers[currentIndex]
                if sectionName then
                    self:UpdateOSDContent(sectionName, currentIndex, totalSections)
                    self:Debug("osd", "OSD content updated with current section after initialization")
                end
            end
        end
    end, 0.5) -- Short delay to ensure navigation is fully loaded
    
    self:Debug("osd", "OSD system initialized (enabled: " .. (self.OSD.enabled and "true" or "false") .. 
                       ", showOnNavigation: " .. (self.OSD.showOnNavigation and "true" or "false") .. ")")
    return true
end

-- Toggle the OSD enabled state
function TWRA:ToggleOSDEnabled(state)
    -- Set state if provided, otherwise toggle
    if state ~= nil then
        self.OSD.enabled = state
    else
        self.OSD.enabled = not self.OSD.enabled
    end
    
    -- Save to config - ensure option path exists
    if not TWRA_SavedVariables.options then TWRA_SavedVariables.options = {} end
    if not TWRA_SavedVariables.options.osd then TWRA_SavedVariables.options.osd = {} end
    TWRA_SavedVariables.options.osd.enabled = self.OSD.enabled -- Store as boolean
    
    -- Debug message
    self:Debug("osd", "OSD " .. (self.OSD.enabled and "enabled" or "disabled"))
    
    -- If enabling and we have a current section, show a preview
    if self.OSD.enabled and self.navigation and self.navigation.currentIndex and 
       self.navigation.handlers and table.getn(self.navigation.handlers) > 0 then
        local currentIndex = self.navigation.currentIndex
        local sectionName = self.navigation.handlers[currentIndex]
        local totalSections = table.getn(self.navigation.handlers)
        
        self:ShowOSD(sectionName, currentIndex, totalSections)
    end
    
    return self.OSD.enabled
end

-- Toggle whether OSD shows automatically on navigation
function TWRA:ToggleOSDOnNavigation(state)
    -- Set state if provided, otherwise toggle
    if state ~= nil then
        self.OSD.showOnNavigation = state
    else
        self.OSD.showOnNavigation = not self.OSD.showOnNavigation
    end
    
    -- Save to config - ensure option path exists
    if not TWRA_SavedVariables.options then TWRA_SavedVariables.options = {} end
    if not TWRA_SavedVariables.options.osd then TWRA_SavedVariables.options.osd = {} end
    TWRA_SavedVariables.options.osd.showOnNavigation = self.OSD.showOnNavigation -- Store as boolean
    
    -- Debug message
    self:Debug("osd", "OSD on Navigation " .. (self.OSD.showOnNavigation and "enabled" or "disabled"))
    
    return self.OSD.showOnNavigation
end

-- Create a simple OSD frame
function TWRA:CreateOSDFrame()
    self:Debug("osd", "Creating OSD frame")
    
    -- Create the main frame
    self.osdFrame = CreateFrame("Frame", "TWRA_OSDFrame", UIParent)
    self.osdFrame:SetFrameStrata("DIALOG")
    self.osdFrame:SetWidth(400)
    self.osdFrame:SetHeight(300)
    
    -- Position based on saved settings
    self.osdFrame:SetPoint(
        self.OSD.point or "CENTER",
        UIParent,
        self.OSD.point or "CENTER",
        self.OSD.xOffset or 0,
        self.OSD.yOffset or 100
    )
    
    -- Apply scale
    self.osdFrame:SetScale(self.OSD.scale or 1.0)
    
    -- Background and border
    self.osdFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    
    -- Section title
    self.osdTitle = self.osdFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    self.osdTitle:SetPoint("TOP", self.osdFrame, "TOP", 0, -15)
    self.osdTitle:SetTextColor(1, 0.82, 0)
    
    -- Create scroll frame for assignments
    self.scrollFrame = CreateFrame("ScrollFrame", "TWRA_OSDScrollFrame", self.osdFrame, "UIPanelScrollFrameTemplate")
    self.scrollFrame:SetPoint("TOPLEFT", 20, -40)
    self.scrollFrame:SetPoint("BOTTOMRIGHT", -40, 30)
    
    -- Content frame to hold assignments
    self.contentFrame = CreateFrame("Frame", "TWRA_OSDContentFrame", self.scrollFrame)
    self.contentFrame:SetWidth(self.scrollFrame:GetWidth() - 20)
    self.contentFrame:SetHeight(400) -- Will be adjusted based on content
    self.scrollFrame:SetScrollChild(self.contentFrame)
    
    -- Footer with section count
    self.osdFooter = self.osdFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.osdFooter:SetPoint("BOTTOM", self.osdFrame, "BOTTOM", 0, 10)
    self.osdFooter:SetTextColor(1, 1, 1)
    
    -- Store array for assignment text elements
    self.assignmentLines = {}
    
    -- Make frame movable if not locked
    if not self.OSD.locked then
        self.osdFrame:SetMovable(true)
        self.osdFrame:EnableMouse(true)
        self.osdFrame:RegisterForDrag("LeftButton")
        self.osdFrame:SetScript("OnDragStart", function()
            this:StartMoving()
        end)
        self.osdFrame:SetScript("OnDragStop", function()
            this:StopMovingOrSizing()
            -- Save new position
            local point, _, _, xOffset, yOffset = this:GetPoint()
            TWRA.OSD.point = point
            TWRA.OSD.xOffset = xOffset
            TWRA.OSD.yOffset = yOffset
            
            -- Update saved variables
            TWRA_SavedVariables.options.osd.point = point
            TWRA_SavedVariables.options.osd.xOffset = xOffset
            TWRA_SavedVariables.options.osd.yOffset = yOffset
        end)
    end
    
    -- Hide initially
    self.osdFrame:Hide()
    
    return self.osdFrame
end

-- Filter data to get only rows for the current section
function TWRA:GetSectionData(sectionName)
    if not self.fullData or not sectionName then return {} end
    
    local sectionData = {}
    for i = 1, table.getn(self.fullData) do
        if self.fullData[i][1] == sectionName then
            table.insert(sectionData, self.fullData[i])
        end
    end
    
    return sectionData
end

-- Format player assignments for display
function TWRA:FormatAssignmentLine(row, headerRow)
    local icon = row[2]
    local target = row[3] or ""
    local playerName = UnitName("player")
    local roleLabel = "Role"
    local playerColumn = nil
    
    -- Find player's role in this row
    for col = 4, table.getn(row) do
        if row[col] == playerName then
            roleLabel = headerRow[col] or "Role"
            playerColumn = col
            break
        end
    end
    
    -- Get colored icon if available
    local coloredIcon = icon
    if self.COLORED_ICONS and self.COLORED_ICONS[icon] then
        coloredIcon = self.COLORED_ICONS[icon]
    else
        -- Use raid icon texture if available
        if self.ICON_IDS and self.ICON_IDS[icon] then
            coloredIcon = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_" .. 
                          self.ICON_IDS[icon] .. ":0|t"
        end
    end
    
    -- Format the line
    local line = roleLabel .. " - " .. coloredIcon
    if target ~= "" then
        line = line .. " " .. target
    end
    
    -- Add other players with same role
    if playerColumn then
        local others = {}
        for col = 4, table.getn(row) do
            if col ~= playerColumn and row[col] ~= "" and row[col] ~= playerName and headerRow[col] == roleLabel then
                table.insert(others, row[col])
            end
        end
        
        if table.getn(others) > 0 then
            line = line .. " with " .. table.concat(others, ", ")
        end
    end
    
    return line
end

-- Display player-relevant assignments in OSD
function TWRA:DisplayAssignments(sectionName)
    if not self.osdFrame or not self.contentFrame then return end
    
    -- Clear previous assignments
    for i = 1, table.getn(self.assignmentLines) do
        if self.assignmentLines[i] then
            self.assignmentLines[i]:Hide()
            self.assignmentLines[i]:SetText("")
        end
    end
    
    -- Get section data
    local sectionData = self:GetSectionData(sectionName)
    if table.getn(sectionData) == 0 then return end
    
    -- Find header row
    local headerRow = nil
    for i = 1, table.getn(sectionData) do
        if sectionData[i][2] == "Icon" then
            headerRow = sectionData[i]
            break
        end
    end
    
    if not headerRow then
        self:Debug("osd", "No header row found in section: " .. sectionName)
        return
    end
    
    -- Find rows relevant to the player
    local relevantRows = self:GetPlayerRelevantRows(sectionData)
    
    -- Display assignments
    local yOffset = 0
    for i = 1, table.getn(relevantRows) do
        local rowIndex = relevantRows[i]
        local row = sectionData[rowIndex]
        
        -- Format the line
        local line = self:FormatAssignmentLine(row, headerRow)
        
        -- Create or reuse a text element
        if not self.assignmentLines[i] then
            self.assignmentLines[i] = self.contentFrame:CreateFontString(
                nil, "OVERLAY", "GameFontNormal")
        end
        
        -- Position and display the line
        self.assignmentLines[i]:SetPoint("TOPLEFT", self.contentFrame, "TOPLEFT", 5, yOffset)
        self.assignmentLines[i]:SetPoint("TOPRIGHT", self.contentFrame, "TOPRIGHT", -5, yOffset)
        self.assignmentLines[i]:SetText(line)
        self.assignmentLines[i]:SetJustifyH("LEFT")
        self.assignmentLines[i]:Show()
        
        -- Update offset for next line
        yOffset = yOffset - 16
    end
    
    -- Update content height
    self.contentFrame:SetHeight(math.abs(yOffset) + 10)
    
    -- Display section warnings
    for i = 1, table.getn(sectionData) do
        if sectionData[i][2] == "Warning" then
            local warningText = sectionData[i][3]
            if warningText and warningText ~= "" then
                local lineIndex = table.getn(self.assignmentLines) + 1
                
                -- Create text element if needed
                if not self.assignmentLines[lineIndex] then
                    self.assignmentLines[lineIndex] = self.contentFrame:CreateFontString(
                        nil, "OVERLAY", "GameFontNormal")
                end
                
                -- Add some spacing before warnings
                yOffset = yOffset - 8
                
                -- Display warning
                self.assignmentLines[lineIndex]:SetPoint("TOPLEFT", self.contentFrame, "TOPLEFT", 5, yOffset)
                self.assignmentLines[lineIndex]:SetPoint("TOPRIGHT", self.contentFrame, "TOPRIGHT", -5, yOffset)
                self.assignmentLines[lineIndex]:SetText("|cFFFF0000WARNING:|r " .. warningText)
                self.assignmentLines[lineIndex]:SetJustifyH("LEFT")
                self.assignmentLines[lineIndex]:Show()
                
                -- Update offset for next line
                yOffset = yOffset - 20
                
                -- Update content height again
                self.contentFrame:SetHeight(math.abs(yOffset) + 10)
            end
        end
    end
end

-- NEW: Update OSD content without necessarily showing the frame
function TWRA:UpdateOSDContent(sectionName, currentIndex, totalSections)
    if not sectionName then return end
    
    self:Debug("osd", "Updating OSD content for section: " .. sectionName)
    
    -- Ensure OSD frame exists
    if not self.osdFrame then
        self:CreateOSDFrame()
    end
    
    -- Update title and footer
    self.osdTitle:SetText(sectionName)
    self.osdFooter:SetText("Section " .. currentIndex .. " of " .. totalSections)
    
    -- Update player-specific assignments
    self:DisplayAssignments(sectionName)
    
    -- Store current content info for later use
    self.OSD.currentSection = {
        name = sectionName,
        index = currentIndex,
        total = totalSections
    }
    
    -- Save this info to persistent storage to restore after reload
    TWRA_SavedVariables.options.osd = TWRA_SavedVariables.options.osd or {}
    TWRA_SavedVariables.options.osd.lastSection = {
        name = sectionName,
        index = currentIndex,
        total = totalSections
    }
    
    -- If OSD is currently visible due to manual toggle, do NOT reset the hide timer
    -- This allows manually toggled OSD to stay visible until manually hidden
    if self.osdFrame:IsShown() and not self.manuallyToggled then
        -- Reset hide timer to give user time to read the new content
        if self.hideTimer then
            self:CancelTimer(self.hideTimer)
        end
        
        local duration = self.OSD.duration or 2
        self.hideTimer = self:ScheduleTimer(function()
            -- Only auto-hide if not manually toggled
            if self.osdFrame and not self.manuallyToggled then
                self.osdFrame:Hide()
            end
        end, duration)
        
        self:Debug("osd", "OSD was visible, updated content and reset timer")
    end
end

-- Show OSD with player-relevant information
function TWRA:ShowOSD(sectionName, currentIndex, totalSections, keepOpen)
    -- If no section provided, try to use current section
    if not sectionName then
        -- Try to get values from current navigation
        if self.navigation and self.navigation.currentIndex and self.navigation.handlers then
            currentIndex = self.navigation.currentIndex
            if currentIndex <= table.getn(self.navigation.handlers) then
                sectionName = self.navigation.handlers[currentIndex]
                totalSections = table.getn(self.navigation.handlers)
            end
        end
        
        -- If still no section name, try from stored values
        if not sectionName and self.OSD and self.OSD.currentSection then
            sectionName = self.OSD.currentSection.name
            currentIndex = self.OSD.currentSection.index
            totalSections = self.OSD.currentSection.total
        end
        
        -- Last resort - try from saved variables
        if not sectionName and TWRA_SavedVariables.options.osd and 
           TWRA_SavedVariables.options.osd.lastSection then
            local lastSection = TWRA_SavedVariables.options.osd.lastSection
            sectionName = lastSection.name
            currentIndex = lastSection.index  
            totalSections = lastSection.total
        end
        
        -- If we still don't have a section, we can't proceed
        if not sectionName then
            self:Debug("osd", "No section to display")
            return
        end
    end
    
    self:Debug("osd", "Showing OSD for section: " .. sectionName)
    
    -- Ensure OSD frame exists
    if not self.osdFrame then
        self:CreateOSDFrame()
    end
    
    -- Update the content first
    self:UpdateOSDContent(sectionName, currentIndex, totalSections)
    
    -- Mark if this should remain open (from manual toggle)
    if keepOpen then
        self.manuallyToggled = true
    else
        self.manuallyToggled = false
    end
    
    -- Only show and set timer if not already visible
    if not self.osdFrame:IsShown() then
        -- Show the OSD
        self.osdFrame:Show()
        
        -- Only set auto-hide timer if not manually toggled
        if not self.manuallyToggled then
            -- Set timer to hide
            if self.hideTimer then
                self:CancelTimer(self.hideTimer)
            end
            
            local duration = self.OSD.duration or 2
            self.hideTimer = self:ScheduleTimer(function()
                if self.osdFrame and not self.manuallyToggled then
                    self.osdFrame:Hide()
                end
            end, duration)
        end
    end
end

-- Test the OSD with current data
function TWRA:TestOSD()
    if not self.navigation or not self.navigation.handlers or table.getn(self.navigation.handlers) == 0 then
        -- Create simple test data if no real data exists
        self:ShowOSD("Test Section", 1, 1)
        self:Debug("osd", "Showing test OSD (no real data available)")
        return
    end
    
    -- Use current section
    local currentIndex = self.navigation.currentIndex or 1
    if currentIndex > table.getn(self.navigation.handlers) then
        currentIndex = 1
    end
    
    local sectionName = self.navigation.handlers[currentIndex]
    local totalSections = table.getn(self.navigation.handlers)
    
    -- Display OSD with current section - show regardless of enabled state
    self:ShowOSD(sectionName, currentIndex, totalSections)
end

-- Toggle OSD visibility manually
function TWRA:ToggleOSD()
    if not self.osdFrame then
        self:CreateOSDFrame()
    end
    
    if self.osdFrame:IsShown() and self.manuallyToggled then
        -- Only manually hide if it was manually shown
        self.osdFrame:Hide()
        self.manuallyToggled = false
        
        -- Cancel hide timer
        if self.hideTimer then
            self:CancelTimer(self.hideTimer)
            self.hideTimer = nil
        end
        
        self:Debug("osd", "OSD manually hidden")
    else
        -- Show the OSD with current section data and keep it open
        -- First priority: Navigation's current section
        if self.navigation and self.navigation.currentIndex and 
           self.navigation.handlers and table.getn(self.navigation.handlers) > 0 then
           
            local currentIndex = self.navigation.currentIndex
            local sectionName = self.navigation.handlers[currentIndex] 
            local totalSections = table.getn(self.navigation.handlers)
            
            self:ShowOSD(sectionName, currentIndex, totalSections, true)
            self:Debug("osd", "OSD manually shown with current navigation data (keeping open)")
        -- Second priority: Stored section data
        elseif self.OSD.currentSection then
            self:ShowOSD(self.OSD.currentSection.name, 
                        self.OSD.currentSection.index, 
                        self.OSD.currentSection.total,
                        true)
            self:Debug("osd", "OSD manually shown with stored section data (keeping open)")
        -- Last resort: Test data
        else
            -- Call TestOSD but mark it to stay open
            self.manuallyToggled = true
            self:TestOSD()
            self:Debug("osd", "OSD manually shown with test data (keeping open)")
        end
    end
end

-- Reset OSD position to default
function TWRA:ResetOSDPosition()
    if not self.osdFrame then return end
    
    -- Reset position
    self.osdFrame:ClearAllPoints()
    self.osdFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
    
    -- Save new position
    self.OSD.point = "CENTER"
    self.OSD.xOffset = 0
    self.OSD.yOffset = 100
    
    -- Update saved variables
    TWRA_SavedVariables.options.osd.point = "CENTER"
    TWRA_SavedVariables.options.osd.xOffset = 0
    TWRA_SavedVariables.options.osd.yOffset = 100
    
    -- Show OSD to demonstrate new position
    self:TestOSD()
end

-- Update OSD settings
function TWRA:UpdateOSDSettings()
    if not self.osdFrame or not self.OSD then return end
    
    -- Update scale
    self.osdFrame:SetScale(self.OSD.scale or 1.0)
    
    -- Update locked state
    if self.OSD.locked then
        self.osdFrame:SetMovable(false)
        self.osdFrame:EnableMouse(false)
        self.osdFrame:RegisterForDrag()
        self.osdFrame:SetScript("OnDragStart", nil)
        self.osdFrame:SetScript("OnDragStop", nil)
    else
        self.osdFrame:SetMovable(true)
        self.osdFrame:EnableMouse(true)
        self.osdFrame:RegisterForDrag("LeftButton")
        self.osdFrame:SetScript("OnDragStart", function()
            this:StartMoving()
        end)
        self.osdFrame:SetScript("OnDragStop", function()
            this:StopMovingOrSizing()
            -- Save position
            local point, _, _, xOffset, yOffset = this:GetPoint()
            TWRA.OSD.point = point
            TWRA.OSD.xOffset = xOffset
            TWRA.OSD.yOffset = yOffset
            
            -- Update saved variables - ensure options path exists
            if not TWRA_SavedVariables.options then TWRA_SavedVariables.options = {} end
            if not TWRA_SavedVariables.options.osd then TWRA_SavedVariables.options.osd = {} end
            TWRA_SavedVariables.options.osd.point = point
            TWRA_SavedVariables.options.osd.xOffset = xOffset
            TWRA_SavedVariables.options.osd.yOffset = yOffset
        end)
    end
    
    -- Save all current settings to ensure consistency
    if not TWRA_SavedVariables.options then TWRA_SavedVariables.options = {} end
    if not TWRA_SavedVariables.options.osd then TWRA_SavedVariables.options.osd = {} end
    
    TWRA_SavedVariables.options.osd = {
        point = self.OSD.point or "CENTER",
        xOffset = self.OSD.xOffset or 0,
        yOffset = self.OSD.yOffset or 100,
        scale = self.OSD.scale or 1.0,
        duration = self.OSD.duration or 2,
        locked = self.OSD.locked,          -- Store as boolean
        enabled = self.OSD.enabled,        -- Store as boolean
        showOnNavigation = self.OSD.showOnNavigation  -- Store as boolean
    }
    
    -- Debug message about settings
    self:Debug("osd", "OSD settings updated and saved")
end
