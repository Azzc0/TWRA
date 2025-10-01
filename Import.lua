-- ...existing code...

function TWRA:ImportData(importString)
    -- ...existing code...
    
    -- If import was successful
    if success then
        -- ...existing code...
        
        -- Broadcast to group if in one
        if IsInGroup() or IsInRaid() then
            local channel = IsInRaid() and "RAID" or "PARTY"
            
            -- Use our new sequenced bulk sync
            if self.SendBulkSyncToGroup then
                self:Debug("import", "Broadcasting imported data to group")
                self:SendBulkSyncToGroup()
            elseif self.SendBulkSyncToPlayer then
                -- Fallback to sending to each player individually
                self:Debug("import", "Broadcasting imported data to each group member")
                self:SendBulkSyncToEachGroupMember()
            else
                self:Debug("error", "Sync functions not available")
            end
        end
        
        -- ...existing code...
    end
    
    -- ...existing code...
end

-- New function to send bulk sync to the group, using the proper sequence
function TWRA:SendBulkSyncToGroup()
    local channel = IsInRaid() and "RAID" or "PARTY"
    if not IsInGroup() and not IsInRaid() then
        self:Debug("sync", "Not in a group, cannot send bulk sync")
        return
    end
    
    self:Debug("sync", "Sending bulk sync to group via " .. channel)
    
    -- First, send metadata message with timestamp
    local timestamp = TWRA_Assignments.timestamp or GetServerTime()
    local metadataMessage = "META:" .. timestamp .. ":" .. self:GetAddonVersion()
    
    SendAddonMessage(self.SYNC.PREFIX, metadataMessage, channel)
    self:Debug("sync", "Sent metadata message with timestamp " .. timestamp)
    
    -- Add a small delay between metadata and structure
    self:ScheduleTimer(function()
        -- Then send structure data
        self:SendBulkStructure(channel)
        
        -- Add a delay before sending sections
        self:ScheduleTimer(function()
            -- Finally, send all sections
            self:SendAllSections(channel)
        end, 0.5)
    end, 0.2)
end

-- Function to send to each group member individually if needed
function TWRA:SendBulkSyncToEachGroupMember()
    -- Handle raid
    if IsInRaid() then
        for i = 1, GetNumRaidMembers() do
            local name = GetRaidRosterInfo(i)
            if name and name ~= UnitName("player") then
                self:SendBulkSyncToPlayer(name)
            end
        end
    -- Handle party
    elseif IsInGroup() then
        for i = 1, GetNumPartyMembers() do
            local name = UnitName("party" .. i)
            if name then
                self:SendBulkSyncToPlayer(name)
            end
        end
    end
end