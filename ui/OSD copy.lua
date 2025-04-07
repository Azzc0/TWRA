-- TWRA On-Screen Display (OSD) module
TWRA = TWRA or {}

-- Initialize OSD settings
TWRA.OSD = {
    enabled = true,           -- OSD enabled by default
    showOnNavigation = true,  -- Show OSD on section changes
    locked = false,           -- OSD position unlocked by default
    frame = nil,              -- Will hold the OSD frame
    point = "CENTER",         -- Default anchor point
    xOffset = 0,              -- X offset from anchor
    yOffset = 100,            -- Y offset from anchor (higher up on screen)
    scale = 1.0,              -- Default OSD scale
    duration = 2,             -- How long to show the OSD (seconds)
    hideTimer = nil,          -- Timer for auto-hiding
    lastSection = nil,        -- Last section displayed
    isVisible = false         -- Tracking visibility state
}

-- Initialize the OSD system
function TWRA:InitOSD()
    self:Debug("osd", "Initializing OSD system")
    
    -- Load saved settings
    if TWRA_SavedVariables and TWRA_SavedVariables.options and TWRA_SavedVariables.options.osd then
        local saved = TWRA_SavedVariables.options.osd
        
        -- Apply saved settings with default fallbacks
        self.OSD.enabled = saved.enabled ~= nil and saved.enabled or true
        self.OSD.showOnNavigation = saved.showOnNavigation ~= nil and saved.showOnNavigation or true
        self.OSD.locked = saved.locked ~= nil and saved.locked or false
        self.OSD.point = saved.point or "CENTER"
        self.OSD.xOffset = saved.xOffset or 0
        self.OSD.yOffset = saved.yOffset or 100
        self.OSD.scale = saved.scale or 1.0
        self.OSD.duration = saved.duration or 2
    end
    
    -- Register for section change messages
    self:RegisterMessageHandler("SECTION_CHANGED", function(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
        self:OnSectionChanged(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
    end)
    
    self:Debug("osd", "OSD initialized with settings: Enabled=" .. tostring(self.OSD.enabled) .. 
               ", ShowOnNav=" .. tostring(self.OSD.showOnNavigation))
    
    return true
end

-- Create or get the OSD frame
function TWRA:GetOSDFrame()
    -- Return existing frame if it's already created
    if self.OSD.frame then 
        return self.OSD.frame 
    end
    
    self:Debug("osd", "Creating OSD frame")
    
    -- Create the main frame
    local frame = CreateFrame("Frame", "TWRAOSDFrame", UIParent)
    frame:SetWidth(500)
    frame:SetHeight(100) -- Initial height, will be adjusted dynamically
    frame:SetPoint(self.OSD.point, UIParent, self.OSD.point, self.OSD.xOffset, self.OSD.yOffset)
    frame:SetScale(self.OSD.scale or 1.0)
    frame:SetFrameStrata("HIGH")
    
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
    
    -- Create layout containers for better organization
    -- Header container (for title)
    local headerContainer = CreateFrame("Frame", nil, frame)
    headerContainer:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    headerContainer:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    headerContainer:SetHeight(40)
    frame.headerContainer = headerContainer
    
    -- Content container (for assignments, notes, warnings)
    local contentContainer = CreateFrame("Frame", nil, frame)
    contentContainer:SetPoint("TOPLEFT", headerContainer, "BOTTOMLEFT", 0, 0)
    contentContainer:SetPoint("TOPRIGHT", headerContainer, "BOTTOMRIGHT", 0, 0)
    contentContainer:SetHeight(40) -- Initial height, will grow as needed
    frame.contentContainer = contentContainer
    
    -- Footer container (for section count and nav indicators)
    local footerContainer = CreateFrame("Frame", nil, frame)
    footerContainer:SetHeight(20) -- Reduced from 30 to 20 (less padding)
    footerContainer:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    footerContainer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    frame.footerContainer = footerContainer
    
    -- Remove the footer background - deleted this code:
    -- local footerBg = footerContainer:CreateTexture(nil, "BACKGROUND")
    -- footerBg:SetAllPoints()
    -- footerBg:SetTexture(0.15, 0.15, 0.15, 0.7) -- Slightly darker than main background
    -- frame.footerBg = footerBg
    
    -- Create title text (section name)
    local title = headerContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", headerContainer, "TOP", 0, -10)
    title:SetTextColor(1, 0.82, 0)
    title:SetText("Current Section")
    frame.title = title
    
    -- Assignment info container
    local infoContainer = CreateFrame("Frame", nil, contentContainer)
    infoContainer:SetPoint("TOP", contentContainer, "TOP", 0, -5)
    infoContainer:SetWidth(460)
    infoContainer:SetHeight(40)
    frame.infoContainer = infoContainer
    
    -- Create section text (larger font)
    -- local text = infoContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    -- text:SetPoint("TOPLEFT", infoContainer, "TOPLEFT", 15, -5)
    -- text:SetWidth(430)
    -- text:SetJustifyH("LEFT")
    -- text:SetText("No section selected")
    -- frame.text = text
    
    -- Add warning container and icon with colored background
    local warningContainer = CreateFrame("Frame", nil, contentContainer)
    warningContainer:SetHeight(25)
    -- Make warning container use full width of content container
    warningContainer:SetPoint("LEFT", contentContainer, "LEFT", 0, 0)
    warningContainer:SetPoint("RIGHT", contentContainer, "RIGHT", 0, 0)
    warningContainer:SetPoint("TOP", infoContainer, "BOTTOM", 0, -5)
    frame.warningContainer = warningContainer
    
    -- Add semi-transparent red background for warning section
    local warningBg = warningContainer:CreateTexture(nil, "BACKGROUND")
    warningBg:SetAllPoints()
    warningBg:SetTexture(0.8, 0.1, 0.1, 0.15) -- Light red with transparency
    frame.warningBg = warningBg
    
    -- Warning icon, position relative to container's left edge
    local warningIcon = warningContainer:CreateTexture(nil, "OVERLAY")
    warningIcon:SetTexture("Interface\\DialogFrame\\DialogAlertIcon")
    warningIcon:SetWidth(16)
    warningIcon:SetHeight(16)
    warningIcon:SetPoint("LEFT", warningContainer, "LEFT", 15, 0)
    warningIcon:Hide() -- Hide by default
    frame.warningIcon = warningIcon
    
    -- Warning text
    local warningText = warningContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    warningText:SetPoint("LEFT", warningIcon, "RIGHT", 5, 0)
    warningText:SetWidth(440)
    warningText:SetJustifyH("LEFT")
    warningText:SetTextColor(1, 0.6, 0.6) -- Light red color
    frame.warningText = warningText
    
    -- Add note container and icon with colored background
    local noteContainer = CreateFrame("Frame", nil, contentContainer)
    noteContainer:SetHeight(25)
    -- Make note container use full width of content container
    noteContainer:SetPoint("LEFT", contentContainer, "LEFT", 0, 0)
    noteContainer:SetPoint("RIGHT", contentContainer, "RIGHT", 0, 0)
    noteContainer:SetPoint("TOP", warningContainer, "BOTTOM", 0, 0)
    frame.noteContainer = noteContainer
    
    -- Add semi-transparent blue background for note section
    local noteBg = noteContainer:CreateTexture(nil, "BACKGROUND")
    noteBg:SetAllPoints()
    noteBg:SetTexture(0.2, 0.4, 0.8, 0.15) -- Light blue with transparency
    frame.noteBg = noteBg
    
    -- Note icon
    local noteIcon = noteContainer:CreateTexture(nil, "OVERLAY")
    noteIcon:SetTexture("Interface\\TutorialFrame\\TutorialFrame-QuestionMark")
    noteIcon:SetWidth(16)
    noteIcon:SetHeight(16)
    noteIcon:SetPoint("LEFT", noteContainer, "LEFT", 15, 0)
    noteIcon:Hide() -- Hide by default
    frame.noteIcon = noteIcon
    
    -- Note text
    local noteText = noteContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    noteText:SetPoint("LEFT", noteIcon, "RIGHT", 5, 0)
    noteText:SetWidth(440)
    noteText:SetJustifyH("LEFT")
    noteText:SetTextColor(0.8, 0.8, 1) -- Light blue color
    frame.noteText = noteText
    
    -- Section count text (footer)
    local countText = footerContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    countText:SetPoint("CENTER", footerContainer, "CENTER", 0, 0)
    countText:SetTextColor(1, 1, 1)
    countText:SetText("Section 0/0")
    frame.countText = countText
    
    -- Make the frame movable but respect locked status
    frame:SetMovable(true)
    frame:EnableMouse(not self.OSD.locked)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function()
        if not self.OSD.locked then
            this:StartMoving()
        end
    end)
    frame:SetScript("OnDragStop", function()
        this:StopMovingOrSizing()
        -- Save new position
        local point, _, relPoint, xOffset, yOffset = this:GetPoint()
        self.OSD.point = point
        self.OSD.relPoint = relPoint
        self.OSD.xOffset = xOffset
        self.OSD.yOffset = yOffset
        
        -- Save to settings
        if TWRA_SavedVariables and TWRA_SavedVariables.options and TWRA_SavedVariables.options.osd then
            TWRA_SavedVariables.options.osd.point = point
            TWRA_SavedVariables.options.osd.relPoint = relPoint
            TWRA_SavedVariables.options.osd.xOffset = xOffset
            TWRA_SavedVariables.options.osd.yOffset = yOffset
        end
    end)
    
    -- Initialize icons array for possible future use
    frame.assignmentIcons = {}
    
    -- Initial state is hidden
    frame:Hide()
    
    -- Store reference
    self.OSD.frame = frame
    
    self:Debug("osd", "OSD frame created")
    return frame
end

-- Function to toggle OSD visibility
function TWRA:ToggleOSD()
    -- Get or create OSD frame
    local frame = self:GetOSDFrame()
    
    -- Add debug to see if we're reaching this
    self:Debug("osd", "ToggleOSD called, current visibility: " .. tostring(self.OSD.isVisible))
    
    -- Fix reset logic - always reset visibility state based on actual frame visibility
    self.OSD.isVisible = frame:IsShown()
    
    -- Add debug about frame state directly
    self:Debug("osd", "Frame is currently " .. (frame:IsShown() and "shown" or "hidden") .. 
               ", isVisible flag is " .. tostring(self.OSD.isVisible))
    
    -- Toggle visibility
    if self.OSD.isVisible then
        self:Debug("osd", "ToggleOSD: Hiding OSD")
        self:HideOSD()
    else
        self:Debug("osd", "ToggleOSD: Showing OSD permanently")
        -- When called from ToggleOSD, display without auto-hide (no duration parameter)
        self:ShowOSDPermanent()
    end
    
    -- Debug the final state
    self:Debug("osd", "ToggleOSD: After toggle, visibility is: " .. tostring(self.OSD.isVisible))
    
    return self.OSD.isVisible
end

-- Show the OSD permanently (no auto-hide)
function TWRA:ShowOSDPermanent()
    -- Skip if OSD is disabled
    if not self.OSD.enabled then
        self:Debug("osd", "OSD is disabled, not showing")
        return false
    end
    
    -- Get or create OSD frame
    local frame = self:GetOSDFrame()
    
    -- Update content if we have navigation data
    if self.navigation and self.navigation.currentIndex then
        local currentSection = self.navigation.currentIndex
        local totalSections = table.getn(self.navigation.handlers)
        local sectionName = self.navigation.handlers[currentSection]
        
        self:UpdateOSDContent(sectionName, currentSection, totalSections)
    end
    
    -- Ensure the frame is shown regardless of content updates
    -- This was the key issue - frame wasn't being shown explicitly after content updates
    frame:Show()
    
    -- Debug the visibility state to confirm it's shown
    self:Debug("osd", "OSD frame visibility enforced: " .. (frame:IsShown() and "visible" or "still hidden"))
    
    self.OSD.isVisible = true
    
    -- Cancel any pending hide timer
    if self.OSD.hideTimer then
        self:CancelTimer(self.OSD.hideTimer)
        self.OSD.hideTimer = nil
    end
    
    self:Debug("osd", "OSD shown permanently")
    return true
end

-- Show the OSD with optional auto-hide
function TWRA:ShowOSD(duration)
    -- Skip if OSD is disabled
    if not self.OSD.enabled then
        self:Debug("osd", "OSD is disabled, not showing")
        return false
    end
    
    -- Get or create OSD frame
    local frame = self:GetOSDFrame()
    
    -- Update content if we have navigation data
    if self.navigation and self.navigation.currentIndex then
        local currentSection = self.navigation.currentIndex
        local totalSections = table.getn(self.navigation.handlers)
        local sectionName = self.navigation.handlers[currentSection]
        
        self:UpdateOSDContent(sectionName, currentSection, totalSections)
    end
    
    -- Show the frame
    frame:Show()
    self.OSD.isVisible = true
    
    -- Cancel any pending hide timer
    if self.OSD.hideTimer then
        self:CancelTimer(self.OSD.hideTimer)
        self.OSD.hideTimer = nil
    end
    
    -- Set up auto-hide timer if duration specified
    local autohideDuration = duration or self.OSD.duration
    if autohideDuration and autohideDuration > 0 then
        self.OSD.hideTimer = self:ScheduleTimer(function()
            self:HideOSD()
        end, autohideDuration)
        self:Debug("osd", "OSD shown with " .. autohideDuration .. "s duration")
    else
        self:Debug("osd", "OSD shown permanently")
    end
    
    return true
end

-- Hide the OSD
function TWRA:HideOSD()
    -- Skip if no frame or already hidden
    if not self.OSD.frame then return false end
    
    -- Cancel any pending hide timer
    if self.OSD.hideTimer then
        self:CancelTimer(self.OSD.hideTimer)
        self.OSD.hideTimer = nil
    end
    
    -- Hide the frame
    self.OSD.frame:Hide()
    self.OSD.isVisible = false
    
    self:Debug("osd", "OSD hidden")
    return true
end

-- Update OSD content with section information
function TWRA:UpdateOSDContent(sectionName, sectionIndex, totalSections)
    self:Debug("osd", "Updating OSD content for section: " .. (sectionName or "unknown"))
    
    -- Create frame if it doesn't exist
    local frame = self:GetOSDFrame()
    
    -- Update section name in title
    frame.title:SetText(sectionName or "No section selected")
    
    -- Extract section data for processing in OSDContent.lua
    local sectionData = self:FilterAndExtractSectionData(sectionName)
    self:Debug("osd", "Extracted " .. table.getn(sectionData) .. " rows for section data")
    
    -- Initialize assignments namespace if needed
    self.assignments = self.assignments or {}
    
    -- Call the PrepOSD function in OSDContent.lua if available
    if self.PrepOSD then
        self:Debug("osd", "Calling PrepOSD to format assignment information")
        self:PrepOSD(sectionData)
        
        -- Debug the formatted data if it exists
        if self.assignments.osdtable then
            self:DebugFormattedData(self.assignments.osdtable)
            
            -- Update OSD with the formatted data
            self:UpdateOSDWithFormattedData(self.assignments.osdtable)
        else
            self:Debug("osd", "No OSD table found in TWRA.assignments after PrepOSD call")
            
            -- Even if no assignments are found, ensure we create the assignment text field
            if self.UpdateOSDAssignmentLines then
                self:UpdateOSDAssignmentLines({"No specific assignments for you in this section"})
            end
        end
    else
        self:Debug("osd", "PrepOSD function not found in OSDContent.lua - falling back to basic display")
    end
    
    -- Update section counter in footer
    if sectionIndex and totalSections then
        frame.countText:SetText("Section " .. sectionIndex .. " / " .. totalSections)
    else
        frame.countText:SetText("")
    end
    
    -- Store last section
    self.OSD.lastSection = sectionName
    
    return true
end

-- Helper function to debug the formatted data from PrepOSD
function TWRA:DebugFormattedData(formattedData)
    if not formattedData or type(formattedData) ~= "table" or table.getn(formattedData) == 0 then
        self:Debug("osd", "No formatted data available to debug")
        return
    end
    
    self:Debug("osd", "Formatted assignment data (" .. table.getn(formattedData) .. " rows):")
    
    -- Debug each row in the formatted data
    for i, row in ipairs(formattedData) do
        local tanks = (row.Tank1 or "none") .. "/" .. (row.Tank2 or "none") .. "/" .. (row.Tank3 or "none")
        local target = row.Target or "unknown"
        local icon = row.RaidIcon or "none"
        local role = row.RoleCleartext or "unknown"
        local position = row.position or "unknown"
        
        self:Debug("osd", string.format("Row %d: Position=%s, Target=%s, Icon=%s, Role=%s, Tanks=%s", 
            i, position, target, icon, role, tanks))
    end
end

-- Function to update OSD display with the formatted data from PrepOSD
function TWRA:UpdateOSDWithFormattedData(formattedData)
    -- Skip if no formatted data is provided
    if not formattedData or type(formattedData) ~= "table" or table.getn(formattedData) == 0 then
        self:Debug("osd", "No formatted data available to display")
        return self:UpdateOSDAssignmentLines({"No specific assignments for you in this section"})
    end
    
    -- Create or get OSD frame
    local frame = self:GetOSDFrame()
    
    -- Clear any existing assignment content
    if frame.assignmentRows then
        for _, row in ipairs(frame.assignmentRows) do
            row:Hide()
        end
    end
    
    -- Initialize rows array if it doesn't exist
    frame.assignmentRows = frame.assignmentRows or {}
    
    -- Container for assignment rows (replaces assignmentText)
    if not frame.assignmentContainer then
        frame.assignmentContainer = CreateFrame("Frame", nil, frame.contentContainer)
        frame.assignmentContainer:SetPoint("TOPLEFT", frame.infoContainer, "BOTTOMLEFT", 15, -5)
        frame.assignmentContainer:SetPoint("TOPRIGHT", frame.infoContainer, "BOTTOMRIGHT", -15, -5)
        frame.assignmentContainer:SetHeight(10) -- Initial height, will be adjusted
    end
    
    -- Reset container height
    frame.assignmentContainer:SetHeight(10)
    
    -- Track the total height we'll need
    local totalHeight = 0
    local rowHeight = 16 -- Height for each assignment row
    local rowPadding = 2 -- Padding between rows
    
    -- Add header row
    if not frame.headerRow then
        frame.headerRow = frame.assignmentContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        frame.headerRow:SetPoint("TOPLEFT", frame.assignmentContainer, "TOPLEFT", 0, 0)
        frame.headerRow:SetWidth(frame.assignmentContainer:GetWidth())
        frame.headerRow:SetJustifyH("LEFT")
    end
    
    frame.headerRow:SetText("|cFFFFCC00Your Assignments:|r")
    frame.headerRow:Show()
    
    -- Update y position after header
    totalHeight = totalHeight + rowHeight + rowPadding
    
    -- Create and update each assignment row
    for i, entry in ipairs(formattedData) do
        -- Create row if it doesn't exist
        if not frame.assignmentRows[i] then
            frame.assignmentRows[i] = frame.assignmentContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            frame.assignmentRows[i]:SetWidth(frame.assignmentContainer:GetWidth())
            frame.assignmentRows[i]:SetJustifyH("LEFT")
        end
        
        -- Position row
        frame.assignmentRows[i]:SetPoint("TOPLEFT", frame.assignmentContainer, "TOPLEFT", 0, -totalHeight)
        
        -- Format display string
        local displayString = entry.displayString or ""
        
        -- Replace icon identifiers with actual textures
        if self.ICON_INDICES then
            for iconName, iconIndex in pairs(self.ICON_INDICES) do
                local iconTag = "[" .. iconName .. "]"
                if string.find(displayString, iconTag) then
                    local iconTexture = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_" .. 
                                      iconIndex .. ":14:14:0:0|t"
                    displayString = string.gsub(displayString, iconTag, iconTexture)
                end
            end
        end
        
        -- Apply role-specific coloring
        if entry.roleType == "tank" then
            displayString = "|cFF8888FF" .. displayString .. "|r"  -- Blue for tanks
        elseif entry.roleType == "healer" then
            displayString = "|cFF88FF88" .. displayString .. "|r"  -- Green for healers
        else
            displayString = "|cFFFFAA33" .. displayString .. "|r"  -- Orange for DPS and other roles
        end
        
        -- Set the row text and show it
        frame.assignmentRows[i]:SetText(displayString)
        frame.assignmentRows[i]:Show()
        
        -- Update total height
        totalHeight = totalHeight + rowHeight + rowPadding
    end
    
    -- Add warnings if any
    local warningsStartIndex = table.getn(formattedData) + 1
    if self.assignments.warnings and table.getn(self.assignments.warnings) > 0 then
        -- Add spacer before warnings
        totalHeight = totalHeight + rowPadding
        
        for i, warning in ipairs(self.assignments.warnings) do
            local rowIndex = warningsStartIndex + i - 1
            
            -- Create row if it doesn't exist
            if not frame.assignmentRows[rowIndex] then
                frame.assignmentRows[rowIndex] = frame.assignmentContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                frame.assignmentRows[rowIndex]:SetWidth(frame.assignmentContainer:GetWidth())
                frame.assignmentRows[rowIndex]:SetJustifyH("LEFT")
            end
            
            -- Position row
            frame.assignmentRows[rowIndex]:SetPoint("TOPLEFT", frame.assignmentContainer, "TOPLEFT", 0, -totalHeight)
            
            -- Set warning text with red color
            frame.assignmentRows[rowIndex]:SetText("|cFFFF5555Warning:|r " .. warning)
            frame.assignmentRows[rowIndex]:Show()
            
            -- Update total height
            totalHeight = totalHeight + rowHeight + rowPadding
        end
    end
    
    -- Add notes if any
    local notesStartIndex = warningsStartIndex + table.getn(self.assignments.warnings or {})
    if self.assignments.notes and table.getn(self.assignments.notes) > 0 then
        -- Add spacer before notes
        totalHeight = totalHeight + rowPadding
        
        for i, note in ipairs(self.assignments.notes) do
            local rowIndex = notesStartIndex + i - 1
            
            -- Create row if it doesn't exist
            if not frame.assignmentRows[rowIndex] then
                frame.assignmentRows[rowIndex] = frame.assignmentContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                frame.assignmentRows[rowIndex]:SetWidth(frame.assignmentContainer:GetWidth())
                frame.assignmentRows[rowIndex]:SetJustifyH("LEFT")
            end
            
            -- Position row
            frame.assignmentRows[rowIndex]:SetPoint("TOPLEFT", frame.assignmentContainer, "TOPLEFT", 0, -totalHeight)
            
            -- Set note text with blue color
            frame.assignmentRows[rowIndex]:SetText("|cFF5555FFNote:|r " .. note)
            frame.assignmentRows[rowIndex]:Show()
            
            -- Update total height
            totalHeight = totalHeight + rowHeight + rowPadding
        end
    end
    
    -- Update container height
    frame.assignmentContainer:SetHeight(totalHeight)
    
    -- Hide any unused rows
    local totalRowsNeeded = table.getn(formattedData) + 
                           table.getn(self.assignments.warnings or {}) + 
                           table.getn(self.assignments.notes or {})
    
    for i = totalRowsNeeded + 1, table.getn(frame.assignmentRows) do
        frame.assignmentRows[i]:Hide()
    end
    
    -- Hide the old warning and note containers
    if frame.warningContainer then
        frame.warningContainer:Hide()
        if frame.warningBg then frame.warningBg:Hide() end
        if frame.warningIcon then frame.warningIcon:Hide() end
    end
    
    if frame.noteContainer then
        frame.noteContainer:Hide()
        if frame.noteBg then frame.noteBg:Hide() end
        if frame.noteIcon then frame.noteIcon:Hide() end
    end
    
    -- Calculate additional content height for assignment container
    local contentHeight = frame.infoContainer:GetHeight() + totalHeight + 10 -- Add some padding
    
    -- Update content container height
    frame.contentContainer:SetHeight(contentHeight)
    
    -- Calculate total frame height
    local totalFrameHeight = 40 + contentHeight + 20 + 10 -- Header + Content + Footer + Padding
    
    -- Set minimum height if content is very small
    if totalFrameHeight < 100 then 
        totalFrameHeight = 100
    end
    
    -- Update frame height
    frame:SetHeight(totalFrameHeight)
    
    -- Make sure the frame is actually shown
    frame:Show()
    self.OSD.isVisible = true
    
    -- Update footer position to always be at the bottom
    frame.footerContainer:ClearAllPoints()
    frame.footerContainer:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    frame.footerContainer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    
    self:Debug("osd", "Updated OSD with " .. table.getn(formattedData) .. " assignment rows")
    return true
end

-- Backwards compatibility function for plugins that might still use UpdateOSDAssignmentLines
function TWRA:UpdateOSDAssignmentLines(lines)
    -- Check if OSD frame exists
    if not self.OSD or not self.OSD.frame then
        self:Debug("osd", "OSD frame not available")
        return false
    end
    
    -- Create or get the frame
    local frame = self.OSD.frame
    
    -- If we already have the container system set up, use that
    if frame.assignmentContainer then
        -- Clear any existing assignment rows
        if frame.assignmentRows then
            for _, row in ipairs(frame.assignmentRows) do
                row:Hide()
            end
        end
        
        -- Initialize rows array if it doesn't exist
        frame.assignmentRows = frame.assignmentRows or {}
        
        -- Reset container height
        frame.assignmentContainer:SetHeight(10)
        
        -- Track the total height we'll need
        local totalHeight = 0
        local rowHeight = 16 -- Height for each assignment row
        local rowPadding = 2 -- Padding between rows
        
        -- Process each line
        for i, lineText in ipairs(lines) do
            -- Create row if it doesn't exist
            if not frame.assignmentRows[i] then
                frame.assignmentRows[i] = frame.assignmentContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                frame.assignmentRows[i]:SetWidth(frame.assignmentContainer:GetWidth())
                frame.assignmentRows[i]:SetJustifyH("LEFT")
            end
            
            -- Position row
            frame.assignmentRows[i]:SetPoint("TOPLEFT", frame.assignmentContainer, "TOPLEFT", 0, -totalHeight)
            
            -- Set the row text and show it
            frame.assignmentRows[i]:SetText(lineText)
            frame.assignmentRows[i]:Show()
            
            -- Update total height
            totalHeight = totalHeight + rowHeight + rowPadding
        end
        
        -- Update container height
        frame.assignmentContainer:SetHeight(totalHeight)
        
        -- Hide any unused rows
        for i = table.getn(lines) + 1, table.getn(frame.assignmentRows) do
            frame.assignmentRows[i]:Hide()
        end
        
        -- Calculate content height
        local contentHeight = frame.infoContainer:GetHeight() + totalHeight + 10 -- Add some padding
        
        -- Update content container height
        frame.contentContainer:SetHeight(contentHeight)
        
        -- Calculate total frame height
        local totalFrameHeight = 40 + contentHeight + 20 + 10 -- Header + Content + Footer + Padding
        
        -- Set minimum height
        if totalFrameHeight < 100 then 
            totalFrameHeight = 100
        end
        
        -- Update frame height
        frame:SetHeight(totalFrameHeight)
    else
        -- Legacy path: use single text field
        -- Create assignment text field if it doesn't exist
        if not frame.assignmentText then
            self:Debug("osd", "Creating new assignment text field")
            frame.assignmentText = frame.contentContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            frame.assignmentText:SetPoint("TOPLEFT", frame.infoContainer, "BOTTOMLEFT", 15, -5)
            frame.assignmentText:SetWidth(frame.contentContainer:GetWidth() - 30)
            frame.assignmentText:SetJustifyH("LEFT")
            
            -- Add reference for easier access
            self.OSD.assignmentText = frame.assignmentText
        end
        
        -- Format lines into text
        local assignmentText = ""
        if lines and table.getn(lines) > 0 then
            assignmentText = table.concat(lines, "\n")
        else
            assignmentText = "No assignments available"
        end
        
        frame.assignmentText:SetText(assignmentText)
        frame.assignmentText:Show()
        
        -- Calculate height for text
        local textHeight = 0
        for _ in string.gmatch(assignmentText, "\n") do
            textHeight = textHeight + 15
        end
        
        -- Add base height for first line
        if assignmentText ~= "" then
            textHeight = textHeight + 20
        end
        
        -- Adjust content height
        local contentHeight = frame.infoContainer:GetHeight() + textHeight + 10 -- Add padding
        frame.contentContainer:SetHeight(contentHeight)
        
        -- Calculate total frame height
        local totalFrameHeight = 40 + contentHeight + 20 + 10 -- Header + Content + Footer + Padding
        if totalFrameHeight < 100 then 
            totalFrameHeight = 100
        end
        frame:SetHeight(totalFrameHeight)
    end
    
    -- Hide the old warning and note containers
    if frame.warningContainer then
        frame.warningContainer:Hide()
        if frame.warningBg then frame.warningBg:Hide() end
        if frame.warningIcon then frame.warningIcon:Hide() end
    end
    
    if frame.noteContainer then
        frame.noteContainer:Hide()
        if frame.noteBg then frame.noteBg:Hide() end
        if frame.noteIcon then frame.noteIcon:Hide() end
    end
    
    -- Make sure the frame is actually shown
    frame:Show()
    self.OSD.isVisible = true
    
    -- Update footer position to always be at the bottom
    frame.footerContainer:ClearAllPoints()
    frame.footerContainer:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    frame.footerContainer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    
    self:Debug("osd", "OSD assignment text updated with " .. table.getn(lines) .. " lines")
    return true
end

-- Handler for section change events
function TWRA:OnSectionChanged(sectionName, sectionIndex, totalSections, context)
    -- Always update content whether the OSD is visible or not
    self:UpdateOSDContent(sectionName, sectionIndex, totalSections)
    
    -- Skip showing the OSD if it's disabled or showOnNavigation is disabled
    if not self.OSD.enabled or not self.OSD.showOnNavigation then 
        self:Debug("osd", "OSD not shown (enabled=" .. tostring(self.OSD.enabled) .. 
                   ", showOnNav=" .. tostring(self.OSD.showOnNavigation) .. ")")
        return
    end
    
    -- Context contains additional information about the change
    local isMainFrameVisible = false
    local inOptionsView = false
    
    -- Extract context information if available
    if context then
        isMainFrameVisible = context.isMainFrameVisible or false
        inOptionsView = context.inOptionsView or false
    else
        -- If no context provided, determine it from current state
        isMainFrameVisible = (self.mainFrame and self.mainFrame:IsShown()) or false
        inOptionsView = (self.currentView == "options") or false
    end
    
    -- Show OSD with timer when in options view or main frame is hidden
    if not isMainFrameVisible or inOptionsView then
        -- When showing automatically on navigation, use the configured auto-hide duration
        self:ShowOSD(self.OSD.duration)
        self:Debug("osd", "OSD shown on section change (" .. 
                   (not isMainFrameVisible and "main frame hidden" or "in options view") .. ")")
    end
end

-- Function to update OSD settings
function TWRA:UpdateOSDSettings()
    -- Skip if no frame
    if not self.OSD.frame then return false end
    
    -- Update position
    self.OSD.frame:ClearAllPoints()
    self.OSD.frame:SetPoint(self.OSD.point, UIParent, self.OSD.point, self.OSD.xOffset, self.OSD.yOffset)
    
    -- Update scale
    self.OSD.frame:SetScale(self.OSD.scale or 1.0)
    
    -- Update movability based on locked state
    self.OSD.frame:EnableMouse(not self.OSD.locked)
    
    -- Apply current content
    if self.navigation and self.navigation.currentIndex and self.navigation.handlers then
        local currentSection = self.navigation.currentIndex
        local sectionName = self.navigation.handlers[currentSection]
        local totalSections = table.getn(self.navigation.handlers)
        self:UpdateOSDContent(sectionName, currentSection, totalSections)
    end
    
    self:Debug("osd", "OSD settings updated")
    return true
end

-- Toggle OSD enabled state
function TWRA:ToggleOSDEnabled(state)
    if state ~= nil then
        self.OSD.enabled = state
    else
        self.OSD.enabled = not self.OSD.enabled
    end
    
    -- Save to settings
    if not TWRA_SavedVariables then TWRA_SavedVariables = {} end
    if not TWRA_SavedVariables.options then TWRA_SavedVariables.options = {} end
    if not TWRA_SavedVariables.options.osd then TWRA_SavedVariables.options.osd = {} end
    TWRA_SavedVariables.options.osd.enabled = self.OSD.enabled
    
    -- Hide OSD if disabling
    if not self.OSD.enabled and self.OSD.isVisible then
        self:HideOSD()
    end
    
    self:Debug("osd", "OSD " .. (self.OSD.enabled and "enabled" or "disabled"))
    return self.OSD.enabled
end

-- Toggle OSD on navigation setting
function TWRA:ToggleOSDOnNavigation(state)
    if state ~= nil then
        self.OSD.showOnNavigation = state
    else
        self.OSD.showOnNavigation = not self.OSD.showOnNavigation
    end
    
    -- Save to settings
    if not TWRA_SavedVariables then TWRA_SavedVariables = {} end
    if not TWRA_SavedVariables.options then TWRA_SavedVariables.options = {} end
    if not TWRA_SavedVariables.options.osd then TWRA_SavedVariables.options.osd = {} end
    TWRA_SavedVariables.options.osd.showOnNavigation = self.OSD.showOnNavigation
    
    self:Debug("osd", "OSD on navigation " .. (self.OSD.showOnNavigation and "enabled" or "disabled"))
    return self.OSD.showOnNavigation
end

-- Reset OSD position to default
function TWRA:ResetOSDPosition()
    -- Default position values
    self.OSD.point = "CENTER"
    self.OSD.relPoint = "CENTER"
    self.OSD.xOffset = 0
    self.OSD.yOffset = 100
    
    -- Save to settings
    if TWRA_SavedVariables and TWRA_SavedVariables.options and TWRA_SavedVariables.options.osd then
        TWRA_SavedVariables.options.osd.point = self.OSD.point
        TWRA_SavedVariables.options.osd.relPoint = self.OSD.relPoint
        TWRA_SavedVariables.options.osd.xOffset = self.OSD.xOffset
        TWRA_SavedVariables.options.osd.yOffset = self.OSD.yOffset
    end
    
    -- Update frame if it exists
    if self.OSD.frame then
        self.OSD.frame:ClearAllPoints()
        self.OSD.frame:SetPoint(self.OSD.point, UIParent, self.OSD.point, self.OSD.xOffset, self.OSD.yOffset)
    end
    
    self:Debug("osd", "OSD position reset to default")
    return true
end

-- Test OSD by showing current section
function TWRA:TestOSD()
    -- Create frame if it doesn't exist
    local frame = self:GetOSDFrame()
    
    -- Get current section if available
    local sectionName = "Test Section"
    local sectionIndex = nil
    local totalSections = nil
    
    if self.navigation and self.navigation.currentIndex and self.navigation.handlers then
        sectionIndex = self.navigation.currentIndex
        totalSections = table.getn(self.navigation.handlers)
        sectionName = self.navigation.handlers[sectionIndex]
    end
    
    -- Update OSD content
    self:UpdateOSDContent(sectionName, sectionIndex, totalSections)
    
    -- Show OSD with double the normal duration
    local testDuration = self.OSD.duration * 2
    self:ShowOSD(testDuration)
    
    self:Debug("osd", "Testing OSD with section: " .. sectionName .. " for " .. testDuration .. "s")
    return true
end

-- Function to display section name in overlay
function TWRA:ShowSectionNameOverlay(sectionName, sectionIndex, totalSections)
    -- Always update content regardless of visibility state
    self:UpdateOSDContent(sectionName, sectionIndex, totalSections)
    
    -- Skip showing if OSD is disabled or showOnNavigation is disabled
    if not self.OSD.enabled or not self.OSD.showOnNavigation then
        return false
    end
    
    -- Only show if the main frame isn't visible or we're in options view
    local mainFrameVisible = self.mainFrame and self.mainFrame:IsShown()
    local inOptionsView = self.currentView == "options"
    
    if not mainFrameVisible or inOptionsView then
        -- When showing automatically on navigation, use the configured auto-hide duration
        self:ShowOSD(self.OSD.duration)
    end
    
    return true
end

-- Filter and extract section data for OSD display
function TWRA:FilterAndExtractSectionData(sectionName)
    self:Debug("osd", "FilterAndExtractSectionData called for section: " .. (sectionName or "unknown"))
    
    -- Safety checks
    if not self.fullData then
        self:Debug("osd", "ERROR: No data available to extract")
        return {}
    end
    
    if not sectionName or sectionName == "" then
        self:Debug("osd", "ERROR: Invalid section name")
        return {}
    end
    
    -- Find and extract all rows for this section
    local sectionData = {}
    
    -- Add all rows for this section
    for i = 1, table.getn(self.fullData) do
        local row = self.fullData[i]
        if row[1] == sectionName then
            -- Add this row to our section data
            table.insert(sectionData, row)
        end
    end
    
    self:Debug("osd", "Extracted " .. table.getn(sectionData) .. " rows for section: " .. sectionName)
    return sectionData
end

-- Refresh OSD content regardless of visibility
function TWRA:RefreshOSDContent()
    -- Skip if OSD is disabled completely
    if not self.OSD.enabled then
        self:Debug("osd", "OSD is disabled, not refreshing content")
        return false
    end
    
    -- Make sure we have navigation data
    if not self.navigation or not self.navigation.currentIndex or not self.navigation.handlers then
        self:Debug("osd", "Cannot refresh OSD content - navigation data unavailable")
        return false
    end
    
    -- Get current section info
    local currentSection = self.navigation.currentIndex
    local totalSections = table.getn(self.navigation.handlers)
    local sectionName = self.navigation.handlers[currentSection]
    
    self:Debug("osd", "RefreshOSDContent for: " .. (sectionName or "unknown"))
    
    -- ALWAYS update OSD content even if not visible
    self:UpdateOSDContent(sectionName, currentSection, totalSections)
    
    -- Also update visibility state to match frame's actual state
    if self.OSD.frame then
        self.OSD.isVisible = self.OSD.frame:IsShown()
    end
    
    return true
end