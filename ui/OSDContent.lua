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
    contentContainer.rowFrames = contentContainer.rowFrames or {}
    contentContainer.roleIcons = contentContainer.roleIcons or {}
    contentContainer.targetIcons = contentContainer.targetIcons or {}
    
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
    
    -- Process section data to get player assignments with role-based formatting
    local playerAssignments = self:GetRoleBasedAssignments(sectionData)
    
    -- Y-offset for rows
    local yOffset = 5
    
    -- Create and update each data row
    local hasContent = playerAssignments and table.getn(playerAssignments) > 0
    
    if hasContent then
        self:Debug("osd", "Creating " .. table.getn(playerAssignments) .. " data rows")
        
        -- Sort assignments to show tanks first, then healers, then DPS
        table.sort(playerAssignments, function(a, b)
            local priority = {tank = 1, healer = 2, other = 3}
            return (priority[a.roleType] or 3) < (priority[b.roleType] or 3)
        end)
        
        -- Row spacing
        local rowHeight = 18
        local rowSpacing = 2
        
        for i, assignment in ipairs(playerAssignments) do
            -- Create or get row frame (container for icon + text)
            if not contentContainer.rowFrames[i] then
                contentContainer.rowFrames[i] = CreateFrame("Frame", nil, contentContainer)
            end
            local rowFrame = contentContainer.rowFrames[i]
            
            -- Position and size the row frame
            rowFrame:ClearAllPoints()
            rowFrame:SetPoint("TOPLEFT", contentContainer, "TOPLEFT", 5, -yOffset)
            rowFrame:SetPoint("TOPRIGHT", contentContainer, "TOPRIGHT", -5, -yOffset)
            rowFrame:SetHeight(rowHeight)
            rowFrame:Show()
            
            -- Create or get role icon texture
            if not contentContainer.roleIcons[i] then
                contentContainer.roleIcons[i] = rowFrame:CreateTexture(nil, "ARTWORK")
            end
            local roleIcon = contentContainer.roleIcons[i]
            
            -- Determine icon path based on role
            local iconPath = "Interface\\Icons\\INV_Misc_QuestionMark" -- Default icon
            if assignment.roleType == "tank" then
                iconPath = self.ROLE_ICONS["Tank"] or "Interface\\Icons\\Ability_Warrior_DefensiveStance"
            elseif assignment.roleType == "healer" then
                iconPath = self.ROLE_ICONS["Heal"] or "Interface\\Icons\\Spell_Holy_HolyBolt"
            else
                -- Try to find a specific matching role icon based on exact role name
                local roleName = assignment.role
                if self.ROLE_ICONS[roleName] then
                    iconPath = self.ROLE_ICONS[roleName]
                else
                    -- Default icon for generic DPS/other
                    iconPath = self.ROLE_ICONS["DPS"] or "Interface\\Icons\\INV_Sword_04"
                end
            end
            
            -- Set up role icon
            roleIcon:SetTexture(iconPath)
            roleIcon:SetWidth(16)
            roleIcon:SetHeight(16)
            roleIcon:SetPoint("LEFT", rowFrame, "LEFT", 5, 0)
            roleIcon:Show()
            
            -- Create row text if it doesn't exist
            if not contentContainer.dataRows[i] then
                contentContainer.dataRows[i] = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                contentContainer.dataRows[i]:SetJustifyH("LEFT")
            end
            
            -- Set position for text (to the right of the icon)
            contentContainer.dataRows[i]:ClearAllPoints()
            contentContainer.dataRows[i]:SetPoint("LEFT", roleIcon, "RIGHT", 3, 0)
            contentContainer.dataRows[i]:SetPoint("RIGHT", rowFrame, "RIGHT", -5, 0)
            
            -- Format display string based on role type
            local displayString = self:FormatRoleBasedDisplayString(assignment)
            
            -- Create or get target icon if needed
            if not contentContainer.targetIcons[i] then
                contentContainer.targetIcons[i] = rowFrame:CreateTexture(nil, "ARTWORK")
            end
            local targetIcon = contentContainer.targetIcons[i]
            
            -- Process raid target icon
            if assignment.icon and assignment.icon ~= "" and self.ICONS then
                local iconInfo = self.ICONS[assignment.icon]
                
                if iconInfo then
                    -- Calculate where the icon tag is in the text
                    local rolePrefix = assignment.role .. " - "
                    local iconTag = "%[" .. assignment.icon .. "%]"
                    
                    -- Remove the icon tag from display string
                    displayString = string.gsub(displayString, iconTag, "")
                    
                    -- Update texture
                    targetIcon:SetTexture(iconInfo[1])
                    targetIcon:SetTexCoord(iconInfo[2], iconInfo[3], iconInfo[4], iconInfo[5])
                    targetIcon:SetWidth(16)
                    targetIcon:SetHeight(16)
                    
                    -- Set the text first to be able to measure it
                    contentContainer.dataRows[i]:SetText(rolePrefix)
                    
                    -- Position icon immediately after role prefix
                    local roleTextWidth = contentContainer.dataRows[i]:GetStringWidth()
                    targetIcon:ClearAllPoints()
                    targetIcon:SetPoint("LEFT", contentContainer.dataRows[i], "LEFT", roleTextWidth, 0)
                    targetIcon:Show()
                    
                    -- Now reconstruct the display string with proper spacing for icon
                    if assignment.roleType == "tank" then
                        -- For tank format: Tank - [Icon]Target with Tank2 and Tank3
                        local targetAndRest = string.gsub(displayString, "^" .. rolePrefix, "")
                        displayString = rolePrefix .. "     " .. targetAndRest -- Add space for icon
                    elseif assignment.roleType == "healer" then
                        -- For healer format: Heal - Tank1 and Tank2 tanking [Icon]Target
                        -- Find where the icon would be after "tanking "
                        if assignment.tanks and table.getn(assignment.tanks) > 0 then
                            local beforeIconText = rolePrefix
                            
                            -- Format the tanks list with "and"
                            local function formatList(list)
                                if not list or table.getn(list) == 0 then
                                    return ""
                                elseif table.getn(list) == 1 then
                                    return list[1]
                                elseif table.getn(list) == 2 then
                                    return list[1] .. " and " .. list[2]
                                else
                                    local result = ""
                                    for i = 1, table.getn(list) - 1 do
                                        if i > 1 then
                                            result = result .. ", "
                                        end
                                        result = result .. list[i]
                                    end
                                    return result .. " and " .. list[table.getn(list)]
                                end
                            end
                            
                            beforeIconText = beforeIconText .. formatList(assignment.tanks) .. " tanking "
                            contentContainer.dataRows[i]:SetText(beforeIconText)
                            
                            -- Reposition icon after the "tanking " text
                            local textWidth = contentContainer.dataRows[i]:GetStringWidth()
                            targetIcon:ClearAllPoints()
                            targetIcon:SetPoint("LEFT", contentContainer.dataRows[i], "LEFT", textWidth, 0)
                            
                            -- Add space for the icon in display string
                            local parts = {beforeIconText, "     ", assignment.target or ""}
                            displayString = table.concat(parts)
                        else
                            -- No tanks, icon comes right after role prefix
                            displayString = rolePrefix .. "     " .. (assignment.target or "")
                        end
                    else
                        -- For other roles: Role - [Icon]Target tanked by Tank1 and Tank2
                        local targetAndRest = string.gsub(displayString, "^" .. rolePrefix, "")
                        displayString = rolePrefix .. "     " .. targetAndRest -- Add space for icon
                    end
                    
                    self:Debug("osd", "Added target icon for " .. assignment.icon)
                else
                    targetIcon:Hide()
                    self:Debug("osd", "No icon information found for " .. assignment.icon)
                end
            else
                targetIcon:Hide()
            end
            
            -- Set text and show
            contentContainer.dataRows[i]:SetText(displayString)
            contentContainer.dataRows[i]:SetTextColor(1.0, 1.0, 1.0) -- White text
            contentContainer.dataRows[i]:Show()
            
            -- Update y-offset for next row
            yOffset = yOffset + rowHeight + rowSpacing
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
        contentContainer.noAssignments:SetTextColor(0.7, 0.7, 0.7) -- Gray text
        contentContainer.noAssignments:Show()
        
        yOffset = yOffset + 16 -- Account for the no assignments text
        
        -- Hide any row frames and icons
        for i = 1, table.getn(contentContainer.rowFrames) do
            if contentContainer.rowFrames[i] then contentContainer.rowFrames[i]:Hide() end
            if contentContainer.roleIcons[i] then contentContainer.roleIcons[i]:Hide() end
        end
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
        for i = (hasContent and table.getn(playerAssignments) or 0) + 1, table.getn(contentContainer.dataRows) do
            if contentContainer.dataRows[i] then contentContainer.dataRows[i]:Hide() end
            if contentContainer.roleIcons[i] then contentContainer.roleIcons[i]:Hide() end
            if contentContainer.rowFrames[i] then contentContainer.rowFrames[i]:Hide() end
        end
    end
    
    self:Debug("osd", "DatarowsOSD returning height: " .. yOffset)
    return yOffset
