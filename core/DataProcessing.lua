-- Handle loading of data including scanning for GUIDs
function TWRA:ProcessLoadedData(data)
    -- Process player-specific information after data is loaded with comprehensive error handling
    self:Debug("data", "Processing player information for loaded data")
    
    -- Use pcall to safely execute player info processing
    local success, error = pcall(function()
        self:ProcessPlayerInfo()
    end)
    
    if not success then
        self:Debug("error", "Error processing player info during data load: " .. tostring(error))
        
        -- Try a second approach with safer section-by-section processing
        self:Debug("data", "Attempting fallback section-by-section player info processing")
        if TWRA_Assignments and TWRA_Assignments.data then
            for sectionIdx, section in pairs(TWRA_Assignments.data) do
                if type(section) == "table" and section["Section Name"] then
                    local sectionSuccess, sectionError = pcall(function()
                        self:ProcessPlayerInfo(section)
                    end)
                    
                    if sectionSuccess then
                        self:Debug("data", "Successfully processed player info for section " .. section["Section Name"])
                    else
                        self:Debug("error", "Failed to process player info for section " .. 
                                  section["Section Name"] .. ": " .. tostring(sectionError))
                    end
                end
            end
        end
    else
        self:Debug("data", "Successfully processed player info for all sections")
    end
    
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
    
    -- Return success
    return true
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

-- Enhanced ProcessPlayerInfo with better debugging and optional section parameter
function TWRA:ProcessPlayerInfo(section)
    if section then
        self:Debug("data", "Processing player-specific information for section: " .. (section["Section Name"] or "Unknown"))
    else
        self:Debug("data", "Processing player-specific information for all sections")
    end
    
    -- Process static player info first (based on player name and class)
    self:ProcessStaticPlayerInfo(section)
    
    -- Then process dynamic player info (based on group)
    self:ProcessDynamicPlayerInfo(section)
    
    return true
end

-- Process static player information that doesn't change when group composition changes
-- Optional section parameter to process only that section
function TWRA:ProcessStaticPlayerInfo(section)
    if section then
        self:Debug("data", "Processing static player information for specific section: " .. (section["Section Name"] or "Unknown"))
    else
        self:Debug("data", "Processing static player information (name/class based) for all sections")
    end
    
    -- Get player info that we'll need for processing
    local playerName = UnitName("player")
    local _, playerClass = UnitClass("player")
    -- Convert to player class group name (e.g., "WARRIOR" to "Warriors")
    local playerClassGroup = nil
    
    -- Find the class group name for the player's class
    for groupName, className in pairs(self.CLASS_GROUP_NAMES) do
        if className == playerClass then
            playerClassGroup = groupName
            break
        end
    end
    
    self:Debug("data", "Static player info: " .. playerName .. 
              ", class: " .. (playerClass or "unknown") .. 
              ", class group: " .. (playerClassGroup or "unknown"))
    
    -- Skip if we don't have saved data
    if not TWRA_Assignments or not TWRA_Assignments.data then
        self:Debug("data", "No saved data available for processing")
        return
    end
    
    -- Process each section in the data or just the specified section
    local sectionsProcessed = 0
    
    -- If a specific section was provided, just process that one
    if section and type(section) == "table" and section["Section Name"] then
        self:ProcessStaticPlayerInfoForSection(section, playerName, playerClass, playerClassGroup)
        sectionsProcessed = 1
    else
        -- Process all sections
        for _, sectionData in pairs(TWRA_Assignments.data) do
            -- We're only working with table sections (new format)
            if type(sectionData) == "table" and sectionData["Section Name"] then
                self:ProcessStaticPlayerInfoForSection(sectionData, playerName, playerClass, playerClassGroup)
                sectionsProcessed = sectionsProcessed + 1
            end
        end
    end
    
    self:Debug("data", "Processed static player info for " .. sectionsProcessed .. " sections")
    return true
end

-- Helper function to process static player info for a specific section
function TWRA:ProcessStaticPlayerInfoForSection(section, playerName, playerClass, playerClassGroup)
    local sectionName = section["Section Name"]
    
    -- Ensure Section Player Info exists
    section["Section Player Info"] = section["Section Player Info"] or {}
    
    -- Ensure Section Metadata exists
    section["Section Metadata"] = section["Section Metadata"] or {}
    
    -- Access the metadata
    local metadata = section["Section Metadata"]
    local playerInfo = section["Section Player Info"]
    
    -- Get tank columns from metadata - no need to find them again
    -- They should already be available in the metadata
    
    -- Find rows relevant to the player by name or class group
    local relevantRows = {}
    
    -- Scan each row in the section
    if section["Section Rows"] then
        for rowIndex, rowData in ipairs(section["Section Rows"]) do
            if type(rowData) == "table" then
                -- Skip special rows
                if rowData[1] ~= "Note" and rowData[1] ~= "Warning" and rowData[1] ~= "GUID" then
                    local isRelevant = false
                    
                    -- Check each cell for player name or class group match
                    -- Skip first two columns (icon and target) for both matching types
                    for colIndex = 3, table.getn(rowData) do
                        local cellValue = rowData[colIndex]
                        -- Only process valid string cells
                        if type(cellValue) == "string" and cellValue ~= "" then
                            -- Check direct player name match or class group match in the same pass
                            if cellValue == playerName or (playerClassGroup and cellValue == playerClassGroup) then
                                local matchType = cellValue == playerName and "direct name match" or "class group match"
                                isRelevant = true
                                self:Debug("data", "Row " .. rowIndex .. " is relevant: " .. matchType .. " in column " .. colIndex, false, true)
                                break
                            end
                        end
                    end
                    
                    -- Add row to relevant rows if it matches
                    if isRelevant then
                        table.insert(relevantRows, rowIndex)
                    end
                end
            end
        end
    end
    
    -- Store the relevant rows in section's player info
    playerInfo["Relevant Rows"] = relevantRows
    
    -- Log the number of relevant rows found
    self:Debug("data", "Section '" .. sectionName .. "': Found " .. 
              table.getn(relevantRows) .. " rows relevant to player " .. playerName)
    
    -- Generate OSD info for static player assignments
    playerInfo["OSD Assignments"] = self:GenerateOSDInfoForSection(section, relevantRows)
    
    return true
end

-- Process dynamic player information that changes when group composition changes
-- Optional section parameter to process only that section
function TWRA:ProcessDynamicPlayerInfo(section)
    if section then
        self:Debug("data", "Processing dynamic player information for specific section: " .. (section["Section Name"] or "Unknown"))
    else
        self:Debug("data", "Processing dynamic player information (group based) for all sections")
    end
    
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
    
    self:Debug("data", "Dynamic player info: player name: " .. playerName .. ", group: " .. (playerGroup or "none"))
    
    -- Skip if we don't have saved data
    if not TWRA_Assignments or not TWRA_Assignments.data then
        self:Debug("data", "No saved data available for processing")
        return
    end
    
    -- Process each section in the data or just the specified section
    local sectionsProcessed = 0
    
    -- If a specific section was provided, just process that one
    if section and type(section) == "table" and section["Section Name"] then
        self:ProcessDynamicPlayerInfoForSection(section, playerName, playerGroup)
        sectionsProcessed = 1
    else
        -- Process all sections
        for _, sectionData in pairs(TWRA_Assignments.data) do
            -- We're only working with table sections (new format)
            if type(sectionData) == "table" and sectionData["Section Name"] then
                self:ProcessDynamicPlayerInfoForSection(sectionData, playerName, playerGroup)
                sectionsProcessed = sectionsProcessed + 1
            end
        end
    end
    
    self:Debug("data", "Processed dynamic player info for " .. sectionsProcessed .. " sections")
    return true
