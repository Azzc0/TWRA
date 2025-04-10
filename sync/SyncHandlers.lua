-- TWRA Sync Message Handlers
-- Handles all incoming addon communications for synchronization
TWRA = TWRA or {}

-- Main addon message handler - routes messages to appropriate handlers
function TWRA:HandleAddonMessage(message, channel, sender)
    -- Skip our own messages
    if sender == UnitName("player") then
        self:Debug("sync", "Ignoring own message: " .. message)
        return
    end
    
    -- Validate message format
    if not message or message == "" then
        self:Debug("sync", "Received empty message from " .. sender)
        return
    end
    
    -- Split message by colon to get command and arguments
    local parts = self:SplitString(message, ":")
    if not parts or table.getn(parts) < 1 then
        self:Debug("sync", "Malformed message from " .. sender .. ": " .. message)
        return
    end
    
    -- Extract command and arguments
    local command = parts[1]
    local args = {}
    for i = 2, table.getn(parts) do
        table.insert(args, parts[i])
    end
    
    -- Route to appropriate handler based on command
    self:Debug("sync", "Received " .. command .. " from " .. sender)
    
    if command == self.SYNC.COMMANDS.SECTION then
        self:HandleSectionCommand(args, sender)
    elseif command == self.SYNC.COMMANDS.ANNOUNCE then
        self:HandleAnnounceCommand(args, sender)
    elseif command == self.SYNC.COMMANDS.DATA_REQUEST then
        self:HandleDataRequestCommand(args, sender)
    elseif command == self.SYNC.COMMANDS.DATA_RESPONSE then
        self:HandleDataResponseCommand(args, sender)
    elseif command == self.SYNC.COMMANDS.VERSION then
        self:HandleVersionCommand(args, sender)
    else
        self:Debug("sync", "Unknown command from " .. sender .. ": " .. command)
    end
end

-- Handle section change commands (live section sync)
function TWRA:HandleSectionCommand(args, sender)
    -- Validate arguments
    if table.getn(args) < 3 then
        self:Debug("sync", "Malformed section command from " .. sender)
        return
    end
    
    -- Extract arguments
    local timestamp = tonumber(args[1])
    local sectionIndex = tonumber(args[2])
    local sectionName = args[3]
    
    -- Debug info
    self:Debug("sync", string.format("Section change from %s: '%s' (index: %d, timestamp: %d)", 
        sender, sectionName, sectionIndex, timestamp))
    
    -- Verify we have live sync enabled
    if not self.SYNC.liveSync then
        self:Debug("sync", "Ignoring section change (live sync disabled)")
        return
    end
    
    -- Compare timestamps
    local ourTimestamp = 0
    if TWRA_SavedVariables and TWRA_SavedVariables.assignments then
        ourTimestamp = TWRA_SavedVariables.assignments.timestamp or 0
    end
    
    -- If the sender has newer data, request a sync
    if timestamp > ourTimestamp then
        self:Debug("sync", "Sender has newer data (timestamp: " .. timestamp .. " vs ours: " .. ourTimestamp .. ")")
        self:RequestDataSync(timestamp)
        
        -- Store the pending section to navigate to after sync completes
        self.SYNC.pendingSection = {
            index = sectionIndex, 
            name = sectionName
        }
        return
    end
    
    -- If timestamps match, navigate to the section
    if timestamp == ourTimestamp then
        self:Debug("sync", "Navigating to section: " .. sectionName)
        
        -- Use NavigateToSection with suppressSync=true to avoid broadcast loops
        self:NavigateToSection(sectionIndex, true)
    else
        self:Debug("sync", "Ignoring section change (we have newer data)")
    end
end

-- Handle table announcement commands (manual imports by other users)
function TWRA:HandleAnnounceCommand(args, sender)
    -- Validate arguments
    if table.getn(args) < 2 then
        self:Debug("sync", "Malformed announce command from " .. sender)
        return
    end
    
    -- Extract arguments
    local timestamp = tonumber(args[1])
    local importerName = args[2]
    
    -- Debug info
    self:Debug("sync", string.format("New import announced by %s (timestamp: %d)", 
        importerName, timestamp))
    
    -- Compare timestamps
    local ourTimestamp = 0
    if TWRA_SavedVariables and TWRA_SavedVariables.assignments then
        ourTimestamp = TWRA_SavedVariables.assignments.timestamp or 0
    end
    
    -- Request data if announced import is newer than what we have
    if timestamp > ourTimestamp then
        self:Debug("sync", "Requesting newer data (timestamp: " .. timestamp .. " vs ours: " .. ourTimestamp .. ")")
        self:RequestDataSync(timestamp)
    else
        self:Debug("sync", "Ignoring import announcement (we have newer or same data)")
    end
end

-- Handle data request commands
function TWRA:HandleDataRequestCommand(args, sender)
    -- Validate arguments
    if table.getn(args) < 1 then
        self:Debug("sync", "Malformed data request command from " .. sender)
        return
    end
    
    -- Extract arguments
    local requestedTimestamp = tonumber(args[1])
    
    -- Debug info
    self:Debug("sync", string.format("Data request from %s (timestamp: %d)", 
        sender, requestedTimestamp))
    
    -- Check if we have the requested data
    local ourTimestamp = 0
    local sourceString = nil
    
    if TWRA_SavedVariables and TWRA_SavedVariables.assignments then
        ourTimestamp = TWRA_SavedVariables.assignments.timestamp or 0
        sourceString = TWRA_SavedVariables.assignments.source
    end
    
    -- Only respond if our timestamp matches what was requested
    if ourTimestamp ~= requestedTimestamp then
        self:Debug("sync", "Timestamp mismatch - we have: " .. ourTimestamp)
        return
    end
    
    -- Make sure we have source data
    if not sourceString or sourceString == "" then
        self:Debug("sync", "No source data available to share")
        return
    end
    
    -- Add random delay to prevent multiple responses at once
    -- Delay proportional to group size: 0-2 seconds in a 40-man raid
    local groupSize = GetNumPartyMembers() + GetNumRaidMembers()
    local maxDelay = math.min(2, groupSize * 0.05)
    local delay = maxDelay * math.random()
    
    -- Schedule the response after the delay
    self:ScheduleTimer(function()
        self:SendDataResponse(sourceString, ourTimestamp)
    end, delay)
    
    self:Debug("sync", string.format("Scheduling data response in %.1f seconds", delay))