end

-- Helper function to process section data and extract player-specific assignments with role information
function TWRA:GetRoleBasedAssignments(sectionData)
    local assignments = {}
    
    -- Check if we have data to format
    if not sectionData or table.getn(sectionData) == 0 then
        self:Debug("osd", "No section data to process for role-based assignments")
        return assignments
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
    
    -- Find proper header row with role names
    local headerRow = nil
    local headerRowIndex = 0
    
    -- First, look specifically for a row with "Icon" in column 2
    for i, row in ipairs(sectionData) do
        if row[2] == "Icon" then
            headerRow = row
            headerRowIndex = i
            self:Debug("osd", "Found header row with 'Icon' marker at index " .. i)
            break
        end
    end
    
    -- If no Icon row found, search for a row that looks like a header
    if not headerRow then
        for i, row in ipairs(sectionData) do
            -- Check if this row has typical header content
            local isHeader = false
            
            -- Check for typical header names in columns 4+ (Tank, Healer, DPS, etc.)
            for j = 4, table.getn(row) do
                if row[j] and type(row[j]) == "string" then
                    local colText = string.lower(row[j])
                    if string.find(colText, "tank") or string.find(colText, "heal") or 
                       string.find(colText, "dps") or string.find(colText, "util") or
                       string.find(colText, "mc") then  -- Added MC as a header indicator
                        isHeader = true
                        break
                    end
                end
            end
            
            -- Check if column 3 is "Target" or similar
            if row[3] and type(row[3]) == "string" and 
               (string.lower(row[3]) == "target" or string.lower(row[3]) == "name") then
                isHeader = true
            end
            
            if isHeader then
                headerRow = row
                headerRowIndex = i
                self:Debug("osd", "Found probable header row at index " .. i)
                break
            end
        end
    end
    
    -- If still no header, try to create one from the structure of the data
    if not headerRow then
        -- Look for a row with a raid icon in column 2 and a target name in column 3
        for i, row in ipairs(sectionData) do
            if row[2] and row[2] ~= "" and row[3] and row[3] ~= "" then
                -- Use the first row with content as a guide to create a header
                headerRow = {"Section", "Icon", "Target"}
                
                -- Create generic headers for remaining columns based on typical layout
                for j = 4, table.getn(row) do
                    if j == 4 or j == 5 then
                        -- Columns 4-5 are typically tanks
                        headerRow[j] = "Tank"
                    elseif j == 6 then
                        -- Column 6 is often utility
                        headerRow[j] = "Utility"
                    elseif j == 7 or j == 8 then
                        -- Columns 7-8 are often healers
                        headerRow[j] = "Healer"
                    else
                        -- Other columns are typically DPS
                        headerRow[j] = "DPS"
                    end
                end
                
                self:Debug("osd", "Created synthetic header row based on data structure")
                break
            end
        end
    end
    
    -- If all else fails, create a default header row
    if not headerRow then
        headerRow = {"Section", "Icon", "Target", "Tank", "Tank", "Utility", "Healer", "Healer", "DPS"}
        self:Debug("osd", "Using default header row as last resort")
    end
    
    -- Debug the header row we're using
    local headerDebug = "Using header row: "
    for i, col in ipairs(headerRow) do
        headerDebug = headerDebug .. "[" .. i .. "]=" .. (col or "nil") .. " "
    end
    self:Debug("osd", headerDebug)
    
    -- First pass: Find tanks for each target
    local targetTanks = {}
    for i, row in ipairs(sectionData) do
        -- Skip the header row and rows for notes, warnings, and GUID
        if i ~= headerRowIndex and row[2] ~= "Note" and row[2] ~= "Warning" and row[2] ~= "GUID" then
            local target = row[3]
            local icon = row[2]
            -- Allow processing even if target is empty, as long as we have an icon
            if (target and target ~= "") or (icon and icon ~= "") then
                -- Use target as key if available, otherwise use icon
                local key = target and target ~= "" and target or icon
                targetTanks[key] = targetTanks[key] or {} -- Initialize if not exists
                
                -- Find tank columns by looking at headers - ONLY use columns explicitly marked as tanks
                for colIndex = 4, table.getn(headerRow) do
                    local colHeader = headerRow[colIndex] or ""
                    -- If column header contains "tank" (case insensitive)
                    if type(colHeader) == "string" and string.find(string.lower(colHeader), "tank") then
                        local tankName = row[colIndex]
                        if tankName and tankName ~= "" then
                            -- Check if tank is already in the list
                            local tankExists = false
                            for _, existingTank in ipairs(targetTanks[key]) do
                                if existingTank == tankName then
                                    tankExists = true
                                    break
                                end
                            end
                            
                            -- Add tank only if not already in the list
                            if not tankExists then
                                table.insert(targetTanks[key], tankName)
                                self:Debug("osd", "Added tank '" .. tankName .. "' for '" .. key .. "' from column '" .. colHeader .. "'")
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- Debug tanks found
    for target, tanks in pairs(targetTanks) do
        local tanksStr = table.concat(tanks, ", ")
        self:Debug("osd", "Tanks for " .. target .. ": " .. tanksStr)
    end
    
    -- Direct player assignment check - we'll check every cell for the player name
    for i, row in ipairs(sectionData) do
        -- Skip the header row and rows for notes, warnings, and GUID
        if i ~= headerRowIndex and row[2] ~= "Note" and row[2] ~= "Warning" and row[2] ~= "GUID" then
            local raidIcon = row[2]  -- Can be empty but that's ok
            local target = row[3]    -- Can be empty but that's ok
            
            -- Skip only if both target AND icon are empty
            if (target and target ~= "") or (raidIcon and raidIcon ~= "") then
                for colIndex = 4, math.min(table.getn(row), table.getn(headerRow)) do
                    local cellValue = row[colIndex]
                    -- Direct name match check
                    if cellValue and cellValue ~= "" and 
                       (cellValue == playerName or 
                        (type(cellValue) == "string" and string.find(string.lower(cellValue), string.lower(playerName)))) then
                        
                        -- Get header for this column, defaulting to its position if not available
                        local colHeader = headerRow[colIndex] or ("Column" .. colIndex)
                        local roleType = "other"
                        
                        -- Determine role type from header name
                        if string.find(string.lower(colHeader), "tank") then
                            roleType = "tank"
                        elseif string.find(string.lower(colHeader), "heal") then
                            roleType = "healer"
                        end
                        
                        -- Get lookup key for tanks
                        local tankLookupKey = target and target ~= "" and target or raidIcon
                        
                        -- Create assignment entry
                        table.insert(assignments, {
                            role = colHeader,
                            roleType = roleType,
                            icon = raidIcon,
                            target = target,
                            tanks = targetTanks[tankLookupKey] or {}
                        })
                        
                        self:Debug("osd", "Found direct player assignment in " .. colHeader .. " column for " .. 
                                (target or raidIcon or "unknown target"))
                    end
                end
            end
        end
    end
    
    -- Class group assignments check
    if self.CLASS_GROUP_NAMES and table.getn(assignments) == 0 then
        for _, row in ipairs(sectionData) do
            if row[2] ~= "Icon" and row[2] ~= "Note" and row[2] ~= "Warning" and row[2] ~= "GUID" then
                local raidIcon = row[2]
                local target = row[3]
                
                if (target and target ~= "") or (raidIcon and raidIcon ~= "") then
                    for colIndex = 4, table.getn(row) do
                        local cellValue = row[colIndex]
                        if cellValue and cellValue ~= "" and self.CLASS_GROUP_NAMES[cellValue] == playerClass then
                            -- Found class group assignment
                            local colHeader = headerRow[colIndex] or "Role"
                            local roleType = "other"
                            if string.find(string.lower(colHeader or ""), "tank") then
                                roleType = "tank"
                            elseif string.find(string.lower(colHeader or ""), "heal") then
                                roleType = "healer"
                            end
                            
                            table.insert(assignments, {
                                role = colHeader,
                                roleType = roleType,
                                icon = raidIcon,
                                target = target,
                                tanks = targetTanks[target and target ~= "" and target or raidIcon] or {}
                            })
                            
                            self:Debug("osd", "Found class group assignment (" .. cellValue .. ") in " .. 
                                    colHeader .. " column for " .. (target or raidIcon or "unknown target"))
                        end
                    end
                end
            end
        end
    end
    
    -- Raid group assignments check
    if table.getn(assignments) == 0 and playerGroup > 0 then
        for _, row in ipairs(sectionData) do
            if row[2] ~= "Icon" and row[2] ~= "Note" and row[2] ~= "Warning" and row[2] ~= "GUID" then
                local raidIcon = row[2]
                local target = row[3]
                
                if (target and target ~= "") or (raidIcon and raidIcon ~= "") then
                    for colIndex = 4, table.getn(row) do
                        local cellValue = row[colIndex]
                        if cellValue and type(cellValue) == "string" and string.find(cellValue, "Group") then
                            -- Check if player's group is included
                            if string.find(cellValue, tostring(playerGroup)) then
                                -- Found group assignment
                                local colHeader = headerRow[colIndex] or "Role"
                                local roleType = "other"
                                if string.find(string.lower(colHeader or ""), "tank") then
                                    roleType = "tank"
                                elseif string.find(string.lower(colHeader or ""), "heal") then
                                    roleType = "healer"
                                end
                                
                                table.insert(assignments, {
                                    role = colHeader,
                                    roleType = roleType,
                                    icon = raidIcon,
                                    target = target,
                                    tanks = targetTanks[target and target ~= "" and target or raidIcon] or {}
                                })
                                
                                self:Debug("osd", "Found group assignment (" .. cellValue .. ") in " .. 
                                        colHeader .. " column for " .. (target or raidIcon or "unknown target"))
                            end
                        end
                    end
                end
            end
        end
    end
    
    -- For healers: If no assignments and player is a healer, add auto-assignments to tank targets
    if table.getn(assignments) == 0 then
        local isHealer = (playerClass == "PRIEST" or playerClass == "DRUID" or 
                         playerClass == "SHAMAN" or playerClass == "PALADIN")
                         
        if isHealer then
            -- Look for targets that have tanks
            for targetName, tanks in pairs(targetTanks) do
                if table.getn(tanks) > 0 then
                    -- Add an auto-healing assignment
                    table.insert(assignments, {
                        role = "Heal",
                        roleType = "healer",
                        icon = nil, -- Will be set if targetName is actually an icon
                        target = targetName,
                        tanks = tanks
                    })
                    
                    -- If this is an icon rather than a target name, adjust
                    if not string.find(targetName, " ") and self.ICON_INDICES and self.ICON_INDICES[targetName] then
                        assignments[table.getn(assignments)].icon = targetName
                        assignments[table.getn(assignments)].target = nil
                    end
                end
            end
            
            if table.getn(assignments) > 0 then
                self:Debug("osd", "Added auto-heal assignments for healer class")
            end
        end
    end
    
    -- Fall back to checking if player is directly mentioned in target names
    if table.getn(assignments) == 0 then
        for _, row in ipairs(sectionData) do
            if row[2] ~= "Icon" and row[2] ~= "Note" and row[2] ~= "Warning" and row[2] ~= "GUID" then
                local raidIcon = row[2]
                local target = row[3]
                
                if target and target ~= "" and string.find(string.lower(target), string.lower(playerName)) then
                    -- Player's name is in the target - they are likely the target
                    local tanks = targetTanks[target] or {}
                    
                    table.insert(assignments, {
                        role = "Target",
                        roleType = "other",
                        icon = raidIcon,
                        target = target,
                        tanks = tanks
                    })
                    
                    self:Debug("osd", "Player found as target: " .. target)
                end
            end
        end
    end
    
    -- If we have icon assignments but no player assignments, show them anyway
    if table.getn(assignments) == 0 then
        -- Look for any icon assignments that might be relevant
        for icon, tanks in pairs(targetTanks) do
            if self.ICON_INDICES and self.ICON_INDICES[icon] then
                -- This is a valid raid icon assignment
                table.insert(assignments, {
                    role = "Mark",
                    roleType = "other",
                    icon = icon,
                    target = nil,
                    tanks = tanks
                })
                
                self:Debug("osd", "Added fallback icon assignment for: " .. icon)
            end
        end
    end
    
    self:Debug("osd", "Found " .. table.getn(assignments) .. " role-based assignments")
    return assignments
