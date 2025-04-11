-- TWRA Import Diagnostic Tools
-- Provides functions for diagnosing import issues

TWRA = TWRA or {}

-- Function to verify an import string without actually importing it
function TWRA:VerifyImportString(importText)
    self:Debug("data", "Verifying import string...")
    
    -- Step 1: Decode the Base64 string
    local decodedString = self:DecodeBase64(importText)
    
    if not decodedString then
        self:Debug("error", "Failed to decode Base64 string", true)
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000TWRA:|r Failed to decode Base64 string")
        return false
    end
    
    -- Show string beginning
    local previewLength = math.min(100, string.len(decodedString))
    local previewText = string.sub(decodedString, 1, previewLength)
    self:Debug("data", "Decoded string beginning: " .. previewText)
    DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA:|r Decoded string length: " .. string.len(decodedString))
    
    -- Step 2: Create a temporary environment to evaluate the string
    local env = {}
    
    -- Step 3: Create a modified script that loads into our temp environment
    local script = "local TWRA_ImportString; " .. decodedString .. "; return TWRA_ImportString"
    
    -- Execute the script
    local func, err = loadstring(script)
    if not func then
        self:Debug("error", "Error in loadstring: " .. tostring(err), true)
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000TWRA:|r Syntax error: " .. tostring(err))
        return false
    end
    
    -- Create a safe environment
    setfenv(func, env)
    
    -- Execute and get result
    local success, importData = pcall(func)
    if not success or not importData then
        self:Debug("error", "Error executing import script: " .. tostring(importData or "unknown error"), true)
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000TWRA:|r Error executing script: " .. tostring(importData or "unknown error"))
        return false
    end
    
    -- Step 4: Validate the structure
    if not importData.data then
        self:Debug("error", "Missing 'data' field in import", true)
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000TWRA:|r Import missing 'data' field")
        return false
    end
    
    -- Count sections
    local sectionCount = 0
    local sectionsWithCorrectFormat = 0
    
    for idx, section in pairs(importData.data) do
        sectionCount = sectionCount + 1
        
        if type(section) == "table" then
            if section["Section Name"] and section["Section Header"] and section["Section Rows"] then
                sectionsWithCorrectFormat = sectionsWithCorrectFormat + 1
                DEFAULT_CHAT_FRAME:AddMessage("|cFF00FF00TWRA:|r Section " .. idx .. ": " .. section["Section Name"] .. " (valid)")
            else
                local missingFields = {}
                if not section["Section Name"] then table.insert(missingFields, "Section Name") end
                if not section["Section Header"] then table.insert(missingFields, "Section Header") end
                if not section["Section Rows"] then table.insert(missingFields, "Section Rows") end
                
                DEFAULT_CHAT_FRAME:AddMessage("|cFFFFFF00TWRA:|r Section " .. idx .. ": Missing " .. table.concat(missingFields, ", "))
            end
        else
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000TWRA:|r Section " .. idx .. " is not a table")
        end
    end
    
    -- Final report
    DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA:|r Verified " .. sectionsWithCorrectFormat .. "/" .. sectionCount .. " sections with correct format")
    
    return sectionsWithCorrectFormat > 0
end

-- Register diagnostic command
SLASH_TWRAIMPORT1 = "/twraimport"
SlashCmdList["TWRAIMPORT"] = function(msg)
    -- Extract arguments
    local command, arg = string.match(msg or "", "^(%S*)%s*(.-)$")
    
    if command == "verify" and arg and arg ~= "" then
        TWRA:VerifyImportString(arg)
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA Import Commands:|r")
        DEFAULT_CHAT_FRAME:AddMessage("  /twraimport verify <base64string> - Verify an import string")
    end
end

-- Log that we've added the import diagnostic commands
TWRA:Debug("general", "Import diagnostic commands loaded")
