-- Handle loading of data including scanning for GUIDs
function TWRA:ProcessLoadedData(data)
    -- Process player-specific information after data is loaded
    self:ProcessPlayerInfo()
    
    -- After processing data, setup section navigation
    self:RebuildNavigation()
    
    -- If AutoNavigate is enabled, we should prepare any GUID information
    if self.AUTONAVIGATE and self.AUTONAVIGATE.enabled then
        -- This helps the mob scanning system have up-to-date section information
        self:Debug("nav", "Refreshing section navigation for AutoNavigate")
        
        -- Force GUID refresh if needed
        if self.AUTONAVIGATE.debug then
            self:Debug("nav", "Data loaded, refreshed GUID mappings")
            -- Reset last marked GUID to force new scan
            self.AUTONAVIGATE.lastMarkedGuid = nil  
        end
    end
end

-- EnsureCompleteRows - Ensures that all rows have the same number of columns
-- Adds empty strings at missing indices to prevent nil reference errors
function TWRA:EnsureCompleteRows(data)
    if not data then return data end
    
    -- For new data format
    if data.data and type(data.data) == "table" then
        -- Process each section
        for sectionIdx, section in pairs(data.data) do
            -- Skip if not a proper section
            if type(section) == "table" then
                -- Process section header first to determine column count
                local maxColumns = 0
                if section["Section Header"] and type(section["Section Header"]) == "table" then
                    maxColumns = table.getn(section["Section Header"])
                end
                
                -- Process section rows if they exist
                if section["Section Rows"] and type(section["Section Rows"]) == "table" then
                    for rowIdx, rowData in ipairs(section["Section Rows"]) do
                        -- Skip non-table rows
                        if type(rowData) == "table" then
                            -- Special rows like Note, Warning, GUID need exactly 2 columns
                            if rowData[1] == "Note" or rowData[1] == "Warning" or rowData[1] == "GUID" then
                                -- Ensure we have at least 2 columns for special rows
                                if not rowData[1] then rowData[1] = "" end
                                if not rowData[2] then rowData[2] = "" end
                                
                                -- Remove any extra columns beyond 2
                                for i = 3, table.getn(rowData) do
                                    rowData[i] = nil
                                end
                            else
                                -- Normal rows - make sure they have maxColumns entries
                                -- Make sure we have at least as many columns as the header
                                for i = 1, maxColumns do
                                    if not rowData[i] then
                                        rowData[i] = ""
                                    end
                                end
                            end
                        else
                            self:Debug("data", "EnsureCompleteRows: Row " .. rowIdx .. " in section " .. 
                                      tostring(section["Section Name"] or sectionIdx) .. " is not a table")
                        end
                    end
                end
            else
                self:Debug("data", "EnsureCompleteRows: Section " .. tostring(sectionIdx) .. " is not a table")
            end
        end
    end

    -- For legacy format
    if type(data) == "table" and not data.data then
        -- Find max columns in any row
        local maxColumns = 0
        for i = 1, table.getn(data) do
            local row = data[i]
            if type(row) == "table" then
                local rowLen = table.getn(row)
                if rowLen > maxColumns then
                    maxColumns = rowLen
                end
            end
        end
        
        -- Normalize rows
        for i = 1, table.getn(data) do
            local row = data[i]
            if type(row) == "table" then
                for j = 1, maxColumns do
                    if not row[j] then
                        row[j] = ""
                    end
                end
            end
        end
    end
    
    return data
end

-- Enhanced ProcessPlayerInfo with better debugging
function TWRA:ProcessPlayerInfo()
    self:Debug("data", "Processing player-specific information for sections")
    
    -- Process static player info first (based on player name and class)
    self:ProcessStaticPlayerInfo()
    
    -- Then process dynamic player info (based on group)
    self:ProcessDynamicPlayerInfo()
    
    return true
end

