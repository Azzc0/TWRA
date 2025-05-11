-- TWRA Chunk Testing
-- This file contains test functions for the chunk system
-- These are isolated from core addon files to keep tests separate from main code
TWRA = TWRA or {}

-- Initialize tests
function TWRA:InitializeChunkTests()
    self:Debug("sync", "Initializing chunk tests")
    
    -- Enhance chunk manager for better test handling
    self:EnhanceChunkManagerForTests()
    
    self:Debug("sync", "Chunk tests initialized")
    DEFAULT_CHAT_FRAME:AddMessage("|cFF33FFFF[TWRA Tests]|r Chunk testing initialized. You can run tests with |cFFFFFF00/run TWRA:TestChunkSync()|r and |cFFFFFF00/run TWRA:TestChunkCompletion()|r")
    
    return true
end

-- Function to enhance the chunk manager for better test handling
function TWRA:EnhanceChunkManagerForTests()
    self:Debug("sync", "Enhancing ChunkManager for testing")
    self:Debug("chunk", "Enhancing ChunkManager for testing")
    
    -- Ensure the chunk manager is initialized
    if not self.chunkManager then
        self.chunkManager = self.chunkManager or {}
        self.chunkManager:Initialize()
    end
    
    -- Enhance debug capabilities during tests
    self.chunkManager.testMode = true
    
    -- Store the test transfer ID when created
    self.chunkManager.testTransferId = nil
    
    self:Debug("sync", "ChunkManager enhanced for testing")
    self:Debug("chunk", "ChunkManager enhanced for testing")
    return true
end

-- ChunkTestS: Splits content into small chunks (max 10 bytes) and sends them
-- @param content The string content to be split and transmitted
-- @return transferId The unique ID for this chunked transfer
function TWRA:ChunkTestS(content)
    if not content or type(content) ~= "string" then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF33FFFF[TWRA Chunk Test]|r |cFFFF0000ERROR:|r Invalid content. Must provide a string.")
        return nil
    end

    self:Debug("sync", "----- CHUNK TEST S: Starting with content size " .. string.len(content) .. " bytes -----")
    
    -- Ensure ChunkManager exists
    if not self.chunkManager then
        self:Debug("error", "CHUNK TEST S: ChunkManager not available, initializing it now")
        self.chunkManager = self.chunkManager or {}
        self.chunkManager:Initialize()
    end
    
    -- Override the maxChunkSize temporarily for this test
    local originalMaxChunkSize = self.chunkManager.maxChunkSize
    self.chunkManager.maxChunkSize = 10 -- Force small chunks of 10 bytes each
    
    -- Determine communication channel
    local channel = GetNumRaidMembers() > 0 and "RAID" or 
                   (GetNumPartyMembers() > 0 and "PARTY" or "GUILD")
    
    -- Send the content using ChunkContent and capture the returned transferId
    local transferId = self.chunkManager:ChunkContent(content, channel, nil, nil)
    
    -- Restore the original chunk size
    self.chunkManager.maxChunkSize = originalMaxChunkSize
    
    -- Store the content for verification
    self.chunkManager.testContent = content
    
    -- Store the test transfer ID for later reference
    self.chunkManager.testTransferId = transferId
    
    -- Display transfer ID to chat
    DEFAULT_CHAT_FRAME:AddMessage("|cFF33FFFF[TWRA Chunk Test]|r Started chunked transfer with ID: |cFFFFFF00" .. transferId .. "|r")
     DEFAULT_CHAT_FRAME:AddMessage("|cFF33FFFF[TWRA Chunk Test]|r Run this command on the other client: /run TWRA:ChunkTestR('" .. transferId .. "')")
    self:Debug("sync", "CHUNK TEST S: Transfer ID: " .. transferId)
    self:Debug("sync", "Run this command on the other client: /run TWRA:ChunkTestR('" .. transferId .. "')")
    
    return transferId
end

