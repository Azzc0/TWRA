-- TWRA Chunk Manager
-- Manages splitting and reassembling large messages
TWRA = TWRA or {}
TWRA.chunkManager = TWRA.chunkManager or {}

-- Initialize the chunk manager with appropriate settings
function TWRA.chunkManager:Initialize()
    -- Maximum message size, leaving room for headers
    -- Maximum allowed is 2047, but we use 1800 to be safe
    self.maxChunkSize = 1800
    
    -- Initialize tracking tables
    self.pendingChunks = {}  -- For outgoing chunks
    self.receivingChunks = {} -- For incoming chunks
    self.processedTransfers = {} -- Track completed transfers
    self.storedChunkData = {} -- Store assembled chunk data for retrieval
    
    -- Debug that we're initialized
    TWRA:Debug("sync", "ChunkManager initialized with chunk size " .. self.maxChunkSize)
    TWRA:Debug("chunk", "ChunkManager initialized with chunk size " .. self.maxChunkSize)
    
    return self
end

-- Generic function to chunk content with flexible communication options
-- @param data The content to chunk and send
-- @param comms Communication type ("RAID", "PARTY", "GUILD", "WHISPER", etc.)
-- @param target Target player name (required for WHISPER)
-- @param prefix Optional prefix to add before each chunk
-- @return transferId The ID of this chunked transfer
function TWRA.chunkManager:ChunkContent(data, comms, target, prefix)
    if not data then
        TWRA:Debug("error", "ChunkManager: No data to chunk")
        TWRA:Debug("chunk", "ChunkManager: No data to chunk")
        return false
    end
    
    -- Ensure we're initialized
    if not self.maxChunkSize then
        self:Initialize()
    end
    
    -- Calculate total size and chunks needed
    local dataLength = string.len(data)
    local totalChunks = math.ceil(dataLength / self.maxChunkSize)
    
    TWRA:Debug("sync", "ChunkManager: Chunking " .. dataLength .. " bytes into " .. totalChunks .. " chunks")
    TWRA:Debug("chunk", "ChunkManager: Chunking " .. dataLength .. " bytes into " .. totalChunks .. " chunks")
    
    -- Generate a unique transfer ID
    local transferId = tostring(time()) .. "-" .. tostring(math.random(10000, 99999))
    
    -- Determine communication channel
    local channel = comms or (GetNumRaidMembers() > 0 and "RAID" or 
                 (GetNumPartyMembers() > 0 and "PARTY" or nil))
    
    -- Validate channel and target if needed
    if not channel then
        TWRA:Debug("error", "ChunkManager: No valid channel available")
        TWRA:Debug("chunk", "ChunkManager: No valid channel available")
        return false
    end
    
    if channel == "WHISPER" and not target then
        TWRA:Debug("error", "ChunkManager: Target required for whisper")
        TWRA:Debug("chunk", "ChunkManager: Target required for whisper")
        return false
    end
    
    -- Send header message with total size
    local headerMessage = "CHUNKED:" .. dataLength .. ":" .. transferId .. ":" .. totalChunks
    if prefix then
        headerMessage = prefix .. headerMessage
    end
    
    -- Send the header message
    if channel == "WHISPER" then
        SendAddonMessage(TWRA.SYNC.PREFIX, headerMessage, channel, target)
    else
        SendAddonMessage(TWRA.SYNC.PREFIX, headerMessage, channel)
    end
    
    TWRA:Debug("sync", "ChunkManager: Sent header with transfer ID " .. transferId)
    TWRA:Debug("chunk", "ChunkManager: Sent header with transfer ID " .. transferId .. " via " .. channel .. " channel")
    TWRA:Debug("chunk", "ChunkManager: Header message: " .. headerMessage)
    
    -- Send all chunks immediately without using timers
    local position = 1
    
    for chunkNum = 1, totalChunks do
        -- Extract chunk data
        local endPos = math.min(position + self.maxChunkSize - 1, dataLength)
        local chunkData = string.sub(data, position, endPos)
        position = endPos + 1
        
        -- Create chunk message
        local chunkMessage = "CHUNK:" .. transferId .. ":" .. chunkNum .. ":" .. chunkData
        if prefix then
            chunkMessage = prefix .. chunkMessage
        end
        
        -- Send the chunk
        if channel == "WHISPER" then
            SendAddonMessage(TWRA.SYNC.PREFIX, chunkMessage, channel, target)
        else
            SendAddonMessage(TWRA.SYNC.PREFIX, chunkMessage, channel)
        end
        
        -- Debug chunk stats
        TWRA:Debug("sync", "ChunkManager: Sent chunk " .. chunkNum .. "/" .. totalChunks .. 
                   " for transfer " .. transferId)
        TWRA:Debug("chunk", "ChunkManager: Sent chunk " .. chunkNum .. "/" .. totalChunks .. 
                   " for transfer " .. transferId .. " with size " .. string.len(chunkData) .. " bytes")
        TWRA:Debug("chunk", "ChunkManager: Chunk data starts with: " .. string.sub(chunkData, 1, math.min(20, string.len(chunkData))) .. "...")
    end
    
    TWRA:Debug("sync", "ChunkManager: Completed sending all chunks for " .. transferId)
    TWRA:Debug("chunk", "ChunkManager: Completed sending all chunks for " .. transferId .. " via " .. channel)
    
    return transferId
