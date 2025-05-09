-- TWRA Sync Message Handlers
-- Handles all incoming addon communications for synchronization
TWRA = TWRA or {}

-- Initialize SYNC namespace with new segmented sync commands
if not TWRA.SYNC then
    TWRA.SYNC = {
        PREFIX = "TWRA",
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
        VER = self.UnusedCommand,
        BSEC = self.HandleBulkSectionCommand, -- Bulk section handler
        BSTR = self.HandleBulkStructureCommand, -- Bulk structure handler
        MSREQ = self.HandleMissingSectionsRequestCommand, -- Missing sections request handler
        MSACK = self.HandleMissingSectionsAckCommand, -- Missing sections acknowledgment handler
        MSRES = self.HandleMissingSectionResponseCommand, -- Missing section response handler
        BSREQ = self.HandleBulkSyncRequestCommand, -- Bulk sync request handler
        BSACK = self.HandleBulkSyncAckCommand, -- Bulk sync acknowledgment handler
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
    elseif command == self.SYNC.COMMANDS.MISS_SEC_REQ then
        -- Handle MSREQ (missing sections request)
        if self.HandleMissingSectionsRequestCommand then
            self:HandleMissingSectionsRequestCommand(components[2], components[3], components[4], sender)
        end
    elseif command == self.SYNC.COMMANDS.MISS_SEC_ACK then
        -- Handle MSACK (missing sections acknowledgment)
        if self.HandleMissingSectionsAckCommand then
            self:HandleMissingSectionsAckCommand(components[2], components[3], components[4], sender)
        end
    elseif command == self.SYNC.COMMANDS.MISS_SEC_RESP then
        -- Handle MSRES (missing section response)
        if self.HandleMissingSectionResponseCommand then
            self:HandleMissingSectionResponseCommand(components[2], components[3], self:ExtractDataPortion(message, 4), sender)
        end
    elseif command == self.SYNC.COMMANDS.BULK_SYNC_REQ then
        -- Handle BSREQ (bulk sync request)
        if self.HandleBulkSyncRequestCommand then
            self:HandleBulkSyncRequestCommand(sender)
        end
    elseif command == self.SYNC.COMMANDS.BULK_SYNC_ACK then
        -- Handle BSACK (bulk sync acknowledgment)
        if self.HandleBulkSyncAckCommand then
            self:HandleBulkSyncAckCommand(components[2], components[3])
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
        -- They have a newer version - LOG ONLY, NO SYNC REQUEST
        self:Debug("sync", "Detected newer data from " .. sender .. " (timestamp " .. 
                  timestamp .. " > " .. ourTimestamp .. "), but automatic sync is disabled", true)
        
        -- Only store the section index for reference, but don't trigger sync
        self.SYNC.pendingSection = sectionIndex
        self:Debug("sync", "User must manually request newer data using /twra sync", true)
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
    -- Note: We don't trigger a new sync request here, just update the timestamp
    if TWRA_Assignments then
        local currentTimestamp = TWRA_Assignments.timestamp or 0
        if tonumber(timestamp) > currentTimestamp then
            self:Debug("sync", "Updating our timestamp to " .. timestamp .. " from BULK_SECTION without triggering a new sync")
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
        end
    end
    
    -- Ensure TWRA_CompressedAssignments exists
    TWRA_CompressedAssignments = TWRA_CompressedAssignments or {}
    
    -- Store the structure data
    -- Ensure the compressed data has the marker if needed
    if string.byte(structureData, 1) ~= 241 then
        structureData = "\241" .. structureData
    end
    -- Store the structure
    TWRA_CompressedAssignments.structure = structureData

    -- Update Timestamp after storing the data
    TWRA_CompressedAssignments.timestamp = timestamp
    
    -- IMPORTANT: Decompress the structure now to rebuild navigation
    local success, decodedStructure = pcall(function()
        return self:DecompressStructureData(structureData)
    end)
    
    if not success or not decodedStructure then
        self:Debug("error", "Failed to decompress structure data from BSTR message")
        return false
    end
    
    -- Update assignment timestamp to match the structure
    -- IMPORTANT: Just update the timestamp without triggering new sync requests
    if TWRA_Assignments then
        self:Debug("sync", "Updating our timestamp to " .. timestamp .. " from BULK_STRUCTURE without triggering a new sync")
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
        self:Debug("sync", "Sections available after receiving bulk structure")
        
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

        self:ProcessSectionData()
        
        -- Navigate to the selected section after processing all data
        if self.NavigateToSection then
            -- CRITICAL FIX: Use "fromSync" context instead of "bulkSync" to prevent broadcast
            -- "bulkSync" wasn't being recognized in the broadcast prevention logic
            self:Debug("sync", "Navigating to section " .. currentSection .. " with 'fromSync' context to prevent broadcasting")
            self:NavigateToSection(currentSection, "fromSync")
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
    
    -- Check if we have any missing sections after processing
    local missingCount = 0
    if TWRA_CompressedAssignments.sections and TWRA_CompressedAssignments.sections.missing then
        for idx, _ in pairs(TWRA_CompressedAssignments.sections.missing) do
            if type(idx) == "number" then
                missingCount = missingCount + 1
            end
        end
    end
    
    -- Only clear bulkSyncTimestamp if we have no missing sections
    if missingCount == 0 then
        self:Debug("sync", "No missing sections, clearing bulkSyncTimestamp")
        TWRA_CompressedAssignments.bulkSyncTimestamp = nil
    else
        self:Debug("sync", "Still have " .. missingCount .. " missing sections, keeping bulkSyncTimestamp")
        
        -- Request missing sections through whisper to sender
        self:Debug("sync", "Requesting " .. missingCount .. " missing sections from " .. sender)
        self:RequestMissingSectionsWhisper(sender, timestamp)
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
        TWRA:ProcessSectionData()
    end
    
    return true
end

-- Function to request missing sections via whisper to the original sender
function TWRA:RequestMissingSectionsWhisper(sender, timestamp, timeoutSeconds)
    self:Debug("sync", "Requesting missing sections via hidden addon whisper to " .. sender)
    
    -- Skip if not valid
    if not sender or not timestamp then
        self:Debug("error", "Missing required arguments for RequestMissingSectionsWhisper")
        return false
    end
    
    -- Ensure TWRA_CompressedAssignments exists and has sections
    if not TWRA_CompressedAssignments or not TWRA_CompressedAssignments.sections then
        self:Debug("error", "No compressed assignments data available")
        return false
    end
    
    -- Mark as timestamp for this sync process
    TWRA_CompressedAssignments.bulkSyncTimestamp = timestamp
    
    -- Initialize missing sections list if needed
    if not TWRA_CompressedAssignments.sections.missing then
        self:Debug("sync", "No missing sections to request")
        return false
    end
    
    -- Build a comma-separated list of missing section indices
    local missingSectionsList = ""
    local missingSectionsCount = 0
    
    for idx, _ in pairs(TWRA_CompressedAssignments.sections.missing) do
        if type(idx) == "number" then
            if missingSectionsList ~= "" then
                missingSectionsList = missingSectionsList .. ","
            end
            missingSectionsList = missingSectionsList .. idx
            missingSectionsCount = missingSectionsCount + 1
        end
    end
    
    if missingSectionsList == "" then
        self:Debug("sync", "No missing sections to request after filtering")
        return false
    end
    
    -- Create the request message
    local message = self:CreateMissingSectionsRequestMessage(timestamp, missingSectionsList, "")
    
    -- IMPORTANT FIX: Use SendAddonMessage with WHISPER distribution instead of SendChatMessage
    SendAddonMessage(self.SYNC.PREFIX, message, "WHISPER", sender)
    
    self:Debug("sync", "Sent hidden addon whisper request for " .. missingSectionsCount .. " missing sections to " .. sender)
    
    -- Set up timeout to fall back to group request if no response
    local timeoutDelay = timeoutSeconds or 5 -- Default 5 second timeout
    
    -- Cancel any existing timeout
    if self.SYNC.missingSectionsTimeout then
        self:CancelTimer(self.SYNC.missingSectionsTimeout)
    end
    
    -- Store original sender for later reference
    self.SYNC.missingSectionsOriginalSender = sender
    self.SYNC.missingSectionsList = missingSectionsList
    
    -- Set up the timeout
    self.SYNC.missingSectionsTimeout = self:ScheduleTimer(function()
        self:Debug("sync", "Whisper request to " .. sender .. " timed out, falling back to group request")
        self:RequestMissingSectionsGroup(timestamp, missingSectionsList, sender)
    end, timeoutDelay)
    
    return true
end

-- Function to request missing sections from the group (fallback when whisper times out)
function TWRA:RequestMissingSectionsGroup(timestamp, sectionList, originalSender)
    self:Debug("sync", "Requesting missing sections from group")
    
    -- Skip if not in a group
    if GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 then
        self:Debug("sync", "Not in a group, cannot request missing sections")
        return false
    end
    
    -- Either use the provided list or build a new one
    local missingSectionsList = sectionList
    
    if not missingSectionsList or missingSectionsList == "" then
        -- Build a comma-separated list of missing section indices
        missingSectionsList = ""
        local missingSectionsCount = 0
        
        for idx, _ in pairs(TWRA_CompressedAssignments.sections.missing) do
            if type(idx) == "number" then
                if missingSectionsList ~= "" then
                    missingSectionsList = missingSectionsList .. ","
                end
                missingSectionsList = missingSectionsList .. idx
                missingSectionsCount = missingSectionsCount + 1
            end
        end
        
        if missingSectionsList == "" then
            self:Debug("sync", "No missing sections to request from group")
            return false
        end
    end
    
    -- Create and send the request message to the group
    local message = self:CreateMissingSectionsRequestMessage(timestamp, missingSectionsList, originalSender or "")
    local success = self:SendAddonMessage(message)
    
    if success then
        self:Debug("sync", "Group request for missing sections sent")
    else
        self:Debug("error", "Failed to send group request for missing sections")
    end
    
    return success
end

-- Function to handle missing sections request messages (MSREQ)
function TWRA:HandleMissingSectionsRequestCommand(timestamp, sectionList, originalSender, requester)
    self:Debug("sync", "Received missing sections request from " .. requester .. " with sectionList: " .. sectionList)
    
    -- Skip if invalid
    if not timestamp or not sectionList then
        self:Debug("error", "Invalid missing sections request: missing timestamp or section list")
        return false
    end
    
    -- Convert timestamp to number
    timestamp = tonumber(timestamp)
    if not timestamp then
        self:Debug("error", "Invalid timestamp in missing sections request")
        return false
    end
    
    -- If we're the original sender, respond immediately without acknowledgment
    local isDirectWhisper = (originalSender == "")
    local playerName = UnitName("player")
    
    if isDirectWhisper or originalSender == playerName then
        self:Debug("sync", "We are the original sender or this is a direct whisper, responding immediately")
        return self:SendMissingSections(timestamp, sectionList, requester)
    end
    
    -- Check if we have the requested data with matching timestamp
    if not TWRA_CompressedAssignments or 
       not TWRA_CompressedAssignments.timestamp or 
       TWRA_CompressedAssignments.timestamp ~= timestamp then
        self:Debug("sync", "We don't have the requested data with matching timestamp")
        return false
    end
    
    -- Parse the section list
    local sectionsToSend = {}
    local sectionsWeHave = {}
    local sectionsMissing = {}
    
    -- Split the comma-separated list
    for sectionIdx in string.gfind(sectionList, "([^,]+)") do
        local idx = tonumber(sectionIdx)
        if idx then
            table.insert(sectionsToSend, idx)
            
            -- Check if we have this section
            if TWRA_CompressedAssignments.sections and TWRA_CompressedAssignments.sections[idx] then
                sectionsWeHave[idx] = true
            else
                sectionsMissing[idx] = true
            end
        end
    end
    
    -- Count how many sections we have
    local countWeHave = 0
    for _, _ in pairs(sectionsWeHave) do
        countWeHave = countWeHave + 1
    end
    
    if countWeHave == 0 then
        self:Debug("sync", "We don't have any of the requested sections")
        return false
    end
    
    -- Send acknowledgment to the group first to prevent multiple responses
    local ackMessage = self:CreateMissingSectionsAckMessage(timestamp, sectionList, requester)
    self:SendAddonMessage(ackMessage)
    self:Debug("sync", "Sent acknowledgment for missing sections request to prevent duplication")
    
    -- Add a short delay before sending the actual data to allow for other acks
    self:ScheduleTimer(function()
        self:SendMissingSections(timestamp, sectionList, requester)
    end, 0.5)
    
    return true
end

-- Function to handle missing sections acknowledgment messages (MSACK)
function TWRA:HandleMissingSectionsAckCommand(timestamp, sectionList, requester, respondent)
    self:Debug("sync", respondent .. " acknowledged missing sections request from " .. requester)
    
    -- Only care about acknowledgments for our own requests
    local playerName = UnitName("player")
    if requester ~= playerName then
        self:Debug("sync", "Ignoring acknowledgment for someone else's request")
        return false
    end
    
    -- Mark that someone is handling our request
    self.SYNC.missingSectionsAcknowledged = true
    self.SYNC.missingSectionsRespondent = respondent
    
    self:Debug("sync", "Our missing sections request is being handled by " .. respondent)
    
    -- Cancel timeout timer for group request since someone is handling it
    if self.SYNC.missingSectionsTimeout then
        self:CancelTimer(self.SYNC.missingSectionsTimeout)
        self.SYNC.missingSectionsTimeout = nil
    end
    
    return true
end

-- Function to handle missing section response messages (MSRES)
function TWRA:HandleMissingSectionResponseCommand(timestamp, sectionIndex, sectionData, sender)
    self:Debug("sync", "Received missing section " .. sectionIndex .. " from " .. sender)
    
    -- Skip if invalid
    if not timestamp or not sectionIndex or not sectionData then
        self:Debug("error", "Invalid missing section response: missing timestamp, index, or data")
        return false
    end
    
    -- Convert parameters to proper types
    timestamp = tonumber(timestamp)
    sectionIndex = tonumber(sectionIndex)
    
    if not timestamp or not sectionIndex then
        self:Debug("error", "Invalid types in missing section response")
        return false
    end
    
    -- Make sure TWRA_CompressedAssignments and its sections exist
    if not TWRA_CompressedAssignments then
        TWRA_CompressedAssignments = {}
    end
    
    if not TWRA_CompressedAssignments.sections then
        TWRA_CompressedAssignments.sections = {}
    end
    
    -- Store the data
    TWRA_CompressedAssignments.sections[sectionIndex] = sectionData
    
    -- Update the missing sections tracking
    if TWRA_CompressedAssignments.sections.missing then
        TWRA_CompressedAssignments.sections.missing[sectionIndex] = nil
    end
    
    self:Debug("sync", "Stored missing section " .. sectionIndex)
    
    -- Check if we have all sections now
    local stillMissing = 0
    if TWRA_CompressedAssignments.sections.missing then
        for idx, _ in pairs(TWRA_CompressedAssignments.sections.missing) do
            if type(idx) == "number" then
                stillMissing = stillMissing + 1
            end
        end
    end
    
    -- If no more missing sections, clear the bulkSyncTimestamp and process all data
    if stillMissing == 0 then
        self:Debug("sync", "All missing sections received, processing complete data")
        
        -- Clear the bulkSyncTimestamp to indicate sync is complete
        TWRA_CompressedAssignments.bulkSyncTimestamp = nil
        
        -- Process all section data
        self:ProcessSectionData()
        
        -- Refresh UI
        if self.RefreshAssignmentTable then
            self:RefreshAssignmentTable()
        else
            self:Debug("error", "RefreshAssignmentTable function not available")
        end
        
        if self.RebuildOSDIfVisible then
            self:RebuildOSDIfVisible()
        end
        
        self:Debug("sync", "Missing sections sync complete!", true)
    else
        self:Debug("sync", "Still missing " .. stillMissing .. " sections")
    end
    
    return true
end

-- Function to send missing sections to a requester
function TWRA:SendMissingSections(timestamp, sectionList, requester)
    self:Debug("sync", "Sending missing sections to " .. requester)
    
    -- Make sure we have the data with matching timestamp
    if not TWRA_CompressedAssignments or 
       not TWRA_CompressedAssignments.timestamp or 
       TWRA_CompressedAssignments.timestamp ~= tonumber(timestamp) then
        self:Debug("sync", "We don't have the data with matching timestamp")
        return false
    end
    
    -- Process the section list
    local sectionsToSend = {}
    
    -- Split the comma-separated list
    for sectionIdx in string.gfind(sectionList, "([^,]+)") do
        local idx = tonumber(sectionIdx)
        if idx then
            table.insert(sectionsToSend, idx)
        end
    end
    
    -- Count how many we'll send
    local sectionsCount = table.getn(sectionsToSend)
    self:Debug("sync", "Preparing to send " .. sectionsCount .. " sections to " .. requester)
    
    -- Send each section with a small delay between to prevent network flooding
    local sendDelay = 0
    local sentCount = 0
    
    for _, sectionIndex in ipairs(sectionsToSend) do
        -- Check if we have this section
        if TWRA_CompressedAssignments.sections and TWRA_CompressedAssignments.sections[sectionIndex] then
            local sectionData = TWRA_CompressedAssignments.sections[sectionIndex]
            
            -- Schedule sending with increasing delay
            self:ScheduleTimer(function()
                -- Create the response message
                local message = self:CreateMissingSectionResponseMessage(timestamp, sectionIndex, sectionData)
                
                -- Use SendAddonMessage with WHISPER distribution for hidden communication
                SendAddonMessage(self.SYNC.PREFIX, message, "WHISPER", requester)
                
                sentCount = sentCount + 1
                self:Debug("sync", "Sent section " .. sectionIndex .. " via hidden addon whisper to " .. requester .. " (" .. sentCount .. "/" .. sectionsCount .. ")")
            end, sendDelay)
            
            -- Increase delay for next section
            sendDelay = sendDelay + 0.3 -- 300ms between sections
        end
    end
    
    return true
end

-- Function to handle bulk sync request (BSREQ)
function TWRA:HandleBulkSyncRequestCommand(sender)
    self:Debug("sync", "Received bulk sync request from " .. sender)
    
    -- ANTI-LOOP: Check if we've already received and processed this request
    local now = GetTime()
    
    -- Initialize tracking table if it doesn't exist
    self.SYNC.processedBulkRequests = self.SYNC.processedBulkRequests or {}
    
    -- Track specific sender+timestamp combinations
    local requestKey = sender .. "_" .. now
    
    -- If this exact request was processed in the last 60 seconds, ignore it completely
    if self.SYNC.processedBulkRequests[requestKey] then
        self:Debug("sync", "Already processed this exact request, ignoring duplicate")
        return false
    end
    
    -- Mark this request as processed IMMEDIATELY to prevent any chance of duplicate processing
    self.SYNC.processedBulkRequests[requestKey] = now
    
    -- Clean up old entries from tracking table (older than 60 seconds)
    for key, timestamp in pairs(self.SYNC.processedBulkRequests) do
        if now - timestamp > 60 then
            self.SYNC.processedBulkRequests[key] = nil
        end
    end
    
    -- Check if we have data to respond with
    if not TWRA_Assignments or not TWRA_Assignments.data then
        self:Debug("sync", "No assignments data available to share")
        return false
    end
    
    -- Check if we have compressed assignments data
    if not TWRA_CompressedAssignments or not TWRA_CompressedAssignments.sections then
        self:Debug("sync", "No compressed assignments data available to share")
        return false
    end
    
    -- Get our timestamp
    local ourTimestamp = TWRA_Assignments.timestamp or 0
    
    -- Count how many sections we have vs. how many we should have
    local sectionsWeHave = 0
    for sectionIndex, _ in pairs(TWRA_CompressedAssignments.sections) do
        if type(sectionIndex) == "number" then
            sectionsWeHave = sectionsWeHave + 1
        end
    end
    
    -- Count how many sections should be in the structure
    local expectedSections = 0
    for sectionIndex, _ in pairs(TWRA_Assignments.data) do
        if type(sectionIndex) == "number" then
            expectedSections = expectedSections + 1
        end
    end
    
    -- Check if we have all expected sections
    if sectionsWeHave < expectedSections then
        self:Debug("sync", "Not responding to bulk sync request - we only have " .. 
                  sectionsWeHave .. " of " .. expectedSections .. " expected sections")
        return false
    end
    
    -- Verify that every section has data
    local missingData = false
    for sectionIndex, _ in pairs(TWRA_Assignments.data) do
        if type(sectionIndex) == "number" then
            if not TWRA_CompressedAssignments.sections[sectionIndex] then
                missingData = true
                self:Debug("sync", "Missing compressed data for section " .. sectionIndex)
                break
            end
        end
    end
    
    if missingData then
        self:Debug("sync", "Not responding to bulk sync request - missing compressed data for some sections")
        return false
    end
    
    -- CRITICAL: Prevent multiple active sync sessions
    if self.SYNC.syncInProgress then
        self:Debug("sync", "Another sync is already in progress, ignoring this request", true)
        return false
    end
    
    -- Mark that sync is now in progress to prevent multiple simultaneous responses
    self.SYNC.syncInProgress = true
    
    -- All checks passed, we can respond
    -- Send acknowledgment with our timestamp
    local ackMessage = self:CreateBulkSyncAckMessage(ourTimestamp, UnitName("player"))
    self:SendAddonMessage(ackMessage)
    self:Debug("sync", "Sent bulk sync acknowledgment with timestamp " .. ourTimestamp)
    
    -- IMPORTANT: Clean up old timer if there's one running
    if self.SYNC.pendingBulkResponse and self.SYNC.pendingBulkResponse.timer then
        self:CancelTimer(self.SYNC.pendingBulkResponse.timer)
        self.SYNC.pendingBulkResponse.timer = nil
    end
    
    -- Set up a delayed response
    -- The delay is randomized based on raid size to prevent network flooding
    local responseDelay = 2 + (math.random() * 2) -- Base delay 2-4 seconds
    
    -- Store our response info
    self.SYNC.pendingBulkResponse = {
        timestamp = ourTimestamp,
        requester = sender,
        responseTime = now,
        timer = self:ScheduleTimer(function()
            -- Check if someone with a newer timestamp has already responded
            if self.SYNC.newerTimestampResponded and self.SYNC.newerTimestampResponded > ourTimestamp then
                self:Debug("sync", "Not sending bulk data - someone with newer timestamp already responded: " .. 
                          self.SYNC.newerTimestampResponded .. " > " .. ourTimestamp)
                self.SYNC.syncInProgress = false
                return
            end
            
            -- We have the newest timestamp (or tied), send the data
            self:Debug("sync", "We have the newest data, sending all sections")
            local success = self:SendAllSections()
            
            -- IMPORTANT: Clear the sync in progress flag AFTER sending completes
            self.SYNC.syncInProgress = false
            
            -- Log the result
            if success then
                self:Debug("sync", "Successfully sent all sections, sync complete", true)
            else
                self:Debug("error", "Failed to send all sections", true)
            end
            
            -- IMPORTANT: Schedule cleanup of state variables
            self:ScheduleTimer(function()
                self:Debug("sync", "Cleaning up bulk sync state variables")
                self.SYNC.newerTimestampResponded = nil
                self.SYNC.pendingBulkResponse = nil
            end, 5) -- Clean up 5 seconds after sending
        end, responseDelay)
    }
    
    -- Setup safety timeout to clear syncInProgress flag if something goes wrong
    self:ScheduleTimer(function()
        if self.SYNC.syncInProgress then
            self:Debug("sync", "Safety timeout: clearing syncInProgress flag", true)
            self.SYNC.syncInProgress = false
        end
    end, responseDelay + 30) -- 30 seconds after expected response time
    
    self:Debug("sync", "Will respond with all sections in " .. responseDelay .. " seconds unless someone with newer data responds")
    
    return true
end

-- Function to handle bulk sync acknowledgment (BSACK)
function TWRA:HandleBulkSyncAckCommand(timestamp, acknowledgedBy)
    self:Debug("sync", "Received bulk sync acknowledgment from " .. acknowledgedBy .. " with timestamp " .. timestamp)
    
    -- Convert timestamp to number
    timestamp = tonumber(timestamp)
    if not timestamp then
        self:Debug("error", "Invalid timestamp format in bulk sync acknowledgment")
        return false
    end
    
    -- Cancel the timeout timer since someone is responding
    if self.SYNC.bulkSyncRequestTimeout then
        self:CancelTimer(self.SYNC.bulkSyncRequestTimeout)
        self.SYNC.bulkSyncRequestTimeout = nil
    end
    
    -- Record this acknowledgment
    self.SYNC.bulkSyncAcknowledgments = self.SYNC.bulkSyncAcknowledgments or {}
    self.SYNC.bulkSyncAcknowledgments[acknowledgedBy] = timestamp
    
    -- Update the newest timestamp seen
    if not self.SYNC.newerTimestampResponded or timestamp > self.SYNC.newerTimestampResponded then
        self.SYNC.newerTimestampResponded = timestamp
    end
    
    -- If we're the requester, show a message about the response
    if self.SYNC.lastRequestTime and (GetTime() - self.SYNC.lastRequestTime < 15) then
        self:Debug("sync", acknowledgedBy .. " acknowledged with timestamp " .. timestamp, true)
        
        -- IMPORTANT: Schedule cleanup of requester state variables to prevent recurring sync loops
        local cleanupTime = 15 -- 15 seconds cleanup time
        
        -- Cancel existing cleanup timer if it exists
        if self.SYNC.requesterCleanupTimer then
            self:CancelTimer(self.SYNC.requesterCleanupTimer)
        end
        
        -- Create new cleanup timer
        self.SYNC.requesterCleanupTimer = self:ScheduleTimer(function()
            self:Debug("sync", "Cleaning up requester state variables")
            self.SYNC.bulkSyncAcknowledgments = {}
            self.SYNC.newerTimestampResponded = nil
            self.SYNC.lastRequestTime = 0 -- Reset request time to prevent auto-triggering
            self.SYNC.requesterCleanupTimer = nil
        end, cleanupTime)
    end
    
    -- If we have a pending response and the incoming timestamp is newer than ours, cancel our response
    if self.SYNC.pendingBulkResponse and timestamp > self.SYNC.pendingBulkResponse.timestamp then
        self:Debug("sync", "Canceling our pending response - " .. acknowledgedBy .. 
                  " has newer data (" .. timestamp .. " > " .. self.SYNC.pendingBulkResponse.timestamp .. ")")
        
        if self.SYNC.pendingBulkResponse.timer then
            self:CancelTimer(self.SYNC.pendingBulkResponse.timer)
            self.SYNC.pendingBulkResponse.timer = nil
        end
        
        -- Make sure to clear syncInProgress flag
        self.SYNC.syncInProgress = false
        
        self.SYNC.pendingBulkResponse = nil
    end
    
    return true
end

