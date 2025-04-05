-- TWRA On-Screen Display Module
-- Handles all OSD-related functionality including section navigation overlay

TWRA = TWRA or {}
TWRA.OSD = TWRA.OSD or {}

-- Initialize the OSD system
function TWRA:InitOSD()
    self:Debug("osd", "Initializing On-Screen Display system")
    
    -- Ensure OSD namespace exists
    if not self.OSD then 
        self.OSD = {}
    end
    
    -- Load default settings if they don't exist
    if not TWRA_SavedVariables.options then
        TWRA_SavedVariables.options = {}
    end
    
    if not TWRA_SavedVariables.options.osdPoint then
        TWRA_SavedVariables.options.osdPoint = "CENTER"
        TWRA_SavedVariables.options.osdXOffset = 0
        TWRA_SavedVariables.options.osdYOffset = 100
        TWRA_SavedVariables.options.osdScale = 1.0
        TWRA_SavedVariables.options.osdDuration = 2
        TWRA_SavedVariables.options.osdLocked = false
    end
    
    -- Apply settings to OSD module
    self.OSD.point = TWRA_SavedVariables.options.osdPoint
    self.OSD.xOffset = TWRA_SavedVariables.options.osdXOffset
    self.OSD.yOffset = TWRA_SavedVariables.options.osdYOffset
    self.OSD.scale = TWRA_SavedVariables.options.osdScale
    self.OSD.duration = TWRA_SavedVariables.options.osdDuration
    self.OSD.locked = TWRA_SavedVariables.options.osdLocked
    
    -- Create the OSD overlay frame if it doesn't exist
    if not self.sectionOverlay then
        self:CreateOSDFrame()
    end
    
    -- Register for section changed messages
    self:RegisterMessageHandler("SECTION_CHANGED", function(sectionName, sectionIndex, totalSections, context)
        -- Show OSD when navigating to new section regardless of source
        self:ShowOSD(sectionName, sectionIndex, totalSections)
    end)
    
    self:Debug("osd", "OSD system initialized")
    return true
end

-- Create the OSD frame with all necessary elements
function TWRA:CreateOSDFrame()
    self:Debug("osd", "Creating OSD frame")
    
    -- Create the overlay frame
    self.sectionOverlay = CreateFrame("Frame", "TWRA_SectionOverlay", UIParent)
    self.sectionOverlay:SetFrameStrata("DIALOG")
    self.sectionOverlay:SetWidth(400)
    self.sectionOverlay:SetHeight(300)  -- Taller to accommodate assignments
    
    -- Position based on saved settings
    if self.OSD and self.OSD.point then
        self.sectionOverlay:SetPoint(
            self.OSD.point, 
            UIParent, 
            self.OSD.point, 
            self.OSD.xOffset or 0, 
            self.OSD.yOffset or 100
        )
        
        -- Apply scale
        if self.OSD.scale then
            self.sectionOverlay:SetScale(self.OSD.scale)
        end
    else
        self.sectionOverlay:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
    end
    
    -- Add background
    local bg = self.sectionOverlay:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture(0, 0, 0, 0.7)
    
    -- Add border
    local border = CreateFrame("Frame", nil, self.sectionOverlay)
    border:SetPoint("TOPLEFT", -2, 2)
    border:SetPoint("BOTTOMRIGHT", 2, -2)
    border:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    
    -- Create title and sections container
    local titleBar = CreateFrame("Frame", nil, self.sectionOverlay)
    titleBar:SetPoint("TOPLEFT", 10, -10)
    titleBar:SetPoint("TOPRIGHT", -10, -10)
    titleBar:SetHeight(30)
    
    -- Section name text (title)
    self.sectionOverlayTitle = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    self.sectionOverlayTitle:SetPoint("TOP", titleBar, "TOP", 0, 0)
    self.sectionOverlayTitle:SetTextColor(1, 0.82, 0)
    self.sectionOverlayTitle:SetText("Section Name")
    
    -- Create container for player-specific assignments
    self.assignmentsContainer = CreateFrame("Frame", nil, self.sectionOverlay)
    self.assignmentsContainer:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 0, -5)
    self.assignmentsContainer:SetPoint("BOTTOMRIGHT", self.sectionOverlay, "BOTTOMRIGHT", -10, 35)
    
    -- Setup scrolling for assignments
    self.scrollFrame = CreateFrame("ScrollFrame", "TWRA_OSD_ScrollFrame", self.assignmentsContainer)
    self.scrollFrame:SetPoint("TOPLEFT")
    self.scrollFrame:SetPoint("BOTTOMRIGHT")
    
    -- Create the content frame that will hold the assignments
    self.contentFrame = CreateFrame("Frame", "TWRA_OSD_ContentFrame", self.scrollFrame)
    self.contentFrame:SetWidth(self.assignmentsContainer:GetWidth())
    self.contentFrame:SetHeight(200)  -- Will be resized based on content
    self.scrollFrame:SetScrollChild(self.contentFrame)
    
    -- Store assignment text elements for reuse
    self.assignmentTexts = {}
    
    -- Section count text (footer)
    local footerBar = CreateFrame("Frame", nil, self.sectionOverlay)
    footerBar:SetPoint("BOTTOMLEFT", 10, 10)
    footerBar:SetPoint("BOTTOMRIGHT", -10, 10)
    footerBar:SetHeight(20)
    
    -- Section counter text
    self.sectionOverlayCount = footerBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    self.sectionOverlayCount:SetPoint("BOTTOM", footerBar, "BOTTOM", 0, 0)
    self.sectionOverlayCount:SetTextColor(1, 1, 1)
    self.sectionOverlayCount:SetText("Section 1 of 5")
    
    -- Make frame movable if not locked
    self:UpdateOSDMovable()
    
    -- Hide initially
    self.sectionOverlay:Hide()
    
    self:Debug("osd", "OSD frame created")
    return self.sectionOverlay
