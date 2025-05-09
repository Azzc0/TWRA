-- TWRA Base64 Module
-- Handles encoding and decoding of Base64 strings

TWRA = TWRA or {}

-- Initialize with character table from Constants or create if needed
local b64Table = TWRA.BASE64_TABLE or {
    ['A']=0,['B']=1,['C']=2,['D']=3,['E']=4,['F']=5,['G']=6,['H']=7,['I']=8,['J']=9,
    ['K']=10,['L']=11,['M']=12,['N']=13,['O']=14,['P']=15,['Q']=16,['R']=17,['S']=18,
    ['T']=19,['U']=20,['V']=21,['W']=22,['X']=23,['Y']=24,['Z']=25,['a']=26,['b']=27,
    ['c']=28,['d']=29,['e']=30,['f']=31,['g']=32,['h']=33,['i']=34,['j']=35,['k']=36,
    ['l']=37,['m']=38,['n']=39,['o']=40,['p']=41,['q']=42,['r']=43,['s']=44,['t']=45,
    ['u']=46,['v']=47,['w']=48,['x']=49,['y']=50,['z']=51,['0']=52,['1']=53,['2']=54,
    ['3']=55,['4']=56,['5']=57,['6']=58,['7']=59,['8']=60,['9']=61,['+'] = 62,['/'] = 63,
    ['='] = -1
}

-- Define abbreviation mappings (must match the ones in Google Spreadsheet script)
TWRA.ABBREVIATION_MAPPINGS = {
    -- Icon column abbreviations
    ["1"] = "Star",
    ["2"] = "Circle",
    ["3"] = "Diamond",
    ["4"] = "Triangle",
    ["5"] = "Moon",
    ["6"] = "Square",
    ["7"] = "Cross",
    ["8"] = "Skull",
    ["9"] = "GUID",
    ["!"] = "Warning",
    ["?"] = "Note",
    
    -- Class and group abbreviations
    ["D"] = "Druids",
    ["Hu"] = "Hunters",
    ["M"] = "Mages",
    ["Pa"] = "Paladins",
    ["Pr"] = "Priests",
    ["R"] = "Rogues",
    ["S"] = "Shamans",
    ["W"] = "Warriors",
    ["Wl"] = "Warlocks",
    ["G"] = "Group",
    ["Gr"] = "Groups",
    ["G1"] = "Group 1",
    ["G2"] = "Group 2",
    ["G3"] = "Group 3",
    ["G4"] = "Group 4",
    ["G5"] = "Group 5",
    ["G6"] = "Group 6",
    ["G7"] = "Group 7",
    ["G8"] = "Group 8",

    -- Header abbreviations
    ["T"] = "Tank",
    ["H"] = "Heal",
    ["He"] = "Healer",
    ["I"] = "Interrupt",
    ["B"] = "Banish",
    ["Dc"] = "Decurse",
    ["Dp"] = "Depoison",
    ["Ds"] = "Dispell",
    ["Dd"] = "Dedisease",
    ["Ri"] = "Ranged Interrupt",
    ["P"] = "Pull",
    ["K"] = "Kite"
}

local function b64Encode(ch)
    if not ch then return "A" end
    local b = ch
    if b < 64 then
    else
        b = b - (math.floor(b / 64) * 64)
    end
    
    if b < 26 then return string.char(65 + b) end
    if b < 52 then return string.char(71 + b) end
    if b < 62 then return string.char(b - 4) end
    if b == 62 then return "+" end
    return "/"
end

-- Initialize the encode array for faster lookups if not present
local b64EncodeArray = {}
for i=0, 63 do
    b64EncodeArray[i] = b64Encode(i)
end

-- Initialize LibCompress library
local LibCompress = LibStub:GetLibrary("LibCompress")

