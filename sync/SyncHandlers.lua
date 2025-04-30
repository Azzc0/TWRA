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
    }  
    self:Debug("sync", "Initialized message handler map with " .. self:GetTableSize(self.syncHandlers) .. " handlers")
end

-- Main addon message handler - routes messages to appropriate handlers
function TWRA:HandleAddonMessage(message, distribution, sender)
    -- Skip processing if message is empty
    if not message or message == "" then
        self:Debug("sync", "Empty message from " .. sender .. ", skipping")
        return
    end
    
    -- Log the full message for debugging if it's not from ourselves
    if sender ~= UnitName("player") then
        self:Debug("sync", "Received message from " .. sender .. ": " .. message, true)
    end
    
    -- Enhanced debug for the message parsing step
    self:Debug("sync", "Parsing message: " .. message, true)
    
    -- More robust message parsing to avoid silent failures
    local command, rest = nil, nil
    local colonPos = string.find(message, ":", 1, true) -- Find first colon with plain search
    
    if colonPos and colonPos > 1 then
        command = string.sub(message, 1, colonPos-1)
        rest = string.sub(message, colonPos+1)
        self:Debug("sync", "Parsed command: '" .. command .. "', rest: '" .. rest .. "'", true)
    else
        self:Debug("sync", "Malformed message, no colon found: " .. message, true)
        return
    end
    
    if not command or command == "" then
        self:Debug("sync", "Malformed message, empty command: " .. message, true)
        return
    end
    
    -- Initialize handlers table if not already done
    if not self.syncHandlers then
        self:InitializeHandlerMap()
    end
    self:Debug("sync", "Command used:" .. command)
    -- Route to the appropriate handler using the handler table
    local handler = self.syncHandlers[command]
    if handler then
        -- Special cases for handlers that need the full message
        if command == "DRES" or command == "SRES" or command == "SECRES" or command == "ANC" then
            handler(self, rest, sender, message)
        else
            -- Standard handler call with just the rest of the message
            handler(self, rest, sender)
        end
    else
        -- Unknown command
        self:Debug("sync", "Unknown command from " .. sender .. ": " .. command)
    end
end

-- Helper function to extract timestamp from a message
function TWRA:ExtractTimestampFromMessage(message)
    if not message or type(message) ~= "string" then
        self:Debug("sync", "Failed to extract timestamp - invalid message")
        return nil, message
    end
    
    -- For SECTION, format is timestamp:sectionIndex
    local colonPos = string.find(message, ":", 1, true)
    if not colonPos then
        self:Debug("sync", "Failed to extract timestamp - no colons found")
        return nil, message
    end
    
    local timestampStr = string.sub(message, 1, colonPos - 1)
    local timestamp = tonumber(timestampStr)
    
    if not timestamp then
        self:Debug("sync", "Failed to extract timestamp - invalid format")
        return nil, message
    end
    
    -- Return both timestamp and remaining content (sectionIndex)
    local remainingContent = string.sub(message, colonPos + 1)
    return timestamp, remainingContent
end

-- Use the centralized timestamp comparison function from Sync.lua
function TWRA:CheckTimestampAndHandleResponse(remoteTimestamp, sender)
    -- Get our current timestamp from assignments
    local localTimestamp = 0
    if TWRA_Assignments and TWRA_Assignments.timestamp then
        localTimestamp = tonumber(TWRA_Assignments.timestamp) or 0
    end
    
    -- Debug the comparison
    self:Debug("sync", "CheckTimestampAndHandleResponse - Local: " .. localTimestamp .. ", Remote: " .. remoteTimestamp)
    
    -- Use the centralized function for timestamp comparison
    local comparison = self:CompareTimestamps(localTimestamp, remoteTimestamp)
    
    if comparison > 0 then
        -- Our data is newer - log but don't act
        self:Debug("sync", "Our data is NEWER")
        
        -- If we're asked to respond with our newer structure, do so
        if sender then
            self:Debug("sync", "Sending our newer structure data to " .. sender)
            self:RespondWithStructure(sender)
        end
        
        return -1 -- Caller should not proceed with normal flow
        
    elseif comparison < 0 then
        -- Remote data is newer - request structure
        self:Debug("sync", "Remote data is NEWER")
        
        -- Request the structure sync
        self:Debug("sync", "Requesting newer structure data (timestamp: " .. remoteTimestamp .. ")")
        self:RequestStructureSync(remoteTimestamp)
            
        -- Set a timeout for waiting for the response
        self.SYNC.structureRequestTimeout = self:ScheduleTimer(function()
            self:Debug("sync", "Structure request timeout - no response received within 1 second")
            -- Could implement fallback behavior here
        end, 1.0)
            
        return 1 -- Caller should not proceed with normal flow
    else
        -- Timestamps are equal - proceed normally
        self:Debug("sync", "Timestamps are EQUAL")
        return 0 -- Timestamps are equal, caller can proceed with normal flow
    end
