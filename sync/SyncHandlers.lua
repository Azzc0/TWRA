-- TWRA Sync Message Handlers
-- Handles all incoming addon communications for synchronization
TWRA = TWRA or {}

-- Initialize SYNC namespace with new segmented sync commands
if not TWRA.SYNC then
    TWRA.SYNC = {
        PREFIX = "TWRA",
        useSegmentedSync = true, -- Enable segmented sync by default
        pendingSection = nil     -- Section to navigate to after sync
    }
end

-- Initialize handler map in SYNC namespace
function TWRA:InitializeHandlerMap()
    -- Map command codes to handler functions directly
    -- The command codes are the values, not the keys, from TWRA.SYNC.COMMANDS
    self.syncHandlers = {
        -- Standard messages
        SECTION = self.HandleSectionCommand,
        ANC = self.HandleAnnounceCommand,
        SREQ = self.HandleStructureRequestCommand,
        SRES = self.HandleStructureResponseCommand,
        SECREQ = self.HandleSectionRequestCommand, 
        SECRES = self.HandleSectionResponseCommand,
        VER = self.UnusedCommand,
        DREQ = self.UnusedCommand,
        DRES = self.UnusedCommand,
        BULKREQ = self.HandleBulkRequestCommand,
        BULKRES = self.HandleBulkResponseCommand,
        BSEC = self.HandleBulkSectionCommand, -- Added BULK_SECTION handler
        BSTR = self.HandleBulkStructureCommand, -- Added BULK_STRUCTURE handler
    }  
    self:Debug("sync", "Initialized message handler map with " .. self:GetTableSize(self.syncHandlers) .. " handlers")
end

-- Main addon message handler - routes messages to appropriate handlers
function TWRA:HandleAddonMessage(message, distribution, sender)
    -- Shared initial processing for all message types
    if not message or message == "" then
        return
    end
    
    -- Common parsing for all message types
    local components = {}
    local index = 1
    
    -- Parse message into components using ":" delimiter
    for part in string.gfind(message, "([^:]+)") do
        components[index] = part
        index = index + 1
    end
    
    if table.getn(components) < 1 then
        self:Debug("sync", "Invalid message format: " .. message)
        return
    end
    
    -- Extract command
    local command = components[1]
    
    -- Handle different command types
    if command == self.SYNC.COMMANDS.SECTION then
        -- Handle SECTION (navigation update)
        if self.HandleSectionCommand then
            self:HandleSectionCommand(components[2], components[3], sender)
        end
    elseif command == self.SYNC.COMMANDS.ANNOUNCE then
        -- Handle ANNOUNCE (new import)
        if self.HandleAnnounceCommand then
            self:HandleAnnounceCommand(components[2], sender)
        end
    elseif command == self.SYNC.COMMANDS.STRUCTURE_REQUEST then
        -- Handle SREQ (structure request)
        if self.HandleStructureRequestCommand then
            self:HandleStructureRequestCommand(components[2], sender)
        end
    elseif command == self.SYNC.COMMANDS.STRUCTURE_RESPONSE then
        -- Handle SRES (structure response)
        if self.HandleStructureResponseCommand then
            self:HandleStructureResponseCommand(message, sender)
        end
    elseif command == self.SYNC.COMMANDS.SECTION_REQUEST then
        -- Handle SECREQ (section request)
        if self.HandleSectionRequestCommand then
            self:HandleSectionRequestCommand(components[2], components[3], sender)
        end
    elseif command == self.SYNC.COMMANDS.SECTION_RESPONSE then
        -- Handle SECRES (section response)
        if self.HandleSectionResponseCommand then
            self:HandleSectionResponseCommand(components[2], components[3], self:ExtractDataPortion(message, 4), sender)
        end
    elseif command == self.SYNC.COMMANDS.BULK_SECTION then
        -- Handle BSEC (bulk section transmission without processing)
        if self.HandleBulkSectionCommand then
            self:HandleBulkSectionCommand(components[2], components[3], self:ExtractDataPortion(message, 4), sender)
        end
    elseif command == self.SYNC.COMMANDS.BULK_STRUCTURE then
        -- Handle BSTR (bulk structure transmission)
        if self.HandleBulkStructureCommand then
            self:HandleBulkStructureCommand(components[2], self:ExtractDataPortion(message, 3), sender)
        end
    elseif command == self.SYNC.COMMANDS.VERSION then
        -- Handle VER (version check)
        if self.HandleVersionCommand then
            self:HandleVersionCommand(components[2], sender)
        end
    else
        -- Unknown command - log it but don't act
        self:Debug("sync", "Unknown command in message: " .. command)
    end