-- Process static player information that doesn't change when group composition changes
function TWRA:ProcessStaticPlayerInfo()
    self:Debug("data", "Processing static player information (name/class based)")
    
    -- Get player info that we'll need for processing
    local playerName = UnitName("player")
    local _, playerClass = UnitClass("player")
    playerClass = playerClass and string.upper(playerClass) or nil
    
    self:Debug("data", "Static player info: " .. playerName .. 
              ", class: " .. (playerClass or "unknown"))
    
    -- Skip if we don't have saved data
    if not TWRA_SavedVariables or not TWRA_SavedVariables.assignments or 
       not TWRA_SavedVariables.assignments.data then
        self:Debug("data", "No saved data available for processing")
        return
    end
    
    -- Process each section in the data
    local sectionsProcessed = 0
    for _, section in pairs(TWRA_SavedVariables.assignments.data) do
        -- We're only working with table sections (new format)
        if type(section) == "table" and section["Section Name"] then
            local sectionName = section["Section Name"]
            sectionsProcessed = sectionsProcessed + 1
            
            -- Initialize the player info table
            section["Section Player Info"] = section["Section Player Info"] or {}
            local playerInfo = section["Section Player Info"]
            
            -- Find tank role columns - moved to section level
            section["Tanks"] = self:FindTankRoleColumns(section)
            local tanksCount = table.getn(section["Tanks"])
            
            -- Generate list of tank indices for debugging
            local tanksList = ""
            for i, tankIndex in ipairs(section["Tanks"]) do
                tanksList = tanksList .. tankIndex
                if i < tanksCount then
                    tanksList = tanksList .. ", "
                end
            end
            
            if tanksCount > 0 then
                self:Debug("data", "Section '" .. sectionName .. "': Found " .. tanksCount .. 
                          " tank columns: [" .. tanksList .. "]", false, true)
            end
            
            -- Find relevant rows by player name or class
            playerInfo["Relevant Rows"] = self:GetPlayerRelevantRowsForSection(section)
            local relevantCount = table.getn(playerInfo["Relevant Rows"])
            
            -- Debug relevant rows for this section with detail flag
            local rowsList = ""
            for i, rowIndex in ipairs(playerInfo["Relevant Rows"]) do
                rowsList = rowsList .. rowIndex
                if i < table.getn(playerInfo["Relevant Rows"]) then
                    rowsList = rowsList .. ", "
                end
            end
            
            self:Debug("data", "Section '" .. sectionName .. "': Found " .. relevantCount .. 
                      " relevant rows: [" .. rowsList .. "]", false, true)
            
            -- Generate OSD info for static player assignments
            playerInfo["OSD Assignments"] = self:GenerateOSDInfoForSection(section, playerInfo["Relevant Rows"], false)
        end
    end
    
    self:Debug("data", "Processed static player info for " .. sectionsProcessed .. " sections")
    return true
end

-- Process dynamic player information that changes when group composition changes
function TWRA:ProcessDynamicPlayerInfo()
    self:Debug("data", "Processing dynamic player information (group based)")
    
    -- Get player group info
    local playerName = UnitName("player")
    local playerGroup = nil
    for i = 1, GetNumRaidMembers() do
        local name, _, subgroup = GetRaidRosterInfo(i)
        if name == playerName then
            playerGroup = subgroup
            break
        end
    end
    
    self:Debug("data", "Dynamic player info: group: " .. (playerGroup or "none"))
    
    -- Skip if we don't have saved data
    if not TWRA_SavedVariables or not TWRA_SavedVariables.assignments or 
       not TWRA_SavedVariables.assignments.data then
        self:Debug("data", "No saved data available for processing")
        return
    end
    
    -- Process each section in the data
    local sectionsProcessed = 0
    for _, section in pairs(TWRA_SavedVariables.assignments.data) do
        -- We're only working with table sections (new format)
        if type(section) == "table" and section["Section Name"] then
            local sectionName = section["Section Name"]
            sectionsProcessed = sectionsProcessed + 1
            
            -- Initialize the player info table if needed
            section["Section Player Info"] = section["Section Player Info"] or {}
            local playerInfo = section["Section Player Info"]
            
            -- Identify all group rows (rows containing any group reference) - moved to section level
            section["Group Rows"] = self:GetAllGroupRowsForSection(section)
            
            -- Identify group rows relevant to player's current group
            playerInfo["Relevant Group Rows"] = self:GetGroupRowsForSection(section)
            
            -- Debug group rows for this section
            local groupRowsList = ""
            for i, rowIndex in ipairs(playerInfo["Relevant Group Rows"]) do
                groupRowsList = groupRowsList .. rowIndex
                if i < table.getn(playerInfo["Relevant Group Rows"]) then
                    groupRowsList = groupRowsList .. ", "
                end
            end
            
            self:Debug("data", "Section '" .. sectionName .. "': Found " .. 
                      table.getn(playerInfo["Relevant Group Rows"]) .. 
                      " relevant group rows: [" .. groupRowsList .. "]", false, true)
            
            -- Generate OSD info for group assignments
            playerInfo["OSD Group Assignments"] = self:GenerateOSDInfoForSection(section, playerInfo["Relevant Group Rows"], true)
        end
    end
    
    self:Debug("data", "Processed dynamic player info for " .. sectionsProcessed .. " sections")
    return true
