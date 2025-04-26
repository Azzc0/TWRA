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

function TWRA:CompareTimestamps(remoteTimestamp)
    -- Get our current timestamp from assignments
    local localTimestamp = 0
    if TWRA_Assignments and TWRA_Assignments.timestamp then
        localTimestamp = tonumber(TWRA_Assignments.timestamp) or 0
    end
    
    -- Handle nil/invalid values for remote timestamp
    remoteTimestamp = tonumber(remoteTimestamp) or 0
    
    -- Debug the comparison
    self:Debug("sync", "CompareTimestamps - Local: " .. localTimestamp .. ", Remote: " .. remoteTimestamp)
    
    -- Compare timestamps and take action
    if localTimestamp > remoteTimestamp then
        -- Our data is newer - log but don't act
        self:Debug("sync", "Our data is NEWER")
        
        -- If we're asked to respond with our newer structure, do so
        if sender then
            self:Debug("sync", "Sending our newer structure data to " .. sender)
            self:RespondWithStructure(sender)
        end
        
        return -1 -- Caller should not proceed with normal flow
        
    elseif localTimestamp < remoteTimestamp then
        -- Remote data is newer - request structure
        self:Debug("sync", "Remote data from  is NEWER")
        
        if self.RequestStructureSync then
            -- Request the structure and handle the response
            self:Debug("sync", "Requesting newer structure data (timestamp: " .. remoteTimestamp .. ")")
            self:RequestStructureSync(remoteTimestamp)
            
            -- Set a timeout for waiting for the response
            self.SYNC.structureRequestTimeout = self:ScheduleTimer(function()
                self:Debug("sync", "Structure request timeout - no response received within 1 second")
                -- Could implement fallback behavior here
            end, 1.0)
            
            return 1 -- Caller should not proceed with normal flow
        end
    else
        -- Timestamps are equal - proceed normally
        self:Debug("sync", "Timestamps are EQUAL")
        return 0 -- Caller should proceed with normal flow
    end
end

-- Send our structure data in response to a section change when we have newer data
function TWRA:AnnounceStructure(recipient)
    -- Temporary stub function - to be implemented fully
    self:Debug("sync", "RespondWithStructure called for " .. recipient)
    
    -- If we have structure compression functionality
    if self.GetCompressedStructure then
        -- Get our structure data
        local structureData = self:GetCompressedStructure()
        if structureData then
            -- Send structure response
            self:Debug("sync", "Sending structure response with our newer data")
            -- This would use the full implementation of SendStructureResponse
            -- For now we'll just log that we would respond
            self:Debug("sync", "STUB: Would send SRESP message with structure data")
        else
            self:Debug("sync", "Failed to get compressed structure data")
        end
    else
        self:Debug("sync", "GetCompressedStructure not available - cannot respond with structure")
    end
end

-- Handle a section change command received from another player
function TWRA:HandleSectionCommand(message, sender)
    if not message or type(message) ~= "string" then
        self:Debug("sync", "Received invalid section command from " .. sender)
        return false
    end
    
    -- The message format is "timestamp:sectionIndex" 
    -- Parse the timestamp and sectionIndex directly from the message
    local parts = self:SplitString(message, ":")
    if not parts or table.getn(parts) ~= 2 then
        self:Debug("sync", "Malformed section command from " .. sender .. ": " .. message)
        return false
    end
    
    -- Extract parts
    local timestampComparison = self:CompareTimestamps(parts[1])
    local sectionIndex = tonumber(parts[2])
    
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
        self:NavigateToSection(sectionIndex, fromSync)  -- suppressSync=true
        self:Debug("sync", "Navigated to section " .. sectionIndex .. " from sync command by " .. sender)
    else 
        -- timestamp mismatch. CompareTimestamp should already be trying to get us on the same timestamp
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
    
    -- Get our current timestamp
    local ourTimestamp = TWRA_Assignments and TWRA_Assignments.timestamp or 0
    
    -- Compare timestamps
    local comparison = self:CompareTimestamps(ourTimestamp, timestamp)
    
    if comparison < 0 then
        -- Their timestamp is newer - request their structure data
        self:Debug("sync", "Requesting structure data from " .. sender .. " - they have newer data")
        self:RequestStructureSync(timestamp)
        return true
    else
        -- Our data is newer or the same - ignore
        self:Debug("sync", "Ignoring announce command from " .. sender .. " - we have same or newer data")
        return true
    end