end

-- Utility function to extract the data portion of a message which may contain colons
function TWRA:ExtractDataPortion(message, startComponent)
    if not message or message == "" then
        return ""
    end
    
    local colonCount = 0
    local dataStart = 1
    
    -- Find the position after the (startComponent-1)th colon
    for i = 1, string.len(message) do
        local char = string.sub(message, i, i)
        if char == ":" then
            colonCount = colonCount + 1
            if colonCount == startComponent - 1 then
                dataStart = i + 1
                break
            end
        end
    end
    
    return string.sub(message, dataStart)
end

-- Handle section change commands
function TWRA:HandleSectionCommand(timestamp, sectionIndex, sender)
    -- Add debug statement right at the start
    self:Debug("sync", "HandleSectionCommand called with sectionIndex: " .. sectionIndex .. 
              ", timestamp: " .. timestamp .. " from " .. sender, true)
    
    -- Convert to numbers (default to 0 if conversion fails)
    local sectionIndexNum = tonumber(sectionIndex)
    local timestampNum = tonumber(timestamp)
    
    if not sectionIndexNum then
        self:Debug("sync", "Failed to convert section index to number: " .. sectionIndex, true)
        return
    end
    
    if not timestampNum then
        self:Debug("sync", "Failed to convert timestamp to number: " .. timestamp, true)
        return
    end
    
    sectionIndex = sectionIndexNum
    timestamp = timestampNum
    
    -- Always debug what we received
    self:Debug("sync", string.format("Section change from %s (index: %d, timestamp: %d)", 
        sender, sectionIndex, timestamp), true)
    
    -- Get our own timestamp for comparison
    local ourTimestamp = TWRA_Assignments and TWRA_Assignments.timestamp or 0

    -- Debug the timestamp comparison
    self:Debug("sync", "Comparing timestamps - Received: " .. timestamp .. 
               " vs Our: " .. ourTimestamp, true)
    
    -- Compare timestamps and act accordingly
    local comparisonResult = self:CompareTimestamps(ourTimestamp, timestamp)
    
    if comparisonResult == 0 then
        -- Timestamps match - navigate to the section
        self:Debug("sync", "Timestamps match - navigating to section " .. sectionIndex, true)
        self:NavigateToSection(sectionIndex, "fromSync")
        
    elseif comparisonResult > 0 then
        -- We have a newer version - just log it and don't navigate
        self:Debug("sync", "We have a newer version (timestamp " .. ourTimestamp .. 
                  " > " .. timestamp .. "), ignoring section change", true)
    
    else -- comparisonResult < 0
        -- They have a newer version - request their data
        self:Debug("sync", "Detected newer data from " .. sender .. " (timestamp " .. 
                  timestamp .. " > " .. ourTimestamp .. "), requesting data", true)
        
        -- Store the section index to navigate to after sync completes
        self.SYNC.pendingSection = sectionIndex
        self:Debug("sync", "Stored pending section index " .. sectionIndex .. " to navigate after sync", true)
        
        -- Request the data using the RECEIVED timestamp (not our own)
        -- Use segmented sync if available, otherwise fall back to legacy sync
        if self.SYNC.useSegmentedSync and self.RequestStructureSync then
            self:Debug("sync", "Using segmented sync for newer data")
            self:RequestStructureSync(timestamp)
        else
            self:Debug("sync", "Falling back to legacy sync for newer data")
            -- Legacy sync is not implemented in this version, so log that
            self:Debug("sync", "Legacy sync not available in this version", true)
        end
    end
