TWRA = TWRA or {}


-- Version information
TWRA.VERSION = {
    MAJOR = 0,
    MINOR = 3,
    PATCH = 0,
    STRING = "0.3.0"
}

-- Early dependency checks
local SUPERWOW_AVAILABLE = (SUPERWOW_VERSION ~= nil)
-- local ORA2_AVAILABLE = (oRA and oRA.maintanktable ~= nil) --Need to find the proper syntax to check availbility. This is wrong.

-- Feature flags now depend on detected dependencies
TWRA.FEATURES = {
    AUTO_NAVIGATE = SUPERWOW_AVAILABLE,  -- Automatically disable if SuperWoW not found 
    TANK_SYNC = true,          -- Automatically disable if oRA2 not found
    ANNOUNCEMENT = true                  -- No dependencies for this feature
}

-- Add debug info about feature availability
if TWRA.FEATURES.AUTO_NAVIGATE ~= SUPERWOW_AVAILABLE then
    DEFAULT_CHAT_FRAME:AddMessage("TWRA: SuperWoW features " .. 
        (SUPERWOW_AVAILABLE and "available" or "unavailable") .. 
        " - AutoNavigate " .. (SUPERWOW_AVAILABLE and "enabled" or "disabled"))
end

-- DEFAULT_CHAT_FRAME:AddMessage("TWRA: oRA2 " .. 
--     (ORA2_AVAILABLE and "detected" or "not detected") .. 
--     " - Tank sync " .. (ORA2_AVAILABLE and "enabled" or "disabled"))

-- Timing constants (in seconds)
TWRA.TIMING = {
    OSD_DISPLAY = 3.0,           -- How long OSD messages display
    THROTTLE = 0.3,              -- Message throttle delay
    SYNC_TIMEOUT = 10,           -- Sync request timeout
    SCAN_FREQUENCY = 1.0,        -- AutoNavigate scan frequency
    FADE_TIME = 0.5              -- UI fade animation time
}

-- Default settings
TWRA.DEFAULTS = {
    FRAME_SCALE = 1.0,           -- Default UI scale
    FRAME_WIDTH = 600,           -- Default frame width
    FRAME_HEIGHT = 400,          -- Default frame height
    MAX_ROWS = 20,               -- Maximum rows to display
    ANNOUNCE_CHANNEL = "RAID",   -- Default announce channel
    AUTO_SYNC = true,            -- Auto-sync on join
    NAVIGATION_STYLE = "dropdown" -- Navigation style (dropdown/tabs)
}

-- Command prefixes
TWRA.COMMANDS = {
    PREFIX = "TWRA",            -- Addon message prefix
    SECTIONS = {                -- Section commands
        CHANGE = "SECTION",     -- Section change notification
        LIST = "SECTIONS"       -- List available sections
    },
    DATA = {                    -- Data commands
        REQUEST = "REQ",        -- Request data
        SEND = "DATA",          -- Send data chunk
        COMPLETE = "COMPLETE"   -- Data transfer complete
    },
    MISC = {                    -- Miscellaneous commands
        VERSION = "VERSION",    -- Version check
        PING = "PING",          -- Ping
        PONG = "PONG",          -- Pong response
        TANKS = "TANKS"         -- Tank assignments
    },
    CHUNKS = {
        REQUEST = "REQ",
        RESPONSE = "DATA",
        COMPLETE = "COMPLETE",
        CANCEL = "CANCEL"
    }
}

-- State constants
TWRA.STATES = {
    VIEW = {
        MAIN = "main",           -- Main view 
        OPTIONS = "options",      -- Options view
        IMPORT = "import"         -- Import view
    },
    SYNC = {
        IDLE = 1,                 -- Not syncing
        SENDING = 2,              -- Sending data
        RECEIVING = 3,            -- Receiving data
        COMPLETE = 4,             -- Sync complete
        FAILED = 5                -- Sync failed
    },
    TRANSFER = {                  -- Chunk transfer states
        INIT = 1,                 -- Transfer initialized
        IN_PROGRESS = 2,          -- Transfer in progress
        COMPLETE = 3,             -- Transfer complete
        ERROR = 4,                -- Error during transfer
        TIMEOUT = 5               -- Transfer timed out
    },
    DATA = {                      -- Data states
        EMPTY = 1,                -- No data available
        LOADED = 2,               -- Data loaded
        PROCESSING = 3,           -- Data being processed
        READY = 4,                -- Data processed and ready
        ERROR = 5                 -- Error processing data
    }
}

