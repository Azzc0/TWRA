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

-- Helper function to find columns containing tank roles
function TWRA:FindTankRoleColumns(section)
    local tankColumns = {}
    
    -- Skip if no header
    if not section["Section Header"] then
        return tankColumns
    end
    
    -- The standardized tank role name
    local tankRole = "tank"
    
    -- Check each header column
    for colIdx, headerText in ipairs(section["Section Header"]) do
        -- Skip if not a string
        if type(headerText) == "string" then
            -- Convert to lowercase for case-insensitive matching
            local lcHeader = string.lower(headerText)
            
            -- Check if this header has a direct mapping to "Tank" in ROLE_MAPPINGS
            if self.ROLE_MAPPINGS and self.ROLE_MAPPINGS[lcHeader] == tankRole then
                table.insert(tankColumns, colIdx)
                self:Debug("data", "Found tank column: " .. colIdx .. " (" .. headerText .. ")", false, true)
            -- Fallback to pattern matching if we don't have a direct match in ROLE_MAPPINGS
            elseif string.find(lcHeader, "tank") or 
                   string.find(lcHeader, "mt") or 
                   string.find(lcHeader, "ot") or
                   string.find(lcHeader, "maintank") or
                   string.find(lcHeader, "main tank") or
                   string.find(lcHeader, "offtank") or
                   string.find(lcHeader, "off tank") or
                   string.find(lcHeader, "t1") or
                   string.find(lcHeader, "t2") or
                   string.find(lcHeader, "t3") or
                   string.find(lcHeader, "t4") or
                   string.find(lcHeader, "tank1") or
                   string.find(lcHeader, "tank2") or
                   string.find(lcHeader, "tank3") or
                   string.find(lcHeader, "tank4") then
                
                table.insert(tankColumns, colIdx)
                self:Debug("data", "Found tank column via pattern: " .. colIdx .. " (" .. headerText .. ")", false, true)
            end
        end
    end
    
    -- Always store found tank columns in section metadata for future use
    if section["Section Metadata"] then
        section["Section Metadata"]["Tank Columns"] = tankColumns
        self:Debug("data", "Stored " .. table.getn(tankColumns) .. " tank columns in section metadata", false, true)
    end
    
    return tankColumns
end

-- Helper function to normalize metadata keys
function TWRA:NormalizeMetadataKeys(metadata)
    if type(metadata) ~= "table" then
        return metadata
    end
    
    local normalizedMetadata = {}
    local keyMappings = {
        ["notes"] = "Note",
        ["warnings"] = "Warning",
        ["guids"] = "GUID",
        ["Group Rows"] = "Group Rows"
    }
    
    -- Copy all values, normalizing keys as needed
    for key, value in pairs(metadata) do
        local normalizedKey = keyMappings[key] or key
        normalizedMetadata[normalizedKey] = value
    end
    
    return normalizedMetadata
end