end

-- Get ALL rows containing ANY group references
function TWRA:GetAllGroupRowsForSection(section)
    local allGroupRows = {}
    
    -- Skip if no rows
    if not section["Section Rows"] then
        return allGroupRows
    end
    
    -- Check each row for ANY group references
    for rowIdx, rowData in ipairs(section["Section Rows"]) do
        -- Skip special rows
        if rowData[1] ~= "Note" and rowData[1] ~= "Warning" and rowData[1] ~= "GUID" then
            -- Check each cell for group references
            for _, cellValue in ipairs(rowData) do
                if type(cellValue) == "string" and cellValue ~= "" then
                    -- Look for "Group" keyword
                    if string.find(string.lower(cellValue), "group") then
                        table.insert(allGroupRows, rowIdx)
                        self:Debug("data", "Found group reference in row " .. rowIdx, false, true)
                        break
                    end
                end
            end
        end
    end
    
    return allGroupRows
end

-- Find tank role columns in section headers
function TWRA:FindTankRoleColumns(section)
    local tankColumns = {}
    
    -- Skip if no header
    if not section["Section Header"] then
        return tankColumns
    end
    
    -- Define known tank role keywords
    local tankKeywords = {
        "tank", "offtank", "off-tank", "main tank", "mt", "ot"
    }
    
    -- Check each header column
    for colIdx, headerText in ipairs(section["Section Header"]) do
        -- Skip if not a string
        if type(headerText) == "string" then
            -- Convert to lowercase for case-insensitive matching
            local lcHeader = string.lower(headerText)
            
            -- Check against tank keywords
            for _, keyword in ipairs(tankKeywords) do
                if string.find(lcHeader, keyword) then
                    table.insert(tankColumns, colIdx)
                    self:Debug("data", "Found tank column: " .. colIdx .. " (" .. headerText .. ")", false, true)
                    break
                end
            end
        end
    end
    
    return tankColumns
end

-- Find rows that contain references to player's group
function TWRA:GetGroupRowsForSection(section)
    local groupRows = {}
    
    -- Find player's group number (1-8)
    local playerGroup = nil
    for i = 1, GetNumRaidMembers() do
        local name, _, subgroup = GetRaidRosterInfo(i)
        if name == UnitName("player") then
            playerGroup = subgroup
            break
        end
    end
    
    -- If not in a raid or no group found, return empty list
    if not playerGroup then
        return groupRows
    end
    
    -- Skip if no rows
    if not section["Section Rows"] then
        return groupRows
    end
    
    -- Check each row for group references
    for rowIdx, rowData in ipairs(section["Section Rows"]) do
        -- Skip special rows
        if rowData[1] ~= "Note" and rowData[1] ~= "Warning" and rowData[1] ~= "GUID" then
            -- Check each cell for group references
            for _, cellValue in ipairs(rowData) do
                if type(cellValue) == "string" and cellValue ~= "" then
                    -- Look for "Group X" format
                    if string.find(string.lower(cellValue), "group%s*" .. playerGroup) then
                        table.insert(groupRows, rowIdx)
                        self:Debug("data", "Found group row " .. rowIdx .. " for group " .. playerGroup, false, true)
                        break
                    end
                    
                    -- Look for numeric references to the group
                    if string.find(cellValue, "Group") then
                        local pos = 1
                        local str = cellValue
                        while pos <= string.len(str) do
                            local digitStart, digitEnd = string.find(str, "%d+", pos)
                            if not digitStart then break end
                            
                            local groupNum = tonumber(string.sub(str, digitStart, digitEnd))
                            if groupNum and groupNum == playerGroup then
                                table.insert(groupRows, rowIdx)
                                self:Debug("data", "Found group row " .. rowIdx .. " for group " .. playerGroup, false, true)
                                break
                            end
                            pos = digitEnd + 1
                        end
                    end
                end
            end
        end
    end
    
    return groupRows