-- Sync constants
TWRA.SYNC = {
    PREFIX = "TWRA",
    COMMANDS = {
        VERSION = "VERSION",      -- For version checking
        SECTION = "SECTION",      -- For live section updates
        DATA_REQUEST = "DREQ",    -- Request full data
        DATA_RESPONSE = "DRES",   -- Send full data
        ANNOUNCE = "ANC"          -- Announce new import
    },
    THROTTLE = {
        REQUEST_TIMEOUT = 5,      -- Seconds to wait before requesting again
        RESPONSE_DELAY = 1.0,     -- Maximum random delay for responses
    },
    MESSAGING = {
        MAX_LENGTH = 200,         -- Maximum addon message length
        RETRY_ATTEMPTS = 3,       -- Number of retry attempts for failed messages
        RETRY_DELAY = 2.0         -- Seconds between retry attempts
    },
    BATCH = {
        DELAY = 0.2,              -- Delay between batch messages
        MAX_BATCH_SIZE = 5        -- Maximum number of messages in a batch
    },
    STATUS_MESSAGES = {
        SYNC_SUCCESS = "Successfully synchronized",
        SYNC_FAILED = "Synchronization failed",
        NEWER_VERSION = "Newer data available",
        SAME_VERSION = "Data is up to date",
        OLDER_VERSION = "Your data is newer"
    }
}

-- Data Processing constants
TWRA.DATA_PROCESSING = {
    FORMAT_VERSION = 2,           -- Current data format version
    SUPPORTED_VERSIONS = {1, 2},  -- List of supported data versions
    SECTION_INDEX_DEFAULT = 1,    -- Default section index
    TIMESTAMP_FORMAT = "%Y%m%d%H%M%S" -- Format for timestamp string
}

-- System constants
TWRA.SYSTEM = {
    MAX_MESSAGE_SIZE = 200,       -- Maximum addon message size (bytes)
    MAX_SECTIONS = 20,            -- Maximum number of sections
    MAX_ASSIGNMENTS = 100,        -- Maximum number of assignments
    DEBUG = false                 -- Global debug flag
}

-- File loading constants - add to SYSTEM section
TWRA.SYSTEM.FILE_LOAD_ORDER = {
    "constants",    -- Core constants
    "debug",        -- Debug functionality
    "utils",        -- Utility functions
    "base64",       -- Base64 encoding/decoding
    "icons",        -- Icon definitions
    "core",         -- Core functionality
    "sync",         -- Sync system
    "features",     -- Feature modules
    "ui",           -- UI components
    "bindings",     -- Key bindings
    "example"       -- Example data
}

-- UI layout constants
TWRA.UI_LAYOUT = {
    FRAME = {
        DEFAULT_WIDTH = 800,
        DEFAULT_HEIGHT = 300,
        PADDING = 20,
        HEADER_HEIGHT = 40,
        ROW_HEIGHT = 20,
        FOOTER_PADDING = 25
    },
    BUTTONS = {
        STANDARD_HEIGHT = 22,
        NAV_WIDTH = 24,
        OPTIONS_WIDTH = 60,
        ANNOUNCE_WIDTH = 80,
        TANKS_WIDTH = 100,
        PADDING = 10
    },
    OSD = {
        DEFAULT_WIDTH = 500,
        DEFAULT_HEIGHT = 100,
        ICON_SIZE = 22,
        LINE_HEIGHT = 18,
        SHOW_DURATION = 2.0,
        DEFAULT_POSITION = {
            POINT = "CENTER",
            X_OFFSET = 0,
            Y_OFFSET = 100
        },
        DEFAULT_SCALE = 1.0
    },
    ICONS = {
        STANDARD_SIZE = 16,
        ROLE_SIZE = 22,
        TARGET_SIZE = 16
    },
    COLORS = {
        NOTE_BG = {0.1, 0.1, 0.3, 0.15},
        WARNING_BG = {0.3, 0.1, 0.1, 0.15},
        NOTE_TEXT = {0.8, 0.8, 1},
        WARNING_TEXT = {1, 0.7, 0.7},
        OSD_TITLE = {1, 0.82, 0},
        PROGRESS_BAR = {0.0, 0.44, 0.87, 0.8},
        PROGRESS_BG = {0.3, 0.3, 0.3, 0.8}
    },
    ANIMATIONS = {
        FADE_DURATION = 0.5,
        FLASH_DURATION = 0.2
    }
}

