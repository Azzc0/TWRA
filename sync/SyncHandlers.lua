-- TWRA Sync Message Handlers
-- Handles all incoming addon communications for synchronization
TWRA = TWRA or {}

-- Initialize SYNC namespace with new segmented sync commands
if not TWRA.SYNC then
    TWRA.SYNC = {
        PREFIX = "TWRA",
        COMMANDS = {
            SECTION = "SEC",
            DATA_REQUEST = "REQ",
            DATA_RESPONSE = "RESP",
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
        self:HandleDataRequestCommand(rest, sender)
    elseif command == self.SYNC.COMMANDS.DATA_RESPONSE then
        -- Data response
        self:HandleDataResponseCommand(message, sender)
    elseif command == self.SYNC.COMMANDS.ANNOUNCE then
        -- Announce new import
        self:HandleAnnounceCommand(message, sender)
    elseif command == self.SYNC.COMMANDS.VERSION then
        -- Version check (to be implemented)
        self:Debug("sync", "Version check from " .. sender .. " (not yet implemented)")
    -- New handlers for segmented sync
    elseif command == self.SYNC.COMMANDS.STRUCTURE_REQUEST then
        -- Structure request
        self:HandleStructureRequestCommand(rest, sender)
    elseif command == self.SYNC.COMMANDS.STRUCTURE_RESPONSE then
        -- Structure response
        self:HandleStructureResponseCommand(message, sender)
    elseif command == self.SYNC.COMMANDS.SECTION_REQUEST then
        -- Section request
        self:HandleSectionRequestCommand(rest, sender)
    elseif command == self.SYNC.COMMANDS.SECTION_RESPONSE then
        -- Section response
        self:HandleSectionResponseCommand(message, sender)
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
        
        -- Use segmented sync if available, otherwise fall back to legacy sync
        if self.SYNC.useSegmentedSync and self.RequestStructureSync then
            self:Debug("sync", "Using segmented sync for announced data")
            self:RequestStructureSync(timestamp)
        else
            self:Debug("sync", "Falling back to legacy sync for announced data")
            self:RequestDataSync(timestamp)
        end
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
        
        -- Get compressed data
        local compressedData = nil
        
        -- Use segmented sync if available
        if self.SYNC.useSegmentedSync and self.RequestStructureSync then
            self:Debug("sync", "Redirecting to segmented sync for response")
            -- We will redirect to segmented sync by sending structure instead
            if self.HandleStructureRequestCommand then
                self:HandleStructureRequestCommand(message, sender)
            end
            return
        -- Otherwise generate compressed data on the fly
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

-- NEW FUNCTIONS FOR SEGMENTED SYNC

-- Request structure data from the group
function TWRA:RequestStructureSync(timestamp)
    self:Debug("sync", "Requesting structure data, timestamp: " .. timestamp)
    
    -- Format: SREQ:timestamp
    local message = string.format("%s:%d", self.SYNC.COMMANDS.STRUCTURE_REQUEST, timestamp)
    
    -- Store pending timestamp for validation
    self.SYNC.pendingTimestamp = timestamp
    
    -- Send the request
    self:SendAddonMessage(message)
    
    -- Initialize our section cache if needed
    self.SYNC.sectionCache = self.SYNC.sectionCache or {}
    
    -- Clear any previous cache with different timestamp
    if self.SYNC.cachedTimestamp ~= timestamp then
        self.SYNC.sectionCache = {}
        self.SYNC.cachedTimestamp = timestamp
    end
    
    return true
end

-- Handle structure request from other users
function TWRA:HandleStructureRequestCommand(message, sender)
    self:Debug("sync", "Received structure request from: " .. sender)
    
    -- Parse the timestamp
    local timestamp = tonumber(message) or 0
    
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
                   .. timestamp .. "), sending structure to " .. sender)
        
        -- Get compressed structure data
        local structureData = nil
        
        -- Try to get from segmented compression first
        if self.GetCompressedStructure then
            structureData = self:GetCompressedStructure()
            self:Debug("sync", "Using compressed structure data")
        else
            self:Debug("sync", "GetCompressedStructure not available")
        end
        
        -- Send the response if we have data
        if structureData then
            self:Debug("sync", "Sending structure response to " .. sender .. " with timestamp " .. ourTimestamp)
            self:SendStructureResponse(structureData, ourTimestamp)
        else
            self:Debug("error", "Failed to get compressed structure data for " .. sender)
        end
    else
        self:Debug("sync", "Our timestamp (" .. ourTimestamp .. ") is older than requested (" 
                   .. timestamp .. "), not sending data to " .. sender)
    end
end

-- Send structure response to group
function TWRA:SendStructureResponse(structureData, timestamp)
    self:Debug("sync", "Sending structure response with timestamp: " .. timestamp)
    
    -- Format: SRESP:timestamp:compressedStructure
    local message = string.format("%s:%d:%s", 
        self.SYNC.COMMANDS.STRUCTURE_RESPONSE,
        timestamp,
        structureData)
        
    -- Check message length
    if string.len(message) <= 254 then  -- Safe limit for addon messages
        self:Debug("sync", "Sending structure response (" .. 
                  string.len(structureData) .. " bytes)")
        self:SendAddonMessage(message)
        return true
    else
        self:Debug("error", "Structure data too large (" .. 
                  string.len(message) .. " bytes)")
        
        -- Try to use chunk manager if available
        if self.chunkManager then
            self:Debug("sync", "Using ChunkManager to send structure data")
            local prefix = string.format("%s:%d:", 
                self.SYNC.COMMANDS.STRUCTURE_RESPONSE, timestamp)
            
            self.chunkManager:SendChunkedMessage(structureData, prefix)
            return true
        end
    end
    
    return false
end

-- Handle structure response from other users
function TWRA:HandleStructureResponseCommand(message, sender)
    self:Debug("sync", "Received structure response from: " .. sender)
    
    -- Extract timestamp and data
    local parts = self:SplitString(message, ":")
    if table.getn(parts) < 3 then
        self:Debug("sync", "Malformed structure response from " .. sender)
        return
    end
    
    -- Extract timestamp
    local timestamp = tonumber(parts[2])
    
    -- Check for chunked data
    if parts[3] == "CHUNKED" then
        -- Only handle if chunk manager is available
        if self.chunkManager then
            self:Debug("sync", "Using chunk manager for chunked structure response")
            self.chunkManager:ProcessChunkHeader(message, sender)
        else
            self:Debug("error", "Cannot process chunked structure without chunk manager")
        end
        return
    end
    
    -- Extract structure data (everything after SRESP:timestamp:)
    local prefix = parts[1] .. ":" .. parts[2] .. ":"
    local prefixLen = string.len(prefix)
    local structureData = string.sub(message, prefixLen + 1)
    
    -- Debug
    self:Debug("sync", "Processing structure data (" .. string.len(structureData) .. " bytes)")
    
    -- Validate timestamp
    if timestamp ~= self.SYNC.pendingTimestamp then
        self:Debug("sync", "Timestamp mismatch: expected " .. (self.SYNC.pendingTimestamp or "nil") ..
                  ", got " .. timestamp)
        return
    end
    
    -- Process structure data
    self:ProcessStructureData(structureData, timestamp, sender)
end

-- Process structure data received via sync
function TWRA:ProcessStructureData(structureData, timestamp, sender)
    self:Debug("sync", "Processing structure data from " .. sender)
    
    -- Initialize compression if needed
    if not self.LibCompress and self.InitializeCompression then
        self:InitializeCompression()
    end
    
    -- Decompress structure data
    local structureTable = nil
    if self.DecompressStructureData then
        structureTable = self:DecompressStructureData(structureData)
    else
        self:Debug("error", "DecompressStructureData function not available")
        return false
    end
    
    if not structureTable then
        self:Debug("error", "Failed to decompress structure data from " .. sender)
        return false
    end
    
    -- Process the structure table
    local sectionCount = 0
    for i, sectionName in pairs(structureTable) do
        if type(i) == "number" and type(sectionName) == "string" then
            sectionCount = sectionCount + 1
        end
    end
    
    self:Debug("sync", "Processed structure with " .. sectionCount .. " sections")
    
    -- Store structure in cache
    self.SYNC.structureTable = structureTable
    self.SYNC.cachedTimestamp = timestamp
    self.SYNC.sectionCache = self.SYNC.sectionCache or {}
    
    -- Request each section
    local sectionsRequested = 0
    for i, _ in pairs(structureTable) do
        if type(i) == "number" then
            -- Add delay based on section index to prevent flooding
            local delay = (i - 1) * 0.2 -- 200ms between requests
            self:ScheduleTimer(function()
                self:RequestSectionSync(i, timestamp)
            end, delay)
            sectionsRequested = sectionsRequested + 1
        end
    end
    
    self:Debug("sync", "Scheduled requests for " .. sectionsRequested .. " sections")
    
    -- Notify user
    DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA:|r Receiving raid assignments from " .. sender .. 
                                 " (" .. sectionCount .. " sections)")
    
    return true