-- Function to compress data using Huffman encoding
-- This is a new function that uses LibCompress TableToString + Huffman compression
function TWRA:CompressAssignmentsData(data)
    if not data then
        self:Debug("error", "CompressAssignmentsData: nil data provided", true)
        return nil
    end
    
    self:Debug("data", "Compressing assignment data for storage/transmission")
    local startTime = debugprofilestop and debugprofilestop() or 0
    
    -- First, convert the Lua table to a string representation
    local tableString = LibCompress:TableToString(data)
    if not tableString then
        self:Debug("error", "Failed to convert table to string format", true)
        return nil
    end
    
    -- Then compress the string using Huffman encoding
    local compressedString = LibCompress:CompressHuffman(tableString)
    if not compressedString then
        self:Debug("error", "Huffman compression failed", true)
        return nil
    end
    
    -- Calculate compression ratio for monitoring
    local originalSize = string.len(tableString or "")
    local compressedSize = string.len(compressedString or "")
    local ratio = originalSize > 0 and math.floor((compressedSize / originalSize) * 100) or 0
    
    if debugprofilestop then
        local compressionTime = debugprofilestop() - startTime
        self:Debug("performance", "Data compressed: " .. originalSize .. " bytes to " .. 
                   compressedSize .. " bytes (" .. ratio .. "%) in " .. compressionTime .. "ms")
    else
        self:Debug("data", "Data compressed: " .. originalSize .. " bytes to " .. 
                   compressedSize .. " bytes (" .. ratio .. "%)")
    end
    
    -- Base64 encode for safe transfer
    local base64String = self:EncodeBase64(compressedString)
    
    -- Add a marker at the beginning to indicate this is using normal TableToString compression
    return "\241" .. base64String
end

-- Function to decompress data compressed with CompressAssignmentsData
function TWRA:DecompressAssignmentsData(compressedData)
    self:Debug("error", "DecompressAssignmentsData called from Base64.lua")
    if not compressedData then
        self:Debug("error", "DecompressAssignmentsData: nil data provided", true)
        return nil
    end
    
    -- Check for marker - only support new format with byte \241 marker
    if string.byte(compressedData, 1) ~= 241 then
        self:Debug("error", "Data is not in the expected compressed format (missing \\241 marker)", true)
        return nil
    end
    
    self:Debug("data", "Decompressing assignment data")
    local startTime = debugprofilestop and debugprofilestop() or 0
    
    -- Skip the marker prefix and decode the Base64 string
    local compressedString = string.sub(compressedData, 2)
    compressedString = self:DecodeBase64Raw(compressedString)
    
    if not compressedString then
        self:Debug("error", "Failed to decode Base64 data", true)
        return nil
    end
    
    -- Decompress using Huffman
    local tableString, decompressionError = LibCompress:DecompressHuffman(compressedString)
    if not tableString or decompressionError then
        self:Debug("error", "Failed to decompress data: " .. (decompressionError or "unknown error"), true)
        return nil
    end
    
    -- Convert the string back to a table
    local resultTable = LibCompress:StringToTable(tableString)
    if not resultTable then
        self:Debug("error", "Failed to convert string back to table", true)
        return nil
    end
    
    if debugprofilestop then
        local decompressionTime = debugprofilestop() - startTime
        self:Debug("performance", "Data decompressed in " .. decompressionTime .. "ms")
    end
    
    -- Return the decompressed table - let the caller handle saving and UI updates
    return resultTable
end

-- Function to prepare data for sync by removing client-specific information
function TWRA:PrepareDataForSync(data)
    if not data or not data.data then
        self:Debug("error", "PrepareDataForSync: Invalid data structure", true)
        return data
    end
    
    self:Debug("sync", "Preparing assignment data for synchronization")
    
    -- Create a deep copy to avoid modifying the original
    local syncData = {
        data = {}
    }
    
    -- Copy all sections except client-specific data
    for sectionIdx, section in pairs(data.data) do
        if type(section) == "table" then
            syncData.data[sectionIdx] = {}
            
            -- Copy basic section data
            for k, v in pairs(section) do
                if k ~= "Section Player Info" and k ~= "_specialRowIndices" then
                    if type(v) == "table" then
                        -- Deep copy for tables
                        syncData.data[sectionIdx][k] = {}
                        for tk, tv in pairs(v) do
                            if type(tv) == "table" then
                                syncData.data[sectionIdx][k][tk] = {}
                                for stk, stv in pairs(tv) do
                                    syncData.data[sectionIdx][k][tk][stk] = stv
                                end
                            else
                                syncData.data[sectionIdx][k][tk] = tv
                            end
                        end
                    else
                        syncData.data[sectionIdx][k] = v
                    end
                end
            end
            
            -- Initialize empty Section Player Info to ensure consistent structure
            syncData.data[sectionIdx]["Section Player Info"] = { 
                ["Relevant Rows"] = {} 
            }
        end
    end
    
    self:Debug("sync", "Data prepared for sync: removed client-specific information")
    return syncData
end

