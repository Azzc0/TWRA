-- TWRA Sync Message Handlers
-- Handles all incoming addon communications for synchronization
TWRA = TWRA or {}

-- Main addon message handler - routes messages to appropriate handlers
function TWRA:HandleAddonMessage(message, channel, sender)
    -- Skip our own messages
    if sender == UnitName("player") then
        self:Debug("sync", "Ignoring own message: " .. message)
        return
    end
    
    -- Validate message format with improved diagnostic
    if not message or message == "" then
        self:Debug("sync", "Received empty message from " .. sender)
        return
    end
    
    -- Reduce debug spam - only show this for important messages
    self:Debug("sync", "Processing message from " .. sender .. ": " .. message)
    
    -- Split message by colon to get command and arguments
    local parts = self:SplitString(message, ":")
    if not parts or table.getn(parts) < 1 then
        self:Debug("sync", "Malformed message from " .. sender .. ": " .. message)
        return
    end
    
    -- Extract command and arguments
    local command = parts[1]
    
    -- Route to appropriate handler based on command
    -- Remove the diagnostic and detailed message parts output for routine operations
    
    if command == self.SYNC.COMMANDS.SECTION then
        self:HandleSectionCommand(message, sender)
    elseif command == self.SYNC.COMMANDS.ANNOUNCE then
        self:HandleAnnounceCommand(message, sender)
    elseif command == self.SYNC.COMMANDS.DATA_REQUEST then
        self:HandleDataRequestCommand(message, sender)
    elseif command == self.SYNC.COMMANDS.DATA_RESPONSE then
        self:HandleDataResponseCommand(message, sender)
    elseif command == self.SYNC.COMMANDS.VERSION then
        self:HandleVersionCommand(message, sender)
    else
        self:Debug("sync", "Unknown command from " .. sender .. ": " .. command)
    end
end

-- Handle section change commands (live section sync)
function TWRA:HandleSectionCommand(message, sender)
    -- Reduce initial debug spam
    
    -- Extract parts from the message
    local parts = self:SplitString(message, ":")
    if table.getn(parts) < 4 then
        self:Debug("sync", "Malformed section command from " .. sender .. ": " .. message)
        return
    end
    
    -- Extract arguments - format is "SECTION:timestamp:sectionIndex:sectionName"
    local timestamp = tonumber(parts[2])
    local sectionIndex = tonumber(parts[3])
    local sectionName = parts[4]
    
    -- Simplified debug info - only show the essential details
    self:Debug("sync", string.format("Section change from %s: '%s' (index: %d, timestamp: %d)", 
        sender, sectionName, sectionIndex, timestamp))
    
    -- Verify we have live sync enabled - combine checks to reduce debug spam
    if not self.SYNC or not self.SYNC.liveSync or not self.SYNC.isActive then
        self:Debug("sync", "Ignoring section change (LiveSync not active)")
        return
    end
    
    -- Compare timestamps
    local ourTimestamp = 0
    if TWRA_SavedVariables and TWRA_SavedVariables.assignments then
        ourTimestamp = TWRA_SavedVariables.assignments.timestamp or 0
    end
    
    -- If the sender has newer data, request a sync
    if timestamp > ourTimestamp then
        self:Debug("sync", "Newer data detected (" .. timestamp .. " vs " .. ourTimestamp .. ") - requesting sync")
        
        -- Store the pending section to navigate to after sync completes
        self.SYNC.pendingSection = {
            index = sectionIndex, 
            name = sectionName
        }
        
        if self.RequestDataSync then
            self:RequestDataSync(timestamp)
        else
            self:Debug("error", "RequestDataSync function not found")
        end
        return
    end
    
    -- If timestamps match, navigate to the section - with less debug spam
    if timestamp == ourTimestamp then
        -- Verify navigation functionality in one check to reduce debug spam
        if not (self.NavigateToSection and self.navigation and self.navigation.handlers) then
            self:Debug("error", "Navigation system not properly initialized")
            return
        end
        
        -- Check if the section exists in our handlers
        local totalSections = table.getn(self.navigation.handlers)
        if sectionIndex > totalSections then
            self:Debug("error", "Section index out of range: " .. sectionIndex .. " (max: " .. totalSections .. ")")
            return
        end
        
        -- Use NavigateToSection with suppressSync=true to avoid broadcast loops
        self:Debug("sync", "Navigating to section " .. sectionIndex .. " (" .. sectionName .. ")")
        self:NavigateToSection(sectionIndex, true)
        
        -- Show message to user
        DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA:|r Changed to section " .. sectionName .. " by " .. sender)
    else
        self:Debug("sync", "Ignoring section change (we have newer data)")
    end
