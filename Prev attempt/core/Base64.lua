-- TWRA Base64 Module - Fixed implementation
TWRA = TWRA or {}

-- Make sure _G is initialized first before trying to use it
local globalEnv = getfenv(0)

-- Base64 decoding lookup table
local b64Table = {
    ['A']=0,['B']=1,['C']=2,['D']=3,['E']=4,['F']=5,['G']=6,['H']=7,['I']=8,['J']=9,
    ['K']=10,['L']=11,['M']=12,['N']=13,['O']=14,['P']=15,['Q']=16,['R']=17,['S']=18,
    ['T']=19,['U']=20,['V']=21,['W']=22,['X']=23,['Y']=24,['Z']=25,['a']=26,['b']=27,
    ['c']=28,['d']=29,['e']=30,['f']=31,['g']=32,['h']=33,['i']=34,['j']=35,['k']=36,
    ['l']=37,['m']=38,['n']=39,['o']=40,['p']=41,['q']=42,['r']=43,['s']=44,['t']=45,
    ['u']=46,['v']=47,['w']=48,['x']=49,['y']=50,['z']=51,['0']=52,['1']=53,['2']=54,
    ['3']=55,['4']=56,['5']=57,['6']=58,['7']=59,['8']=60,['9']=61,['+'] = 62,['/'] = 63,
    ['='] = -1
}

-- Forward declare functions that will be used globally
local TestBasicLuaEnvironment
local TestBaseDecoding
local SimpleBase64Test

-- Very simple test function to verify the basic environment
function TestBasicLuaEnvironment()
    DEFAULT_CHAT_FRAME:AddMessage("Testing basic Lua environment...")
    
    -- Test loadstring
    local f, err = loadstring("return {1,2,3}")
    if not f then
        DEFAULT_CHAT_FRAME:AddMessage("ERROR: loadstring failed: " .. tostring(err))
        return false
    end
    
    -- Test pcall
    local success, result = pcall(f)
    if not success then
        DEFAULT_CHAT_FRAME:AddMessage("ERROR: pcall failed: " .. tostring(result))
        return false
    end
    
    -- Test table functions
    if type(result) ~= "table" then
        DEFAULT_CHAT_FRAME:AddMessage("ERROR: Result is not a table")
        return false
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("Basic Lua environment test passed!")
    return true
end

-- Enhance debugging for Base64 decoding
function TWRA:DecodeBase64(base64Str, syncTimestamp, noAnnounce)
    -- Input validation
    if not base64Str or base64Str == "" then
        self:Error("Empty base64 string")
        return nil
    end
    
    self:Debug("data", "Decoding Base64 data of length: " .. string.len(base64Str))
    
    -- Clean whitespace and invalid characters
    base64Str = string.gsub(base64Str, "[^ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=]", "")
    
    local function safeDecoding()
        -- Create a clean output buffer
        local luaCode = ""
        local bits = 0
        local bitCount = 0
        
        -- Process one character at a time
        for i = 1, string.len(base64Str) do
            local b64char = string.sub(base64Str, i, i)
            local b64value = b64Table[b64char]
            
            -- Only process valid characters (not padding)
            if b64value and b64value >= 0 then
                -- Left shift bits by 6 and add new value
                bits = bits * 64 + b64value
                bitCount = bitCount + 6
                
                -- Extract 8-bit bytes when we have enough bits
                while bitCount >= 8 do
                    bitCount = bitCount - 8
                    
                    -- Extract next byte using integer math
                    local byte = math.floor(bits / (2^bitCount))
                    
                    -- Keep only the lowest 8 bits (equivalent to % 256)
                    byte = byte - (math.floor(byte / 256) * 256)
                    
                    -- Add byte to output
                    luaCode = luaCode .. string.char(byte)
                    
                    -- Remove processed bits
                    bits = bits - (math.floor(bits / (2^bitCount)) * (2^bitCount))
                end
            end
        end
        
        -- Debug output
        local printable = ""
        for i = 1, math.min(50, string.len(luaCode)) do
            local c = string.sub(luaCode, i, i)
            local b = string.byte(c)
            if b >= 32 and b <= 126 then
                printable = printable .. c
            else
                printable = printable .. "."
            end
        end
        self:Debug("data", "Decoded first 50 chars: " .. printable)
        
        -- Make sure it starts with "return"
        if string.sub(luaCode, 1, 6) ~= "return" then
            if string.sub(luaCode, 1, 1) == "{" then
                luaCode = "return " .. luaCode
                self:Debug("data", "Added 'return' prefix")
            else
                luaCode = "return " .. luaCode
                self:Debug("data", "Forced 'return' prefix")
            end
        end
        
        -- Fix common Lua syntax issues
        -- 1. Fix trailing commas in tables which can cause errors in Lua 5.0
        luaCode = string.gsub(luaCode, ",(%s*})", "%1")
        
        -- 2. Clean problematic characters
        luaCode = string.gsub(luaCode, "[\128-\255]", "?")
        
        -- Show what we're trying to execute
        self:Debug("data", "About to execute: " .. string.sub(luaCode, 1, math.min(50, string.len(luaCode))) .. "...")
        
        -- Load the string as Lua code
        self:Debug("data", "Attempting loadstring...")
        local func, loadError = loadstring(luaCode)
        
        if not func then
            self:Error("loadstring failed: " .. tostring(loadError))
            return nil
        end
        
        -- Execute function
        self:Debug("data", "Executing function...")
        local status, result = pcall(func)
        
        if not status then
            self:Error("Function execution failed: " .. tostring(result))
            return nil
        end
        
        if not result or type(result) ~= "table" then
            self:Error("Result not a table: " .. tostring(type(result)))
            return nil
        end
        
        return result
    end
    
    local success, result = pcall(safeDecoding)
    
    if not success then
        self:Error("Base64 decode exception: " .. tostring(result))
        return nil
    end
    
    return result