end

-- Helper function to process dynamic player info for a specific section
function TWRA:ProcessDynamicPlayerInfoForSection(section, playerName, playerGroup)
    local sectionName = section["Section Name"]
    
    -- Initialize the metadata and player info tables if needed
    section["Section Metadata"] = section["Section Metadata"] or {}
    section["Section Player Info"] = section["Section Player Info"] or {}
    
    local metadata = section["Section Metadata"]
    local playerInfo = section["Section Player Info"]
    
    -- Skip if player is not in a raid group
    if not playerGroup then
        self:Debug("data", "Player is not in a raid group - skipping dynamic player info for section: " .. sectionName)
        playerInfo["Relevant Group Rows"] = {}
        playerInfo["OSD Group Assignments"] = {}
        return
    end
    
    -- Get group rows from metadata if they exist, otherwise find them
    metadata["Group Rows"] = metadata["Group Rows"] or self:GetAllGroupRowsForSection(section)
    
    -- Find rows that match player's current group number
    local relevantGroupRows = {}
    
    -- Look at each row in the section's Group Rows
    for _, rowIndex in ipairs(metadata["Group Rows"]) do
        local rowData = section["Section Rows"][rowIndex]
        
        -- Skip if the row is not valid
        if type(rowData) ~= "table" then
            self:Debug("data", "Invalid row data at index " .. rowIndex, false, true)
        else
            local isRelevant = false
            
            -- Check each cell for player's group number, skipping first two columns
            for colIndex = 3, table.getn(rowData) do
                local cellValue = rowData[colIndex]
                -- Only process string cells with content
                if type(cellValue) == "string" and cellValue ~= "" then
                    -- Look for direct group number references
                    if string.find(string.lower(cellValue), "group%s*" .. playerGroup) or
                       string.find(string.lower(cellValue), "gr%.%s*" .. playerGroup) or
                       string.find(string.lower(cellValue), "gr%s*" .. playerGroup) or
                       string.find(string.lower(cellValue), "grp%s*" .. playerGroup) then
                       
                        isRelevant = true
                        self:Debug("data", "Row " .. rowIndex .. " is relevant to group " .. playerGroup .. 
                                   ": group match in column " .. colIndex, false, true)
                        break
                    end
                    
                    -- Check for numerical group references like "Groups 1, 3, 5"
                    if string.find(cellValue, "Group") then
                        local pos = 1
                        local str = cellValue
                        while pos <= string.len(str) do
                            local digitStart, digitEnd = string.find(str, "%d+", pos)
                            if not digitStart then break end
                            
                            local groupNum = tonumber(string.sub(str, digitStart, digitEnd))
                            if groupNum and groupNum == playerGroup then
                                isRelevant = true
                                self:Debug("data", "Row " .. rowIndex .. " is relevant to group " .. playerGroup ..
                                           ": numeric group match in column " .. colIndex, false, true)
                                break
                            end
                            pos = digitEnd + 1
                        end
                    end
                end
            end
            
            -- Add to our list if relevant
            if isRelevant then
                table.insert(relevantGroupRows, rowIndex)
            end
        end
    end
    
    -- Store the relevant group rows
    playerInfo["Relevant Group Rows"] = relevantGroupRows
    
    -- Log the number of relevant group rows found
    self:Debug("data", "Section '" .. sectionName .. "': Found " .. 
               table.getn(relevantGroupRows) .. " group rows relevant to player's group " .. playerGroup)
    
    -- Generate OSD info for group assignments
    playerInfo["OSD Group Assignments"] = self:GenerateOSDInfoForSection(section, relevantGroupRows, true)
    
    return true
end

-- UpdatePlayerInfo - Refreshes player info and updates UI elements with improved debugging
-- Now supports updating a single section
function TWRA:UpdatePlayerInfo(section)
    if section then
        self:Debug("data", "Updating player info for section: " .. (section["Section Name"] or "Unknown"))
    else
        self:Debug("data", "Updating player info for all sections")
    end
    
    -- Process all sections or just the specified one
    self:ProcessPlayerInfo(section)
    
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

-- RefreshPlayerInfo - Can now refresh a specific section
function TWRA:RefreshPlayerInfo(section)
    if section then
        self:Debug("data", "Refreshing player info for section: " .. (section["Section Name"] or "Unknown"))
    else
        self:Debug("data", "Refreshing player info for all sections")
    end
    
    -- For group changes, we only need to update the dynamic player info
    -- This is more efficient than reprocessing everything
    self:ProcessDynamicPlayerInfo(section)
    
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