-- ChunkTestR: Retrieves chunk data from a given transfer ID
-- @param transferId The ID of the transfer to retrieve
-- @return content The content if successful, nil otherwise
function TWRA:ChunkTestR(transferId)
    if not transferId or type(transferId) ~= "string" then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF33FFFF[TWRA Chunk Test]|r |cFFFF0000ERROR:|r Invalid transfer ID. Must provide a string.")
        return nil
    end

    self:Debug("sync", "----- CHUNK TEST R: Retrieving for transfer ID " .. transferId .. " -----")
    
    -- Ensure the chunk manager is initialized
    if not self.chunkManager then
        self:Debug("error", "CHUNK TEST R: ChunkManager not available")
        DEFAULT_CHAT_FRAME:AddMessage("|cFF33FFFF[TWRA Chunk Test]|r |cFFFF0000ERROR:|r ChunkManager not available")
        return nil
    end
    
    self:Debug("chunk", "CHUNK TEST R: ChunkManager available")
    
    -- Process chunks before retrieving if they exist but aren't stored yet
    if self.chunkManager.receivingChunks and self.chunkManager.receivingChunks[transferId] then
        local isComplete = (self.chunkManager.receivingChunks[transferId].received == 
                            self.chunkManager.receivingChunks[transferId].expected)
        
        if isComplete then
            self:Debug("chunk", "CHUNK TEST R: Found complete chunks, processing before retrieval")
            self.chunkManager:ProcessChunks(transferId, false)
        else
            self:Debug("chunk", "CHUNK TEST R: Found incomplete chunks, cannot retrieve yet")
            DEFAULT_CHAT_FRAME:AddMessage("|cFF33FFFF[TWRA Chunk Test]|r |cFFFF0000ERROR:|r Transfer incomplete: " .. 
                                          self.chunkManager.receivingChunks[transferId].received .. "/" .. 
                                          self.chunkManager.receivingChunks[transferId].expected .. " chunks received")
            return nil
        end
    else
        self:Debug("chunk", "CHUNK TEST R: No incomplete chunks found, proceeding to retrieve")
    end
    
    -- Check if the data exists in storedChunkData first
    if self.chunkManager.storedChunkData and self.chunkManager.storedChunkData[transferId] then
        self:Debug("chunk", "CHUNK TEST R: Found stored data for this transfer ID")
    else
        self:Debug("chunk", "CHUNK TEST R: No stored data found for this transfer ID yet")
        
        -- List available transfers for debugging
        local availableIds = ""
        local transferCount = 0
        if self.chunkManager.storedChunkData then
            for id, _ in pairs(self.chunkManager.storedChunkData) do
                transferCount = transferCount + 1
                if availableIds ~= "" then
                    availableIds = availableIds .. ", "
                end
                availableIds = availableIds .. id
            end
            self:Debug("chunk", "CHUNK TEST R: Available transfers (" .. transferCount .. "): " .. (availableIds ~= "" and availableIds or "none"))
        end
    end
    
    -- Actually retrieve the chunk data
    self:Debug("chunk", "CHUNK TEST R: Calling RetrieveChunkData on ChunkManager...")
    local content = self.chunkManager:RetrieveChunkData(transferId)
    
    -- Debug the result
    if content then
        self:Debug("chunk", "CHUNK TEST R: Successfully retrieved content with length: " .. string.len(content))
        self:Debug("sync", "CHUNK TEST R: Successfully retrieved data for transfer ID " .. transferId)
        DEFAULT_CHAT_FRAME:AddMessage("|cFF33FFFF[TWRA Chunk Test]|r Successfully retrieved data with size " .. string.len(content) .. " bytes")
        
        -- Print out the retrieved content to verify it's valid
        DEFAULT_CHAT_FRAME:AddMessage("|cFF33FFFF[TWRA Chunk Test]|r Content: " .. content)
        
        return content
    else
        self:Debug("error", "CHUNK TEST R: Failed to retrieve data for transfer ID " .. transferId)
        DEFAULT_CHAT_FRAME:AddMessage("|cFF33FFFF[TWRA Chunk Test]|r |cFFFF0000ERROR:|r Failed to retrieve data")
        
        -- Add diagnostic information
        local availableIds = ""
        if self.chunkManager.storedChunkData then
            for id, _ in pairs(self.chunkManager.storedChunkData) do
                availableIds = availableIds .. id .. ", "
            end
            DEFAULT_CHAT_FRAME:AddMessage("|cFF33FFFF[TWRA Chunk Test]|r Available transfers: " .. (availableIds ~= "" and availableIds or "none"))
        end
        
        return nil
    end
