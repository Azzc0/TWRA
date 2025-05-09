-- TWRA AutoNavigate integration for SuperWoW
TWRA = TWRA or {}
-- Use RAID_TARGET_UPDATE event from TWRA.lua instead of timer-based scanning
-- Store information about mob-to-section mapping
TWRA.AUTONAVIGATE = {
    enabled = false,          -- Feature toggle
    hasSupported = false,     -- Whether SuperWoW features are available
    lastMarkedGuid = nil,     -- Last mob GUID we processed
    debug = false,            -- Enable debug messages
    initialized = false       -- Track if we've initialized
}

-- Check if SuperWoW is available using proper globals
function TWRA:CheckSuperWoWSupport(quiet)
    -- Check for SUPERWOW_VERSION global variable
    local hasSuperWow = (SUPERWOW_VERSION ~= nil)
    
    -- Additional check: Test if mark1 unit ID works
    if hasSuperWow then
        -- Try to use the mark1 unit ID
        local testExists, testGuid = pcall(function() return UnitExists("mark1") end)
        
        -- If pcall failed, mark1 isn't implemented
        if not testExists then
            hasSuperWow = false
        end
    end
    
    -- Output message unless quiet mode is requested
    if not hasSuperWow and not quiet then
        self:Debug("nav", "SuperWoW features not available - AutoNavigate disabled")
    end
    
    return hasSuperWow
end

-- Main function called from RAID_TARGET_UPDATE event in TWRA.lua
function TWRA:CheckSkullMarkedMob()
    self:Debug("nav", "Checking for skull-marked mob", false, true)
    
    -- Early return if AutoNavigate is not enabled
    if not self.AUTONAVIGATE.enabled then
        self:Debug("nav", "DEBUG: Early return - AutoNavigate is not enabled", false, true)
        return
    end
    
    self:Debug("nav", "DEBUG: AutoNavigate is enabled, checking SuperWoW support...", false, true)
    
    -- Make sure SuperWoW is available
    if not self:CheckSuperWoWSupport(true) then 
        -- Throw an error as requested
        self:Debug("error", "SuperWoW is required for AutoNavigate")
        -- Disable AutoNavigate to prevent further errors
        self.AUTONAVIGATE.enabled = false
        if TWRA_SavedVariables and TWRA_SavedVariables.options then
            TWRA_SavedVariables.options.autoNavigate = false
        end
        return
    end
    
    self:Debug("nav", "DEBUG: SuperWoW support confirmed, checking for skull-marked unit...", false, true)
    
    -- Use direct mark8 reference for skull-marked units (SuperWoW feature)
    local markUnitId = "mark8"  -- Skull is always mark8
    
    -- Check if mark8 exists and get its guid
    local exists,guid = UnitExists("mark8")
    if not exists then
        self:Debug("nav", "DEBUG: No skull-marked unit exists", false, true)
        if self.AUTONAVIGATE.debug and self.AUTONAVIGATE.lastMarkedGuid ~= "none" then
            self:Debug("nav", "No skull-marked units found", false, true)
            self.AUTONAVIGATE.lastMarkedGuid = "none" -- Use "none" as a marker so we don't spam this message
        end
        return
    end
    
    self:Debug("nav", "DEBUG: Skull-marked unit exists, getting GUID...", false, true)
    
    -- Make sure we got a valid GUID
    if not guid or guid == "" then
        self:Debug("nav", "Unit exists but no GUID available for skull-marked unit", false, true)
        return
    end
    
    local name = UnitName("mark8")
    
    self:Debug("nav", "DEBUG: Successfully got name and GUID", false, true)
    
    if self.AUTONAVIGATE.debug then
        self:Debug("nav", "Found skull-marked unit: " .. name .. " with GUID: " .. guid, false, true)
    end
    
    -- Only process if this is a new GUID to avoid constant processing
    if guid ~= self.AUTONAVIGATE.lastMarkedGuid then
        if self.AUTONAVIGATE.debug then
            self:Debug("nav", "Processing new skull-marked unit", false, true)
        end
        
        self:ProcessMarkedMob(name, guid)
        self.AUTONAVIGATE.lastMarkedGuid = guid
    end