-- ProcessImportedData - Process shortened keys and performs any adjustments needed after Base64 decoding
function TWRA:ProcessImportedData(data)
    if not data or type(data) ~= "table" then
        self:Debug("error", "ProcessImportedData: Invalid data structure")
        return data
    end
    
    -- For the new structure format (with data.data)
    if data.data and type(data.data) == "table" then
        self:Debug("data", "Processing imported data with new format structure")
        
        -- Process each section
        for sectionIdx, section in pairs(data.data) do
            -- Skip if not a table or doesn't have required keys
            if type(section) == "table" then
                -- If using short key format, convert to full names
                if section["sn"] and not section["Section Name"] then
                    section["Section Name"] = section["sn"]
                    section["sn"] = nil
                    self:Debug("data", "Converted short key 'sn' to 'Section Name'")
                end
                
                if section["sh"] and not section["Section Header"] then
                    section["Section Header"] = section["sh"]
                    section["sh"] = nil
                    self:Debug("data", "Converted short key 'sh' to 'Section Header'")
                end
                
                if section["sr"] and not section["Section Rows"] then
                    section["Section Rows"] = section["sr"]
                    section["sr"] = nil
                    self:Debug("data", "Converted short key 'sr' to 'Section Rows'")
                end
                
                -- Initialize Section Metadata if not present
                section["Section Metadata"] = section["Section Metadata"] or {}
                local metadata = section["Section Metadata"]
                
                -- IMPORTANT: Process special rows (Note, Warning, GUID) and store in metadata
                if section["Section Rows"] and type(section["Section Rows"]) == "table" then
                    -- Initialize metadata arrays
                    metadata["Note"] = metadata["Note"] or {}
                    metadata["Warning"] = metadata["Warning"] or {}
                    metadata["GUID"] = metadata["GUID"] or {}
                    
                    -- Store section name in metadata
                    metadata["Name"] = metadata["Name"] or { section["Section Name"] or "" }
                    
                    -- Track indices of rows to remove
                    local rowsToRemove = {}
                    local sectionName = section["Section Name"] or tostring(sectionIdx)
                    
                    -- Process each row looking for special rows
                    for rowIdx, rowData in ipairs(section["Section Rows"]) do
                        if type(rowData) == "table" then
                            -- Check for special rows
                            if rowData[1] == "Note" and rowData[2] then
                                table.insert(metadata["Note"], rowData[2])
                                table.insert(rowsToRemove, rowIdx)
                                self:Debug("data", "Found Note in section " .. sectionName .. ": " .. rowData[2])
                            elseif rowData[1] == "Warning" and rowData[2] then
                                table.insert(metadata["Warning"], rowData[2])
                                table.insert(rowsToRemove, rowIdx)
                                self:Debug("data", "Found Warning in section " .. sectionName .. ": " .. rowData[2])
                            elseif rowData[1] == "GUID" and rowData[2] then
                                table.insert(metadata["GUID"], rowData[2])
                                table.insert(rowsToRemove, rowIdx)
                                self:Debug("data", "Found GUID in section " .. sectionName .. ": " .. rowData[2])
                            end
                        end
                    end
                    
                    -- Remove special rows in reverse order to maintain correct indices
                    table.sort(rowsToRemove, function(a, b) return a > b end)
                    for _, rowIdx in ipairs(rowsToRemove) do
                        table.remove(section["Section Rows"], rowIdx)
                        self:Debug("data", "Removed special row at index " .. rowIdx .. " from section " .. sectionName)
                    end
                    
                    -- Log the number of special rows found
                    self:Debug("data", "Section '" .. sectionName .. "': Found " .. 
                              table.getn(metadata["Note"]) .. " notes, " ..
                              table.getn(metadata["Warning"]) .. " warnings, " ..
                              table.getn(metadata["GUID"]) .. " GUIDs")
                    
                    -- CRITICAL: ALWAYS identify Group Rows during import
                    -- Force generation and store in metadata
                    metadata["Group Rows"] = self:GetAllGroupRowsForSection(section)
                    local groupRowCount = table.getn(metadata["Group Rows"])
                    self:Debug("data", "CRITICAL: Section '" .. sectionName .. "': Identified " .. 
                              groupRowCount .. " group rows during import processing")
                    
                    -- Print the actual group rows found for debugging
                    if groupRowCount > 0 then
                        local groupRowsList = ""
                        for i, rowIndex in ipairs(metadata["Group Rows"]) do
                            if rowIndex > 0 and rowIndex <= table.getn(section["Section Rows"]) then
                                local rowData = section["Section Rows"][rowIndex]
                                local rowContent = ""
                                -- Get a summary of the row content
                                if type(rowData) == "table" then
                                    for j = 1, math.min(5, table.getn(rowData)) do
                                        if rowData[j] and rowData[j] ~= "" then
                                            rowContent = rowContent .. "[" .. j .. "]=" .. rowData[j] .. " "
                                        end
                                    end
                                end
                                groupRowsList = groupRowsList .. rowIndex .. "(" .. rowContent .. "), "
                            else
                                groupRowsList = groupRowsList .. rowIndex .. "(invalid), "
                            end
                        end
                        self:Debug("data", "Group rows: " .. groupRowsList, false, true)
                    else
                        self:Debug("data", "No Group Rows found for section '" .. sectionName .. "'")
                    end
                    
                    -- ENHANCED: Also identify tank columns during import
                    -- First check if tank columns already exist, if not then find them
                    if not metadata["Tank Columns"] or table.getn(metadata["Tank Columns"]) == 0 then
                        metadata["Tank Columns"] = self:FindTankRoleColumns(section)
                        self:Debug("data", "Section '" .. sectionName .. "': Identified " .. 
                                  table.getn(metadata["Tank Columns"]) .. " tank columns during import")
                    else
                        self:Debug("data", "Section '" .. sectionName .. "': Using existing " .. 
                                  table.getn(metadata["Tank Columns"]) .. " tank columns")
                    end
                end
            end
        end
    elseif type(data) == "table" then
        -- For legacy format, just return unchanged
        self:Debug("data", "Processing imported data with legacy format structure")
    end
    
    return data
end

-- Central implementation of StoreCompressedData
-- This is the consolidated version that all other modules should use
-- It properly handles segmented compression instead of storing redundant data
function TWRA:StoreCompressedData(compressedData)
    if not compressedData then
        self:Debug("error", "StoreCompressedData: No compressed data to store")
        return false
    end
    
    self:Debug("data", "StoreCompressedData: Using segmented compression approach")
    
    -- Initialize compression if needed
    if self.InitializeCompression and not self.LibCompress then
        self:InitializeCompression()
    end
    
    -- Always prefer to use segmented data approach
    if self.StoreSegmentedData then
        self:Debug("data", "Storing segmented compressed data instead of complete data")
        return self:StoreSegmentedData()
    else
        -- Only update the timestamp if segmented approach is not available
        -- This isn't ideal but maintains compatibility with older code
        TWRA_CompressedAssignments = TWRA_CompressedAssignments or {}
        
        -- Just store the timestamp for version checking
        if TWRA_Assignments then
            TWRA_CompressedAssignments.timestamp = TWRA_Assignments.timestamp or time()
            self:Debug("data", "Stored timestamp but not complete data")
        end
        
        -- Log that we're not storing the full data to avoid redundancy
        self:Debug("data", "Skipped storing complete compressed data (" .. 
                  string.len(compressedData) .. " bytes) to avoid redundancy")
    end
    
    return true
end

-- Helper function to clear data structures when receiving SRES response
function TWRA:ClearDataForStructureResponse()
    self:Debug("data", "Clearing data structures for structure response processing")
    
    -- Clear TWRA_Assignments data
    if TWRA_Assignments then
        -- Preserve timestamp and isExample flag as they'll be properly overwritten
        local timestamp = TWRA_Assignments.timestamp
        local isExample = TWRA_Assignments.isExample
        
        -- Completely clear the data table
        TWRA_Assignments.data = nil
        
        -- Restore preserved values
        TWRA_Assignments.timestamp = timestamp
        TWRA_Assignments.isExample = isExample
    end
    
    -- Clear TWRA_CompressedAssignments sections
    if TWRA_CompressedAssignments then
        -- This MUST be completely cleared
        TWRA_CompressedAssignments.sections = nil
        
        -- The structure and timestamp will be overwritten, so no need to clear them
    end
    
    self:Debug("data", "Data structures cleared successfully for structure response")
    return true
end