end

-- Function to handle bulk section messages (BSEC)
-- These are stored directly without processing
function TWRA:HandleBulkSectionCommand(timestamp, sectionIndex, sectionData, sender)
    self:Debug("sync", "Handling BULK_SECTION from " .. sender .. " for section " .. sectionIndex)
    
    -- Skip if we're missing required arguments
    if not timestamp or not sectionIndex or not sectionData then
        self:Debug("error", "Missing required arguments for BULK_SECTION handler")
        return false
    end
    
    -- Convert section index to number
    sectionIndex = tonumber(sectionIndex)
    if not sectionIndex then
        self:Debug("error", "Invalid section index in BULK_SECTION: " .. tostring(sectionIndex))
        return false
    end
    
    -- Make sure TWRA_CompressedAssignments and its sections table exist
    if not TWRA_CompressedAssignments then
        TWRA_CompressedAssignments = {}
    end
    
    if not TWRA_CompressedAssignments.sections then
        TWRA_CompressedAssignments.sections = {}
    end
    
    -- Store the data directly without processing it
    TWRA_CompressedAssignments.sections[sectionIndex] = sectionData
    
    -- Update the timestamp if it's newer than our current one
    if TWRA_Assignments then
        local currentTimestamp = TWRA_Assignments.timestamp or 0
        if tonumber(timestamp) > currentTimestamp then
            TWRA_Assignments.timestamp = tonumber(timestamp)
        end
    end
    
    self:Debug("sync", "Successfully stored bulk section " .. sectionIndex .. " data without processing")
    
    -- Add this section to our tracking of received sections
    self.SYNC.receivedSectionResponses = self.SYNC.receivedSectionResponses or {}
    self.SYNC.receivedSectionResponses[sectionIndex] = true
    
    return true
end

