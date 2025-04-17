-- TWRA Compression Module
-- This module handles the compression and decompression of data for sync operations
TWRA = TWRA or {}

-- Initialize compression system
function TWRA:InitializeCompression()
    -- Use LibCompress for Huffman compression
    self.LibCompress = LibStub:GetLibrary("LibCompress")
    
    -- Load AceSerializer for better data serialization
    self.AceSerializer = LibStub:GetLibrary("AceSerializer-3.0")
    
    if not self.LibCompress then
        self:Debug("error", "LibCompress library not found")
        return false
    end
    
    if not self.AceSerializer then
        self:Debug("error", "AceSerializer-3.0 library not found")
        self:Debug("compress", "Falling back to TableToString for serialization")
    else
        self:Debug("compress", "AceSerializer-3.0 loaded successfully")
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
    
    -- Test various serialization and compression methods
    local results = {}
    
    -- 1. Original LibCompress TableToString + Huffman
    local lcString = self.LibCompress:TableToString(testData)
    if not lcString then
        self:Debug("error", "Failed to convert table to string using LibCompress")
        return false, "TableToString conversion failed"
    end
    
    results.lcOrigSize = string.len(lcString)
    
    local lcCompressed = self.LibCompress:CompressHuffman(lcString)
    if not lcCompressed then
        self:Debug("error", "Failed to compress data using LibCompress Huffman")
        return false, "LibCompress Huffman compression failed"
    end
    
    results.lcCompressedSize = string.len(lcCompressed)
    results.lcRatio = math.floor((results.lcCompressedSize / results.lcOrigSize) * 100)
    
    -- 2. AceSerializer + LibCompress Huffman (if available)
    if self.AceSerializer then
        local aceString = self.AceSerializer:Serialize(testData)
        results.aceOrigSize = string.len(aceString)
        
        local aceCompressed = self.LibCompress:CompressHuffman(aceString)
        if not aceCompressed then
            self:Debug("error", "Failed to compress AceSerializer data")
        else
            results.aceCompressedSize = string.len(aceCompressed)
            results.aceRatio = math.floor((results.aceCompressedSize / results.aceOrigSize) * 100)
        end
    end
    
    -- 3. Our optimized approach (AceSerializer + pattern optimization + Huffman)
    local optimizedString, optimizedCompressed
    if self.AceSerializer then
        optimizedString = self.AceSerializer:Serialize(testData)
    else
        optimizedString = self.LibCompress:TableToString(testData)
    end
    
    -- Apply pattern optimization
    optimizedString = self:ApplyPatternOptimization(optimizedString)
    
    results.optOrigSize = string.len(optimizedString)
    
    optimizedCompressed = self.LibCompress:CompressHuffman(optimizedString)
    results.optCompressedSize = string.len(optimizedCompressed)
    results.optRatio = math.floor((results.optCompressedSize / results.optOrigSize) * 100)
    
    -- 4. Test with real addon data
    local realDataTest = false
    if TWRA_SavedVariables and TWRA_SavedVariables.assignments and 
       TWRA_SavedVariables.assignments.data then
        realDataTest = true
        
        local syncData = self:PrepareDataForSync()
        if syncData then
            -- Method 1: Original approach
            local realDataString = self.LibCompress:TableToString(syncData)
            local realCompressed1 = self.LibCompress:CompressHuffman(realDataString)
            
            -- Method 2: New approach with AceSerializer and pattern optimization
            local serializedString
            if self.AceSerializer then
                serializedString = self.AceSerializer:Serialize(syncData)
            else
                serializedString = realDataString
            end
            local optimizedRealString = self:ApplyPatternOptimization(serializedString)
            local realCompressed2 = self.LibCompress:CompressHuffman(optimizedRealString)
            
            results.realOrigSize = string.len(realDataString)
            results.realCompressed1Size = string.len(realCompressed1)
            results.realCompressed1Ratio = math.floor((results.realCompressed1Size / results.realOrigSize) * 100)
            
            results.realOptSize = string.len(optimizedRealString)
            results.realCompressed2Size = string.len(realCompressed2)
            results.realCompressed2Ratio = math.floor((results.realCompressed2Size / results.realOrigSize) * 100)
            
            -- Test compression and decompression to verify data integrity
            local recoveredData = self:DecompressAssignmentsData("\240" .. realCompressed2)
            if recoveredData then
                self:Debug("compress", "Real data compression/decompression successful")
                results.realSuccess = true
            else
                self:Debug("error", "Failed to decompress real data with new method")
                results.realSuccess = false
            end
        end
    end
    
    -- Display the results
    self:Debug("compress", "Compression test results:")
    self:Debug("compress", "LibCompress original: " .. results.lcOrigSize .. " bytes")
    self:Debug("compress", "LibCompress compressed: " .. results.lcCompressedSize .. " bytes (" .. results.lcRatio .. "%)")
    
    if self.AceSerializer and results.aceCompressedSize then
        self:Debug("compress", "AceSerializer original: " .. results.aceOrigSize .. " bytes")
        self:Debug("compress", "AceSerializer compressed: " .. results.aceCompressedSize .. " bytes (" .. results.aceRatio .. "%)")
    end
    
    self:Debug("compress", "Optimized original: " .. results.optOrigSize .. " bytes")
    self:Debug("compress", "Optimized compressed: " .. results.optCompressedSize .. " bytes (" .. results.optRatio .. "%)")
    
    if realDataTest then
        self:Debug("compress", "Real data tests:")
        self:Debug("compress", "  Original method: " .. results.realCompressed1Size .. " bytes (" .. results.realCompressed1Ratio .. "%)")
        self:Debug("compress", "  New optimized method: " .. results.realCompressed2Size .. " bytes (" .. results.realCompressed2Ratio .. "%)")
        self:Debug("compress", "  Improvement: " .. (results.realCompressed1Size - results.realCompressed2Size) .. " bytes (" ..
                math.floor(((results.realCompressed1Size - results.realCompressed2Size) / results.realCompressed1Size) * 100) .. "% better)")
    end
    
    -- Print results to chat frame for visibility
    DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA Compression Test|r: " .. 
                               (self.AceSerializer and "Using AceSerializer" or "Using TableToString"))
    DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA Compression Test|r: Original size: " .. results.lcOrigSize .. " bytes")
    DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA Compression Test|r: Best compression: " .. results.optCompressedSize .. 
                               " bytes (" .. results.optRatio .. "% of original)")
    
    if realDataTest and results.realSuccess then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA Compression Test|r: Real data improvement: " .. 
                                   math.floor(((results.realCompressed1Size - results.realCompressed2Size) / results.realCompressed1Size) * 100) .. 
                                   "% better with new method!")
    end
    
    return true, results
