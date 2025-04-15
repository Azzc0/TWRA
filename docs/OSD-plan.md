# TWRA On-Screen Display (OSD) Rework Plan

## Overview

This document outlines the plan for reworking the TWRA On-Screen Display (OSD) system. The OSD has two primary functions:
- Display relevant assignments from the saved variables
- Show progress during data transmission/reception, returning to assignment display when complete

## Current OSD Options

The OSD system already has several options that should be utilized in the rewrite:

```lua
TWRA.OSD = {
    isVisible = false,      -- Current visibility state
    autoHideTimer = nil,    -- Timer for auto-hiding
    duration = 2,           -- Duration in seconds before auto-hide (user configurable)
    scale = 1.0,            -- Scale factor for the OSD (user configurable)
    locked = false,         -- Whether frame position is locked (user configurable)
    enabled = true,         -- Whether OSD is enabled at all (user configurable)
    showOnNavigation = true, -- Show OSD when navigating sections (user configurable)
    point = "CENTER",       -- Frame position anchor point (saved between sessions)
    xOffset = 0,            -- X position offset (saved between sessions)
    yOffset = 100           -- Y position offset (saved between sessions)
}
```

These options are already being saved and loaded from the saved variables, so the new implementation should continue to use them.

## Data Structure

The OSD will use data from the following sources in the saved variables:

```lua
assignments.data.section["Section Metadata"].["Name"] -- Section title
assignments.data.section["Section Metadata"].["Warning"] -- Section Warnings
assignments.data.section["Section Player Info"].["OSD Assignments"] -- Player-specific OSD Rows
assignments.data.section["Section Player Info"].["OSD Group Assignments"] -- Group-based OSD rows
```

OSD row data follows this pattern:

```lua
["OSD Assignments"] = {
	[1] = {                  -- First osd row
		[1] = "Grab debuff", -- Role
		[2] = "",            -- Icon associated with target
		[3] = "",            -- Target
		[4] = "",            -- This and subsequent indices are tanks
	},
},
["OSD Group Assignments"] = {
	[1] = {                  -- First osd row
		[1] = "Grab debuff", -- Role
		[2] = "",            -- Icon associated with target
		[3] = "",            -- Target
		[4] = "",            -- This and subsequent indices are tanks
	},
},
```

### Display Format

Each row will be formatted based on role type:

1. **Tank Role:**
   - `[roleIcon] Role - [raidIcon] Target w/ [classIcon] Tank1 & [classIcon] Tank2`
2. **Healer Role:**
   - `[roleIcon] Role - [raidIcon] Target healing [classIcon] Tank1 & [classIcon] Tank2`
3. **Other Roles:**
   - `[roleIcon] Role - [raidIcon] Target tanked by [classIcon] Tank1 & [classIcon] Tank2`

### Icon Usage

- Role icons from `TWRA.ROLE_ICONS` (use `TWRA.ROLE_MAPPINGS` to determine icon, default to "misc")
- Raid icons from `TWRA.ICONS` (only display if exact match found)
- Class icons from class coordinates in `TWRA.CLASS_COORDS` using texture "Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES"
- Class colored text for player names - red for missing and grey for offline

## Primary Function - Assignment Display

The OSD will display:
- Section Title (top)
- OSD Rows (OSD Assignments & OSD Group Assignments)
- Warning footer (if any)

## Secondary Function - Progress Display

During data reception, the OSD will show:
- "Receiving data" message as header
- Progress bar with percentage text overlay
- "Receiving from X" message (if sender is known)

The same OSD frame will be used, but with different content elements showing/hidden based on mode.

## Visibility Management

The OSD will follow these visibility rules:

1. **Auto-show on Navigation:**
   - Show when navigating to a new section (if `showOnNavigation` is true)
   - Hide after `duration` seconds (configurable in options)
   - Don't show if main TWRA frame is visible (except when options panel is open)

2. **Manual Toggle Mode:**
   - If manually toggled via `ToggleOSD()`, stay visible until manually closed
   - Set `manuallyToggled` flag to override auto-hide timer
   - Clear flag when toggled off