end

-- Updated GetPlayerRelevantRowsForSection to only include name and class matches (not group matches)
function TWRA:GetPlayerRelevantRowsForSection(section)
    -- Get player info
    local playerName = UnitName("player")
    local _, playerClass = UnitClass("player")
    playerClass = playerClass and string.upper(playerClass) or nil
    
    -- Prepare result array
    local relevantRows = {}
    
    -- Ensure Section Rows exists
    if not section["Section Rows"] then
        return relevantRows
    end
    
    -- Scan through rows looking for matches
    for rowIndex, rowData in ipairs(section["Section Rows"]) do
        local isRelevantRow = false
        local matchReason = ""
        
        -- Skip special rows
        if rowData[1] == "Note" or rowData[1] == "Warning" or rowData[1] == "GUID" then
            -- Skip these special rows
        else
            -- Check each cell in the row for a match
            for colIndex, cellValue in ipairs(rowData) do
                -- Only process string values
                if type(cellValue) == "string" and cellValue ~= "" then
                    -- Direct player name match
                    if cellValue == playerName then
                        isRelevantRow = true
                        matchReason = "direct name match in column " .. colIndex
                        break
                    end
                    
                    -- Class group match (e.g. "Warriors" for a Warrior)
                    if playerClass and self.CLASS_GROUP_NAMES and 
                       self.CLASS_GROUP_NAMES[cellValue] and 
                       string.upper(self.CLASS_GROUP_NAMES[cellValue]) == playerClass then
                        isRelevantRow = true
                        matchReason = "class group match (" .. cellValue .. ") in column " .. colIndex
                        break
                    end
                    
                    -- NOTE: Group matching is removed from here - it now only happens in GetGroupRowsForSection
                end
            end
            
            -- Add to our list if relevant
            if isRelevantRow then
                table.insert(relevantRows, rowIndex)
                self:Debug("data", "Row " .. rowIndex .. " is relevant: " .. matchReason, false, true)
            end
        end
    end
    
    return relevantRows
end

