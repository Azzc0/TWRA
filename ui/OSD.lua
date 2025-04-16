-- TWRA On-Screen Display (OSD) Module
-- Phase 0: Visual Prototype based on the OSD-plan.md document

TWRA = TWRA or {}

-- Initialize OSD settings and structure
function TWRA:InitOSD()
    -- Skip if already initialized
    if self.OSD and self.OSD.initialized then
        self:Debug("osd", "OSD already initialized")
        return true
    end

    -- Create OSD namespace with default settings
    self.OSD = self.OSD or {
        isVisible = false,      -- Current visibility state
        autoHideTimer = nil,    -- Timer for auto-hiding
        duration = 2,           -- Duration in seconds before auto-hide (user configurable)
        scale = 1.0,            -- Scale factor for the OSD (user configurable)
        locked = false,         -- Whether frame position is locked (user configurable)
        enabled = true,         -- Whether OSD is enabled at all (user configurable)
        showOnNavigation = true, -- Show OSD when navigating sections (user configurable)
        point = "CENTER",       -- Frame position anchor point (saved between sessions)
        xOffset = 0,            -- X position offset (saved between sessions)
        yOffset = 100,          -- Y position offset (saved between sessions),
        displayMode = "assignments" -- Current display mode: "assignments" or "progress"
    }

    -- Load saved settings if available
    if TWRA_SavedVariables and TWRA_SavedVariables.options and TWRA_SavedVariables.options.osd then
        local savedOSD = TWRA_SavedVariables.options.osd
        self.OSD.point = savedOSD.point or self.OSD.point
        self.OSD.xOffset = savedOSD.xOffset or self.OSD.xOffset
        self.OSD.yOffset = savedOSD.yOffset or self.OSD.yOffset
        self.OSD.scale = savedOSD.scale or self.OSD.scale
        self.OSD.locked = savedOSD.locked
        self.OSD.enabled = (savedOSD.enabled ~= false) -- Default to true if nil
        self.OSD.showOnNavigation = (savedOSD.showOnNavigation ~= false) -- Default to true if nil
        self.OSD.duration = savedOSD.duration or self.OSD.duration
        self.OSD.displayMode = savedOSD.displayMode or self.OSD.displayMode
    end

    -- Register for events
    if self.RegisterEvent then
        self:Debug("osd", "Registering OSD event handlers")
        
        -- Register for section navigation events
        self:RegisterEvent("SECTION_CHANGED", function(sectionName, currentIndex, totalSections)
            self:Debug("osd", "SECTION_CHANGED event received: " .. sectionName)
            
            -- Always update the OSD content if it's currently visible
            if self.OSD.isVisible and self.OSDFrame and self.OSDFrame:IsShown() then
                self:Debug("osd", "OSD is visible, updating content regardless of view state")
                self:UpdateOSDContent(sectionName, currentIndex, totalSections)
            end
            
            -- Separately determine if we should show the OSD (new or existing)
            if self.ShouldShowOSD and self:ShouldShowOSD() then
                -- Update content (in case OSD wasn't already visible)
                self:UpdateOSDContent(sectionName, currentIndex, totalSections)
                -- Show the OSD
                self:ShowOSD()
            end
        end, "OSD")
        
        -- Register for group roster updates
        self:RegisterEvent("GROUP_ROSTER_UPDATED", function()
            self:Debug("osd", "GROUP_ROSTER_UPDATED event received")
            -- Only update OSD if it's already visible
            if self.OSD and self.OSD.isVisible then
                if self.navigation and self.navigation.currentIndex and self.navigation.handlers then
                    local sectionName = self.navigation.handlers[self.navigation.currentIndex]
                    local currentIndex = self.navigation.currentIndex
                    local totalSections = table.getn(self.navigation.handlers)
                    self:UpdateOSDContent(sectionName, currentIndex, totalSections)
                end
            end
        end, "OSD")
    end

    -- Mark as initialized
    self.OSD.initialized = true
    self:Debug("osd", "OSD system initialized")
    return true
end

-- Get or create the OSD frame
function TWRA:GetOSDFrame()
    -- Return existing frame if we have one
    if self.OSDFrame then
        return self.OSDFrame
    end

    -- Create the main OSD frame
    local frame = CreateFrame("Frame", "TWRAOSDFrame", UIParent)
    frame:SetFrameStrata("DIALOG")
    frame:SetWidth(400) -- Width of the OSD frame
    frame:SetHeight(200) -- Initial height, will be adjusted based on content

    -- Position the frame
    frame:ClearAllPoints()
    frame:SetPoint(self.OSD.point, UIParent, self.OSD.point, self.OSD.xOffset, self.OSD.yOffset)
    frame:SetScale(self.OSD.scale or 1.0)

    -- Add background with transparency
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture(0, 0, 0, 0.5) -- Black transparent background
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

    -- Create header container (for title)
    local headerContainer = CreateFrame("Frame", nil, frame)
    headerContainer:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -5)
    headerContainer:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -5)
    headerContainer:SetHeight(25)
    frame.headerContainer = headerContainer

    -- Create title text
    local titleText = headerContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleText:SetPoint("TOP", headerContainer, "TOP", 0, 0)
    titleText:SetPoint("LEFT", headerContainer, "LEFT", 10, 0)
    titleText:SetPoint("RIGHT", headerContainer, "RIGHT", -10, 0)
    titleText:SetHeight(25)
    titleText:SetJustifyH("CENTER")
    titleText:SetText("TWRA On-Screen Display")
    titleText:SetTextColor(1, 1, 1) -- Set title text to white
    frame.titleText = titleText
    if frame.titleText then
        local sectionTitle = sectionName
        
        -- Try to get proper section name from saved variables
        if TWRA_SavedVariables and TWRA_SavedVariables.assignments and 
           TWRA_SavedVariables.assignments.currentSectionName then
            sectionTitle = TWRA_SavedVariables.assignments.currentSectionName
            self:Debug("osd", "Using saved currentSectionName for title: " .. sectionTitle)
        end
        
        frame.titleText:SetText(sectionTitle)
    end

    -- Create content container (for assignment rows)
    local contentContainer = CreateFrame("Frame", nil, frame)
    contentContainer:SetPoint("TOPLEFT", headerContainer, "BOTTOMLEFT", 0, -5)
    contentContainer:SetPoint("TOPRIGHT", headerContainer, "BOTTOMRIGHT", 0, -5)
    contentContainer:SetHeight(80) -- Will be adjusted based on content
    frame.contentContainer = contentContainer
    
    -- Initial content will be generated by CreateContent
    self:CreateContent(contentContainer)

    -- Create footer container (for warnings/notes)
    local footerContainer = CreateFrame("Frame", nil, frame)
    footerContainer:SetPoint("TOPLEFT", contentContainer, "BOTTOMLEFT", 0, -5)
    footerContainer:SetPoint("TOPRIGHT", contentContainer, "BOTTOMRIGHT", 0, -5)
    footerContainer:SetHeight(25) -- Will be adjusted based on content
    frame.footerContainer = footerContainer

    -- Generate warnings
    self:CreateWarnings(footerContainer)

    -- Create progress bar container (positioned directly under header for progress mode)
    local progressBarContainer = CreateFrame("Frame", nil, frame)
    progressBarContainer:SetPoint("TOPLEFT", headerContainer, "BOTTOMLEFT", 10, -10)
    progressBarContainer:SetPoint("TOPRIGHT", headerContainer, "BOTTOMRIGHT", -10, -10)
    progressBarContainer:SetHeight(25)
    frame.progressBarContainer = progressBarContainer

    -- Add progress bar
    self:CreateProgressBar(progressBarContainer)
    progressBarContainer:Hide() -- Initially hidden

    -- Calculate total height for default display mode
    local totalHeight = headerContainer:GetHeight() + 
                       contentContainer:GetHeight() + 
                       footerContainer:GetHeight() + 
                       15 -- 15px total padding (5px between each container)

    frame:SetHeight(totalHeight)
    
    -- Set initial visibility
    frame:Hide()
    self.OSDFrame = frame

    self:Debug("osd", "OSD frame created")
    return frame