end

-- Request a specific section from the group
function TWRA:RequestSectionSync(sectionIndex, timestamp)
    self:Debug("sync", "Requesting section " .. sectionIndex .. ", timestamp: " .. timestamp)
    
    -- Format: SECREQ:timestamp:sectionIndex
    local message = string.format("%s:%d:%d", 
                                 self.SYNC.COMMANDS.SECTION_REQUEST,
                                 timestamp,
                                 sectionIndex)
    
    -- Send the request
    self:SendAddonMessage(message)
    
    return true
end

-- Handle section request from other users
function TWRA:HandleSectionRequestCommand(message, sender)
    self:Debug("sync", "Received section request from: " .. sender)
    
    -- Parse the message: timestamp:sectionIndex
    local parts = self:SplitString(message, ":")
    if table.getn(parts) < 2 then
        self:Debug("sync", "Malformed section request from " .. sender)
        return
    end
    
    -- Extract data
    local timestamp = tonumber(parts[1])
    local sectionIndex = tonumber(parts[2])
    
    if not timestamp or not sectionIndex then
        self:Debug("sync", "Invalid section request parameters from " .. sender)
        return
    end
    
    -- Check if we have data to share
    if not TWRA_Assignments or not TWRA_Assignments.data or
       not TWRA_Assignments.data[sectionIndex] then
        self:Debug("sync", "Section " .. sectionIndex .. " not available to send to " .. sender)
        return
    end
    
    -- Get our current timestamp
    local ourTimestamp = TWRA_Assignments.timestamp or 0
    
    -- Only respond if our data is newer or matches the request
    if ourTimestamp >= timestamp then
        self:Debug("sync", "Our timestamp (" .. ourTimestamp .. ") matches or is newer than requested (" 
                   .. timestamp .. "), sending section " .. sectionIndex .. " to " .. sender)
        
        -- Get compressed section data
        local sectionData = nil
        
        -- Try to get from segmented compression
        if self.GetCompressedSection then
            sectionData = self:GetCompressedSection(sectionIndex)
            self:Debug("sync", "Using compressed section data")
        else
            self:Debug("sync", "GetCompressedSection not available")
        end
        
        -- Send the response if we have data
        if sectionData then
            self:Debug("sync", "Sending section response to " .. sender .. " for section " .. sectionIndex)
            self:SendSectionResponse(sectionData, timestamp, sectionIndex)
        else
            self:Debug("error", "Failed to get compressed section data for " .. sender)
        end
    else
        self:Debug("sync", "Our timestamp (" .. ourTimestamp .. ") is older than requested (" 
                   .. timestamp .. "), not sending data to " .. sender)
    end
