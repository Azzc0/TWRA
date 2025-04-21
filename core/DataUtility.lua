-- TWRA Data Utility
-- Functions for handling the new structured data format

TWRA = TWRA or {}

-- Add a function to translate shortened keys to their full forms
local function TranslateKeyNames(data)
    if not data or type(data) ~= "table" then return data end
    
    local keyMappings = {
        ["sn"] = "Section Name",
        ["sh"] = "Section Header",
        ["sr"] = "Section Rows",
        ["ri"] = "Relevant Icons",
        ["fa"] = "Formatted Assignments"
    }
    
    local result = {}
    for k, v in pairs(data) do
        local newKey = keyMappings[k] or k
        
        if type(v) == "table" then
            result[newKey] = TranslateKeyNames(v)
        else
            result[newKey] = v
        end
    end
    
    return result
end

-- Convert special characters in a string
function TWRA:ConvertSpecialCharacters(str)
    if not str or type(str) ~= "string" then return str end
    
    -- Replace common special character patterns
    local replacements = {
        ["?"] = "å",
        ["?"] = "ä",
        ["?"] = "ö",
        ["?"] = "Å",
        ["?"] = "Ä",
        ["?"] = "Ö",
        ["?"] = "ø",
        ["?"] = "æ",
        ["?"] = "ũ"
    }
    
    for pattern, replacement in pairs(replacements) do
        str = string.gsub(str, pattern, replacement)
    end
    
    return str
end

-- Fix special characters throughout the entire data structure
function TWRA:FixSpecialCharacters(data)
    if type(data) ~= "table" then
        if type(data) == "string" then
            return self:ConvertSpecialCharacters(data)
        end
        return data
    end
    
    local result = {}
    for k, v in pairs(data) do
        if type(k) == "string" then
            k = self:ConvertSpecialCharacters(k)
        end
        
        if type(v) == "table" then
            result[k] = self:FixSpecialCharacters(v)
        elseif type(v) == "string" then
            result[k] = self:ConvertSpecialCharacters(v)
        else
            result[k] = v
        end
    end
    
    return result
end

-- Build navigation from the new data format
function TWRA:BuildNavigationFromNewFormat()
    -- Forward to the canonical implementation in Core.lua
    self:Debug("nav", "BuildNavigationFromNewFormat is deprecated - forwarding to RebuildNavigation")
    return self:RebuildNavigation()
end

-- Get section by index
function TWRA:GetNewFormatSection(index)
    return TWRA_Assignments.data[index]
end

-- Simplify GetCurrentSectionData to always assume new format
function TWRA:GetCurrentSectionData()
    -- Check if we have assignment data
    if not TWRA_Assignments or not TWRA_Assignments.data then
        self:Debug("error", "No assignment data available")
        return nil
    end

    -- Get the current section name
    local currentSectionName = nil
    
    -- First try to get from navigation if it exists
    if self.navigation and self.navigation.currentIndex and self.navigation.handlers then
        currentSectionName = self.navigation.handlers[self.navigation.currentIndex]
    end
    
    -- If not found in navigation, try saved currentSectionName
    if not currentSectionName and TWRA_Assignments.currentSectionName then
        currentSectionName = TWRA_Assignments.currentSectionName
    end
    
    if not currentSectionName then
        self:Debug("error", "No current section name found")
        return nil
    end
    
    -- Find the section data in TWRA_Assignments.data
    for _, sectionData in pairs(TWRA_Assignments.data) do
        if type(sectionData) == "table" and sectionData["Section Name"] == currentSectionName then
            return sectionData
        end
    end
    
    self:Debug("error", "Failed to get section data for " .. currentSectionName)
    return nil
end

-- Simplify DisplayCurrentSection to always use new format
function TWRA:DisplayCurrentSection()
    local sectionData = self:GetCurrentSectionData()
    if not sectionData then
        self:Debug("data", "No data for current section.")
        return false
    end
    
    self:FilterAndDisplayHandler(sectionData)
    
    -- Update OSD if enabled
    if self.db.osd.enabled and self.db.osd.showOnNavigation then
        local currentName = ""
        if self.navigation and self.navigation.currentIndex and self.navigation.sections then
            currentName = self.navigation.sections[self.navigation.currentIndex] or ""
        end
        self:UpdateOSDContent(currentName, self.navigation.currentIndex, table.getn(self.navigation.sections))
    end
    
    return true
end