end

-- Register AutoNavigate events and hooks - simplified now that we use RAID_TARGET_UPDATE
function TWRA:RegisterAutoNavigateEvents()
    self:Debug("nav", "Registering AutoNavigate events")
    
    -- Create a hook into OnLoad to ensure initialization
    local originalOnLoad = self.OnLoad
    self.OnLoad = function(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
        -- Call the original OnLoad function
        if originalOnLoad then
            originalOnLoad(self, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
        end
        
        -- Schedule AutoNavigate initialization after a short delay
        self:ScheduleTimer(function()
            self:Debug("nav", "Running InitializeAutoNavigate from OnLoad hook")
            self:InitializeAutoNavigate()
        end, 0.5)
    end
    
    -- Add hook to ensure initialization during PLAYER_ENTERING_WORLD
    local originalOnEvent = self.OnEvent
    if originalOnEvent then
        self.OnEvent = function(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
            -- Call the original event handler
            originalOnEvent(self, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
            
            -- Additional initialization for AutoNavigate during PLAYER_ENTERING_WORLD
            if event == "PLAYER_ENTERING_WORLD" then
                self:ScheduleTimer(function()
                    if TWRA_SavedVariables and TWRA_SavedVariables.options and 
                       TWRA_SavedVariables.options.autoNavigate then
                        self:Debug("nav", "Re-initializing AutoNavigate from PLAYER_ENTERING_WORLD")
                        self:InitializeAutoNavigate()
                    end
                end, 0.2)
            end
        end
    end
    
    -- Force initialization after 1 second to handle any load order issues
    self:ScheduleTimer(function()
        if TWRA_SavedVariables and TWRA_SavedVariables.options and 
           TWRA_SavedVariables.options.autoNavigate and not self.AUTONAVIGATE.initialized then
            self:Debug("nav", "Forcing AutoNavigate initialization via timer")
            self:InitializeAutoNavigate()
        end
    end, 1)
end

-- Simplified initialization function that no longer needs to set up scanning
function TWRA:InitializeAutoNavigate()
    self:Debug("nav", "Initializing AutoNavigate module")
    
    -- Check if we've already initialized
    if self.AUTONAVIGATE.initialized then
        self:Debug("nav", "AutoNavigate already initialized, refreshing settings")
    end
    
    -- Check SuperWoW support early to handle error cases
    local hasSupport = self:CheckSuperWoWSupport()
    if not hasSupport then
        self:Debug("error", "SuperWoW is required for AutoNavigate")
        
        -- Disable AutoNavigate if SuperWoW isn't available
        if TWRA_SavedVariables and TWRA_SavedVariables.options then
            TWRA_SavedVariables.options.autoNavigate = false
        end
        self.AUTONAVIGATE.enabled = false
        return false
    end
    
    -- Load enabled state from SavedVariables
    if TWRA_SavedVariables and TWRA_SavedVariables.options then
        -- Convert settings to ensure proper boolean values
        local autoNavigateEnabled = false
        
        -- Make sure we have the correct type for the setting
        if TWRA_SavedVariables.options.autoNavigate ~= nil then
            if type(TWRA_SavedVariables.options.autoNavigate) == "boolean" then
                autoNavigateEnabled = TWRA_SavedVariables.options.autoNavigate
            else
                -- Convert non-boolean to boolean
                autoNavigateEnabled = (TWRA_SavedVariables.options.autoNavigate == 1 or 
                                      TWRA_SavedVariables.options.autoNavigate == true)
                TWRA_SavedVariables.options.autoNavigate = autoNavigateEnabled
                self:Debug("nav", "Converted autoNavigate setting to boolean: " .. tostring(autoNavigateEnabled))
            end
        end
        
        -- Update the runtime state to match saved settings
        self.AUTONAVIGATE.enabled = autoNavigateEnabled
        
        -- Output debug message about the loaded state
        self:Debug("nav", "AutoNavigate " .. (autoNavigateEnabled and "enabled" or "disabled"))
    end

    -- Ensure initialization completes properly
    self.AUTONAVIGATE.initialized = true
    self:Debug("nav", "AutoNavigate initialized")
    
    return true
end

-- Process a skull-marked mob and navigate to its section if matched
function TWRA:ProcessMarkedMob(mobName, mobId)
    if not mobName or mobName == "" or not mobId then 
        if self.AUTONAVIGATE.debug then
            self:Debug("nav", "Invalid mob data provided")
        end
        return
    end
    
    if self.AUTONAVIGATE.debug then
        self:Debug("nav", "Processing mob: '" .. mobName .. "' with GUID: '" .. mobId .. "'")
    end
    
    -- Look up matching section for this GUID
    local targetSection = self:FindSectionByGuid(mobId)
    
    -- Navigate to the section if one was found
    if targetSection then
        if self.AUTONAVIGATE.debug then
            self:Debug("nav", "Found section '" .. targetSection .. "' for mob: " .. mobName)
        end
        
        -- Find index for this section name
        local sectionIndex = 0
        if self.navigation and self.navigation.handlers then
            for i = 1, table.getn(self.navigation.handlers) do
                if self.navigation.handlers[i] == targetSection then
                    sectionIndex = i
                    break
                end
            end
        else
            if self.AUTONAVIGATE.debug then
                self:Debug("nav", "No navigation handlers available")
            end
        end
        
        if sectionIndex > 0 then
            if self.AUTONAVIGATE.debug then
                self:Debug("nav", "Navigating to section index: " .. sectionIndex)
            end
            
            self:NavigateToSection(sectionIndex)
            self:Debug("nav", "Auto-navigated to " .. targetSection .. " (standard method)")

        else
            if self.AUTONAVIGATE.debug then
                self:Debug("nav", "Section name found but no matching index in navigation: " .. targetSection)
            end
        end
    elseif self.AUTONAVIGATE.debug then
        self:Debug("nav", "No section found for " .. mobName .. " (" .. mobId .. ")")
    end
end

-- Find section by checking for GUID in the data directly
function TWRA:FindSectionByGuid(guid)
    if not guid or guid == "" then return nil end
    
    -- Normalize the GUID for comparison
    local normalizedGuid = string.lower(guid)
    local guidWithoutPrefix = normalizedGuid
    if string.sub(normalizedGuid, 1, 2) == "0x" then
        guidWithoutPrefix = string.sub(normalizedGuid, 3)
    end
    
    -- Short GUID for partial matching
    local shortGuid = nil
    if string.len(normalizedGuid) >= 12 then
        shortGuid = string.sub(normalizedGuid, -12)
    end
    
    if self.AUTONAVIGATE.debug then
        self:Debug("nav", "Looking for GUID: " .. guid)
        self:Debug("nav", "  Normalized: " .. normalizedGuid)
        self:Debug("nav", "  Without prefix: " .. guidWithoutPrefix)
        if shortGuid then
            self:Debug("nav", "  Short GUID: " .. shortGuid)
        end
    end
    
    -- Check the assignments data for GUIDs in the new data structure
    if TWRA_Assignments and TWRA_Assignments.data then
        local savedData = TWRA_Assignments.data
        
        if self.AUTONAVIGATE.debug then
            self:Debug("nav", "Checking assignment data for GUIDs in new format...")
        end
        
        -- New data format: Check each section's metadata for GUIDs
        for _, section in pairs(savedData) do
            -- Only process properly structured sections
            if type(section) == "table" and section["Section Name"] then
                local sectionName = section["Section Name"]
                
                -- Check if this section has metadata with GUIDs
                if section["Section Metadata"] and section["Section Metadata"]["GUID"] then
                    local guidList = section["Section Metadata"]["GUID"]
                    
                    if self.AUTONAVIGATE.debug then
                        self:Debug("nav", "Found GUIDs in metadata for section: " .. sectionName)
                    end
                    
                    -- Check each GUID in the metadata
                    for _, rowGuid in ipairs(guidList) do
                        if rowGuid and rowGuid ~= "" then
                            if self.AUTONAVIGATE.debug then
                                self:Debug("nav", "Checking GUID: " .. rowGuid)
                            end
                            
                            -- Normalize for comparison
                            local normalizedRowGuid = string.lower(rowGuid)
                            local rowGuidWithoutPrefix = normalizedRowGuid
                            if string.sub(normalizedRowGuid, 1, 2) == "0x" then
                                rowGuidWithoutPrefix = string.sub(normalizedRowGuid, 3)
                            end
                            
                            -- Try exact matches first
                            if normalizedRowGuid == normalizedGuid or 
                               rowGuidWithoutPrefix == guidWithoutPrefix then
                                if self.AUTONAVIGATE.debug then
                                    self:Debug("nav", "Found exact GUID match for " .. 
                                        sectionName .. ": " .. rowGuid)
                                end
                                return sectionName
                            end
                            
                            -- Try partial matching with the end of the GUID
                            if shortGuid and string.len(normalizedRowGuid) >= 8 then
                                local shortRowGuid = string.sub(normalizedRowGuid, -12)
                                if string.find(shortRowGuid, shortGuid, 1, true) or 
                                   string.find(shortGuid, shortRowGuid, 1, true) then
                                    if self.AUTONAVIGATE.debug then
                                        self:Debug("nav", "Found partial GUID match for " .. 
                                            sectionName .. ": " .. shortRowGuid .. " ~ " .. shortGuid)
                                    end
                                    return sectionName
                                end
                            end
                        end
                    end
                end
            end
        end
    else
        if self.AUTONAVIGATE.debug then
            self:Debug("nav", "No saved assignments data available")
        end
    end
    
    if self.AUTONAVIGATE.debug then
        self:Debug("nav", "No matching section found for GUID: " .. guid)
    end
    return nil
end

-- Toggle debug mode with enhanced info
function TWRA:ToggleAutoNavigateDebug()
    self.AUTONAVIGATE.debug = not self.AUTONAVIGATE.debug
    self:Debug("nav", "AutoNavigate debug " .. 
        (self.AUTONAVIGATE.debug and "enabled" or "disabled"))
        
    -- Reset last marked GUID when toggling debug
    self.AUTONAVIGATE.lastMarkedGuid = nil
        
    -- When enabling debug, show section data
    if self.AUTONAVIGATE.debug then
        -- Show navigation info
        if self.navigation and self.navigation.handlers then
            self:Debug("nav", "Current sections in order:")
            for i = 1, table.getn(self.navigation.handlers) do
                local name = self.navigation.handlers[i]
                self:Debug("nav", "  " .. i .. ": " .. name)
            end
            self:Debug("nav", "Current section: " .. (self.navigation.currentIndex or "unknown"))
        else
            self:Debug("nav", "No navigation data available")
        end
        
        -- Show GUID mappings
        if TWRA_Assignments and TWRA_Assignments.data then
            local savedData = TWRA_Assignments.data
            
            self:Debug("nav", "Checking for GUIDs in sections:")
            for _, section in pairs(savedData) do
                -- Only process properly structured sections
                if type(section) == "table" and section["Section Name"] then
                    local sectionName = section["Section Name"]
                    
                    -- Check if this section has metadata with GUIDs
                    if section["Section Metadata"] and section["Section Metadata"]["GUID"] then
                        local guidList = section["Section Metadata"]["GUID"]
                        
                        if table.getn(guidList) > 0 then
                            self:Debug("nav", "  Section '" .. sectionName .. "' GUIDs:")
                            for _, guid in ipairs(guidList) do
                                if guid and guid ~= "" then
                                    -- Extract just the GUID part for cleaner display
                                    local extractedGuid = self:ExtractGuidFromString(guid)
                                    self:Debug("nav", "    Original: " .. guid)
                                    self:Debug("nav", "    Extracted: " .. (extractedGuid or "none"))
                                end
                            end
                        end
                    end
                end
            end
        else
            self:Debug("nav", "No assignment data available")
        end
    end
end

-- Extract the GUID part from a string that may contain additional information
function TWRA:ExtractGuidFromString(text)
    if not text or text == "" then
        return nil
    end
    
    -- Look for a pattern starting with "0x" followed by hexadecimal characters
    local guid = string.match(text, "0x[0-9A-Fa-f]+")
    return guid
end

-- Add a new function to list all GUIDs and their sections
function TWRA:ListAllGuids()
    self:Debug("nav", "Listing all stored GUIDs and their sections:")
    
    -- Check if we have assignment data
    if not TWRA_Assignments or not TWRA_Assignments.data then
        self:Debug("nav", "No assignment data available")
        return
    end
    
    local savedData = TWRA_Assignments.data
    local guidCount = 0
    local guidsBySection = {}
    
    -- Iterate through the assignment data
    for index, section in pairs(savedData) do
        -- Only process properly structured sections
        if type(section) == "table" and section["Section Name"] then
            local sectionName = section["Section Name"]
            
            -- Check if this section has metadata with GUIDs
            if section["Section Metadata"] and section["Section Metadata"]["GUID"] then
                -- Get the GUID list
                local guidList = section["Section Metadata"]["GUID"]
                
                -- Initialize section in our tracking table
                if not guidsBySection[sectionName] then
                    guidsBySection[sectionName] = {}
                end
                
                -- Add each GUID in this section
                for _, guid in ipairs(guidList) do
                    if guid and guid ~= "" then
                        -- Extract just the GUID part if there's additional text
                        local extractedGuid = self:ExtractGuidFromString(guid) or guid
                        table.insert(guidsBySection[sectionName], extractedGuid)
                        guidCount = guidCount + 1
                    end
                end
            end
        end
    end
    
    -- Display the results
    if guidCount == 0 then
        self:Debug("nav", "No GUIDs found in the data")
        return
    end
    
    self:Debug("nav", "Found " .. guidCount .. " GUIDs in " .. self:GetTableSize(guidsBySection) .. " sections")
    
    -- Sort the sections alphabetically for easier reading
    local sortedSections = {}
    for section, _ in pairs(guidsBySection) do
        table.insert(sortedSections, section)
    end
    table.sort(sortedSections)
    
    -- Display each section and its GUIDs
    for _, section in ipairs(sortedSections) do
        self:Debug("nav", "Section: " .. section)
        
        for _, guid in ipairs(guidsBySection[section]) do
            self:Debug("nav", "  " .. guid)
        end
    end
    
    self:Debug("nav", "End of GUID listing")
end

-- Extract GUID of current target and add to chat for easier assignment setup
function TWRA:GetCurrentTargetGuid()
    -- Check if SuperWoW is available
    if not self:CheckSuperWoWSupport(true) then
        self:Debug("error", "SuperWoW is required to get target GUID")
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF4444TWRA:|r SuperWoW is required to get target GUID")
        return
    end
    
    -- Check if player has a target
    if not UnitExists("target") then
        self:Debug("nav", "No target selected")
        DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA:|r No target selected. Please select a target to get its GUID.")
        return
    end
    
    -- Get target info using SuperWoW's enhanced UnitExists
    local exists, guid = UnitExists("target")
    local name = UnitName("target")
    
    -- Validate GUID
    if not guid or guid == "" then
        self:Debug("nav", "No GUID available for current target")
        DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA:|r Could not get GUID for " .. name)
        return
    end
    
    -- Format the output in a way that's easy to copy-paste
    local output = "GUID: " .. guid .. " - " .. name
    
    -- Print to chat for user to copy
    DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA:|r " .. output)
    
    -- Return the GUID in case other functions want to use it
    return guid
end

-- Execute registration immediately
TWRA:RegisterAutoNavigateEvents()