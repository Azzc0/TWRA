-- TWRA Compression Module
-- This module handles the compression and decompression of data for sync operations
TWRA = TWRA or {}

-- Initialize compression system
function TWRA:InitializeCompression()
    -- Use LibCompress for Huffman compression
    self.LibCompress = LibStub:GetLibrary("LibCompress")
    
    if not self.LibCompress then
        self:Debug("error", "LibCompress library not found")
        return false
    end
    
    -- Initialize the TWRA_CompressedAssignments if it doesn't exist
    TWRA_CompressedAssignments = TWRA_CompressedAssignments or {}
    
    -- Handle migration from old format (if compressed data exists in old location)
    if TWRA_Assignments and TWRA_Assignments.compressed then
        self:Debug("compress", "Migrating compressed data to new location")
        TWRA_CompressedAssignments.data = TWRA_Assignments.compressed
        TWRA_CompressedAssignments.timestamp = TWRA_Assignments.timestamp or 0
        -- Remove from old location
        TWRA_Assignments.compressed = nil
    end
    
    self:Debug("system", "Compression system initialized")
    return true
end

-- Test compression functionality
-- This function can be called to verify that compression is working properly
function TWRA:TestCompression()
    self:Debug("compress", "Starting compression test")
    
    -- Initialize compression system if not already done
    if not self.LibCompress then
        if not self:InitializeCompression() then
            return false, "Failed to initialize compression system"
        end
    end
    
    -- Create a simple test table
    local testData = {
        currentSectionName = "Test Section",
        isExample = false,
        version = 2,
        timestamp = time(),
        currentSection = 1,
        data = {
            [1] = {
                ["Section Name"] = "Test Boss",
                ["Section Header"] = {"Icon", "Target", "Tank", "Healer", "DPS"},
                ["Section Rows"] = {
                    [1] = {"Skull", "Boss", "MainTank", "Healer1", "DPS1"},
                    [2] = {"Cross", "Add", "OffTank", "Healer2", "DPS2"}
                }
            }
        }
    }
    
    -- Test compression with LibCompress TableToString + Huffman
    local results = {}
    
    -- Convert to string using TableToString
    local dataString = self.LibCompress:TableToString(testData)
    if not dataString then
        self:Debug("error", "Failed to convert table to string")
        return false, "TableToString conversion failed"
    end
    
    results.origSize = string.len(dataString)
    
    -- Compress using Huffman
    local compressed = self.LibCompress:CompressHuffman(dataString)
    if not compressed then
        self:Debug("error", "Huffman compression failed")
        return false, "Compression failed"
    end
    
    -- Log compression results
    local ratio = math.floor((string.len(compressed) / string.len(dataString)) * 100)
    results.compressedSize = string.len(compressed)
    results.ratio = ratio
    
    self:Debug("compress", "Original: " .. string.len(dataString) .. " bytes")
    self:Debug("compress", "Compressed: " .. string.len(compressed) .. " bytes (" .. ratio .. "% of original)")
    
    -- Test with real addon data if it exists
    local realDataTest = false
    if TWRA_Assignments and TWRA_Assignments.data then
        realDataTest = true
        
        local syncData = self:PrepareDataForSync()
        if syncData then
            -- Compress real data
            local realDataString = self.LibCompress:TableToString(syncData)
            local realCompressed = self.LibCompress:CompressHuffman(realDataString)
            
            results.realOrigSize = string.len(realDataString)
            results.realCompressedSize = string.len(realCompressed)
            results.realRatio = math.floor((results.realCompressedSize / results.realOrigSize) * 100)
            
            -- Test compression and decompression to verify data integrity
            local decompressedData = self.LibCompress:DecompressHuffman(realCompressed)
            if not decompressedData then
                self:Debug("error", "Failed to decompress real data")
                results.realSuccess = false
            else
                local recoveredData = self.LibCompress:StringToTable(decompressedData)
                if not recoveredData then
                    self:Debug("error", "Failed to convert decompressed string back to table")
                    results.realSuccess = false
                else
                    self:Debug("compress", "Real data compression/decompression successful")
                    results.realSuccess = true
                end
            end
        end
    end
    
    -- Print results to chat frame for visibility
    DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA Compression Test|r:")
    DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA Compression Test|r: Original size: " .. results.origSize .. " bytes")
    DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA Compression Test|r: Best compression: " .. results.compressedSize .. 
                               " bytes (" .. results.ratio .. "% of original)")
    
    if realDataTest and results.realSuccess then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA Compression Test|r: Real data: " .. 
                                   results.realCompressedSize .. " bytes (" .. 
                                   results.realRatio .. "% of original)")
    end
    
    return true, results
