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
        DEFAULT_CHAT_FRAME:AddMessage("TWRA: SuperWoW features not available - AutoNavigate disabled")
    end
    
    return hasSuperWow
end

-- Initialize AutoNavigate function
function TWRA:InitializeAutoNavigate()
    DEFAULT_CHAT_FRAME:AddMessage("TWRA: Initializing AutoNavigate module")
    
    -- Clear any existing timer
    if self.AUTONAVIGATE.timer then
        self:CancelTimer(self.AUTONAVIGATE.timer)
        self.AUTONAVIGATE.timer = nil
    end
    
    -- Set up the scanning timer if enabled
    if self.AUTONAVIGATE.enabled then
        self:StartAutoNavigate()
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("TWRA: AutoNavigate initialized with scan frequency: " .. self.AUTONAVIGATE.scanFreq .. "s")
end

-- Toggle AutoNavigate on/off
function TWRA:ToggleAutoNavigate(enable)
    if enable then
        self.AUTONAVIGATE.enabled = true
        self:StartAutoNavigate()
        DEFAULT_CHAT_FRAME:AddMessage("TWRA: AutoNavigate enabled")
    else
        self.AUTONAVIGATE.enabled = false
        if self.AUTONAVIGATE.timer then
            self:CancelTimer(self.AUTONAVIGATE.timer)
            self.AUTONAVIGATE.timer = nil
        end
        DEFAULT_CHAT_FRAME:AddMessage("TWRA: AutoNavigate disabled")
    end
    
    -- Save setting
    if TWRA_SavedVariables and TWRA_SavedVariables.options then
        TWRA_SavedVariables.options.autoNavigate = self.AUTONAVIGATE.enabled
    end
end

-- Start the AutoNavigate scanning timer
function TWRA:StartAutoNavigate()
    -- Clear any existing timer
    if self.AUTONAVIGATE.timer then
        self:CancelTimer(self.AUTONAVIGATE.timer)
    end
    
    -- Create the scanning timer
    self.AUTONAVIGATE.timer = self:ScheduleTimer(function()
        self:ScanForTargetAndNavigate()
        -- Re-schedule timer recursively if still enabled
        if self.AUTONAVIGATE.enabled then
            self:StartAutoNavigate()
        end
    end, self.AUTONAVIGATE.scanFreq)
end

-- Core function to scan for target and navigate to the appropriate section
function TWRA:ScanForTargetAndNavigate()
    -- Check if we have data to work with
    if not self.fullData or table.getn(self.fullData) == 0 then
        return
    end
    
    -- Get current target information
    local targetName = UnitName("target")
    if not targetName or targetName == "" or targetName == UnitName("player") then
        return -- No valid target selected
    end
    
    -- Skip if this is the same target we already processed
    if targetName == self.AUTONAVIGATE.lastTarget then
        return
    end
    
    -- Search for target in data
    local targetSection = nil
    local targetRow = nil
    
    for i = 1, table.getn(self.fullData) do
        local row = self.fullData[i]
        if row[3] == targetName then
            targetSection = row[1]
            targetRow = i
            break
        end
    end
    
    -- If found, navigate to that section
    if targetSection and targetSection ~= "" then
        self.AUTONAVIGATE.lastTarget = targetName -- Update last target
        
        -- Navigate to section WITHOUT showing the main frame
        self:NavigateToSectionQuietly(targetSection)
        DEFAULT_CHAT_FRAME:AddMessage("TWRA: AutoNavigated to section: " .. targetSection .. " for target: " .. targetName)
    end
end

-- New function to navigate without showing the main frame
function TWRA:NavigateToSectionQuietly(targetSection)
    -- Basic error checking
    if not self.navigation then return false end
    if not self.navigation.handlers then return false end
    
    local handlers = self.navigation.handlers
    local numSections = table.getn(handlers)
    
    if numSections == 0 then return false end
    
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
    
    -- Update current index
    self.navigation.currentIndex = sectionIndex
    
    -- Update UI text if frame is visible
    if self.navigation.handlerText and sectionName then
        self.navigation.handlerText:SetText(sectionName)
    end
    
    -- Save as current section
    self:SaveCurrentSection()
    
    -- Always show OSD
    self:ShowSectionNameOverlay(sectionName, sectionIndex, numSections)
    
    -- Broadcast to group if sync enabled
    if self.SYNC and self.SYNC.liveSync and self.BroadcastSectionChange then
        self:BroadcastSectionChange(sectionIndex)
    end
    
    -- If enabled, update tanks
    if self.SYNC and self.SYNC.tankSync and self:IsORA2Available() then
        self:UpdateTanks()
    end
    
    return true
