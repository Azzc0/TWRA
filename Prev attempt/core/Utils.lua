-- TWRA Utility Functions Module
TWRA = TWRA or {}

-- String splitting utility
function TWRA:SplitString(inputStr, delimiter)
    if not inputStr or inputStr == "" then return {} end
    if not delimiter or delimiter == "" then return { inputStr } end
    
    local result = {}
    local pattern = "(.-)" .. delimiter
    local lastPos = 1
    
    for part, pos in string.gmatch(inputStr, pattern) do
        table.insert(result, part)
        lastPos = pos + string.len(delimiter)
    end
    
    -- Add the last part
    table.insert(result, string.sub(inputStr, lastPos))
    
    return result
end

-- Timer functionality for older WoW versions
function TWRA:ScheduleTimer(func, delay)
    local timer = CreateFrame("Frame")
    timer.start = GetTime()
    timer.delay = delay
    timer.func = func
    timer:SetScript("OnUpdate", function()
        local elapsed = GetTime() - timer.start
        if elapsed >= timer.delay then
            timer:SetScript("OnUpdate", nil)
            timer.func()
        end
    end)
    return timer
end

function TWRA:CancelTimer(timer)
    if timer then
        timer:SetScript("OnUpdate", nil)
    end
end

-- Player and raid utility functions
function TWRA:GetPlayerStatus(name)
    if not name or name == "" then return false, nil end
    
    if UnitName("player") == name then return true, true end
    
    -- Check raid roster
    for i = 1, GetNumRaidMembers() do
        local raidName, _, _, _, _, _, _, online = GetRaidRosterInfo(i)
        if raidName == name then
            -- In vanilla, online is 0 when offline
            return true, (online ~= 0)
        end
    end
    
    -- Check party if not in raid
    if GetNumRaidMembers() == 0 then
        for i = 1, GetNumPartyMembers() do
            if UnitName("party"..i) == name then
                return true, UnitIsConnected("party"..i)
            end
        end
    end
    
    return false, nil
end

function TWRA:GetPlayerClass(name)
    -- First check if it's the player
    if UnitName("player") == name then
        local _, class = UnitClass("player")
        return string.upper(class)
    end
    
    -- Check raid roster
    for i = 1, GetNumRaidMembers() do
        local raidName, _, _, _, _, class = GetRaidRosterInfo(i)
        if raidName == name then
            return string.upper(class)
        end
    end
    
    -- Check party if not in raid
    if GetNumRaidMembers() == 0 then
        for i = 1, GetNumPartyMembers() do
            if UnitName("party"..i) == name then
                local _, class = UnitClass("party"..i)
                return string.upper(class)
            end
        end
    end
    
    return nil
end

function TWRA:HasClassInRaid(className)
    for i = 1, GetNumRaidMembers() do
        local _, _, _, _, _, class = GetRaidRosterInfo(i)
        -- Convert both to uppercase for comparison
        if string.upper(class) == string.upper(className) then
            return true
        end
    end
    return false
end

function TWRA:IsRaidAssist()
    if GetNumRaidMembers() == 0 then
        return false
    end
    
    local playerName = UnitName("player")
    for i = 1, GetNumRaidMembers() do
        if UnitName("raid"..i) == playerName then
            -- Use the Classic function names
            return IsRaidOfficer("raid"..i) or IsRaidLeader("raid"..i)
        end
    end
    return false
end

-- Addon detection utilities
function TWRA:IsORA2Available()
    return oRA and oRA.maintanktable ~= nil
end

function TWRA:IsSuperWoWAvailable()
    return SUPERWOW_VERSION ~= nil
end

-- Table utilities
function TWRA:GetKeys(tbl)
    if not tbl then return {} end
    
    local keys = {}
    for k in pairs(tbl) do
        table.insert(keys, k)
    end
    return keys
end

