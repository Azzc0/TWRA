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
    self.pendingChunks = {}
    self.receivingChunks = {}
    
    -- Debug that we're initialized
    TWRA:Debug("sync", "ChunkManager initialized with chunk size " .. self.maxChunkSize)
    
    return self
end

-- Function to send chunked message with improved Base64 handling
function TWRA.chunkManager:SendChunkedMessage(data, prefix)
    if not data then
        TWRA:Debug("error", "ChunkManager: No data to send")
        return false
    end
    
    -- Ensure we're initialized
    if not self.maxChunkSize then
        TWRA:Debug("sync", "ChunkManager: maxChunkSize not set, initializing with default")
        self:Initialize()
    end
    
    -- Calculate total size and chunks needed
    local dataLength = string.len(data)
    local maxChunkSize = self.maxChunkSize or 1800  -- Fallback if still nil
    local totalChunks = math.ceil(dataLength / maxChunkSize)
    
    TWRA:Debug("sync", "ChunkManager: Sending " .. dataLength .. " bytes in " .. totalChunks .. " chunks")
    
    -- Generate a unique transfer ID
    local transferId = tostring(time()) .. "-" .. tostring(math.random(10000, 99999))
    
    -- Send header message with total size
    local headerMessage = prefix .. "CHUNKED:" .. dataLength .. ":" .. transferId .. ":" .. totalChunks
    TWRA:SendAddonMessage(headerMessage)
    TWRA:Debug("sync", "ChunkManager: Sent header with transfer ID " .. transferId)
    
    -- Schedule chunks to be sent with a small delay between them
    local position = 1
    
    for chunkNum = 1, totalChunks do
        -- Use closure to preserve current values
        local currentChunkNum = chunkNum
        
        -- Calculate delay - staggered to prevent message dropping
        local delay = (chunkNum - 1) * 0.2
        
        -- Schedule this chunk
        TWRA:ScheduleTimer(function()
            -- Extract chunk data
            local endPos = math.min(position + maxChunkSize - 1, dataLength)
            local chunkData = string.sub(data, position, endPos)
            position = endPos + 1
            
            -- Debug chunk stats
            TWRA:Debug("sync", string.format("ChunkManager: Sending chunk %d/%d (%d bytes)", 
                currentChunkNum, totalChunks, string.len(chunkData)))
            
            -- Send chunk with proper formatting 
            local chunkMessage = prefix .. "CHUNK:" .. currentChunkNum .. ":" .. 
                                totalChunks .. ":" .. transferId .. ":" .. chunkData
            TWRA:SendAddonMessage(chunkMessage)
            
            -- Mark if this is the last chunk
            if currentChunkNum == totalChunks then
                TWRA:Debug("sync", "ChunkManager: Finished sending all chunks for transfer " .. transferId)
            end
        end, delay)
    end
    
    return true
end