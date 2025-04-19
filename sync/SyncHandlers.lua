-- TWRA Sync Message Handlers
-- Handles all incoming addon communications for synchronization
TWRA = TWRA or {}

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
    
    -- Route to the appropriate handler based on command prefix
    if command == self.SYNC.COMMANDS.SECTION then
        -- Section change notification
        self:Debug("sync", "Routing to HandleSectionCommand with rest: " .. rest, true)
        self:HandleSectionCommand(rest, sender)
    elseif command == self.SYNC.COMMANDS.DATA_REQUEST then
        -- Data request
        self:HandleDataRequestCommand(message, sender)
    elseif command == self.SYNC.COMMANDS.DATA_RESPONSE then
        -- Data response
        self:HandleDataResponseCommand(message, sender)
    elseif command == self.SYNC.COMMANDS.ANNOUNCE then
        -- Announce new import
        self:HandleAnnounceCommand(message, sender)
    elseif command == self.SYNC.COMMANDS.VERSION then
        -- Version check (to be implemented)
        self:Debug("sync", "Version check from " .. sender .. " (not yet implemented)")
    else
        -- Unknown command
        self:Debug("sync", "Unknown command from " .. sender .. ": " .. command)
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
    -- local ourTimestamp = 0

    -- Debug the timestamp comparison
    self:Debug("sync", "Comparing timestamps - Received: " .. timestamp .. 
               " vs Our: " .. TWRA_Assignments.timestamp, true)
    
    
    if timestamp == TWRA_Assignments.timestamp then
        -- Timestamps match - navigate to the section
        self:Debug("sync", "Timestamps match - navigating to section " .. sectionIndex, true)
        
        self:NavigateToSection(sectionIndex, "fromSync")
        
    elseif timestamp < TWRA_Assignments.timestamp then
        -- We have a newer version - just log it and don't navigate
        self:Debug("sync", "We have a newer version (timestamp " .. TWRA_Assignments.timestamp .. 
                  " > " .. timestamp .. "), ignoring section change", true)
    
    else -- timestamp > ourTimestamp
        -- They have a newer version - request their data
        self:Debug("sync", "Detected newer data from " .. sender .. " (timestamp " .. 
                  timestamp .. " > " ..TWRA_Assignments.timestamp .. "), requesting data", true)
        
        -- Store the section index to navigate to after sync completes
        self.SYNC.pendingSection = { index = sectionIndex }
        self:Debug("sync", "Stored pending section index " .. sectionIndex .. " to navigate after sync", true)
        
        -- Request the data using the RECEIVED timestamp (not our own)
        self:RequestDataSync(timestamp)
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
    if TWRA_Assignments then
        ourTimestamp = TWRA_Assignments.timestamp or 0
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

-- Handle data request commands with correct timestamp matching
function TWRA:HandleDataRequestCommand(message, sender)
    -- Extract parts from the message
    local parts = self:SplitString(message, ":")
    if table.getn(parts) < 2 then
        self:Debug("sync", "Malformed data request command from " .. sender .. ": " .. message)
        return
    end
    
    -- Extract arguments - format is now simply "DREQ:timestamp"
    local requestedTimestamp = tonumber(parts[2])
    
    -- Debug info
    self:Debug("sync", string.format("Data request from %s (timestamp: %d)", 
        sender, requestedTimestamp))
    
    -- Check if we have the requested data
    local ourTimestamp = 0
    
    if TWRA_Assignments then
        ourTimestamp = TWRA_Assignments.timestamp or 0
    end
    
    -- Respond if our timestamp EQUALS the requested timestamp
    if ourTimestamp ~= requestedTimestamp then
        self:Debug("sync", "Timestamp mismatch - we have: " .. ourTimestamp .. 
                  ", requested: " .. requestedTimestamp .. " (not sending data)")
        return
    end
    
    self:Debug("sync", "We have the requested data (timestamp " .. ourTimestamp .. 
               " = " .. requestedTimestamp .. "), sending data to " .. sender)
    
    -- Always use compressed data from TWRA_CompressedAssignments.data
    if TWRA_CompressedAssignments and TWRA_CompressedAssignments.data then
        local compressedData = TWRA_CompressedAssignments.data
        self:Debug("sync", "Using stored compressed data for response (length: " .. 
                  string.len(compressedData) .. ")")
        
        -- Add random delay to prevent multiple responses at once
        -- Delay proportional to group size: 0-2 seconds in a 40-man raid
        local groupSize = GetNumRaidMembers() > 0 and GetNumRaidMembers() or GetNumPartyMembers()
        local maxDelay = math.min(2, groupSize * 0.05)
        local delay = maxDelay * math.random()
        
        -- Schedule the response after the delay
        self:ScheduleTimer(function()
            self:Debug("sync", "Sending compressed data response now")
            
            -- Format message - without COMP marker since we always use compression
            local message = string.format("%s:%d:%s", 
                self.SYNC.COMMANDS.DATA_RESPONSE,
                ourTimestamp,
                compressedData)
            
            -- Use chunk manager if needed for large data
            if string.len(message) > 254 and self.chunkManager then
                self:Debug("sync", "Data too large, using chunk manager")
                local prefix = string.format("%s:%d:", 
                    self.SYNC.COMMANDS.DATA_RESPONSE, ourTimestamp)
                
                self.chunkManager:SendChunkedMessage(compressedData, prefix)
            else
                -- Send directly if small enough
                self:SendAddonMessage(message)
            end
        end, delay)
        
        self:Debug("sync", string.format("Scheduled compressed data response in %.1f seconds", delay))
        return
    end
    
    -- If we get here, we don't have compressed data to share
    self:Debug("sync", "No compressed data available to share")
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
                    
                    -- Process the assembled data - now always treated as compressed
                    self:ProcessCompressedData(assembledData, timestamp, sender)
                    
                    -- Clean up the transfer data
                    self.SYNC.chunkedData[transferId] = nil
                end
            end
            return
        end
    end
    
    -- Standard non-chunked response - extract the data portion
    local prefix = parts[1] .. ":" .. parts[2] .. ":"
    local prefixLen = string.len(prefix)
    local compressedData = string.sub(message, prefixLen + 1)
    
    self:Debug("sync", string.format("Received data response from %s (timestamp: %d, length: %d)", 
        sender, timestamp, string.len(compressedData)))
    
    -- Process the data - now always treat as compressed
    self:ProcessCompressedData(compressedData, timestamp, sender)