end

-- Prepare data for sync by stripping client-specific information
function TWRA:PrepareDataForSync()
    -- Early initialization guard - ensure assignment data structure exists
    if not TWRA_Assignments then
        self:Debug("error", "No data to prepare for sync - TWRA_Assignments is nil")
        -- Auto-repair the structure
        TWRA_Assignments = {
            data = {},
            version = 2,
            currentSection = 1,
            timestamp = time()
        }
        return nil
    end
    
    -- Also verify that we actually have data to work with
    if not TWRA_Assignments.data then
        self:Debug("error", "No assignment data to prepare for sync - TWRA_Assignments.data is nil")
        -- Auto-repair the data table
        TWRA_Assignments.data = {}
        return nil
    end
    
    -- Create a copy of the assignments data without client-specific information
    local syncData = {
        -- currentSectionName = TWRA_Assignments.currentSectionName,
        isExample = TWRA_Assignments.isExample,
        version = TWRA_Assignments.version,
        timestamp = TWRA_Assignments.timestamp,
        -- currentSection = TWRA_Assignments.currentSection,
        data = {}
    }
    
    -- Copy the data without Section Player Info
    for sectionIndex, sectionData in pairs(TWRA_Assignments.data) do
        if type(sectionData) == "table" then
            syncData.data[sectionIndex] = {}
            
            -- Copy all fields except Section Player Info
            for key, value in pairs(sectionData) do
                if key ~= "Section Player Info" then
                    syncData.data[sectionIndex][key] = value
                end
            end
        end
    end
    
    self:Debug("compress", "Data prepared for sync: " .. 
               tostring(syncData.timestamp) .. " with " .. 
               tostring(table.getn(syncData.data)) .. " sections")
    
    return syncData
end

-- Compress the assignment data for efficient sync
-- Returns compressed string or nil if compression failed
function TWRA:CompressAssignmentsData()
    -- Prepare the data by removing client-specific information
    local syncData = self:PrepareDataForSync()
    
    if not syncData then
        return nil, "No data to compress"
    end
    
    -- Initialize compression system if needed
    if not self.LibCompress then
        if not self:InitializeCompression() then
            return nil, "Failed to initialize compression system"
        end
    end
    
    -- Convert to string using TableToString
    local dataString = self.LibCompress:TableToString(syncData)
    
    if not dataString then
        self:Debug("error", "Failed to convert data to string for compression")
        return nil, "Failed to convert data to string"
    end
    
    -- Use Huffman compression specifically (better for our text data)
    local compressed = self.LibCompress:CompressHuffman(dataString)
    
    if not compressed then
        self:Debug("error", "Failed to compress data")
        return nil, "Compression failed"
    end
    
    local compressionRatio = math.floor((string.len(compressed) / string.len(dataString)) * 100)
    self:Debug("compress", "Compressed " .. string.len(dataString) .. " bytes to " .. 
               string.len(compressed) .. " bytes (" .. compressionRatio .. "% of original)")
    
    -- Base64 encode the compressed data for safe transmission
    compressed = TWRA:EncodeBase64(compressed)
    
    -- Add a marker at the beginning to indicate this is using normal TableToString compression
    return "\241"..compressed
end

-- Decompress data received via sync
-- Returns decompressed table or nil if decompression failed
function TWRA:DecompressAssignmentsData(compressedData)
    if not compressedData or type(compressedData) ~= "string" then
        self:Debug("error", "Invalid compressed data")
        return nil, "Invalid compressed data"
    end
    
    -- Check for serialization method marker
    local marker = string.byte(compressedData, 1)
    local useTableToString = (marker == 241)
    
    -- Only process our marker
    if not useTableToString then
        self:Debug("error", "Unknown compression marker: " .. tostring(marker))
        return nil, "Unknown compression marker"
    end
    
    compressedData = string.sub(compressedData, 2) -- Remove the marker
    
    -- Initialize compression system if needed
    if not self.LibCompress then
        if not self:InitializeCompression() then
            return nil, "Failed to initialize compression system"
        end
    end
    
    -- First decode Base64 using our raw decoder to get binary data
    local binaryData = self:DecodeBase64Raw(compressedData)
    
    if not binaryData then
        self:Debug("error", "Failed to decode Base64 data")
        return nil, "Failed to decode Base64 data"
    end
    
    -- Decompress data using LibCompress
    local decompressed, err = self.LibCompress:DecompressHuffman(binaryData)
    
    if not decompressed then
        self:Debug("error", "Failed to decompress data: " .. tostring(err))
        return nil, "Decompression failed: " .. tostring(err)
    end
    
    -- Convert string back to table structure
    local dataTable = self.LibCompress:StringToTable(decompressed)
    
    if not dataTable then
        self:Debug("error", "Failed to convert decompressed string to table")
        return nil, "Failed to parse decompressed data"
    end
    
    self:Debug("compress", "Successfully decompressed data with timestamp: " .. 
               tostring(dataTable.timestamp) .. " and " .. 
               tostring(table.getn(dataTable.data)) .. " sections")
    
    return dataTable