end

-- Send section response to group
function TWRA:SendSectionResponse(sectionData, timestamp, sectionIndex)
    self:Debug("sync", "Sending section " .. sectionIndex .. " response with timestamp: " .. timestamp)
    
    -- Format: SECRESP:timestamp:sectionIndex:compressedSection
    local message = string.format("%s:%d:%d:%s", 
        self.SYNC.COMMANDS.SECTION_RESPONSE,
        timestamp,
        sectionIndex,
        sectionData)
        
    -- Check message length
    if string.len(message) <= 254 then  -- Safe limit for addon messages
        self:Debug("sync", "Sending section response (" .. 
                  string.len(sectionData) .. " bytes)")
        self:SendAddonMessage(message)
        return true
    else
        self:Debug("error", "Section data too large (" .. 
                  string.len(message) .. " bytes)")
        
        -- Try to use chunk manager if available
        if self.chunkManager then
            self:Debug("sync", "Using ChunkManager to send section data")
            local prefix = string.format("%s:%d:%d:", 
                self.SYNC.COMMANDS.SECTION_RESPONSE, timestamp, sectionIndex)
            
            self.chunkManager:SendChunkedMessage(sectionData, prefix)
            return true
        end
    end
    
    return false
end

-- Handle section response from other users
function TWRA:HandleSectionResponseCommand(message, sender)
    self:Debug("sync", "Received section response from: " .. sender)
    
    -- Extract data
    local parts = self:SplitString(message, ":")
    if table.getn(parts) < 4 then
        self:Debug("sync", "Malformed section response from " .. sender)
        return
    end
    
    -- Extract timestamp and section index
    local timestamp = tonumber(parts[2])
    local sectionIndex = tonumber(parts[3])
    
    if not timestamp or not sectionIndex then
        self:Debug("sync", "Invalid section response parameters from " .. sender)
        return
    end
    
    -- Check for chunked data
    if parts[4] == "CHUNKED" then
        -- Only handle if chunk manager is available
        if self.chunkManager then
            self:Debug("sync", "Using chunk manager for chunked section response")
            self.chunkManager:ProcessChunkHeader(message, sender)
        else
            self:Debug("error", "Cannot process chunked section without chunk manager")
        end
        return
    end
    
    -- Extract section data (everything after SECRESP:timestamp:sectionIndex:)
    local prefix = parts[1] .. ":" .. parts[2] .. ":" .. parts[3] .. ":"
    local prefixLen = string.len(prefix)
    local sectionData = string.sub(message, prefixLen + 1)
    
    -- Debug
    self:Debug("sync", "Processing section data for section " .. sectionIndex .. 
               " (" .. string.len(sectionData) .. " bytes)")
    
    -- Validate timestamp
    if timestamp ~= self.SYNC.cachedTimestamp then
        self:Debug("sync", "Timestamp mismatch: expected " .. (self.SYNC.cachedTimestamp or "nil") ..
                  ", got " .. timestamp)
        return
    end
    
    -- Process section data
    self:ProcessSectionData(sectionData, timestamp, sectionIndex, sender)
