-- Turtle WoW Raid Assignments (TWRA)
-- Core initialization file

TWRA = TWRA or {}

function TWRA:OnLoad(eventFrame)
    -- Store reference to the event frame for future use
    self.eventFrame = eventFrame or _G["TWRAEventFrame"]
    
    if not self.eventFrame then
        self:Debug("error", "Could not find event frame to register events")
        return
    end
    
    -- Register for events
    self.eventFrame:RegisterEvent("ADDON_LOADED")
    self.eventFrame:RegisterEvent("CHAT_MSG_ADDON")
    self.eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    self.eventFrame:RegisterEvent("RAID_ROSTER_UPDATE")
    self.eventFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
    
    -- Initialize saved variables if needed
    TWRA_SavedVariables = TWRA_SavedVariables or {}
    -- Ensure options table exists
    TWRA_SavedVariables.options = TWRA_SavedVariables.options or {}
    
    -- Initialize TWRA_Assignments if it doesn't exist
    TWRA_Assignments = TWRA_Assignments or {}
    
    -- Ensure TWRA_Assignments.data exists to prevent nil references
    if not TWRA_Assignments.data then
        TWRA_Assignments.data = {}
        
        -- Try to migrate data from the old format if it exists
        if TWRA_SavedVariables.assignments and TWRA_SavedVariables.assignments.data then
            self:Debug("system", "Migrating data from old format to new format")
            TWRA_Assignments.data = TWRA_SavedVariables.assignments.data
            TWRA_Assignments.version = TWRA_SavedVariables.assignments.version or 1
            TWRA_Assignments.timestamp = TWRA_SavedVariables.assignments.timestamp or time()
            TWRA_Assignments.currentSection = TWRA_SavedVariables.assignments.currentSection or 1
        end
    end
    
    -- IMPORTANT: Ensure we never store full compressed data
    TWRA_CompressedAssignments = TWRA_CompressedAssignments or {}
    
    -- Set default for main frame visibility if it doesn't exist
    if TWRA_SavedVariables.options.hideFrameByDefault == nil then
        TWRA_SavedVariables.options.hideFrameByDefault = true
    end
    
    -- Initialize options with proper boolean values if needed
    if not TWRA_SavedVariables.options then
        TWRA_SavedVariables.options = {}
    end
    
    -- Initialize PLAYERS table with error handling
    self:Debug("general", "Initializing player table")
    
    -- Create a new PLAYERS table (don't try to use an existing one that might be corrupted)
    self.PLAYERS = {}
    
    -- Try to initialize the player table with error handling
    local success, errorMsg = pcall(function()
        return self:UpdatePlayerTable()
    end)
    
    if not success then
        -- Log the error and create a minimal PLAYERS table with at least the player themselves
        self:Debug("error", "Failed to initialize PLAYERS table: " .. tostring(errorMsg))
        
        -- Create a minimal table with just the player
        local playerName = UnitName("player")
        local _, playerClass = UnitClass("player")
        self.PLAYERS = {}
        self.PLAYERS[playerName] = {playerClass, true}  -- Player is always online
        
        self:Debug("general", "Created minimal PLAYERS table with just the player")
    end
    
    -- Debug output to verify PLAYERS table initialization
    local playerCount = 0
    for name, data in pairs(self.PLAYERS) do
        playerCount = playerCount + 1
        if playerCount <= 3 then -- Just show first 3 players for brevity
            self:Debug("general", "Player in table: " .. name .. " = " .. data[1] .. " (" .. (data[2] and "Online" or "Offline") .. ")")
        end
    end
    self:Debug("general", "Player table initialized with " .. playerCount .. " entries")
    
    -- Initialize compression system
    if self.InitializeCompression then
        if self:InitializeCompression() then
            self:Debug("system", "Compression system initialized successfully")
        else
            self:Debug("error", "Failed to initialize compression system")
        end
    else
        self:Debug("error", "InitializeCompression function not found")
    end
    
    -- Convert any existing numeric values to booleans
    if TWRA_SavedVariables.options.autoNavigate ~= nil and 
       type(TWRA_SavedVariables.options.autoNavigate) ~= "boolean" then
        TWRA_SavedVariables.options.autoNavigate = (TWRA_SavedVariables.options.autoNavigate == 1) 
    end
    
    -- Initialize AUTONAVIGATE with consistent value
    self.AUTONAVIGATE = self.AUTONAVIGATE or {}
    self.AUTONAVIGATE.enabled = TWRA_SavedVariables.options.autoNavigate or false
    
    -- Initialize Debug system
    if self.InitDebug then
        self:InitDebug()
    end
    
    -- Initialize Performance monitoring system
    if self.InitializePerformance then
        self:Debug("perf", "Initializing performance monitoring system")
        if self:InitializePerformance() then
            self:Debug("perf", "Performance monitoring system initialized successfully")
            -- Hook critical functions during initialization
            if self.Performance and not self.Performance.hooked and self.HookCriticalFunctions then
                self:HookCriticalFunctions()
            end
        else
            self:Debug("error", "Failed to initialize performance monitoring system")
        end
    else
        self:Debug("error", "InitializePerformance function not found")
    end
    
    -- Ensure all needed namespaces exist
    TWRA.UI = TWRA.UI or {}
    TWRA.SYNC = TWRA.SYNC or {
        PREFIX = "TWRA",
        COMMANDS = {}
    }
    
    -- Initialize UI systems
    if self.UI then
        self.UI:InitializeDropdowns()
        self:Debug("ui", "Dropdowns initialized")
    end
    
    -- Initialize group monitoring system
    if self.InitializeGroupMonitoring then
        self:Debug("data", "Initializing group monitoring")
        self:InitializeGroupMonitoring()
    else
        self:Debug("warning", "InitializeGroupMonitoring function not found, group monitoring not initialized")
    end
    
    self:Debug("general", "Addon loaded. Type /twra for options.")

    -- Create minimap button during load
    self:Debug("general", "Creating minimap button during load")
    self:CreateMinimapButton()
    
    -- Initialize UI systems
    TWRA.UI:InitializeDropdowns()
    
    -- Initialize AutoNavigate module with proper boolean handling
    if self.AUTONAVIGATE then
        -- Make sure saved variable exists
        if not TWRA_SavedVariables.options then
            TWRA_SavedVariables.options = {}
        end
        
        -- Convert autoNavigate option to boolean if needed
        if TWRA_SavedVariables.options.autoNavigate ~= nil then
            if type(TWRA_SavedVariables.options.autoNavigate) ~= "boolean" then
                local wasEnabled = (TWRA_SavedVariables.options.autoNavigate == 1 or 
                                   TWRA_SavedVariables.options.autoNavigate == true)
                TWRA_SavedVariables.options.autoNavigate = wasEnabled
                self:Debug("nav", "Converted autoNavigate from " .. 
                          type(TWRA_SavedVariables.options.autoNavigate) .. 
                          " to boolean: " .. tostring(wasEnabled))
            end
        else
            -- Default to disabled
            TWRA_SavedVariables.options.autoNavigate = false
        end
        
        -- Apply the setting
        self.AUTONAVIGATE.enabled = TWRA_SavedVariables.options.autoNavigate
        
        -- Start AutoNavigate if it's enabled
        if self.AUTONAVIGATE.enabled then
            self:Debug("nav", "Starting AutoNavigate during initialization")
            if self.StartAutoNavigateScan then
                self:StartAutoNavigateScan()
            else
                self:Debug("error", "StartAutoNavigateScan function not found")
            end
        end
    end
end

function TWRA:OnEvent()
    if event == "ADDON_LOADED" and arg1 == "TWRA" then
        -- Initialize options
        if self.InitOptions then
            self:Debug("general", "Initializing options")
            self:InitOptions()
        else
            self:Error("InitOptions function not found")
        end
        
        -- Rebuild navigation from saved data
        self:Debug("nav", "Rebuilding navigation from saved data")
        self:RebuildNavigation()
        
        -- Add emergency UI reset function
        self.ResetUI = function()
            self:Debug("ui", "Performing emergency UI reset")
            
            -- Set view to main
            self.currentView = "main"
            
            -- Hide and destroy options container
            if self.optionsContainer then
                self.optionsContainer:Hide()
                self.optionsContainer:SetParent(nil)
                self.optionsContainer = nil
            end
            
            -- Clear options elements
            self.optionsElements = {}
            
            -- Update buttons
            if self.optionsButton then
                self.optionsButton:SetText("Options")
            end
            
            -- Reset title
            if self.mainFrame and self.mainFrame.titleText then
                self.mainFrame.titleText:SetText("Raid Assignments")
            end
            
            -- Show navigation elements
            if self.navigation then
                if self.navigation.prevButton then self.navigation.prevButton:Show() end
                if self.navigation.nextButton then self.navigation.nextButton:Show() end
                if self.navigation.dropdown and self.navigation.dropdown.container then
                    self.navigation.dropdown.container:Show()
                end
            end
            
            -- Show other buttons
            if self.announceButton then self.announceButton:Show() end
            if self.updateTanksButton then self.updateTanksButton:Show() end
            
            self:Debug("ui", "UI reset complete")
        end
        
        -- Handle addon messages for sync
        self:HandleAddonMessage(arg2, arg3, arg4)
        
        -- Create minimap button if it doesn't exist yet
        if not self.minimapButton then
            self:Debug("general", "Creating minimap button after addon loaded")
            self:CreateMinimapButton()
        end
    elseif event == "GROUP_ROSTER_UPDATE" then
        -- Handle group composition changes
        if self.OnGroupChanged then
            self:OnGroupChanged()
        end
    end
end

-- Create frame for events
local frame = CreateFrame("Frame", "TWRAEventFrame")
frame:RegisterEvent("PLAYER_ENTERING_WORLD") -- Explicitly register the event here too
frame:SetScript("OnEvent", function() 
    -- Add direct debug output before passing to OnEvent to ensure the event is triggering
    if event == "PLAYER_ENTERING_WORLD" then
        -- DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA Debug [event]:|r PLAYER_ENTERING_WORLD triggered")
        
        -- Create the main frame directly here but don't load content yet
        if not TWRA.mainFrame and TWRA.CreateMainFrame then
            TWRA:CreateMainFrame()
            TWRA.mainFrame:Hide() -- Ensure it's hidden by default
            -- DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA Debug [ui]:|r Main frame created and hidden directly from event handler")
            
            -- Set a flag to indicate we need to load content when user manually shows frame
            TWRA.needsInitialContentLoad = true
        end
        
        TWRA:CreateMinimapButton()

        -- Initialize OSD system (moved from OnEvent)
        if TWRA.InitOSD then
            TWRA:Debug("ui", "Initializing OSD system")
            TWRA:InitOSD()
        end
        
        -- IMPORTANT: Ensure PLAYERS table is properly initialized
        -- This ensures the table is always populated properly even if early initialization failed
        if TWRA.UpdatePlayerTable then
            TWRA:Debug("general", "Reinitializing PLAYERS table during PLAYER_ENTERING_WORLD")
            TWRA:UpdatePlayerTable() -- No parameters needed now
            
            -- Log the results
            local playerCount = TWRA:GetTableSize(TWRA.PLAYERS or {})
            TWRA:Debug("general", "PLAYERS table now contains " .. playerCount .. " entries")
        else
            TWRA:Debug("error", "UpdatePlayerTable function not available during PLAYER_ENTERING_WORLD")
        end
    else
        -- Call the regular event handler for other events
        TWRA:OnEvent(event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
    end
end)
frame:SetScript("OnLoad", function() TWRA:OnLoad(frame) end)

-- TWRA Performance Monitoring
-- Modify the slash command handler to support performance monitoring commands
SLASH_TWRA1 = "/twra"
SlashCmdList["TWRA"] = function(msg)
    -- Basic slash command handling
    TWRA:Debug("general", "Command received: " .. (msg or ""))
    
    -- Parse the message into tokens (simple split by whitespace)
    local args = {}
    local i = 1
    for word in string.gfind(msg, "%S+") do
        args[i] = string.lower(word)
        i = i + 1
    end
    
    -- Check for performance command first
    if args[1] == "perf" then
        -- Remove the first argument (perf) and pass the rest to HandlePerfCommand
        local perfArgs = {}
        for j = 2, i-1 do
            perfArgs[j-1] = args[j]
        end
        
        -- Call the performance command handler
        if TWRA.HandlePerfCommand then
            TWRA:HandlePerfCommand(perfArgs)
        else
            DEFAULT_CHAT_FRAME:AddMessage("TWRA: Performance monitoring system not initialized")
        end
        return
    end
    
    -- Check for debug command
    if args[1] == "debug" then
        -- Remove the first argument (debug) and pass the rest to HandleDebugCommand
        local debugArgs = {}
        for j = 2, i-1 do
            debugArgs[j-1] = args[j]
        end
        
        -- Call the debug command handler if it exists
        if TWRA.HandleDebugCommand then
            TWRA:HandleDebugCommand(debugArgs)
        else
            DEFAULT_CHAT_FRAME:AddMessage("TWRA Debug: Debug system not initialized")
        end
        return
    end
    
    -- Check for decursive commands
    if args[1] == "decursive" then
        -- Get the subcommand (if any)
        local subCommand = args[2] or ""
        
        if subCommand == "auto" then
            -- Toggle auto feature
            if TWRA_SavedVariables and TWRA_SavedVariables.options then
                local currentValue = TWRA_SavedVariables.options.decursivePrio or false
                TWRA_SavedVariables.options.decursivePrio = not currentValue
                DEFAULT_CHAT_FRAME:AddMessage("TWRA: Auto Decursive feature " .. 
                    (TWRA_SavedVariables.options.decursivePrio and "enabled" or "disabled"))
            else
                DEFAULT_CHAT_FRAME:AddMessage("TWRA: Could not save settings - SavedVariables not available")
            end
            return
        elseif subCommand == "on" then
            -- Turn on auto feature
            if TWRA_SavedVariables and TWRA_SavedVariables.options then
                TWRA_SavedVariables.options.decursivePrio = true
                DEFAULT_CHAT_FRAME:AddMessage("TWRA: Auto Decursive feature enabled")
            else
                DEFAULT_CHAT_FRAME:AddMessage("TWRA: Could not save settings - SavedVariables not available")
            end
            return
        elseif subCommand == "off" then
            -- Turn off auto feature
            if TWRA_SavedVariables and TWRA_SavedVariables.options then
                TWRA_SavedVariables.options.decursivePrio = false
                DEFAULT_CHAT_FRAME:AddMessage("TWRA: Auto Decursive feature disabled")
            else
                DEFAULT_CHAT_FRAME:AddMessage("TWRA: Could not save settings - SavedVariables not available")
            end
            return
        elseif subCommand == "update" then
            -- Update priority list without changing auto setting
            DEFAULT_CHAT_FRAME:AddMessage("TWRA: Updating Decursive priority list...")
            if TWRA.UpdateDecursivePriorityList then
                TWRA:UpdateDecursivePriorityList()
            else
                DEFAULT_CHAT_FRAME:AddMessage("TWRA: Decursive priority feature not initialized")
            end
            return
        else
            -- Show decursive help (this now runs when subCommand is empty or not recognized)
            DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA Decursive Commands|r:")
            DEFAULT_CHAT_FRAME:AddMessage("  /twra decursive auto - Toggle automatic updates")
            DEFAULT_CHAT_FRAME:AddMessage("  /twra decursive on - Enable automatic updates")
            DEFAULT_CHAT_FRAME:AddMessage("  /twra decursive off - Disable automatic updates")
            DEFAULT_CHAT_FRAME:AddMessage("  /twra decursive update - Update priority list now")
            return
        end
    end
    
    -- Command to toggle OSD visibility
    if msg == "osd" then
        if TWRA.ToggleOSD then
            local visible = TWRA:ToggleOSD()
            TWRA:Debug("osd", "OSD visibility toggled: " .. (visible and "shown" or "hidden"))
        else
            DEFAULT_CHAT_FRAME:AddMessage("TWRA: OSD system not initialized")
        end
        return
    end
    
    -- Navigation commands
    if msg == "next" then
        TWRA:Debug("nav", "Next section command received")
        TWRA:NavigateHandler(1)
        return
    elseif msg == "prev" then
        TWRA:Debug("nav", "Previous section command received")
        TWRA:NavigateHandler(-1)
        return
    elseif tonumber(msg) then
        local sectionNum = tonumber(msg)
        TWRA:Debug("nav", "Navigate to section " .. sectionNum .. " command received")
        TWRA:NavigateToSection(sectionNum)
        return
    end
    
    -- Command to explicitly show options
    if msg == "options" then
        if not TWRA.mainFrame then
            TWRA:CreateMainFrame()
        end
        TWRA.mainFrame:Show()
        TWRA:ShowOptionsView()
        TWRA:Debug("ui", "Options panel opened")
    -- Command to explicitly show the main frame
    elseif msg == "show" then
        if TWRA.mainFrame and not TWRA.mainFrame:IsShown() then
            TWRA.mainFrame:Show()
            TWRA:Debug("ui", "Window shown")
        elseif not TWRA.mainFrame then
            TWRA:CreateMainFrame()
            TWRA.mainFrame:Show()
            TWRA:Debug("ui", "Window created and shown")
        else
            TWRA:Debug("ui", "Window is already visible")
        end
    -- Command to explicitly hide the main frame
    elseif msg == "hide" then
        if TWRA.mainFrame and TWRA.mainFrame:IsShown() then
            TWRA.mainFrame:Hide()
            TWRA:Debug("ui", "Window hidden")
        else
            TWRA:Debug("ui", "Window is already hidden")
        end
    -- Command to reset UI to main view
    elseif msg == "resetview" then
        if TWRA.mainFrame then
            if TWRA.currentView == "options" then
                TWRA:ShowMainView()
            end
            TWRA:Debug("ui", "UI view reset to main view")
        end
    -- Command to toggle the main frame
    elseif msg == "toggle" or msg == "" then
        TWRA:ToggleMainFrame()
    else
        -- Show help message
        DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA Commands|r:")
        DEFAULT_CHAT_FRAME:AddMessage("  /twra - Toggle main window")
        DEFAULT_CHAT_FRAME:AddMessage("  /twra show - Show main window")
        DEFAULT_CHAT_FRAME:AddMessage("  /twra hide - Hide main window")
        DEFAULT_CHAT_FRAME:AddMessage("  /twra osd - Toggle on-screen display")
        DEFAULT_CHAT_FRAME:AddMessage("  /twra perf - Performance monitoring commands")
        DEFAULT_CHAT_FRAME:AddMessage("  /twra options - Open options panel")
        DEFAULT_CHAT_FRAME:AddMessage("  /twra resetview - Reset to main view")
        DEFAULT_CHAT_FRAME:AddMessage("  /twra next - Go to next section")
        DEFAULT_CHAT_FRAME:AddMessage("  /twra prev - Go to previous section")
        DEFAULT_CHAT_FRAME:AddMessage("  /twra # - Go to specific section number")
        DEFAULT_CHAT_FRAME:AddMessage("  /twra debug - Access debug commands")
        DEFAULT_CHAT_FRAME:AddMessage("  /twra decursive - Decursive priority list commands")
        DEFAULT_CHAT_FRAME:AddMessage("  Use '/twra perf' for performance monitoring options")
        DEFAULT_CHAT_FRAME:AddMessage("  Use '/twra debug' for detailed debug options")
        DEFAULT_CHAT_FRAME:AddMessage("  Use '/twra decursive' for Decursive priority list options")
    end
end

-- Timer functionality (needed for sync)
TWRA.timers = {}

-- Add ToggleMainFrame function to Core.lua
function TWRA:ToggleMainFrame()
    -- Fix for the double-toggle issue - check if frame is already being toggled
    if self.isTogglingMainFrame then
        self:Debug("ui", "Toggle operation already in progress, ignoring duplicate request")
        return
    end
    
    -- Set the flag with a built-in failsafe (will auto-reset after 1 second no matter what)
    self.isTogglingMainFrame = true
    self.isTogglingMainFrameTime = GetTime()

    -- SIMPLIFIED: check if frame exists and toggle visibility directly
    if not self.mainFrame then
        if self.CreateMainFrame then
            self:CreateMainFrame()
            -- Apply user preference for initial visibility (don't hide by default)
            if TWRA_SavedVariables.options.hideFrameByDefault then  -- Changed to boolean comparison
                self.mainFrame:Hide()
            else
                self.mainFrame:Show()
                -- Load content if showing the frame
                if self.LoadInitialContent then
                    self:LoadInitialContent()
                end
                self:Debug("ui", "Frame created and shown with content")
            end
        else
            self:Error("Unable to create main frame")
        end
    else
        -- Simple toggle - if shown, hide; if hidden, show
        if self.mainFrame:IsShown() then
            self.mainFrame:Hide()
            self:Debug("ui", "Window hidden")
        else
            self.mainFrame:Show()
            -- Load content when showing the frame
            if self.LoadInitialContent then
                self:LoadInitialContent()
            end
            self:Debug("ui", "Window shown with content")
        end
    end

    -- Immediately clear the flag instead of using a timer
    self.isTogglingMainFrame = nil
    
    -- Add a failsafe frame to ensure the flag gets cleared
    if not self.toggleMainFrameFailsafeFrame then
        self.toggleMainFrameFailsafeFrame = CreateFrame("Frame")
        self.toggleMainFrameFailsafeFrame:SetScript("OnUpdate", function()
            -- If the flag has been set for more than 1 second, force reset it
            if TWRA.isTogglingMainFrame and TWRA.isTogglingMainFrameTime and 
               (GetTime() - TWRA.isTogglingMainFrameTime > 1) then
                TWRA:Debug("ui", "Failsafe: resetting stuck toggle flag")
                TWRA.isTogglingMainFrame = nil
                TWRA.isTogglingMainFrameTime = nil
            end
        end)
    end
end

-- Replace NavigateHandler to use event system
function TWRA:NavigateHandler(delta)
    -- Safety checks
    if not self.navigation or not self.navigation.handlers then
        self:Debug("error", "NavigateHandler: No navigation or handlers")
        return
    end
    
    if not self.navigation.currentIndex then
        self.navigation.currentIndex = 1
    end
    
    -- Calculate the new index with bounds checking
    local newIndex = self.navigation.currentIndex + delta
    local maxIndex = table.getn(self.navigation.handlers)
    
    -- Wrap around navigation
    if newIndex < 1 then
        newIndex = maxIndex
    elseif newIndex > maxIndex then
        newIndex = 1
    end
    
    -- Use NavigateToSection for consistent event dispatching
    self:NavigateToSection(newIndex)
end

-- Helper function to rebuild navigation after data updates
function TWRA:RebuildNavigation()
    self:Debug("nav", "Building navigation from data")
    
    -- Initialize or reset navigation
    if not self.navigation then
        self.navigation = { handlers = {}, currentIndex = 1, sections = {}, sectionNames = {} }
    else
        -- Clear all navigation arrays
        self.navigation.handlers = {}
        self.navigation.sections = {}
        self.navigation.sectionNames = {}
    end
    
    -- Check if we have data to work with
    if not TWRA_Assignments or not TWRA_Assignments.data then
        self:Debug("error", "No data found for rebuilding navigation")
        return false
    end
    
    local data = TWRA_Assignments.data
    if not data or type(data) ~= "table" then 
        self:Debug("error", "Data is not a table or is empty for rebuilding navigation")
        return false
    end
    
    -- Build section information
    local sections = {}
    for i, section in pairs(data) do
        if section and type(section) == "table" and 
           (section["Section Name"] or section["sn"]) then
            local sectionName = section["Section Name"] or section["sn"]
            table.insert(self.navigation.sections, i)
            table.insert(self.navigation.sectionNames, sectionName)
            table.insert(self.navigation.handlers, sectionName) -- Keep compatibility with existing code
            table.insert(sections, sectionName) -- For debug output
        end
    end
    
    -- Set up current index if needed
    if not self.navigation.currentIndex or self.navigation.currentIndex < 1 or 
       self.navigation.currentIndex > table.getn(self.navigation.sections) then
        if table.getn(self.navigation.sections) > 0 then
            self.navigation.currentIndex = 1
            self:Debug("nav", "Reset current section to 1")
        else
            self.navigation.currentIndex = nil
            self:Debug("error", "No valid sections found")
            return false
        end
    end
    
    -- Report what we found
    local sectionCount = table.getn(self.navigation.sections)
    self:Debug("nav", "Built " .. sectionCount .. " sections from data")
    
    -- Show section names in debug output if available
    if sectionCount > 0 and table.getn(sections) > 0 then
        self:Debug("nav", "Section names: " .. table.concat(sections, ", "))
    end
    
    return true
end

-- Function to save the current section index
function TWRA:SaveCurrentSection(name)
    -- Only save if we have assignments already
    if TWRA_Assignments and self.navigation then
        -- Make sure currentIndex exists before trying to save it 
        if self.navigation.currentIndex then
            TWRA_Assignments.currentSection = self.navigation.currentIndex
            
            -- Also save the section name
            if self.navigation.handlers and 
               self.navigation.currentIndex <= table.getn(self.navigation.handlers) then
                local sectionName = self.navigation.handlers[self.navigation.currentIndex]
                TWRA_Assignments.currentSectionName = sectionName
                self:Debug("nav", "Saved current section: " .. self.navigation.currentIndex .. 
                            " (" .. sectionName .. ")")
            end
        else
            -- If no current index, default to 1
            TWRA_Assignments.currentSection = 1
            TWRA_Assignments.currentSectionName = nil
        end
    end
end

-- Add this function to ensure we have the necessary UI utilities
function TWRA:EnsureUIUtils()
    -- Ensure UI namespace exists
    TWRA.UI = TWRA.UI or {}
        
    -- Add other fallback functions if needed
    
    self:Debug("ui", "UI utils check complete")
    return true
end
TWRA:EnsureUIUtils()

-- Add emergency reset command for when things go wrong
function TWRA:ResetUI()
    self:Debug("ui", "Performing emergency UI reset")
    
    -- Hide UI if it exists
    if self.mainFrame then
        self.mainFrame:Hide()
    end
    
    -- Destroy any option panels that might be interfering
    if self.optionsContainer then
        self.optionsContainer:Hide()
        self.optionsContainer:SetParent(nil)
        self.optionsContainer = nil
    end
    
    -- Clear options elements array
    self.optionsElements = {}
    
    -- Reset the current view to main
    self.currentView = "main"
    
    self:Debug("ui", "UI reset complete")
end

-- Add helper function for the new format navigation
function TWRA:BuildNavigationFromNewFormat()
    -- Forward to the canonical implementation
    self:Debug("nav", "BuildNavigationFromNewFormat is deprecated - forwarding to RebuildNavigation")
    return self:RebuildNavigation()
end