-- Handle a bulk structure message (BSTR) in reversed bulk sync approach
function TWRA:HandleBulkStructureCommand(timestamp, structureData, sender)
    self:Debug("sync", "Handling BULK_STRUCTURE from " .. sender)
    
    -- Skip if we're missing required arguments
    if not timestamp or not structureData then
        self:Debug("error", "Missing required arguments for BULK_STRUCTURE handler")
        return false
    end
    
    -- Convert timestamp to number
    timestamp = tonumber(timestamp)
    if not timestamp then
        self:Debug("error", "Invalid timestamp in BULK_STRUCTURE: " .. tostring(timestamp))
        return false
    end
    
    -- Check our current data timestamp against the received one
    local localTimestamp = 0
    if TWRA_CompressedAssignments then
        localTimestamp = TWRA_CompressedAssignments.timestamp or 0
    elseif TWRA_Assignments then
        localTimestamp = TWRA_Assignments.timestamp or 0
    end
    
    -- Compare timestamps
    local timestampDiff = self:CompareTimestamps(localTimestamp, timestamp)
    
    -- If our timestamp is newer, we should keep our data
    if timestampDiff > 0 then
        self:Debug("sync", "Our data is newer than BULK_STRUCTURE received - ignoring")
        return false
    end
    
    -- UPDATED: Validate bulkSyncTimestamp with this message's timestamp
    -- If we have a bulkSyncTimestamp but it doesn't match this message's timestamp
    if TWRA_CompressedAssignments and TWRA_CompressedAssignments.bulkSyncTimestamp then
        if TWRA_CompressedAssignments.bulkSyncTimestamp ~= timestamp then
            -- Timestamps don't match, discard all compressed assignments
            self:Debug("sync", "Timestamp mismatch: BULK_STRUCTURE timestamp (" .. timestamp .. 
                     ") doesn't match bulkSyncTimestamp (" .. TWRA_CompressedAssignments.bulkSyncTimestamp .. 
                     "). Discarding all compressed assignments.")
            
            -- Reset the entire compressed assignments table
            TWRA_CompressedAssignments = {}
        else
            -- Timestamps match, remove the bulkSyncTimestamp flag
            self:Debug("sync", "BULK_STRUCTURE timestamp matches bulkSyncTimestamp, clearing flag")
            TWRA_CompressedAssignments.bulkSyncTimestamp = nil
        end
    end
    
    -- Ensure TWRA_CompressedAssignments exists
    TWRA_CompressedAssignments = TWRA_CompressedAssignments or {}
    TWRA_CompressedAssignments.timestamp = timestamp
    
    -- Store the structure data
    -- Ensure the compressed data has the marker if needed
    if string.byte(structureData, 1) ~= 241 then
        structureData = "\241" .. structureData
    end
    
    -- Store the structure
    TWRA_CompressedAssignments.structure = structureData
    
    -- IMPORTANT: Decompress the structure now to rebuild navigation
    local success, decodedStructure = pcall(function()
        return self:DecompressStructureData(structureData)
    end)
    
    if not success or not decodedStructure then
        self:Debug("error", "Failed to decompress structure data from BSTR message")
        return false
    end
    
    -- Update assignment timestamp to match the structure
    if TWRA_Assignments then
        TWRA_Assignments.timestamp = timestamp
    else
        TWRA_Assignments = { timestamp = timestamp }
    end
    
    -- CRITICAL: Build skeleton from structure BEFORE rebuilding navigation
    -- This properly sets up the TWRA_Assignments data structure with placeholders
    local hasBuiltSkeleton = false
    if self.BuildSkeletonFromStructure then
        self:Debug("sync", "Building skeleton structure from decoded data")
        hasBuiltSkeleton = self:BuildSkeletonFromStructure(decodedStructure, timestamp, true)
        if hasBuiltSkeleton then
            self:Debug("sync", "Successfully built skeleton structure from decoded data")
        else
            self:Debug("error", "Failed to build skeleton structure - may cause navigation issues")
        end
    else
        self:Debug("error", "BuildSkeletonFromStructure function not available")
        return false
    end
    
    -- Process the structure if we have received bulk sections that match the timestamp
    local hasSections = TWRA_CompressedAssignments.sections and next(TWRA_CompressedAssignments.sections)
    
    -- Always rebuild navigation regardless of whether we have sections or not
    self:Debug("sync", "CRITICAL: Rebuilding navigation after skeleton structure creation")
    if self.RebuildNavigation then
        self:RebuildNavigation()
        self:Debug("sync", "Navigation successfully rebuilt")
    else
        self:Debug("error", "RebuildNavigation function not available")
    end
    
    if hasSections then
        self:Debug("sync", "Processing bulk structure after receiving bulk sections")
        
        -- Get the current section name or index
        local currentSection = TWRA_Assignments and TWRA_Assignments.currentSectionName or 1
        
        -- ADDED: Verify that the current section name exists in decodedStructure
        local sectionExists = false
        if type(currentSection) == "string" then
            -- When currentSection is a section name (string), verify it exists in decodedStructure
            for index, sectionName in pairs(decodedStructure) do
                if type(index) == "number" and type(sectionName) == "string" and sectionName == currentSection then
                    self:Debug("sync", "Verified section name '" .. currentSection .. "' exists in structure")
                    currentSection = index -- Convert section name to index for navigation
                    sectionExists = true
                    break
                end
            end
            
            if not sectionExists then
                self:Debug("sync", "Section name '" .. currentSection .. "' not found in structure, defaulting to section 1")
                currentSection = 1
            end
        elseif type(currentSection) == "number" then
            -- When currentSection is an index, verify it exists
            if decodedStructure[currentSection] then
                sectionExists = true
                self:Debug("sync", "Verified section index " .. currentSection .. " exists in structure")
            else
                self:Debug("sync", "Section index " .. currentSection .. " not found in structure, defaulting to section 1")
                currentSection = 1
            end
        else
            -- Invalid currentSection type, default to first section
            self:Debug("sync", "Invalid currentSection type, defaulting to section 1")
            currentSection = 1
        end
        
        if self.NavigateToSection then
            self:NavigateToSection(currentSection, "bulkSync")
        else
            self:Debug("error", "NavigateToSection function not available")
        end
        
        if self.RefreshAssignmentTable then
            self:RefreshAssignmentTable()
        else
            self:Debug("error", "RefreshAssignmentTable function not available")
        end
        
        if self.RebuildOSDIfVisible then
            self:RebuildOSDIfVisible()
        end
        
        self:Debug("sync", "Bulk sync data processing and navigation rebuild complete!", true)
    else
        self:Debug("sync", "Received bulk structure but no sections")
        
        -- Since we've already rebuilt navigation, just refresh UI if needed
        -- Use a timer to ensure everything is processed
        self:ScheduleTimer(function()
            -- Refresh UI if needed
            if self.RefreshAssignmentTable then
                self:RefreshAssignmentTable()
                self:Debug("sync", "Refreshed assignment table")
            else
                self:Debug("error", "RefreshAssignmentTable function not available")
            end
            
            -- Navigate to the first section as a fallback
            if self.NavigateToSection then
                self:NavigateToSection(1, "bulkSyncNoData")
                self:Debug("sync", "Navigated to first section (no section data)")
            end
        end, 0.3)
    end
    
    return true
