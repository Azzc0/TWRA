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
    
    -- Ensure we have structure and sections tables
    TWRA_CompressedAssignments.structure = TWRA_CompressedAssignments.structure or nil
    TWRA_CompressedAssignments.sections = TWRA_CompressedAssignments.sections or {}
    
    -- Set flag to indicate we only use section compression
    TWRA_CompressedAssignments.useSectionCompression = true
    
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
        isExample = TWRA_Assignments.isExample,
        version = TWRA_Assignments.version,
        timestamp = TWRA_Assignments.timestamp,
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

-- Compress the structure data (section names and indices)
function TWRA:CompressStructureData()
    -- Initialize compression system if needed
    if not self.LibCompress then
        if not self:InitializeCompression() then
            return nil, "Failed to initialize compression system"
        end
    end
    
    -- Extract structure information from TWRA_Assignments
    if not TWRA_Assignments or not TWRA_Assignments.data then
        self:Debug("error", "No assignments data to extract structure from")
        return nil, "No assignment data available"
    end
    
    -- Create structure data (minimal with just section names and indices)
    local structure = {}
    for i, sectionData in ipairs(TWRA_Assignments.data) do
        if type(sectionData) == "table" then
            structure[i] = sectionData["Section Name"] or ("Section " .. i)
        end
    end
    
    -- Add metadata
    structure.timestamp = TWRA_Assignments.timestamp or time()
    structure.version = TWRA_Assignments.version or 2
    
    -- Compress structure data
    local dataString = self.LibCompress:TableToString(structure)
    if not dataString then
        self:Debug("error", "Failed to convert structure to string")
        return nil, "Failed to convert structure to string"
    end
    
    -- Use Huffman compression
    local compressed = self.LibCompress:CompressHuffman(dataString)
    if not compressed then
        self:Debug("error", "Failed to compress structure data")
        return nil, "Compression failed"
    end
    
    -- Base64 encode
    compressed = self:EncodeBase64(compressed)
    
    -- Add compression marker
    return "\241" .. compressed
end

-- Compress individual section data
function TWRA:CompressSectionData(sectionIndex)
    -- Initialize compression system if needed
    if not self.LibCompress then
        if not self:InitializeCompression() then
            return nil, "Failed to initialize compression system"
        end
    end
    
    -- Validate section index
    if not TWRA_Assignments or not TWRA_Assignments.data or 
       not TWRA_Assignments.data[sectionIndex] then
        self:Debug("error", "Invalid section index: " .. tostring(sectionIndex))
        return nil, "Invalid section index"
    end
    
    -- Create a clean copy of the section data without player info
    local sectionData = {}
    for key, value in pairs(TWRA_Assignments.data[sectionIndex]) do
        if key ~= "Section Player Info" then
            sectionData[key] = value
        end
    end
    
    -- Add minimal metadata
    sectionData.timestamp = TWRA_Assignments.timestamp or time()
    
    -- Compress section data
    local dataString = self.LibCompress:TableToString(sectionData)
    if not dataString then
        self:Debug("error", "Failed to convert section to string")
        return nil, "Failed to convert section to string"
    end
    
    -- Use Huffman compression
    local compressed = self.LibCompress:CompressHuffman(dataString)
    if not compressed then
        self:Debug("error", "Failed to compress section data")
        return nil, "Compression failed"
    end
    
    -- Base64 encode
    compressed = self:EncodeBase64(compressed)
    
    -- Add compression marker
    return "\241" .. compressed
end

