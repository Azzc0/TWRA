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
    self:Debug("data", "Loading example data")
    
    -- Clear any existing data first
    self:ClearData()
    
    -- Set up example data
    self.EXAMPLE_DATA = {
        {"Anub", "Icon", "Target", "Tank", "Tank", "Utility", "Healer", "Healer", "Healer"},
        {"Anub", "Skull", "Anub'rekhan", "Azzco", "Heartstiller", "Kaydaawg", "Kaydaawg", "Cozzalisa", "Warriors"},
        {"Anub", "Cross", "Crypt Fiend", "Clickyou", "Clickyou", "Clickyou", "Clickyou", "Clickyou", "Clickyou"},
        {"Anub", "Square", "Crypt Fiend", "Lenato", "Clickyou", "Slubban", "", "", ""},
        {"Anub", "Moon", "Crypt Fiend", "Lenato", "Clickyou", "Slubban", "", "", ""},
        {"Anub", "Triangle", "", "Warriors", "Warlocks", "Shamans", "", "", ""},
        {"Anub", "Diamond", "", "Paladins", "Priests", "Rogues", "ö", "", ""},
        {"Anub", "Circle", "Grand Widow Faerlina", "Druids", "Hunters", "Mages", "Warrior", "", ""},
        {"Anub", "Star", "", "", "", "Group 1,2", "", "", ""},
        {"Anub", "Note", "Use consumables [Free Action Potion]", "", "", "", "", "", ""},
        {"Anub", "Warning", "Melee, use FAP on pull", "", "", "", "", "", ""},
        {"Faerlina", "Icon", "Target", "Tank", "MC", "Healer", "", "", ""},
        {"Faerlina", "Skull", "Faerlina", "Azzco", "Clickyou", "Sinfiull", "", "", ""},
        {"Faerlina", "Warning", "Test", "", "", "", "", "", ""}
    }
    
    -- Create example players for testing
    self.EXAMPLE_PLAYERS = {
        ["Azzco"] = "WARRIOR",
        ["Heartstiller"] = "PALADIN",
        ["Kaydaawg"] = "PRIEST",
        ["Cozzalisa"] = "SHAMAN",
        ["Lenato"] = "DRUID|OFFLINE", -- This player will show as offline
        ["Clickyou"] = "MAGE",
        ["Slubban"] = "ROGUE", -- This is "Kroken" in the original data
        ["Sinfiull"] = "WARLOCK",
        ["Kroken"] = "ROGUE" -- Added Kroken explicitly
    }
    
    -- Set the flag to indicate we're using example data
    self.usingExampleData = true
    
    -- Save the example data with proper isExample flag
    self:SaveAssignments(self.EXAMPLE_DATA, "example_data", nil, true)
    
    self:Debug("data", "Example data loaded with " .. table.getn(self.EXAMPLE_DATA) .. " rows")
    
    return self.EXAMPLE_DATA
end