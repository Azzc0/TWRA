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
    
    -- Check if this is likely a TWRA error
    local isTWRAError = string.find(message, "TWRA") or 
                        string.find(message, "Raid Assignment") or
                        string.find(message, "RaidAssignment") or
                        (string.find(message, "Interface\\AddOns\\TWRA"))
    
    if isTWRAError then
        -- Add timestamp to the error
        local errorEntry = {
            time = GetTime(),
            message = message
        }
        
        -- Store error in our list for proper processing later - don't print immediately
        table.insert(TWRA.earlyErrors, errorEntry)
    end
    
    -- Return the error so the default handler still processes it
    return message
end

-- Register our early error handler (will be replaced later)
local oldErrorHandler = geterrorhandler()
seterrorhandler(TWRA_CaptureEarlyError)

-- Initialize the debug system and load saved settings
function TWRA:InitDebug()
    -- Skip if already initialized
    if self.DEBUG and self.DEBUG.initialized then
        return
    end
    
    -- Create default settings if they don't exist
    if not TWRA_SavedVariables then
        TWRA_SavedVariables = {}
    end
    
    if not TWRA_SavedVariables.debug then
        TWRA_SavedVariables.debug = {
            level = self.DEBUG_LEVELS.INFO,  -- Default to INFO level
            categories = {},                 -- Will be filled with default values
            timestamp = true,                -- Show timestamps by default
            frameNum = false,                -- Don't show frame numbers by default
            suppressCount = 0,               -- Count of suppressed messages
            enabled = false,                 -- Debug disabled by default
            showDetails = false              -- Don't show detailed logs by default
        }
        
        -- Set default category values
        for category, info in pairs(self.DEBUG_CATEGORIES) do
            TWRA_SavedVariables.debug.categories[category] = info.default
        end
    end
    
    -- Initialize Debug namespace
    self.DEBUG = self.DEBUG or {}
    
    -- Create debug frame if needed (for performance monitoring)
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

    -- Set up debug constants and colors
    -- Copy category definitions to DEBUG namespace for UI use
    self.DEBUG.CATEGORIES = {}
    for category, details in pairs(self.DEBUG_CATEGORIES) do
        self.DEBUG.CATEGORIES[category] = {
            name = details.name,
            description = details.description,
            enabled = details.default
        }
    end
    
    -- Set up debug colors
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
    
    -- Create simplified category tracking
    self.DEBUG.categories = {}
    for category, _ in pairs(self.DEBUG.CATEGORIES) do
        self.DEBUG.categories[category] = false
    end
    
    -- Load saved debug settings - explicitly check each value
    local savedDebug = TWRA_SavedVariables.debug
    
    -- Explicitly convert to proper boolean value, not just nil check
    if savedDebug.enabled ~= nil then
        self.DEBUG.enabled = (savedDebug.enabled == 1 or savedDebug.enabled == true)
    else
        self.DEBUG.enabled = false
    end
    
    -- Use the saved log level
    if savedDebug.logLevel ~= nil then
        self.DEBUG.logLevel = savedDebug.logLevel
    else
        self.DEBUG.logLevel = 3 -- Default to standard
    end
    
    -- Use the saved showDetails setting
    if savedDebug.showDetails ~= nil then
        self.DEBUG.showDetails = (savedDebug.showDetails == 1 or savedDebug.showDetails == true)
    else
        self.DEBUG.showDetails = false
    end
    
    -- Load timestamp setting
    if savedDebug.timestamp ~= nil then
        self.DEBUG.showTimestamps = (savedDebug.timestamp == 1 or savedDebug.timestamp == true)
    else
        self.DEBUG.showTimestamps = false
    end
    
    -- Apply saved category settings to each category
    for category, _ in pairs(self.DEBUG.categories) do
        -- Only apply if the category exists in saved vars, handle boolean conversion
        if savedDebug.categories and savedDebug.categories[category] ~= nil then
            self.DEBUG.categories[category] = (savedDebug.categories[category] == 1 or savedDebug.categories[category] == true)
            
            -- Also update the CATEGORIES table for UI display
            if self.DEBUG.CATEGORIES[category] then
                self.DEBUG.CATEGORIES[category].enabled = self.DEBUG.categories[category]
            end
        end
        
        -- Ensure the category exists in saved vars for next time
        if not savedDebug.categories then savedDebug.categories = {} end
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
    
    -- Mark debug as initialized to prevent double-initialization
    self.DEBUG.initialized = true
    self.processingEarlyErrors = false
    
    -- Now that debug is fully initialized, replace the error handler
    seterrorhandler(TWRA_ErrorHandler)
    
    self:Debug("general", "Debug system initialized")
    
    -- Reset suppressed message count
    TWRA_SavedVariables.debug.suppressCount = 0