-- Announcement settings
TWRA.ANNOUNCE = {
    MAX_MESSAGE_LENGTH = 240,
    SPLIT_THRESHOLD = 200,
    THROTTLE_DELAY = 0.5,
    DEFAULT_CHANNEL = "GROUP",
    SPECIAL_PREFIXES = {
        WARNING = "Warning: ",
        NOTE = "Note: "
    }
}

-- AutoNavigate settings
TWRA.AUTO_NAVIGATE = {
    DEFAULT_ENABLED = false,
    MIN_SCAN_FREQ = 1,
    DEFAULT_SCAN_FREQ = 3,
    MAX_SCAN_FREQ = 10
}

-- Default options
TWRA.DEFAULT_OPTIONS = {
    LIVE_SYNC = false,
    TANK_SYNC = true,
    AUTO_NAVIGATE = false,
    SCAN_FREQUENCY = 3,
    ANNOUNCE_CHANNEL = "GROUP",
    CUSTOM_CHANNEL = "",
    OSD_DURATION = 2.0,
    OSD_SCALE = 1.0,
    OSD_LOCKED = false
}

-- Default SavedVariables structure
TWRA.DEFAULT_SAVED_VARS = {
    assignments = {
        data = nil,          -- Decoded assignment data
        source = nil,        -- Original Base64 string
        timestamp = nil,     -- When the data was last updated
        version = 2,         -- Data structure version
        currentSection = 1   -- Currently selected section index
    },
    options = {
        liveSync = false,            -- Auto-sync section navigation
        tankSync = true,             -- Auto-update tanks on navigation
        autoNavigate = false,        -- Enable auto-navigation feature
        scanFrequency = 3,           -- Scan frequency for auto-navigation
        announceChannel = "GROUP",   -- Default announcement channel
        customChannel = "",          -- Custom channel name if used
        osdDuration = 2.0,           -- How long OSD messages display
        osdScale = 1.0,              -- Scale of OSD messages
        osdLocked = false            -- Whether OSD position is locked
    },
    debug = {
        enabled = false,             -- Master debug switch
        categories = {               -- Category-specific switches
            sync = false,
            ui = false,
            data = false,
            nav = false,
            general = false
        }
    }
}

-- ORA2 integration constants
TWRA.ORA2 = {
    MAX_TANKS = 10,              -- Maximum number of tanks ORA2 supports
    ADDON_PREFIX = "CTRA",       -- ORA2 addon message prefix
    COMMANDS = {
        CLEAR = "MT CLEAR",      -- Command to clear all tanks
        SET = "SET"              -- Command to set tank (followed by index and name)
    }
}

-- Chunk Manager constants
TWRA.CHUNK_MANAGER = {
    MAX_CHUNK_SIZE = 200,      -- Maximum bytes per chunk (conservative for WoW 1.12)
    CHUNK_DELAY = 0.3,         -- Seconds between chunk transmissions
    TIMEOUT = 30,              -- Seconds to wait before considering a transfer failed
    PROGRESS_COLORS = {
        LOW = {1.0, 0.3, 0.3, 0.8},    -- Red (<25%)
        MEDIUM = {1.0, 0.8, 0.0, 0.8},  -- Yellow (25-75%)
        HIGH = {0.0, 0.8, 0.3, 0.8}     -- Green (>75%)
    },
    PROGRESS_FRAME = {
        WIDTH = 300,
        HEIGHT = 60,
        POSITION = {
            POINT = "TOP", 
            X_OFFSET = 0, 
            Y_OFFSET = -100
        },
        BAR_HEIGHT = 15,
        BAR_PADDING = 15
    }
}

-- Add this new section

-- Message format constants
TWRA.MESSAGE_FORMATS = {
    VERSION = "%s:%d:%s",                -- VERSION:timestamp:playerName
    SECTION = "%s:%d:%s:%d",             -- SECTION:timestamp:sectionName:sectionIndex
    DATA_REQUEST = "%s:%d",               -- DATA_REQUEST:timestamp
    DATA_RESPONSE = "%s:%d:%s",           -- DATA_RESPONSE:timestamp:data
    DATA_CHUNK = "%s:%d:%d:%d:%s",        -- DATA_RESPONSE:timestamp:chunkNum:totalChunks:chunkData
    ANNOUNCE = "%s:%d:%s",                -- ANNOUNCE:timestamp:data
    TANK = "%s:%d:%s",                    -- TANK:index:name
    TANK_CLEAR = "%s"                     -- TANK_CLEAR
}

-- TWRA:Debug("general", "Constants module loaded")