end

-- Legacy function for backward compatibility
function TWRA.chunkManager:SendChunkedMessage(data, prefix, channel, target)
    TWRA:Debug("sync", "Using SendChunkedMessage (legacy) with prefix: " .. (prefix or "none"))
    TWRA:Debug("chunk", "Using SendChunkedMessage (legacy) with prefix: " .. (prefix or "none") .. " on channel: " .. (channel or "default"))
    return self:ChunkContent(data, channel, target, prefix)
end

-- Function to handle incoming chunk header
-- @param dataLength Total expected data length
-- @param transferId Unique ID for this transfer
-- @param totalChunks Number of chunks to expect
-- @param sender Who sent this header
function TWRA.chunkManager:HandleChunkHeader(dataLength, transferId, totalChunks, sender)
    -- Ensure we're initialized
    if not self.receivingChunks then
        TWRA:Debug("error", "ChunkManager not initialized properly in HandleChunkHeader. Initializing now.")
        self:Initialize()
    end
    
    if not transferId then
        TWRA:Debug("error", "ChunkManager: Invalid transfer ID in header")
        TWRA:Debug("chunk", "ChunkManager: Invalid transfer ID in header from sender: " .. (sender or "unknown"))
        return false
    end
    
    -- Check if we've already processed this transfer
    if self.processedTransfers and self.processedTransfers[transferId] then
        TWRA:Debug("sync", "ChunkManager: Already processed transfer " .. transferId .. ", ignoring")
        TWRA:Debug("chunk", "ChunkManager: Already processed transfer " .. transferId .. " from " .. (sender or "unknown") .. ", ignoring")
        return false
    end
    
    -- Ensure tables are initialized
    self.receivingChunks = self.receivingChunks or {}
    self.processedTransfers = self.processedTransfers or {}
    self.storedChunkData = self.storedChunkData or {}
    
    -- Initialize storage for this transfer
    self.receivingChunks[transferId] = {
        expected = tonumber(totalChunks) or 0,
        received = 0,
        chunks = {},
        dataLength = tonumber(dataLength) or 0,
        sender = sender,
        timestamp = GetTime()
    }
    
    TWRA:Debug("sync", "ChunkManager: Initialized receiving for transfer " .. transferId .. 
              " expecting " .. totalChunks .. " chunks")
    TWRA:Debug("chunk", "ChunkManager: Initialized receiving for transfer " .. transferId .. 
              " expecting " .. totalChunks .. " chunks of total size " .. dataLength .. " bytes from " .. (sender or "unknown"))
    
    -- Also log all existing transfers for debugging
    local receivingCount = 0
    local receivingInfo = ""
    for id, info in pairs(self.receivingChunks) do
        receivingCount = receivingCount + 1
        receivingInfo = receivingInfo .. id .. " (" .. info.received .. "/" .. info.expected .. "), "
    end
    
    TWRA:Debug("chunk", "ChunkManager: NOW receivingChunks contains " .. receivingCount .. " entries")
    TWRA:Debug("chunk", "ChunkManager: NOW Receiving transfers: " .. (receivingInfo ~= "" and receivingInfo or "none"))
    
    return true