end

-- Update whether the OSD is movable based on lock setting
function TWRA:UpdateOSDMovable()
    if not self.sectionOverlay then return end
    
    local locked = self.OSD and self.OSD.locked
    
    if locked then
        -- Make immovable
        self.sectionOverlay:SetMovable(false)
        self.sectionOverlay:EnableMouse(false)
        self.sectionOverlay:RegisterForDrag()
        self.sectionOverlay:SetScript("OnDragStart", nil)
        self.sectionOverlay:SetScript("OnDragStop", nil)
    else
        -- Make movable
        self.sectionOverlay:SetMovable(true)
        self.sectionOverlay:EnableMouse(true)
        self.sectionOverlay:RegisterForDrag("LeftButton")
        self.sectionOverlay:SetScript("OnDragStart", function()
            this:StartMoving()
        end)
        self.sectionOverlay:SetScript("OnDragStop", function()
            this:StopMovingOrSizing()
            -- Save position
            local point, _, _, xOffset, yOffset = this:GetPoint()
            if point then
                TWRA.OSD.point = point
                TWRA.OSD.xOffset = xOffset
                TWRA.OSD.yOffset = yOffset
                
                -- Save to settings
                TWRA_SavedVariables.options.osdPoint = point
                TWRA_SavedVariables.options.osdXOffset = xOffset
                TWRA_SavedVariables.options.osdYOffset = yOffset
            end
        end)
    end
end

-- Clear all assignment texts in the OSD
function TWRA:ClearOSDAssignments()
    if not self.assignmentTexts then return end
    
    for i = 1, table.getn(self.assignmentTexts) do
        if self.assignmentTexts[i] then
            self.assignmentTexts[i]:Hide()
            self.assignmentTexts[i]:SetText("")
        end
    end
end

