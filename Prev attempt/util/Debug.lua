-- TWRA Debug System
TWRA = TWRA or {}

-- Initialize debug system
TWRA.DEBUG = {
    enabled = false,        -- Master switch for all debugging
    categories = {          -- Individual category toggles
        sync = false,       -- Sync-related messages
        ui = false,         -- UI-related messages
        data = false,       -- Data processing messages
        nav = false,        -- Navigation messages
        general = false     -- General debug messages
    },
    colors = {              -- Color codes for each category
        sync = "00AAFF",    -- Blue
        ui = "FFAA00",      -- Orange
        data = "00FF00",    -- Green
        nav = "FF00FF",     -- Purple
        general = "FFFFFF", -- White
        error = "FF0000",   -- Red (always shown)
        warning = "FFFF00", -- Yellow (always shown)
        details = "777777"  -- Gray (for detailed logs)
    },
    logLevel = 1,           -- 1=errors only, 2=warnings+errors, 3=normal debug, 4=detailed debug
    showDetails = false     -- Whether to show detailed debug info (level 4)
}

-- Let's add an initialization function to make sure everything is set up properly
function TWRA:InitializeDebug()
    -- Make sure all categories exist
    self.DEBUG.categories.sync = self.DEBUG.categories.sync or false
    self.DEBUG.categories.ui = self.DEBUG.categories.ui or false
    self.DEBUG.categories.data = self.DEBUG.categories.data or false
    self.DEBUG.categories.nav = self.DEBUG.categories.nav or false
    self.DEBUG.categories.general = self.DEBUG.categories.general or false
    
    -- Load from saved variables if available
    if TWRA_SavedVariables and TWRA_SavedVariables.debug then
        self.DEBUG.enabled = TWRA_SavedVariables.debug.enabled
        self.DEBUG.logLevel = TWRA_SavedVariables.debug.logLevel or 1
        self.DEBUG.showDetails = TWRA_SavedVariables.debug.showDetails or false
        
        -- Copy saved categories but ensure all required ones exist
        if TWRA_SavedVariables.debug.categories then
            for cat, val in pairs(TWRA_SavedVariables.debug.categories) do
                -- Only copy if the category is defined in our table
                if self.DEBUG.categories[cat] ~= nil then
                    self.DEBUG.categories[cat] = val
                end
            end
        end
    end
    
    -- Only show initialization details if debug is enabled
    if self.DEBUG.enabled then
        DEFAULT_CHAT_FRAME:AddMessage("TWRA: Debug system initialized (currently " .. 
                                     (self.DEBUG.enabled and "enabled" or "disabled") .. ")")
        
        -- Only show category status if detailed debugging is enabled
        if self.DEBUG.showDetails then
            DEFAULT_CHAT_FRAME:AddMessage("Debug categories status:")
            for cat, value in pairs(self.DEBUG.categories) do
                DEFAULT_CHAT_FRAME:AddMessage("Category '" .. cat .. "': " .. tostring(value))
            end
        end
    end
end

-- Main debug function
function TWRA:Debug(category, message, level)
    -- CASE 1: Boolean passed - toggle debug mode
    if type(category) == "boolean" then
        self.DEBUG.enabled = category
        -- Update all categories to match master setting
        for cat in pairs(self.DEBUG.categories) do
            self.DEBUG.categories[cat] = category
        end
        
        -- Save to saved variables
        if TWRA_SavedVariables then
            TWRA_SavedVariables.debug = TWRA_SavedVariables.debug or {}
            TWRA_SavedVariables.debug.enabled = category
            TWRA_SavedVariables.debug.categories = TWRA_SavedVariables.debug.categories or {}
            for cat in pairs(self.DEBUG.categories) do
                TWRA_SavedVariables.debug.categories[cat] = category
            end
        end
        
        DEFAULT_CHAT_FRAME:AddMessage("TWRA: Debug mode " .. (category and "enabled" or "disabled"))
        return
    end
    
    -- CASE 2: String passed without message - use it as message with "general" category
    if type(category) == "string" and message == nil then
        message = category
        category = "general"
        level = level or 3  -- Default to regular debug level
    else
        -- Handle level parameter or convert category to level if it's a special category
        level = level or 3  -- Default to regular debug level
        
        if category == "error" then
            level = 1
        elseif category == "warning" then
            level = 2
        elseif category == "details" then
            level = 4  -- New level for detailed debugging
        end
    end
    
    -- Make sure category is a string
    if type(category) ~= "string" then
        -- Output directly to avoid recursion
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[TWRA ERROR]|r Invalid non-string debug category: " .. 
                                     tostring(category))
        category = "general" -- Default to general
    end
    
    -- ENHANCEMENT: Use "general" as fallback for unknown categories rather than showing error
    if not self.DEBUG.categories[category] then
        -- Silently fall back to general category
        category = "general"
    end
    
    -- Check if debugging is enabled for this category or if it's a high priority message
    local showMessage = false
    
    -- Always show error messages (level 1)
    if level == 1 then
        showMessage = true
    -- Show warnings (level 2) if logLevel is 2 or higher
    elseif level == 2 and self.DEBUG.logLevel >= 2 then
        showMessage = true
    -- Show regular debug messages (level 3) based on category settings
    elseif level == 3 and self.DEBUG.enabled and self.DEBUG.categories[category] and self.DEBUG.logLevel >= 3 then
        showMessage = true
    -- Show detailed debug messages (level 4) only if showDetails is enabled
    elseif level == 4 and self.DEBUG.enabled and self.DEBUG.categories[category] and self.DEBUG.showDetails and self.DEBUG.logLevel >= 4 then
        showMessage = true
    end
    
    if not showMessage then
        return
    end
    
    -- Format the message with category color
    local color = self.DEBUG.colors[category] or "FFFFFF"
    -- For detailed messages, use the details color
    if level == 4 then
        color = self.DEBUG.colors.details
    end
    
    local formattedMessage = string.format("|cFF%s[TWRA %s]|r %s", 
                                         color, 
                                         string.upper(category), 
                                         message)
    
    DEFAULT_CHAT_FRAME:AddMessage(formattedMessage)
    
    -- If this is an error, also print stack trace
    if level == 1 and self.DEBUG.logLevel >= 1 then
        local stackTrace = debugstack(3, 3, 2)
        if stackTrace then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000[STACK]|r " .. stackTrace)
        end
    end
