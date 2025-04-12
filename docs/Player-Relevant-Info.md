# Player Relevant Information

This document describes how TWRA identifies and processes player-relevant information within raid assignments.

## Data Structure

During import, TWRA generates additional metadata for each section to help identify assignments relevant to the player and their group. This makes highlighting and OSD display more efficient.

### Section Group Rows

A simple array listing row indices that contain any group reference:

```lua
section["Section Group Rows"] = {2, 3, 4, 5, 6, 7}  -- All rows containing ANY group reference
section["Tanks"] = {3, 5, 7},                       -- Column indices from the header that contain tank roles (matched by "Tank", "OffTank", "Off-Tank", "Main Tank", etc.)
```

This data is used for quick lookups when determining which rows might be relevant based on the player's group membership.

### Section Player Info

A structured table containing various aspects of player relevance:

```lua
section["Section Player Info"] = {
    ["Relevant Rows"] = {2, 5, 8},       -- Rows directly relevant to the player by name
    ["Relevant Group Rows"] = {3, 6},     -- Rows relevant to player based on their group
    ["OSD Assignments"] = {
        [1] = {                           -- Index matches Relevant Rows index
            "Heal",                       -- Role (column header where player was found)
            "Skull",                      -- Icon from column 1 in the row
            "Anub'rekhan",                -- Target from column 2 in the row
            "Players"                     -- Array of all tank players. Get players names from ["Tanks"]
        },
        -- Additional assignment entries
    },
    ["OSD Assignments"] = {
        [1] = {                           -- Index matches Relevant Rows index
            "Heal",                       -- Role (column header where group was found)
            "Skull",                      -- Icon from column 1 in the row
            "Anub'rekhan",                -- Target from column 2 in the row
            "Players"                     -- Array of all tank players. Get players names from ["Tanks"]
        },
        -- Additional assignment entries
    }
}
```

## Assignment Types

### OSD Assignments vs OSD Group Assignments

These two structures serve different purposes and have different stability characteristics:

1. **OSD Assignments**:
   - Based on individual player names or class matching
   - More static and stable throughout a raid
   - Generated when a player's name or class is explicitly found in an assignment row
   - Used for displaying personal assignments that rarely change during an encounter

2. **OSD Group Assignments**:
   - Based on group membership (Group 1, Group 2, etc.)
   - Dynamic and may change if raid group composition changes
   - Generated when a player's current group number is found in an assignment row
   - Used for displaying assignments that apply to an entire group
   - More likely to be affected by raid roster changes or group reorganization

## Tank Identification

The "Tanks" array contains indices that correspond to columns in the header row which contain tank roles. The addon identifies these by matching column header text against known tank role keywords:

- "Tank"
- "OffTank"
- "Off-Tank"
- "Main Tank"
- etc.

This information is used for:
1. Quick identification of which columns represent tank assignments
2. Supporting features like automatic tank assignment to oRA2
3. Properly highlighting tank assignments in the OSD

For example, if the header row contains ["Icon", "Target", "Tank", "Heal", "Off-Tank"], the "Tanks" array would contain [3, 5] (since indices 3 and 5 represent "Tank" and "Off-Tank" columns).

## Processing Flow

During import and before saving assignments, the following data processing occurs:

1. **Section Processing**: Each section is analyzed to:
   - Ensure complete rows via `EnsureCompleteRows()`
   - Generate group row indices
   - Identify player-specific relevant rows
   - Find tank role column indices by header matching
   - Create pre-formatted OSD assignment data

2. **Relevant Row Identification**:
   - **Direct Relevance**: Rows containing the player's name or class (EG. Warriors for a warrior) in any role column
   - **Group Relevance**: Rows containing a reference to the player's current group number

3. **OSD Assignment Formatting**:
   - Pre-formatted entries are created that can be directly used by the OSD without additional processing
   - Both direct assignments and group assignments are formatted similarly for consistent display

## Usage Example

This pre-processed data is used in several ways:

1. **Main Frame Highlighting**: 
   - `Relevant Rows` indices are used to highlight rows in the main assignments frame

2. **OSD Display**: 
   - `OSD Assignments` and `OSD Group Assignments` are used to generate concise, role-specific information
   - This eliminates the need for complex lookups during OSD display, improving performance

3. **Navigation Relevance**:
   - Helps determine whether a section contains assignments relevant to the player
   - Enables potential features like "Jump to my next assignment"

4. **Tank Assignments**:
   - `Tanks` indices identify which columns contain tank assignments
   - Used for features like oRA2 integration and tank-specific highlighting

## Implementation Details

The additional metadata is generated during:
1. Initial import from string
2. Sync operations receiving assignment data
3. Manual saves of assignment data

The processing functions ensure data integrity through:
- Safety checks for nil values and empty arrays
- Handling of special rows like Notes and Warnings
- Recalculation whenever player group changes in raid