-- Function to expand abbreviations based on static mapping table
function TWRA:ExpandAbbreviations(data)
    if not data or type(data) ~= "table" then
        self:Debug("error", "ExpandAbbreviations: Invalid data structure")
        return data
    end
    
    if not self.ABBREVIATION_MAPPINGS then
        self:Debug("error", "ExpandAbbreviations: No abbreviation mappings defined")
        return data
    end
    
    self:Debug("data", "Expanding abbreviations in imported data")
    
    -- Process each section
    if data.data and type(data.data) == "table" then
        for sectionIndex, section in pairs(data.data) do
            -- Skip if not a table
            if type(section) ~= "table" then
                self:Debug("data", "Skipping non-table section: " .. tostring(sectionIndex))
            else
                -- Process section header abbreviations
                if section["Section Header"] and type(section["Section Header"]) == "table" then
                    for i, headerValue in pairs(section["Section Header"]) do
                        if type(headerValue) == "string" and self.ABBREVIATION_MAPPINGS[headerValue] then
                            section["Section Header"][i] = self.ABBREVIATION_MAPPINGS[headerValue]
                            self:Debug("data", "Expanded header abbreviation: " .. headerValue .. " -> " .. self.ABBREVIATION_MAPPINGS[headerValue])
                        end
                    end
                end
                
                -- Process section rows
                if section["Section Rows"] and type(section["Section Rows"]) == "table" then
                    for rowIndex, row in pairs(section["Section Rows"]) do
                        if type(row) == "table" then
                            for colIndex, value in pairs(row) do
                                -- Try exact match first
                                if type(value) == "string" and self.ABBREVIATION_MAPPINGS[value] then
                                    row[colIndex] = self.ABBREVIATION_MAPPINGS[value]
                                    self:Debug("data", "Expanded row abbreviation: " .. value .. " -> " .. self.ABBREVIATION_MAPPINGS[value], false, true)
                                end
                                -- For icon column (usually index 1), also try special handling
                                if colIndex == 1 and type(value) == "string" then
                                    -- Handle numeric icons (1-9) which should become Star, Circle, etc.
                                    local num = tonumber(value)
                                    if num and num >= 1 and num <= 9 and self.ABBREVIATION_MAPPINGS[value] then
                                        row[colIndex] = self.ABBREVIATION_MAPPINGS[value]
                                        self:Debug("data", "Expanded numeric icon: " .. value .. " -> " .. self.ABBREVIATION_MAPPINGS[value], false, true)
                                    -- Handle symbol icons (!, ?)
                                    elseif (value == "!" or value == "?") and self.ABBREVIATION_MAPPINGS[value] then
                                        row[colIndex] = self.ABBREVIATION_MAPPINGS[value]
                                        self:Debug("data", "Expanded symbol icon: " .. value .. " -> " .. self.ABBREVIATION_MAPPINGS[value], false, true)
                                    end
                                end
                            end
                        end
                    end
                end
                
                -- Handle section name if it's abbreviated (unusual but possible)
                if section["Section Name"] and type(section["Section Name"]) == "string" and
                   self.ABBREVIATION_MAPPINGS[section["Section Name"]] then
                    section["Section Name"] = self.ABBREVIATION_MAPPINGS[section["Section Name"]]
                    self:Debug("data", "Expanded section name: " .. section["Section Name"])
                end
            end
        end
    else
        self:Debug("data", "Data doesn't have expected 'data' field structure for abbreviation expansion")
    end
    
    -- Also expand in the short key format
    if data.data and type(data.data) == "table" then
        for sectionIndex, section in pairs(data.data) do
            if type(section) == "table" then
                -- Process short section header abbreviations
                if section["sh"] and type(section["sh"]) == "table" then
                    for i, headerValue in pairs(section["sh"]) do
                        if type(headerValue) == "string" and self.ABBREVIATION_MAPPINGS[headerValue] then
                            section["sh"][i] = self.ABBREVIATION_MAPPINGS[headerValue]
                            self:Debug("data", "Expanded short header abbreviation: " .. headerValue .. " -> " .. self.ABBREVIATION_MAPPINGS[headerValue], false, true)
                        end
                    end
                end
                
                -- Process short section rows
                if section["sr"] and type(section["sr"]) == "table" then
                    for rowIndex, row in pairs(section["sr"]) do
                        if type(row) == "table" then
                            for colIndex, value in pairs(row) do
                                if type(value) == "string" and self.ABBREVIATION_MAPPINGS[value] then
                                    row[colIndex] = self.ABBREVIATION_MAPPINGS[value]
                                    self:Debug("data", "Expanded short row abbreviation: " .. value .. " -> " .. self.ABBREVIATION_MAPPINGS[value], false, true)
                                end
                            end
                        end
                    end
                end
                
                -- Short section name
                if section["sn"] and type(section["sn"]) == "string" and
                   self.ABBREVIATION_MAPPINGS[section["sn"]] then
                    section["sn"] = self.ABBREVIATION_MAPPINGS[section["sn"]]
                    self:Debug("data", "Expanded short section name: " .. section["sn"])
                end
            end
        end
    end
    
    return data
