-- TWRA Chunk Manager
-- Manages splitting and reassembling large messages
TWRA = TWRA or {}
TWRA.chunkManager = TWRA.chunkManager or {}

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
    
    -- Ensure transfers table exists
    self.chunkManager.transfers = self.chunkManager.transfers or {}
    
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
    
    -- Calculate total size and chunks needed
    local dataLength = string.len(data)
    local maxChunkSize = self.maxChunkSize
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

-- Split a message into appropriate chunks
function TWRA.chunkManager:SplitIntoChunks(message)
    local chunks = {}
    local totalLength = string.len(message)
    local numChunks = math.ceil(totalLength / self.maxChunkSize)
    
    TWRA:Debug("sync", "Splitting message of " .. totalLength .. " bytes into " .. numChunks .. " chunks")
    
    for i = 1, numChunks do
        local startPos = ((i - 1) * self.maxChunkSize) + 1
        local endPos = math.min(startPos + self.maxChunkSize - 1, totalLength)
        local chunk = string.sub(message, startPos, endPos)
        table.insert(chunks, chunk)
    end
    
    return chunks
end

-- Function to receive and process chunked messages
function TWRA.chunkManager:ProcessChunkHeader(message, sender)
    -- Parse the message first
    local parts = TWRA:SplitString(message, ":")
    if table.getn(parts) < 6 then
        TWRA:Debug("error", "ChunkManager: Invalid chunk header format: " .. message)
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
    self.transfers = self.transfers or {}  -- Ensure transfers exists
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
function TWRA.chunkManager:ProcessChunk(message, sender)
    TWRA:Debug("sync", "ChunkManager: Begin ProcessChunk for " .. sender)
    
    -- Parse the message first
    local parts = TWRA:SplitString(message, ":")
    if table.getn(parts) < 7 then
        TWRA:Debug("error", "ChunkManager: Invalid data chunk format: " .. message, true)
        return false
    end
    
    TWRA:Debug("sync", "ChunkManager: Message split into " .. table.getn(parts) .. " parts")
    
    -- Extract parts
    local command = parts[1]
    local timestamp = tonumber(parts[2])
    local chunkNum = tonumber(parts[4])
    local totalChunks = tonumber(parts[5])
    local transferId = parts[6]
    
    TWRA:Debug("sync", "ChunkManager: Parsed header - chunk " .. chunkNum .. "/" .. totalChunks .. " for transfer " .. transferId)
    
    -- Extract the actual data chunk after the header
    -- Find the position after transferId:
    local headerPart = command .. ":" .. timestamp .. ":CHUNK:" .. 
                      chunkNum .. ":" .. totalChunks .. ":" .. transferId .. ":"
    local dataStart = string.len(headerPart) + 1
    local chunkData = string.sub(message, dataStart)
    
    TWRA:Debug("sync", "ChunkManager: Extracted data chunk of " .. string.len(chunkData) .. " bytes")
    
    -- TEST: Check if TWRA.SYNC.COMMANDS exists and has DATA_RESPONSE
    TWRA:Debug("sync", "ChunkManager: TEST - TWRA.SYNC exists: " .. (TWRA.SYNC and "Yes" or "No"))
    if TWRA.SYNC then
        TWRA:Debug("sync", "ChunkManager: TEST - TWRA.SYNC.COMMANDS exists: " .. (TWRA.SYNC.COMMANDS and "Yes" or "No"))
        if TWRA.SYNC.COMMANDS then
            TWRA:Debug("sync", "ChunkManager: TEST - DATA_RESPONSE defined: " .. (TWRA.SYNC.COMMANDS.DATA_RESPONSE and "Yes" or "No"))
            TWRA:Debug("sync", "ChunkManager: TEST - DATA_RESPONSE value: " .. (TWRA.SYNC.COMMANDS.DATA_RESPONSE or "nil"))
            TWRA:Debug("sync", "ChunkManager: TEST - Command matches DATA_RESPONSE: " .. (command == TWRA.SYNC.COMMANDS.DATA_RESPONSE and "Yes" or "No"))
        end
    end
    
    -- Initialize transfers table if it doesn't exist
    self.transfers = self.transfers or {}
    
    -- TEST: Check if self.transfers table exists
    TWRA:Debug("sync", "ChunkManager: TEST - self.transfers exists: " .. (self.transfers and "Yes" or "No"))
    if self.transfers then
        TWRA:Debug("sync", "ChunkManager: TEST - self.transfers[" .. transferId .. "] exists: " .. (self.transfers[transferId] and "Yes" or "No"))
    end
    
    -- Check if we're tracking this transfer
    if not self.transfers[transferId] then
        TWRA:Debug("error", "ChunkManager: Received unexpected chunk for transfer " .. transferId .. ". Creating new transfer entry.", true)
        
        -- Create a new transfer entry as fallback recovery
        self.transfers[transferId] = {
            command = command,
            timestamp = timestamp,
            sender = sender,
            totalSize = 0, -- We don't know the size since we missed the header
            receivedSize = 0,
            chunks = {},
            totalChunks = totalChunks,
            receivedChunks = 0,
            startTime = GetTime(),
            lastTime = GetTime(),
            complete = false,
            data = "",
            recovered = true -- Mark as recovered to track this special case
        }
    end
    
    TWRA:Debug("sync", "ChunkManager: Found transfer " .. transferId .. " in transfers table")
    local transfer = self.transfers[transferId]
    
    -- Validate sender is the same
    if transfer.sender ~= sender then
        TWRA:Debug("error", "ChunkManager: Chunk has different sender than transfer header", true)
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
        
        TWRA:Debug("sync", "ChunkManager: Chunk stored, now have " .. 
            transfer.receivedChunks .. "/" .. transfer.totalChunks .. " chunks")
        
        -- Log progress for large transfers
        if transfer.totalChunks > 10 and (math.floor(chunkNum / 5) * 5 == chunkNum or chunkNum == transfer.totalChunks) then
            local percent = math.floor((transfer.receivedChunks / transfer.totalChunks) * 100)
            TWRA:Debug("sync", string.format("ChunkManager: Transfer %s progress: %d%% (%d/%d chunks)", 
            transferId, percent, transfer.receivedChunks, transfer.totalChunks))
        end
        
        -- Check if transfer is complete
        if transfer.receivedChunks >= transfer.totalChunks then
            TWRA:Debug("sync", string.format("ChunkManager: Transfer %s potentially complete (%d/%d chunks received)", 
                transferId, transfer.receivedChunks, transfer.totalChunks))
            
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
                TWRA:Debug("error", "ChunkManager: Missing chunks in completed transfer: " .. 
                          table.concat(missingList, ", "), true)
                return false
            end
            
            TWRA:Debug("sync", "ChunkManager: All chunks verified, assembling data")
            
            -- Assemble the data in order
            local assembledData = ""
            for i = 1, transfer.totalChunks do
                assembledData = assembledData .. transfer.chunks[i]
                TWRA:Debug("sync", string.format("ChunkManager: Added chunk %d (%d bytes) to assembled data", 
                    i, string.len(transfer.chunks[i])))
            end
            
            TWRA:Debug("sync", string.format("ChunkManager: Transfer %s complete - %d bytes assembled in %d chunks (%.2f seconds)", 
                transferId, string.len(assembledData), transfer.totalChunks, GetTime() - transfer.startTime))
            
            -- Store the result
            transfer.complete = true
            transfer.data = assembledData
            
            TWRA:Debug("sync", "ChunkManager: Beginning to process assembled data")
            
            -- Process the assembled data
            -- For data responses:
            if command == TWRA.SYNC.COMMANDS.DATA_RESPONSE then
                TWRA:Debug("sync", "ChunkManager: Processing DATA_RESPONSE command")
                
                -- Make sure it's valid Base64 - auto-pad if needed
                local dataLen = string.len(assembledData)
                local remainder = dataLen - (math.floor(dataLen / 4) * 4)
                if remainder > 0 then
                    local padding = 4 - remainder
                    for i = 1, padding do
                        assembledData = assembledData .. "="
                    end
                    TWRA:Debug("sync", "ChunkManager: Added " .. padding .. " padding characters to Base64 data")
                end
                
                -- Check the first byte
                local firstByte = string.byte(assembledData, 1)
                TWRA:Debug("sync", "ChunkManager: First byte of data: " .. tostring(firstByte) .. 
                          (firstByte == 241 and " (correct binary format marker)" or " (NOT the correct marker!)"))
                
                -- Process the data - using compression system
                TWRA:Debug("sync", "ChunkManager: Processing " .. string.len(assembledData) .. " bytes of data")
                
                -- First, ensure compression system is initialized
                if not TWRA.LibCompress and TWRA.InitializeCompression then
                    TWRA:Debug("sync", "ChunkManager: Initializing compression system before processing")
                    TWRA:InitializeCompression()
                end
                
                -- Check if ProcessCompressedData function exists
                if TWRA.ProcessCompressedData then
                    TWRA:Debug("sync", "ChunkManager: ProcessCompressedData function found, calling it")
                    
                    -- Wrap in pcall to catch any errors
                    local success, result = pcall(function()
                        return TWRA:ProcessCompressedData(assembledData, timestamp, sender)
                    end)
                    
                    if not success then
                        -- Critical error handling - log in multiple categories to ensure visibility
                        TWRA:Debug("error", "ChunkManager: ERROR during ProcessCompressedData: " .. tostring(result), true)
                        TWRA:Debug("sync", "ChunkManager: ERROR during ProcessCompressedData: " .. tostring(result), true)
                        TWRA:Debug("general", "ChunkManager: ERROR during ProcessCompressedData: " .. tostring(result), true)
                        return false
                    else
                        TWRA:Debug("sync", "ChunkManager: ProcessCompressedData returned: " .. (result and "success" or "failure"))
                    end
                else
                    TWRA:Debug("error", "ChunkManager: ProcessCompressedData function NOT found!", true)
                    
                    -- Try fallback methods
                    TWRA:Debug("sync", "ChunkManager: Looking for fallback methods")
                    
                    -- Check if LibCompress exists
                    TWRA:Debug("sync", "ChunkManager: LibCompress exists: " .. (TWRA.LibCompress and "Yes" or "No"))
                    
                    -- Try direct decode if available
                    if TWRA.DecodeBase64 then
                        TWRA:Debug("sync", "ChunkManager: Attempting direct DecodeBase64 call as fallback")
                        local success, result = pcall(function()
                            return TWRA:DecodeBase64(assembledData, timestamp)
                        end)
                        
                        if not success then
                            TWRA:Debug("error", "ChunkManager: Fallback DecodeBase64 failed: " .. tostring(result), true)
                        else
                            TWRA:Debug("sync", "ChunkManager: Fallback DecodeBase64 completed")
                        end
                    else
                        TWRA:Debug("error", "ChunkManager: No fallback methods available", true)
                    end
                end
            else
                TWRA:Debug("sync", "ChunkManager: Unhandled command: " .. (command or "nil"))
            end
            
            -- Clean up the transfer
            self.transfers[transferId] = nil
            TWRA:Debug("sync", "ChunkManager: Transfer " .. transferId .. " cleaned up")
        else
            TWRA:Debug("sync", string.format("ChunkManager: Transfer %s progress: %d/%d chunks received", 
                transferId, transfer.receivedChunks, transfer.totalChunks))
        end
    else
        TWRA:Debug("sync", "ChunkManager: Received duplicate chunk " .. chunkNum .. " for transfer " .. transferId)
    end
    
    TWRA:Debug("sync", "ChunkManager: Finished ProcessChunk for " .. sender)
    return true
end
