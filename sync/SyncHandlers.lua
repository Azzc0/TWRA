-- TWRA Sync Message Handlers
-- Handles all incoming addon communications for synchronization
TWRA = TWRA or {}

-- Initialize SYNC namespace with new segmented sync commands
if not TWRA.SYNC then
    TWRA.SYNC = {
        PREFIX = "TWRA",
        pendingSection = nil,     -- Section to navigate to after sync
        chunkPrefixes = {}        -- Prefixes for chunked messages
    }
end

-- Initialize handler map in SYNC namespace
function TWRA:InitializeHandlerMap()
    -- Map command codes to handler functions directly
    -- The command codes are the values, not the keys, from TWRA.SYNC.COMMANDS
    self.syncHandlers = {
        -- Standard messages
        SECTION = self.HandleSectionCommand,
        VER = self.UnusedCommand,
        BSEC = self.HandleBulkSectionCommand, -- Bulk section handler
        BSTR = self.HandleBulkStructureCommand, -- Bulk structure handler
        MSREQ = self.HandleMissingSectionsRequestCommand, -- Missing sections request handler
        MSACK = self.HandleMissingSectionsAckCommand, -- Missing sections acknowledgment handler
        MSRES = self.HandleMissingSectionResponseCommand, -- Missing section response handler
        BSREQ = self.HandleBulkSyncRequestCommand, -- Bulk sync request handler
        BSACK = self.HandleBulkSyncAckCommand, -- Bulk sync acknowledgment handler
        
        -- Chunk handlers
        CHUNKED = self.HandleChunkHeaderCommand, -- Chunk header handler
        CHUNK = self.HandleChunkDataCommand, -- Chunk data handler
    }  
    self:Debug("sync", "Initialized message handler map with " .. self:GetTableSize(self.syncHandlers) .. " handlers")
end