end

-- Store compressed data for later use
-- This replaces storing the source string
function TWRA:StoreCompressedData(compressedData)
    if not compressedData then
        self:Debug("error", "No compressed data to store")
        return false
    end
    
    -- Ensure our storage exists
    TWRA_CompressedAssignments = TWRA_CompressedAssignments or {}
    
    -- Store the compressed data in our dedicated variable
    TWRA_CompressedAssignments.data = compressedData
    
    -- Also store the timestamp for validation
    if TWRA_Assignments then
        TWRA_CompressedAssignments.timestamp = TWRA_Assignments.timestamp or 0
    end
    
    self:Debug("compress", "Stored compressed data (" .. string.len(compressedData) .. " bytes) in TWRA_CompressedAssignments")
    return true
end

-- Get stored compressed data for syncing
function TWRA:GetStoredCompressedData()
    -- Ensure our storage exists
    TWRA_CompressedAssignments = TWRA_CompressedAssignments or {}
    
    -- Check if we have saved assignments
    if not TWRA_Assignments then
        return nil, "No saved assignments"
    end
    
    -- Get current timestamp
    local currentTimestamp = TWRA_Assignments.timestamp or 0
    
    -- Check if the compressed data exists and is up to date
    if not TWRA_CompressedAssignments.data or 
       not TWRA_CompressedAssignments.timestamp or 
       TWRA_CompressedAssignments.timestamp ~= currentTimestamp then
        
        -- If compressed data doesn't exist or is outdated, create it
        self:Debug("compress", "Generating new compressed data (missing or outdated)")
        local compressed, err = self:CompressAssignmentsData()
        if not compressed then
            return nil, "Failed to generate compressed data: " .. tostring(err)
        end
        
        -- Store for future use
        self:StoreCompressedData(compressed)
    end
    
    return TWRA_CompressedAssignments.data
end