end

-- Handle a section change command received from another player
function TWRA:HandleSectionCommand(message, sender)
    if not message or type(message) ~= "string" then
        self:Debug("sync", "Received invalid section command from " .. sender)
        return false
    end
    self:Debug("sync", "Welcome to the Section Coammand HAndler")
    -- The message format is "timestamp:sectionIndex" 
    -- Parse the timestamp and sectionIndex directly from the message
    local timestamp, sectionIndex = self:ExtractTimestampFromMessage(message)

    -- Extract parts
    local timestampComparison = self:CheckTimestampAndHandleResponse(timestamp, sender)
    
    if not sectionIndex then
        self:Debug("sync", "Invalid section index in command from " .. sender)
        return false
    end
    
    self:Debug("sync", "Parsed section command with section:" .. sectionIndex)
    
    -- Store the section index before timestamp comparison
    self.SYNC.pendingSection = sectionIndex
    
    -- Compare timestamps - simplified comparison for now
    if timestampComparison == 0 then
        -- Our timestamp is equal - navigate to the section
        self:NavigateToSection(tonumber(sectionIndex), "fromSync")  -- suppressSync=true
        self:Debug("sync", "Navigated to section " .. sectionIndex .. " from sync command by " .. sender)
    else 
        -- timestamp mismatch. CheckTimestampAndHandleResponse should already be trying to get us on the same timestamp
        self:Debug("sync", "Timestamp mismatch, not navigating.")
    end
end

-- Handle an announcement command from sync operations
function TWRA:HandleAnnounceCommand(message, sender)
    if not message or type(message) ~= "string" then
        self:Debug("sync", "Received invalid announce command from " .. sender)
        return false
    end
    
    -- Extract timestamp using our helper function
    local timestamp, _ = self:ExtractTimestampFromMessage(message)
    if not timestamp then
        self:Debug("sync", "Invalid timestamp in announce command from " .. sender)
        return false
    end
    
    -- Compare timestamps
    local comparison = self:CheckTimestampAndHandleResponse(timestamp, sender)
    
    if comparison < 0 then
        -- Their timestamp is newer - request their structure data
        return true
    else
        -- Our data is newer or the same - ignore
        return true
    end
end

function TWRA:UnusedCommand()    -- Placeholder for unused command
    self:Debug("sync", "Unused command handler called")
end

-- Handle incoming structure request messages
function TWRA:HandleStructureRequestCommand(message, sender)
    self:Debug("sync", "Received structure request from " .. sender)
    
    -- Extract the requested timestamp from the message (SREQ:timestamp format)
    local requestedTimestamp = tonumber(message)
    if not requestedTimestamp then
        self:Debug("sync", "Invalid structure request format from " .. sender)
        return false
    end
    
    -- Check if we have any data to share
    if not TWRA_CompressedAssignments or not TWRA_CompressedAssignments.structure then
        self:Debug("sync", "No structure data available to share with " .. sender)
        return false
    end
    
    -- Get our current data timestamp
    local ourTimestamp = TWRA_CompressedAssignments.timestamp
    
    -- Compare timestamps
    local comparison = self:CheckTimestampAndHandleResponse(requestedTimestamp, sender)
    
    self:Debug("sync", "After timestamp check, comparison result: " .. tostring(comparison))
    
    -- Changed from comparison < 0 to comparison == -1 to match the return value from CheckTimestampAndHandleResponse
    if comparison == 1 then
        -- Our data is older than requested - don't respond
        self:Debug("sync", "Our data (" .. ourTimestamp .. ") is older than requested (" 
                 .. requestedTimestamp .. ") - not responding")
        return false
    end
    
    self:Debug("sync", "Proceeding with structure response - our timestamp: " .. ourTimestamp)
    
    -- Use the QueueStructureResponse function instead of directly scheduling a timer
    self:QueueStructureResponse(ourTimestamp, sender)
    
    return true
