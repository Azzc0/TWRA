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
    
    -- Set default for main frame visibility if it doesn't exist
    if TWRA_SavedVariables.options.hideFrameByDefault == nil then
        TWRA_SavedVariables.options.hideFrameByDefault = true
    end
    
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

    -- Check if debug slash command is already registered
    if not SlashCmdList["TWRADEBUG"] then
        SLASH_TWRADEBUG1 = "/twradebug"
        SlashCmdList["TWRADEBUG"] = function(msg)
            self:Debug("general", "Debug system not yet initialized. Try again in a moment.")
        end
    end

    -- Initialize UI systems
    TWRA.UI:InitializeDropdowns()
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
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Initialize on entering world
        self:Debug("general", "Player entered world")
        
        -- Ensure OSD is initialized when player enters world
        if self.InitOSD and (not self.minimapButton or not self.minimapButton:IsShown()) then
            self:Debug("ui", "Ensuring OSD is initialized on player enter world")
            self:InitOSD()
        end
    elseif event == "RAID_ROSTER_UPDATE" or event == "PARTY_MEMBERS_CHANGED" then
        -- Handle group composition changes
        if self.OnGroupChanged then
            self:OnGroupChanged()
        end
    end
end

-- Create frame for events
local frame = CreateFrame("Frame", "TWRAEventFrame")
frame:SetScript("OnEvent", function() TWRA:OnEvent(event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9) end)
frame:SetScript("OnLoad", function() TWRA:OnLoad() end)

-- Modify the slash command handler to support show/hide commands
SLASH_TWRA1 = "/twra"
SlashCmdList["TWRA"] = function(msg)
    -- Basic slash command handling
    TWRA:Debug("general", "Command received: " .. (msg or ""))
    
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
            if TWRA_SavedVariables.options.hideFrameByDefault then
                self.mainFrame:Hide()
            else
                self.mainFrame:Show()
                self:Debug("ui", "Frame created and shown")
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
            self:Debug("ui", "Window shown")
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
    if not self.fullData then return end
    
    -- Initialize or reset navigation
    if not self.navigation then
        self.navigation = { handlers = {}, currentIndex = 1 }
    else
        -- Keep the existing handlers array if it exists
        if not self.navigation.handlers then
            self.navigation.handlers = {}
        end
    end
    
    -- Use an ordered list to maintain section order
    local seenSections = {}
    
    -- First pass: collect sections in the order they appear in the data
    for i = 1, table.getn(self.fullData) do
        local sectionName = self.fullData[i][1]
        if sectionName and sectionName ~= "" and not seenSections[sectionName] then 
            seenSections[sectionName] = true  -- Mark as seen
            table.insert(self.navigation.handlers, sectionName)  -- Add to ordered list
        end
    end
    
    -- Debug output to verify sections
    if self.Debug then
        self:Debug("nav", "Built " .. table.getn(self.navigation.handlers) .. " sections: " .. 
                   table.concat(self.navigation.handlers, ", "))
    end
    
    return self.navigation.handlers
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

-- Navigate to a specific section by index or name
function TWRA:NavigateToSection(targetSection, suppressSync)
    -- Ensure navigation exists
    if not self.navigation then
        self.navigation = { handlers = {}, currentIndex = 1 }
    end
    
    -- If there are no handlers but we have data, rebuild the navigation
    if table.getn(self.navigation.handlers or {}) == 0 and self.fullData then
        self:RebuildNavigation()
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
        for i = 1, table.getn(handlers) do
            if handlers[i] == targetSection then
                sectionIndex = i
                sectionName = targetSection
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
    
    -- Always update the dropdown text
    if self.navigation.handlerText then
        self.navigation.handlerText:SetText(sectionName)
    end
    
    -- Save current section
    self:SaveCurrentSection()
    self:Debug("nav", "Navigated to section " .. sectionIndex .. " (" .. sectionName .. ")")
    
    -- Update display based on current view
    if self.currentView == "options" then
        if self.ClearRows then
            self:ClearRows()
        end
        self:Debug("nav", "Skipping display update while in options view")
    else
        if self.FilterAndDisplayHandler then
            self:FilterAndDisplayHandler(sectionName)
        end
    end
    
    -- Send internal message for OSD handling
    local isMainFrameVisible = self.mainFrame and self.mainFrame:IsShown() or false
    local inOptionsView = self.currentView == "options" or false
    local fromSync = suppressSync == "fromSync"
    
    -- Create a context table to pass all related info as a single argument
    local context = {
        isMainFrameVisible = isMainFrameVisible,
        inOptionsView = inOptionsView,
        fromSync = fromSync
    }
    
    self:SendMessage("SECTION_CHANGED", sectionName, sectionIndex, numSections, context)
    
    -- Broadcast to group if sync enabled and not suppressed
    if not suppressSync and self.SYNC and self.SYNC.liveSync and self.BroadcastSectionChange then
        self:BroadcastSectionChange(sectionIndex)
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
    if TWRA_SavedVariables and TWRA_SavedVariables.assignments and self.navigation then
        -- Make sure currentIndex exists before trying to save it 
        if self.navigation.currentIndex then
            TWRA_SavedVariables.assignments.currentSection = self.navigation.currentIndex
            
            -- Also save the section name
            if self.navigation.handlers and 
               self.navigation.currentIndex <= table.getn(self.navigation.handlers) then
                local sectionName = self.navigation.handlers[self.navigation.currentIndex]
                TWRA_SavedVariables.assignments.currentSectionName = sectionName
                self:Debug("nav", "Saved current section: " .. self.navigation.currentIndex .. 
                            " (" .. sectionName .. ")")
            end
        else
            -- If no current index, default to 1
            TWRA_SavedVariables.assignments.currentSection = 1
            TWRA_SavedVariables.assignments.currentSectionName = nil
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
    -- This will be overridden by UI modules 
    self:Debug("ui", "DisplayCurrentSection placeholder called")
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
    
    -- Add CreateIconWithTooltip if it doesn't exist
    if not TWRA.UI.CreateIconWithTooltip then
        self:Debug("ui", "Creating fallback CreateIconWithTooltip function")
        TWRA.UI.CreateIconWithTooltip = function(parent, texturePath, tooltipTitle, tooltipText, anchorFrame, offsetX, width, height)
            -- Create a container frame for the icon
            local iconFrame = CreateFrame("Frame", nil, parent)
            iconFrame:SetWidth(width or 16)
            iconFrame:SetHeight(height or 16)
            
            -- Position the frame
            if anchorFrame then
                iconFrame:SetPoint("LEFT", anchorFrame, "RIGHT", offsetX or 0, 0)
            else
                iconFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
            end
            
            -- Create the texture
            local icon = iconFrame:CreateTexture(nil, "ARTWORK")
            icon:SetAllPoints()
            icon:SetTexture(texturePath)
            
            -- Add tooltip functionality
            iconFrame:SetScript("OnEnter", function()
                GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
                GameTooltip:SetText(tooltipTitle, 1, 1, 1)
                if tooltipText then
                    GameTooltip:AddLine(tooltipText, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true)
                end
                GameTooltip:Show()
            end)
            
            iconFrame:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)
            
            return icon, iconFrame
        end
    end
    
    -- Add other fallback functions if needed
    
    self:Debug("ui", "UI utils check complete")
    return true