-- GenerateOSDInfoForSection - Creates a compact representation of player's assignments
-- with proper tank information included as per Player-Relevant-Info.md
function TWRA:GenerateOSDInfoForSection(section, relevantRows, isGroupAssignments)
    local osdInfo = {}
    
    -- If no relevant rows, return empty info
    if not relevantRows or table.getn(relevantRows) == 0 then
        return osdInfo
    end
    
    -- Check if section has header and rows
    if not section["Section Header"] or not section["Section Rows"] then
        return osdInfo
    end
    
    -- Get tank columns from section level (not from player info)
    local tankColumns = section["Tanks"] or self:FindTankRoleColumns(section)
    local playerName = UnitName("player")
    
    -- For each relevant row, extract useful information
    for _, rowIndex in ipairs(relevantRows) do
        local rowData = section["Section Rows"][rowIndex]
        
        -- Skip this if we don't have valid row data
        if not rowData or rowData[1] == "Note" or rowData[1] == "Warning" or rowData[1] == "GUID" then
            self:Debug("data", "Skipping special row " .. rowIndex, false, true)
            -- Skip special rows
        else
            -- Extract target and icon info (columns 1 and 2)
            local icon = rowData[1] or ""
            local target = rowData[2] or ""
            
            -- Find roles where player is mentioned in this row
            -- One row can generate multiple OSD entries - one for each role
            local playerRoles = {}
            for colIndex = 3, table.getn(rowData) do
                if colIndex <= table.getn(section["Section Header"]) then
                    local headerText = section["Section Header"][colIndex]
                    local cellText = rowData[colIndex]
                    
                    -- For group assignments, we only care about cells with group references
                    -- For personal assignments, we care about cells with player name or class
                    local isRelevantCell = false
                    
                    if isGroupAssignments then
                        -- For group assignments, check if cell contains player's group
                        isRelevantCell = self:IsCellContainingPlayerGroup(cellText)
                    else
                        -- For personal assignments, check if cell contains player name or class group
                        isRelevantCell = self:IsCellContainingPlayerNameOrClass(cellText)
                    end
                    
                    if isRelevantCell then
                        table.insert(playerRoles, {
                            role = headerText,
                            column = colIndex
                        })
                        self:Debug("data", "Found " .. (isGroupAssignments and "group" or "personal") .. 
                                 " role " .. headerText .. " in row " .. rowIndex .. 
                                 ", column " .. colIndex, false, true)
                    end
                end
            end
            
            -- Extract tank names from this row
            local tankNames = {}
            for _, tankCol in ipairs(tankColumns) do
                if tankCol <= table.getn(rowData) and rowData[tankCol] and rowData[tankCol] ~= "" then
                    -- Avoid adding player's own name to tank list
                    if rowData[tankCol] ~= playerName then
                        table.insert(tankNames, rowData[tankCol])
                        self:Debug("data", "Found tank name " .. rowData[tankCol] .. 
                                 " in row " .. rowIndex .. ", column " .. tankCol, false, true)
                    end
                end
            end
            
            -- Generate OSD entries for each role where player is mentioned
            for _, roleInfo in ipairs(playerRoles) do
                -- Create a new entry for this role
                local entry = {}
                
                -- Format as per Player-Relevant-Info.md:
                -- 1. Role (column header where player was found)
                -- 2. Icon from column 1
                -- 3. Target from column 2
                -- 4+ Tank names from tank columns
                table.insert(entry, roleInfo.role)  -- Role
                table.insert(entry, icon)           -- Icon
                table.insert(entry, target)         -- Target
                
                -- Add all tank names
                for _, tankName in ipairs(tankNames) do
                    table.insert(entry, tankName)   -- Tank name
                end
                
                -- Add the entry to our results
                table.insert(osdInfo, entry)
                
                self:Debug("data", "Added OSD entry for " .. (isGroupAssignments and "group" or "personal") .. 
                         " role " .. roleInfo.role .. " on target " .. target .. 
                         " with " .. table.getn(tankNames) .. " tanks", false, true)
            end
        end
    end
    
    return osdInfo
end

-- Helper function to check if a cell is relevant to the current player
function TWRA:IsCellRelevantToPlayer(cellValue)
    -- Skip non-string values
    if type(cellValue) ~= "string" or cellValue == "" then
        return false
    end
    
    -- Get player info
    local playerName = UnitName("player")
    local _, playerClass = UnitClass("player")
    playerClass = playerClass and string.upper(playerClass) or nil
    
    -- Direct name match
    if cellValue == playerName then
        return true
    end
    
    -- Class group match
    if playerClass and self.CLASS_GROUP_NAMES and
       self.CLASS_GROUP_NAMES[cellValue] and
       string.upper(self.CLASS_GROUP_NAMES[cellValue]) == playerClass then
        return true
    end
    
    -- Find player's group
    local playerGroup = nil
    for i = 1, GetNumRaidMembers() do
        local name, _, subgroup = GetRaidRosterInfo(i)
        if name == playerName then
            playerGroup = subgroup
            break
        end
    end
    
    -- Check for group references
    if playerGroup and string.find(cellValue, "Group") then
        -- Look for numerical group references
        local pos = 1
        local str = cellValue
        while pos <= string.len(str) do
            local digitStart, digitEnd = string.find(str, "%d+", pos)
            if not digitStart then break end
            
            local groupNum = tonumber(string.sub(str, digitStart, digitEnd))
            if groupNum and groupNum == playerGroup then
                return true
            end
            pos = digitEnd + 1
        end
    end
    
    return false
end