end

-- Error logging - always shown even at minimal debug levels
function TWRA:Error(message)
    self:Debug("error", message, true)
end

-- Warning logging - shown at WARN level and above
function TWRA:Warn(category, message)
    self:Debug(category, message, self.DEBUG_LEVELS.WARN)
end

-- Info logging - shown at INFO level and above (default)
function TWRA:Info(category, message)
    self:Debug(category, message, self.DEBUG_LEVELS.INFO)
end

-- Verbose logging - only shown at VERBOSE level
function TWRA:Verbose(category, message)
    self:Debug(category, message, self.DEBUG_LEVELS.VERBOSE)
end

-- Debug output function with category filtering and detail level support
function TWRA:Debug(category, message, forceOutput, isDetail)
    -- Skip output if world hasn't loaded yet and not forcing output
    if not self.worldLoaded and not forceOutput then
        -- Capture as early error to display later
        -- Make sure to include category in the message for later parsing
        local formattedMessage = ""
        if category ~= "error" then
            formattedMessage = "[" .. category .. "] " .. message
        else
            formattedMessage = message
        end
        
        table.insert(self.earlyErrors, {
            time = GetTime(),
            message = formattedMessage
        })
        return
    end
    
    -- Always allow forced output regardless of settings
    if forceOutput then
        -- Use consistent formatting for forced output too
        local color = self.DEBUG and self.DEBUG.colors and self.DEBUG.colors[category] or "FFFFFF"
        
        -- Create simple prefix without timestamp for regular messages
        local prefix = "|cFF" .. color .. "[TWRA: " .. (category or "Debug") .. "]|r "
        
        -- Add timestamp - respect timestamp settings even for forced messages
        local showTimestamp = self.DEBUG and self.DEBUG.showTimestamps
        if showTimestamp then
            local timeStr = string.format("%.2f", GetTime())
            prefix = prefix .. "[" .. timeStr .. "s] "
        end
        
        DEFAULT_CHAT_FRAME:AddMessage(prefix .. message)
        return
    end
    
    -- Handle boolean toggle case
    if type(category) == "boolean" then
        self:ToggleDebug(category)
        return
    end
    
    -- Handle single string parameter case (general debug)
    if type(category) == "string" and message == nil then
        message = category
        category = "general"
    end
    
    -- Skip output if debug isn't initialized, debug is disabled, or category is disabled
    if not self.DEBUG or not self.DEBUG.initialized or not self.DEBUG.enabled then
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
    
    -- Create prefix - add timestamp if enabled
    local prefix = "|cFF" .. color .. "[TWRA: " .. category .. "]|r "
    
    -- Add timestamp if enabled
    if self.DEBUG.showTimestamps then
        local timeStr = string.format("%.2f", GetTime())
        prefix = prefix .. "[" .. timeStr .. "s] "
    end
    
    -- Use simplified format for all debug messages
    if isDetail then
        -- Add "DETAIL" marker to detailed logs
        DEFAULT_CHAT_FRAME:AddMessage(prefix .. "DETAIL: " .. message)
    else
        DEFAULT_CHAT_FRAME:AddMessage(prefix .. message)
    end
end