end

-- Process section data received via sync
function TWRA:ProcessSectionData(sectionData, timestamp, sectionIndex, sender)
    self:Debug("sync", "Processing section " .. sectionIndex .. " data from " .. sender)
    
    -- Initialize compression if needed
    if not self.LibCompress and self.InitializeCompression then
        self:InitializeCompression()
    end
    
    -- Decompress section data
    local sectionTable = nil
    if self.DecompressSectionData then
        sectionTable = self:DecompressSectionData(sectionData)
    else
        self:Debug("error", "DecompressSectionData function not available")
        return false
    end
    
    if not sectionTable then
        self:Debug("sync", "Failed to decompress section " .. sectionIndex .. " data from " .. sender)
        return false
    end
    
    -- Store section in cache
    self.SYNC.sectionCache = self.SYNC.sectionCache or {}
    self.SYNC.sectionCache[sectionIndex] = sectionTable
    
    -- Check if we have all sections
    local missingAnySection = false
    local sectionCount = 0
    
    -- Count expected sections from structure
    if self.SYNC.structureTable then
        for i, _ in pairs(self.SYNC.structureTable) do
            if type(i) == "number" then
                sectionCount = sectionCount + 1
                if not self.SYNC.sectionCache[i] then
                    missingAnySection = true
                    break
                end
            end
        end
    else
        self:Debug("error", "Missing structure table in section processor")
        return false
    end
    
    -- If we have all sections, build the complete data
    if not missingAnySection and sectionCount > 0 then
        self:Debug("sync", "All sections received (" .. sectionCount .. "), reassembling data")
        self:ReassembleDataFromSections(timestamp, sender)
    else
        self:Debug("sync", "Still missing sections (received: " .. 
                  self:GetTableSize(self.SYNC.sectionCache) .. "/" .. sectionCount .. ")")
    end
    
    return true