end

-- Handle table announcement commands (manual imports by other users)
function TWRA:HandleAnnounceCommand(message, sender)
    -- Extract parts from the message
    local parts = self:SplitString(message, ":")
    if table.getn(parts) < 3 then
        self:Debug("sync", "Malformed announce command from " .. sender .. ": " .. message)
        return
    end
    
    -- Extract arguments - format is "ANC:timestamp:importerName"
    local timestamp = tonumber(parts[2])
    local importerName = parts[3]
    
    -- Debug info with more details
    self:Debug("sync", string.format("New import announced by %s (timestamp: %d)", 
        importerName, timestamp))
    
    -- Compare timestamps with better debugging
    local ourTimestamp = 0
    if TWRA_SavedVariables and TWRA_SavedVariables.assignments then
        ourTimestamp = TWRA_SavedVariables.assignments.timestamp or 0
    end
    
    self:Debug("sync", "Comparing announced import - theirs: " .. timestamp .. ", ours: " .. ourTimestamp)
    
    -- Request data if announced import is newer than what we have
    if timestamp > ourTimestamp then
        self:Debug("sync", "Requesting newer data from import announcement")
        DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA:|r New data import detected from " .. importerName .. ", requesting sync...")
        self:RequestDataSync(timestamp)
    else
        self:Debug("sync", "Ignoring import announcement (we have newer or same data)")
    end
end

-- Handle data request commands with more detailed debugging
function TWRA:HandleDataRequestCommand(message, sender)
    -- Extract parts from the message
    local parts = self:SplitString(message, ":")
    if table.getn(parts) < 2 then
        self:Debug("sync", "Malformed data request command from " .. sender .. ": " .. message)
        return
    end
    
    -- Extract arguments - format is "DREQ:timestamp"
    local requestedTimestamp = tonumber(parts[2])
    
    -- Debug info
    self:Debug("sync", string.format("Data request from %s (timestamp: %d)", 
        sender, requestedTimestamp))
    
    -- Check if we have the requested data
    local ourTimestamp = 0
    local sourceString = nil
    
    if TWRA_SavedVariables and TWRA_SavedVariables.assignments then
        ourTimestamp = TWRA_SavedVariables.assignments.timestamp or 0
        sourceString = TWRA_SavedVariables.assignments.source
    end
    
    self:Debug("sync", "Our data: timestamp=" .. ourTimestamp .. 
               ", source=" .. (sourceString and "present (" .. string.len(sourceString or "") .. " chars)" or "missing"))
    
    -- Only respond if our timestamp matches what was requested
    if ourTimestamp ~= requestedTimestamp then
        self:Debug("sync", "Timestamp mismatch - we have: " .. ourTimestamp .. 
                  ", requested: " .. requestedTimestamp)
        return
    end
    
    -- Make sure we have source data
    if not sourceString or sourceString == "" then
        self:Debug("sync", "No source data available to share")
        return
    end
    
    -- Add random delay to prevent multiple responses at once
    -- Delay proportional to group size: 0-2 seconds in a 40-man raid
    local groupSize = GetNumRaidMembers() > 0 and GetNumRaidMembers() or GetNumPartyMembers()
    local maxDelay = math.min(2, groupSize * 0.05)
    local delay = maxDelay * math.random()
    
    -- Schedule the response after the delay
    self:ScheduleTimer(function()
        self:Debug("sync", "Sending data response now with source of length: " .. string.len(sourceString))
        self:SendDataResponse(sourceString, ourTimestamp)
    end, delay)
    
    self:Debug("sync", string.format("Scheduling data response in %.1f seconds (data length: %d)", 
                delay, string.len(sourceString)))
