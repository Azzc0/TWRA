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
        VER = self.HandleVersionCommand, -- Version check handler
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
    -- Add detailed debug logging
    self:Debug("sync", "Received addon message: '" .. message .. "' from " .. sender)
    
    -- Shared initial processing for all message types
    if not message or message == "" then
        self:Debug("error", "Empty message received from " .. sender)
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
        self:Debug("error", "Invalid message format: " .. message)
        return
    end
    
    -- Extract command and log it explicitly
    local command = components[1]
    self:Debug("sync", "Extracted command: '" .. command .. "' from message")
    
    -- For troubleshooting, output the actual SYNC.COMMANDS values
    self:Debug("sync", "Expected BULK_SYNC_REQ value: '" .. (self.SYNC.COMMANDS.BULK_SYNC_REQ or "nil") .. "'")
    self:Debug("sync", "Expected BULK_SYNC_ACK value: '" .. (self.SYNC.COMMANDS.BULK_SYNC_ACK or "nil") .. "'")
    
    -- Log all components for debugging
    local componentsStr = ""
    for i, comp in ipairs(components) do
        componentsStr = componentsStr .. "[" .. i .. "]:" .. comp .. " "
    end
    self:Debug("sync", "Message components: " .. componentsStr)
    
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
    
    -- Direct handling for BULK_SYNC_REQUEST (BSREQ)
    if command == "BSREQ" then
        self:Debug("sync", "Detected BSREQ command directly, handling bulk sync request from " .. sender)
        -- Check if the request includes a timestamp (format: BSREQ:timestamp)
        local requesterTimestamp = components[2] and tonumber(components[2]) or 0
        
        -- Handle the request with the timestamp parameter
        if requesterTimestamp and requesterTimestamp > 0 then
            self:Debug("sync", "Bulk sync request includes timestamp: " .. requesterTimestamp)
            self:HandleBulkSyncRequestCommand(sender, requesterTimestamp)
        else
            self:Debug("sync", "Bulk sync request has no timestamp or timestamp is 0")
            self:HandleBulkSyncRequestCommand(sender)
        end
        return
    end
    
    -- Direct handling for BULK_SYNC_ACK (BSACK)
    if command == "BSACK" then
        self:Debug("sync", "Detected BSACK command directly, handling bulk sync acknowledgment")
        if components[2] and components[3] then
            self:HandleBulkSyncAckCommand(components[2], components[3], sender)
        else
            self:Debug("error", "Invalid BSACK format - missing parameters")
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
        -- Handle BSREQ (bulk sync request) - direct routing
        if self.HandleBulkSyncRequestCommand then
            self:Debug("sync", "Routing BSREQ command directly to handler")
            self:HandleBulkSyncRequestCommand(sender)
        end
    elseif command == self.SYNC.COMMANDS.BULK_SYNC_ACK then
        -- Handle BSACK (bulk sync acknowledgment) - direct routing
        if self.HandleBulkSyncAckCommand then
            self:Debug("sync", "Routing BSACK command directly to handler")
            self:HandleBulkSyncAckCommand(components[2], components[3], sender)
        end
    else
        -- Try using the handler map for other commands
        local handler = self.syncHandlers[command]
        if handler then
            self:Debug("sync", "Using handler map for command: " .. command)
            handler(self, components, sender)
        else
            self:Debug("error", "Unknown command: '" .. command .. "'")
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
    
    -- Store the current section index we might want to navigate to
    local targetSectionIndex = nil
    
    -- Check if we have a pending section from a previous request
    if self.SYNC and self.SYNC.pendingSection then
        targetSectionIndex = self.SYNC.pendingSection
        self:Debug("sync", "Found pending section: " .. targetSectionIndex)
    else
        -- Default to current section or first section
        targetSectionIndex = TWRA_Assignments and TWRA_Assignments.currentSection or 1
    end
    
    -- Validate that the target section exists in the decoded structure
    local targetSectionExists = false
    if targetSectionIndex and type(targetSectionIndex) == "number" then
        if decodedStructure and decodedStructure[targetSectionIndex] then
            targetSectionExists = true
            self:Debug("sync", "Target section " .. targetSectionIndex .. " exists in structure")
        else
            self:Debug("sync", "Target section " .. targetSectionIndex .. " not found in structure, defaulting to first section")
            targetSectionIndex = 1
        end
    end
    
    if hasSections then
        self:Debug("sync", "Sections available after receiving bulk structure")
        
        -- Process all available section data
        self:ProcessSectionData()
        
        -- Navigate to the target section after processing all data
        if self.NavigateToSection and targetSectionIndex then
            -- Use "fromSync" context to prevent broadcast
            self:Debug("sync", "Navigating to target section " .. targetSectionIndex .. " with 'fromSync' context to prevent broadcasting")
            self:NavigateToSection(targetSectionIndex, "fromSync")
            
            -- Clear the pending section as we've now navigated to it
            if self.SYNC then
                self.SYNC.pendingSection = nil
                self:Debug("sync", "Cleared pendingSection after navigation")
            end
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
            
            -- Navigate to the target section even if we have no section data
            if self.NavigateToSection and targetSectionIndex then
                self:NavigateToSection(targetSectionIndex, "bulkSyncNoData")
                self:Debug("sync", "Navigated to target section " .. targetSectionIndex .. " (no section data)")
                
                -- Clear the pending section as we've now navigated to it
                if self.SYNC then
                    self.SYNC.pendingSection = nil
                    self:Debug("sync", "Cleared pendingSection after navigation (no data case)")
                end
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
    
    -- ANTI-LOOP: Skip processing of our own messages or if we're already processing a sync
    if sender == UnitName("player") then
        self:Debug("sync", "Ignoring our own section command")
        return
    end
    
    -- ANTI-LOOP: Skip if we're currently in a sync operation
    if self.SYNC.syncInProgress then
        self:Debug("sync", "Ignoring section command - sync already in progress")
        return
    end
    
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
        -- They have a newer version - auto-request sync if outside cooldown period
        self:Debug("sync", "Detected newer data from " .. sender .. " (timestamp " .. 
                  timestamp .. " > " .. ourTimestamp .. ")")
        
        -- Store the section index for reference
        self.SYNC.pendingSection = sectionIndex
        
        -- Initialize the lastNewerTimestampReaction variable if it doesn't exist
        if not self.SYNC.lastNewerTimestampReaction then
            self.SYNC.lastNewerTimestampReaction = 0
        end
        
        -- Get current time
        local now = GetTime()
        
        -- Check if we're outside the cooldown period (30 seconds)
        if (now - self.SYNC.lastNewerTimestampReaction) > 30 then
            -- We're outside the cooldown period, so we can request a sync
            self.SYNC.lastNewerTimestampReaction = now
            
            -- ANTI-LOOP: Set syncInProgress flag BEFORE making the request
            -- This prevents multiple requests being triggered during processing
            self.SYNC.syncInProgress = true
            
            self:Debug("sync", "Outside 30-second cooldown period, auto-requesting bulk sync to get newer data")
            
            -- Request bulk sync to get newer data
            if self.RequestBulkSync then
                self:RequestBulkSync()
                
                -- Set a safety timeout to clear syncInProgress after 15 seconds if something goes wrong
                self:ScheduleTimer(function()
                    self:Debug("sync", "Safety timeout: clearing syncInProgress flag from section handler")
                    self.SYNC.syncInProgress = false
                end, 15)
            else
                self:Debug("error", "RequestBulkSync function not available")
                self.SYNC.syncInProgress = false -- Clear the flag if we couldn't make the request
            end
        else
            -- We're still in the cooldown period
            local remainingCooldown = 30 - (now - self.SYNC.lastNewerTimestampReaction)
            self:Debug("sync", "Detected newer timestamp but still in " .. math.floor(remainingCooldown) .. 
                      "-second cooldown. User can manually request sync with /twra sync")
        end
    end