end

-- Test function to send a test message in chunks to test the chunk system
function TWRA:TestChunkSync()
    self:Debug("sync", "----- CHUNK SYNC TEST: Starting sender test -----")
    self:Debug("chunk", "----- CHUNK SYNC TEST: Starting sender test -----")
    
    -- Make sure ChunkManager exists
    if not self.chunkManager then
        self:Debug("error", "CHUNK SYNC TEST: ChunkManager not available, initializing it now")
        self.chunkManager = self.chunkManager or {}
        self.chunkManager:Initialize()
    end
    
    -- Enable test mode
    self:EnhanceChunkManagerForTests()
    
    -- Create a test message deliberately longer than the max chunk size
    -- but split into a specific number of chunks for testing
    local testMessage = "My pinapple is strawberry flavoured and tastes like chocolate"
    
    -- Generate a unique test transfer ID
    local testTransferId = "TEST_CHUNK_" .. tostring(time()) .. "_" .. tostring(math.random(1000, 9999))
    
    -- Store the test transfer ID for reference
    self.chunkManager.testTransferId = testTransferId
    
    -- Determine chunk size to force a specific number of chunks (using 7 chunks for test)
    local numTestChunks = 7
    local chunkSize = math.floor(string.len(testMessage) / numTestChunks)
    if chunkSize < 1 then chunkSize = 5 end -- Minimum size
    
    self:Debug("sync", "CHUNK SYNC TEST: Sending test message with " .. numTestChunks .. " chunks of size " .. chunkSize .. " bytes")
    self:Debug("chunk", "CHUNK SYNC TEST: Test message: '" .. testMessage .. "'")
    self:Debug("chunk", "CHUNK SYNC TEST: Message length: " .. string.len(testMessage) .. " bytes")
    self:Debug("chunk", "CHUNK SYNC TEST: Transfer ID: " .. testTransferId)
    
    -- Override the maxChunkSize temporarily for this test
    local originalMaxChunkSize = self.chunkManager.maxChunkSize
    self.chunkManager.maxChunkSize = chunkSize
    
    -- Send the test message
    local channel = GetNumRaidMembers() > 0 and "RAID" or 
                   (GetNumPartyMembers() > 0 and "PARTY" or "GUILD")
    
    -- Determine if we're in a group, if not use GUILD
    if GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 then
        channel = "GUILD"
        self:Debug("sync", "CHUNK SYNC TEST: Not in a group, using GUILD channel for test")
        self:Debug("chunk", "CHUNK SYNC TEST: Not in a group, using GUILD channel for test")
    end
    
    -- Use the ChunkContent method to send the test
    self.chunkManager:ChunkContent(testMessage, channel, nil, nil)
    
    -- Restore the original chunk size
    self.chunkManager.maxChunkSize = originalMaxChunkSize
    
    self:Debug("sync", "CHUNK SYNC TEST: Test message sent via " .. channel)
    self:Debug("chunk", "CHUNK SYNC TEST: Test message sent via " .. channel)
    
    -- Inform the user
    DEFAULT_CHAT_FRAME:AddMessage("|cFF33FFFF[TWRA Chunk Test]|r Started chunk transfer test: Sending " .. 
                                   numTestChunks .. " chunks with size of " .. chunkSize .. 
                                   " bytes each. The other client should see them and can then run |cFFFFFF00/run TWRA:TestChunkCompletion()|r")
    
    self:Debug("sync", "----- CHUNK SYNC TEST: Sender test complete -----")
    self:Debug("chunk", "----- CHUNK SYNC TEST: Sender test complete -----")
    
    return testTransferId
end

