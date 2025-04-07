-- TWRA On-Screen Display (OSD) module
TWRA = TWRA or {}

-- Helper function for OSD content debugging
local function debugOSDContent(message)
    if TWRA and TWRA.Debug then
        TWRA:Debug("osd", message)
    end
end

-- Function to prepare OSD data in the requested format with simplified string-based approach
function TWRA:PrepOSD(sectionData)
    -- Initialize assignments namespace
    if not self.assignments then
        self.assignments = {}
    end
    
    -- Initialize the tables for storing data
    self.assignments.notes = {}
    self.assignments.warnings = {}
    self.assignments.osdtable = {}
    
    -- Exit early if no data
    if not sectionData or type(sectionData) ~= "table" or table.getn(sectionData) == 0 then
        self:Debug("osd", "No section data to process")
        return
    end
    
    -- Get player information
    local playerName = UnitName("player")
    local _, playerClass = UnitClass("player")
    local playerGroup = 0
    
    -- Find player's raid group
    if GetNumRaidMembers() > 0 then
        for i = 1, GetNumRaidMembers() do
            local name, _, subgroup = GetRaidRosterInfo(i)
            if name == playerName then
                playerGroup = subgroup
                break
            end
        end
    end
    
    self:Debug("osd", "Looking for assignments for " .. playerName .. " (Group: " .. playerGroup .. ")")
    
    -- Find header row for role names
    local headerRow = nil
    for _, row in ipairs(sectionData) do
        if row[2] == "Icon" then
            headerRow = row
            break
        end
    end
    
    if not headerRow then
        self:Debug("osd", "No header row found in data")
        return
    end
    
    -- First pass: Find tanks for each target
    local targetTanks = {}
    for _, row in ipairs(sectionData) do
        -- Skip header rows, notes, warnings, and GUID rows
        if row[2] ~= "Icon" and row[2] ~= "Note" and row[2] ~= "Warning" and row[2] ~= "GUID" then
            local target = row[3]
            local icon = row[2]
            -- Allow processing even if target is empty, as long as we have an icon
            if (target and target ~= "") or (icon and icon ~= "") then
                -- Use target as key if available, otherwise use icon
                local key = target and target ~= "" and target or icon
                targetTanks[key] = {}
                
                -- Find tank columns by looking at headers
                for colIndex = 4, table.getn(headerRow) do
                    local colHeader = headerRow[colIndex] or ""
                    -- If column header contains "tank" (case insensitive)
                    if string.find(string.lower(colHeader or ""), "tank") then
                        local tankName = row[colIndex]
                        if tankName and tankName ~= "" then
                            table.insert(targetTanks[key], tankName)
                        end
                    end
                end
            end
        end
    end
    
    -- Tracking structure to avoid duplicate target+role combinations
    local assignmentMap = {}
    
    -- Second pass: Find rows relevant to the player, avoiding duplicates
    for rowIndex, row in ipairs(sectionData) do
        -- Skip header rows, notes, warnings, and GUID rows
        if row[2] ~= "Icon" and row[2] ~= "Note" and row[2] ~= "Warning" and row[2] ~= "GUID" then
            local raidIcon = row[2]  -- Can be empty but that's ok
            local target = row[3]    -- Can be empty but that's ok
            
            -- Skip only if both target AND icon are empty
            if (target and target ~= "") or (raidIcon and raidIcon ~= "") then
                -- Check each column for player assignments
                for colIndex = 4, table.getn(row) do
                    local cellValue = row[colIndex]
                    local colHeader = headerRow[colIndex] or ""
                    local isRelevant = false
                    
                    -- Debug cell values
                    self:Debug("osd", "Checking cell value: '" .. tostring(cellValue) .. "', header: '" .. tostring(colHeader) .. "'")
                    
                    -- Check if this cell is for the player
                    if cellValue == playerName then
                        isRelevant = true
                        self:Debug("osd", "Found direct player match: " .. playerName)
                    elseif self.CLASS_GROUP_NAMES and self.CLASS_GROUP_NAMES[cellValue] == playerClass then
                        -- Cell contains a class group that matches player's class
                        isRelevant = true
                        self:Debug("osd", "Found class group match: " .. cellValue .. " = " .. playerClass)
                    elseif cellValue and type(cellValue) == "string" and string.find(cellValue, "Group") and playerGroup > 0 then
                        -- Cell contains group assignment - check if player's group is included
                        if string.find(cellValue, tostring(playerGroup)) then
                            isRelevant = true
                            self:Debug("osd", "Found group match: " .. cellValue .. " includes group " .. playerGroup)
                        end
                    end
                    
                    -- If this assignment is relevant to the player
                    if isRelevant then
                        -- Get role from column header (default to empty string)
                        local role = colHeader or ""
                        
                        -- Determine which key to use for tank lookup
                        local tankLookupKey = target and target ~= "" and target or raidIcon
                        
                        -- Get tanks for this target/icon
                        local tanks = targetTanks[tankLookupKey] or {}
                        
                        -- Format display text based on role type and tanks
                        local displayFormat = {}
                        
                        -- Add icon identifier string (will be replaced with texture in OSD.lua)
                        local iconIdentifier = ""
                        if raidIcon and raidIcon ~= "" then
                            iconIdentifier = "[" .. raidIcon .. "]"
                        end
                        
                        -- Format target string with name and/or icon
                        local targetText = ""
                        if target and target ~= "" then
                            targetText = target
                        else
                            targetText = raidIcon or "Unknown"
                        end
                        
                        -- Format tanks list
                        local tanksText = ""
                        if table.getn(tanks) > 0 then
                            tanksText = table.concat(tanks, ", ")
                        end
                        
                        -- Format based on role type
                        local roleLower = string.lower(role)
                        local formattedString = ""
                        
                        -- The key needs to uniquely identify this assignment
                        local key = (raidIcon or "") .. ":" .. (target or "") .. ":" .. role
                        
                        -- Skip if we've already seen this assignment combination
                        if assignmentMap[key] then
                            self:Debug("osd", "Skipping duplicate assignment: " .. key)
                        else
                            -- Mark this target+role as processed
                            assignmentMap[key] = true
                            
                            -- Create entry with formatted string based on role type
                            local entry = {
                                role = role,
                                tanks = tanks,
                                icon = raidIcon,
                                target = target,
                                roleType = ""  -- Will be set below
                            }
                            
                            -- Format string based on role type
                            if string.find(roleLower, "tank") then
                                -- Tank role format
                                entry.roleType = "tank"
                                
                                -- Tank - Icon Target with Tank(s)
                                local withTanks = ""
                                if table.getn(tanks) > 1 then
                                    -- Filter out the player from the tanks list
                                    local otherTanks = {}
                                    for _, tank in ipairs(tanks) do
                                        if tank ~= playerName then
                                            table.insert(otherTanks, tank)
                                        end
                                    end
                                    
                                    if table.getn(otherTanks) > 0 then
                                        withTanks = " with " .. table.concat(otherTanks, ", ")
                                    end
                                end
                                
                                entry.displayString = role .. " - " .. iconIdentifier .. " " .. targetText .. withTanks
                            elseif string.find(roleLower, "heal") then
                                -- Healer role format
                                entry.roleType = "healer"
                                
                                -- Heal - Tank(s) tanking Icon Target
                                local tankingText = ""
                                if table.getn(tanks) > 0 then
                                    tankingText = tanksText .. " tanking "
                                end
                                
                                entry.displayString = role .. " - " .. tankingText .. iconIdentifier .. " " .. targetText
                            else
                                -- Other roles (DPS, MC, etc.)
                                entry.roleType = "other"
                                
                                -- Role - Icon Target tanked by Tanks
                                local tankedBy = ""
                                if table.getn(tanks) > 0 then
                                    tankedBy = " tanked by " .. tanksText
                                end
                                
                                entry.displayString = role .. " - " .. iconIdentifier .. " " .. targetText .. tankedBy
                            end
                            
                            -- Only add if we have a display string
                            if entry.displayString ~= "" then
                                table.insert(self.assignments.osdtable, entry)
                            end
                        end
                    end
                end
            end
        elseif row[2] == "Note" and row[3] and row[3] ~= "" then
            -- Collect notes
            table.insert(self.assignments.notes, row[3])
        elseif row[2] == "Warning" and row[3] and row[3] ~= "" then
            -- Collect warnings
            table.insert(self.assignments.warnings, row[3])
        end
    end
    
    self:Debug("osd", "Found " .. table.getn(self.assignments.osdtable) .. " unique relevant assignments")
