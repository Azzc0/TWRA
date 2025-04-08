-- TWRA AutoNavigate integration for SuperWoW
TWRA = TWRA or {}

-- Store information about mob-to-section mapping
TWRA.AUTONAVIGATE = {
    enabled = false,          -- Feature toggle
    hasSupported = false,     -- Whether SuperWoW features are available
    lastMarkedGuid = nil,     -- Last mob GUID we processed
    debug = false,            -- Enable debug messages
    scanTimer = 0,            -- Timer for periodic scanning
    scanFreq = 1              -- How often to scan (seconds)
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

-- Register AutoNavigate events and hooks
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

-- Improved initialization for AutoNavigate
function TWRA:InitializeAutoNavigate()
    self:Debug("nav", "Initializing AutoNavigate module")
    
    -- Check if we've already initialized
    if self.AUTONAVIGATE.initialized then
        self:Debug("nav", "AutoNavigate already initialized, refreshing settings")
    end
    
    -- Clear any existing timer
    if self.AUTONAVIGATE.timer then
        self:CancelTimer(self.AUTONAVIGATE.timer)
        self.AUTONAVIGATE.timer = nil
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
        
        -- Load scan frequency
        if TWRA_SavedVariables.options.scanFrequency then
            self.AUTONAVIGATE.scanFreq = TWRA_SavedVariables.options.scanFrequency
        end
        
        -- Update the runtime state to match saved settings
        self.AUTONAVIGATE.enabled = autoNavigateEnabled
        
        -- Output debug message about the loaded state
        self:Debug("nav", "AutoNavigate " .. (autoNavigateEnabled and "enabled" or "disabled"))
        
        -- Start scanning if enabled
        if autoNavigateEnabled then
            if self:CheckSuperWoWSupport() then
                self:StartAutoNavigateScan()
                self:Debug("nav", "AutoNavigate scanning started during initialization")
            else
                -- SuperWoW not available, reset the state
                self.AUTONAVIGATE.enabled = false
                TWRA_SavedVariables.options.autoNavigate = false
                self:Debug("nav", "AutoNavigate disabled: SuperWoW not available")
            end
        else
            -- Make sure scanning is stopped if disabled
            self:StopAutoNavigateScan()
        end
    end

    -- Ensure initialization completes properly
    self.AUTONAVIGATE.initialized = true
    
    self:Debug("nav", "AutoNavigate initialized with scan frequency: " .. 
               (self.AUTONAVIGATE.scanFreq or "default") .. "s")
end

-- Toggle AutoNavigate feature on/off with explicit debugging
function TWRA:ToggleAutoNavigate(state)
    -- Debug the function call with explicit information
    self:Debug("nav", "ToggleAutoNavigate called with state: " .. tostring(state) .. 
               " (current state: " .. tostring(self.AUTONAVIGATE.enabled) .. ")")
    
    -- Determine the new state
    local newState
    if state ~= nil then
        -- Use provided state
        newState = state
    else
        -- Toggle current state
        newState = not self.AUTONAVIGATE.enabled
    end
    
    -- Only proceed if state is actually changing
    if newState == self.AUTONAVIGATE.enabled then
        self:Debug("nav", "AutoNavigate already " .. (newState and "enabled" or "disabled") .. ", no action needed")
        return self.AUTONAVIGATE.enabled
    end
    
    -- Set the new state
    self.AUTONAVIGATE.enabled = newState
    
    -- Save to config
    if not TWRA_SavedVariables.options then TWRA_SavedVariables.options = {} end
    TWRA_SavedVariables.options.autoNavigate = newState
    
    -- Debug with explicit state info
    self:Debug("nav", "AutoNavigate " .. (newState and "enabled" or "disabled") .. 
              " (saved value: " .. tostring(TWRA_SavedVariables.options.autoNavigate) .. ")")
    
    -- Start or stop scanning based on new state
    if newState then
        -- First check SuperWoW support
        if self:CheckSuperWoWSupport() then
            self:StartAutoNavigateScan()
            self:Debug("nav", "AutoNavigate scanning activated with frequency: " .. self.AUTONAVIGATE.scanFreq .. "s")
        else
            self:Debug("nav", "AutoNavigate enabled but SuperWoW not available, scanning disabled")
            -- If SuperWoW is not available, reset the enabled state
            self.AUTONAVIGATE.enabled = false
            TWRA_SavedVariables.options.autoNavigate = false
        end
    else
        self:StopAutoNavigateScan()
        self:Debug("nav", "AutoNavigate scanning deactivated")
    end
    
    return self.AUTONAVIGATE.enabled
end

-- Start the AutoNavigate scanning - make sure this function works independently
function TWRA:StartAutoNavigateScan()
    -- Debug output to verify this function is being called
    self:Debug("nav", "StartAutoNavigateScan called")

    -- Clear any existing timer to avoid duplicates
    if self.AUTONAVIGATE.timer then
        self:CancelTimer(self.AUTONAVIGATE.timer)
        self.AUTONAVIGATE.timer = nil
        self:Debug("nav", "Cleared existing AutoNavigate timer")
    end
    
    -- Get scan frequency from settings or use default
    local scanFreq = self.AUTONAVIGATE.scanFreq or 1
    
    -- Create and configure the scan frame if it doesn't exist
    if not self.AUTONAVIGATE.scanFrame then
        self.AUTONAVIGATE.scanFrame = CreateFrame("Frame", "TWRAAutoNavigateFrame", UIParent)
        self.AUTONAVIGATE.lastUpdate = GetTime()
        
        -- Use SetScript to handle frame updates
        self.AUTONAVIGATE.scanFrame:SetScript("OnUpdate", function()
            -- Only proceed if auto navigate is actually enabled
            if not TWRA.AUTONAVIGATE or not TWRA.AUTONAVIGATE.enabled then
                return
            end
            
            -- Check if enough time has passed since last scan
            local currentTime = GetTime()
            local elapsed = currentTime - (TWRA.AUTONAVIGATE.lastUpdate or 0)
            
            -- Only scan when we've waited long enough
            if elapsed >= TWRA.AUTONAVIGATE.scanFreq then
                -- Reset the timer
                TWRA.AUTONAVIGATE.lastUpdate = currentTime
                
                -- Debug output if in debug mode
                if TWRA.AUTONAVIGATE.debug then
                    TWRA:Debug("nav", "Auto scan triggering after " .. string.format("%.1f", elapsed) .. "s")
                end
                
                -- Perform the actual scan
                TWRA:ScanMarkedTargets()
            end
        end)
    end
    
    -- Reset last update time to ensure first scan happens quickly
    self.AUTONAVIGATE.lastUpdate = GetTime()
    
    -- Perform an initial scan immediately
    self:ScanMarkedTargets()
    
    -- Ensure the scan frame is shown and working
    self.AUTONAVIGATE.scanFrame:Show()
    
    self:Debug("nav", "AutoNavigate continuous scanning active with " .. scanFreq .. "s interval")
    return true
end

-- Stop scanning for marked targets
function TWRA:StopAutoNavigateScan()
    -- Debug output to verify this function is being called
    self:Debug("nav", "StopAutoNavigateScan called")
    
    -- Hide the scan frame to stop OnUpdate processing
    if self.AUTONAVIGATE.scanFrame then
        self.AUTONAVIGATE.scanFrame:Hide()
        self:Debug("nav", "AutoNavigate scan frame hidden")
    end
    
    -- Clear any existing timer
    if self.AUTONAVIGATE.timer then
        self:CancelTimer(self.AUTONAVIGATE.timer)
        self.AUTONAVIGATE.timer = nil
    end
    
    -- Reset tracking variables
    self.AUTONAVIGATE.lastMarkedGuid = nil
    
    self:Debug("nav", "AutoNavigate scan stopped")
end

-- Simplified scan function that uses only the direct SuperWoW approach
function TWRA:ScanMarkedTargets()
    -- Add debug message to confirm scan is running
    self:Debug("nav", "Scanning for marked targets...")
    
    -- Make sure SuperWoW is available
    if not self:CheckSuperWoWSupport(true) then 
        if self.AUTONAVIGATE.debug == true then
            self:Debug("nav", "SuperWoW not available, skipping scan")
        end
        return 
    end
    
    -- Use direct mark8 reference for skull-marked units (SuperWoW feature)
    local markUnitId = "mark8"  -- Skull is always mark8
    
    -- Check if mark8 exists and get its guid
    local exists, guid = UnitExists("mark8")
    if not exists then
        if self.AUTONAVIGATE.debug and self.AUTONAVIGATE.lastMarkedGuid ~= "none" then
            self:Debug("nav", "No skull-marked units found")
            self.AUTONAVIGATE.lastMarkedGuid = "none" -- Use "none" as a marker so we don't spam this message
        end
        return
    end
    
    -- Make sure we got a valid GUID
    if not guid or guid == "" then
        self:Debug("nav", "Unit exists but no GUID available for skull-marked unit")
        return
    end
    
    local name = UnitName("mark8")
    
    if self.AUTONAVIGATE.debug then
        self:Debug("nav", "Found skull-marked unit: " .. name .. " with GUID: " .. guid)
    end
    
    -- Only process if this is a new GUID to avoid constant processing
    if guid ~= self.AUTONAVIGATE.lastMarkedGuid then
        if self.AUTONAVIGATE.debug then
            self:Debug("nav", "Processing new skull-marked unit")
        end
        
        self:ProcessMarkedMob(name, guid)
        self.AUTONAVIGATE.lastMarkedGuid = guid
    end
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
    
    -- Check the assignments data for GUID rows
    if TWRA_SavedVariables and TWRA_SavedVariables.assignments and TWRA_SavedVariables.assignments.data then
        -- Get the saved data directly from the SavedVariables
        local savedData = TWRA_SavedVariables.assignments.data
        
        if self.AUTONAVIGATE.debug then
            self:Debug("nav", "Checking assignment data for GUIDs...")
        end
        
        -- Track current section while iterating through the flat array
        local currentSection = nil
        
        -- Iterate through all rows
        for i = 1, table.getn(savedData) do
            local row = savedData[i]
            
            -- Update current section name if this row has one
            if type(row) == "table" and row[1] and row[1] ~= "" then
                currentSection = row[1]
            end
            
            -- Check if it's a GUID row - in flat data structure the GUID is in column 2
            if type(row) == "table" and row[2] == "GUID" then
                if self.AUTONAVIGATE.debug and currentSection then
                    self:Debug("nav", "Found GUID row in section: " .. currentSection)
                end
                
                -- Check each cell in the row for GUIDs
                for j = 3, table.getn(row) do
                    local rowGuid = row[j]
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
                                    currentSection .. ": " .. rowGuid)
                            end
                            return currentSection
                        end
                        
                        -- Try partial matching with the end of the GUID
                        if shortGuid and string.len(normalizedRowGuid) >= 8 then
                            local shortRowGuid = string.sub(normalizedRowGuid, -12)
                            if string.find(shortRowGuid, shortGuid, 1, true) or 
                               string.find(shortGuid, shortRowGuid, 1, true) then
                                if self.AUTONAVIGATE.debug then
                                    self:Debug("nav", "Found partial GUID match for " .. 
                                        currentSection .. ": " .. shortRowGuid .. " ~ " .. shortGuid)
                                end
                                return currentSection
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

