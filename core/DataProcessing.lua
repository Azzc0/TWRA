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
                    -- Track rows to be removed (Image rows)
                    local rowsToRemove = {}
                    -- Track image references found
                    local imageRefs = {}
                    
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
                            -- Handle Image rows by storing data in section metadata and marking for removal
                            elseif rowData[1] == "Image" and rowData[2] and rowData[2] ~= "" then
                                -- Get the image reference from column 2
                                local imageRef = rowData[2]
                                
                                -- Add to our list of image references
                                table.insert(imageRefs, imageRef)
                                
                                -- Mark this row for removal
                                table.insert(rowsToRemove, rowIdx)
                                
                                self:Debug("data", "Found image reference '" .. imageRef .. "' in section " .. sectionIdx)
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
                    
                    -- Store the image references in section metadata
                    if table.getn(imageRefs) > 0 then
                        -- Ensure Section Metadata exists
                        section["Section Metadata"] = section["Section Metadata"] or {}
                        
                        -- If we have just one image, store it directly
                        if table.getn(imageRefs) == 1 then
                            section["Section Metadata"]["Image"] = imageRefs[1]
                            self:Debug("data", "Stored image reference '" .. imageRefs[1] .. "' in section metadata for section " .. sectionIdx)
                        else
                            -- If we have multiple images, store them as an array
                            section["Section Metadata"]["Images"] = imageRefs
                            self:Debug("data", "Stored " .. table.getn(imageRefs) .. " image references in section metadata for section " .. sectionIdx)
                        end
                    end
                    
                    -- Remove rows that were marked for removal (Image rows)
                    -- We need to remove in reverse order to avoid shifting indices
                    table.sort(rowsToRemove, function(a, b) return a > b end)
                    for _, rowIdx in ipairs(rowsToRemove) do
                        table.remove(section["Section Rows"], rowIdx)
                    end
                    
                    if table.getn(rowsToRemove) > 0 then
                        self:Debug("data", "Removed " .. table.getn(rowsToRemove) .. " Image rows from section " .. sectionIdx)
                    end
                end
            else
                self:Debug("data", "EnsureCompleteRows: Section " .. tostring(sectionIdx) .. " is not a table")
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