end

-- Plain Base64 decoder without any additional processing
-- Use this for raw binary data decoding
function TWRA:DecodeBase64Raw(base64Str)
    if not base64Str then 
        self:Debug("error", "DecodeBase64Raw failed - nil string", true)
        return nil 
    end
    
    -- Clean up the string
    base64Str = string.gsub(base64Str, " ", "")
    base64Str = string.gsub(base64Str, "\n", "")
    base64Str = string.gsub(base64Str, "\r", "")
    base64Str = string.gsub(base64Str, "\t", "")
    
    -- Safety check for minimum length
    if string.len(base64Str) < 4 then
        self:Debug("error", "DecodeBase64Raw failed - string too short: " .. string.len(base64Str), true)
        return nil
    end
    
    -- Ensure string is a multiple of 4 characters by adding padding if necessary
    local remainder = string.len(base64Str) - (math.floor(string.len(base64Str) / 4) * 4)
    local padding = 0
    if remainder > 0 then
        padding = 4 - remainder
    end
    if padding > 0 then
        for i = 1, padding do
            base64Str = base64Str .. "="
        end
    end
    
    -- Convert Base64 to binary string
    local binaryStr = ""
    local bits = 0
    local bitCount = 0
    
    -- Use protected call for decoding loop to avoid crashing on bad input
    local success, result = pcall(function()
        for i = 1, string.len(base64Str) do
            local b64char = string.sub(base64Str, i, i)
            local b64value = b64Table[b64char]
            
            -- Skip padding characters (=)
            if b64char == "=" then
                -- Just skip, padding at the end is normal
            elseif not b64value then
                -- Invalid character - graceful handling
                self:Debug("error", "Invalid Base64 character: '" .. b64char .. "' at position " .. i, true)
                -- Continue processing rather than breaking, to be more forgiving
            elseif b64value >= 0 then
                -- Left shift bits by 6 and add new value
                bits = (bits * 64) + b64value
                bitCount = bitCount + 6
                
                -- If we have at least 8 bits, extract a byte
                while bitCount >= 8 do
                    bitCount = bitCount - 8
                    
                    -- Extract next byte (shift right)
                    local byte = math.floor(bits / (2^bitCount))
                    
                    -- Keep only the lowest 8 bits
                    byte = byte - (math.floor(byte / 256) * 256)
                    
                    binaryStr = binaryStr .. string.char(byte)
                    
                    -- Remove the consumed bits
                    bits = bits - (math.floor(bits / (2^bitCount)) * (2^bitCount))
                end
            end
        end
        return true
    end)
    
    if not success then
        self:Debug("error", "Error during Base64 decoding: " .. tostring(result), true)
        return nil
    end
    
    return binaryStr
end