end

-- Simplified scan function that uses only the direct SuperWoW approach
function TWRA:ScanMarkedTargets()
    -- Make sure SuperWoW is available
    if not self:CheckSuperWoWSupport(true) then 
        if self.AUTONAVIGATE.debug then
            DEFAULT_CHAT_FRAME:AddMessage("TWRA: SuperWoW not available, skipping scan")
        end
        return 
    end
    
    -- Use direct mark8 reference for skull-marked units (SuperWoW feature)
    local markUnitId = "mark8"  -- Skull is always mark8
    
    -- According to SuperWoW wiki, we need to set the mouseover unit first
    -- This is necessary to actually query information about the marked unit
    -- SetMouseoverUnit(markUnitId)
    
    -- Check if mark8 exists and get its guid
    local exists = UnitExists("mark8")
    if not exists then
        if self.AUTONAVIGATE.debug and self.AUTONAVIGATE.lastMarkedGuid ~= "none" then
            DEFAULT_CHAT_FRAME:AddMessage("TWRA: No skull-marked units found")
            self.AUTONAVIGATE.lastMarkedGuid = "none" -- Use "none" as a marker so we don't spam this message
        end
        return
    end
    
    local exists, guid = UnitExists("mouseover")
    if not guid or guid == "" then
        if self.AUTONAVIGATE.debug then
            DEFAULT_CHAT_FRAME:AddMessage("TWRA: No GUID available for skull-marked unit")
        end
        return
    end
    
    local name = UnitName("mouseover")
    
    if self.AUTONAVIGATE.debug then
        DEFAULT_CHAT_FRAME:AddMessage("TWRA: Found skull-marked unit: " .. name .. " with GUID: " .. guid)
    end
    
    -- Only process if this is a new GUID to avoid constant processing
    if guid ~= self.AUTONAVIGATE.lastMarkedGuid then
        if self.AUTONAVIGATE.debug then
            DEFAULT_CHAT_FRAME:AddMessage("TWRA: Processing new skull-marked unit")
        end
        
        self:ProcessMarkedMob(name, guid)
        self.AUTONAVIGATE.lastMarkedGuid = guid
    end
end

