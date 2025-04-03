TWRA = TWRA or {}

-- Example player data (only used for demo purposes)
TWRA.EXAMPLE_PLAYERS = {
    -- Active players
    ["Azzco"] = "WARRIOR",
    ["Recin"] = "WARRIOR",
    ["Nytorpa"] = "WARRIOR",
    ["Dhl"] = "DRUID",
    ["Lenato"] = "PALADIN",
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
    {"Grand Widow Faerlina", "Icon", "Target", "Tank", "Pull", "MC", "Sinful", "", ""},
    {"Grand Widow Faerlina", "Skull", "Naxxramas Follower", "Azzco", "", "", "", "", ""},
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
    {"Thaddius", "Note", "if Feugen and Stalagg doesn't die at the same time they'll ressurrect.", "", "", "", "", ""},
    
    -- Empty rows to ensure proper termination
    {"", "", "", "", "", "", "", "", ""},
    {"", "", "", "", "", "", "", "", ""},
    {"", "", "", "", "", "", "", "", ""},
    {"", "", "", "", "", "", "", "", ""}
}

-- Function to load example data
function TWRA:LoadExampleData()
    DEFAULT_CHAT_FRAME:AddMessage("TWRA Debug: Loading example data")
    
    -- Set a flag to indicate we're using example data
    self.usingExampleData = true
    
    -- Store the example data
    self.fullData = self.EXAMPLE_DATA
    
    -- Generate a simple timestamp
    local timestamp = time()
    
    -- Create a Base64-ish representation for storage
    -- We'll just use what's already in the Example.lua file for simplicity
    local fakeSource = "EXAMPLE_DATA"
    
    -- Save the data properly to use the existing UI mechanism
    TWRA_SavedVariables.assignments = {
        data = self.EXAMPLE_DATA,
        source = fakeSource,
        timestamp = timestamp,
        version = 1,
        currentSection = 1
    }
    
    -- Rebuild navigation with the example data
    self:RebuildNavigation()
    
    -- Set current section to first section
    self.navigation.currentIndex = 1
    
    -- Save the current section
    self:SaveCurrentSection()
    
    return true
end
TWRA:Debug("data", "Example module loaded")