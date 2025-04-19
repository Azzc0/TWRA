-- Turtle WoW Raid Assignments (TWRA)
-- Core initialization file

TWRA = TWRA or {}

function TWRA:OnLoad()
    -- Register for events
    this:RegisterEvent("ADDON_LOADED")
    this:RegisterEvent("CHAT_MSG_ADDON")
    this:RegisterEvent("PLAYER_ENTERING_WORLD")
    this:RegisterEvent("RAID_ROSTER_UPDATE")
    this:RegisterEvent("PARTY_MEMBERS_CHANGED")
    
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
        DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA Debug [event]:|r PLAYER_ENTERING_WORLD triggered")
        
        -- Create the main frame directly here but don't load content yet
        if not TWRA.mainFrame and TWRA.CreateMainFrame then
            TWRA:CreateMainFrame()
            TWRA.mainFrame:Hide() -- Ensure it's hidden by default
            DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA Debug [ui]:|r Main frame created and hidden directly from event handler")
            
            -- Set a flag to indicate we need to load content when user manually shows frame
            TWRA.needsInitialContentLoad = true
        end
        
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
frame:SetScript("OnLoad", function() TWRA:OnLoad() end)

-- Modify the slash command handler to support show/hide commands
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
        DEFAULT_CHAT_FRAME:AddMessage("  /twra options - Open options panel")
        DEFAULT_CHAT_FRAME:AddMessage("  /twra resetview - Reset to main view")
        DEFAULT_CHAT_FRAME:AddMessage("  /twra debug - Access debug commands")
        DEFAULT_CHAT_FRAME:AddMessage("  Use '/twra debug' for detailed debug options")
    end
end

-- Timer functionality (needed for sync)
TWRA.timers = {}

function TWRA:ScheduleTimer(callback, delay)
    if not callback or type(delay) ~= "number" then return end
    
    -- Create a unique ID for this timer
    local id = tostring({})  -- Simple way to get a unique string
    
    -- Store the timer info
    self.timers[id] = {
        callback = callback,
        expires = GetTime() + delay
    }
    
    -- If this is our first timer, start the update frame, create it if needed
    if not self.timerFrame then
        self.timerFrame = CreateFrame("Frame")
        self.timerFrame:SetScript("OnUpdate", function()
            -- Check all timers on each frame update
            local now = GetTime()
            for timerId, timer in pairs(TWRA.timers) do
                if timer.expires <= now then
                    -- Call the callback
                    timer.callback()
                    -- Remove the timer
                    TWRA.timers[timerId] = nil
                end
            end
        end)
    end
    
    return id
end

function TWRA:CancelTimer(timerId)
    if timerId then
        self.timers[timerId] = nil
    end
end

-- Add ToggleMainFrame function to Core.lua
function TWRA:ToggleMainFrame()
    -- Fix for the double-toggle issue - check if frame is already being toggled
    if self.isTogglingMainFrame then
        return
    end
    self.isTogglingMainFrame = true

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

    -- Clear the flag after a short delay using our own timer system
    self:ScheduleTimer(function() self.isTogglingMainFrame = nil end, 0.1)  -- Reduced delay
end

-- Add navigation handler for navigating to the previous or next section
function TWRA:NavigateHandler(delta)
    -- Ensure navigation exists
    if not self.navigation then
        self.navigation = { handlers = {}, currentIndex = 1 }
    end
    
    local nav = self.navigation
    
    -- Safety check for handlers
    if not nav.handlers or table.getn(nav.handlers) == 0 then
        self:Debug("nav", "No sections available to navigate")
        return
    end
    
    local newIndex = nav.currentIndex + delta
    if newIndex < 1 then 
        newIndex = table.getn(nav.handlers)
    elseif newIndex > table.getn(nav.handlers) then
        newIndex = 1
    end
    -- Use the central NavigateToSection function that handles syncing
    self:NavigateToSection(newIndex)
end

