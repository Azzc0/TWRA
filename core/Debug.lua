-- TWRA Debug System
-- Manages debug messages with categories and configurable verbosity

TWRA = TWRA or {}

-- Debug category definitions 
TWRA.DEBUG_CATEGORIES = {
    general = { name = "General", default = true, description = "General debug messages" },
    ui = { name = "UI", default = true, description = "User interface events and updates" },
    sync = { name = "Sync", default = true, description = "Synchronization messages" },
    data = { name = "Data", default = false, description = "Detailed data processing messages" },
    compress = { name = "Compress", default = true, description = "Compression-related messages" },
    chunk = { name = "Chunk", default = true, description = "Data chunking messages for sync" },
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
    
    -- Initialize debug namespace early
    self.DEBUG = self.DEBUG or {}
    
    -- Always default to debug disabled unless explicitly enabled in SavedVariables
    self.DEBUG.enabled = false
    self.DEBUG.logLevel = self.DEBUG_LEVELS.INFO
    self.DEBUG.showDetails = false
    self.DEBUG.showTimestamps = true
    
    -- Create debug settings if they don't exist in saved variables
    if not TWRA_SavedVariables.debug then
        TWRA_SavedVariables.debug = {
            enabled = false,                 -- Debug disabled by default
            logLevel = self.DEBUG_LEVELS.INFO, -- Default to INFO level
            categories = {},                 -- Will be filled with default values
            timestamp = true,                -- Show timestamps by default
            frameNum = false,                -- Don't show frame numbers by default
            suppressCount = 0,               -- Count of suppressed messages
            showDetails = false              -- Don't show detailed logs by default
        }
        
        -- Set default category values
        for category, info in pairs(self.DEBUG_CATEGORIES) do
            TWRA_SavedVariables.debug.categories[category] = info.default
        end
    end
    
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
            enabled = false -- Default everything to false initially
        }
    end
    
    -- Set up debug colors
    self.DEBUG.colors = {
        general = "FFFFFF",  -- White
        ui = "33FF33",       -- Green
        data = "33AAFF",     -- Light Blue
        sync = "FF33FF",     -- Pink
        nav = "FFAA33",      -- Orange
        compress = "33FFFF", -- Cyan
        chunk = "FF9933",    -- Dark Orange
        osd = "FFFF33",      -- Yellow
        error = "FF0000",    -- Red
        warning = "FFAA00",  -- Orange
        details = "AAAAAA"   -- Gray
    }
    
    -- Create simplified category tracking
    self.DEBUG.categories = {}
    for category, _ in pairs(self.DEBUG.CATEGORIES) do
        self.DEBUG.categories[category] = false -- Default all categories to false
    end
    
    -- ONLY AFTER initializing defaults, load saved debug settings
    local savedDebug = TWRA_SavedVariables.debug
    
    -- Explicitly convert to proper boolean value, not just nil check
    if savedDebug.enabled ~= nil then
        self.DEBUG.enabled = (savedDebug.enabled == true or savedDebug.enabled == 1)
    end
    
    -- Use the saved log level
    if savedDebug.logLevel ~= nil and type(savedDebug.logLevel) == "number" then
        self.DEBUG.logLevel = savedDebug.logLevel
    end
    
    -- Use the saved showDetails setting
    if savedDebug.showDetails ~= nil then
        self.DEBUG.showDetails = (savedDebug.showDetails == true or savedDebug.showDetails == 1)
    end
    
    -- Load timestamp setting
    if savedDebug.timestamp ~= nil then
        self.DEBUG.showTimestamps = (savedDebug.timestamp == true or savedDebug.timestamp == 1)
    end
    
    -- Apply saved category settings to each category
    if savedDebug.categories then
        for category, _ in pairs(self.DEBUG.categories) do
            -- Only apply if the category exists in saved vars, handle boolean conversion
            if savedDebug.categories[category] ~= nil then
                self.DEBUG.categories[category] = (savedDebug.categories[category] == true or
                                                  savedDebug.categories[category] == 1)
                
                -- Also update the CATEGORIES table for UI display
                if self.DEBUG.CATEGORIES[category] then
                    self.DEBUG.CATEGORIES[category].enabled = self.DEBUG.categories[category]
                end
            end
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
    self.DEBUG.enabled = (enable == true or enable == 1)
    
    -- Ensure proper data structure exists
    TWRA_SavedVariables = TWRA_SavedVariables or {}
    TWRA_SavedVariables.debug = TWRA_SavedVariables.debug or {
        categories = {},
        logLevel = 3,
        showDetails = false
    }
    
    -- Save to the saved variables with proper boolean value
    TWRA_SavedVariables.debug.enabled = self.DEBUG.enabled
    
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

