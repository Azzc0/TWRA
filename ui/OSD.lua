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

    -- FIX: Create minimap button with delay to ensure all dependencies are loaded
    self:ScheduleTimer(function()
        self:Debug("osd", "Creating minimap button...")
        self:CreateMinimapButton()
    end, 1)
    
    -- Register message handlers
    self:RegisterMessageHandler("SECTION_CHANGED", function(sectionName, currentIndex, totalSections, context)
        self:HandleSectionChange(sectionName, currentIndex, totalSections, context)
    end)
    
    self:RegisterMessageHandler("SHOW_OSD", function(sectionName, currentIndex, totalSections, persistent)
        self:ShowSectionNameOverlay(sectionName, currentIndex, totalSections, persistent)
    end)
    
    self:RegisterMessageHandler("TEST_OSD", function()
        self:TestOSD()
    end)
    
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
        DEFAULT_CHAT_FRAME:AddMessage("TWRA Debug: Creating section overlay frame")
        
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
    
    DEFAULT_CHAT_FRAME:AddMessage("TWRA Debug: Showing section OSD with section: " .. (sectionName or "Unknown"))
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
        DEFAULT_CHAT_FRAME:AddMessage("TWRA: OSD shown (persistent)")
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
        DEFAULT_CHAT_FRAME:AddMessage("TWRA Debug: No assignment data available for OSD")
        return
    end
    
    local playerName = UnitName("player")
    local _, playerClass = UnitClass("player")
    DEFAULT_CHAT_FRAME:AddMessage("TWRA Debug: Looking up OSD content for " .. playerName .. 
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
                DEFAULT_CHAT_FRAME:AddMessage("TWRA Debug: Found class group name: " .. group)
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
                DEFAULT_CHAT_FRAME:AddMessage("TWRA Debug: Found header row at index " .. i)
            elseif row[2] == "Warning" then
                table.insert(warnings, row[3])
                DEFAULT_CHAT_FRAME:AddMessage("TWRA Debug: Found warning: " .. row[3])
            elseif row[2] == "Note" then
                table.insert(notes, row[3])
                DEFAULT_CHAT_FRAME:AddMessage("TWRA Debug: Found note: " .. row[3])
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
                        DEFAULT_CHAT_FRAME:AddMessage("TWRA Debug: Found player match in column " .. col .. 
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
                    DEFAULT_CHAT_FRAME:AddMessage("TWRA Debug: Found relevant row - Target: " .. row[3])
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
                        
                        -- Use our coloring function instead of inline color setting
                            TWRA.UI:ApplyClassColoring(tankName, tank.name, tank.class, tank.inRaid, tank.online)
                        else
                            -- Fallback if UI utils not available
                            self:ApplyPlayerNameColoring(tankName, tank.name, tank.class, tank.inRaid, tank.online)
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
                            TWRA.UI:ApplyClassColoring(tankName, tank.name, tank.class, tank.inRaid, tank.online)
                        else
                            -- Fallback if UI utils not available
                            self:ApplyPlayerNameColoring(tankName, tank.name, tank.class, tank.inRaid, tank.online)
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
                                TWRA.UI:ApplyClassColoring(tankName, tank.name, tank.class, tank.inRaid, tank.online)
                            else
                                -- Fallback if UI utils not available
                                self:ApplyPlayerNameColoring(tankName, tank.name, tank.class, tank.inRaid, tank.online)
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
                                TWRA.UI:ApplyClassColoring(healerName, healer.name, healer.class, healer.inRaid, healer.online)
                            else
                                -- Fallback if UI utils not available
                                self:ApplyPlayerNameColoring(healerName, healer.name, healer.class, healer.inRaid, healer.online)
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
                            TWRA.UI:ApplyClassColoring(tankText, tank.name, tank.class, tank.inRaid, tank.online)
                        else
                            -- Fallback if UI utils not available
                            self:ApplyPlayerNameColoring(tankText, tank.name, tank.class, tank.inRaid, tank.online)
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
                            TWRA.UI:ApplyClassColoring(tankName, tank.name, tank.class, tank.inRaid, tank.online)
                        else
                            -- Fallback if UI utils not available
                            self:ApplyPlayerNameColoring(tankName, tank.name, tank.class, tank.inRaid, tank.online)
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
                                TWRA.UI:ApplyClassColoring(tankName, tank.name, tank.class, tank.inRaid, tank.online)
                            else
                                -- Fallback if UI utils not available
                                self:ApplyPlayerNameColoring(tankName, tank.name, tank.class, tank.inRaid, tank.online)
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
                                TWRA.UI:ApplyClassColoring(healerName, healer.name, healer.class, healer.inRaid, healer.online)
                            else
                                -- Fallback if UI utils not available
                                self:ApplyPlayerNameColoring(healerName, healer.name, healer.class, healer.inRaid, healer.online)
                            end
                            
                            currentXPos = healerName
                        end
                    end
                end
            end
            
            -- Store this line container and update total height
            table.insert(contentLines, lineContainer)
            table.insert(self.assignmentIcons, lineContainer)
            totalHeight = totalHeight + lineHeight + 2  -- Add spacing between lines
        end
    else
        -- No assignments found - create a simple "no assignment" line
        local noAssignmentContainer = CreateFrame("Frame", nil, self.sectionOverlay)
        noAssignmentContainer:SetHeight(lineHeight)
        noAssignmentContainer:SetPoint("TOPLEFT", self.sectionOverlayInfo, "TOPLEFT", 0, 0)
        noAssignmentContainer:SetPoint("TOPRIGHT", self.sectionOverlayInfo, "TOPRIGHT", 0, 0)
        
        local noAssignText = noAssignmentContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        noAssignText:SetPoint("LEFT", noAssignmentContainer, "LEFT", 15, 0)
        noAssignText:SetText("No specific assignment")
        noAssignText:SetTextColor(0.8, 0.8, 0.8) -- Gray text
        
        table.insert(contentLines, noAssignmentContainer)
        table.insert(self.assignmentIcons, noAssignmentContainer)
        totalHeight = lineHeight
    end
    
    -- Resize the info container to fit the content
    self.sectionOverlayInfo:SetHeight(totalHeight)
    
    -- Display warning if any
    if table.getn(warnings) > 0 then
        self.sectionOverlayWarning:SetText(warnings[1])
        self.warningIcon:Show()
        DEFAULT_CHAT_FRAME:AddMessage("TWRA Debug: Showing warning")
    end
    
    -- Display note if any
    if table.getn(notes) > 0 then
        self.sectionOverlayNote:SetText(notes[1])
        self.noteIcon:Show()
        DEFAULT_CHAT_FRAME:AddMessage("TWRA Debug: Showing note")
    end
    
    -- Adjust container positions based on content
    if warnings[1] then
        self.warningContainer:ClearAllPoints()
        self.warningContainer:SetPoint("TOP", self.sectionOverlayInfo, "BOTTOM", 0, -5)
    end
    
    if notes[1] then
        self.noteContainer:ClearAllPoints()
        if warnings[1] then
            self.noteContainer:SetPoint("TOP", self.warningContainer, "BOTTOM", 0, -2)
        else
            self.noteContainer:SetPoint("TOP", self.sectionOverlayInfo, "BOTTOM", 0, -5)
        end
    end
    
    -- Calculate total height needed for overlay
    local totalOverlayHeight = 70  -- Base height (header + footer space)
    totalOverlayHeight = totalOverlayHeight + totalHeight  -- Add content height
    
    if warnings[1] then
        totalOverlayHeight = totalOverlayHeight + 25  -- Add warning height
    end
    
    if notes[1] then
        totalOverlayHeight = totalOverlayHeight + 25  -- Add note height
    end
    
    -- Update overlay height
    self.sectionOverlay:SetHeight(totalOverlayHeight)
    DEFAULT_CHAT_FRAME:AddMessage("TWRA Debug: Set OSD height to " .. totalOverlayHeight)
end

-- Test the OSD with full content (for test button)
function TWRA:TestOSD()
    local currentIndex = 1
    local totalSections = 5
    local sectionName = "Test Section"
    
    -- Use current section if available
    if self.navigation and self.navigation.currentIndex and self.navigation.handlers then
        currentIndex = self.navigation.currentIndex
        totalSections = table.getn(self.navigation.handlers)
        sectionName = self.navigation.handlers[currentIndex]
    end
    
    -- Make sure we have a section name to display, use a placeholder if necessary
    if not sectionName then
        sectionName = "Test Section"
    end
    
    self:ShowSectionNameOverlay(sectionName, currentIndex, totalSections)
    self:Debug("osd", "Testing OSD with section '" .. sectionName .. "'")
end

-- Reset OSD position to default
function TWRA:ResetOSDPosition()
    self.OSD.point = "CENTER"
    self.OSD.xOffset = 0
    self.OSD.yOffset = 100
    
    -- Save to options
    if TWRA_SavedVariables and TWRA_SavedVariables.options then
        TWRA_SavedVariables.options.osdPoint = self.OSD.point
        TWRA_SavedVariables.options.osdXOffset = self.OSD.xOffset
        TWRA_SavedVariables.options.osdYOffset = self.OSD.yOffset
    end
    
    -- Apply to existing overlay if it exists
    if self.sectionOverlay then
        self.sectionOverlay:ClearAllPoints()
        self.sectionOverlay:SetPoint(self.OSD.point, UIParent, self.OSD.point, self.OSD.xOffset, self.OSD.yOffset)
    end
    
    self:Debug("osd", "OSD position reset to default")
    -- Show test OSD to confirm position
    self:TestOSD()
end

-- Create minimap button
function TWRA:CreateMinimapButton()
    -- Return existing button if already created
    if self.minimapButton and self.minimapButton:GetName() == "TWRAMinimapButton" then 
        self:Debug("osd", "Minimap button already exists")
        -- Make sure it's shown
        self.minimapButton:Show()
        return self.minimapButton
    end
    
    self:Debug("osd", "Creating new minimap button")
    
    -- Create the button frame with a unique name to avoid conflicts
    local button = CreateFrame("Button", "TWRAMinimapButton", Minimap)
    button:SetWidth(32)
    button:SetHeight(32)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(8)
    
    -- Set button appearance
    local icon = button:CreateTexture(nil, "BACKGROUND")
    icon:SetWidth(20)
    icon:SetHeight(20)
    icon:SetPoint("CENTER", button, "CENTER", 0, 0)
    icon:SetTexture("Interface\\FriendsFrame\\FriendsFrameScrollIcon")
    
    -- Add button border
    local overlay = button:CreateTexture(nil, "OVERLAY")
    overlay:SetWidth(53)
    overlay:SetHeight(53)
    overlay:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    overlay:SetPoint("TOPLEFT", button, "TOPLEFT", -10, 10)  -- FIX: Adjust border position
    
    -- Set scripts for showing OSD on hover
    button:SetScript("OnEnter", function()
        -- Show OSD when hovering without starting the auto-hide timer
        self:ShowSectionNameOverlay(nil, nil, nil, true) -- Pass true to indicate persistent display
    end)
    button:SetScript("OnLeave", function()
        -- Hide OSD when mouse leaves the button
        if self.sectionOverlay then
            self.sectionOverlay:Hide()
        end
    end)
    
    -- Left-click to open main frame
    button:SetScript("OnClick", function()
        TWRA:ToggleMainFrame()
    end)
    
    -- Functions to handle drag positioning around the minimap
    local function UpdatePosition(angle)
        -- Position the button based on angle and a set radius from minimap center
        local radius = 80
        local xpos = math.cos(angle) * radius
        local ypos = math.sin(angle) * radius
        button:ClearAllPoints()
        button:SetPoint("CENTER", Minimap, "CENTER", xpos, ypos)
        
        -- Save position
        if TWRA_SavedVariables and TWRA_SavedVariables.options then
            TWRA_SavedVariables.options.minimapAngle = angle
        end
    end
    
    -- Right-click drag handler
    button:RegisterForDrag("RightButton")
    button:SetScript("OnDragStart", function()
        button:StartMoving()
    end)
    button:SetScript("OnDragStop", function()
        button:StopMovingOrSizing()
        
        -- Calculate angle from minimap center
        local x, y = button:GetCenter()
        local minimapX, minimapY = Minimap:GetCenter()
        if not x or not y or not minimapX or not minimapY then return end
            
        local angleRad = math.atan2(y - minimapY, x - minimapX)
        UpdatePosition(angleRad)
    end)
    
    -- Load saved position or set default
    if TWRA_SavedVariables and TWRA_SavedVariables.options and TWRA_SavedVariables.options.minimapAngle then
        UpdatePosition(TWRA_SavedVariables.options.minimapAngle)
    else
        -- Default position at top of minimap
        button:ClearAllPoints()
        button:SetPoint("CENTER", Minimap, "CENTER", 0, 80)
    end
    
    -- Store button reference
    self.minimapButton = button
    
    -- Set initial visibility based on options
    if TWRA_SavedVariables and TWRA_SavedVariables.options and TWRA_SavedVariables.options.hideMinimapButton then
        self:Debug("osd", "Minimap button hidden per saved options")
        button:Hide()
    else
        -- Explicitly show the button
        self:Debug("osd", "Showing minimap button")
        button:Show()
    end
    
    return button
end

-- Show sync progress in the OSD
function TWRA:ShowSyncProgressInOSD(progress, sender)
    -- Create the sync OSD if it doesn't exist
    if not self.syncOSD then
        self.syncOSD = CreateFrame("Frame", "TWRA_SyncOSD", UIParent)
        self.syncOSD:SetFrameStrata("HIGH")
        self.syncOSD:SetWidth(300)
        self.syncOSD:SetHeight(80)
        
        -- Add background
        local bg = self.syncOSD:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetTexture(0, 0, 0, 0.7)
        
        -- Add border
        local border = CreateFrame("Frame", nil, self.syncOSD)
        border:SetPoint("TOPLEFT", -2, 2)
        border:SetPoint("BOTTOMRIGHT", 2, -2)
        border:SetBackdrop({
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        
        -- Title text
        self.syncTitle = self.syncOSD:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        self.syncTitle:SetPoint("TOP", self.syncOSD, "TOP", 0, -10)
        self.syncTitle:SetTextColor(0.41, 0.8, 0.94)  -- Light blue color
        self.syncTitle:SetText("Updating Assignments")
        
        -- Source text
        self.syncSource = self.syncOSD:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        self.syncSource:SetPoint("TOP", self.syncTitle, "BOTTOM", 0, -5)
        self.syncSource:SetTextColor(1, 1, 1)
        
        -- Progress background
        local progressBg = self.syncOSD:CreateTexture(nil, "ARTWORK")
        progressBg:SetPoint("TOPLEFT", self.syncOSD, "TOPLEFT", 20, -45)
        progressBg:SetPoint("RIGHT", self.syncOSD, "RIGHT", -20, 0)
        progressBg:SetHeight(20)
        progressBg:SetTexture(0.3, 0.3, 0.3, 0.8)
        self.progressBg = progressBg
        
        -- Progress bar with fixed position
        self.progressBar = self.syncOSD:CreateTexture(nil, "OVERLAY")
        self.progressBar:SetPoint("TOPLEFT", progressBg, "TOPLEFT", 0, 0)
        self.progressBar:SetHeight(progressBg:GetHeight())
        self.progressBar:SetTexture(0.0, 0.44, 0.87, 0.8)  -- Blue color
        
        -- Progress text
        self.progressText = self.syncOSD:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        self.progressText:SetPoint("CENTER", progressBg, "CENTER", 0, 0)
        self.progressText:SetTextColor(1, 1, 1)
        
        -- Apply position and scale settings from regular OSD
        self.syncOSD:ClearAllPoints()
        self.syncOSD:SetPoint(self.OSD.point, UIParent, self.OSD.point, self.OSD.xOffset, self.OSD.yOffset)
        self.syncOSD:SetScale(self.OSD.scale)
        
        -- Make sync OSD also movable (just like the regular OSD)
        self.syncOSD:SetMovable(true)
        self.syncOSD:EnableMouse(true)
        self.syncOSD:RegisterForDrag("LeftButton")
        self.syncOSD:SetScript("OnDragStart", function()
            if not self.OSD.locked then
                self.syncOSD:StartMoving()
            end
        end)
        self.syncOSD:SetScript("OnDragStop", function()
            self.syncOSD:StopMovingOrSizing()
            -- Update position variables
            local point, _, relPoint, xOffset, yOffset = self.syncOSD:GetPoint()
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
    end
    
    -- Update source text
    self.syncSource:SetText("Receiving from " .. sender)
    
    -- FIX: Use SetWidth with a direct percentage calculation
    -- First store the total width
    if not self.progressBgWidth then
        -- Get the width directly
        self.progressBgWidth = self.progressBg:GetWidth() 
        -- If not valid, use a fallback measurement
        if not self.progressBgWidth or self.progressBgWidth <= 0 then
            self.progressBgWidth = 260  -- Fixed fallback width (300 - 40 padding)
        end
    end
    
    -- Calculate progress width based on percentage
    local progressWidth = (self.progressBgWidth * progress) / 100
    -- Apply the width directly
    self.progressBar:SetWidth(progressWidth)
    
    -- Update progress text
    self.progressText:SetText(progress .. "%")
    
    -- Show the sync OSD
    self.syncOSD:Show()
end

-- Hide the sync progress OSD
function TWRA:HideSyncProgressOSD()
    if self.syncOSD then
        self.syncOSD:Hide()
    end
end

-- OSD (On-Screen Display) Implementation for TWRA
TWRA = TWRA or {}
TWRA.UI = TWRA.UI or {}

-- Initialize OSD settings and frame
function TWRA:InitOSD()
    -- Create the OSD namespace if it doesn't exist
    self.OSD = self.OSD or {}
    
    -- Load settings from saved variables
    self.OSD.locked = TWRA_SavedVariables.options.osdLocked or false
    self.OSD.scale = TWRA_SavedVariables.options.osdScale or 1.0
    self.OSD.duration = TWRA_SavedVariables.options.osdDuration or 2
    self.OSD.lines = self.OSD.lines or {}
    
    -- Create the OSD frame if it doesn't exist
    if not self.OSD.frame then
        local frame = CreateFrame("Frame", "TWRA_OSDFrame", UIParent)
        frame:SetFrameStrata("HIGH")
        frame:SetWidth(400)
        frame:SetHeight(100)
        
        -- Set initial position from saved variables or default to center
        if TWRA_SavedVariables.options.osdPoint then
            frame:SetPoint(
                TWRA_SavedVariables.options.osdPoint,
                UIParent,
                TWRA_SavedVariables.options.osdPoint,
                TWRA_SavedVariables.options.osdXOffset or 0,
                TWRA_SavedVariables.options.osdYOffset or 100
            )
        else
            frame:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
        end
        
        -- Set scale
        frame:SetScale(self.OSD.scale)
        
        -- Add background
        local bg = frame:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetTexture(0, 0, 0, 0.7)
        
        -- Add border
        local border = CreateFrame("Frame", nil, frame)
        border:SetPoint("TOPLEFT", -2, 2)
        border:SetPoint("BOTTOMRIGHT", 2, -2)
        border:SetBackdrop({
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        
        -- Create text lines container
        local textContainer = CreateFrame("Frame", nil, frame)
        textContainer:SetPoint("TOPLEFT", 10, -10)
        textContainer:SetPoint("BOTTOMRIGHT", -10, 10)
        
        -- Store frame references
        self.OSD.frame = frame
        self.OSD.bg = bg
        self.OSD.border = border
        self.OSD.textContainer = textContainer
        self.OSD.textLines = {}
        
        -- Make the frame movable
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
            
            -- Save position
            local point, _, _, xOffset, yOffset = this:GetPoint()
            TWRA_SavedVariables.options.osdPoint = point
            TWRA_SavedVariables.options.osdXOffset = xOffset
            TWRA_SavedVariables.options.osdYOffset = yOffset
        end)
        
        -- Initially hide the frame
        frame:Hide()
    end
    
    -- Update OSD lock state
    self:UpdateOSDLock()
    DEFAULT_CHAT_FRAME:AddMessage("TWRA: OSD system initialized")
end

-- Update OSD lock state
function TWRA:UpdateOSDLock()
    if not self.OSD or not self.OSD.frame then return end
    self.OSD.frame:EnableMouse(not self.OSD.locked)
end

-- Reset OSD position to center
function TWRA:ResetOSDPosition()
    if not self.OSD or not self.OSD.frame then return end
    
    -- Reset position
    self.OSD.frame:ClearAllPoints()
    self.OSD.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
    
    -- Save new position
    TWRA_SavedVariables.options.osdPoint = "CENTER"
    TWRA_SavedVariables.options.osdXOffset = 0
    TWRA_SavedVariables.options.osdYOffset = 100
    
    DEFAULT_CHAT_FRAME:AddMessage("TWRA: OSD position reset")
end

-- Toggle OSD visibility
function TWRA:ToggleOSD(show)
    -- Create OSD if it doesn't exist
    if not self.OSD or not self.OSD.frame then
        self:InitOSD()
    end
    
    if show == nil then
        -- Toggle visibility
        show = not self.OSD.frame:IsShown()
    end
    
    if show then
        -- FIX: Always set content when showing OSD
        self:SetDefaultOSDContent()
        self:UpdateOSDContent()
        self.OSD.frame:Show()
    else
        -- Hide the OSD
        self.OSD.frame:Hide()
    end
end

-- FIX: Add function to set default content if none exists
function TWRA:SetDefaultOSDContent()
    -- Make sure OSD structure exists
    self.OSD = self.OSD or {}
    
    -- If no content exists or it's empty, add default content
    if not self.OSD.lines or table.getn(self.OSD.lines) == 0 then
        -- Try to get current section info
        local sectionName, currentIndex, totalSections
        
        if self.navigation and self.navigation.currentIndex and self.navigation.handlers then
            currentIndex = self.navigation.currentIndex
            sectionName = self.navigation.handlers[currentIndex]
            totalSections = table.getn(self.navigation.handlers)
        end
        
        if sectionName then
            -- We have a section, show its info
            self.OSD.lines = {
                { text = sectionName, color = {1, 0.82, 0} },
                { text = "Section " .. (currentIndex or "?") .. " of " .. (totalSections or "?"), color = {1, 1, 1} }
            }
            
            -- Try to find player's assignment
            self:AddPlayerAssignmentToOSD(sectionName)
        else 
            -- No section info available, show default message
            self.OSD.lines = {
                { text = "TWRA OSD", color = {1, 0.82, 0} },
                { text = "No active section selected", color = {1, 1, 1} }
            }
        end
    end
end

-- FIX: Add helper function to find player assignments
function TWRA:AddPlayerAssignmentToOSD(sectionName)
    -- Ensure we have data
    if not self.fullData then return end
    
    local playerName = UnitName("player")
    local _, playerClass = UnitClass("player")
    
    -- Look for player in the current section
    for i, row in ipairs(self.fullData) do
        if row[1] == sectionName then
            -- Skip header rows (with Icon in column 2)
            if row[2] ~= "Icon" then
                for j = 4, table.getn(row) do  -- Start from column 4 (first role)
                    if row[j] == playerName then
                        -- Get role name from header
                        local roleName = "Unknown Role"
                        local targetName = row[3] or "Unknown Target"
                        
                        -- Find header row to get role name
                        for k, headerRow in ipairs(self.fullData) do
                            if headerRow[1] == sectionName and headerRow[2] == "Icon" then
                                roleName = headerRow[j] or "Unknown Role"
                                break
                            end
                        end
                        
                        -- Add assignment to OSD content
                        table.insert(self.OSD.lines, {
                            text = "Your assignment: " .. roleName .. " on " .. targetName,
                            color = {0.8, 1, 0.8}
                        })
                        
                        return  -- Found assignment, exit function
                    end
                end
            end
        end
    end
    
    -- If reached here, no assignment found
    table.insert(self.OSD.lines, {
        text = "No specific assignment found",
        color = {0.8, 0.8, 0.8}
    })
end

-- Update the content displayed in the OSD
function TWRA:UpdateOSDContent()
    if not self.OSD or not self.OSD.frame then return end
    
    -- Clear existing text lines
    for _, line in pairs(self.OSD.textLines or {}) do
        if line then
            line:Hide()
            line:SetParent(nil)
        end
    end
    self.OSD.textLines = {}
    
    -- Create new text lines
    local yOffset = 0
    local lineHeight = 20
    
    -- Determine the maximum height needed
    local contentHeight = table.getn(self.OSD.lines or {}) * lineHeight
    self.OSD.frame:SetHeight(contentHeight + 20) -- Add padding
    
    -- Create text for each line
    for i, lineData in ipairs(self.OSD.lines or {}) do
        local lineText = self.OSD.textContainer:CreateFontString(nil, "OVERLAY", 
            i == 1 and "GameFontNormalLarge" or "GameFontNormal")
        
        lineText:SetPoint("TOP", self.OSD.textContainer, "TOP", 0, yOffset)
        lineText:SetWidth(self.OSD.textContainer:GetWidth())
        lineText:SetText(lineData.text or "")
        lineText:SetJustifyH("CENTER")
        
        -- Set color if provided
        if lineData.color then
            lineText:SetTextColor(lineData.color[1], lineData.color[2], lineData.color[3], lineData.color[4] or 1)
        end
        
        table.insert(self.OSD.textLines, lineText)
        yOffset = yOffset - lineHeight
    end
end

-- Test the OSD
function TWRA:TestOSD()
    -- Set up test content
    self.OSD = self.OSD or {}
    self.OSD.lines = {
        { text = "OSD Test", color = {1, 0.82, 0} },
        { text = "Display working correctly", color = {1, 1, 1} }
    }
    
    -- Show the OSD
    self:ToggleOSD(true)
    
    -- Hide after the configured duration
    local duration = (self.OSD and self.OSD.duration) or 2
    if self.osdHideTimer then
        self:CancelTimer(self.osdHideTimer)
    end
    
    self.osdHideTimer = self:ScheduleTimer(function() 
        self:ToggleOSD(false)
    end, duration)
end

-- Show section navigation in OSD
function TWRA:ShowOSD(sectionName, currentIndex, totalSections)
    -- Create OSD if it doesn't exist
    if not self.OSD or not self.OSD.frame then
        self:InitOSD()
    end
    
    self.OSD = self.OSD or {}
    self.OSD.lines = {
        { text = sectionName or "Unknown Section", color = {1, 0.82, 0} },
    }
    
    -- Add section count if provided
    if currentIndex and totalSections then
        table.insert(self.OSD.lines, 
            { text = "Section " .. currentIndex .. " of " .. totalSections, color = {1, 1, 1} })
    end
    
    -- Add player's assignment if available
    if sectionName then
        self:AddPlayerAssignmentToOSD(sectionName)
    end
    
    -- Show the OSD
    self:ToggleOSD(true)
    
    -- Hide after the configured duration
    local duration = (self.OSD and self.OSD.duration) or 2
    if self.osdHideTimer then
        self:CancelTimer(self.osdHideTimer)
    end
    
    self.osdHideTimer = self:ScheduleTimer(function() 
        self:ToggleOSD(false)
    end, duration)
end

-- REMOVE: Apply class colors to text
function TWRA:ApplyPlayerNameColoring(nameElement, playerName, playerClass, isInRaid, isOnline)
    -- This should be replaced with:
    -- if TWRA.UI and TWRA.UI.ApplyClassColoring then
    --     TWRA.UI:ApplyClassColoring(nameElement, playerName, playerClass, isInRaid, isOnline)
    -- end
end

-- Fix the function with proper structure to close the for loop
function TWRA:ProcessTarget(unitID)
    -- Get the unit's raid target marker
    local index = GetRaidTargetIndex(unitID)
    if not index then return end
    
    -- Get the marker name from the index
    local markerName = self.GetMarkerNameFromIndex(index)
    if not markerName then return end
    
    -- Check if we can get the target NPC name
    local targetName = UnitName(unitID)
    if not targetName then return end
    
    -- Skip non-NPC targets
    if UnitIsPlayer(unitID) then return end
    
    -- Find sections with this target and marker
    for sectionName, sectionData in pairs(self.cachedMarkerData) do
        for iconName, targets in pairs(sectionData) do
            if iconName == markerName then
                for _, targetData in ipairs(targets) do
                    -- Check if target name matches
                    if targetData.name == targetName then
                        -- We found a match - navigate to this section
                        if sectionName ~= self.lastMatchedSection then
                            self:Debug("auto", "Found match for " .. markerName .. " " .. targetName .. " in section " .. sectionName)
                            self.lastMatchedSection = sectionName
                            
                            -- Navigate to this section
                            self:NavigateToSection(sectionName)
                            return true
                        end
                        return false -- Already on this section
                    end
                end
            end
        end
    end
    
    -- No match found
    return false
end