-- Function to get relevant rows for the current player
function TWRA:GetRelevantRowsForCurrentSection(sectionData)
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
    
    -- Scan through all rows to find matches
    local rowsData = sectionData["Section Rows"] or sectionData["sr"]
    if not rowsData then return {} end
    
    for idx, rowData in pairs(rowsData) do
        local isRelevantRow = false
        
        -- Check each cell for player name, class group, or player's group number
        for _, cellData in pairs(rowData) do
            -- Only check string data
            if type(cellData) == "string" and cellData ~= "" then
                -- Match player name directly
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
                
                -- Check for player's group number using a pattern
                if playerGroup then
                    local groupPattern = "%f[%a%d]" .. playerGroup .. "%f[^%a%d]"
                    if string.find(cellData, groupPattern) then
                        isRelevantRow = true
                        break
                    end
                end
            end
        end
        
        -- If row is relevant, add to our list
        if isRelevantRow then
            relevantRows[idx] = true
        end
    end
    
    return relevantRows
end

-- Legacy display function to handle the old format
function TWRA:DisplayLegacySection()
    self:Debug("ui", "Displaying legacy format section")
    
    -- Check if we have data and navigation
    if not self.fullData or not self.navigation or 
       not self.navigation.currentIndex or
       not self.navigation.handlers then
        self:Debug("ui", "No data or navigation available")
        return
    end
    
    local currentSection = self.navigation.handlers[self.navigation.currentIndex]
    if not currentSection then
        self:Debug("ui", "No current section selected")
        return
    end
    
    -- Clear any existing rows
    if self.ClearRows then
        self:ClearRows()
    end
    
    -- Find header row for this section and create it
    local headerRow = nil
    for i = 1, table.getn(self.fullData) do
        if self.fullData[i][1] == currentSection and self.fullData[i][2] == "Icon" then
            headerRow = self.fullData[i]
            break
        end
    end
    
    if headerRow and self.CreateRow then
        self:CreateRow(1, headerRow, false, true)
    end
    
    -- Find rows for this section and create them
    local rowIdx = 2  -- Start after header
    local relevantRows = self:GetPlayerRelevantRows(currentSection)
    
    for i = 1, table.getn(self.fullData) do
        if self.fullData[i][1] == currentSection and self.fullData[i][2] ~= "Icon" then
            local isRelevant = false
            for _, r in ipairs(relevantRows) do
                if r == i then
                    isRelevant = true
                    break
                end
            end
            
            if self.CreateRow then
                self:CreateRow(rowIdx, self.fullData[i], isRelevant)
                rowIdx = rowIdx + 1
            end
        end
    end
    
    -- Update UI elements
    if self.UpdateRowDisplay then
        self:UpdateRowDisplay()
    end
    
    -- Update OSD if needed
    if self.ShouldShowOSD and self.ShouldShowOSD() and self.ShowOSD then
        self:Debug("osd", "Showing OSD for legacy section")
        self:ShowOSD()
    end
    
    return true
end

-- Clear data while preserving section metadata
function TWRA:ClearData()
    self:Debug("data", "Clearing current data")
    
    -- Check if we have metadata to preserve
    local metadataToPreserve = {}
    if TWRA_Assignments and TWRA_Assignments.data and type(TWRA_Assignments.data) == "table" then
        
        -- Extract metadata from each section
        for sectionIdx, section in pairs(TWRA_Assignments.data) do
            if type(section) == "table" and section["Section Name"] and section["Section Metadata"] then
                local sectionName = section["Section Name"]
                metadataToPreserve[sectionName] = {
                    Note = {},
                    Warning = {},
                    GUID = {}
                }
                
                -- Copy metadata arrays 
                if type(section["Section Metadata"]) == "table" then
                    -- Copy Notes
                    if type(section["Section Metadata"]["Note"]) == "table" then
                        for _, note in ipairs(section["Section Metadata"]["Note"]) do
                            table.insert(metadataToPreserve[sectionName].Note, note)
                        end
                        self:Debug("data", "Preserved " .. table.getn(section["Section Metadata"]["Note"]) .. 
                                  " notes for section " .. sectionName)
                    end
                    
                    -- Copy Warnings
                    if type(section["Section Metadata"]["Warning"]) == "table" then
                        for _, warning in ipairs(section["Section Metadata"]["Warning"]) do
                            table.insert(metadataToPreserve[sectionName].Warning, warning)
                        end
                        self:Debug("data", "Preserved " .. table.getn(section["Section Metadata"]["Warning"]) .. 
                                  " warnings for section " .. sectionName)
                    end
                    
                    -- Copy GUIDs
                    if type(section["Section Metadata"]["GUID"]) == "table" then
                        for _, guid in ipairs(section["Section Metadata"]["GUID"]) do
                            table.insert(metadataToPreserve[sectionName].GUID, guid)
                        end
                        self:Debug("data", "Preserved " .. table.getn(section["Section Metadata"]["GUID"]) .. 
                                  " GUIDs for section " .. sectionName)
                    end
                end
            end
        end
    end

    -- Clear the full data and reset navigation
    self.fullData = nil
    
    if self.navigation then
        self.navigation.handlers = {}
        self.navigation.currentIndex = 1
    end
    
    -- Create a hook to restore metadata after the next save
    if next(metadataToPreserve) ~= nil then
        self.pendingMetadataRestore = metadataToPreserve
        self:Debug("data", "Set up metadata restoration hook for next save operation")
        
        -- Create a function that will be called after SaveAssignments to restore metadata
        self.RestorePendingMetadata = function()
            if not self.pendingMetadataRestore then
                return
            end
            
            -- Clear the pending metadata
            self.pendingMetadataRestore = nil
        end
        
        -- Set up a post-save hook
        local originalSaveAssignments = self.SaveAssignments
        self.SaveAssignments = function(self, data, sourceString, originalTimestamp, noAnnounce)
            local result = originalSaveAssignments(self, data, sourceString, originalTimestamp, noAnnounce)
            
            -- Restore metadata after saving
            if self.RestorePendingMetadata then
                self:RestorePendingMetadata()
            end
            
            return result
        end
    end
    
    self:Debug("data", "Data cleared successfully")
    return true
