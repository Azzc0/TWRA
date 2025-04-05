-- Sync functionality for TWRA
TWRA = TWRA or {}

-- Setup initial SYNC module properties
TWRA.SYNC = TWRA.SYNC or {}
TWRA.SYNC.PREFIX = "TWRA" -- Addon message prefix
TWRA.SYNC.liveSync = false -- Live sync enabled
TWRA.SYNC.tankSync = false -- Tank sync enabled
TWRA.SYNC.isActive = false -- Is sync system active
TWRA.SYNC.pendingSection = nil -- Section to navigate to after sync

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

-- Function to broadcast section changes to the group
function TWRA:BroadcastSectionChange(sectionIndex)
    if not self.SYNC or not self.SYNC.liveSync then
        self:Debug("sync", "Cannot broadcast - sync not enabled")
        return false
    end
    
    -- Make sure we have a valid section
    if not sectionIndex or type(sectionIndex) ~= "number" then
        self:Debug("sync", "Invalid section index for broadcast: " .. tostring(sectionIndex))
        return false
    end
    
    -- Get channel to broadcast to
    local channel = "RAID"
    if GetNumRaidMembers() == 0 then
        if GetNumPartyMembers() > 0 then
            channel = "PARTY"
        else
            self:Debug("sync", "Not in a group, skipping broadcast")
            return false
        end
    end
    
    -- Ensure the section index is valid
    if self.navigation and self.navigation.handlers then
        local numSections = table.getn(self.navigation.handlers)
        if sectionIndex > numSections then
            self:Debug("sync", "Section index out of range: " .. sectionIndex .. " (max: " .. numSections .. ")")
            sectionIndex = math.min(sectionIndex, numSections)
        end
        
        -- Get section name for better debug information
        local sectionName = self.navigation.handlers[sectionIndex] or "unknown"
        
        -- Create the message with a simple protocol
        local message = "SECTION:" .. sectionIndex
        
        -- Send the message
        SendAddonMessage(self.SYNC.PREFIX, message, channel)
        self:Debug("sync", "Broadcasted section change: " .. sectionIndex .. " (" .. sectionName .. ") via " .. channel)
        return true
    else
        self:Debug("sync", "Cannot broadcast - navigation not initialized")
        return false
    end
end

-- Process incoming addon communication messages
function TWRA:OnChatMsgAddon(prefix, message, distribution, sender)
    -- Check if message is from our addon
    if prefix ~= self.SYNC.PREFIX then return end
    
    -- Skip our own messages
    if sender == UnitName("player") then return end
    
    -- Check for section change messages
    if string.sub(message, 1, 8) == "SECTION:" then
        -- Only process if live sync is enabled
        if not self.SYNC.liveSync then return end
        
        -- Extract section index
        local sectionIndex = tonumber(string.sub(message, 9))
        
        -- Validate section index
        if not sectionIndex or sectionIndex < 1 then
            self:Debug("sync", "Invalid section index received: " .. string.sub(message, 9))
            return
        end
        
        self:Debug("sync", "Received section change to " .. sectionIndex .. " from " .. sender)
        
        -- Navigate to the new section if valid
        if self.navigation and self.navigation.handlers then
            local maxSection = table.getn(self.navigation.handlers)
            
            if sectionIndex > maxSection then
                self:Debug("sync", "Section index out of range: " .. sectionIndex .. " (max: " .. maxSection .. ")")
                return
            end
            
            -- Navigate to the section with "fromSync" flag
            if self.NavigateToSection then
                self:NavigateToSection(sectionIndex, "fromSync")
                self:Debug("sync", "Navigated to section " .. sectionIndex .. " due to sync from " .. sender)
            end
        end
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