end

-- Apply OSD settings to the frame
function TWRA:UpdateOSDSettings()
    if not self.OSDFrame then
        self:Debug("osd", "Cannot update OSD settings: frame doesn't exist")
        return false
    end
    
    -- Apply scale setting
    self.OSDFrame:SetScale(self.OSD.scale or 1.0)
    
    -- Apply position settings
    self.OSDFrame:ClearAllPoints()
    self.OSDFrame:SetPoint(self.OSD.point or "CENTER", UIParent, self.OSD.point or "CENTER", self.OSD.xOffset or 0, self.OSD.yOffset or 100)
    
    -- Apply movable/locked state
    self.OSDFrame:SetMovable(not self.OSD.locked)
    self.OSDFrame:EnableMouse(not self.OSD.locked)
    
    -- Show/hide based on enabled setting
    if not self.OSD.enabled and self.OSD.isVisible then
        self:HideOSD()
    end
    
    self:Debug("osd", "OSD settings updated")
    return true
end

-- Create the base elements (icon and text) for a row
function TWRA:CreateRowBaseElements(rowFrame, role)
    -- Create role icon
    local roleIcon = rowFrame:CreateTexture(nil, "ARTWORK")
    
    -- Get role icon path based on role using TWRA.ROLE_MAPPINGS and TWRA.ROLE_ICONS
    local iconPath = "Interface\\Icons\\INV_Misc_QuestionMark" -- Default fallback
    
    -- Try to find a standardized role name using ROLE_MAPPINGS (case-insensitive)
    local standardRole = "Misc" -- Default if no match found
    local lowerRole = string.lower(role)
    
    -- Check if the role directly exists in ROLE_ICONS
    if self.ROLE_ICONS and self.ROLE_ICONS[role] then
        iconPath = self.ROLE_ICONS[role]
    -- Otherwise try to map it through ROLE_MAPPINGS
    elseif self.ROLE_MAPPINGS then
        -- Check if we have a direct match in the mappings
        if self.ROLE_MAPPINGS[lowerRole] then
            standardRole = self.ROLE_MAPPINGS[lowerRole]
        else
            -- Try to find a partial match (more expensive but catches variations)
            for pattern, mappedRole in pairs(self.ROLE_MAPPINGS) do
                if string.find(lowerRole, pattern) then
                    standardRole = mappedRole
                    break
                end
            end
        end
        
        -- Now get the icon path for the standardized role
        if self.ROLE_ICONS and self.ROLE_ICONS[standardRole] then
            iconPath = self.ROLE_ICONS[standardRole]
        end
    end
    
    roleIcon:SetTexture(iconPath)
    roleIcon:SetWidth(16)
    roleIcon:SetHeight(16)
    roleIcon:SetPoint("LEFT", rowFrame, "LEFT", 5, 0)
    
    -- Create role text
    local roleFontString = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    roleFontString:SetPoint("LEFT", roleIcon, "RIGHT", 3, 0)
    roleFontString:SetText(role .. " - ")
    roleFontString:SetJustifyH("LEFT")
    
    return roleIcon, roleFontString, 16 -- Return icon width for calculations
end

-- Create tank element (class icon + name)
function TWRA:CreateTankElement(rowFrame, tankName, tankClass, inRaid, isOnline, xPosition)
    -- Add tank class icon
    local tankClassIcon = rowFrame:CreateTexture(nil, "ARTWORK")
    
    -- Choose the right icon based on availability
    if not inRaid then
        -- Player not in group - use missing icon
        local iconInfo = self.ICONS and self.ICONS.Missing or {"Interface\\Buttons\\UI-GroupLoot-Pass-Up", 0, 1, 0, 1}
        tankClassIcon:SetTexture(iconInfo[1])
        tankClassIcon:SetTexCoord(iconInfo[2], iconInfo[3], iconInfo[4], iconInfo[5])
    else
        -- Player in group - use class icon
        tankClassIcon:SetTexture(self.TEXTURES.CLASS_ICONS)
        -- Set class icon texture coordinates using TWRA.CLASS_COORDS
        if self.CLASS_COORDS and self.CLASS_COORDS[string.upper(tankClass)] then
            local coords = self.CLASS_COORDS[string.upper(tankClass)]
            tankClassIcon:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
        end
    end
    
    tankClassIcon:SetWidth(14)
    tankClassIcon:SetHeight(14)
    tankClassIcon:SetPoint("LEFT", rowFrame, "LEFT", xPosition + 2, 0)
    
    -- Add tank name with class coloring
    local tankNameText = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    tankNameText:SetPoint("LEFT", tankClassIcon, "RIGHT", 2, 0)
    tankNameText:SetText(tankName)
    
    -- Apply class coloring using UIUtils function
    if self.UI and self.UI.ApplyClassColoring then
        self.UI:ApplyClassColoring(tankNameText, nil, tankClass, inRaid, isOnline)
    else
        -- Fallback if UI utils not available
        if not inRaid then
            -- Player not in group - gray color
            tankNameText:SetTextColor(0.5, 0.5, 0.5)
        elseif not isOnline then
            -- Player in group but offline - red color
            tankNameText:SetTextColor(1.0, 0.3, 0.3)
        else
            -- Player in group and online - use class color
            if self.VANILLA_CLASS_COLORS and self.VANILLA_CLASS_COLORS[tankClass] then
                local color = self.VANILLA_CLASS_COLORS[tankClass]
                tankNameText:SetTextColor(color.r, color.g, color.b)
            end
        end
    end
    
    -- Return elements and width calculation
    return tankClassIcon, tankNameText, 14 + 2 + tankNameText:GetStringWidth()
end