end

function TWRA:UnusedCommand()    -- Placeholder for unused command
    self:Debug("sync", "Unused command handler called")
end

-- Handle structure request commands (SREQ)
function TWRA:HandleStructureRequestCommand(message, sender)
    -- Extract timestamp from the message
    local timestamp = tonumber(message)
    if not timestamp then
        self:Debug("sync", "Malformed structure request from " .. sender .. ": Invalid timestamp format")
        return
    end
    
    self:Debug("sync", "Received structure request from " .. sender .. " with timestamp: " .. timestamp)
    
    -- Get our current timestamp
    local localTimestamp = 0
    if TWRA_Assignments and TWRA_Assignments.timestamp then
        localTimestamp = tonumber(TWRA_Assignments.timestamp) or 0
    end
    
    -- Only respond if we have a valid timestamp and it matches or is newer than the requested one
    if localTimestamp > 0 and localTimestamp >= timestamp then
        self:Debug("sync", "We have matching or newer data (timestamp " .. localTimestamp .. "), preparing structure response")
        
        -- Use the request collapse system to prevent flooding
        -- We'll queue this request and potentially handle it after a short delay
        self:QueueStructureResponse(timestamp, sender)
    else
        self:Debug("sync", "We don't have matching or newer data (our timestamp: " .. localTimestamp .. ")")
    end
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
        localTimestamp = tonumber(TWRA_Assignments.timestamp) or 0
    end
    
    -- Only respond if we have matching data
    if localTimestamp == timestamp then
        -- Queue the section response with the request collapse system
        self:QueueSectionResponse(sectionIndex, timestamp, sender)
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
    local cachedTimestamp = self.SYNC.cachedTimestamp
    if not cachedTimestamp or cachedTimestamp ~= timestamp then
        self:Debug("sync", "Ignoring section response - timestamp mismatch (ours: " .. 
                  (cachedTimestamp or "nil") .. ", received: " .. timestamp .. ")")
        return
    end
    
    -- Process the section data
    if self:ProcessSectionData(sectionIndex, sectionData, timestamp, sender) then
        -- If we have a pending section that we were waiting to navigate to,
        -- and we just received its data, navigate to it now
        if self.SYNC.pendingSection and self.SYNC.pendingSection == sectionIndex then
            self:Debug("sync", "Navigating to pending section " .. sectionIndex .. " now that we have its data")
            self:NavigateToSection(sectionIndex, "fromSync")
            self.SYNC.pendingSection = nil
        end
    end
end

-- Request collapse system
function TWRA:QueueStructureResponse(timestamp, requestingPlayer)
    -- Check if we already have a pending response timer
    if self.SYNC.pendingStructureResponse then
        self:Debug("sync", "Already have a pending structure response, adding requester to list")
        
        -- Add this requester to the list
        self.SYNC.structureRequesters = self.SYNC.structureRequesters or {}
        self.SYNC.structureRequesters[requestingPlayer] = true
        return
    end
    
    -- Calculate a random delay between 0.1 and 0.5 seconds to prevent response flooding
    local responseDelay = 0.1 + (math.random() * 0.4)
    self:Debug("sync", "Queueing structure response with delay of " .. responseDelay .. " seconds")
    
    -- Set up the delay timer
    self.SYNC.structureRequesters = self.SYNC.structureRequesters or {}
    self.SYNC.structureRequesters[requestingPlayer] = true
    
    self.SYNC.pendingStructureResponse = self:ScheduleTimer(function()
        -- Check if we've received a SRES from someone else during our wait
        if self.SYNC.receivedStructureResponseForTimestamp == timestamp then
            self:Debug("sync", "Someone else already sent a structure response, canceling ours")
        else
            -- Send our structure response - we use our own timestamp, not the requested one
            -- as our data might be newer
            local ourTimestamp = TWRA_Assignments and TWRA_Assignments.timestamp or 0
            
            -- Use the structured SendStructureResponse from Sync.lua
            if self.SendStructureResponse then
                self:Debug("sync", "Sending structure response with timestamp " .. ourTimestamp)
                self:SendStructureResponse(ourTimestamp)
            else
                self:Debug("sync", "SendStructureResponse function not available")
            end
        end
        
        -- Clear state
        self.SYNC.pendingStructureResponse = nil
        self.SYNC.structureRequesters = nil
    end, responseDelay)