end

-- Handle data response commands
function TWRA:HandleDataResponseCommand(message, sender)
    -- Extract the timestamp from the beginning of the message
    local parts = self:SplitString(message, ":")
    if table.getn(parts) < 3 then
        self:Debug("sync", "Malformed data response from " .. sender .. ": " .. message)
        return
    end
    
    -- Extract timestamp
    local timestamp = tonumber(parts[2])
    
    -- Check if this is a chunked message
    if parts[3] == "CHUNKED" then
        -- If we have the ChunkManager, use it
        if self.chunkManager then
            self:ProcessChunkHeader(parts, message, sender)
            return
        else
            -- Basic chunked data handling fallback
            if table.getn(parts) < 4 then
                self:Debug("sync", "Malformed chunked data header from " .. sender)
                return
            end
            
            -- Initialize chunk storage in SYNC (create if needed)
            self.SYNC.chunkedData = self.SYNC.chunkedData or {}
            
            -- Create a unique transfer ID for this chunked transfer
            local transferId = parts[1] .. ":" .. parts[2] .. ":" .. sender
            
            -- Store the transfer info
            self.SYNC.chunkedData[transferId] = {
                timestamp = timestamp,
                sender = sender,
                totalSize = tonumber(parts[4]) or 0,
                chunks = {},
                chunkCount = 0,
                receivedChunks = 0,
                complete = false,
                assembledData = nil,
                startTime = GetTime()
            }
            
            self:Debug("sync", "Receiving chunked data from " .. sender .. 
                      " (timestamp: " .. timestamp .. ")")
            return
        end
    end
    
    -- Check if this is a chunk of data
    if parts[3] == "CHUNK" then
        -- If we have the ChunkManager, use it
        if self.chunkManager then
            self:ProcessDataChunk(parts, message, sender)
            return
        else
            -- Basic chunk handling fallback
            if table.getn(parts) < 6 then
                self:Debug("sync", "Malformed data chunk from " .. sender)
                return
            end
            
            -- Create transfer ID to match the chunks
            local transferId = parts[1] .. ":" .. parts[2] .. ":" .. sender
            
            -- Make sure we have SYNC.chunkedData
            self.SYNC.chunkedData = self.SYNC.chunkedData or {}
            
            -- Make sure we're expecting chunks for this transfer
            if not self.SYNC.chunkedData[transferId] then
                self:Debug("sync", "Received unexpected chunk from " .. sender)
                return
            end
            
            local transfer = self.SYNC.chunkedData[transferId]
            
            -- Extract chunk info
            local chunkNumber = tonumber(parts[4])
            local totalChunks = tonumber(parts[5])
            
            -- Update the expected chunk count if this is the first chunk we've seen
            if transfer.chunkCount == 0 then
                transfer.chunkCount = totalChunks
            end
            
            -- Extract the chunk data - piece together everything after the header
            local headerLength = string.len(parts[1] .. ":" .. parts[2] .. ":" .. 
                                           parts[3] .. ":" .. parts[4] .. ":" .. parts[5] .. ":")
            local chunkData = string.sub(message, headerLength + 1)
            
            -- Store the chunk
            transfer.chunks[chunkNumber] = chunkData
            transfer.receivedChunks = transfer.receivedChunks + 1
            
            self:Debug("sync", "Received chunk " .. chunkNumber .. "/" .. totalChunks .. 
                      " (length: " .. string.len(chunkData) .. ")")
            
            -- Check if we have all chunks
            if transfer.receivedChunks >= transfer.chunkCount then
                -- Assemble the complete data
                local assembledData = ""
                local missingChunks = false
                
                -- Check all chunks are present
                for i = 1, transfer.chunkCount do
                    if not transfer.chunks[i] then
                        self:Debug("error", "Missing chunk " .. i .. " in assembled data")
                        missingChunks = true
                        break
                    end
                end
                
                -- Only proceed if all chunks present
                if not missingChunks then
                    -- Assemble in correct order
                    for i = 1, transfer.chunkCount do
                        assembledData = assembledData .. transfer.chunks[i]
                    end
                    
                    transfer.complete = true
                    transfer.assembledData = assembledData
                    
                    self:Debug("sync", "Successfully assembled chunked data (" .. 
                              string.len(assembledData) .. " bytes)")
                    
                    -- Process the assembled data
                    self:ProcessReceivedData(assembledData, timestamp, sender)
                    
                    -- Clean up the transfer data
                    self.SYNC.chunkedData[transferId] = nil
                end
            end
            return
        end
    end
    
    -- Standard non-chunked response - reconstruct the encoded data
    local prefix = parts[1] .. ":" .. parts[2] .. ":"
    local prefixLen = string.len(prefix)
    local encodedData = string.sub(message, prefixLen + 1)
    
    self:Debug("sync", string.format("Received standard data response from %s (timestamp: %d, length: %d)", 
        sender, timestamp, string.len(encodedData)))
    
    -- Process the data
    self:ProcessReceivedData(encodedData, timestamp, sender)
