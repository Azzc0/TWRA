-- TWRA Debug System
-- Manages debug messages with categories and configurable verbosity

TWRA = TWRA or {}

-- Debug category definitions 
TWRA.DEBUG_CATEGORIES = {
    general = { name = "General", default = true, description = "General debug messages" },
    ui = { name = "UI", default = true, description = "User interface events and updates" },
    sync = { name = "Sync", default = true, description = "Synchronization messages" },
    data = { name = "Data", default = false, description = "Detailed data processing messages" },
    nav = { name = "Navigation", default = true, description = "Section navigation events" },
    auto = { name = "Auto", default = true, description = "Automatic features" },
    tank = { name = "Tank", default = true, description = "Tank assignments" },
    osd = { name = "OSD", default = true, description = "On-screen display messages" },
    error = { name = "Error", default = true, description = "Errors and warnings" }
}

-- Debug level definitions
TWRA.DEBUG_LEVELS = {
    OFF = 0,    -- No debug output
    ERROR = 1,  -- Only errors
    WARN = 2,   -- Errors and warnings
    INFO = 3,   -- Normal information 
    VERBOSE = 4 -- All messages including detailed logs
}

-- Initialize debug settings
function TWRA:InitDebug()
    -- Create default settings if they don't exist
    if not TWRA_SavedVariables.debug then
        TWRA_SavedVariables.debug = {
            level = self.DEBUG_LEVELS.INFO,  -- Default to INFO level
            categories = {},                 -- Will be filled with default values
            timestamp = true,                -- Show timestamps by default
            frameNum = false,                -- Don't show frame numbers by default
            suppressCount = 0                -- Count of suppressed messages
        }
        
        -- Set default category values
        for category, info in pairs(self.DEBUG_CATEGORIES) do
            TWRA_SavedVariables.debug.categories[category] = info.default
        end
    end
    
    -- Create debug frame if needed
    if not self.debugFrame then
        self.debugFrame = CreateFrame("Frame")
        self.debugFrame.lastUpdate = GetTime()
        self.debugFrame.frameCount = 0
        self.debugFrame:SetScript("OnUpdate", function()
            -- Count frames for performance debugging
            self.debugFrame.frameCount = self.debugFrame.frameCount + 1
            
            -- Reset counter every second
            if GetTime() - self.debugFrame.lastUpdate > 1 then
                self.debugFrame.lastUpdate = GetTime()
                self.debugFrame.frameCount = 0
            end
        end)
    end
    
    -- Reset suppressed message count
    TWRA_SavedVariables.debug.suppressCount = 0
    
    self:Debug("general", "Debug system initialized")
end

-- Main debug function
function TWRA:Debug(category, message, level)
    -- Default level if not specified
    level = level or self.DEBUG_LEVELS.INFO
    
    -- Exit immediately if debugging is disabled or if level is too verbose
    if not TWRA_SavedVariables or not TWRA_SavedVariables.debug then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA|r: " .. message)
        return
    end
    
    -- Exit if debug level is below the requested level
    if TWRA_SavedVariables.debug.level < level then
        TWRA_SavedVariables.debug.suppressCount = TWRA_SavedVariables.debug.suppressCount + 1
        return
    end
    
    -- Exit if category is disabled
    if category ~= "error" and TWRA_SavedVariables.debug.categories[category] == false then
        TWRA_SavedVariables.debug.suppressCount = TWRA_SavedVariables.debug.suppressCount + 1
        return
    end
    
    -- Format message with optional components
    local msgPrefix = "|cFF33FF99TWRA|r"
    
    -- Add timestamp if enabled
    if TWRA_SavedVariables.debug.timestamp then
        local time = date("%H:%M:%S")
        msgPrefix = msgPrefix .. " [" .. time .. "]"
    end
    
    -- Add frame number if enabled
    if TWRA_SavedVariables.debug.frameNum and self.debugFrame then
        msgPrefix = msgPrefix .. " [" .. self.debugFrame.frameCount .. "]"
    end
    
    -- Add category
    local categoryInfo = self.DEBUG_CATEGORIES[category] or {}
    local categoryName = categoryInfo.name or category
    
    -- Color code based on level/category
    local categoryColor = "|cFFAAAAFF"
    if category == "error" then
        categoryColor = "|cFFFF3333"
    elseif level == self.DEBUG_LEVELS.WARN then
        categoryColor = "|cFFFFAA33"
    end
    
    msgPrefix = msgPrefix .. " " .. categoryColor .. "[" .. categoryName .. "]|r:"
    
    -- Add final message
    local fullMessage = msgPrefix .. " " .. message
    
    -- Output to chat frame
    DEFAULT_CHAT_FRAME:AddMessage(fullMessage)
end

-- Error logging - always shown even at minimal debug levels
function TWRA:Error(message)
    self:Debug("error", message, self.DEBUG_LEVELS.ERROR)
end

-- Warning logging - shown at WARN level and above
function TWRA:Warn(category, message)
    self:Debug(category, message, self.DEBUG_LEVELS.WARN)
end

-- Info logging - shown at INFO level and above (default)
function TWRA:Info(category, message)
    self:Debug(category, self.DEBUG_LEVELS.INFO)
end

-- Verbose logging - only shown at VERBOSE level
function TWRA:Verbose(category, message)
    self:Debug(category, message, self.DEBUG_LEVELS.VERBOSE)
end