end

-- Pattern optimization to improve compression
function TWRA:ApplyPatternOptimization(inputString)
    if not inputString then return nil end
    
    -- Common patterns in raid assignments and serialized data
    local patterns = {
        -- Section keys
        ["Section Name"] = "\001",
        ["Section Header"] = "\002",
        ["Section Rows"] = "\003",
        ["Section Metadata"] = "\004",
        
        -- Common role names
        ["Tank"] = "\005",
        ["Healer"] = "\006",
        ["DPS"] = "\007",
        
        -- Raid markers
        ["Skull"] = "\008",
        ["Cross"] = "\009",
        ["Star"] = "\010",
        ["Circle"] = "\011",
        ["Square"] = "\012",
        ["Triangle"] = "\013",
        ["Diamond"] = "\014",
        ["Moon"] = "\015",
        
        -- AceSerializer patterns
        ['^".-"$'] = "\016",
        ["^%-?%d+$"] = "\017",
        ["^%-?%d+%.%d+$"] = "\018",
        ["^true$"] = "\019",
        ["^false$"] = "\020",
        ["^nil$"] = "\021",
        
        -- Additional common words in raid assignments
        ["target"] = "\022",
        ["player"] = "\023",
        ["group"] = "\024",
        ["raid"] = "\025",
        ["assignment"] = "\026",
        ["boss"] = "\027",
        ["ability"] = "\028",
        ["interrupt"] = "\029",
        ["dispel"] = "\030",
        ["cooldown"] = "\031"
    }
    
    -- Apply pattern substitution
    local optimizedString = inputString
    local substitutionCount = 0
    
    -- Replace patterns
    for pattern, replacement in pairs(patterns) do
        -- Handle string patterns differently than exact matches
        if string.sub(pattern, 1, 1) == "^" then
            -- This is a pattern, not an exact string
            -- We need to handle this differently
            local count
            optimizedString, count = string.gsub(optimizedString, pattern, replacement)
            substitutionCount = substitutionCount + count
        else
            -- Exact string replacement
            local count
            optimizedString, count = string.gsub(optimizedString, pattern, replacement)
            substitutionCount = substitutionCount + count
        end
    end
    
    self:Debug("compress", "Applied " .. substitutionCount .. " pattern substitutions")
    return optimizedString