end

-- Helper function to process received data (either chunked or standard)
function TWRA:ProcessReceivedData(encodedData, timestamp, sender)
    -- Compare timestamps
    local ourTimestamp = 0
    if TWRA_SavedVariables and TWRA_SavedVariables.assignments then
        ourTimestamp = TWRA_SavedVariables.assignments.timestamp or 0
    end
    
    -- Only process if we need this data
    if timestamp <= ourTimestamp then
        self:Debug("sync", "Ignoring data response (we have newer or same data)")
        return
    end
    
    -- Process the data like an import but with sync flags
    if self.DecodeBase64 then
        -- Add safety check to ensure the data is complete
        if string.len(encodedData) < 10 then
            self:Debug("error", "Data from " .. sender .. " is too short: " .. string.len(encodedData) .. " bytes")
            return
        end
        
        -- Fix Base64 padding without using modulo
        -- Base64 data length should be divisible by 4
        local dataLen = string.len(encodedData)
        local remainder = dataLen
        while remainder > 0 and remainder < 4 do
            encodedData = encodedData .. "="
            remainder = remainder + 1
            self:Debug("sync", "Added padding to make Base64 string length divisible by 4")
        end
        
        -- Ensure string ends with proper Base64 padding
        if not string.find(encodedData, "==$") and not string.find(encodedData, "=$") then
            -- Check if we need padding based on length
            local padNeeded = 4 - (string.len(encodedData) - (math.floor(string.len(encodedData)/4) * 4))
            if padNeeded > 0 and padNeeded < 4 then
                local padding = ""
                for i = 1, padNeeded do
                    padding = padding .. "="
                end
                encodedData = encodedData .. padding
                self:Debug("sync", "Added " .. padNeeded .. " padding characters to data")
            end
        end
        
        -- Try decoding with better error handling
        local success, result = pcall(function()
            return self:DecodeBase64(encodedData, timestamp, true)
        end)
        
        if not success then
            self:Debug("error", "Error decoding sync data: " .. tostring(result))
            return
        end
        
        if not result then
            self:Debug("error", "Failed to decode data from " .. sender)
            return
        end
        
        -- Data successfully imported
        self:Debug("sync", "Successfully imported data from " .. sender)
        DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA:|r Successfully imported data from " .. sender)
        
        -- Navigate to pending section if one was stored
        if self.SYNC.pendingSection then
            self:Debug("sync", "Navigating to pending section: " .. self.SYNC.pendingSection.name)
            self:NavigateToSection(self.SYNC.pendingSection.index, true)
            self.SYNC.pendingSection = nil
        end
    else
        self:Debug("error", "DecodeBase64 function not found")
    end
