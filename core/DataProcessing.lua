-- TWRA Data Processing Module
-- Handles assignment data loading, saving, and processing

TWRA = TWRA or {}

-- Load assignments from saved variables
function TWRA:LoadSavedAssignments()
    -- Check if we have saved assignments
    if TWRA_SavedVariables and TWRA_SavedVariables.assignments and TWRA_SavedVariables.assignments.data then
        self:Debug("data", "Loading saved assignments")
        
        -- Set fullData reference for the UI to display
        self.fullData = TWRA_SavedVariables.assignments.data
        
        -- Rebuild navigation based on loaded data
        self:RebuildNavigation()
        
        -- Restore saved section if available
        if TWRA_SavedVariables.assignments.currentSection and 
           self.navigation and self.navigation.handlers then
            -- Make sure the index is valid
            if TWRA_SavedVariables.assignments.currentSection <= table.getn(self.navigation.handlers) then
                self.navigation.currentIndex = TWRA_SavedVariables.assignments.currentSection
            else
                -- If out of range, reset to 1
                self.navigation.currentIndex = 1
            end
            self:SaveCurrentSection()
        end
        
        return true
    else
        self:Debug("data", "No saved assignments found")
        return false
    end
end

-- Rebuilds navigation data based on current fullData
function TWRA:RebuildNavigation()
    -- Make sure we have data
    if not self.fullData then
        self:Debug("error", "Can't rebuild navigation - no data")
        return false
    end
    
    -- Make sure we have navigation structure
    if not self.navigation then
        self.navigation = { handlers = {}, currentIndex = 1 }
    end
    
    -- Clear existing handlers
    self.navigation.handlers = {}
    
    -- Track unique section names
    local seenSections = {}
    
    -- Loop through data and extract section names
    for i = 1, table.getn(self.fullData) do
        local sectionName = self.fullData[i][1]
        if sectionName and not seenSections[sectionName] then
            seenSections[sectionName] = true
            table.insert(self.navigation.handlers, sectionName)
        end
    end
    
    -- Ensure currentIndex is valid
    if not self.navigation.currentIndex or 
       self.navigation.currentIndex > table.getn(self.navigation.handlers) then
        self.navigation.currentIndex = 1
    end
    
    self:Debug("data", "Rebuilt navigation with " .. table.getn(self.navigation.handlers) .. " sections")
    
    return true
end

-- Navigate to a specific section by index
function TWRA:NavigateToSection(sectionIndex, suppressSync)
    -- Check if we have navigation
    if not self.navigation or not self.navigation.handlers then
        self:Debug("error", "Can't navigate - navigation not initialized")
        return false
    end
    
    -- Validate section index
    if sectionIndex < 1 or sectionIndex > table.getn(self.navigation.handlers) then
        self:Debug("error", "Invalid section index: " .. tostring(sectionIndex))
        return false
    end
    
    -- Get section name
    local sectionName = self.navigation.handlers[sectionIndex]
    if not sectionName then
        self:Debug("error", "Unable to get section name for index: " .. tostring(sectionIndex))
        return false
    end
    
    -- Set current index
    self.navigation.currentIndex = sectionIndex
    
    -- Save the current section
    self:SaveCurrentSection()
    
    -- Update display if the frame is showing
    if self.mainFrame and self.mainFrame:IsShown() and self.currentView ~= "options" then
        if self.DisplayCurrentSection then
            self:DisplayCurrentSection()
        end
    end
    
    -- Update section name text
    if self.navigation.handlerText then
        self.navigation.handlerText:SetText(sectionName)
    end
    
    return true
end  -- Fixed closing bracket here (was a closing parenthesis)

-- Save the current section to saved variables
function TWRA:SaveCurrentSection()
    -- Only save if we have assignments already
    if TWRA_SavedVariables.assignments and self.navigation and self.navigation.currentIndex then
        TWRA_SavedVariables.assignments.currentSection = self.navigation.currentIndex
    end
end

-- Process a set of assignments (used for both import and sync)
function TWRA:ProcessAssignments(data, timestamp, source)
    -- Default timestamp if not provided
    if not timestamp then
        timestamp = time()
    end
    
    -- Store assignments in saved variables
    TWRA_SavedVariables.assignments = {
        data = data,
        source = source,  -- Optional serialized source
        timestamp = timestamp,
        version = 1,
        currentSection = 1  -- Start at the first section
    }
    
    -- Update fullData reference for display
    self.fullData = data
    
    -- Rebuild navigation
    self:RebuildNavigation()
    
    return true
end

-- Helper function to navigate to next/previous section
function TWRA:NavigateHandler(direction)
    -- Check if we have navigation
    if not self.navigation or not self.navigation.handlers then
        self:Debug("error", "Can't navigate - navigation not initialized")
        return false
    end
    
    local numHandlers = table.getn(self.navigation.handlers)
    if numHandlers == 0 then
        return false
    end
    
    -- Calculate new index with wrap-around
    local newIndex = self.navigation.currentIndex + direction
    
    -- Handle wrap-around
    if newIndex < 1 then
        newIndex = numHandlers
    elseif newIndex > numHandlers then
        newIndex = 1
    end
    
    -- Navigate to the new section
    return self:NavigateToSection(newIndex)
end

-- Load example data for testing
function TWRA:LoadExampleData()
    self:Debug("data", "Loading example data")
    
    -- Create a simple example data structure
    local exampleData = {
        -- Section 1: Lucifron
        {
            "Lucifron",
            "Note",
            "Decurse priority: Healers > Tanks > DPS"
        },
        {
            "Lucifron",
            "RaidTarget_8",  -- Skull
            "Tank 1",
            "main tank",
            {"Healer 1", "Healer 2"}
        },
        {
            "Lucifron",
            "RaidTarget_7",  -- Cross
            "Tank 2",
            "off tank",
            {"Healer 3"}
        },
        
        -- Section 2: Magmadar
        {
            "Magmadar",
            "Warning",
            "Stand against the wall during fear"
        },
        {
            "Magmadar",
            "RaidTarget_8",  -- Skull
            "Tank 1", 
            "main tank",
            {"Healer 1", "Healer 2", "Healer 3"}
        }
    }
    
    -- Process the example data
    return self:ProcessAssignments(exampleData)
end