end

-- Function to update OSD with formatted lines
function TWRA:UpdateOSDAssignmentLines(lines)
    -- Check if OSD frame exists
    if not self.OSD or not self.OSD.frame then
        self:Debug("osd", "OSD frame not available")
        return false
    end
    
    -- Create or get the frame
    local frame = self.OSD.frame
    
    -- Create assignment text field if it doesn't exist
    if not frame.assignmentText then
        self:Debug("osd", "Creating new assignment text field")
        frame.assignmentText = frame.contentContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        frame.assignmentText:SetPoint("TOPLEFT", frame.infoContainer, "BOTTOMLEFT", 15, -5)
        frame.assignmentText:SetWidth(frame.contentContainer:GetWidth() - 30)
        frame.assignmentText:SetJustifyH("LEFT")
        
        -- Add reference to this field directly in OSD for easier access
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
    
    -- Hide the old warning and note containers since we include them in the text directly
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
    
    -- Make sure the frame is actually shown after updating content
    frame:Show()
    self.OSD.isVisible = true
    
    -- Debug the frame's visibility state after update
    self:Debug("osd", "OSD assignment text updated, frame visibility: " .. 
               (frame:IsShown() and "shown" or "hidden"))
    
    return true
end

-- Function to create and update data rows directly inside the contentContainer
function TWRA:DatarowsOSD(contentContainer, sectionName)
    if not contentContainer then
        self:Debug("osd", "No contentContainer provided to DatarowsOSD")
        return false
    end

    self:Debug("osd", "DatarowsOSD called with section: " .. (sectionName or "nil"))
    
    -- Clear any existing data rows
    if contentContainer.dataRows then
        for _, row in ipairs(contentContainer.dataRows) do
            row:Hide()
        end
    end
    
    -- Initialize dataRows array if it doesn't exist
    contentContainer.dataRows = contentContainer.dataRows or {}
    
    -- Find the section data in the assignments
    local sectionData = {}
    local warnings = {}
    local notes = {}
    
    -- Get the data from fullData
    if self.fullData then
        for i = 1, table.getn(self.fullData) do
            local row = self.fullData[i]
            if row[1] == sectionName then
                -- Check for warnings and notes
                if row[2] == "Warning" then
                    table.insert(warnings, row[3] or "")
                    self:Debug("osd", "Found warning: " .. (row[3] or ""))
                elseif row[2] == "Note" then
                    table.insert(notes, row[3] or "")
                    self:Debug("osd", "Found note: " .. (row[3] or ""))
                elseif row[2] ~= "Icon" and row[2] ~= "GUID" then
                    -- Regular data row
                    table.insert(sectionData, row)
                end
            end
        end
    end
    
    -- Save warnings and notes for use in the footer section
    self.assignments = self.assignments or {}
    self.assignments.warnings = warnings
    self.assignments.notes = notes
    
    -- Output debug for warnings and notes
    self:Debug("osd", "DatarowsOSD collected " .. table.getn(warnings) .. 
                      " warnings and " .. table.getn(notes) .. " notes")
    
    -- Format the data for this player's role(s)
    local formattedData = self:FormatDataForPlayer(sectionData)
    
    -- Y-offset for rows
    local yOffset = 5
    
    -- Create and update each data row
    local hasContent = formattedData and table.getn(formattedData) > 0
    
    if hasContent then
        self:Debug("osd", "Creating " .. table.getn(formattedData) .. " data rows")
        for i, entry in ipairs(formattedData) do
            -- Create row if it doesn't exist
            if not contentContainer.dataRows[i] then
                contentContainer.dataRows[i] = contentContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                contentContainer.dataRows[i]:SetJustifyH("LEFT")
            end
            
            -- Set position
            contentContainer.dataRows[i]:ClearAllPoints()
            contentContainer.dataRows[i]:SetPoint("TOPLEFT", contentContainer, "TOPLEFT", 15, -yOffset)
            contentContainer.dataRows[i]:SetPoint("TOPRIGHT", contentContainer, "TOPRIGHT", -15, -yOffset)
            
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
            
            -- Set text and show
            contentContainer.dataRows[i]:SetText(displayString)
            contentContainer.dataRows[i]:Show()
            
            -- Update y-offset for next row
            yOffset = yOffset + 16  -- Typical text height
            
            -- Add a little extra space between rows
            yOffset = yOffset + 1
        end
    else
        self:Debug("osd", "No formatted data, showing 'no assignments' message")
        -- No assignments for this player, show a message
        if not contentContainer.noAssignments then
            contentContainer.noAssignments = contentContainer:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            contentContainer.noAssignments:SetJustifyH("LEFT")
        end
        
        contentContainer.noAssignments:ClearAllPoints()
        contentContainer.noAssignments:SetPoint("TOPLEFT", contentContainer, "TOPLEFT", 15, -yOffset)
        contentContainer.noAssignments:SetPoint("TOPRIGHT", contentContainer, "TOPRIGHT", -15, -yOffset)
        contentContainer.noAssignments:SetText("No specific assignments for you in this section")
        contentContainer.noAssignments:Show()
        
        yOffset = yOffset + 16 -- Account for the no assignments text
    end
    
    -- Make sure the "no assignments" message is properly shown/hidden
    if contentContainer.noAssignments then
        if hasContent then
            contentContainer.noAssignments:Hide()
        else
            contentContainer.noAssignments:Show()
        end
    end
    
    -- Hide any unused rows
    if contentContainer.dataRows then
        for i = (hasContent and table.getn(formattedData) or 0) + 1, table.getn(contentContainer.dataRows) do
            contentContainer.dataRows[i]:Hide()
        end
    end
    
    self:Debug("osd", "DatarowsOSD returning height: " .. yOffset)
    return yOffset