-- Benchmark various compression methods using real assignment data
function TWRA:BenchmarkCompression(iterations)
    iterations = iterations or 3 -- Default to 3 iterations
    
    -- Check if we have any saved data to test with
    if not TWRA_Assignments or not TWRA_Assignments.data then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF3333TWRA Compression Benchmark:|r No saved assignments data available")
        return nil, "No saved assignments data available"
    end
    
    -- Initialize compression system if needed
    if not self.LibCompress then
        if not self:InitializeCompression() then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF3333TWRA Compression Benchmark:|r Failed to initialize compression system")
            return nil, "Failed to initialize compression system"
        end
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA Compression Benchmark Started|r (running " .. iterations .. " iterations)")
    
    -- Prepare the data by making a deep copy (don't modify original)
    local syncData = self:PrepareDataForSync()
    if not syncData then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF3333TWRA Compression Benchmark:|r Failed to prepare data")
        return nil, "Failed to prepare benchmark data"
    end
    
    -- Get section count for context
    local sectionCount = syncData.data and table.getn(syncData.data or {}) or 0
    DEFAULT_CHAT_FRAME:AddMessage("Testing on " .. sectionCount .. " sections of data")
    
    local results = {}
    
    -- Test TableToString + Huffman
    DEFAULT_CHAT_FRAME:AddMessage("Testing TableToString + Huffman...")
    local serialized = self.LibCompress:TableToString(syncData)
    if not serialized then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF3333Error:|r TableToString conversion failed")
        return nil, "TableToString conversion failed"
    end
    
    results.originalSize = string.len(serialized)
    DEFAULT_CHAT_FRAME:AddMessage("Original data size: " .. results.originalSize .. " bytes")
    
    local compressed = self.LibCompress:CompressHuffman(serialized)
    if compressed then
        results.compressedSize = string.len(compressed)
        results.ratio = math.floor((results.compressedSize / results.originalSize) * 100)
        DEFAULT_CHAT_FRAME:AddMessage("TableToString + Huffman: " .. 
            results.compressedSize .. " bytes (" ..
            results.ratio .. "% of original)")
        
        -- Test decompression to verify integrity
        local decompressed = self.LibCompress:DecompressHuffman(compressed)
        if not decompressed then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF3333Error:|r Decompression failed for TableToString + Huffman")
        else
            local recovered = self.LibCompress:StringToTable(decompressed)
            if not recovered then
                DEFAULT_CHAT_FRAME:AddMessage("|cFFFF3333Error:|r StringToTable failed for TableToString + Huffman")
            else
                DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00Integrity check:|r PASS")
            end
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF3333Error:|r Compression failed for TableToString + Huffman")
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA Compression Benchmark Results:|r")
    DEFAULT_CHAT_FRAME:AddMessage("Original data size: " .. results.originalSize .. " bytes")
    DEFAULT_CHAT_FRAME:AddMessage("Compressed size: " .. results.compressedSize .. " bytes (" .. results.ratio .. "% of original)")
    DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA Compression Benchmark completed|r")
    
    return results
end

-- Process compressed data received from sync
function TWRA:ProcessCompressedData(compressedData, timestamp, sender)
    self:Debug("sync", "ProcessCompressedData: Processing " .. string.len(compressedData) .. 
              " bytes of compressed data from " .. sender .. " with timestamp " .. timestamp)
    
    -- Check if we're still tracking this pending section
    local pendingSectionIndex = self.SYNC.pendingSection
    self:Debug("sync", "Pending section to navigate after sync: " .. (pendingSectionIndex or "nil"))
    
    -- First decompress the data
    local decompressedData = self:DecompressAssignmentsData(compressedData)
    
    if not decompressedData then
        self:Debug("error", "ProcessCompressedData: Failed to decompress data from " .. sender)
        return false
    end
    
    self:Debug("sync", "ProcessCompressedData: Successfully decompressed data with timestamp " .. 
              (decompressedData.timestamp or "nil"))
              
    -- Check if the received data is newer than what we have
    local ourTimestamp = TWRA_Assignments and TWRA_Assignments.timestamp or 0
    
    if decompressedData.timestamp and decompressedData.timestamp > ourTimestamp then
        self:Debug("sync", "ProcessCompressedData: Received newer data (timestamp " .. 
                  decompressedData.timestamp .. " > " .. ourTimestamp .. "), applying it")
        
        -- Initialize assignments if needed
        if not TWRA_Assignments then
            TWRA_Assignments = {}
        end
        
        -- Store the decompressed data
        TWRA_Assignments.data = decompressedData.data
        TWRA_Assignments.timestamp = decompressedData.timestamp
        TWRA_Assignments.version = 2 -- Use new data format
        
        -- Also store the compressed version for future sync
        self:StoreCompressedData(compressedData)
        
        -- Rebuild navigation with the new data
        self:Debug("sync", "ProcessCompressedData: Rebuilding navigation with new data")
        if self.RebuildNavigation then
            self:RebuildNavigation()
        else
            self:Debug("error", "ProcessCompressedData: RebuildNavigation function not found")
        end
        
        -- Process player information
        self:Debug("sync", "ProcessCompressedData: Processing player information")
        if self.RefreshPlayerInfo then
            self:RefreshPlayerInfo()
        elseif self.ProcessPlayerInfo then
            self:ProcessPlayerInfo()
        else
            self:Debug("error", "ProcessCompressedData: Neither RefreshPlayerInfo nor ProcessPlayerInfo function found")
        end
        
        -- Navigate to the pending section or first section
        local sectionToUse = pendingSectionIndex or 1
        self:Debug("sync", "ProcessCompressedData: Navigating to section " .. sectionToUse)
        
        if self.NavigateToSection then
            self:NavigateToSection(sectionToUse, "fromSync")
        else
            self:Debug("error", "ProcessCompressedData: NavigateToSection function not found")
        end
        
        -- Clear pending section after use
        self.SYNC.pendingSection = nil
        
        self:Debug("sync", "ProcessCompressedData: Data sync from " .. sender .. " complete")
        
        -- Notify user
        DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA:|r Synchronized raid assignments from " .. sender)
        
        return true
    else
        self:Debug("sync", "ProcessCompressedData: Received older or same timestamp data, ignoring")
        return false
    end
end