-- Process a skull-marked mob and navigate to its section if matched
function TWRA:ProcessMarkedMob(mobName, mobId)
    if not mobName or mobName == "" or not mobId then 
        if self.AUTONAVIGATE.debug then
            DEFAULT_CHAT_FRAME:AddMessage("TWRA: Invalid mob data provided")
        end
        return
    end
    
    if self.AUTONAVIGATE.debug then
        DEFAULT_CHAT_FRAME:AddMessage("TWRA: Processing mob: '" .. mobName .. "' with GUID: '" .. mobId .. "'")
    end
    
    -- Look up matching section for this GUID
    local targetSection = self:FindSectionByGuid(mobId)
    
    -- Navigate to the section if one was found
    if targetSection then
        if self.AUTONAVIGATE.debug then
            DEFAULT_CHAT_FRAME:AddMessage("TWRA: Found section '" .. targetSection .. "' for mob: " .. mobName)
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
                DEFAULT_CHAT_FRAME:AddMessage("TWRA: No navigation handlers available")
            end
        end
        
        if sectionIndex > 0 then
            if self.AUTONAVIGATE.debug then
                DEFAULT_CHAT_FRAME:AddMessage("TWRA: Navigating to section index: " .. sectionIndex)
            end
            
            -- Use the defined NavigateToSection function from TWRA.lua
            if self.mainFrame and not self.mainFrame:IsShown() then
                -- Show the main frame if it's hidden
                self.mainFrame:Show()
                DEFAULT_CHAT_FRAME:AddMessage("TWRA: Showing main frame for auto-navigation")
            end
            
            -- Navigate to the section
            self:NavigateToSection(sectionIndex)
            DEFAULT_CHAT_FRAME:AddMessage("TWRA: Auto-navigated to " .. targetSection)
        else
            if self.AUTONAVIGATE.debug then
                DEFAULT_CHAT_FRAME:AddMessage("TWRA: Section name found but no matching index in navigation: " .. targetSection)
            end
        end
    elseif self.AUTONAVIGATE.debug then
        DEFAULT_CHAT_FRAME:AddMessage("TWRA: No section found for " .. mobName .. " (" .. mobId .. ")")
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
        DEFAULT_CHAT_FRAME:AddMessage("TWRA: Looking for GUID: " .. guid)
        DEFAULT_CHAT_FRAME:AddMessage("  Normalized: " .. normalizedGuid)
        DEFAULT_CHAT_FRAME:AddMessage("  Without prefix: " .. guidWithoutPrefix)
        if shortGuid then
            DEFAULT_CHAT_FRAME:AddMessage("  Short GUID: " .. shortGuid)
        end
    end
    
    -- Check the assignments data for GUID rows
    if TWRA_SavedVariables and TWRA_SavedVariables.assignments and TWRA_SavedVariables.assignments.data then
        -- Get the saved data directly from the SavedVariables
        local savedData = TWRA_SavedVariables.assignments.data
        
        if self.AUTONAVIGATE.debug then
            DEFAULT_CHAT_FRAME:AddMessage("TWRA: Checking assignment data for GUIDs...")
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
                    DEFAULT_CHAT_FRAME:AddMessage("TWRA: Found GUID row in section: " .. currentSection)
                end
                
                -- Check each cell in the row for GUIDs
                for j = 3, table.getn(row) do
                    local rowGuid = row[j]
                    if rowGuid and rowGuid ~= "" then
                        if self.AUTONAVIGATE.debug then
                            DEFAULT_CHAT_FRAME:AddMessage("TWRA: Checking GUID: " .. rowGuid)
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
                                DEFAULT_CHAT_FRAME:AddMessage("TWRA: Found exact GUID match for " .. 
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
                                    DEFAULT_CHAT_FRAME:AddMessage("TWRA: Found partial GUID match for " .. 
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
            DEFAULT_CHAT_FRAME:AddMessage("TWRA: No saved assignments data available")
        end
    end
    
    if self.AUTONAVIGATE.debug then
        DEFAULT_CHAT_FRAME:AddMessage("TWRA: No matching section found for GUID: " .. guid)
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
        DEFAULT_CHAT_FRAME:AddMessage("TWRA: No target selected")
        return
    end
    
    local name = UnitName("target")
    
    if not guid then
        DEFAULT_CHAT_FRAME:AddMessage("TWRA: No GUID available for target: " .. name)
        return
    end
    
    -- Show the GUID
    DEFAULT_CHAT_FRAME:AddMessage(guid .. " " .. name)
    
    -- Force this target to be processed as if it was skull-marked
    self.AUTONAVIGATE.lastMarkedGuid = nil -- Reset to allow processing
    self:ProcessMarkedMob(name, guid)
end

-- Add a function to check current target for debugging
function TWRA:CheckCurrentTarget()
    local exists, guid = UnitExists("target")
    
    if not exists then
        DEFAULT_CHAT_FRAME:AddMessage("TWRA: No target selected")
        return
    end
    
    local name = UnitName("target")
    
    DEFAULT_CHAT_FRAME:AddMessage("TWRA: Target: " .. name .. " (" .. (guid or "no GUID") .. ")")
    
    if guid then
        -- Try to find the section directly
        local targetSection = self:FindSectionByGuid(guid)
        if targetSection then
            DEFAULT_CHAT_FRAME:AddMessage("TWRA: Found mapping to section: " .. targetSection)
        else
            DEFAULT_CHAT_FRAME:AddMessage("TWRA: No mapping found")
        end
    end
end

-- Add toggle function for UI
function TWRA:ToggleAutoNavigate()
    if not self:CheckSuperWoWSupport() then
        DEFAULT_CHAT_FRAME:AddMessage("TWRA: AutoNavigate requires SuperWoW, but it's not available")
        return
    end
    
    self.AUTONAVIGATE.enabled = not self.AUTONAVIGATE.enabled
    DEFAULT_CHAT_FRAME:AddMessage("TWRA: AutoNavigate " .. 
        (self.AUTONAVIGATE.enabled and "enabled" or "disabled"))
end

-- Toggle debug mode with enhanced info
function TWRA:ToggleAutoNavigateDebug()
    self.AUTONAVIGATE.debug = not self.AUTONAVIGATE.debug
    DEFAULT_CHAT_FRAME:AddMessage("TWRA: AutoNavigate debug " .. 
        (self.AUTONAVIGATE.debug and "enabled" or "disabled"))
        
    -- Reset last marked GUID when toggling debug
    self.AUTONAVIGATE.lastMarkedGuid = nil
        
    -- When enabling debug, show section data
    if self.AUTONAVIGATE.debug then
        -- Show navigation info
        if self.navigation and self.navigation.handlers then
            DEFAULT_CHAT_FRAME:AddMessage("TWRA: Current sections in order:")
            for i = 1, table.getn(self.navigation.handlers) do
                local name = self.navigation.handlers[i]
                DEFAULT_CHAT_FRAME:AddMessage("  " .. i .. ": " .. name)
            end
            DEFAULT_CHAT_FRAME:AddMessage("Current section: " .. (self.navigation.currentIndex or "unknown"))
        else
            DEFAULT_CHAT_FRAME:AddMessage("TWRA: No navigation data available")
        end
        
        -- Show GUID mappings (Updated for flat data structure)
        if TWRA_SavedVariables and TWRA_SavedVariables.assignments and TWRA_SavedVariables.assignments.data then
            local savedData = TWRA_SavedVariables.assignments.data
            local currentSection = nil
            
            DEFAULT_CHAT_FRAME:AddMessage("TWRA: Checking for GUIDs:")
            for i = 1, table.getn(savedData) do
                local row = savedData[i]
                
                -- Track current section
                if type(row) == "table" and row[1] and row[1] ~= "" then
                    currentSection = row[1]
                end
                
                -- Look for GUID rows in this section
                if type(row) == "table" and row[2] == "GUID" then
                    DEFAULT_CHAT_FRAME:AddMessage("  Section '" .. (currentSection or "Unknown") .. "' GUIDs:")
                    for j = 3, table.getn(row) do
                        if row[j] and row[j] ~= "" then
                            DEFAULT_CHAT_FRAME:AddMessage("    " .. row[j])
                        end
                    end
                end
            end
        end
    end
end

-- Add a new function to list all GUIDs and their sections
function TWRA:ListAllGuids()
    DEFAULT_CHAT_FRAME:AddMessage("TWRA: Listing all stored GUIDs and their sections:")
    
    -- Check if we have assignment data
    if not TWRA_SavedVariables or not TWRA_SavedVariables.assignments or not TWRA_SavedVariables.assignments.data then
        DEFAULT_CHAT_FRAME:AddMessage("TWRA: No assignment data available")
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
            DEFAULT_CHAT_FRAME:AddMessage("TWRA Warning: Found non-table row at index " .. i)
            DEFAULT_CHAT_FRAME:AddMessage("  Value: " .. tostring(row))
            DEFAULT_CHAT_FRAME:AddMessage("  Type: " .. type(row))
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
        DEFAULT_CHAT_FRAME:AddMessage("TWRA: No GUIDs found in the data")
        return
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("TWRA: Found " .. guidCount .. " GUIDs in " .. 
                                 table.getn(guidsBySection) .. " sections")
    
    -- Sort the sections alphabetically for easier reading
    local sortedSections = {}
    for section, _ in pairs(guidsBySection) do
        table.insert(sortedSections, section)
    end
    table.sort(sortedSections)
    
    -- Display each section and its GUIDs
    for _, section in ipairs(sortedSections) do
        DEFAULT_CHAT_FRAME:AddMessage("Section: " .. section)
        
        for _, guid in ipairs(guidsBySection[section]) do
            DEFAULT_CHAT_FRAME:AddMessage("  " .. guid)
        end
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("TWRA: End of GUID listing")
end