end

-- Queue section response with collapse system
function TWRA:QueueSectionResponse(sectionIndex, timestamp, requestingPlayer)
    -- Check if we already have a pending response for this section
    if self.SYNC.pendingSectionResponses and self.SYNC.pendingSectionResponses[sectionIndex] then
        self:Debug("sync", "Already have a pending response for section " .. sectionIndex .. ", adding requester to list")
        
        -- Add this requester to the list
        self.SYNC.sectionRequesters = self.SYNC.sectionRequesters or {}
        self.SYNC.sectionRequesters[sectionIndex] = self.SYNC.sectionRequesters[sectionIndex] or {}
        self.SYNC.sectionRequesters[sectionIndex][requestingPlayer] = true
        return
    end
    
    -- Calculate a random delay between 0.1 and 0.5 seconds
    local responseDelay = 0.1 + (math.random() * 0.4)
    self:Debug("sync", "Queueing section " .. sectionIndex .. " response with delay of " .. responseDelay .. " seconds")
    
    -- Initialize section requesters tracking
    self.SYNC.sectionRequesters = self.SYNC.sectionRequesters or {}
    self.SYNC.sectionRequesters[sectionIndex] = self.SYNC.sectionRequesters[sectionIndex] or {}
    self.SYNC.sectionRequesters[sectionIndex][requestingPlayer] = true
    
    -- Initialize pending section responses tracking
    self.SYNC.pendingSectionResponses = self.SYNC.pendingSectionResponses or {}
    
    -- Set up the delay timer
    self.SYNC.pendingSectionResponses[sectionIndex] = self:ScheduleTimer(function()
        -- Check if we've received a section response from someone else during our wait
        if self.SYNC.receivedSectionResponses and self.SYNC.receivedSectionResponses[sectionIndex] then
            self:Debug("sync", "Someone else already sent section " .. sectionIndex .. ", canceling ours")
        else
            -- Send our response using the SendSectionResponse from Sync.lua
            if self.SendSectionResponse then
                self:Debug("sync", "Sending response for section " .. sectionIndex .. " with timestamp " .. timestamp)
                self:SendSectionResponse(sectionIndex, timestamp)
            else
                self:Debug("sync", "SendSectionResponse function not available")
            end
        end
        
        -- Clear state for this section
        if self.SYNC.pendingSectionResponses then
            self.SYNC.pendingSectionResponses[sectionIndex] = nil
        end
        
        if self.SYNC.sectionRequesters and self.SYNC.sectionRequesters[sectionIndex] then
            self.SYNC.sectionRequesters[sectionIndex] = nil
        end
    end, responseDelay)
end

