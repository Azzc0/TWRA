-- TWRA Chunk Manager
-- Manages splitting and reassembling large messages
TWRA = TWRA or {}

-- Initialize chunk management system
function TWRA:InitChunkManager()
    -- Ensure we have a place to store chunked data
    self.chunkManager = {
        pendingTransfers = {},  -- Store all currently pending transfers
        transferTimeout = 30,   -- How long to wait for a complete transfer (seconds)
        cleanupInterval = 60,   -- How often to clean up stale transfers (seconds)
        messageSizeLimit = 1800 -- Updated message size limit based on Turtle WoW testing (max is ~2042)
    }
    
    -- Start periodic cleanup of stale transfers
    self:ScheduleRepeatingTimer(function() 
        self:CleanupStaleTransfers() 
    end, self.chunkManager.cleanupInterval)
    
    self:Debug("sync", "ChunkManager initialized with message size limit: " .. self.chunkManager.messageSizeLimit)
    return true
end

-- Split a large message into manageable chunks
function TWRA:SplitMessageIntoChunks(message)
    local chunks = {}
    local chunkSize = self.chunkManager.messageSizeLimit or 2042 -- Use the tested/configured message size limit
    
    if string.len(message) <= chunkSize then
        return {message}
    end
    
    -- Calculate how many chunks we'll need
    local numChunks = math.ceil(string.len(message) / chunkSize)
    
    -- Prepare each chunk
    for i = 1, numChunks do
        local startPos = (i - 1) * chunkSize + 1
        local endPos = math.min(startPos + chunkSize - 1, string.len(message))
        local chunk = string.sub(message, startPos, endPos)
        table.insert(chunks, chunk)
    end
    
    -- Add chunk metadata to each chunk
    for i = 1, numChunks do
        chunks[i] = "C:" .. i .. ":" .. numChunks .. ":" .. chunks[i]
    end
    
    return chunks
end

-- Send a chunked message with delays between chunks
function TWRA:SendChunkedMessage(chunks, totalChunks)
    if not chunks or not totalChunks or totalChunks < 1 then
        self:Debug("error", "Invalid chunks to send")
        return false
    end
    
    -- Send header first
    if chunks[0] then 
        self:SendAddonMessage(chunks[0])
        self:Debug("sync", "Sent chunked message header")
    end
    
    -- Send chunks with delay between them
    local chunkDelay = 0.2  -- 0.2 seconds between chunks
    
    for i = 1, totalChunks do
        local delay = i * chunkDelay
        
        self:ScheduleTimer(function()
            if chunks[i] then
                self:SendAddonMessage(chunks[i])
                self:Debug("sync", "Sent chunk " .. i .. "/" .. totalChunks)
            else
                self:Debug("error", "Missing chunk " .. i .. " during sending")
            end
        end, delay)
    end
    
    return true
end

-- Process a chunked message header
function TWRA:ProcessChunkHeader(parts, message, sender)
    -- Validate header format
    if table.getn(parts) < 5 then
        self:Debug("error", "Malformed chunk header: " .. message)
        return false
    end
    
    -- Extract information
    local command = parts[1]
    local timestamp = tonumber(parts[2])
    local totalSize = tonumber(parts[4])
    local totalChunks = tonumber(parts[5])
    
    -- Create a unique transfer ID
    local transferId = command .. ":" .. timestamp .. ":" .. sender
    
    -- Initialize transfer record
    self.chunkManager.pendingTransfers[transferId] = {
        command = command,
        timestamp = timestamp,
        sender = sender,
        totalSize = totalSize,
        totalChunks = totalChunks,
        receivedChunks = 0,
        chunks = {},
        startTime = GetTime(),
        isComplete = false
    }
    
    self:Debug("sync", "Started new chunked transfer: " .. transferId .. 
            " (" .. totalChunks .. " chunks expected)")
    
    return true
end

-- Process an incoming data chunk
function TWRA:ProcessDataChunk(parts, message, sender)
    -- Validate chunk format
    if table.getn(parts) < 6 then
        self:Debug("error", "Malformed data chunk: " .. message)
        return false
    end
    
    -- Extract information
    local command = parts[1]
    local timestamp = tonumber(parts[2])
    local chunkNum = tonumber(parts[4])
    local totalChunks = tonumber(parts[5])
    
    -- Extract chunk data - everything after the header
    local prefix = parts[1] .. ":" .. parts[2] .. ":" .. parts[3] .. ":" .. 
                  parts[4] .. ":" .. parts[5] .. ":"
    local chunkData = string.sub(message, string.len(prefix) + 1)
    
    -- Create transfer ID
    local transferId = command .. ":" .. timestamp .. ":" .. sender
    
    -- Check if we have this transfer
    local transfer = self.chunkManager.pendingTransfers[transferId]
    if not transfer then
        self:Debug("error", "Received chunk for unknown transfer: " .. transferId)
        return false
    end
    
    -- Store the chunk
    transfer.chunks[chunkNum] = chunkData
    transfer.receivedChunks = transfer.receivedChunks + 1
    
    self:Debug("sync", "Received chunk " .. chunkNum .. "/" .. 
            transfer.totalChunks .. " for transfer " .. transferId)
    
    -- Check if transfer is complete
    if transfer.receivedChunks >= transfer.totalChunks then
        return self:FinalizeTransfer(transferId)
    end
    
    return true
end

-- Finalize a completed transfer
function TWRA:FinalizeTransfer(transferId)
    -- Get transfer record
    local transfer = self.chunkManager.pendingTransfers[transferId]
    if not transfer then
        self:Debug("error", "Cannot finalize unknown transfer: " .. transferId)
        return false
    end
    
    -- Check for missing chunks
    for i = 1, transfer.totalChunks do
        if not transfer.chunks[i] then
            self:Debug("error", "Missing chunk " .. i .. " in transfer " .. transferId)
            return false
        end
    end
    
    -- Assemble the complete data
    local assembledData = ""
    for i = 1, transfer.totalChunks do
        assembledData = assembledData .. transfer.chunks[i]
    end
    
    -- Check final size
    local finalSize = string.len(assembledData)
    if finalSize ~= transfer.totalSize then
        self:Debug("warning", "Assembled data size (" .. finalSize .. 
                ") doesn't match expected size (" .. transfer.totalSize .. ")")
    end
    
    -- Mark transfer as complete
    transfer.isComplete = true
    transfer.assembledData = assembledData
    
    self:Debug("sync", "Transfer completed: " .. transferId .. 
            " (assembled " .. finalSize .. " bytes)")
    
    -- Pass to appropriate handler based on command
    if transfer.command == self.SYNC.COMMANDS.DATA_RESPONSE then
        -- Process as data response
        self:ProcessReceivedData(assembledData, transfer.timestamp, transfer.sender)
    end
    
    -- Clean up this transfer
    self.chunkManager.pendingTransfers[transferId] = nil
    
    return true
end

-- Cleanup stale transfers
function TWRA:CleanupStaleTransfers()
    local now = GetTime()
    local count = 0
    
    for id, transfer in pairs(self.chunkManager.pendingTransfers) do
        -- Check if transfer has timed out
        if (now - transfer.startTime) > self.chunkManager.transferTimeout then
            self:Debug("sync", "Removing stale transfer: " .. id)
            self.chunkManager.pendingTransfers[id] = nil
            count = count + 1
        end
    end
    
    if count > 0 then
        self:Debug("sync", "Cleaned up " .. count .. " stale transfers")
    end
    
    return count
end
