-- TWRA Chunk Manager
-- Manages splitting and reassembling large messages
TWRA = TWRA or {}

-- Initialize chunk management system
function TWRA:InitChunkManager()
    if not self.chunkManager then
        self.chunkManager = {
            transfers = {},
            
            -- Method placeholders - will be replaced
            SendChunkedMessage = nil,
            ProcessChunkHeader = nil,
            ProcessDataChunk = nil,
            CleanupStaleTransfers = nil
        }
    end
    
    -- Schedule periodic cleanup
    self:ScheduleRepeatingTimer(function()
        -- Clean up any transfers older than 30 seconds
        local now = GetTime()
        local count = 0
        
        for id, transfer in pairs(self.chunkManager.transfers) do
            -- Check if transfer has timed out (30 second timeout since last activity)
            if (now - (transfer.lastTime or 0)) > 30 then
                self:Debug("sync", "ChunkManager: Removing stale transfer: " .. id)
                self.chunkManager.transfers[id] = nil
                count = count + 1
            end
        end
        
        if count > 0 then
            self:Debug("sync", "ChunkManager: Cleaned up " .. count .. " stale transfers")
        end
    end, 60) -- Check every 60 seconds
    
    self:Debug("sync", "ChunkManager initialized")
    return true
end

-- Function to send chunked message with improved Base64 handling
function TWRA.chunkManager:SendChunkedMessage(data, prefix)
    if not data then
        TWRA:Debug("error", "ChunkManager: No data to send")
        return false
    end
    
    -- Calculate total size and chunks needed
    local dataLength = string.len(data)
    local maxChunkSize = 1900  -- Increased from 190 to maximize efficiency while leaving buffer for headers
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

-- Function to receive and process chunked messages
function TWRA.chunkManager:ProcessChunkHeader(message, parts, sender)
    -- Expected format: CMD:timestamp:CHUNKED:dataSize:transferId:totalChunks
    if table.getn(parts) < 6 then
        TWRA:Debug("error", "ChunkManager: Invalid chunk header format")
        return false
    end
    
    -- Extract parts
    local command = parts[1]
    local timestamp = tonumber(parts[2])
    local dataSize = tonumber(parts[4])
    local transferId = parts[5]
    local totalChunks = tonumber(parts[6])
    
    TWRA:Debug("sync", string.format("ChunkManager: Starting transfer %s from %s (%d bytes in %d chunks)", 
        transferId, sender, dataSize, totalChunks))
    
    -- Initialize transfer record
    self.transfers[transferId] = {
        command = command,
        timestamp = timestamp,
        sender = sender,
        totalSize = dataSize,
        receivedSize = 0,
        chunks = {},
        totalChunks = totalChunks,
        receivedChunks = 0,
        startTime = GetTime(),
        lastTime = GetTime(),
        complete = false,
        data = ""
    }
    
    return true
end

-- Function to process individual data chunks
function TWRA.chunkManager:ProcessDataChunk(message, parts, sender)
    -- Expected format: CMD:timestamp:CHUNK:chunkNum:totalChunks:transferId:data
    if table.getn(parts) < 7 then
        TWRA:Debug("error", "ChunkManager: Invalid data chunk format")
        return false
    end
    
    -- Extract parts
    local command = parts[1]
    local timestamp = tonumber(parts[2])
    local chunkNum = tonumber(parts[4])
    local totalChunks = tonumber(parts[5])
    local transferId = parts[6]
    
    -- Extract the actual data chunk after the header
    -- Find the position after transferId:
    local headerPart = command .. ":" .. timestamp .. ":CHUNK:" .. 
                      chunkNum .. ":" .. totalChunks .. ":" .. transferId .. ":"
    local dataStart = string.len(headerPart) + 1
    local chunkData = string.sub(message, dataStart)
    
    -- Check if we're tracking this transfer
    if not self.transfers[transferId] then
        TWRA:Debug("sync", "ChunkManager: Received unexpected chunk for transfer " .. transferId)
        return false
    end
    
    local transfer = self.transfers[transferId]
    
    -- Validate sender is the same
    if transfer.sender ~= sender then
        TWRA:Debug("error", "ChunkManager: Chunk has different sender than transfer header")
        return false
    end
    
    -- Store the chunk and update stats
    TWRA:Debug("sync", string.format("ChunkManager: Received chunk %d/%d for transfer %s (%d bytes)", 
        chunkNum, totalChunks, transferId, string.len(chunkData)))
    
    -- Store in the chunk table
    if not transfer.chunks[chunkNum] then
        transfer.chunks[chunkNum] = chunkData
        transfer.receivedChunks = transfer.receivedChunks + 1
        transfer.receivedSize = transfer.receivedSize + string.len(chunkData)
        transfer.lastTime = GetTime()
        
        -- Log progress for large transfers
        if transfer.totalChunks > 10 and (math.floor(chunkNum / 5) * 5 == chunkNum or chunkNum == transfer.totalChunks) then
            local percent = math.floor((transfer.receivedChunks / transfer.totalChunks) * 100)
            TWRA:Debug("sync", string.format("ChunkManager: Transfer %s progress: %d%% (%d/%d chunks)", 
            transferId, percent, transfer.receivedChunks, transfer.totalChunks))
        end
        
        -- Check if transfer is complete
        if transfer.receivedChunks >= transfer.totalChunks then
            -- Verify we have all chunks
            local missingChunks = false
            local missingList = {}
            
            for i = 1, transfer.totalChunks do
                if not transfer.chunks[i] then
                    missingChunks = true
                    table.insert(missingList, i)
                end
            end
            
            if missingChunks then
                TWRA:Debug("sync", "ChunkManager: Missing chunks in completed transfer: " .. 
                          table.concat(missingList, ", "))
                return false
            end
            
            -- Assemble the data in order
            local assembledData = ""
            for i = 1, transfer.totalChunks do
                assembledData = assembledData .. transfer.chunks[i]
            end
            
            TWRA:Debug("sync", string.format("ChunkManager: Transfer %s complete - %d bytes received in %d chunks (%.2f seconds)", 
                transferId, string.len(assembledData), transfer.totalChunks, GetTime() - transfer.startTime))
            
            -- Store the result
            transfer.complete = true
            transfer.data = assembledData
            
            -- Process the assembled data
            -- For data responses:
            if command == TWRA.SYNC.COMMANDS.DATA_RESPONSE then
                TWRA:Debug("sync", "ChunkManager: Processing completed data response")
                
                -- Double check for Base64 issues
                if transfer.data and string.len(transfer.data) > 0 then
                    if string.byte(transfer.data, 1) == 241 then 
                        -- It's our marked binary format
                        TWRA:Debug("sync", "ChunkManager: Data uses binary format marker")
                    else
                        -- Make sure it's valid Base64 - auto-pad if needed
                        local dataLen = string.len(transfer.data)
                        local remainder = dataLen - (math.floor(dataLen / 4) * 4)
                        if remainder > 0 then
                            local padding = 4 - remainder
                            for i = 1, padding do
                                transfer.data = transfer.data .. "="
                            end
                            TWRA:Debug("sync", "ChunkManager: Added " .. padding .. " padding characters to Base64 data")
                        end
                    end
                    
                    -- Process the data
                    TWRA:ProcessCompressedData(transfer.data, timestamp, sender)
                else
                    TWRA:Debug("error", "ChunkManager: Assembled data is empty or nil")
                end
            end
            
            -- Clean up the transfer
            self.transfers[transferId] = nil
        end
    else
        TWRA:Debug("sync", "ChunkManager: Received duplicate chunk " .. chunkNum .. " for transfer " .. transferId)
    end
    
    return true
end
