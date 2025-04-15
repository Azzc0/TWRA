TWRA = TWRA or {}

-- Initialize OSD settings
TWRA.OSD = TWRA.OSD or {
    isVisible = false,
    autoHideTimer = nil,
    duration = 2,
    scale = 1.0,
    locked = false,
    enabled = true,
    showOnNavigation = true,
    point = "CENTER",
    xOffset = 0,
    yOffset = 100,
    manuallyToggled = false,
    hoveredFromMinimap = false,
    -- UI element pools
    pools = {
        rows = {},            -- Row frames
        roleIcons = {},       -- Role icon textures
        targetIcons = {},     -- Target icon textures
        classIcons = {},      -- Class icon textures
        textSegments = {},    -- Text font strings
        warnings = {},        -- Warning frames
        notes = {}            -- Note frames
    },
    mode = "assignments"      -- assignments or progress
}