end

-- Function to update footer content (warnings and notes)
function TWRA:UpdateOSDFooters(footerContainer, sectionName)
    -- Make sure we have a valid container to work with
    if not footerContainer then
        self:Debug("osd", "No footerContainer provided to UpdateOSDFooters")
        return 0
    end

    -- Debug output to verify function is being called
    self:Debug("osd", "UpdateOSDFooters called for section: " .. (sectionName or "nil"))
    
    -- Track total height of footer content
    local totalHeight = 0
    
    -- Check if we have warnings and notes to display
    if not self.assignments then 
        self:Debug("osd", "No assignments data available for footers")
        return 0
    end
    
    local hasWarnings = (self.assignments.warnings and table.getn(self.assignments.warnings) > 0)
    local hasNotes = (self.assignments.notes and table.getn(self.assignments.notes) > 0)
    
    -- Debug content we found
    if hasWarnings then
        self:Debug("osd", "Found " .. table.getn(self.assignments.warnings) .. " warnings to display")
    end
    
    if hasNotes then
        self:Debug("osd", "Found " .. table.getn(self.assignments.notes) .. " notes to display")
    end
    
    if not hasWarnings and not hasNotes then
        -- Clean up existing elements if any and exit
        footerContainer:SetHeight(1)
        return 0
    end

    -- Create warning section if needed - now handling multiple warnings
    if hasWarnings then
        for i, warningText in ipairs(self.assignments.warnings) do
            -- Create background for this warning
            local warningBg = footerContainer:CreateTexture(nil, "BACKGROUND")
            warningBg:SetTexture(0.3, 0.1, 0.1, 0.15) -- Red background
            
            -- Position this warning (first warning at top, others with 1px space)
            if i == 1 then
                warningBg:SetPoint("TOPLEFT", footerContainer, "TOPLEFT", 0, 0)
                warningBg:SetPoint("TOPRIGHT", footerContainer, "TOPRIGHT", 0, 0)
            else
                warningBg:SetPoint("TOPLEFT", footerContainer, "TOPLEFT", 0, -totalHeight - 1)
                warningBg:SetPoint("TOPRIGHT", footerContainer, "TOPRIGHT", 0, -totalHeight - 1)
                totalHeight = totalHeight + 1 -- Add 1px space between warnings
            end
            
            warningBg:SetHeight(18) -- Using 18px height
            
            -- Use icon from Constants.lua
            local warningIcon = footerContainer:CreateTexture(nil, "OVERLAY")
            -- Get icon info from TWRA.ICONS
            local iconInfo = self.ICONS and self.ICONS["Warning"] or {"Interface\\GossipFrame\\AvailableQuestIcon", 0, 1, 0, 1}
            warningIcon:SetTexture(iconInfo[1])
            warningIcon:SetTexCoord(iconInfo[2], iconInfo[3], iconInfo[4], iconInfo[5])
            warningIcon:SetWidth(16)
            warningIcon:SetHeight(16)
            warningIcon:SetPoint("LEFT", warningBg, "LEFT", 5, -1) -- Center vertically
            
            -- Create warning text
            local warningTextObj = footerContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            warningTextObj:SetJustifyH("LEFT")
            warningTextObj:SetPoint("LEFT", warningIcon, "RIGHT", 5, 0)
            warningTextObj:SetPoint("RIGHT", warningBg, "RIGHT", -5, 0)
            warningTextObj:SetTextColor(1, 0.7, 0.7) -- Light red
            warningTextObj:SetText(warningText)
            
            -- Update total height
            totalHeight = totalHeight + 18 -- Use fixed height
            
            -- Debug
            warningTextObj:SetPoint("RIGHT", warningBg, "RIGHT", -5, 0)
            warningTextObj:SetTextColor(1, 0.7, 0.7) -- Light red
            warningTextObj:SetText(warningText)
            
            -- Update total height
            totalHeight = totalHeight + 18 -- Use the new height (18px)
            
            -- Debug
            self:Debug("osd", "Added warning " .. i .. " with height: 18")
        end
    end
    
    -- Create note elements next - now with 1px space between each note
    if hasNotes then
        for i, noteText in ipairs(self.assignments.notes) do
            -- Create note background
            local noteBg = footerContainer:CreateTexture(nil, "BACKGROUND")
            noteBg:SetTexture(0.1, 0.1, 0.3, 0.15) -- Blue background
            
            -- Position with spacing
            if i == 1 and totalHeight == 0 then
                -- First note and no warnings - position at top
                noteBg:SetPoint("TOPLEFT", footerContainer, "TOPLEFT", 0, 0)
                noteBg:SetPoint("TOPRIGHT", footerContainer, "TOPRIGHT", 0, 0)
            else
                -- Add 1px spacing between elements
                noteBg:SetPoint("TOPLEFT", footerContainer, "TOPLEFT", 0, -totalHeight - 1)
                noteBg:SetPoint("TOPRIGHT", footerContainer, "TOPRIGHT", 0, -totalHeight - 1)
                totalHeight = totalHeight + 1 -- Account for spacing
            end
            
            noteBg:SetHeight(18) -- Reduced from 24px to 18px
            
            -- Use icon from Constants.lua
            local noteIcon = footerContainer:CreateTexture(nil, "OVERLAY")
            -- Get icon info from TWRA.ICONS
            local iconInfo = self.ICONS and self.ICONS["Note"] or {"Interface\\GossipFrame\\ActiveQuestIcon", 0, 1, 0, 1}
            noteIcon:SetTexture(iconInfo[1])
            noteIcon:SetTexCoord(iconInfo[2], iconInfo[3], iconInfo[4], iconInfo[5])
            noteIcon:SetWidth(16)
            noteIcon:SetHeight(16)
            noteIcon:SetPoint("LEFT", noteBg, "LEFT", 5, -1) -- Slightly adjusted vertical position
            
            -- Create note text
            local noteTextObj = footerContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            noteTextObj:SetJustifyH("LEFT")
            noteTextObj:SetPoint("LEFT", noteIcon, "RIGHT", 5, 0)
            noteTextObj:SetPoint("RIGHT", noteBg, "RIGHT", -5, 0)
            noteTextObj:SetTextColor(0.8, 0.8, 1) -- Light blue
            noteTextObj:SetText(noteText)
            
            -- Update total height - use the new height
            totalHeight = totalHeight + 18
            
            -- Debug
            self:Debug("osd", "Added note " .. i .. " with height: 18")
        end
    end
    
    -- Set footer height to the total calculated height
    footerContainer:SetHeight(totalHeight)
    self:Debug("osd", "Set footer container height to " .. totalHeight)
    
    return totalHeight