-- Helper function to rebuild navigation after data updates
function TWRA:RebuildNavigation()
    -- Initialize or reset navigation
    if not self.navigation then
        self.navigation = { handlers = {}, currentIndex = 1 }
    else
        -- IMPORTANT CHANGE: Always completely clear handlers array before rebuilding
        self.navigation.handlers = {}
    end
    
    -- Check if we have data to work with
    if not TWRA_Assignments or not TWRA_Assignments.data then
        self:Debug("error", "No assignment data available")
        return false
    end
    
    -- Special handling for the new format structure (table with numerical indices)
    if type(TWRA_Assignments.data) == "table" then
        -- Check if we're dealing with the new format (structured data)
        local isNewFormat = false
        for idx, section in pairs(TWRA_Assignments.data) do
            if type(section) == "table" and section["Section Name"] then
                isNewFormat = true
                break
            end
        end
        
        if isNewFormat then
            -- Collect section names from our new format structure
            local sections = {}
            for idx, section in pairs(TWRA_Assignments.data) do
                if type(section) == "table" and section["Section Name"] and section["Section Name"] ~= "" then
                    table.insert(self.navigation.handlers, section["Section Name"])
                    table.insert(sections, section["Section Name"])
                end
            end
            
            -- Report what we found
            local sectionCount = table.getn(self.navigation.handlers)
            self:Debug("nav", "Built " .. sectionCount .. " sections from new format")
            
            if sectionCount > 0 and table.getn(sections) > 0 then
                self:Debug("nav", "Section names: " .. table.concat(sections, ", "))
            end
            
            return true
        end
    end
    
    -- Fall back to old format handling
    if self.fullData then
        -- Use an ordered list to maintain section order
        local seenSections = {}
        
        -- First pass: collect sections in the order they appear in the data
        for i = 1, table.getn(self.fullData) do
            local sectionName = self.fullData[i][1]
            -- Stricter empty check and whitespace trimming
            if sectionName and sectionName ~= "" and string.gsub(sectionName, "%s", "") ~= "" and not seenSections[sectionName] then
                seenSections[sectionName] = true
                table.insert(self.navigation.handlers, sectionName)
            end
        end
        
        -- Debug output to verify sections
        self:Debug("nav", "Built " .. table.getn(self.navigation.handlers) .. " sections from old format")
        
        return true
    end
    
    -- No data found
    self:Debug("error", "No data found for rebuilding navigation")
    return false
end

-- Add an internal message system
TWRA.messageHandlers = {}

-- Register a handler for internal messages
function TWRA:RegisterMessageHandler(message, callback)
    if not self.messageHandlers[message] then
        self.messageHandlers[message] = {}
    end
    table.insert(self.messageHandlers[message], callback)
end

