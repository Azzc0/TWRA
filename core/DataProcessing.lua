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
    playerClass = playerClass and string.upper(playerClass) or nil
    
    self:Debug("data", "Static player info: " .. playerName .. 
              ", class: " .. (playerClass or "unknown"))
    
    -- Skip if we don't have saved data
    if not TWRA_Assignments or not TWRA_Assignments.data then
        self:Debug("data", "No saved data available for processing")
        return
    end
    
    -- Process each section in the data or just the specified section
    local sectionsProcessed = 0
    
    -- If a specific section was provided, just process that one
    if section and type(section) == "table" and section["Section Name"] then
        self:ProcessStaticPlayerInfoForSection(section)
        sectionsProcessed = 1
    else
        -- Process all sections
        for _, sectionData in pairs(TWRA_Assignments.data) do
            -- We're only working with table sections (new format)
            if type(sectionData) == "table" and sectionData["Section Name"] then
                self:ProcessStaticPlayerInfoForSection(sectionData)
                sectionsProcessed = sectionsProcessed + 1
            end
        end
    end
    
    self:Debug("data", "Processed static player info for " .. sectionsProcessed .. " sections")
    return true
end

-- Helper function to process static player info for a specific section
function TWRA:ProcessStaticPlayerInfoForSection(section)
    local sectionName = section["Section Name"]
    
    -- Ensure Section Player Info exists
    section["Section Player Info"] = section["Section Player Info"] or {}
    
    -- Ensure Section Metadata exists, but no need to recreate it
    -- since it's already processed during import in Base64.lua
    section["Section Metadata"] = section["Section Metadata"] or {}
    
    -- Access the metadata that was created during import
    local metadata = section["Section Metadata"]
    local playerInfo = section["Section Player Info"]
    
    -- Get tank columns from metadata if they exist, otherwise find them
    metadata["Tank Columns"] = metadata["Tank Columns"] or self:FindTankRoleColumns(section)
    local tanksCount = table.getn(metadata["Tank Columns"])
    
    -- Generate list of tank indices for debugging
    local tanksList = ""
    for i, tankIndex in ipairs(metadata["Tank Columns"]) do
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
    
    self:Debug("data", "Dynamic player info: group: " .. (playerGroup or "none"))
    
    -- Skip if we don't have saved data
    if not TWRA_Assignments or not TWRA_Assignments.data then
        self:Debug("data", "No saved data available for processing")
        return
    end
    
    -- Process each section in the data or just the specified section
    local sectionsProcessed = 0
    
    -- If a specific section was provided, just process that one
    if section and type(section) == "table" and section["Section Name"] then
        self:ProcessDynamicPlayerInfoForSection(section)
        sectionsProcessed = 1
    else
        -- Process all sections
        for _, sectionData in pairs(TWRA_Assignments.data) do
            -- We're only working with table sections (new format)
            if type(sectionData) == "table" and sectionData["Section Name"] then
                self:ProcessDynamicPlayerInfoForSection(sectionData)
                sectionsProcessed = sectionsProcessed + 1
            end
        end
    end
    
    self:Debug("data", "Processed dynamic player info for " .. sectionsProcessed .. " sections")
    return true
end

-- Helper function to process dynamic player info for a specific section
function TWRA:ProcessDynamicPlayerInfoForSection(section)
    local sectionName = section["Section Name"]
    
    -- Initialize the metadata and player info tables if needed
    section["Section Metadata"] = section["Section Metadata"] or {}
    section["Section Player Info"] = section["Section Player Info"] or {}
    
    local metadata = section["Section Metadata"]
    local playerInfo = section["Section Player Info"]
    
    -- Identify all group rows (rows containing any group reference) - moved to section metadata
    metadata["Group Rows"] = self:GetAllGroupRowsForSection(section)
    
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
                
                -- IMPORTANT: Process special rows (Note, Warning, GUID) and store in metadata
                if section["Section Rows"] and type(section["Section Rows"]) == "table" then
                    local metadata = section["Section Metadata"]
                    
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
function TWRA:BuildSkeletonFromStructure(decodedStructure, timestamp)
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
    -- This centralizes section placeholder creation in one place
    TWRA_CompressedAssignments = TWRA_CompressedAssignments or {}
    TWRA_CompressedAssignments.timestamp = timestamp
    
    -- CRITICAL: Explicitly clear existing sections and create a fresh table
    -- This ensures a clean start without any stale section data
    TWRA_CompressedAssignments.sections = {}
    
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
            TWRA_CompressedAssignments.sections[index] = ""
            
            sectionsCount = sectionsCount + 1
        end
    end
    
    -- Verify that sections were properly created in both data structures
    local compressedSectionCount = 0
    for index, _ in pairs(TWRA_CompressedAssignments.sections) do
        compressedSectionCount = compressedSectionCount + 1
    end
    
    self:Debug("data", "Built minimal skeleton structure with " .. sectionsCount .. " sections")
    self:Debug("data", "Created " .. compressedSectionCount .. " empty section placeholders in TWRA_CompressedAssignments.sections")
    
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

