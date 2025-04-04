TWRA = TWRA or {}

-- Example player data (only used for demo purposes)
TWRA.EXAMPLE_PLAYERS = {
    -- Active players
    ["Azzco"] = "WARRIOR",
    ["Recin"] = "WARRIOR",
    ["Nytorpa"] = "WARRIOR",
    ["Dhl"] = "DRUID",
    ["Lenato"] = "PALADIN",
    ["Sinfuil"] = "PALADIN",
    ["Kroken"] = "ROGUE",
    ["Kaydaawg"] = "PRIEST",
    ["Slaktaren"] = "PRIEST",
    ["Pooras"] = "DRUID",
    ["Ambulans"] = "SHAMAN",
    ["Heartstiller"] = "PRIEST",
    ["Jouthor"] = "HUNTER",
    ["Nattoega"] = "HUNTER",
    ["Vasslan"] = "HUNTER",
    ["Falken"] = "HUNTER",
    -- Offline player
    ["Slubban"] = "PRIEST|OFFLINE"
}

-- Default example data that loads instantly
TWRA.EXAMPLE_DATA = {
    -- Headers and welcome section
    {"Welcome", "Icon", "Target", "Tank", "DPS", "Heal", "", "", ""},
    {"Welcome", "Star", "Big nasty boss", UnitName("player"), "Kroken", "Kaydaawg", "", "", ""},
    {"Welcome", "Skull", "Add", "Druids", "Mages", "Hunters", "", "", ""},
    {"Welcome", "Cross", "Add", "Paladins", "Priests", "Rogues", "", "", ""},
    {"Welcome", "Moon", "Add", "Shamans", "Warlocks", "Warriors", "", "", ""},
    {"Welcome", "Warning", "Warning text will be announced along with assignments into raidchat.", "", "", "", "", "", ""},
    {"Welcome", "Note", "Note text will not be sent to the chat.", "", "", "", "", "", ""},
    {"Welcome", "Note", "You need to import your own assignments! Check the README on github for how to create your own.", "", "", "", "", "", ""},
    {"Welcome", "Note", "Players not in the raid will be marked red and they will not have an associated class icon", "", "", "", "Heal", "", ""},
    {"Welcome", "Note", "Players offline will be marked grey.", "", "", "", "Kaydaawg", "", ""},
    {"Welcome", "Note", "Lines with your name or your class (plural) will be highlighted.", "", "", "", "Pooras", "", ""},
    
    -- Faerlina example
    {"Grand Widow Faerlina", "Icon", "Target", "Tank", "Pull", "MC", "Heal", "", ""},
    {"Grand Widow Faerlina", "Skull", "Naxxramas Follower", "Azzco", "", "", "Sinfuil", "", ""},
    {"Grand Widow Faerlina", "Cross", "Naxxramas Follower", "Dhl", "", "", "Slaktaren", "", ""},
    {"Grand Widow Faerlina", "Triangle", "Grand Widow Faerlina", "Lenato", "", "", "Ambulans", "", ""},
    {"Grand Widow Faerlina", "Square", "Naxxramas Worshipper", "", "Jouthor", "Slubban", "", "", ""},
    {"Grand Widow Faerlina", "Circle", "Naxxramas Worshipper", "Recin", "Nattoega", "Heartstiller", "", "", ""},
    {"Grand Widow Faerlina", "Moon", "Naxxramas Worshipper", "Nytorpa", "Vasslan", "Heartstiller", "", "", ""},
    {"Grand Widow Faerlina", "Star", "Naxxramas Worshipper", "", "Falken", "Heartstiller", "", "", ""},
    {"Grand Widow Faerlina", "Warning", "Do NOT kill woshippers. We mind control and sacrifice them to counter the boss's enrage!", "", "", "", "", "", ""},
    {"Grand Widow Faerlina", "Note", "We use one healing priest to sacrifice one of the worshippers early.", "", "", "", "", "", ""},
    
    -- Thaddius example
    {"Thaddius", "Icon", "Target", "Tank", "DPS", "DPS", "DPS", "Heal", "Heal"},
    {"Thaddius", "Skull", "Thaddius", "Lenato", "", "", "", "Pooras", "Kaydaawg"},
    {"Thaddius", "Cross", "Stalagg", "Azzco", "Paladins", "Mages", "Warlocks", "Priests", "Paladins"},
    {"Thaddius", "Square", "Feugen", "Dhl", "Warriors", "Rogues", "Hunters", "Shamans", "Druids"},
    {"Thaddius", "Note", "Feugen (right) mana burns around him, it can be outranged.", "", "", "", "", "", ""},
    {"Thaddius", "Warning", "--- BOSS +++", "", "", "", "", "", ""},
    {"Thaddius", "Note", "if Feugen and Stalagg doesn't die at the same time they'll ressurrect.", "", "", "", "", ""}
}

