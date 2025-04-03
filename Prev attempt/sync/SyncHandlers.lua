-- TWRA Sync Command Handlers
TWRA = TWRA or {}

-- Handle ANNOUNCE command
function TWRA:HandleAnnounceCommand(args, sender)
    self:Debug("sync", "Processing ANNOUNCE command from " .. sender)
    
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
        self:Debug("sync", "Timestamp is newer - processing data from " .. sender)
        
        -- Use pending section if available
        local sectionToUse = self.SYNC.pendingSection or 1
        -- Call the function in DataProcessing.lua
        if self:ForceUpdateFromSync(data, timestamp, sectionToUse, true) then
            -- Clear pending section after use
            self.SYNC.pendingSection = nil
            DEFAULT_CHAT_FRAME:AddMessage("TWRA: Successfully synchronized with " .. sender)
        else
            self:Debug("error", "Failed to update from sync with " .. sender)
        end
    else
        self:Debug("sync", "Our data is newer or the same - ignoring")
    end
end

-- Handle SECTION command
function TWRA:HandleSectionCommand(args, sender)
    self:Debug("sync", "Processing SECTION command from " .. sender)
    
    -- Safety check
    if not args then 
        self:Debug("error", "SECTION command with nil args")
        return 
    end
    
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
        
        -- 1. Ensure navigation exists
        if not self.navigation or not self.navigation.handlers then
            self:Debug("sync", "Rebuilding navigation")
            self:RebuildNavigation()
        end
        
        -- 2. Validate section index
        if not self.navigation or sectionIndex > table.getn(self.navigation.handlers) then
            self:Debug("error", "Invalid section index: " .. sectionIndex)
            return
        end
        
        -- 3. Update state
        self.navigation.currentIndex = sectionIndex
        
        -- 4. Save to SavedVariables
        if TWRA_SavedVariables.assignments then
            TWRA_SavedVariables.assignments.currentSection = sectionIndex
        end
        
        -- 5. Update dropdown text
        if self.navigation and self.navigation.handlerText then
            self.navigation.handlerText:SetText(sectionName)
        end
        
        -- 6. Update display if visible
        if self.mainFrame and self.mainFrame:IsShown() and self.currentView ~= self.STATES.VIEW.OPTIONS and self.DisplayCurrentSection then
            self:DisplayCurrentSection()
        end
        
        -- 7. Show OSD
        if self.ShowSectionNameOverlay then
            self:ShowSectionNameOverlay(sectionName, sectionIndex, table.getn(self.navigation.handlers))
        end
        
        -- Success message
        DEFAULT_CHAT_FRAME:AddMessage("TWRA: " .. self.SYNC.STATUS_MESSAGES.SYNC_SUCCESS .. " - " .. 
                                     "Changed to section " .. sectionIndex .. " (" .. sectionName .. ") by " .. sender)
    else
        self:Debug("sync", "Ignoring older timestamp")
    end
end

-- Handle VERSION command
function TWRA:HandleVersionCommand(args, sender)
    self:Debug("sync", "Processing VERSION command from " .. sender)
    
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
    
    -- Check if we have newer data to share
    local ourTimestamp = TWRA_SavedVariables.assignments and TWRA_SavedVariables.assignments.timestamp or 0
    
    if ourTimestamp > timestamp then
        self:Debug("sync", "Our data is newer - announcing to group")
        
        -- Announce our data to the group
        if TWRA_SavedVariables.assignments and TWRA_SavedVariables.assignments.source then
            local announceMsg = string.format("%s:%d:%s", 
                self.SYNC.COMMANDS.ANNOUNCE,
                ourTimestamp,
                TWRA_SavedVariables.assignments.source)
            
            self:SendAddonMessage(announceMsg)
        else
            self:Debug("sync", "Can't announce - no source data")
        end
    elseif timestamp > ourTimestamp then
        self:Debug("sync", "Their data is newer - requesting")
        
        -- Request newer data
        self:SendAddonMessage(self.SYNC.COMMANDS.DATA_REQUEST .. ":" .. timestamp)
    else
        self:Debug("sync", "Same timestamp, no action needed")
    end
end