-- Process section data for a specific section index or all sections if no index provided
function TWRA:ProcessSectionData(sectionIndex)
    -- Determine which sections to process
    local sectionsToProcess = {}
    local processedCount = 0
    local errorCount = 0
    
    if sectionIndex then
        -- Single section mode
        self:Debug("data", "Processing single section: " .. sectionIndex)
        table.insert(sectionsToProcess, sectionIndex)
    else
        -- All sections mode
        self:Debug("data", "Processing all sections")
        if TWRA_Assignments and TWRA_Assignments.data then
            for idx, _ in pairs(TWRA_Assignments.data) do
                if type(idx) == "number" then
                    table.insert(sectionsToProcess, idx)
                end
            end
        end
    end
    
    -- Initialize section tracking
    TWRA_CompressedAssignments = TWRA_CompressedAssignments or {}
    TWRA_CompressedAssignments.sections = TWRA_CompressedAssignments.sections or {}
    TWRA_CompressedAssignments.sections.missing = TWRA_CompressedAssignments.sections.missing or {}
    
    -- Process each section in our list
    for _, idx in ipairs(sectionsToProcess) do
        -- Ensure we have assignment data
        if not TWRA_Assignments or not TWRA_Assignments.data or not TWRA_Assignments.data[idx] then
            self:Debug("error", "Section " .. idx .. " not found in TWRA_Assignments.data")
            errorCount = errorCount + 1
        else
            -- Check if section data exists in TWRA_CompressedAssignments
            if not TWRA_CompressedAssignments or not TWRA_CompressedAssignments.sections or not TWRA_CompressedAssignments.sections[idx] then
                self:Debug("error", "No compressed data found for section " .. idx)
                -- FIXED: Explicitly mark as needing processing since we don't have the data
                if TWRA_Assignments.data[idx] then
                    TWRA_Assignments.data[idx]["NeedsProcessing"] = true
                    self:Debug("data", "Marked section " .. idx .. " as needing processing (no compressed data)")
                    
                    -- Add to missing sections tracking
                    TWRA_CompressedAssignments.sections.missing[idx] = true
                    self:Debug("data", "Added section " .. idx .. " to missing sections tracking")
                end
                errorCount = errorCount + 1
            else
                -- Get the section name for reference
                local sectionName = TWRA_Assignments.data[idx]["Section Name"]
                if not sectionName then
                    self:Debug("error", "Section name not found for index " .. idx)
                    errorCount = errorCount + 1
                else
                    -- Check if this is a pending chunked section
                    local isPendingChunkedSection = false
                    if self.SYNC and self.SYNC.pendingChunkedSections then
                        for sectionIndex, info in pairs(self.SYNC.pendingChunkedSections) do
                            if sectionIndex == idx then
                                self:Debug("data", "Section " .. idx .. " (" .. sectionName .. ") is a pending chunked section")
                                isPendingChunkedSection = true
                                
                                -- Mark it as needing processing but don't add to missing sections
                                TWRA_Assignments.data[idx]["NeedsProcessing"] = true
                                
                                -- We don't add it to missing sections here since it's expected to be filled by chunk processing
                                break
                            end
                        end
                    end
                    
                    -- Only process if it's not a pending chunked section
                    if not isPendingChunkedSection then
                        -- Get the compressed section data
                        local sectionData = TWRA_CompressedAssignments.sections[idx]
                        local decompressedData = nil
                        
                        if sectionData and sectionData ~= "" then
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
                                
                                -- Remove from missing sections tracking if it was there
                                if TWRA_CompressedAssignments.sections.missing[idx] then
                                    TWRA_CompressedAssignments.sections.missing[idx] = nil
                                    self:Debug("data", "Removed section " .. idx .. " from missing sections tracking")
                                end
                            else
                                self:Debug("error", "Failed to decompress section data: " .. tostring(result))
                                
                                -- Try to provide more diagnostic information
                                if sectionData:sub(1, 1) == "?" then
                                    self:Debug("error", "Section data starts with '?' - may be incorrectly formatted Base64")
                                end
                                
                                -- FIXED: Ensure section is marked as needing processing
                                TWRA_Assignments.data[idx]["NeedsProcessing"] = true
                                
                                -- Add to missing sections tracking
                                TWRA_CompressedAssignments.sections.missing[idx] = true
                                self:Debug("data", "Added section " .. idx .. " to missing sections tracking (decompression failed)")
                                
                                errorCount = errorCount + 1
                            end
                            
                            -- Continue only if decompression was successful
                            if decompressedData and type(decompressedData) == "table" then
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
                                
                                -- Check if rows actually have any content
                                local rowsHaveContent = false
                                local validRows = 0
                                local totalRows = 0
                                
                                if decompressedData["Section Rows"] then
                                    totalRows = table.getn(decompressedData["Section Rows"])
                                    
                                    for _, row in ipairs(decompressedData["Section Rows"]) do
                                        -- Verify row is a table
                                        if type(row) == "table" then
                                            -- MODIFIED: For standard data rows, check if they have first two columns (icon and target) present at all
                                            -- Regardless of whether they contain empty strings or actual content
                                            if row[1] ~= nil and row[2] ~= nil then
                                                validRows = validRows + 1
                                            end
                                            
                                            -- Also count special rows (Notes/Warnings/GUIDs) as valid
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
                                local preservedNeedsProcessing = TWRA_Assignments.data[idx]["NeedsProcessing"]
                                local preservedSectionName = TWRA_Assignments.data[idx]["Section Name"]
                                
                                -- Also preserve any existing metadata before overwriting the section
                                local preservedMetadata = nil
                                if TWRA_Assignments.data[idx]["Section Metadata"] then
                                    preservedMetadata = self:DeepCopy(TWRA_Assignments.data[idx]["Section Metadata"])
                                    self:Debug("data", "Preserved existing metadata for section " .. sectionName)
                                end
                                
                                -- Replace the entire section with decompressed data
                                TWRA_Assignments.data[idx] = decompressedData
                                
                                -- Restore the section name to ensure consistency
                                TWRA_Assignments.data[idx]["Section Name"] = preservedSectionName
                                
                                -- Ensure Section Metadata exists
                                TWRA_Assignments.data[idx]["Section Metadata"] = TWRA_Assignments.data[idx]["Section Metadata"] or {}
                                
                                -- Restore or merge preserved metadata
                                if preservedMetadata then
                                    -- Don't completely overwrite - merge instead
                                    for key, value in pairs(preservedMetadata) do
                                        -- Only restore if the key doesn't already exist in the new metadata
                                        if not TWRA_Assignments.data[idx]["Section Metadata"][key] then
                                            TWRA_Assignments.data[idx]["Section Metadata"][key] = value
                                            self:Debug("data", "Restored metadata key: " .. key .. " for section " .. sectionName)
                                        end
                                    end
                                end
                                    
                                -- IMPROVED VALIDATION: Only mark as processed if all critical data was properly decompressed
                                -- and we have at least one valid row with actual content
                                if isValid and rowsHaveContent then
                                    self:Debug("data", "Section " .. sectionName .. " processed successfully with " .. 
                                            validRows .. " valid rows, marking as complete")
                                    TWRA_Assignments.data[idx]["NeedsProcessing"] = false
                                    processedCount = processedCount + 1
                                    
                                    -- Remove from missing sections if it was there
                                    if TWRA_CompressedAssignments.sections.missing[idx] then
                                        TWRA_CompressedAssignments.sections.missing[idx] = nil
                                        self:Debug("data", "Removed section " .. idx .. " from missing sections tracking (valid content)")
                                    end
                                else
                                    -- Better logging for why processing is needed
                                    if not isValid then
                                        self:Debug("error", "Section " .. sectionName .. " missing required fields, keeping NeedsProcessing flag true")
                                    elseif not rowsHaveContent then
                                        self:Debug("error", "Section " .. sectionName .. " has no valid rows with content, keeping NeedsProcessing flag true")
                                    else
                                        self:Debug("error", "Section " .. sectionName .. " incomplete for unknown reason, keeping NeedsProcessing flag true")
                                    end
                                    
                                    TWRA_Assignments.data[idx]["NeedsProcessing"] = true
                                    
                                    -- Add to missing sections tracking
                                    TWRA_CompressedAssignments.sections.missing[idx] = true
                                    self:Debug("data", "Added section " .. idx .. " to missing sections tracking (invalid content)")
                                    
                                    errorCount = errorCount + 1
                                end
                            else
                                -- Failed to decompress or result is not a table
                                if not decompressedData then
                                    self:Debug("error", "Decompression returned nil for section index " .. idx)
                                elseif type(decompressedData) ~= "table" then
                                    self:Debug("error", "Decompressed data is not a table but " .. type(decompressedData))
                                end
                                
                                -- Add to missing sections tracking
                                TWRA_CompressedAssignments.sections.missing[idx] = true
                                self:Debug("data", "Added section " .. idx .. " to missing sections tracking (invalid decompressed data)")
                                
                                errorCount = errorCount + 1
                            end
                        else
                            self:Debug("error", "Empty section data for section " .. idx)
                            TWRA_Assignments.data[idx]["NeedsProcessing"] = true
                            
                            -- Add to missing sections tracking
                            TWRA_CompressedAssignments.sections.missing[idx] = true
                            self:Debug("data", "Added section " .. idx .. " to missing sections tracking (empty data)")
                            
                            errorCount = errorCount + 1
                        end
                    end
                end
            end
        end
    end
    
    -- Process player-relevant info after all sections are processed
    if self.ProcessPlayerInfo then
        if sectionIndex then
            -- For a single section, process just that section's player info
            self:Debug("data", "Processing player-relevant info for section: " .. sectionIndex)
            self:ProcessPlayerInfo(TWRA_Assignments.data[sectionIndex])
        else
            -- For all sections, process all player info at once
            self:Debug("data", "Processing player-relevant info for all sections")
            self:ProcessPlayerInfo()
        end
    end
    
    -- Check if we have any missing sections and log them
    local missingCount = 0
    local missingList = {}
    if TWRA_CompressedAssignments.sections.missing then
        for idx, _ in pairs(TWRA_CompressedAssignments.sections.missing) do
            if type(idx) == "number" then
                missingCount = missingCount + 1
                table.insert(missingList, idx)
            end
        end
    end
    
    if missingCount > 0 then
        table.sort(missingList)
        local missingStr = table.concat(missingList, ", ")
        self:Debug("data", "WARNING: " .. missingCount .. " sections still missing after processing: " .. missingStr, true)
    end
    
    -- Log summary when processing multiple sections
    if not sectionIndex then
        self:Debug("data", "Completed processing all sections. Successfully processed " .. 
                processedCount .. " sections with " .. errorCount .. " errors.")
    end
    
    return processedCount > 0
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
    
    -- If tank columns not found in metadata, try to identify them dynamically
    if table.getn(tankColumns) == 0 then
        tankColumns = self:FindTankRoleColumns(section)
        -- Store in metadata for future use
        if metadata then
            metadata["Tank Columns"] = tankColumns
            self:Debug("data", "Stored " .. table.getn(tankColumns) .. " tank columns in section metadata", false, true)
        end
    end
    
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
                    local referenceType = nil
                    
                    if isGroupAssignments then
                        if self:IsCellRelevantForPlayerGroup(cellText) then
                            referenceType = "group"
                            table.insert(playerRoles, {
                                role = headerText,
                                column = colIndex,
                                referenceType = referenceType
                            })
                            self:Debug("data", "Found role " .. headerText .. " in row " .. rowIndex .. 
                                    ", column " .. colIndex .. " (group reference)", false, true)
                        end
                    else
                        -- Check if it's a direct name match or class match
                        if cellText == UnitName("player") then
                            referenceType = "direct"
                            table.insert(playerRoles, {
                                role = headerText,
                                column = colIndex,
                                referenceType = referenceType
                            })
                            self:Debug("data", "Found role " .. headerText .. " in row " .. rowIndex .. 
                                    ", column " .. colIndex .. " (direct name reference)", false, true)
                        elseif self:IsCellRelevantForPlayer(cellText) and cellText ~= UnitName("player") then
                            -- If it's not a direct match but still relevant, it must be a class match
                            referenceType = "class"
                            table.insert(playerRoles, {
                                role = headerText,
                                column = colIndex,
                                referenceType = referenceType
                            })
                            self:Debug("data", "Found role " .. headerText .. " in row " .. rowIndex .. 
                                    ", column " .. colIndex .. " (class reference)", false, true)
                        end
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
                
                -- If target is empty but icon is present, use icon name as target
                if (not target or target == "") and icon and icon ~= "" then
                    self:Debug("data", "Using icon name as target for empty target: " .. icon, false, true)
                    table.insert(entry, icon)       -- Use icon name as target
                else
                    table.insert(entry, target)     -- Target
                end
                
                -- Add all tank names
                for _, tankName in ipairs(tankNames) do
                    table.insert(entry, tankName)   -- Tank name
                end
                
                -- Determine roleType (tank/heal/other) based on role name
                local roleType = "other"  -- Default
                local lowerRole = string.lower(roleInfo.role)
                
                -- Use the ROLE_MAPPINGS table for flexible role categorization
                -- Check for direct match in mappings
                if self.ROLE_MAPPINGS[lowerRole] then
                    roleType = self.ROLE_MAPPINGS[lowerRole]
                else
                    -- Check for partial matches if direct match fails
                    for pattern, mappedRole in pairs(self.ROLE_MAPPINGS) do
                        if string.find(lowerRole, pattern) then
                            roleType = mappedRole
                            break
                        end
                    end
                end
                
                -- Add reference type and role type as fields in the entry table
                entry.referenceType = roleInfo.referenceType
                entry.roleType = roleType
                
                -- Add the entry to our results
                table.insert(osdInfo, entry)
                
                self:Debug("data", "Added OSD entry for role " .. roleInfo.role .. 
                          " on target " .. (entry[3] or "none") .. " with " .. 
                          table.getn(tankNames) .. " tanks, role type: " ..
                          roleType .. ", reference type: " ..
                          (roleInfo.referenceType or "none"), false, true)
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