-- Helper function to get section index by name
function TWRA:GetSectionIndex(sectionName)
    if not self.navigation or not self.navigation.handlers then 
        return 1 -- Default to first section if navigation not ready
    end
    
    -- Look for the section by name
    for i = 1, table.getn(self.navigation.handlers) do
        if self.navigation.handlers[i] == sectionName then
            return i
        end
    end
    
    -- If not found, return current index or default to 1
    return self.navigation.currentIndex or 1
end

-- Simpler test function that just works with the current target
function TWRA:TestCurrentTarget()
    local exists, guid = UnitExists("target")
    
    if not exists then
        self:Debug("nav", "No target selected")
        return
    end
    
    local name = UnitName("target")
    
    if not guid then
        self:Debug("nav", "No GUID available for target: " .. name)
        return
    end
    
    -- Show the GUID
    self:Debug("nav", guid .. " " .. name)
    
    -- Force this target to be processed as if it was skull-marked
    self.AUTONAVIGATE.lastMarkedGuid = nil -- Reset to allow processing
    self:ProcessMarkedMob(name, guid)
end

-- Add a function to check current target for debugging
function TWRA:CheckCurrentTarget()
    local exists, guid = UnitExists("target")
    
    if not exists then
        self:Debug("nav", "No target selected")
        return
    end
    
    local name = UnitName("target")
    
    self:Debug("nav", "Target: " .. name .. " (" .. (guid or "no GUID") .. ")")
    
    if guid then
        -- Try to find the section directly
        local targetSection = self:FindSectionByGuid(guid)
        if targetSection then
            self:Debug("nav", "Found mapping to section: " .. targetSection)
        else
            self:Debug("nav", "No mapping found")
        end
    end