end

-- Handle structure response commands (SRES)
function TWRA:HandleStructureResponseCommand(message, sender)
    self:Debug("sync", "Received structure response from " .. sender)
    
    -- Cancel any pending structure request timeout
    if self.SYNC.structureRequestTimeout then
        self:CancelTimer(self.SYNC.structureRequestTimeout)
        self.SYNC.structureRequestTimeout = nil
    end
    
    -- Extract timestamp and structure data from the message using our helper
    local timestamp, structureData = self:ExtractTimestampFromMessage(message)
    
    if not timestamp or not structureData or structureData == "" then
        self:Debug("sync", "Invalid structure response: missing timestamp or data")
        return
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
end

-- Handle section request commands (SECREQ)
function TWRA:HandleSectionRequestCommand(message, sender)
    -- Extract timestamp and section index from the message using our helper
    local timestamp, remainingContent = self:ExtractTimestampFromMessage(message)
    local sectionIndex = tonumber(remainingContent)
    
    if not timestamp or not sectionIndex then
        self:Debug("sync", "Invalid section request: missing timestamp or section index")
        return
    end
    
    self:Debug("sync", "Received request for section " .. sectionIndex .. " with timestamp " .. timestamp .. " from " .. sender)
    
    -- Get our current timestamp
    local localTimestamp = 0
    if TWRA_Assignments and TWRA_Assignments.timestamp then
        localTimestamp = TWRA_Assignments.timestamp or 0
    end
    
    -- Only respond if we have matching data
    if localTimestamp == timestamp then
        -- IMPORTANT: Check if we actually have the section data before promising to send it
        local haveSectionData = false
        if TWRA_CompressedAssignments and 
           TWRA_CompressedAssignments.sections and 
           TWRA_CompressedAssignments.sections[sectionIndex] and 
           TWRA_CompressedAssignments.sections[sectionIndex] ~= "" then
            haveSectionData = true
        end
        
        if haveSectionData then
            -- Queue the section response with the request collapse system
            self:Debug("sync", "We have section " .. sectionIndex .. " data, queueing response")
            self:QueueSectionResponse(sectionIndex, timestamp, sender)
        else
            self:Debug("sync", "Cannot respond to section request - we don't have data for section " .. sectionIndex)
            -- Optionally notify the sender that we don't have the data they're requesting
        end
    elseif localTimestamp > timestamp then
        -- We have newer data, send our structure instead
        self:Debug("sync", "We have newer data than requested, sending structure response")
        if self.SendStructureResponse then
            self:SendStructureResponse(localTimestamp)
        end
    else
        self:Debug("sync", "Cannot respond to section request - our timestamp is older (ours: " .. 
                  localTimestamp .. ", requested: " .. timestamp .. ")")
        
        -- We should request their structure since they have newer data
        if self.RequestStructureSync then
            self:RequestStructureSync(timestamp)
        end
    end
end

