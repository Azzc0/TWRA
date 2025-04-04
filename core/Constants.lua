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

-- TWRA Constants Module
-- Stores all configuration constants

TWRA = TWRA or {}

-- Debug system defaults
TWRA.DEBUG_DEFAULTS = {
    ENABLED = false,    -- Debug disabled by default
    LOG_LEVEL = 3,      -- Default to standard debug messages
    SHOW_DETAILS = false, -- Don't show detailed messages by default
    
    -- Debug message categories
    CATEGORIES = {
        general = { name = "General", description = "Core addon functionality", enabled = true },
        ui = { name = "User Interface", description = "UI creation and updates", enabled = true },
        data = { name = "Data Processing", description = "Assignment data handling", enabled = false },
        sync = { name = "Synchronization", description = "Raid sync and communication", enabled = true },
        nav = { name = "Navigation", description = "Section navigation handling", enabled = true },
        osd = { name = "On-Screen Display", description = "OSD notifications and updates", enabled = true },
        tank = { name = "Tank", description = "Tank handling functionality", enabled = true },
        error = { name = "Error", description = "Error messages and handling", enabled = true }
    },
    
    -- Color codes for different debug categories
    COLORS = {
        general = "FFFFFF",  -- White
        ui = "33FF33",       -- Green
        data = "33AAFF",     -- Light Blue
        sync = "FF33FF",     -- Pink
        nav = "FFAA33",      -- Orange
        osd = "FFFF33",      -- Yellow
        tank = "00FFAA",     -- Teal
        error = "FF0000",    -- Red
        warning = "FFAA00",  -- Orange
        details = "AAAAAA"   -- Gray
    }
}

-- Class color constants
TWRA.VANILLA_CLASS_COLORS = {
    ["WARRIOR"] = {r=0.78, g=0.61, b=0.43},
    ["PRIEST"] = {r=1.0, g=1.0, b=1.0},
    ["DRUID"] = {r=1.0, g=0.49, b=0.04},
    ["ROGUE"] = {r=1.0, g=0.96, b=0.41},
    ["MAGE"] = {r=0.41, g=0.8, b=0.94},
    ["HUNTER"] = {r=0.67, g=0.83, b=0.45},
    ["WARLOCK"] = {r=0.58, g=0.51, b=0.79},
    ["PALADIN"] = {r=0.96, g=0.55, b=0.73},
    ["SHAMAN"] = {r=0.0, g=0.44, b=0.87}
}

-- Class group mapping
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

-- Class icon coordinates for the class selection texture
TWRA.CLASS_COORDS = {
    ["WARRIOR"] = {0, 0.25, 0, 0.25},
    ["PALADIN"] = {0, 0.25, 0.5, 0.75},
    ["HUNTER"] = {0, 0.25, 0.25, 0.5},
    ["ROGUE"] = {0.5, 0.75, 0, 0.25},
    ["PRIEST"] = {0.5, 0.75, 0.25, 0.5},
    ["SHAMAN"] = {0.25, 0.5, 0.25, 0.5},
    ["MAGE"] = {0.25, 0.5, 0, 0.25},
    ["WARLOCK"] = {0.75, 1, 0.25, 0.5},
    ["DRUID"] = {0.75, 1, 0, 0.25}
}

-- Target marker icon data
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

-- Colored text for raid markers in announcements
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