end

-- Fix the character-by-character debug output that has a syntax error
function TWRA:DebugDecodeBase64(base64Str)
    -- Input validation
    if not base64Str or base64Str == "" then
        self:Error("Empty base64 string")
        return nil
    end
    
    self:Debug("data", "Debugging Base64 decoding of " .. string.len(base64Str) .. " characters")
    
    -- Clean whitespace and invalid characters
    base64Str = string.gsub(base64Str, "[^ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=]", "")
    
    -- Create a clean output buffer
    local luaCode = ""
    local bits = 0
    local bitCount = 0
    
    -- Process one character at a time
    for i = 1, string.len(base64Str) do
        local b64char = string.sub(base64Str, i, i)
        local b64value = b64Table[b64char]
        
        -- Only process valid characters (not padding)
        if b64value and b64value >= 0 then
            -- Left shift bits by 6 and add new value
            bits = bits * 64 + b64value
            bitCount = bitCount + 6
            
            -- Extract 8-bit bytes when we have enough bits
            while bitCount >= 8 do
                bitCount = bitCount - 8
                
                -- Extract next byte using integer math
                local byte = math.floor(bits / (2^bitCount))
                
                -- Keep only the lowest 8 bits (equivalent to % 256)
                byte = byte - (math.floor(byte / 256) * 256)
                
                -- Add byte to output
                luaCode = luaCode .. string.char(byte)
                
                -- Remove processed bits
                bits = bits - (math.floor(bits / (2^bitCount)) * (2^bitCount))
            end
        end
    end
    
    -- Output the raw decoded string
    DEFAULT_CHAT_FRAME:AddMessage("Raw decoded string: " .. luaCode)
    DEFAULT_CHAT_FRAME:AddMessage("Length: " .. string.len(luaCode))
    
    -- Output character by character with codes (fixed)
    DEFAULT_CHAT_FRAME:AddMessage("Character by character:")
    local charOutput = ""
    for i = 1, string.len(luaCode) do
        local c = string.sub(luaCode, i, i)
        local b = string.byte(c)
        charOutput = charOutput .. "[" .. b .. ":" .. c .. "] "
        if math.floor(i / 10) * 10 == i then
            DEFAULT_CHAT_FRAME:AddMessage(charOutput)
            charOutput = ""
        end
    end
    if charOutput ~= "" then
        DEFAULT_CHAT_FRAME:AddMessage(charOutput)
    end
    
    return luaCode
end

-- Simple test function
function TWRA:TestBase64()
    -- Small test string (contains a minimal table)
    local testStr = "cmV0dXJuIHt7IlRlc3QifX0="
    
    -- Enable debugging
    self:ToggleDebugCategory("data", true)
    
    local result = self:DecodeBase64(testStr)
    
    if result then
        DEFAULT_CHAT_FRAME:AddMessage("Base64 test succeeded!")
        return result
    else
        DEFAULT_CHAT_FRAME:AddMessage("Base64 test failed!")
        return nil
    end
end

