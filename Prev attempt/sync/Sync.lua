-- Sync functionality for TWRA
TWRA = TWRA or {}

-- Initialize sync system
function TWRA:InitializeSync()
    -- Sync runtime state variables
    self.SYNC.liveSync = false
    self.SYNC.tankSync = false
    self.SYNC.pendingSection = nil
    self.SYNC.lastRequestTime = 0
    self.SYNC.pendingResponse = false
    
    -- Load sync settings from SavedVariables
    if TWRA_SavedVariables and TWRA_SavedVariables.options then
        self.SYNC.liveSync = TWRA_SavedVariables.options.liveSync or false
        self.SYNC.tankSync = TWRA_SavedVariables.options.tankSync or false
    end
    
    -- Register for in-game events
    self:RegisterEvent("CHAT_MSG_ADDON")
    self:RegisterEvent("RAID_ROSTER_UPDATE")
    self:RegisterEvent("PARTY_MEMBERS_CHANGED")
    
    self:Debug("sync", "Sync system initialized")
end

-- Function to send addon messages
function TWRA:SendAddonMessage(message, distribution, target)
    if not message then return end
    
    self:Debug("sync", "Sending message (" .. string.len(message) .. " chars)")
    
    -- Send appropriately based on group
    if GetNumRaidMembers() > 0 then
        SendAddonMessage(self.SYNC.PREFIX, message, "RAID")
    elseif GetNumPartyMembers() > 0 then
        SendAddonMessage(self.SYNC.PREFIX, message, "PARTY")
    else
        self:Debug("sync", "Not in a group, message not sent")
    end
end

-- Function to handle incoming addon messages
function TWRA:HandleAddonMessage(message, channel, sender)
    -- Parse command and args
    local colonPos = string.find(message, ":", 1, true)
    if not colonPos then
        self:Debug("error", "Invalid addon message format from " .. sender)
        return
    end
    
    local command = string.sub(message, 1, colonPos - 1)
    local args = string.sub(message, colonPos + 1)
    
    self:Debug("sync", "Received command: " .. command .. " from " .. sender)
    
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
    else
        self:Debug("error", "Unknown command: " .. command .. " from " .. sender)
    end
end

-- Called when group composition changes
function TWRA:OnGroupChanged()
    if GetNumRaidMembers() > 0 or GetNumPartyMembers() > 0 then
        -- Announce our version and data timestamp to the group
        local msg = string.format(
            self.MESSAGE_FORMATS.VERSION,
            self.SYNC.COMMANDS.VERSION,
            TWRA_SavedVariables.assignments and TWRA_SavedVariables.assignments.timestamp or 0,
            UnitName("player")
        )
        self:SendAddonMessage(msg)
    end
end

-- Event handler for addon messages
function TWRA:CHAT_MSG_ADDON(prefix, message, distribution, sender)
    if prefix ~= self.SYNC.PREFIX then
        return
    end
    
    -- Ignore messages from self
    if sender == UnitName("player") then 
        return
    end
    
    self:Debug("sync", "Received addon message from " .. sender)
    self:HandleAddonMessage(message, distribution, sender)
end

-- Event handler for raid roster changes
function TWRA:RAID_ROSTER_UPDATE()
    self:Debug("sync", "Raid roster updated")
    self:OnGroupChanged()
end

-- Event handler for party changes
function TWRA:PARTY_MEMBERS_CHANGED()
    self:Debug("sync", "Party members changed")
    self:OnGroupChanged()
end

TWRA:Debug("sync", "Sync module loaded")