-- Get player-relevant assignments for the current section
function TWRA:GetPlayerRelevantAssignments(sectionName)
    if not sectionName or not self.fullData then 
        return {}
    end
    
    -- Find all rows for this section
    local sectionRows = {}
    for i = 1, table.getn(self.fullData) do
        if self.fullData[i][1] == sectionName then
            table.insert(sectionRows, self.fullData[i])
        end
    end
    
    if table.getn(sectionRows) == 0 then
        return {}
    end
    
    -- Find header row with column definitions
    local headerIndex = nil
    for i = 1, table.getn(sectionRows) do
        if sectionRows[i][2] == "Icon" then
            headerIndex = i
            break
        end
    end
    
    if not headerIndex then
        self:Debug("osd", "No header row found for section: " .. sectionName)
        return {}
    end
    
    -- Get player name and class
    local playerName = UnitName("player")
    local _, playerClass = UnitClass("player")
    playerClass = playerClass and string.upper(playerClass) or nil
    
    -- Get player's group number (1-8)
    local playerGroup = nil
    for i = 1, GetNumRaidMembers() do
        local name, _, subgroup = GetRaidRosterInfo(i)
        if name == playerName then
            playerGroup = subgroup
            break
        end
    end
    
    local headerRow = sectionRows[headerIndex]
    local relevantRows = {}
    
    -- Process each row for relevance
    for i = 1, table.getn(sectionRows) do
        -- Skip header row and special rows (Note, Warning, GUID)
        if i ~= headerIndex and sectionRows[i][2] ~= "Note" and 
           sectionRows[i][2] ~= "Warning" and sectionRows[i][2] ~= "GUID" then
            local row = sectionRows[i]
            local isRelevant = false
            local icon = row[2]
            local target = row[3] or ""
            
            -- Check if player is mentioned in any cell
            for col = 4, table.getn(row) do
                if row[col] == playerName then
                    isRelevant = true
                    break
                end
                
                -- Check for class groups (like "Warriors")
                if playerClass and self.CLASS_GROUP_NAMES then
                    for className, groupName in pairs(self.CLASS_GROUP_NAMES) do
                        if row[col] == className and string.upper(groupName) == playerClass then
                            isRelevant = true
                            break
                        end
                    end
                end
                
                -- Check for group references (like "Group 1")
                if playerGroup and string.find(row[col] or "", "Group " .. playerGroup) then
                    isRelevant = true
                    break
                end
            end
            
            if isRelevant then
                local entry = {
                    icon = icon,
                    target = target,
                    role = nil,
                    colored = self.COLORED_ICONS and self.COLORED_ICONS[icon] or icon
                }
                
                -- Determine player's specific role in this entry
                for col = 4, table.getn(row) do
                    if row[col] == playerName then
                        entry.role = headerRow[col] or "Role"
                        break
                    end
                end
                
                table.insert(relevantRows, entry)
            end
        end
    end
    
    return relevantRows
end

-- Format player assignments for OSD display
function TWRA:FormatPlayerAssignments(assignments, sectionData)
    local formattedLines = {}
    local headerFound = false
    local columnRoles = {}
    
    -- Find the header row for this section
    for i = 1, table.getn(sectionData) do
        if sectionData[i][1] == assignments[1].section and sectionData[i][2] == "Icon" then
            headerFound = true
            for j = 3, table.getn(sectionData[i]) do
                columnRoles[j-2] = sectionData[i][j] or "Role"
            end
            break
        end
    end
    
    if not headerFound then
        self:Debug("osd", "No header row found for assignments")
        return {}
    end
    
    -- Process and format each assignment for the player
    for _, assignment in ipairs(assignments) do
        local formatted = {}
        
        -- Create the formatted text
        local text
        if assignment.role then
            text = assignment.role .. " - " .. assignment.playerName .. " " .. 
                   (assignment.action or "targeting") .. " " .. 
                   (assignment.colored or assignment.icon) .. assignment.target
        else
            text = assignment.role .. " - " .. 
                   (assignment.colored or assignment.icon) .. assignment.target
        end
        
        table.insert(formattedLines, text)
    end
    
    return formattedLines
end