-- Process early errors after debug system is initialized and player enters world
function TWRA:ProcessEarlyErrors()
    -- Don't process if player hasn't entered world yet or no errors exist
    if not self.worldLoaded or not self.earlyErrors or table.getn(self.earlyErrors) == 0 then
        return
    end
    
    -- Set flag to indicate we're processing early errors
    self.processingEarlyErrors = true
    
    -- Process each early error through our debug system
    for _, errorEntry in ipairs(self.earlyErrors) do
        -- Parse the message to extract category if present
        local message = errorEntry.message
        local category = "error"  -- Default to error category
        local forceOutput = false
        
        -- Check if message contains category pattern [category]
        local categoryStart, categoryEnd, extractedCategory = string.find(message, "%[([^%]]+)%]")
        if categoryStart and extractedCategory then
            -- Found a category, extract it and the real message
            category = extractedCategory
            message = string.sub(message, categoryEnd + 1) -- Get everything after the category
            message = string.gsub(message, "^%s+", "") -- Trim leading spaces
            
            -- Force output only for error messages or if debug is enabled for the category
            forceOutput = (category == "error") or 
                         (self.DEBUG and self.DEBUG.enabled and 
                          self.DEBUG.categories and self.DEBUG.categories[category])
        else
            -- If no category found, force output for all error messages
            forceOutput = true
        end
        
        -- Pass the message with the correct category to Debug
        -- Only force early messages if they would be shown normally
        self:Debug(category, message, forceOutput)
    end
    
    -- Clear early errors once processed
    self.earlyErrors = {}
    
    -- Clear the flag when done
    self.processingEarlyErrors = false
end

-- Our proper error handler that will replace the early one
function TWRA_ErrorHandler(message)
    -- Make sure TWRA exists
    if not TWRA then
        return message
    end
    
    -- Log the error through our Debug system if it's initialized
    if TWRA.DEBUG and TWRA.DEBUG.initialized then
        -- Check if this is a Lua error with file/line information
        local fileInfo = string.match(message, "([^:]+:%d+:)")
        if fileInfo and string.find(fileInfo, "TWRA") then
            -- This is a TWRA addon error with file information
            TWRA:Debug("error", message, true)
        else
            -- Only log errors from our addon
            local isTWRAError = string.find(message, "TWRA") or 
                                string.find(message, "Raid Assignment") or
                                string.find(message, "RaidAssignment")
            if isTWRAError then
                TWRA:Debug("error", message, true)
            end
        end
    else
        -- Fall back to the early error capture if Debug isn't ready
        TWRA_CaptureEarlyError(message)
    end
    
    -- Return the error so the default handler still processes it
    return message
end

-- Toggle debug mode globally
function TWRA:ToggleDebug(enable)
    if not self.DEBUG then
        self:InitDebug()
    end
    
    if enable == nil then
        enable = not self.DEBUG.enabled
    end
    
    -- Ensure the value is an actual boolean, not just truthy
    if enable == 1 or enable == true then
        self.DEBUG.enabled = true
    else
        self.DEBUG.enabled = false
    end
    
    -- Ensure proper data structure exists
    TWRA_SavedVariables = TWRA_SavedVariables or {}
    TWRA_SavedVariables.debug = TWRA_SavedVariables.debug or {
        categories = {},
        logLevel = 3,
        showDetails = false
    }
    
    -- Save to the saved variables with proper boolean value
    TWRA_SavedVariables.debug.enabled = (self.DEBUG.enabled == true)
    
    -- Update all categories to match master setting
    for cat in pairs(self.DEBUG.categories) do
        self.DEBUG.categories[cat] = self.DEBUG.enabled
        
        -- Also update the CATEGORIES table for UI display
        if self.DEBUG.CATEGORIES[cat] then
            self.DEBUG.CATEGORIES[cat].enabled = self.DEBUG.enabled
        end
        
        -- Update saved variables
        TWRA_SavedVariables.debug.categories = TWRA_SavedVariables.debug.categories or {}
        TWRA_SavedVariables.debug.categories[cat] = self.DEBUG.enabled
    end
    
    -- Inform user about the change
    DEFAULT_CHAT_FRAME:AddMessage("|cFF33AAFF[TWRA: Debug]|r Mode " .. (self.DEBUG.enabled and "enabled" or "disabled"))
end

-- Toggle a specific debug category
function TWRA:ToggleDebugCategory(category, enable)
    if not self.DEBUG or not self.DEBUG.categories or not self.DEBUG.categories[category] then
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