-- Handle UI updates and data saving after processing imported data
function TWRA:HandleImportedData(processedData, syncTimestamp, noAnnounce)
    if not processedData then
        self:Debug("error", "HandleImportedData: nil data provided", true)
        return
    end
    
    -- If this is not a sync operation with timestamp, handle it as manual import
    if not syncTimestamp then
        -- This is a manual import, use SaveAssignments to handle proper UI updates
        if self.SaveAssignments then
            local timestamp = time()
            self:SaveAssignments(processedData, "import", timestamp, noAnnounce)
            
            -- Explicitly ensure isExample is set to false for manual imports
            if TWRA_Assignments then
                TWRA_Assignments.isExample = false
                self:Debug("data", "Explicitly set isExample = false for manual import")
            end
            
            -- Reset UI state after import
            if self.ShowMainView then
                self:Debug("ui", "Resetting UI to main view after import")
                self:ShowMainView()
            end
            
            -- Make sure navigation is rebuilt
            if self.RebuildNavigation then
                self:Debug("nav", "Rebuilding navigation after import")
                self:RebuildNavigation()
            end
            
            -- Navigate to first section
            if self.NavigateToSection then
                self:Debug("nav", "Navigating to first section after import")
                self:NavigateToSection(1)
            end
            
            -- Clear import text box if it exists
            if self.importEditBox then
                self:Debug("ui", "Clearing import edit box")
                self.importEditBox:SetText("")
            end

            -- IMPORTANT: Auto-send data to group after manual import (if in a group)
            if GetNumRaidMembers() > 0 or GetNumPartyMembers() > 0 then
                -- Check if we have the SendAllSections function
                if self.SendAllSections then
                    self:Debug("sync", "Manual import detected, sending data to group")
                    -- Small delay to ensure the data is fully processed before sending
                    self:ScheduleTimer(function()
                        self:SendAllSections()
                    end, 0.5)
                else
                    self:Debug("error", "SendAllSections function not available, can't share data")
                end
            else
                self:Debug("sync", "Not in a group, no need to send data after manual import")
            end
        else
            self:Debug("error", "SaveAssignments function not found")
        end
    else
        -- If this is a sync operation with timestamp, handle it directly
        TWRA_Assignments.timestamp = syncTimestamp
        TWRA_Assignments.version = 2
        self:Debug("data", "Saved data to Assignments with timestamp: " .. syncTimestamp)
        
        -- Rebuild navigation after sync import
        if self.RebuildNavigation then
            self:Debug("nav", "Rebuilding navigation after sync import")
            self:RebuildNavigation()
        end
        
        -- Update dynamic player information after sync imports
        if self.RefreshPlayerInfo then
            self:RefreshPlayerInfo()
            self:Debug("data", "Processed dynamic player information after sync import")
        end
        
        -- Navigate to first section after sync import
        if self.NavigateToSection then
            self:Debug("nav", "Navigating to first section after sync import")
            self:NavigateToSection(1)
        end
    end
end

