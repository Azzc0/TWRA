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
    self:Debug("sync", "Received addon message: " .. message .. " from " .. sender, false, true)
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
    elseif command == self.SYNC.COMMANDS.BULK_SYNC_REQUEST then
        -- Handle BSREQ (bulk sync request)
        if self.HandleBulkSyncRequestCommand then
            self:HandleBulkSyncRequestCommand(components, sender)
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

-- Helper function to extract data portion from a message with a variable number of components
function TWRA:ExtractDataPortion(message, startPos)
    if not message or not startPos or startPos < 1 then
        return ""
    end
    
    -- Find the position of the Nth colon (startPos-1 colons)
    local colonCount = 0
    local dataStartPos = 1
    
    for i = 1, string.len(message) do
        if string.sub(message, i, i) == ":" then
            colonCount = colonCount + 1
            if colonCount == startPos - 1 then
                dataStartPos = i + 1
                break
            end
        end
    end
    
    -- Extract everything after that position
    return string.sub(message, dataStartPos)
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

-- Function to handle bulk section messages (BSEC)
-- These are stored directly without processing
function TWRA:HandleBulkSectionCommand(timestamp, sectionIndex, sectionData, sender)
    self:Debug("sync", "Handling BULK_SECTION from Clickyou for section " .. sectionIndex)
    
    -- Skip if we're missing required arguments
    if not timestamp or not sectionIndex or not sectionData then
        self:Debug("error", "Missing required arguments for BULK_SECTION handler")
        return false
    end
    
    -- Convert section index to number
    sectionIndex = tonumber(sectionIndex)
    if not sectionIndex then
        self:Debug("error", "Invalid section index in BULK_SECTION: " .. tostring(sectionIndex))
        return false
    end
    
    -- Make sure TWRA_CompressedAssignments and its sections table exist
    if not TWRA_CompressedAssignments then
        TWRA_CompressedAssignments = {}
    end
    
    if not TWRA_CompressedAssignments.sections then
        TWRA_CompressedAssignments.sections = {}
    end

    -- Check if this is a chunked section reference
    if string.find(sectionData, "^CHUNKED:") then
        self:Debug("sync", "Detected chunked section reference: " .. sectionData)
        
        -- Extract the transfer ID from the chunked reference
        -- Format should be "CHUNKED:transferId"
        local transferId = nil
        
        -- Use string.gfind instead of string.match (Lua 5.0 compatible)
        for part in string.gfind(sectionData, "CHUNKED:([^:]+)") do
            transferId = part
            break -- Just get the first match
        end
        
        self:Debug("sync", "Extracted transferId: " .. (transferId or "nil"))
        
        if not transferId then
            self:Debug("error", "Failed to extract transferId from chunked reference: " .. sectionData)
            return false
        end
        
        self:Debug("sync", "Processing chunked section reference with transferId: " .. transferId)
        
        -- Attempt to retrieve the actual chunked data from the chunk manager
        if not self.chunkManager then
            self:Debug("error", "Chunk manager not available to retrieve chunked section data")
            return false
        end
        
        -- Make sure the chunk manager is initialized
        if not self.chunkManager.storedChunkData then
            self:Debug("error", "Chunk manager not properly initialized, cannot retrieve chunked data")
            return false
        end
        
        -- Use RetrieveChunkData to get the chunked data
        local actualData = self.chunkManager:RetrieveChunkData(transferId)
        
        -- Check if the chunk data is available
        if not actualData then
            self:Debug("error", "Chunked data not found for transferId: " .. transferId)
            self:Debug("sync", "Available transferIds in storedChunkData: " .. self:DebugTableKeys(self.chunkManager.storedChunkData))
            
            -- Store the reference temporarily, but mark it for later resolution
            -- This will allow us to request the missing data later
            TWRA_CompressedAssignments.sections[sectionIndex] = sectionData
            
            -- Track this as a missing section that needs to be requested
            TWRA_CompressedAssignments.sections.missing = TWRA_CompressedAssignments.sections.missing or {}
            TWRA_CompressedAssignments.sections.missing[sectionIndex] = transferId
            
            self:Debug("sync", "Marked section " .. sectionIndex .. " as missing, will request later")
            return false
        end
        
        -- Debug the retrieved chunk data
        self:Debug("sync", "Successfully retrieved chunked data for section " .. sectionIndex .. 
                  " (length: " .. string.len(actualData) .. " bytes)")
        
        -- Add more detailed debug information about the chunk data
        if string.len(actualData) > 0 then
            local firstChar = string.sub(actualData, 1, 1)
            local firstByte = string.byte(firstChar)
            self:Debug("sync", "Chunk data first byte: " .. tostring(firstByte) .. 
                      " (char: '" .. (firstByte >= 32 and firstByte <= 126 and firstChar or "non-printable") .. "')")
            
            -- Show first 20 bytes in hex format for debugging
            local hexOutput = ""
            local maxBytes = math.min(20, string.len(actualData))
            for i = 1, maxBytes do
                hexOutput = hexOutput .. string.format("%02X ", string.byte(string.sub(actualData, i, i)))
            end
            self:Debug("sync", "Chunk data first " .. maxBytes .. " bytes: " .. hexOutput)
        else
            self:Debug("error", "Retrieved chunk data is empty!")
        end
        
        -- Replace the reference with the actual data
        sectionData = actualData
    end
    
    -- Store the actual data (either the original or the retrieved chunked data)
    TWRA_CompressedAssignments.sections[sectionIndex] = sectionData
    
    -- Update the timestamp if it's newer than our current one
    -- Note: We don't trigger a new sync request here, just update the timestamp
    if TWRA_Assignments then
        local currentTimestamp = TWRA_Assignments.timestamp or 0
        if tonumber(timestamp) > currentTimestamp then
            self:Debug("sync", "Updating our timestamp to " .. timestamp .. " from BULK_SECTION without triggering a new sync")
            TWRA_Assignments.timestamp = tonumber(timestamp)
        end
    end
    
    self:Debug("sync", "Successfully stored bulk section " .. sectionIndex .. " data without processing")
    
    -- Add this section to our tracking of received sections
    self.SYNC.receivedSectionResponses = self.SYNC.receivedSectionResponses or {}
    self.SYNC.receivedSectionResponses[sectionIndex] = true
    
    -- Remove this section from the missing sections tracking if it was there
    if TWRA_CompressedAssignments.sections.missing and 
       TWRA_CompressedAssignments.sections.missing[sectionIndex] then
        self:Debug("sync", "Removing section " .. sectionIndex .. " from missing sections list")
        TWRA_CompressedAssignments.sections.missing[sectionIndex] = nil
    end
    
    return true
