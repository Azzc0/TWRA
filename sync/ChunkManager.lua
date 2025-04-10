-- TWRA Chunk Manager
-- Manages splitting and reassembling large messages
TWRA = TWRA or {}

-- Initialize chunk management system
function TWRA:InitChunkManager()
    -- Ensure we have a place to store chunked data
    self.chunkManager = {
        pendingTransfers = {},  -- Store all currently pending transfers
        maxChunkSize = 180,     -- Maximum chunk size (conservative)
        transferTimeout = 30,   -- How long to wait for a complete transfer (seconds)
        cleanupInterval = 60    -- How often to clean up stale transfers (seconds)
    }
    
    -- Start periodic cleanup of stale transfers
    self:ScheduleRepeatingTimer(function() 
        self:CleanupStaleTransfers() 
    end, self.chunkManager.cleanupInterval)
    
    self:Debug("sync", "ChunkManager initialized")
    return true
end

-- Split a large message into manageable chunks
function TWRA:SplitIntoChunks(message, commandPrefix, timestamp)
    if not message or message == "" then
        self:Debug("error", "Cannot split empty message into chunks")
        return nil
    end
    
    -- Ensure proper Base64 padding before splitting
    local dataLen = string.len(message)
    local remainder = dataLen % 4
    while remainder > 0 and remainder < 4 do
        message = message .. "="
        remainder = remainder + 1
        self:Debug("sync", "Added padding character to Base64 data before chunking")
    end
    
    local chunks = {}
    local messageLength = string.len(message)
    local chunkSize = self.chunkManager.maxChunkSize or 180
    
    -- Calculate how many chunks we'll need
    local totalChunks = math.ceil(messageLength / chunkSize)
    self:Debug("sync", "Splitting message into " .. totalChunks .. " chunks")
    
    -- Create header message (doesn't contain actual data)
    local headerMessage = string.format("%s:%d:CHUNKED:%d:%d", 
        commandPrefix, 
        timestamp,
        messageLength,  -- total message size
        totalChunks     -- number of chunks
    )
    chunks[0] = headerMessage  -- Use index 0 for the header
    
    -- Split message into chunks
    local position = 1
    for i = 1, totalChunks do
        local endPos = math.min(position + chunkSize - 1, messageLength)
        local chunkData = string.sub(message, position, endPos)
        
        -- Create chunk message
        local chunkMessage = string.format("%s:%d:CHUNK:%d:%d:%s", 
            commandPrefix,
            timestamp,
            i,              -- chunk number
            totalChunks,    -- total chunks
            chunkData       -- chunk data
        )
        
        -- Add to chunks table
        chunks[i] = chunkMessage
        position = endPos + 1
    end
    
    return chunks, totalChunks
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