-- Process structure data received from another player
function TWRA:ProcessStructureData(structureData, timestamp, sender)
    self:Debug("sync", "Processing structure data from " .. sender .. " with timestamp " .. timestamp)
    
    -- Store the compressed structure data
    if not TWRA_CompressedAssignments then
        TWRA_CompressedAssignments = {}
    end
    
    -- Update our structure data
    TWRA_CompressedAssignments.timestamp = timestamp
    TWRA_CompressedAssignments.structure = structureData
    
    -- Store the timestamp for section requests
    self.SYNC.cachedTimestamp = timestamp
    
    -- Attempt to decode the structure to get section information
    local success = false
    
    if self.DecompressStructureData then
        local decodedStructure = self:DecompressStructureData(structureData)
        
        if decodedStructure and type(decodedStructure) == "table" then
            -- Create skeleton TWRA_Assignments structure with placeholders for sections
            if not TWRA_Assignments then
                TWRA_Assignments = {}
            end
            
            -- Update our timestamp
            TWRA_Assignments.timestamp = timestamp
            
            -- Clear existing sections if any
            TWRA_Assignments.data = {}
            
            -- Create skeleton sections
            for index, sectionName in pairs(decodedStructure) do
                if type(index) == "number" and type(sectionName) == "string" then
                    -- Add skeleton section entry
                    TWRA_Assignments.data[index] = {
                        ["Section name"] = sectionName
                    }
                end
            end
            
            -- Store the structure table for section validation
            self.SYNC.structureTable = decodedStructure
            
            -- Rebuild navigation with the skeleton
            if self.RebuildNavigation then
                self:RebuildNavigation()
                success = true
                
                -- Show a message to the user
                DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA:|r Received structure from " .. sender .. 
                    ", requesting " .. table.getn(decodedStructure) .. " sections...")
            else
                self:Debug("error", "RebuildNavigation function not available")
            end
            
            -- Request all sections with staggered timing
            self:RequestAllSectionsWithDelay(timestamp, decodedStructure)
        else
            self:Debug("error", "Failed to decode structure data")
        end
    else
        self:Debug("error", "DecompressStructureData function not available")
    end
    
    if not success then
        -- Fall back to legacy sync if structure processing failed
        self:Debug("sync", "Structure processing failed, falling back to legacy sync")
        if self.RequestDataSync then
            self:RequestDataSync(timestamp)
        end
    end
    
    return success
end

-- Request all sections with staggered timing
function TWRA:RequestAllSectionsWithDelay(timestamp, structureTable)
    -- Track which sections we've received
    self.SYNC.receivedSections = {}
    self.SYNC.totalSections = table.getn(structureTable)
    
    -- Request sections with increasing delay
    local requestDelay = 0
    for index, _ in pairs(structureTable) do
        if type(index) == "number" then
            -- Add increasing delay for each section request to prevent flooding
            self:ScheduleTimer(function()
                if not self.SYNC.receivedSections or not self.SYNC.receivedSections[index] then
                    if self.RequestSectionSync then
                        self:RequestSectionSync(index, timestamp)
                    else
                        self:Debug("sync", "RequestSectionSync function not available")
                    end
                end
            end, requestDelay)
            requestDelay = requestDelay + 0.2 -- 200ms between requests
        end
    end
    
    -- Set up a timeout to detect incomplete syncs
    self:ScheduleTimer(function()
        if not self.SYNC.receivedSections then return end
        
        local received = self:GetTableSize(self.SYNC.receivedSections)
        if received < self.SYNC.totalSections then
            self:Debug("sync", "Sync incomplete: received " .. received .. " of " .. self.SYNC.totalSections .. " sections")
            DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA:|r Sync incomplete! Received " .. 
                received .. " of " .. self.SYNC.totalSections .. " sections. Try '/twra sync' to retry.")
        end
    end, 15) -- 15 second timeout
end