-- Send an internal message
function TWRA:SendMessage(message, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
    if not self.messageHandlers[message] then
        return -- No handlers registered
    end
    
    for _, callback in ipairs(self.messageHandlers[message]) do
        -- Use explicit arguments instead of ... unpacking
        callback(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
    end
end

-- Consolidated NavigateToSection function with messaging system integration
function TWRA:NavigateToSection(targetSection, suppressSync)
    -- Extended debug output
    self:Debug("nav", string.format("NavigateToSection(%s, %s) - mainFrame:%s, isShown:%s, currentView:%s",
        tostring(targetSection), 
        tostring(suppressSync),
        tostring(self.mainFrame),
        self.mainFrame and tostring(self.mainFrame:IsShown()) or "nil",
        tostring(self.currentView)))
    
    -- Ensure navigation exists
    if not self.navigation then
        self.navigation = { handlers = {}, currentIndex = 1 }
    end
    
    local handlers = self.navigation.handlers
    local numSections = table.getn(handlers)
    
    if numSections == 0 then 
        self:Debug("nav", "No sections available")
        return false
    end
    
    local sectionIndex = targetSection
    local sectionName = nil
    -- If sectionIndex is a string, find its index
    if type(targetSection) == "string" then
        for i, name in ipairs(handlers) do
            if name == targetSection then
                sectionIndex = i
                sectionName = name
                break
            end
        end
    else
        -- Make sure targetSection is within bounds
        sectionIndex = math.max(1, math.min(numSections, targetSection))
        sectionName = handlers[sectionIndex]
    end
    
    if not sectionName then
        self:Debug("nav", "Invalid section index: "..tostring(targetSection))
        return false
    end
    
    -- Update current index
    self.navigation.currentIndex = sectionIndex
    
    -- Save current section immediately
    self:SaveCurrentSection()
    
    -- Explicitly update UI elements that show section information
    if self.mainFrame and self.mainFrame:IsShown() then
        if self.navigation.handlerText then
            self.navigation.handlerText:SetText(sectionName)
        end
        
        -- Also update dropdown text if it exists
        if self.navigation.menuButton and self.navigation.menuButton.text then
            self.navigation.menuButton.text:SetText(sectionName)
        end
        
        -- Filter and display the selected section's data
        if self.FilterAndDisplayHandler then
            self:FilterAndDisplayHandler(sectionName)
            self:Debug("nav", "Updated main frame content for section: " .. sectionName)
        else
            self:Debug("error", "FilterAndDisplayHandler function not found")
        end
        
        -- And refresh the assignment table to show the new section
        if self.RefreshAssignmentTable then
            self:RefreshAssignmentTable()
        end
    end
    
    -- Determine if we should show OSD based on several factors
    local shouldShowOSD = false
    
    -- Case 1: Main frame is not visible
    if not self.mainFrame or not self.mainFrame:IsShown() then
        shouldShowOSD = true
    -- Case 2: We're in options view
    elseif self.currentView == "options" then
        shouldShowOSD = true
    -- Case 3: This is a sync-triggered navigation
    elseif suppressSync == "fromSync" then
        shouldShowOSD = true
    end
    
    self:Debug("nav", string.format("shouldShowOSD=%s (mainFrame:%s, isShown:%s, currentView:%s)",
        tostring(shouldShowOSD),
        tostring(self.mainFrame),
        self.mainFrame and tostring(self.mainFrame:IsShown()) or "nil",
        self.currentView or "nil"))
    
    -- Create context for section change message - with forceUpdate flag
    local context = {
        isMainFrameVisible = self.mainFrame and self.mainFrame:IsShown() or false,
        inOptionsView = self.currentView == "options" or false,
        fromSync = suppressSync == "fromSync",
        forceUpdate = true,  -- Always force OSD content update
        suppressSync = suppressSync -- Pass through the suppressSync flag directly to the event handler
    }
    
    -- Send section changed message which triggers OSD if appropriate
    self:SendMessage("SECTION_CHANGED", sectionName, sectionIndex, numSections, context)
    
    -- ALWAYS refresh OSD content, even if it isn't shown (it will be available to show on demand)
    if self.RefreshOSDContent then
        self:RefreshOSDContent()
    end
    
    -- If enabled, update tanks
    if self.SYNC and self.SYNC.tankSync and self:IsORA2Available() then
        self:UpdateTanks()
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

-- Basic implementation of CreateMainFrame (will be overridden by Frame.lua)
function TWRA:CreateMainFrame()
    self:Debug("ui", "Creating basic main frame (placeholder)")
    
    -- Initialize important UI namespace
    TWRA.UI = TWRA.UI or {}
    
    self.navigation = { handlers = {}, currentIndex = 1 }
    self.mainFrame = CreateFrame("Frame", "TWRAMainFrame", UIParent)
    self.mainFrame:SetWidth(800)
    self.mainFrame:SetHeight(300)
    self.mainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    
    -- Basic backdrop
    self.mainFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    
    -- Add the frame to UISpecialFrames so it can be closed with Escape key
    tinsert(UISpecialFrames, "TWRAMainFrame")
    
    -- Make the frame movable
    self.mainFrame:SetMovable(true)
    self.mainFrame:EnableMouse(true)
    self.mainFrame:RegisterForDrag("LeftButton")
    self.mainFrame:SetScript("OnDragStart", function() self.mainFrame:StartMoving() end)
    self.mainFrame:SetScript("OnDragStop", function() self.mainFrame:StopMovingOrSizing() end)
    
    -- Add a title
    local titleText = self.mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleText:SetPoint("TOP", 0, -15)
    titleText:SetText("Raid Assignments")
    
    -- Add a simple "Under Construction" message
    local constructionText = self.mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    constructionText:SetPoint("CENTER", 0, 0)
    constructionText:SetText("Loading addon components...")
    
    self.mainFrame:Hide() -- Initially hidden
    
    return self.mainFrame    
end

-- Add empty placeholder functions that will be overridden
function TWRA:DisplayCurrentSection()
    -- This is a placeholder that will be overridden by the implementation in ui/OSD.lua
    self:Debug("ui", "DisplayCurrentSection placeholder called - implementation should be in ui/OSD.lua")
end

-- Debug function placeholder in case Debug.lua hasn't loaded yet
if not TWRA.Debug then
    function TWRA:Debug(category, message)
        -- Simple debug output if the full debug system isn't loaded yet
        DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA Debug [" .. category .. "]:|r " .. (message or "nil"))
    end
    
    function TWRA:Error(message)
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF3333TWRA Error:|r " .. (message or "nil"))
    end
end

-- Add this function to the Core.lua file
function TWRA:InitializeUI()
    -- Initialize UI systems
    if self.UI then
        self:Debug("ui", "UI systems initialized")
    else
        self:Debug("error", "UI namespace not found, cannot initialize UI systems")
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

-- Add a function to check and debug the options system
function TWRA:DebugOptions()
    self:Debug("ui", "Debug options called")
    
    -- Check if options initialization exists
    self:Debug("ui", "InitOptions exists: " .. tostring(self.InitOptions ~= nil))
    
    -- Check if Options.lua implementation exists
    self:Debug("ui", "CreateOptionsInMainFrame exists: " .. tostring(self.CreateOptionsInMainFrame ~= nil))
    
    -- Check current view
    self:Debug("ui", "Current view: " .. (self.currentView or "nil"))
    
    -- Check options elements
    if self.optionsElements then
        self:Debug("ui", "Options elements count: " .. table.getn(self.optionsElements))
    else
        self:Debug("ui", "Options elements table doesn't exist")
    end
    
    -- Check if options are visible
    if self.optionsContainer then
        self:Debug("ui", "Options container exists and is " .. 
            (self.optionsContainer:IsShown() and "visible" or "hidden"))
    else
        self:Debug("ui", "Options container doesn't exist")
    end
    
    -- Search for rogue frames
    if self.mainFrame then
        self:Debug("ui", "Searching for InterfaceOptionsFrame children in mainFrame...")
        for i, child in ipairs({self.mainFrame:GetChildren()}) do
            if child:GetName() then
                self:Debug("ui", "Child " .. i .. ": " .. child:GetName() .. " (visible: " .. tostring(child:IsShown()) .. ")")
            else
                self:Debug("ui", "Child " .. i .. ": unnamed (visible: " .. tostring(child:IsShown()) .. ")")
            end
        end
    end
    
    return true
end

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

-- Consolidated SaveAssignments function incorporating both implementations
function TWRA:SaveAssignments(data, sourceString, originalTimestamp, noAnnounce)
    if not data then return end
    
    -- Check if this is our new format structure with ["data"] key
    local isNewFormat = false
    if type(data) == "table" and data.data and type(data.data) == "table" then
        isNewFormat = true
        self:Debug("data", "Detected new format structure in SaveAssignments")
        
        -- Make one final pass with EnsureCompleteRows to guarantee all indices are filled before saving
        if self.EnsureCompleteRows then
            data = self:EnsureCompleteRows(data)
            self:Debug("data", "Applied EnsureCompleteRows during SaveAssignments for new format")
        else
            self:Debug("error", "EnsureCompleteRows function not found during SaveAssignments")
        end
        
        -- NEW: Process special rows (Notes, Warnings, GUIDs) and move them to metadata
        if self.CaptureSpecialRows then
            data = self:CaptureSpecialRows(data)
            self:Debug("data", "Applied CaptureSpecialRows to extract special rows as metadata")
        end
        
        -- CRITICAL ADDITION: Preserve Section Metadata from existing sections
        if TWRA_Assignments and TWRA_Assignments.data and type(TWRA_Assignments.data) == "table" then
            self:Debug("data", "Preserving metadata from existing sections")
            
            for newSectionIdx, newSection in pairs(data.data) do
                if type(newSection) == "table" and newSection["Section Name"] then
                    local sectionName = newSection["Section Name"]
                    
                    -- Look for matching section in existing data
                    for _, oldSection in pairs(TWRA_Assignments.data) do
                        if type(oldSection) == "table" and oldSection["Section Name"] == sectionName then
                            -- Transfer section metadata if it exists
                            if oldSection["Section Metadata"] and type(oldSection["Section Metadata"]) == "table" then
                                newSection["Section Metadata"] = newSection["Section Metadata"] or {}
                                
                                -- Copy metadata arrays if they exist
                                for key, array in pairs(oldSection["Section Metadata"]) do
                                    if type(array) == "table" and (key == "Note" or key == "Warning" or key == "GUID") then
                                        newSection["Section Metadata"][key] = newSection["Section Metadata"][key] or {}
                                        
                                        -- Copy array values if they don't already exist
                                        for _, value in ipairs(array) do
                                            local exists = false
                                            for _, newValue in ipairs(newSection["Section Metadata"][key] or {}) do
                                                if newValue == value then
                                                    exists = true
                                                    break
                                                end
                                            end
                                            
                                            if not exists then
                                                table.insert(newSection["Section Metadata"][key], value)
                                                self:Debug("data", "Preserved metadata " .. key .. " for section " .. sectionName)
                                            end
                                        end
                                    end
                                end
                            end
                            
                            break -- Found matching section, no need to continue
                        end
                    end
                end
            end
        end
    end
    
    -- Calculate timestamp (or use provided one)
    local timestamp = originalTimestamp
    if not timestamp then
        if self:IsExampleData(data) then
            timestamp = 0
        else
            timestamp = time()
        end
    end
    
    -- Get current section info before we save
    local currentSectionName = nil
    local currentSectionIndex = 1
    
    if self.navigation and self.navigation.currentIndex and self.navigation.handlers then
        currentSectionIndex = self.navigation.currentIndex
        currentSectionName = self.navigation.handlers[currentSectionIndex]
        self:Debug("nav", "SaveAssignments - Current section before update: " .. 
                  currentSectionIndex .. " (" .. (currentSectionName or "unknown") .. ")")
    end
    
    -- Remember the section name for post-import navigation
    self.pendingSectionName = currentSectionName
    self.pendingSectionIndex = currentSectionIndex
    
    -- Handle new format directly
    if isNewFormat then
        -- Clear current data for clean import
        if self.ClearData then
            self:Debug("data", "Clearing current data")
            self:ClearData()
            self:Debug("data", "Data cleared successfully")
        end
        
        -- Direct assignment to SavedVariables for new format
        TWRA_Assignments = {
            data = data.data,
            -- IMPORTANT: Don't store source string to save memory
            timestamp = timestamp,
            currentSection = 1,  -- Start at first section for new imports
            version = 2,  -- Mark as new format
            isExample = false
        }
        
        -- IMPORTANT: Completely stop using old format data structure
        -- Instead of maintaining minimal structure, fully remove it
        if TWRA_SavedVariables and TWRA_SavedVariables.assignments then
            TWRA_SavedVariables.assignments = nil
            self:Debug("data", "Removed obsolete assignments data structure")
        end
        
        -- IMPORTANT: Generate compressed version for future sync
        if self.PrepareDataForSync and self.CompressAssignmentsData and self.StoreCompressedData then
            self:Debug("data", "Generating compressed data for future sync operations")
            local syncReadyData = self:PrepareDataForSync(TWRA_Assignments)
            local compressedData = self:CompressAssignmentsData(syncReadyData)
            if compressedData then
                self:StoreCompressedData(compressedData)
                self:Debug("data", "Compressed data generated and stored in TWRA_CompressedAssignments")
            else
                self:Debug("error", "Failed to generate compressed version of data")
            end
        else
            self:Debug("error", "Missing compression functions - compressed data not generated")
        end
        
        -- Build navigation from the imported sections
        self:BuildNavigationFromNewFormat()
        
        self:Debug("data", "Assigned new format data directly to SavedVariables")
        
        -- Skip announcement if noAnnounce is true
        if noAnnounce then return true end
        
        -- IMPORTANT: Don't announce in a party/raid during development
        if GetNumRaidMembers() > 0 or GetNumPartyMembers() > 0 then
            self:Debug("general", "Import detected while in party/raid - suppressing announcement")
            return true
        end
        
        -- Announce the import in chat
        DEFAULT_CHAT_FRAME:AddMessage("TWRA: Assigned imported data with " .. 
                                     table.getn(self.navigation.handlers) .. " sections")
        return true
    end
    
    -- Legacy format handling
    -- Clean the data using our centralized function
    data = self:CleanAssignmentData(data)
    
    -- Check if we have actual content after cleaning
    local contentFound = false
    if type(data) == "table" then
        contentFound = table.getn(data) > 0
    end
    
    if not contentFound then
        self:Debug("error", "No valid content found in input data")
        return false
    end
    
    -- Store in saved variables
    self.fullData = data
    
    -- Set up saved variables structure if it doesn't exist
    TWRA_Assignments = {
        data = data,
        -- IMPORTANT: Don't store source string to save memory
        timestamp = timestamp,
        currentSection = 1, -- Default to first section on import
        version = 1 -- Mark as v1 (legacy) format
    }
    
    -- IMPORTANT: Completely stop using old format data structure
    -- Instead of maintaining minimal structure, fully remove it
    if TWRA_SavedVariables and TWRA_SavedVariables.assignments then
        TWRA_SavedVariables.assignments = nil
        self:Debug("data", "Removed obsolete assignments data structure")
    end
    
    self:Debug("nav", "SaveAssignments - Saved with section: " .. 
               (currentSectionName or "None") .. " (index: " .. currentSectionIndex .. ")")
    self:Debug("data", "Data saved with timestamp: " .. timestamp)
    
    -- Skip announcement if noAnnounce is true
    if noAnnounce then return true end
    
    -- IMPORTANT: Don't announce in a party/raid during development
    if GetNumRaidMembers() > 0 or GetNumPartyMembers() > 0 then
        self:Debug("general", "Import detected while in party/raid - suppressing announcement")
        return true
    end
    
    -- Rebuild navigation with the new data
    self:RebuildNavigation()
    
    -- Announce the import in chat
    DEFAULT_CHAT_FRAME:AddMessage("TWRA: Imported " .. table.getn(self.fullData) .. 
                                 " assignments in " ..
                                 table.getn(self.navigation.handlers) .. " sections")
    return true
end

-- Add helper function for the new format navigation
function TWRA:BuildNavigationFromNewFormat()
    self:Debug("nav", "Building navigation from new format data")
    
    -- Initialize navigation structure
    self.navigation = self.navigation or { handlers = {}, currentIndex = 1 }
    self.navigation.handlers = {}
    self.navigation.currentIndex = 1
    
    -- Check if we have data to work with
    if not TWRA_Assignments or not TWRA_Assignments.data then
        self:Debug("error", "No assignment data available")
        return false
    end
    
    -- Collect section names from our new format structure
    local sections = {}
    for idx, section in pairs(TWRA_Assignments.data) do
        if type(section) == "table" and section["Section Name"] then
            table.insert(self.navigation.handlers, section["Section Name"])
            table.insert(sections, section["Section Name"])
        end
    end
    
    -- Report what we found
    local sectionCount = table.getn(self.navigation.handlers)
    self:Debug("nav", "Built " .. sectionCount .. " sections from new format")
    
    if sectionCount > 0 and table.getn(sections) > 0 then
        self:Debug("nav", "Section names: " .. table.concat(sections, ", "))
    end
    
    return (sectionCount > 0)
end

-- Add CreateMinimapButton function - moved from OSD.lua to TWRA.lua as requested
function TWRA:CreateMinimapButton()
    self:Debug("general", "Creating minimap button")
    
    -- Create a frame for our minimap button
    local miniButton = CreateFrame("Button", "TWRAMinimapButton", Minimap)
    miniButton:SetWidth(32)
    miniButton:SetHeight(32)
    miniButton:SetFrameStrata("MEDIUM")
    miniButton:SetFrameLevel(8)
    
    -- Set position (default to 180 degrees)
    local defaultAngle = 180
    local angle = defaultAngle
    
    -- Use saved angle if available
    if TWRA_SavedVariables and TWRA_SavedVariables.options and TWRA_SavedVariables.options.minimapAngle then
        angle = TWRA_SavedVariables.options.minimapAngle
    end
    
    -- Calculate position
    local radius = 80
    local radian = math.rad(angle)
    local x = math.cos(radian) * radius
    local y = math.sin(radian) * radius
    miniButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
    
    -- Set icon texture
    local icon = miniButton:CreateTexture(nil, "BACKGROUND")
    icon:SetTexture("Interface\\AddOns\\TWRA\\textures\\minimap_icon")
    
    -- If the custom texture doesn't exist, use a default
    if not icon:GetTexture() then
        icon:SetTexture("Interface\\FriendsFrame\\FriendsFrameScrollIcon")
    end
    
    icon:SetAllPoints(miniButton)
    miniButton.icon = icon
    
    -- Add highlight texture
    local highlight = miniButton:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    highlight:SetBlendMode("ADD")
    highlight:SetAllPoints(miniButton)
    miniButton.highlight = highlight
    
    -- Set up scripts
    miniButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(miniButton, "ANCHOR_LEFT")
        GameTooltip:AddLine("TWRA - Raid Assignments")
        GameTooltip:AddLine("Left-click: Toggle assignments window", 1, 1, 1)
        GameTooltip:AddLine("Right-click: Toggle assignments OSD", 1, 1, 1)
        GameTooltip:Show()
    end)
    miniButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    miniButton:SetScript("OnClick", function()
        if arg1 == "RightButton" then
            -- Right click: Toggle OSD
            if TWRA.ToggleOSD then
                TWRA:ToggleOSD()
            end
        else
            -- Left click: Toggle main window
            if TWRA.ToggleMainFrame then
                TWRA:ToggleMainFrame()
            else
                DEFAULT_CHAT_FRAME:AddMessage("TWRA: Main window not available")
            end
        end
    end)
    
    -- Make the button draggable
    miniButton:RegisterForDrag("LeftButton")
    miniButton:SetScript("OnDragStart", function()
        this:LockHighlight()
        this:StartMoving()
    end)
    miniButton:SetScript("OnDragStop", function()
        this:StopMovingOrSizing()
        this:UnlockHighlight()
        
        -- Calculate and save angle
        local x, y = this:GetCenter()
        local mx, my = Minimap:GetCenter()
        local angle = math.deg(math.atan2(y - my, x - mx))
        
        -- Save to settings
        if TWRA_SavedVariables and TWRA_SavedVariables.options then
            TWRA_SavedVariables.options.minimapAngle = angle
        end
    end)
    
    -- Store reference in addon
    self.minimapButton = miniButton
    
    self:Debug("general", "Minimap button created")
    return miniButton
end
TWRA:CreateMinimapButton()

-- Add this function to your Core.lua file to handle slash command registration

-- Register a custom slash command
function TWRA:RegisterSlashCommand(command, handler)
    if not command or not handler then return end
    
    -- Create a unique global name for this command
    local cmdName = "TWRA_CMD_" .. string.upper(command)
    
    -- Register the slash command
    _G["SLASH_" .. cmdName .. "1"] = "/" .. command
    _G[cmdName] = handler
    
    SlashCmdList[cmdName] = function(msg)
        handler(msg)
    end
    
    self:Debug("general", "Registered slash command: /" .. command)
end