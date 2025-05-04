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
            self:HandleStructureResponseCommand(components[2], self:ExtractDataPortion(message, 3), sender)
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
function TWRA:HandleSectionCommand(timestamp, sectionIndex, sender)
    -- Validate input parameters
    if not timestamp or not sectionIndex then
        self:Debug("sync", "Received invalid section command parameters from " .. sender)
        return false
    end
    
    self:Debug("sync", "Handling section command: timestamp=" .. timestamp .. ", section=" .. sectionIndex)
    
    -- Convert timestamp to number
    timestamp = tonumber(timestamp)
    sectionIndex = tonumber(sectionIndex)
    
    if not timestamp or not sectionIndex then
        self:Debug("sync", "Invalid timestamp or section index format in command from " .. sender)
        return false
    end
    
    -- Compare timestamps to ensure data is synchronized
    local timestampComparison = self:CheckTimestampAndHandleResponse(timestamp, sender)
    
    -- Store the section index before timestamp comparison
    self.SYNC.pendingSection = sectionIndex
    
    -- Compare timestamps - simplified comparison for now
    if timestampComparison == 0 then
        -- Our timestamp is equal - navigate to the section
        self:NavigateToSection(sectionIndex, "fromSync")  -- suppressSync=true
        self:Debug("sync", "Navigated to section " .. sectionIndex .. " from sync command by " .. sender)
    else 
        -- timestamp mismatch. CheckTimestampAndHandleResponse should already be trying to get us on the same timestamp
        self:Debug("sync", "Timestamp mismatch, not navigating.")
    end
    
    return true
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
    
    -- Store the compressed section data
    TWRA_CompressedAssignments.sections[sectionIndex] = sectionData
    self:Debug("sync", "Stored compressed data for section " .. sectionIndex)
    
    -- Track that we've received this section
    self.SYNC = self.SYNC or {}
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
    
    -- IMPROVED: Create or ensure the section placeholder exists with NeedsProcessing flag explicitly set
    self:CreateSectionPlaceholder(sectionIndex, timestamp)
    
    -- FIXED: Ensure the section is explicitly marked as needing processing in all relevant places
    if TWRA_Assignments and TWRA_Assignments.data and TWRA_Assignments.data[sectionIndex] then
        -- Double-check that NeedsProcessing is definitely set to true
        TWRA_Assignments.data[sectionIndex]["NeedsProcessing"] = true
        self:Debug("sync", "Explicitly marked section " .. sectionIndex .. " as needing processing after receiving data")
    end
    
    -- IMPROVED: Hide the waiting for data message in UI if this is our current section
    if self.mainFrame and self.mainFrame.processingWarningElements and 
       self.navigation and self.navigation.currentIndex == sectionIndex then
        
        -- Hide the waiting message if visible
        if self.mainFrame.processingWarningElements.infoText and 
           self.mainFrame.processingWarningElements.infoText:IsShown() then
            self.mainFrame.processingWarningElements.infoText:Hide()
            self:Debug("sync", "Hiding 'Waiting for data' message after receiving section data")
        end
        
        -- Force a refresh of the main UI to show that we're now processing the data
        if self.RefreshAssignmentTable then
            self:ScheduleTimer(function()
                self:RefreshAssignmentTable()
            end, 0.1) -- Small delay to ensure data is ready
        end
    end
    
    -- NEW: Try to process the section immediately if not in a pending operation
    -- This ensures the section is processed as soon as possible rather than waiting for navigation
    if not self.SYNC.pendingSection or tonumber(self.SYNC.pendingSection) ~= tonumber(sectionIndex) then
        -- Process the section in the background with a small delay to avoid UI freezing
        self:ScheduleTimer(function()
            if self:ProcessSectionData(sectionIndex) then
                self:Debug("sync", "Successfully processed section " .. sectionIndex .. " immediately after receiving")
                
                -- Refresh the UI if this is our current section
                if self.navigation and self.navigation.currentIndex == sectionIndex then
                    if self.RefreshAssignmentTable then
                        self:RefreshAssignmentTable()
                    end
                end
            else
                self:Debug("error", "Failed to process section " .. sectionIndex .. " immediately")
            end
        end, 0.2)
    end
    
    -- If we have a pending section that we were waiting to navigate to,
    -- and we just received its data, navigate to it now
    if self.SYNC.pendingSection and tonumber(self.SYNC.pendingSection) == tonumber(sectionIndex) then
        self:Debug("sync", "Received data for pending section " .. sectionIndex .. ", proceeding with navigation")
        
        -- Now we can navigate to this section - it will be processed on demand
        if self.NavigateToSection then
            -- Add a small delay to ensure the section data is ready
            self:ScheduleTimer(function()
                self:NavigateToSection(sectionIndex, self.SYNC.pendingSource or "fromSync")
                
                -- Clear pending section after navigation
                self.SYNC.pendingSection = nil
                self.SYNC.pendingSource = nil
            end, 0.3)
        else
            self:Debug("error", "NavigateToSection function not available")
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

-- Helper function to create or update a section placeholder
function TWRA:CreateSectionPlaceholder(sectionIndex, timestamp)
    -- We need to find the section name from our existing structure
    local sectionName = nil
    
    -- First try to get the section name from TWRA_Assignments if it exists
    if TWRA_Assignments and TWRA_Assignments.data then
        for idx, section in pairs(TWRA_Assignments.data) do
            if idx == sectionIndex or (section["Section Index"] and section["Section Index"] == sectionIndex) then
                sectionName = section["Section Name"]
                break
            end
        end
    end
    
    -- If we couldn't find the section name in TWRA_Assignments, try to decode the structure
    if not sectionName and TWRA_CompressedAssignments and TWRA_CompressedAssignments.structure then
        local success, decodedStructure = pcall(function()
            return self:DecompressStructureData(TWRA_CompressedAssignments.structure)
        end)
        
        if success and decodedStructure and decodedStructure[sectionIndex] then
            sectionName = decodedStructure[sectionIndex]
        end
    end
    
    -- If we still don't have a section name, we can't create a placeholder
    if not sectionName then
        self:Debug("error", "Cannot create section placeholder - no name found for section " .. sectionIndex)
        return false
    end
    
    -- Ensure TWRA_Assignments exists and has a data table
    TWRA_Assignments = TWRA_Assignments or {}
    TWRA_Assignments.data = TWRA_Assignments.data or {}
    
    -- Create or update the section placeholder
    local placeholderExists = false
    for idx, section in pairs(TWRA_Assignments.data) do
        if (idx == sectionIndex or (section["Section Index"] and section["Section Index"] == sectionIndex)) and 
           section["Section Name"] == sectionName then
            -- Update the existing placeholder
            section["NeedsProcessing"] = true
            placeholderExists = true
            self:Debug("sync", "Updated placeholder for section " .. sectionName)
            break
        end
    end
    
    -- If the placeholder doesn't exist, create it
    if not placeholderExists then
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
    
    return true
end

