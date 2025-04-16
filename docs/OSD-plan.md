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

## Revised Implementation Approach: Smallest Possible Steps

To ensure stability and proper functionality, we'll break down the implementation into much smaller steps than originally planned, focusing on visual appearance first before adding complex logic.

### Phase 0: Visual Prototyping and Testing

1. **Create Static Visual Prototype** (No actual data connection)
   - Create basic OSD frame with proper styling and appearance
   - Implement static header showing a fixed title
   - Add 2-3 hardcoded sample rows with different formatting
   - Add sample warning with proper styling
   - Test positioning, scaling, and backdrop appearance
   - Make frame movable and test position saving
   - Validate visual appearance matches expectations
   - The frame needs to house three containers
        - Header
        - Content
        - Footer

2. **Basic Controls Testing**
   - [ ] Add show/hide toggle functionality
   - [ ] Test manual movement and position saving
   - [ ] Implement lock/unlock toggle with visual feedback
   - [ ] Test basic scale adjustment
   - [ ] Verify all UI controls behave as expected visually

This phase is crucial to establish the correct visual appearance without adding complexities of data integration or events.

### Phase 1: Core Frame Structure with Minimal Logic

1. **Basic Frame Setup**
   - [ ] Create the main OSD frame with proper styling
   - Implement show/hide functions with duration timer
   - Make frame movable/positionable when unlocked
   - Add settings persistance for position and appearance

2. **UI Element Pool Foundation**
   - Create basic element pools structure
   - Implement helper functions for pooled elements
   - Test element creation, release, and reuse

This phase focuses on having a working frame that can be shown/hidden and positioned correctly, with no connection to real data yet.

### Phase 2: Simple Content Display

1. **Minimal Content Display**
   - Add header text display for section title
   - Create basic row layout with simple text
   - Implement manual content update function
   - Test content updates through console commands

2. **Element Styling**
   - Implement text color handling
   - Add background and border styling
   - Basic icon display without complex logic

Focus on getting elements to display correctly with manual testing before connecting to real data sources.

### Phase 3: Assignment Display Integration

1. **Real Data Connection**
   - Process section data for display
   - Generate appropriate row formatting 
   - Connect to current section data
   - Test with various assignment types

2. **Dynamic Content Handling**
   - Add dynamic sizing based on content
   - Implement warning display with styling
   - Handle empty or missing data cases

This phase connects the visual elements to actual data but still without automatic events.

### Phase 4: Progress Display Implementation

1. **Progress UI Elements**
   - Create progress bar and text elements
   - Implement visual mode switching
   - Test progress display with test values

2. **Progress Display Styling**
   - Style progress bar appearance
   - Add placeholder text elements
   - Ensure visual consistency with assignment display

This phase focuses solely on the progress display visuals before connecting to actual sync events.

### Phase 5: Event System Integration

1. **Basic Event Hooks**
   - Connect to navigation events
   - Implement auto-show/hide based on navigation
   - Add basic timer for auto-hiding

2. **Advanced Event Integration**
   - Connect to sync progress events
   - Add minimap button integration
   - Implement visibility rules and conditions

This final phase connects the working visual elements to the event system.

## Testing Strategy

Each phase will include specific testing strategies:

1. **Visual Testing**
   - Use screenshots to compare intended vs. actual appearance
   - Test at different UI scales and resolutions
   - Verify all elements display correctly

2. **Functional Testing**
   - Create specific test commands to trigger each feature
   - Verify options work correctly
   - Test edge cases for each phase

3. **Integration Testing**
   - Ensure new OSD doesn't interfere with existing functionality
   - Validate event handling works correctly
   - Check performance impact

## Technical Notes

1. **Testing Commands:**
   - Create slash commands for testing each phase
   - For example: `/run TWRA:TestOSDVisual()` to show visual prototype
   - Use specific commands to test individual features

2. **Isolated Development:**
   - Test each component in isolation before integration
   - Create separate test functions for each feature
   - Document test procedures for each phase

3. **Constant Visual Validation:**
   - Check visual appearance frequently during development
   - Ensure all elements follow WoW UI styling
   - Pay special attention to text readability

4. **Integration Planning:**
   - Plan each integration step carefully
   - Create verification steps for each integration
   - Document fallback options if issues occur



