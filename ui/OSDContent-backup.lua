-- TWRA On-Screen Display (OSD) module
TWRA = TWRA or {}

-- Helper function for OSD content debugging
local function debugOSDContent(message)
    if TWRA and TWRA.Debug then
        TWRA:Debug("osd", message)
    end
end

-- Function to prepare OSD data with structured assignment format
function TWRA:PrepOSD(sectionData)
    -- Initialize assignments namespace
    if not self.assignments then
        self.assignments = {}
    end
    
    -- Initialize the tables for storing data
    self.assignments.notes = {}
    self.assignments.warnings = {}
    self.assignments.playerAssignments = {}  -- Renamed from osdtable for clarity
    
    -- Exit early if no data
    if not sectionData or type(sectionData) ~= "table" or table.getn(sectionData) == 0 then
        self:Debug("osd", "No section data to process, ensure sectionData exists")
        return
    end
    
    self:Debug("osd", "PrepOSD processing " .. table.getn(sectionData) .. " rows")
    
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
    
    -- Find header row for role names - look through the entire fullData table if needed
    local headerRow = nil
    
    -- First try to find section-specific header row
    for _, row in ipairs(sectionData) do
        if row[2] == "Icon" then
            headerRow = row
            self:Debug("osd", "Found section-specific header row")
            break
        end
    end
    
    -- If no section-specific header, look through the entire fullData for a generic header
    if not headerRow and self.fullData then
        for i = 1, table.getn(self.fullData) do
            if self.fullData[i][2] == "Icon" then
                headerRow = self.fullData[i]
                self:Debug("osd", "Found generic header row from fullData")
                break
            end
        end
    end
    
    -- Last resort - create a default header row with basic columns
    if not headerRow then
        self:Debug("osd", "Creating default header row as none was found")
        headerRow = {"Header", "Icon", "Target", "Tank", "Offtank", "Heal", "DPS"}
    end
    
    self:Debug("osd", "Using header row: " .. table.concat(headerRow, ", "))
    
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
                
                -- Find tank columns by checking header naming patterns
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
                                self:Debug("osd", "Added tank '" .. tankName .. "' for '" .. key .. "'")
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
        self:Debug("osd", "Target " .. target .. " has tanks: " .. tanksStr)
    end
    
    -- Tracking structure to avoid duplicate target+role combinations
    local assignmentMap = {}
    
    -- Second pass: Find rows relevant to the player, avoiding duplicates
    for _, row in ipairs(sectionData) do
        -- Skip header rows, notes, warnings, and GUID rows
        if row[2] ~= "Icon" and row[2] ~= "Note" and row[2] ~= "Warning" and row[2] ~= "GUID" then
            local raidIcon = row[2]  -- Column 2 is icon
            local target = row[3]    -- Column 3 is target
            
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
                        -- Get role from column header
                        local role = colHeader or ""
                        
                        -- Determine which key to use for tank lookup
                        local tankLookupKey = target and target ~= "" and target or raidIcon
                        
                        -- Get tanks for this target/icon
                        local tanks = targetTanks[tankLookupKey] or {}
                        
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
                            
                            -- Determine role type from header name
                            local roleLower = string.lower(role)
                            if string.find(roleLower, "tank") then
                                entry.roleType = "tank"
                            elseif string.find(roleLower, "heal") then
                                entry.roleType = "healer"
                            elseif string.find(roleLower, "mc") then
                                entry.roleType = "cc"
                            elseif string.find(roleLower, "dps") or string.find(roleLower, "melee") or string.find(roleLower, "ranged") then
                                entry.roleType = "dps"
                            else
                                entry.roleType = "other"
                            end
                            
                            -- Add to assignments table
                            table.insert(self.assignments.playerAssignments, entry)
                            self:Debug("osd", "Added assignment: " .. role .. " for " .. (target or raidIcon or "unknown target"))
                        end
                    end
                end
            end
        elseif row[2] == "Note" and row[3] and row[3] ~= "" then
            -- Collect notes
            table.insert(self.assignments.notes, row[3])
            self:Debug("osd", "Added note: " .. row[3])
        elseif row[2] == "Warning" and row[3] and row[3] ~= "" then
            -- Collect warnings
            table.insert(self.assignments.warnings, row[3])
            self:Debug("osd", "Added warning: " .. row[3])
        end
    end
    
    self:Debug("osd", "Found " .. table.getn(self.assignments.playerAssignments) .. " player assignments")

    -- If no assignments were found, check if player is directly mentioned in target names
    if table.getn(self.assignments.playerAssignments) == 0 then
        self:Debug("osd", "No direct assignments found, checking if player is a target")
        
        for _, row in ipairs(sectionData) do
            if row[2] ~= "Icon" and row[2] ~= "Note" and row[2] ~= "Warning" and row[2] ~= "GUID" then
                local raidIcon = row[2]
                local target = row[3]
                
                if target and target ~= "" and string.find(string.lower(target), string.lower(playerName)) then
                    -- Player's name is in the target - they are likely the target
                    local tanks = targetTanks[target] or {}
                    
                    table.insert(self.assignments.playerAssignments, {
                        role = "Target",
                        roleType = "target",
                        icon = raidIcon,
                        target = target,
                        tanks = tanks
                    })
                    
                    self:Debug("osd", "Player found as target: " .. target)
                    break
                end
            end
        end
    end
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
    self:Debug("osd", "DatarowsOSD called with section: " .. (sectionName or "nil"))
    
    if not contentContainer then
        self:Debug("osd", "No contentContainer provided to DatarowsOSD")
        return false
    end

    -- Check if the OSD frame is properly constructed
    self:Debug("osd", "contentContainer parent: " .. tostring(contentContainer:GetParent():GetName()))
    self:Debug("osd", "contentContainer width: " .. tostring(contentContainer:GetWidth()))
    self:Debug("osd", "contentContainer visible: " .. tostring(contentContainer:IsVisible() and "true" or "false"))
    
    -- Ensure contentContainer is properly visible and sized
    contentContainer:Show()
    
    -- Initialize or reset UI element arrays
    contentContainer.rowFrames = contentContainer.rowFrames or {}
    contentContainer.roleIcons = contentContainer.roleIcons or {}
    contentContainer.targetIcons = contentContainer.targetIcons or {}
    contentContainer.roleFontStrings = contentContainer.roleFontStrings or {}
    contentContainer.targetFontStrings = contentContainer.targetFontStrings or {}
    contentContainer.tanksFontStrings = contentContainer.tanksFontStrings or {}
    
    -- Hide all existing UI elements (will show the needed ones later)
    for i = 1, 20 do -- Assume maximum 20 rows for cleanup
        if contentContainer.rowFrames[i] then contentContainer.rowFrames[i]:Hide() end
        if contentContainer.roleIcons[i] then contentContainer.roleIcons[i]:Hide() end
        if contentContainer.targetIcons[i] then contentContainer.targetIcons[i]:Hide() end
        if contentContainer.roleFontStrings[i] then contentContainer.roleFontStrings[i]:Hide() end
        if contentContainer.targetFontStrings[i] then contentContainer.targetFontStrings[i]:Hide() end
        if contentContainer.tanksFontStrings[i] then contentContainer.tanksFontStrings[i]:Hide() end
    end
    
    -- Find and extract all rows for this section
    local sectionData = {}
    local warnings = {}
    local notes = {}
    
    -- Get the data from fullData, more thoroughly
    if self.fullData then
        -- First identify the section's rows
        local foundSection = false
        local foundHeader = false
        
        for i = 1, table.getn(self.fullData) do
            local row = self.fullData[i]
            
            -- Check if this is the start of our section
            if row[1] == sectionName then
                foundSection = true
                
                -- Extract data based on row type
                if row[2] == "Icon" then
                    -- This is the header row for this section
                    foundHeader = true
                    table.insert(sectionData, row) -- Add header first
                    self:Debug("osd", "Found header row for section: " .. sectionName)
                elseif row[2] == "Warning" then
                    table.insert(warnings, row[3] or "")
                    self:Debug("osd", "Found warning: " .. (row[3] or ""))
                elseif row[2] == "Note" then
                    table.insert(notes, row[3] or "")
                    self:Debug("osd", "Found note: " .. (row[3] or ""))
                elseif row[2] ~= "GUID" then
                    -- Regular data row for this section
                    table.insert(sectionData, row)
                    self:Debug("osd", "Added data row for section: " .. sectionName)
                end
            end
        end
        
        -- Special handling if we didn't find a header
        if not foundHeader and foundSection then
            -- Look for a generic header row
            for i = 1, table.getn(self.fullData) do
                if self.fullData[i][2] == "Icon" then
                    table.insert(sectionData, 1, self.fullData[i]) -- Insert at start
                    self:Debug("osd", "Using generic header row for section: " .. sectionName)
                    break
                end
            end
        end
        
        self:Debug("osd", "Collected " .. table.getn(sectionData) .. " rows for section: " .. sectionName)
    else
        self:Debug("osd", "No fullData available for section: " .. sectionName)
    end
    
    -- Process section data with PrepOSD to get structured assignments
    self:PrepOSD(sectionData)
    
    -- Save warnings and notes for use in the footer section
    if not self.assignments then self.assignments = {} end
    if table.getn(warnings) > 0 then self.assignments.warnings = warnings end
    if table.getn(notes) > 0 then self.assignments.notes = notes end
    
    -- Y-offset for rows
    local yOffset = 5
    
    -- Create and update each data row
    local playerAssignments = self.assignments.playerAssignments
    local hasContent = playerAssignments and table.getn(playerAssignments) > 0
    
    -- Hide the "no assignments" message by default
    if contentContainer.noAssignments then
        contentContainer.noAssignments:Hide()
    end
    
    if hasContent then
        self:Debug("osd", "Creating " .. table.getn(playerAssignments) .. " data rows")
        
        -- Sort assignments to show tanks first, then healers, then DPS
        table.sort(playerAssignments, function(a, b)
            local priority = {tank = 1, healer = 2, cc = 3, dps = 4, target = 5, other = 6}
            return (priority[a.roleType] or 6) < (priority[b.roleType] or 6)
        end)
        
        -- Row spacing
        local rowHeight = 18
        local rowSpacing = 2
        
        for i, assignment in ipairs(playerAssignments) do
            -- 1. Create or get row frame (container for all elements)
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
            
            -- 2. Create or get role icon texture
            if not contentContainer.roleIcons[i] then
                contentContainer.roleIcons[i] = rowFrame:CreateTexture(nil, "ARTWORK")
            end
            local roleIcon = contentContainer.roleIcons[i]
            
            -- Determine icon path based on role type
            local iconPath = "Interface\\Icons\\INV_Misc_QuestionMark" -- Default icon
            
            -- Get standardized role for better icon selection
            local standardizedRole = nil
            
            -- First check if the role has a direct mapping in ROLE_MAPPINGS
            if self.ROLE_MAPPINGS then
                local lowerRole = string.lower(assignment.role)
                standardizedRole = self.ROLE_MAPPINGS[lowerRole]
            end
            
            -- If no direct mapping, try the standardized role function
            if not standardizedRole then
                standardizedRole = self:GetStandardizedRoleName(assignment.role)
            end
            
            -- Now use the standardized role to find the icon
            if self.ROLE_ICONS and self.ROLE_ICONS[standardizedRole] then
                iconPath = self.ROLE_ICONS[standardizedRole]
            else
                -- For unknown roles, use a generic icon based on role type
                if assignment.roleType == "tank" then
                    iconPath = self.ROLE_ICONS and self.ROLE_ICONS["Tank"] or "Interface\\Icons\\Ability_Warrior_DefensiveStance"
                elseif assignment.roleType == "healer" then
                    iconPath = self.ROLE_ICONS and self.ROLE_ICONS["Heal"] or "Interface\\Icons\\Spell_Holy_HolyBolt"
                elseif assignment.roleType == "cc" then
                    iconPath = self.ROLE_ICONS and self.ROLE_ICONS["CC"] or "Interface\\Icons\\Spell_Frost_ChainsOfIce"
                elseif assignment.roleType == "dps" then
                    iconPath = self.ROLE_ICONS and self.ROLE_ICONS["DPS"] or "Interface\\Icons\\INV_Sword_04"
                else
                    -- Default icon for other roles
                    iconPath = self.ROLE_ICONS and self.ROLE_ICONS["Misc"] or "Interface\\Icons\\INV_Misc_QuestionMark"
                end
            end
            
            -- Set up role icon
            roleIcon:SetTexture(iconPath)
            roleIcon:SetWidth(16)
            roleIcon:SetHeight(16)
            roleIcon:SetPoint("LEFT", rowFrame, "LEFT", 5, 0)
            roleIcon:Show()
            
            -- 3. Create or get role text
            if not contentContainer.roleFontStrings[i] then
                contentContainer.roleFontStrings[i] = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                contentContainer.roleFontStrings[i]:SetJustifyH("LEFT")
            end
            local roleFontString = contentContainer.roleFontStrings[i]
            
            -- Position role text (to the right of the role icon)
            roleFontString:ClearAllPoints()
            roleFontString:SetPoint("LEFT", roleIcon, "RIGHT", 3, 0)
            roleFontString:SetText(assignment.role .. ":")
            
            -- -- Set color based on role type -- this is not desired behaviour
            -- if assignment.roleType == "tank" then
            --     roleFontString:SetTextColor(0.78, 0.61, 0.43) -- Light brown for tanks
            -- elseif assignment.roleType == "healer" then
            --     roleFontString:SetTextColor(0.67, 0.83, 0.45) -- Light green for healers
            -- elseif assignment.roleType == "cc" then
            --     roleFontString:SetTextColor(0.58, 0.51, 0.79) -- Light purple for CC
            -- else
            --     roleFontString:SetTextColor(1.0, 1.0, 1.0) -- White for others
            -- end
            roleFontString:Show()

            -- 4. Create or get target icon (for raid markers)
            if not contentContainer.targetIcons[i] then
                contentContainer.targetIcons[i] = rowFrame:CreateTexture(nil, "ARTWORK")
            end
            local targetIcon = contentContainer.targetIcons[i]
            
            -- 5. Create or get target text
            if not contentContainer.targetFontStrings[i] then
                contentContainer.targetFontStrings[i] = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                contentContainer.targetFontStrings[i]:SetJustifyH("LEFT")
            end
            local targetFontString = contentContainer.targetFontStrings[i]
            
            -- 6. Create or get tanks text (for "tanked by" or "with" text)
            if not contentContainer.tanksFontStrings[i] then
                contentContainer.tanksFontStrings[i] = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                contentContainer.tanksFontStrings[i]:SetJustifyH("LEFT")
                contentContainer.tanksFontStrings[i]:SetTextColor(0.82, 0.82, 0.82) -- Light gray for secondary info
            end
            local tanksFontString = contentContainer.tanksFontStrings[i]
            
            -- 7. Process content based on role type and available information
            
            -- Get display text for target
            local targetText = assignment.target and assignment.target ~= "" and assignment.target or "Unknown"
            
            -- Get raid icon if available
            local hasRaidIcon = assignment.icon and assignment.icon ~= "" and self.ICONS and self.ICONS[assignment.icon]
            
            -- Calculate position of elements based on role
            local roleWidth = roleFontString:GetStringWidth()
            local xOffset = roleWidth + 28 -- Role icon (16) + spacing (6) + role text + spacing (6)
            
            -- Format tanks text based on role
            local tanksText = ""
            
            if assignment.tanks and table.getn(assignment.tanks) > 0 then
                if assignment.roleType == "tank" then
                    -- "with Tank2, Tank3"
                    local otherTanks = {}
                    local playerName = UnitName("player")
                    
                    for _, tankName in ipairs(assignment.tanks) do
                        if tankName ~= playerName then
                            table.insert(otherTanks, tankName)
                        end
                    end
                    
                    if table.getn(otherTanks) > 0 then
                        tanksText = "with "
                        
                        -- Add each tank name with class color
                        for i, tankName in ipairs(otherTanks) do
                            if i > 1 then tanksText = tanksText .. ", " end
                            
                            -- Get tank status and class
                            local isInRaid, isOnline = self:GetPlayerStatus(tankName)
                            local tankClass = self:GetPlayerClass(tankName)
                            
                            -- Create colored name text
                            local coloredName = self:ColorTextByClass(tankName, tankClass)
                            
                            -- Add status indicator for offline tanks
                            if not isOnline then
                                coloredName = coloredName .. " |cFFFF0000(offline)|r"
                            elseif not isInRaid then
                                coloredName = coloredName .. " |cFFFF0000(missing)|r"
                            end
                            
                            tanksText = tanksText .. coloredName
                        end
                    end
                    
                elseif assignment.roleType == "healer" then
                    -- "Tank1, Tank2 tanking"
                    tanksText = ""
                    
                    -- Add each tank name with class color
                    for i, tankName in ipairs(assignment.tanks) do
                        if i > 1 then tanksText = tanksText .. ", " end
                        
                        -- Get tank status and class
                        local isInRaid, isOnline = self:GetPlayerStatus(tankName)
                        local tankClass = self:GetPlayerClass(tankName)
                        
                        -- Create colored name text
                        local coloredName = self:ColorTextByClass(tankName, tankClass)
                        
                        -- Add status indicator for offline tanks
                        if not isOnline then
                            coloredName = coloredName .. " |cFFFF0000(offline)|r"
                        elseif not isInRaid then
                            coloredName = coloredName .. " |cFFFF0000(missing)|r"
                        end
                        
                        tanksText = tanksText .. coloredName
                    end
                    
                    tanksText = tanksText .. " tanking"
                else
                    -- "tanked by Tank1, Tank2"
                    tanksText = "tanked by "
                    
                    -- Add each tank name with class color
                    for i, tankName in ipairs(assignment.tanks) do
                        if i > 1 then tanksText = tanksText .. ", " end
                        
                        -- Get tank status and class
                        local isInRaid, isOnline = self:GetPlayerStatus(tankName)
                        local tankClass = self:GetPlayerClass(tankName)
                        
                        -- Create colored name text
                        local coloredName = self:ColorTextByClass(tankName, tankClass)
                        
                        -- Add status indicator for offline tanks
                        if not isOnline then
                            coloredName = coloredName .. " |cFFFF0000(offline)|r"
                        elseif not isInRaid then
                            coloredName = coloredName .. " |cFFFF0000(missing)|r"
                        end
                        
                        tanksText = tanksText .. coloredName
                    end
                end
            end
            
            -- Arrange UI elements based on role type
            if assignment.roleType == "healer" and tanksText ~= "" then
                -- For healers with tanks: Role -> Tanks text -> Target icon -> Target
                tanksFontString:ClearAllPoints()
                tanksFontString:SetPoint("LEFT", roleFontString, "RIGHT", 6, 0)
                tanksFontString:SetText(tanksText)
                tanksFontString:Show()
                
                -- Calculate width for tanks text
                local tanksWidth = tanksFontString:GetStringWidth()
                
                if hasRaidIcon then
                    -- Set icon
                    local iconInfo = self.ICONS[assignment.icon]
                    targetIcon:SetTexture(iconInfo[1])
                    targetIcon:SetTexCoord(iconInfo[2], iconInfo[3], iconInfo[4], iconInfo[5])
                    targetIcon:SetWidth(16)
                    targetIcon:SetHeight(16)
                    
                    -- Position icon after tanks text
                    targetIcon:ClearAllPoints()
                    targetIcon:SetPoint("LEFT", tanksFontString, "RIGHT", 6, 0)
                    targetIcon:Show()
                    
                    -- Position target text after icon
                    targetFontString:ClearAllPoints()
                    targetFontString:SetPoint("LEFT", targetIcon, "RIGHT", 3, 0)
                    targetFontString:SetText(targetText)
                    targetFontString:Show()
                else
                    -- No icon, position target text directly after tanks text
                    targetIcon:Hide()
                    targetFontString:ClearAllPoints()
                    targetFontString:SetPoint("LEFT", tanksFontString, "RIGHT", 6, 0)
                    targetFontString:SetText(targetText)
                    targetFontString:Show()
                end
            else
                -- For tanks and other roles: Role -> Target icon -> Target -> Tanks text
                if hasRaidIcon then
                    -- Set icon
                    local iconInfo = self.ICONS[assignment.icon]
                    targetIcon:SetTexture(iconInfo[1])
                    targetIcon:SetTexCoord(iconInfo[2], iconInfo[3], iconInfo[4], iconInfo[5])
                    targetIcon:SetWidth(16)
                    targetIcon:SetHeight(16)
                    
                    -- Position icon after role text
                    targetIcon:ClearAllPoints()
                    targetIcon:SetPoint("LEFT", roleFontString, "RIGHT", 6, 0)
                    targetIcon:Show()
                    
                    -- Position target text after icon
                    targetFontString:ClearAllPoints()
                    targetFontString:SetPoint("LEFT", targetIcon, "RIGHT", 3, 0)
                    targetFontString:SetText(targetText)
                    targetFontString:Show()
                    
                    -- Position tanks text after target text if needed
                    if tanksText ~= "" then
                        tanksFontString:ClearAllPoints()
                        tanksFontString:SetPoint("LEFT", targetFontString, "RIGHT", 6, 0)
                        tanksFontString:SetText(tanksText)
                        tanksFontString:Show()
                    else
                        tanksFontString:Hide()
                    end
                else
                    -- No icon, position target text directly after role text
                    targetIcon:Hide()
                    targetFontString:ClearAllPoints()
                    targetFontString:SetPoint("LEFT", roleFontString, "RIGHT", 6, 0)
                    targetFontString:SetText(targetText)
                    targetFontString:Show()
                    
                    -- Position tanks text after target text if needed
                    if tanksText ~= "" then
                        tanksFontString:ClearAllPoints()
                        tanksFontString:SetPoint("LEFT", targetFontString, "RIGHT", 6, 0)
                        tanksFontString:SetText(tanksText)
                        tanksFontString:Show()
                    else
                        tanksFontString:Hide()
                    end
                end
            end
            
            -- Update y-offset for next row
            yOffset = yOffset + rowHeight + rowSpacing
        end
    else
        self:Debug("osd", "No assignments found, showing 'no assignments' message")
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
    end
    
    -- Ensure minimum content height
    if yOffset < 20 then
        yOffset = 20
    end
    
    self:Debug("osd", "DatarowsOSD returning height: " .. yOffset)
    return yOffset
