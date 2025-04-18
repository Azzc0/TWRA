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
        cleanupInterval = 60,   -- How often to clean up stale transfers (seconds)
        messageSizeLimit = 240  -- Default message size limit (can be updated by testing)
    }
    
    -- Start periodic cleanup of stale transfers
    self:ScheduleRepeatingTimer(function() 
        self:CleanupStaleTransfers() 
    end, self.chunkManager.cleanupInterval)
    
    self:Debug("sync", "ChunkManager initialized")
    return true
end

-- Test function to determine the maximum message size on Turtle WoW
function TWRA:TestMessageSizeLimit()
    -- Stop any previously running tests
    if self.testingInProgress then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA Size Test:|r Stopping previous test")
        if self.testTimers then
            for _, timer in pairs(self.testTimers) do
                self:CancelTimer(timer)
            end
        end
        -- Restore original handler if exists
        if self.originalChatMsgHandler then
            self.OnChatMsgAddon = self.originalChatMsgHandler
            self.originalChatMsgHandler = nil
        end
    end
    
    -- Fixed test sizes to try
    local testSizes = {240, 500, 1000, 1500, 2000, 3000, 4000}
    self.testTimers = {}
    self.testResults = {}
    self.testingInProgress = true
    
    -- Function to generate a string of specified length
    local function generateTestString(length)
        local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
        local str = "TWRA_TEST:" .. tostring(length) .. ":"
        local baseLength = string.len(str)
        
        -- Fill the rest with random characters
        for i = baseLength, length - 1 do
            local randIndex = math.random(1, string.len(chars))
            str = str .. string.sub(chars, randIndex, randIndex)
        end
        
        return str
    end
    
    -- Save the original chat message handler
    if not self.originalChatMsgHandler then
        self.originalChatMsgHandler = self.OnChatMsgAddon
    end
    
    -- Create a temporary handler to process test messages
    self.OnChatMsgAddon = function(self, prefix, message, distribution, sender)
        -- Pass to original handler
        if self.originalChatMsgHandler then
            self:originalChatMsgHandler(prefix, message, distribution, sender)
        end
        
        -- Check if this is our test message
        if string.sub(message, 1, 10) == "TWRA_TEST:" then
            local parts = self:SplitString(message, ":")
            if parts and parts[2] then
                local size = tonumber(parts[2])
                if size then
                    self.testResults[size] = true
                    DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA Size Test:|r Successfully received message of length " .. size)
                end
            end
        end
    end
    
    -- Schedule the actual tests with delays
    local function scheduleTests()
        -- Initialize random seed
        math.randomseed(GetTime())
        
        -- Display test start message
        DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA Size Test:|r Starting message size tests with fixed sizes")
        
        -- Run tests with 3 seconds between them
        for i, size in ipairs(testSizes) do
            local timer = self:ScheduleTimer(function()
                local testMessage = generateTestString(size)
                DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA Size Test:|r Testing size: " .. size)
                
                -- Try to use the proper sync channel and prefix
                if self.SYNC and self.SYNC.PREFIX then
                    SendAddonMessage(self.SYNC.PREFIX, testMessage, "RAID")
                else
                    -- Fallback to a generic prefix if the sync module isn't initialized
                    SendAddonMessage("TWRA", testMessage, "RAID")
                end
            end, (i-1) * 3)
            
            table.insert(self.testTimers, timer)
        end
        
        -- Schedule final evaluation
        local finalTimer = self:ScheduleTimer(function()
            local maxSuccessfulSize = 0
            local successCount = 0
            
            -- Find the maximum successful size
            for _, size in ipairs(testSizes) do
                if self.testResults[size] then
                    maxSuccessfulSize = size
                    successCount = successCount + 1
                end
            end
            
            -- Display results
            DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA Size Test:|r Testing completed")
            if successCount > 0 then
                DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA Size Test:|r Maximum successful size: " .. maxSuccessfulSize .. " bytes")
                
                -- Set a safe limit (90% of max or 4000, whichever is lower)
                local recommendedSize = math.min(math.floor(maxSuccessfulSize * 0.9), 4000)
                DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA Size Test:|r Recommended chunk size: " .. recommendedSize .. " bytes")
                
                -- Update the chunk size in the manager
                self.chunkManager.messageSizeLimit = recommendedSize
            else
                DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA Size Test:|r No successful tests! Keeping default size of 240 bytes")
            end
            
            -- Clean up test variables
            self.testingInProgress = false
            self.testTimers = {}
            
            -- Restore original handler
            self.OnChatMsgAddon = self.originalChatMsgHandler
            self.originalChatMsgHandler = nil
        end, table.getn(testSizes) * 3 + 2) -- Wait a few seconds after last test
        
        table.insert(self.testTimers, finalTimer)
    end
    
    -- Start the tests
    scheduleTests()
    
    -- Create slash command if it doesn't exist
    if not self.sizeTestSlashRegistered then
        SlashCmdList["TWRA_SIZE_TEST"] = function(msg)
            if msg == "run" then
                TWRA:TestMessageSizeLimit()
            else
                DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA Size Test:|r Current message size limit: " .. 
                    TWRA.chunkManager.messageSizeLimit .. " bytes")
                DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA Size Test:|r Type /twrasize run to run the test again")
            end
        end
        SLASH_TWRA_SIZE_TEST1 = "/twrasize"
        self.sizeTestSlashRegistered = true
    end
end

-- Split a large message into manageable chunks
function TWRA:SplitMessageIntoChunks(message)
    local chunks = {}
    local chunkSize = self.chunkManager.messageSizeLimit or 240 -- Use the tested/configured message size limit
    
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