-- Helper function to check if a cell contains player name or class group
function TWRA:IsCellContainingPlayerNameOrClass(cellValue)
    -- Skip non-string values
    if type(cellValue) ~= "string" or cellValue == "" then
        return false
    end
    
    -- Get player info
    local playerName = UnitName("player")
    local _, playerClass = UnitClass("player")
    playerClass = playerClass and string.upper(playerClass) or nil
    
    -- Direct name match
    if cellValue == playerName then
        return true
    end
    
    -- Class group match
    if playerClass and self.CLASS_GROUP_NAMES and
       self.CLASS_GROUP_NAMES[cellValue] and
       string.upper(self.CLASS_GROUP_NAMES[cellValue]) == playerClass then
        return true
    end
    
    return false
end

-- Helper function to check if a cell contains player's current group
function TWRA:IsCellContainingPlayerGroup(cellValue)
    -- Skip non-string values
    if type(cellValue) ~= "string" or cellValue == "" then
        return false
    end
    
    -- Find player's group
    local playerGroup = nil
    for i = 1, GetNumRaidMembers() do
        local name, _, subgroup = GetRaidRosterInfo(i)
        if name == UnitName("player") then
            playerGroup = subgroup
            break
        end
    end
    
    -- If not in a raid or no group found, return false
    if not playerGroup then
        return false
    end
    
    -- Check for group references
    if string.find(cellValue, "Group") then
        -- Look for "Group X" format
        if string.find(string.lower(cellValue), "group%s*" .. playerGroup) then
            return true
        end
        
        -- Look for numerical group references
        local pos = 1
        local str = cellValue
        while pos <= string.len(str) do
            local digitStart, digitEnd = string.find(str, "%d+", pos)
            if not digitStart then break end
            
            local groupNum = tonumber(string.sub(str, digitStart, digitEnd))
            if groupNum and groupNum == playerGroup then
                return true
            end
            pos = digitEnd + 1
        end
    end
    
    return false
end

-- UpdatePlayerInfo - Refreshes player info and updates UI elements with improved debugging
function TWRA:UpdatePlayerInfo()
    self:Debug("data", "Updating player info for all sections")
    
    -- Process all sections
    self:ProcessPlayerInfo()
    
    -- Update OSD if needed
    self:UpdateOSDWithPlayerInfo()
    
    return true
end

-- Helper function to update OSD with new player info
function TWRA:UpdateOSDWithPlayerInfo()
    -- Only update if OSD is visible
    if not self.OSD or not self.OSD.isVisible then
        self:Debug("data", "OSD not visible - skipping update")
        return false
    end
    
    -- Get current section
    if not self.navigation or not self.navigation.currentIndex or not self.navigation.handlers then
        self:Debug("data", "Navigation not ready - skipping OSD update")
        return false
    end
    
    -- Update OSD content
    local currentSectionName = self.navigation.handlers[self.navigation.currentIndex]
    local currentIndex = self.navigation.currentIndex
    local totalSections = table.getn(self.navigation.handlers)
    
    self:Debug("data", "Updating OSD with section: " .. currentSectionName)
    
    -- Update OSD
    if self.UpdateOSDContent then
        self:UpdateOSDContent(currentSectionName, currentIndex, totalSections)
        return true
    else
        self:Debug("error", "UpdateOSDContent function not available")
        return false
    end
end

-- Process all sections to update player info when data changes or player changes groups
function TWRA:RefreshPlayerInfo()
    self:Debug("data", "Refreshing player info for all sections")
    
    -- For group changes, we only need to update the dynamic player info
    -- This is more efficient than reprocessing everything
    self:ProcessDynamicPlayerInfo()
    
    -- If we have an active section, refresh the display
    if self.navigation and self.navigation.currentIndex and 
       self.navigation.handlers and table.getn(self.navigation.handlers) > 0 then
        local currentSection = self.navigation.handlers[self.navigation.currentIndex]
        
        -- Refresh UI if needed
        if self.mainFrame and self.mainFrame:IsShown() and
           self.currentView == "main" and self.FilterAndDisplayHandler then
            self:FilterAndDisplayHandler(currentSection)
            self:Debug("ui", "Refreshed UI for current section after player info update")
        end
        
        -- Refresh OSD if it's showing
        if self.OSD and self.OSD.isVisible then
            self:UpdateOSDContent()
            self:Debug("osd", "Refreshed OSD after player info update")
        end
    end
    
    return true
end
