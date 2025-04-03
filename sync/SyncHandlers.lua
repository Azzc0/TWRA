-- TWRA Sync Command Handlers
-- Contains implementations for handling different sync commands

TWRA = TWRA or {}

-- Handle ANNOUNCE command
function TWRA:HandleAnnounceCommand(args, sender)
    self:Debug("sync", "Processing ANNOUNCE command")
    
    -- Parse timestamp and data
    local colonPos = string.find(args, ":", 1, true)
    if not colonPos then
        self:Debug("error", "Invalid announce format")
        return
    end
    
    local timestamp = tonumber(string.sub(args, 1, colonPos - 1))
    local data = string.sub(args, colonPos + 1)
    
    self:Debug("sync", "Timestamp: " .. tostring(timestamp))
    self:Debug("sync", "Data length: " .. string.len(data))
    
    -- Check against our timestamp
    local ourTimestamp = TWRA_SavedVariables.assignments and TWRA_SavedVariables.assignments.timestamp or 0
    
    if timestamp and timestamp > ourTimestamp then
        self:Debug("sync", "Timestamp is newer - processing")
        -- We'll implement the full handling logic in DataProcessing.lua
    else
        self:Debug("sync", "Our data is newer or the same - ignoring")
    end
end

-- Handle SECTION command
function TWRA:HandleSectionCommand(args, sender)
    self:Debug("sync", "Processing SECTION command")
    
    -- Parse the message
    local parts = self:SplitString(args, ":")
    if table.getn(parts) < 3 then
        self:Debug("error", "Invalid SECTION format: " .. args)
        return
    end
    
    local timestamp = tonumber(parts[1])
    local sectionName = parts[2]
    local sectionIndex = tonumber(parts[3])
    
    self:Debug("sync", "Section: " .. sectionName .. " (index: " .. sectionIndex .. ")")
    
    -- Check timestamp
    local ourTimestamp = TWRA_SavedVariables.assignments and TWRA_SavedVariables.assignments.timestamp or 0
    
    if timestamp > ourTimestamp then
        -- Need newer data
        self:Debug("sync", "Requesting newer data (timestamp " .. timestamp .. ")")
        self.SYNC.pendingSection = sectionIndex
        self:SendAddonMessage(self.SYNC.COMMANDS.DATA_REQUEST .. ":" .. timestamp)
    elseif timestamp == ourTimestamp then
        self:Debug("sync", "Timestamps match - changing to section " .. sectionIndex)
        -- We'll implement section changing logic later
    else
        self:Debug("sync", "Ignoring older timestamp")
    end
end

-- Handle VERSION command
function TWRA:HandleVersionCommand(args, sender)
    self:Debug("sync", "Processing VERSION command")
    
    local parts = self:SplitString(args, ":")
    if table.getn(parts) < 2 then 
        self:Debug("error", "Invalid VERSION format")
        return 
    end
    
    local timestamp = tonumber(parts[1])
    local senderName = parts[2]
    
    -- Safety check for valid timestamp
    if not timestamp then
        self:Debug("error", "Invalid timestamp in VERSION from " .. sender)
        return
    end
    
    self:Debug("sync", sender .. " has version with timestamp: " .. tostring(timestamp))
    
    -- Check if we have newer data to share
    local ourTimestamp = TWRA_SavedVariables.assignments and TWRA_SavedVariables.assignments.timestamp or 0
    
    if ourTimestamp > timestamp then
        self:Debug("sync", "Our data is newer - will announce later")
        -- We'll implement announcing later
    elseif timestamp > ourTimestamp then
        self:Debug("sync", "Their data is newer - requesting")
        self:SendAddonMessage(self.SYNC.COMMANDS.DATA_REQUEST .. ":" .. timestamp)
    else
        self:Debug("sync", "Same timestamp, no action needed")
    end
end

-- Basic implementation of DATA_REQUEST command handler
function TWRA:HandleDataRequestCommand(args, sender)
    self:Debug("sync", "Processing DATA_REQUEST command")
    
    -- Parse the requested timestamp
    local requestedTimestamp = tonumber(args)
    if not requestedTimestamp then 
        self:Debug("error", "Invalid timestamp in DATA_REQUEST")
        return 
    end
    
    local ourTimestamp = TWRA_SavedVariables.assignments and TWRA_SavedVariables.assignments.timestamp or 0
    
    -- Only respond if we have the requested version and have source data
    if requestedTimestamp == ourTimestamp and TWRA_SavedVariables.assignments and TWRA_SavedVariables.assignments.source then
        self:Debug("sync", "We have the requested data - will respond")
        -- We'll implement the chunking logic in ChunkManager.lua
    else
        -- Log message for debugging when we can't respond
        if requestedTimestamp ~= ourTimestamp then
            self:Debug("sync", "Can't respond - timestamp mismatch")
        elseif not TWRA_SavedVariables.assignments then
            self:Debug("sync", "Can't respond - no assignments data")
        elseif not TWRA_SavedVariables.assignments.source then
            self:Debug("sync", "Can't respond - no source data")
        end
    end
end

-- Basic implementation of DATA_RESPONSE command handler
function TWRA:HandleDataResponseCommand(args, sender)
    self:Debug("sync", "Processing DATA_RESPONSE command from " .. sender)
    
    -- Check if this is a chunked response
    local colonPos1 = string.find(args, ":", 1, true)
    if not colonPos1 then 
        self:Debug("error", "Invalid DATA_RESPONSE format")
        return 
    end
    
    local timestamp = tonumber(string.sub(args, 1, colonPos1 - 1))
    local remaining = string.sub(args, colonPos1 + 1)
    
    -- Check for chunked format
    local colonPos2 = string.find(remaining, ":", 1, true)
    if colonPos2 then
        self:Debug("sync", "Received chunked data - will process via ChunkManager")
        -- We'll implement chunk management in ChunkManager.lua
    else
        -- Single part format: timestamp:data
        local data = remaining
        self:Debug("sync", "Received single-part data, length: " .. string.len(data))
        -- Will process via DataProcessing.lua
    end
end