-- Helper function to build skeleton structure from decoded structure data
function TWRA:BuildSkeletonFromStructure(decodedStructure, timestamp, preserveCompressedData)
    if not decodedStructure or type(decodedStructure) ~= "table" then
        self:Debug("error", "BuildSkeletonFromStructure: Invalid structure data")
        return false
    end
    
    self:Debug("data", "Building minimal skeleton structure from decoded structure data")
    
    -- Create new TWRA_Assignments skeleton or use existing
    TWRA_Assignments = TWRA_Assignments or {}
    TWRA_Assignments.timestamp = timestamp or TWRA_Assignments.timestamp
    TWRA_Assignments.data = {}
    -- Explicitly set isExample to false when creating skeleton from received structure data
    TWRA_Assignments.isExample = false
    
    -- IMPORTANT: Also initialize TWRA_CompressedAssignments.sections here
    TWRA_CompressedAssignments = TWRA_CompressedAssignments or {}
    TWRA_CompressedAssignments.timestamp = timestamp
    
    -- CRITICAL: Initialize sections table if it doesn't exist yet
    if not TWRA_CompressedAssignments.sections then
        self:Debug("data", "Creating fresh TWRA_CompressedAssignments.sections table")
        TWRA_CompressedAssignments.sections = {}
    end
    
    -- Build minimal skeleton sections
    local sectionsCount = 0
    for index, sectionName in pairs(decodedStructure) do
        if type(index) == "number" and type(sectionName) == "string" then
            -- Create minimal skeleton section entry in TWRA_Assignments
            -- Only include what's absolutely necessary
            TWRA_Assignments.data[index] = {
                ["Section Name"] = sectionName,
                ["NeedsProcessing"] = true
            }
            
            -- Also create empty placeholder in TWRA_CompressedAssignments.sections
            -- Only if preserveCompressedData is false or if the section doesn't already exist
            if not preserveCompressedData or not TWRA_CompressedAssignments.sections[index] then
                TWRA_CompressedAssignments.sections[index] = ""
            end

            sectionsCount = sectionsCount + 1
        end
    end
    
    -- Verify that sections were properly created in both data structures
    local compressedSectionCount = 0
    for index, _ in pairs(TWRA_CompressedAssignments.sections) do
        compressedSectionCount = compressedSectionCount + 1
    end
    
    self:Debug("data", "Built minimal skeleton structure with " .. sectionsCount .. " sections")
    if not preserveCompressedData then
        self:Debug("data", "Created " .. compressedSectionCount .. " empty section placeholders in TWRA_CompressedAssignments.sections")
    else
        self:Debug("data", "Preserved " .. compressedSectionCount .. " existing sections in TWRA_CompressedAssignments.sections")
    end
    
    return true
end

-- Process structure data received from another player
function TWRA:ProcessStructureData(structureData, timestamp, sender)
    self:Debug("sync", "ProcessStructureData: Processing structure data from " .. sender)
    self:Debug("data", "Structure data length: " .. string.len(structureData))
    
    -- First let's verify that the structure data is valid
    if not structureData or type(structureData) ~= "string" then
        self:Debug("sync", "Invalid structure data received from " .. sender)
        return false
    end
    
    -- Attempt to decode the structure to get section information
    local decodedStructure = nil
    self:Debug("sync", "Attempting to decode structure data")
    
    if self.DecompressStructureData then
        -- Use pcall to catch any errors in the decompression process
        local success, result = pcall(function()
            return self:DecompressStructureData(structureData)
        end)
        
        if success and result then
            decodedStructure = result
            self:Debug("sync", "Successfully decompressed structure data with " .. self:GetTableSize(decodedStructure) .. " sections")
        else
            self:Debug("error", "DecompressStructureData failed: " .. tostring(result))
            return false
        end
    else
        self:Debug("sync", "DecompressStructureData function not available")
        return false
    end
    
    -- Verify the decoded structure is a valid table
    if not decodedStructure or type(decodedStructure) ~= "table" then
        self:Debug("sync", "Failed to decode structure data from " .. sender)
        return false
    end
    
    -- Success - we have decoded structure data with section names
    self:Debug("sync", "Structure data decoded successfully with " .. self:GetTableSize(decodedStructure) .. " sections")
    
    -- IMPORTANT: Create or update TWRA_CompressedAssignments with proper initialization
    TWRA_CompressedAssignments = TWRA_CompressedAssignments or {}
    
    -- Store timestamp and structure data first
    TWRA_CompressedAssignments.timestamp = timestamp
    TWRA_CompressedAssignments.structure = structureData
    
    -- CRITICAL: Explicitly initialize the sections table
    TWRA_CompressedAssignments.sections = {}
    
    -- Store the timestamp for section requests
    self.SYNC = self.SYNC or {}
    self.SYNC.cachedTimestamp = timestamp
    
    -- Clear existing data structures to prepare for new structure
    if self.ClearDataForStructureResponse then
        self:ClearDataForStructureResponse()
    else
        -- Fallback in case ClearDataForStructureResponse isn't available
        if TWRA_Assignments then
            -- Preserve timestamp and isExample flag
            local ts = TWRA_Assignments.timestamp
            local isEx = TWRA_Assignments.isExample
            
            -- Clear data table
            TWRA_Assignments.data = {}
            
            -- Restore preserved values
            TWRA_Assignments.timestamp = ts
            TWRA_Assignments.isExample = isEx
        end
    end
    
    -- IMPORTANT: Use BuildSkeletonFromStructure to create section skeletons
    if self.BuildSkeletonFromStructure then
        self:Debug("sync", "Using BuildSkeletonFromStructure to create section skeletons")
        self:BuildSkeletonFromStructure(decodedStructure, timestamp)
    else
        -- Fallback to manual creation if the function is not available
        self:Debug("error", "BuildSkeletonFromStructure not available, falling back to manual skeleton creation")
        
        -- Create or update TWRA_Assignments with proper initialization
        TWRA_Assignments = TWRA_Assignments or {}
        TWRA_Assignments.timestamp = timestamp
        TWRA_Assignments.data = {}
        TWRA_Assignments.isExample = false
        
        -- Create minimal skeleton sections like BuildSkeletonFromStructure would
        for index, sectionName in pairs(decodedStructure) do
            if type(index) == "number" and type(sectionName) == "string" then
                -- Just the bare minimum structure needed
                TWRA_Assignments.data[index] = {
                    ["Section Name"] = sectionName,
                    ["NeedsProcessing"] = true
                }
                self:Debug("sync", "Created skeleton for section " .. index .. ": " .. sectionName)
            end
        end
    end
    
    -- Double-check that both data structures have the same indices
    local compressedIndices = {}
    local assignmentIndices = {}
    
    -- Count compressed indices
    for index, _ in pairs(TWRA_CompressedAssignments.sections) do
        compressedIndices[index] = true
    end
    
    -- Count assignment indices
    for index, _ in pairs(TWRA_Assignments.data) do
        assignmentIndices[index] = true
    end
    
    -- Verify they match
    for index, _ in pairs(assignmentIndices) do
        if not compressedIndices[index] then
            self:Debug("error", "Section index " .. index .. " exists in TWRA_Assignments but not in TWRA_CompressedAssignments")
            -- Auto-fix by creating the missing placeholder
            TWRA_CompressedAssignments.sections[index] = ""
            self:Debug("sync", "Auto-created missing placeholder for section " .. index)
        end
    end
    
    -- Rebuild navigation
    if self.RebuildNavigation then
        self:Debug("sync", "Rebuilding navigation with skeleton structure")
        self:RebuildNavigation()
        self:Debug("sync", "Navigation rebuilt successfully")
    else
        self:Debug("sync", "RebuildNavigation function not available")
    end
    
    -- Mark that we've received structure for this timestamp
    self.SYNC.receivedStructureResponseForTimestamp = timestamp
    
    -- Navigate to pending section if one is set
    if self.SYNC.pendingSection and tonumber(self.SYNC.pendingSection) then
        local pendingSection = tonumber(self.SYNC.pendingSection)
        self:Debug("sync", "Navigating to pending section " .. pendingSection)
        
        if self.NavigateToSection then
            self:NavigateToSection(pendingSection, "fromSync")
            self:Debug("sync", "Navigation to section " .. pendingSection .. " complete")
        else
            self:Debug("error", "NavigateToSection function not available")
        end
        
        -- Clear pending section after use
        self.SYNC.pendingSection = nil
        self:Debug("sync", "Cleared pendingSection after navigation")
    else
        -- If no pending section, navigate to first section
        if TWRA_Assignments.data[1] and self.NavigateToSection then
            self:Debug("sync", "No pending section, navigating to section 1")
            self:NavigateToSection(1, "fromSync")
        end
    end
    
    -- Notify the user that structure has been updated
    local sectionCount = self:GetTableSize(decodedStructure)
    DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA:|r Received structure data from " .. sender .. " with " .. sectionCount .. " sections")
    
    self:Debug("sync", "ProcessStructureData completed successfully")
    return true
