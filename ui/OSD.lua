-- TWRA On-Screen Display (OSD) Module
-- Phase 0: Visual Prototype based on the OSD-plan.md document

TWRA = TWRA or {}
TWRA.OSD = TWRA.OSD or {}

-- Initialize OSD settings and structure
function TWRA:InitOSD()
    -- Skip if already initialized
    if self.OSD and self.OSD.initialized then
        self:Debug("osd", "OSD already initialized")
        return true
    end

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
        self.OSD.showNotes = savedOSD.showNotes ~= false -- Default to true if nil
    end

    -- Register for events
    if self.RegisterEvent then
        self:Debug("osd", "Registering OSD event handlers")
        
        -- Register for section navigation events
        self:RegisterEvent("SECTION_CHANGED", function(sectionName, currentIndex, totalSections)
            self:Debug("osd", "SECTION_CHANGED event received: " .. sectionName)
            
            -- Check if we're navigating to the same section
            if self.OSD.lastSectionIndex and self.OSD.lastSectionIndex == currentIndex then
                self:Debug("osd", "Same section detected: " .. sectionName .. " (index " .. currentIndex .. ")")
                
                -- Still update content even if it's the same section
                -- This ensures data consistency if something else changed
                self:UpdateOSDContent(sectionName, currentIndex, totalSections)
                return
            end
            
            -- Store the current section index for future comparison
            self.OSD.lastSectionIndex = currentIndex
            
            -- Always update the OSD content regardless of visibility
            -- This ensures that data is current whenever the OSD is displayed
            self:UpdateOSDContent(sectionName, currentIndex, totalSections)
            
            -- Only show the OSD if conditions are met
            if self.ShouldShowOSD and self:ShouldShowOSD() then
                -- If OSD is already visible in permanent mode, don't change its state
                if self.OSD.isVisible and self.OSD.isPermanent then
                    self:Debug("osd", "OSD already in permanent display mode, leaving as is")
                else
                    -- Show the OSD with auto-hide (non-permanent mode)
                    self:ShowOSD()
                end
            end
        end, "OSD")
        
        -- Register for group roster updates
        self:RegisterEvent("GROUP_ROSTER_UPDATED", function()
            self:Debug("osd", "GROUP_ROSTER_UPDATED event received")
            
            -- Always update OSD content on group changes, regardless of visibility
            -- This ensures that when the OSD is shown, it has current data
            if self.navigation and self.navigation.currentIndex and self.navigation.handlers then
                local sectionName = self.navigation.handlers[self.navigation.currentIndex]
                local currentIndex = self.navigation.currentIndex
                local totalSections = table.getn(self.navigation.handlers)
                self:UpdateOSDContent(sectionName, currentIndex, totalSections)
                self:Debug("osd", "Updated OSD content after group change")
            end
        end, "OSD")
        
        -- Register for player status updates
        self:RegisterEvent("PLAYERS_UPDATED", function()
            self:Debug("osd", "PLAYERS_UPDATED event received")
            
            -- Always update OSD content on player changes, regardless of visibility
            -- This ensures that when the OSD is shown, it has current data
            if self.navigation and self.navigation.currentIndex and self.navigation.handlers then
                local sectionName = self.navigation.handlers[self.navigation.currentIndex]
                local currentIndex = self.navigation.currentIndex
                local totalSections = table.getn(self.navigation.handlers)
                
                self:Debug("osd", "Updating OSD content due to player changes")
                self:UpdateOSDContent(sectionName, currentIndex, totalSections)
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
    frame:EnableMouse(true) -- Always enable mouse so we can detect hover, even when locked
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function() 
        if not TWRA.OSD.locked then
            this:StartMoving()
        end 
    end)
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
    
    -- Add mouse enter/leave scripts to pause/resume timer
    frame:SetScript("OnEnter", function()
        TWRA:Debug("osd", "Mouse entered OSD frame")
        
        -- Debug current timer state
        TWRA:Debug("osd", "Timer state: autoHideTimer=" .. 
                  (TWRA.OSD.autoHideTimer and "exists" or "nil") .. 
                  ", isPermanent=" .. tostring(TWRA.OSD.isPermanent or false) .. 
                  ", isVisible=" .. tostring(TWRA.OSD.isVisible or false))
        
        -- Cancel any active timer and store that this was originally not permanent
        if TWRA.OSD.isVisible and not TWRA.OSD.isPermanent and TWRA.OSD.autoHideTimer then
            -- Store original state to know we need to restore the timer when mouse leaves
            TWRA.OSD.wasTemporary = true
            
            -- Cancel the timer
            TWRA:CancelTimer(TWRA.OSD.autoHideTimer)
            TWRA.OSD.autoHideTimer = nil
            
            -- Make OSD permanent while mouse is over
            TWRA.OSD.isPermanent = true
            
            TWRA:Debug("osd", "Paused auto-hide timer by setting OSD to permanent mode")
        end
        
        -- Display cursor position for debugging
        local x, y = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        TWRA:Debug("osd", "Mouse position: " .. math.floor(x/scale) .. ", " .. math.floor(y/scale))
    end)
    
    frame:SetScript("OnLeave", function()
        TWRA:Debug("osd", "Mouse left OSD frame")
        
        -- Only restore timer if we previously set it to permanent (wasTemporary flag)
        if TWRA.OSD.isVisible and TWRA.OSD.wasTemporary and TWRA.OSD.isPermanent then
            -- Restore non-permanent state
            TWRA.OSD.isPermanent = false
            TWRA.OSD.wasTemporary = nil
            
            -- Create a new timer with the default duration
            TWRA.OSD.autoHideTimer = TWRA:ScheduleTimer(function()
                -- Only hide if the OSD is still in temporary mode
                if TWRA.OSD.isVisible and not TWRA.OSD.isPermanent then
                    TWRA:Debug("osd", "Auto-hide timer completed after resuming")
                    TWRA:HideOSD()
                end
                TWRA.OSD.autoHideTimer = nil
            end, TWRA.OSD.duration or 6)
            
            TWRA:Debug("osd", "Restored auto-hide timer with " .. 
                      (TWRA.OSD.duration or 6) .. "s delay")
        else
            -- Debug why we're not resuming
            if not TWRA.OSD.isVisible then
                TWRA:Debug("osd", "OSD is not visible, no timer to resume")
            elseif not TWRA.OSD.wasTemporary then
                TWRA:Debug("osd", "OSD was not temporarily set to permanent, not changing state")
            elseif not TWRA.OSD.isPermanent then
                TWRA:Debug("osd", "OSD is not in permanent mode, no state to restore")
            end
        end
        
        -- Display cursor position for debugging
        local x, y = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        TWRA:Debug("osd", "Mouse position: " .. math.floor(x/scale) .. ", " .. math.floor(y/scale))
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
        if TWRA_Assignments and TWRA_Assignments.currentSectionName then
            sectionTitle = TWRA_Assignments.currentSectionName
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

    -- Generate warnings and notes
    self:CreateWarnings(footerContainer)

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
    
    -- Get role icon path based on role using TWRA:GetRoleIcon
    local iconPath = self:GetRoleIcon(role)
    
    roleIcon:SetTexture(iconPath)
    roleIcon:SetWidth(16)
    roleIcon:SetHeight(16)
    roleIcon:SetPoint("LEFT", rowFrame, "LEFT", 5, 0)
    
    -- Create role text
    local roleFontString = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    roleFontString:SetPoint("LEFT", roleIcon, "RIGHT", 3, 0)
    
    -- Handle nil role safely by providing a default empty string
    local roleText = role or ""
    if roleText ~= "" then
        roleText = roleText .. " - "
    end
    roleFontString:SetText(roleText)
    roleFontString:SetJustifyH("LEFT")
    
    return roleIcon, roleFontString, 16 -- Return icon width for calculations
end

-- Create initial row elements that are common for all row types
function TWRA:InitializeRow(rowFrame, role)
    -- Create role icon and font string
    local roleIcon, roleFontString, iconWidth = self:CreateRowBaseElements(rowFrame, role)
    
    -- Calculate initial row width starting with left padding + role icon + padding + role text
    local rowWidth = 5 + iconWidth + 3 + roleFontString:GetStringWidth()
    
    return roleIcon, roleFontString, rowWidth
end

-- Create a unified assignment row for both healer and tank/other types
function TWRA:CreateAssignmentRow(rowFrame, roleFontString, roleType, icon, target, tanks, playerData, playerStatus)
    -- Initialize the row with common elements
    local _, _, rowWidth = self:InitializeRow(rowFrame, nil)
    
    -- Different row layouts based on role type
    if roleType == "healer" then
        -- HEALER FORMAT: [RoleIcon]Heal - [tanks] tanking [target]
        
        local tankElements = {}
        
        -- Check if we have any tanks assigned
        if table.getn(tanks) > 0 then
            -- Add all tanks with their class icons
            for t = 1, table.getn(tanks) do
                local tankName = tanks[t]
                
                -- Get player information
                local inRaid = false
                local isOnline = false
                local tankClass = nil
                
                if self.PLAYERS and self.PLAYERS[tankName] then
                    tankClass = self.PLAYERS[tankName][1]
                    isOnline = self.PLAYERS[tankName][2]
                    inRaid = true
                end
                
                -- Calculate position for tank element based on previous elements
                local anchorFrame
                local xOffset
                
                if t == 1 then
                    -- First tank anchors to roleFontString
                    anchorFrame = roleFontString
                    xOffset = 5
                else
                    -- For subsequent tanks, we need to anchor to the LAST element of the previous tank
                    -- which might be a separator (comma/and) or the tank name itself
                    if tankElements[t-1].separator then
                        anchorFrame = tankElements[t-1].separator
                    else
                        anchorFrame = tankElements[t-1].name
                    end
                    xOffset = 5 -- Use consistent spacing for all tanks
                end
                
                -- Create tank element with proper anchoring
                local tankClassIcon = rowFrame:CreateTexture(nil, "ARTWORK")
                
                -- Set up class icon
                if inRaid and tankClass and self.CLASS_COORDS and self.CLASS_COORDS[string.upper(tankClass)] then
                    tankClassIcon:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
                    local coords = self.CLASS_COORDS[string.upper(tankClass)]
                    tankClassIcon:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
                else
                    -- Default to Missing icon
                    local iconInfo = self.ICONS["Missing"]
                    tankClassIcon:SetTexture(iconInfo[1])
                    tankClassIcon:SetTexCoord(iconInfo[2], iconInfo[3], iconInfo[4], iconInfo[5])
                end
                
                tankClassIcon:SetWidth(14)
                tankClassIcon:SetHeight(14)
                tankClassIcon:SetPoint("LEFT", anchorFrame, "RIGHT", xOffset, 0)
                
                -- Add tank name
                local tankNameText = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                tankNameText:SetPoint("LEFT", tankClassIcon, "RIGHT", 2, 0)
                tankNameText:SetText(tankName)
                
                -- Apply class coloring
                if self.UI and self.UI.ApplyClassColoring then
                    self.UI:ApplyClassColoring(tankNameText, nil, tankClass, inRaid, isOnline)
                else
                    if not inRaid then
                        tankNameText:SetTextColor(1, 0.3, 0.3) -- Red for not in raid
                    elseif not isOnline then
                        tankNameText:SetTextColor(0.5, 0.5, 0.5) -- Gray for offline
                    elseif tankClass and self.VANILLA_CLASS_COLORS then
                        local color = self.VANILLA_CLASS_COLORS[string.upper(tankClass)]
                        if color then
                            tankNameText:SetTextColor(color.r, color.g, color.b)
                        else
                            tankNameText:SetTextColor(1, 1, 1) -- White fallback
                        end
                    else
                        tankNameText:SetTextColor(1, 1, 1) -- White fallback
                    end
                end
                
                -- Store tank elements
                local tankElement = {icon = tankClassIcon, name = tankNameText}
                table.insert(tankElements, tankElement)
                
                -- Update width calculation with tank elements
                local elementWidth = 14 + 2 + tankNameText:GetStringWidth()
                rowWidth = rowWidth + xOffset + elementWidth
                
                -- Add comma or "and" based on position in tank list
                if t < table.getn(tanks) then
                    local separator
                    if t == table.getn(tanks) - 1 then
                        -- Use "and" for the second-to-last tank
                        separator = " and "
                    else
                        -- Use comma for other tanks
                        separator = ", "
                    end
                    
                    local separatorText = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                    separatorText:SetPoint("LEFT", tankNameText, "RIGHT", 1, 0)
                    separatorText:SetText(separator)
                    separatorText:SetTextColor(0.82, 0.82, 0.82) -- Light gray
                    
                    -- Add separator to tank element for proper anchoring
                    tankElements[t].separator = separatorText
                    
                    -- Add separator width to total
                    rowWidth = rowWidth + 1 + separatorText:GetStringWidth()
                end
            end
                
            -- Add "tanking" text after the LAST tank name
            if table.getn(tankElements) > 0 then
                local lastTankElement = tankElements[table.getn(tankElements)]
                local anchorElement = lastTankElement.separator or lastTankElement.name
                
                local tankingText = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                tankingText:SetPoint("LEFT", anchorElement, "RIGHT", 5, 0)
                tankingText:SetText("tanking")
                tankingText:SetTextColor(0.82, 0.82, 0.82) -- Light gray
                
                -- Update width with tanking text
                rowWidth = rowWidth + 5 + tankingText:GetStringWidth()
                    
                -- Add target with icon if available
                rowWidth = rowWidth + self:AddTargetDisplay(rowFrame, tankingText, icon, target, 5)
            end
        else
            -- No tanks assigned, directly show the heal target
            -- Format: [Heal] Heal - [RaidIcon]Target
            rowWidth = rowWidth + self:AddTargetDisplay(rowFrame, roleFontString, icon, target, 5)
        end
    else
        -- TANK/OTHER FORMAT: [RoleIcon]Role - [RaidIcon]Target with [tanks]
        
        -- Add target display first
        local targetAnchor
        local iconInfo = self:GetIconInfo(icon)
        
        if iconInfo then
            -- Set up the target icon
            local targetIcon = rowFrame:CreateTexture(nil, "ARTWORK")
            targetIcon:SetTexture(iconInfo[1])
            targetIcon:SetTexCoord(iconInfo[2], iconInfo[3], iconInfo[4], iconInfo[5])
            targetIcon:SetWidth(16)
            targetIcon:SetHeight(16)
            targetIcon:SetPoint("LEFT", roleFontString, "RIGHT", 0, 0)
            
            -- Add target text to the right of the icon
            local targetText = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            targetText:SetPoint("LEFT", targetIcon, "RIGHT", 2, 0)
            targetText:SetText(target)
            targetAnchor = targetText
            
            -- Add target width to calculation (icon + spacing + text)
            rowWidth = rowWidth + 16 + 2 + targetText:GetStringWidth()
        else
            -- No icon, just display the target text directly after the role
            local targetText = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            targetText:SetPoint("LEFT", roleFontString, "RIGHT", 3, 0)
            targetText:SetText(target)
            targetAnchor = targetText
            
            -- Add target width to calculation (just text with padding)
            rowWidth = rowWidth + 3 + targetText:GetStringWidth()
        end
        
        if table.getn(tanks) > 0 then
            -- Add prefix text based on role (no extra spaces)
            local prefixText = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            prefixText:SetPoint("LEFT", targetAnchor, "RIGHT", 3, 0)
            if roleType == "tank" then
                prefixText:SetText("with")
            else
                prefixText:SetText("tanked by")
            end
            prefixText:SetTextColor(0.82, 0.82, 0.82) -- Light gray
            
            -- Add width of prefix text
            rowWidth = rowWidth + 3 + prefixText:GetStringWidth() + 5
            
            -- Add tank elements
            local lastElement = prefixText
            local tankElements = {}
            
            -- Add tank elements with proper anchoring
            for t = 1, table.getn(tanks) do
                local tankName = tanks[t]
                
                -- Get player information
                local inRaid = false
                local isOnline = false
                local tankClass = nil
                
                if self.PLAYERS and self.PLAYERS[tankName] then
                    tankClass = self.PLAYERS[tankName][1]
                    isOnline = self.PLAYERS[tankName][2]
                    inRaid = true
                end
                
                -- Create the tank element
                local tankClassIcon = rowFrame:CreateTexture(nil, "ARTWORK")
                
                -- Set up class icon
                if inRaid and tankClass and self.CLASS_COORDS and self.CLASS_COORDS[string.upper(tankClass)] then
                    tankClassIcon:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
                    local coords = self.CLASS_COORDS[string.upper(tankClass)]
                    tankClassIcon:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
                else
                    -- Default to Missing icon
                    local iconInfo = self.ICONS["Missing"]
                    tankClassIcon:SetTexture(iconInfo[1])
                    tankClassIcon:SetTexCoord(iconInfo[2], iconInfo[3], iconInfo[4], iconInfo[5])
                end
                
                tankClassIcon:SetWidth(14)
                tankClassIcon:SetHeight(14)
                
                -- Position the tank icon properly
                tankClassIcon:SetPoint("LEFT", lastElement, "RIGHT", 5, 0)
                
                -- Add tank name
                local tankNameText = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                tankNameText:SetPoint("LEFT", tankClassIcon, "RIGHT", 2, 0)
                tankNameText:SetText(tankName)
                
                -- Apply class coloring
                if self.UI and self.UI.ApplyClassColoring then
                    self.UI:ApplyClassColoring(tankNameText, nil, tankClass, inRaid, isOnline)
                else
                    if not inRaid then
                        tankNameText:SetTextColor(1, 0.3, 0.3) -- Red for not in raid
                    elseif not isOnline then
                        tankNameText:SetTextColor(0.5, 0.5, 0.5) -- Gray for offline
                    elseif tankClass and self.VANILLA_CLASS_COLORS then
                        local color = self.VANILLA_CLASS_COLORS[string.upper(tankClass)]
                        if color then
                            tankNameText:SetTextColor(color.r, color.g, color.b)
                        else
                            tankNameText:SetTextColor(1, 1, 1) -- White fallback
                        end
                    else
                        tankNameText:SetTextColor(1, 1, 1) -- White fallback
                    end
                end
                
                -- Store tank elements
                local tankElement = {icon = tankClassIcon, name = tankNameText}
                table.insert(tankElements, tankElement)
                
                -- Update the last element reference
                lastElement = tankNameText
                
                -- Calculate element width for row width tracking
                local elementWidth = 14 + 2 + tankNameText:GetStringWidth()
                rowWidth = rowWidth + 5 + elementWidth
                
                -- Add comma or "and" if not the last tank
                if t < table.getn(tanks) then
                    local separator
                    if t == table.getn(tanks) - 1 then
                        separator = " and "
                    else
                        separator = ", "
                    end
                    
                    local separatorText = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                    separatorText:SetPoint("LEFT", tankNameText, "RIGHT", 1, 0)
                    separatorText:SetText(separator)
                    separatorText:SetTextColor(0.82, 0.82, 0.82) -- Light gray
                    
                    -- Add separator to tank element
                    tankElements[t].separator = separatorText
                    lastElement = separatorText
                    rowWidth = rowWidth + 1 + separatorText:GetStringWidth()
                end
            end
        end
    end
    
    return rowWidth
end

-- Helper function to add target display with optional icon
function TWRA:AddTargetDisplay(rowFrame, anchorElement, icon, target, spacing)
    local rowWidth = 0
    
    -- Check if we have an icon for the target
    local iconInfo = self:GetIconInfo(icon)
    if iconInfo then
        -- Add target raid icon with proper spacing
        local targetIcon = rowFrame:CreateTexture(nil, "ARTWORK")
        targetIcon:SetTexture(iconInfo[1])
        targetIcon:SetTexCoord(iconInfo[2], iconInfo[3], iconInfo[4], iconInfo[5])
        targetIcon:SetWidth(16)
        targetIcon:SetHeight(16)
        targetIcon:SetPoint("LEFT", anchorElement, "RIGHT", spacing, 0)
        
        -- Add target text with reduced spacing
        local targetText = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        targetText:SetPoint("LEFT", targetIcon, "RIGHT", 2, 0)
        targetText:SetText(target)
        
        -- Update width with icon and target text
        rowWidth = spacing + 16 + 2 + targetText:GetStringWidth() + 10 -- Extra padding at end
    else
        -- No icon, just display the target text directly after the anchor
        local targetText = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        targetText:SetPoint("LEFT", anchorElement, "RIGHT", spacing, 0)
        targetText:SetText(target)
        
        -- Update width with just target text
        rowWidth = spacing + targetText:GetStringWidth() + 10 -- Extra padding at end
    end
    
    return rowWidth
end

-- Helper function to get icon information
function TWRA:GetIconInfo(iconName)
    return self.ICONS and self.ICONS[iconName]
end

-- GetRoleIcon returns icon path for a specific role
function TWRA:GetRoleIcon(role)
    if not role then return nil end
    
    -- Convert role to lowercase for case-insensitive matching
    local lowerRole = string.lower(role)
    
    -- Check for direct match in role icons mappings
    if TWRA.ROLE_ICONS_MAPPINGS[lowerRole] then
        local iconName = TWRA.ROLE_ICONS_MAPPINGS[lowerRole]
        if TWRA.ROLE_ICONS[iconName] then
            return TWRA.ROLE_ICONS[iconName]
        end
    end
    
    -- Check for partial match in role icons mappings
    for pattern, iconName in pairs(TWRA.ROLE_ICONS_MAPPINGS) do
        if string.find(lowerRole, string.lower(pattern)) then
            if TWRA.ROLE_ICONS[iconName] then
                return TWRA.ROLE_ICONS[iconName]
            end
        end
    end
    
    -- Default to misc/unknown
    return TWRA.ROLE_ICONS["Misc"]
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
        if currentSection and TWRA_Assignments and TWRA_Assignments.data then
            for _, section in pairs(TWRA_Assignments.data) do
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
    
    -- Use the existing TWRA.PLAYERS table for player info instead of gathering it separately
    local playerData = {}
    local playerStatus = {}
    
    -- Use player data exclusively from the TWRA.PLAYERS table which is maintained elsewhere
    if self.PLAYERS then
        for name, data in pairs(self.PLAYERS) do
            if data and type(data) == "table" and data[1] and data[2] ~= nil then
                playerData[name] = data[1]  -- Class
                playerStatus[name] = {inRaid = true, online = data[2]}  -- Online status
            end
        end
    else
        -- If PLAYERS table is missing, this indicates a more serious problem with the addon
        self:Debug("error", "PLAYERS table not available - this indicates a serious initialization problem")
        -- We won't try to gather data directly as fallback - if PLAYERS is failing, we have bigger issues
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
        
        -- Get role type from entry object
        local roleType = assignment.roleType or "other"
        self:Debug("osd", "Using roleType for " .. role .. ": " .. roleType)
        
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
        
        local rowWidth = self:CreateAssignmentRow(rowFrame, roleFontString, roleType, icon, target, tanks, playerData, playerStatus)
        
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
        self:Debug("osd", "Set OSD width to " .. neededWidth)
        
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

-- Create warnings and notes using real data from the current section
function TWRA:CreateWarnings(footerContainer)
    self:Debug("osd", "Creating warnings and notes from real data")
    
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
        if currentSection and TWRA_Assignments and TWRA_Assignments.data then
            for _, section in pairs(TWRA_Assignments.data) do
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
    local warnings = metadata and metadata["Warning"] or {}
    
    -- Get notes (adding this part)
    local notes = metadata and metadata["Note"] or {}
    
    -- Check if notes should be displayed in OSD
    local showNotesInOSD = true
    if TWRA_SavedVariables and TWRA_SavedVariables.options and 
       TWRA_SavedVariables.options.osd and TWRA_SavedVariables.options.osd.showNotes ~= nil then
        showNotesInOSD = TWRA_SavedVariables.options.osd.showNotes
    end
    
    -- Height of each row and spacing
    local rowHeight = 20
    local rowSpacing = 1 -- 1px spacing between rows
    local totalHeight = 0
    
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
        warningBg:SetHeight(rowHeight)
        
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
        if self.Items and self.Items.EnhancedProcessText then
            processedText = self.Items:EnhancedProcessText(warningText)
            self:Debug("osd", "Processed warning text for item links with EnhancedProcessText")
        elseif self.Items and self.Items.ProcessText then
            processedText = self.Items:ProcessText(warningText)
            self:Debug("osd", "Processed warning text for item links")
        end
        
        -- Create warning text
        local warnText = footerContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        warnText:SetPoint("LEFT", warningIcon, "RIGHT", iconTextGap, 0)
        warnText:SetPoint("RIGHT", warningBg, "RIGHT", -rightPadding, 0)
        warnText:SetHeight(rowHeight)
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
            -- Process the warning text with item links before announcing
            local announcementText = warningText
            if self.Items and self.Items.EnhancedProcessText then
                announcementText = self.Items:EnhancedProcessText(warningText)
            elseif self.Items and self.Items.ProcessText then
                announcementText = self.Items:ProcessText(warningText)
            end
            
            -- Always try raid warning first, then fall back to raid announcement
            -- Ignore channel settings for warnings from OSD
            local success = false
            
            -- Try raid warning first
            if IsRaidOfficer() or IsRaidLeader() then
                SendChatMessage(announcementText, "RAID_WARNING")
                success = true
            end
            
            -- Fall back to raid announcement if raid warning failed
            if not success then
                SendChatMessage(announcementText, "RAID")
            end
            
            -- Visual feedback
            warningBg:SetTexture(0.7, 0.1, 0.1, 0.7)
            self:ScheduleTimer(function()
                if MouseIsOver(clickArea) then
                    warningBg:SetTexture(0.5, 0.1, 0.1, 0.5) -- Hover color
                else
                    warningBg:SetTexture(0.3, 0.1, 0.1, 0.3) -- Original color
                end
            end, 0.2)
        end)
        
        return rowHeight + rowSpacing
    end
    
    -- Helper function to create a single note row
    local function createNoteRow(noteText, yOffset)
        -- Create background
        local noteBg = footerContainer:CreateTexture(nil, "BACKGROUND")
        noteBg:SetTexture(0.1, 0.1, 0.3, 0.15) -- Blue background (similar to Frame.lua)
        noteBg:SetPoint("TOPLEFT", footerContainer, "TOPLEFT", 0, -yOffset)
        noteBg:SetPoint("TOPRIGHT", footerContainer, "TOPRIGHT", 0, -yOffset)
        noteBg:SetHeight(rowHeight)
        
        -- Create note icon (question mark like in Frame.lua)
        local noteIcon = footerContainer:CreateTexture(nil, "OVERLAY")
        local iconInfo = {"Interface\\GossipFrame\\ActiveQuestIcon", 0, 1, 0, 1}
        noteIcon:SetTexture(iconInfo[1])
        noteIcon:SetTexCoord(iconInfo[2], iconInfo[3], iconInfo[4], iconInfo[5])
        noteIcon:SetWidth(16)
        noteIcon:SetHeight(16)
        noteIcon:SetPoint("LEFT", noteBg, "LEFT", leftPadding, 0)
        
        -- Process note text for item links
        local processedText = noteText
        if self.Items and self.Items.EnhancedProcessText then
            processedText = self.Items:EnhancedProcessText(noteText)
        elseif self.Items and self.Items.ProcessText then
            processedText = self.Items:ProcessText(noteText)
        end
        
        -- Create note text
        local noteTextElement = footerContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        noteTextElement:SetPoint("LEFT", noteIcon, "RIGHT", iconTextGap, 0)
        noteTextElement:SetPoint("RIGHT", noteBg, "RIGHT", -rightPadding, 0)
        noteTextElement:SetHeight(rowHeight)
        noteTextElement:SetJustifyH("LEFT")
        
        -- Measure text and truncate if needed
        testString:SetText(processedText)
        local fullTextWidth = testString:GetStringWidth()
        
        -- Truncate text if it's too long
        if fullTextWidth > availableWidth then
            local avgCharWidth = fullTextWidth / string.len(processedText)
            local fitChars = math.floor(availableWidth / avgCharWidth) - 3
            fitChars = math.min(fitChars, string.len(processedText))
            
            local truncatedText = string.sub(processedText, 1, fitChars) .. "..."
            noteTextElement:SetText(truncatedText)
        else
            noteTextElement:SetText(processedText)
        end
        
        -- Set text color
        noteTextElement:SetTextColor(0.85, 0.85, 1) -- Light blue for notes (same as Frame.lua)
        
        -- Make the row clickable to announce to raid chat (not raid warning)
        local clickArea = CreateFrame("Button", nil, footerContainer)
        clickArea:SetAllPoints(noteBg)
        clickArea:SetScript("OnEnter", function()
            noteBg:SetTexture(0.1, 0.1, 0.7, 0.3) -- Highlight on hover
            GameTooltip:SetOwner(clickArea, "ANCHOR_RIGHT")
            GameTooltip:AddLine("Click to announce to raid chat")
            GameTooltip:Show()
        end)
        
        clickArea:SetScript("OnLeave", function()
            noteBg:SetTexture(0.1, 0.1, 0.3, 0.15) -- Original color
            GameTooltip:Hide()
        end)
        
        clickArea:SetScript("OnClick", function()
            -- Process the note text with item links before announcing
            local announcementText = noteText
            if self.Items and self.Items.EnhancedProcessText then
                announcementText = self.Items:EnhancedProcessText(noteText)
            elseif self.Items and self.Items.ProcessText then
                announcementText = self.Items:ProcessText(noteText)
            end
            
            -- For notes, always use raid announcement (no raid warning)
            SendChatMessage(announcementText, "RAID")
            
            -- Visual feedback
            noteBg:SetTexture(0.1, 0.1, 0.7, 0.3) -- Bright blue flash
            self:ScheduleTimer(function()
                if MouseIsOver(clickArea) then
                    noteBg:SetTexture(0.1, 0.1, 0.7, 0.3) -- Hover color
                else
                    noteBg:SetTexture(0.1, 0.1, 0.3, 0.15) -- Original color
                end
            end, 0.2)
        end)
        
        return rowHeight + rowSpacing
    end
    
    -- Create all warning rows first
    for _, warningText in ipairs(warnings) do
        local rowHeight = createWarningRow(warningText, totalHeight)
        totalHeight = totalHeight + rowHeight
    end
    
    -- Then create all note rows if enabled
    if showNotesInOSD then
        for _, noteText in ipairs(notes) do
            local rowHeight = createNoteRow(noteText, totalHeight)
            totalHeight = totalHeight + rowHeight
        end
    end
    
    -- Set footer height based on all rows (subtract the last spacing)
    if totalHeight > 0 then
        totalHeight = totalHeight - rowSpacing -- Remove the last spacing
    end
    footerContainer:SetHeight(totalHeight)
    
    -- Clean up the test string
    testString:Hide()
    
    self:Debug("osd", "Created footer container with " .. table.getn(warnings) .. " warnings and " .. 
               (showNotesInOSD and table.getn(notes) or 0) .. " notes")
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
        if TWRA_Assignments and TWRA_Assignments.currentSectionName then
            sectionTitle = TWRA_Assignments.currentSectionName
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
    
    -- Update warnings and notes with real data
    if frame.footerContainer then
        -- Generate new warnings and notes
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
    self.OSD.isPermanent = true
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
    self.OSD.isPermanent = false
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
        self.OSD.isPermanent = false
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

-- Reset the OSD position to default center values
function TWRA:ResetOSDPosition()
    -- Default position values
    local defaultPoint = "CENTER"
    local defaultXOffset = 0
    local defaultYOffset = 100
    
    -- Update OSD settings
    self.OSD.point = defaultPoint
    self.OSD.xOffset = defaultXOffset
    self.OSD.yOffset = defaultYOffset
    
    -- Save to saved variables
    if TWRA_SavedVariables and TWRA_SavedVariables.options and TWRA_SavedVariables.options.osd then
        TWRA_SavedVariables.options.osd.point = defaultPoint
        TWRA_SavedVariables.options.osd.xOffset = defaultXOffset
        TWRA_SavedVariables.options.osd.yOffset = defaultYOffset
    end
    
    -- Apply new position if frame exists
    if self.OSDFrame then
        self.OSDFrame:ClearAllPoints()
        self.OSDFrame:SetPoint(defaultPoint, UIParent, defaultPoint, defaultXOffset, defaultYOffset)
        self:Debug("osd", "OSD position reset to default center position")
    end
    
    return true
end