-- Main addon message handler - routes messages to appropriate handlers
function TWRA:HandleAddonMessage(message, distribution, sender)
    -- Shared initial processing for all message types
    if not message or message == "" then
        return
    end
    
    -- Common parsing for all message types
    local components = {}
    local index = 1
    
    -- Parse message into components using ":" delimiter
    for part in string.gfind(message, "([^:]+)") do
        components[index] = part
        index = index + 1
    end
    
    if table.getn(components) < 1 then
        self:Debug("sync", "Invalid message format: " .. message)
        return
    end
    
    -- Extract command
    local command = components[1]
    
    -- Handle chunked message header
    if string.find(command, "CHUNKED") then
        -- Format: CHUNKED:dataLength:transferId:totalChunks
        -- Or with prefix: prefix:CHUNKED:dataLength:transferId:totalChunks
        local startPos = string.find(message, "CHUNKED:")
        if startPos then
            -- Extract the prefix if any
            local prefix = ""
            if startPos > 1 then
                prefix = string.sub(message, 1, startPos - 2) -- -2 to account for the colon
            end
            
            -- Parse the chunked message header
            local parts = {}
            local idx = 1
            for part in string.gfind(string.sub(message, startPos), "([^:]+)") do
                parts[idx] = part
                idx = idx + 1
            end
            
            if idx >= 5 then -- CHUNKED command plus 3 parameters
                local dataLength = parts[2]
                local transferId = parts[3]
                local totalChunks = parts[4]
                
                self:HandleChunkHeaderCommand(dataLength, transferId, totalChunks, sender, prefix)
            end
        end
        return
    end
    
    -- Handle chunk data
    if string.find(command, "CHUNK") then
        -- Format: CHUNK:transferId:chunkNum:chunkData
        -- Or with prefix: prefix:CHUNK:transferId:chunkNum:chunkData
        local startPos = string.find(message, "CHUNK:")
        if startPos then
            -- Extract the transfer ID and chunk number from the message
            local parts = {}
            local idx = 1
            local afterCommand = string.sub(message, startPos)
            
            -- Get the first few parts (command, transferId, chunkNum)
            for part in string.gfind(afterCommand, "([^:]+)") do
                parts[idx] = part
                idx = idx + 1
                if idx > 3 then break end
            end
            
            if idx >= 4 then -- Need at least CHUNK, transferId, chunkNum
                local transferId = parts[2]
                local chunkNum = parts[3]
                
                -- Extract the chunk data portion (everything after the third colon after CHUNK:)
                local dataStartPos = startPos
                local colonCount = 0
                for i = startPos, string.len(message) do
                    if string.sub(message, i, i) == ":" then
                        colonCount = colonCount + 1
                        if colonCount == 3 then
                            dataStartPos = i + 1
                            break
                        end
                    end
                end
                
                local chunkData = string.sub(message, dataStartPos)
                
                self:HandleChunkDataCommand(transferId, chunkNum, chunkData, sender)
            end
        end
        return
    end
    
    -- Handle different command types
    if command == self.SYNC.COMMANDS.SECTION then
        -- Handle SECTION (navigation update)
        if self.HandleSectionCommand then
            self:HandleSectionCommand(components[2], components[3], sender)
        end
    elseif command == self.SYNC.COMMANDS.BULK_SECTION then
        -- Handle BSEC (bulk section transmission without processing)
        if self.HandleBulkSectionCommand then
            self:HandleBulkSectionCommand(components[2], components[3], self:ExtractDataPortion(message, 4), sender)
        end
    elseif command == self.SYNC.COMMANDS.BULK_STRUCTURE then
        -- Handle BSTR (bulk structure transmission)
        if self.HandleBulkStructureCommand then
            self:HandleBulkStructureCommand(components[2], self:ExtractDataPortion(message, 3), sender)
        end
    elseif command == self.SYNC.COMMANDS.VERSION then
        -- Handle VER (version check)
        if self.HandleVersionCommand then
            self:HandleVersionCommand(components[2], sender)
        end
    elseif command == self.SYNC.COMMANDS.MISS_SEC_REQ then
        -- Handle MSREQ (missing sections request)
        if self.HandleMissingSectionsRequestCommand then
            self:HandleMissingSectionsRequestCommand(components[2], components[3], components[4], sender)
        end
    elseif command == self.SYNC.COMMANDS.MISS_SEC_ACK then
        -- Handle MSACK (missing sections acknowledgment)
        if self.HandleMissingSectionsAckCommand then
            self:HandleMissingSectionsAckCommand(components[2], components[3], components[4], sender)
        end
    -- Handle other command types here...
    else
        -- Try using the handler map for other commands
        local handler = self.syncHandlers[command]
        if handler then
            handler(self, components, sender)
        else
            self:Debug("sync", "Unknown command: " .. command)
        end
    end
end

-- Handler for chunk header messages
-- @param dataLength The total length of data in this transfer
-- @param transferId Unique identifier for this transfer
-- @param totalChunks Total number of chunks expected
-- @param sender The player who sent this message
-- @param prefix Optional message prefix for this transfer
function TWRA:HandleChunkHeaderCommand(dataLength, transferId, totalChunks, sender, prefix)
    self:Debug("sync", "Received chunk header from " .. sender .. " for transfer " .. transferId)
    self:Debug("chunk", "Received chunk header from " .. sender .. " for transfer " .. transferId .. 
                " expecting " .. totalChunks .. " chunks totaling " .. dataLength .. " bytes")
    
    -- Store the prefix for this transfer
    if not self.SYNC.chunkPrefixes then
        self.SYNC.chunkPrefixes = {}
    end
    
    if prefix and prefix ~= "" then
        self.SYNC.chunkPrefixes[transferId] = prefix
        self:Debug("chunk", "Stored prefix '" .. prefix .. "' for transfer " .. transferId)
    end
    
    -- Initialize the chunk transfer in the chunk manager
    if self.chunkManager then
        self.chunkManager:HandleChunkHeader(dataLength, transferId, totalChunks, sender)
    else
        self:Debug("error", "No chunk manager available to handle chunk header")
    end
end