-- Enable full debugging quickly for emergency troubleshooting
function TWRA:EnableFullDebug()
    if not self.DEBUG then
        self:InitDebug()
    end
    
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
    DEFAULT_CHAT_FRAME:AddMessage("TWRA: Debug settings have been saved and will persist through UI reloads.")
    
    -- Return true so we can verify in other functions
    return true
end

-- Toggle detailed logging
function TWRA:ToggleDetailedLogging(state)
    if not self.DEBUG then
        self:InitDebug()
    end
    
    if state == nil then
        state = not self.DEBUG.showDetails
    end
    
    self.DEBUG.showDetails = state
    
    -- Save to saved variables
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

-- Add timestamp toggle functionality
function TWRA:ToggleTimestamps(state)
    if not self.DEBUG then
        self:InitDebug()
    end
    
    if state == nil then
        state = not self.DEBUG.showTimestamps
    end
    
    self.DEBUG.showTimestamps = state
    
    -- Save to saved variables
    if TWRA_SavedVariables then
        TWRA_SavedVariables.debug = TWRA_SavedVariables.debug or {}
        TWRA_SavedVariables.debug.timestamp = state
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("TWRA: Timestamps " .. (state and "enabled" or "disabled"))
end

-- Set the debug log level
function TWRA:SetDebugLevel(level)
    if not self.DEBUG then
        self:InitDebug()
    end
    
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

-- Show debug statistics
function TWRA:ShowDebugStats()
    if not self.DEBUG then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA Debug|r: Debug system not initialized")
        return
    end
    
    local stats = {
        "Debug Mode: " .. (self.DEBUG.enabled and "Enabled" or "Disabled"),
        "Log Level: " .. self.DEBUG.logLevel .. " (" .. 
            (self.DEBUG.logLevel == 1 and "Errors Only" or 
             self.DEBUG.logLevel == 2 and "Warnings & Errors" or 
             self.DEBUG.logLevel == 3 and "Standard Debug" or 
             "Detailed Debug") .. ")",
        "Detailed logging: " .. (self.DEBUG.showDetails and "ON" or "OFF"),
        "Timestamps: " .. (self.DEBUG.showTimestamps and "ON" or "OFF"),
        "Active Categories:"
    }
    
    local activeCategoryCount = 0
    for category, enabled in pairs(self.DEBUG.categories) do
        if enabled then
            table.insert(stats, "  - " .. category)
            activeCategoryCount = activeCategoryCount + 1
        end
    end
    
    if activeCategoryCount == 0 then
        table.insert(stats, "  (No categories enabled)")
    end
    
    -- Check if early messages are queued
    if self.earlyErrors and table.getn(self.earlyErrors) > 0 then
        table.insert(stats, "Early errors: " .. table.getn(self.earlyErrors) .. " (waiting for world load)")
    end
    
    for _, line in ipairs(stats) do
        DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA Debug|r: " .. line)
    end
end

-- Register event handler for initializing debug and processing early errors
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("ADDON_ACTION_FORBIDDEN")
frame:RegisterEvent("ADDON_ACTION_BLOCKED")
frame:RegisterEvent("LUA_WARNING")

frame:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" and arg1 == "TWRA" then
        TWRA:InitDebug()
        seterrorhandler(TWRA_ErrorHandler)
    elseif event == "PLAYER_ENTERING_WORLD" then
        TWRA.worldLoaded = true
        
        -- Process early errors now that world is loaded
        if TWRA.DEBUG and TWRA.DEBUG.initialized then
            TWRA:ProcessEarlyErrors()
        else
            -- Schedule processing for when debug is ready
            if TWRA.ScheduleTimer then 
                TWRA:ScheduleTimer(function()
                    if TWRA.ProcessEarlyErrors then 
                        TWRA:ProcessEarlyErrors() 
                    end
                end, 1)
            else
                -- Fallback if timer system isn't loaded
                DEFAULT_CHAT_FRAME:AddMessage("TWRA warning: Timer system not available, early errors may not be processed")
            end
        end
    elseif event == "ADDON_ACTION_FORBIDDEN" or event == "ADDON_ACTION_BLOCKED" or event == "LUA_WARNING" then
        -- Capture addon action events with consistent formatting
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[TWRA: Warning]|r " .. event .. " - " .. (arg1 or "unknown"))
    end