-- Set debug level
function TWRA:SetDebugLevel(level)
    if not TWRA_SavedVariables.debug then 
        self:InitDebug()
    end
    
    TWRA_SavedVariables.debug.level = level
    self:Debug("general", "Debug level set to " .. level)
end

-- Enable/disable debug category
function TWRA:SetDebugCategory(category, enabled)
    if not TWRA_SavedVariables.debug then
        self:InitDebug()
    end
    
    if self.DEBUG_CATEGORIES[category] then
        TWRA_SavedVariables.debug.categories[category] = enabled
        self:Debug("general", "Debug category '" .. category .. "' " .. (enabled and "enabled" or "disabled"))
    else
        self:Error("Unknown debug category: " .. tostring(category))
    end
end

-- Show debug statistics
function TWRA:ShowDebugStats()
    local stats = {
        "Debug Level: " .. TWRA_SavedVariables.debug.level,
        "Suppressed Messages: " .. TWRA_SavedVariables.debug.suppressCount,
        "Active Categories:"
    }
    
    for category, enabled in pairs(TWRA_SavedVariables.debug.categories) do
        if enabled then
            table.insert(stats, "  - " .. category)
        end
    end
    
    for _, line in ipairs(stats) do
        DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA Debug|r: " .. line)
    end
end

-- Add debug slash command
SLASH_TWRADEBUG1 = "/twradebug"
SlashCmdList["TWRADEBUG"] = function(msg)
    local args = {}
    for arg in string.gmatch(msg, "%S+") do
        table.insert(args, string.lower(arg))
    end
    
    if args[1] == "level" then
        if not args[2] then
            TWRA:Debug("general", "Current debug level: " .. TWRA_SavedVariables.debug.level)
            return
        end
        
        local level = tonumber(args[2])
        if level and level >= 0 and level <= 4 then
            TWRA:SetDebugLevel(level)
        else
            TWRA:Error("Invalid debug level. Use 0-4 (OFF, ERROR, WARN, INFO, VERBOSE)")
        end
        
    elseif args[1] == "enable" and args[2] then
        TWRA:SetDebugCategory(args[2], true)
        
    elseif args[1] == "disable" and args[2] then
        TWRA:SetDebugCategory(args[2], false)
        
    elseif args[1] == "timestamp" then
        TWRA_SavedVariables.debug.timestamp = not TWRA_SavedVariables.debug.timestamp
        TWRA:Debug("general", "Timestamps " .. (TWRA_SavedVariables.debug.timestamp and "enabled" or "disabled"))
        
    elseif args[1] == "framenum" then
        TWRA_SavedVariables.debug.frameNum = not TWRA_SavedVariables.debug.frameNum
        TWRA:Debug("general", "Frame numbers " .. (TWRA_SavedVariables.debug.frameNum and "enabled" or "disabled"))
        
    elseif args[1] == "stats" then
        TWRA:ShowDebugStats()
        
    elseif args[1] == "categories" then
        TWRA:Debug("general", "Available debug categories:")
        for cat, info in pairs(TWRA.DEBUG_CATEGORIES) do
            local status = TWRA_SavedVariables.debug.categories[cat]
            status = status == nil and info.default or status
            TWRA:Debug("general", "  - " .. cat .. ": " .. (status and "enabled" or "disabled") .. " (" .. info.description .. ")")
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA Debug Commands|r:")
        DEFAULT_CHAT_FRAME:AddMessage("  /twradebug level [0-4] - Set debug level (0=Off, 1=Error, 2=Warn, 3=Info, 4=Verbose)")
        DEFAULT_CHAT_FRAME:AddMessage("  /twradebug enable <category> - Enable a debug category")
        DEFAULT_CHAT_FRAME:AddMessage("  /twradebug disable <category> - Disable a debug category")
        DEFAULT_CHAT_FRAME:AddMessage("  /twradebug categories - List all categories")
        DEFAULT_CHAT_FRAME:AddMessage("  /twradebug timestamp - Toggle timestamps")
        DEFAULT_CHAT_FRAME:AddMessage("  /twradebug framenum - Toggle frame numbers")
        DEFAULT_CHAT_FRAME:AddMessage("  /twradebug stats - Show debug statistics")
    end
end

-- TWRA Debug System
TWRA = TWRA or {}
TWRA.DEBUG = TWRA.DEBUG or {}

-- List to store early errors that occur before addon is fully loaded
TWRA.earlyErrors = TWRA.earlyErrors or {}
TWRA.worldLoaded = false -- Track if player has entered world

-- Global error handler to capture early errors 
-- (Will be replaced with our proper error handler once addon is fully loaded)
function TWRA_CaptureEarlyError(message)
    -- Create our addon table if it doesn't exist
    TWRA = TWRA or {}
    -- Create early errors array if it doesn't exist
    TWRA.earlyErrors = TWRA.earlyErrors or {}
    
    -- Add timestamp to the error
    local errorEntry = {
        time = GetTime(),
        message = message
    }
    
    -- Store error in our list for proper processing later - don't print immediately
    table.insert(TWRA.earlyErrors, errorEntry)
    
    -- Return the error so the default handler still processes it
    return message
end

-- Register our early error handler (will be replaced later)
local oldErrorHandler = geterrorhandler()
seterrorhandler(TWRA_CaptureEarlyError)

