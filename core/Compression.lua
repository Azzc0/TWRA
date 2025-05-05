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

-- Simple function to serialize a table to a string using standard Lua syntax
function TWRA:SerializeTable(tbl)
    if type(tbl) ~= "table" then
        return tostring(tbl)
    end
    
    local result = "{"
    
    -- Process all keys in the table
    local isFirst = true
    for k, v in pairs(tbl) do
        -- Add comma separator between entries
        if not isFirst then
            result = result .. ","
        end
        isFirst = false
        
        -- Format the key part
        if type(k) == "number" then
            result = result .. "[" .. k .. "]="
        elseif type(k) == "string" then
            -- Properly escape string keys
            local escapedKey = string.gsub(k, '(["\\\n\r])', '\\%1')
            result = result .. '["' .. escapedKey .. '"]='
        else
            result = result .. "[" .. tostring(k) .. "]="
        end
        
        -- Format the value part
        if type(v) == "table" then
            result = result .. self:SerializeTable(v)
        elseif type(v) == "string" then
            -- Properly escape string values including commas and quotes
            local escapedValue = v
            escapedValue = string.gsub(escapedValue, '(["\\\n\r])', '\\%1')
            result = result .. '"' .. escapedValue .. '"'
        elseif type(v) == "number" or type(v) == "boolean" then
            result = result .. tostring(v)
        elseif v == nil then
            result = result .. "nil"
        else
            -- For other types, convert to string and escape
            local str = tostring(v)
            local escapedStr = string.gsub(str, '(["\\\n\r])', '\\%1')
            result = result .. '"' .. escapedStr .. '"'
        end
    end
    
    result = result .. "}"
    return result
end

-- Function to deserialize a table string back to a table
function TWRA:DeserializeTable(str)
    if str == nil or str == "" then
        return nil
    end
    
    local func, err = loadstring("return " .. str)
    if not func then
        self:Debug("error", "DeserializeTable error: " .. (err or "Unknown error"))
        return nil
    end
    
    local success, result = pcall(func)
    if not success then
        self:Debug("error", "DeserializeTable execution error: " .. tostring(result))
        return nil
    end
    
    return result
end


