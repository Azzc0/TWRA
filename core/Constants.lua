-- Core constants and namespace initialization
-- This file should have no dependencies and contain only basic initialization

-- Initialize main addon table
TWRA = TWRA or {}

-- Initialize all major namespaces to avoid nil errors
TWRA.UI = TWRA.UI or {}
TWRA.SYNC = TWRA.SYNC or {
    PREFIX = "TWRA",
    COMMANDS = {
        VERSION = "VERSION",      -- For version checking
        SECTION = "SECTION",      -- For live section updates
        DATA_REQUEST = "DREQ",    -- Request full data
        DATA_RESPONSE = "DRES",   -- Send full data
        ANNOUNCE = "ANC"          -- Announce new import
    },
    liveSync = false,            -- Live sync enabled
    pendingSection = nil,        -- Section to navigate to after sync
    lastRequestTime = 0,         -- Throttle requests
    requestTimeout = 5,          -- Time to wait before requesting again
}

-- Initialize DEBUG namespace
TWRA.DEBUG = TWRA.DEBUG or {
    enabled = false,        -- Master switch for all debugging
    categories = {          -- Individual category toggles
        sync = false,       -- Sync-related messages
        ui = false,         -- UI-related messages
        data = false,       -- Data processing messages
        nav = false,        -- Navigation messages
        general = false     -- General debug messages
    },
    logLevel = 1,           -- Default log level
    showDetails = false     -- Detailed logging toggle
}

-- Initialize AutoNavigate namespace
TWRA.AUTONAVIGATE = TWRA.AUTONAVIGATE or {
    enabled = false,          -- Feature toggle
    hasSupported = false,     -- Whether SuperWoW features are available
    lastMarkedGuid = nil,     -- Last mob GUID we processed
    debug = false,            -- Enable debug messages
    scanTimer = 0,            -- Timer for periodic scanning
    scanFreq = 1              -- How often to scan (seconds)
}

-- Initialize saved variables structure
TWRA_SavedVariables = TWRA_SavedVariables or {
    assignments = {
        data = nil,          -- Decoded assignment data
        source = nil,        -- Original Base64 string
        timestamp = nil,     -- When the data was last updated
        version = 1,         -- Data structure version
        currentSection = 1   -- Currently selected section index
    },
    options = {
        tankSync = false,      -- Tank sync option
        liveSync = false,      -- Live sync option
        announceChannel = "GROUP" -- Default announce channel
    },
    debug = {
        enabled = false,
        logLevel = 1,
        showDetails = false,
        categories = {}
    }
}

-- Class colors for vanilla WoW (pre-TBC)
TWRA.VANILLA_CLASS_COLORS = {
    ["DRUID"] = { r = 1.0, g = 0.49, b = 0.04 },
    ["HUNTER"] = { r = 0.67, g = 0.83, b = 0.45 },
    ["MAGE"] = { r = 0.41, g = 0.8, b = 0.94 },
    ["PALADIN"] = { r = 0.96, g = 0.55, b = 0.73 },
    ["PRIEST"] = { r = 1.0, g = 1.0, b = 1.0 },
    ["ROGUE"] = { r = 1.0, g = 0.96, b = 0.41 },
    ["SHAMAN"] = { r = 0.0, g = 0.44, b = 0.87 },
    ["WARLOCK"] = { r = 0.58, g = 0.51, b = 0.79 },
    ["WARRIOR"] = { r = 0.78, g = 0.61, b = 0.43 }
}

-- Player status colors
TWRA.STATUS_COLORS = {
    ["ONLINE"] = { r = 1.0, g = 1.0, b = 1.0 },    -- White for online players
    ["OFFLINE"] = { r = 0.5, g = 0.5, b = 0.5 },   -- Grey for offline players
    ["MISSING"] = { r = 1.0, g = 0.3, b = 0.3 }    -- Red for missing players
}

-- Class group name mappings
TWRA.CLASS_GROUP_NAMES = {
    ["Druids"] = "DRUID",
    ["Hunters"] = "HUNTER",
    ["Mages"] = "MAGE",
    ["Paladins"] = "PALADIN",
    ["Priests"] = "PRIEST",
    ["Rogues"] = "ROGUE",
    ["Shamans"] = "SHAMAN",
    ["Warlocks"] = "WARLOCK",
    ["Warriors"] = "WARRIOR"
}

-- Class texture coordinates
TWRA.CLASS_COORDS = {
    ["WARRIOR"] = {0, 0.25, 0, 0.25},
    ["MAGE"] = {0.25, 0.5, 0, 0.25},
    ["ROGUE"] = {0.5, 0.75, 0, 0.25},
    ["DRUID"] = {0.75, 1, 0, 0.25},
    ["HUNTER"] = {0, 0.25, 0.25, 0.5},
    ["SHAMAN"] = {0.25, 0.5, 0.25, 0.5},
    ["PRIEST"] = {0.5, 0.75, 0.25, 0.5},
    ["WARLOCK"] = {0.75, 1, 0.25, 0.5},
    ["PALADIN"] = {0, 0.25, 0.5, 0.75}
}