-- Initialize debug categories from constants
function TWRA:InitializeDebugSystem()
    -- Copy category definitions from constants
    if TWRA.DEBUG_DEFAULTS and TWRA.DEBUG_DEFAULTS.CATEGORIES then
        self.DEBUG.CATEGORIES = {}
        for category, details in pairs(TWRA.DEBUG_DEFAULTS.CATEGORIES) do
            self.DEBUG.CATEGORIES[category] = {
                name = details.name,
                description = details.description,
                enabled = details.enabled
            }
        end
    else
        -- Fallback if constants not loaded
        self.DEBUG.CATEGORIES = {
            general = { name = "General", description = "Core addon functionality", enabled = false },
            ui = { name = "User Interface", description = "UI creation and updates", enabled = false },
            data = { name = "Data Processing", description = "Assignment data handling", enabled = false },
            sync = { name = "Synchronization", description = "Raid sync and communication", enabled = false },
            nav = { name = "Navigation", description = "Section navigation handling", enabled = false },
            osd = { name = "On-Screen Display", description = "OSD notifications and updates", enabled = false }
        }
    end

    -- Copy colors from constants
    if TWRA.DEBUG_DEFAULTS and TWRA.DEBUG_DEFAULTS.COLORS then
        self.DEBUG.colors = {}
        for category, color in pairs(TWRA.DEBUG_DEFAULTS.COLORS) do
            self.DEBUG.colors[category] = color
        end
    else
        -- Fallback if constants not loaded
        self.DEBUG.colors = {
            general = "FFFFFF",  -- White
            ui = "33FF33",       -- Green
            data = "33AAFF",     -- Light Blue
            sync = "FF33FF",     -- Pink
            nav = "FFAA33",      -- Orange
            osd = "FFFF33",      -- Yellow
            error = "FF0000",    -- Red
            warning = "FFAA00",  -- Orange
            details = "AAAAAA"   -- Gray
        }
    end

    -- Create simplified category tracking
    self.DEBUG.categories = {}
    for category, _ in pairs(self.DEBUG.CATEGORIES) do
        self.DEBUG.categories[category] = false
    end

    -- Set default values
    self.DEBUG.enabled = TWRA.DEBUG_DEFAULTS and TWRA.DEBUG_DEFAULTS.ENABLED or false
    self.DEBUG.logLevel = TWRA.DEBUG_DEFAULTS and TWRA.DEBUG_DEFAULTS.LOG_LEVEL or 3
    self.DEBUG.showDetails = TWRA.DEBUG_DEFAULTS and TWRA.DEBUG_DEFAULTS.SHOW_DETAILS or false
    
    -- Don't process early errors yet - wait for world load
    -- We'll process them when PLAYER_ENTERING_WORLD fires
end

-- Process early errors after debug system is initialized and player enters world
function TWRA:ProcessEarlyErrors()
    -- Don't process if player hasn't entered world yet or no errors exist
    if not self.worldLoaded or not self.earlyErrors or table.getn(self.earlyErrors) == 0 then
        return
    end
    
    -- Process each early error through our debug system
    for _, errorEntry in ipairs(self.earlyErrors) do
        local timeStr = string.format("%.2f", errorEntry.time)
        self:Debug("error", "[" .. timeStr .. "s] " .. errorEntry.message, true)
    end
    
    -- Clear early errors once processed
    self.earlyErrors = {}
end

-- Our proper error handler that will replace the early one
function TWRA_ErrorHandler(message)
    -- Make sure TWRA exists
    if not TWRA then
        return message
    end
    
    -- Log the error through our Debug system if it's initialized
    if TWRA.DEBUG and TWRA.DEBUG.initialized then
        TWRA:Debug("error", message)
    else
        -- Fall back to the early error capture if Debug isn't ready
        TWRA_CaptureEarlyError(message)
    end
    
    -- Return the error so the default handler still processes it
    return message
end

