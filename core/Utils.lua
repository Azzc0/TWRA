-- TWRA Utility Functions
-- Common utility functions used throughout the addon

TWRA = TWRA or {}

function TWRA:ScheduleTimer(callback, delay)
    if not callback or type(delay) ~= "number" then return end
    
    -- Create a unique ID for this timer
    local id = tostring({})  -- Simple way to get a unique string
    
    -- Store the timer info
    self.timers[id] = {
        callback = callback,
        expires = GetTime() + delay
    }
    
    -- If this is our first timer, start the update frame, create it if needed
    if not self.timerFrame then
        self.timerFrame = CreateFrame("Frame")
        self.timerFrame:SetScript("OnUpdate", function()
            -- Check all timers on each frame update
            local now = GetTime()
            for timerId, timer in pairs(TWRA.timers) do
                if timer.expires <= now then
                    -- Call the callback
                    timer.callback()
                    -- Remove the timer
                    TWRA.timers[timerId] = nil
                end
            end
        end)
    end
    
    return id
end

function TWRA:CancelTimer(timerId)
    if timerId then
        self.timers[timerId] = nil
    end
end

-- Split a string by delimiter - improved version with better debugging
function TWRA:SplitString(str, delimiter)
    if not str then return {} end
    if not delimiter or delimiter == "" then return { str } end
    
    self:Debug("sync", "SplitString called on: " .. str .. ", delimiter: " .. delimiter, false, true) -- Mark as details
    
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
    self:Debug("sync", resultInfo .. " (total: " .. table.getn(result) .. " parts)", false, true) -- Mark as details
    
    return result
end

-- Add frame creation logic to convert from 0/1 to boolean
function TWRA:ConvertOptionValues()
    -- Ensure options exist
    if not TWRA_SavedVariables.options then
        TWRA_SavedVariables.options = {}
    end
    
    -- Convert any 0/1 values to proper booleans
    local optionsToConvert = {
        "hideFrameByDefault", "lockFramePosition", "autoNavigate", 
        "liveSync", "tankSync"
    }
    
    for _, option in ipairs(optionsToConvert) do
        if TWRA_SavedVariables.options[option] ~= nil then
            if type(TWRA_SavedVariables.options[option]) == "number" then
                -- Convert 0/1 to boolean
                TWRA_SavedVariables.options[option] = (TWRA_SavedVariables.options[option] == 1)
            end
        end
    end
    
    -- Also check OSD options
    if TWRA_SavedVariables.options.osd then
        local osdOptions = {"locked", "enabled", "showOnNavigation"}
        for _, option in ipairs(osdOptions) do
            if TWRA_SavedVariables.options.osd[option] ~= nil then
                if type(TWRA_SavedVariables.options.osd[option]) == "number" then
                    -- Convert 0/1 to boolean
                    TWRA_SavedVariables.options.osd[option] = (TWRA_SavedVariables.options.osd[option] == 1)
                end
            end
        end
    end
end

-- Function to update the player table with current group information
function TWRA:UpdatePlayerTable()
    -- Store previous player data for comparison
    local oldPlayers = {}
    if self.PLAYERS then
        for name, data in pairs(self.PLAYERS) do
            oldPlayers[name] = {data[1], data[2]} -- Copy class and status
        end
    end
    
    -- Check if we're using example data
    local useExampleData = false
    if TWRA_Assignments and TWRA_Assignments.isExample ~= nil then
        useExampleData = TWRA_Assignments.isExample
    end
    
    -- Set the addon-wide flag for example data
    self.usingExampleData = useExampleData
    
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
            self.PLAYERS[groupName] = {className, true} -- Class groups are always "online"
        end
    end
    
    -- Add example players if requested
    if useExampleData and self.EXAMPLE_PLAYERS then
        for name, classInfo in pairs(self.EXAMPLE_PLAYERS) do
            if not self.PLAYERS[name] then  -- Don't overwrite real players
                -- If we have new format (array format)
                if type(classInfo) == "table" then
                    self.PLAYERS[name] = {classInfo[1], classInfo[2]}
                else
                    -- Convert from old format with |OFFLINE marker to new format
                    local isOffline = string.find(classInfo, "|OFFLINE")
                    local class = string.gsub(classInfo, "|OFFLINE", "")
                    self.PLAYERS[name] = {class, not isOffline}
                end
            end
        end
    end
    
    -- Check if the player table has changed
    local hasChanges = false
    
    -- Check for added or modified players
    for name, data in pairs(self.PLAYERS) do
        if not oldPlayers[name] or 
           oldPlayers[name][1] ~= data[1] or 
           oldPlayers[name][2] ~= data[2] then
            hasChanges = true
            break
        end
    end
    
    -- Check for removed players
    if not hasChanges then
        for name, _ in pairs(oldPlayers) do
            if not self.PLAYERS[name] then
                hasChanges = true
                break
            end
        end
    end
    
    -- Notify about changes if detected
    if hasChanges then
        self:Debug("data", "Player table changed - triggering updates")
        
        -- Trigger PLAYERS_UPDATED event if the event system is available
        if self.TriggerEvent then
            self:TriggerEvent("PLAYERS_UPDATED")
        end
        
        -- Update UI if main frame is visible
        if self.mainFrame and self.mainFrame:IsShown() and self.currentView == "main" then
            -- Refresh assignment table to update player colors/status
            if self.RefreshAssignmentTable then
                self:Debug("ui", "Refreshing assignment table due to player changes")
                self:RefreshAssignmentTable()
            end
        end
        
        -- Update OSD if it's visible
        if self.OSD and self.OSD.isVisible then
            -- Update OSD content with current section
            if self.UpdateOSDContent and self.navigation and
               self.navigation.currentIndex and self.navigation.handlers then
                local sectionName = self.navigation.handlers[self.navigation.currentIndex]
                local currentIndex = self.navigation.currentIndex
                local totalSections = table.getn(self.navigation.handlers)
                
                self:Debug("osd", "Updating OSD content due to player changes")
                self:UpdateOSDContent(sectionName, currentIndex, totalSections)
            end
        end
    end
    
    self:Debug("data", "Updated player table with " .. self:GetTableSize(self.PLAYERS) .. " entries")
    
    return self.PLAYERS, hasChanges
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