end

-- Helper function to debug table keys - only create if it doesn't exist
function TWRA:DebugTableKeys(tbl)
    if not tbl then return "nil" end
    
    local keys = ""
    local count = 0
    
    for k, _ in pairs(tbl) do
        if count > 0 then
            keys = keys .. ", "
        end
        keys = keys .. tostring(k)
        count = count + 1
    end
    
    if count == 0 then
        return "empty table"
    else
        return keys .. " (total: " .. count .. ")"
    end
end

-- Handle a bulk structure message (BSTR) in reversed bulk sync approach
function TWRA:HandleBulkStructureCommand(timestamp, structureData, sender)
    self:Debug("sync", "Handling BULK_STRUCTURE from " .. sender)
    
    -- Skip if we're missing required arguments
    if not timestamp or not structureData then
        self:Debug("error", "Missing required arguments for BULK_STRUCTURE handler")
        return false
    end
    
    -- Convert timestamp to number
    timestamp = tonumber(timestamp)
    if not timestamp then
        self:Debug("error", "Invalid timestamp in BULK_STRUCTURE: " .. tostring(timestamp))
        return false
    end
    
    -- Check our current data timestamp against the received one
    local localTimestamp = 0
    if TWRA_CompressedAssignments then
        localTimestamp = TWRA_CompressedAssignments.timestamp or 0
    elseif TWRA_Assignments then
        localTimestamp = TWRA_Assignments.timestamp or 0
    end
    
    -- Compare timestamps
    local timestampDiff = self:CompareTimestamps(localTimestamp, timestamp)
    
    -- If our timestamp is newer, we should keep our data
    if timestampDiff > 0 then
        self:Debug("sync", "Our data is newer than BULK_STRUCTURE received - ignoring")
        return false
    end
    
    -- UPDATED: Validate bulkSyncTimestamp with this message's timestamp
    -- If we have a bulkSyncTimestamp but it doesn't match this message's timestamp
    if TWRA_CompressedAssignments and TWRA_CompressedAssignments.bulkSyncTimestamp then
        if TWRA_CompressedAssignments.bulkSyncTimestamp ~= timestamp then
            -- Timestamps don't match, discard all compressed assignments
            self:Debug("sync", "Timestamp mismatch: BULK_STRUCTURE timestamp (" .. timestamp .. 
                     ") doesn't match bulkSyncTimestamp (" .. TWRA_CompressedAssignments.bulkSyncTimestamp .. 
                     "). Discarding all compressed assignments.")
            
            -- Reset the entire compressed assignments table
            TWRA_CompressedAssignments = {}
        end
    end
    
    -- Check if this is a chunked structure reference
    if string.find(structureData, "^CHUNKED:") then
        self:Debug("sync", "Detected chunked structure reference: " .. structureData)
        
        -- Extract the transfer ID from the chunked reference
        -- Format should be "CHUNKED:transferId"
        local transferId = nil
        
        -- Use string.gfind instead of string.match (Lua 5.0 compatible)
        for part in string.gfind(structureData, "CHUNKED:([^:]+)") do
            transferId = part
            break -- Just get the first match
        end
        
        self:Debug("sync", "Extracted transferId: " .. (transferId or "nil"))
        
        if not transferId then
            self:Debug("error", "Failed to extract transferId from chunked reference: " .. structureData)
            return false
        end
        
        self:Debug("sync", "Processing chunked structure reference with transferId: " .. transferId)
        
        -- Attempt to retrieve the actual chunked data from the chunk manager
        if not self.chunkManager then
            self:Debug("error", "Chunk manager not available to retrieve chunked structure data")
            return false
        end
        
        -- Make sure the chunk manager is initialized
        if not self.chunkManager.storedChunkData then
            self:Debug("error", "Chunk manager not properly initialized, cannot retrieve chunked data")
            return false
        end
        
        -- Use RetrieveChunkData to get the chunked data
        local actualData = self.chunkManager:RetrieveChunkData(transferId)
        
        -- Check if the chunk data is available
        if not actualData then
            self:Debug("error", "Chunked data not found for transferId: " .. transferId)
            self:Debug("sync", "Available transferIds in storedChunkData: " .. self:DebugTableKeys(self.chunkManager.storedChunkData))
            
            -- Store the reference temporarily, but mark it for later resolution
            -- This will allow us to request the missing data later
            TWRA_CompressedAssignments = TWRA_CompressedAssignments or {}
            TWRA_CompressedAssignments.structureReference = {
                transferId = transferId,
                timestamp = timestamp
            }
            
            self:Debug("sync", "Marked structure as missing, will request later")
            return false
        end
        
        -- Debug the retrieved chunk data
        self:Debug("sync", "Successfully retrieved chunked data for structure" .. 
                  " (length: " .. string.len(actualData) .. " bytes)")
        
        -- Add more detailed debug information about the chunk data
        if string.len(actualData) > 0 then
            local firstChar = string.sub(actualData, 1, 1)
            local firstByte = string.byte(firstChar)
            self:Debug("sync", "Chunk data first byte: " .. tostring(firstByte) .. 
                      " (char: '" .. (firstByte >= 32 and firstByte <= 126 and firstChar or "non-printable") .. "')")
            
            -- Show first 20 bytes in hex format for debugging
            local hexOutput = ""
            local maxBytes = math.min(20, string.len(actualData))
            for i = 1, maxBytes do
                hexOutput = hexOutput .. string.format("%02X ", string.byte(string.sub(actualData, i, i)))
            end
            self:Debug("sync", "Chunk data first " .. maxBytes .. " bytes: " .. hexOutput)
        else
            self:Debug("error", "Retrieved chunk data is empty!")
            return false
        end
        
        -- Replace the reference with the actual data
        structureData = actualData
    end
    
    -- Ensure TWRA_CompressedAssignments exists
    TWRA_CompressedAssignments = TWRA_CompressedAssignments or {}
    
    -- Store the structure data
    -- Ensure the compressed data has the marker if needed
    if string.byte(structureData, 1) ~= 241 then
        structureData = "\241" .. structureData
    end
    -- Store the structure
    TWRA_CompressedAssignments.structure = structureData

    -- Update Timestamp after storing the data
    TWRA_CompressedAssignments.timestamp = timestamp
    
    -- IMPORTANT: Decompress the structure now to rebuild navigation
    local success, decodedStructure = pcall(function()
        return self:DecompressStructureData(structureData)
    end)
    
    if not success or not decodedStructure then
        self:Debug("error", "Failed to decompress structure data from BSTR message")
        return false
    end
    
    -- Update assignment timestamp to match the structure
    -- IMPORTANT: Just update the timestamp without triggering new sync requests
    if TWRA_Assignments then
        self:Debug("sync", "Updating our timestamp to " .. timestamp .. " from BULK_STRUCTURE without triggering a new sync")
        TWRA_Assignments.timestamp = timestamp
    else
        TWRA_Assignments = { timestamp = timestamp }
    end
    
    -- CRITICAL: Build skeleton from structure BEFORE rebuilding navigation
    -- This properly sets up the TWRA_Assignments data structure with placeholders
    local hasBuiltSkeleton = false
    if self.BuildSkeletonFromStructure then
        self:Debug("sync", "Building skeleton structure from decoded data")
        hasBuiltSkeleton = self:BuildSkeletonFromStructure(decodedStructure, timestamp, true)
        if hasBuiltSkeleton then
            self:Debug("sync", "Successfully built skeleton structure from decoded data")
        else
            self:Debug("error", "Failed to build skeleton structure - may cause navigation issues")
        end
    else
        self:Debug("error", "BuildSkeletonFromStructure function not available")
        return false
    end
    
    -- Process the structure if we have received bulk sections that match the timestamp
    local hasSections = TWRA_CompressedAssignments.sections and next(TWRA_CompressedAssignments.sections)
    
    -- Always rebuild navigation regardless of whether we have sections or not
    self:Debug("sync", "CRITICAL: Rebuilding navigation after skeleton structure creation")
    if self.RebuildNavigation then
        self:RebuildNavigation()
        self:Debug("sync", "Navigation successfully rebuilt")
    else
        self:Debug("error", "RebuildNavigation function not available")
    end
    
    if hasSections then
        self:Debug("sync", "Sections available after receiving bulk structure")
        
        -- Get the current section name or index
        local currentSection = TWRA_Assignments and TWRA_Assignments.currentSectionName or 1
        
        -- ADDED: Verify that the current section name exists in decodedStructure
        local sectionExists = false
        if type(currentSection) == "string" then
            -- When currentSection is a section name (string), verify it exists in decodedStructure
            for index, sectionName in pairs(decodedStructure) do
                if type(index) == "number" and type(sectionName) == "string" and sectionName == currentSection then
                    self:Debug("sync", "Verified section name '" .. currentSection .. "' exists in structure")
                    currentSection = index -- Convert section name to index for navigation
                    sectionExists = true
                    break
                end
            end
            
            if not sectionExists then
                self:Debug("sync", "Section name '" .. currentSection .. "' not found in structure, defaulting to section 1")
                currentSection = 1
            end
        elseif type(currentSection) == "number" then
            -- When currentSection is an index, verify it exists
            if decodedStructure[currentSection] then
                sectionExists = true
                self:Debug("sync", "Verified section index " .. currentSection .. " exists in structure")
            else
                self:Debug("sync", "Section index " .. currentSection .. " not found in structure, defaulting to section 1")
                currentSection = 1
            end
        else
            -- Invalid currentSection type, default to first section
            self:Debug("sync", "Invalid currentSection type, defaulting to section 1")
            currentSection = 1
        end

        self:ProcessSectionData()
        
        -- Navigate to the selected section after processing all data
        if self.NavigateToSection then
            -- CRITICAL FIX: Use "fromSync" context instead of "bulkSync" to prevent broadcast
            -- "bulkSync" wasn't being recognized in the broadcast prevention logic
            self:Debug("sync", "Navigating to section " .. currentSection .. " with 'fromSync' context to prevent broadcasting")
            self:NavigateToSection(currentSection, "fromSync")
        else
            self:Debug("error", "NavigateToSection function not available")
        end
        
        if self.RefreshAssignmentTable then
            self:RefreshAssignmentTable()
        else
            self:Debug("error", "RefreshAssignmentTable function not available")
        end
        
        if self.RebuildOSDIfVisible then
            self:RebuildOSDIfVisible()
        end
        
        self:Debug("sync", "Bulk sync data processing and navigation rebuild complete!")
    else
        self:Debug("sync", "Received bulk structure but no sections")
        
        -- Since we've already rebuilt navigation, just refresh UI if needed
        -- Use a timer to ensure everything is processed
        self:ScheduleTimer(function()
            -- Refresh UI if needed
            if self.RefreshAssignmentTable then
                self:RefreshAssignmentTable()
                self:Debug("sync", "Refreshed assignment table")
            else
                self:Debug("error", "RefreshAssignmentTable function not available")
            end
            
            -- Navigate to the first section as a fallback
            if self.NavigateToSection then
                self:NavigateToSection(1, "bulkSyncNoData")
                self:Debug("sync", "Navigated to first section (no section data)")
            end
        end, 0.3)
    end
    
    -- Check if we have any missing sections after processing
    local missingCount = 0
    if TWRA_CompressedAssignments.sections and TWRA_CompressedAssignments.sections.missing then
        for idx, _ in pairs(TWRA_CompressedAssignments.sections.missing) do
            if type(idx) == "number" then
                missingCount = missingCount + 1
            end
        end
    end
    
    -- Only clear bulkSyncTimestamp if we have no missing sections
    if missingCount == 0 then
        self:Debug("sync", "No missing sections, clearing bulkSyncTimestamp")
        TWRA_CompressedAssignments.bulkSyncTimestamp = nil
    else
        self:Debug("sync", "Still have " .. missingCount .. " missing sections, keeping bulkSyncTimestamp")
        
        -- Request missing sections through whisper to sender
        self:Debug("sync", "Requesting " .. missingCount .. " missing sections from " .. sender)
        self:RequestMissingSectionsWhisper(sender, timestamp)
    end
    
    -- Clear structure reference if we successfully processed the structure
    if TWRA_CompressedAssignments.structureReference then
        self:Debug("sync", "Clearing structure reference after successful processing")
        TWRA_CompressedAssignments.structureReference = nil
    end
    
    return true