end

-- Helper function to format the display string based on role type
function TWRA:FormatRoleBasedDisplayString(assignment)
    if not assignment then return "Invalid assignment" end
    
    -- We don't want to show the icon tag in the text anymore
    -- Format target name
    local targetDisplay = ""
    if assignment.target and assignment.target ~= "" then
        targetDisplay = assignment.target
    elseif assignment.icon and assignment.icon ~= "" then
        targetDisplay = assignment.icon -- fallback if no target name
    else
        targetDisplay = "Unknown"
    end
    
    -- Helper function to format a list with commas and "and"
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
    
    -- Role-specific formatting
    if assignment.roleType == "tank" then
        -- Tank TARGET with Tank2 and Tank3
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
        return assignment.role .. " " .. targetDisplay .. withTanksText
    elseif assignment.roleType == "healer" then
        -- Heal Tank1 and Tank2 tanking TARGET
        local tanksText = ""
        if assignment.tanks and table.getn(assignment.tanks) > 0 then
            tanksText = formatList(assignment.tanks) .. " tanking "
            return assignment.role .. " " .. tanksText .. targetDisplay
        else
            return assignment.role .. " " .. targetDisplay
        end
    else
        -- Other roles: Role TARGET tanked by Tank1 and Tank2
        local tankedByText = ""
        if assignment.tanks and table.getn(assignment.tanks) > 0 then
            tankedByText = " tanked by " .. formatList(assignment.tanks)
        end
        return assignment.role .. " " .. targetDisplay .. tankedByText
    end