end

-- Process imported data to handle shortened keys and special characters
function TWRA:ProcessImportedData(data)
    if not data then return data end
    
    -- First handle any shortened keys
    local processedData = TranslateKeyNames(data)
    
    -- Return the processed data
    return processedData
end

-- Verify and log the new data structure
function TWRA:VerifyNewDataStructure()
    if not TWRA_Assignments then
        self:Debug("error", "TWRA_Assignments not found")
        return false
    end
    
    self:Debug("data", "Verifying assignments structure:")
    self:Debug("data", "  version: " .. (TWRA_Assignments.version or "nil"))
    self:Debug("data", "  timestamp: " .. (TWRA_Assignments.timestamp or "nil"))
    self:Debug("data", "  currentSection: " .. (TWRA_Assignments.currentSection or "nil"))
    
    if not TWRA_Assignments.data then
        self:Debug("error", "TWRA_Assignments.data is nil")
        return false
    end
    
    if type(TWRA_Assignments.data) ~= "table" then
        self:Debug("error", "TWRA_Assignments.data is not a table, but " .. type(TWRA_Assignments.data))
        return false
    end
    
    local count = 0
    for idx, section in pairs(TWRA_Assignments.data) do
        count = count + 1
        self:Debug("data", "  Section " .. idx .. ": " .. 
                  (section["Section Name"] or "unnamed"))
    end
    
    self:Debug("data", "Found " .. count .. " sections in TWRA_Assignments.data")
    
   
    return true
end

-- Function to add a special row directly to section metadata
function TWRA:AddSpecialRowToMetadata(sectionName, rowType, content)
    if not sectionName or not rowType or not content then
        self:Debug("error", "Missing required parameters for AddSpecialRowToMetadata")
        return false
    end
    
    -- Validate rowType is valid
    if rowType ~= "Note" and rowType ~= "Warning" and rowType ~= "GUID" then
        self:Debug("error", "Invalid special row type: " .. rowType)
        return false
    end
    
    -- Ensure saved variables exist
    TWRA_Assignments = TWRA_Assignments or {}
    TWRA_Assignments.data = TWRA_Assignments.data or {}
    
    -- Find the section by name
    local sectionFound = false
    for sectionIdx, section in pairs(TWRA_Assignments.data) do
        if type(section) == "table" and section["Section Name"] == sectionName then
            -- Ensure Section Metadata structure exists
            section["Section Metadata"] = section["Section Metadata"] or {}
            section["Section Metadata"][rowType] = section["Section Metadata"][rowType] or {}
            
            -- Add the content to the appropriate metadata array
            table.insert(section["Section Metadata"][rowType], content)
            
            self:Debug("data", "Added " .. rowType .. " to section '" .. sectionName .. "': " .. content)
            sectionFound = true
            break
        end
    end
    
    if not sectionFound then
        self:Debug("error", "Section '" .. sectionName .. "' not found for adding " .. rowType)
        return false
    end
    
    return true
end