-- Role icons for assignments
TWRA.ROLE_ICONS = {
    -- Basic role icons using standard game textures
    ["Tank"] = "Interface\\Icons\\Ability_Warrior_DefensiveStance",     -- Tank
    ["Heal"] = "Interface\\Icons\\Spell_Holy_HolyBolt",                 -- Heal
    ["DPS"] = "Interface\\Icons\\INV_Sword_04",                         -- DPS
    ["CC"] = "Interface\\Icons\\Spell_Frost_ChainsOfIce",               -- CC
    ["Pull"] = "Interface\\Icons\\Ability_Hunter_SniperShot",           -- Pull
    ["Ress"] = "Interface\\Icons\\Spell_Holy_Resurrection",             -- Ress
    ["Assist"] = "Interface\\Icons\\Ability_Warrior_BattleShout",       -- Assist
    ["Scout"] = "Interface\\Icons\\Ability_Hunter_EagleEye",            -- Scout
    ["Lead"] = "Interface\\Icons\\Ability_Warrior_RallyingCry",         -- Lead
    
    -- Specialized role icons
    ["MC"] = "Interface\\Icons\\Spell_Shadow_ShadowWordDominate",
    ["Kick"] = "Interface\\Icons\\Ability_Kick",
    ["Decurse"] = "Interface\\Icons\\Spell_Holy_RemoveCurse",
    ["Taunt"] = "Interface\\Icons\\Spell_Nature_Reincarnation",
    ["MD"] = "Interface\\Icons\\Ability_Hunter_Misdirection",
    ["Sap"] = "Interface\\Icons\\Ability_Sap",
    ["Purge"] = "Interface\\Icons\\Spell_Holy_Dispel",
    ["Shackle"] = "Interface\\Icons\\Spell_Nature_Slow",
    ["Banish"] = "Interface\\Icons\\Spell_Shadow_Cripple",
    ["Kite"] = "Interface\\Icons\\Ability_Rogue_Sprint",
    ["Bomb"] = "Interface\\Icons\\spell_fire_selfdestruct",
    ["Interrupt"] = "Interface\\Icons\\Ability_Kick",
    ["Misc"] = "Interface\\Icons\\INV_Misc_Gear_01"
}

-- Default options
TWRA.DEFAULT_OPTIONS = {
    -- UI options
    hideFrameByDefault = true,  -- Hide main frame on login
    lockFramePosition = false,  -- Allow frame movement
    frameScale = 1.0,          -- Default frame scale
    frameWidth = 800,          -- Default frame width
    frameHeight = 300,         -- Default frame height
    
    -- OSD options
    enableOSD = true,          -- Enable on-screen display
    osdScale = 1.0,            -- Default OSD scale
    osdPoint = "CENTER",       -- Default OSD position
    osdXOffset = 0,            -- Default X offset
    osdYOffset = 100,          -- Default Y offset
    osdDuration = 2,           -- Default duration in seconds
    osdLocked = false,         -- Allow OSD movement
    
    -- Sync options
    enableLiveSync = true,     -- Enable section sync with group
    tankSync = true,           -- Enable tank syncing with oRA2
    customChannel = "",        -- Default custom channel name
    announceChannel = "GROUP"  -- Default announcement channel
}

-- Export version information
TWRA.VERSION = {
    MAJOR = 0,
    MINOR = 1,
    PATCH = 0,
    STRING = "0.1.0",
    BUILD_DATE = "2023-10-09"
}

-- Export base64 character table for encoding/decoding
TWRA.BASE64_TABLE = {
    ['A']=0,['B']=1,['C']=2,['D']=3,['E']=4,['F']=5,['G']=6,['H']=7,['I']=8,['J']=9,
    ['K']=10,['L']=11,['M']=12,['N']=13,['O']=14,['P']=15,['Q']=16,['R']=17,['S']=18,
    ['T']=19,['U']=20,['V']=21,['W']=22,['X']=23,['Y']=24,['Z']=25,['a']=26,['b']=27,
    ['c']=28,['d']=29,['e']=30,['f']=31,['g']=32,['h']=33,['i']=34,['j']=35,['k']=36,
    ['l']=37,['m']=38,['n']=39,['o']=40,['p']=41,['q']=42,['r']=43,['s']=44,['t']=45,
    ['u']=46,['v']=47,['w']=48,['x']=49,['y']=50,['z']=51,['0']=52,['1']=53,['2']=54,
    ['3']=55,['4']=56,['5']=57,['6']=58,['7']=59,['8']=60,['9']=61,['+'] = 62,['/'] = 63,
    ['='] = -1
}