-- Modified Base64 decoding function with improved UTF-8 handling and compression support
function TWRA:DecodeBase64(base64Str, syncTimestamp, noAnnounce)
    if not base64Str then 
        self:Debug("error", "Decode failed - nil string", true)
        return nil 
    end
    
    -- CRITICAL FIX: Clear TWRA_CompressedAssignments completely at the beginning of the import
    -- This ensures no stale compressed data persists across imports
    TWRA_CompressedAssignments = {
        sections = {},
        structure = nil,
        timestamp = nil,
        useSectionCompression = true
    }
    self:Debug("data", "Completely reset TWRA_CompressedAssignments at start of decoding")
    
    -- Check if this is compressed data
    if string.byte(base64Str, 1) == 241 then
        self:Debug("data", "Detected compressed data format, processing with decompression")
        local decompressedData = self:DecompressAssignmentsData(base64Str)
        
        if not decompressedData then
            self:Debug("error", "Failed to decompress data", true)
            return nil
        end
        
        -- Initialize Assignments if they don't exist
        if not TWRA_Assignments then
            TWRA_Assignments = {}
        end
        
        -- Store the decompressed data
        TWRA_Assignments.data = decompressedData.data
        
        -- Store the compressed version for future sync operations
        self:StoreCompressedData(base64Str)
        
        -- Process player information
        if self.ProcessPlayerInfo then
            self:ProcessPlayerInfo()
            self:Debug("data", "Player information processed")
        end
        
        -- Handle UI updates and data saving
        self:HandleImportedData(decompressedData, syncTimestamp, noAnnounce)
        
        return decompressedData
    end
    
    -- Track operation start time for performance debugging
    local startTime = debugprofilestop and debugprofilestop() or 0
    
    -- Clean up the string
    base64Str = string.gsub(base64Str, " ", "")
    base64Str = string.gsub(base64Str, "\n", "")
    base64Str = string.gsub(base64Str, "\r", "")
    base64Str = string.gsub(base64Str, "\t", "")
    
    self:Debug("data", "Decoding base64 string of length " .. string.len(base64Str))
    
    -- Safety check for minimum length
    if string.len(base64Str) < 4 then
        self:Debug("error", "Decode failed - string too short: " .. string.len(base64Str), true)
        return nil
    end
    
    -- Ensure string is a multiple of 4 characters by adding padding if necessary
    local remainder = string.len(base64Str) - (math.floor(string.len(base64Str) / 4) * 4)
    local padding = 0
    if remainder > 0 then
        padding = 4 - remainder
    end
    if padding > 0 then
        for i = 1, padding do
            base64Str = base64Str .. "="
        end
        self:Debug("data", "Added " .. padding .. " padding characters for proper decoding")
    end
    
    -- Convert Base64 to binary string with improved UTF-8 handling
    local luaCode = ""
    local bits = 0
    local bitCount = 0
    
    -- Use protected call for decoding loop to avoid crashing on bad input
    local success, result = pcall(function()
        for i = 1, string.len(base64Str) do
            local b64char = string.sub(base64Str, i, i)
            local b64value = b64Table[b64char]
            
            -- Skip padding characters (=)
            if b64char == "=" then
                -- Just skip, padding at the end is normal
            elseif not b64value then
                -- Invalid character - graceful handling
                self:Debug("error", "Invalid Base64 character: '" .. b64char .. "' at position " .. i, true)
                -- Continue processing rather than breaking, to be more forgiving
            elseif b64value >= 0 then
                -- Left shift bits by 6 and add new value
                bits = (bits * 64) + b64value
                bitCount = bitCount + 6
                
                -- If we have at least 8 bits, extract a byte
                while bitCount >= 8 do
                    bitCount = bitCount - 8
                    
                    -- Extract next byte (shift right)
                    local byte = math.floor(bits / (2^bitCount))
                    
                    -- Keep only the lowest 8 bits (replace modulo with math.floor approach)
                    byte = byte - (math.floor(byte / 256) * 256)
                    
                    luaCode = luaCode .. string.char(byte)
                    
                    -- Remove the consumed bits (replace modulo with math.floor approach)
                    bits = bits - (math.floor(bits / (2^bitCount)) * (2^bitCount))
                end
            end
        end
        return true
    end)
    
    if not success then
        self:Debug("error", "Error during Base64 decoding: " .. tostring(result), true)
        return nil
    end
    
    -- Report decoding time for performance monitoring
    if debugprofilestop then
        local decodeTime = debugprofilestop() - startTime
        self:Debug("performance", "Base64 decoding completed in " .. decodeTime .. "ms")
    end
    
    -- Handle empty result (should never happen with valid base64)
    if string.len(luaCode) == 0 then
        self:Debug("error", "Decoded to empty string", true)
        return nil
    end
    
    self:Debug("data", "Decoded string length: " .. string.len(luaCode))
    local previewText = string.sub(luaCode, 1, 40)
    if string.len(luaCode) > 40 then
        previewText = previewText .. "..."
    end
    self:Debug("data", "String begins with: " .. previewText)
    
    -- Process the luaCode to extract data - wrapped in pcall for safety
    local finalResult = nil
    local parseSuccess, parseResult = pcall(function()
        -- Check if we have the new format (starting with TWRA_ImportString = {)
        if string.find(luaCode, "^TWRA_ImportString%s*=%s*{") then
            self:Debug("data", "Detected import string format")
            
            -- Create a temporary environment
            local env = {}
            
            -- Execute the code in this environment
            local script = "local TWRA_ImportString; " .. luaCode .. "; return TWRA_ImportString"
            local func, err = loadstring(script)
            if not func then
                self:Debug("error", "Error parsing format: " .. (err or "unknown error"), true)
                return nil
            end
            
            -- Set environment and execute
            setfenv(func, env)
            local success, result = pcall(func)
            
            if not success then
                self:Debug("error", "Error executing format: " .. (result or "unknown error"), true)
                return nil
            end
            
            -- Get the result from environment
            if result and type(result) == "table" then
                self:Debug("data", "Successfully parsed structure")
                
                -- Verify that the structure is what we expect
                if not result.data then
                    self:Debug("error", "Format missing 'data' field", true)
                    return nil
                end
                
                -- First, expand abbreviations
                self:Debug("data", "Expanding abbreviations in the imported data")
                result = self:ExpandAbbreviations(result)
                                
                -- Ensure all rows have entries for all columns
                result = self:EnsureCompleteRows(result)
                
                -- Process the data to handle shortened keys and fix special characters
                if self.ProcessImportedData then
                    result = self:ProcessImportedData(result)
                end
                
                -- Fix special characters throughout the data
                if self.FixSpecialCharacters then
                    result = self:FixSpecialCharacters(result)
                end
                
                -- IMPORTANT: Generate and store compressed version for future sync
                self:Debug("data", "Generating compressed version for future sync")
                local syncReadyData = self:PrepareDataForSync(result)
                local compressedData = self:CompressAssignmentsData(syncReadyData)
                if compressedData then
                    self:StoreCompressedData(compressedData)
                else
                    self:Debug("error", "Failed to create compressed version of imported data")
                end
                
                -- Process player-relevant information
                if self.ProcessPlayerInfo then
                    self:Debug("data", "Processing player-relevant information for imported data")
                    
                    -- Initialize Assignments if they don't exist
                    if not TWRA_Assignments then
                        TWRA_Assignments = {}
                    end
                    
                    -- IMPORTANT: Clear existing data only once, right before we need it for processing
                    -- This prevents multiple redundant clearing operations
                    TWRA_Assignments.data = result.data
                    
                    -- Process player information
                    self:ProcessPlayerInfo()
                    self:Debug("data", "Player information processed")
                    
                    -- Get the processed data back from Assignments
                    result.data = TWRA_Assignments.data
                    
                    -- Clear the data if this was just a validation and not a real import
                    if not syncTimestamp then
                        TWRA_Assignments.data = nil
                    end
                end
                
                -- Remove the special rows now that all processing is complete
                self:Debug("data", "Removing special rows after all processing")
                for sectionIdx, section in pairs(result.data) do
                    if type(section) == "table" and section["Section Rows"] and section["_specialRowIndices"] then
                        local sectionName = section["Section Name"] or tostring(sectionIdx)
                        local rowsToRemove = section["_specialRowIndices"]
                        
                        -- Sort indices in descending order to maintain correct indices when removing
                        table.sort(rowsToRemove, function(a, b) return a > b end)
                        
                        -- Remove the special rows
                        for _, rowIdx in ipairs(rowsToRemove) do
                            table.remove(section["Section Rows"], rowIdx)
                            self:Debug("data", "Removed special row at index " .. rowIdx .. " from section " .. sectionName)
                        end
                        
                        -- Clean up the temporary indices list
                        section["_specialRowIndices"] = nil
                    end
                end
                
                -- IMPORTANT: Clear current data ONE TIME before final save
                if not syncTimestamp then
                    -- This is a manual import, use SaveAssignments to handle proper UI updates
                    self:Debug("data", "Clearing current data before final save")
                    if self.ClearData then
                        self:ClearData()
                    end
                    
                    -- Set up timestamp for this import
                    local timestamp = time()
                    
                    -- Use SaveAssignments function which will handle UI resets and navigation building
                    if self.SaveAssignments then
                        -- IMPORTANT: Don't store the original source string to save memory
                        self:SaveAssignments(result, "import", timestamp, noAnnounce)
                        
                        -- Explicitly ensure isExample is set to false for manual imports
                        if TWRA_Assignments then
                            TWRA_Assignments.isExample = false
                            self:Debug("data", "Explicitly set isExample = false for manual import")
                        end
                        
                        -- IMPORTANT: Reset UI state after import
                        if self.ShowMainView then
                            self:Debug("ui", "Resetting UI to main view after import")
                            self:ShowMainView()
                        end
                        
                        -- IMPORTANT: Make sure navigation is rebuilt
                        if self.RebuildNavigation then
                            self:Debug("nav", "Rebuilding navigation after import")
                            self:RebuildNavigation()
                        end
                        
                        -- IMPORTANT: Navigate to first section
                        if self.NavigateToSection then
                            self:Debug("nav", "Navigating to first section after import")
                            self:NavigateToSection(1)
                        end
                        
                        -- IMPORTANT: Clear import text box if it exists
                        if self.importEditBox then
                            self:Debug("ui", "Clearing import edit box")
                            self.importEditBox:SetText("")
                        end

                        -- IMPORTANT: Auto-send data to group after manual import (if in a group)
                        if GetNumRaidMembers() > 0 or GetNumPartyMembers() > 0 then
                            -- Check if we have the SendAllSections function
                            if self.SendAllSections then
                                self:Debug("sync", "Manual import detected, sending data to group")
                                -- Small delay to ensure the data is fully processed before sending
                                self:ScheduleTimer(function()
                                    self:SendAllSections()
                                end, 0.5)
                            else
                                self:Debug("error", "SendAllSections function not available, can't share data")
                            end
                        else
                            self:Debug("sync", "Not in a group, no need to send data after manual import")
                        end
                    else
                        self:Debug("error", "SaveAssignments function not found")
                    end
                else
                    -- If this is a sync operation with timestamp, handle it directly
                    self:Debug("data", "Setting up data for sync import")
                    TWRA_Assignments = {
                        data = result.data,
                        timestamp = syncTimestamp,
                        version = 2,
                        -- Store compressed version for future sync
                        compressed = compressedData
                    }
                    self:Debug("data", "Saved data to Assignments with timestamp: " .. syncTimestamp)
                    
                    -- Rebuild navigation after sync import
                    if self.RebuildNavigation then
                        self:Debug("nav", "Rebuilding navigation after sync import")
                        self:RebuildNavigation()
                    end
                    
                    -- Update dynamic player information after sync imports
                    if self.RefreshPlayerInfo then
                        self:RefreshPlayerInfo()
                        self:Debug("data", "Processed dynamic player information after sync import")
                    end
                    
                    -- Navigate to first section after sync import
                    if self.NavigateToSection then
                        self:Debug("nav", "Navigating to first section after sync import")
                        self:NavigateToSection(1)
                    end
                end
                
                return result
            else
                self:Debug("error", "Format parsed but TWRA_ImportString not found", true)
                return nil
            end
        else
            self:Debug("error", "Unrecognized import format", true)
            return nil
        end
    end)
    
    -- Handle any errors that occurred during processing
    if not parseSuccess then
        self:Debug("error", "Critical error during import parsing: " .. tostring(parseResult), true)
        return nil
    end
    
    -- Track total operation time if possible
    if debugprofilestop then
        local totalTime = debugprofilestop() - startTime
        self:Debug("performance", "Total import processing completed in " .. totalTime .. "ms")
    end
    
    return parseResult
end

-- Convert a table to a Lua code string
function TWRA:TableToLuaString(tbl)
    if type(tbl) ~= "table" then
        return "nil"
    end
    
    local result = "return {"
    
    -- Handle array part
    for i = 1, table.getn(tbl) do
        if i > 1 then result = result .. "," end
        
        if type(tbl[i]) == "table" then
            result = result .. self:TableToLuaString(tbl[i])
        elseif type(tbl[i]) == "string" then
            result = result .. string.format("%q", tbl[i])
        elseif type(tbl[i]) == "number" then
            result = result .. tostring(tbl[i])
        elseif type(tbl[i]) == "boolean" then
            result = result .. (tbl[i] and "true" or "false")
        else
            result = result .. "nil"
        end
    end
    
    -- Handle non-array part (just in case, though we don't expect it in our data format)
    for k, v in pairs(tbl) do
        if type(k) ~= "number" or k > table.getn(tbl) or k < 1 then
            result = result .. "," .. (type(k) == "string" and "[" .. string.format("%q", k) .. "]" or "[" .. tostring(k) .. "]") .. "="
            
            if type(v) == "table" then
                result = result .. self:TableToLuaString(v)
            elseif type(v) == "string" then
                result = result .. string.format("%q", v)
            elseif type(v) == "number" then
                result = result .. tostring(v)
            elseif type(v) == "boolean" then
                result = result .. (v and "true" or "false")
            else
                result = result .. "nil"
            end
        end
    end
    
    result = result .. "}"
    return result
end

-- Encode a string to Base64
function TWRA:EncodeBase64(str)
    if not str then return nil end
    
    local bytes = {}
    local result = ""
    
    for i = 1, string.len(str) do
        local byte = string.byte(str, i)
        table.insert(bytes, byte)
    end
    
    -- Process all bytes, 3 at a time
    for i = 1, table.getn(bytes), 3 do
        local b1, b2, b3 = bytes[i], bytes[i+1], bytes[i+2]
        
        -- Extract 4 6-bit chunks from the 3 bytes
        local c1 = math.floor(b1 / 4)
        local c2 = (b1 - c1 * 4) * 16
        
        if b2 then
            c2 = c2 + math.floor(b2 / 16)
            local c3 = (b2 - math.floor(b2 / 16) * 16) * 4
            
            if b3 then
                c3 = c3 + math.floor(b3 / 64)
                local c4 = b3 - math.floor(b3 / 64) * 64
                
                result = result .. b64EncodeArray[c1] .. b64EncodeArray[c2] .. 
                                 b64EncodeArray[c3] .. b64EncodeArray[c4]
            else
                result = result .. b64EncodeArray[c1] .. b64EncodeArray[c2] .. 
                                 b64EncodeArray[c3] .. "="
            end
        else
            result = result .. b64EncodeArray[c1] .. b64EncodeArray[c2] .. "=="
        end
    end
    
    return result
end