function TWRA:TableToString(tbl, indent)
    if not tbl then return "nil" end
    if type(tbl) ~= "table" then return tostring(tbl) end
    
    indent = indent or ""
    local result = "{\n"
    local isArray = true
    local maxIndex = 0
    
    -- Check if this table is an array
    for k, v in pairs(tbl) do
        if type(k) ~= "number" or k <= 0 or math.floor(k) ~= k then
            isArray = false
            break
        end
        maxIndex = math.max(maxIndex, k)
    end
    
    isArray = isArray and (maxIndex == table.getn(tbl))
    
    -- Serialize array-style (just values)
    if isArray then
        for i, v in ipairs(tbl) do
            result = result .. indent .. "  "
            
            if type(v) == "string" then
                -- Escape special characters in strings
                v = string.gsub(v, "\\", "\\\\")
                v = string.gsub(v, "\"", "\\\"")
                v = string.gsub(v, "\n", "\\n")
                result = result .. "\"" .. v .. "\""
            elseif type(v) == "table" then
                result = result .. self:TableToString(v, indent .. "  ")
            else
                result = result .. tostring(v)
            end
            
            if i < table.getn(tbl) then
                result = result .. ","
            end
            result = result .. "\n"
        end
    else
        -- Serialize map-style (key-value pairs)
        for k, v in pairs(tbl) do
            result = result .. indent .. "  "
            
            -- Handle key based on type
            if type(k) == "string" then
                -- If key is a simple identifier, use field notation
                if string.find(k, "^[%a_][%w_]*$") then
                    result = result .. k .. " = "
                else
                    -- Otherwise use quoted string
                    k = string.gsub(k, "\\", "\\\\")
                    k = string.gsub(k, "\"", "\\\"")
                    result = result .. "[\"" .. k .. "\"] = "
                end
            else
                result = result .. "[" .. tostring(k) .. "] = "
            end
            
            -- Handle value based on type
            if type(v) == "string" then
                -- Escape special characters in strings
                v = string.gsub(v, "\\", "\\\\")
                v = string.gsub(v, "\"", "\\\"")
                v = string.gsub(v, "\n", "\\n")
                result = result .. "\"" .. v .. "\""
            elseif type(v) == "table" then
                result = result .. self:TableToString(v, indent .. "  ")
            else
                result = result .. tostring(v)
            end
            
            result = result .. ",\n"
        end
    end
    
    result = result .. indent .. "}"
    return result
end

-- Safe table copy function
function TWRA:DeepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[self:DeepCopy(orig_key)] = self:DeepCopy(orig_value)
        end
        setmetatable(copy, self:DeepCopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

-- Print a table structure for debugging
function TWRA:PrintTable(tbl, indent, maxDepth, currentDepth)
    if not tbl or type(tbl) ~= "table" then return end
    
    indent = indent or ""
    maxDepth = maxDepth or 5
    currentDepth = currentDepth or 1
    
    if currentDepth > maxDepth then
        DEFAULT_CHAT_FRAME:AddMessage(indent .. "... (max depth reached)")
        return
    end
    
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            DEFAULT_CHAT_FRAME:AddMessage(indent .. tostring(k) .. " = {")
            self:PrintTable(v, indent .. "  ", maxDepth, currentDepth + 1)
            DEFAULT_CHAT_FRAME:AddMessage(indent .. "}")
        else
            DEFAULT_CHAT_FRAME:AddMessage(indent .. tostring(k) .. " = " .. tostring(v))
        end
    end
end

-- Find index of value in array
function TWRA:IndexOf(array, value)
    if not array or type(array) ~= "table" then return nil end
    
    for i, v in ipairs(array) do
        if v == value then return i end
    end
    return nil
end

-- Check if an array contains a value
function TWRA:Contains(array, value)
    return self:IndexOf(array, value) ~= nil
end

-- Round a number to specified decimal places
function TWRA:Round(num, numDecimalPlaces)
    local mult = 10^(numDecimalPlaces or 0)
    if num >= 0 then
        return math.floor(num * mult + 0.5) / mult
    else
        return math.ceil(num * mult - 0.5) / mult
    end
end

-- Format time in seconds to readable string
function TWRA:FormatTime(timeInSeconds)
    if timeInSeconds < 60 then
        return math.floor(timeInSeconds) .. "s"
    elseif timeInSeconds < 3600 then
        local minutes = math.floor(timeInSeconds / 60)
        local seconds = math.floor(timeInSeconds - minutes * 60)
        return minutes .. "m " .. seconds .. "s"
    else
        local hours = math.floor(timeInSeconds / 3600)
        local minutes = math.floor((timeInSeconds - hours * 3600) / 60)
        return hours .. "h " .. minutes .. "m"
    end
end

TWRA:Debug("general", "Utils module loaded")