end

-- Handle structure response commands (SRES)
function TWRA:HandleStructureResponseCommand(timestamp, structureData, sender)
    self:Debug("sync", "Received structure response from " .. sender)
    
    -- Cancel any pending structure request timeout
    if self.SYNC.structureRequestTimeout then
        self:CancelTimer(self.SYNC.structureRequestTimeout)
        self.SYNC.structureRequestTimeout = nil
    end
    
    -- Validate parameters
    if not timestamp or not structureData or structureData == "" then
        self:Debug("sync", "Invalid structure response: missing timestamp or data")
        return false
    end
    
    -- Convert timestamp to number
    timestamp = tonumber(timestamp)
    if not timestamp then
        self:Debug("sync", "Invalid timestamp format in structure response")
        return false
    end
    
    self:Debug("sync", "Processing structure response with timestamp: " .. timestamp)
    
    -- Compare with our current timestamp
    -- Only process if the incoming data is newer or we specifically requested it
    local shouldProcess = false
    local localTimestamp = TWRA_Assignments and TWRA_Assignments.timestamp or 0
    
    if localTimestamp < timestamp then
        shouldProcess = true
        self:Debug("sync", "Processing structure response - remote data is newer")
    elseif self.SYNC.requestedTimestamp and self.SYNC.requestedTimestamp == timestamp then
        shouldProcess = true
        self:Debug("sync", "Processing structure response - matches our requested timestamp")
    else
        self:Debug("sync", "Ignoring structure response - our data is newer or we didn't request it")
    end
    
    -- Process the structure data
    if shouldProcess then
        -- Check if the structure data has the compression marker at the beginning (byte 241)
        -- If not, add it to ensure proper decompression
        if structureData and string.len(structureData) > 0 then
            -- Check if data already has the marker
            local firstByte = string.byte(structureData, 1)
            -- If it doesn't have our marker (241), add it
            if firstByte ~= 241 then
                self:Debug("sync", "Adding compression marker to structure data")
                structureData = "\241" .. structureData
            end
        end
        
        self:ProcessStructureData(structureData, timestamp, sender)
    end
    
    return true
end