end

-- Handle data response commands
function TWRA:HandleDataResponseCommand(args, sender)
    -- Validate arguments - first arg is timestamp, rest is the encoded data
    if table.getn(args) < 2 then
        self:Debug("sync", "Malformed data response from " .. sender)
        return
    end
    
    -- Extract timestamp
    local timestamp = tonumber(args[1])
    
    -- Reconstruct the encoded data (may contain colons which were split)
    local encodedData = args[2]
    for i = 3, table.getn(args) do
        encodedData = encodedData .. ":" .. args[i]
    end
    
    self:Debug("sync", string.format("Received data response from %s (timestamp: %d, length: %d)", 
        sender, timestamp, string.len(encodedData)))
    
    -- Compare timestamps
    local ourTimestamp = 0
    if TWRA_SavedVariables and TWRA_SavedVariables.assignments then
        ourTimestamp = TWRA_SavedVariables.assignments.timestamp or 0
    end
    
    -- Only process if we need this data
    if timestamp <= ourTimestamp then
        self:Debug("sync", "Ignoring data response (we have newer or same data)")
        return
    end
    
    -- Process the data like an import but with sync flags
    if self.DecodeBase64 then
        local decodedData = self:DecodeBase64(encodedData, timestamp, true)
        if not decodedData then
            self:Debug("error", "Failed to decode sync data from " .. sender)
            return
        end
        
        -- Data successfully imported
        self:Debug("sync", "Successfully imported data from " .. sender)
        
        -- Navigate to pending section if one was stored
        if self.SYNC.pendingSection then
            self:Debug("sync", "Navigating to pending section: " .. self.SYNC.pendingSection.name)
            self:NavigateToSection(self.SYNC.pendingSection.index, true)
            self.SYNC.pendingSection = nil
        end
    else
        self:Debug("error", "DecodeBase64 function not found")
    end
end

-- Handle version check commands
function TWRA:HandleVersionCommand(args, sender)
    -- Currently just logs the version info
    self:Debug("sync", "Version check from " .. sender .. " (args: " .. table.concat(args, ", ") .. ")")
end

-- Request data sync from group
function TWRA:RequestDataSync(timestamp)
    -- Throttle requests - don't spam requests
    local now = GetTime()
    if now - self.SYNC.lastRequestTime < self.SYNC.requestTimeout then
        self:Debug("sync", "Data request throttled")
        return
    end
    
    -- Update last request time
    self.SYNC.lastRequestTime = now
    
    -- Send data request message
    local message = string.format("%s:%d", self.SYNC.COMMANDS.DATA_REQUEST, timestamp)
    self:SendAddonMessage(message)
    
    self:Debug("sync", "Requested data sync for timestamp: " .. timestamp)
end

-- Send data response to group
function TWRA:SendDataResponse(encodedData, timestamp)
    if not encodedData or encodedData == "" then
        self:Debug("error", "No data to send in response")
        return
    end
    
    -- Format message
    local message = string.format("%s:%d:%s", 
        self.SYNC.COMMANDS.DATA_RESPONSE,
        timestamp,
        encodedData)
    
    -- This could be very large, so we might need to chunk it
    -- For now, just try to send directly
    self:Debug("sync", "Sending data response (timestamp: " .. timestamp .. ", length: " .. string.len(message) .. ")")
    self:SendAddonMessage(message)
end

-- Send section change notification to group
function TWRA:BroadcastSectionChange(sectionIndex, sectionName)
    -- Check if we're in a group
    if GetNumPartyMembers() == 0 and GetNumRaidMembers() == 0 then
        self:Debug("sync", "Not in a group, skipping section broadcast")
        return false
    end
    
    -- Get current timestamp
    local timestamp = 0
    if TWRA_SavedVariables and TWRA_SavedVariables.assignments then
        timestamp = TWRA_SavedVariables.assignments.timestamp or 0
    end
    
    -- Format and send the message
    local message = string.format("%s:%d:%d:%s", 
        self.SYNC.COMMANDS.SECTION,
        timestamp,
        sectionIndex,
        sectionName or "")
    
    self:SendAddonMessage(message)
    self:Debug("sync", "Broadcast section change: " .. (sectionName or "") .. 
               " (index: " .. sectionIndex .. ", timestamp: " .. timestamp .. ")")
    return true
end

-- Helper function to send an addon message using the correct channel
function TWRA:SendAddonMessage(message, target)
    -- Determine channel to use
    local channel = "RAID"
    if GetNumRaidMembers() == 0 then
        if GetNumPartyMembers() > 0 then
            channel = "PARTY"
        else
            self:Debug("sync", "Not in a group, can't send message")
            return false
        end
    end
    
    -- Check message length
    local maxLength = 254 -- Safe limit for addon messages
    if string.len(message) > maxLength then
        self:Debug("sync", "Message too long (" .. string.len(message) .. " chars), truncating")
        message = string.sub(message, 1, maxLength)
    end
    
    -- Send the message
    SendAddonMessage(self.SYNC.PREFIX, message, channel, target)
    return true
end
