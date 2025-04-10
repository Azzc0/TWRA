-- Sync functionality for TWRA
TWRA = TWRA or {}

-- Setup initial SYNC module properties
TWRA.SYNC = TWRA.SYNC or {}
TWRA.SYNC.PREFIX = "TWRA" -- Addon message prefix
TWRA.SYNC.liveSync = false -- Live sync enabled
TWRA.SYNC.tankSync = false -- Tank sync enabled
TWRA.SYNC.isActive = false -- Is sync system active
TWRA.SYNC.pendingSection = nil -- Section to navigate to after sync
TWRA.SYNC.lastRequestTime = 0 -- When we last requested data
TWRA.SYNC.requestTimeout = 5 -- Seconds to wait between requests
TWRA.SYNC.monitorMessages = false -- Monitor all addon messages

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
        if not self.SYNC.isActive then
            self:Debug("sync", "Auto-activating Live Sync from saved settings")
            self:ActivateLiveSync()
        end
    else
        self:Debug("sync", "Live Sync not enabled in settings")
    end
end

-- Function to activate Live Sync on initialization or UI reload
function TWRA:ActivateLiveSync()
    -- Check if we're already active
    if self.SYNC.isActive then
        self:Debug("sync", "Live Sync is already active")
        return true
    end
    
    -- Set active state
    self.SYNC.liveSync = true
    self.SYNC.isActive = true
    
    -- Register for addon communication messages
    local frame = getglobal("TWRAEventFrame")
    if frame then
        frame:RegisterEvent("CHAT_MSG_ADDON")
        self:Debug("sync", "Registered for CHAT_MSG_ADDON events")
    else
        self:Debug("error", "Could not find event frame to register events")
    end
    
    -- Enable message handling
    self:Debug("sync", "Live Sync fully activated")
    
    -- Hook into section changes if they happen
    if self.navigation and self.navigation.currentIndex then
        self:Debug("sync", "Current section found: " .. self.navigation.currentIndex)
        
        -- Always broadcast current section when activating live sync, even if UI not shown
        if GetNumRaidMembers() > 0 or GetNumPartyMembers() > 0 then
            local currentSection = self.navigation.currentIndex
            if currentSection and self.BroadcastSectionChange then
                self:Debug("sync", "Broadcasting initial section: " .. currentSection)
                self:BroadcastSectionChange(currentSection)
            end
        end
    else
        self:Debug("sync", "No current section available yet")
    end
    
    -- Ensure the option is saved in saved variables
    if not TWRA_SavedVariables.options then TWRA_SavedVariables.options = {} end
    TWRA_SavedVariables.options.liveSync = true
    
    -- Set up an OnUpdate function to ensure sync works even without UI
    if not self.syncInitTimer then
        self.syncInitTimer = self:ScheduleTimer(function()
            -- This ensures we have proper sync regardless of UI state
            if self.navigation and self.navigation.currentIndex and 
               not self.syncInitialBroadcastSent and self.BroadcastSectionChange and
               (GetNumRaidMembers() > 0 or GetNumPartyMembers() > 0) then
                self:Debug("sync", "Sending delayed initial broadcast")
                self:BroadcastSectionChange(self.navigation.currentIndex)
                self.syncInitialBroadcastSent = true
            end
        end, 3)  -- Generous delay to ensure everything is loaded
    end
    
    return true
end

-- Function to deactivate Live Sync
function TWRA:DeactivateLiveSync()
    -- Set inactive state
    self.SYNC.liveSync = false
    self.SYNC.isActive = false
    
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
    -- Default channel selection (RAID or PARTY)
    local channel = "RAID"
    if GetNumRaidMembers() == 0 then
        channel = "PARTY"
    end
    
    -- Skip if not in a group
    if GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 then
        self:Debug("sync", "Not broadcasting section change - not in a group")
        return false
    end
    
    -- Ensure we have navigation data
    if self.navigation and self.navigation.handlers then
        local numSections = table.getn(self.navigation.handlers)
        if sectionIndex > numSections then
            self:Debug("sync", "Section index out of range: " .. sectionIndex .. " (max: " .. numSections .. ")")
            sectionIndex = math.min(sectionIndex, numSections)
        end
        
        -- Get section name for better debug information
        local sectionName = self.navigation.handlers[sectionIndex] or "unknown"
        
        -- Create the message with timestamp, section index, and section name
        -- Format: SECTION:timestamp:sectionIndex:sectionName
        local message = string.format("%s:%d:%d:%s", 
            self.SYNC.COMMANDS.SECTION,
            timestamp or 0,
            sectionIndex,
            sectionName)
        
        -- Send the message
        if self.SendAddonMessage then
            self:SendAddonMessage(message)
            self:Debug("sync", "Broadcast section change: " .. sectionIndex .. 
                      " (" .. sectionName .. ") with timestamp " .. (timestamp or 0))
            return true
        else
            self:Debug("error", "SendAddonMessage function not available")
            return false
        end
    else
        self:Debug("sync", "Cannot broadcast - navigation not initialized")
        return false
    end
end

-- Process incoming addon communication messages
function TWRA:OnChatMsgAddon(prefix, message, distribution, sender)
    -- Global message monitoring for debugging
    if self.SYNC.monitorMessages then
        -- Display all addon messages in a more visible way
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF00FF[ADDON MSG]|r |cFF33FF33" .. 
            prefix .. "|r from |cFF33FFFF" .. sender .. "|r: |cFFFFFFFF" .. message .. "|r")
    end
    
    -- Check if message is from our addon
    if prefix ~= self.SYNC.PREFIX then return end
    
    -- Skip our own messages
    if sender == UnitName("player") then return end
    
    -- Forward to our message handler
    if self.HandleAddonMessage then
        self:HandleAddonMessage(message, distribution, sender)
    else
        self:Debug("sync", "HandleAddonMessage function not available, message received but not processed")
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

-- Debug function to show sync status information
function TWRA:ShowSyncStatus()
    DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA Sync Status:|r")
    DEFAULT_CHAT_FRAME:AddMessage("  Live Sync: " .. (self.SYNC.liveSync and "|cFF00FF00ENABLED|r" or "|cFFFF0000DISABLED|r"))
    DEFAULT_CHAT_FRAME:AddMessage("  Tank Sync: " .. (self.SYNC.tankSync and "|cFF00FF00ENABLED|r" or "|cFFFF0000DISABLED|r"))
    DEFAULT_CHAT_FRAME:AddMessage("  Active: " .. (self.SYNC.isActive and "|cFF00FF00YES|r" or "|cFFFF0000NO|r"))
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