-- Function to process structure data (shared by both SRES and BSTR handlers)
function TWRA:ProcessStructureData(structureData, timestamp, sender)
    self:Debug("sync", "Processing structure data with timestamp: " .. timestamp)
    
    -- Make sure we have valid data
    if not structureData or structureData == "" then
        self:Debug("error", "Cannot process empty structure data")
        return false
    end
    
    -- Ensure TWRA_CompressedAssignments exists
    TWRA_CompressedAssignments = TWRA_CompressedAssignments or {}
    
    -- Store the compressed structure
    TWRA_CompressedAssignments.structure = structureData
    TWRA_CompressedAssignments.timestamp = timestamp
    
    -- Update TWRA_Assignments timestamp
    TWRA_Assignments = TWRA_Assignments or {}
    TWRA_Assignments.timestamp = timestamp
    
    -- Try to decompress the structure
    local success, decodedStructure = pcall(function()
        return self:DecompressStructureData(structureData)
    end)
    
    if not success or not decodedStructure then
        self:Debug("error", "Failed to decompress structure data: " .. (decodedStructure or "unknown error"))
        return false
    end
    
    -- IMPORTANT: Completely rebuild TWRA_Assignments to match the new structure
    -- Initialize data table if it doesn't exist
    TWRA_Assignments.data = TWRA_Assignments.data or {}
    
    -- If we're receiving a completely new structure, clear the existing data table
    -- but preserve any sections that exist in the new structure to retain data
    local preserveSections = {}
    for index, _ in pairs(decodedStructure) do
        if type(index) == "number" and TWRA_Assignments.data[index] then
            preserveSections[index] = TWRA_Assignments.data[index]
        end
    end
    
    -- Clear and rebuild the data table
    TWRA_Assignments.data = {}
    
    -- Process section structure into TWRA_Assignments
    local sectionsFound = 0
    for index, sectionName in pairs(decodedStructure) do
        if type(index) == "number" and type(sectionName) == "string" then
            -- Check if we had preserved data for this section
            if preserveSections[index] then
                -- Restore the preserved section data but update the name
                TWRA_Assignments.data[index] = preserveSections[index]
                TWRA_Assignments.data[index]["Section Name"] = sectionName
                self:Debug("sync", "Restored preserved section data for: " .. sectionName)
            else
                -- Create a new section entry
                TWRA_Assignments.data[index] = {
                    ["Section Name"] = sectionName,
                    ["Section Index"] = index,
                    ["NeedsProcessing"] = true,
                    ["Section Metadata"] = {
                        ["Note"] = {},
                        ["Warning"] = {},
                        ["GUID"] = {}
                    }
                }
                self:Debug("sync", "Created new section entry for: " .. sectionName)
            end
            sectionsFound = sectionsFound + 1
        end
    end
    
    -- Store section count and update currentSection if needed
    TWRA_Assignments.sectionCount = sectionsFound
    if not TWRA_Assignments.currentSection or TWRA_Assignments.currentSection > sectionsFound then
        TWRA_Assignments.currentSection = 1
        self:Debug("sync", "Reset currentSection to 1 as previous section was invalid")
    end
    
    self:Debug("sync", "Updated TWRA_Assignments with " .. sectionsFound .. " sections from structure")
    
    -- Request sections for this structure if we don't already have them
    if not self.SYNC.bulkSyncInProgress then
        self:Debug("sync", "Requesting sections for updated structure")
        self:RequestSectionsAfterStructure(decodedStructure, timestamp)
    else
        self:Debug("sync", "Bulk sync in progress, not requesting sections")
    end
    
    return true
end