end

-- Make sure the GetStandardizedRoleName function is defined here if it's not in Constants.lua
if not TWRA.GetStandardizedRoleName then
    function TWRA:GetStandardizedRoleName(roleName)
        if not roleName then return "Misc" end
        
        -- Standard role mappings
        local roleMappings = {
            ["tank"] = "Tank",
            ["offtank"] = "Tank", 
            ["off-tank"] = "Tank",
            ["main tank"] = "Tank",
            ["mt"] = "Tank",
            ["ot"] = "Tank",
            ["ranged tank"] = "Tank",
            ["r.tank"] = "Tank",
            
            ["heal"] = "Heal",
            ["healer"] = "Heal",
            ["tank heal"] = "Heal",
            ["tank healer"] = "Heal",
            ["raid heal"] = "Heal",
            ["raid healer"] = "Heal",
            ["main heal"] = "Heal",
            
            ["dps"] = "DPS",
            ["mdps"] = "DPS",
            ["rdps"] = "DPS",
            ["melee"] = "DPS",
            ["ranged"] = "DPS",
            
            ["mc"] = "MC",
            ["mind control"] = "MC",
            
            ["kick"] = "Kick",
            ["interrupt"] = "Kick",
            ["interrupts"] = "Kick"
        }
        
        local lowerRole = string.lower(roleName)
        return roleMappings[lowerRole] or "Misc"
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
            totalHeight = totalHeight + 18 -- Use fixed height
            self:Debug("osd", "Added note " .. i .. " with height: 18")
        end
    end
    
    -- Set footer height to the total calculated height
    footerContainer:SetHeight(totalHeight)
    self:Debug("osd", "Set footer container height to " .. totalHeight)
    
    return totalHeight