end

-- Restore original strings from pattern-optimized data
function TWRA:RestoreFromPatternOptimization(optimizedString)
    if not optimizedString then return nil end
    
    -- Reverse pattern mapping for decompression
    local reversePatterns = {
        ["\001"] = "Section Name",
        ["\002"] = "Section Header",
        ["\003"] = "Section Rows",
        ["\004"] = "Section Metadata",
        ["\005"] = "Tank",
        ["\006"] = "Healer",
        ["\007"] = "DPS",
        ["\008"] = "Skull",
        ["\009"] = "Cross",
        ["\010"] = "Star",
        ["\011"] = "Circle",
        ["\012"] = "Square",
        ["\013"] = "Triangle",
        ["\014"] = "Diamond",
        ["\015"] = "Moon",
        ["\022"] = "target",
        ["\023"] = "player",
        ["\024"] = "group",
        ["\025"] = "raid",
        ["\026"] = "assignment",
        ["\027"] = "boss",
        ["\028"] = "ability",
        ["\029"] = "interrupt",
        ["\030"] = "dispel",
        ["\031"] = "cooldown"
        
        -- Note: We don't restore regex patterns as they're context dependent
        -- AceSerializer will handle those patterns during deserialization
    }
    
    -- Apply reverse substitutions
    local restoredString = optimizedString
    local substitutionCount = 0
    
    -- Replace patterns
    for replacement, pattern in pairs(reversePatterns) do
        local singleChar = string.format("%c", string.byte(replacement))
        local _, count = string.gsub(restoredString, singleChar, pattern)
        restoredString = string.gsub(restoredString, singleChar, pattern)
        substitutionCount = substitutionCount + count
    end
    
    self:Debug("compress", "Restored " .. substitutionCount .. " pattern substitutions")
    return restoredString
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
    
    -- Track original data size for comparison
    local originalStringSize = 0
    local serializedString = nil
    
    -- Use AceSerializer if available (better for complex data)
    if self.AceSerializer then
        serializedString = self.AceSerializer:Serialize(syncData)
        self:Debug("compress", "Data serialized with AceSerializer")
    else
        -- Fallback to LibCompress's TableToString
        serializedString = self.LibCompress:TableToString(syncData)
        self:Debug("compress", "Data serialized with TableToString (AceSerializer not available)")
    end
    
    if not serializedString then
        self:Debug("error", "Failed to serialize data")
        return nil, "Failed to serialize data"
    end
    
    originalStringSize = string.len(serializedString)
    
    -- Apply pattern optimization before compression
    local optimizedString = self:ApplyPatternOptimization(serializedString)
    
    -- Use Huffman compression specifically (better for our text data)
    local compressed = self.LibCompress:CompressHuffman(optimizedString)
    
    if not compressed then
        self:Debug("error", "Failed to compress data")
        return nil, "Compression failed"
    end
    
    local compressionRatio = math.floor((string.len(compressed) / originalStringSize) * 100)
    self:Debug("compress", "Compressed " .. originalStringSize .. " bytes to " .. 
               string.len(compressed) .. " bytes (" .. compressionRatio .. "% of original)")
    
    -- Add a marker at the beginning to indicate the serialization method
    -- 240 = pattern optimized AceSerializer
    -- 241 = pattern optimized TableToString
    if self.AceSerializer then
        return "\240" .. compressed
    else
        return "\241" .. compressed
    end
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
    local useAceSerializer = (marker == 240)
    local usePatternOptimization = (marker == 240 or marker == 241)
    
    if usePatternOptimization then
        compressedData = string.sub(compressedData, 2) -- Remove the marker
    end
    
    -- Decompress data using LibCompress
    local decompressed, err = self.LibCompress:DecompressHuffman(compressedData)
    
    if not decompressed then
        self:Debug("error", "Failed to decompress data: " .. tostring(err))
        return nil, "Decompression failed: " .. tostring(err)
    end
    
    -- If pattern optimized, restore the original patterns
    if usePatternOptimization then
        decompressed = self:RestoreFromPatternOptimization(decompressed)
    end
    
    -- Convert string back to table structure
    local dataTable
    
    if useAceSerializer and self.AceSerializer then
        -- Use AceSerializer to deserialize
        local success
        success, dataTable = self.AceSerializer:Deserialize(decompressed)
        
        if not success then
            self:Debug("error", "Failed to deserialize data with AceSerializer: " .. tostring(dataTable))
            return nil, "Failed to deserialize data: " .. tostring(dataTable)
        end
    else
        -- Fallback to StringToTable
        dataTable = self.LibCompress:StringToTable(decompressed)
        
        if not dataTable then
            self:Debug("error", "Failed to convert decompressed string back to table")
            return nil, "Failed to parse decompressed data"
        end
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