end

-- Function to process compressed data received via sync
function TWRA:ProcessCompressedData(compressedData, timestamp, sender)
    -- Compare timestamps
    local ourTimestamp = 0
    if TWRA_Assignments then
        ourTimestamp = TWRA_Assignments.timestamp or 0
    end
    
    -- Only process if we need this data
    if timestamp <= ourTimestamp then
        self:Debug("sync", "Ignoring compressed data (we have newer or same data)")
        return
    end
    
    -- Initialize compression system if needed
    if not self.LibCompress then
        if not self:InitializeCompression() then
            self:Debug("error", "Failed to initialize compression system")
            return
        end
    end
    
    -- Decompress the data
    local decompressedData, err = self:DecompressAssignmentsData(compressedData)
    
    if not decompressedData then
        self:Debug("error", "Failed to decompress data from " .. sender .. ": " .. tostring(err))
        return
    end
    
    self:Debug("sync", "Successfully decompressed data from " .. sender .. 
              " (" .. table.getn(decompressedData.data or {}) .. " sections)")
    
    -- Save the decompressed data
    local saveResult = self:SaveAssignments(decompressedData, "sync", timestamp, true)
    if not saveResult then
        self:Debug("error", "Failed to save decompressed data from " .. sender)
        return
    end
    
    -- Data successfully imported
    self:Debug("sync", "Successfully imported compressed data from " .. sender)
    DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA:|r Successfully imported data from " .. sender)
    
    -- Navigate to pending section if one was stored
    if self.SYNC.pendingSection then
        self:Debug("sync", "Navigating to pending section: " .. 
                 (self.SYNC.pendingSection.name or self.SYNC.pendingSection.index))
        self:NavigateToSection(self.SYNC.pendingSection.index, true)
        self.SYNC.pendingSection = nil
    end
end

-- Send data response to group
function TWRA:SendDataResponse(encodedData, timestamp)
    -- Try to use compressed data first if available
    if self.CompressAssignmentsData then
        self:Debug("sync", "Attempting to send compressed data response")
        
        local compressedData = self:GetStoredCompressedData()
        
        if compressedData then
            -- Format message with COMP marker to indicate compressed data
            local message = string.format("%s:%d:%s", 
                self.SYNC.COMMANDS.DATA_RESPONSE,
                timestamp,
                compressedData)
            
            -- Check if message is within size limits
            if string.len(message) <= 254 then  -- Safe limit for addon messages
                self:Debug("sync", "Sending compressed data response (" .. 
                          string.len(compressedData) .. " bytes)")
                self:SendAddonMessage(message)
                return true
            else
                self:Debug("sync", "Compressed data too large (" .. 
                          string.len(message) .. " bytes), will use chunking")
                
                -- If we have the ChunkManager, use it for sending compressed data
                if self.chunkManager then
                    self:Debug("sync", "Using ChunkManager to send compressed data")
                    local prefix = string.format("%s:%d:", 
                        self.SYNC.COMMANDS.DATA_RESPONSE, timestamp)
                    
                    self.chunkManager:SendChunkedMessage(compressedData, prefix)
                    return true
                end
            end
        else
            self:Debug("sync", "No compressed data available, falling back to Base64")
        end
    end
    
    -- Fall back to original Base64 method if compression isn't available
    if not encodedData or encodedData == "" then
        self:Debug("error", "No data to send in response")
        return false
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