-- Function to process bulk sync data (structure + sections)
function TWRA:ProcessBulkSyncData(decodedStructure, timestamp)
    self:Debug("sync", "Processing complete bulk sync data with timestamp: " .. timestamp)
    
    -- Ensure TWRA_Assignments is initialized
    TWRA_Assignments = TWRA_Assignments or {}
    TWRA_Assignments.timestamp = timestamp
    TWRA_Assignments.data = TWRA_Assignments.data or {}
    
    -- Count received sections to check if any are missing
    local receivedSections = 0
    local expectedSections = 0
    for index, _ in pairs(decodedStructure) do
        if type(index) == "number" then
            expectedSections = expectedSections + 1
            if TWRA_CompressedAssignments.sections[index] then
                receivedSections = receivedSections + 1
            end
        end
    end
    
    self:Debug("sync", "Received " .. receivedSections .. " out of " .. expectedSections .. " expected sections")
    
    if receivedSections < expectedSections then
        -- Some sections are missing, request them
        self:Debug("sync", "Some sections missing - requesting them")
        self:RequestMissingSectionsForBulkSync(decodedStructure, timestamp)
    else
        -- All sections received, process everything
        self:Debug("sync", "All sections received, processing complete bulk data")
        
        -- Process all sections
        for index, _ in pairs(decodedStructure) do
            if type(index) == "number" and TWRA_CompressedAssignments.sections[index] then
                -- Create section placeholders first
                self:CreateSectionPlaceholder(index, timestamp)
                
                -- Then process the section data
                local sectionData = TWRA_CompressedAssignments.sections[index]
                local success = self:ProcessCompressedSection(index, sectionData, false, true)
                
                if not success then
                    self:Debug("error", "Failed to process section " .. index .. " during bulk sync")
                end
            end
        end
        
        -- Extract player-relevant data if needed
        if self.ExtractPlayerRelevantData then
            self:ExtractPlayerRelevantData()
        end
        
        -- Navigate to current section and update UI
        local currentSection = TWRA_Assignments.currentSection or 1
        self:Debug("sync", "Navigating to section " .. currentSection .. " after processing bulk data")
        
        -- Use a timer to allow processing to complete
        self:ScheduleTimer(function()
            if self.NavigateToSection then
                self:NavigateToSection(currentSection, "bulkSync")
            end
            
            -- Refresh UI
            if self.RefreshAssignmentTable then
                self:RefreshAssignmentTable()
            end
            
            if self.RebuildOSDIfVisible then
                self:RebuildOSDIfVisible()
            end
            
            -- Notify user
            self:Debug("sync", "Bulk sync data processing complete!", true)
        end, 0.5)
    end
end

-- Function to request missing sections for bulk sync
function TWRA:RequestMissingSectionsForBulkSync(decodedStructure, timestamp)
    self:Debug("sync", "Requesting missing sections for bulk sync")
    
    local requestedCount = 0
    local requestDelay = 0
    
    -- Request each missing section with staggered timing
    for index, _ in pairs(decodedStructure) do
        if type(index) == "number" then
            -- Check if we already have this section
            if not TWRA_CompressedAssignments.sections or not TWRA_CompressedAssignments.sections[index] then
                -- Schedule each request with increasing delay to prevent network flooding
                self:ScheduleTimer(function()
                    if self.RequestSectionSync then
                        self:Debug("sync", "Requesting missing section " .. index .. " for bulk sync")
                        self:RequestSectionSync(index, timestamp)
                        requestedCount = requestedCount + 1
                    end
                end, requestDelay)
                
                requestDelay = requestDelay + 0.2 -- 200ms between requests
            end
        end
    end
    
    -- Set up a timer to check if we've received all sections
    self:ScheduleTimer(function()
        self:CheckBulkSyncCompleteness(decodedStructure, timestamp)
    end, requestDelay + 5.0) -- Check 5 seconds after last request
    
    self:Debug("sync", "Scheduled requests for missing sections: " .. requestedCount)
end

-- Function to check if bulk sync is complete after requesting missing sections
function TWRA:CheckBulkSyncCompleteness(decodedStructure, timestamp)
    self:Debug("sync", "Checking bulk sync completeness")
    
    -- Count total expected sections and received sections
    local expectedSections = 0
    local receivedSections = 0
    
    for index, _ in pairs(decodedStructure) do
        if type(index) == "number" then
            expectedSections = expectedSections + 1
            if TWRA_CompressedAssignments.sections and TWRA_CompressedAssignments.sections[index] then
                receivedSections = receivedSections + 1
            end
        end
    end
    
    self:Debug("sync", "Received " .. receivedSections .. " out of " .. expectedSections .. " expected sections")
    
    if receivedSections == expectedSections then
        -- All sections received, process full data
        self:Debug("sync", "All sections received after requests, processing complete bulk data")
        self:ProcessBulkSyncData(decodedStructure, timestamp)
    else
        -- Still missing sections - could retry or notify user
        self:Debug("sync", "Still missing " .. (expectedSections - receivedSections) .. " sections after requests", true)
    end
end