end

-- Helper function to format the display string based on role type
function TWRA:FormatRoleBasedDisplayString(assignment)
    if not assignment then return "Invalid assignment" end
    
    -- Format icon for display
    local iconDisplay = ""
    if assignment.icon and assignment.icon ~= "" then
        iconDisplay = "[" .. assignment.icon .. "] "
    end
    
    -- Format target name
    local targetDisplay = ""
    if assignment.target and assignment.target ~= "" then
        targetDisplay = assignment.target
    elseif assignment.icon and assignment.icon ~= "" then
        targetDisplay = assignment.icon
    else
        targetDisplay = "Unknown"
    end
    
    -- Helper function to format a list with "and" between the last two items
    local function formatList(list)
        if not list or table.getn(list) == 0 then
            return ""
        elseif table.getn(list) == 1 then
            return list[1]
        elseif table.getn(list) == 2 then
            return list[1] .. " and " .. list[2]
        else
            local result = ""
            for i = 1, table.getn(list) - 1 do
                if i > 1 then
                    result = result .. ", "
                end
                result = result .. list[i]
            end
            return result .. " and " .. list[table.getn(list)]
        end
    end
    
    -- Role-specific formatting - Keep role name in the display string
    if assignment.roleType == "tank" then
        -- Tank - [Icon] Target with Tank2 and Tank3
        local withTanksText = ""
        if assignment.tanks and table.getn(assignment.tanks) > 1 then
            -- Filter out the player from the tanks list
            local otherTanks = {}
            local playerName = UnitName("player")
            for _, tank in ipairs(assignment.tanks) do
                if tank ~= playerName then
                    table.insert(otherTanks, tank)
                end
            end
            
            if table.getn(otherTanks) > 0 then
                withTanksText = " with " .. formatList(otherTanks)
            end
        end
        
        return assignment.role .. " - " .. iconDisplay .. targetDisplay .. withTanksText
    
    elseif assignment.roleType == "healer" then
        -- Heal - Tank1 and Tank2 tanking [Icon] Target
        local tanksText = ""
        if assignment.tanks and table.getn(assignment.tanks) > 0 then
            tanksText = formatList(assignment.tanks) .. " tanking "
        end
        
        return assignment.role .. " - " .. tanksText .. iconDisplay .. targetDisplay
    
    else
        -- Other roles: Role - [Icon] Target tanked by Tank1 and Tank2
        local tankedByText = ""
        if assignment.tanks and table.getn(assignment.tanks) > 0 then
            tankedByText = " tanked by " .. formatList(assignment.tanks)
        end
        
        return assignment.role .. " - " .. iconDisplay .. targetDisplay .. tankedByText
    end
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

    -- Clear existing elements first to prevent stacking issues
    local elements = {footerContainer:GetRegions()}
    for _, element in pairs(elements) do
        element:Hide()
        element:SetParent(nil)
    end
    
    local contentElements = {footerContainer:GetChildren()}
    for _, element in pairs(contentElements) do
        element:Hide()
        element:SetParent(nil)
    end

    -- Create warning section if needed - now handling multiple warnings
    if hasWarnings then
        for i, warningText in ipairs(self.assignments.warnings) do
            -- Create background for this warning
            local warningBg = footerContainer:CreateTexture(nil, "BACKGROUND")
            warningBg:SetTexture(0.3, 0.1, 0.1, 0.3) -- Slightly brighter red background
            
            -- Position this warning (first warning at top, others with 1px space)
            if i == 1 then
                warningBg:SetPoint("TOPLEFT", footerContainer, "TOPLEFT", 0, 0)
                warningBg:SetPoint("TOPRIGHT", footerContainer, "TOPRIGHT", 0, 0)
            else
                warningBg:SetPoint("TOPLEFT", footerContainer, "TOPLEFT", 0, -totalHeight)
                warningBg:SetPoint("TOPRIGHT", footerContainer, "TOPRIGHT", 0, -totalHeight)
            end
            
            warningBg:SetHeight(18) -- Fixed height for consistency
            
            -- Use icon from Constants.lua
            local warningIcon = footerContainer:CreateTexture(nil, "OVERLAY")
            -- Get icon info from TWRA.ICONS
            local iconInfo = self.ICONS and self.ICONS["Warning"] or {"Interface\\GossipFrame\\AvailableQuestIcon", 0, 1, 0, 1}
            warningIcon:SetTexture(iconInfo[1])
            warningIcon:SetTexCoord(iconInfo[2], iconInfo[3], iconInfo[4], iconInfo[5])
            warningIcon:SetWidth(16)
            warningIcon:SetHeight(16)
            warningIcon:SetPoint("LEFT", warningBg, "LEFT", 5, 0) -- Centered vertically
            
            -- Create warning text
            local warningTextObj = footerContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            warningTextObj:SetJustifyH("LEFT")
            warningTextObj:SetPoint("LEFT", warningIcon, "RIGHT", 5, 0)
            warningTextObj:SetPoint("RIGHT", warningBg, "RIGHT", -5, 0)
            warningTextObj:SetTextColor(1, 0.7, 0.7) -- Light red
            warningTextObj:SetText(warningText)
            
            -- Update total height
            totalHeight = totalHeight + 18 -- Use fixed height
            
            self:Debug("osd", "Added warning " .. i .. " with height: 18")
        end
    end
    
    -- Create note elements with proper spacing from warnings
    if hasNotes then
        -- Add small spacing between warnings and notes sections only if both exist
        if hasWarnings then
            totalHeight = totalHeight + 1 -- Just 1px spacing between sections
        end
        
        for i, noteText in ipairs(self.assignments.notes) do
            -- Create note background
            local noteBg = footerContainer:CreateTexture(nil, "BACKGROUND")
            noteBg:SetTexture(0.1, 0.1, 0.3, 0.3) -- Slightly brighter blue background
            
            -- Position with proper spacing
            if i == 1 and totalHeight == 0 then
                -- First note and no warnings - position at top
                noteBg:SetPoint("TOPLEFT", footerContainer, "TOPLEFT", 0, 0)
                noteBg:SetPoint("TOPRIGHT", footerContainer, "TOPRIGHT", 0, 0)
            else
                -- Position directly below previous element
                noteBg:SetPoint("TOPLEFT", footerContainer, "TOPLEFT", 0, -totalHeight)
                noteBg:SetPoint("TOPRIGHT", footerContainer, "TOPRIGHT", 0, -totalHeight)
            end
            
            noteBg:SetHeight(18) -- Fixed height for consistency
            
            -- Use icon from Constants.lua
            local noteIcon = footerContainer:CreateTexture(nil, "OVERLAY")
            -- Get icon info from TWRA.ICONS
            local iconInfo = self.ICONS and self.ICONS["Note"] or {"Interface\\GossipFrame\\ActiveQuestIcon", 0, 1, 0, 1}
            noteIcon:SetTexture(iconInfo[1])
            noteIcon:SetTexCoord(iconInfo[2], iconInfo[3], iconInfo[4], iconInfo[5])
            noteIcon:SetWidth(16)
            noteIcon:SetHeight(16)
            noteIcon:SetPoint("LEFT", noteBg, "LEFT", 5, 0) -- Centered vertically
            
            -- Create note text
            local noteTextObj = footerContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            noteTextObj:SetJustifyH("LEFT")
            noteTextObj:SetPoint("LEFT", noteIcon, "RIGHT", 5, 0)
            noteTextObj:SetPoint("RIGHT", noteBg, "RIGHT", -5, 0)
            noteTextObj:SetTextColor(0.8, 0.8, 1) -- Light blue
            noteTextObj:SetText(noteText)
            
            -- Update total height
            totalHeight = totalHeight + 18
            
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