-- Benchmark various compression methods using real assignment data
function TWRA:BenchmarkCompression(iterations)
    iterations = iterations or 3 -- Reduced default iterations for faster results
    
    -- Check if we have any saved data to test with
    if not TWRA_SavedVariables or not TWRA_SavedVariables.assignments or 
       not TWRA_SavedVariables.assignments.data then
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
    
    -- Define test methods with simpler structure
    local results = {
        methods = {
            ["TableToString + Huffman"] = {size = 0, ratio = 0},
            ["AceSerializer + Huffman"] = {size = 0, ratio = 0},
            ["AceSerializer + Pattern + Huffman"] = {size = 0, ratio = 0}
        },
        originalSize = 0
    }
    
    -- Method 1: Original LibCompress TableToString + Huffman
    DEFAULT_CHAT_FRAME:AddMessage("Testing TableToString + Huffman...")
    local serialized1 = self.LibCompress:TableToString(syncData)
    if not serialized1 then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF3333Error:|r TableToString conversion failed")
        return nil, "TableToString conversion failed"
    end
    
    results.originalSize = string.len(serialized1)
    DEFAULT_CHAT_FRAME:AddMessage("Original data size: " .. results.originalSize .. " bytes")
    
    local compressed1 = self.LibCompress:CompressHuffman(serialized1)
    if compressed1 then
        results.methods["TableToString + Huffman"].size = string.len(compressed1)
        results.methods["TableToString + Huffman"].ratio = 
            math.floor((results.methods["TableToString + Huffman"].size / results.originalSize) * 100)
        DEFAULT_CHAT_FRAME:AddMessage("TableToString + Huffman: " .. 
            results.methods["TableToString + Huffman"].size .. " bytes (" ..
            results.methods["TableToString + Huffman"].ratio .. "% of original)")
        
        -- Test decompression to verify integrity
        local decompressed = self.LibCompress:DecompressHuffman(compressed1)
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
    
    -- Method 2: AceSerializer + Huffman
    if self.AceSerializer then
        DEFAULT_CHAT_FRAME:AddMessage("Testing AceSerializer + Huffman...")
        local serialized2 = self.AceSerializer:Serialize(syncData)
        if serialized2 then
            local compressed2 = self.LibCompress:CompressHuffman(serialized2)
            if compressed2 then
                results.methods["AceSerializer + Huffman"].size = string.len(compressed2)
                results.methods["AceSerializer + Huffman"].ratio = 
                    math.floor((results.methods["AceSerializer + Huffman"].size / results.originalSize) * 100)
                DEFAULT_CHAT_FRAME:AddMessage("AceSerializer + Huffman: " .. 
                    results.methods["AceSerializer + Huffman"].size .. " bytes (" ..
                    results.methods["AceSerializer + Huffman"].ratio .. "% of original)")
                
                -- Test decompression to verify integrity
                local decompressed = self.LibCompress:DecompressHuffman(compressed2)
                if not decompressed then
                    DEFAULT_CHAT_FRAME:AddMessage("|cFFFF3333Error:|r Decompression failed for AceSerializer + Huffman")
                else
                    local success, recovered = self.AceSerializer:Deserialize(decompressed)
                    if not success then
                        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF3333Error:|r Deserialization failed for AceSerializer + Huffman")
                    else
                        DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00Integrity check:|r PASS")
                    end
                end
            else
                DEFAULT_CHAT_FRAME:AddMessage("|cFFFF3333Error:|r Compression failed for AceSerializer + Huffman")
            end
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF3333Error:|r Serialization failed for AceSerializer + Huffman")
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("Skipping AceSerializer tests (library not available)")
    end
    
    -- Method 3: AceSerializer + Pattern + Huffman
    if self.AceSerializer then
        DEFAULT_CHAT_FRAME:AddMessage("Testing AceSerializer + Pattern + Huffman...")
        local serialized3 = self.AceSerializer:Serialize(syncData)
        if serialized3 then
            local optimizedString = self:ApplyPatternOptimization(serialized3)
            local compressed3 = self.LibCompress:CompressHuffman(optimizedString)
            if compressed3 then
                results.methods["AceSerializer + Pattern + Huffman"].size = string.len(compressed3)
                results.methods["AceSerializer + Pattern + Huffman"].ratio = 
                    math.floor((results.methods["AceSerializer + Pattern + Huffman"].size / results.originalSize) * 100)
                DEFAULT_CHAT_FRAME:AddMessage("AceSerializer + Pattern + Huffman: " .. 
                    results.methods["AceSerializer + Pattern + Huffman"].size .. " bytes (" ..
                    results.methods["AceSerializer + Pattern + Huffman"].ratio .. "% of original)")
                
                -- Test decompression to verify integrity
                local decompressed = self.LibCompress:DecompressHuffman(compressed3)
                if not decompressed then
                    DEFAULT_CHAT_FRAME:AddMessage("|cFFFF3333Error:|r Decompression failed for AceSerializer + Pattern + Huffman")
                else
                    local restored = self:RestoreFromPatternOptimization(decompressed)
                    if not restored then
                        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF3333Error:|r Pattern restoration failed")
                    else
                        local success, recovered = self.AceSerializer:Deserialize(restored)
                        if not success then
                            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF3333Error:|r Deserialization failed for AceSerializer + Pattern + Huffman")
                        else
                            DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00Integrity check:|r PASS")
                        end
                    end
                end
            else
                DEFAULT_CHAT_FRAME:AddMessage("|cFFFF3333Error:|r Compression failed for AceSerializer + Pattern + Huffman")
            end
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF3333Error:|r Serialization failed for AceSerializer + Pattern + Huffman")
        end
    end
    
    -- Calculate the best method based on compression ratio
    local bestMethod = nil
    local bestRatio = 100
    for name, data in pairs(results.methods) do
        if data.ratio > 0 and data.ratio < bestRatio then
            bestRatio = data.ratio
            bestMethod = name
        end
    end
    
    -- Summary
    DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA Compression Benchmark Results:|r")
    DEFAULT_CHAT_FRAME:AddMessage("Original data size: " .. results.originalSize .. " bytes")
    
    for name, data in pairs(results.methods) do
        if data.size > 0 then
            DEFAULT_CHAT_FRAME:AddMessage(name .. ": " .. data.size .. " bytes (" .. data.ratio .. "% of original)")
        end
    end
    
    if bestMethod then
        DEFAULT_CHAT_FRAME:AddMessage("Best compression method: |cFF00FF00" .. bestMethod .. "|r")
        
        -- Calculate improvement over original method
        if bestMethod ~= "TableToString + Huffman" then
            local improvement = results.methods["TableToString + Huffman"].size - results.methods[bestMethod].size
            local improvementPercent = math.floor((improvement / results.methods["TableToString + Huffman"].size) * 100)
            DEFAULT_CHAT_FRAME:AddMessage("Improvement over original method: " .. improvement .. 
                " bytes (" .. improvementPercent .. "% better)")
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("No method provided better compression")
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA Compression Benchmark completed|r")
    return results, bestMethod
end