-- Handler for chunk data messages
-- @param transferId Identifier for this transfer
-- @param chunkNum The sequence number of this chunk
-- @param chunkData The actual chunk data
-- @param sender The player who sent this message
function TWRA:HandleChunkDataCommand(transferId, chunkNum, chunkData, sender)
    self:Debug("chunk", "Received chunk " .. chunkNum .. " from " .. sender .. 
                " for transfer " .. transferId .. " with " .. string.len(chunkData) .. " bytes")
    
    -- Add additional diagnostic logging to track what happens
    self:Debug("chunk", "Processing chunk " .. chunkNum .. " for transfer " .. transferId)
    
    -- Process this chunk via the chunk manager
    if self.chunkManager then
        -- Ensure chunk manager is initialized
        if not self.chunkManager.receivingChunks then
            self:Debug("chunk", "Ensuring chunk manager is initialized before handling chunk")
            self.chunkManager:Initialize()
        end
        
        local isComplete = self.chunkManager:HandleChunkData(transferId, chunkNum, chunkData)
        
        -- Diagnostic logging to check what's returned
        self:Debug("chunk", "Chunk " .. chunkNum .. " processed, isComplete: " .. tostring(isComplete))
        
        -- If transfer is complete, process it
        if isComplete then
            self:Debug("sync", "CHUNK TRANSFER COMPLETE: " .. transferId .. " is complete, processing")
            self:Debug("chunk", "CHUNK TRANSFER COMPLETE: " .. transferId .. " is complete, processing")
            
            -- Explicitly force processing of chunks
            if not self.chunkManager.storedChunkData or not self.chunkManager.storedChunkData[transferId] then
                self:Debug("chunk", "FORCING CHUNK PROCESSING: Transfer " .. transferId .. " is not in storedChunkData, reprocessing")
                self.chunkManager:ProcessChunks(transferId, false)
            end
            
            -- Check if we have data now
            if self.chunkManager.storedChunkData and self.chunkManager.storedChunkData[transferId] then
                self:Debug("chunk", "CHUNKS SUCCESSFULLY PROCESSED: Data available in storedChunkData for " .. transferId)
            else
                self:Debug("error", "CHUNK PROCESSING FAILED: Could not store data for " .. transferId)
            end
        end
    else
        self:Debug("error", "No chunk manager available to handle chunk data")
    end
end

-- Process a completed chunk transfer based on its prefix
-- @param transferId The ID of the completed transfer
function TWRA:ProcessCompleteChunkTransfer(transferId)
    if not transferId then
        self:Debug("error", "Invalid transfer ID for processing")
        return
    end
    
    self:Debug("chunk", "Processing complete chunk transfer: " .. transferId)
    
    -- Get the associated prefix for this transfer
    local prefix = ""
    if self.SYNC and self.SYNC.chunkPrefixes and self.SYNC.chunkPrefixes[transferId] then
        prefix = self.SYNC.chunkPrefixes[transferId]
    end
    
    -- Make sure the chunks are processed and stored in storedChunkData
    if self.chunkManager then
        self:Debug("chunk", "Ensuring chunks are processed and stored in storedChunkData")
        local success = self.chunkManager:ProcessChunks(transferId, false)
        if success then
            self:Debug("chunk", "Successfully processed and stored chunks for transfer " .. transferId)
        else
            self:Debug("error", "Failed to process chunks for transfer " .. transferId)
        end
    else
        self:Debug("error", "No chunk manager available to process complete transfer")
        return
    end
    
    -- Clean up after processing
    if self.SYNC and self.SYNC.chunkPrefixes then
        self.SYNC.chunkPrefixes[transferId] = nil
    end
    
    -- Handle test chunk case for ChunkTest functions
    if prefix == "TEST_CHUNK" or prefix == "" then
        -- This might be a test chunk from ChunkTestS/ChunkTestR
        self:Debug("chunk", "Possible test chunk detected, no special processing needed")
        -- No special processing needed for test chunks, just let the data be retrievable
    end
    
    -- Note: Other prefix handlers removed for brevity as they're not related to the issue
end