-- Test function to verify received chunks are correctly processed
function TWRA:TestChunkCompletion()
    self:Debug("sync", "----- CHUNK SYNC TEST: Starting receiver verification -----")
    self:Debug("chunk", "----- CHUNK SYNC TEST: Starting receiver verification -----")
    
    -- Make sure ChunkManager exists
    if not self.chunkManager then
        self:Debug("error", "CHUNK SYNC TEST: ChunkManager not available, test cannot continue")
        self:Debug("chunk", "CHUNK SYNC TEST: ChunkManager not available, test cannot continue")
        return false
    end
    
    -- Find chunks that start with TEST_CHUNK prefix
    local foundTransferId = nil
    local receivedChunks = nil
    
    self:Debug("chunk", "CHUNK SYNC TEST: Checking for TEST_CHUNK transfers in receivingChunks table")
    self:Debug("chunk", "CHUNK SYNC TEST: Number of transfers in receiving queue: " .. (self:TableCount(self.chunkManager.receivingChunks or {}) or 0))
    
    for transferId, info in pairs(self.chunkManager.receivingChunks or {}) do
        self:Debug("chunk", "CHUNK SYNC TEST: Examining transfer: " .. transferId)
        if string.find(transferId, "TEST_CHUNK_") then
            foundTransferId = transferId
            receivedChunks = info
            self:Debug("sync", "CHUNK SYNC TEST: Found test transfer: " .. transferId)
            self:Debug("chunk", "CHUNK SYNC TEST: Found test transfer: " .. transferId)
            break
        end
    end
    
    if not foundTransferId or not receivedChunks then
        self:Debug("error", "CHUNK SYNC TEST: No test chunk transfer found in receivingChunks. Checking storedChunkData...")
        self:Debug("chunk", "CHUNK SYNC TEST: No test chunk transfer found in receivingChunks. Checking storedChunkData...")
        
        -- Check in storedChunkData using the RetrieveChunkData function
        for transferId, _ in pairs(self.chunkManager.storedChunkData or {}) do
            if string.find(transferId, "TEST_CHUNK_") then
                foundTransferId = transferId
                self:Debug("chunk", "CHUNK SYNC TEST: Found test transfer in storedChunkData: " .. transferId)
                
                -- Retrieve the chunk data without removing it
                local retrieved = self.chunkManager:RetrieveChunkData(transferId, false)
                if retrieved then
                    self:Debug("chunk", "CHUNK SYNC TEST: Successfully retrieved stored chunk data for: " .. transferId)
                    DEFAULT_CHAT_FRAME:AddMessage("|cFF33FFFF[TWRA Chunk Test]|r Found completed test transfer in stored data. Proceeding with verification.")
                    
                    -- Continue with verification using the retrieved data
                    local assembledMessage = retrieved.data
                    local expectedMessage = "My pinapple is strawberry flavoured and tastes like chocolate"
                    local messageMatches = (assembledMessage == expectedMessage)
                    
                    self:Debug("sync", "CHUNK SYNC TEST: Assembled message: '" .. assembledMessage .. "'")
                    self:Debug("chunk", "CHUNK SYNC TEST: Assembled message: '" .. assembledMessage .. "'")
                    self:Debug("sync", "CHUNK SYNC TEST: Message matches expected: " .. (messageMatches and "YES (PASS)" or "NO (FAIL)"))
                    self:Debug("chunk", "CHUNK SYNC TEST: Message matches expected: " .. (messageMatches and "YES (PASS)" or "NO (FAIL)"))
                    self:Debug("chunk", "CHUNK SYNC TEST: Expected: '" .. expectedMessage .. "'")
                    self:Debug("chunk", "CHUNK SYNC TEST: Received: '" .. assembledMessage .. "'")
                    
                    -- Final result
                    if messageMatches then
                        self:Debug("sync", "CHUNK SYNC TEST: OVERALL RESULT: PASS - Chunking system working correctly!")
                        self:Debug("chunk", "CHUNK SYNC TEST: OVERALL RESULT: PASS - Chunking system working correctly!")
                        DEFAULT_CHAT_FRAME:AddMessage("|cFF33FFFF[TWRA Chunk Test]|r |cFF00FF00SUCCESS!|r Retrieved and verified the correct message: '" .. assembledMessage .. "'")
                    else
                        self:Debug("sync", "CHUNK SYNC TEST: OVERALL RESULT: FAIL - Retrieved message does not match expected")
                        self:Debug("chunk", "CHUNK SYNC TEST: OVERALL RESULT: FAIL - Retrieved message does not match expected")
                        DEFAULT_CHAT_FRAME:AddMessage("|cFF33FFFF[TWRA Chunk Test]|r |cFFFF0000FAILED!|r Retrieved message does not match expected")
                    end
                    
                    self:Debug("sync", "----- CHUNK SYNC TEST: Stored data verification complete -----")
                    self:Debug("chunk", "----- CHUNK SYNC TEST: Stored data verification complete -----")
                    
                    return messageMatches
                else
                    self:Debug("chunk", "CHUNK SYNC TEST: Failed to retrieve data from storedChunkData for: " .. transferId)
                end
                break
            end
        end
        
        -- Also check in processed transfers as a final fallback
        for transferId, timestamp in pairs(self.chunkManager.processedTransfers or {}) do
            if string.find(transferId, "TEST_CHUNK_") then
                self:Debug("chunk", "CHUNK SYNC TEST: Found test transfer in processedTransfers: " .. transferId .. " (processed at " .. timestamp .. ")")
                DEFAULT_CHAT_FRAME:AddMessage("|cFF33FFFF[TWRA Chunk Test]|r Found test transfer in processedTransfers - it was already processed at " .. timestamp)
                return false
            end
        end
        
        self:Debug("chunk", "CHUNK SYNC TEST: No test transfers found in receivingChunks, storedChunkData, or processedTransfers tables")
        DEFAULT_CHAT_FRAME:AddMessage("|cFF33FFFF[TWRA Chunk Test]|r No test chunk transfer found. Did the sender run |cFFFFFF00/run TWRA:TestChunkSync()|r?")
        return false
    end
    
    self:Debug("sync", "CHUNK SYNC TEST: Found test transfer ID: " .. foundTransferId)
    self:Debug("chunk", "CHUNK SYNC TEST: Found test transfer ID: " .. foundTransferId)
    self:Debug("chunk", "CHUNK SYNC TEST: Transfer details:")
    self:Debug("chunk", "  - Expected chunks: " .. (receivedChunks.expected or "unknown"))
    self:Debug("chunk", "  - Received chunks: " .. (receivedChunks.received or "unknown"))
    self:Debug("chunk", "  - Sender: " .. (receivedChunks.sender or "unknown"))
    self:Debug("chunk", "  - Timestamp: " .. (receivedChunks.timestamp or "unknown"))
    self:Debug("chunk", "  - Data length: " .. (receivedChunks.dataLength or "unknown"))
    
    -- Check if we received all chunks
    local isComplete = (receivedChunks.expected > 0 and receivedChunks.received == receivedChunks.expected)
    self:Debug("sync", "CHUNK SYNC TEST: Transfer complete: " .. (isComplete and "YES (PASS)" or "NO (FAIL)"))
    self:Debug("chunk", "CHUNK SYNC TEST: Transfer complete: " .. (isComplete and "YES (PASS)" or "NO (FAIL)"))
    
    -- Debug chunks received
    self:Debug("chunk", "CHUNK SYNC TEST: Listing received chunks:")
    for i = 1, receivedChunks.expected do
        if receivedChunks.chunks[i] then
            self:Debug("chunk", "  Chunk " .. i .. ": '" .. receivedChunks.chunks[i] .. "'")
        else
            self:Debug("chunk", "  Chunk " .. i .. ": MISSING")
        end
    end
    
    if isComplete then
        -- Use ChunkManager's ProcessChunks function to assemble and potentially store the chunks
        -- We'll retrieve the data without immediately retrieving it to test the storage functionality
        self:Debug("chunk", "CHUNK SYNC TEST: Using ProcessChunks to assemble the message and store it")
        local assembledData = self.chunkManager:ProcessChunks(foundTransferId, false)
        
        -- At this point, the data should be stored in storedChunkData
        -- Now retrieve it using RetrieveChunkData to verify the storage/retrieval system
        local retrievedData = self.chunkManager:RetrieveChunkData(foundTransferId, false)
        
        -- The data should be in the retrievedData.data field if everything worked correctly
        if not retrievedData or not retrievedData.data then
            self:Debug("error", "CHUNK SYNC TEST: FAILURE - Failed to retrieve stored data for transfer: " .. foundTransferId)
            self:Debug("chunk", "CHUNK SYNC TEST: FAILURE - Failed to retrieve stored data for transfer: " .. foundTransferId)
            DEFAULT_CHAT_FRAME:AddMessage("|cFF33FFFF[TWRA Chunk Test]|r |cFFFF0000FAILED!|r Could not retrieve stored chunk data.")
            return false
        end
        
        -- Verify the data
        local assembledMessage = retrievedData.data
        
        self:Debug("sync", "CHUNK SYNC TEST: Retrieved message: '" .. assembledMessage .. "'")
        self:Debug("chunk", "CHUNK SYNC TEST: Retrieved message: '" .. assembledMessage .. "'")
        
        -- Verify the expected message
        local expectedMessage = "My pinapple is strawberry flavoured and tastes like chocolate"
        local messageMatches = (assembledMessage == expectedMessage)
        
        self:Debug("sync", "CHUNK SYNC TEST: Message matches expected: " .. (messageMatches and "YES (PASS)" or "NO (FAIL)"))
        self:Debug("chunk", "CHUNK SYNC TEST: Message matches expected: " .. (messageMatches and "YES (PASS)" or "NO (FAIL)"))
        self:Debug("chunk", "CHUNK SYNC TEST: Expected: '" .. expectedMessage .. "'")
        self:Debug("chunk", "CHUNK SYNC TEST: Received: '" .. assembledMessage .. "'")
        
        -- Check character by character if there's a mismatch
        if not messageMatches then
            self:Debug("chunk", "CHUNK SYNC TEST: Character by character comparison:")
            for i = 1, math.max(string.len(expectedMessage), string.len(assembledMessage)) do
                local expectedChar = string.sub(expectedMessage, i, i) or "END"
                local receivedChar = string.sub(assembledMessage, i, i) or "END"
                if expectedChar ~= receivedChar then
                    self:Debug("chunk", "  Position " .. i .. ": Expected '" .. expectedChar .. 
                              "' but got '" .. receivedChar .. "' - MISMATCH")
                end
            end
        end
        
        -- Final result
        if messageMatches then
            self:Debug("sync", "CHUNK SYNC TEST: OVERALL RESULT: PASS - Chunking system working correctly!")
            self:Debug("chunk", "CHUNK SYNC TEST: OVERALL RESULT: PASS - Chunking system working correctly!")
            DEFAULT_CHAT_FRAME:AddMessage("|cFF33FFFF[TWRA Chunk Test]|r |cFF00FF00SUCCESS!|r Received, stored, and retrieved the correct message: '" .. assembledMessage .. "'")
            
            -- Now test retrieving and removing data
            self:Debug("chunk", "CHUNK SYNC TEST: Testing retrieval with removal...")
            local finalRetrieval = self.chunkManager:RetrieveChunkData(foundTransferId, true)
            if finalRetrieval and finalRetrieval.data then
                self:Debug("chunk", "CHUNK SYNC TEST: Successfully retrieved data with removal.")
                
                -- Verify data is gone
                if not self.chunkManager.storedChunkData[foundTransferId] then
                    self:Debug("chunk", "CHUNK SYNC TEST: Verified data was removed from storage after final retrieval. PASS")
                    DEFAULT_CHAT_FRAME:AddMessage("|cFF33FFFF[TWRA Chunk Test]|r |cFF00FF00BONUS TEST PASSED!|r Data removed from storage after final retrieval")
                else
                    self:Debug("chunk", "CHUNK SYNC TEST: WARNING - Data was not removed from storage after final retrieval with removal=true")
                    DEFAULT_CHAT_FRAME:AddMessage("|cFF33FFFF[TWRA Chunk Test]|r |cFFFFCC00WARNING:|r Data was not removed from storage after final retrieval")
                end
            else
                self:Debug("chunk", "CHUNK SYNC TEST: Failed to perform final retrieval with removal")
                DEFAULT_CHAT_FRAME:AddMessage("|cFF33FFFF[TWRA Chunk Test]|r |cFFFFCC00WARNING:|r Failed to perform final retrieval with removal")
            end
        else
            self:Debug("sync", "CHUNK SYNC TEST: OVERALL RESULT: FAIL - Retrieved message does not match expected")
            self:Debug("chunk", "CHUNK SYNC TEST: OVERALL RESULT: FAIL - Retrieved message does not match expected")
            DEFAULT_CHAT_FRAME:AddMessage("|cFF33FFFF[TWRA Chunk Test]|r |cFFFF0000FAILED!|r Retrieved message does not match expected")
        end
    else
        self:Debug("sync", "CHUNK SYNC TEST: OVERALL RESULT: FAIL - Did not receive all expected chunks")
        self:Debug("chunk", "CHUNK SYNC TEST: OVERALL RESULT: FAIL - Did not receive all expected chunks")
        DEFAULT_CHAT_FRAME:AddMessage("|cFF33FFFF[TWRA Chunk Test]|r |cFFFF0000FAILED!|r Did not receive all expected chunks. Received " .. 
                                     (receivedChunks.received or "0") .. "/" .. (receivedChunks.expected or "?"))
    end
    
    self:Debug("sync", "----- CHUNK SYNC TEST: Receiver verification complete -----")
    self:Debug("chunk", "----- CHUNK SYNC TEST: Receiver verification complete -----")
    
    return isComplete and messageMatches