-- Initialize the debug system and load saved settings
function TWRA:InitializeDebug()
    -- Skip if already initialized
    if self.DEBUG and self.DEBUG.initialized then
        return
    end
    
    -- Initialize debug system structure with defaults first
    self:InitializeDebugSystem()
    
    -- Ensure TWRA_SavedVariables exists
    TWRA_SavedVariables = TWRA_SavedVariables or {}
    
    -- Create saved vars structure if needed with proper defaults
    if not TWRA_SavedVariables.debug then
        TWRA_SavedVariables.debug = {
            enabled = false, -- Default to disabled
            categories = {},
            logLevel = 3, -- Default to standard debug level
            showDetails = false -- Default to no details
        }
    end
    
    -- Load saved debug settings - explicitly check each value
    local savedDebug = TWRA_SavedVariables.debug
    
    -- FIX: Explicitly convert to proper boolean value, not just nil check
    -- Some Lua implementations might store 1/0 instead of true/false in savedvars
    if savedDebug.enabled ~= nil then
        -- Convert to actual boolean to ensure consistent type
        if savedDebug.enabled == 1 or savedDebug.enabled == true then
            self.DEBUG.enabled = true
        else
            self.DEBUG.enabled = false
        end
    end
    
    -- Use the saved log level
    if savedDebug.logLevel ~= nil then
        self.DEBUG.logLevel = savedDebug.logLevel
    end
    
    -- Use the saved showDetails setting - also ensure proper boolean conversion
    if savedDebug.showDetails ~= nil then
        if savedDebug.showDetails == 1 or savedDebug.showDetails == true then
            self.DEBUG.showDetails = true
        else
            self.DEBUG.showDetails = false
        end
    end
    
    -- Ensure categories table exists
    savedDebug.categories = savedDebug.categories or {}
    
    -- Apply saved category settings to each category
    for category, _ in pairs(self.DEBUG.categories) do
        -- Only apply if the category exists in saved vars, handle boolean conversion
        if savedDebug.categories[category] ~= nil then
            -- Convert to actual boolean
            if savedDebug.categories[category] == 1 or savedDebug.categories[category] == true then
                self.DEBUG.categories[category] = true
            else
                self.DEBUG.categories[category] = false
            end
            
            -- Also update the CATEGORIES table for UI display
            if self.DEBUG.CATEGORIES[category] then
                self.DEBUG.CATEGORIES[category].enabled = self.DEBUG.categories[category]
            end
        end
        
        -- Ensure the category exists in saved vars for next time
        savedDebug.categories[category] = self.DEBUG.categories[category]
    end
    
    -- When full debug was enabled, make sure ALL categories get enabled
    if self.DEBUG.enabled and self.DEBUG.logLevel == 4 and self.DEBUG.showDetails then
        for category, _ in pairs(self.DEBUG.categories) do
            self.DEBUG.categories[category] = true
            -- Also update the CATEGORIES table for UI display
            if self.DEBUG.CATEGORIES[category] then
                self.DEBUG.CATEGORIES[category].enabled = true
            end
            -- Ensure saved in savedvars too
            savedDebug.categories[category] = true
        end
    end
    
    -- FIX: Mark debug as initialized to prevent double-initialization
    self.DEBUG.initialized = true
    
    -- Make a clean normalized copy to ensure everything is saved properly
    TWRA_SavedVariables.debug = {
        enabled = self.DEBUG.enabled,
        logLevel = self.DEBUG.logLevel,
        showDetails = self.DEBUG.showDetails,
        categories = {}
    }
    
    -- Copy categories explicitly to avoid reference issues
    for category, value in pairs(savedDebug.categories) do
        TWRA_SavedVariables.debug.categories[category] = value
    end
    
    -- Now that debug is fully initialized, replace the error handler
    seterrorhandler(TWRA_ErrorHandler)
end

-- Debug output function with category filtering and detail level support
function TWRA:Debug(category, message, forceOutput, isDetail)
    -- Skip output if world hasn't loaded yet and not forcing output
    if not self.worldLoaded and not forceOutput then
        -- Capture as early error to display later
        TWRA_CaptureEarlyError((category ~= "error" and "[" .. category .. "] " or "") .. message)
        return
    end
    
    -- Always allow forced output regardless of settings
    if forceOutput then
        -- Use consistent formatting for forced output too
        local color = self.DEBUG.colors[category] or "FFFFFF"
        DEFAULT_CHAT_FRAME:AddMessage("|cFF" .. color .. "[TWRA: " .. (category or "Debug") .. "]|r " .. message)
        return
    end
    
    -- Handle boolean toggle case
    if type(category) == "boolean" then
        self.DEBUG.enabled = category
        -- Update all categories to match master setting
        for cat in pairs(self.DEBUG.categories) do
            self.DEBUG.categories[cat] = category
            
            -- Also update the CATEGORIES table for UI display
            if self.DEBUG.CATEGORIES[cat] then
                self.DEBUG.CATEGORIES[cat].enabled = category
            end
        end
        
        -- Save to saved variables
        if TWRA_SavedVariables and TWRA_SavedVariables.debug then
            TWRA_SavedVariables.debug.enabled = category
            TWRA_SavedVariables.debug.categories = TWRA_SavedVariables.debug.categories or {}
            
            for cat in pairs(self.DEBUG.categories) do
                TWRA_SavedVariables.debug.categories[cat] = category
            end
        end
        
        DEFAULT_CHAT_FRAME:AddMessage("TWRA: Debug mode " .. (category and "enabled" or "disabled"))
        return
    end
    
    -- Handle single string parameter case (general debug)
    if type(category) == "string" and message == nil then
        message = category
        category = "general"
    end
    
    -- Skip output if debug is disabled or category is disabled
    if not self.DEBUG.enabled then
        return
    end
    
    -- Skip detail messages if showDetails is off
    if isDetail and not self.DEBUG.showDetails then
        return
    end
    
    if not category or not self.DEBUG.categories[category] then
        return
    end
    
    -- Format and output the message using the correct color
    local color = self.DEBUG.colors[category] or "FFFFFF"
    -- Use simplified format for all debug messages: [Category] message
    if isDetail then
        -- Add "DETAIL" marker to detailed logs
        DEFAULT_CHAT_FRAME:AddMessage("|cFF" .. color .. "[TWRA: " .. category .. " DETAIL]|r " .. message)
    else
        DEFAULT_CHAT_FRAME:AddMessage("|cFF" .. color .. "[TWRA: " .. category .. "]|r " .. message)
    end
end