end

-- Format assignment data for the current player
function TWRA:FormatDataForPlayer(sectionData)
    -- Check if we have data to format
    if not sectionData or table.getn(sectionData) == 0 then
        return {}
    end
    
    -- Get player name and check for diminutives
    local playerName = UnitName("player")
    if not playerName then 
        self:Debug("osd", "Could not get player name")
        return {} 
    end
    
    local playerNameLower = string.lower(playerName)
    
    -- Formatted data array with display strings
    local formattedData = {}
    
    -- Check all rows for assignments that match the player
    for i = 1, table.getn(sectionData) do
        local row = sectionData[i]
        
        -- Skip the icon row if present
        if row[2] ~= "Icon" then
            -- Check each cell for player name matches
            for j = 3, table.getn(row) do
                local cellValue = row[j]
                
                -- Check for player name in the cell
                if cellValue and cellValue ~= "" then
                    -- Try exact name match first
                    if cellValue == playerName then
                        -- Found direct match, add this as an assignment
                        self:AddFormattedAssignment(formattedData, row, j)
                    else
                        -- Check for partial name match or abbreviated names
                        local cellValueLower = string.lower(cellValue)
                        if string.find(cellValueLower, playerNameLower) then
                            -- Found player name within text, add as assignment
                            self:AddFormattedAssignment(formattedData, row, j)
                        end
                    end
                end
            end
        end
    end
    
    return formattedData
end

-- Helper function to add formatted assignment to our data array
function TWRA:AddFormattedAssignment(formattedData, row, cellIndex)
    -- Extract the task (row[2]) and the assignment details
    local task = row[2] or "Task"
    local detail = row[cellIndex] or ""
    
    -- Create display string based on task and assignment
    local displayString = task .. ": " .. detail
    
    -- Check for duplicate
    for _, entry in ipairs(formattedData) do
        if entry.displayString == displayString then
            -- Skip duplicate entries
            return
        end
    end
    
    -- Add to formatted data
    table.insert(formattedData, {
        displayString = displayString,
        task = task,
        detail = detail,
        -- Removed roleType, let users manually colorize in the sheet if needed
    })
    
    return true
end

-- Helper function to debug the formatted data from DatarowsOSD
function TWRA:DebugFormattedData(formattedData)
    if not formattedData then
        self:Debug("osd", "No formatted data to debug")
        return
    end
    
    self:Debug("osd", "Formatted data rows: " .. table.getn(formattedData))
    
    for i, entry in ipairs(formattedData) do
        self:Debug("osd", "  Row " .. i .. ": " .. entry.displayString)
    end
end
