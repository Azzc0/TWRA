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
    VERSION = "VER",        -- For version checking
    SECTION = "SECTION",    -- For live section updates
    DATA_REQUEST = "DREQ",  -- Request full data (legacy)
    DATA_RESPONSE = "DRES", -- Send full data (legacy)
    ANNOUNCE = "ANC",        -- Announce new import
    STRUCTURE_REQUEST = "SREQ",  -- Request structure data
    STRUCTURE_RESPONSE = "SRES", -- Send structure data
    SECTION_REQUEST = "SECREQ",   -- Request specific section data
    SECTION_RESPONSE = "SECRES"  -- Send specific section data
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

-- Function to create an announcement message (ANC)
function TWRA:CreateAnnounceMessage(timestamp)
    return self.SYNC.COMMANDS.ANNOUNCE .. ":" .. timestamp
end

-- Function to create a structure request message (SREQ)
function TWRA:CreateStructureRequestMessage(timestamp)
    return self.SYNC.COMMANDS.STRUCTURE_REQUEST .. ":" .. timestamp
end

-- Function to create a structure response message (SRES)
function TWRA:CreateStructureResponseMessage(timestamp, structureData)
    return self.SYNC.COMMANDS.STRUCTURE_RESPONSE .. ":" .. timestamp .. ":" .. structureData
end

-- Function to create a section request message (SECREQ)
function TWRA:CreateSectionRequestMessage(timestamp, sectionIndex)
    return self.SYNC.COMMANDS.SECTION_REQUEST .. ":" .. timestamp .. ":" .. sectionIndex
end

-- Function to create a section response message (SECRES)
function TWRA:CreateSectionResponseMessage(timestamp, sectionIndex, sectionData)
    return self.SYNC.COMMANDS.SECTION_RESPONSE .. ":" .. timestamp .. ":" .. sectionIndex .. ":" .. sectionData
end

-- Legacy function to create a data request message (DREQ) - Deprecated
function TWRA:CreateDataRequestMessage(timestamp)
    self:Debug("sync", "WARNING: Using deprecated DREQ message format")
    return self.SYNC.COMMANDS.DATA_REQUEST .. ":" .. timestamp
end

-- Legacy function to create a data response message (DRES) - Deprecated
function TWRA:CreateDataResponseMessage(timestamp, data)
    self:Debug("sync", "WARNING: Using deprecated DRES message format")
    return self.SYNC.COMMANDS.DATA_RESPONSE .. ":" .. timestamp .. ":" .. data
end

-- Function to create a version check message (VER)
function TWRA:CreateVersionMessage(versionNumber)
    return self.SYNC.COMMANDS.VERSION .. ":" .. versionNumber
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

-- Function to request structure data from group (replacing RequestDataSync)
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
        self:Debug("sync", "No specific timestamp provided, ~~using our current timestamp~~")
        if TWRA_Assignments and TWRA_Assignments.timestamp then
            timestamp = TWRA_Assignments.timestamp
        -- else  -- we should most definitely SREQ:0 at any point.
        --     timestamp = 0
        end
    end
    
    -- Create the request message using our generator
    local message = self:CreateStructureRequestMessage(timestamp)
    
    -- Send the request
    self:SendAddonMessage(message)
    self:Debug("sync", "Requested structure sync with timestamp " .. timestamp)
    
    -- Show a message to the user
    self:Debug("sync", "Requesting raid structure from group...", true)
    
    return true
end

-- Function to request a specific section from group
function TWRA:RequestSectionSync(sectionIndex, timestamp)
    -- Check if we're in a group
    if GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 then
        self:Debug("sync", "Not in a group, skipping section request")
        return false
    end
    
    -- Make sure we have a valid timestamp
    if not timestamp or timestamp == 0 then
        self:Debug("sync", "No specific timestamp provided for section request, using current")
        if TWRA_Assignments and TWRA_Assignments.timestamp then
            timestamp = TWRA_Assignments.timestamp
        else
            timestamp = 0
        end
    end
    
    -- Create the request message using our generator
    local message = self:CreateSectionRequestMessage(timestamp, sectionIndex)
    
    -- Send the request
    self:SendAddonMessage(message)
    self:Debug("sync", "Requested section " .. sectionIndex .. " with timestamp " .. timestamp)
    
    return true
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
    local sectionData = self:GetCompressedSection(sectionIndex)
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

-- Stub functions for compressed data retrieval - to be implemented elsewhere

-- Function to get compressed structure data
function TWRA:GetCompressedStructure()
    -- This stub would be implemented in the core compression module
    self:Debug("sync", "GetCompressedStructure called - needs implementation")
    
    if TWRA_CompressedAssignments and TWRA_CompressedAssignments.structure then
        return TWRA_CompressedAssignments.structure
    end
    
    return nil
end

-- Function to get compressed section data by index
function TWRA:GetCompressedSection(sectionIndex)
    -- This stub would be implemented in the core compression module
    self:Debug("sync", "GetCompressedSection called for section " .. sectionIndex .. " - needs implementation")
    
    if TWRA_CompressedAssignments and TWRA_CompressedAssignments.data and 
       TWRA_CompressedAssignments.data[sectionIndex] then
        return TWRA_CompressedAssignments.data[sectionIndex]
    end
    
    return nil
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
