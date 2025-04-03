-- TWRA Chunk Management
-- Handles splitting and reassembling large data transfers

TWRA = TWRA or {}

-- Initialize SYNC if it doesn't exist yet
TWRA.SYNC = TWRA.SYNC or {
    PREFIX = "TWRA",
    COMMANDS = {},
    chunks = {}  -- Initialize chunks array
}

-- Send data in chunks if needed
function TWRA:SendDataInChunks(data, timestamp)
    if not data then return end
    
    local dataLength = string.len(data)
    self:Debug("sync", "Preparing to send data (" .. dataLength .. " bytes)")
    
    -- Maximum chunk size (safe for addon communication)
    local maxChunkSize = 200  -- Reduced for safety
    
    -- If small enough, send as one message
    if dataLength <= maxChunkSize then
        local responseMsg = string.format("%s:%d:%s", 
            self.SYNC.COMMANDS.DATA_RESPONSE,
            timestamp,
            data)
        self:SendAddonMessage(responseMsg)
        self:Debug("sync", "Sent data in one part")
    else
        -- Send in chunks
        local chunks = math.ceil(dataLength / maxChunkSize)
        self:Debug("sync", "Splitting data into " .. chunks .. " chunks")
        
        for i = 1, chunks do
            local start = (i-1) * maxChunkSize + 1
            local finish = math.min(i * maxChunkSize, dataLength)
            local chunk = string.sub(data, start, finish)
            
            -- Format: DATA_RESPONSE:timestamp:chunkNum:totalChunks:chunkData
            local chunkMsg = string.format("%s:%d:%d:%d:%s", 
                self.SYNC.COMMANDS.DATA_RESPONSE,
                timestamp,
                i,
                chunks,
                chunk)
            
            -- Delay each chunk to avoid flooding
            local chunkDelay = (i-1) * 0.3  -- 300ms between chunks
            self:ScheduleTimer(function()
                self:SendAddonMessage(chunkMsg)
                self:Debug("sync", "Sent chunk " .. i .. " of " .. chunks)
            end, chunkDelay)
        end
    end
end

-- Process a received chunk
function TWRA:ProcessChunk(timestamp, chunkNum, totalChunks, chunkData, sender)
    -- Initialize specific timestamp chunk storage if needed
    if not self.SYNC.chunks[timestamp] then
        self.SYNC.chunks[timestamp] = {
            data = {},
            receivedChunks = 0,
            totalChunks = totalChunks,
            sender = sender
        }
    end
    
    -- Store this chunk
    self.SYNC.chunks[timestamp].data[chunkNum] = chunkData
    self.SYNC.chunks[timestamp].receivedChunks = self.SYNC.chunks[timestamp].receivedChunks + 1
    
    -- Calculate progress percentage
    local progress = math.floor((self.SYNC.chunks[timestamp].receivedChunks / totalChunks) * 100)
    self:Debug("sync", "Receiving data: " .. progress .. "% complete")
    
    -- If we have all chunks, combine and process
    if self.SYNC.chunks[timestamp].receivedChunks == totalChunks then
        self:Debug("sync", "All chunks received, combining data")
        
        -- Combine all chunks in correct order
        local completeData = ""
        for i = 1, totalChunks do
            if self.SYNC.chunks[timestamp].data[i] then
                completeData = completeData .. self.SYNC.chunks[timestamp].data[i]
            else
                self:Debug("error", "Missing chunk " .. i .. ", can't combine")
                return
            end
        end
        
        self:Debug("sync", "Combined data length: " .. string.len(completeData))
        
        -- Clean up
        self.SYNC.chunks[timestamp] = nil
        
        -- Return the completed data for processing
        return completeData
    end
    
    return nil -- Not complete yet
end