end

-- Function to handle an incoming chunk's data
-- @param transferId ID of the transfer this chunk belongs to
-- @param chunkNum Number of this chunk in sequence
-- @param chunkData The actual chunk data
-- @return boolean True if transfer is complete, false otherwise
function TWRA.chunkManager:HandleChunkData(transferId, chunkNum, chunkData)
    -- Ensure we're initialized
    if not self.receivingChunks then
        TWRA:Debug("error", "ChunkManager not initialized properly. Initializing now.")
        self:Initialize()
    end
    
    -- Validate inputs
    if not transferId or not chunkNum or not chunkData then
        TWRA:Debug("error", "ChunkManager: Invalid chunk data received")
        TWRA:Debug("chunk", "ChunkManager: Invalid chunk data received - missing transferId, chunkNum, or chunkData")
        return false
    end
    
    -- Convert chunk number to number
    chunkNum = tonumber(chunkNum)
    if not chunkNum then
        TWRA:Debug("error", "ChunkManager: Invalid chunk number")
        TWRA:Debug("chunk", "ChunkManager: Invalid chunk number for transfer " .. transferId .. " - not a number")
        return false
    end
    
    -- Check if we have a record for this transfer
    if not self.receivingChunks[transferId] then
        TWRA:Debug("error", "ChunkManager: Received chunk for unknown transfer " .. transferId)
        TWRA:Debug("chunk", "ChunkManager: Received chunk #" .. chunkNum .. " for unknown transfer " .. transferId .. " with data size " .. string.len(chunkData))
        
        -- Check if this is for a pending chunked section
        if TWRA.SYNC and TWRA.SYNC.pendingChunkedSections then
            local foundSection = nil
            for sectionIndex, info in pairs(TWRA.SYNC.pendingChunkedSections) do
                if info.transferId == transferId then
                    foundSection = sectionIndex
                    TWRA:Debug("sync", "Found pending chunked section " .. sectionIndex .. " for transfer " .. transferId .. " but header missing, creating header")
                    TWRA:Debug("chunk", "Found pending chunked section " .. sectionIndex .. " for transfer " .. transferId .. " but header missing, creating header")
                    break
                end
            end
            
            if foundSection then
                -- Create a header entry for this transfer
                self.receivingChunks[transferId] = {
                    expected = 0,  -- We don't know how many chunks to expect yet
                    received = 0,
                    chunks = {},
                    dataLength = 0,
                    timestamp = GetTime(),
                    pendingSection = foundSection
                }
                TWRA:Debug("chunk", "ChunkManager: Created artificial header for transfer " .. transferId .. " for pending section " .. foundSection)
            else
                TWRA:Debug("chunk", "ChunkManager: No pending section found for transfer " .. transferId .. " - discarding chunk")
                return false
            end
        else
            TWRA:Debug("chunk", "ChunkManager: No TWRA.SYNC.pendingChunkedSections table found - discarding chunk for " .. transferId)
            return false
        end
    end
    
    -- Store this chunk
    self.receivingChunks[transferId].chunks[chunkNum] = chunkData
    self.receivingChunks[transferId].received = self.receivingChunks[transferId].received + 1
    
    -- Update last activity time
    self.receivingChunks[transferId].timestamp = GetTime()
    
    -- Debug progress periodically or on completion
    local received = self.receivingChunks[transferId].received
    local expected = self.receivingChunks[transferId].expected
    
    TWRA:Debug("chunk", "ChunkManager: Received chunk #" .. chunkNum .. " for transfer " .. transferId .. 
              " with data size " .. string.len(chunkData) .. " bytes (total received: " .. received .. ")")
    
    if expected > 0 then
        -- Only log periodically to prevent spam
        local shouldLog = false
        
        -- Log on completion
        if received == expected then
            shouldLog = true
        end
        
        -- Log every 5th chunk
        if math.floor(received / 5) * 5 == received then
            shouldLog = true
        end
        
        -- Log based on conditions
        if shouldLog then
            local progress = math.floor((received / expected) * 100)
            TWRA:Debug("sync", "ChunkManager: Transfer " .. transferId .. " at " .. 
                      progress .. "% (" .. received .. "/" .. expected .. " chunks)")
            TWRA:Debug("chunk", "ChunkManager: Transfer " .. transferId .. " at " .. 
                      progress .. "% (" .. received .. "/" .. expected .. " chunks)")
        end
    else
        -- If we don't know how many to expect, just log periodically
        if math.floor(received / 5) * 5 == received then
            TWRA:Debug("sync", "ChunkManager: Received " .. received .. " chunks for transfer " .. transferId)
            TWRA:Debug("chunk", "ChunkManager: Received " .. received .. " chunks for transfer " .. transferId .. " (expected count unknown)")
        end
    end
    
    -- Check if transfer is complete
    if expected > 0 and received == expected then
        TWRA:Debug("sync", "ChunkManager: Transfer " .. transferId .. " has received all expected chunks")
        TWRA:Debug("sync", "CRITICAL: This transfer is COMPLETE - expected: " .. expected .. ", received: " .. received)
        TWRA:Debug("chunk", "ChunkManager: Transfer " .. transferId .. " has received all expected chunks (" .. received .. "/" .. expected .. ")")
        
        -- If this is for a pending chunked section, mark it as ready for processing
        if self.receivingChunks[transferId].pendingSection then
            local sectionIndex = self.receivingChunks[transferId].pendingSection
            
            -- Assemble the chunks
            local assembled = ""
            for i = 1, expected do
                if self.receivingChunks[transferId].chunks[i] then
                    assembled = assembled .. self.receivingChunks[transferId].chunks[i]
                else
                    TWRA:Debug("error", "ChunkManager: Missing chunk " .. i .. " for section " .. sectionIndex)
                    TWRA:Debug("chunk", "ChunkManager: Missing chunk " .. i .. " for section " .. sectionIndex .. " of transfer " .. transferId)
                    return false
                end
            end
            
            -- Store the assembled data in the compressed assignments
            if TWRA_CompressedAssignments and TWRA_CompressedAssignments.sections then
                TWRA_CompressedAssignments.sections[sectionIndex] = assembled
                TWRA:Debug("sync", "ChunkManager: Stored assembled chunk data for section " .. sectionIndex)
                TWRA:Debug("chunk", "ChunkManager: Stored assembled chunk data for section " .. sectionIndex .. " with total size " .. string.len(assembled) .. " bytes")
                
                -- Remove from pending chunked sections
                if TWRA.SYNC and TWRA.SYNC.pendingChunkedSections then
                    TWRA.SYNC.pendingChunkedSections[sectionIndex] = nil
                    TWRA:Debug("sync", "ChunkManager: Removed section " .. sectionIndex .. " from pending chunked sections")
                    TWRA:Debug("chunk", "ChunkManager: Removed section " .. sectionIndex .. " from pending chunked sections")
                end
                
                -- Mark this section for processing
                if TWRA.ProcessSectionData then
                    TWRA:Debug("sync", "ChunkManager: Scheduling processing for section " .. sectionIndex)
                    TWRA:Debug("chunk", "ChunkManager: Scheduling processing for section " .. sectionIndex)
                    TWRA:ScheduleTimer(function()
                        TWRA:ProcessSectionData(sectionIndex)
                    end, 0.1)
                end
            end
        else
            -- Automatically process chunks when all are received
            -- THIS IS THE CRITICAL FIX - ensure we're processing and storing the data
            TWRA:Debug("sync", "CRITICAL: All chunks received, processing immediately...")
            self:ProcessChunks(transferId, false)
            TWRA:Debug("sync", "CRITICAL: Processing complete!")
        end
        
        -- FORCE PROCESSING HERE AS WELL TO SEE IF IT HELPS
        TWRA:Debug("sync", "CRITICAL: Forcing additional processing attempt...")
        self:ProcessChunks(transferId, false)
        
        -- Important debug to verify the transfer is in storedChunkData
        if self.storedChunkData and self.storedChunkData[transferId] then
            TWRA:Debug("sync", "CRITICAL: Data successfully stored in storedChunkData!")
        else
            TWRA:Debug("sync", "CRITICAL: Data NOT FOUND in storedChunkData after processing!")
        end
        
        TWRA:Debug("sync", "CRITICAL: Returning TRUE from HandleChunkData!")
        return true  -- This return statement is critical!
    end
    
    TWRA:Debug("sync", "CRITICAL: Transfer not yet complete - expected: " .. expected .. ", received: " .. received)
    return false