-- Decompress structure data
function TWRA:DecompressStructureData(compressedStructure)
    self:Debug("compress", "Decompressing structure data")
    
    if not compressedStructure or type(compressedStructure) ~= "string" then
        self:Debug("error", "Invalid compressed structure data")
        return nil
    end
    
    -- Decode from Base64
    local decodedString = self:DecodeBase64(compressedStructure)
    if not decodedString then
        self:Debug("error", "Failed to decode structure data from Base64")
        return nil
    end
    
    -- Decompress using LibCompress
    local decompressedString
    if self.LibCompress then
        decompressedString = self.LibCompress:DecompressHuffman(decodedString)
        
        if not decompressedString then
            self:Debug("error", "Failed to decompress structure data with Huffman")
            return nil
        end
    else
        -- Fallback if LibCompress not available (shouldn't happen, but just in case)
        decompressedString = decodedString
        self:Debug("compress", "Warning: Using uncompressed data, LibCompress not available")
    end
    
    -- Convert string to table
    local decompressedTable
    local func, errorMessage = loadstring("return " .. decompressedString)
    
    if func then
        decompressedTable = func()
        self:Debug("compress", "Successfully decompressed structure data with " .. 
                  (self:GetTableSize(decompressedTable) or 0) .. " sections")
    else
        self:Debug("error", "Failed to convert decompressed structure string to table: " .. (errorMessage or "unknown error"))
        return nil
    end
    
    return decompressedTable
end

-- Decompress section data
function TWRA:DecompressSectionData(sectionIndex, compressedSection)
    self:Debug("compress", "Decompressing section " .. sectionIndex .. " data")
    
    if not compressedSection or type(compressedSection) ~= "string" then
        self:Debug("error", "Invalid compressed section data")
        return nil
    end
    
    -- Decode from Base64
    local decodedString = self:DecodeBase64(compressedSection)
    if not decodedString then
        self:Debug("error", "Failed to decode section data from Base64")
        return nil
    end
    
    -- Decompress using LibCompress
    local decompressedString
    if self.LibCompress then
        decompressedString = self.LibCompress:DecompressHuffman(decodedString)
        
        if not decompressedString then
            self:Debug("error", "Failed to decompress section data with Huffman")
            return nil
        end
    else
        -- Fallback if LibCompress not available
        decompressedString = decodedString
        self:Debug("compress", "Warning: Using uncompressed data, LibCompress not available")
    end
    
    -- Convert string to table
    local decompressedTable
    local func, errorMessage = loadstring("return " .. decompressedString)
    
    if func then
        decompressedTable = func()
        self:Debug("compress", "Successfully decompressed section " .. sectionIndex .. " data")
    else
        self:Debug("error", "Failed to convert decompressed section string to table: " .. (errorMessage or "unknown error"))
        return nil
    end
    
    return decompressedTable
end

-- Store segmented compressed data
function TWRA:StoreSegmentedData()
    -- Ensure our storage exists
    TWRA_CompressedAssignments = TWRA_CompressedAssignments or {}
    
    -- Check if we have assignments to compress
    if not TWRA_Assignments or not TWRA_Assignments.data then
        self:Debug("error", "No assignments data to compress")
        return false
    end
    
    -- Compress and store structure data
    local structureData = self:CompressStructureData()
    if not structureData then
        self:Debug("error", "Failed to compress structure data")
        return false
    end
    
    -- Store structure
    TWRA_CompressedAssignments.structure = structureData
    TWRA_CompressedAssignments.timestamp = TWRA_Assignments.timestamp or time()
    
    -- IMPORTANT: Reset the data field if using old format
    if TWRA_CompressedAssignments.data then
        TWRA_CompressedAssignments.data = nil
    end
    
    -- Initialize the sections table if it doesn't exist
    TWRA_CompressedAssignments.sections = TWRA_CompressedAssignments.sections or {}
    
    -- Compress and store each section
    local sectionCount = 0
    for i, section in pairs(TWRA_Assignments.data) do
        if type(i) == "number" and type(section) == "table" then
            local sectionData = self:CompressSectionData(i)
            if sectionData then
                TWRA_CompressedAssignments.sections[i] = sectionData
                sectionCount = sectionCount + 1
                self:Debug("compress", "Compressed section " .. i)
            else
                self:Debug("error", "Failed to compress section " .. i)
            end
        end
    end
    
    -- Update flag to indicate we're using section compression
    TWRA_CompressedAssignments.useSectionCompression = true
    
    self:Debug("compress", "Stored segmented compressed data for " .. sectionCount .. " sections")
    return true
end

-- Function to get the compressed structure from TWRA_CompressedAssignments
function TWRA:GetCompressedStructure()
    if not TWRA_CompressedAssignments or not TWRA_CompressedAssignments.structure then
        self:Debug("compress", "No compressed structure available")
        return nil
    end
    
    return TWRA_CompressedAssignments.structure
end

-- Function to get a compressed section from TWRA_CompressedAssignments
function TWRA:GetCompressedSection(sectionIndex)
    if not TWRA_CompressedAssignments or 
       not TWRA_CompressedAssignments.data or 
       not TWRA_CompressedAssignments.data[sectionIndex] then
        self:Debug("compress", "No compressed data available for section " .. sectionIndex)
        return nil
    end
    
    return TWRA_CompressedAssignments.data[sectionIndex]
end

-- Get compressed structure data
function TWRA:GetCompressedStructure()
    -- Ensure our storage exists
    TWRA_CompressedAssignments = TWRA_CompressedAssignments or {}
    
    -- Check if we have saved assignments
    if not TWRA_Assignments or not TWRA_Assignments.data then
        return nil, "No saved assignments"
    end
    
    -- Check if structure exists and is current
    local currentTimestamp = TWRA_Assignments.timestamp or 0
    
    if not TWRA_CompressedAssignments.structure or
       not TWRA_CompressedAssignments.timestamp or
       TWRA_CompressedAssignments.timestamp ~= currentTimestamp then
        
        -- Generate structure data
        self:Debug("compress", "Generating new structure data")
        self:StoreSegmentedData()
    end
    
    return TWRA_CompressedAssignments.structure
end

-- Get compressed section data
function TWRA:GetCompressedSection(sectionIndex)
    -- Ensure our storage exists
    TWRA_CompressedAssignments = TWRA_CompressedAssignments or {}
    TWRA_CompressedAssignments.sections = TWRA_CompressedAssignments.sections or {}
    
    -- Check if we have saved assignments
    if not TWRA_Assignments or not TWRA_Assignments.data or
       not TWRA_Assignments.data[sectionIndex] then
        return nil, "Section not found"
    end
    
    -- Check if section data exists and is current
    local currentTimestamp = TWRA_Assignments.timestamp or 0
    
    if not TWRA_CompressedAssignments.sections[sectionIndex] or
       not TWRA_CompressedAssignments.timestamp or
       TWRA_CompressedAssignments.timestamp ~= currentTimestamp then
        
        -- Check if we need to store all data
        if not TWRA_CompressedAssignments.useSectionCompression then
            -- Full refresh of all compressed data
            self:Debug("compress", "Initializing segmented compression")
            self:StoreSegmentedData()
        else
            -- Just compress the required section
            self:Debug("compress", "Generating compressed data for section " .. sectionIndex)
            local sectionData = self:CompressSectionData(sectionIndex)
            if sectionData then
                TWRA_CompressedAssignments.sections[sectionIndex] = sectionData
                -- Update timestamp if needed
                if not TWRA_CompressedAssignments.timestamp then
                    TWRA_CompressedAssignments.timestamp = currentTimestamp
                end
            else
                return nil, "Failed to compress section data"
            end
        end
    end
    
    return TWRA_CompressedAssignments.sections[sectionIndex]
end

-- Compress the assignment data for efficient sync (Legacy method)
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
-- This is a legacy function that redirects to the consolidated implementation
function TWRA:StoreCompressedData(compressedData)
    -- Forward to the consolidated implementation in DataProcessing.lua
    if not compressedData then
        self:Debug("error", "StoreCompressedData: No compressed data to store")
        return false
    end
    
    self:Debug("compress", "Redirecting to consolidated StoreCompressedData implementation")
    
    -- Call the consolidated implementation directly if loaded
    if self.ProcessImportedData then  -- This check ensures DataProcessing.lua is loaded
        return self:StoreCompressedData(compressedData)
    else
        -- Fallback implementation to avoid redundancy in case DataProcessing.lua is not loaded
        self:Debug("compress", "DataProcessing.lua not loaded, using local fallback")
        
        -- Log that we received compressed data but are not storing it
        self:Debug("compress", "Legacy compressed data received (" .. string.len(compressedData) .. " bytes) - not storing complete data")
        
        -- IMPORTANT: We don't store any data here anymore, including timestamps
        -- This prevents redundant storage of complete compressed data
    end
    
    return true
end

-- Get stored compressed data for syncing (Legacy method)
-- Perhaps completely irrelevant - Let's return to this function later and see if we can completely remove it.
-- I am not ready to get rid of it at this point.
function TWRA:GetStoredCompressedData()
    -- Check if we have saved assignments
    if not TWRA_Assignments then
        return nil, "No saved assignments"
    end
    
    -- Always generate new compressed data instead of retrieving stored data
    self:Debug("compress", "Generating new compressed data")
    local compressed, err = self:CompressAssignmentsData()
    if not compressed then
        return nil, "Failed to generate compressed data: " .. tostring(err)
    end
    
    -- Log but don't store
    self:Debug("compress", "Generated " .. string.len(compressed) .. " bytes of compressed data")
    
    return compressed
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
        
        -- IMPORTANT: Use the segmented approach instead of storing complete compressed data
        self:Debug("sync", "ProcessCompressedData: Storing segmented data for future sync")
        self:StoreSegmentedData()
        
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