-- Add a test function for chunk sync
function TWRA:TestChunkSync()
    self:Debug("sync", "----- CHUNK SYNC TEST: Starting -----")
    self:Debug("chunk", "----- CHUNK SYNC TEST: Starting -----")
    
    -- Initialize the chunk manager if needed
    if not self.chunkManager then
        self.chunkManager = TWRA.chunkManager
        if not self.chunkManager.Initialize then
            self:Debug("error", "ChunkManager not properly loaded")
            return
        end
        self.chunkManager:Initialize()
    end
    
    -- Generate test data (approximately 10KB)
    local testData = "TEST_DATA:"
    for i = 1, 2000 do
        testData = testData .. "Line " .. i .. " of test data with some random values: " .. math.random(1000, 9999) .. "\n"
    end
    
    -- Determine if we're the sender or receiver
    if not TWRA.chunkTestMode then
        -- First time running the test, we're the sender
        TWRA.chunkTestMode = "sender"
        
        -- Send the test data
        self:Debug("sync", "CHUNK SYNC TEST: Sending test data as " .. TWRA.chunkTestMode)
        self:Debug("chunk", "CHUNK SYNC TEST: Sending " .. string.len(testData) .. " bytes of test data")
        
        local channel = "RAID"
        if GetNumRaidMembers() == 0 then
            channel = "PARTY"
            if GetNumPartyMembers() == 0 then
                -- No raid or party, switch to WHISPER to self
                channel = "WHISPER"
                
                -- Get player name
                local playerName = UnitName("player")
                
                -- Send to self for testing
                TWRA.chunkManager:ChunkContent(testData, channel, playerName, "TEST_CHUNK")
                DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[TWRA Chunk Test]|r Test data sent to self via whisper. Run again to verify.")
                return
            end
        end
        
        -- Send to raid or party
        TWRA.chunkManager:ChunkContent(testData, channel, nil, "TEST_CHUNK")
        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[TWRA Chunk Test]|r Test data sent. Run again on receiving client to verify.")
    else
        -- Second time running the test, we're verifying receipt
        TWRA.chunkTestMode = "receiver"
        
        self:Debug("sync", "----- CHUNK SYNC TEST: Starting receiver verification -----")
        self:Debug("chunk", "----- CHUNK SYNC TEST: Starting receiver verification -----")
        
        -- Check if we've received any TEST_CHUNK transfers
        local found = false
        
        -- First check if there's an active transfer
        self:Debug("chunk", "CHUNK SYNC TEST: Checking for TEST_CHUNK transfers in receivingChunks table")
        local receivingCount = 0
        
        if self.chunkManager and self.chunkManager.receivingChunks then
            for transferId, transfer in pairs(self.chunkManager.receivingChunks) do
                receivingCount = receivingCount + 1
                if self.SYNC and self.SYNC.chunkPrefixes and self.SYNC.chunkPrefixes[transferId] == "TEST_CHUNK" then
                    found = true
                    self:Debug("chunk", "CHUNK SYNC TEST: Found active test transfer " .. transferId .. 
                               " with " .. transfer.received .. "/" .. transfer.expected .. " chunks")
                    DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00[TWRA Chunk Test]|r Test transfer in progress: " .. 
                                                 math.floor((transfer.received / transfer.expected) * 100) .. "% complete")
                    break
                end
            end
        end
        
        self:Debug("chunk", "CHUNK SYNC TEST: Number of transfers in receiving queue: " .. receivingCount)
        
        -- If not found in active transfers, check processed transfers
        if not found and self.chunkManager and self.chunkManager.processedTransfers then
            -- Check if we processed a TEST_CHUNK transfer
            for transferId, timestamp in pairs(self.chunkManager.processedTransfers) do
                if transferId and string.find(transferId, "TEST_CHUNK") then
                    found = true
                    self:Debug("chunk", "CHUNK SYNC TEST: Found completed test transfer " .. transferId .. 
                               " processed at " .. timestamp)
                    DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00[TWRA Chunk Test]|r Test transfer completed successfully!")
                    break
                end
            end
        end
        
        if not found then
            self:Debug("error", "CHUNK SYNC TEST: No test chunk transfer found. Make sure the sender has run TestChunkSync first.")
            self:Debug("chunk", "CHUNK SYNC TEST: No test chunk transfer found in receivingChunks. Checking processedTransfers...")
            self:Debug("chunk", "CHUNK SYNC TEST: No test transfers found in receivingChunks or processedTransfers tables")
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[TWRA Chunk Test]|r No test chunk transfer found. Did the sender run /run TWRA:TestChunkSync()?")
        end
    end
end