end

-- Process chunks for a given transfer ID and return the assembled data
-- @param transferId The ID of the transfer to process
-- @param retrieveNow Whether to return the data immediately (true) or store for later retrieval (false)
-- @return assembled data if successful and retrieveNow is true, or true if stored successfully, false otherwise
function TWRA.chunkManager:ProcessChunks(transferId, retrieveNow)
    -- Default retrieveNow to true for backward compatibility
    retrieveNow = (retrieveNow ~= false)
    
    -- Validate transfer ID
    if not transferId or not self.receivingChunks[transferId] then
        -- Changed from error to chunk debug category since this is expected behavior when forcing additional processing
        TWRA:Debug("chunk", "ChunkManager: Cannot process unknown transfer " .. tostring(transferId))
        return false
    end
    
    local transfer = self.receivingChunks[transferId]
    
    -- Check if all chunks have been received
    if transfer.received < transfer.expected then
        TWRA:Debug("error", "ChunkManager: Cannot process incomplete transfer " .. 
                  transferId .. " (" .. transfer.received .. "/" .. transfer.expected .. " chunks)")
        return false
    end
    
    -- Assemble the chunks in order
    local assembled = ""
    for i = 1, transfer.expected do
        if not transfer.chunks[i] then
            TWRA:Debug("error", "ChunkManager: Missing chunk " .. i .. " in transfer " .. transferId)
            return false
        end
        assembled = assembled .. transfer.chunks[i]
    end
    
    -- Verify the assembled length
    if string.len(assembled) ~= transfer.dataLength then
        TWRA:Debug("error", "ChunkManager: Length mismatch in assembled data for " .. 
                  transferId .. " (expected " .. transfer.dataLength .. 
                  ", got " .. string.len(assembled) .. ")")
    end
    
    -- Store the assembled data for later retrieval
    self.storedChunkData[transferId] = {
        data = assembled,
        timestamp = GetTime(),
        sender = transfer.sender,
        dataLength = string.len(assembled)
    }
    
    -- Mark as processed 
    self.processedTransfers[transferId] = GetTime()
    self.receivingChunks[transferId] = nil
    
    TWRA:Debug("sync", "ChunkManager: Successfully processed transfer " .. transferId)
    TWRA:Debug("chunk", "ChunkManager: Successfully processed transfer " .. transferId .. " and stored " .. 
               string.len(assembled) .. " bytes of data")
    
    -- Clean old processed transfers periodically
    self:CleanupOldTransfers()
    
    -- Return the assembled data if requested immediately, otherwise return success
    if retrieveNow then
        return assembled
    else
        return true
    end
