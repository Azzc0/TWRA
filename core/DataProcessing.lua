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

-- Enhanced ProcessPlayerInfo with better debugging
function TWRA:ProcessPlayerInfo()
    self:Debug("data", "Processing player-specific information for sections")
    
    -- Get player info that we'll need for processing
    local playerName = UnitName("player")
    local _, playerClass = UnitClass("player")
    playerClass = playerClass and string.upper(playerClass) or nil
    
    -- Find player's group number (1-8)
    local playerGroup = nil
    for i = 1, GetNumRaidMembers() do
        local name, _, subgroup = GetRaidRosterInfo(i)
        if name == playerName then
            playerGroup = subgroup
            break
        end
    end
    
    self:Debug("data", "Current player: " .. playerName .. 
              ", class: " .. (playerClass or "unknown") .. 
              ", group: " .. (playerGroup or "none"))
    
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
            
            -- Find relevant rows
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
            
            -- Generate OSD info
            playerInfo["OSD Info"] = self:GenerateOSDInfoForSection(section, playerInfo["Relevant Rows"])
        end
    end
    
    self:Debug("data", "Processed " .. sectionsProcessed .. " sections")
    return true
end

-- Updated GetPlayerRelevantRowsForSection to show first match reason
function TWRA:GetPlayerRelevantRowsForSection(section)
    -- Get player info
    local playerName = UnitName("player")
    local _, playerClass = UnitClass("player")
    playerClass = playerClass and string.upper(playerClass) or nil
    
    -- Find player's group
    local playerGroup = nil
    for i = 1, GetNumRaidMembers() do
        local name, _, subgroup = GetRaidRosterInfo(i)
        if name == playerName then
            playerGroup = subgroup
            break
        end
    end
    
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
                                isRelevantRow = true
                                matchReason = "group match (" .. playerGroup .. ") in column " .. colIndex
                                break
                            end
                            pos = digitEnd + 1
                        end
                        
                        -- If we found a match, break out of the column loop
                        if isRelevantRow then
                            break
                        end
                    end
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
function TWRA:GenerateOSDInfoForSection(section, relevantRows)
    local osdInfo = {}
    
    -- If no relevant rows, return empty info
    if not relevantRows or table.getn(relevantRows) == 0 then
        return osdInfo
    end
    
    -- Check if section has header and rows
    if not section["Section Header"] or not section["Section Rows"] then
        return osdInfo
    end
    
    -- For each relevant row, extract useful information
    for _, rowIndex in ipairs(relevantRows) do
        local rowData = section["Section Rows"][rowIndex]
        
        -- Skip this if we don't have valid row data
        if not rowData then
            break
        end
        
        -- Extract target and icon info (columns 2 and 1)
        local target = rowData[2] or ""
        local icon = rowData[1] or ""
        
        -- Extract role info (determined from header, column 3+ where player is mentioned)
        local role = ""
        for colIndex = 3, table.getn(rowData) do
            if colIndex <= table.getn(section["Section Header"]) then
                local headerText = section["Section Header"][colIndex]
                local cellText = rowData[colIndex]
                
                -- If this cell contains the player's name or class group
                if self:IsCellRelevantToPlayer(cellText) then
                    role = headerText
                    break
                end
            end
        end
        
        -- Add to OSD info: target, player's role, icon, special instructions
        -- We use empty string for any missing elements
        table.insert(osdInfo, target)   -- Target
        table.insert(osdInfo, role)      -- Role
        table.insert(osdInfo, icon)      -- Icon
        table.insert(osdInfo, "")        -- Future special instructions
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

-- UpdatePlayerInfo - Refreshes player info and updates UI elements with improved debugging
function TWRA:UpdatePlayerInfo()
    self:Debug("data", "Updating player info for all sections")
    
    -- Check if we have data to work with
    if not TWRA_SavedVariables or not TWRA_SavedVariables.assignments or
       not TWRA_SavedVariables.assignments.data then
        self:Debug("error", "UpdatePlayerInfo: No assignment data available")
        return false
    end
    
    -- Check data format
    local isNewFormat = TWRA_SavedVariables.assignments.version and TWRA_SavedVariables.assignments.version >= 2
    
    if not isNewFormat then
        self:Debug("data", "UpdatePlayerInfo: Not using new data format, skipping")
        return false
    end
    
    -- Process each section
    local sectionsUpdated = 0
    for idx, section in pairs(TWRA_SavedVariables.assignments.data) do
        if type(section) == "table" and section["Section Name"] then
            -- Process player info for this section
            TWRA_SavedVariables.assignments.data[idx] = self:ProcessPlayerInfo(section)
            sectionsUpdated = sectionsUpdated + 1
        end
    end
    
    self:Debug("data", "Updated player info for " .. sectionsUpdated .. " sections")
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
    
    -- Update player info for all sections
    self:UpdatePlayerInfo()
    
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
        if self.OSD and self.OSD.isVisible and self.RefreshOSDContent then
            self:RefreshOSDContent()
            self:Debug("osd", "Refreshed OSD after player info update")
        end
    end
    
    return true