-- Toggle debug mode globally
function TWRA:ToggleDebug(enable)
    if enable == nil then
        enable = not self.DEBUG.enabled
    end
    
    -- FIX: Ensure the value is an actual boolean, not just truthy
    if enable == 1 or enable == true then
        self.DEBUG.enabled = true
    else
        self.DEBUG.enabled = false
    end
    
    -- CRITICAL FIX: Ensure proper data structure exists
    TWRA_SavedVariables = TWRA_SavedVariables or {}
    TWRA_SavedVariables.debug = TWRA_SavedVariables.debug or {
        categories = {},
        logLevel = 3,
        showDetails = false
    }
    
    -- Save to the saved variables with proper boolean value
    TWRA_SavedVariables.debug.enabled = (self.DEBUG.enabled == true)
    
    -- FIX: Use direct assignment instead of _G approach
    -- This approach is compatible with older Lua versions
    -- Now use a more direct approach to update the saved variables
    DEFAULT_CHAT_FRAME:AddMessage("TWRA: Committing debug settings immediately")
    
    -- CRITICAL FIX: Force save by doing a full re-assignment
    -- Handle all categories too
    for cat in pairs(self.DEBUG.categories) do
        TWRA_SavedVariables.debug.categories = TWRA_SavedVariables.debug.categories or {}
        TWRA_SavedVariables.debug.categories[cat] = (self.DEBUG.categories[cat] == true)
    end
    
    -- Skip the detailed debug messages here
    DEFAULT_CHAT_FRAME:AddMessage("|cFF33AAFF[TWRA: Debug]|r Mode " .. (self.DEBUG.enabled and "enabled" or "disabled"))
end

-- Toggle a specific debug category
function TWRA:ToggleDebugCategory(category, enable)
    if not self.DEBUG.categories[category] then
        return
    end
    
    if enable == nil then
        enable = not self.DEBUG.categories[category]
    end
    
    self.DEBUG.categories[category] = enable
    
    -- Save to the saved variables
    if TWRA_SavedVariables then
        TWRA_SavedVariables.debug = TWRA_SavedVariables.debug or {}
        TWRA_SavedVariables.debug.categories = TWRA_SavedVariables.debug.categories or {}
        TWRA_SavedVariables.debug.categories[category] = enable
    end
    
    -- Also update the CATEGORIES table for UI display
    if self.DEBUG.CATEGORIES[category] then
        self.DEBUG.CATEGORIES[category].enabled = enable
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("TWRA: Debug category '" .. 
                                 (self.DEBUG.CATEGORIES[category] and self.DEBUG.CATEGORIES[category].name or category) .. 
                                 "' " .. (enable and "enabled" or "disabled"))
end