end

-- Process section data for a specific section index
function TWRA:ProcessSectionData(sectionIndex)
    self:Debug("data", "Processing section " .. sectionIndex)
    
    -- Check for valid input
    if not sectionIndex or type(sectionIndex) ~= "number" then
        self:Debug("error", "Invalid section index: " .. tostring(sectionIndex))
        return false
    end
    
    -- Ensure we have assignment data
    if not TWRA_Assignments or not TWRA_Assignments.data or not TWRA_Assignments.data[sectionIndex] then
        self:Debug("error", "Section " .. sectionIndex .. " not found in TWRA_Assignments.data")
        return false
    end
    
    -- Check if section data exists in TWRA_CompressedAssignments
    if not TWRA_CompressedAssignments or not TWRA_CompressedAssignments.sections or not TWRA_CompressedAssignments.sections[sectionIndex] then
        self:Debug("error", "No compressed data found for section " .. sectionIndex)
        -- FIXED: Explicitly mark as needing processing since we don't have the data
        if TWRA_Assignments.data[sectionIndex] then
            TWRA_Assignments.data[sectionIndex]["NeedsProcessing"] = true
            self:Debug("data", "Marked section " .. sectionIndex .. " as needing processing (no compressed data)")
        end
        return false
    end
    
    -- Get the compressed section data
    local sectionData = TWRA_CompressedAssignments.sections[sectionIndex]
    if not sectionData or sectionData == "" then
        self:Debug("error", "Empty compressed data for section " .. sectionIndex)
        -- FIXED: Explicitly mark as needing processing for empty data
        if TWRA_Assignments.data[sectionIndex] then
            TWRA_Assignments.data[sectionIndex]["NeedsProcessing"] = true
            self:Debug("data", "Marked section " .. sectionIndex .. " as needing processing (empty data)")
        end
        return false
    end
    
    -- Get the section name for reference
    local sectionName = TWRA_Assignments.data[sectionIndex]["Section Name"]
    if not sectionName then
        self:Debug("error", "Section name not found for index " .. sectionIndex)
        return false
    end
    
    self:Debug("data", "Processing section: " .. sectionName .. " (index: " .. sectionIndex .. ")")
    
    -- IMPORTANT: Always mark as needing processing before attempting decompression
    -- This ensures that if decompression fails, we won't have a false "processed" state
    TWRA_Assignments.data[sectionIndex]["NeedsProcessing"] = true
    
    -- Decompress the section data
    local decompressedData = nil
    
    -- Use pcall to catch any decompression errors
    local success, result = pcall(function()
        if self.DecompressSectionData then
            return self:DecompressSectionData(sectionData)
        else
            self:Debug("error", "DecompressSectionData function not available")
            return nil
        end
    end)
    
    if success and result then
        decompressedData = result
        self:Debug("data", "Successfully decompressed section data for " .. sectionName)
    else
        self:Debug("error", "Failed to decompress section data: " .. tostring(result))
        
        -- Try to provide more diagnostic information
        if sectionData:sub(1, 1) == "?" then
            self:Debug("error", "Section data starts with '?' - may be incorrectly formatted Base64")
        end
        
        -- FIXED: Ensure section is marked as needing processing
        TWRA_Assignments.data[sectionIndex]["NeedsProcessing"] = true
        return false
    end
    
    -- Verify decompressed data is valid
    if not decompressedData then
        self:Debug("error", "Decompression returned nil for section " .. sectionName)
        -- FIXED: Ensure section is marked as needing processing
        TWRA_Assignments.data[sectionIndex]["NeedsProcessing"] = true
        return false
    end
    
    if type(decompressedData) ~= "table" then
        self:Debug("error", "Decompressed data is not a table but " .. type(decompressedData))
        -- FIXED: Ensure section is marked as needing processing
        TWRA_Assignments.data[sectionIndex]["NeedsProcessing"] = true
        return false
    end
    
    -- Validate required section fields
    local isValid = true
    
    if not decompressedData["Section Header"] then
        self:Debug("error", "Decompressed data missing Section Header for " .. sectionName)
        isValid = false
        -- Continue anyway and try to create it
        decompressedData["Section Header"] = decompressedData["Section Header"] or {"Icon", "Target"}
    end
    
    if not decompressedData["Section Rows"] then
        self:Debug("error", "Decompressed data missing Section Rows for " .. sectionName)
        isValid = false
        -- Continue anyway and create empty rows
        decompressedData["Section Rows"] = decompressedData["Section Rows"] or {}
    end
    
    -- ENHANCED VALIDATION: Check if section rows have proper content
    local rowsHaveContent = false
    local totalRows = 0
    local validRows = 0
    
    if decompressedData["Section Rows"] and type(decompressedData["Section Rows"]) == "table" then
        totalRows = table.getn(decompressedData["Section Rows"])
        
        -- Go through each row and validate it has proper content
        for i, row in ipairs(decompressedData["Section Rows"]) do
            if type(row) == "table" and table.getn(row) >= 2 then  -- At minimum should have Icon and Target
                -- For normal rows, check that at least icon or target has content
                if (row[1] and row[1] ~= "") or (row[2] and row[2] ~= "") then
                    validRows = validRows + 1
                end
                
                -- For special rows (Note, Warning, GUID), they're always valid if they have at least 2 columns
                if row[1] == "Note" or row[1] == "Warning" or row[1] == "GUID" then
                    validRows = validRows + 1
                end
            end
        end
        
        -- We consider the section to have content if at least one row is valid
        rowsHaveContent = (validRows > 0)
        
        self:Debug("data", "Section validation: " .. validRows .. " valid rows out of " .. totalRows .. " total rows")
    end
    
    -- Preserve critical fields from existing section data
    local preservedNeedsProcessing = TWRA_Assignments.data[sectionIndex]["NeedsProcessing"]
    local preservedSectionName = TWRA_Assignments.data[sectionIndex]["Section Name"]
    
    -- Replace the entire section with decompressed data
    TWRA_Assignments.data[sectionIndex] = decompressedData
    
    -- Restore the section name to ensure consistency
    TWRA_Assignments.data[sectionIndex]["Section Name"] = preservedSectionName
    
    -- IMPROVED VALIDATION: Only mark as processed if all critical data was properly decompressed
    -- and we have at least one valid row with actual content
    if isValid and rowsHaveContent then
        self:Debug("data", "Section " .. sectionName .. " processed successfully with " .. 
                  validRows .. " valid rows, marking as complete")
        TWRA_Assignments.data[sectionIndex]["NeedsProcessing"] = false
    else
        -- Better logging for why processing is needed
        if not isValid then
            self:Debug("error", "Section " .. sectionName .. " missing required fields, keeping NeedsProcessing flag true")
        elseif not rowsHaveContent then
            self:Debug("error", "Section " .. sectionName .. " has no valid rows with content, keeping NeedsProcessing flag true")
        else
            self:Debug("error", "Section " .. sectionName .. " incomplete for unknown reason, keeping NeedsProcessing flag true")
        end
        
        TWRA_Assignments.data[sectionIndex]["NeedsProcessing"] = true
    end
    
    -- Process player-relevant info for this specific section
    if self.ProcessPlayerInfo then
        self:Debug("data", "Processing player-relevant info for section: " .. sectionName)
        
        local processSuccess, processError = pcall(function()
            self:ProcessPlayerInfo(TWRA_Assignments.data[sectionIndex])
        end)
        
        if not processSuccess then
            self:Debug("error", "Error processing player info for section " .. sectionName .. ": " .. tostring(processError))
        end
    end
    
    return true