end

-- Helper function to process section data and extract player-specific assignments with role information
function TWRA:GetRoleBasedAssignments(sectionData)
    local assignments = {}
    
    -- Check if we have data to format
    if not sectionData or table.getn(sectionData) == 0 then
        self:Debug("osd", "No section data to process for role-based assignments")
        return assignments
    end
    
    self:Debug("osd", "Processing section data for role-based assignments")
    
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
                headerRowIndex = i
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

-- Add the GetPlayerClass function if it's not defined elsewhere
if not TWRA.GetPlayerClass then
    function TWRA:GetPlayerClass(name)
        if not name or name == "" then return nil end
        
        -- Check if we're using example data
        if self.usingExampleData and self.EXAMPLE_PLAYERS then
            local classInfo = self.EXAMPLE_PLAYERS[name]
            if classInfo then
                -- Return just the class part without the offline flag
                return string.gsub(classInfo, "|OFFLINE", "")
            end
        end
        
        -- Check if player is in raid
        if GetNumRaidMembers() > 0 then
            for i = 1, GetNumRaidMembers() do
                local raidName, _, _, _, _, class = GetRaidRosterInfo(i)
                if raidName == name then
                    return string.upper(class)
                end
            end
        end
        
        -- Check if player is in party
        if GetNumPartyMembers() > 0 then
            for i = 1, GetNumPartyMembers() do
                if UnitName("party"..i) == name then
                    local _, class = UnitClass("party"..i)
                    return string.upper(class)
                end
            end
        end
        
        -- Check if this is the player
        if UnitName("player") == name then
            local _, class = UnitClass("player")
            return string.upper(class)
        end
        
        return nil
    end