end

-- Retrieve stored chunk data by transfer ID
-- @param transferId The ID of the transfer to retrieve
-- @param removeAfterRetrieval Whether to remove the data after retrieval (default: true)
-- @return The assembled data string if found, false otherwise
function TWRA.chunkManager:RetrieveChunkData(transferId, removeAfterRetrieval)
    -- Default to removing data after retrieval
    if removeAfterRetrieval == nil then
        removeAfterRetrieval = true
    end
    
    TWRA:Debug("chunk", "----- CHUNK TEST R: Retrieving for transfer ID " .. transferId .. " -----")
    
    -- Check if we need to process chunks first
    if self.receivingChunks[transferId] and self:IsTransferComplete(transferId) then
        TWRA:Debug("chunk", "ChunkManager: Transfer " .. transferId .. " complete but not processed. Processing now.")
        local success = self:ProcessChunks(transferId, false)
        TWRA:Debug("chunk", "ChunkManager: Processing result: " .. (success and "SUCCESS" or "FAILED"))
    end
    
    -- Check if data exists in stored chunk data
    if not self.storedChunkData[transferId] then
        TWRA:Debug("error", "ChunkManager: No stored data found for transfer " .. tostring(transferId))
        TWRA:Debug("chunk", "ChunkManager: No stored data found for transfer " .. tostring(transferId))
        
        -- Try to process chunks one more time if they exist but aren't stored
        if self.receivingChunks[transferId] then
            TWRA:Debug("chunk", "ChunkManager: Attempting to process chunks again for transfer " .. transferId)
            
            -- Force processing regardless of completion status
            local success = false
            local transfer = self.receivingChunks[transferId]
            
            -- Only process if we have received any chunks
            if transfer.received > 0 then
                -- If expected is not set but we have chunks, estimate it based on received
                if transfer.expected == 0 then
                    transfer.expected = transfer.received
                    TWRA:Debug("chunk", "ChunkManager: Setting expected chunks to " .. transfer.received .. " based on received count")
                end
                
                success = self:ProcessChunks(transferId, false)
            end
            
            -- Check again after processing
            if self.storedChunkData[transferId] then
                TWRA:Debug("chunk", "ChunkManager: Successfully processed chunks after retry for " .. transferId)
            else
                TWRA:Debug("chunk", "ChunkManager: Failed to process chunks after retry for " .. transferId .. 
                           " (ProcessChunks result: " .. (success and "SUCCESS" or "FAILED") .. ")")
                
                -- Check if chunks are missing or incomplete
                if self.receivingChunks[transferId] then
                    local transfer = self.receivingChunks[transferId]
                    TWRA:Debug("chunk", "ChunkManager: Transfer " .. transferId .. " has " .. 
                               transfer.received .. "/" .. transfer.expected .. " chunks received")
                    
                    -- List all available chunks
                    local chunkList = ""
                    for i = 1, transfer.expected do
                        if transfer.chunks[i] then
                            chunkList = chunkList .. i .. ","
                        end
                    end
                    TWRA:Debug("chunk", "ChunkManager: Available chunks: " .. chunkList)
                end
            end
        end
        
        -- Check one more time after potentially processing
        if not self.storedChunkData[transferId] then
            local availableTransfers = ""
            local transferCount = 0
            for id, _ in pairs(self.storedChunkData) do
                transferCount = transferCount + 1
                if availableTransfers ~= "" then
                    availableTransfers = availableTransfers .. ", "
                end
                availableTransfers = availableTransfers .. id
            end
            
            TWRA:Debug("chunk", "ChunkManager: storedChunkData contains " .. transferCount .. " entries")
            TWRA:Debug("chunk", "ChunkManager: Available transfers: " .. (availableTransfers ~= "" and availableTransfers or "none"))
            
            -- Check for receiving data
            local receivingCount = 0
            local receivingInfo = ""
            for id, info in pairs(self.receivingChunks) do
                receivingCount = receivingCount + 1
                receivingInfo = receivingInfo .. id .. " (" .. info.received .. "/" .. info.expected .. "), "
            end
            
            TWRA:Debug("chunk", "ChunkManager: receivingChunks contains " .. receivingCount .. " entries")
            TWRA:Debug("chunk", "ChunkManager: Receiving transfers: " .. (receivingInfo ~= "" and receivingInfo or "none"))
            
            return false
        end
    end
    
    -- Get the data
    local storedData = self.storedChunkData[transferId].data
    
    -- Add extra validation to ensure data exists and is valid
    if not storedData then
        TWRA:Debug("error", "ChunkManager: Retrieved nil data for transfer " .. transferId)
        return false
    end
    
    -- Log the retrieval
    TWRA:Debug("sync", "ChunkManager: Retrieved stored data for transfer " .. transferId)
    TWRA:Debug("chunk", "ChunkManager: Retrieved stored data for transfer " .. transferId .. 
               " with size " .. string.len(storedData) .. " bytes")
    TWRA:Debug("chunk", "ChunkManager: Data starts with: " .. string.sub(storedData, 1, math.min(20, string.len(storedData))) .. "...")
    
    -- Remove the data if requested
    if removeAfterRetrieval then
        self.storedChunkData[transferId] = nil
        TWRA:Debug("chunk", "ChunkManager: Removed stored data for transfer " .. transferId .. " after retrieval")
    end
    
    -- Return the actual string data
    return storedData
