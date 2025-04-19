-- Sync functionality for TWRA
TWRA = TWRA or {}

-- Setup initial SYNC module properties
TWRA.SYNC = TWRA.SYNC or {}
TWRA.SYNC.PREFIX = "TWRA" -- Addon message prefix
TWRA.SYNC.liveSync = false -- Live sync enabled
TWRA.SYNC.tankSync = false -- Tank sync enabled
TWRA.SYNC.pendingSection = nil -- Section to navigate to after sync
TWRA.SYNC.lastRequestTime = 0 -- When we last requested data
TWRA.SYNC.requestTimeout = 5 -- Seconds to wait between requests
TWRA.SYNC.monitorMessages = false -- Monitor all addon messages
TWRA.SYNC.justActivated = false -- Keep for backward compatibility
TWRA.SYNC.sectionChangeHandlerRegistered = false -- Section change handler registration flag

-- Command constants for addon messages
TWRA.SYNC.COMMANDS = {
    VERSION = "VERSION",     -- For version checking
    SECTION = "SECTION",     -- For live section updates
    DATA_REQUEST = "DREQ",   -- Request full data
    DATA_RESPONSE = "DRES",  -- Send full data
    ANNOUNCE = "ANC"         -- Announce new import
}

-- Function to register all sync-related events
function TWRA:RegisterSyncEvents()
    self:Debug("sync", "Registering sync events")
    
    -- Create a hook into OnLoad to ensure initialization happens
    local originalOnLoad = self.OnLoad
    self.OnLoad = function(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
        -- Call the original OnLoad function
        if originalOnLoad then
            originalOnLoad(self, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
        end
        
        -- Schedule sync initialization after a short delay
        self:ScheduleTimer(function()
            self:Debug("sync", "Running InitializeSync from OnLoad hook")
            self:InitializeSync()
        end, 0.5)
    end
    
    -- Add hook to ensure initialization during PLAYER_ENTERING_WORLD
    local originalOnEvent = self.OnEvent
    if originalOnEvent then
        self.OnEvent = function(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
            -- Call the original event handler
            originalOnEvent(self, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
            
            -- Additional initialization for sync during PLAYER_ENTERING_WORLD
            if event == "PLAYER_ENTERING_WORLD" then
                self:ScheduleTimer(function()
                    if not self.SYNC.initialized then
                        self:Debug("sync", "Initializing sync from PLAYER_ENTERING_WORLD")
                        self:InitializeSync()
                    end
                end, 0.2)
            end
        end
    end
end

-- Function to check if Live Sync should be active based on saved settings
function TWRA:CheckAndActivateLiveSync()
    -- Read from saved variables
    if TWRA_SavedVariables and TWRA_SavedVariables.options and TWRA_SavedVariables.options.liveSync then
        -- Only activate if not already active
        if not self.SYNC.liveSync then
            self:Debug("sync", "Auto-activating Live Sync from saved settings")
            self:ActivateLiveSync()
        end
    else
        self:Debug("sync", "Live Sync not enabled in settings")
    end
end

-- Function to activate Live Sync on initialization or UI reload
function TWRA:ActivateLiveSync()
    -- Set liveSync to true when activating
    self.SYNC.liveSync = true
    
    -- Register for addon communication messages
    local frame = getglobal("TWRAEventFrame")
    if frame then
        frame:RegisterEvent("CHAT_MSG_ADDON")
        self:Debug("sync", "Registered for CHAT_MSG_ADDON events")
    else
        self:Debug("error", "Could not find event frame to register events")
        -- Even without the frame, we'll try to continue
    end
    
    -- Make sure section change handler is registered (only registers once)
    self:RegisterSectionChangeHandler()
    
    -- Enable message handling
    self:Debug("sync", "Live Sync fully activated")
    
    -- Ensure the option is saved in saved variables
    if TWRA_SavedVariables then
        if not TWRA_SavedVariables.options then 
            TWRA_SavedVariables.options = {} 
        end
        TWRA_SavedVariables.options.liveSync = true
    end
    
    -- If we're in Options, update the checkbox
    if TWRA.UI and TWRA.UI.OptionsFrame and TWRA.UI.OptionsFrame.liveSyncCheckbox then
        TWRA.UI.OptionsFrame.liveSyncCheckbox:SetChecked(true)
    end
    
    return true
end

-- Function to deactivate Live Sync
function TWRA:DeactivateLiveSync()
    -- Set inactive state
    self.SYNC.liveSync = false
    
    -- Unregister addon communication
    -- Instead of checking IsEventRegistered, we'll just unregister if we need to
    local frame = getglobal("TWRAEventFrame")
    if frame and not self.needsAddonComm then
        frame:UnregisterEvent("CHAT_MSG_ADDON")
        self:Debug("sync", "Unregistered from CHAT_MSG_ADDON events")
    end
    
    -- Update saved variables
    if TWRA_SavedVariables and TWRA_SavedVariables.options then
        TWRA_SavedVariables.options.liveSync = false
    end
    
    self:Debug("sync", "Live Sync deactivated")
    return true
end

-- Enhanced BroadcastSectionChange function with timestamp support
function TWRA:BroadcastSectionChange(sectionIndex, timestamp)
    -- Use provided timestamp or get current timestamp
    local timeToSync = timestamp or 0
    if not timeToSync or timeToSync == 0 then
        if TWRA_Assignments and TWRA_Assignments.timestamp then
            timeToSync = TWRA_Assignments.timestamp
        else
            timeToSync = GetTime()
        end
    end
    
    -- Skip if not in a group
    if GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 then
        self:Debug("sync", "Not broadcasting section change - not in a group")
        return false
    end
    
    self:Debug("sync", "Broadcasting section change to index " .. tostring(sectionIndex) .. " with timestamp " .. tostring(timeToSync))
    
    -- Format and send the message using proper command format
    -- Send both section index and timestamp
    local message = self.SYNC.COMMANDS.SECTION .. ":" .. sectionIndex .. ":" .. timeToSync
    return self:SendAddonMessage(message, "RAID")
end

-- Process incoming addon communication messages with reduced debugging spam
function TWRA:OnChatMsgAddon(prefix, message, distribution, sender)
    -- Only debug if it's our addon prefix or message monitoring is enabled
    local isOurPrefix = (prefix == self.SYNC.PREFIX)
    
    -- Skip detailed debugging for non-TWRA messages unless monitoring is enabled
    if not isOurPrefix and not self.SYNC.monitorMessages then
        return
    end
    
    -- Global message monitoring for debugging - keep this
    if self.SYNC.monitorMessages then
        -- Display all addon messages in a more visible way
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF00FF[ADDON MSG]|r |cFF33FF33" .. 
            prefix .. "|r from |cFF33FFFF" .. sender .. "|r: |cFFFFFFFF" .. message .. "|r")
    end
    
    -- If not our prefix, we're done
    if not isOurPrefix then return end
    
    -- Skip our own messages
    if sender == UnitName("player") then 
        self:Debug("sync", "Ignoring own message: " .. message)
        return 
    end
    
    -- Forward to our message handler - reduced debug output here
    if self.HandleAddonMessage then
        -- Only show detailed debug for our own prefix
        self:HandleAddonMessage(message, distribution, sender)
    else
        self:Debug("error", "HandleAddonMessage function not available")
    end
end

-- Helper function to send addon messages
function TWRA:SendAddonMessage(message, channel)
    -- Default to RAID if in raid, otherwise PARTY
    if not channel then
        channel = GetNumRaidMembers() > 0 and "RAID" or 
                 (GetNumPartyMembers() > 0 and "PARTY" or nil)
    end
    
    -- Exit if not in a group and no channel specified
    if not channel then
        self:Debug("sync", "Cannot send addon message - not in a group")
        return false
    end
    
    -- Log outgoing message if monitoring is enabled
    if self.SYNC.monitorMessages then
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF00FF[ADDON SEND]|r |cFFFFFF00" .. 
            self.SYNC.PREFIX .. "|r to |cFF33FFFF" .. channel .. "|r: |cFFFFFFFF" .. message .. "|r")
    end
    
    -- Send the message
    SendAddonMessage(self.SYNC.PREFIX, message, channel)
    return true
end

-- Send data response to group
function TWRA:SendDataResponse(encodedData, timestamp)
    if not encodedData or encodedData == "" then
        self:Debug("error", "No data to send in response - source string is empty")
        return false
    end
    
    -- Debug the data we're about to send
    self:Debug("sync", "Preparing to send data response with timestamp: " .. timestamp)
    self:Debug("sync", "Data length: " .. string.len(encodedData) .. " characters")
    
    -- Ensure proper Base64 padding before sending
    local dataLen = string.len(encodedData)
    local remainder = dataLen - (math.floor(dataLen / 4) * 4)
    while remainder > 0 and remainder < 4 do
        encodedData = encodedData .. "="
        remainder = remainder + 1
        self:Debug("sync", "Added padding character to Base64 data")
    end
    
    -- Check if data needs to be chunked
    local maxMsgSize = 2000  -- Increased from 200 to maximize efficiency (close to WoW's 2042 limit)
    
    if string.len(encodedData) > maxMsgSize then
        -- Use chunk manager if available
        if self.chunkManager then
            self:Debug("sync", "Using chunk manager for large data response")
            
            -- Use proper prefix format for the chunk manager
            local prefix = string.format("%s:%d:", 
                self.SYNC.COMMANDS.DATA_RESPONSE,
                timestamp)
                
            -- Call the chunk manager's function directly
            self.chunkManager:SendChunkedMessage(encodedData, prefix)
            return true
        else
            self:Debug("sync", "Chunk manager not available, using fallback chunking")
            -- Fallback to basic chunking
            local message = string.format("%s:%d:CHUNKED:%d", 
                self.SYNC.COMMANDS.DATA_RESPONSE,
                timestamp,
                string.len(encodedData))
                
            self:SendAddonMessage(message)
            
            -- Break into simple chunks with basic numbering
            local position = 1
            local chunkSize = 1900  -- Increased from 180 to match ChunkManager's size
            local chunkNum = 1
            local totalChunks = math.ceil(string.len(encodedData) / chunkSize)
            
            self:Debug("sync", "Sending data in " .. totalChunks .. " chunks")
            
            -- Use scheduled timers to send chunks with delay
            while position <= string.len(encodedData) do
                local endPos = math.min(position + chunkSize - 1, string.len(encodedData))
                local chunk = string.sub(encodedData, position, endPos)
                
                -- Use closure to capture current values
                local currentChunk = chunk
                local currentChunkNum = chunkNum
                
                -- Schedule sends with increasing delay
                self:ScheduleTimer(function()
                    local chunkMessage = string.format("%s:%d:CHUNK:%d:%d:%s", 
                        self.SYNC.COMMANDS.DATA_RESPONSE,
                        timestamp,
                        currentChunkNum,
                        totalChunks,
                        currentChunk)
                    
                    self:SendAddonMessage(chunkMessage)
                    self:Debug("sync", "Sent chunk " .. currentChunkNum .. "/" .. totalChunks)
                end, (chunkNum - 1) * 0.2)
                
                position = endPos + 1
                chunkNum = chunkNum + 1
            end
            
            return true
        end
    else
        -- Small enough for single message
        local message = string.format("%s:%d:%s", 
            self.SYNC.COMMANDS.DATA_RESPONSE,
            timestamp,
            encodedData)
        
        self:Debug("sync", "Sending data response in single message (size: " .. string.len(message) .. ")")
        return self:SendAddonMessage(message)
    end
end

-- Handle incoming addon messages - this connects to the CHAT_MSG_ADDON event in Core.lua
function TWRA:CHAT_MSG_ADDON(prefix, message, distribution, sender)
    -- Forward to our message handler
    if self.OnChatMsgAddon then
        self:OnChatMsgAddon(prefix, message, distribution, sender)
    end
end

-- Function to toggle message monitoring
function TWRA:ToggleMessageMonitoring(enable)
    if enable ~= nil then
        self.SYNC.monitorMessages = enable
    else
        self.SYNC.monitorMessages = not self.SYNC.monitorMessages
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("TWRA Sync Message Monitoring: " .. 
        (self.SYNC.monitorMessages and "|cFF00FF00ENABLED|r" or "|cFFFF0000DISABLED|r"))
end

-- Handle group composition changes
function TWRA:OnGroupChanged()
    self:Debug("sync", "Group composition changed")
    TWRA:UpdatePlayerTable()
    -- Check if we went from solo to group (might want to activate sync)
    local inGroup = (GetNumRaidMembers() > 0 or GetNumPartyMembers() > 0)
    
    -- Always refresh player information when group changes as 
    -- assignments might be group-dependent
    if self.RefreshPlayerInfo then
        self:Debug("data", "Refreshing player info after group composition change")
        self:RefreshPlayerInfo()
    else
        self:Debug("error", "RefreshPlayerInfo function not available")
    end
    
    -- Additional sync-related logic
    if inGroup and self.SYNC.liveSync then
        -- We joined a group and sync is enabled, make sure it's active
        self:Debug("sync", "Joined a group with sync enabled")
        self:ActivateLiveSync()
    elseif not inGroup then
        -- We left all groups, could consider deactivating sync
        -- Not auto-deactivating for now, as the user might join another group soon
    end
end

-- Debug function to show sync status information
function TWRA:ShowSyncStatus()
    DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA Sync Status:|r")
    DEFAULT_CHAT_FRAME:AddMessage("  Live Sync: " .. (self.SYNC.liveSync and "|cFF00FF00ENABLED|r" or "|cFFFF0000DISABLED|r"))
    DEFAULT_CHAT_FRAME:AddMessage("  Tank Sync: " .. (self.SYNC.tankSync and "|cFF00FF00ENABLED|r" or "|cFFFF0000DISABLED|r"))
    DEFAULT_CHAT_FRAME:AddMessage("  Message Monitoring: " .. (self.SYNC.monitorMessages and "|cFF00FF00ENABLED|r" or "|cFFFF0000DISABLED|r"))
    DEFAULT_CHAT_FRAME:AddMessage("  Prefix: " .. self.SYNC.PREFIX)
    
    -- Check event registration
    local frame = getglobal("TWRAEventFrame")
    local isRegistered = frame and frame:IsEventRegistered("CHAT_MSG_ADDON")
    DEFAULT_CHAT_FRAME:AddMessage("  Event Registration: " .. (isRegistered and "|cFF00FF00REGISTERED|r" or "|cFFFF0000NOT REGISTERED|r"))
    
    -- Show group status
    local inRaid = GetNumRaidMembers() > 0
    local inParty = GetNumPartyMembers() > 0
    local groupSize = inRaid and GetNumRaidMembers() or (inParty and GetNumPartyMembers() or 0)
    DEFAULT_CHAT_FRAME:AddMessage("  Group Status: " .. (inRaid and "RAID (" .. groupSize .. " members)" or (inParty and "PARTY (" .. groupSize .. " members)" or "NOT IN GROUP")))

    -- Check command handlers
    DEFAULT_CHAT_FRAME:AddMessage("  Command Handlers:")
    DEFAULT_CHAT_FRAME:AddMessage("    Section: " .. (self.HandleSectionCommand and "|cFF00FF00AVAILABLE|r" or "|cFFFF0000MISSING|r"))
    DEFAULT_CHAT_FRAME:AddMessage("    Announce: " .. (self.HandleAnnounceCommand and "|cFF00FF00AVAILABLE|r" or "|cFFFF0000MISSING|r"))
    DEFAULT_CHAT_FRAME:AddMessage("    Data Request: " .. (self.HandleDataRequestCommand and "|cFF00FF00AVAILABLE|r" or "|cFFFF0000MISSING|r"))
    DEFAULT_CHAT_FRAME:AddMessage("    Data Response: " .. (self.HandleDataResponseCommand and "|cFF00FF00AVAILABLE|r" or "|cFFFF0000MISSING|r"))
    
    DEFAULT_CHAT_FRAME:AddMessage("  Activation Commands:")
    DEFAULT_CHAT_FRAME:AddMessage("    /twra debug sync - Show this status")
    DEFAULT_CHAT_FRAME:AddMessage("    /twra syncmon - Toggle message monitoring")
end

-- Register with ADDON_LOADED to initialize sync
function TWRA:InitializeSync()
    self:Debug("sync", "Initializing sync module")
    
    -- Check saved variables for sync settings
    if TWRA_SavedVariables and TWRA_SavedVariables.options then
        -- Update runtime values with saved settings - use boolean conversion for consistency
        self.SYNC.liveSync = (TWRA_SavedVariables.options.liveSync == true)
        self.SYNC.tankSync = (TWRA_SavedVariables.options.tankSync == true)
        
        self:Debug("sync", "Sync settings loaded from saved variables: LiveSync=" .. 
                  tostring(self.SYNC.liveSync) .. ", TankSync=" .. 
                  tostring(self.SYNC.tankSync))
        
        -- Automatically activate if enabled in settings
        if self.SYNC.liveSync then
            self:Debug("sync", "LiveSync is enabled in settings, activating now")
            self:ActivateLiveSync()
            
            -- Also activate tank sync if enabled
            if self.SYNC.tankSync and self.InitializeTankSync then
                self:Debug("tank", "TankSync is enabled, initializing")
                self:InitializeTankSync()
            end
        else
            self:Debug("sync", "LiveSync is disabled in settings")
        end
    else
        self:Debug("sync", "No saved sync settings found")
    end
    
    -- Mark as initialized to prevent duplicate initialization
    self.SYNC.initialized = true
    
    -- Register the syncmon slash command
    SLASH_SYNCMON1 = "/syncmon"
    SlashCmdList["SYNCMON"] = function(msg)
        TWRA:ToggleMessageMonitoring()
    end
    
    self:Debug("sync", "Registered /syncmon command")
    
    -- Register our section change handler
    self:RegisterSectionChangeHandler()
end

-- Function to request data sync from group members
function TWRA:RequestDataSync(timestamp)
    -- Throttle requests to prevent spam
    local now = GetTime()
    if now - self.SYNC.lastRequestTime < self.SYNC.requestTimeout then
        self:Debug("sync", "Data request throttled - too soon since last request")
        return false
    end
    
    -- Update last request time
    self.SYNC.lastRequestTime = now
    
    -- Check if we're in a group
    if GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 then
        self:Debug("sync", "Not in a group, skipping data request")
        return false
    end
    
    -- Make sure we have a valid timestamp to request
    -- IMPORTANT: We are requesting the timestamp passed to us, NOT our own timestamp
    -- This is because we want data matching that specific timestamp
    if not timestamp or timestamp == 0 then
        self:Debug("sync", "No specific timestamp provided, using our current timestamp")
        if TWRA_Assignments and TWRA_Assignments.timestamp then
            timestamp = TWRA_Assignments.timestamp
        else
            timestamp = 0
        end
    end
    
    -- Debug timestamp information clearly
    self:Debug("sync", "RequestDataSync: Requesting timestamp " .. timestamp .. 
               ", Our timestamp: " .. (TWRA_Assignments and TWRA_Assignments.timestamp or 0))
    
    -- Create the request message
    local message = string.format("%s:%d", 
        self.SYNC.COMMANDS.DATA_REQUEST,
        timestamp)
    
    -- Send the request
    self:SendAddonMessage(message)
    self:Debug("sync", "Requested data sync with timestamp " .. timestamp)
    
    -- Show a message to the user
    DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA:|r Requesting raid assignments from group...")
    
    return true
end

-- Function to announce when new data has been imported
function TWRA:AnnounceDataImport()
    -- Check if we're in a group
    if GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 then
        self:Debug("sync", "Not in a group, skipping import announcement")
        return false
    end
    
    -- Get current timestamp
    local timestamp = 0
    if TWRA_Assignments then
        timestamp = TWRA_Assignments.timestamp or 0
    end
    
    -- Create the announce message
    local message = string.format("%s:%d:%s", 
        self.SYNC.COMMANDS.ANNOUNCE,
        timestamp,
        UnitName("player"))
    
    -- Add debug for monitoring
    self:Debug("sync", "Announcing data import: timestamp=" .. timestamp)
    
    -- Send the announcement
    self:SendAddonMessage(message)
    
    return true
end

-- Function to handle section changes for sync
function TWRA:RegisterSectionChangeHandler()
    self:Debug("sync", "Registering section change handler (only registers once)")
    
    -- Check if we've already registered to avoid duplicate handlers
    if self.SYNC.sectionChangeHandlerRegistered then
        self:Debug("sync", "Section change handler already registered, skipping")
        return
    end
    
    -- Register for the SECTION_CHANGED message
    self:RegisterEvent("SECTION_CHANGED", function(sectionName, sectionIndex, numSections, context)
        -- Always log that we received the event regardless of LiveSync status
        self:Debug("sync", "SECTION_CHANGED event received: " .. tostring(sectionName) .. 
                  " (" .. tostring(sectionIndex) .. "), liveSync=" .. tostring(self.SYNC.liveSync))
        
        -- Don't broadcast if live sync is not enabled
        if not self.SYNC.liveSync then
            self:Debug("sync", "Skipping section broadcast - LiveSync not enabled")
            return
        end
        
        -- Skip if the context indicates we should suppress sync
        if context then
            self:Debug("sync", "Skipping section broadcast - suppressSync flag is set")
            return
        end
        
        -- Get current section directly from TWRA_Assignments
        if not TWRA_Assignments or not TWRA_Assignments.currentSection then
            self:Debug("error", "Cannot broadcast section - TWRA_Assignments.currentSection is not set")
            return
        end
        
        -- Get timestamp for sync
        local timestamp = TWRA_Assignments.timestamp
        
        -- Broadcast section change with the current section from assignments
        self:Debug("sync", "Broadcasting section change with index: " .. TWRA_Assignments.currentSection)
        self:BroadcastSectionChange(TWRA_Assignments.currentSection, timestamp)
    end)
    
    -- Mark as registered
    self.SYNC.sectionChangeHandlerRegistered = true
    self:Debug("sync", "Section change handler registered")
end

-- Function to handle data requests and route them to the appropriate handler
function TWRA:HandleDataRequestCommand(message, sender)
    -- Parse timestamp from message format "DREQ:timestamp"
    local timestamp = tonumber(string.sub(message, 6)) or 0
    
    self:Debug("sync", "Data request from " .. sender .. " for timestamp " .. timestamp)
    
    -- If we don't have any saved assignments, exit early
    if not TWRA_Assignments or not TWRA_Assignments.data then
        self:Debug("sync", "No data to send to " .. sender)
        return
    end
    
    -- Compare our timestamp with the requested one
    local ourTimestamp = TWRA_Assignments.timestamp or 0
    
    -- Send our data if it matches or is newer
    if ourTimestamp >= timestamp then
        self:Debug("sync", "Our data matches or is newer, preparing response")
        
        -- Get compressed data to send
        local compressedData = nil
        
        -- Try to get from dedicated compressed storage first
        if TWRA_CompressedAssignments and TWRA_CompressedAssignments.data then
            compressedData = TWRA_CompressedAssignments.data
            self:Debug("sync", "Using stored compressed data")
        else
            -- Try to generate compressed data
            if self.GetStoredCompressedData then
                compressedData = self:GetStoredCompressedData()
                self:Debug("sync", "Generated compressed data using GetStoredCompressedData")
            elseif self.CompressAssignmentsData then
                -- Prepare sync data
                local syncData = nil
                if self.PrepareDataForSync then
                    syncData = self:PrepareDataForSync(TWRA_Assignments)
                else
                    syncData = TWRA_Assignments
                end
                
                -- Compress the data
                compressedData = self:CompressAssignmentsData(syncData)
                self:Debug("sync", "Compressed data on-demand")
            end
        end
        
        -- Send the data if we have it
        if compressedData then
            self:Debug("sync", "Sending data to " .. sender .. " with timestamp " .. ourTimestamp)
            self:SendDataResponse(compressedData, ourTimestamp)
        else
            self:Debug("error", "Failed to compress data for " .. sender)
        end
    else
        self:Debug("sync", "Our data is older than requested, not sending")
    end
end

-- Execute registration of sync events immediately
TWRA:RegisterSyncEvents()

-- Force initialization after 1 second to handle any load order issues
TWRA:ScheduleTimer(function()
    if not TWRA.SYNC.initialized then
        TWRA:Debug("sync", "Forcing sync initialization via timer")
        TWRA:InitializeSync()
    end
end, 1)