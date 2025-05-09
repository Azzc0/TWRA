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

-- Create OSD namespace with default settings
TWRA.OSD = TWRA.OSD or {
    isVisible = false,      -- Current visibility state
    isPermanent = false,    -- Whether OSD is in permanent display mode
    lastSectionIndex = nil, -- Last section index to detect same-section navigation
    autoHideTimer = nil,    -- Timer for auto-hiding
    duration = 3,           -- Duration in seconds before auto-hide (user configurable)
    scale = 1.0,            -- Scale factor for the OSD (user configurable)
    locked = false,         -- Whether frame position is locked (user configurable)
    enabled = true,         -- Whether OSD is enabled at all (user configurable)
    showOnNavigation = true, -- Show OSD when navigating sections (user configurable)
    point = "CENTER",       -- Frame position anchor point (saved between sessions)
    xOffset = 0,            -- X position offset (saved between sessions)
    yOffset = 100,          -- Y position offset (saved between sessions),
    displayMode = "assignments" -- Current display mode: "assignments" or "progress"
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

-- Add a constant for the class icon texture path
TWRA.TEXTURES = TWRA.TEXTURES or {
    CLASS_ICONS = "Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES",
    ROLE_ICONS = "Interface\\Icons\\", -- Base path for role icons
    TARGET_ICONS = "Interface\\TargetingFrame\\UI-RaidTargetingIcons"
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
    ["Warning"] = {"Interface\\GossipFrame\\AvailableQuestIcon", 0, 1, 0, 1},
    ["Note"] = {"Interface\\GossipFrame\\ActiveQuestIcon", 0, 1, 0, 1},
    ["GUID"] = {"Interface\\Icons\\INV_Misc_Note_01", 0, 1, 0, 1},
    ["Missing"] = {"Interface\\Buttons\\UI-GroupLoot-Pass-Up", 0, 1, 0, 1},
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

-- Role mappings for categorization (determining if a role is tank, healer, or other)
TWRA.ROLE_MAPPINGS = {
    -- Tank role patterns
    ["tank"] = "tank",
    ["tanks"] = "tank", 
    ["offtank"] = "tank",
    ["off-tank"] = "tank",
    ["off tank"] = "tank",
    ["maintank"] = "tank",
    ["main-tank"] = "tank",
    ["main tank"] = "tank",
    ["ranged tank"] = "tank",
    ["r.tank"] = "tank",
    ["t1"] = "tank",
    ["t2"] = "tank",
    ["t3"] = "tank",
    ["t4"] = "tank",
    ["tank1"] = "tank",
    ["tank2"] = "tank",
    ["tank3"] = "tank",
    ["tank4"] = "tank",
    ["mt"] = "tank",
    ["ot"] = "tank",
    
    -- Healer role patterns
    ["heal"] = "healer",
    ["heals"] = "healer",
    ["healer"] = "healer",
    ["healers"] = "healer",
    ["tank heal"] = "healer",
    ["tank healer"] = "healer",
    ["raid heal"] = "healer",
    ["raid healer"] = "healer",
    ["main heal"] = "healer",
    ["h1"] = "healer",
    ["h2"] = "healer",
    ["h3"] = "healer",
    ["h4"] = "healer",
    ["heal1"] = "healer",
    ["heal2"] = "healer",
    ["heal3"] = "healer",
    ["heal4"] = "healer",
    ["healing"] = "healer",
    ["holy"] = "healer",
    ["disc"] = "healer",
    ["resto"] = "healer",
    ["restoration"] = "healer",
    ["hps"] = "healer",
    
    -- Custom role mappings can be added here
    -- You can add any role name to map to "tank", "healer", or any other category
    -- Examples for DPS-specific roles that might be used in your raid assignments
    ["dps"] = "dps",
    ["damage"] = "dps",
    ["mdps"] = "dps",
    ["rdps"] = "dps",
    ["ranged"] = "dps",
    ["ranged dps"] = "dps",
    ["melee"] = "dps",
    ["melee dps"] = "dps",
    
    -- Examples for utility roles
    ["kite"] = "utility",
    ["kiter"] = "utility",
    ["cc"] = "utility",
    ["crowd control"] = "utility",
    ["interrupt"] = "utility",
    ["purge"] = "utility",
    ["decurse"] = "utility",
    ["dispell"] = "utility",
    
    -- Other roles default to "other" and don't need explicit mapping
}
TWRA_DECURSIVE = {
    ["dc"] = "decurse",
    ["decurse"] = "decurse",
    ["depoison"] = "depoison",
    ["poison"] = "depoison",
    ["poison cure"] = "depoison",
    ["remove poison"] = "depoison",
    ["remove curse"] = "decurse",
    ["remove disease"] = "didisease",
    ["remove magic"] = "dispell",
    ["remove magic curse"] = "dispell",
    ["remove magic disease"] = "dispell",
    ["remove magic poison"] = "dispell",
    ["cure poison"] = "depoison",
    ["abolish poison"] = "depoison",
    ["cure poison"] = "depoison",
    ["dispell"] = "dispell",
    ["dispell magic"] = "dispell",
    ["cure disease"] = "didisease",
    ["abolish disease"] = "didesease",
    ["cleanse"] = "cleanse",
}
-- Mapping of role names to icon paths (previously TWRA.ROLE_MAPPINGS)
TWRA.ROLE_ICONS_MAPPINGS = {
    ["tank"] = "Tank",
    ["offtank"] = "Tank", 
    ["off-tank"] = "Tank",
    ["ranged tank"] = "Tank",
    ["r.tank"] = "Tank",
    
    ["heal"] = "Heal",
    ["heal[1]"] = "Heal",
    ["heal[2]"] = "Heal",
    ["heal[3]"] = "Heal",
    ["heal[4]"] = "Heal",
    ["healer"] = "Heal",
    ["tank heal"] = "Heal",
    
    ["mc"] = "MC",
    ["mind control"] = "MC",

    ["cor"] = "CoR",
    ["c.o.r"] = "CoR",
    ["curse of recklessness"] = "CoR",
 
    ["kick"] = "Kick",
    ["interrupt"] = "Kick",

    ["decurse"] = "Decurse",
    ["dec"] = "Decurse",
    ["dispell"] = "Decurse",
    
    ["pull"] = "Pull",
    ["puller"] = "Pull",
    
    ["assist"] = "Assist",
    
    ["bomb"] = "Bomb",
    
    ["dps"] = "DPS",
    ["damage"] = "DPS",
    
    ["aoe"] = "AOE",

    ["resurrect"] = "Ress",
    ["ress"] = "Ress",
    ["resurrect"] = "Ress",
    
    ["cc"] = "CC",
    ["crowd control"] = "CC",
    
    
    ["sap"] = "Sap",
    
    ["purge"] = "Purge",
    
    ["shackle"] = "Shackle",
    
    ["banish"] = "Banish",
    
    ["kite"] = "Kite",
    ["kiting"] = "Kite",
    ["kiter"] = "Kite",
    
    ["tranq"] = "Tranq Shot",
    ["tranq shot"] = "Tranq Shot",
    ["t. shot"] = "Tranq Shot",
    
    ["tranquility"] = "Tranquility",
    
    ["misc"] = "Misc"
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
    ["Tranq Shot"] = "Interface\\Icons\\Spell_Nature_Drowsy",
    ["Tranquility"] = "Interface\\Icons\\Spell_Nature_Tranquility",
    ["CoR"] = "Interface\\Icons\\Spell_Shadow_UnholyStrength",
    
    ["Misc"] = "Interface\\Icons\\INV_Misc_Gear_01"
}

-- Default options
TWRA.DEFAULT_OPTIONS = {
    -- UI options
    hideFrameByDefault = true,    -- Hide main frame on login (changed to boolean)
    lockFramePosition = false,    -- Allow frame movement (changed to boolean)
    frameScale = 1.0,             -- Default frame scale
    frameWidth = 800,             -- Default frame width
    frameHeight = 300,            -- Default frame height
    
    -- OSD options
    enableOSD = true,             -- Enable on-screen display (changed to boolean)
    osdScale = 1.0,               -- Default OSD scale
    osdPoint = "CENTER",          -- Default OSD position
    osdXOffset = 0,               -- Default X offset
    osdYOffset = 100,             -- Default Y offset
    osdDuration = 2,              -- Default duration in seconds
    osdLocked = false,            -- Allow OSD movement (changed to boolean)
    
    -- Sync options
    enableLiveSync = true,        -- Enable section sync with group (changed to boolean)
    tankSync = true,              -- Enable tank syncing with oRA2 (changed to boolean)
    customChannel = "",           -- Default custom channel name
    announceChannel = "GROUP"     -- Default announcement channel
}

-- Default OSD settings
TWRA.DEFAULT_OSD_SETTINGS = {
    point = "CENTER",
    xOffset = 0,
    yOffset = 100,
    scale = 1.0,
    duration = 2,
    locked = false,       -- Changed to boolean
    enabled = true,       -- Changed to boolean
    showOnNavigation = true -- Changed to boolean
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

-- Item rarity colors for links
TWRA.ITEM_QUALITY_COLORS = {
    ["Poor"] = "9d9d9d",      -- Gray
    ["Common"] = "ffffff",    -- White
    ["Uncommon"] = "1eff00",  -- Green
    ["Rare"] = "0070dd",      -- Blue
    ["Epic"] = "a335ee",      -- Purple
    ["Legendary"] = "ff8000", -- Orange
    ["Artifact"] = "e6cc80",  -- Light gold
    ["Heirloom"] = "00ccff"   -- Light blue
}

-- Database mapping item names to their item IDs and quality
TWRA.ITEM_DATABASE = {
   
    -- Consumables
    ["Major Healing Potion"] = {id = 13446, quality = "Common"},
    ["Greater Fire Protection Potion"] = {id = 13457, quality = "Common"},
    ["Fire Protection Potion"] = {id = 6049, quality = "Common"},
    ["Greater Nature Protection Potion"] = {id = 13458, quality = "Common"},
    ["Nature Protection Potion"] = {id = 6052, quality = "Common"},
    ["Greater Shadow Protection Potion"] = {id = 13459, quality = "Common"},
    ["Shadow Protection Potion"] = {id = 6048, quality = "Common"},
    ["Greater Frost Protection Potion"] = {id = 13456, quality = "Common"},
    ["Frost Protection Potion"] = {id = 6050, quality = "Common"},
    ["Greater Arcane Protection Potion"] = {id = 13461, quality = "Common"},
    ["Greater Holy Protection Potion"] = {id = 13460, quality = "Common"},
    ["Holy Protection Potion"] = {id = 6051, quality = "Common"},
    ["Flask of the Titans"] = {id = 13510, quality = "Common"},
    ["Major Mana Potion"] = {id = 13444, quality = "Common"},
    ["Elixir of Poison Resistance"] = {id = 3386, quality = "Common"},
    ["Free Action Potion"] = {id = 5634, quality = "Common"},
    ["Limited Invulnerability Potion"] = {id = 3387, quality = "Common"},
    ["Living Action Potion"] = {id = 20008, quality = "Common"},
    ["Restorative Potion"] = {id = 9030, quality = "Common"},
    ["Elixir of the Mongoose"] = {id = 13452, quality = "Common"},
    ["Elixir of Brute Force"] = {id = 13453, quality = "Common"},
    ["Greater Stoneshield Potion"] = {id = 13455, quality = "Common"},
    ["Flask of Supreme Power"] = {id = 13512, quality = "Common"},
    ["Flask of Chromatic Resistance"] = {id = 13522, quality = "Common"},
    ["Nordanaar Herbal Tea"] = {id = 61675, quality = "Uncommon"},
    ["Onyxia Scale Cloak"] = {id = 15138, quality = "Epic"}
}