-- CaptureSpecialRows: Process and move special rows (Notes, Warnings, GUIDs) to section metadata
function TWRA:CaptureSpecialRows(data)
    if not data or not data.data or type(data.data) ~= "table" then
        self:Debug("error", "Invalid data structure in CaptureSpecialRows")
        return data
    end
    
    self:Debug("data", "Processing special rows to move them to section metadata")
    
    -- Track metadata restoration hook
    self.pendingMetadataRestore = {}
    
    -- Process each section
    for sectionIdx, section in pairs(data.data) do
        -- Make sure section is a table
        if type(section) ~= "table" then
            self:Debug("data", "Skipping non-table section: " .. tostring(sectionIdx))
        else
            local sectionName = section["Section Name"] or tostring(sectionIdx)
            
            -- Initialize Section Metadata if not present
            section["Section Metadata"] = section["Section Metadata"] or {}
            local metadata = section["Section Metadata"]
            
            -- Initialize metadata arrays
            metadata["Note"] = metadata["Note"] or {}
            metadata["Warning"] = metadata["Warning"] or {}
            metadata["GUID"] = metadata["GUID"] or {}
            
            -- Ensure Section Rows exists before trying to iterate over it
            if section["Section Rows"] and type(section["Section Rows"]) == "table" then
                -- Track indices of special rows to remove later
                local specialRowIndices = {}
                
                -- Scan through rows to find special rows
                for rowIdx, row in ipairs(section["Section Rows"]) do
                    if type(row) == "table" and row[1] then
                        -- After abbreviation expansion, we'll have "Note", "Warning", "GUID" 
                        if row[1] == "Note" and row[2] then
                            -- Add to metadata if not already there
                            local exists = false
                            for _, existingNote in ipairs(metadata["Note"]) do
                                if existingNote == row[2] then
                                    exists = true
                                    break
                                end
                            end
                            
                            if not exists then
                                table.insert(metadata["Note"], row[2])
                                self:Debug("data", "Found Note in section " .. sectionName .. ": " .. row[2])
                            end
                            
                            -- Mark for removal from rows
                            table.insert(specialRowIndices, rowIdx)
                            
                        elseif row[1] == "Warning" and row[2] then
                            -- Add to metadata if not already there
                            local exists = false
                            for _, existingWarning in ipairs(metadata["Warning"]) do
                                if existingWarning == row[2] then
                                    exists = true
                                    break
                                end
                            end
                            
                            if not exists then
                                table.insert(metadata["Warning"], row[2])
                                self:Debug("data", "Found Warning in section " .. sectionName .. ": " .. row[2])
                            end
                            
                            -- Mark for removal from rows
                            table.insert(specialRowIndices, rowIdx)
                            
                        elseif row[1] == "GUID" and row[2] then
                            -- Add to metadata if not already there
                            local exists = false
                            for _, existingGUID in ipairs(metadata["GUID"]) do
                                if existingGUID == row[2] then
                                    exists = true
                                    break
                                end
                            end
                            
                            if not exists then
                                table.insert(metadata["GUID"], row[2])
                                self:Debug("data", "Found GUID in section " .. sectionName .. ": " .. row[2])
                            end
                            
                            -- Mark for removal from rows
                            table.insert(specialRowIndices, rowIdx)
                        end
                    end
                end
                
                -- Remember the metadata for this section
                self.pendingMetadataRestore[sectionName] = {
                    notes = table.getn(metadata["Note"]),
                    warnings = table.getn(metadata["Warning"]),
                    guids = table.getn(metadata["GUID"])
                }
                
                -- Only remove special rows if we found any
                if table.getn(specialRowIndices) > 0 then
                    -- Remove special rows from section rows (from highest index to lowest)
                    table.sort(specialRowIndices, function(a,b) return a > b end)
                    for _, idx in ipairs(specialRowIndices) do
                        table.remove(section["Section Rows"], idx)
                    end
                end
            else
                self:Debug("data", "Section '" .. sectionName .. "' has no Section Rows or it's not a table")
            end
            
            self:Debug("data", "Section '" .. sectionName .. "': Found " .. 
                       table.getn(metadata["Note"]) .. " notes, " ..
                       table.getn(metadata["Warning"]) .. " warnings, " ..
                       table.getn(metadata["GUID"]) .. " GUIDs")
        end
    end
    
    -- Set up hook to ensure metadata is restored when data is cleared
    self:Debug("data", "Set up metadata restoration hook for next save operation")
    
    return data
end

-- Initialize diagnostics when this file loads
TWRA:VerifyNewDataStructure()