-- Process section data received from another player
function TWRA:ProcessSectionData(sectionIndex, sectionData, timestamp, sender)
    self:Debug("sync", "Processing section " .. sectionIndex .. " data from " .. (sender or "local"))
    
    -- Check for valid inputs
    if not sectionIndex or not sectionData or sectionData == "" then
        self:Debug("error", "Invalid section data or index")
        return false
    end
    
    -- Store the section name for reference
    local sectionName = nil
    if TWRA_Assignments and TWRA_Assignments.data then
        for idx, section in pairs(TWRA_Assignments.data) do
            if type(section) == "table" and 
               ((section["Section Index"] and section["Section Index"] == sectionIndex) or 
                (idx == sectionIndex)) then
                sectionName = section["Section Name"]
                break
            end
        end
    end
    
    -- If we don't have a section name, can't proceed
    if not sectionName then
        self:Debug("error", "Cannot find section name for index " .. sectionIndex)
        return false
    end
    
    self:Debug("sync", "Processing section: " .. sectionName .. " (index: " .. sectionIndex .. ")")
    
    -- Decompress the section data
    local decompressedData = nil
    if self.DecompressSectionData then
        -- Use pcall to catch any decompression errors
        local success, result = pcall(function()
            return self:DecompressSectionData(sectionData)
        end)
        
        if success and result then
            decompressedData = result
            self:Debug("sync", "Successfully decompressed section data")
        else
            self:Debug("error", "Failed to decompress section data: " .. tostring(result))
            return false
        end
    else
        self:Debug("error", "DecompressSectionData function not available")
        return false
    end
    
    -- Verify decompressed data is valid
    if not decompressedData or type(decompressedData) ~= "table" then
        self:Debug("error", "Decompressed data is not valid")
        return false
    end
    
    -- Find the section in TWRA_Assignments.data
    local sectionFound = false
    local processedSection = nil
    if TWRA_Assignments and TWRA_Assignments.data then
        for idx, section in pairs(TWRA_Assignments.data) do
            if type(section) == "table" and section["Section Name"] == sectionName then
                -- We found the section, update it with the decompressed data
                
                -- Preserve metadata that might have been added
                local existingMetadata = section["Section Metadata"] or {}
                
                -- Replace section content with decompressed data
                for key, value in pairs(decompressedData) do
                    if key ~= "Section Metadata" then
                        section[key] = value
                    end
                end
                
                -- Ensure Metadata exists and merge with existing metadata
                section["Section Metadata"] = section["Section Metadata"] or {}
                if existingMetadata then
                    -- Preserve notes, warnings, GUIDs
                    for metaKey, metaValue in pairs(existingMetadata) do
                        if metaKey == "Note" or metaKey == "Warning" or metaKey == "GUID" then
                            section["Section Metadata"][metaKey] = metaValue
                        end
                    end
                end
                
                -- Mark as processed
                section["NeedsProcessing"] = false
                
                self:Debug("sync", "Updated section " .. sectionName .. " with processed data")
                sectionFound = true
                processedSection = section
                break
            end
        end
    end
    
    -- If section wasn't found, create it
    if not sectionFound then
        TWRA_Assignments = TWRA_Assignments or {}
        TWRA_Assignments.data = TWRA_Assignments.data or {}
        
        -- Create new section with the decompressed data
        decompressedData["Section Name"] = sectionName
        decompressedData["Section Index"] = sectionIndex
        decompressedData["NeedsProcessing"] = false
        decompressedData["Section Metadata"] = decompressedData["Section Metadata"] or {
            ["Note"] = {},
            ["Warning"] = {},
            ["GUID"] = {}
        }
        
        -- Add to TWRA_Assignments.data
        TWRA_Assignments.data[sectionIndex] = decompressedData
        self:Debug("sync", "Created new section " .. sectionName .. " with processed data")
        processedSection = decompressedData
    end
    
    -- Process player-relevant info for JUST this section (using our new functionality)
    if self.ProcessPlayerInfo and processedSection then
        self:Debug("data", "Processing player-relevant info for just the updated section")
        self:ProcessPlayerInfo(processedSection)
    else
        -- Fallback to processing all sections if something went wrong or old function is being used
        self:Debug("data", "Falling back to processing player info for all sections")
        self:ProcessPlayerInfo()
    end
    
    self:Debug("sync", "Successfully processed section " .. sectionName)
    return true
end

--- Didn't we refactor out these functions befo

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
            -- Check each cell in the row for a match - SKIP column 2 (target column)
            for colIndex, cellValue in ipairs(rowData) do
                -- Only process string values and skip the target column (column 2)
                if colIndex ~= 2 and type(cellValue) == "string" and cellValue ~= "" then
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
    
    -- Get tank columns from section metadata
    local metadata = section["Section Metadata"] or {}
    local tankColumns = metadata["Tank Columns"] or self:FindTankRoleColumns(section)
    local playerName = UnitName("player")
    
    -- For each relevant row, extract useful information
    for _, rowIndex in ipairs(relevantRows) do
        local rowData = section["Section Rows"][rowIndex]
        
        -- Skip this if we don't have valid row data
        if not rowData then
            self:Debug("data", "Skipping invalid row " .. rowIndex, false, true)
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
                        -- Pass false for isTargetColumn since we're processing role columns (3+) here
                        isRelevantCell = self:IsCellContainingPlayerNameOrClass(cellText, false)
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
            -- Check each cell for group references, SKIP column 2 (target column)
            for colIndex, cellValue in ipairs(rowData) do
                -- Skip target column (column 2)
                if colIndex ~= 2 and type(cellValue) == "string" and cellValue ~= "" then
                    -- Look for "Group" keyword
                    if string.find(string.lower(cellValue), "group") then
                        table.insert(allGroupRows, rowIdx)
                        self:Debug("data", "Found group reference in row " .. rowIdx .. ", column " .. colIndex, false, true)
                        break
                    end
                end
            end
        end
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