end

-- Function to process player-specific information for a section
function TWRA:ProcessPlayerInfo(sectionData)
    if not sectionData or type(sectionData) ~= "table" then
        self:Debug("error", "ProcessPlayerInfo: Invalid section data")
        return sectionData
    end
    
    -- Initialize section player info if not exists
    sectionData["Section Player Info"] = sectionData["Section Player Info"] or {}
    
    -- Get relevant rows for the current player
    local relevantRows = self:GetPlayerRelevantRowsForSection(sectionData)
    
    -- Convert from map to array format
    local relevantRowsArray = {}
    for idx, _ in pairs(relevantRows) do
        table.insert(relevantRowsArray, idx)
    end
    
    -- Sort the array for consistent order
    table.sort(relevantRowsArray)
    
    -- Store in section data
    sectionData["Section Player Info"]["Relevant Rows"] = relevantRowsArray
    
    self:Debug("data", "Processed player info for section: " .. 
               (sectionData["Section Name"] or "unnamed") .. 
               ", found " .. table.getn(relevantRowsArray) .. " relevant rows")
    
    return sectionData
end

-- Function to extract player-relevant rows from a section
function TWRA:GetPlayerRelevantRowsForSection(sectionData)
    if not sectionData then
        self:Debug("error", "GetPlayerRelevantRowsForSection: No section data provided")
        return {}
    end
    
    local relevantRows = {}
    local playerName = UnitName("player")
    local _, playerClass = UnitClass("player")
    playerClass = playerClass and string.upper(playerClass) or nil
    
    -- Find player's group number (1-8)
    local playerGroup = nil
    for i = 1, GetNumRaidMembers() do
        local name, _, subgroup = GetRaidRosterInfo(i)
        if name == playerName then
            playerGroup = subgroup
            break
        end
    end
    
    -- Check if we have pre-calculated relevant rows
    if sectionData["Section Player Info"] and 
       sectionData["Section Player Info"]["Relevant Rows"] then
        -- Use pre-calculated relevant rows if available
        for _, rowIdx in pairs(sectionData["Section Player Info"]["Relevant Rows"]) do
            relevantRows[rowIdx] = true
        end
        
        self:Debug("data", "Using pre-calculated relevant rows")
        return relevantRows
    end
    
    -- No pre-calculated data, we need to determine relevant rows
    self:Debug("data", "Calculating relevant rows for player: " .. playerName)
    
    -- Check if we have rows to process
    if not sectionData["Section Rows"] then
        return relevantRows
    end
    
    -- Process each row in the section
    for idx, rowData in pairs(sectionData["Section Rows"]) do
        -- Skip special rows (Note, Warning, GUID)
        if rowData[1] ~= "Note" and rowData[1] ~= "Warning" and rowData[1] ~= "GUID" then
            local isRelevantRow = false
            
            -- Check each cell for player name, class, or group
            for _, cellData in pairs(rowData) do
                -- Only check string data
                if type(cellData) == "string" and cellData ~= "" then
                    -- Direct player name match
                    if cellData == playerName then
                        isRelevantRow = true
                        break
                    end
                    
                    -- Match player class directly
                    if playerClass and string.upper(cellData) == playerClass then
                        isRelevantRow = true
                        break
                    end
                    
                    -- Match player class group (like "Warriors" for a Warrior)
                    if playerClass and self.CLASS_GROUP_NAMES and 
                       self.CLASS_GROUP_NAMES[cellData] and 
                       string.upper(self.CLASS_GROUP_NAMES[cellData]) == playerClass then
                        isRelevantRow = true
                        break
                    end
                    
                    -- Match player group number if available
                    if playerGroup then
                        local groupPattern = "%f[%a%d]" .. playerGroup .. "%f[^%a%d]"
                        if string.find(cellData, groupPattern) then
                            isRelevantRow = true
                            break
                        end
                        
                        -- Also check for "Group X" format
                        if string.find(string.lower(cellData), "group%s*" .. playerGroup) then
                            isRelevantRow = true
                            break
                        end
                    end
                end
            end
            
            -- Mark row as relevant if any condition matched
            if isRelevantRow then
                relevantRows[idx] = true
                self:Debug("data", "Row " .. idx .. " is relevant to player")
            end
        end
    end
    
    return relevantRows
end