-- Function to load example data
function TWRA:LoadExampleData()
    self:Debug("data", "Loading example data")
    
    -- Store current section name if available
    local currentSectionName = nil
    if self.navigation and self.navigation.currentIndex and
       self.navigation.handlers and self.navigation.currentIndex <= table.getn(self.navigation.handlers) then
        currentSectionName = self.navigation.handlers[self.navigation.currentIndex]
        self:Debug("data", "Remembering current section: " .. currentSectionName)
    end
    
    -- Clear any existing data first
    self:ClearData()
    
    -- Set the flag to indicate we're using example data
    self.usingExampleData = true
    
    -- Create the assignment data in memory
    self.fullData = self.EXAMPLE_DATA
    
    -- Save the example data with proper flags
    TWRA_SavedVariables.assignments = {
        data = self.EXAMPLE_DATA,
        source = "example_data",
        timestamp = time(),
        currentSection = currentSectionName or "Welcome", -- Try to keep current section or default to Welcome
        version = 1,
        isExample = true
    }
    
    -- Rebuild navigation with the new data
    self:RebuildNavigation()
    
    -- Try to restore previous section
    if self.navigation and self.navigation.handlers then
        local foundSection = false
        if currentSectionName then
            -- Try to find the section by name first
            for i, name in ipairs(self.navigation.handlers) do
                if name == currentSectionName then
                    self.navigation.currentIndex = i
                    foundSection = true
                    self:Debug("data", "Restored section: " .. currentSectionName)
                    break
                end
            end
        end
        
        -- If section not found, default to first section
        if not foundSection then
            self.navigation.currentIndex = 1
            self:Debug("data", "Previous section not found, using first section")
        end
        
        -- Update UI if main frame is already created
        if self.mainFrame then
            -- Update navigation display if it exists
            if self.navigation.handlerText and 
               self.navigation.handlers and self.navigation.handlers[self.navigation.currentIndex] then
                self.navigation.handlerText:SetText(self.navigation.handlers[self.navigation.currentIndex])
            end
        end
    end
    
    self:Debug("data", "Example data loaded successfully")
    return true
end

-- Function to load example data and show main view - called by the Example button
function TWRA:LoadExampleDataAndShow()
    -- Load the example data
    if self:LoadExampleData() then
        -- Switch to main view if in options
        if self.currentView == "options" then
            self:ShowMainView()
        else
            -- Just update the display
            self:DisplayCurrentSection()
        end
        
        -- Show user feedback (optional)
        DEFAULT_CHAT_FRAME:AddMessage("TWRA: Example data loaded!")
        
        return true
    end
    
    return false
end

-- Function to check if data is example data
function TWRA:IsExampleData(data)
    if not data then return false end
    
    -- Do a simple check - if the first section is named "Welcome" and there's a note about importing assignments
    for i = 1, table.getn(data) do
        if data[i][1] == "Welcome" and 
           data[i][2] == "Note" and 
           string.find(data[i][3] or "", "import your own assignments") then
            return true
        end
    end
    
    return false
end