end

-- Function to process all sections data
function TWRA:ProcessAllSectionsData(data, sender)
    self:Debug("data", "Processing all sections data from " .. sender)
    
    -- Parse the data format: numSections;index1:len1:data1;index2:len2:data2;...
    local parts = self:SplitString(data, ";")
    local numSections = tonumber(parts[1])
    
    if not numSections then
        self:Debug("error", "Invalid section count in bulk data")
        return
    end
    
    self:Debug("data", "Processing " .. numSections .. " sections")
    
    -- Process each section
    local processedCount = 0
    
    for i = 2, table.getn(parts) do -- The # length operator is not available to us hence the table.getn approach
        if parts[i] and parts[i] ~= "" then
            local sectionParts = self:SplitString(parts[i], ":")
            if table.getns(ectionParts) >= 3 then
                local sectionIndex = tonumber(sectionParts[1])
                local dataLength = tonumber(sectionParts[2])
                local sectionData = sectionParts[3]
                
                if sectionIndex and dataLength and sectionData and string.len(sectionData) == dataLength then
                    -- Process this section
                    self:Debug("sync", "Processing section " .. sectionIndex .. " from bulk data")
                    self:ProcessSectionData(sectionIndex)
                    processedCount = processedCount + 1
                else
                    self:Debug("error", "Invalid section data format in bulk response")
                end
            end
        end
    end
    
    self:Debug("sync", "Finished processing " .. processedCount .. " sections from bulk data")
    
    -- Notify user of completion
    if processedCount > 0 then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA:|r Received and processed " .. 
                                      processedCount .. " sections from " .. sender)
    end
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
    
    -- Log player info for debugging
    self:Debug("data", "Searching for rows relevant to player: " .. playerName, false, true)
    
    -- Scan through rows looking for matches
    for rowIndex, rowData in ipairs(section["Section Rows"]) do
        local isRelevantRow = false
        local matchReason = ""
        
        -- Skip special rows
        if rowData[1] == "Note" or rowData[1] == "Warning" or rowData[1] == "GUID" then
            -- Skip these special rows
        else
            -- Check each cell in the row for a match - SKIP target column (column 2) if configured to do so
            for colIndex, cellValue in ipairs(rowData) do
                -- Skip processing if not a string or empty
                if type(cellValue) ~= "string" or cellValue == "" then
                    -- Skip empty or non-string cells
                elseif colIndex == 2 and self.IGNORE_TARGET_COLUMN_FOR_RELEVANCE then
                    -- Skip target column if configured to ignore it
                else
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
    
    self:Debug("data", "Found " .. table.getn(relevantRows) .. " relevant rows for player: " .. playerName, false, true)
    return relevantRows
end

-- GenerateOSDInfoForSection - Creates a compact representation of player's assignments
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
    
    -- Get tank columns from section metadata
    local metadata = section["Section Metadata"] or {}
    local tankColumns = metadata["Tank Columns"] or {}
    
    -- For each relevant row, extract useful information
    for _, rowIndex in ipairs(relevantRows) do
        local rowData = section["Section Rows"][rowIndex]
        
        -- Skip this if we don't have valid row data
        if not rowData or type(rowData) ~= "table" then
            self:Debug("data", "Skipping invalid row " .. rowIndex, false, true)
        -- Skip special rows
        elseif rowData[1] == "Note" or rowData[1] == "Warning" or rowData[1] == "GUID" then
            self:Debug("data", "Skipping special row " .. rowIndex, false, true)
        else
            -- Extract target and icon info (columns 1 and 2)
            local icon = rowData[1] or ""
            local target = rowData[2] or ""
            
            -- Find role columns where player is mentioned (columns 3+)
            local playerRoles = {}
            
            -- Start at column 3 (after icon and target)
            for colIndex = 3, table.getn(rowData) do
                if colIndex <= table.getn(section["Section Header"]) then
                    local headerText = section["Section Header"][colIndex]
                    local cellText = rowData[colIndex]
                    
                    -- For personal assignments or group assignments
                    if (not isGroupAssignments and self:IsCellRelevantForPlayer(cellText)) or
                       (isGroupAssignments and self:IsCellRelevantForPlayerGroup(cellText)) then
                        table.insert(playerRoles, {
                            role = headerText,
                            column = colIndex
                        })
                        self:Debug("data", "Found role " .. headerText .. " in row " .. rowIndex .. 
                                  ", column " .. colIndex, false, true)
                    end
                end
            end
            
            -- Extract tank names from this row
            local tankNames = {}
            for _, tankCol in ipairs(tankColumns) do
                if tankCol <= table.getn(rowData) and rowData[tankCol] and rowData[tankCol] ~= "" then
                    -- Avoid adding player's own name to tank list
                    if rowData[tankCol] ~= UnitName("player") then
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
                
                -- Format: [Role, Icon, Target, Tank1, Tank2, ...]
                table.insert(entry, roleInfo.role)  -- Role
                table.insert(entry, icon)           -- Icon
                table.insert(entry, target)         -- Target
                
                -- Add all tank names
                for _, tankName in ipairs(tankNames) do
                    table.insert(entry, tankName)   -- Tank name
                end
                
                -- Add the entry to our results
                table.insert(osdInfo, entry)
                
                self:Debug("data", "Added OSD entry for role " .. roleInfo.role .. 
                          " on target " .. target .. " with " .. 
                          table.getn(tankNames) .. " tanks", false, true)
            end
        end
    end
    
    self:Debug("data", "Generated " .. table.getn(osdInfo) .. " OSD info entries")
    return osdInfo
end