-- Handle section response commands (SECRES)
function TWRA:HandleSectionResponseCommand(message, sender)
    self:Debug("sync", "Received section response from " .. sender)
    
    -- Extract timestamp and remaining content from the message
    local timestamp, remainingContent = self:ExtractTimestampFromMessage(message)
    if not timestamp or not remainingContent then
        self:Debug("sync", "Malformed section response: missing timestamp")
        return
    end
    
    -- Extract section index and section data
    local colonPos = string.find(remainingContent, ":", 1, true)
    if not colonPos then
        self:Debug("sync", "Malformed section response: missing section index separator")
        return
    end
    
    local sectionIndex = tonumber(string.sub(remainingContent, 1, colonPos - 1))
    local sectionData = string.sub(remainingContent, colonPos + 1)
    
    if not sectionIndex or not sectionData or sectionData == "" then
        self:Debug("sync", "Invalid section response: missing section index or data")
        return
    end
    
    -- Compare with our cached structure timestamp
    local cachedTimestamp = TWRA_Assignments.timestamp
    if not cachedTimestamp or cachedTimestamp ~= timestamp then
        self:Debug("sync", "Ignoring section response - timestamp mismatch (ours: " .. 
                  (cachedTimestamp or "nil") .. ", received: " .. timestamp .. ")")
        return
    end
    
    -- Initialize TWRA_CompressedAssignments and sections table if needed
    TWRA_CompressedAssignments = TWRA_CompressedAssignments or {}
    TWRA_CompressedAssignments.sections = TWRA_CompressedAssignments.sections or {}
    TWRA_CompressedAssignments.timestamp = timestamp
    
    -- Ensure the compressed data has the marker
    if string.byte(sectionData, 1) ~= 241 then
        sectionData = "\241" .. sectionData
    end
    
    -- Simply store the compressed section data
    TWRA_CompressedAssignments.sections[sectionIndex] = sectionData
    self:Debug("sync", "Stored compressed data for section " .. sectionIndex)
    
    -- Process the section data
    if self:ProcessSectionData(sectionIndex, sectionData, timestamp, sender) then
        -- If we have a pending section that we were waiting to navigate to,
        -- and we just received its data, navigate to it now
        if self.SYNC.pendingSection then
            self:Debug("sync", "Navigating to pending section " .. sectionIndex .. " that we have its data")
            self:NavigateToSection(sectionIndex, self.SYNC.pendingSource)
            self.SYNC.pendingSection = nil
        end
    end
end