end

-- Function to handle bulk sync request (BSREQ)
function TWRA:HandleBulkSyncRequestCommand(sender, requesterTimestamp)
    -- Basic validation
    if not sender then
        self:Debug("error", "HandleBulkSyncRequestCommand called with no valid sender")
        return false
    end
    
    -- Skip processing our own requests
    if sender == UnitName("player") then
        self:Debug("sync", "Ignoring bulk sync request from ourselves")
        return false
    end
    
    self:Debug("sync", "Received bulk sync request from " .. sender)
    
    -- ANTI-LOOP: Check if we've already received and processed this request
    local now = GetTime()
    
    -- Initialize tracking table if it doesn't exist
    self.SYNC.processedBulkRequests = self.SYNC.processedBulkRequests or {}
    
    -- Track specific sender+timestamp combinations
    local requestKey = sender .. "_" .. math.floor(now) -- Truncate to seconds for better duplicate detection
    
    -- If this exact request was processed in the last 60 seconds, ignore it completely
    if self.SYNC.processedBulkRequests[requestKey] then
        self:Debug("sync", "Already processed a bulk request from " .. sender .. " in the last minute, ignoring duplicate")
        return false
    end
    
    -- Mark this request as processed IMMEDIATELY to prevent any chance of duplicate processing
    self.SYNC.processedBulkRequests[requestKey] = now
    
    -- Clean up old entries from tracking table (older than 60 seconds)
    for key, timestamp in pairs(self.SYNC.processedBulkRequests) do
        if now - timestamp > 60 then
            self.SYNC.processedBulkRequests[key] = nil
        end
    end
    
    -- Check if we have data to respond with
    if not TWRA_Assignments or not TWRA_Assignments.data then
        self:Debug("sync", "No assignments data available to share")
        return false
    end
    
    -- Check if we have compressed assignments data
    if not TWRA_CompressedAssignments or not TWRA_CompressedAssignments.sections then
        self:Debug("sync", "No compressed assignments data available to share")
        return false
    end
    
    -- Get our timestamp
    local ourTimestamp = TWRA_Assignments.timestamp or 0
    
    -- NEW: Check if requester provided their timestamp and compare
    if requesterTimestamp and tonumber(requesterTimestamp) > 0 then
        -- Convert to number if it's not already
        requesterTimestamp = tonumber(requesterTimestamp)
        
        self:Debug("sync", "Comparing timestamps - Our: " .. ourTimestamp .. " vs Requester: " .. requesterTimestamp)
        
        -- Compare our timestamp with the requester's timestamp
        local comparison = self:CompareTimestamps(ourTimestamp, requesterTimestamp)
        
        if comparison <= 0 then
            -- Our data is the same or older than the requester's data
            self:Debug("sync", "Our data (" .. ourTimestamp .. ") is not newer than requester's data (" .. 
                      requesterTimestamp .. "). Not responding.")
            return false
        else
            -- Our data is newer, proceed with response
            self:Debug("sync", "Our data (" .. ourTimestamp .. ") is newer than requester's data (" .. 
                      requesterTimestamp .. "). Will respond.")
        end
    else
        -- No timestamp provided, assume requester needs data
        self:Debug("sync", "No valid timestamp provided by requester, assuming they need data")
    end
    
    -- Count how many sections we have vs. how many we should have
    local sectionsWeHave = 0
    for sectionIndex, _ in pairs(TWRA_CompressedAssignments.sections) do
        if type(sectionIndex) == "number" then
            sectionsWeHave = sectionsWeHave + 1
        end
    end
    
    -- Count how many sections should be in the structure
    local expectedSections = 0
    for sectionIndex, _ in pairs(TWRA_Assignments.data) do
        if type(sectionIndex) == "number" then
            expectedSections = expectedSections + 1
        end
    end
    
    -- Check if we have all expected sections
    if sectionsWeHave < expectedSections then
        self:Debug("sync", "Not responding to bulk sync request - we only have " .. 
                  sectionsWeHave .. " of " .. expectedSections .. " expected sections")
        return false
    end
    
    -- Verify that every section has data
    local missingData = false
    for sectionIndex, _ in pairs(TWRA_Assignments.data) do
        if type(sectionIndex) == "number" then
            if not TWRA_CompressedAssignments.sections[sectionIndex] then
                missingData = true
                self:Debug("sync", "Missing compressed data for section " .. sectionIndex)
                break
            end
        end
    end
    
    if missingData then
        self:Debug("sync", "Not responding to bulk sync request - missing compressed data for some sections")
        return false
    end
    
    -- CRITICAL: Prevent multiple active sync sessions
    if self.SYNC.syncInProgress then
        self:Debug("sync", "Another sync is already in progress, ignoring this request")
        return false
    end
    
    -- Mark that sync is now in progress to prevent multiple simultaneous responses
    self.SYNC.syncInProgress = true
    
    -- All checks passed, we can respond
    -- Send acknowledgment with our timestamp
    local ackMessage = self:CreateBulkSyncAckMessage(ourTimestamp, UnitName("player"))
    self:SendAddonMessage(ackMessage)
    self:Debug("sync", "Sent bulk sync acknowledgment with timestamp " .. ourTimestamp)
    
    -- IMPORTANT: Clean up old timer if there's one running
    if self.SYNC.pendingBulkResponse and self.SYNC.pendingBulkResponse.timer then
        self:CancelTimer(self.SYNC.pendingBulkResponse.timer)
        self.SYNC.pendingBulkResponse.timer = nil
    end
    
    -- Set up a delayed response
    -- The delay is set to 2 seconds as requested to reduce unnecessary wait time
    local responseDelay = 2 + (math.random() * 0.5) -- Base delay 2-2.5 seconds
    
    -- Store our response info
    self.SYNC.pendingBulkResponse = {
        timestamp = ourTimestamp,
        requester = sender,
        responseTime = now,
        timer = self:ScheduleTimer(function()
            -- Check if someone with a newer timestamp has already responded
            if self.SYNC.newerTimestampResponded and self.SYNC.newerTimestampResponded > ourTimestamp then
                self:Debug("sync", "Not sending bulk data - someone with newer timestamp already responded: " .. 
                          self.SYNC.newerTimestampResponded .. " > " .. ourTimestamp)
                self.SYNC.syncInProgress = false
                return
            end
            
            -- We have the newest timestamp (or tied), send the data
            self:Debug("sync", "We have the newest data, sending all sections")
            local success = self:SendAllSections()
            
            -- IMPORTANT: Clear the sync in progress flag AFTER sending completes
            self.SYNC.syncInProgress = false
            
            -- Log the result
            if success then
                self:Debug("sync", "Successfully sent all sections, sync complete")
            else
                self:Debug("error", "Failed to send all sections")
            end
            
            -- IMPORTANT: Schedule cleanup of state variables
            self:ScheduleTimer(function()
                self:Debug("sync", "Cleaning up bulk sync state variables")
                self.SYNC.newerTimestampResponded = nil
                self.SYNC.pendingBulkResponse = nil
            end, 5) -- Clean up 5 seconds after sending
        end, responseDelay)
    }
    
    -- Setup safety timeout to clear syncInProgress flag if something goes wrong
    self:ScheduleTimer(function()
        if self.SYNC.syncInProgress then
            self:Debug("sync", "Safety timeout: clearing syncInProgress flag")
            self.SYNC.syncInProgress = false
        end
    end, responseDelay + 30) -- 30 seconds after expected response time
    
    self:Debug("sync", "Will respond with all sections in " .. responseDelay .. " seconds unless someone with newer data responds")
    
    return true