-- Get ALL rows containing ANY group references
function TWRA:GetAllGroupRowsForSection(section)
    local allGroupRows = {}
    
    -- Skip if no rows
    if not section["Section Rows"] then
        self:Debug("data", "No Section Rows found in GetAllGroupRowsForSection", false, true)
        return allGroupRows
    end
    
    self:Debug("data", "Scanning for explicit group references in section: " .. (section["Section Name"] or "Unknown"), false, true)
    
    -- Check each row for group references - ONLY explicit ones
    for rowIdx, rowData in ipairs(section["Section Rows"]) do
        -- Skip if rowData is not a table
        if type(rowData) ~= "table" then
            self:Debug("data", "Row " .. rowIdx .. " is not a table, skipping", false, true)
        -- Skip special rows
        elseif rowData[1] == "Note" or rowData[1] == "Warning" or rowData[1] == "GUID" then
            self:Debug("data", "Row " .. rowIdx .. " is a special row, skipping", false, true)
        else
            local foundGroupRef = false
            local matchedCell = ""
            local matchedColumn = 0
            
            -- IMPORTANT: Check all columns EXCEPT icon and target (columns 1 and 2)
            -- Start from column 3 and check all remaining columns
            for colIndex = 3, table.getn(rowData) do
                if type(rowData[colIndex]) == "string" and rowData[colIndex] ~= "" then
                    local cellValue = rowData[colIndex]
                    local lowerCell = string.lower(cellValue)
                    
                    -- Check for group references using various patterns
                    -- Note the explicit space matching with %s* for optional spaces
                    if string.find(lowerCell, "group%s+") or     -- "Group " with trailing space
                       string.find(lowerCell, "groups%s+") or    -- "Groups " with trailing space
                       string.find(lowerCell, "gr%s+") or        -- "Gr " with trailing space
                       string.find(lowerCell, "gr%.%s*") or      -- "Gr." with optional space
                       string.find(lowerCell, "grp%s*") then     -- "Grp" with optional space
                        
                        foundGroupRef = true
                        matchedCell = cellValue
                        matchedColumn = colIndex
                        self:Debug("data", "Found group reference in row " .. rowIdx .. 
                                 " column " .. colIndex ..
                                 ": '" .. cellValue .. "'", false, true)
                        break  -- Found a match, no need to check other columns
                    end
                end
            end
            
            -- Add to our list if we found a group reference
            if foundGroupRef then
                table.insert(allGroupRows, rowIdx)
                self:Debug("data", "Found group reference in row " .. rowIdx .. 
                         " column " .. matchedColumn ..
                         ": '" .. matchedCell .. "'", false, true)
            end
        end
    end
    
    self:Debug("data", "Found " .. table.getn(allGroupRows) .. " rows with group references", false, true)
    
    -- CRITICAL: Persist this information into the section metadata immediately
    if section["Section Metadata"] then
        section["Section Metadata"]["Group Rows"] = allGroupRows
        self:Debug("data", "Stored " .. table.getn(allGroupRows) .. 
                  " group rows in section metadata", false, true)
    end
    
    return allGroupRows
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
            -- Check each cell for group references, SKIP column 2 (target column)
            for colIndex, cellValue in ipairs(rowData) do
                -- Skip target column (column 2)
                if colIndex ~= 2 and type(cellValue) == "string" and cellValue ~= "" then
                    -- Look for "Group X" format
                    if string.find(string.lower(cellValue), "group%s*" .. playerGroup) then
                        table.insert(groupRows, rowIdx)
                        self:Debug("data", "Found group row " .. rowIdx .. " for group " .. playerGroup .. " in column " .. colIndex, false, true)
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
                                self:Debug("data", "Found group row " .. rowIdx .. " for group " .. playerGroup .. " in column " .. colIndex, false, true)
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

-- Check if a cell contains the player's name or class group
function TWRA:IsCellContainingPlayerNameOrClass(cellText, isTargetColumn)
    -- Skip empty cells or non-string cells
    if not cellText or type(cellText) ~= "string" or cellText == "" then
        return false
    end
    
    -- Get player info
    local playerName = UnitName("player")
    local _, playerClass = UnitClass("player")
    playerClass = playerClass and string.upper(playerClass) or nil
    
    -- Direct player name match
    if cellText == playerName then
        self:Debug("data", "Cell contains direct player name match: " .. cellText, false, true)
        return true
    end
    
    -- Class group match (e.g. "Warriors" for a Warrior)
    if not isTargetColumn and playerClass and self.CLASS_GROUP_NAMES and 
       self.CLASS_GROUP_NAMES[cellText] and 
       string.upper(self.CLASS_GROUP_NAMES[cellText]) == playerClass then
        self:Debug("data", "Cell contains class group match: " .. cellText, false, true)
        return true
    end
    
    -- No match found
    return false
end

-- Helper function to check if a cell is relevant for the player's current group
function TWRA:IsCellRelevantForPlayerGroup(cellText)
    -- Skip empty cells or non-string cells
    if not cellText or type(cellText) ~= "string" or cellText == "" then
        return false
    end
    
    -- Find player's group number (1-8)
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
    
    -- Look for group references
    local lowerCell = string.lower(cellText)
    
    -- First, check if this is a group-related cell by looking for common group patterns
    -- This is just a quick pre-check to filter out non-group cells
    if string.find(lowerCell, "group") or 
       string.find(lowerCell, "gr%.") or 
       string.find(lowerCell, "gr ") or
       string.find(lowerCell, "grp") then
        
        -- Optimize by directly looking for the group number
        -- This approach focuses more on numeric matching than text patterns
        local pos = 1
        local str = lowerCell
        while pos <= string.len(str) do
            local digitStart, digitEnd = string.find(str, "%d+", pos)
            if not digitStart then break end
            
            local groupNum = tonumber(string.sub(str, digitStart, digitEnd))
            if groupNum and groupNum == playerGroup then
                self:Debug("data", "Cell relevant for player's group " .. playerGroup .. 
                          " (numeric reference): " .. cellText, false, true)
                return true
            end
            pos = digitEnd + 1
        end
    end
    
    -- No match found
    return false
end

-- UpdateGroupInfo - Called when player's group changes to update relevant information
function TWRA:UpdateGroupInfo()
    self:Debug("data", "Updating player group information for all sections")
    
    -- Get player's current group
    local playerName = UnitName("player")
    local playerGroup = nil
    for i = 1, GetNumRaidMembers() do
        local name, _, subgroup = GetRaidRosterInfo(i)
        if name == playerName then
            playerGroup = subgroup
            break
        end
    end
    
    if playerGroup then
        self:Debug("data", "Player is in group " .. playerGroup)
    else
        self:Debug("data", "Player is not in a raid group")
    end
    
    -- Only update dynamic player info (based on group), no need to update static player info
    self:ProcessDynamicPlayerInfo()
    
    -- Update UI if a section is currently active
    if self.navigation and self.navigation.currentIndex and 
       self.navigation.handlers and table.getn(self.navigation.handlers) > 0 then
        local currentSection = self.navigation.handlers[self.navigation.currentIndex]
        
        -- Refresh UI if needed
        if self.mainFrame and self.mainFrame:IsShown() and
           self.currentView == "main" and self.FilterAndDisplayHandler then
            self:FilterAndDisplayHandler(currentSection)
            self:Debug("ui", "Refreshed UI for current section after group change")
        end
        
        -- Refresh OSD if it's showing
        if self.OSD and self.OSD.isVisible then
            self:UpdateOSDContent()
            self:Debug("osd", "Refreshed OSD after group change")
        end
    end
    
    return true
end