-- Clear data while preserving section metadata
function TWRA:ClearData()
    self:Debug("data", "Clearing current data")
    
    -- Check if we have metadata to preserve
    local metadataToPreserve = {}
    local playerInfoToPreserve = {}
    
    if TWRA_Assignments and TWRA_Assignments.data and type(TWRA_Assignments.data) == "table" then
        -- Extract metadata and player info from each section
        for sectionIdx, section in pairs(TWRA_Assignments.data) do
            if type(section) == "table" and section["Section Name"] then
                local sectionName = section["Section Name"]
                
                -- PRESERVE METADATA: Normalize and deep copy all metadata
                metadataToPreserve[sectionName] = {}
                if section["Section Metadata"] and type(section["Section Metadata"]) == "table" then
                    -- First normalize the keys to ensure consistent case
                    local normalizedMetadata = self:NormalizeMetadataKeys(section["Section Metadata"])
                    
                    -- Then deep copy the normalized metadata
                    metadataToPreserve[sectionName] = self:DeepCopy(normalizedMetadata)
                    
                    -- Log what we're preserving
                    local metadataKeys = ""
                    for key, value in pairs(normalizedMetadata) do
                        if type(value) == "table" then
                            metadataKeys = metadataKeys .. key .. "(" .. table.getn(value) .. "), "
                        else
                            metadataKeys = metadataKeys .. key .. ", "
                        end
                    end
                    
                    self:Debug("data", "Preserved metadata for section " .. sectionName .. ": " .. metadataKeys)
                end
                
                -- PRESERVE PLAYER INFO: Separately preserve the player info
                playerInfoToPreserve[sectionName] = {}
                if section["Section Player Info"] and type(section["Section Player Info"]) == "table" then
                    playerInfoToPreserve[sectionName] = self:DeepCopy(section["Section Player Info"])
                    
                    -- Log what we're preserving
                    local playerInfoKeys = ""
                    for key, value in pairs(section["Section Player Info"]) do
                        if type(value) == "table" then
                            playerInfoKeys = playerInfoKeys .. key .. "(" .. table.getn(value) .. "), "
                        else
                            playerInfoKeys = playerInfoKeys .. key .. ", "
                        end
                    end
                    
                    self:Debug("data", "Preserved player info for section " .. sectionName .. ": " .. playerInfoKeys)
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
    
    -- Create a hook to restore metadata and player info after the next save
    if next(metadataToPreserve) ~= nil or next(playerInfoToPreserve) ~= nil then
        self.pendingMetadataRestore = metadataToPreserve
        self.pendingPlayerInfoRestore = playerInfoToPreserve
        
        self:Debug("data", "Set up metadata and player info restoration hook for next save operation")
        
        -- Create a function that will be called after SaveAssignments to restore metadata and player info
        self.RestorePendingMetadata = function()
            if not self.pendingMetadataRestore or not TWRA_Assignments or not TWRA_Assignments.data then
                return
            end
            
            -- For each section, restore the entire metadata
            for sectionIdx, section in pairs(TWRA_Assignments.data) do
                if type(section) == "table" and section["Section Name"] then
                    local sectionName = section["Section Name"]
                    
                    -- RESTORE METADATA
                    if self.pendingMetadataRestore[sectionName] then
                        -- Initialize metadata if needed
                        section["Section Metadata"] = section["Section Metadata"] or {}
                        
                        -- Normalize the existing metadata keys
                        section["Section Metadata"] = self:NormalizeMetadataKeys(section["Section Metadata"])
                        
                        -- Merge the preserved metadata with any new metadata
                        for key, value in pairs(self.pendingMetadataRestore[sectionName]) do
                            -- Don't overwrite existing non-empty values
                            if not section["Section Metadata"][key] or 
                               (type(section["Section Metadata"][key]) == "table" and table.getn(section["Section Metadata"][key]) == 0) then
                                
                                section["Section Metadata"][key] = self:DeepCopy(value)
                                self:Debug("data", "Restored " .. key .. " metadata for section " .. sectionName)
                            end
                        end
                    end
                    
                    -- RESTORE PLAYER INFO
                    if self.pendingPlayerInfoRestore and self.pendingPlayerInfoRestore[sectionName] then
                        -- Initialize player info if needed
                        section["Section Player Info"] = section["Section Player Info"] or {}
                        
                        -- Merge the preserved player info with any new player info
                        for key, value in pairs(self.pendingPlayerInfoRestore[sectionName]) do
                            -- Always restore player info since it's computed from scratch
                            section["Section Player Info"][key] = self:DeepCopy(value)
                        end
                        
                        self:Debug("data", "Restored player info for section " .. sectionName)
                    end
                end
            end
            
            -- Clear the pending restoration data
            self.pendingMetadataRestore = nil
            self.pendingPlayerInfoRestore = nil
            self:Debug("data", "Completed metadata and player info restoration")
        end
        
        -- Set up a post-save hook if it doesn't already exist
        if not self.originalSaveAssignments then
            self.originalSaveAssignments = self.SaveAssignments
            self.SaveAssignments = function(self, data, sourceString, originalTimestamp, noAnnounce)
                local result = self:originalSaveAssignments(data, sourceString, originalTimestamp, noAnnounce)
                
                -- Restore metadata and player info after saving
                if self.RestorePendingMetadata then
                    self:RestorePendingMetadata()
                end
                
                return result
            end
        end
    end
    
    self:Debug("data", "Data cleared successfully")
    return true
end

-- Helper function to deep copy a table
function TWRA:DeepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = self:DeepCopy(orig_value)
        end
    else
        -- Simple value - just return it directly
        copy = orig
    end
    return copy
end