-- Create healer-specific row layout
function TWRA:CreateHealerRow(rowFrame, roleFontString, tanks, icon, target, playerData, playerStatus)
    -- Calculate row width for healers
    local rowWidth = 0
    
    -- Start with left padding + role icon + padding + role text
    rowWidth = 5 + 16 + 3 + roleFontString:GetStringWidth()
    
    local tankElements = {}
    
    -- Add all tanks with their class icons
    for t = 1, table.getn(tanks) do
        local tankName = tanks[t]
        local tankClass = playerData[tankName] or nil
        local inRaid = playerStatus[tankName] and playerStatus[tankName].inRaid or false
        local isOnline = playerStatus[tankName] and playerStatus[tankName].online or false
        
        local tankClassIcon, tankNameText, elementWidth = self:CreateTankElement(rowFrame, tankName, tankClass, inRaid, isOnline, rowWidth)
        
        -- Store reference to tank elements
        table.insert(tankElements, {icon = tankClassIcon, name = tankNameText})
        
        -- Update width calculation with tank elements
        rowWidth = rowWidth + elementWidth
        
        -- Add ampersand if more tanks coming
        if t < table.getn(tanks) then
            local ampText = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            ampText:SetPoint("LEFT", tankNameText, "RIGHT", 3, 0)
            ampText:SetText("&")
            ampText:SetTextColor(0.82, 0.82, 0.82) -- Light gray
            
            -- Add ampersand width to total
            rowWidth = rowWidth + 3 + ampText:GetStringWidth() + 5
        end
    end
        
    -- Add "tanking" text after the LAST tank name (not each tank)
    if table.getn(tankElements) > 0 then
        local lastTankElement = tankElements[table.getn(tankElements)]
        local tankingText = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        tankingText:SetPoint("LEFT", lastTankElement.name, "RIGHT", 3, 0)
        tankingText:SetText("tanking")
        tankingText:SetTextColor(0.82, 0.82, 0.82) -- Light gray
        
        -- Update width with tanking text
        rowWidth = rowWidth + 3 + tankingText:GetStringWidth()
            
        -- Add target raid icon with proper spacing
        local targetIcon = rowFrame:CreateTexture(nil, "ARTWORK")
        local iconInfo = self:GetIconInfo(icon)
        if iconInfo then
            targetIcon:SetTexture(iconInfo[1])
            targetIcon:SetTexCoord(iconInfo[2], iconInfo[3], iconInfo[4], iconInfo[5])
            targetIcon:SetWidth(16)
            targetIcon:SetHeight(16)
            targetIcon:SetPoint("LEFT", tankingText, "RIGHT", 5, 0)
            
            -- Add target text with reduced spacing
            local targetText = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            targetText:SetPoint("LEFT", targetIcon, "RIGHT", 2, 0)
            targetText:SetText(target)
            
            -- Update width with icon and target text
            rowWidth = rowWidth + 5 + 16 + 2 + targetText:GetStringWidth() + 10 -- Extra padding at end
        end
    end
    
    return rowWidth
end

-- Create tank/other row layout
function TWRA:CreateTankOrOtherRow(rowFrame, roleFontString, roleType, icon, target, tanks, playerData, playerStatus)
    -- TANK/OTHER FORMAT calculation
    local rowWidth = 0
    
    -- Start with left padding + role icon + padding + role text
    rowWidth = 5 + 16 + 3 + roleFontString:GetStringWidth()
    
    local targetIcon = rowFrame:CreateTexture(nil, "ARTWORK")
    local iconInfo = self:GetIconInfo(icon)
    if iconInfo then
        targetIcon:SetTexture(iconInfo[1])
        targetIcon:SetTexCoord(iconInfo[2], iconInfo[3], iconInfo[4], iconInfo[5])
        targetIcon:SetWidth(16)
        targetIcon:SetHeight(16)
        targetIcon:SetPoint("LEFT", roleFontString, "RIGHT", 0, 0)
        
        -- Add target text
        local targetText = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        targetText:SetPoint("LEFT", targetIcon, "RIGHT", 2, 0)
        targetText:SetText(target)
        
        -- Add target width to calculation
        rowWidth = rowWidth + 16 + 2 + targetText:GetStringWidth()
        
        if table.getn(tanks) > 0 then
            -- Add prefix text based on role (no extra spaces)
            local prefixText = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            prefixText:SetPoint("LEFT", targetText, "RIGHT", 3, 0)
            if roleType == "tank" then
                prefixText:SetText("with")
            else
                prefixText:SetText("tanked by")
            end
            prefixText:SetTextColor(0.82, 0.82, 0.82) -- Light gray
            
            -- Add width of prefix text
            rowWidth = rowWidth + 3 + prefixText:GetStringWidth() + 5
            
            -- Add tank widths
            for t = 1, table.getn(tanks) do
                local tankName = tanks[t]
                local tankClass = playerData[tankName] or nil
                local inRaid = playerStatus[tankName] and playerStatus[tankName].inRaid or false
                local isOnline = playerStatus[tankName] and playerStatus[tankName].online or false
                
                local tankClassIcon, tankNameText, elementWidth = self:CreateTankElement(rowFrame, tankName, tankClass, inRaid, isOnline, rowWidth)
                
                rowWidth = rowWidth + elementWidth
                
                if t < table.getn(tanks) then
                    local ampText = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                    ampText:SetPoint("LEFT", tankNameText, "RIGHT", 3, 0)
                    ampText:SetText("&")
                    ampText:SetTextColor(0.82, 0.82, 0.82)
                    
                    rowWidth = rowWidth + 3 + ampText:GetStringWidth() + 5
                end
            end
        end
        
        rowWidth = rowWidth + 10
    end
    
    return rowWidth
end

-- Helper function to get icon information
function TWRA:GetIconInfo(iconName)
    return self.ICONS and self.ICONS[iconName]
end

