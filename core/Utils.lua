-- TWRA Utility Functions
-- Common utility functions used throughout the addon

TWRA = TWRA or {}

-- Deep copy a table
function TWRA:DeepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in pairs(orig) do
            copy[orig_key] = self:DeepCopy(orig_value)
        end
    else
        copy = orig
    end
    return copy
end

-- Format time as HH:MM:SS
function TWRA:FormatTime(seconds)
    if not seconds then return "00:00:00" end
    
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds - (hours * 3600)) / 60)
    local secs = math.floor(seconds - (hours * 3600) - (minutes * 60))
    
    return string.format("%02d:%02d:%02d", hours, minutes, secs)
end

-- Format large numbers with commas
function TWRA:FormatNumber(num)
    if not num then return "0" end
    
    local formatted = tostring(num)
    local k
    
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then break end
    end
    
    return formatted
end

-- Truncate text to a specific length with ellipsis
function TWRA:TruncateText(text, length)
    if not text then return "" end
    if string.len(text) <= length then return text end
    
    return string.sub(text, 1, length) .. "..."
end

-- Player status utility functions
-- These were previously in Frame.lua but are more appropriate in a utils file

-- Get player status (in raid and online status)
function TWRA:GetPlayerStatus(name)
    if self.usingExampleData then
        if not name or name == "" then return false, nil end
        if self.EXAMPLE_PLAYERS[name] then
            local isOffline = string.find(self.EXAMPLE_PLAYERS[name], "OFFLINE")
            return true, not isOffline
        end
        return false, nil
    end
    
    -- Default behavior for real raid data
    if not name or name == "" then return false, nil end
    for i = 1, GetNumRaidMembers() do
        local raidName, _, _, _, _, _, _, online = GetRaidRosterInfo(i)
        if raidName == name then
            return true, online == 1
        end
    end
    return false, nil
end

-- Get class for a player
function TWRA:GetPlayerClass(name)
    if self.usingExampleData and self.EXAMPLE_PLAYERS[name] then
        return string.gsub(self.EXAMPLE_PLAYERS[name], "|OFFLINE", "")
    end
    
    -- Default behavior for real raid data
    for i = 1, GetNumRaidMembers() do
        local raidName, _, _, _, _, className = GetRaidRosterInfo(i)
        if raidName == name then
            return className
        end
    end
    return nil
end

-- Check if a specific class exists in raid
function TWRA:HasClassInRaid(className)
    -- If using example data, check against EXAMPLE_PLAYERS
    if self.usingExampleData then
        for _, classInfo in pairs(self.EXAMPLE_PLAYERS) do
            local playerClass = string.gsub(classInfo, "|OFFLINE", "")
            if string.upper(className) == playerClass then
                return true
            end
        end
        return false
    end
    
    -- Default behavior for real raid data
    for i = 1, GetNumRaidMembers() do
        local _, _, _, _, _, class = GetRaidRosterInfo(i)
        if string.upper(class) == string.upper(className) then
            return true
        end
    end
    return false
end