end

-- Clean up old transfer records to prevent memory bloat
function TWRA.chunkManager:CleanupOldTransfers()
    local now = GetTime()
    local cleanupThreshold = 3600 -- 1 hour
    
    -- Clean up processed transfers
    for id, timestamp in pairs(self.processedTransfers) do
        if (now - timestamp) > cleanupThreshold then
            self.processedTransfers[id] = nil
        end
    end
    
    -- Clean up stale receiving transfers
    for id, transfer in pairs(self.receivingChunks) do
        if (now - transfer.timestamp) > cleanupThreshold then
            TWRA:Debug("sync", "ChunkManager: Cleaning up stale transfer " .. id)
            self.receivingChunks[id] = nil
        end
    end
    
    -- Clean up old stored chunk data
    for id, data in pairs(self.storedChunkData) do
        if (now - data.timestamp) > cleanupThreshold then
            TWRA:Debug("sync", "ChunkManager: Cleaning up stored data for transfer " .. id)
            TWRA:Debug("chunk", "ChunkManager: Removing stored data for transfer " .. id .. " after " .. 
                       math.floor((now - data.timestamp)) .. " seconds")
            self.storedChunkData[id] = nil
        end
    end
end

-- Manual cleanup of stored chunk data for a specific transfer ID
-- @param transferId The ID of the transfer to clean up
function TWRA.chunkManager:RemoveStoredChunkData(transferId)
    if not transferId then
        return false
    end
    
    if self.storedChunkData[transferId] then
        TWRA:Debug("sync", "ChunkManager: Manually removing stored data for transfer " .. transferId)
        self.storedChunkData[transferId] = nil
        return true
    end
    
    return false