end

-- Add toggle function for UI
function TWRA:ToggleAutoNavigate()
    if not self:CheckSuperWoWSupport() then
        self:Debug("error", "AutoNavigate requires SuperWoW, but it's not available")
        return
    end
    
    self.AUTONAVIGATE.enabled = not self.AUTONAVIGATE.enabled
    self:Debug("nav", "AutoNavigate " .. 
        (self.AUTONAVIGATE.enabled and "enabled" or "disabled"))
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
        
        -- Show GUID mappings (Updated for flat data structure)
        if TWRA_SavedVariables and TWRA_SavedVariables.assignments and TWRA_SavedVariables.assignments.data then
            local savedData = TWRA_SavedVariables.assignments.data
            local currentSection = nil
            
            self:Debug("nav", "Checking for GUIDs:")
            for i = 1, table.getn(savedData) do
                local row = savedData[i]
                
                -- Track current section
                if type(row) == "table" and row[1] and row[1] ~= "" then
                    currentSection = row[1]
                end
                
                -- Look for GUID rows in this section
                if type(row) == "table" and row[2] == "GUID" then
                    self:Debug("nav", "  Section '" .. (currentSection or "Unknown") .. "' GUIDs:")
                    for j = 3, table.getn(row) do
                        if row[j] and row[j] ~= "" then
                            self:Debug("nav", "    " .. row[j])
                        end
                    end
                end
            end
        end
    end