3. **Minimap Hover:**
   - Show when hovering over minimap button
   - Hide when mouse leaves minimap button (unless manually toggled)
   - Keep track of previous state with `hoveredFromMinimap` flag

4. **Group Change Awareness:**
   - LOWER PRIORITY FEATURE
   - When group composition changes, assignments may change
   - Wait a short period after group change (let DataProcessing update)
   - Compare new assignments with stored previous assignments
   - Show OSD only if assignments have actually changed

## UI Implementation

- Maintain tooltip styling for the frame
- Implement UI element pools for efficient reuse
- Prepare for maximum 10 rows and 10 footer items
- Allow OSD to be movable when unlocked, save position between sessions

### Element Pools

We'll implement UI element pools for efficient reuse:

```lua
TWRA.OSD.pools = {
    rows = {},            -- Row frames
    roleIcons = {},       -- Role icon textures
    targetIcons = {},     -- Target icon textures
    classIcons = {},      -- Class icon textures
    textSegments = {},    -- Text font strings
    warnings = {},        -- Warning frames
    notes = {}            -- Note frames
}
```

### Warning Styling

Warnings will have specific styling:
- Light red background tint (rgba(0.3, 0.1, 0.1, 0.3))
- Warning icon (`TWRA.ICONS.Warning`) on the left
- Red-tinted text
- Each warning on separate line

## Implementation Priorities

1. **Core Frame Structure** (Phase 1)
   - Create main OSD frame
   - Implement element pools system
   - Basic show/hide functionality
   - Support for moving and positioning

2. **Assignment Display** (Phase 2)
   - Process and display assignments with proper formatting
   - Handle role-specific formatting
   - Implement warnings display
   - Add dynamic height calculation

3. **Progress Display** (Phase 3)
   - Create progress bar element
   - Implement status text display
   - Connect to sync system

4. **Enhanced Visibility Controls** (Phase 4)
   - Implement OnUpdate for timer handling
   - Add minimap button integration
   - Connect to navigation events

5. **Group Change Awareness** (Phase 5 - Lower Priority)
   - Create assignment storage/comparison system
   - Connect to group change events
   - Add delayed check and comparison logic

## Implementation Approach

### Phase 1: Core Frame Structure

1. Create the base OSD frame with proper styling
2. Implement pooled element system for UI components
3. Add show/hide/toggle functions with duration timer
4. Make frame movable/positionable when unlocked

### Phase 2: Assignment Display

1. Add content processing from assignments data
2. Generate appropriate formatting for each role type
3. Create warning display with styling
4. Implement dynamic sizing based on content

### Phase 3: Progress Display

1. Create progress bar and text elements
2. Add handlers for sync progress updates
3. Implement mode switching between assignments/progress
4. Connect to data synchronization system

### Phase 4: Enhanced Visibility

1. Add OnUpdate handler for auto-hide timer
2. Implement minimap button hover functionality
3. Connect to navigation events for auto-show
4. Handle manual toggle state persistence

### Phase 5: Group Change Awareness (Lower Priority)

1. Create system to store current assignments
2. Add delayed check after group composition changes
3. Compare assignments to determine if display is needed
4. Show OSD only when relevant assignments change

## Technical Notes

1. **Element Reuse:**
   - Create helper functions for getting pooled elements
   - Reset all pools when changing display mode
   - Only create new elements when necessary

2. **OnUpdate Handler:**
   - Use for smooth auto-hide timer countdown
   - Reset timer when new content is displayed
   - Skip timer checks when manually toggled

3. **Group Change Detection:**
   - Don't track specific group numbers - not necessary
   - Let DataProcessing handle updating the assignments first
   - Focus on comparing assignment content rather than group membership
   - Keep implementation simple - this is a nice-to-have feature

4. **Existing Options Integration:**
   - Use the existing OSD options already being saved/loaded
   - Respect user configuration for enabled/disabled state
   - Honor scale, position, and duration settings

5. **Data Source:**
   - DataProcessing module already handles populating OSD assignments
   - No need to reimplement this logic, just consume the data