end

-- Add the GetPlayerStatus function if it's not defined elsewhere
if not TWRA.GetPlayerStatus then
    function TWRA:GetPlayerStatus(name)
        if not name or name == "" then return false, false end
        
        -- Check if player is in raid
        if GetNumRaidMembers() > 0 then
            for i = 1, GetNumRaidMembers() do
                local raidName, _, _, _, _, _, _, online = GetRaidRosterInfo(i)
                if raidName == name then
                    return true, online
                end
            end
        end
        
        -- Check if player is in party
        if GetNumPartyMembers() > 0 then
            for i = 1, GetNumPartyMembers() do
                if UnitName("party"..i) == name then
                    return true, UnitIsConnected("party"..i)
                end
            end
        end
        
        -- Check if this is the player
        if UnitName("player") == name then
            return true, true
        end
        
        return false, false
    end
end

-- Helper function to color text based on player class
function TWRA:ColorTextByClass(text, class)
    if not text then return "" end
    if not class then return text end
    
    -- Get class color
    local color = self.VANILLA_CLASS_COLORS and self.VANILLA_CLASS_COLORS[class]
    
    -- If we have a valid color, format the text
    if color then
        -- Convert RGB values to hex
        local r = math.floor(color.r * 255)
        local g = math.floor(color.g * 255)
        local b = math.floor(color.b * 255)
        local hexColor = string.format("%02x%02x%02x", r, g, b)
        
        -- Return colored text
        return "|cFF" .. hexColor .. text .. "|r"
    end
    
    -- Default to uncolored text
    return text
end