end

-- Add a new function to list all GUIDs and their sections
function TWRA:ListAllGuids()
    self:Debug("nav", "Listing all stored GUIDs and their sections:")
    
    -- Check if we have assignment data
    if not TWRA_SavedVariables or not TWRA_SavedVariables.assignments or not TWRA_SavedVariables.assignments.data then
        self:Debug("nav", "No assignment data available")
        return
    end
    
    local savedData = TWRA_SavedVariables.assignments.data
    local guidCount = 0
    local currentSection = nil
    local guidsBySection = {}
    
    -- First pass: collect all GUIDs by section
    for i = 1, table.getn(savedData) do
        local row = savedData[i]
        
        -- Skip if not a table
        if type(row) ~= "table" then
            self:Debug("nav", "Warning: Found non-table row at index " .. i)
            self:Debug("nav", "  Value: " .. tostring(row))
            self:Debug("nav", "  Type: " .. type(row))
            -- Continue to next iteration
        else
            -- Update current section name if this row has one
            if row[1] and row[1] ~= "" then
                currentSection = row[1]
            end
            
            -- Check if it's a GUID row - in flat data structure the GUID is in column 2
            if row[2] == "GUID" then
                -- Make sure we have a section table
                if not guidsBySection[currentSection] then
                    guidsBySection[currentSection] = {}
                end
                
                -- Add each GUID in this row
                for j = 3, table.getn(row) do
                    local guid = row[j]
                    if guid and guid ~= "" then
                        table.insert(guidsBySection[currentSection], guid)
                        guidCount = guidCount + 1
                    end
                end
            end
        end
    end
    
    -- Second pass: display the results
    if guidCount == 0 then
        self:Debug("nav", "No GUIDs found in the data")
        return
    end
    
    self:Debug("nav", "Found " .. guidCount .. " GUIDs in " .. 
                                 table.getn(guidsBySection) .. " sections")
    
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

-- Execute registration immediately
TWRA:RegisterAutoNavigateEvents()