-- Queue a structure response with proper coordination
function TWRA:QueueStructureResponse(timestamp, sender)
    -- Check if we're already handling a structure response
    self.SYNC = self.SYNC or {}
    
    -- Track when we last sent a structure response to avoid flooding
    local now = GetTime()
    if self.SYNC.lastStructureResponseTime and (now - self.SYNC.lastStructureResponseTime < 2) then
        self:Debug("sync", "Skipping structure response - sent one recently")
        return false
    end
    
    -- If we already have a pending timer for structure response, cancel it
    if self.SYNC.structureResponseTimer then
        self:CancelTimer(self.SYNC.structureResponseTimer)
        self.SYNC.structureResponseTimer = nil
        self:Debug("sync", "Canceled previous structure response timer")
    end
    
    -- Calculate a small random delay (100-400ms) to avoid everyone responding at once
    local delay = 0.1 + (math.random() * 0.3)
    
    self:Debug("sync", "Queueing structure response with delay: " .. delay)
    
    -- Schedule the response after a short delay
    self.SYNC.structureResponseTimer = self:ScheduleTimer(function()
        -- Mark that we're preparing a response - one time only
        self:Debug("sync", "Preparing structure response message")
        
        -- Double-check we still have data to send
        if not TWRA_CompressedAssignments or not TWRA_CompressedAssignments.structure then
            self:Debug("sync", "No structure data available when timer fired")
            return
        end
        
        -- Get the structure data
        local structureData = TWRA_CompressedAssignments.structure
        
        -- Clear the timer reference
        self.SYNC.structureResponseTimer = nil
        
        -- Track when we sent this response
        self.SYNC.lastStructureResponseTime = GetTime()
        
        -- Prepare the response message - SRES:timestamp:structureData
        local message = "SRES:" .. timestamp .. ":" .. structureData
        
        -- Use SendAddonMessage directly to ensure the message is sent
        SendAddonMessage("TWRA", message, "RAID")
        
        self:Debug("sync", "Structure response sent successfully with timestamp " .. timestamp)
    end, delay)
    
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
    
    -- Explicitly clear existing sections to avoid stale data
    TWRA_CompressedAssignments.sections = nil
    
    -- Update timestamp and structure data
    TWRA_CompressedAssignments.timestamp = timestamp
    TWRA_CompressedAssignments.structure = structureData

    -- Now initialize empty sections table
    TWRA_CompressedAssignments.sections = {}
    
    -- Create empty placeholders for each section (we'll fill them later)
    for index, sectionName in pairs(decodedStructure) do
        if type(index) == "number" then
            TWRA_CompressedAssignments.sections[index] = ""
            self:Debug("sync", "Created empty section placeholder for section " .. index)
        end
    end

    self:Debug("sync", "Updated TWRA_CompressedAssignments with timestamp " .. timestamp .. " and " .. 
              self:GetTableSize(TWRA_CompressedAssignments.sections) .. " empty section placeholders")
    
    -- Store the timestamp for section requests
    self.SYNC = self.SYNC or {}
    self.SYNC.cachedTimestamp = timestamp
    
    -- Clear existing data structures to prepare for new structure
    if self.ClearDataForStructureResponse then
        self:ClearDataForStructureResponse()
    end
    
    -- IMPORTANT: Use BuildSkeletonFromStructure instead of manually creating sections
    if self.BuildSkeletonFromStructure then
        self:Debug("sync", "Using BuildSkeletonFromStructure to create section skeletons")
        self:BuildSkeletonFromStructure(decodedStructure, timestamp)
    else
        -- Fallback to manual creation if the function is not available
        self:Debug("error", "BuildSkeletonFromStructure not available, falling back to manual skeleton creation")
        
        -- IMPORTANT: Create or update TWRA_Assignments with proper initialization
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
    
    -- Log the actual saved sections to verify
    self:Debug("sync", "TWRA_Assignments.data now contains " .. self:GetTableSize(TWRA_Assignments.data) .. " sections")
    for idx, section in pairs(TWRA_Assignments.data) do
        if type(section) == "table" and section["Section Name"] then
            self:Debug("sync", "Saved section " .. idx .. ": " .. section["Section Name"])
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

-- Helper function to request all sections after receiving a structure oh no this is definitly something we want to be default.
function TWRA:RequestSectionsAfterStructure(decodedStructure, timestamp)
    -- Calculate the total number of sections to request
    local sectionCount = 0
    for index, _ in pairs(decodedStructure) do
        if type(index) == "number" then
            sectionCount = sectionCount + 1
        end
    end
    
    self:Debug("sync", "Requesting " .. sectionCount .. " sections after structure sync")
    
    -- Request each section with staggered timing
    local requestDelay = 0
    for index, _ in pairs(decodedStructure) do
        if type(index) == "number" then
            -- Schedule each request with increasing delay to prevent network flooding
            self:ScheduleTimer(function()
                -- Check if we've already received this section from someone else
                if not self.SYNC.receivedSectionResponses or not self.SYNC.receivedSectionResponses[index] then
                    if self.RequestSectionSync then
                        self:Debug("sync", "Requesting section " .. index .. " with timestamp " .. timestamp)
                        self:RequestSectionSync(index, timestamp)
                    end
                else
                    self:Debug("sync", "Skipping request for section " .. index .. " - already received")
                end
            end, requestDelay)
            
            requestDelay = requestDelay + 0.2 -- 200ms between requests
        end
    end
end

-- Process section data received from another player
function TWRA:ProcessSectionData(sectionIndex, sectionData, timestamp, sender)
    self:Debug("sync", "Processing section " .. sectionIndex .. " data from " .. (sender or "local"))
    
    -- Store in compressed format
    if not TWRA_CompressedAssignments then
        TWRA_CompressedAssignments = {}
    end
    
    if not TWRA_CompressedAssignments.sections then
        TWRA_CompressedAssignments.sections = {}
    end
    
    -- Store timestamp with compressed data
    TWRA_CompressedAssignments.timestamp = timestamp
    
    -- Store the compressed section data
    TWRA_CompressedAssignments.sections[sectionIndex] = sectionData
    
    -- Track that we've received this section
    self.SYNC.receivedSections = self.SYNC.receivedSections or {}
    self.SYNC.receivedSections[sectionIndex] = true
    
    -- Track others' responses to avoid duplicate responses
    self.SYNC.receivedSectionResponses = self.SYNC.receivedSectionResponses or {}
    self.SYNC.receivedSectionResponses[sectionIndex] = true
    
    -- Cancel our response if pending
    if self.SYNC.pendingSectionResponses and self.SYNC.pendingSectionResponses[sectionIndex] then
        self.SYNC.pendingSectionResponses[sectionIndex] = nil
        self:Debug("sync", "Cancelled pending section response for " .. sectionIndex)
    end
    
    -- If we have a pending section that we just received, we should now navigate to it
    if self.SYNC.pendingSection and tonumber(self.SYNC.pendingSection) == tonumber(sectionIndex) then
        self:Debug("sync", "Received data for pending section " .. sectionIndex .. ", proceeding with navigation")
        
        -- Get the section name if we can
        local sectionName = nil
        if TWRA_Assignments and TWRA_Assignments.data then
            for _, section in pairs(TWRA_Assignments.data) do
                if type(section) == "table" and section["Section Index"] == sectionIndex then
                    sectionName = section["Section Name"]
                    break
                end
            end
        end
        
        -- Find section name from structure if needed
        if not sectionName and self.SYNC.structure then
            sectionName = self.SYNC.structure[sectionIndex]
            self:Debug("sync", "Found section name in structure: " .. (sectionName or "nil"))
        end
        
        -- Create a placeholder in TWRA_Assignments.data if it doesn't exist
        if sectionName then
            -- Check if we already have this section
            local sectionExists = false
            if TWRA_Assignments and TWRA_Assignments.data then
                for _, section in pairs(TWRA_Assignments.data) do
                    if type(section) == "table" and section["Section Name"] == sectionName then
                        sectionExists = true
                        
                        -- Mark that it needs processing
                        section["NeedsProcessing"] = true
                        break
                    end
                end
            end
            
            -- If section doesn't exist, create a placeholder
            if not sectionExists then
                TWRA_Assignments = TWRA_Assignments or {}
                TWRA_Assignments.data = TWRA_Assignments.data or {}
                
                -- Add skeleton section with needed metadata
                TWRA_Assignments.data[sectionIndex] = {
                    ["Section Name"] = sectionName,
                    ["Section Index"] = sectionIndex,
                    ["NeedsProcessing"] = true,
                    ["Section Metadata"] = {
                        ["Note"] = {},
                        ["Warning"] = {},
                        ["GUID"] = {}
                    }
                }
                self:Debug("sync", "Created placeholder for section: " .. sectionName)
            end
            
            -- Now we can navigate to this section
            if self.NavigateToSection then
                -- Use navigation by index, which will now handle the processing
                self:NavigateToSection(sectionIndex, self.SYNC.pendingSource or "fromSync")
                
                -- Clear pending section after navigation
                self.SYNC.pendingSection = nil
                self.SYNC.pendingSource = nil
            else
                self:Debug("error", "NavigateToSection function not available")
            end
        else
            self:Debug("error", "Could not find section name for index " .. sectionIndex)
            -- We'll still return success, just won't navigate
        end
    end
    
    return true
end

-- Function to process all compressed sections at once
function TWRA:ProcessAllCompressedSections()
    self:Debug("sync", "Processing all compressed sections")
    
    if not TWRA_CompressedAssignments or not TWRA_CompressedAssignments.sections then
        self:Debug("error", "No compressed sections to process")
        return
    end
    
    local startTime = GetTime()
    local sectionCount = 0
    
    -- First pass: Count sections for progress tracking
    for sectionIndex, sectionData in pairs(TWRA_CompressedAssignments.sections) do
        if type(sectionIndex) == "number" and sectionData then
            sectionCount = sectionCount + 1
        end
    end
    
    self:Debug("sync", "Found " .. sectionCount .. " sections to process")
    
    -- Second pass: Process all sections
    local processedCount = 0
    for sectionIndex, sectionData in pairs(TWRA_CompressedAssignments.sections) do
        if type(sectionIndex) == "number" and sectionData then
            -- Process this section's data
            if self:ProcessCompressedSection(sectionIndex, sectionData, false, true) then
                processedCount = processedCount + 1
                
                -- Log progress periodically
                local modResult = processedCount - (math.floor(processedCount / 5) * 5)
                if modResult == 0 or processedCount == sectionCount then
                    local percent = math.floor((processedCount / sectionCount) * 100)
                    self:Debug("sync", "Processing progress: " .. processedCount .. "/" .. sectionCount .. " (" .. percent .. "%)")
                end
            else
                self:Debug("error", "Failed to process section " .. sectionIndex)
            end
        end
    end
    
    local processingTime = GetTime() - startTime
    self:Debug("sync", "Processed " .. processedCount .. "/" .. sectionCount .. " sections in " .. processingTime .. " seconds")
    
    -- Perform any additional data processing
    self:ExtractPlayerRelevantData()
    
    -- Update the UI
    self:ScheduleTimer(function()
        -- Get the current section from TWRA_Assignments
        local currentSection = TWRA_Assignments and TWRA_Assignments.currentSection or 1
        
        -- Navigate to the current section
        self:NavigateToSection(currentSection, "bulkSync")
        
        -- Refresh UI elements
        if self.RefreshAssignmentTable then
            self:RefreshAssignmentTable()
        end
        
        if self.RebuildOSDIfVisible then
            self:RebuildOSDIfVisible()
        end
    end, 0.2)
end

-- Process compressed data into usable format
function TWRA:ProcessCompressedData()
    if not TWRA_CompressedAssignments then
        self:Debug("error", "No compressed data to process")
        return false
    end
    
    if not TWRA_CompressedAssignments.structure or not TWRA_CompressedAssignments.sections then
        self:Debug("error", "Incomplete compressed data - missing structure or sections")
        return false
    end
    
    self:Debug("sync", "Processing compressed data...")
    
    -- Here we would decompress the data in future implementation
    -- For now, just indicate that we processed it
    
    -- Update the UI with the new data
    if TWRA.RefreshAssignmentTable then
        TWRA:RefreshAssignmentTable()
    end
    
    -- Update OSD if it's open
    if TWRA.UpdateOSDContent then
        TWRA:UpdateOSDContent()
    end
    
    return true
end

-- Add initialization of the chunk manager at addon load
function TWRA:InitializeSyncHandlers()
    -- Initialize the handler map
    self:InitializeHandlerMap()
    
    -- Initialize the chunk manager if needed
    if not self.chunkManager and self.InitChunkManager then
        self:InitChunkManager()
    end
    
    -- Set up a cleanup timer for any partial transfers
    self:ScheduleRepeatingTimer(function()
        -- Clean up any partial transfers older than 30 seconds
        local now = GetTime()
        local count = 0
        
        -- Make sure chunkedData exists
        if self.SYNC.chunkedData then
            for id, transfer in pairs(self.SYNC.chunkedData) do
                -- Check if transfer has timed out (30 second timeout)
                if (now - (transfer.startTime or 0)) > 30 then
                    self:Debug("sync", "Removing stale transfer: " .. id)
                    self.SYNC.chunkedData[id] = nil
                    count = count + 1
                end
            end
            
            if count > 0 then
                self:Debug("sync", "Cleaned up " .. count .. " stale transfers")
            end
        end
    end, 60) -- Check every 60 seconds
    
    -- Initialize segmented sync flag based on compressed storage availability
    self.SYNC.useSegmentedSync = (self.StoreSegmentedData ~= nil and self.GetCompressedSection ~= nil)
    self:Debug("sync", "Segmented sync " .. (self.SYNC.useSegmentedSync and "enabled" or "disabled"))
    
    self:Debug("sync", "Sync handlers initialized")
    return true
end