-- Create and display assignment text for the OSD
function TWRA:DisplayAssignmentsInOSD(sectionName)
    if not self.sectionOverlay or not self.contentFrame then return end
    
    -- Clear previous assignments
    self:ClearOSDAssignments()
    
    -- Get relevant assignments for the player
    local relevantRowIndices = self:GetPlayerRelevantRows(self:FilterToCurrentSection(self.fullData, sectionName))
    if table.getn(relevantRowIndices) == 0 then 
        self:Debug("osd", "No relevant assignments found for player")
        return
    end
    
    local lines = {}
    
    -- Find the header row to get role names
    local headerRow = nil
    local sectionData = self:FilterToCurrentSection(self.fullData, sectionName)
    for i, row in ipairs(sectionData) do
        if row[2] == "Icon" then
            headerRow = row
            break
        end
    end
    
    if not headerRow then
        self:Debug("osd", "No header row found in section: " .. sectionName)
        return
    end
    
    -- Format each relevant row
    local playerName = UnitName("player")
    local yOffset = 0
    
    for _, rowIndex in ipairs(relevantRowIndices) do
        local row = sectionData[rowIndex]
        if not row then 
            self:Debug("osd", "Row " .. rowIndex .. " not found in section data")
            break
        end
        
        local icon = row[2]
        local target = row[3] or ""
        local coloredIcon = (self.COLORED_ICONS and self.COLORED_ICONS[icon]) or icon
        
        -- Determine player's role in this row
        local roleLabel = nil
        local playerColumn = nil
        for col = 4, table.getn(row) do
            if row[col] == playerName then
                roleLabel = headerRow[col]
                playerColumn = col
                break
            end
        end
        
        -- Create formatted text
        local lineText = ""
        if roleLabel then
            -- If player directly appears, format based on their role
            lineText = roleLabel .. " - " .. coloredIcon .. (target ~= "" and " " .. target or "")
            
            -- Check if others are assigned to same role/target
            local others = {}
            for col = 4, table.getn(row) do
                if col ~= playerColumn and row[col] ~= "" and row[col] ~= playerName and headerRow[col] == roleLabel then
                    table.insert(others, row[col])
                end
            end
            
            -- Add other players with same role if any
            if table.getn(others) > 0 then
                lineText = lineText .. " with " .. table.concat(others, ", ")
            end
        else
            -- Alternative format if player is mentioned in a class group
            local formattedIcons = ""
            if coloredIcon ~= icon then
                formattedIcons = coloredIcon
            else
                formattedIcons = "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_" .. 
                               (TWRA.ICON_IDS[icon] or "8") .. ":0|t"
            end
            
            lineText = formattedIcons .. " " .. (target ~= "" and target or "")
            
            -- Check for class group roles
            for col = 4, table.getn(row) do
                local entry = row[col]
                if entry and entry ~= "" then
                    -- Check if this might be a class group the player belongs to
                    local isPlayerGroup = false
                    if entry == UnitClass("player") then 
                        isPlayerGroup = true
                    end
                    
                    -- TODO: Add more complex class group checking for entries like "Warriors"
                    
                    if isPlayerGroup then
                        lineText = headerRow[col] .. " - " .. lineText .. " with " .. entry
                        break
                    end
                end
            end
        end
        
        -- Create or reuse a fontstring for this line
        if not self.assignmentTexts[rowIndex] then
            self.assignmentTexts[rowIndex] = self.contentFrame:CreateFontString(
                nil, "OVERLAY", "GameFontNormal")
        end
        
        local textElement = self.assignmentTexts[rowIndex]
        textElement:SetPoint("TOPLEFT", self.contentFrame, "TOPLEFT", 10, yOffset)
        textElement:SetPoint("TOPRIGHT", self.contentFrame, "TOPRIGHT", -10, yOffset)
        textElement:SetJustifyH("LEFT")
        textElement:SetText(lineText)
        textElement:Show()
        
        -- Update Y offset for the next line
        yOffset = yOffset - 16
    end
    
    -- Resize the content frame to fit the assignments
    self.contentFrame:SetHeight(math.abs(yOffset) + 10)
end

