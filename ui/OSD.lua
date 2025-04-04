-- TWRA On-Screen Display Module
TWRA = TWRA or {}

-- OSD configuration defaults
TWRA.OSD = {
    point = "CENTER",
    xOffset = 0,
    yOffset = 100,
    scale = 1.0,
    duration = 2,
    locked = false
}

-- Initialize OSD settings
function TWRA:InitOSD()
    -- Load saved settings or use defaults
    if TWRA_SavedVariables and TWRA_SavedVariables.options then
        self.OSD.point = TWRA_SavedVariables.options.osdPoint or self.OSD.point
        self.OSD.xOffset = TWRA_SavedVariables.options.osdXOffset or self.OSD.xOffset
        self.OSD.yOffset = TWRA_SavedVariables.options.osdYOffset or self.OSD.yOffset
        self.OSD.scale = TWRA_SavedVariables.options.osdScale or self.OSD.scale
        self.OSD.duration = TWRA_SavedVariables.options.osdDuration or self.OSD.duration
        self.OSD.locked = TWRA_SavedVariables.options.osdLocked or self.OSD.locked
    end

    -- Schedule minimap button creation using the function from TWRA.lua
    self:ScheduleTimer(function()
        self:Debug("osd", "Creating minimap button...")
        -- Call CreateMinimapButton from TWRA.lua
        if self.CreateMinimapButton then
            self:CreateMinimapButton()
        else
            self:Debug("error", "CreateMinimapButton function not found!")
        end
    end, 1)
    
    -- Register message handlers using RegisterMessageHandler from TWRA.lua
    if self.RegisterMessageHandler then
        self:RegisterMessageHandler("SECTION_CHANGED", function(sectionName, currentIndex, totalSections, context)
            self:HandleSectionChange(sectionName, currentIndex, totalSections, context)
        end)
        
        self:RegisterMessageHandler("SHOW_OSD", function(sectionName, currentIndex, totalSections, persistent)
            self:ShowSectionNameOverlay(sectionName, currentIndex, totalSections, persistent)
        end)
        
        self:RegisterMessageHandler("TEST_OSD", function()
            self:TestOSD()
        end)
        
        self:Debug("osd", "OSD message handlers registered")
    else
        self:Debug("error", "RegisterMessageHandler function not found!")
    end
    
    self:Debug("osd", "OSD module initialized")
end

-- Handler for section change messages
function TWRA:HandleSectionChange(sectionName, currentIndex, totalSections, context)
    -- Determine if we should show OSD
    local shouldShowOSD = false
    
    -- Make sure context exists
    context = context or {}
    
    -- Case 1: Main frame doesn't exist or isn't shown
    if context.isMainFrameVisible == false then
        shouldShowOSD = true
    -- Case 2: We're in options view
    elseif context.inOptionsView then
        shouldShowOSD = true
    -- Case 3: This is a sync-triggered navigation
    elseif context.fromSync then
        shouldShowOSD = true
    end
    
    if shouldShowOSD then
        self:ShowSectionNameOverlay(sectionName, currentIndex, totalSections)
    end
end