end

-- Handle version check commands
function TWRA:HandleVersionCommand(message, sender)
    -- Currently just logs the version info
    self:Debug("sync", "Version check from " .. sender .. " (message: " .. message .. ")")
end

-- Request data sync from group
function TWRA:RequestDataSync(timestamp)
    -- Throttle requests - don't spam requests
    local now = GetTime()
    if now - self.SYNC.lastRequestTime < self.SYNC.requestTimeout then
        self:Debug("sync", "Data request throttled")
        return
    end
    
    -- Update last request time
    self.SYNC.lastRequestTime = now
    
    -- Send data request message
    local message = string.format("%s:%d", self.SYNC.COMMANDS.DATA_REQUEST, timestamp)
    self:SendAddonMessage(message)
    
    self:Debug("sync", "Requested data sync for timestamp: " .. timestamp)
end

-- Send data response to group
function TWRA:SendDataResponse(encodedData, timestamp)
    if not encodedData or encodedData == "" then
        self:Debug("error", "No data to send in response")
        return
    end
    
    -- Format message
    local message = string.format("%s:%d:%s", 
        self.SYNC.COMMANDS.DATA_RESPONSE,
        timestamp,
        encodedData)
    
    -- This could be very large, so we might need to chunk it
    -- For now, just try to send directly
    self:Debug("sync", "Sending data response (timestamp: " .. timestamp .. ", length: " .. string.len(message) .. ")")
    self:SendAddonMessage(message)
end

-- Send section change notification to group
function TWRA:BroadcastSectionChange(sectionIndex, sectionName)
    -- Check if we're in a group
    if GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 then
        self:Debug("sync", "Not in a group, skipping section broadcast")
        return false
    end
    
    -- Make sure live sync is enabled
    if not self.SYNC or not self.SYNC.liveSync then
        self:Debug("sync", "Live sync disabled, skipping section broadcast")
        return false
    end
    
    -- Get current timestamp
    local timestamp = 0
    if TWRA_SavedVariables and TWRA_SavedVariables.assignments then
        timestamp = TWRA_SavedVariables.assignments.timestamp or 0
    end
    
    -- Format and send the message
    local message = string.format("%s:%d:%d:%s", 
        self.SYNC.COMMANDS.SECTION,
        timestamp,
        sectionIndex,
        sectionName or "")
    
    self:SendAddonMessage(message)
    self:Debug("sync", "Broadcast section change: " .. (sectionName or "") .. 
               " (index: " .. sectionIndex .. ", timestamp: " .. timestamp .. ")")
    return true
end

-- Helper function to send an addon message using the correct channel
function TWRA:SendAddonMessage(message, target)
    -- Determine channel to use
    local channel = "RAID"
    if GetNumRaidMembers() == 0 then
        if GetNumPartyMembers() > 0 then
            channel = "PARTY"
        else
            self:Debug("sync", "Not in a group, can't send message")
            return false
        end
    end
    
    -- Check message length
    local maxLength = 254 -- Safe limit for addon messages
    if string.len(message) > maxLength then
        self:Debug("sync", "Message too long (" .. string.len(message) .. " chars), truncating")
        message = string.sub(message, 1, maxLength)
    end
    
    -- Send the message
    SendAddonMessage(self.SYNC.PREFIX, message, channel, target)
    return true
end

-- Add initialization of the chunk manager at addon load
function TWRA:InitializeSyncHandlers()
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
    
    self:Debug("sync", "Sync handlers initialized")
    return true
end
