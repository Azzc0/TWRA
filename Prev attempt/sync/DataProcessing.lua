-- TWRA Data Processing Module
TWRA = TWRA or {}

-- Process raw data after all chunks are assembled
function TWRA:ProcessCompleteData(data, timestamp, sender)
    local ourTimestamp = TWRA_SavedVariables.assignments and TWRA_SavedVariables.assignments.timestamp or 0
    
    if timestamp and timestamp > ourTimestamp then
        self:Debug("data", "Processing newer data from " .. sender)
        
        -- Decode the data
        local decodedData = self:DecodeBase64(data, timestamp, true)
        if not decodedData then
            self:Debug("error", "Failed to decode data from " .. sender)
            return
        end
        
        self:Debug("data", "Successfully decoded data with " .. table.getn(decodedData) .. " entries")
        
        -- Update our data
        TWRA_SavedVariables.assignments = {
            data = decodedData,
            source = data,
            timestamp = timestamp,
            version = self.DATA_PROCESSING.FORMAT_VERSION,
            currentSection = self.SYNC.pendingSection or 
                            (self.navigation and self.navigation.currentIndex) or 
                            self.DATA_PROCESSING.SECTION_INDEX_DEFAULT
        }
        
        -- Update fullData
        self.fullData = decodedData
        
        -- Rebuild navigation
        self:RebuildNavigation()
        
        -- Handle any pending section navigation
        if self.SYNC.pendingSection then
            if self.navigation and self.SYNC.pendingSection <= table.getn(self.navigation.handlers) then
                self.navigation.currentIndex = self.SYNC.pendingSection
                self:SaveCurrentSection()
            end
            self.SYNC.pendingSection = nil
        end
        
        -- Update the display
        self:HandleDisplayUpdate()
        
        DEFAULT_CHAT_FRAME:AddMessage("TWRA: " .. self.SYNC.STATUS_MESSAGES.SYNC_SUCCESS .. " with " .. sender)
    else
        self:Debug("data", "Ignoring data from " .. sender .. " - our data is newer or the same")
    end
end

-- Force an update from sync data
function TWRA:ForceUpdateFromSync(data, timestamp, targetSection, noAnnounce)
    local decodedData
    if type(data) == "string" then
        -- Use noAnnounce=true to avoid recursive broadcasts
        decodedData = self:DecodeBase64(data, timestamp, noAnnounce)
    else
        decodedData = data
    end
    
    if not decodedData then
        self:Debug("error", "Failed to decode sync data")
        return false
    end
    
    -- Use the specified section, default to 1, or keep current if available
    local sectionToUse = targetSection or 
                        (self.navigation and self.navigation.currentIndex) or 
                        self.DATA_PROCESSING.SECTION_INDEX_DEFAULT
    
    -- Update saved variables
    TWRA_SavedVariables.assignments = {
        data = decodedData,
        source = type(data) == "string" and data or nil,
        timestamp = timestamp,
        version = self.DATA_PROCESSING.FORMAT_VERSION,
        currentSection = sectionToUse
    }
    
    -- Update fullData
    self.fullData = decodedData
    
    -- Rebuild navigation
    self:RebuildNavigation()
    
    -- Set the current section index
    if self.navigation and self.navigation.handlers then
        -- Make sure the section index is valid
        if sectionToUse > table.getn(self.navigation.handlers) then
            sectionToUse = self.DATA_PROCESSING.SECTION_INDEX_DEFAULT
        end
        self.navigation.currentIndex = sectionToUse
    end
    
    -- Handle display update
    self:HandleDisplayUpdate()
    
    return true
end

-- Decode Base64 encoded data
function TWRA:DecodeBase64(encodedData, timestamp, noAnnounce)
    self:Debug("data", "Decoding Base64 data of length: " .. string.len(encodedData))
    
    -- Basic validation
    if not encodedData or encodedData == "" then
        self:Debug("error", "Empty data passed to decoder")
        return nil
    end
    
    local success, decodedData = pcall(function()
        return self:Base64Decode(encodedData)
    end)
    
    if not success or not decodedData then
        self:Debug("error", "Base64 decoding failed")
        return nil
    end
    
    -- Parse the JSON
    local success2, parsedData = pcall(function()
        -- Replace this with your JSON parsing function
        return self:ParseAssignmentsData(decodedData)
    end)
    
    if not success2 or not parsedData then
        self:Debug("error", "JSON parsing failed")
        return nil
    end
    
    self:Debug("data", "Data successfully decoded and parsed")
    return parsedData
end

-- Parse assignments data from JSON
function TWRA:ParseAssignmentsData(jsonData)
    self:Debug("data", "Parsing assignments data")
    
    if not jsonData or jsonData == "" then
        self:Debug("error", "No data to parse")
        return nil
    end
    
    -- Simple JSON parser for assignment data
    -- This is a placeholder - implement your actual JSON parsing logic here
    local parsedData = {}
    
    -- Here would be your parsing logic
    -- For now, we'll just return an empty table to avoid errors
    
    return parsedData
end

-- Rebuild navigation based on current data
function TWRA:RebuildNavigation()
    self:Debug("data", "Rebuilding navigation")
    
    -- Create navigation if it doesn't exist
    if not self.navigation then
        self.navigation = {
            handlers = {},
            currentIndex = 1
        }
    end
    
    -- Clear existing handlers
    self.navigation.handlers = {}
    
    -- Extract unique handlers from data
    if self.fullData then
        local handlerSet = {}
        
        for i = 1, table.getn(self.fullData) do
            local entry = self.fullData[i]
            if entry and entry.handler and not handlerSet[entry.handler] then
                handlerSet[entry.handler] = true
                table.insert(self.navigation.handlers, entry.handler)
            end
        end
        
        -- Sort handlers alphabetically
        table.sort(self.navigation.handlers)
    end
    
    -- Safety check for empty handlers
    if table.getn(self.navigation.handlers) == 0 then
        table.insert(self.navigation.handlers, "Default")
    end
    
    -- Validate current index
    local savedSection = TWRA_SavedVariables.assignments and TWRA_SavedVariables.assignments.currentSection or 1
    if savedSection > table.getn(self.navigation.handlers) then
        savedSection = 1
    end
    
    self.navigation.currentIndex = savedSection
    
    self:Debug("data", "Navigation rebuilt with " .. table.getn(self.navigation.handlers) .. " sections")
    return table.getn(self.navigation.handlers)
end

-- Save current section to SavedVariables
function TWRA:SaveCurrentSection()
    if TWRA_SavedVariables and TWRA_SavedVariables.assignments and self.navigation then
        TWRA_SavedVariables.assignments.currentSection = self.navigation.currentIndex
    end
end

-- Handle display updates based on current view
function TWRA:HandleDisplayUpdate()
    if self.currentView == self.STATES.VIEW.OPTIONS then
        -- Store a flag indicating that we should update when returning to main view
        self.pendingNavigation = self.navigation and self.navigation.currentIndex or self.DATA_PROCESSING.SECTION_INDEX_DEFAULT
        self:Debug("data", "In options view - deferring UI update")
    else
        -- We're in main view, update immediately
        if self.DisplayCurrentSection then
            self:DisplayCurrentSection()
            self:Debug("data", "In main view - updating UI immediately")
        else
            self:Debug("error", "DisplayCurrentSection function not found")
        end
    end
end

TWRA:Debug("data", "DataProcessing module loaded")