-- SaveAssignments - Save assignments to SavedVariables for sharing and persistence
function TWRA:SaveAssignments(data, sourceString, timestamp, noAnnounce)
    if not data then
        self:Debug("error", "SaveAssignments called with nil data")
        return
    end
    
    -- Remember the current section name before we clear data
    local previousSectionName = nil
    previousSectionName = TWRA_Assignments.currentSectionName or nil
    self:Debug("error", "Precious Section name (TWRA_Assignments.currentSectionName): " .. (previousSectionName or "nil"))

    local currentSection = nil
    if self.navigation and self.navigation.currentIndex then
        currentSection = self.navigation.currentIndex
    end
    self:Debug("nav", "SaveAssignments - Current section before update: " .. (currentSection or "unknown"))
    
    -- Clear current data first to avoid duplications
    self:Debug("data", "Clearing current data")
    if not self:ClearData() then
        self:Debug("error", "Failed to clear data before save")
    else
        self:Debug("data", "Data cleared successfully")
    end
    
        
    -- Make sure all rows have entries for all columns
    if self.EnsureCompleteRows then
        data = self:EnsureCompleteRows(data)
        self:Debug("data", "Applied EnsureCompleteRows during SaveAssignments for new format")
    end
    
    -- Process special rows like Note, Warning, GUID and move them to section metadata
    self:Debug("data", "Processing special rows to move them to section metadata")
    if self.CaptureSpecialRows then
        data = self:CaptureSpecialRows(data)
        self:Debug("data", "Applied CaptureSpecialRows to extract special rows as metadata")
    end
    
    -- ENSURE GROUP ROWS IDENTIFICATION: Now we rely on preserved metadata
    if self.EnsureGroupRowsIdentified then
        -- First, we need to store the data temporarily so EnsureGroupRowsIdentified can find it
        TWRA_Assignments = TWRA_Assignments or {}
        TWRA_Assignments.data = data.data
        TWRA_Assignments.timestamp = timestamp or time()
        TWRA_Assignments.version = 2
        TWRA_Assignments.source = sourceString
        
        -- Now identify all group rows in each section
        self:EnsureGroupRowsIdentified()
        self:Debug("data", "Ensured group rows are identified in all sections during SaveAssignments")
        
        -- Get the data back after group rows identification
        data.data = TWRA_Assignments.data
    end

    
    -- Update the saved variables
    TWRA_Assignments = TWRA_Assignments or {}
    -- Always ensure isExample is false for any saved data that's not from the example system
    if not (self.usingExampleData) then
        TWRA_Assignments.isExample = false
    end
    
    -- Set core properties
    TWRA_Assignments.data = data.data
    TWRA_Assignments.version = 2
    
    -- Store additional metadata
    TWRA_Assignments.timestamp = timestamp or time()
    TWRA_Assignments.source = sourceString
    
    -- -- Set current section to 1 if it doesn't already exist
    -- if not self.navigation then
    --     self.navigation = {}
    -- end
    -- if not self.navigation.currentIndex or self.navigation.currentIndex < 1 then
    --     self.navigation.currentIndex = 1
    -- end
    
    -- Generate compressed data for sync if new format
    if data.data then
        self:Debug("data", "Generating segmented compressed data for future sync operations")
        if self.StoreSegmentedData then
            self:StoreSegmentedData()
            self:Debug("data", "Generated and stored segmented compressed data successfully")
        else
            self:Debug("error", "StoreSegmentedData not available, compressed data not stored")
        end
        self:Debug("data", "Assigned new format data directly to SavedVariables")
    else
        self:Debug("data", "Assigned legacy format data directly to SavedVariables")
    end
    
    -- IMPORTANT: Do NOT process player info here yet - we'll do it at the very end
    -- First make sure our hooks run to restore all metadata
    
    -- Announce save to chat if enabled and not suppressed
    -- local announceMessage = "Raid assignments " .. (sourceString or "unknown source") .. 
    --                       " saved."
    -- if self.db and self.db.char and not self.db.char.quietmode and not noAnnounce then
    --     -- Check if player is in a party/raid before announcing
    --     local inRaid = GetNumRaidMembers() > 0
    --     local inParty = GetNumPartyMembers() > 0
        
    --     if inRaid or inParty then
    --         self:Debug("general", "Import detected while in party/raid - suppressing announcement")
    --     else
    --         DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA:|r " .. announceMessage)
    --     end
    -- else
    --     self:Debug("general", "Import detected while in party/raid - suppressing announcement")
    -- end
    
    -- Trigger events for custom handlers
    self:TriggerEvent("ASSIGNMENTS_SAVED", data)
    
    -- Rebuild navigation after save
    if self.RebuildNavigation then
        self:Debug("nav", "Rebuilding navigation after import")
        self:RebuildNavigation()
    end
    
    -- Try to find the previous section in the new navigation
    if previousSectionName and self.navigation and self.navigation.handlers then
        local targetSectionIndex = nil
        for idx, name in ipairs(self.navigation.handlers) do
            if name == previousSectionName then
                targetSectionIndex = idx
                self:Debug("nav", "Found previously active section in new data: " .. name .. " (index " .. idx .. ")")
                break
            end
        end
        
        -- If we found the section, update the navigation index
        if targetSectionIndex then
            self.navigation.currentIndex = targetSectionIndex
            -- Store the current section in TWRA_Assignments as well
            TWRA_Assignments.currentSection = targetSectionIndex
            self:Debug("nav", "Restored navigation to previous section: " .. previousSectionName)
        end
    end
    
    -- MOVE METADATA RESTORATION HERE - if the hook exists, call it directly
    if self.RestorePendingMetadata then
        self:Debug("data", "Calling RestorePendingMetadata before processing player info")
        self:RestorePendingMetadata()
    end
    
    -- NOW: Process player info AFTER all metadata restoration is complete
    -- This ensures player info is generated from the final, complete data state
    self:Debug("data", "Processing player information AFTER metadata restoration (very late in import)")
    if self.ProcessPlayerInfo then
        local success, error = pcall(function()
            self:ProcessPlayerInfo()
        end)
        
        if success then
            self:Debug("data", "Successfully processed player info at the end of import")
        else
            self:Debug("error", "Error processing player info at the end of import: " .. tostring(error))
        end
    else
        self:Debug("error", "ProcessPlayerInfo function not available")
    end
    
    -- -- Navigate to first section if needed - but now we check if we have previously restored a section
    -- if self.navigation and self.navigation.currentIndex and self.navigation.currentIndex < 1 then
    --     if self.NavigateToSection then
    --         self:Debug("nav", "Navigating to first section after import (no previous section found)")
    --         self:NavigateToSection(1)
    --     end
    -- end
    self:NavigateToSection(previousSectionName or 1)
    
    -- Return timestamp for calling functions
    return timestamp or time()