-- Compress the structure data (section names only without indices)
function TWRA:CompressStructureData()
    -- Initialize compression system if needed
    if not self.LibCompress then
        if not self:InitializeCompression() then
            self:Debug("error", "Failed to initialize compression system")
            return nil, "Failed to initialize compression system"
        end
    end
    
    -- Extract structure information from TWRA_Assignments
    if not TWRA_Assignments or not TWRA_Assignments.data then
        self:Debug("error", "No assignments data to extract structure from")
        return nil, "No assignment data available"
    end
    
    -- Create a simple array of section names in order
    local sectionNames = {}
    local sectionCount = 0
    
    -- Collect sections in index order
    for i = 1, 100 do  -- Reasonable upper limit
        if TWRA_Assignments.data[i] then
            local sectionData = TWRA_Assignments.data[i]
            if type(sectionData) == "table" then
                local sectionName = sectionData["Section Name"]
                if sectionName then
                    table.insert(sectionNames, sectionName)
                    sectionCount = sectionCount + 1
                end
            end
        end
    end
    
    -- If no sections found, return nil
    if sectionCount == 0 then
        self:Debug("error", "No sections found in assignments data")
        return nil, "No sections found"
    end
    
    -- Create a simple string representation: just section names as comma-separated values
    -- Format: "Section Name 1","Section Name 2",...,"Section Name N"
    local structureString = ""
    for i, name in ipairs(sectionNames) do
        if i > 1 then
            structureString = structureString .. ","
        end
        structureString = structureString .. "\"" .. name .. "\""
    end
    
    self:Debug("compress", "Created structure string with " .. sectionCount .. " sections: " .. string.sub(structureString, 1, 100) .. (string.len(structureString) > 100 and "..." or ""))
    
    -- Apply Huffman compression with explicit error handling
    local success, compressed = pcall(function() 
        return self.LibCompress:CompressHuffman(structureString)
    end)
    
    if not success or not compressed then
        self:Debug("error", "Failed to apply Huffman compression: " .. tostring(compressed))
        -- Fall back to using uncompressed data
        self:Debug("compress", "Using uncompressed data as fallback")
        
        -- Just Base64 encode the string directly
        local encodedData = self:EncodeBase64(structureString)
        if not encodedData then
            self:Debug("error", "Failed to encode structure")
            return nil, "Base64 encoding failed"
        end
        
        -- Add the compression marker (even though it's not compressed)
        return "\241" .. encodedData
    end
    
    -- Success path - log compression stats
    local originalSize = string.len(structureString)
    local compressedSize = string.len(compressed)
    local ratio = math.floor((compressedSize / originalSize) * 100)
    self:Debug("compress", "Huffman compression: " .. originalSize .. " bytes to " .. 
               compressedSize .. " bytes (" .. ratio .. "% of original)")
    
    -- Base64 encode the compressed data
    local encodedData = self:EncodeBase64(compressed)
    if not encodedData then
        self:Debug("error", "Failed to encode compressed structure")
        return nil, "Base64 encoding failed"
    end
    
    -- Add the compression marker
    return "\241" .. encodedData
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
            -- For Section Metadata, make a deep copy to ensure Group Rows metadata is preserved
            if key == "Section Metadata" and type(value) == "table" then
                sectionData[key] = {}
                for metaKey, metaValue in pairs(value) do
                    -- Deep copy each metadata field
                    if type(metaValue) == "table" then
                        sectionData[key][metaKey] = {}
                        for k, v in pairs(metaValue) do
                            sectionData[key][metaKey][k] = v
                        end
                    else
                        sectionData[key][metaKey] = metaValue
                    end
                end
                
                -- Debug output to verify Group Rows are being preserved
                if value["Group Rows"] then
                    local groupRowCount = table.getn(value["Group Rows"])
                    self:Debug("compress", "Preserving " .. groupRowCount .. " Group Rows metadata for section " .. sectionIndex)
                else
                    self:Debug("compress", "No Group Rows metadata found for section " .. sectionIndex)
                end
            else
                -- For other keys, just copy directly
                sectionData[key] = value
            end
        end
    end
    
    -- Ensure Section Metadata exists and Group Rows are present
    if not sectionData["Section Metadata"] then
        sectionData["Section Metadata"] = {}
    end
    
    -- If Group Rows is missing but should be generated, generate it now
    if not sectionData["Section Metadata"]["Group Rows"] or 
       table.getn(sectionData["Section Metadata"]["Group Rows"]) == 0 then
        self:Debug("compress", "Generating missing Group Rows metadata for section " .. sectionIndex)
        
        -- Use GetAllGroupRowsForSection if available
        if self.GetAllGroupRowsForSection then
            sectionData["Section Metadata"]["Group Rows"] = self:GetAllGroupRowsForSection(sectionData)
            self:Debug("compress", "Generated " .. table.getn(sectionData["Section Metadata"]["Group Rows"]) .. 
                      " Group Rows for section " .. sectionIndex)
        else
            self:Debug("error", "GetAllGroupRowsForSection function not available")
        end
    end
    
    -- Add minimal metadata
    sectionData.timestamp = TWRA_Assignments.timestamp or time()
    
    -- Use standard Lua serialization instead of TableToString
    self:Debug("compress", "Using standard Lua serialization for section " .. sectionIndex)
    local serialized = self:SerializeTable(sectionData)
    
    if not serialized then
        self:Debug("error", "Failed to serialize section data")
        return nil, "Serialization failed"
    end
    
    -- Use Huffman compression
    local compressed = self.LibCompress:CompressHuffman(serialized)
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
    self:Debug("compress", "Decompressing structure data of length " .. string.len(compressedStructure))
    
    if not compressedStructure or type(compressedStructure) ~= "string" then
        self:Debug("error", "Invalid compressed structure data")
        return nil
    end
    
    -- More detailed debugging of the first few bytes
    local firstByte = string.byte(compressedStructure, 1)
    local secondByte = string.byte(compressedStructure, 2)
    local prefix = string.sub(compressedStructure, 1, 10)
    self:Debug("data", "Structure data starts with: " .. prefix)
    
    -- Debug the actual byte values rather than characters
    self:Debug("data", "First byte: " .. tostring(firstByte) .. ", Second byte: " .. tostring(secondByte))
    
    -- Add pcall around all potentially failing operations
    local success, decodedString = pcall(function()
        -- Handle the different encoding formats
        if firstByte == 63 and secondByte == 66 then
            -- Format starting with "?B" - skip the "?" character
            self:Debug("compress", "Found ?B prefix (bytes 63, 66), using special decode path")
            local base64Data = string.sub(compressedStructure, 2)  -- Skip the "?" character
            return self:DecodeBase64Raw(base64Data)
        elseif firstByte == 241 then
            -- Normal format with marker - remove the marker and decode
            self:Debug("compress", "Found compression marker (241), using normal decode path")
            local base64Data = string.sub(compressedStructure, 2)
            return self:DecodeBase64Raw(base64Data)
        else
            -- Try direct base64 decoding (fallback for older format)
            self:Debug("compress", "No recognized marker found, trying direct Base64 decode")
            return self:DecodeBase64Raw(compressedStructure)
        end
    end)
    
    if not success or not decodedString then
        self:Debug("error", "Failed to decode Base64 data: " .. tostring(decodedString))
        return nil
    end
    
    self:Debug("data", "Decoded Base64 successfully, length: " .. string.len(decodedString))
    
    -- Check if the decoded string starts with a Huffman marker (byte 3)
    local huffmanMarker = string.byte(decodedString, 1)
    self:Debug("data", "Decoded data first byte: " .. tostring(huffmanMarker))
    
    -- Wrap all decompression in pcall for safety
    local success2, decompressedString = pcall(function()
        -- First try Huffman decompression
        -- Make sure LibCompress is available 
        if not self.LibCompress then 
            if not self:InitializeCompression() then
                self:Debug("error", "Failed to initialize LibCompress for decompression")
                return nil
            end
        end
        
        -- Check if it's uncompressed data with a marker of 1
        if huffmanMarker == 1 then
            -- If it starts with byte 1, it might be uncompressed data (LibCompress format)
            self:Debug("compress", "Found uncompressed marker (1), treating as uncompressed data")
            return string.sub(decodedString, 2) -- Skip the marker byte
        else
            -- Try Huffman decompression
            local decompressedResult = self.LibCompress:DecompressHuffman(decodedString)
            if decompressedResult then
                self:Debug("compress", "Successfully decompressed with Huffman")
                return decompressedResult
            else
                self:Debug("compress", "Huffman decompression failed, assuming raw data")
                return decodedString
            end
        end
    end)
    
    if not success2 then
        self:Debug("error", "Error during decompression: " .. tostring(decompressedString))
        return nil
    end
    
    if not decompressedString then
        self:Debug("error", "Decompression returned nil result")
        return nil
    end
    
    -- Debug the decompressed string
    self:Debug("data", "Decompressed string (first 50 chars): " .. string.sub(decompressedString, 1, 50))
    self:Debug("data", "Full decompressed string: " .. decompressedString)
    
    -- Extract section names with a simple, direct approach
    local function extractSectionNames(decompressedString)
        -- Check if the string is valid
        if not decompressedString or type(decompressedString) ~= "string" then
            return nil
        end
        
        local sections = {}
        -- Simple, direct pattern matching with quotation marks
        local pattern = '"([^"]+)"'
        local i = 1
        
        for name in string.gfind(decompressedString, pattern) do
            sections[i] = name
            i = i + 1
        end
        
        return sections
    end

    -- Wrap section extraction in pcall
    local success3, sections = pcall(function()
        return extractSectionNames(decompressedString)
    end)
    
    if not success3 then
        self:Debug("error", "Error during section extraction: " .. tostring(sections))
        return nil
    end
    
    if not sections or table.getn(sections) == 0 then
        self:Debug("error", "Failed to extract any sections from decompressed data")
        self:Debug("data", "Decompressed string for reference: " .. decompressedString)
        return nil
    end
    
    -- Final validation check
    self:Debug("compress", "Successfully extracted " .. table.getn(sections) .. " sections")
    
    -- List all found sections
    local sectionList = ""
    for i, name in pairs(sections) do
        if i > 1 then
            sectionList = sectionList .. ", "
        end
        sectionList = sectionList .. i .. "=" .. name
    end
    self:Debug("compress", "Extracted sections: " .. sectionList)
    
    return sections
end

-- Decompress section data (version with consistent marker byte handling)
function TWRA:DecompressSectionData(compressedSection)
    if not compressedSection or type(compressedSection) ~= "string" then
        self:Debug("error", "Invalid compressed section data")
        return nil
    end
    
    -- Debug the actual content we're trying to decompress
    self:Debug("compress", "Decompressing section data of length " .. string.len(compressedSection))
    
    -- Check first byte and handle marker properly
    local firstByte = string.byte(compressedSection, 1)
    self:Debug("compress", "First byte of compressed data: " .. tostring(firstByte))
    
    -- Process data based on first byte
    local base64Data = nil
    if firstByte == 241 then  -- Marker byte present (ñ)
        self:Debug("compress", "Marker byte found, extracting Base64 data")
        base64Data = string.sub(compressedSection, 2)  -- Skip the marker byte
    else
        -- The data might be just Base64 without the marker
        self:Debug("compress", "No marker byte found, treating entire string as Base64 data")
        base64Data = compressedSection
    end
    
    -- Decode from Base64
    local decodedString = self:DecodeBase64Raw(base64Data)
    if not decodedString then
        self:Debug("error", "Failed to decode section data from Base64")
        return nil
    end
    
    -- Initialize compression if needed
    if not self.LibCompress then
        if not self:InitializeCompression() then
            self:Debug("error", "LibCompress not available for decompression")
            return nil
        end
    end
    
    -- Decompress using LibCompress
    local decompressedString = self.LibCompress:DecompressHuffman(decodedString)
    if not decompressedString then
        self:Debug("error", "Failed to decompress section data with Huffman")
        return nil
    end
    
    -- Show a bit of the decompressed string for debugging
    self:Debug("data", "Decompressed string begins with: " .. 
              string.sub(decompressedString, 1, math.min(50, string.len(decompressedString))))
    
    -- Try standard Lua deserialization with loadstring
    local success, result = pcall(function()
        local func, errorMsg = loadstring("return " .. decompressedString)
        if not func then
            self:Debug("error", "loadstring failed: " .. tostring(errorMsg))
            return nil
        end
        
        local execSuccess, tbl = pcall(func)
        if not execSuccess then
            self:Debug("error", "Failed to execute loadstring function: " .. tostring(tbl))
            return nil
        end
        
        if type(tbl) ~= "table" then
            self:Debug("error", "Deserialized result is not a table: " .. type(tbl))
            return nil
        end
        
        return tbl
    end)
    
    if not success or not result then
        self:Debug("error", "All deserialization methods failed: " .. tostring(result))
        return nil
    end
    
    -- Fill in any missing indices in the table
    return self:FillMissingIndices(result)
end

-- Helper function to fill in missing indices in a table
function TWRA:FillMissingIndices(inputTable)
    if not inputTable or type(inputTable) ~= "table" then
        return inputTable
    end
    
    -- Process all arrays in the table (indexed by numbers)
    for key, value in pairs(inputTable) do
        -- If value is a table, recursively process it first
        if type(value) == "table" then
            inputTable[key] = self:FillMissingIndices(value)
        end
    end
    
    -- After processing nested tables, check if this is an array
    -- Determine if this table appears to be an array (has numeric indices)
    local isArray = false
    local maxIndex = 0
    
    for index, _ in pairs(inputTable) do
        if type(index) == "number" then
            isArray = true
            if index > maxIndex then
                maxIndex = index
            end
        end
    end
    
    -- If it's an array, fill in missing indices
    if isArray and maxIndex > 0 then
        for i = 1, maxIndex do
            if inputTable[i] == nil then
                inputTable[i] = "" -- Fill with empty string
            end
        end
    end
    
    -- Special handling for section data to ensure consistency across the table
    -- First, determine the number of columns from Section Header if present
    local headerColumnCount = 0
    if inputTable["Section Header"] and type(inputTable["Section Header"]) == "table" then
        -- Find max header index
        for headerIdx, _ in pairs(inputTable["Section Header"]) do
            if type(headerIdx) == "number" and headerIdx > headerColumnCount then
                headerColumnCount = headerIdx
            end
        end
        
        -- Fill in missing header indices
        for i = 1, headerColumnCount do
            if inputTable["Section Header"][i] == nil then
                inputTable["Section Header"][i] = "" -- Fill with empty string
            end
        end
    end
    
    -- If we have Section Rows, ensure each row has as many columns as the header
    if inputTable["Section Rows"] and type(inputTable["Section Rows"]) == "table" and headerColumnCount > 0 then
        for rowIndex, rowData in pairs(inputTable["Section Rows"]) do
            if type(rowData) == "table" then
                -- Each row should have exactly the same number of columns as the header
                for i = 1, headerColumnCount do
                    if rowData[i] == nil then
                        rowData[i] = "" -- Fill with empty string
                    end
                end
                -- Log the row data after filling for debugging
                local rowContents = ""
                for i = 1, headerColumnCount do
                    rowContents = rowContents .. "[" .. i .. "]=" .. (rowData[i] or "nil") .. " "
                end
                self:Debug("compress", "Filled row " .. rowIndex .. ": " .. rowContents)
            end
        end
    else
        -- Generic array handling if there's no header to reference
        if inputTable["Section Rows"] and type(inputTable["Section Rows"]) == "table" then
            -- Find max column count across all rows
            local maxColumnCount = 0
            for _, rowData in pairs(inputTable["Section Rows"]) do
                if type(rowData) == "table" then
                    for colIndex, _ in pairs(rowData) do
                        if type(colIndex) == "number" and colIndex > maxColumnCount then
                            maxColumnCount = colIndex
                        end
                    end
                end
            end
            
            -- Now ensure all rows have that many columns
            if maxColumnCount > 0 then
                for rowIndex, rowData in pairs(inputTable["Section Rows"]) do
                    if type(rowData) == "table" then
                        for i = 1, maxColumnCount do
                            if rowData[i] == nil then
                                rowData[i] = "" -- Fill with empty string
                            end
                        end
                    end
                end
            end
        end
    end
    
    return inputTable
end

-- Store segmented compressed data
function TWRA:StoreSegmentedData()
    -- CRITICAL FIX: Always create a completely fresh TWRA_CompressedAssignments structure
    -- This ensures no stale sections remain across imports/rebuilds
    TWRA_CompressedAssignments = {
        sections = {},
        structure = nil,
        timestamp = nil,
        useSectionCompression = true
    }
    self:Debug("compress", "Completely reset TWRA_CompressedAssignments at start of StoreSegmentedData")
    
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