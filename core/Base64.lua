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

-- Improved Base64 decoding function with better error handling through debug system
function TWRA:DecodeBase64(base64Str, syncTimestamp, noAnnounce)
    if not base64Str then 
        self:Debug("error", "Decode failed - nil string", true)
        return nil 
    end
    
    -- Clean up the string
    base64Str = string.gsub(base64Str, " ", "")
    base64Str = string.gsub(base64Str, "\n", "")
    base64Str = string.gsub(base64Str, "\r", "")
    base64Str = string.gsub(base64Str, "\t", "")
    
    self:Debug("data", "Decoding base64 string")
    
    -- Safety check for minimum length
    if string.len(base64Str) < 4 then
        self:Debug("error", "Decode failed - string too short", true)
        return nil
    end
    
    -- Convert Base64 to binary string
    local luaCode = ""
    local bits = 0
    local bitCount = 0
    
    for i = 1, string.len(base64Str) do
        local b64char = string.sub(base64Str, i, i)
        local b64value = b64Table[b64char]
        
        if b64value and b64value >= 0 then
            -- Left shift bits by 6 and add new value
            bits = (bits * 64) + b64value
            bitCount = bitCount + 6
            
            -- If we have at least 8 bits, extract a byte
            if bitCount >= 8 then
                bitCount = bitCount - 8
                
                -- Extract next byte (shift right)
                local byte = math.floor(bits / (2^bitCount))
                -- Keep only the lowest 8 bits by subtracting multiples of 256
                byte = byte - math.floor(byte / 256) * 256
                
                luaCode = luaCode .. string.char(byte)
                
                -- Clear the used bits
                bits = bits - math.floor(bits / (2^bitCount)) * (2^bitCount)
            end
        end
    end
    
    self:Debug("data", "Decoded string length: " .. string.len(luaCode))
    self:Debug("data", "String begins with: " .. string.sub(luaCode, 1, 40) .. "...")
    
    -- The decoded string may contain Unicode escape sequences like \u00e5
    -- We need to convert these to actual UTF-8 characters
    luaCode = string.gsub(luaCode, "\\u(%x%x%x%x)", function(hex)
        local charCode = tonumber(hex, 16)
        if charCode then
            -- Convert Unicode code point to UTF-8 bytes
            if charCode < 128 then
                return string.char(charCode)
            elseif charCode < 2048 then
                return string.char(
                    192 + math.floor(charCode / 64),
                    128 + (charCode - math.floor(charCode / 64) * 64)
                )
            else
                return string.char(
                    224 + math.floor(charCode / 4096),
                    128 + math.floor((charCode - math.floor(charCode / 4096) * 4096) / 64),
                    128 + (charCode - math.floor(charCode / 64) * 64)
                )
            end
        end
        return "?"  -- Fallback for invalid codes
    end)
    
    -- Verify the string starts with "return {" - basic sanity check
    if string.sub(luaCode, 1, 8) ~= "return {" then
        self:Debug("error", "Decoded text does not appear to be a valid Lua table", true)
        self:Debug("error", "Expected 'return {' but found: " .. string.sub(luaCode, 1, 10), true)
        return nil
    end
    
    -- Execute the Lua code to get the table - use pcall for safety
    local func, err = loadstring(luaCode)
    if not func then
        self:Debug("error", "Error parsing Lua code: " .. (err or "unknown error"), true)
        return nil
    end
    
    local success, result = pcall(func)
    if not success then
        self:Debug("error", "Error executing Lua code: " .. (result or "unknown error"), true)
        return nil
    end
    
    -- Ensure we have a valid table
    if type(result) ~= "table" then
        self:Debug("error", "Decoded result is not a table (type: " .. type(result) .. ")", true)
        return nil
    end
    
    -- Verify the table has at least one entry
    if table.getn(result) == 0 then
        self:Debug("error", "Decoded table is empty", true)
        return nil
    end
    
    -- If we get here, we have a valid table
    self:Debug("data", "Successfully decoded table with " .. table.getn(result) .. " entries")
    
    -- If this is a sync operation with timestamp, handle it directly
    if syncTimestamp then
        -- Skip section restoration during sync - handled separately
        self:SaveAssignments(result, base64Str, syncTimestamp, noAnnounce or true)
    end
    
    return result
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
