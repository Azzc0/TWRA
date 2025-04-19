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

-- Player status utility functions
-- These were previously in Frame.lua but are more appropriate in a utils file

-- Get player status (in raid and online status)
function TWRA:GetPlayerStatus(name)
    -- Check for valid name
    if not name or name == "" then return false, nil end
    
    -- Check if we have this player in our PLAYERS table
    if self.PLAYERS and self.PLAYERS[name] then
        return true, self.PLAYERS[name][2] -- Return online status directly from table
    end
    
    -- Handle example data mode if not yet in PLAYERS table
    if self.usingExampleData and self.EXAMPLE_PLAYERS and self.EXAMPLE_PLAYERS[name] then
        local isOffline = string.find(self.EXAMPLE_PLAYERS[name], "OFFLINE")
        return true, not isOffline
    end
    
    -- Check if it's the player
    if UnitName("player") == name then return true, true end
    
    -- Check raid roster
    for i = 1, GetNumRaidMembers() do
        local raidName, _, _, _, _, _, _, online = GetRaidRosterInfo(i)
        if raidName == name then
            return true, online == 1
        end
    end
    
    -- Check party if not in raid
    if GetNumRaidMembers() == 0 then
        for i = 1, GetNumPartyMembers() do
            if UnitName("party" .. i) == name then
                return true, UnitIsConnected("party" .. i)
            end
        end
    end
    
    return false, nil
end

-- Get class for a player
function TWRA:GetPlayerClass(name)
    -- Check if we have this player in our PLAYERS table
    if self.PLAYERS and self.PLAYERS[name] then
        return self.PLAYERS[name][1] -- Return class directly from table
    end
    
    -- Handle example data if not yet in PLAYERS table
    if self.usingExampleData and self.EXAMPLE_PLAYERS and self.EXAMPLE_PLAYERS[name] then
        return string.gsub(self.EXAMPLE_PLAYERS[name], "|OFFLINE", "")
    end
    
    -- Check if it's the player
    if UnitName("player") == name then
        local _, class = UnitClass("player")
        return class
    end
    
    -- Check raid roster
    for i = 1, GetNumRaidMembers() do
        local raidName, _, _, _, _, className = GetRaidRosterInfo(i)
        if raidName == name then
            return className
        end
    end
    
    -- Check party if not in raid
    if GetNumRaidMembers() == 0 then
        for i = 1, GetNumPartyMembers() do
            if UnitName("party" .. i) == name then
                local _, class = UnitClass("party" .. i)
                return class
            end
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

-- Split a string by delimiter - improved version with better debugging
function TWRA:SplitString(str, delimiter)
    if not str then return {} end
    if not delimiter or delimiter == "" then return { str } end
    
    self:Debug("sync", "SplitString called on: " .. str .. ", delimiter: " .. delimiter)
    
    local result = {}
    local from = 1
    local delim_from, delim_to = string.find(str, delimiter, from, true)
    
    while delim_from do
        table.insert(result, string.sub(str, from, delim_from - 1))
        from = delim_to + 1
        delim_from, delim_to = string.find(str, delimiter, from, true)
    end
    
    table.insert(result, string.sub(str, from))
    
    -- Add debug output for the result
    local resultInfo = "Split result:"
    for i, part in ipairs(result) do
        resultInfo = resultInfo .. " [" .. i .. "]=\"" .. part .. "\""
    end
    self:Debug("sync", resultInfo .. " (total: " .. table.getn(result) .. " parts)")
    
    return result
end

---- Import from TWRA.lua

-- Utility functions
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

-- Check if oRA2 is available
function TWRA:IsORA2Available()
    return oRA and oRA.maintanktable ~= nil  -- Changed to lowercase
end

-- Function to update the player table with current group information
function TWRA:UpdatePlayerTable(isExample)
    -- Create or reset the player table
    self.PLAYERS = {}
    
    -- Add real players from group first
    if GetNumRaidMembers() > 0 then
        -- We're in a raid
        for i = 1, GetNumRaidMembers() do
            local name, _, _, _, _, class, _, online = GetRaidRosterInfo(i)
            if name and class then
                -- Store class and online status as separate values
                self.PLAYERS[name] = {class, online == 1}
            end
        end
    elseif GetNumPartyMembers() > 0 then
        -- We're in a party
        -- Add the player first
        local playerName = UnitName("player")
        local _, playerClass = UnitClass("player")
        if playerName and playerClass then
            self.PLAYERS[playerName] = {playerClass, true} -- Player is always online
        end
        
        -- Add party members
        for i = 1, GetNumPartyMembers() do
            local unitID = "party" .. i
            local name = UnitName(unitID)
            local _, class = UnitClass(unitID)
            local online = UnitIsConnected(unitID)
            
            if name and class then
                self.PLAYERS[name] = {class, online}
            end
        end
    else
        -- Solo - just add the player
        local playerName = UnitName("player")
        local _, playerClass = UnitClass("player")
        if playerName and playerClass then
            self.PLAYERS[playerName] = {playerClass, true} -- Player is always online
        end
    end
    
    -- Add class group names from CLASS_GROUP_NAMES
    if self.CLASS_GROUP_NAMES then
        for groupName, className in pairs(self.CLASS_GROUP_NAMES) do
            self.PLAYERS[groupName] = {groupName, true} -- Class groups are always "online"
        end
    end
    
    -- Add example players if requested
    if isExample and self.EXAMPLE_PLAYERS then
        for name, classInfo in pairs(self.EXAMPLE_PLAYERS) do
            if not self.PLAYERS[name] then  -- Don't overwrite real players
                -- Convert from old format with |OFFLINE marker to new format
                local isOffline = string.find(classInfo, "|OFFLINE")
                local class = string.gsub(classInfo, "|OFFLINE", "")
                self.PLAYERS[name] = {class, not isOffline}
            end
        end
    end
    
    self:Debug("data", "Updated player table with " .. self:GetTableSize(self.PLAYERS) .. " entries")
    
    return self.PLAYERS
end

-- Helper function to count table entries (including non-integer keys)
function TWRA:GetTableSize(tbl)
    if not tbl then return 0 end
    
    local count = 0
    for _ in pairs(tbl) do
        count = count + 1
    end
    return count
end