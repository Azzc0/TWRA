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
        
        return false -- Caller should not proceed with normal flow
        
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
            
            return false -- Caller should not proceed with normal flow
        else
            -- Fall back to legacy sync if structure sync not available
            self:Debug("sync", "RequestStructureSync not available, falling back to legacy sync")
            if self.RequestDataSync then
                self:RequestDataSync(remoteTimestamp)
            end
            return false -- Caller should not proceed with normal flow
        end
    else
        -- Timestamps are equal - proceed normally
        self:Debug("sync", "Timestamps are EQUAL")
        return true -- Caller should proceed with normal flow
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

-- Handle section change commands
function TWRA:HandleSectionCommand(message, sender)
    -- Add debug statement right at the start
    self:Debug("sync", "HandleSectionCommand called with message: " .. message .. " from " .. sender, true)
    
    -- More robust extraction of timestamp and section index
    local timestamp, sectionIndex = nil, nil
    local colonPos = string.find(message, ":", 1, true)  -- Find the colon with plain search
    
    if colonPos and colonPos > 1 then
        -- Extract parts directly using string.sub which is more reliable than pattern matching
        timestamp = string.sub(message, 1, colonPos-1)
        sectionIndex = string.sub(message, colonPos+1)
        
        self:Debug("sync", "Parsed from message - timestamp: '" .. timestamp .. "', sectionIndex: '" .. sectionIndex .. "'", true)
    else
        self:Debug("sync", "Invalid SECTION message format. Expected timestamp:sectionIndex but got: " .. message, true)
        return
    end
    
    -- Convert sectionIndex to number
    local sectionIndexNum = tonumber(sectionIndex)
    if not sectionIndexNum then
        self:Debug("sync", "Failed to convert section index to number: " .. sectionIndex, true)
        return
    end
    sectionIndex = sectionIndexNum
    
    -- Always debug what we received
    self:Debug("sync", string.format("Section change from %s (timestamp: %s, index: %d)", 
        sender, timestamp, sectionIndex), true)
    
    -- Use centralized timestamp comparison function
    -- If CompareTimestamps returns true, timestamps match and we should navigate
    -- If false, either we have newer data or they do, and CompareTimestamps has handled it
    if self:CompareTimestamps(timestamp, sender) then
        -- Timestamps match - navigate to the section
        self:Debug("sync", "Navigating to section " .. sectionIndex, true)
        self:NavigateToSection(sectionIndex, "fromSync")
    end
end

-- Handle table announcement commands (manual imports by other users)
function TWRA:HandleAnnounceCommand(message, sender)
    -- Extract parts from the message
    local parts = self:SplitString(message, ":")
    if table.getn(parts) < 2 then
        self:Debug("sync", "Malformed announce command from " .. sender .. ": " .. message)
        return
    end
    
    -- Extract timestamp - format is now "ANC:timestamp" (simplified for Phase 2)
    local timestamp = tonumber(parts[2])
    
    -- Debug info with sender name directly from addon message system
    self:Debug("sync", string.format("New import announced by %s (timestamp: %d)", 
        sender, timestamp))
    
    -- Compare timestamps using our centralized function
    self:Debug("sync", "Comparing announced import timestamp: " .. timestamp)
    
    -- Use centralized timestamp comparison
    local comparisonResult = self:CompareTimestamps(timestamp, sender)
    
    -- Request data if announced import is newer than what we have
    if not comparisonResult then
        self:Debug("sync", "Requesting newer data from import announcement")
        DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA:|r New data import detected from " .. sender .. ", requesting sync...")
    end
end

function TWRA:UnusedCommand()    -- Placeholder for unused command
    self:Debug("sync", "Unused command handler called")
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