-- Process section data received from another player
function TWRA:ProcessSectionData(sectionIndex, sectionData, timestamp, sender)
    self:Debug("sync", "Processing section " .. sectionIndex .. " data from " .. sender)
    
    -- Store in compressed format
    if not TWRA_CompressedAssignments then
        TWRA_CompressedAssignments = {}
    end
    
    if not TWRA_CompressedAssignments.data then
        TWRA_CompressedAssignments.data = {}
    end
    
    -- Store the compressed section data
    TWRA_CompressedAssignments.data[sectionIndex] = sectionData
    
    -- Track that we've received this section
    self.SYNC.receivedSections = self.SYNC.receivedSections or {}
    self.SYNC.receivedSections[sectionIndex] = true
    
    -- Track others' responses to avoid duplicate responses
    self.SYNC.receivedSectionResponses = self.SYNC.receivedSectionResponses or {}
    self.SYNC.receivedSectionResponses[sectionIndex] = true
    
    -- Cancel our response if pending
    if self.SYNC.pendingSectionResponses and self.SYNC.pendingSectionResponses[sectionIndex] then
        self:CancelTimer(self.SYNC.pendingSectionResponses[sectionIndex])
        self.SYNC.pendingSectionResponses[sectionIndex] = nil
        self:Debug("sync", "Canceled our pending response for section " .. sectionIndex .. " as someone else responded")
    end
    
    -- Attempt to decompress and store the section data
    local success = false
    
    if self.DecompressSectionData then
        local decompressedSection = self:DecompressSectionData(sectionIndex, sectionData)
        
        if decompressedSection and type(decompressedSection) == "table" then
            -- Update the TWRA_Assignments data
            if not TWRA_Assignments then
                TWRA_Assignments = {}
            end
            
            if not TWRA_Assignments.data then
                TWRA_Assignments.data = {}
            end
            
            -- Store the decompressed section
            TWRA_Assignments.data[sectionIndex] = decompressedSection
            
            -- Update section count
            local receivedCount = self:GetTableSize(self.SYNC.receivedSections)
            local totalCount = self.SYNC.totalSections or 0
            
            -- Log progress
            self:Debug("sync", "Section " .. sectionIndex .. " received (" .. 
                      receivedCount .. "/" .. totalCount .. " sections)")
            
            -- Show progress to user if receiving multiple sections
            if totalCount > 1 then
                DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA:|r Received section: " .. 
                    decompressedSection["Section name"] .. " (" .. receivedCount .. "/" .. totalCount .. ")")
                
                -- Update OSD with progress if available
                if self.UpdateProgressBar then
                    local percent = math.floor((receivedCount / totalCount) * 100)
                    self:UpdateProgressBar(percent, receivedCount, totalCount)
                end
            end
            
            -- If this is the currently displayed section, refresh it
            if self.currentSection == sectionIndex and self.RefreshAssignmentTable then
                self:RefreshAssignmentTable()
            end
            
            -- If all sections have been received
            if receivedCount >= totalCount then
                self:Debug("sync", "All sections received!")
                DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA:|r Sync complete! Received all " .. totalCount .. " sections from " .. sender)
                
                -- Process player information for all sections
                if self.ProcessPlayerInfo then
                    self:ProcessPlayerInfo()
                end
                
                -- Switch OSD back to assignment mode if needed
                if self.SwitchToAssignmentMode and self.currentSection then
                    local sectionName = TWRA_Assignments.data[self.currentSection]["Section name"]
                    self:SwitchToAssignmentMode(sectionName)
                end
            end
            
            success = true
        else
            self:Debug("error", "Failed to decode section " .. sectionIndex .. " data")
        end
    else
        self:Debug("error", "DecompressSectionData function not available")
    end
    
    return success
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

-- Helper function to extract timestamp from a message
function TWRA:ExtractTimestampFromMessage(message)
    if not message or type(message) ~= "string" then
        self:Debug("sync", "Failed to extract timestamp - invalid message")
        return nil, message
    end
    
    -- Try to extract timestamp between first and second colon
    local firstColon = string.find(message, ":", 1, true)
    if not firstColon then
        self:Debug("sync", "Failed to extract timestamp - no colons found")
        return nil, message
    end
    
    local secondColon = string.find(message, ":", firstColon + 1, true)
    if not secondColon then
        -- Only one colon, assume everything after it is timestamp
        local timestampStr = string.sub(message, firstColon + 1)
        local timestamp = tonumber(timestampStr)
        
        if not timestamp then
            self:Debug("sync", "Failed to extract timestamp - invalid format after single colon")
            return nil, message
        end
        
        return timestamp, "" -- No remaining content
    end
    
    -- Extract timestamp between the colons
    local timestampStr = string.sub(message, firstColon + 1, secondColon - 1)
    local timestamp = tonumber(timestampStr)
    
    if not timestamp then
        self:Debug("sync", "Failed to extract timestamp - invalid format between colons")
        return nil, message
    end
    
    -- Return both timestamp and remaining content
    local remainingContent = string.sub(message, secondColon + 1)
    return timestamp, remainingContent
end