-- Simplified import box test function
function TWRA:TestImportBox()
    -- Try to find the import box
    local importBox = nil
    
    -- Check if options UI is active
    if self.optionsElements then
        for _, element in pairs(self.optionsElements) do
            -- Look for an EditBox element
            if element and element.GetObjectType and element:GetObjectType() == "EditBox" then
                importBox = element
                break
            end
        end
    end
    
    -- Fallback to try finding by name - using _G directly
    if not importBox then
        -- Check some common names first
        local commonNames = {"ImportBox", "TWRAImportBox", "ImportText"}
        for _, name in pairs(commonNames) do
            if globalEnv[name] and globalEnv[name].GetText then
                importBox = globalEnv[name]
                break
            end
        end
        
        -- If still not found, search all global frames
        if not importBox then
            for name, frame in pairs(globalEnv) do
                if type(frame) == "table" and frame.GetObjectType and 
                   frame:GetObjectType() == "EditBox" and string.find(string.lower(name), "import") then
                    importBox = frame
                    self:Debug("ui", "Found import box: " .. name)
                    break
                end
            end
        end
    end
    
    if not importBox then
        self:Error("Import box not found. Make sure the options panel is open.")
        return nil
    end
    
    local text = importBox:GetText()
    if not text or text == "" then
        self:Error("Import box is empty")
        return nil
    end
    
    self:Debug("ui", "Testing import with " .. string.len(text) .. " characters")
    
    -- Enable data debugging for this test
    self:ToggleDebugCategory("data", true)
    
    local result = self:DecodeBase64(text)
    
    -- Restore original debug settings
    self:ToggleDebugCategory("data", false)
    
    if result then
        self:Debug("ui", "Import test succeeded!")
    else
        self:Error("Import test failed!")
    end
    
    return result
end

-- Standalone test function that doesn't depend on TWRA methods
function SimpleBase64Test()
    local testStr = "cmV0dXJuIHt7IlRlc3QifX0=" -- Encodes to "return {{"Test"}}"
    DEFAULT_CHAT_FRAME:AddMessage("Testing Base64 decoding with a simple test string")
    
    -- Clean the string
    testStr = string.gsub(testStr, "%s", "")
    
    local luaCode = ""
    local i = 1
    
    -- Process in chunks of 4 characters
    while i <= string.len(testStr) do
        local c1 = string.sub(testStr, i, i)
        if c1 == "" then break end
        
        local c2 = string.sub(testStr, i+1, i+1)
        if c2 == "" then 
            DEFAULT_CHAT_FRAME:AddMessage("Error: Unexpected end of string")
            return nil
        end
        
        local c3 = string.sub(testStr, i+2, i+2)
        local c4 = string.sub(testStr, i+3, i+3)
        
        local n1 = b64Table[c1]
        local n2 = b64Table[c2]
        local n3 = c3 ~= "=" and b64Table[c3] or 0
        local n4 = c4 ~= "=" and b64Table[c4] or 0
        
        local byte1 = (n1 * 4) + math.floor(n2 / 16)
        local n2_remainder = n2 - math.floor(n2 / 16) * 16
        local byte2 = (n2_remainder * 16) + math.floor(n3 / 4)
        local n3_remainder = n3 - math.floor(n3 / 4) * 4
        local byte3 = (n3_remainder * 64) + n4
        
        luaCode = luaCode .. string.char(byte1)
        if c3 ~= "=" then luaCode = luaCode .. string.char(byte2) end
        if c4 ~= "=" then luaCode = luaCode .. string.char(byte3) end
        
        i = i + 4
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("Decoded to: " .. luaCode)
    
    if string.sub(luaCode, 1, 1) == "{" then
        luaCode = "return " .. luaCode
    end
    
    local func, err = loadstring(luaCode)
    if not func then
        DEFAULT_CHAT_FRAME:AddMessage("Error: " .. tostring(err))
        return nil
    end
    
    local status, result = pcall(func)
    if not status then
        DEFAULT_CHAT_FRAME:AddMessage("Error: " .. tostring(result))
        return nil
    end
    
    if type(result) ~= "table" then
        DEFAULT_CHAT_FRAME:AddMessage("Error: Result is not a table")
        return nil
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("Success! Decoded table with " .. table.getn(result) .. " entries")
    return result
end