-- Handle DATA_REQUEST command
function TWRA:HandleDataRequestCommand(args, sender)
    self:Debug("sync", "Processing DATA_REQUEST command from " .. sender)
    
    -- Parse the requested timestamp
    local requestedTimestamp = tonumber(args)
    if not requestedTimestamp then 
        self:Debug("error", "Invalid timestamp in DATA_REQUEST")
        return 
    end
    
    local ourTimestamp = TWRA_SavedVariables.assignments and TWRA_SavedVariables.assignments.timestamp or 0
    
    -- Only respond if we have the requested version and have source data
    if requestedTimestamp == ourTimestamp and TWRA_SavedVariables.assignments and TWRA_SavedVariables.assignments.source then
        -- Add a small random delay (0-1 seconds) to reduce chance of multiple simultaneous responses
        local delay = math.random()
        
        -- Store the fact that we're going to respond
        self.SYNC.pendingResponse = true
        
        -- Wait a moment before sending
        self:ScheduleTimer(function()
            -- Check if someone else already responded
            if not self.SYNC.pendingResponse then
                self:Debug("sync", "Someone else already responded, skipping")
                return
            end
            
            self.SYNC.pendingResponse = false
            
            -- Get the data to send
            local data = TWRA_SavedVariables.assignments.source
            
            self:Debug("sync", "Sending requested data to " .. sender)
            
            -- Use chunk manager to send data
            self:SendDataInChunks(data, requestedTimestamp, self.SYNC.COMMANDS.DATA_RESPONSE, function()
                self:Debug("sync", "Completed sending data to " .. sender)
            end)
            
        end, delay)
    else
        -- Log message for debugging when we can't respond
        if requestedTimestamp ~= ourTimestamp then
            self:Debug("sync", "Can't respond - timestamp mismatch (requested " .. 
                requestedTimestamp .. ", we have " .. ourTimestamp .. ")")
        elseif not TWRA_SavedVariables.assignments then
            self:Debug("sync", "Can't respond - no assignments data")
        elseif not TWRA_SavedVariables.assignments.source then
            self:Debug("sync", "Can't respond - no source data")
        end
    end
end

-- Handle DATA_RESPONSE command
function TWRA:HandleDataResponseCommand(args, sender)
    self:Debug("sync", "Processing DATA_RESPONSE command from " .. sender)
    
    -- Mark that someone has responded (to avoid duplicate responses)
    self.SYNC.pendingResponse = false
    
    -- Check for chunked format
    local parts = self:SplitString(args, ":")
    if table.getn(parts) < 2 then
        self:Debug("error", "Invalid DATA_RESPONSE format")
        return
    end
    
    local timestamp = tonumber(parts[1])
    
    if table.getn(parts) >= 4 then
        -- This is a chunked message - delegate to ChunkManager
        local chunkNum = tonumber(parts[2])
        local totalChunks = tonumber(parts[3])
        
        -- Extract the chunk data (rejoin any parts that might contain colons)
        local chunkData = ""
        for i = 4, table.getn(parts) do
            if i > 4 then chunkData = chunkData .. ":" end
            chunkData = chunkData .. parts[i]
        end
        
        -- Process the chunk and check if all chunks are received
        local completeData = self:ProcessChunk(
            self.SYNC.COMMANDS.DATA_RESPONSE, 
            timestamp, 
            chunkNum, 
            totalChunks, 
            chunkData, 
            sender
        )
        
        -- If we have the complete data, process it
        if completeData then
            self:ProcessCompleteData(completeData, timestamp, sender)
        end
    else
        -- Single part message - process directly
        local data = parts[2]
        
        -- For single chunks, show 100% progress briefly
        self:ShowSyncProgress(100, sender, 1, 1)
        
        -- Process the data using the function in DataProcessing.lua
        self:ProcessCompleteData(data, timestamp, sender)
        
        -- Hide progress after a short delay
        self:ScheduleTimer(function()
            self:HideSyncProgress()
        end, 0.5)
    end
end

-- Broadcast section change to group
function TWRA:SyncSectionChange(sectionIndex, sectionName)
    -- Skip if live sync is disabled or we're not in a group
    if not self.SYNC.liveSync then 
        self:Debug("sync", "Live sync disabled - not broadcasting section")
        return 
    end
    
    -- Skip if we're not in a group
    if GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 then
        self:Debug("sync", "Not in a group - not broadcasting section")
        return
    end
    
    -- Skip if we don't have assignments data
    if not TWRA_SavedVariables.assignments or not TWRA_SavedVariables.assignments.timestamp then
        self:Debug("sync", "No assignments data - not broadcasting section") 
        return
    end
    
    -- Build and send section message
    local sectionMsg = string.format(
        self.MESSAGE_FORMATS.SECTION, 
        self.SYNC.COMMANDS.SECTION,
        TWRA_SavedVariables.assignments.timestamp,
        sectionName,
        sectionIndex
    )
    
    self:Debug("sync", "Broadcasting section change: " .. sectionName .. " (index " .. sectionIndex .. ")")
    
    self:SendAddonMessage(sectionMsg)
end

TWRA:Debug("sync", "SyncHandlers module loaded")