end

-- Add a helper function to count table entries if not already provided
if not TWRA.TableCount then
    function TWRA:TableCount(t)
        if not t or type(t) ~= "table" then
            return 0
        end
        
        local count = 0
        for _ in pairs(t) do
            count = count + 1
        end
        return count
    end
end

-- Function to handle the TEST_CHUNK command
function TWRA:HandleTestChunkCommand(message, sender)
    if not message then
        return
    end
    
    self:Debug("sync", "Processing test chunk command from " .. sender)
    self:Debug("chunk", "Processing test chunk command: " .. message)
    
    -- Extract the transfer ID if available
    local transferId = nil
    local pattern = "TEST_CHUNK_[^: ]+"
    local match = string.gfind(message, pattern)()
    
    if match then
        transferId = match
        self:Debug("chunk", "Extracted test transfer ID: " .. transferId)
    else
        self:Debug("error", "Could not extract test transfer ID from message: " .. message)
        return
    end
    
    -- If we have a chunkManager, check if this transfer is in progress
    if self.chunkManager and self.chunkManager.receivingChunks then
        local transferInfo = self.chunkManager.receivingChunks[transferId]
        if transferInfo then
            self:Debug("sync", "Found ongoing test transfer: " .. transferId)
            self:Debug("chunk", "Test transfer status: " .. transferInfo.received .. "/" .. transferInfo.expected .. " chunks received")
            
            -- Check if this transfer is complete
            if transferInfo.received == transferInfo.expected then
                self:Debug("sync", "Test transfer is complete, processing")
                self:ProcessCompleteChunkTransfer(transferId)
            else
                self:Debug("sync", "Test transfer is incomplete, waiting for more chunks")
                DEFAULT_CHAT_FRAME:AddMessage("|cFF33FFFF[TWRA Chunk Test]|r Receiving test transfer: " .. 
                                           transferInfo.received .. "/" .. transferInfo.expected .. " chunks received")
            end
        else
            self:Debug("chunk", "No ongoing test transfer found with ID: " .. transferId)
        end
    else
        self:Debug("error", "ChunkManager not initialized, cannot process test chunks")
    end
end

-- Hook the initialization to load our tests
if not TWRA.ChunkTestHooked then
    TWRA.ChunkTestHooked = true
    local originalOnLoad = TWRA.OnLoad
    TWRA.OnLoad = function(self)
        -- Call the original OnLoad function if it exists
        if originalOnLoad then
            originalOnLoad(self)
        end
        
        -- Schedule initialization of chunk tests
        self:ScheduleTimer(function()
            self:InitializeChunkTests()
        end, 2) -- Give some time for other systems to initialize
    end
end