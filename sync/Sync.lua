-- Sync functionality for TWRA
TWRA = TWRA or {}

-- Setup initial SYNC module properties
TWRA.SYNC = TWRA.SYNC or {}
TWRA.SYNC.PREFIX = "TWRA" -- Addon message prefix
TWRA.SYNC.liveSync = false -- Live sync enabled
TWRA.SYNC.tankSync = false -- Tank sync enabled
TWRA.SYNC.pendingSection = nil -- Section to navigate to after sync
TWRA.SYNC.pendingSource = nil -- When sync handlers navigate they set this to fromSync to supress further sync messages
TWRA.SYNC.lastRequestTime = 0 -- When we last requested data
TWRA.SYNC.requestTimeout = 5 -- Seconds to wait between requests
TWRA.SYNC.monitorMessages = false -- Monitor all addon messages
TWRA.SYNC.justActivated = false -- Keep for backward compatibility
TWRA.SYNC.sectionChangeHandlerRegistered = false -- Section change handler registration flag

-- Command constants for addon messages
TWRA.SYNC.COMMANDS = {
    VERSION = "VER",        -- For version checking
    SECTION = "SECTION",    -- For live section updates
    BULK_SECTION = "BSEC",  -- Bulk section transmission without processing
    BULK_STRUCTURE = "BSTR", -- Final structure transmission in bulk mode
    MISS_SEC_REQ = "MSREQ", -- Request for missing sections
    MISS_SEC_ACK = "MSACK", -- Acknowledge handling missing section request
    MISS_SEC_RESP = "MSRES", -- Response with missing section data
    BULK_SYNC_REQ = "BSREQ", -- Request for complete bulk sync
    BULK_SYNC_ACK = "BSACK"  -- Acknowledge handling bulk sync request
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

    -- Register for the CHAT_MSG_WHISPER event to handle whispered sync commands
    local frame = getglobal("TWRAEventFrame")
    if frame then
        frame:RegisterEvent("CHAT_MSG_WHISPER")
        self:Debug("sync", "Registered for CHAT_MSG_WHISPER events")
    else
        self:Debug("error", "Could not find event frame to register whisper events")
    end

    -- Immediately register for the SECTION_CHANGED event
    -- This ensures we're registered even if InitializeSync hasn't run yet
    self:RegisterSectionChangeHandler()
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
    
    -- Note: We're not registering for SECTION_CHANGED here anymore since it's
    -- done in InitializeSync regardless of sync settings
    
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

-- Message Generation Functions for each command type

-- Function to create a section change message (SECTION)
function TWRA:CreateSectionMessage(timestamp, sectionIndex)
    return self.SYNC.COMMANDS.SECTION .. ":" .. timestamp .. ":" .. sectionIndex
end

-- Function to create a bulk section message (BSEC)
function TWRA:CreateBulkSectionMessage(timestamp, sectionIndex, sectionData)
    return self.SYNC.COMMANDS.BULK_SECTION .. ":" .. timestamp .. ":" .. sectionIndex .. ":" .. sectionData
end

-- Function to create a bulk structure message (BSTR)
function TWRA:CreateBulkStructureMessage(timestamp, structureData)
    return self.SYNC.COMMANDS.BULK_STRUCTURE .. ":" .. timestamp .. ":" .. structureData
end

-- Function to create a version message (VER)
function TWRA:CreateVersionMessage(version)
    return self.SYNC.COMMANDS.VERSION .. ":" .. version
end

-- Function to create a missing sections request message (MSREQ)
function TWRA:CreateMissingSectionsRequestMessage(timestamp, sectionList, originalSender)
    -- sectionList should be a comma-separated list of section indices
    return self.SYNC.COMMANDS.MISS_SEC_REQ .. ":" .. timestamp .. ":" .. sectionList .. ":" .. (originalSender or "")
end

-- Function to create a missing sections acknowledgment message (MSACK)
function TWRA:CreateMissingSectionsAckMessage(timestamp, sectionList, requester)
    return self.SYNC.COMMANDS.MISS_SEC_ACK .. ":" .. timestamp .. ":" .. sectionList .. ":" .. requester
end

-- Function to create a missing section response message (MSRES)
function TWRA:CreateMissingSectionResponseMessage(timestamp, sectionIndex, sectionData)
    return self.SYNC.COMMANDS.MISS_SEC_RESP .. ":" .. timestamp .. ":" .. sectionIndex .. ":" .. sectionData
end

-- Function to create a bulk sync request message (BSREQ)
function TWRA:CreateBulkSyncRequestMessage()
    -- No timestamp needed in the request
    return self.SYNC.COMMANDS.BULK_SYNC_REQ
end

-- Function to create a bulk sync acknowledgment message (BSACK)
function TWRA:CreateBulkSyncAckMessage(timestamp, sender)
    -- Include the timestamp in the acknowledgment
    return self.SYNC.COMMANDS.BULK_SYNC_ACK .. ":" .. timestamp .. ":" .. sender
end

-- Compare timestamps and return relationship between them
-- Returns: 
--   1 if local timestamp is newer
--   0 if timestamps are equal
--   -1 if remote timestamp is newer
function TWRA:CompareTimestamps(localTimestamp, remoteTimestamp)
    -- Handle nil values
    localTimestamp = tonumber(localTimestamp) or 0
    remoteTimestamp = tonumber(remoteTimestamp) or 0
    
    -- Compare and return result
    if localTimestamp > remoteTimestamp then
        return 1       -- Local is newer
    elseif localTimestamp < remoteTimestamp then
        return -1      -- Remote is newer
    else
        return 0       -- Equal timestamps
    end
end

-- Request structure from other raid members
-- @param timestamp (optional) Timestamp to use in the structure request
-- @return boolean Success flag
function TWRA:RequestStructureSync(timestamp)
    -- Throttle requests to prevent spam
    local now = GetTime()
    if now - self.SYNC.lastRequestTime < self.SYNC.requestTimeout then
        self:Debug("sync", "Structure request throttled - too soon since last request")
        return false
    end
    
    -- Update last request time
    self.SYNC.lastRequestTime = now
    
    -- Check if we're in a group
    if GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 then
        self:Debug("sync", "Not in a group, skipping structure request")
        return false
    end
    
    -- Make sure we have a valid timestamp to request
    if not timestamp or timestamp == 0 then
        self:Debug("sync", "No specific timestamp provided, using our current timestamp")
        if TWRA_Assignments and TWRA_Assignments.timestamp then
            timestamp = TWRA_Assignments.timestamp
        else
            timestamp = GetTime()
        end
    end
    
    -- Create the request message using our generator
    local message = self:CreateStructureRequestMessage(timestamp)
    
    -- Send the request
    self:SendAddonMessage(message)
    self:Debug("sync", "Requested structure sync with timestamp " .. timestamp)
    
    -- Show a message to the user
    self:Debug("sync", "Requesting raid structure from group...")
    
    return true
end

-- Function to request a complete bulk sync from anyone with complete data
function TWRA:RequestBulkSync()
    self:Debug("sync", "Requesting complete bulk sync from anyone with complete data")
    
    -- Throttle requests to prevent spam
    local now = GetTime()
    if now - self.SYNC.lastRequestTime < self.SYNC.requestTimeout then
        self:Debug("sync", "Bulk sync request throttled - too soon since last request")
        return false
    end
    
    -- Update last request time
    self.SYNC.lastRequestTime = now
    
    -- Check if we're in a group
    if GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 then
        self:Debug("sync", "Not in a group, skipping bulk sync request")
        return false
    end
    
    -- IMPORTANT: Reset any existing sync state
    if self.SYNC.syncInProgress then
        self:Debug("sync", "Clearing existing syncInProgress flag before requesting new sync")
        self.SYNC.syncInProgress = false
    end
    
    -- Reset any other sync variables to prevent stale state
    self.SYNC.newerTimestampResponded = nil
    self.SYNC.pendingBulkResponse = nil
    
    -- Create the request message (no timestamp needed)
    local message = self:CreateBulkSyncRequestMessage()
    
    -- Send the request to the group
    local success = self:SendAddonMessage(message)
    
    if success then
        -- Start a timeout timer to report if we don't get a response
        if self.SYNC.bulkSyncRequestTimeout then
            self:CancelTimer(self.SYNC.bulkSyncRequestTimeout)
        end
        
        self.SYNC.bulkSyncRequestTimeout = self:ScheduleTimer(function()
            self:Debug("sync", "No response to bulk sync request after timeout period")
            -- Also reset the sync state if timeout occurs
            self.SYNC.syncInProgress = false
        end, 10) -- 10 second timeout
        
        -- Clear any previous tracking of acknowledgments
        self.SYNC.bulkSyncAcknowledgments = {}
        
        self:Debug("sync", "Sent bulk sync request to group")
    else
        self:Debug("error", "Failed to send bulk sync request")
    end
    
    return success
end

-- Enhanced BroadcastSectionChange function using the message generator
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
    
    self:Debug("sync", "Broadcasting section change with index: " .. tostring(sectionIndex))
    
    -- Create and send the message using our generator
    local message = self:CreateSectionMessage(timeToSync, sectionIndex)
    return self:SendAddonMessage(message)
end

-- Process incoming addon communication messages with optimized self-message handling
function TWRA:OnChatMsgAddon(prefix, message, distribution, sender)
    -- OPTIMIZATION: Skip our own messages immediately without any processing
    if sender == UnitName("player") then
        -- Avoid even debug logging for our own messages to eliminate processing overhead
        return
    end
    
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
    
    -- Forward to our message handler - reduced debug output here
    if self.HandleAddonMessage then
        -- Only show detailed debug for our own prefix
        self:HandleAddonMessage(message, distribution, sender)
    else
        self:Debug("error", "HandleAddonMessage function not available")
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
    DEFAULT_CHAT_FRAME:AddMessage("    Structure Request: " .. (self.HandleStructureRequestCommand and "|cFF00FF00AVAILABLE|r" or "|cFFFF0000MISSING|r"))
    DEFAULT_CHAT_FRAME:AddMessage("    Structure Response: " .. (self.HandleStructureResponseCommand and "|cFF00FF00AVAILABLE|r" or "|cFFFF0000MISSING|r"))
    DEFAULT_CHAT_FRAME:AddMessage("    Section Request: " .. (self.HandleSectionRequestCommand and "|cFF00FF00AVAILABLE|r" or "|cFFFF0000MISSING|r"))
    DEFAULT_CHAT_FRAME:AddMessage("    Section Response: " .. (self.HandleSectionResponseCommand and "|cFF00FF00AVAILABLE|r" or "|cFFFF0000MISSING|r"))
    
    DEFAULT_CHAT_FRAME:AddMessage("  Activation Commands:")
    DEFAULT_CHAT_FRAME:AddMessage("    /twra debug sync - Show this status")
    DEFAULT_CHAT_FRAME:AddMessage("    /twra syncmon - Toggle message monitoring")
end

-- Register with ADDON_LOADED to initialize sync
function TWRA:InitializeSync()
    self:Debug("sync", "Initializing sync module")
    
    -- Register for SECTION_CHANGED event early, regardless of sync settings
    -- Ensure this is actually called by adding explicit debugging and error checking
    if self.RegisterSectionChangeHandler then
        self:Debug("sync", "Calling RegisterSectionChangeHandler...")
        self:RegisterSectionChangeHandler()
        
        -- Verify registration was successful
        if not self.SYNC.sectionChangeHandlerRegistered then
            self:Debug("error", "Section change handler was not registered properly. Trying again...")
            self:RegisterSectionChangeHandler()
        else
            self:Debug("sync", "Section change handler registered successfully!")
        end
    else
        self:Debug("error", "RegisterSectionChangeHandler function not available!")
    end
    
    -- Check saved variables for sync settings
    if TWRA_SavedVariables and TWRA_SavedVariables.options then
        -- Update runtime values with saved settings - use boolean conversion for consistency
        self.SYNC.liveSync = (TWRA_SavedVariables.options.liveSync == true)
        self.SYNC.tankSync = (TWRA_SavedVariables.options.tankSync == true)
        
        self:Debug("sync", "Sync settings loaded from saved variables: LiveSync=" .. 
                  tostring(self.SYNC.liveSync) .. ", TankSync=" .. 
                  tostring(self.SYNC.tankSync))
        
        -- Only activate automated syncing if enabled
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
    
    self:Debug("sync", "Sync initialization complete")
    
    -- As a safety measure, also register a backup timer to check registration
    self:ScheduleTimer(function()
        if not self.SYNC.sectionChangeHandlerRegistered then
            self:Debug("error", "Section change handler still not registered after initialization. Registering now...")
            self:RegisterSectionChangeHandler()
        end
    end, 5)  -- Check 5 seconds after initialization
end

-- Function to register with CHAT_MSG_ADDON event
function TWRA:CHAT_MSG_ADDON(prefix, message, distribution, sender)
    self:OnChatMsgAddon(prefix, message, distribution, sender)
end

-- Function to send structure data in response to a request
function TWRA:SendStructureResponse(timestamp)
    -- Get the structure data
    local structureData = self:GetCompressedStructure()
    if not structureData then
        self:Debug("error", "No structure data available to send")
        return false
    end
    
    -- Create the response message using our generator
    local message = self:CreateStructureResponseMessage(timestamp, structureData)
    
    -- Check if it needs chunking
    if string.len(message) > 2000 then
        self:Debug("sync", "Structure data too large, using chunk manager")
        if self.chunkManager then
            local prefix = self.SYNC.COMMANDS.STRUCTURE_RESPONSE .. ":" .. timestamp .. ":"
            self.chunkManager:SendChunkedMessage(structureData, prefix)
            return true
        else
            self:Debug("error", "Chunk manager not available for large structure data")
            return false
        end
    else
        -- Send the message
        return self:SendAddonMessage(message)
    end
end

-- Function to send section data in response to a request
function TWRA:SendSectionResponse(sectionIndex, timestamp)
    -- Get the section data
    local sectionData = TWRA_CompressedAssignments.sections[sectionIndex]
    if not sectionData then
        self:Debug("error", "No data available for section " .. sectionIndex)
        return false
    end
    
    -- Create the response message using our generator
    local message = self:CreateSectionResponseMessage(timestamp, sectionIndex, sectionData)
    
    -- Check if it needs chunking
    if string.len(message) > 2000 then
        self:Debug("sync", "Section data too large, using chunk manager")
        if self.chunkManager then
            local prefix = self.SYNC.COMMANDS.SECTION_RESPONSE .. ":" .. timestamp .. ":" .. sectionIndex .. ":"
            self.chunkManager:SendChunkedMessage(sectionData, prefix)
            return true
        else
            self:Debug("error", "Chunk manager not available for large section data")
            return false
        end
    else
        -- Send the message
        return self:SendAddonMessage(message)
    end
end

-- Queue section response with collapse system
function TWRA:QueueSectionResponse(sectionIndex, timestamp, requestingPlayer)
    -- Check if we already have a pending response for this section
    if self.SYNC.pendingSectionResponses and self.SYNC.pendingSectionResponses[sectionIndex] then
        self:Debug("sync", "Already have a pending response for section " .. sectionIndex .. ", adding requester to list")
        
        -- Add this requester to the list
        self.SYNC.sectionRequesters = self.SYNC.sectionRequesters or {}
        self.SYNC.sectionRequesters[sectionIndex] = self.SYNC.sectionRequesters[sectionIndex] or {}
        self.SYNC.sectionRequesters[sectionIndex][requestingPlayer] = true
        return
    end
    
    -- Calculate a random delay between 0.1 and 0.5 seconds
    local responseDelay = 0.1 + (math.random() * 0.4)
    self:Debug("sync", "Queueing section " .. sectionIndex .. " response with delay of " .. responseDelay .. " seconds")
    
    -- Initialize section requesters tracking
    self.SYNC.sectionRequesters = self.SYNC.sectionRequesters or {}
    self.SYNC.sectionRequesters[sectionIndex] = self.SYNC.sectionRequesters[sectionIndex] or {}
    self.SYNC.sectionRequesters[sectionIndex][requestingPlayer] = true
    
    -- Initialize pending section responses tracking
    self.SYNC.pendingSectionResponses = self.SYNC.pendingSectionResponses or {}
    
    -- Set up the delay timer
    self.SYNC.pendingSectionResponses[sectionIndex] = self:ScheduleTimer(function()
        -- Check if we've received a section response from someone else during our wait
        if self.SYNC.receivedSectionResponses and self.SYNC.receivedSectionResponses[sectionIndex] then
            self:Debug("sync", "Someone else already sent section " .. sectionIndex .. ", canceling ours")
        else
            -- Send our response using the SendSectionResponse from Sync.lua
            if self.SendSectionResponse then
                self:Debug("sync", "Sending response for section " .. sectionIndex .. " with timestamp " .. timestamp)
                self:SendSectionResponse(sectionIndex, timestamp)
            else
                self:Debug("sync", "SendSectionResponse function not available")
            end
        end
        
        -- Clear state for this section
        if self.SYNC.pendingSectionResponses then
            self.SYNC.pendingSectionResponses[sectionIndex] = nil
        end
        
        if self.SYNC.sectionRequesters and self.SYNC.sectionRequesters[sectionIndex] then
            self.SYNC.sectionRequesters[sectionIndex] = nil
        end
    end, responseDelay)
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
    
    -- Create the announce message using our generator
    local message = self:CreateAnnounceMessage(timestamp)
    
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
    
    -- Register for the SECTION_CHANGED message - we always want to listen
    -- for this event regardless of sync settings
    self:RegisterEvent("SECTION_CHANGED", function(sectionName, sectionIndex, numSections, context)
       
        -- Only broadcast if Live Sync is enabled
        if not self.SYNC.liveSync then
            self:Debug("sync", "Skipping section broadcast - LiveSync not enabled")
            return
        end
        
        -- Skip if the context is "fromSync" to prevent feedback loops
        if context == "fromSync" then
            self:Debug("sync", "Skipping section broadcast - came from sync already")
            return
        end
        
        -- Get current section index either from parameter or assignments
        local currentSectionIndex = sectionIndex
        if not currentSectionIndex and TWRA_Assignments and TWRA_Assignments.currentSection then
            currentSectionIndex = TWRA_Assignments.currentSection
            self:Debug("sync", "Using section index from TWRA_Assignments: " .. currentSectionIndex)
        end
        
        if not currentSectionIndex then
            self:Debug("error", "Cannot broadcast section - no valid section index found")
            return
        end
        
        -- Get timestamp for sync
        local timestamp = 0
        if TWRA_Assignments and TWRA_Assignments.timestamp then
            timestamp = TWRA_Assignments.timestamp
            self:Debug("sync", "Using timestamp from TWRA_Assignments: " .. timestamp)
        end
        
        -- Debug before broadcasting
        self:Debug("sync", "About to broadcast section change with index: " .. currentSectionIndex)
        
        -- Broadcast section change with the determined section index
        local success = self:BroadcastSectionChange(currentSectionIndex, timestamp)
        
        -- Debug after broadcasting
        if success then
            self:Debug("sync", "Successfully broadcast section change")
        else
            self:Debug("error", "Failed to broadcast section change")
        end
    end, "Sync")  -- Added "Sync" as the owner parameter
    
    -- Mark as registered
    self.SYNC.sectionChangeHandlerRegistered = true
    self:Debug("sync", "Section change handler registered successfully")
end

-- Stub functions for compressed data retrieval - to be implemented elsewhere

-- Function to get compressed structure data
function TWRA:GetCompressedStructure() -- Probably redundant, structure is readily available from TWRA_CompressedAssignments.structure
    -- This stub would be implemented in the core compression module    
    if TWRA_CompressedAssignments and TWRA_CompressedAssignments.structure then
        return TWRA_CompressedAssignments.structure
    end
    
    return nil
end

-- Send structure data to the group
function TWRA:SendStructureData()
    self:Debug("sync", "Sending structure data to group")
    
    -- Skip if not in a group
    if GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 then
        self:Debug("error", "Cannot send structure data - not in a group")
        return false
    end
    
    -- Get current timestamp
    local timestamp = 0
    if TWRA_Assignments then
        timestamp = TWRA_Assignments.timestamp or time()
    end
    
    -- Get the compressed structure data
    local structureData = self:GetCompressedStructure()
    if not structureData then
        self:Debug("error", "No structure data available to send")
        return false
    end
    
    -- Create the message 
    local message = self:CreateStructureResponseMessage(timestamp, structureData)
    
    -- Determine channel
    local channel = GetNumRaidMembers() > 0 and "RAID" or 
                   (GetNumPartyMembers() > 0 and "PARTY" or nil)
    
    -- If no valid channel, exit
    if not channel then
        self:Debug("error", "Cannot send structure data - not in a group")
        return false
    end
    
    -- Check if message needs chunking
    if string.len(message) > 2000 then
        self:Debug("sync", "Structure data too large (" .. string.len(message) .. " bytes), using chunk manager")
        if self.chunkManager then
            local prefix = self.SYNC.COMMANDS.STRUCTURE_RESPONSE .. ":" .. timestamp .. ":"
            return self.chunkManager:SendChunkedMessage(structureData, prefix, channel)
        else
            self:Debug("error", "Chunk manager not available for large structure data")
            return false
        end
    else
        -- Send the message directly
        SendAddonMessage(self.SYNC.PREFIX, message, channel)
        self:Debug("sync", "Sent structure data (" .. string.len(message) .. " bytes) via " .. channel)
        return true
    end
end

-- Send individual section data to the group
function TWRA:SendSectionData(sectionIndex)
    self:Debug("sync", "Sending section " .. sectionIndex .. " to group")
    
    -- Skip if not in a group
    if GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 then
        self:Debug("error", "Cannot send section data - not in a group")
        return false
    end
    
    -- Get current timestamp
    local timestamp = 0
    if TWRA_Assignments then
        timestamp = TWRA_Assignments.timestamp or time()
    end
    
    -- Direct access to section data from TWRA_CompressedAssignments.sections
    local sectionData = nil
    if TWRA_CompressedAssignments and TWRA_CompressedAssignments.sections then
        sectionData = TWRA_CompressedAssignments.sections[sectionIndex]
    end
    
    -- If still no data, attempt to compress it (if we have a compress function)
    if not sectionData and TWRA_Assignments and TWRA_Assignments.data and TWRA_Assignments.data[sectionIndex] then
        if self.CompressSectionData then
            self:Debug("sync", "Compressing section " .. sectionIndex .. " for sync")
            sectionData = self:CompressSectionData(sectionIndex)
            
            -- Store for future use
            if sectionData and TWRA_CompressedAssignments and TWRA_CompressedAssignments.sections then
                TWRA_CompressedAssignments.sections[sectionIndex] = sectionData
            end
        else
            self:Debug("error", "CompressSectionData function not available")
        end
    end
    
    if not sectionData then
        self:Debug("error", "No data available for section " .. sectionIndex)
        return false
    end
    
    -- Create the message
    local message = self:CreateSectionResponseMessage(timestamp, sectionIndex, sectionData)
    
    -- Determine channel
    local channel = GetNumRaidMembers() > 0 and "RAID" or 
                   (GetNumPartyMembers() > 0 and "PARTY" or nil)
    
    -- If no valid channel, exit
    if not channel then
        self:Debug("error", "Cannot send section data - not in a group")
        return false
    end
    
    -- Check if message needs chunking
    if string.len(message) > 2000 then
        self:Debug("sync", "Section data too large (" .. string.len(message) .. " bytes), using chunk manager")
        if self.chunkManager then
            local prefix = self.SYNC.COMMANDS.SECTION_RESPONSE .. ":" .. timestamp .. ":" .. sectionIndex .. ":"
            return self.chunkManager:SendChunkedMessage(sectionData, prefix, channel)
        else
            self:Debug("error", "Chunk manager not available for large section data")
            return false
        end
    else
        -- Send the message directly
        SendAddonMessage(self.SYNC.PREFIX, message, channel)
        self:Debug("sync", "Sent section " .. sectionIndex .. " data (" .. string.len(message) .. " bytes) via " .. channel)
        return true
    end
end

-- Function to send all sections to the group in bulk mode with reversed order (sections first, structure last)
function TWRA:SendAllSections()
    self:Debug("sync", "Sending all sections in reversed bulk mode (sections first, structure last)")
    
    -- Skip if not in a group
    if GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 then
        self:Debug("error", "Cannot send sections - not in a group")
        return false
    end
    
    -- Make sure we have compressed assignments data
    if not TWRA_CompressedAssignments or not TWRA_CompressedAssignments.sections then
        self:Debug("error", "No compressed assignments data available to send")
        return false
    end
    
    -- Get current timestamp
    local timestamp = 0
    if TWRA_Assignments and TWRA_Assignments.timestamp then
        timestamp = TWRA_Assignments.timestamp
    end
    
    -- CRITICAL: Prevent sending if we are already in the middle of receiving
    if TWRA_CompressedAssignments.bulkSyncTimestamp then
        return false
    end
    
    -- CRITICAL: Prevent multiple SendAllSections calls in a short period
    local now = GetTime()
    if self.SYNC.lastSendAllSectionsTime and (now - self.SYNC.lastSendAllSectionsTime < 10) then
        self:Debug("error", "Not sending sections - already sent sections recently")
        return false
    end
    
    -- Update the last send time
    self.SYNC.lastSendAllSectionsTime = now
    
    -- Count how many sections we have
    local sectionCount = 0
    local sectionIndices = {}
    for sectionIndex, _ in pairs(TWRA_CompressedAssignments.sections) do
        if type(sectionIndex) == "number" then
            sectionCount = sectionCount + 1
            table.insert(sectionIndices, sectionIndex)
        end
    end
    
    if sectionCount == 0 then
        self:Debug("error", "No sections found to send")
        return false
    end
    
    self:Debug("sync", "Found " .. sectionCount .. " sections to send in reversed bulk mode")
    
    -- Sort section indices numerically
    table.sort(sectionIndices)
    
    -- Mark that we're about to send bulk sections
    self.SYNC.sendingBulkSections = true
    self.SYNC.bulkSectionCount = sectionCount
    self.SYNC.bulkSectionsSent = 0
    
    -- Determine channel for sending
    local channel = GetNumRaidMembers() > 0 and "RAID" or 
                   (GetNumPartyMembers() > 0 and "PARTY" or nil)
    
    -- Track transfer IDs for chunked sections
    self.SYNC.chunkedSectionTransfers = self.SYNC.chunkedSectionTransfers or {}
    
    -- REVERSED ORDER: Send sections first
    self:Debug("sync", "REVERSED ORDER: Sending all sections first")
    
    local sentCount = 0
    local emptyCount = 0
    local errorCount = 0
    local chunkedCount = 0
    
    -- Send each section, potentially using chunking
    for _, sectionIndex in ipairs(sectionIndices) do
        local sectionData = TWRA_CompressedAssignments.sections[sectionIndex]
        
        -- Skip empty sections
        if not sectionData or sectionData == "" then
            emptyCount = emptyCount + 1
            self:Debug("sync", "Skipping empty section " .. sectionIndex)
        else
            -- Create the regular message to check size
            local normalMessage = self.SYNC.COMMANDS.BULK_SECTION .. ":" .. timestamp .. ":" .. sectionIndex .. ":" .. sectionData
            
            -- Determine if chunking is needed
            if string.len(normalMessage) > 2000 then
                -- Section needs chunking
                chunkedCount = chunkedCount + 1
                self:Debug("sync", "Section " .. sectionIndex .. " is large (" .. string.len(normalMessage) .. " bytes), using ChunkManager")
                
                -- Create prefix for this section's chunks
                local chunkPrefix = self.SYNC.COMMANDS.BULK_SECTION .. ":" .. timestamp .. ":" .. sectionIndex .. ":"
                
                -- Use ChunkManager to send the section data
                if self.chunkManager then
                    -- Send the content via ChunkManager and get transfer ID
                    local transferId = self.chunkManager:ChunkContent(sectionData, channel, nil, nil)
                    
                    if transferId then
                        -- Store the transfer ID for this section
                        self.SYNC.chunkedSectionTransfers[sectionIndex] = transferId
                        
                        -- Create and send a special message indicating that this section is chunked
                        local chunkRefMessage = self.SYNC.COMMANDS.BULK_SECTION .. ":" .. timestamp .. ":" .. sectionIndex .. ":CHUNK:" .. transferId
                        local success = self:SendAddonMessage(chunkRefMessage, channel)
                        
                        if success then
                            sentCount = sentCount + 1
                            self:Debug("sync", "Sent chunked section reference for section " .. sectionIndex .. " with transfer ID " .. transferId)
                        else
                            errorCount = errorCount + 1
                            self:Debug("error", "Failed to send chunked section reference for section " .. sectionIndex)
                        end
                    else
                        errorCount = errorCount + 1
                        self:Debug("error", "Failed to create chunked transfer for section " .. sectionIndex)
                    end
                else
                    errorCount = errorCount + 1
                    self:Debug("error", "Chunk manager not available for large section data")
                end
            else
                -- Send normal (non-chunked) message
                local success = self:SendAddonMessage(normalMessage, channel)
                
                if success then
                    sentCount = sentCount + 1
                    self:Debug("sync", "Sent regular section " .. sectionIndex .. " (" .. string.len(normalMessage) .. " bytes)")
                else
                    errorCount = errorCount + 1
                    self:Debug("error", "Failed to send section " .. sectionIndex)
                end
            end
        end
    end
    
    -- Report section sending results
    self:Debug("sync", "Completed sending sections. Successfully sent " .. 
             sentCount .. " out of " .. sectionCount .. " sections (" .. 
             chunkedCount .. " chunked). " .. 
             emptyCount .. " empty sections skipped. " .. 
             errorCount .. " errors.")
    
    -- REVERSED ORDER: Now get the structure data and send it LAST
    local structureData = self:GetCompressedStructure()
    if not structureData then
        self:Debug("error", "No structure data available to send at end of bulk sync")
        return false
    end
    
    -- Create the bulk structure message
    local structureMessage = self:CreateBulkStructureMessage(timestamp, structureData)
    
    -- Check if structure message needs chunking
    if string.len(structureMessage) > 2000 then
        self:Debug("sync", "Structure data too large, using chunk manager for final structure message")
        if self.chunkManager then
            local prefix = self.SYNC.COMMANDS.BULK_STRUCTURE .. ":" .. timestamp .. ":"
            local success = self.chunkManager:ChunkContent(structureData, channel, nil, prefix)
            if success then
                self:Debug("sync", "Successfully sent final structure message via chunk manager")
            else
                return false
            end
        else
            self:Debug("error", "Chunk manager not available for large structure data")
            return false
        end
    else
        -- Send the structure message directly
        local success = self:SendAddonMessage(structureMessage, channel)
        if success then
            self:Debug("sync", "Successfully sent final structure message")
        else
            self:Debug("error", "Failed to send final structure message")
            return false
        end
    end
    
    -- Clear the bulk sending flags
    self.SYNC.sendingBulkSections = nil
    self.SYNC.bulkSectionCount = nil
    self.SYNC.bulkSectionsSent = 0
    self.SYNC.chunkedSectionTransfers = {}
    
    -- Schedule clearing the lastSendAllSectionsTime after a cooldown period
    self:ScheduleTimer(function()
        self.SYNC.lastSendAllSectionsTime = nil
        self:Debug("sync", "Cleared send cooldown, ready for next sync if needed")
    end, 15) -- 15 second cooldown before allowing another send
    
    -- Final user notification
    self:Debug("sync", "Bulk sync complete with reversed order (sections first, structure last)!")
    
    collectgarbage(0) -- Fixed: In Lua 5.0, collectgarbage takes a number, not a string
    return true
end

-- Helper function to serialize data for transmission
function TWRA:SerializeData(data) -- How is this different from  TWRA:SerilizeTable(tbl) in Compression.lua?
    local serialized = ""
    
    -- Attempt to serialize using custom serialization if available
    if type(self.SerializeTableToString) == "function" then
        local success, result = pcall(self.SerializeTableToString, self, data)
        if success and result then
            return result
        end
    end
    
    -- Fallback to basic serialization
    -- This is simplified and should be replaced with proper serialization
    if type(data) == "table" then
        serialized = self.chunkManager:SerializeTable(data)
    else
        serialized = tostring(data)
    end
    
    return serialized
end

-- Helper function to deserialize received data
function TWRA:DeserializeData(serialized) -- How is this different from  TWRA:DeserilizeTable(tbl) in Compression.lua?
    if not serialized or serialized == "" then
        return false, nil
    end
    
    -- Attempt to deserialize using custom deserialization if available
    if type(self.DeserializeStringToTable) == "function" then
        local success, result = pcall(self.DeserializeStringToTable, self, serialized)
        if success and result then
            return true, result
        end
    end
    
    -- Fallback to basic deserialization
    local success, result = pcall(function()
        return self.chunkManager:DeserializeTable(serialized)
    end)
    
    return success, result
end


-- Function to send structure data in chunks
function TWRA:SendStructureDataInChunks(requestId, target)
    self:Debug("sync", "Preparing to send structure data in chunks")
    
    -- Get the compressed structure data
    local structureData = self:GetCompressedStructure()
    if not structureData then
        self:Debug("error", "No structure data available to send")
        return false
    end
    
    -- Send the data in chunks
    self:SendDataInChunks(structureData, "STRUCTURE", requestId, target)
    
    return true
end

-- Function to send section data in chunks
function TWRA:SendSectionDataInChunks(sectionIndex, requestId, target)
    self:Debug("sync", "Preparing to send section " .. sectionIndex .. " in chunks")
    
    -- Get the section data
    local sectionData = self:GetCompressedSection(sectionIndex)
    if not sectionData then
        self:Debug("error", "No data available for section " .. sectionIndex)
        return false
    end
    
    -- Send the data in chunks
    self:SendDataInChunks(sectionData, "SECTION_" .. sectionIndex, requestId, target)
    
    return true
end

-- Generic function to split and send large data in chunks
function TWRA:SendDataInChunks(data, dataType, requestId, target)
    -- Calculate chunks (max 200 chars per chunk for safety)
    local chunkSize = 200
    local totalLength = string.len(data)
    local totalChunks = math.ceil(totalLength / chunkSize)
    
    self:Debug("sync", "Sending " .. dataType .. " data in " .. totalChunks .. " chunks (total size: " .. totalLength .. " bytes)")
    
    -- Send each chunk with a small delay
    for i = 1, totalChunks do
        local startPos = ((i - 1) * chunkSize) + 1
        local endPos = math.min(startPos + chunkSize - 1, totalLength)
        local chunkData = string.sub(data, startPos, endPos)
        
        -- Create closure to preserve values
        local chunkIndex = i
        
        -- Schedule sending this chunk
        self:ScheduleTimer(function()
            local message = self:CreateBulkResponseMessage(GetTime(), requestId, dataType, chunkIndex, totalChunks, chunkData)
            self:SendAddonMessage(message, target)
            
            -- Debug progress periodically
            if (math.floor(chunkIndex / 5) * 5 == chunkIndex) or (chunkIndex == totalChunks) then --the modulo operator is not available to use, we need to user a math.floor variant
                local progress = math.floor((chunkIndex / totalChunks) * 100)
                self:Debug("sync", "Sent chunk " .. chunkIndex .. "/" .. totalChunks .. 
                          " (" .. progress .. "%) for " .. dataType)
            end
        end, (i - 1) * 0.1) -- 0.1 second delay between chunks
    end
    
    return true
end

-- Test function for isolated chunk testing
-- This allows us to test the chunking system without a full sync process
function TWRA:TestChunkedSectionProcessing()
    self:Debug("sync", "----- CHUNK TEST: Starting isolated chunked section test -----")
    
    -- Make sure our data structures exist
    TWRA_Assignments = TWRA_Assignments or {}
    TWRA_Assignments.data = TWRA_Assignments.data or {}
    TWRA_CompressedAssignments = TWRA_CompressedAssignments or {}
    TWRA_CompressedAssignments.sections = TWRA_CompressedAssignments.sections or {}
    TWRA_CompressedAssignments.sections.missing = TWRA_CompressedAssignments.sections.missing or {}
    
    -- Create a test section
    local testSectionIndex = 999
    local testSectionName = "Chunked Test Section"
    
    -- Create skeleton entry in TWRA_Assignments
    TWRA_Assignments.data[testSectionIndex] = {
        ["Section Name"] = testSectionName,
        ["NeedsProcessing"] = true
    }
    
    -- Setup the SYNC context if it doesn't exist
    self.SYNC = self.SYNC or {}
    self.SYNC.pendingChunkedSections = self.SYNC.pendingChunkedSections or {}
    
    -- Simulate a pending chunked section
    self.SYNC.pendingChunkedSections[testSectionIndex] = {
        transferId = "TEST_TRANSFER_ID",
        timestamp = time(),
        chunks = {},
        totalChunks = 5,
        receivedChunks = 0
    }
    
    -- Set an empty placeholder in sections
    TWRA_CompressedAssignments.sections[testSectionIndex] = ""
    
    -- Test ProcessSectionData to ensure it handles chunked sections correctly
    self:Debug("sync", "CHUNK TEST: Testing ProcessSectionData on pending chunked section")
    
    -- Process the test section
    if self.ProcessSectionData then
        self:ProcessSectionData(testSectionIndex)
        
        -- Verify the section is NOT added to missing sections
        local isMissing = TWRA_CompressedAssignments.sections.missing[testSectionIndex]
        self:Debug("sync", "CHUNK TEST: Section marked as missing: " .. (isMissing and "YES (FAIL)" or "NO (PASS)"))
        
        -- Verify it's still marked as needing processing
        local needsProcessing = TWRA_Assignments.data[testSectionIndex] and 
                               TWRA_Assignments.data[testSectionIndex]["NeedsProcessing"]
        self:Debug("sync", "CHUNK TEST: Section needs processing: " .. (needsProcessing and "YES (PASS)" or "NO (FAIL)"))
    else
        self:Debug("error", "CHUNK TEST: ProcessSectionData function not available")
    end
    
    -- Now simulate completed chunk assembly
    self:Debug("sync", "CHUNK TEST: Simulating completed chunk assembly")
    
    -- Create sample section data
    local sampleData = {
        ["Section Header"] = {"Icon", "Target", "Tank", "Healer"},
        ["Section Rows"] = {
            {"Skull", "Test Target", "Tank1", "Healer1"},
            {"Cross", "Test Target 2", "Tank2", "Healer2"}
        }
    }
    
    -- Convert to string (simulating assembled chunk data)
    local dataString = "THIS_IS_TEST_ASSEMBLED_CHUNK_DATA"
    
    -- Store the assembled data
    TWRA_CompressedAssignments.sections[testSectionIndex] = dataString
    
    -- Remove from pending chunked sections
    self.SYNC.pendingChunkedSections[testSectionIndex] = nil
    
    -- Process again now that chunks are "assembled"
    self:Debug("sync", "CHUNK TEST: Testing ProcessSectionData with assembled chunks")
    
    -- Mock the DecompressSectionData function to return our sample data
    local originalDecompress = self.DecompressSectionData
    self.DecompressSectionData = function(self, data)
        if data == dataString then
            return sampleData
        else
            return originalDecompress(self, data)
        end
    end
    
    -- Process the section again
    if self.ProcessSectionData then
        self:ProcessSectionData(testSectionIndex)
        
        -- Verify the section is NOT in missing sections
        local isMissing = TWRA_CompressedAssignments.sections.missing[testSectionIndex]
        self:Debug("sync", "CHUNK TEST: Section marked as missing after assembly: " .. (isMissing and "YES (FAIL)" or "NO (PASS)"))
        
        -- Verify it's no longer marked as needing processing
        local needsProcessing = TWRA_Assignments.data[testSectionIndex] and 
                               TWRA_Assignments.data[testSectionIndex]["NeedsProcessing"]
        self:Debug("sync", "CHUNK TEST: Section still needs processing: " .. (needsProcessing and "YES (FAIL)" or "NO (PASS)"))
    end
    
    -- Restore original function
    self.DecompressSectionData = originalDecompress
    
    -- Clean up after test
    TWRA_Assignments.data[testSectionIndex] = nil
    TWRA_CompressedAssignments.sections[testSectionIndex] = nil
    if TWRA_CompressedAssignments.sections.missing then
        TWRA_CompressedAssignments.sections.missing[testSectionIndex] = nil
    end
    
    self:Debug("sync", "----- CHUNK TEST: Completed isolated chunked section test -----")
    
    return true
end

-- Test function for cross-client chunked section processing
-- This simulates two clients exchanging chunked data
function TWRA:TestCrossClientChunkProcessing()
    self:Debug("sync", "----- CROSS-CLIENT CHUNK TEST: Starting test -----")
    
    -- Set up test variables
    local testSectionIndex = 999
    local testSectionName = "Cross-Client Chunked Test Section"
    local testTimestamp = time()
    local testTransferId = "TEST_" .. testTimestamp .. "_" .. testSectionIndex
    
    -- Make sure our data structures exist
    TWRA_Assignments = TWRA_Assignments or {}
    TWRA_Assignments.data = TWRA_Assignments.data or {}
    TWRA_CompressedAssignments = TWRA_CompressedAssignments or {}
    TWRA_CompressedAssignments.sections = TWRA_CompressedAssignments.sections or {}
    TWRA_CompressedAssignments.sections.missing = TWRA_CompressedAssignments.sections.missing or {}
    
    -- Ensure SYNC context exists
    self.SYNC = self.SYNC or {}
    self.SYNC.pendingChunkedSections = self.SYNC.pendingChunkedSections or {}
    
    -- Ensure ChunkManager exists
    if not self.chunkManager then
        self:Debug("error", "CROSS-CLIENT TEST: ChunkManager not available, test cannot continue")
        return false
    end
    
    -- Reset chunk manager state for clean test
    self.chunkManager.receivingChunks = {}
    self.chunkManager.processedTransfers = {}
    
    -- =============================================
    -- PHASE 1: SIMULATE CLIENT A (SENDER)
    -- =============================================
    self:Debug("sync", "CROSS-CLIENT TEST: PHASE 1 - Simulating Client A (Sender)")
    
    -- Create sample section data
    local sampleData = {
        ["Section Header"] = {"Icon", "Target", "Tank", "Healer"},
        ["Section Rows"] = {
            {"Skull", "Test Target", "Tank1", "Healer1"},
            {"Cross", "Test Target 2", "Tank2", "Healer2"},
            {"Note", "This is a test note"}
        },
        ["Section Name"] = testSectionName
    }
    
    -- Convert to string (simulating compression result)
    local sampleDataString = "SIMULATED_COMPRESSED_SECTION_DATA_FOR_TESTING"
    
    -- Create a reference to the chunked section (what would be sent via addon message)
    local chunkRefMessage = self.SYNC.COMMANDS.BULK_SECTION .. ":" .. testTimestamp .. ":" .. testSectionIndex .. ":CHUNK:" .. testTransferId
    self:Debug("sync", "CROSS-CLIENT TEST: Client A sending chunk reference message: " .. chunkRefMessage)
    
    -- Split the data into chunks (simulating what ChunkManager would do)
    local chunkSize = 50  -- Small size for testing
    local totalLength = string.len(sampleDataString)
    local totalChunks = math.ceil(totalLength / chunkSize)
    local chunks = {}
    
    for i = 1, totalChunks do
        local startPos = ((i - 1) * chunkSize) + 1
        local endPos = math.min(startPos + chunkSize - 1, totalLength)
        chunks[i] = string.sub(sampleDataString, startPos, endPos)
    end
    
    self:Debug("sync", "CROSS-CLIENT TEST: Client A prepared " .. totalChunks .. " chunks for transfer")
    
    -- Create chunk header message
    local chunkHeaderMessage = "CH:" .. totalLength .. ":" .. testTransferId .. ":" .. totalChunks
    self:Debug("sync", "CROSS-CLIENT TEST: Client A sending chunk header: " .. chunkHeaderMessage)
    
    -- =============================================
    -- PHASE 2: SIMULATE CLIENT B (RECEIVER)
    -- =============================================
    self:Debug("sync", "CROSS-CLIENT TEST: PHASE 2 - Simulating Client B (Receiver)")
    
    -- Create skeleton entry in TWRA_Assignments
    TWRA_Assignments.data[testSectionIndex] = {
        ["Section Name"] = testSectionName,
        ["NeedsProcessing"] = true
    }
    
    -- First, simulate Client B receiving the chunk reference message
    -- This is handled by the HandleBulkSectionCommand function, which would register the transfer ID
    -- We'll simulate this by directly adding to pendingChunkedSections
    self.SYNC.pendingChunkedSections[testSectionIndex] = {
        transferId = testTransferId,
        timestamp = testTimestamp,
        chunks = {},
        totalChunks = totalChunks,
        receivedChunks = 0
    }
    
    -- Set an empty placeholder in sections
    TWRA_CompressedAssignments.sections[testSectionIndex] = ""
    
    self:Debug("sync", "CROSS-CLIENT TEST: Client B registered pending chunked section with transferId: " .. testTransferId)
    
    -- Test ProcessSectionData to ensure it doesn't mark chunked section as missing
    self:Debug("sync", "CROSS-CLIENT TEST: Testing ProcessSectionData on pending chunked section")
    
    if self.ProcessSectionData then
        self:ProcessSectionData(testSectionIndex)
        
        -- Verify section is NOT added to missing sections because it's a pending chunked section
        local isMissing = TWRA_CompressedAssignments.sections.missing[testSectionIndex]
        self:Debug("sync", "CROSS-CLIENT TEST: Section marked as missing: " .. (isMissing and "YES (FAIL)" or "NO (PASS)"))
        
        -- Verify it's still marked as needing processing
        local needsProcessing = TWRA_Assignments.data[testSectionIndex] and 
                               TWRA_Assignments.data[testSectionIndex]["NeedsProcessing"]
        self:Debug("sync", "CROSS-CLIENT TEST: Section needs processing: " .. (needsProcessing and "YES (PASS)" or "NO (FAIL)"))
    else
        self:Debug("error", "CROSS-CLIENT TEST: ProcessSectionData function not available")
    end
    
    -- Simulate Client B receiving the chunk header
    self:Debug("sync", "CROSS-CLIENT TEST: Client B receiving chunk header")
    local success = self.chunkManager:HandleChunkHeader(totalLength, testTransferId, totalChunks, "ClientA")
    self:Debug("sync", "CROSS-CLIENT TEST: Chunk header processing " .. (success and "SUCCEEDED" or "FAILED"))
    
    -- Verify that the transfer is properly registered in ChunkManager
    local isRegistered = self.chunkManager.receivingChunks[testTransferId] ~= nil
    self:Debug("sync", "CROSS-CLIENT TEST: Transfer registered in ChunkManager: " .. (isRegistered and "YES (PASS)" or "NO (FAIL)"))
    
    -- Now simulate Client B receiving each chunk
    self:Debug("sync", "CROSS-CLIENT TEST: Client B receiving chunks")
    for i = 1, totalChunks do
        -- Simulate Client B receiving chunk data
        local chunkMessage = "CD:" .. testTransferId .. ":" .. i .. ":" .. chunks[i]
        self:Debug("sync", "CROSS-CLIENT TEST: Receiving chunk " .. i .. "/" .. totalChunks)
        
        local chunkSuccess = self.chunkManager:HandleChunkData(testTransferId, i, chunks[i])
        self:Debug("sync", "CROSS-CLIENT TEST: Chunk " .. i .. " processing " .. (chunkSuccess and "SUCCEEDED" or "FAILED"))
    end
    
    -- Check if ChunkManager shows that all chunks are received
    local allReceived = self.chunkManager.receivingChunks[testTransferId] and 
                        self.chunkManager.receivingChunks[testTransferId].received == totalChunks
    self:Debug("sync", "CROSS-CLIENT TEST: All chunks received: " .. (allReceived and "YES (PASS)" or "NO (FAIL)"))
    
    -- =============================================
    -- PHASE 3: SIMULATE FINALIZING THE TRANSFER
    -- =============================================
    self:Debug("sync", "CROSS-CLIENT TEST: PHASE 3 - Finalizing transfer")
    
    -- Normally, the ChunkManager would assemble and finalize the content
    -- Let's place the assembled content in the right place
    TWRA_CompressedAssignments.sections[testSectionIndex] = sampleDataString
    
    -- Remove from pending chunked sections
    self.SYNC.pendingChunkedSections[testSectionIndex] = nil
    
    -- Process the section now that chunks are "assembled"
    self:Debug("sync", "CROSS-CLIENT TEST: Testing ProcessSectionData with assembled chunks")
    
    -- Mock the DecompressSectionData function to return our sample data
    local originalDecompress = self.DecompressSectionData
    self.DecompressSectionData = function(self, data)
        if data == sampleDataString then
            return sampleData
        else
            return originalDecompress(self, data)
        end
    end
    
    -- Process the section again
    if self.ProcessSectionData then
        self:ProcessSectionData(testSectionIndex)
        
        -- Verify section is NOT in missing sections
        local isMissing = TWRA_CompressedAssignments.sections.missing[testSectionIndex]
        self:Debug("sync", "CROSS-CLIENT TEST: Section marked as missing after assembly: " .. (isMissing and "YES (FAIL)" or "NO (PASS)"))
        
        -- Verify it's no longer marked as needing processing
        local needsProcessing = TWRA_Assignments.data[testSectionIndex] and 
                               TWRA_Assignments.data[testSectionIndex]["NeedsProcessing"]
        self:Debug("sync", "CROSS-CLIENT TEST: Section still needs processing: " .. (needsProcessing and "YES (FAIL)" or "NO (PASS)"))
    end
    
    -- Restore original function
    self.DecompressSectionData = originalDecompress
    
    -- Clean up after test
    TWRA_Assignments.data[testSectionIndex] = nil
    TWRA_CompressedAssignments.sections[testSectionIndex] = nil
    if TWRA_CompressedAssignments.sections.missing then
        TWRA_CompressedAssignments.sections.missing[testSectionIndex] = nil
    end
    
    self:Debug("sync", "----- CROSS-CLIENT CHUNK TEST: Completed cross-client test -----")
    
    return true
end

-- Test function for basic chunk sending and receiving between clients
-- This is a simple test that just sends a known string using chunks
function TWRA:TestChunkSync()
    self:Debug("sync", "----- CHUNK SYNC TEST: Starting sender test -----")
    self:Debug("chunk", "----- CHUNK SYNC TEST: Starting sender test -----")
    
    -- The test message we want to send
    local testMessage = "My pinapple is strawberry flavoured and tastes like chocolate"
    local testId = "TEST_CHUNK_" .. tostring(math.floor(GetTime()))
    
    -- Make sure ChunkManager exists
    if not self.chunkManager then
        self:Debug("error", "CHUNK SYNC TEST: ChunkManager not available, test cannot continue")
        self:Debug("chunk", "CHUNK SYNC TEST: ChunkManager not available, test cannot continue")
        return false
    end
    
    -- Reset chunk manager state for clean test
    self.chunkManager.testData = self.chunkManager.testData or {}
    self.chunkManager.testData.sentMessage = testMessage
    self.chunkManager.testData.transferId = testId
    
    -- Force an aggressive chunk size for testing
    local originalMaxChunkSize = self.chunkManager.maxChunkSize
    self.chunkManager.maxChunkSize = 10  -- Force exactly 10 bytes for testing
    
    -- Calculate chunks
    local totalLength = string.len(testMessage)
    local chunkSize = self.chunkManager.maxChunkSize
    local totalChunks = math.ceil(totalLength / chunkSize)
    
    self:Debug("sync", "CHUNK SYNC TEST: Prepared message: '" .. testMessage .. "'")
    self:Debug("chunk", "CHUNK SYNC TEST: Prepared message: '" .. testMessage .. "'")
    self:Debug("chunk", "CHUNK SYNC TEST: Transfer ID: " .. testId)
    self:Debug("chunk", "CHUNK SYNC TEST: Total length: " .. totalLength .. " bytes")
    self:Debug("chunk", "CHUNK SYNC TEST: Chunk size: " .. chunkSize .. " bytes")
    self:Debug("chunk", "CHUNK SYNC TEST: Total chunks: " .. totalChunks)
    
    -- First send the chunk header to set up the transfer
    local channel = GetNumRaidMembers() > 0 and "RAID" or 
                   (GetNumPartyMembers() > 0 and "PARTY" or "GUILD")
    
    -- Create the chunk header using the standard CHUNKED prefix format
    local headerMessage = "CHUNKED:" .. totalLength .. ":" .. testId .. ":" .. totalChunks
    
    -- Output debug info about the channel and message
    self:Debug("chunk", "CHUNK SYNC TEST: Using channel: " .. channel)
    self:Debug("chunk", "CHUNK SYNC TEST: Header message format: " .. headerMessage)
    self:Debug("chunk", "CHUNK SYNC TEST: Full addon prefix: " .. self.SYNC.PREFIX)
    
    -- Send the chunk header
    if self.SendAddonMessage then
        self:Debug("chunk", "CHUNK SYNC TEST: Using TWRA:SendAddonMessage to send header")
        self:SendAddonMessage(headerMessage, channel)
        self:Debug("sync", "CHUNK SYNC TEST: Sent chunk header: " .. headerMessage)
        self:Debug("chunk", "CHUNK SYNC TEST: Sent chunk header: " .. headerMessage)
    else
        self:Debug("chunk", "CHUNK SYNC TEST: Using raw SendAddonMessage to send header")
        SendAddonMessage(self.SYNC.PREFIX, headerMessage, channel)
        self:Debug("sync", "CHUNK SYNC TEST: Sent chunk header (raw): " .. headerMessage)
        self:Debug("chunk", "CHUNK SYNC TEST: Sent chunk header (raw): " .. self.SYNC.PREFIX .. " :: " .. headerMessage)
    end
    
    -- Store chunks in the test data for verification
    self.chunkManager.testData.chunks = {}
    
    -- Now send each chunk with short delay between them
    for i = 1, totalChunks do
        local startPos = ((i - 1) * chunkSize) + 1
        local endPos = math.min(startPos + chunkSize - 1, totalLength)
        local chunkData = string.sub(testMessage, startPos, endPos)
        
        -- Store the chunk for verification
        self.chunkManager.testData.chunks[i] = chunkData
        
        -- Create the chunk data message using the standard CHUNK prefix format
        local chunkMessage = "CHUNK:" .. testId .. ":" .. i .. ":" .. chunkData
        
        -- Schedule sending this chunk
        self:ScheduleTimer(function()
            self:Debug("chunk", "CHUNK SYNC TEST: About to send chunk " .. i .. "/" .. totalChunks)
            
            if self.SendAddonMessage then
                self:Debug("chunk", "CHUNK SYNC TEST: Using TWRA:SendAddonMessage to send chunk")
                self:SendAddonMessage(chunkMessage, channel)
            else
                self:Debug("chunk", "CHUNK SYNC TEST: Using raw SendAddonMessage to send chunk")
                SendAddonMessage(self.SYNC.PREFIX, chunkMessage, channel)
            end
            
            self:Debug("sync", "CHUNK SYNC TEST: Sent chunk " .. i .. "/" .. totalChunks .. 
                      ": '" .. chunkData .. "'")
            self:Debug("chunk", "CHUNK SYNC TEST: Sent chunk " .. i .. "/" .. totalChunks .. 
                      ": '" .. chunkData .. "' with message: " .. chunkMessage)
            
            -- If this is the last chunk, log completion
            if i == totalChunks then
                self:Debug("sync", "CHUNK SYNC TEST: Completed sending all " .. totalChunks .. " chunks")
                self:Debug("chunk", "CHUNK SYNC TEST: Completed sending all " .. totalChunks .. " chunks")
                self:Debug("chunk", "CHUNK SYNC TEST: Receiving client should now run /run TWRA:TestChunkCompletion()")
                
                -- Restore original chunk size
                self.chunkManager.maxChunkSize = originalMaxChunkSize
            end
        end, (i - 1) * 0.1) -- 0.1 second delay between chunks
    end
    
    self:Debug("sync", "----- CHUNK SYNC TEST: Sender test setup complete -----")
    self:Debug("chunk", "----- CHUNK SYNC TEST: Sender test setup complete -----")
    DEFAULT_CHAT_FRAME:AddMessage("|cFF33FFFF[TWRA Chunk Test]|r Started chunk transfer test: Sending " .. 
                                 totalChunks .. " chunks with size of " .. chunkSize .. " bytes each. The other client should see them and can then run |cFFFFFF00/run TWRA:TestChunkCompletion()|r")
    
    return true
end

-- Test function to verify received chunks are correctly processed
function TWRA:TestChunkCompletion()
    self:Debug("sync", "----- CHUNK SYNC TEST: Starting receiver verification -----")
    
    -- Make sure ChunkManager exists
    if not self.chunkManager then
        self:Debug("error", "CHUNK SYNC TEST: ChunkManager not available, test cannot continue")
        return false
    end
    
    -- Find chunks that start with TEST_CHUNK prefix
    local foundTransferId = nil
    local receivedChunks = nil
    
    for transferId, info in pairs(self.chunkManager.receivingChunks or {}) do
        if string.find(transferId, "TEST_CHUNK_") then
            foundTransferId = transferId
            receivedChunks = info
            self:Debug("sync", "CHUNK SYNC TEST: Found test transfer: " .. transferId)
            break
        end
    end
    
    if not foundTransferId or not receivedChunks then
        self:Debug("error", "CHUNK SYNC TEST: No test chunk transfer found. Make sure the sender has run TestChunkSync first.")
        DEFAULT_CHAT_FRAME:AddMessage("|cFF33FFFF[TWRA Chunk Test]|r No test chunk transfer found. Did the sender run |cFFFFFF00/run TWRA:TestChunkSync()|r?")
        return false
    end
    
    self:Debug("sync", "CHUNK SYNC TEST: Found test transfer ID: " .. foundTransferId)
    self:Debug("sync", "CHUNK SYNC TEST: Expected chunks: " .. (receivedChunks.expected or "unknown"))
    self:Debug("sync", "CHUNK SYNC TEST: Received chunks: " .. (receivedChunks.received or "unknown"))
    
    -- Check if we received all chunks
    local isComplete = (receivedChunks.expected > 0 and receivedChunks.received == receivedChunks.expected)
    self:Debug("sync", "CHUNK SYNC TEST: Transfer complete: " .. (isComplete and "YES (PASS)" or "NO (FAIL)"))
    
    if isComplete then
        -- Assemble the chunks and check the message
        local assembledMessage = ""
        for i = 1, receivedChunks.received do
            if receivedChunks.chunks[i] then
                assembledMessage = assembledMessage .. receivedChunks.chunks[i]
            else
                self:Debug("error", "CHUNK SYNC TEST: Missing chunk " .. i)
            end
        end
        
        self:Debug("sync", "CHUNK SYNC TEST: Assembled message: '" .. assembledMessage .. "'")
        
        -- Verify the expected message
        local expectedMessage = "My pinapple is strawberry flavoured and tastes like chocolate"
        local messageMatches = (assembledMessage == expectedMessage)
        
        self:Debug("sync", "CHUNK SYNC TEST: Message matches expected: " .. (messageMatches and "YES (PASS)" or "NO (FAIL)"))
        self:Debug("sync", "CHUNK SYNC TEST: Expected: '" .. expectedMessage .. "'")
        self:Debug("sync", "CHUNK SYNC TEST: Received: '" .. assembledMessage .. "'")
        
        -- Final result
        if messageMatches then
            self:Debug("sync", "CHUNK SYNC TEST: OVERALL RESULT: PASS - Chunking system working correctly!")
            DEFAULT_CHAT_FRAME:AddMessage("|cFF33FFFF[TWRA Chunk Test]|r |cFF00FF00SUCCESS!|r Received and assembled the correct message: '" .. assembledMessage .. "'")
        else
            self:Debug("sync", "CHUNK SYNC TEST: OVERALL RESULT: FAIL - Assembled message does not match expected")
            DEFAULT_CHAT_FRAME:AddMessage("|cFF33FFFF[TWRA Chunk Test]|r |cFFFF0000FAILED!|r Assembled message does not match expected")
        end
    else
        self:Debug("sync", "CHUNK SYNC TEST: OVERALL RESULT: FAIL - Did not receive all expected chunks")
        DEFAULT_CHAT_FRAME:AddMessage("|cFF33FFFF[TWRA Chunk Test]|r |cFFFF0000FAILED!|r Did not receive all expected chunks. Received " .. 
                                     (receivedChunks.received or "0") .. "/" .. (receivedChunks.expected or "?"))
    end
    
    self:Debug("sync", "----- CHUNK SYNC TEST: Receiver verification complete -----")
    
    return isComplete and messageMatches
end

-- Enhance the chunk manager to finalize the test chunks properly
function TWRA:EnhanceChunkManagerForTests()
    if not self.chunkManager then
        self:Debug("error", "Cannot enhance chunk manager - not available")
        return false
    end
    
    -- Store the original HandleChunkData function
    local originalHandleChunkData = self.chunkManager.HandleChunkData
    
    -- Override the HandleChunkData function to better handle our test chunks
    self.chunkManager.HandleChunkData = function(self, transferId, chunkIndex, chunkData)
        -- Call the original function first
        local result = originalHandleChunkData(self, transferId, chunkIndex, chunkData)
        
        -- Special handling for test chunks
        if string.find(transferId, "TEST_CHUNK_") then
            -- Check if we've received all chunks
            local transfer = self.receivingChunks[transferId]
            if transfer and transfer.expected > 0 and transfer.received == transfer.expected then
                -- Log that all chunks have been received
                TWRA:Debug("sync", "All test chunks received for transfer: " .. transferId)
                TWRA:Debug("sync", "You can now run /run TWRA:TestChunkCompletion() to verify")
                
                -- Add a message to the chat frame to make it obvious
                DEFAULT_CHAT_FRAME:AddMessage("|cFF33FFFF[TWRA Chunk Test]|r Received all chunks! Run |cFFFFFF00/run TWRA:TestChunkCompletion()|r to verify")
            end
        end
        
        return result
    end
    
    self:Debug("sync", "Enhanced ChunkManager for testing")
    return true
end