-- New function to toggle a specific debug category
function TWRA:ToggleDebugCategory(category, forceState)
    if not self.DEBUG then
        self:InitDebug()
    end
    
    -- Ensure the category exists
    if not self.DEBUG_CATEGORIES[category] then
        DEFAULT_CHAT_FRAME:AddMessage("TWRA: Invalid debug category: " .. tostring(category))
        return
    end
    
    -- Toggle or set the category based on forceState
    if forceState ~= nil then
        self.DEBUG.categories[category] = (forceState == true or forceState == 1)
    else
        self.DEBUG.categories[category] = not self.DEBUG.categories[category]
    end
    
    -- Update saved settings - ENSURE this happens properly
    TWRA_SavedVariables.debug = TWRA_SavedVariables.debug or {}
    TWRA_SavedVariables.debug.categories = TWRA_SavedVariables.debug.categories or {}
    TWRA_SavedVariables.debug.categories[category] = self.DEBUG.categories[category]
    
    -- Also update the CATEGORIES table for UI display
    if self.DEBUG.CATEGORIES[category] then
        self.DEBUG.CATEGORIES[category].enabled = self.DEBUG.categories[category]
    end
    
    -- If we're enabling a category, make sure debug is enabled overall
    if self.DEBUG.categories[category] and not self.DEBUG.enabled then
        self.DEBUG.enabled = true
        TWRA_SavedVariables.debug.enabled = true
        DEFAULT_CHAT_FRAME:AddMessage("TWRA: Debug mode automatically enabled")
    end
    
    -- Display toggle status
    DEFAULT_CHAT_FRAME:AddMessage("TWRA: Debug category '" .. category .. "' " .. 
                                (self.DEBUG.categories[category] and "enabled" or "disabled"))
end