end

-- Error and warning functions (always displayed)
function TWRA:Error(message)
    self:Debug("error", message, 1)
end

function TWRA:Warning(message)
    self:Debug("warning", message, 2)
end

-- New function for detailed logging
function TWRA:DebugDetailed(category, message)
    self:Debug(category, message, 4)
end

-- Shorthand for category-specific debug functions
function TWRA:DebugSync(message)
    self:Debug("sync", message)
end

function TWRA:DebugUI(message)
    self:Debug("ui", message)
end

function TWRA:DebugData(message)
    self:Debug("data", message)
end

function TWRA:DebugNav(message)
    self:Debug("nav", message)
end

-- Set the debug log level
function TWRA:SetDebugLevel(level)
    if type(level) ~= "number" or level < 1 or level > 4 then
        self:Error("Invalid debug level. Must be 1-4")
        return
    end
    
    self.DEBUG.logLevel = level
    
    if TWRA_SavedVariables and TWRA_SavedVariables.debug then
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

-- Toggle detailed logging
function TWRA:ToggleDetailedLogging(state)
    if state == nil then
        state = not self.DEBUG.showDetails
    end
    
    self.DEBUG.showDetails = state
    
    if TWRA_SavedVariables and TWRA_SavedVariables.debug then
        TWRA_SavedVariables.debug.showDetails = state
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("TWRA: Detailed logging " .. (state and "enabled" or "disabled"))
    
    -- If enabling details, make sure level is appropriate
    if state and self.DEBUG.logLevel < 4 then
        self:SetDebugLevel(4)
    end
end

-- Toggle specific debug category
function TWRA:ToggleDebugCategory(category, state)
    if not category then
        DEFAULT_CHAT_FRAME:AddMessage("TWRA: Missing category to toggle")
        return
    end
    
    -- Check if category exists using iteration
    local categoryExists = false
    for cat in pairs(self.DEBUG.categories) do
        if cat == category then
            categoryExists = true
            break
        end
    end
    
    if not categoryExists then
        -- We need to safely handle the case when category is invalid
        local categoryStr = tostring(category or "nil")
        DEFAULT_CHAT_FRAME:AddMessage("TWRA: Invalid debug category: " .. categoryStr)
        
        -- Get list of valid categories as a string
        local validCategories = ""
        for cat in pairs(self.DEBUG.categories) do
            if validCategories ~= "" then 
                validCategories = validCategories .. " " 
            end
            validCategories = validCategories .. cat
        end
        
        DEFAULT_CHAT_FRAME:AddMessage("TWRA: Available categories: " .. validCategories)
        return
    end
    
    -- Set the category state
    self.DEBUG.categories[category] = state
    
    -- Save to saved variables
    if TWRA_SavedVariables then
        if not TWRA_SavedVariables.debug then
            TWRA_SavedVariables.debug = {}
        end
        if not TWRA_SavedVariables.debug.categories then
            TWRA_SavedVariables.debug.categories = {}
        end
        TWRA_SavedVariables.debug.categories[category] = state
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("TWRA: Debug category '" .. category .. "' " .. 
                                 (state and "enabled" or "disabled"))
end

-- Check if a particular module is in debug mode
function TWRA:IsDebugging(category)
    return self.DEBUG.enabled and self.DEBUG.categories[category or "general"]
end

-- Check if detailed debugging is enabled for a category
function TWRA:IsDetailedDebugging(category)
    return self.DEBUG.enabled and self.DEBUG.categories[category or "general"] and 
           self.DEBUG.showDetails and self.DEBUG.logLevel >= 4
end

-- Enable full debugging quickly for emergency troubleshooting
function TWRA:EnableFullDebug()
    self.DEBUG.enabled = true
    self.DEBUG.logLevel = 4
    self.DEBUG.showDetails = true
    
    for cat in pairs(self.DEBUG.categories) do
        self.DEBUG.categories[cat] = true
    end
    
    -- Save to saved variables
    if TWRA_SavedVariables then
        TWRA_SavedVariables.debug = TWRA_SavedVariables.debug or {}
        TWRA_SavedVariables.debug.enabled = true
        TWRA_SavedVariables.debug.logLevel = 4
        TWRA_SavedVariables.debug.showDetails = true
        TWRA_SavedVariables.debug.categories = TWRA_SavedVariables.debug.categories or {}
        
        for cat in pairs(self.DEBUG.categories) do
            TWRA_SavedVariables.debug.categories[cat] = true
        end
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("TWRA: |cFFFF0000FULL DEBUG MODE ENABLED|r")
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

-- Initialize before doing anything else (including the final debug message)
TWRA:InitializeDebug()

-- Now it's safe to log this message
TWRA:Debug("general", "Debug module loaded")