end

-- Function to handle bulk sync acknowledgment (BSACK)
function TWRA:HandleBulkSyncAckCommand(components, sender)
    -- Parse parameters - could be (timestamp, sender) or (components, sender) or (components)
    local timestamp
    local acknowledgedBy
    
    if type(components) == "table" then
        -- If it's a components array
        timestamp = components[2]
        acknowledgedBy = components[3] or sender
    else
        -- If it's direct parameters
        timestamp = components
        acknowledgedBy = sender
    end
    
    -- Ensure we have valid values
    if not timestamp then
        self:Debug("error", "Missing timestamp in BSACK command")
        return false
    end
    
    if not acknowledgedBy then
        acknowledgedBy = "Unknown"
    end
    
    self:Debug("sync", "Received bulk sync acknowledgment from " .. acknowledgedBy .. " with timestamp " .. timestamp)
    
    -- Convert timestamp to number
    timestamp = tonumber(timestamp)
    if not timestamp then
        self:Debug("error", "Invalid timestamp format in bulk sync acknowledgment")
        return false
    end
    
    -- Cancel the timeout timer since someone is responding
    if self.SYNC.bulkSyncRequestTimeout then
        self:CancelTimer(self.SYNC.bulkSyncRequestTimeout)
        self.SYNC.bulkSyncRequestTimeout = nil
    end
    
    -- Record this acknowledgment
    self.SYNC.bulkSyncAcknowledgments = self.SYNC.bulkSyncAcknowledgments or {}
    self.SYNC.bulkSyncAcknowledgments[acknowledgedBy] = timestamp
    
    -- Update the newest timestamp seen
    if not self.SYNC.newerTimestampResponded or timestamp > self.SYNC.newerTimestampResponded then
        self.SYNC.newerTimestampResponded = timestamp
    end
    
    -- If we're the requester, show a message about the response
    if self.SYNC.lastRequestTime and (GetTime() - self.SYNC.lastRequestTime < 15) then
        self:Debug("sync", acknowledgedBy .. " acknowledged with timestamp " .. timestamp)
        
        -- IMPORTANT: Schedule cleanup of requester state variables to prevent recurring sync loops
        local cleanupTime = 15 -- 15 seconds cleanup time
        self:ScheduleTimer(function()
            self:Debug("sync", "Cleaning up requester state variables")
            self.SYNC.bulkSyncAcknowledgments = {}
            self.SYNC.newerTimestampResponded = nil
        end, cleanupTime)
    end
    
    -- If we have a pending response and the incoming timestamp is newer than ours, cancel our response
    if self.SYNC.pendingBulkResponse and timestamp > self.SYNC.pendingBulkResponse.timestamp then
        self:Debug("sync", "Canceling our pending response - " .. acknowledgedBy .. 
                  " has newer data (" .. timestamp .. " > " .. self.SYNC.pendingBulkResponse.timestamp .. ")")
        
        if self.SYNC.pendingBulkResponse.timer then
            self:CancelTimer(self.SYNC.pendingBulkResponse.timer)
            self.SYNC.pendingBulkResponse.timer = nil
        end
        
        self.SYNC.pendingBulkResponse = nil
        
        -- Since we're canceling our response, also clear sync in progress flag
        self.SYNC.syncInProgress = false
    end
    
    return true