-- Add a test function specifically for your import string
function TWRA:TestImportString()
    DEFAULT_CHAT_FRAME:AddMessage("Starting Base64 import string test...")
    
    -- Try first with absolute minimal string
    local result = self:TestBaseDecoding()
    if result ~= "test" then
        DEFAULT_CHAT_FRAME:AddMessage("ERROR: Even minimal test failed!")
        return nil
    else
        DEFAULT_CHAT_FRAME:AddMessage("Minimal test succeeded, continuing...")
    end
    
    -- Next try with a tiny valid Lua table string
    local tinyTest = "cmV0dXJuIHsxLDIsfQ==" -- encodes to "return {1,2,}"
    self:ToggleDebugCategory("data", true)
    
    self:Debug("data", "Attempting to decode tiny table string...")
    -- First just debug the raw decoded string
    local decodedStr = self:DebugDecodeBase64(tinyTest)
    DEFAULT_CHAT_FRAME:AddMessage("Decoded string: '" .. decodedStr .. "'")
    
    -- Fix trailing commas in the test string
    local fixedStr = string.gsub(decodedStr, ",(%s*})", "%1")
    DEFAULT_CHAT_FRAME:AddMessage("Fixed string: '" .. fixedStr .. "'")
    
    -- Test if the string loads directly
    local f, err = loadstring(fixedStr)
    if not f then
        DEFAULT_CHAT_FRAME:AddMessage("Loadstring error: " .. tostring(err))
    else
        DEFAULT_CHAT_FRAME:AddMessage("Loadstring successful!")
    end
    
    -- Then try to process it
    local tinyResult = self:DecodeBase64(tinyTest)
    
    if tinyResult then
        DEFAULT_CHAT_FRAME:AddMessage("Tiny table decoding succeeded!")
        
        -- Now try with the actual test string
        local testStr = "cmV0dXJuIHt7IkFudWIiLCJJY29uIn19" -- Highly shortened version
        self:Debug("data", "Attempting simplified test string...")
        
        local finalResult = self:DecodeBase64(testStr)
        if finalResult then
            DEFAULT_CHAT_FRAME:AddMessage("Test string decoding succeeded!")
            return finalResult
        else
            DEFAULT_CHAT_FRAME:AddMessage("Test string decoding failed!")
            return nil
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("Tiny table decoding failed!")
        return nil
    end
end

-- Fix the TestBaseDecoding function to properly decode "dGVzdA==" to "test"
function TWRA:TestBaseDecoding()
    -- Use a minimal test string that decodes to "test"
    local testStr = "dGVzdA=="
    DEFAULT_CHAT_FRAME:AddMessage("Testing minimal Base64 decoding...")
    
    -- Turn on detailed debugging
    self:ToggleDebugCategory("data", true)
    
    -- Step by step debugging
    self:Debug("data", "Test string: " .. testStr)
    
    -- Clean the string
    testStr = string.gsub(testStr, "%s", "")
    
    local luaCode = ""
    local bits = 0
    local bitCount = 0
    
    -- Process one character at a time (simpler than quartet approach)
    for i = 1, string.len(testStr) do
        local b64char = string.sub(testStr, i, i)
        local b64value = b64Table[b64char]
        
        -- Only process valid Base64 characters, skip padding
        if b64value and b64value >= 0 then
            -- Left shift bits by 6 and add new value
            bits = bits * 64 + b64value
            bitCount = bitCount + 6
            
            -- Extract 8-bit bytes when we have enough bits
            while bitCount >= 8 do
                bitCount = bitCount - 8
                
                -- Extract next byte using integer math
                local byte = math.floor(bits / (2^bitCount))
                
                -- Keep only the lowest 8 bits (equivalent to % 256)
                byte = byte - (math.floor(byte / 256) * 256)
                
                -- Add byte to output
                luaCode = luaCode .. string.char(byte)
                
                -- Remove processed bits
                bits = bits - (math.floor(bits / (2^bitCount)) * (2^bitCount))
            end
        end
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("Decoded to: '" .. luaCode .. "'")
    
    -- Restore debug settings
    self:ToggleDebugCategory("data", false)
    
    return luaCode
end

-- Initialize the global functions now that they're defined
globalEnv["TestEnvironment"] = TestBasicLuaEnvironment
globalEnv["TestBaseDecoding"] = function() return TWRA:TestBaseDecoding() end
globalEnv["TestImportString"] = function() return TWRA:TestImportString() end
globalEnv["SimpleTest"] = SimpleBase64Test
globalEnv["DebugBase64"] = function(str) return TWRA:DebugDecodeBase64(str) end

-- Add a slash command that users can run if the globals aren't working
SLASH_TWRARESET1 = "/twrareset"
SlashCmdList["TWRARESET"] = function()
    globalEnv["TestEnvironment"] = TestBasicLuaEnvironment
    globalEnv["TestBaseDecoding"] = function() return TWRA:TestBaseDecoding() end
    globalEnv["TestImportString"] = function() return TWRA:TestImportString() end
    globalEnv["SimpleTest"] = SimpleBase64Test
    globalEnv["DebugBase64"] = function(str) return TWRA:DebugDecodeBase64(str) end
    DEFAULT_CHAT_FRAME:AddMessage("TWRA: Test functions have been reset")
end

-- Debug message to indicate functionality
DEFAULT_CHAT_FRAME:AddMessage("TWRA Base64: Module loaded successfully")