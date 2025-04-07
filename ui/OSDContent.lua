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