-- Filter data to current section
function TWRA:FilterToCurrentSection(data, sectionName)
    if not data or not sectionName then return {} end
    
    local filteredData = {}
    for i = 1, table.getn(data) do
        if data[i][1] == sectionName then
            table.insert(filteredData, data[i])
        end
    end
    
    return filteredData
end

-- Show the OSD with the section name and player-relevant assignments
function TWRA:ShowOSD(sectionName, currentIndex, totalSections)
    if not sectionName then return end
    
    self:Debug("osd", "Showing OSD for " .. sectionName)
    
    -- Ensure the OSD frame exists
    if not self.sectionOverlay then
        self:CreateOSDFrame()
    end
    
    -- Set the section name and count
    self.sectionOverlayTitle:SetText(sectionName)
    self.sectionOverlayCount:SetText("Section " .. currentIndex .. " of " .. totalSections)
    
    -- Display player-relevant assignments
    self:DisplayAssignmentsInOSD(sectionName)
    
    -- Show the OSD
    self.sectionOverlay:Show()
    
    -- Set up the hide timer
    if self.osdHideTimer then
        self:CancelTimer(self.osdHideTimer)
    end
    
    local duration = (self.OSD and self.OSD.duration) or 2
    self.osdHideTimer = self:ScheduleTimer(function()
        if self.sectionOverlay then
            self.sectionOverlay:Hide()
        end
    end, duration)
    
    self:Debug("osd", "OSD will hide after " .. duration .. " seconds")
end

-- Test the OSD with current data
function TWRA:TestOSD()
    self:Debug("osd", "Testing OSD display")
    
    -- Default values if no data available
    local sectionName = "Test Section"
    local currentIndex = 1
    local totalSections = 1
    
    -- Try to get actual data
    if self.navigation and self.navigation.handlers then
        local handlers = self.navigation.handlers
        
        if table.getn(handlers) > 0 then
            currentIndex = self.navigation.currentIndex or 1
            if currentIndex > table.getn(handlers) then currentIndex = 1 end
            
            sectionName = handlers[currentIndex]
            totalSections = table.getn(handlers)
        end
    end
    
    -- Show the OSD with current data
    self:ShowOSD(sectionName, currentIndex, totalSections)
end

-- Toggle OSD visibility
function TWRA:ToggleOSD()
    if not self.sectionOverlay then
        self:CreateOSDFrame()
    end
    
    if self.sectionOverlay:IsShown() then
        -- If it's visible, hide it and cancel any timers
        self.sectionOverlay:Hide()
        
        if self.osdHideTimer then
            self:CancelTimer(self.osdHideTimer)
            self.osdHideTimer = nil
        end
        
        self:Debug("osd", "OSD manually hidden")
    else
        -- If hidden, show a test
        self:TestOSD()
        self:Debug("osd", "OSD manually shown")
    end
end

-- Reset OSD position to default
function TWRA:ResetOSDPosition()
    if not self.sectionOverlay then
        self:CreateOSDFrame()
    end
    
    -- Reset position
    self.sectionOverlay:ClearAllPoints()
    self.sectionOverlay:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
    
    -- Update saved settings
    self.OSD.point = "CENTER"
    self.OSD.xOffset = 0
    self.OSD.yOffset = 100
    
    -- Save to saved variables
    TWRA_SavedVariables.options.osdPoint = "CENTER"
    TWRA_SavedVariables.options.osdXOffset = 0
    TWRA_SavedVariables.options.osdYOffset = 100
    
    -- Show the OSD briefly to demonstrate the new position
    self:TestOSD()
    
    self:Debug("osd", "OSD position reset to default")
end

-- Update settings for the OSD
function TWRA:UpdateOSDSettings()
    if not self.OSD or not self.sectionOverlay then return end
    
    -- Apply scale
    self.sectionOverlay:SetScale(self.OSD.scale or 1.0)
    
    -- Update movement lock state
    self:UpdateOSDMovable()
    
    self:Debug("osd", "OSD settings updated")
end