-- Create progress bar for Phase 0
function TWRA:CreateProgressBar(progressBarContainer)
    -- Create progress bar background
    local progressBarBg = progressBarContainer:CreateTexture(nil, "BACKGROUND")
    progressBarBg:SetTexture(0.1, 0.1, 0.1, 0.8) -- Darker background with higher opacity
    progressBarBg:SetAllPoints()

    -- Create progress bar fill
    local progressBarFill = progressBarContainer:CreateTexture(nil, "ARTWORK")
    -- Use the StatusBar texture for a smoother look
    progressBarFill:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    progressBarFill:SetTexCoord(0, 1, 0, 0.25) -- Use just the blue portion of the texture
    progressBarFill:SetVertexColor(0.0, 0.6, 1.0, 0.8) -- Brighter blue for better visibility
    progressBarFill:SetPoint("LEFT", progressBarContainer, "LEFT", 0, 0)
    progressBarFill:SetHeight(progressBarContainer:GetHeight())
    progressBarFill:SetWidth(0) -- Start at 0% progress
    progressBarContainer.progressBarFill = progressBarFill

    -- Add a subtle glow effect on top of the bar
    local progressBarGlow = progressBarContainer:CreateTexture(nil, "OVERLAY")
    progressBarGlow:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
    progressBarGlow:SetBlendMode("ADD")
    progressBarGlow:SetWidth(16)
    progressBarGlow:SetHeight(progressBarContainer:GetHeight() * 2)
    progressBarGlow:SetPoint("CENTER", progressBarFill, "RIGHT", 0, 0)
    progressBarContainer.progressBarGlow = progressBarGlow
    
    -- Create a border frame - using 9-slice approach for proper border scaling
    local borderFrame = CreateFrame("Frame", nil, progressBarContainer)
    borderFrame:SetFrameStrata("MEDIUM")
    -- Reduce gap by 5px on all sides (from ±5px to 0px)
    borderFrame:SetPoint("TOPLEFT", progressBarContainer, "TOPLEFT", 0, 0) 
    borderFrame:SetPoint("BOTTOMRIGHT", progressBarContainer, "BOTTOMRIGHT", 0, 0)
    
    -- Create a proper 9-slice border that scales well
    local edgeSize = 12
    borderFrame:SetBackdrop({
        bgFile = nil,
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", -- Using a border that's designed to tile/scale
        tile = true,
        tileSize = 16,
        edgeSize = edgeSize,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    borderFrame:SetBackdropBorderColor(0.6, 0.6, 0.6, 1.0) -- Slightly silver border
    progressBarContainer.borderFrame = borderFrame
    
    -- Create progress text
    local progressText = progressBarContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    progressText:SetPoint("CENTER", progressBarContainer, "CENTER", 0, 0)
    progressText:SetText("0% (0/0)")
    progressText:SetTextColor(1, 1, 1) -- White text
    progressBarContainer.progressText = progressText
    
    -- Create source text below the progress bar
    local sourceText = progressBarContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    sourceText:SetPoint("TOP", progressBarContainer, "BOTTOM", 0, -5)
    sourceText:SetPoint("LEFT", progressBarContainer, "LEFT", 5, 0)
    sourceText:SetPoint("RIGHT", progressBarContainer, "RIGHT", -5, 0)
    sourceText:SetText("Getting data from unknown")
    sourceText:SetHeight(20)
    sourceText:SetTextColor(1, 1, 1) -- White text
    progressBarContainer.sourceText = sourceText
    
    -- Initially hide the progress bar container
    progressBarContainer:Hide()
end

-- Create content using real data from the current section
function TWRA:CreateContent(contentContainer)
    self:Debug("osd", "Creating OSD content from real data")
    
    -- Store collections for reuse
    contentContainer.rowFrames = {}
    contentContainer.roleIcons = {}
    contentContainer.roleFontStrings = {}
    contentContainer.targetIcons = {}
    contentContainer.targetFontStrings = {}
    contentContainer.tanksFontStrings = {}
    
    -- Get current section data
    local currentSection = nil
    local currentSectionData = nil
    
    if self.navigation and self.navigation.currentIndex and self.navigation.handlers then
        currentSection = self.navigation.handlers[self.navigation.currentIndex]
        
        -- Find section data
        if currentSection and TWRA_SavedVariables and TWRA_SavedVariables.assignments and 
           TWRA_SavedVariables.assignments.data then
            for _, section in pairs(TWRA_SavedVariables.assignments.data) do
                if section["Section Name"] == currentSection then
                    currentSectionData = section
                    break
                end
            end
        end
    end
    
    -- If no section data found, create default content
    if not currentSectionData then
        self:Debug("osd", "No section data found, creating default content")
        return self:CreateDefaultContent(contentContainer)
    end
    
    -- Get player info
    local playerInfo = currentSectionData["Section Player Info"]
    if not playerInfo then
        self:Debug("osd", "No player info found in section, creating default content")
        return self:CreateDefaultContent(contentContainer)
    end
    
    -- Collect assignments from section data
    local osdAssignments = playerInfo["OSD Assignments"] or {}
    local osdGroupAssignments = playerInfo["OSD Group Assignments"] or {}
    
    -- Combine individual and group assignments
    local allAssignments = {}
    for _, assignment in ipairs(osdAssignments) do
        table.insert(allAssignments, assignment)
    end
    for _, assignment in ipairs(osdGroupAssignments) do
        table.insert(allAssignments, assignment)
    end
    
    -- If no assignments, return default content
    if table.getn(allAssignments) == 0 then
        self:Debug("osd", "No assignments found in section data, creating default content")
        return self:CreateDefaultContent(contentContainer)
    end
    
    -- Get player status for all players (in raid and online status)
    local playerData = {}
    local playerStatus = {}
    
    -- Loop through raid members to get class and status info
    for i = 1, GetNumRaidMembers() do
        local name, _, _, _, class, _, _, online = GetRaidRosterInfo(i)
        if name then
            playerData[name] = class
            playerStatus[name] = {inRaid = true, online = online}
        end
    end
    
    -- Loop through party members if not in a raid
    if GetNumRaidMembers() == 0 then
        for i = 1, GetNumPartyMembers() do
            local name = UnitName("party"..i)
            local _, class = UnitClass("party"..i)
            if name then
                playerData[name] = class
                playerStatus[name] = {inRaid = true, online = UnitIsConnected("party"..i)}
            end
        end
        
        -- Add player's own info
        local playerName = UnitName("player")
        local _, playerClass = UnitClass("player")
        playerData[playerName] = playerClass
        playerStatus[playerName] = {inRaid = true, online = true}
    end
    
    local yOffset = 0
    local rowHeight = 20 -- Increased row height to accommodate class icons
    
    -- Calculate the maximum content width needed
    local maxContentWidth = 400 -- Minimum width
    
    for i, assignment in ipairs(allAssignments) do
        -- Extract data from assignment
        local role = assignment[1]
        local icon = assignment[2]
        local target = assignment[3]
        local tanks = {}
        
        -- Collect tanks (indices 4 and beyond)
        for j = 4, table.getn(assignment) do
            table.insert(tanks, assignment[j])
        end
        
        -- Determine role type for different display formats
        local roleType = "other"
        if role == "Tank" then
            roleType = "tank"
        elseif role == "Heal" then
            roleType = "healer"
        end
        
        -- Create row frame
        local rowFrame = CreateFrame("Frame", nil, contentContainer)
        rowFrame:SetPoint("TOPLEFT", contentContainer, "TOPLEFT", 5, -yOffset)
        rowFrame:SetPoint("TOPRIGHT", contentContainer, "TOPRIGHT", -5, -yOffset)
        rowFrame:SetHeight(rowHeight)
        contentContainer.rowFrames[i] = rowFrame
        
        -- Create role icon and role text
        local roleIcon, roleFontString = self:CreateRowBaseElements(rowFrame, role)
        contentContainer.roleIcons[i] = roleIcon
        contentContainer.roleFontStrings[i] = roleFontString
        
        local rowWidth = 0
        -- Different layout based on role type
        if roleType == "healer" then
            rowWidth = self:CreateHealerRow(rowFrame, roleFontString, tanks, icon, target, playerData, playerStatus)
        else
            rowWidth = self:CreateTankOrOtherRow(rowFrame, roleFontString, roleType, icon, target, tanks, playerData, playerStatus)
        end
        
        -- Check if this row is wider than our current max
        if rowWidth > maxContentWidth then
            maxContentWidth = rowWidth
            self:Debug("osd", "New max width from row #" .. i .. ": " .. rowWidth)
        end
        
        yOffset = yOffset + rowHeight + 2
    end
    
    local parentFrame = contentContainer:GetParent()
    if parentFrame then
        local currentWidth = parentFrame:GetWidth()
        local neededWidth = maxContentWidth
        
        neededWidth = math.max(neededWidth, 400)
        
        parentFrame:SetWidth(neededWidth)
        self:Debug("osd", "Set OSD width to " .. neededWidth .. " pixels (content width: " .. maxContentWidth .. ")")
        
        -- Store the calculated max content width for later reuse when switching modes
        self.OSD.maxContentWidth = neededWidth
    end
    
    contentContainer:SetHeight(yOffset)
    
    self:Debug("osd", "Created real content with " .. table.getn(allAssignments) .. " assignments")
end

-- Create default content when no real assignments are found
function TWRA:CreateDefaultContent(contentContainer)
    self:Debug("osd", "Creating default content")
    
    -- Store collections for reuse
    contentContainer.rowFrames = {}
    contentContainer.roleIcons = {}
    contentContainer.roleFontStrings = {}
    contentContainer.targetIcons = {}
    contentContainer.targetFontStrings = {}
    contentContainer.tanksFontStrings = {}
    
    local rowHeight = 20
    local yOffset = 0
    
    -- Default assignment data
    local defaultAssignment = {
        [1] = "No assignment found",
        [2] = "",
        [3] = "Do your thing"
    }
    
    -- Create row frame
    local rowFrame = CreateFrame("Frame", nil, contentContainer)
    rowFrame:SetPoint("TOPLEFT", contentContainer, "TOPLEFT", 5, -yOffset)
    rowFrame:SetPoint("TOPRIGHT", contentContainer, "TOPRIGHT", -5, -yOffset)
    rowFrame:SetHeight(rowHeight)
    contentContainer.rowFrames[1] = rowFrame
    
    -- Create role icon and role text
    local roleIcon, roleFontString = self:CreateRowBaseElements(rowFrame, defaultAssignment[1])
    contentContainer.roleIcons[1] = roleIcon
    contentContainer.roleFontStrings[1] = roleFontString
    
    -- Create target elements (similar to CreateTankOrOtherRow but simplified)
    local targetText = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    targetText:SetPoint("LEFT", roleFontString, "RIGHT", 5, 0)
    targetText:SetText(defaultAssignment[3])
    targetText:SetTextColor(1, 0.82, 0) -- Golden color for visibility
    contentContainer.targetFontStrings[1] = targetText
    
    -- Set container height for the default row
    contentContainer:SetHeight(rowHeight)
    
    -- Set width for the parent frame
    local parentFrame = contentContainer:GetParent()
    if parentFrame then
        parentFrame:SetWidth(400)  -- Default width
        self.OSD.maxContentWidth = 400
    end
    
    self:Debug("osd", "Default content created")
    return true
end

-- Create warnings using real data from the current section
function TWRA:CreateWarnings(footerContainer)
    self:Debug("osd", "Creating warnings from real data")
    
    -- Clear existing warnings first
    footerContainer:SetHeight(0)
    local children = {footerContainer:GetChildren()}
    for _, child in ipairs(children) do
        child:Hide()
    end
    
    -- Clear existing textures
    local textures = {footerContainer:GetRegions()}
    for _, texture in ipairs(textures) do
        texture:Hide()
    end
    
    -- Get current section data
    local currentSection = nil
    local currentSectionData = nil
    
    if self.navigation and self.navigation.currentIndex and self.navigation.handlers then
        currentSection = self.navigation.handlers[self.navigation.currentIndex]
        
        -- Find section data
        if currentSection and TWRA_SavedVariables and TWRA_SavedVariables.assignments and 
           TWRA_SavedVariables.assignments.data then
            for _, section in pairs(TWRA_SavedVariables.assignments.data) do
                if section["Section Name"] == currentSection then
                    currentSectionData = section
                    break
                end
            end
        end
    end
    
    -- If no section data found, create default warning
    if not currentSectionData then
        self:Debug("osd", "No section data found, creating default warning")
    end
    
    -- Get metadata
    local metadata = currentSectionData["Section Metadata"]
    if not metadata then
        self:Debug("osd", "No metadata found in section, creating default warning")
    end
    
    -- Get warnings
    local warnings = metadata["Warning"] or {}
    
    -- If no warnings, create default warning
    if table.getn(warnings) == 0 then
        self:Debug("osd", "No warnings found in section metadata, creating default warning")
    end
    
    -- Height of each warning row and spacing
    local warningRowHeight = 20
    local rowSpacing = 1 -- 1px spacing between warning rows
    local totalWarningHeight = 0
    
    -- Create a test font string to calculate text widths accurately
    local testString = footerContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    testString:Hide() -- Keep it invisible
    
    -- Calculate fixed parameters for text fitting once
    local parentFrame = footerContainer:GetParent()
    local containerWidth = parentFrame:GetWidth() or 400
    local iconWidth = 16
    local leftPadding = 5
    local iconTextGap = 5
    local rightPadding = 5
    local availableWidth = containerWidth - iconWidth - leftPadding - iconTextGap - rightPadding
    
    -- Helper function to create a single warning row
    local function createWarningRow(warningText, yOffset)
        -- Create background
        local warningBg = footerContainer:CreateTexture(nil, "BACKGROUND")
        warningBg:SetTexture(0.3, 0.1, 0.1, 0.3) -- Red background
        warningBg:SetPoint("TOPLEFT", footerContainer, "TOPLEFT", 0, -yOffset)
        warningBg:SetPoint("TOPRIGHT", footerContainer, "TOPRIGHT", 0, -yOffset)
        warningBg:SetHeight(warningRowHeight)
        
        -- Create warning icon
        local warningIcon = footerContainer:CreateTexture(nil, "OVERLAY")
        local iconInfo = {"Interface\\GossipFrame\\AvailableQuestIcon", 0, 1, 0, 1}
        warningIcon:SetTexture(iconInfo[1])
        warningIcon:SetTexCoord(iconInfo[2], iconInfo[3], iconInfo[4], iconInfo[5])
        warningIcon:SetWidth(16)
        warningIcon:SetHeight(16)
        warningIcon:SetPoint("LEFT", warningBg, "LEFT", leftPadding, 0)
        
        -- Process warning text for item links
        local processedText = warningText
        if self.Items and self.Items.ProcessText then
            processedText = self.Items:ProcessText(warningText)
            self:Debug("osd", "Processed warning text for item links")
        end
        
        -- Create warning text
        local warnText = footerContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        warnText:SetPoint("LEFT", warningIcon, "RIGHT", iconTextGap, 0)
        warnText:SetPoint("RIGHT", warningBg, "RIGHT", -rightPadding, 0)
        warnText:SetHeight(warningRowHeight)
        warnText:SetJustifyH("LEFT")
        
        -- Measure text and truncate if needed
        testString:SetText(processedText)
        local fullTextWidth = testString:GetStringWidth()
        
        -- Truncate text if it's too long using simpler approach
        if fullTextWidth > availableWidth then
            -- Calculate approximate character width
            local avgCharWidth = fullTextWidth / string.len(processedText)
            -- Estimate how many characters will fit
            local fitChars = math.floor(availableWidth / avgCharWidth) - 3 -- leave room for ellipsis
            -- Apply upper limit to ensure we don't go out of bounds
            fitChars = math.min(fitChars, string.len(processedText))
            
            local truncatedText = string.sub(processedText, 1, fitChars) .. "..."
            warnText:SetText(truncatedText)
        else
            warnText:SetText(processedText)
        end
        
        -- Set text color
        warnText:SetTextColor(1, 0.7, 0.7) -- Light red for warnings
        
        -- Make the row clickable to announce to raid
        local clickArea = CreateFrame("Button", nil, footerContainer)
        clickArea:SetAllPoints(warningBg)
        clickArea:SetScript("OnEnter", function()
            warningBg:SetTexture(0.5, 0.1, 0.1, 0.5) -- Highlight on hover
            GameTooltip:SetOwner(clickArea, "ANCHOR_RIGHT")
            GameTooltip:AddLine("Click to announce to raid")
            GameTooltip:Show()
        end)
        
        clickArea:SetScript("OnLeave", function()
            warningBg:SetTexture(0.3, 0.1, 0.1, 0.3) -- Original color
            GameTooltip:Hide()
        end)
        
        clickArea:SetScript("OnClick", function()
            -- Announce the warning with properly processed item links
            SendChatMessage(warningText, "RAID")
            
            -- Visual feedback
            warningBg:SetTexture(0.7, 0.1, 0.1, 0.7)
            self:ScheduleTimer(function()
                if clickArea:IsMouseOver() then
                    warningBg:SetTexture(0.5, 0.1, 0.1, 0.5) -- Hover color
                else
                    warningBg:SetTexture(0.3, 0.1, 0.1, 0.3) -- Original color
                end
            end, 0.2)
        end)
        
        return warningRowHeight + rowSpacing
    end
    
    -- Create all warning rows
    for _, warningText in ipairs(warnings) do
        local rowHeight = createWarningRow(warningText, totalWarningHeight)
        totalWarningHeight = totalWarningHeight + rowHeight
    end
    
    -- Set footer height based on all warnings (subtract the last spacing)
    if totalWarningHeight > 0 then
        totalWarningHeight = totalWarningHeight - rowSpacing -- Remove the last spacing
    end
    footerContainer:SetHeight(totalWarningHeight)
    
    -- Clean up the test string
    testString:Hide()
    
    self:Debug("osd", "Created warnings container with " .. table.getn(warnings) .. " warnings")
    return true
end

-- Update OSD content with current section data
function TWRA:UpdateOSDContent(sectionName, currentIndex, totalSections)
    self:Debug("osd", "Updating OSD content for section: " .. (sectionName or "unknown"))
    
    -- Get or create the OSD frame
    local frame = self:GetOSDFrame()
    if not frame then
        self:Debug("error", "Failed to get OSD frame")
        return
    end
    
    -- Update title text - use the currentSectionName from saved variables if available
    if frame.titleText then
        local sectionTitle = sectionName
        
        -- Try to get proper section name from saved variables
        if TWRA_SavedVariables and TWRA_SavedVariables.assignments and 
           TWRA_SavedVariables.assignments.currentSectionName then
            sectionTitle = TWRA_SavedVariables.assignments.currentSectionName
            self:Debug("osd", "Using saved currentSectionName for title: " .. sectionTitle)
        end
        
        frame.titleText:SetText(sectionTitle)
    end
    
    -- Update content with real data if containers exist
    if frame.contentContainer then
        -- Clear existing content (release all child elements)
        for _, rowFrame in pairs(frame.contentContainer.rowFrames or {}) do
            rowFrame:Hide()
        end
        frame.contentContainer.rowFrames = {}
        
        -- Generate new content
        self:CreateContent(frame.contentContainer)
    end
    
    -- Update warnings with real data
    if frame.footerContainer then
        -- Generate new warnings
        self:CreateWarnings(frame.footerContainer)
    end
    
    -- Recalculate frame height
    local headerHeight = frame.headerContainer and frame.headerContainer:GetHeight() or 0
    local contentHeight = frame.contentContainer and frame.contentContainer:GetHeight() or 0
    local footerHeight = frame.footerContainer and frame.footerContainer:GetHeight() or 0
    
    -- Calculate total height with padding
    local totalHeight = headerHeight + contentHeight + footerHeight + 15  -- 15px total padding
    
    frame:SetHeight(totalHeight)
    
    self:Debug("osd", "Updated OSD content with real data")
    return true
end

-- Show OSD permanently (no auto-hide)
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
    
    -- Show the frame
    frame:Show()
    
    -- Clear any existing hide timer
    if self.OSD.autoHideTimer then
        self:CancelTimer(self.OSD.autoHideTimer)
        self.OSD.autoHideTimer = nil
    end
    
    -- Mark as visible
    self.OSD.isVisible = true
    self:Debug("osd", "OSD shown permanently")
    return true
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
    
    -- Show the frame
    frame:Show()
    
    -- Clear any existing hide timer
    if self.OSD.autoHideTimer then
        self:CancelTimer(self.OSD.autoHideTimer)
        self.OSD.autoHideTimer = nil
    end
    
    -- Set up auto-hide timer if duration is specified
    if duration or self.OSD.duration then
        local hideAfter = duration or self.OSD.duration
        self.OSD.autoHideTimer = self:ScheduleTimer(function()
            self:HideOSD()
            self.OSD.autoHideTimer = nil
        end, hideAfter)
        self:Debug("osd", "OSD shown with " .. hideAfter .. "s auto-hide")
    else
        self:Debug("osd", "OSD shown without auto-hide")
    end
    
    -- Mark as visible
    self.OSD.isVisible = true
    return true
end

-- Hide the OSD
function TWRA:HideOSD()
    -- Cancel any pending hide timer
    if self.OSD and self.OSD.autoHideTimer then
        self:CancelTimer(self.OSD.autoHideTimer)
        self.OSD.autoHideTimer = nil
    end
    
    -- Mark as hidden first (even if we can't find the frame)
    if self.OSD then
        self.OSD.isVisible = false
    end
    
    -- Check if the frame exists and hide it safely
    if self.OSDFrame then
        self.OSDFrame:Hide()
        self:Debug("osd", "OSD hidden")
    end
    
    return true
end

-- Toggle OSD visibility
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

-- Switch OSD to progress display mode
function TWRA:SwitchToProgressMode(sourcePlayer)
    if not self.OSDFrame then
        return false
    end
    
    -- Update OSD display mode
    self.OSD.displayMode = "progress"
    
    -- Update title text
    self.OSDFrame.titleText:SetText("Receiving Data")
    
    -- Hide the content container (assignments)
    self.OSDFrame.contentContainer:Hide()
    
    -- Hide the warning footer if it exists
    if self.OSDFrame.footerContainer then
        self.OSDFrame.footerContainer:Hide()
    end
    
    -- Show and position progress container
    local progressContainer = self.OSDFrame.progressBarContainer
    
    -- Set the width of progress container to exactly match the frame width (minus padding)
    local progressWidth = 380 -- 400px frame width - 10px padding on each side
    
    -- Position the progress bar directly under the header with proper padding
    progressContainer:ClearAllPoints()
    progressContainer:SetPoint("TOPLEFT", self.OSDFrame.headerContainer, "BOTTOMLEFT", 10, -10)
    progressContainer:SetPoint("TOPRIGHT", self.OSDFrame.headerContainer, "BOTTOMRIGHT", -10, -10)
    progressContainer:SetHeight(25)
    progressContainer:Show()
    
    -- Reset progress to 0
    self:UpdateProgressBar(0, 0, 0)
    
    -- Create or update source text
    if not progressContainer.sourceText then
        progressContainer.sourceText = progressContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        progressContainer.sourceText:SetPoint("TOP", progressContainer, "BOTTOM", 0, -5)
        progressContainer.sourceText:SetPoint("LEFT", progressContainer, "LEFT", 0, 0)
        progressContainer.sourceText:SetPoint("RIGHT", progressContainer, "RIGHT", 0, 0)
        progressContainer.sourceText:SetText("Getting data from " .. (sourcePlayer or "unknown"))
        progressContainer.sourceText:SetHeight(20)
    else
        progressContainer.sourceText:SetText("Getting data from " .. (sourcePlayer or "unknown"))
    end
    
    -- Calculate new reduced height for frame
    local totalHeight = self.OSDFrame.headerContainer:GetHeight() + 
                       progressContainer:GetHeight() +
                       20 + -- sourceText height
                       20   -- total padding
    
    -- Always use a fixed width of 400px for the progress display
    local frameWidth = 400
                       
    -- Adjust frame size
    self.OSDFrame:SetHeight(totalHeight)
    self.OSDFrame:SetWidth(frameWidth)
    
    -- Store the progress width for later use in UpdateProgressBar
    self.OSD.progressWidth = progressWidth
    
    return true
end

-- Switch OSD to assignment display mode
function TWRA:SwitchToAssignmentMode(sectionName)
    if not self.OSDFrame then
        return false
    end
    
    -- Update OSD display mode
    self.OSD.displayMode = "assignments"
    
    -- Update title text
    if sectionName then
        self.OSDFrame.titleText:SetText(sectionName)
    end
    
    -- Show the content container (assignments)
    self.OSDFrame.contentContainer:Show()
    
    -- Show the warning footer if it exists
    if self.OSDFrame.footerContainer then
        self.OSDFrame.footerContainer:Show()
    end
    
    -- Hide progress container
    if self.OSDFrame.progressBarContainer then
        self.OSDFrame.progressBarContainer:Hide()
    end
    
    -- Recalculate the proper frame height based on content
    local headerHeight = self.OSDFrame.headerContainer:GetHeight()
    local contentHeight = self.OSDFrame.contentContainer:GetHeight()
    local footerHeight = self.OSDFrame.footerContainer:GetHeight()
    
    -- Calculate total height with padding
    local totalHeight = headerHeight + contentHeight + footerHeight + 15  -- 15px total padding (5px between each container)
    
    -- Use the stored maximum content width to ensure consistent sizing
    local frameWidth = self.OSD.maxContentWidth
    
    -- Ensure we have a reasonable width if for some reason maxContentWidth is not set
    if not frameWidth or frameWidth < 400 then
        frameWidth = 400
    end
    
    -- Apply the calculated dimensions
    self.OSDFrame:SetHeight(totalHeight)
    self.OSDFrame:SetWidth(frameWidth)
    
    -- Log the resize for debugging
    self:Debug("osd", "Restored assignment view dimensions: " .. frameWidth .. "x" .. totalHeight)
    
    return true
end

-- Update progress bar with new values
function TWRA:UpdateProgressBar(progress, current, total)
    if not self.OSDFrame or not self.OSDFrame.progressBarContainer then
        return false
    end
    
    local progressContainer = self.OSDFrame.progressBarContainer
    
    -- Calculate percentage for display
    local percent = 0
    if total > 0 then
        percent = math.floor((current / total) * 100)
    end
    
    -- Update progress text
    if progressContainer.progressText then
        progressContainer.progressText:SetText(percent .. "% (" .. current .. "/" .. total .. ")")
    end
    
    -- Use a fixed container width of 380px for all calculations (400px frame - 20px padding)
    local containerWidth = 380
    
    -- Update progress bar fill
    if progressContainer.progressBarFill then
        -- When at 100%, fill exactly to container width, otherwise use percentage
        if percent >= 100 then
            progressContainer.progressBarFill:SetWidth(containerWidth)
        else
            progressContainer.progressBarFill:SetWidth(containerWidth * (percent / 100))
        end
        
        -- Position the glow at the end of the fill
        if progressContainer.progressBarGlow then
            progressContainer.progressBarGlow:SetPoint("CENTER", progressContainer.progressBarFill, "RIGHT", 0, 0)
        end
    end
    
    return true
end

-- Test function to simulate receiving data with progress updates
function TWRA:TestDataOSD(duration, chunks)
    -- Make sure OSD is initialized
    if not self.OSD then
        self:InitOSD()
    end
    
    -- Default values if not specified
    duration = duration or 5
    chunks = chunks or 10
    
    -- Show OSD and switch to progress mode
    self:ShowOSDPermanent()
    self:SwitchToProgressMode("Azzco")
    
    -- Cancel any existing progress timer
    if self.OSD.progressTimer then
        self:CancelTimer(self.OSD.progressTimer)
        self.OSD.progressTimer = nil
    end
    
    -- Initialize progress tracking variables
    self.OSD.startTime = GetTime()
    self.OSD.duration = duration
    self.OSD.totalChunks = chunks
    self.OSD.lastProcessedChunk = 0
    
    -- Display initial progress (0%)
    self:UpdateProgressBar(0, 0, chunks)
    
    -- Create a frame for OnUpdate handling to avoid timer issues
    if not self.OSD.progressFrame then
        self.OSD.progressFrame = CreateFrame("Frame")
    end
    
    -- Set up the OnUpdate script
    self.OSD.progressFrame:SetScript("OnUpdate", function()
        -- Calculate elapsed time
        local elapsed = GetTime() - self.OSD.startTime
        
        -- Calculate what chunk we should be on based on elapsed time
        local chunkProgress = elapsed / self.OSD.duration * self.OSD.totalChunks
        local currentChunk = math.min(math.floor(chunkProgress) + 1, self.OSD.totalChunks)
        
        -- Only process if we've moved to a new chunk
        if currentChunk > self.OSD.lastProcessedChunk then
            -- Debug output
            DEFAULT_CHAT_FRAME:AddMessage("TWRA: Processing chunk " .. currentChunk .. "/" .. self.OSD.totalChunks)
            
            -- Update progress display
            self:UpdateProgressBar(currentChunk / self.OSD.totalChunks, currentChunk, self.OSD.totalChunks)
            
            -- Update last processed chunk
            self.OSD.lastProcessedChunk = currentChunk
            
            -- If this is the last chunk, schedule cleanup
            if currentChunk >= self.OSD.totalChunks then
                -- Stop updates
                self.OSD.progressFrame:SetScript("OnUpdate", nil)
                
                -- Schedule transition back to assignment mode
                self:ScheduleTimer(function()
                    if self.OSD.isVisible then
                        self:SwitchToAssignmentMode("")
                        
                        -- Auto-hide after a delay
                        self:ScheduleTimer(function()
                            if self.OSD.isVisible then
                                self:HideOSD()
                            end
                        end, 2)
                    end
                end, 1.0)
            end
        end
    end)
    
    DEFAULT_CHAT_FRAME:AddMessage("TWRA: Testing data transfer simulation with " .. chunks .. " chunks over " .. duration .. " seconds")
    return true
end

-- Test function to show specific progress bar state without animation
function TWRA:TestDataOSDChunks(chunks, maxChunks)
    -- Make sure OSD is initialized
    if not self.OSD then
        self:InitOSD()
    end
    
    -- Default values if not specified
    chunks = chunks or 0
    maxChunks = maxChunks or 10
    
    -- Ensure we don't exceed maximum chunks
    chunks = math.min(chunks, maxChunks)
    
    -- Show OSD and switch to progress mode
    self:ShowOSDPermanent()
    self:SwitchToProgressMode("Azzco")
    
    -- Cancel any existing progress timer/update
    if self.OSD.progressTimer then
        self:CancelTimer(self.OSD.progressTimer)
        self.OSD.progressTimer = nil
    end
    
    if self.OSD.progressFrame then
        self.OSD.progressFrame:SetScript("OnUpdate", nil)
    end
    
    -- Update progress display with the specified chunks
    self:UpdateProgressBar(chunks / maxChunks, chunks, maxChunks)
    
    DEFAULT_CHAT_FRAME:AddMessage("TWRA: Showing progress bar at " .. chunks .. "/" .. maxChunks .. 
                                  " (" .. math.floor((chunks / maxChunks) * 100) .. "%)")
    return true
end

-- Test function to show the visual prototype
function TWRA:TestOSDVisual()
    -- Make sure OSD is initialized
    if not self.OSD then
        self:InitOSD()
    end
    
    -- Show OSD permanently
    self:ShowOSDPermanent()
    
    DEFAULT_CHAT_FRAME:AddMessage("TWRA: Showing OSD visual prototype")
    return true
end

-- Register additional slash command for testing
SLASH_TWRAOSD1 = "/twraosd"
SlashCmdList["TWRAOSD"] = function(msg)
    if msg == "test" or msg == "" then
        TWRA:TestOSDVisual()
    elseif msg == "hide" then
        TWRA:HideOSD()
    elseif msg == "toggle" then
        TWRA:ToggleOSD()
    elseif string.find(msg, "^data%s+%d+%s+%d+$") then
        -- Animated progress test with duration and chunks
        local duration, chunks = string.match(msg, "data%s+(%d+)%s+(%d+)")
        if duration and chunks then
            TWRA:TestDataOSD(tonumber(duration), tonumber(chunks))
        end
    elseif string.find(msg, "^chunks%s+%d+%s+%d+$") then
        -- Static progress display with current and max chunks
        local chunks, maxChunks = string.match(msg, "chunks%s+(%d+)%s+(%d+)")
        if chunks and maxChunks then
            TWRA:TestDataOSDChunks(tonumber(chunks), tonumber(maxChunks))
        end
    elseif string.find(msg, "^data") then
        -- Use default values if no parameters specified
        TWRA:TestDataOSD()
    end
end

-- Helper function to determine if OSD should be shown (implementation of placeholder)
function TWRA:ShouldShowOSD()
    -- Only show OSD if it's enabled
    if not self.OSD or not self.OSD.enabled then
        return false
    end
    
    -- If showOnNavigation is disabled, only respect the frame visibility
    if not self.OSD.showOnNavigation then
        return not self.mainFrame or not self.mainFrame:IsShown()
    end
    
    -- Show OSD when:
    -- 1. Main frame isn't visible, OR
    -- 2. We're in options view
    -- This way, navigating with the main frame open and in main view won't show the OSD
    return not self.mainFrame or 
           not self.mainFrame:IsShown() or 
           self.currentView == "options"
end

-- Set OSD anchor point while maintaining screen position
function TWRA:SetOSDAnchor(anchor)
    if not self.OSDFrame then
        self:Debug("osd", "Cannot set anchor: frame doesn't exist")
        return false
    end
    
    -- Get current screen position of the frame
    local x, y = self.OSDFrame:GetCenter()
    local screenWidth = UIParent:GetWidth()
    local screenHeight = UIParent:GetHeight()
    
    -- Validate anchor value
    local newPoint
    if anchor == "TL" then
        newPoint = "TOPLEFT"
    elseif anchor == "TR" then
        newPoint = "TOPRIGHT"
    elseif anchor == "BL" then
        newPoint = "BOTTOMLEFT"
    elseif anchor == "BR" then
        newPoint = "BOTTOMRIGHT"
    elseif anchor == "R" or anchor == "C" then
        newPoint = "CENTER"
    else
        self:Debug("osd", "Invalid anchor point: " .. tostring(anchor))
        return false
    end
    
    -- Calculate new offsets based on the new anchor point
    local width = self.OSDFrame:GetWidth() * self.OSDFrame:GetScale()
    local height = self.OSDFrame:GetHeight() * self.OSDFrame:GetScale()
    local newXOffset, newYOffset
    
    -- Calculate horizontal offset based on anchor
    if newPoint:find("LEFT") then
        newXOffset = x - (0 + width/2)
    elseif newPoint:find("RIGHT") then
        newXOffset = x - (screenWidth - width/2)
    else
        newXOffset = x - (screenWidth/2)
    end
    
    -- Calculate vertical offset based on anchor
    if newPoint:find("TOP") then
        newYOffset = y - (0 + height/2)
    elseif newPoint:find("BOTTOM") then
        newYOffset = y - (screenHeight - height/2)
    else
        newYOffset = y - (screenHeight/2)
    end
    
    -- Save new position settings
    self.OSD.point = newPoint
    self.OSD.xOffset = newXOffset
    self.OSD.yOffset = newYOffset
    
    -- Save to saved variables
    if TWRA_SavedVariables and TWRA_SavedVariables.options and TWRA_SavedVariables.options.osd then
        TWRA_SavedVariables.options.osd.point = newPoint
        TWRA_SavedVariables.options.osd.xOffset = newXOffset
        TWRA_SavedVariables.options.osd.yOffset = newYOffset
    end
    
    -- Apply new position
    self.OSDFrame:ClearAllPoints()
    self.OSDFrame:SetPoint(newPoint, UIParent, newPoint, newXOffset, newYOffset)
    
    self:Debug("osd", string.format("OSD anchor changed to %s at offsets x=%.2f, y=%.2f", 
                                    newPoint, newXOffset, newYOffset))
    
    return true
end