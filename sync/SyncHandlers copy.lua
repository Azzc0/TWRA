-- TWRA Sync Message Handlers
-- Handles all incoming addon communications for synchronization
TWRA = TWRA or {}

-- Initialize SYNC namespace with new segmented sync commands
if not TWRA.SYNC then
    TWRA.SYNC = {
        PREFIX = "TWRA",
        COMMANDS = {
            SECTION = "SEC",
            DATA_REQUEST = "DREQ",  -- Deprecated, will be removed in future
            DATA_RESPONSE = "DRES", -- Deprecated, will be removed in future
            ANNOUNCE = "ANC",
            VERSION = "VER",
            -- New commands for segmented sync
            STRUCTURE_REQUEST = "SREQ",
            STRUCTURE_RESPONSE = "SRESP",
            SECTION_REQUEST = "SECREQ",
            SECTION_RESPONSE = "SECRESP"
        },
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
        SEC = self.HandleSectionCommand,
        ANC = self.HandleAnnounceCommand,
        VER = function(self, rest, sender) 
            self:Debug("sync", "Version check from " .. sender .. " (not yet implemented)")
        end,
        
        -- Deprecated legacy messages
        DREQ = function(self, rest, sender) 
            self:Debug("sync", "DEPRECATED: Received legacy DATA_REQUEST command from " .. sender)
            self:HandleDataRequestCommand(rest, sender) 
        end,
        DRES = function(self, rest, sender, fullMessage) 
            self:Debug("sync", "DEPRECATED: Received legacy DATA_RESPONSE command from " .. sender)
            self:HandleDataResponseCommand(fullMessage, sender) 
        end,
        
        -- Segmented sync messages
        SREQ = self.HandleStructureRequestCommand,
        SRESP = self.HandleStructureResponseCommand,
        SECREQ = self.HandleSectionRequestCommand, 
        SECRESP = self.HandleSectionResponseCommand
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
        if command == "DRES" or command == "SRESP" or command == "SECRESP" or command == "ANC" then
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

-- Compare timestamps and return relationship between them
function TWRA:CompareTimestamps(localTimestamp, remoteTimestamp)
    -- Handle nil values
    localTimestamp = tonumber(localTimestamp) or 0
    remoteTimestamp = tonumber(remoteTimestamp) or 0
    
    -- Compare and return result
    if localTimestamp > remoteTimestamp then
        return 1       -- Local is newer
    elseif localTimestamp < remoteTimestamp then
        return -1      -- Remote is newer
    else
        return 0       -- Equal timestamps
    end
end

-- Handle section change commands
function TWRA:HandleSectionCommand(message, sender)
    -- Add debug statement right at the start
    self:Debug("sync", "HandleSectionCommand called with message: " .. message .. " from " .. sender, true)
    
    -- More robust extraction of section index and timestamp
    local sectionIndex, timestamp = nil, nil
    local colonPos = string.find(message, ":", 1, true)  -- Find the colon with plain search
    
    if colonPos and colonPos > 1 then
        -- Extract parts directly using string.sub which is more reliable than pattern matching
        sectionIndex = string.sub(message, 1, colonPos-1)
        timestamp = string.sub(message, colonPos+1)
        
        self:Debug("sync", "Parsed from message - sectionIndex: '" .. sectionIndex .. "', timestamp: '" .. timestamp .. "'", true)
    else
        self:Debug("sync", "Invalid SECTION message format. Expected sectionIndex:timestamp but got: " .. message, true)
        return
    end
    
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
        self.SYNC.pendingSection = { index = sectionIndex }
        self:Debug("sync", "Stored pending section index " .. sectionIndex .. " to navigate after sync", true)
        
        -- Request the data using the RECEIVED timestamp (not our own)
        -- Use segmented sync if available, otherwise fall back to legacy sync
        if self.SYNC.useSegmentedSync and self.RequestStructureSync then
            self:Debug("sync", "Using segmented sync for newer data")
            self:RequestStructureSync(timestamp)
        else
            self:Debug("sync", "Falling back to legacy sync for newer data")
            self:RequestDataSync(timestamp)
        end
    end
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