end

-- Process imported data to handle shortened keys and special characters
function TWRA:ProcessImportedData(data)
    if not data then return data end
    
    -- First handle any shortened keys
    local processedData = TranslateKeyNames(data)
    
    -- Return the processed data
    return processedData
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
            
            -- IMPORTANT: Also make sure Group Rows exists
            metadata["Group Rows"] = metadata["Group Rows"] or {}
            
            -- Find Group Rows explicitly if they're not already defined
            if table.getn(metadata["Group Rows"]) == 0 then
                metadata["Group Rows"] = self:GetAllGroupRowsForSection(section)
                self:Debug("data", "Generated Group Rows metadata for section: " .. sectionName .. 
                          " with " .. table.getn(metadata["Group Rows"]) .. " rows")
            else
                self:Debug("data", "Using existing Group Rows metadata for section: " .. sectionName .. 
                          " with " .. table.getn(metadata["Group Rows"]) .. " rows")
            end
            
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
                            -- Clean up and extract just the 18-character GUID
                            local fullGuidText = row[2]
                            local extractedGuid = nil
                            
                            -- Look for a GUID pattern using string.find (since string.match doesn't exist in Lua 5.0)
                            -- This will match patterns like "0xF130003F1101594B"
                            local startPos, endPos = string.find(fullGuidText, "%w[xX]%w+")
                            if startPos then
                                -- Extract the matched substring
                                extractedGuid = string.sub(fullGuidText, startPos, endPos)
                                
                                -- Take exactly 18 characters if available
                                if string.len(extractedGuid) >= 18 then
                                    extractedGuid = string.sub(extractedGuid, 1, 18)
                                    self:Debug("data", "Extracted GUID from '" .. fullGuidText .. "' to '" .. extractedGuid .. "'")
                                    
                                    -- Add to metadata if not already there
                                    local exists = false
                                    for _, existingGUID in ipairs(metadata["GUID"]) do
                                        if existingGUID == extractedGuid then
                                            exists = true
                                            break
                                        end
                                    end
                                    
                                    if not exists then
                                        table.insert(metadata["GUID"], extractedGuid)
                                        self:Debug("data", "Found GUID in section " .. sectionName .. ": " .. extractedGuid)
                                    end
                                else
                                    -- If matched text is too short
                                    self:Debug("data", "Extracted GUID too short: " .. extractedGuid)
                                    
                                    -- Add original value to metadata if not already there
                                    local exists = false
                                    for _, existingGUID in ipairs(metadata["GUID"]) do
                                        if existingGUID == fullGuidText then
                                            exists = true
                                            break
                                        end
                                    end
                                    
                                    if not exists then
                                        table.insert(metadata["GUID"], fullGuidText)
                                        self:Debug("data", "Stored original GUID text: " .. fullGuidText)
                                    end
                                end
                            else
                                -- If we can't extract a valid GUID, store the original value but log a warning
                                self:Debug("data", "Could not extract valid GUID pattern from: " .. fullGuidText)
                                
                                -- Add original value to metadata if not already there
                                local exists = false
                                for _, existingGUID in ipairs(metadata["GUID"]) do
                                    if existingGUID == fullGuidText then
                                        exists = true
                                        break
                                    end
                                end
                                
                                if not exists then
                                    table.insert(metadata["GUID"], fullGuidText)
                                    self:Debug("data", "Stored original GUID text: " .. fullGuidText)
                                end
                            end
                            
                            -- Mark for removal from rows
                            table.insert(specialRowIndices, rowIdx)
                        end
                    end
                end
                
                -- Remember the metadata for this section - USING PROPER CAPITALIZATION
                self.pendingMetadataRestore[sectionName] = {
                    ["Note"] = metadata["Note"],
                    ["Warning"] = metadata["Warning"],
                    ["GUID"] = metadata["GUID"],
                    ["Group Rows"] = metadata["Group Rows"]
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