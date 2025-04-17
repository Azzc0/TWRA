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
    
    self:Debug("system", "Compression system initialized")
    return true
end

-- Prepare data for sync by stripping client-specific information
function TWRA:PrepareDataForSync()
    if not TWRA_SavedVariables or not TWRA_SavedVariables.assignments then
        self:Debug("error", "No data to prepare for sync")
        return nil
    end
    
    -- Create a copy of the assignments data without client-specific information
    local syncData = {
        currentSectionName = TWRA_SavedVariables.assignments.currentSectionName,
        isExample = TWRA_SavedVariables.assignments.isExample,
        version = TWRA_SavedVariables.assignments.version,
        timestamp = TWRA_SavedVariables.assignments.timestamp,
        currentSection = TWRA_SavedVariables.assignments.currentSection,
        data = {}
    }
    
    -- Copy the data without Section Player Info
    for sectionIndex, sectionData in pairs(TWRA_SavedVariables.assignments.data) do
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
    
    -- Convert to string using the included TableToString function in LibCompress
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
    
    return compressed
end

-- Decompress data received via sync
-- Returns decompressed table or nil if decompression failed
function TWRA:DecompressAssignmentsData(compressedData)
    if not compressedData or type(compressedData) ~= "string" then
        self:Debug("error", "Invalid compressed data")
        return nil, "Invalid compressed data"
    end
    
    -- Decompress data using LibCompress
    local decompressed, err = self.LibCompress:Decompress(compressedData)
    
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
    if not TWRA_SavedVariables or not TWRA_SavedVariables.assignments then
        self:Debug("error", "No assignments data structure to store compressed data in")
        return false
    end
    
    if not compressedData then
        self:Debug("error", "No compressed data to store")
        return false
    end
    
    -- Store compressed data instead of source
    TWRA_SavedVariables.assignments.compressed = compressedData
    
    -- Don't store source anymore
    TWRA_SavedVariables.assignments.source = nil
    
    self:Debug("compress", "Stored compressed data (" .. string.len(compressedData) .. " bytes)")
    return true
end

-- Get stored compressed data for syncing
function TWRA:GetStoredCompressedData()
    if not TWRA_SavedVariables or not TWRA_SavedVariables.assignments then
        return nil, "No saved assignments"
    end
    
    if not TWRA_SavedVariables.assignments.compressed then
        -- If compressed data doesn't exist yet, create it
        local compressed, err = self:CompressAssignmentsData()
        if not compressed then
            return nil, "Failed to generate compressed data: " .. tostring(err)
        end
        
        -- Store for future use
        self:StoreCompressedData(compressed)
    end
    
    return TWRA_SavedVariables.assignments.compressed
end