-- Enhanced function to display section overlay with updated content every time
function TWRA:ShowSectionNameOverlay(sectionName, currentIndex, totalSections, persistent)
    self:Debug("osd", "Showing overlay for section: " .. (sectionName or "Unknown") .. 
               (persistent and " (persistent)" or ""))
    
    -- Create the overlay frame if it doesn't exist
    if not self.sectionOverlay then
        self:Debug("osd", "Creating section overlay frame")
        
        -- Create main frame
        self.sectionOverlay = CreateFrame("Frame", "TWRA_SectionOverlay", UIParent)
        self.sectionOverlay:SetFrameStrata("HIGH")
        self.sectionOverlay:SetWidth(500)
        self.sectionOverlay:SetHeight(100)
        
        -- Add background with more transparency
        local bg = self.sectionOverlay:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetTexture(0, 0, 0, 0.5) -- More translucent (0.5 instead of 0.7)
        
        -- Add border
        local border = CreateFrame("Frame", nil, self.sectionOverlay)
        border:SetPoint("TOPLEFT", -2, 2)
        border:SetPoint("BOTTOMRIGHT", 2, -2)
        border:SetBackdrop({
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        
        -- Section name text
        self.sectionOverlayText = self.sectionOverlay:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        self.sectionOverlayText:SetPoint("TOP", self.sectionOverlay, "TOP", 0, -10)
        self.sectionOverlayText:SetTextColor(1, 0.82, 0)
        
        -- Assignment info container
        self.sectionOverlayInfo = CreateFrame("Frame", nil, self.sectionOverlay)
        self.sectionOverlayInfo:SetPoint("TOP", self.sectionOverlayText, "BOTTOM", 0, -5)
        self.sectionOverlayInfo:SetWidth(460) -- Smaller width for proper padding
        self.sectionOverlayInfo:SetHeight(40)
        
        -- Assignment text - CHANGED TO LEFT JUSTIFIED
        self.sectionOverlayAssignment = self.sectionOverlayInfo:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        self.sectionOverlayAssignment:SetPoint("TOPLEFT", self.sectionOverlayInfo, "TOPLEFT", 15, -5) -- LEFT aligned
        self.sectionOverlayAssignment:SetWidth(430)
        self.sectionOverlayAssignment:SetJustifyH("LEFT") -- Always left aligned
        self.sectionOverlayAssignment:SetText("Section Content") -- Default text
        
        -- Section count text
        self.sectionOverlayCount = self.sectionOverlay:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        self.sectionOverlayCount:SetPoint("BOTTOM", self.sectionOverlay, "BOTTOM", 0, 10)
        self.sectionOverlayCount:SetTextColor(1, 1, 1)
        
        -- Add warning container and icon
        self.warningContainer = CreateFrame("Frame", nil, self.sectionOverlay)
        self.warningContainer:SetHeight(25)
        self.warningContainer:SetWidth(460)
        self.warningContainer:SetPoint("TOP", self.sectionOverlayInfo, "BOTTOM", 0, -5)
        
        self.warningIcon = self.warningContainer:CreateTexture(nil, "OVERLAY")
        self.warningIcon:SetTexture("Interface\\DialogFrame\\DialogAlertIcon")
        self.warningIcon:SetWidth(16)
        self.warningIcon:SetHeight(16)
        self.warningIcon:SetPoint("LEFT", self.warningContainer, "LEFT", 15, 0)
        self.warningIcon:Hide() -- Hide by default
        
        -- Warning text
        self.sectionOverlayWarning = self.warningContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        self.sectionOverlayWarning:SetPoint("LEFT", self.warningIcon, "RIGHT", 5, 0)
        self.sectionOverlayWarning:SetWidth(440)
        self.sectionOverlayWarning:SetJustifyH("LEFT")
        self.sectionOverlayWarning:SetTextColor(1, 0.6, 0.6) -- Light red color
        
        -- Add note container and icon
        self.noteContainer = CreateFrame("Frame", nil, self.sectionOverlay)
        self.noteContainer:SetHeight(25)
        self.noteContainer:SetWidth(460)
        self.noteContainer:SetPoint("TOP", self.warningContainer, "BOTTOM", 0, 0)
        
        self.noteIcon = self.noteContainer:CreateTexture(nil, "OVERLAY")
        self.noteIcon:SetTexture("Interface\\TutorialFrame\\TutorialFrame-QuestionMark")
        self.noteIcon:SetWidth(16)
        self.noteIcon:SetHeight(16)
        self.noteIcon:SetPoint("LEFT", self.noteContainer, "LEFT", 15, 0)
        self.noteIcon:Hide() -- Hide by default
        
        -- Note text
        self.sectionOverlayNote = self.noteContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        self.sectionOverlayNote:SetPoint("LEFT", self.noteIcon, "RIGHT", 5, 0)
        self.sectionOverlayNote:SetWidth(440)
        self.sectionOverlayNote:SetJustifyH("LEFT")
        self.sectionOverlayNote:SetTextColor(0.8, 0.8, 1) -- Light blue color
        
        -- Make it movable
        self.sectionOverlay:SetMovable(true)
        self.sectionOverlay:EnableMouse(true)
        self.sectionOverlay:RegisterForDrag("LeftButton")
        self.sectionOverlay:SetScript("OnDragStart", function()
            if not self.OSD.locked then
                self.sectionOverlay:StartMoving()
            end
        end)
        self.sectionOverlay:SetScript("OnDragStop", function()
            self.sectionOverlay:StopMovingOrSizing()
            -- Update position variables
            local point, _, relPoint, xOffset, yOffset = self.sectionOverlay:GetPoint()
            self.OSD.point = point
            self.OSD.relPoint = relPoint
            self.OSD.xOffset = xOffset
            self.OSD.yOffset = yOffset
            
            -- Save to options
            if TWRA_SavedVariables and TWRA_SavedVariables.options then
                TWRA_SavedVariables.options.osdPoint = point
                TWRA_SavedVariables.options.osdRelPoint = relPoint
                TWRA_SavedVariables.options.osdXOffset = xOffset
                TWRA_SavedVariables.options.osdYOffset = yOffset
            end
        end)
        
        -- Initialize icons array
        self.assignmentIcons = {}
    end
    
    -- Apply position and scale settings
    self.sectionOverlay:ClearAllPoints()
    self.sectionOverlay:SetPoint(self.OSD.point, UIParent, self.OSD.point, self.OSD.xOffset, self.OSD.yOffset)
    self.sectionOverlay:SetScale(self.OSD.scale)
    
    -- IMPORTANT: Try to determine the current section if arguments are missing
    if not sectionName and self.navigation and self.navigation.handlers and self.navigation.currentIndex then
        sectionName = self.navigation.handlers[self.navigation.currentIndex]
        currentIndex = self.navigation.currentIndex
        totalSections = table.getn(self.navigation.handlers)
    end
    
    -- Update text
    self.sectionOverlayText:SetText(sectionName or "Unknown Section")
    if currentIndex and totalSections then
        self.sectionOverlayCount:SetText("Section " .. currentIndex .. " of " .. totalSections)
    else
        self.sectionOverlayCount:SetText("")
    end
    
    -- IMPORTANT: Always update content when showing the overlay, even if we updated it before
    -- This ensures content is always fresh when the window is shown
    if sectionName and self.fullData then
        -- Clear any existing content first
        if self.sectionOverlayAssignment then self.sectionOverlayAssignment:SetText("") end
        if self.sectionOverlayWarning then self.sectionOverlayWarning:SetText("") end
        if self.sectionOverlayNote then self.sectionOverlayNote:SetText("") end
        if self.warningIcon then self.warningIcon:Hide() end
        if self.noteIcon then self.noteIcon:Hide() end
        
        -- Clean up any previously created icon textures
        if self.assignmentIcons then
            for _, icon in pairs(self.assignmentIcons) do
                if icon and icon.Hide then
                    icon:Hide()
                end
            end
        end
        self.assignmentIcons = {}
        
        -- Now explicitly update the content
        self:UpdateSectionOverlayContent(sectionName)
    else
        -- Just display basic info without content
        self.sectionOverlayAssignment:SetText("No content available")
        if self.sectionOverlayWarning then self.sectionOverlayWarning:SetText("") end
        if self.sectionOverlayNote then self.sectionOverlayNote:SetText("") end
        if self.warningIcon then self.warningIcon:Hide() end
        if self.noteIcon then self.noteIcon:Hide() end
    end
    
    -- Show the overlay
    self.sectionOverlay:Show()
    
    -- Cancel any existing timer
    if self.sectionOverlayTimer then
        self:CancelTimer(self.sectionOverlayTimer)
        self.sectionOverlayTimer = nil
    end
    
    -- If not persistent, hide after duration
    if not persistent then
        self.sectionOverlayTimer = self:ScheduleTimer(function()
            if self.sectionOverlay then
                self.sectionOverlay:Hide()
            end
        end, self.OSD.duration)
    end
    
    self:Debug("osd", "Section OSD shown with section: " .. (sectionName or "Unknown"))
end

-- Also update the ToggleOSD function to always try to show current content
function TWRA:ToggleOSD()
    -- If OSD doesn't exist yet, create it and show it persistently
    if not self.sectionOverlay then
        -- Try to get the current section from navigation
        local sectionName, currentIndex, totalSections
        if self.navigation and self.navigation.handlers and self.navigation.currentIndex then
            currentIndex = self.navigation.currentIndex
            sectionName = self.navigation.handlers[currentIndex]
            totalSections = table.getn(self.navigation.handlers)
        end
        
        -- Make sure we have a section name to display, use a placeholder if necessary
        if not sectionName then
            sectionName = "No section selected"
        end
        
        self:ShowSectionNameOverlay(sectionName, currentIndex, totalSections, true)
        self:Debug("osd", "OSD shown (persistent)")
    -- If OSD exists and is visible, hide it    
    elseif self.sectionOverlay:IsShown() then
        self.sectionOverlay:Hide()
        self:Debug("osd", "OSD hidden")
    -- If OSD exists but is hidden, show it persistently with current section
    else
        -- Try to get the current section from navigation
        local sectionName, currentIndex, totalSections
        if self.navigation and self.navigation.handlers and self.navigation.currentIndex then
            currentIndex = self.navigation.currentIndex
            sectionName = self.navigation.handlers[currentIndex]
            totalSections = table.getn(self.navigation.handlers)
        end
        
        -- Make sure we have a section name to display, use a placeholder if necessary
        if not sectionName then
            sectionName = "No section selected"
        end
        
        self:ShowSectionNameOverlay(sectionName, currentIndex, totalSections, true)
        self:Debug("osd", "OSD shown (persistent)")
    end
end

-- Helper function to extract texture and coordinates from an icon string
function TWRA:GetTextureInfo(iconString)
    if not iconString then return nil, nil end
    
    -- Check if this is a formatted string with texture coordinates
    local pattern = "(.+):(%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(%d+)"
    local texture, width, height, xOffset, yOffset, texWidth, texHeight, left, right, top, bottom = string.find(iconString, pattern)
    
    -- If pattern match failed, try the older direct method
    if not texture then
        -- Match function expects pattern first, then string
        texture, width, height, xOffset, yOffset, texWidth, texHeight, left, right, top, bottom = 
            string.match(iconString, "(.+):(%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(%d+)")
    end
    
    if texture then
        -- Return parsed texture and coordinates
        return texture, {
            left = tonumber(left)/tonumber(texWidth), 
            right = tonumber(right)/tonumber(texWidth), 
            top = tonumber(top)/tonumber(texHeight), 
            bottom = tonumber(bottom)/tonumber(texHeight), 
            width = tonumber(width),
            height = tonumber(height)
        }
    else
        -- Return just the texture without coordinates
        return iconString, nil
    end
end

-- Get player's current role and assignment info for OSD
function TWRA:UpdateSectionOverlayContent(sectionName)
    -- Clear previous content
    self.sectionOverlayAssignment:SetText("")
    
    -- Only clear warning and note elements if they exist
    if self.sectionOverlayWarning then self.sectionOverlayWarning:SetText("") end
    if self.sectionOverlayNote then self.sectionOverlayNote:SetText("") end
    
    -- Only hide icons if they exist
    if self.warningIcon then self.warningIcon:Hide() end
    if self.noteIcon then self.noteIcon:Hide() end
    
    -- Clean up any previously created icon textures
    if self.assignmentIcons then
        for _, icon in pairs(self.assignmentIcons) do
            if icon and icon.Hide then
                icon:Hide()
            end
        end
    end
    self.assignmentIcons = {}
    
    -- Ensure we have data to work with
    if not self.fullData then
        self:Debug("osd", "No assignment data available for OSD")
        return
    end
    
    local playerName = UnitName("player")
    local _, playerClass = UnitClass("player")
    self:Debug("osd", "Looking up OSD content for " .. playerName .. 
                                 " (class: " .. (playerClass or "unknown") .. 
                                 ") in section " .. sectionName)
    
    -- Initialize variables
    local headerRow = nil
    local relevantRows = {}
    local warnings = {}
    local notes = {}
    
    -- Get class group plural name for this player
    local classPlural = nil
    if playerClass and self.CLASS_GROUP_NAMES then
        for group, class in pairs(self.CLASS_GROUP_NAMES) do
            if class == playerClass then
                classPlural = group
                self:Debug("osd", "Found class group name: " .. group)
                break
            end
        end
    end
    
    -- First pass: Find header row and collect warnings/notes
    for i = 1, table.getn(self.fullData) do
        local row = self.fullData[i]
        
        if row and row[1] == sectionName then
            -- Check if this is a header row (has "Target" in column 3)
            if row[3] == "Target" then
                headerRow = row
                self:Debug("osd", "Found header row at index " .. i)
            elseif row[2] == "Warning" then
                table.insert(warnings, row[3])
                self:Debug("osd", "Found warning: " .. row[3])
            elseif row[2] == "Note" then
                table.insert(notes, row[3])
                self:Debug("osd", "Found note: " .. row[3])
            end
        end
    end
    
    -- Second pass: Find all rows where player is mentioned (or their class group)
    if headerRow then
        for i = 1, table.getn(self.fullData) do
            local row = self.fullData[i]
            
            -- Valid data row in the current section
            if row and row[1] == sectionName and 
               row[3] ~= "Target" and 
               row[2] ~= "Warning" and 
               row[2] ~= "Note" and 
               row[2] ~= "GUID" then
                
                local foundMatch = false
                local playerRole = nil
                local matchColumn = 0
                
                -- Check for direct player name match or class group match
                for col = 4, table.getn(row) do
                    if row[col] == playerName or (classPlural and row[col] == classPlural) then
                        foundMatch = true
                        matchColumn = col
                        playerRole = headerRow[col]
                        self:Debug("osd", "Found player match in column " .. col .. 
                                                     " - Role: " .. (playerRole or "unknown"))
                        break
                    end
                end
                
                -- If we found a match for this player, store the row with all needed info
                if foundMatch then
                    -- Process the entire row for player assignment
                    local isPlayerTank = string.find(string.lower(playerRole or ""), "tank") ~= nil
                    local isPlayerHealer = string.find(string.lower(playerRole or ""), "heal") ~= nil
                    
                    -- Collect tanks for this target
                    local tanks = {}
                    for col = 4, table.getn(row) do
                        local colRole = headerRow[col]
                        if colRole and string.find(string.lower(colRole), "tank") and 
                           row[col] and row[col] ~= "" and row[col] ~= playerName then
                            -- Store tank name and class if possible
                            local tankClass = self:GetPlayerClass(row[col])
                            -- Check if tank is in raid
                            local inRaid, online = self:GetPlayerStatus(row[col])
                            table.insert(tanks, { 
                                name = row[col], 
                                class = tankClass, 
                                inRaid = inRaid, 
                                online = online
                            })
                        end
                    end
                    
                    -- Collect healers for this target
                    local healers = {}
                    for col = 4, table.getn(row) do
                        local colRole = headerRow[col]
                        if colRole and string.find(string.lower(colRole), "heal") and 
                           row[col] and row[col] ~= "" and row[col] ~= playerName then
                            -- Store healer name and class if possible
                            local healerClass = self:GetPlayerClass(row[col])
                            -- Check if healer is in raid
                            local inRaid, online = self:GetPlayerStatus(row[col])
                            table.insert(healers, { 
                                name = row[col], 
                                class = healerClass, 
                                inRaid = inRaid, 
                                online = online
                            })
                        end
                    end
                    
                    table.insert(relevantRows, { 
                        rowIndex = i,                    -- Keep track of original row order
                        target = row[3] or "",           -- Target name
                        icon = row[2] or "",             -- Icon name
                        role = playerRole or "",         -- Player's role from header
                        isPlayerTank = isPlayerTank,     -- Whether player is a tank
                        isPlayerHealer = isPlayerHealer, -- Whether player is a healer
                        tanks = tanks,                   -- List of tanks for this target
                        healers = healers,               -- List of healers for this target
                        rowData = row,                   -- Full row data
                        matchColumn = matchColumn        -- Column where player was matched
                    })
                    self:Debug("osd", "Found relevant row - Target: " .. row[3])
                end
            end
        end
    end
    
    -- Sort relevant rows by their original order in the data
    table.sort(relevantRows, function(a, b) return a.rowIndex < b.rowIndex end)
    
    -- Create a new frame for each line of content, with icons properly aligned
    local contentLines = {}
    local lineHeight = 18  -- Slightly increased line height
    local totalHeight = 0
    local iconSize = 22    -- Increased icon size (was 16)
    
    -- Process each relevant row
    if table.getn(relevantRows) > 0 then
        for i, rowInfo in ipairs(relevantRows) do
            -- Create a container for this line
            local lineContainer = CreateFrame("Frame", nil, self.sectionOverlay)
            lineContainer:SetHeight(lineHeight)
            lineContainer:SetPoint("TOPLEFT", self.sectionOverlayInfo, "TOPLEFT", 0, -totalHeight)
            lineContainer:SetPoint("TOPRIGHT", self.sectionOverlayInfo, "TOPRIGHT", 0, -totalHeight)
            
            -- Add role icon
            local roleIconName = nil
            if string.find(string.lower(rowInfo.role), "tank") then
                roleIconName = "Tank"
            elseif string.find(string.lower(rowInfo.role), "heal") then
                roleIconName = "Heal"
            elseif string.find(string.lower(rowInfo.role), "dps") then
                roleIconName = "DPS"
            elseif string.find(string.lower(rowInfo.role), "cc") then
                roleIconName = "CC"
            elseif string.find(string.lower(rowInfo.role), "pull") then
                roleIconName = "Pull"
            elseif string.find(string.lower(rowInfo.role), "ress") or string.find(string.lower(rowInfo.role), "res") then
                roleIconName = "Ress"
            elseif string.find(string.lower(rowInfo.role), "assist") then
                roleIconName = "Assist"
            elseif string.find(string.lower(rowInfo.role), "scout") then
                roleIconName = "Scout"
            elseif string.find(string.lower(rowInfo.role), "lead") then
                roleIconName = "Lead"
            elseif string.find(string.lower(rowInfo.role), "mc") then
                roleIconName = "MC"
            elseif string.find(string.lower(rowInfo.role), "kick") then
                roleIconName = "Kick"
            elseif string.find(string.lower(rowInfo.role), "decurse") then
                roleIconName = "Decurse"
            elseif string.find(string.lower(rowInfo.role), "taunt") then
                roleIconName = "Taunt"
            elseif string.find(string.lower(rowInfo.role), "md") then
                roleIconName = "MD"
            elseif string.find(string.lower(rowInfo.role), "sap") then
                roleIconName = "Sap"
            elseif string.find(string.lower(rowInfo.role), "purge") then
                roleIconName = "Purge"
            elseif string.find(string.lower(rowInfo.role), "shackle") then
                roleIconName = "Shackle"
            elseif string.find(string.lower(rowInfo.role), "banish") then
                roleIconName = "Banish"
            elseif string.find(string.lower(rowInfo.role), "kite") then
                roleIconName = "Kite"
            elseif string.find(string.lower(rowInfo.role), "bomb") then
                roleIconName = "Bomb"
            elseif string.find(string.lower(rowInfo.role), "interrupt") then
                roleIconName = "Interrupt"
            else
                roleIconName = "Misc" -- Default fallback
            end
            
            local roleIcon = lineContainer:CreateTexture(nil, "OVERLAY")
            -- Check if the specific icon exists in our table
            if self.ROLE_ICONS and self.ROLE_ICONS[roleIconName] then
                roleIcon:SetTexture(self.ROLE_ICONS[roleIconName])
            else
                -- If no matching icon found, use the Misc icon as fallback
                roleIcon:SetTexture(self.ROLE_ICONS["Misc"])
            end
            roleIcon:SetWidth(iconSize)   -- Larger icon
            roleIcon:SetHeight(iconSize)  -- Larger icon
            roleIcon:SetPoint("LEFT", lineContainer, "LEFT", 15, 0)
            -- Center the icon vertically in the line
            roleIcon:SetPoint("TOP", lineContainer, "TOP", 0, -((lineHeight - iconSize) / 2))
            table.insert(self.assignmentIcons, roleIcon)
            
            -- Create role text
            local roleText = lineContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            roleText:SetPoint("LEFT", roleIcon, "RIGHT", 5, 0)
            roleText:SetText(rowInfo.role)
            roleText:SetTextColor(1, 1, 1)
            
            -- Add dash after role
            local dashText = lineContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            dashText:SetPoint("LEFT", roleText, "RIGHT", 5, 0)
            dashText:SetText("-")
            dashText:SetTextColor(1, 1, 1)
            
            -- Add raid icon handling for non-healer rows (standardizing with healer approach)
            if not rowInfo.isPlayerHealer then
                local currentXPos = dashText
                
                -- Add raid target icon if available (before target name)
                if rowInfo.icon and rowInfo.icon ~= "" and self.ICONS and self.ICONS[rowInfo.icon] then
                    local iconInfo = self.ICONS[rowInfo.icon]
                    local targetIcon = lineContainer:CreateTexture(nil, "OVERLAY")
                    targetIcon:SetTexture(iconInfo[1])
                    targetIcon:SetTexCoord(iconInfo[2], iconInfo[3], iconInfo[4], iconInfo[5])
                    targetIcon:SetWidth(16) -- Standard 16x16 size
                    targetIcon:SetHeight(16) -- Standard 16x16 size
                    targetIcon:SetPoint("LEFT", currentXPos, "RIGHT", 5, 0)
                    table.insert(self.assignmentIcons, targetIcon)
                    currentXPos = targetIcon
                end
                
                -- Add target name
                local targetText = lineContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                targetText:SetPoint("LEFT", currentXPos, "RIGHT", 3, 0)
                targetText:SetText(rowInfo.target)
                targetText:SetTextColor(1, 1, 1)
                currentXPos = targetText
                
                -- If player is not a tank and we have tank info, show "tanked by <tanks>"
                if not rowInfo.isPlayerTank and table.getn(rowInfo.tanks) > 0 then
                    -- Add "tanked by" text
                    local tankedByText = lineContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                    tankedByText:SetPoint("LEFT", currentXPos, "RIGHT", 5, 0)
                    tankedByText:SetText("tanked by")
                    tankedByText:SetTextColor(0.8, 0.8, 0.8) -- Slightly dimmer
                    currentXPos = tankedByText
                    
                    -- Add each tank with class icon and color
                    for j, tank in ipairs(rowInfo.tanks) do
                        -- Add separator if needed
                        if j > 1 then
                            local separator = lineContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                            separator:SetPoint("LEFT", currentXPos, "RIGHT", 3, 0)
                            if j == table.getn(rowInfo.tanks) then
                                separator:SetText(" and ")
                            else
                                separator:SetText(", ")
                            end
                            separator:SetTextColor(0.8, 0.8, 0.8)
                            currentXPos = separator
                        end
                        
                        -- Add class icon for tank (or not available icon)
                        local classIcon = lineContainer:CreateTexture(nil, "OVERLAY")
                        table.insert(self.assignmentIcons, classIcon)
                        
                        if not tank.inRaid then
                            -- Tank not in raid - use not available icon
                            classIcon:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
                            classIcon:SetWidth(14)
                            classIcon:SetHeight(14)
                            classIcon:SetPoint("LEFT", currentXPos, "RIGHT", 3, 0)
                        elseif tank.class and self.CLASS_COORDS and self.CLASS_COORDS[tank.class] then
                            -- Tank in raid with known class - use class icon
                            local coords = self.CLASS_COORDS[tank.class]
                            classIcon:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
                            classIcon:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
                            classIcon:SetWidth(14)
                            classIcon:SetHeight(14)
                            classIcon:SetPoint("LEFT", currentXPos, "RIGHT", 3, 0)
                            -- Apply red tint if player is offline
                            if not tank.online then
                                classIcon:SetVertexColor(0.5, 0.5, 0.5) -- Gray for offline
                            elseif not tank.inRaid then
                                classIcon:SetVertexColor(1.0, 0.3, 0.3) -- Red for not in raid
                            end
                        end
                        currentXPos = classIcon
                        
                        -- Add colored tank name
                        local tankName = lineContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                        tankName:SetPoint("LEFT", currentXPos, "RIGHT", 3, 0)
                        tankName:SetText(tank.name)
                        
                        if TWRA.UI and TWRA.UI.ApplyClassColoring then
                            TWRA.UI:ApplyClassColoring(tankName, 
                                self:SafeGetTankProperty(tank, "name", ""), 
                                self:SafeGetTankProperty(tank, "class", ""),
                                self:SafeGetTankProperty(tank, "inRaid", false),
                                self:SafeGetTankProperty(tank, "online", false))
                        else
                            -- Fallback if UI utils not available
                            TWRA:ApplyPlayerNameColoring(tankName, 
                                self:SafeGetTankProperty(tank, "name", ""), 
                                self:SafeGetTankProperty(tank, "class", ""),
                                self:SafeGetTankProperty(tank, "inRaid", false),
                                self:SafeGetTankProperty(tank, "online", false))
                        end
                        
                        currentXPos = tankName
                    end
                end
                
                -- If player is a tank and other tanks exist, show "along with <tanks>"
                if rowInfo.isPlayerTank and table.getn(rowInfo.tanks) > 0 then
                    -- Add "along with" text
                    local alongWithText = lineContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                    alongWithText:SetPoint("LEFT", currentXPos, "RIGHT", 5, 0)
                    alongWithText:SetText("along with")
                    alongWithText:SetTextColor(0.8, 0.8, 0.8) -- Slightly dimmer
                    currentXPos = alongWithText
                    
                    -- Add each tank with class icon and color
                    for j, tank in ipairs(rowInfo.tanks) do
                        -- Add separator if needed
                        if j > 1 then
                            local separator = lineContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                            separator:SetPoint("LEFT", currentXPos, "RIGHT", 3, 0)
                            if j == table.getn(rowInfo.tanks) then
                                separator:SetText(" and ")
                            else
                                separator:SetText(", ")
                            end
                            separator:SetTextColor(0.8, 0.8, 0.8)
                            currentXPos = separator
                        end
                        
                        -- Add class icon for tank (or not available icon)
                        local classIcon = lineContainer:CreateTexture(nil, "OVERLAY")
                        table.insert(self.assignmentIcons, classIcon)
                        
                        if not tank.inRaid then
                            -- Tank not in raid - use not available icon
                            classIcon:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
                            classIcon:SetWidth(14)
                            classIcon:SetHeight(14)
                            classIcon:SetPoint("LEFT", currentXPos, "RIGHT", 3, 0)
                        elseif tank.class and self.CLASS_COORDS and self.CLASS_COORDS[tank.class] then
                            -- Tank in raid with known class - use class icon
                            local coords = self.CLASS_COORDS[tank.class]
                            classIcon:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
                            classIcon:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
                            classIcon:SetWidth(14)
                            classIcon:SetHeight(14)
                            classIcon:SetPoint("LEFT", currentXPos, "RIGHT", 3, 0)
                            -- Apply color tint based on status
                            if not tank.online then
                                classIcon:SetVertexColor(0.5, 0.5, 0.5) -- Gray for offline
                            elseif not tank.inRaid then
                                classIcon:SetVertexColor(1.0, 0.3, 0.3) -- Red for not in raid
                            end
                        end
                        currentXPos = classIcon
                        
                        -- Add colored tank name
                        local tankName = lineContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                        tankName:SetPoint("LEFT", currentXPos, "RIGHT", 3, 0)
                        tankName:SetText(tank.name)
                        
                        if TWRA.UI and TWRA.UI.ApplyClassColoring then
                            TWRA.UI:ApplyClassColoring(tankName, 
                                self:SafeGetTankProperty(tank, "name", ""), 
                                self:SafeGetTankProperty(tank, "class", ""),
                                self:SafeGetTankProperty(tank, "inRaid", false),
                                self:SafeGetTankProperty(tank, "online", false))
                        else
                            -- Fallback if UI utils not available
                            TWRA:ApplyPlayerNameColoring(tankName, 
                                self:SafeGetTankProperty(tank, "name", ""), 
                                self:SafeGetTankProperty(tank, "class", ""),
                                self:SafeGetTankProperty(tank, "inRaid", false),
                                self:SafeGetTankProperty(tank, "online", false))
                        end
                        
                        currentXPos = tankName
                    end
                end
                
                -- If player is a tank, list other tanks and healers
                if rowInfo.isPlayerTank then
                    -- List other tanks if any
                    if table.getn(rowInfo.tanks) > 0 then
                        -- Add "along with" text
                        local alongWithText = lineContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                        alongWithText:SetPoint("LEFT", currentXPos, "RIGHT", 5, 0)
                        alongWithText:SetText("along with")
                        alongWithText:SetTextColor(0.8, 0.8, 0.8) -- Slightly dimmer
                        currentXPos = alongWithText
                        
                        -- Add each tank with class icon and color
                        for j, tank in ipairs(rowInfo.tanks) do
                            -- Add separator if needed
                            if j > 1 then
                                local separator = lineContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                                separator:SetPoint("LEFT", currentXPos, "RIGHT", 3, 0)
                                if j == table.getn(rowInfo.tanks) then
                                    separator:SetText(" and ")
                                else
                                    separator:SetText(", ")
                                end
                                separator:SetTextColor(0.8, 0.8, 0.8)
                                currentXPos = separator
                            end
                            
                            -- Add class icon for tank (or not available icon)
                            local classIcon = lineContainer:CreateTexture(nil, "OVERLAY")
                            table.insert(self.assignmentIcons, classIcon)
                            
                            if not tank.inRaid then
                                -- Tank not in raid - use not available icon
                                classIcon:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
                                classIcon:SetWidth(14)
                                classIcon:SetHeight(14)
                                classIcon:SetPoint("LEFT", currentXPos, "RIGHT", 3, 0)
                            elseif tank.class and self.CLASS_COORDS and self.CLASS_COORDS[tank.class] then
                                -- Tank in raid with known class - use class icon
                                local coords = self.CLASS_COORDS[tank.class]
                                classIcon:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
                                classIcon:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
                                classIcon:SetWidth(14)
                                classIcon:SetHeight(14)
                                classIcon:SetPoint("LEFT", currentXPos, "RIGHT", 3, 0)
                                -- Apply color tint based on status
                                if not tank.online then
                                    classIcon:SetVertexColor(0.5, 0.5, 0.5) -- Gray for offline
                                elseif not tank.inRaid then
                                    classIcon:SetVertexColor(1.0, 0.3, 0.3) -- Red for not in raid
                                end
                            end
                            currentXPos = classIcon
                            
                            -- Add colored tank name
                            local tankName = lineContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                            tankName:SetPoint("LEFT", currentXPos, "RIGHT", 3, 0)
                            tankName:SetText(tank.name)
                            
                            if TWRA.UI and TWRA.UI.ApplyClassColoring then
                                TWRA.UI:ApplyClassColoring(tankName, 
                                    self:SafeGetTankProperty(tank, "name", ""), 
                                    self:SafeGetTankProperty(tank, "class", ""),
                                    self:SafeGetTankProperty(tank, "inRaid", false),
                                    self:SafeGetTankProperty(tank, "online", false))
                            else
                                -- Fallback if UI utils not available
                                TWRA:ApplyPlayerNameColoring(tankName, 
                                    self:SafeGetTankProperty(tank, "name", ""), 
                                    self:SafeGetTankProperty(tank, "class", ""),
                                    self:SafeGetTankProperty(tank, "inRaid", false),
                                    self:SafeGetTankProperty(tank, "online", false))
                            end
                            
                            currentXPos = tankName
                        end
                    end
                    
                    -- List healers if any
                    if table.getn(rowInfo.healers) > 0 then
                        -- Add "healed by" text
                        local healedByText = lineContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                        healedByText:SetPoint("LEFT", currentXPos, "RIGHT", 5, 0)
                        healedByText:SetText("healed by")
                        healedByText:SetTextColor(0.8, 0.8, 0.8) -- Slightly dimmer
                        currentXPos = healedByText
                        
                        -- Add each healer with class icon and color
                        for j, healer in ipairs(rowInfo.healers) do
                            -- Add separator if needed
                            if j > 1 then
                                local separator = lineContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                                separator:SetPoint("LEFT", currentXPos, "RIGHT", 3, 0)
                                if j == table.getn(rowInfo.healers) then
                                    separator:SetText(" and ")
                                else
                                    separator:SetText(", ")
                                end
                                separator:SetTextColor(0.8, 0.8, 0.8)
                                currentXPos = separator
                            end
                            
                            -- Add class icon for healer
                            local classIcon = lineContainer:CreateTexture(nil, "OVERLAY")
                            table.insert(self.assignmentIcons, classIcon)
                            
                            if not healer.inRaid then
                                -- Healer not in raid - use not available icon
                                classIcon:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
                                classIcon:SetWidth(14)
                                classIcon:SetHeight(14)
                                classIcon:SetPoint("LEFT", currentXPos, "RIGHT", 3, 0)
                            elseif healer.class and self.CLASS_COORDS and self.CLASS_COORDS[healer.class] then
                                -- Healer in raid with known class - use class icon
                                local coords = self.CLASS_COORDS[healer.class]
                                classIcon:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
                                classIcon:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
                                classIcon:SetWidth(14)
                                classIcon:SetHeight(14)
                                classIcon:SetPoint("LEFT", currentXPos, "RIGHT", 3, 0)
                                -- Apply color tint based on status
                                if not healer.online then
                                    classIcon:SetVertexColor(0.5, 0.5, 0.5) -- Gray for offline
                                elseif not healer.inRaid then
                                    classIcon:SetVertexColor(1.0, 0.3, 0.3) -- Red for not in raid
                                end
                            end
                            currentXPos = classIcon
                            
                            -- Add colored healer name
                            local healerName = lineContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                            healerName:SetPoint("LEFT", currentXPos, "RIGHT", 3, 0)
                            healerName:SetText(healer.name)
                            
                            if TWRA.UI and TWRA.UI.ApplyClassColoring then
                                TWRA.UI:ApplyClassColoring(healerName, 
                                    self:SafeGetTankProperty(healer, "name", ""), 
                                    self:SafeGetTankProperty(healer, "class", ""),
                                    self:SafeGetTankProperty(healer, "inRaid", false),
                                    self:SafeGetTankProperty(healer, "online", false))
                            else
                                -- Fallback if UI utils not available
                                TWRA:ApplyPlayerNameColoring(healerName, 
                                    self:SafeGetTankProperty(healer, "name", ""), 
                                    self:SafeGetTankProperty(healer, "class", ""),
                                    self:SafeGetTankProperty(healer, "inRaid", false),
                                    self:SafeGetTankProperty(healer, "online", false))
                            end
                            
                            currentXPos = healerName
                        end
                    end
                end
            end
            
            -- MODIFIED LAYOUT FOR HEALERS
            if rowInfo.isPlayerHealer then
                local currentXPos = dashText
                
                -- For healers: "Heal - [ClassIcon] Tank's name tanking [RaidIcon] Target"
                if table.getn(rowInfo.tanks) > 0 then
                    for j, tank in ipairs(rowInfo.tanks) do
                        -- Add separator if needed (for multiple tanks)
                        if j > 1 then
                            local separator = lineContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                            separator:SetPoint("LEFT", currentXPos, "RIGHT", 3, 0)
                            if j == table.getn(rowInfo.tanks) then
                                separator:SetText(" and ")
                            else
                                separator:SetText(", ")
                            end
                            separator:SetTextColor(0.8, 0.8, 0.8)
                            currentXPos = separator
                        end
                        
                        -- Add class icon for tank (or not available icon)
                        local classIcon = lineContainer:CreateTexture(nil, "OVERLAY")
                        table.insert(self.assignmentIcons, classIcon)
                        
                        if not tank.inRaid then
                            -- Tank not in raid - use not available icon
                            classIcon:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
                            classIcon:SetWidth(14)
                            classIcon:SetHeight(14)
                            classIcon:SetPoint("LEFT", currentXPos, "RIGHT", 3, 0)
                        elseif tank.class and self.CLASS_COORDS and self.CLASS_COORDS[tank.class] then
                            -- Tank in raid with known class - use class icon
                            local coords = self.CLASS_COORDS[tank.class]
                            classIcon:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
                            classIcon:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
                            classIcon:SetWidth(14)
                            classIcon:SetHeight(14)
                            classIcon:SetPoint("LEFT", currentXPos, "RIGHT", 3, 0)
                            -- Apply red tint if player is offline
                            if not tank.online then
                                classIcon:SetVertexColor(0.5, 0.5, 0.5) -- Gray for offline
                            elseif not tank.inRaid then
                                classIcon:SetVertexColor(1.0, 0.3, 0.3) -- Red for not in raid
                            end
                        end
                        currentXPos = classIcon
                        
                        -- Add tank name
                        local tankText = lineContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                        tankText:SetPoint("LEFT", currentXPos, "RIGHT", 3, 0)
                        tankText:SetText(tank.name)
                        
                        if TWRA.UI and TWRA.UI.ApplyClassColoring then
                            TWRA.UI:ApplyClassColoring(tankText, 
                                self:SafeGetTankProperty(tank, "name", ""), 
                                self:SafeGetTankProperty(tank, "class", ""),
                                self:SafeGetTankProperty(tank, "inRaid", false),
                                self:SafeGetTankProperty(tank, "online", false))
                        else
                            -- Fallback if UI utils not available
                            TWRA:ApplyPlayerNameColoring(tankText, 
                                self:SafeGetTankProperty(tank, "name", ""), 
                                self:SafeGetTankProperty(tank, "class", ""),
                                self:SafeGetTankProperty(tank, "inRaid", false),
                                self:SafeGetTankProperty(tank, "online", false))
                        end
                        
                        currentXPos = tankText
                    end
                    
                    -- Add "tanking" text after all tanks
                    local tankingText = lineContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                    tankingText:SetPoint("LEFT", currentXPos, "RIGHT", 5, 0)
                    tankingText:SetText("tanking")
                    tankingText:SetTextColor(0.8, 0.8, 0.8) -- Slightly dimmer
                    currentXPos = tankingText
                    
                    -- Add raid target icon if available (before target name)
                    if rowInfo.icon and rowInfo.icon ~= "" and self.ICONS and self.ICONS[rowInfo.icon] then
                        local iconInfo = self.ICONS[rowInfo.icon]
                        local targetIcon = lineContainer:CreateTexture(nil, "OVERLAY")
                        targetIcon:SetTexture(iconInfo[1])
                        targetIcon:SetTexCoord(iconInfo[2], iconInfo[3], iconInfo[4], iconInfo[5])
                        targetIcon:SetWidth(16) -- Original size (not increased)
                        targetIcon:SetHeight(16) -- Original size (not increased)
                        targetIcon:SetPoint("LEFT", currentXPos, "RIGHT", 5, 0)
                        table.insert(self.assignmentIcons, targetIcon)
                        currentXPos = targetIcon
                    end
                    
                    local targetText = lineContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                    targetText:SetPoint("LEFT", currentXPos, "RIGHT", 3, 0)
                    targetText:SetText(rowInfo.target)
                    targetText:SetTextColor(1, 1, 1)
                    currentXPos = targetText
                else
                    -- No tank info - just show target with raid icon
                    if rowInfo.icon and rowInfo.icon ~= "" and self.ICONS and self.ICONS[rowInfo.icon] then
                        local iconInfo = self.ICONS[rowInfo.icon]
                        local targetIcon = lineContainer:CreateTexture(nil, "OVERLAY")
                        targetIcon:SetTexture(iconInfo[1])
                        targetIcon:SetTexCoord(iconInfo[2], iconInfo[3], iconInfo[4], iconInfo[5])
                        targetIcon:SetWidth(16) -- Original size (not increased)
                        targetIcon:SetHeight(16) -- Original size (not increased)
                        targetIcon:SetPoint("LEFT", currentXPos, "RIGHT", 5, 0)
                        table.insert(self.assignmentIcons, targetIcon)
                        currentXPos = targetIcon
                    end
                    
                    local targetText = lineContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                    targetText:SetPoint("LEFT", currentXPos, "RIGHT", 3, 0)
                    targetText:SetText(rowInfo.target)
                    targetText:SetTextColor(1, 1, 1)
                    currentXPos = targetText
                end
            else
                -- ORIGINAL LAYOUT FOR NON-HEALERS (Tanks and DPS)
                -- Add target name
                local targetText = lineContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                targetText:SetPoint("LEFT", currentXPos, "RIGHT", 5, 0)
                targetText:SetText(rowInfo.target)
                targetText:SetTextColor(1, 1, 1)
                currentXPos = targetText
                
                -- If player is not a tank, list the tanks
                if not rowInfo.isPlayerTank and table.getn(rowInfo.tanks) > 0 then
                    -- Add "tanked by" text
                    local tankedByText = lineContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                    tankedByText:SetPoint("LEFT", currentXPos, "RIGHT", 5, 0)
                    tankedByText:SetText("tanked by")
                    tankedByText:SetTextColor(0.8, 0.8, 0.8) -- Slightly dimmer
                    currentXPos = tankedByText
                    
                    -- Add each tank with class icon and color
                    for j, tank in ipairs(rowInfo.tanks) do
                        -- Add separator if needed
                        if j > 1 then
                            local separator = lineContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                            separator:SetPoint("LEFT", currentXPos, "RIGHT", 3, 0)
                            if j == table.getn(rowInfo.tanks) then
                                separator:SetText(" and ")
                            else
                                separator:SetText(", ")
                            end
                            separator:SetTextColor(0.8, 0.8, 0.8)
                            currentXPos = separator
                        end
                        
                        -- Add class icon for tank (or not available icon)
                        local classIcon = lineContainer:CreateTexture(nil, "OVERLAY")
                        table.insert(self.assignmentIcons, classIcon)
                        
                        if not tank.inRaid then
                            -- Tank not in raid - use not available icon
                            classIcon:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
                            classIcon:SetWidth(14)
                            classIcon:SetHeight(14)
                            classIcon:SetPoint("LEFT", currentXPos, "RIGHT", 3, 0)
                        elseif tank.class and self.CLASS_COORDS and self.CLASS_COORDS[tank.class] then
                            -- Tank in raid with known class - use class icon
                            local coords = self.CLASS_COORDS[tank.class]
                            classIcon:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
                            classIcon:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
                            classIcon:SetWidth(14)
                            classIcon:SetHeight(14)
                            classIcon:SetPoint("LEFT", currentXPos, "RIGHT", 3, 0)
                            -- Apply red tint if player is offline
                            if not tank.online then
                                classIcon:SetVertexColor(0.5, 0.5, 0.5) -- Gray for offline
                            elseif not tank.inRaid then
                                classIcon:SetVertexColor(1.0, 0.3, 0.3) -- Red for not in raid
                            end
                        end
                        currentXPos = classIcon
                        
                        -- Add colored tank name
                        local tankName = lineContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                        tankName:SetPoint("LEFT", currentXPos, "RIGHT", 3, 0)
                        tankName:SetText(tank.name)
                        
                        if TWRA.UI and TWRA.UI.ApplyClassColoring then
                            TWRA.UI:ApplyClassColoring(tankName, 
                                self:SafeGetTankProperty(tank, "name", ""), 
                                self:SafeGetTankProperty(tank, "class", ""),
                                self:SafeGetTankProperty(tank, "inRaid", false),
                                self:SafeGetTankProperty(tank, "online", false))
                        else
                            -- Fallback if UI utils not available
                            TWRA:ApplyPlayerNameColoring(tankName, 
                                self:SafeGetTankProperty(tank, "name", ""), 
                                self:SafeGetTankProperty(tank, "class", ""),
                                self:SafeGetTankProperty(tank, "inRaid", false),
                                self:SafeGetTankProperty(tank, "online", false))
                        end
                        
                        currentXPos = tankName
                    end
                end
                
                -- If player is a tank, list other tanks and healers
                if rowInfo.isPlayerTank then
                    -- List other tanks if any
                    if table.getn(rowInfo.tanks) > 0 then
                        -- Add "along with" text
                        local alongWithText = lineContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                        alongWithText:SetPoint("LEFT", currentXPos, "RIGHT", 5, 0)
                        alongWithText:SetText("along with")
                        alongWithText:SetTextColor(0.8, 0.8, 0.8) -- Slightly dimmer
                        currentXPos = alongWithText
                        
                        -- Add each tank with class icon and color
                        for j, tank in ipairs(rowInfo.tanks) do
                            -- Add separator if needed
                            if j > 1 then
                                local separator = lineContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                                separator:SetPoint("LEFT", currentXPos, "RIGHT", 3, 0)
                                if j == table.getn(rowInfo.tanks) then
                                    separator:SetText(" and ")
                                else
                                    separator:SetText(", ")
                                end
                                separator:SetTextColor(0.8, 0.8, 0.8)
                                currentXPos = separator
                            end
                            
                            -- Add class icon for tank (or not available icon)
                            local classIcon = lineContainer:CreateTexture(nil, "OVERLAY")
                            table.insert(self.assignmentIcons, classIcon)
                            
                            if not tank.inRaid then
                                -- Tank not in raid - use not available icon
                                classIcon:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
                                classIcon:SetWidth(14)
                                classIcon:SetHeight(14)
                                classIcon:SetPoint("LEFT", currentXPos, "RIGHT", 3, 0)
                            elseif tank.class and self.CLASS_COORDS and self.CLASS_COORDS[tank.class] then
                                -- Tank in raid with known class - use class icon
                                local coords = self.CLASS_COORDS[tank.class]
                                classIcon:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
                                classIcon:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
                                classIcon:SetWidth(14)
                                classIcon:SetHeight(14)
                                classIcon:SetPoint("LEFT", currentXPos, "RIGHT", 3, 0)
                                -- Apply color tint based on status
                                if not tank.online then
                                    classIcon:SetVertexColor(0.5, 0.5, 0.5) -- Gray for offline
                                elseif not tank.inRaid then
                                    classIcon:SetVertexColor(1.0, 0.3, 0.3) -- Red for not in raid
                                end
                            end
                            currentXPos = classIcon
                            
                            -- Add colored tank name
                            local tankName = lineContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                            tankName:SetPoint("LEFT", currentXPos, "RIGHT", 3, 0)
                            tankName:SetText(tank.name)
                            
                            if TWRA.UI and TWRA.UI.ApplyClassColoring then
                                TWRA.UI:ApplyClassColoring(tankName, 
                                    self:SafeGetTankProperty(tank, "name", ""), 
                                    self:SafeGetTankProperty(tank, "class", ""),
                                    self:SafeGetTankProperty(tank, "inRaid", false),
                                    self:SafeGetTankProperty(tank, "online", false))
                            else
                                -- Fallback if UI utils not available
                                TWRA:ApplyPlayerNameColoring(tankName, 
                                    self:SafeGetTankProperty(tank, "name", ""), 
                                    self:SafeGetTankProperty(tank, "class", ""),
                                    self:SafeGetTankProperty(tank, "inRaid", false),
                                    self:SafeGetTankProperty(tank, "online", false))
                            end
                            
                            currentXPos = tankName
                        end
                    end
                    
                    -- List healers if any
                    if table.getn(rowInfo.healers) > 0 then
                        -- Add "healed by" text
                        local healedByText = lineContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                        healedByText:SetPoint("LEFT", currentXPos, "RIGHT", 5, 0)
                        healedByText:SetText("healed by")
                        healedByText:SetTextColor(0.8, 0.8, 0.8) -- Slightly dimmer
                        currentXPos = healedByText
                        
                        -- Add each healer with class icon and color
                        for j, healer in ipairs(rowInfo.healers) do
                            -- Add separator if needed
                            if j > 1 then
                                local separator = lineContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                                separator:SetPoint("LEFT", currentXPos, "RIGHT", 3, 0)
                                if j == table.getn(rowInfo.healers) then
                                    separator:SetText(" and ")
                                else
                                    separator:SetText(", ")
                                end
                                separator:SetTextColor(0.8, 0.8, 0.8)
                                currentXPos = separator
                            end
                            
                            -- Add class icon for healer
                            local classIcon = lineContainer:CreateTexture(nil, "OVERLAY")
                            table.insert(self.assignmentIcons, classIcon)
                            
                            if not healer.inRaid then
                                -- Healer not in raid - use not available icon
                                classIcon:SetTexture("Interface\\Buttons\\UI-GroupLoot-Pass-Up")
                                classIcon:SetWidth(14)
                                classIcon:SetHeight(14)
                                classIcon:SetPoint("LEFT", currentXPos, "RIGHT", 3, 0)
                            elseif healer.class and self.CLASS_COORDS and self.CLASS_COORDS[healer.class] then
                                -- Healer in raid with known class - use class icon
                                local coords = self.CLASS_COORDS[healer.class]
                                classIcon:SetTexture("Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes")
                                classIcon:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
                                classIcon:SetWidth(14)
                                classIcon:SetHeight(14)
                                classIcon:SetPoint("LEFT", currentXPos, "RIGHT", 3, 0)
                                -- Apply color tint based on status
                                if not healer.online then
                                    classIcon:SetVertexColor(0.5, 0.5, 0.5) -- Gray for offline
                                elseif not healer.inRaid then
                                    classIcon:SetVertexColor(1.0, 0.3, 0.3) -- Red for not in raid
                                end
                            end
                            currentXPos = classIcon
                            
                            -- Add colored healer name
                            local healerName = lineContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                            healerName:SetPoint("LEFT", currentXPos, "RIGHT", 3, 0)
                            healerName:SetText(healer.name)
                            
                            if TWRA.UI and TWRA.UI.ApplyClassColoring then
                                TWRA.UI:ApplyClassColoring(healerName, 
                                    self:SafeGetTankProperty(healer, "name", ""), 
                                    self:SafeGetTankProperty(healer, "class", ""),
                                    self:SafeGetTankProperty(healer, "inRaid", false),
                                    self:SafeGetTankProperty(healer, "online", false))
                            else
                                -- Fallback if UI utils not available
                                TWRA:ApplyPlayerNameColoring(healerName, 
                                    self:SafeGetTankProperty(healer, "name", ""), 
                                    self:SafeGetTankProperty(healer, "class", ""),
                                    self:SafeGetTankProperty(healer, "inRaid", false),
                                    self:SafeGetTankProperty(healer, "online", false))
                            end
                            
                            currentXPos = healerName
                        end
                    end
                end
            end
        end
    end
    
    -- Add warnings if any
    if table.getn(warnings) > 0 then
        self.warningIcon:Show()
        self.sectionOverlayWarning:SetText(table.concat(warnings, "\n"))
    end
    
    -- Add notes if any
    if table.getn(notes) > 0 then
        self.noteIcon:Show()
        self.sectionOverlayNote:SetText(table.concat(notes, "\n"))
    end
    
    -- Adjust the height of the info container based on the total content height
    self.sectionOverlayInfo:SetHeight(totalHeight)
end

-- Fix the syntax error in the for loop around line 631-679
-- Section where colorization occurs
if TWRA.UI and TWRA.UI.ApplyClassColoring then
    TWRA.UI:ApplyClassColoring(tankName, tank.name, tank.class, tank.inRaid, tank.online)
else
    -- Fallback if UI utils not available
    TWRA:ApplyPlayerNameColoring(tankName, tank.name, tank.class, tank.inRaid, tank.online)
end

currentXPos = tankName

-- Add fallback ApplyPlayerNameColoring method if not already defined
function TWRA:ApplyPlayerNameColoring(textElement, playerName, playerClass, isInRaid, isOnline)
    -- Safe checks for parameters
    if not textElement or not playerName then return end
    
    -- Default colors
    local r, g, b = 1, 1, 1 -- Default white
    
    -- Apply coloring based on status
    if not isInRaid then
        -- Red for not in raid
        r, g, b = 1, 0.3, 0.3
    elseif not isOnline then
        -- Gray for offline
        r, g, b = 0.5, 0.5, 0.5
    elseif playerClass and self.VANILLA_CLASS_COLORS and self.VANILLA_CLASS_COLORS[playerClass] then
        -- Class color
        local color = self.VANILLA_CLASS_COLORS[playerClass]
        r, g, b = color.r, color.g, color.b
    end
    
    -- Apply the color to the text element
    if textElement.SetTextColor then
        textElement:SetTextColor(r, g, b)
    end
end

-- Add this function to safely access tank properties
function TWRA:SafeGetTankProperty(tankObj, propertyName, defaultValue)
    if not tankObj then
        return defaultValue
    end
    
    return tankObj[propertyName] or defaultValue
end

-- Then use this in the problematic area where tank is being indexed
-- Replace references like tank.name with:
-- TWRA:SafeGetTankProperty(tank, "name", "")