end

-- Function to handle version check messages
-- @param versionString The version string from sender 
-- @param sender The player who sent the message
function TWRA:HandleVersionCommand(versionString, sender)
    self:Debug("sync", "Received version check from " .. sender .. ": " .. versionString)
    
    if not versionString then
        self:Debug("error", "Invalid version check - missing version string")
        return false
    end
    
    -- Parse the version components (format: MAJOR.MINOR.PATCH)
    local major, minor, patch = 0, 0, 0
    
    -- Use string.gfind instead of string.match (Lua 5.0 compatible)
    local parts = {}
    local index = 1
    for part in string.gfind(versionString, "([^.]+)") do
        parts[index] = tonumber(part) or 0
        index = index + 1
    end
    
    -- Extract version components
    major = parts[1] or 0
    minor = parts[2] or 0
    patch = parts[3] or 0
    
    -- Get our version information
    local ourMajor = self.VERSION.MAJOR or 0
    local ourMinor = self.VERSION.MINOR or 0
    local ourPatch = self.VERSION.PATCH or 0
    
    -- Check version compatibility
    local isCompatible = true
    local isOlder = false
    local isNewer = false
    
    -- Version is incompatible if major versions don't match
    if major ~= ourMajor then
        isCompatible = false
        if major < ourMajor then
            isOlder = true
        else
            isNewer = true
        end
    -- If major versions match but minor versions don't, check compatibility threshold
    elseif minor ~= ourMinor then
        -- If their minor version is less than our DATA_COMPAT, it's incompatible
        if minor < self.VERSION.DATA_COMPAT then
            isCompatible = false
            isOlder = true
        -- If their minor version is greater than ours, we're the older one
        elseif minor > ourMinor then
            isNewer = true
        end
    -- If major and minor match but patch is different, they're compatible but one is newer
    elseif patch ~= ourPatch then
        if patch > ourPatch then
            isNewer = true
        else
            isOlder = true
        end
    end
    
    -- Log the compatibility result
    if not isCompatible then
        if isOlder then
            self:Debug("error", sender .. " is using an older incompatible version: " .. versionString)
            -- Respond with our version to inform them
            self:SendVersionResponse(sender, true)
        else
            self:Debug("error", sender .. " is using a newer incompatible version: " .. versionString)
            -- Store that we've seen a newer version
            self.SYNC.hasSeenNewerVersion = true
            self.SYNC.newerVersionString = versionString
        end
    else
        if isNewer then
            self:Debug("sync", sender .. " is using a newer compatible version: " .. versionString)
            -- Store that we've seen a newer version
            self.SYNC.hasSeenNewerVersion = true
            self.SYNC.newerVersionString = versionString
        elseif isOlder then
            self:Debug("sync", sender .. " is using an older compatible version: " .. versionString)
        else
            self:Debug("sync", sender .. " is using the same version: " .. versionString)
        end
    end
    
    -- Notify the user if an incompatible version is detected
    if not isCompatible then
        local messageColor
        local message
        
        if isOlder then
            messageColor = "FF9900" -- Orange for warning
            message = sender .. " is using an older incompatible version (" .. versionString .. "). They may not be able to see your assignments correctly."
        else
            messageColor = "FF0000" -- Red for error
            message = sender .. " is using a newer incompatible version (" .. versionString .. "). You should update your TWRA addon."
        end
        
        -- Send a clear visual message to the user
        local formattedMessage = "|cFF33FF99TWRA|r |cFF" .. messageColor .. "VERSION MISMATCH:|r " .. message
        DEFAULT_CHAT_FRAME:AddMessage(formattedMessage)
    end
    
    return true
