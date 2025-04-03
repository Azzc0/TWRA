-- Sync functionality for TWRA
TWRA = TWRA or {}

-- Sync constants
TWRA.SYNC = {
    PREFIX = "TWRA",
    COMMANDS = {
        VERSION = "VERSION",      -- For version checking
        SECTION = "SECTION",      -- For live section updates
        DATA_REQUEST = "DREQ",    -- Request full data
        DATA_RESPONSE = "DRES",   -- Send full data
        ANNOUNCE = "ANC"          -- Announce new import
    },
    liveSync = false,            -- Live sync enabled
    pendingSection = nil,        -- Section to navigate to after sync
    lastRequestTime = 0,         -- Throttle requests
    requestTimeout = 5,          -- Time to wait before requesting again
}

-- Helper function to split strings
function TWRA:SplitString(str, sep)
    if not str or str == "" then return {} end
    if not sep or sep == "" then return {str} end
    
    local parts = {}
    local start = 1
    local max = string.len(str)
    
    while start <= max do
        local pos = string.find(str, sep, start, true)
        if not pos then
            -- Add the last part
            table.insert(parts, string.sub(str, start))
            break
        else
            -- Add the current part
            table.insert(parts, string.sub(str, start, pos - 1))
            start = pos + string.len(sep)
        end
    end
    
    return parts
end

-- Function to send addon messages
function TWRA:SendAddonMessage(message)
    if not message then return end
    
    -- Detect message type for debug
    local colonPos = string.find(message, ":", 1, true)
    local commandPart = colonPos and string.sub(message, 1, colonPos - 1) or "unknown"
    
    -- Send appropriately based on group
    if GetNumRaidMembers() > 0 then
        self:Debug("sync", "Sending to RAID")
        SendAddonMessage(self.SYNC.PREFIX, message, "RAID")
    elseif GetNumPartyMembers() > 0 then
        self:Debug("sync", "Sending to PARTY")
        SendAddonMessage(self.SYNC.PREFIX, message, "PARTY")
    else
        self:Debug("sync", "Not in a group, message not sent")
    end
end

-- Function to handle incoming addon messages
function TWRA:HandleAddonMessage(message, channel, sender)
    if sender == UnitName("player") then return end
    
    -- Parse command and args
    local colonPos = string.find(message, ":", 1, true)
    if not colonPos then return end
    
    local command = string.sub(message, 1, colonPos - 1)
    local args = string.sub(message, colonPos + 1)
    
    self:Debug("sync", "Received from " .. sender .. ": " .. command)
    
    -- Handle each command type
    if command == self.SYNC.COMMANDS.ANNOUNCE then
        self:HandleAnnounceCommand(args, sender)
    elseif command == self.SYNC.COMMANDS.SECTION then
        self:HandleSectionCommand(args, sender)
    elseif command == self.SYNC.COMMANDS.VERSION then
        self:HandleVersionCommand(args, sender)
    elseif command == self.SYNC.COMMANDS.DATA_REQUEST then
        self:HandleDataRequestCommand(args, sender)
    elseif command == self.SYNC.COMMANDS.DATA_RESPONSE then
        self:HandleDataResponseCommand(args, sender)
    end
end

-- Called when group composition changes
function TWRA:OnGroupChanged()
    if GetNumRaidMembers() > 0 or GetNumPartyMembers() > 0 then
        -- Announce our version and data timestamp to the group
        local msg = string.format("%s:%d:%s", 
            self.SYNC.COMMANDS.VERSION,
            TWRA_SavedVariables.assignments and TWRA_SavedVariables.assignments.timestamp or 0,
            UnitName("player"))
        self:SendAddonMessage(msg)
    end
end

-- Note: Handlers are now implemented in SyncHandlers.lua
