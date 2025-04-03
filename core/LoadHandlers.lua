-- TWRA Load Handlers Module
TWRA = TWRA or {}

-- Initialize navigation handlers for main view
function TWRA:InitializeMainNavigation()
    -- Ensure navigation structure exists
    if not self.navigation then
        self.navigation = { 
            handlers = {},
            currentIndex = 1,
            dropdown = nil 
        }
    end
    
    -- Skip if no full data exists
    if not self.fullData then
        self:Debug("error", "No data available for navigation")
        return false
    end
    
    -- Build handlers list from data
    local handlers = {}
    local uniqueHandlers = {}
    
    for i = 2, table.getn(self.fullData) do  -- Skip header row
        local section = self.fullData[i][1] -- First column is section name
        if section and section ~= "" and not uniqueHandlers[section] then
            uniqueHandlers[section] = true
            table.insert(handlers, section)
        end
    end
    
    -- Store handlers
    self.navigation.handlers = handlers
    
    -- Setup dropdown content
    if self.navigation.dropdown then
        -- Convert handlers to dropdown items format
        local items = {}
        for i, handler in ipairs(handlers) do
            table.insert(items, {
                text = handler,
                name = handler,
                value = i
            })
        end
        
        -- Set dropdown items with navigation callback
        self.navigation.dropdown:SetItems(items, function(item)
            -- Navigate to selected section
            self:NavigateToSection(item.value) 
        end)  -- Fixed missing closing parenthesis here
        
        -- Set initial selection (respecting saved selection if available)
        local savedSection = 1
        if TWRA_SavedVariables and TWRA_SavedVariables.assignments and 
           TWRA_SavedVariables.assignments.currentSection then
            savedSection = TWRA_SavedVariables.assignments.currentSection
        end
        
        -- Make sure saved section is valid
        if savedSection > table.getn(handlers) then
            savedSection = 1
        end
        
        self.navigation.currentIndex = savedSection
        self.navigation.dropdown:SetSelectedItem(savedSection, true)
    end
    
    -- Debug output
    self:Debug("nav", "Initialized navigation with " .. table.getn(handlers) .. " sections")
    
    return true
end

-- Update the navigation to display the current section
function TWRA:UpdateNavigation()
    -- Skip if no navigation
    if not self.navigation or not self.navigation.handlers or not self.navigation.dropdown then
        return false
    end
    
    -- Get current section
    local currentIndex = self.navigation.currentIndex
    local sectionName = self.navigation.handlers[currentIndex]
    
    -- Update dropdown text
    if self.navigation.dropdown and self.navigation.dropdown.SetSelectedItem then
        self.navigation.dropdown:SetSelectedItem(currentIndex, true)
    elseif self.navigation.handlerText then
        -- Fallback for older code
        self.navigation.handlerText:SetText(sectionName or "Unknown")
    end
    
    -- Ensure we display the section data
    self:DisplayCurrentSection()
    
    return true
end

-- Load saved assignments and initialize navigation
function TWRA:LoadSavedAssignmentsAndInitNavigation()
    -- Load saved assignments first
    if TWRA_SavedVariables and TWRA_SavedVariables.assignments and TWRA_SavedVariables.assignments.data then
        self.fullData = TWRA_SavedVariables.assignments.data
        
        -- Initialize navigation with the data
        local result = self:InitializeMainNavigation()
        
        -- Display current section
        if result then
            self:DisplayCurrentSection()
        else
            self:Debug("error", "Failed to initialize navigation")
        end
        
        return result
    end
    
    -- If no saved data, check if we should load example data
    if self.LoadExampleData then
        self:Debug("data", "No saved assignments found, loading example data")
        return self:LoadExampleData()
    end
    
    return false
end

-- Explicitly call this when navigation setup is needed
function TWRA:SetupNavigationDropdown()
    -- Skip if no navigation or handlers
    if not self.navigation or not self.navigation.handlers or not self.navigation.dropdown then
        self:Debug("error", "Cannot setup navigation dropdown - missing components")
        return false
    end
    
    -- Convert handlers to dropdown items format
    local items = {}
    for i, handler in ipairs(self.navigation.handlers) do
        table.insert(items, {
            text = handler,
            name = handler,
            value = i
        })
    end
    
    -- Set dropdown items with navigation callback
    self.navigation.dropdown:SetItems(items, function(item, index)
        -- Navigate to selected section
        self:NavigateToSection(item.value)
    end)
    
    -- Set initial selection
    local currentIndex = self.navigation.currentIndex or 1
    if currentIndex > table.getn(self.navigation.handlers) then
        currentIndex = 1
    end
    
    self.navigation.dropdown:SetSelectedItem(currentIndex, true)
    
    return true
end

function TWRA:DisplayCurrentSection()
    -- Get current section name
    local currentHandler = nil
    
    -- Get current section name from navigation
    if self.navigation and self.navigation.handlers and self.navigation.currentIndex then
        currentHandler = self.navigation.handlers[self.navigation.currentIndex]
    end
    
    -- Display the section data
    if self.FilterAndDisplayHandler and currentHandler then
        self:FilterAndDisplayHandler(currentHandler)
    else
        self:Debug("error", "Cannot display section - no handler available")
    end
end