end

-- List all stored chunk data transfers (for debugging)
function TWRA.chunkManager:ListStoredTransfers()
    local count = 0
    local info = {}
    
    for id, data in pairs(self.storedChunkData) do
        count = count + 1
        local age = math.floor(GetTime() - data.timestamp)
        
        table.insert(info, {
            id = id,
            size = data.dataLength,
            age = age,
            sender = data.sender or "unknown"
        })
        
        TWRA:Debug("chunk", "Stored transfer: " .. id .. " - Size: " .. data.dataLength .. 
                   " bytes, Age: " .. age .. " sec, Sender: " .. (data.sender or "unknown"))
    end
    
    TWRA:Debug("sync", "ChunkManager has " .. count .. " stored transfers")
    
    return info
end

-- Check if a transfer is complete and ready to process
-- @param transferId The ID of the transfer to check
-- @return true if complete, false otherwise
function TWRA.chunkManager:IsTransferComplete(transferId)
    if not transferId or not self.receivingChunks[transferId] then
        return false
    end
    
    local transfer = self.receivingChunks[transferId]
    return (transfer.received == transfer.expected)
end

-- Get receiving progress for a transfer
-- @param transferId The ID of the transfer to check
-- @return progress percentage (0-100) or -1 if unknown
function TWRA.chunkManager:GetTransferProgress(transferId)
    if not transferId or not self.receivingChunks[transferId] then
        return -1
    end
    
    local transfer = self.receivingChunks[transferId]
    if transfer.expected == 0 then
        return 0
    end
    
    return math.floor((transfer.received / transfer.expected) * 100)
end

-- Cancel a pending transfer and clean up its resources
-- @param transferId The ID of the transfer to cancel
function TWRA.chunkManager:CancelTransfer(transferId)
    if not transferId then
        return false
    end
    
    if self.receivingChunks[transferId] then
        self.receivingChunks[transferId] = nil
        TWRA:Debug("sync", "ChunkManager: Canceled transfer " .. transferId)
        return true
    end
    
    return false
end