end

-- Function to check version compatibility with other raid/party members
function TWRA:CheckVersionCompatibility()
    self:Debug("sync", "Checking version compatibility with group members")
    
    -- Send version check to appropriate channel
    local channel = "RAID"
    
    -- If not in a raid, try party
    if not UnitInRaid("player") then
        if GetNumPartyMembers() > 0 then
            channel = "PARTY"
        else
            self:Debug("sync", "Not in a raid or party, skipping version check")
            return
        end
    end
    
    -- Send our version to the group
    local versionMessage = self:CreateVersionMessage(self.VERSION.STRING)
    self:SendAddonMessage(versionMessage, channel)
    self:Debug("sync", "Sent version check to " .. channel .. ": " .. self.VERSION.STRING)
end

-- Function to send a version response to a specific player
function TWRA:SendVersionResponse(target, isIncompatible)
    if not target then return end
    
    -- Send our version to the specified player
    local versionMessage = self:CreateVersionMessage(self.VERSION.STRING, isIncompatible)
    self:SendAddonMessage(versionMessage, "WHISPER", target)
    self:Debug("sync", "Sent version response to " .. target .. ": " .. self.VERSION.STRING)
end

-- Function to create a version message
function TWRA:CreateVersionMessage(versionString, isIncompatible)
    local suffix = isIncompatible and ":INCOMPATIBLE" or ""
    return self.SYNC.COMMANDS.VERSION .. ":" .. versionString .. suffix
end