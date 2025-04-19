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

-- Handle incoming data requests from other users
function TWRA:HandleDataRequestCommand(message, sender)
    self:Debug("sync", "HandleDataRequestCommand called with message: " .. message .. " from " .. sender)
    
    -- Parse the timestamp
    local timestamp = tonumber(message) or 0
    
    -- Debug detailed information about the request
    self:Debug("sync", "Data request from " .. sender .. " with timestamp: " .. timestamp)
    
    -- Check if we have data to share
    if not TWRA_Assignments or not TWRA_Assignments.data then
        self:Debug("sync", "No assignments data available to send to " .. sender)
        return
    end
    
    -- Get our current timestamp
    local ourTimestamp = TWRA_Assignments.timestamp or 0
    
    -- Only respond if our data is newer or matches the request
    if ourTimestamp >= timestamp then
        self:Debug("sync", "Our timestamp (" .. ourTimestamp .. ") matches or is newer than requested (" 
                   .. timestamp .. "), sending data to " .. sender)
        
        -- Get compressed data - first try to get stored compressed data
        local compressedData = nil
        
        -- Try to get from dedicated compressed storage first
        if TWRA_CompressedAssignments and TWRA_CompressedAssignments.data then
            compressedData = TWRA_CompressedAssignments.data
            self:Debug("sync", "Using stored compressed data for response")
        -- Fall back to our GetStoredCompressedData function if available
        elseif self.GetStoredCompressedData then
            compressedData = self:GetStoredCompressedData()
            self:Debug("sync", "Generated compressed data for response using GetStoredCompressedData")
        -- Last resort - compress on the fly
        elseif self.CompressAssignmentsData then
            -- Prepare data for sync (strip client-specific info)
            local syncData = nil
            if self.PrepareDataForSync then
                syncData = self:PrepareDataForSync(TWRA_Assignments)
                self:Debug("sync", "Prepared data for sync")
            else
                syncData = TWRA_Assignments
                self:Debug("sync", "Using raw assignments data (PrepareDataForSync not available)")
            end
            
            -- Compress the data
            compressedData = self:CompressAssignmentsData(syncData)
            self:Debug("sync", "Compressed data on-demand for response")
        end
        
        -- Send the response if we have data
        if compressedData then
            self:Debug("sync", "Sending data response to " .. sender .. " with timestamp " .. ourTimestamp)
            self:SendDataResponse(compressedData, ourTimestamp)
        else
            self:Debug("error", "Failed to compress data for response to " .. sender)
        end
    else
        self:Debug("sync", "Our timestamp (" .. ourTimestamp .. ") is older than requested (" 
                   .. timestamp .. "), not sending data to " .. sender)
    end
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
            self:Debug("sync", "Using chunk manager to process chunked data header")
            self.chunkManager:ProcessChunkHeader(message, sender)
            return
        else
            -- Basic chunked data handling fallback
            if table.getn(parts) < 6 then
                self:Debug("sync", "Malformed chunked data header from " .. sender)
                return
            end
            
            -- Initialize chunk storage in SYNC (create if needed)
            self.SYNC.chunkedData = self.SYNC.chunkedData or {}
            
            -- Create a unique transfer ID for this chunked transfer
            local transferId = parts[5] -- Use the unique ID from the CHUNKED header
            
            -- Store the transfer info
            self.SYNC.chunkedData[transferId] = {
                timestamp = timestamp,
                sender = sender,
                totalSize = tonumber(parts[4]) or 0,
                chunks = {},
                chunkCount = tonumber(parts[6]) or 0,
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
            self:Debug("sync", "Using chunk manager to process data chunk")
            self.chunkManager:ProcessChunk(message, sender)
            return
        else
            -- Basic chunk handling fallback
            if table.getn(parts) < 7 then
                self:Debug("sync", "Malformed data chunk from " .. sender)
                return
            end
            
            -- Extract chunk info
            local chunkNumber = tonumber(parts[4])
            local totalChunks = tonumber(parts[5])
            local transferId = parts[6]
            
            -- Make sure we have SYNC.chunkedData
            self.SYNC.chunkedData = self.SYNC.chunkedData or {}
            
            -- Make sure we're expecting chunks for this transfer
            if not self.SYNC.chunkedData[transferId] then
                self:Debug("sync", "Received unexpected chunk from " .. sender .. " for transfer " .. transferId)
                return
            end
            
            local transfer = self.SYNC.chunkedData[transferId]
            
            -- Update the expected chunk count if this is the first chunk we've seen
            if transfer.chunkCount == 0 then
                transfer.chunkCount = totalChunks
            end
            
            -- Extract the chunk data - piece together everything after the header
            local chunkData = parts[7]
            
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
    -- Get our current timestamp for comparison
    local ourTimestamp = TWRA_Assignments and TWRA_Assignments.timestamp or 0
    
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
              " (" .. (decompressedData.data and table.getn(decompressedData.data or {}) or 0) .. " sections)")
    
    -- IMPORTANT: Additional UI cleanup for any lingering elements
    if self.mainFrame then
        -- Force a complete hard UI reset before changing data
        self:Debug("sync", "Performing thorough UI cleanup before saving new data")
        
        -- 1. Clear rows and footers
        if self.ClearRows then self:ClearRows() end
        if self.ClearFooters then self:ClearFooters() end
        
        -- 2. Reset row structures and highlight elements
        if self.rowFrames then self.rowFrames = {} end
        if self.highlightPool then 
            for _, highlight in pairs(self.highlightPool) do
                if highlight and highlight.Hide then highlight:Hide() end
            end
        end
        
        -- 3. Save current view state before data change
        local wasInOptionsView = self.currentView == "options"
        
        -- Force clear any potential pending handlers
        self.pendingHandler = nil
    end
    
    -- Save the decompressed data
    local saveResult = self:SaveAssignments(decompressedData, "sync", timestamp, true)
    if not saveResult then
        self:Debug("error", "Failed to save decompressed data from " .. sender)
        return
    end
    
    -- Data successfully imported
    self:Debug("sync", "Successfully imported compressed data from " .. sender)
    
    -- IMPORTANT ADDITION: Refresh UI and rebuild navigation completely
    self:Debug("sync", "Performing complete UI refresh after sync")
    
    -- Ensure navigation is properly rebuilt after data load
    if self.RebuildNavigation then
        self:Debug("sync", "Rebuilding navigation system after sync")
        self:RebuildNavigation()
    end
    
    -- Refresh all player information
    if self.RefreshPlayerInfo then
        self:Debug("sync", "Refreshing player information after sync")
        self:RefreshPlayerInfo()
    end
    
    -- Navigate to pending section or first section
    local sectionToNavigate = 1
    if self.SYNC and self.SYNC.pendingSection and self.SYNC.pendingSection.index then
        sectionToNavigate = self.SYNC.pendingSection.index
        -- Clear pending after using
        self.SYNC.pendingSection = nil
    end
    
    -- Register handlers for navigation buttons
    if self.RegisterNavigationHandlers then
        self:Debug("sync", "Registering navigation handlers after sync")
        self:RegisterNavigationHandlers()
    end
    
    -- Full UI reload including content
    if self.LoadContent then
        self:Debug("sync", "Reloading UI content after sync")
        self:LoadContent()
    elseif self.ShowMainView and self.NavigateToSection then
        self:Debug("sync", "Showing main view and navigating after sync")
        self:ShowMainView()
        self:NavigateToSection(sectionToNavigate, "fromSync")
    elseif self.NavigateToSection then
        self:Debug("sync", "Navigating to section " .. sectionToNavigate .. " after sync")
        self:NavigateToSection(sectionToNavigate, "fromSync")
    end
    
    -- Notify the user of successful sync
    DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA:|r Synchronized raid assignments from " .. sender)
    
    return true
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