end

-- Reassemble complete data from cached sections
function TWRA:ReassembleDataFromSections(timestamp, sender)
    self:Debug("sync", "Reassembling complete data from sections")
    
    -- Create the new assignments structure
    local newAssignments = {
        data = {},
        timestamp = timestamp,
        version = 2
    }
    
    -- Add all sections
    for sectionIndex, sectionData in pairs(self.SYNC.sectionCache) do
        newAssignments.data[sectionIndex] = sectionData
    end
    
    -- Get pending section for navigation
    local pendingSection = self.SYNC.pendingSection
    
    -- Apply the new data
    TWRA_Assignments = newAssignments
    
    -- Store in segmented format for future sync
    if self.StoreSegmentedData then
        self:Debug("sync", "Storing reassembled data in segmented format")
        self:StoreSegmentedData()
    end
    
    -- Important: rebuild navigation with new data
    self:Debug("sync", "Rebuilding navigation with new data")
    if self.RebuildNavigation then
        self:RebuildNavigation()
    else
        self:Debug("error", "RebuildNavigation function not found")
    end
    
    -- Process player information
    self:Debug("sync", "Processing player information")
    if self.RefreshPlayerInfo then
        self:RefreshPlayerInfo()
    elseif self.ProcessPlayerInfo then
        self:ProcessPlayerInfo()
    else
        self:Debug("error", "Neither RefreshPlayerInfo nor ProcessPlayerInfo function found")
    end
    
    -- Navigate to the pending section or first section
    local sectionToUse = pendingSection or 1
    self:Debug("sync", "Navigating to section " .. sectionToUse)
    
    if self.NavigateToSection then
        self:NavigateToSection(sectionToUse, "fromSync")
    else
        self:Debug("error", "NavigateToSection function not found")
    end
    
    -- Clear section data cache
    self.SYNC.sectionCache = {}
    self.SYNC.structureTable = nil
    self.SYNC.cachedTimestamp = nil
    self.SYNC.pendingSection = nil
    
    -- Notify user
    DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA:|r Synchronized raid assignments from " .. sender)
    
    return true
end

-- Legacy function to request full data sync (for backward compatibility)
function TWRA:RequestDataSync(timestamp)
    self:Debug("sync", "Requesting data sync with timestamp: " .. timestamp)
    
    -- Store the pending timestamp
    self.SYNC.pendingTimestamp = timestamp
    
    -- Format message
    local message = string.format("%s:%d", self.SYNC.COMMANDS.DATA_REQUEST, timestamp)
    
    -- Send the request
    return self:SendAddonMessage(message)
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
    
    -- Initialize segmented sync flag based on compressed storage availability
    self.SYNC.useSegmentedSync = (self.StoreSegmentedData ~= nil and self.GetCompressedSection ~= nil)
    self:Debug("sync", "Segmented sync " .. (self.SYNC.useSegmentedSync and "enabled" or "disabled"))
    
    self:Debug("sync", "Sync handlers initialized")
    return true
end
