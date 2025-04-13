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

-- Replace the b64Encode function that has modulo operator issues
local function b64Encode(ch)
    if not ch then return "A" end
    local b = ch
    -- Replace modulo with math.floor approach
    if b < 64 then
        -- No change needed
    else
        -- Replace "b = b % 64" with math.floor approach
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

-- Fix the modulo usage in EncodeBase64 function
function TWRA:EncodeBase64(data)
    if not data then return nil end
    
    local bytes = {string.byte(data, 1, string.len(data))}
    local result = {}
    
    local i = 1
    while i <= table.getn(bytes) do
        local b1, b2, b3
        b1 = bytes[i]
        i = i + 1
        b2 = i <= table.getn(bytes) and bytes[i] or 0
        i = i + 1
        b3 = i <= table.getn(bytes) and bytes[i] or 0
        i = i + 1
        
        -- Convert 3 bytes to 4 base64 characters
        table.insert(result, b64EncodeArray[math.floor(b1 / 4)])
        
        -- Replace modulo with math.floor approach
        local b1mod4 = b1 - (math.floor(b1 / 4) * 4)
        table.insert(result, b64EncodeArray[(b1mod4 * 16) + math.floor(b2 / 16)])
        
        if i - 2 > table.getn(bytes) then
            table.insert(result, "=")
        else
            -- Replace modulo with math.floor approach
            local b2mod16 = b2 - (math.floor(b2 / 16) * 16)
            local b3div64 = math.floor(b3 / 64)
            table.insert(result, b64EncodeArray[(b2mod16 * 4) + b3div64])
        end
        
        if i - 1 > table.getn(bytes) then
            table.insert(result, "=")
        else
            -- Replace modulo with math.floor approach
            local b3mod64 = b3 - (math.floor(b3 / 64) * 64)
            table.insert(result, b64EncodeArray[b3mod64])
        end
    end
    
    return table.concat(result)
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
                                    self:Debug("data", "Expanded row abbreviation: " .. value .. " -> " .. self.ABBREVIATION_MAPPINGS[value])
                                end
                                -- For icon column (usually index 1), also try special handling
                                if colIndex == 1 and type(value) == "string" then
                                    -- Handle numeric icons (1-9) which should become Star, Circle, etc.
                                    local num = tonumber(value)
                                    if num and num >= 1 and num <= 9 and self.ABBREVIATION_MAPPINGS[value] then
                                        row[colIndex] = self.ABBREVIATION_MAPPINGS[value]
                                        self:Debug("data", "Expanded numeric icon: " .. value .. " -> " .. self.ABBREVIATION_MAPPINGS[value])
                                    -- Handle symbol icons (!, ?)
                                    elseif (value == "!" or value == "?") and self.ABBREVIATION_MAPPINGS[value] then
                                        row[colIndex] = self.ABBREVIATION_MAPPINGS[value]
                                        self:Debug("data", "Expanded symbol icon: " .. value .. " -> " .. self.ABBREVIATION_MAPPINGS[value])
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
                            self:Debug("data", "Expanded short header abbreviation: " .. headerValue .. " -> " .. self.ABBREVIATION_MAPPINGS[headerValue])
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
                                    self:Debug("data", "Expanded short row abbreviation: " .. value .. " -> " .. self.ABBREVIATION_MAPPINGS[value])
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

-- New function to ensure all rows have entries for all columns
function TWRA:EnsureCompleteRows(data)
    if not data then 
        self:Debug("error", "EnsureCompleteRows: Invalid data structure", true)
        return data 
    end
    
    self:Debug("data", "Ensuring all rows have entries for all columns")
    
    -- Handle the new format structure
    if data.data and type(data.data) == "table" then
        -- Process each section
        for sectionIndex, section in pairs(data.data) do
            -- Only process table sections (new format)
            if type(section) == "table" and section["Section Name"] and section["Section Rows"] and section["Section Header"] then
                local maxColumns = table.getn(section["Section Header"])
                
                self:Debug("data", "Processing section '" .. section["Section Name"] .. "', ensuring " .. maxColumns .. " columns per row", false, true)
                
                -- Process each row, including special rows
                for rowIndex, row in pairs(section["Section Rows"]) do
                    -- Create a new row with sequential indices regardless of row type
                    local newRow = {}
                    
                    -- Determine the max columns to ensure for this row
                    local rowMaxColumns = maxColumns
                    -- Special rows like "Note", "Warning", "GUID" potentially have different column needs
                    if type(row[1]) == "string" and (row[1] == "Note" or row[1] == "Warning" or row[1] == "GUID") then
                        local specialRowLength = 0
                        for _ in pairs(row) do
                            specialRowLength = specialRowLength + 1
                        end
                        if specialRowLength > rowMaxColumns then
                            rowMaxColumns = specialRowLength
                        end
                    end
                    
                    -- Fill in all column indices from 1 to rowMaxColumns
                    for colIndex = 1, rowMaxColumns do
                        -- Handle both nil values and missing indices
                        if row[colIndex] ~= nil then
                            newRow[colIndex] = row[colIndex]
                        else
                            newRow[colIndex] = ""
                        end
                    end
                    
                    -- Replace the original sparse row with the complete row
                    section["Section Rows"][rowIndex] = newRow
                end
                
                self:Debug("data", "Completed filling indices for section '" .. section["Section Name"] .. "'")
            end
        end
    end
    
    return data
end

-- Improved Base64 decoding function with better UTF-8 handling
function TWRA:DecodeBase64(base64Str, syncTimestamp, noAnnounce)
    if not base64Str then 
        self:Debug("error", "Decode failed - nil string", true)
        return nil 
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
    -- Replace modulo with math.floor approach
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
                
                -- Make sure to call abbreviation expansion before any other processing
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
                
                -- Process player-relevant information in the imported data
                if self.ProcessPlayerInfo then
                    self:Debug("data", "Processing player-relevant information for imported data")
                    -- For sync operations, process player info immediately after data is saved
                    if syncTimestamp then
                        self:ProcessPlayerInfo()
                        self:Debug("data", "Processed player-relevant information after sync import")
                    end
                    -- For regular imports, we'll refresh player info which will also update UI
                    -- This happens outside the protected call to ensure it runs even if there are issues
                end
                
                -- If this is a sync operation with timestamp, handle it directly
                if syncTimestamp then
                    -- We need to assign directly to SavedVariables
                    TWRA_SavedVariables = TWRA_SavedVariables or {}
                    TWRA_SavedVariables.assignments = {
                        data = result.data,
                        timestamp = syncTimestamp,
                        version = 2
                    }
                    self:Debug("data", "Directly saved data to SavedVariables with timestamp: " .. syncTimestamp)
                    
                    -- Process player info after data is saved
                    if self.ProcessPlayerInfo then
                        self:ProcessPlayerInfo()
                        self:Debug("data", "Processed player-relevant information after sync import")
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

-- Convert table to Base64
function TWRA:TableToBase64(tbl)
    if not tbl then return nil end
    
    local luaStr = self:TableToLuaString(tbl)
    return self:EncodeBase64(luaStr)
end