end

-- Call this function during initialization
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

-- Add this command to the slash commands in Core.lua
SLASH_TWRADBG1 = "/twradbg"
SlashCmdList["TWRADBG"] = function(msg)
    if msg == "paths" then
        TWRA:DebugFunctionPaths()
    elseif msg == "reset" then
        TWRA:ResetUI()
    elseif msg == "options" then
        TWRA:DebugOptions()
    elseif msg == "forceoptions" then
        -- Force options to show with our implementation
        TWRA:Debug("ui", "Forcing options to show with custom implementation")
        
        -- Make sure main frame exists
        if not TWRA.mainFrame then
            TWRA:CreateMainFrame()
        end
        
        -- Show the main frame
        TWRA.mainFrame:Show()
        
        -- Hide any interface options frame
        if InterfaceOptionsFrame then
            InterfaceOptionsFrame:Hide()
        end
        
        -- Switch to our options view
        TWRA:ShowOptionsView()
    else
        DEFAULT_CHAT_FRAME:AddMessage("TWRA Debug Commands:")
        DEFAULT_CHAT_FRAME:AddMessage("/twradbg paths - Check if required functions exist")
        DEFAULT_CHAT_FRAME:AddMessage("/twradbg reset - Emergency UI reset")
        DEFAULT_CHAT_FRAME:AddMessage("/twradbg options - Debug options system")
        DEFAULT_CHAT_FRAME:AddMessage("/twradbg forceoptions - Force custom options panel")
    end
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

-- Fix the SaveAssignments function to properly preserve current section
function TWRA:SaveAssignments(data, sourceString, originalTimestamp, noAnnounce)
    if not data or not sourceString then return end
    
    -- Use provided timestamp or generate new one
    local timestamp = originalTimestamp or time()
    
    -- Store current section before updating data
    local currentSectionIndex = 1
    local currentSectionName = nil
    if self.navigation and self.navigation.currentIndex then
        currentSectionIndex = self.navigation.currentIndex
        if self.navigation.handlers and self.navigation.currentIndex <= table.getn(self.navigation.handlers) then
            currentSectionName = self.navigation.handlers[self.navigation.currentIndex]
        end
        self:Debug("nav", "SaveAssignments - Current section before update: " .. 
                  currentSectionIndex .. " (" .. (currentSectionName or "unknown") .. ")")
    end
    
    -- Store the section information as pending for post-import navigation
    self.pendingSectionName = currentSectionName
    self.pendingSectionIndex = currentSectionIndex
    
    -- Update our full data in flat format for use in the current session
    self.fullData = data
    
    -- Check if this is the example data and set flag accordingly
    local isExampleData = (sourceString == "example_data" or self:IsExampleData(data))
    self.usingExampleData = isExampleData
    
    -- Rebuild navigation with new section names
    self:RebuildNavigation()
    
    -- Save the data, source string, and timestamps
    TWRA_SavedVariables.assignments = {
        data = data,
        source = sourceString,
        timestamp = timestamp,
        currentSection = currentSectionIndex,
        currentSectionName = currentSectionName, -- Store name for better restoration
        version = 1,
        isExample = isExampleData,
        usingExampleData = isExampleData
    }
    
    self:Debug("nav", "SaveAssignments - Saved with section: " .. 
                (currentSectionName or "unknown") .. " (" .. currentSectionIndex .. ")")
    
    -- Skip announcement if noAnnounce is true
    if noAnnounce then return end
    
    -- Announce update to group if we're in one
    if GetNumRaidMembers() > 0 or GetNumPartyMembers() > 0 then
        local announceMsg = string.format("%s:%d:%s", 
            self.SYNC.COMMANDS.ANNOUNCE,
            timestamp,
            UnitName("player"))
        
        self:SendAddonMessage(announceMsg)
    end
end