-- Icons data from TWRA.lua
TWRA.ICONS = {
    -- Format: name = {texture, x1, x2, y1, y2}
    ["Skull"] = {"Interface\\TargetingFrame\\UI-RaidTargetingIcons", 0.75, 1, 0.25, 0.5},
    ["Cross"] = {"Interface\\TargetingFrame\\UI-RaidTargetingIcons", 0.5, 0.75, 0.25, 0.5},
    ["Square"] = {"Interface\\TargetingFrame\\UI-RaidTargetingIcons", 0.25, 0.5, 0.25, 0.5},
    ["Moon"] = {"Interface\\TargetingFrame\\UI-RaidTargetingIcons", 0, 0.25, 0.25, 0.5},
    ["Triangle"] = {"Interface\\TargetingFrame\\UI-RaidTargetingIcons", 0.75, 1, 0, 0.25},
    ["Diamond"] = {"Interface\\TargetingFrame\\UI-RaidTargetingIcons", 0.5, 0.75, 0, 0.25},
    ["Circle"] = {"Interface\\TargetingFrame\\UI-RaidTargetingIcons", 0.25, 0.5, 0, 0.25},
    ["Star"] = {"Interface\\TargetingFrame\\UI-RaidTargetingIcons", 0, 0.25, 0, 0.25},
    ["Warning"] = {"Interface\\DialogFrame\\DialogAlertIcon", 0, 1, 0, 1},
    ["Note"] = {"Interface\\TutorialFrame\\TutorialFrame-QuestionMark", 0, 1, 0, 1},
    ["GUID"] = {"Interface\\Icons\\INV_Misc_Note_01", 0, 1, 0, 1}
}

-- Colored icon text for announcements
TWRA.COLORED_ICONS = {
    ['Skull'] = '|cFFF1EFE4[Skull]|r',
    ['Cross'] = '|cFFB20A05[Cross]|r',
    ['Square'] = '|cFF00B9F3[Square]|r',
    ['Moon'] = '|cFF8FB9D0[Moon]|r',
    ['Triangle'] = '|cFF2BD923[Triangle]|r',
    ['Diamond'] = '|cffB035F2[Diamond]|r',
    ['Circle'] = '|cFFE76100[Circle]|r',
    ['Star'] = '|cFFF7EF52[Star]|r',
}

-- Role icons using standard game textures
TWRA.ROLE_ICONS = {
    ["Tank"] = "Interface\\Icons\\Ability_Warrior_DefensiveStance",     -- Tank
    ["Heal"] = "Interface\\Icons\\Spell_Holy_HolyBolt",                 -- Heal
    ["DPS"] = "Interface\\Icons\\INV_Sword_04",                         -- DPS
    ["Sap"] = "Interface\\Icons\\Ability_Sap",
    ["Purge"] = "Interface\\Icons\\Spell_Holy_Dispel",
    ["Shackle"] = "Interface\\Icons\\Spell_Nature_Slow",
    ["Banish"] = "Interface\\Icons\\Spell_Shadow_Cripple",
    ["Kite"] = "Interface\\Icons\\Ability_Rogue_Sprint",
    ["Bomb"] = "Interface\\Icons\\spell_fire_selfdestruct",
    ["Interrupt"] = "Interface\\Icons\\Ability_Kick",
    ["Misc"] = "Interface\\Icons\\INV_Misc_Gear_01"
}

-- TWRA Constants

-- Debug system defaults
TWRA.DEBUG_DEFAULTS = {
    ENABLED = false,
    LOG_LEVEL = 3,  -- 1=Errors, 2=Warnings, 3=Standard, 4=Detailed
    SHOW_DETAILS = false,
    
    -- Debug category colors
    COLORS = {
        general = "FFFFFF",  -- White
        ui = "33FF33",       -- Green
        data = "33AAFF",     -- Light Blue
        sync = "FF33FF",     -- Pink
        nav = "FFAA33",      -- Orange
        osd = "FFFF33",      -- Yellow
        error = "FF0000",    -- Red
        warning = "FFAA00",  -- Orange
        details = "AAAAAA"   -- Gray
    },
    
    -- Debug categories
    CATEGORIES = {
        general = {
            name = "General",
            description = "Core addon functionality",
            enabled = false
        },
        ui = {
            name = "User Interface",
            description = "UI creation and updates",
            enabled = false
        },
        data = {
            name = "Data Processing",
            description = "Assignment data handling",
            enabled = false
        },
        sync = {
            name = "Synchronization",
            description = "Raid sync and communication",
            enabled = false
        },
        nav = {
            name = "Navigation",
            description = "Section navigation handling",
            enabled = false
        },
        osd = {
            name = "On-Screen Display",
            description = "OSD notifications and updates",
            enabled = false
        }
    }
}