-- Monitor player's raid group changes
function TWRA:MonitorGroupChanges()
    self:Debug("data", "Setting up group change monitoring")
    
    -- Set up event handler to detect when player joins/leaves a group
    if not self.groupMonitorFrame then
        self.groupMonitorFrame = CreateFrame("Frame")
        
        -- Track the last known group
        self.lastKnownGroup = nil
        
        -- Create function to check if group has changed
        self.CheckGroupChanged = function()
            -- Get current group
            local playerName = UnitName("player")
            local currentGroup = nil
            
            for i = 1, GetNumRaidMembers() do
                local name, _, subgroup = GetRaidRosterInfo(i)
                if name == playerName then
                    currentGroup = subgroup
                    break
                end
            end
            
            -- If group has changed, update info
            if self.lastKnownGroup ~= currentGroup then
                self:Debug("data", "Player's group changed from " .. 
                          (self.lastKnownGroup or "none") .. " to " .. 
                          (currentGroup or "none"))
                
                -- Update last known group
                self.lastKnownGroup = currentGroup
                
                -- Update group-related information
                self:UpdateGroupInfo()
            end
        end
        
        -- Handle RAID_ROSTER_UPDATE event
        self.groupMonitorFrame:RegisterEvent("RAID_ROSTER_UPDATE")
        self.groupMonitorFrame:RegisterEvent("GROUP_ROSTER_UPDATE") -- For compatibility with newer clients
        self.groupMonitorFrame:RegisterEvent("PARTY_MEMBERS_CHANGED") -- For classic compatibility
        
        self.groupMonitorFrame:SetScript("OnEvent", function()
            -- Wait a short delay to ensure all roster changes have processed
            self:ScheduleTimer(self.CheckGroupChanged, 0.5)
        end)
        
        -- Initialize last known group
        self:ScheduleTimer(function()
            local playerName = UnitName("player")
            for i = 1, GetNumRaidMembers() do
                local name, _, subgroup = GetRaidRosterInfo(i)
                if name == playerName then
                    self.lastKnownGroup = subgroup
                    self:Debug("data", "Initial group: " .. (self.lastKnownGroup or "none"))
                    break
                end
            end
        end, 1)
        
        self:Debug("data", "Group monitoring activated")
    end
end

-- Initialize group monitoring during addon startup
function TWRA:InitializeGroupMonitoring()
    self:Debug("data", "Setting up group monitoring during initialization")
    self:MonitorGroupChanges()
end

-- Function to ensure group rows are identified in all sections
function TWRA:EnsureGroupRowsIdentified()
    if not TWRA_Assignments or not TWRA_Assignments.data then
        self:Debug("error", "EnsureGroupRowsIdentified: No assignments data to process")
        return false
    end
    
    self:Debug("data", "Ensuring group rows are identified in all sections")
    
    -- Process each section
    for sectionIdx, section in pairs(TWRA_Assignments.data) do
        -- Skip if not a table or doesn't have required keys
        if type(section) == "table" and section["Section Rows"] then
            -- Ensure group rows are identified
            section["Section Metadata"] = section["Section Metadata"] or {}
            section["Section Metadata"]["Group Rows"] = section["Section Metadata"]["Group Rows"] or self:GetAllGroupRowsForSection(section)
            
            self:Debug("data", "Section '" .. (section["Section Name"] or tostring(sectionIdx)) .. 
                      "': Identified " .. table.getn(section["Section Metadata"]["Group Rows"]) .. " group rows")
        end
    end
    
    return true
end

-- Helper function to find columns containing tank roles
function TWRA:FindTankRoleColumns(section)
    local tankColumns = {}
    
    -- Skip if no header or rows
    if not section["Section Header"] then
        return tankColumns
    end
    
    -- Look through header to find any tank related column
    for colIndex, headerText in ipairs(section["Section Header"]) do
        -- Skip first two columns (icon and target)
        if colIndex > 2 and type(headerText) == "string" then
            -- Look for common tank role terms
            local lowerHeader = string.lower(headerText)
            if string.find(lowerHeader, "tank") or 
               string.find(lowerHeader, "mt") or 
               string.find(lowerHeader, "ot") or
               string.find(lowerHeader, "maintank") or
               string.find(lowerHeader, "main tank") or
               string.find(lowerHeader, "offtank") or
               string.find(lowerHeader, "off tank") or
               string.find(lowerHeader, "t1") or
               string.find(lowerHeader, "t2") or
               string.find(lowerHeader, "t3") or
               string.find(lowerHeader, "t4") or
               string.find(lowerHeader, "tank1") or
               string.find(lowerHeader, "tank2") or
               string.find(lowerHeader, "tank3") or
               string.find(lowerHeader, "tank4") then
                
                table.insert(tankColumns, colIndex)
                self:Debug("data", "Found tank column at index " .. colIndex .. ": " .. headerText, false, true)
            end
        end
    end
    
    self:Debug("data", "Found " .. table.getn(tankColumns) .. " tank columns in section")
    return tankColumns
end

-- Helper function to check if a cell is relevant for the current player
function TWRA:IsCellRelevantForPlayer(cellText)
    -- Skip empty cells or non-string cells
    if not cellText or type(cellText) ~= "string" or cellText == "" then
        return false
    end
    
    -- Get player info
    local playerName = UnitName("player")
    local _, playerClass = UnitClass("player")
    playerClass = playerClass and string.upper(playerClass) or nil
    
    -- Direct player name match
    if cellText == playerName then
        self:Debug("data", "Cell contains direct player name match: " .. cellText, false, true)
        return true
    end
    
    -- Class group match (e.g. "Warriors" for a Warrior)
    if playerClass and self.CLASS_GROUP_NAMES then
        for groupName, className in pairs(self.CLASS_GROUP_NAMES) do
            if cellText == groupName and string.upper(className) == playerClass then
                self:Debug("data", "Cell contains class group match: " .. cellText, false, true)
                return true
            end
        end
    end
    
    -- No match found
    return false
end

-- Helper function to check if a cell is relevant for the player's current group
function TWRA:IsCellRelevantForPlayerGroup(cellText)
    -- Skip empty cells or non-string cells
    if not cellText or type(cellText) ~= "string" or cellText == "" then
        return false
    end
    
    -- Find player's group number (1-8)
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
    
    -- Look for group references
    local lowerCell = string.lower(cellText)
    
    -- First, check if this is a group-related cell by looking for common group patterns
    -- This is just a quick pre-check to filter out non-group cells
    if string.find(lowerCell, "group") or 
       string.find(lowerCell, "gr%.") or 
       string.find(lowerCell, "gr ") or
       string.find(lowerCell, "grp") then
        
        -- Optimize by directly looking for the group number
        -- This approach focuses more on numeric matching than text patterns
        local pos = 1
        local str = lowerCell
        while pos <= string.len(str) do
            local digitStart, digitEnd = string.find(str, "%d+", pos)
            if not digitStart then break end
            
            local groupNum = tonumber(string.sub(str, digitStart, digitEnd))
            if groupNum and groupNum == playerGroup then
                self:Debug("data", "Cell relevant for player's group " .. playerGroup .. 
                          " (numeric reference): " .. cellText, false, true)
                return true
            end
            pos = digitEnd + 1
        end
    end
    
    -- No match found
    return false
end