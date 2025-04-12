# TWRA GitHub Copilot Guide

This document serves as a comprehensive reference for GitHub Copilot when working on the TWRA (Turtle WoW Raid Assignments) addon. Use this at the beginning of each session to provide context about the project.

## Project Overview

TWRA is a raid assignment addon for Turtle WoW (WoW 1.12) that allows raid leaders to:
- Import/export raid assignments from spreadsheets
- Display assignments in-game
- Navigate between different encounter sections
- Sync assignments between raid members
- Update tank assignments to oRA2
- Auto-navigate sections based on targeted mobs (with SuperWoW)

## Technical Constraints

### WoW 1.12 and Lua 5.0 Limitations
- **No modulo operator (`%`)**: Replace with `math.floor` approach
  ```lua
  -- Instead of: x = y % z
  x = y - (math.floor(y / z) * z)
  ```
- **No `#` for table length**: Use `table.getn(tbl)` instead
- **Avoid `_G` references**: Maintain compatibility with older Lua

### SuperWoW Integration
- Features accessed through `SUPERWOW_VERSION` global variable check
- GUID features available through extended `UnitExists` functionality
- Designed to work with or without SuperWoW being present

## Code Structure

### Core Modules
- `core/Constants.lua`: Default data and configuration constants
- `core/Base64.lua`: Encoding/decoding for spreadsheet import/export
- `core/Debug.lua`: Debug system with categories and filtering
- `core/Core.lua`: Initialization and lifecycle management
- `core/DataUtility.lua`: Handles data format conversion and processing

### Feature Modules
- `features/AutoTanks.lua`: oRA2 integration for tank assignments
- `features/AutoNavigate.lua`: Auto-navigation using SuperWoW's GUID

### UI Modules
- `ui/Frame.lua`: Main frame creation and management
- `ui/OSD.lua`: On-screen display functionality
- `ui/Options.lua`: Options panel implementation
- `ui/UIUtils.lua`: Shared UI utilities and components
- `ui/OSDContent.lua`: Content generation for OSD display

### Sync Modules
- `sync/Sync.lua`: Synchronization controller
- `sync/SyncHandlers.lua`: Message handlers for sync operations
- `sync/ChunkManager.lua`: Handles large data chunking for sync

## Debugging Guidelines

Use the debug system instead of direct chat messages:
```lua
TWRA:Debug(category, message, forceOutput, isDetail)
```

Available debug categories:
- `"error"`: Error messages
- `"general"`: General addon information
- `"ui"`: User interface updates
- `"nav"`: Navigation events
- `"osd"`: On-screen display messages
- `"sync"`: Synchronization processes
- `"data"`: Data handling operations

## Key Functions

The following functions are critical to the addon's operation:

### Navigation
- `TWRA:NavigateToSection(index, source)`: Navigate to a specific section
- `TWRA:NavigateHandler(delta)`: Navigate by relative offset
- `TWRA:DisplayCurrentSection()`: Update UI to show current section

### Data Management
- `TWRA:LoadSavedAssignments()`: Load assignments from saved variables
- `TWRA:SaveAssignments(data, sourceString, timestamp, noAnnounce)`: Save assignments
- `TWRA:CleanAssignmentData(data, isTableFormat)`: Clean up data before saving
- `TWRA:ImportString(importString, isSync, syncTimestamp)`: Import a Base64 string

### UI Management
- `TWRA:CreateMainFrame()`: Create the main addon window
- `TWRA:ToggleMainFrame()`: Show/hide the main window
- `TWRA:RefreshAssignmentTable()`: Update the displayed assignments
- `TWRA:FilterAndDisplayHandler(sectionName)`: Filter and display a specific section

### OSD Management
- `TWRA:InitOSD()`: Initialize the on-screen display
- `TWRA:ShowOSD()`: Show the OSD with current section
- `TWRA:UpdateOSDContent()`: Update OSD with current information
- `TWRA:ShouldShowOSD()`: Determine if OSD should be shown

### Synchronization
- `TWRA:SendAddonMessage(message, target)`: Send addon sync message
- `TWRA:BroadcastSectionChange(index, timestamp)`: Broadcast section change to group
- `TWRA:HandleAddonMessage(message, channel, sender)`: Process incoming addon messages

## Data Structure

The addon supports two data formats:

### Legacy Format
Flat array where each row has:
- Column 1: Section name
- Column 2: Icon  
- Column 3: Target
- Column 4+: Roles (Tank, Heal, DPS, etc.)

### New Format
Structured format with better organization:
```lua
{
  ["Section Name"] = "Boss Name",
  ["Section Header"] = {"Icon", "Target", "Tank", "Heal", "DPS"},
  ["Section Rows"] = {
    {icon, target, tank, heal, dps}, -- Normal row
    {"Warning", "Important message"}, -- Warning row
    {"Note", "Helpful tip"}, -- Note row
    {"GUID", "target guid"} -- GUID row for AutoNavigate
  },
  ["Section Player Info"] = {
    ["Relevant Rows"] = {2, 4} -- Indices of rows relevant to current player
  }
}
```

## Known Issues

See the complete list in [Bugs.md](/home/azzco/tmp/TWRA/docs/Bugs.md), but key issues include:
- Item link handling can cause infinite loops with pre-formatted links
- Column count doesn't update properly when navigating between sections with different numbers of columns
- Tank assignments clearing functionality needs improvement
- Section names must be unique (this needs documentation)

## Best Practices

1. **Function Documentation**: Update `Functionmap.md` when adding or modifying functions
2. **Debug Messages**: Use appropriate categories for debug messages
3. **Boolean Values**: Convert 0/1 to true/false in saved variables
4. **Error Handling**: Add proper error checking for all user inputs
5. **Consolidation**: Follow the resolved duplications guide in `Functionmap.md`

## Referencing Files

When working with GitHub Copilot Chat, you can:
1. Use `#codebase` at the beginning of a session to provide overall project context
2. Reference specific files as needed for focused work
3. Always provide this guide file at the start of a session for comprehensive context