-- Add debug panel to options
function TWRA:CreateDebugOptionsPanel(parent)
    -- Create a container frame
    local debugPanel = CreateFrame("Frame", nil, parent)
    debugPanel:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -10)
    debugPanel:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -10, 10)
    
    -- Add title
    local title = debugPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 0, 0)
    title:SetText("Debug Options")
    
    -- Add global debug toggle
    local globalToggle = CreateFrame("CheckButton", nil, debugPanel, "UICheckButtonTemplate")
    globalToggle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
    globalToggle:SetChecked(self.DEBUG.enabled)
    
    local globalText = debugPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    globalText:SetPoint("LEFT", globalToggle, "RIGHT", 5, 0)
    globalText:SetText("Enable Debug Mode")
    
    globalToggle:SetScript("OnClick", function()
        self:ToggleDebug(globalToggle:GetChecked())
        self:UpdateDebugCategoryToggles(debugPanel)
    end)
    
    -- Add category toggles
    local yOffset = -40
    local categoryToggles = {}
    
    for category, settings in pairs(self.DEBUG.CATEGORIES) do
        local toggle = CreateFrame("CheckButton", nil, debugPanel, "UICheckButtonTemplate")
        toggle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 20, yOffset)
        toggle:SetChecked(settings.enabled)
        
        local text = debugPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("LEFT", toggle, "RIGHT", 5, 0)
        text:SetText(settings.name)
        
        -- Add tooltip with description
        toggle:SetScript("OnEnter", function()
            GameTooltip:SetOwner(toggle, "ANCHOR_RIGHT")
            GameTooltip:AddLine(settings.name)
            GameTooltip:AddLine(settings.description, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        
        toggle:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        
        -- Toggle the category when clicked
        toggle:SetScript("OnClick", function()
            self:ToggleDebugCategory(category, toggle:GetChecked())
        end)
        
        -- Store reference to update state
        categoryToggles[category] = toggle
        
        yOffset = yOffset - 25
    end
    
    -- Function to update category toggles based on global state
    function self:UpdateDebugCategoryToggles()
        for category, toggle in pairs(categoryToggles) do
            -- Set enabled state based on global toggle
            if not self.DEBUG.enabled then
                -- Can't use SetEnabled() in vanilla WoW - use different approach
                if toggle:IsEnabled() ~= false then
                    toggle:Disable()
                end
                toggle:SetAlpha(0.5)
            else
                -- Can't use SetEnabled() in vanilla WoW - use different approach
                if not toggle:IsEnabled() then
                    toggle:Enable()
                end
                toggle:SetAlpha(1.0)
            end
        end
    end
    
    -- Initial update
    self:UpdateDebugCategoryToggles()
    
    return debugPanel
end

-- Add this debug panel to the options frame
function TWRA:AddDebugTab()
    if not self.optionsTabFrame then
        return -- Options tab frame doesn't exist
    end
    
    -- Create the debug tab
    local debugTab = self:CreateDebugOptionsPanel(self.optionsTabFrame)
    
    -- Add tab to the tab frame
    self:AddOptionTab("Debug", debugTab)
end

-- Enable full debugging quickly for emergency troubleshooting
function TWRA:EnableFullDebug()
    self.DEBUG.enabled = true
    self.DEBUG.logLevel = 4
    self.DEBUG.showDetails = true
    
    -- Update all categories to be enabled
    for cat in pairs(self.DEBUG.categories) do
        self.DEBUG.categories[cat] = true
        
        -- Also update the CATEGORIES table for UI display
        if self.DEBUG.CATEGORIES[cat] then
            self.DEBUG.CATEGORIES[cat].enabled = true
        end
    end
    
    -- Explicitly save to saved variables to ensure persistence
    TWRA_SavedVariables = TWRA_SavedVariables or {}
    TWRA_SavedVariables.debug = TWRA_SavedVariables.debug or {}
    TWRA_SavedVariables.debug.enabled = true
    TWRA_SavedVariables.debug.logLevel = 4
    TWRA_SavedVariables.debug.showDetails = true
    TWRA_SavedVariables.debug.categories = TWRA_SavedVariables.debug.categories or {}
    
    -- Save each category explicitly
    for cat in pairs(self.DEBUG.categories) do
        TWRA_SavedVariables.debug.categories[cat] = true
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("TWRA: |cFFFF0000FULL DEBUG MODE ENABLED|r")
    
    -- Verify that settings are saved
    DEFAULT_CHAT_FRAME:AddMessage("TWRA: Debug settings have been saved and will persist through UI reloads.")
    
    -- CRITICAL FIX: Return true so we can verify in other functions
    return true
end

-- Toggle detailed logging
function TWRA:ToggleDetailedLogging(state)
    if state == nil then
        state = not self.DEBUG.showDetails
    end
    
    self.DEBUG.showDetails = state
    
    -- Save to saved variables - add check to ensure DEBUG exists
    if TWRA_SavedVariables then
        TWRA_SavedVariables.debug = TWRA_SavedVariables.debug or {}
        TWRA_SavedVariables.debug.showDetails = state
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("TWRA: Detailed logging " .. (state and "enabled" or "disabled"))
    
    -- If enabling details, make sure level is appropriate
    if state and self.DEBUG.logLevel < 4 then
        self.DEBUG.logLevel = 4
        if TWRA_SavedVariables and TWRA_SavedVariables.debug then
            TWRA_SavedVariables.debug.logLevel = 4
        end
    end
end

-- Set the debug log level
function TWRA:SetDebugLevel(level)
    if type(level) ~= "number" or level < 1 or level > 4 then
        DEFAULT_CHAT_FRAME:AddMessage("TWRA: Invalid debug level. Must be 1-4")
        return
    end
    
    self.DEBUG.logLevel = level
    
    -- Save to saved variables
    if TWRA_SavedVariables then
        TWRA_SavedVariables.debug = TWRA_SavedVariables.debug or {}
        TWRA_SavedVariables.debug.logLevel = level
    end
    
    local levelNames = {
        "Errors only", 
        "Errors and warnings", 
        "Standard debug messages",
        "All messages including detailed logs"
    }
    DEFAULT_CHAT_FRAME:AddMessage("TWRA: Debug level set to " .. level .. " (" .. levelNames[level] .. ")")
    
    -- If level is 4, automatically enable detailed logging
    if level == 4 and not self.DEBUG.showDetails then
        self:ToggleDetailedLogging(true)
    end
end

-- Create Debug Options Popup
function TWRA:CreateDebugPopup()
    local popup = CreateFrame("Frame", "TWRA_DebugPopup", UIParent)
    popup:SetFrameStrata("DIALOG")
    popup:SetWidth(300)
    popup:SetHeight(400)
    popup:SetPoint("CENTER", UIParent, "CENTER")
    
    -- Add backdrop
    popup:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    
    -- Add title
    local title = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", popup, "TOP", 0, -20)
    title:SetText("Debug Options")
    
    -- Add close button
    local closeBtn = CreateFrame("Button", nil, popup, "UIPanelCloseButton")
    closeBtn:SetPoint("TOPRIGHT", popup, "TOPRIGHT", -5, -5)
    
    -- Add global debug toggle
    local globalToggle = CreateFrame("CheckButton", nil, popup, "UICheckButtonTemplate")
    globalToggle:SetPoint("TOPLEFT", popup, "TOPLEFT", 20, -50)
    globalToggle:SetChecked(self.DEBUG.enabled)
    
    local globalText = popup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    globalText:SetPoint("LEFT", globalToggle, "RIGHT", 5, 0)
    globalText:SetText("Enable Debug Mode")
    
    globalToggle:SetScript("OnClick", function()
        self:ToggleDebug(globalToggle:GetChecked())
        self:UpdateDebugTogglesInPopup()
    end)
    
    -- Add debug level slider
    local levelSlider = CreateFrame("Slider", "TWRA_DebugLevelSlider", popup, "OptionsSliderTemplate")
    levelSlider:SetPoint("TOPLEFT", globalToggle, "BOTTOMLEFT", 0, -30)
    levelSlider:SetWidth(260)
    levelSlider:SetHeight(16)
    levelSlider:SetMinMaxValues(1, 4)
    levelSlider:SetValueStep(1)
    levelSlider:SetValue(self.DEBUG.logLevel or 3)
    levelSlider:SetOrientation("HORIZONTAL")
    
    -- Set slider text
    getglobal(levelSlider:GetName() .. "Low"):SetText("Errors Only")
    getglobal(levelSlider:GetName() .. "High"):SetText("All")
    getglobal(levelSlider:GetName() .. "Text"):SetText("Debug Level: " .. (self.DEBUG.logLevel or 3))
    
    levelSlider:SetScript("OnValueChanged", function()
        local value = math.floor(levelSlider:GetValue())
        getglobal(levelSlider:GetName() .. "Text"):SetText("Debug Level: " .. value)
        self:SetDebugLevel(value)
    end)
    
    -- Add detailed logging toggle
    local detailsToggle = CreateFrame("CheckButton", nil, popup, "UICheckButtonTemplate")
    detailsToggle:SetPoint("TOPLEFT", levelSlider, "BOTTOMLEFT", 0, -20)
    detailsToggle:SetChecked(self.DEBUG.showDetails)
    
    local detailsText = popup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    detailsText:SetPoint("LEFT", detailsToggle, "RIGHT", 5, 0)
    detailsText:SetText("Show Detailed Logs")
    
    detailsToggle:SetScript("OnClick", function()
        self:ToggleDetailedLogging(detailsToggle:GetChecked())
    end)
    
    -- Add category toggles
    local yOffset = -160
    popup.categoryToggles = {}
    
    -- Category section title
    local catTitle = popup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    catTitle:SetPoint("TOPLEFT", popup, "TOPLEFT", 20, yOffset)
    catTitle:SetText("Debug Categories")
    
    yOffset = yOffset - 25
    
    for category, settings in pairs(self.DEBUG.CATEGORIES) do
        local toggle = CreateFrame("CheckButton", nil, popup, "UICheckButtonTemplate")
        toggle:SetPoint("TOPLEFT", popup, "TOPLEFT", 30, yOffset)
        toggle:SetChecked(settings.enabled)
        
        local text = popup:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        text:SetPoint("LEFT", toggle, "RIGHT", 5, 0)
        text:SetText(settings.name)
        
        -- Add tooltip with description
        toggle:SetScript("OnEnter", function()
            GameTooltip:SetOwner(toggle, "ANCHOR_RIGHT")
            GameTooltip:AddLine(settings.name)
            GameTooltip:AddLine(settings.description, 1, 1, 1, true)
            GameTooltip:Show()
        end)
        
        toggle:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        
        -- Toggle the category when clicked
        toggle:SetScript("OnClick", function()
            self:ToggleDebugCategory(category, toggle:GetChecked())
        end)
        
        -- Store reference to update state
        popup.categoryToggles[category] = toggle
        
        yOffset = yOffset - 25
    end
    
    -- Add status button
    local statusBtn = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
    statusBtn:SetWidth(100)
    statusBtn:SetHeight(22)
    statusBtn:SetPoint("BOTTOM", popup, "BOTTOM", 0, 15)
    statusBtn:SetText("Show Status")
    statusBtn:SetScript("OnClick", function()
        SlashCmdList["TWRADEBUG"]("status")
    end)
    
    -- Add full debug button
    local fullBtn = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
    fullBtn:SetWidth(130)
    fullBtn:SetHeight(22)
    fullBtn:SetPoint("BOTTOMLEFT", popup, "BOTTOMLEFT", 15, 15)
    fullBtn:SetText("Enable Full Debug")
    fullBtn:SetScript("OnClick", function()
        self:EnableFullDebug()
        
        -- Update UI elements to match new settings
        globalToggle:SetChecked(true)
        levelSlider:SetValue(4)
        detailsToggle:SetChecked(true)
        
        for category, toggle in pairs(popup.categoryToggles) do
            toggle:SetChecked(true)
        end
    end)
    
    -- Function to update category toggles based on global state
    function self:UpdateDebugTogglesInPopup()
        -- Check if popup exists and has toggle references
        if not popup or not popup.categoryToggles then
            return
        end
        
        for category, toggle in pairs(popup.categoryToggles) do
            if toggle then  -- Make sure toggle exists before using it
                -- Set enabled state based on global toggle
                if not self.DEBUG.enabled then
                    -- Can't use SetEnabled() in vanilla WoW - use different approach
                    if toggle:IsEnabled() ~= false then
                        toggle:Disable()
                    end
                    toggle:SetAlpha(0.5)
                else
                    -- Can't use SetEnabled() in vanilla WoW - use different approach
                    if not toggle:IsEnabled() then
                        toggle:Enable()
                    end
                    toggle:SetAlpha(1.0)
                end
            end
        end
    end
    
    -- Initial update
    self:UpdateDebugTogglesInPopup()
    
    -- Store reference in addon
    self.debugPopup = popup
    
    -- Initially hide the popup
    popup:Hide()
    
    return popup
end

-- Slash command for debug control
SLASH_TWRADEBUG1 = "/twradebug"
SlashCmdList["TWRADEBUG"] = function(msg)
    if msg == "on" then
        TWRA:Debug(true)
    elseif msg == "off" then
        TWRA:Debug(false)
    elseif msg == "full" then
        TWRA:EnableFullDebug()
    elseif msg == "popup" or msg == "options" or msg == "ui" then
        -- Show the debug popup UI
        if not TWRA.debugPopup then
            TWRA:CreateDebugPopup()
        end
        TWRA.debugPopup:Show()
    elseif msg == "details on" then
        TWRA:ToggleDetailedLogging(true)
    elseif msg == "details off" then
        TWRA:ToggleDetailedLogging(false)
    elseif string.sub(msg, 1, 5) == "level" then
        -- Extract the level number more explicitly for Lua 5.0
        local levelStr = string.sub(msg, 7)
        local level = tonumber(levelStr)
        if level then
            TWRA:SetDebugLevel(level)
        else
            DEFAULT_CHAT_FRAME:AddMessage("TWRA: Invalid level format. Use '/twradebug level 1' for example.")
        end
    elseif msg == "sync on" then
        TWRA:ToggleDebugCategory("sync", true)
    elseif msg == "sync off" then
        TWRA:ToggleDebugCategory("sync", false)
    elseif msg == "ui on" then
        TWRA:ToggleDebugCategory("ui", true)
    elseif msg == "ui off" then
        TWRA:ToggleDebugCategory("ui", false)
    elseif msg == "data on" then
        TWRA:ToggleDebugCategory("data", true)
    elseif msg == "data off" then
        TWRA:ToggleDebugCategory("data", false)
    elseif msg == "nav on" then
        TWRA:ToggleDebugCategory("nav", true)
    elseif msg == "nav off" then
        TWRA:ToggleDebugCategory("nav", false)
    elseif msg == "general on" then
        TWRA:ToggleDebugCategory("general", true)
    elseif msg == "general off" then
        TWRA:ToggleDebugCategory("general", false)
    elseif msg == "status" then
        -- Show current debug status
        DEFAULT_CHAT_FRAME:AddMessage("TWRA Debug Status:")
        DEFAULT_CHAT_FRAME:AddMessage("Master switch: " .. (TWRA.DEBUG.enabled and "ON" or "OFF"))
        DEFAULT_CHAT_FRAME:AddMessage("Log level: " .. TWRA.DEBUG.logLevel .. 
                                     " (" .. (TWRA.DEBUG.logLevel == 1 and "Errors Only" or 
                                             TWRA.DEBUG.logLevel == 2 and "Warnings & Errors" or 
                                             TWRA.DEBUG.logLevel == 3 and "Standard Debug" or 
                                             "Detailed Debug") .. ")")
        DEFAULT_CHAT_FRAME:AddMessage("Detailed logging: " .. (TWRA.DEBUG.showDetails and "ON" or "OFF"))
        DEFAULT_CHAT_FRAME:AddMessage("Categories:")
        for cat, state in pairs(TWRA.DEBUG.categories) do
            DEFAULT_CHAT_FRAME:AddMessage("  - " .. cat .. ": " .. (state and "ON" or "OFF"))
        end
    else
        -- Show help message
        DEFAULT_CHAT_FRAME:AddMessage("TWRA Debug Commands:")
        DEFAULT_CHAT_FRAME:AddMessage("/twradebug on - Enable all debugging")
        DEFAULT_CHAT_FRAME:AddMessage("/twradebug off - Disable all debugging")
        DEFAULT_CHAT_FRAME:AddMessage("/twradebug popup - Open debug options UI")
        DEFAULT_CHAT_FRAME:AddMessage("/twradebug full - Enable full debugging (all categories + max level)")
        DEFAULT_CHAT_FRAME:AddMessage("/twradebug details on/off - Toggle detailed logging")
        DEFAULT_CHAT_FRAME:AddMessage("/twradebug level # - Set debug level (1=errors, 2=warnings, 3=standard, 4=detailed)")
        DEFAULT_CHAT_FRAME:AddMessage("/twradebug status - Show current debug settings")
        
        -- List all available categories
        DEFAULT_CHAT_FRAME:AddMessage("Category commands:")
        for cat in pairs(TWRA.DEBUG.categories) do
            DEFAULT_CHAT_FRAME:AddMessage("/twradebug " .. cat .. " on/off - Toggle " .. cat .. " debugging")
        end
    end
end

-- Initialize debug system when this file loads
TWRA:InitializeDebugSystem()

-- Register for ADDON_LOADED to process early errors
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
-- Also register for errors directly
frame:RegisterEvent("ADDON_ACTION_FORBIDDEN")
frame:RegisterEvent("ADDON_ACTION_BLOCKED")
frame:RegisterEvent("LUA_WARNING")

frame:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" and arg1 == "TWRA" then
        -- Re-initialize debug once saved variables are available
        TWRA:InitializeDebug()
        
        -- Register the proper error handler now that we're loaded
        seterrorhandler(TWRA_ErrorHandler)
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Mark that we've entered the world
        TWRA.worldLoaded = true
        
        -- Now process any early errors that were captured
        if TWRA.DEBUG and TWRA.DEBUG.initialized then
            TWRA:ProcessEarlyErrors()
        else
            -- Schedule processing for when debug is ready
            -- WoW Classic compatible timer replacement for C_Timer.After
            TWRA:ScheduleTimer(function()
                if TWRA.ProcessEarlyErrors then 
                    TWRA:ProcessEarlyErrors() 
                end
            end, 1)
        end
    elseif event == "ADDON_ACTION_FORBIDDEN" or event == "ADDON_ACTION_BLOCKED" or event == "LUA_WARNING" then
        -- Capture these events too using consistent formatting
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[TWRA: Warning]|r " .. event .. " - " .. 
                                     (arg1 or "unknown"))
    end
end)

-- Install our error handler immediately when this file loads
seterrorhandler(TWRA_CaptureEarlyError)