-- Print all debug categories and their status
function TWRA:ListDebugCategories()
    if not self.DEBUG then
        self:InitDebug()
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("TWRA Debug Categories:")
    DEFAULT_CHAT_FRAME:AddMessage("Master switch: " .. (self.DEBUG.enabled and "ON" or "OFF"))
    
    for category, info in pairs(self.DEBUG_CATEGORIES) do
        local status = self.DEBUG.categories[category]
        local color = status and "00FF00" or "FF0000"
        DEFAULT_CHAT_FRAME:AddMessage("|cFF" .. color .. "- " .. category .. ": " .. 
                                     (status and "ON" or "OFF") .. "|r - " .. info.description)
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("Usage: /twra debug [category] - Toggle specific category")
    DEFAULT_CHAT_FRAME:AddMessage("       /twra debug all - Toggle all debug messages")
    DEFAULT_CHAT_FRAME:AddMessage("       /twra debug list - Show this list")
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
    
    -- If state is nil, toggle the current state
    if state == nil then
        state = not self.DEBUG.showDetails
    else
        -- Otherwise, use the provided state (ensuring it's a boolean)
        state = (state == true or state == 1)
    end
    
    -- Set the new state
    self.DEBUG.showDetails = state
    
    -- Save to saved variables - ENSURE this happens properly
    TWRA_SavedVariables.debug = TWRA_SavedVariables.debug or {}
    TWRA_SavedVariables.debug.showDetails = state
    
    DEFAULT_CHAT_FRAME:AddMessage("TWRA: Detailed logging " .. (state and "enabled" or "disabled"))
    
    -- If enabling details, make sure debug is enabled and level is appropriate
    if state then
        -- Enable debug if it's not already enabled
        if not self.DEBUG.enabled then
            self.DEBUG.enabled = true
            TWRA_SavedVariables.debug.enabled = true
            DEFAULT_CHAT_FRAME:AddMessage("TWRA: Debug mode automatically enabled")
        end
        
        -- Set log level to VERBOSE if it's lower
        if self.DEBUG.logLevel < self.DEBUG_LEVELS.VERBOSE then
            self.DEBUG.logLevel = self.DEBUG_LEVELS.VERBOSE
            TWRA_SavedVariables.debug.logLevel = self.DEBUG_LEVELS.VERBOSE
            DEFAULT_CHAT_FRAME:AddMessage("TWRA: Debug level set to VERBOSE to show detailed messages")
        end
    end
    
    return state
end

-- Add timestamp toggle functionality
function TWRA:ToggleTimestamps(state)
    if not self.DEBUG then
        self:InitDebug()
    end
    
    if state == nil then
        state = not self.DEBUG.showTimestamps
    else
        state = (state == true or state == 1)
    end
    
    self.DEBUG.showTimestamps = state
    
    -- Save to saved variables - ENSURE this happens properly
    TWRA_SavedVariables.debug = TWRA_SavedVariables.debug or {}
    TWRA_SavedVariables.debug.timestamp = state
    
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
        
        -- Add the specific commands shown in Core.lua help
        DEFAULT_CHAT_FRAME:AddMessage("  /twra debug nav - Toggle AutoNavigate debugging")
        DEFAULT_CHAT_FRAME:AddMessage("  /twra debug list - List all available debug commands")
        DEFAULT_CHAT_FRAME:AddMessage("  /twra debug guids - List all stored GUIDs and their sections")
        DEFAULT_CHAT_FRAME:AddMessage("  /twra debug target - Check current target for GUID mapping")
        DEFAULT_CHAT_FRAME:AddMessage("  /twra debug test - Test AutoNavigate with current target")
        DEFAULT_CHAT_FRAME:AddMessage("  /twra debug sync - Toggle sync debugging and show status")
        DEFAULT_CHAT_FRAME:AddMessage("  /twra debug ui - Toggle UI debugging")
        DEFAULT_CHAT_FRAME:AddMessage("  /twra debug osd - Toggle OSD debugging")
        DEFAULT_CHAT_FRAME:AddMessage("  /twra debug timestamp - Show timestamp information")
        
        -- Add direct category toggles
        DEFAULT_CHAT_FRAME:AddMessage("  Category toggles (directly toggle specific categories):")
        for category, _ in pairs(self.DEBUG_CATEGORIES or {}) do
            DEFAULT_CHAT_FRAME:AddMessage("    /twra debug " .. category .. " - Toggle " .. category .. " category")
        end
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
            -- Toggle detailed logging when no parameter is provided
            self:ToggleDetailedLogging()
        end
        
    -- Timestamp toggle
    elseif args[1] == "time" or args[1] == "timestamp" or args[1] == "timestamps" then
        if args[2] == "on" then
            self:ToggleTimestamps(true)
        elseif args[2] == "off" then
            self:ToggleTimestamps(false)
        else
            -- If "timestamp" with no on/off parameter, show timestamp information
            if args[1] == "timestamp" then
                -- Show timestamp information
                local currentTime = time()
                DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA Timestamp Information|r:")
                DEFAULT_CHAT_FRAME:AddMessage("  Current date/time: " .. currentDateStr)
            else
            end
        end
        
    -- Category listing
    elseif args[1] == "categories" then
        self:ListDebugCategories()

    -- Handle specific commands with additional functionality
    elseif args[1] == "nav" then
        -- First toggle the nav category
        self:ToggleDebugCategory("nav")
        
        -- Then check if there's an AutoNavigate-specific toggle
        if self.ToggleAutoNavigateDebug then
            self:ToggleAutoNavigateDebug()
        end
    elseif args[1] == "sync" then
        -- Toggle the sync debug category first
        self:ToggleDebugCategory("sync")
        
        -- Then show sync status if the function exists
        if self.ShowSyncStatus then
            self:ShowSyncStatus()
        end
    elseif args[1] == "osd" then
        -- Toggle the osd debug category
        self:ToggleDebugCategory("osd")
    elseif args[1] == "ui" then
        -- Toggle the ui debug category
        self:ToggleDebugCategory("ui")
    elseif args[1] == "list" then
        -- List all debug commands
        DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA Debug Commands|r:")
        DEFAULT_CHAT_FRAME:AddMessage("  nav - Toggle AutoNavigate debugging")
        DEFAULT_CHAT_FRAME:AddMessage("  list - List all available debug commands")
        DEFAULT_CHAT_FRAME:AddMessage("  guids - List all stored GUIDs and their sections")
        DEFAULT_CHAT_FRAME:AddMessage("  target - Check current target for GUID mapping")
        DEFAULT_CHAT_FRAME:AddMessage("  test - Test AutoNavigate with current target")
        DEFAULT_CHAT_FRAME:AddMessage("  sync - Toggle sync debugging and show status")
        DEFAULT_CHAT_FRAME:AddMessage("  ui - Toggle UI debugging")
        DEFAULT_CHAT_FRAME:AddMessage("  osd - Toggle OSD debugging")
        DEFAULT_CHAT_FRAME:AddMessage("  time on/off - Toggle timestamps in debug messages")
        DEFAULT_CHAT_FRAME:AddMessage("  timestamp - Show timestamp information")
    elseif args[1] == "guids" then
        -- List all stored GUIDs and their sections
        if self.ListStoredGUIDs then
            self:ListStoredGUIDs()
        else
            self:Debug("error", "GUID listing function not available")
        end
    elseif args[1] == "target" then
        -- Check current target for GUID mapping
        if self.CheckTargetGUID then
            self:CheckTargetGUID()
        else
            self:Debug("error", "Target GUID check function not available")
        end
    elseif args[1] == "test" then
        -- Test AutoNavigate with current target
        if self.TestAutoNavigateWithTarget then
            self:TestAutoNavigateWithTarget()
        else
            self:Debug("error", "AutoNavigate test function not available")
        end
    elseif args[1] == "monitor" or args[1] == "mon" then
        -- Toggle message monitoring
        if self.ToggleMessageMonitoring then
            self:ToggleMessageMonitoring()
        else
            self:Debug("error", "Message monitoring function not available")
        end

    -- Category toggle - check if arg1 is a valid category name in DEBUG_CATEGORIES
    -- THIS IS THE KEY ADDITION: Check DEBUG_CATEGORIES directly first
    elseif self.DEBUG_CATEGORIES and self.DEBUG_CATEGORIES[args[1]] then
        -- Direct category toggle using ToggleDebugCategory
        self:ToggleDebugCategory(args[1])
        
    -- For backward compatibility, also check in DEBUG.categories
    elseif self.DEBUG and self.DEBUG.categories and self.DEBUG.categories[args[1]] ~= nil then
        if args[2] == "on" then
            self:ToggleDebugCategory(args[1], true)
        elseif args[2] == "off" then
            self:ToggleDebugCategory(args[1], false)
        else
            self:ToggleDebugCategory(args[1])
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("TWRA: Unknown debug command. Type '/twra debug' for help.")
    end
end