end

-- Handler for SECTION command to change the current section
function TWRA:HandleSectionCommand(timestamp, sectionIndex, sender)
    -- Add debug statement right at the start
    self:Debug("sync", "HandleSectionCommand called with sectionIndex: " .. sectionIndex .. 
              ", timestamp: " .. timestamp .. " from " .. sender)
    
    -- Convert to numbers (default to 0 if conversion fails)
    local sectionIndexNum = tonumber(sectionIndex)
    local timestampNum = tonumber(timestamp)
    
    if not sectionIndexNum then
        self:Debug("sync", "Failed to convert section index to number: " .. sectionIndex)
        return
    end
    
    if not timestampNum then
        self:Debug("sync", "Failed to convert timestamp to number: " .. timestamp)
        return
    end
    
    sectionIndex = sectionIndexNum
    timestamp = timestampNum
    
    -- Always debug what we received
    self:Debug("sync", string.format("Section change from %s (index: %d, timestamp: %d)", 
        sender, sectionIndex, timestamp))
    
    -- Get our own timestamp for comparison
    local ourTimestamp = TWRA_Assignments and TWRA_Assignments.timestamp or 0

    -- Debug the timestamp comparison
    self:Debug("sync", "Comparing timestamps - Received: " .. timestamp .. 
               " vs Our: " .. ourTimestamp)
    
    -- Compare timestamps and act accordingly
    local comparisonResult = self:CompareTimestamps(ourTimestamp, timestamp)
    
    if comparisonResult == 0 then
        -- Timestamps match - navigate to the section
        self:Debug("sync", "Timestamps match - navigating to section " .. sectionIndex)
        self:NavigateToSection(sectionIndex, "fromSync")
        
    elseif comparisonResult > 0 then
        -- We have a newer version - just log it and don't navigate
        self:Debug("sync", "We have a newer version (timestamp " .. ourTimestamp .. 
                  " > " .. timestamp .. "), ignoring section change")
    
    else -- comparisonResult < 0
        -- They have a newer version - LOG ONLY, NO SYNC REQUEST
        self:Debug("sync", "Detected newer data from " .. sender .. " (timestamp " .. 
                  timestamp .. " > " .. ourTimestamp .. "), but automatic sync is disabled")
        
        -- Only store the section index for reference, but don't trigger sync
        self.SYNC.pendingSection = sectionIndex
        self:Debug("sync", "User must manually request newer data using /twra sync")
    end
end