end)

-- Install our error handler immediately when this file loads
seterrorhandler(TWRA_CaptureEarlyError)

-- Add this function to be called from the main slash command handler in Core.lua
function TWRA:HandleDebugCommand(args)
    -- Show help if no arguments
    if not args or table.getn(args) == 0 then
        DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA Debug Commands|r:")
        DEFAULT_CHAT_FRAME:AddMessage("  /twra debug on/off - Enable/disable all debugging")
        DEFAULT_CHAT_FRAME:AddMessage("  /twra debug level [1-4] - Set debug level")
        DEFAULT_CHAT_FRAME:AddMessage("  /twra debug details on/off - Toggle detailed logging")
        DEFAULT_CHAT_FRAME:AddMessage("  /twra debug time on/off - Toggle timestamps")
        DEFAULT_CHAT_FRAME:AddMessage("  /twra debug full - Enable full debugging")
        DEFAULT_CHAT_FRAME:AddMessage("  /twra debug status - Show debug status")
        DEFAULT_CHAT_FRAME:AddMessage("  /twra debug categories - List all categories")
        return
    end

    -- Basic on/off commands
    if args[1] == "on" then
        self:ToggleDebug(true)
    elseif args[1] == "off" then
        self:ToggleDebug(false)
    elseif args[1] == "full" then
        self:EnableFullDebug()
    elseif args[1] == "status" then
        self:ShowDebugStats()
        
    -- Debug level setting
    elseif args[1] == "level" then
        if args[2] then
            local level = tonumber(args[2])
            if level and level >= 1 and level <= 4 then
                self:SetDebugLevel(level)
            else
                self:Error("Invalid debug level. Use 1-4 (ERROR, WARN, INFO, VERBOSE)")
            end
        else
            DEFAULT_CHAT_FRAME:AddMessage("TWRA: Current debug level: " .. self.DEBUG.logLevel)
        end
        
    -- Detailed logging toggle
    elseif args[1] == "details" then
        if args[2] == "on" then
            self:ToggleDetailedLogging(true)
        elseif args[2] == "off" then
            self:ToggleDetailedLogging(false)
        else
            DEFAULT_CHAT_FRAME:AddMessage("TWRA: Detailed logging is " .. 
                (self.DEBUG.showDetails and "enabled" or "disabled"))
        end
        
    -- Timestamp toggle
    elseif args[1] == "time" or args[1] == "timestamp" or args[1] == "timestamps" then
        if args[2] == "on" then
            self:ToggleTimestamps(true)
        elseif args[2] == "off" then
            self:ToggleTimestamps(false)
        else
            DEFAULT_CHAT_FRAME:AddMessage("TWRA: Timestamps are " .. 
                (self.DEBUG.showTimestamps and "enabled" or "disabled"))
        end
        
    -- Category listing
    elseif args[1] == "categories" then
        DEFAULT_CHAT_FRAME:AddMessage("TWRA: Available debug categories:")
        for cat, info in pairs(self.DEBUG.CATEGORIES) do
            local enabled = self.DEBUG.categories and self.DEBUG.categories[cat]
            DEFAULT_CHAT_FRAME:AddMessage("  - " .. cat .. ": " .. (enabled and "enabled" or "disabled") .. 
                                      " (" .. info.description .. ")")
        end
        
    -- Category toggle - check if arg1 is a valid category
    elseif self.DEBUG.categories and self.DEBUG.categories[args[1]] ~= nil then
        if args[2] == "on" then
            self:ToggleDebugCategory(args[1], true)
        elseif args[2] == "off" then
            self:ToggleDebugCategory(args[1], false)
        else
            local enabled = self.DEBUG.categories[args[1]]
            DEFAULT_CHAT_FRAME:AddMessage("TWRA: Debug category '" .. args[1] .. "' is " .. 
                (enabled and "enabled" or "disabled"))
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("TWRA: Unknown debug command. Type '/twra debug' for help.")
    end
end