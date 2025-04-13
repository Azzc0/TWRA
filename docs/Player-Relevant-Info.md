# Player Relevant Information

This document describes how TWRA identifies and processes player-relevant information within raid assignments.

## Data Structure

During import, TWRA generates additional metadata for each section to help identify assignments relevant to the player and their group. This makes highlighting and OSD display more efficient.

### Section Group Rows

A simple array listing row indices that contain any group reference:

```lua
section["Group Rows"] = {2, 3, 4, 5, 6, 7}  -- All rows containing ANY group reference
section["Tanks"] = {3, 5, 7},              -- Column indices from the header that contain tank roles (matched by "Tank", "OffTank", "Off-Tank", "Main Tank", etc.)
```

Note that "Group Rows" and "Tanks" are now at the section level, not within "Section Player Info". This data is used for quick lookups when determining which rows might be relevant based on the player's group membership.

### Section Player Info

A structured table containing various aspects of player relevance:

```lua
section["Section Player Info"] = {
    ["Relevant Rows"] = {2, 5, 8},       -- Rows directly relevant to the player by name or class
    ["Relevant Group Rows"] = {3, 6},     -- Rows relevant to player based on their group
    ["OSD Assignments"] = {
        -- Each entry is an array with:
        -- 1. Role (column header where player was found)
        -- 2. Icon from column 1 in the row
        -- 3. Target from column 2 in the row
        -- 4+ Tank names from tank columns
        -- Important: One row can generate multiple OSD Assignment entries
        -- if the player's name or class appears in multiple columns
        {
            "Tank", "Skull", "Anub'rekhan", "Azzco", "Clickyou"
        },
        {
            "Heal", "Circle", "Faerlina", "Azzco", "Clickyou"
        },
        -- Additional assignment entries
    },
    ["OSD Group Assignments"] = {
        -- Array of group assignments structured the same way as OSD Assignments:
        {
            "Heal", "Skull", "Anub'rekhan", "Azzco", "Clickyou"
        },
        -- Additional assignment entries
    }
}
```

## Multiple Matches Per Line

A single row in the raid assignments can generate multiple OSD entries if the player's name or class appears in multiple columns. For example:

```
| Icon  | Target    | Tank   | Heal   | DPS    |
|-------|-----------|--------|--------|--------|
| Skull | Boss Name | Azzco  | Azzco  | Raider |
```

In this case, if the player's name is "Azzco", two separate OSD Assignment entries would be created:
1. An entry for the Tank role
2. An entry for the Heal role

This allows the OSD to display multiple roles that a player may have on a single target.

## Tank Information Inclusion

All OSD entries include the names of tanks assigned to the target. Tanks are identified using the `Tanks` column indices and added to OSD entries after the target (starting at position 4):

1. Role (e.g., "Tank", "Heal", "DPS")
2. Icon (e.g., "Skull", "Star")
3. Target name (e.g., "Anub'rekhan")
4. First tank name from the row (if applicable)
5. Second tank name from the row (if applicable)
6. Additional tank names...

This ensures that regardless of the player's assigned role, they can always see who is tanking the target, which is critical information for most raid encounters.

## Assignment Types

### OSD Assignments vs OSD Group Assignments

These two structures serve different purposes and have different stability characteristics:

1. **OSD Assignments**:
   - Based on individual player names or class matching
   - More static and stable throughout a raid
   - Generated when a player's name or class is explicitly found in an assignment row
   - Used for displaying personal assignments that rarely change during an encounter
   - May contain multiple entries per row if player is assigned multiple roles

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
   - Generate group row indices (stored at section level)
   - Identify player-specific relevant rows
   - Find tank role column indices by header matching (stored at section level)
   - Create pre-formatted OSD assignment data

2. **Relevant Row Identification**:
   - **Direct Relevance**: Rows containing the player's name or class (e.g., Warriors for a warrior) in any role column
   - **Group Relevance**: Rows containing a reference to the player's current group number

3. **OSD Assignment Formatting**:
   - Pre-formatted entries are created for each role where the player's name/class is matched
   - Multiple entries may be created per row if player appears in multiple columns
   - Tank names are included in each entry after the target name
   - Both direct assignments and group assignments are formatted similarly for consistent display

## Refresh Behavior

When groups change, only a subset of data needs to be recalculated:

1. **Static Data** (processed once during import):
   - `Tanks`: Column indices for tank roles (section level)
   - `Group Rows`: All rows with group references (section level)
   - `Relevant Rows`: Rows that match player's name/class
   - `OSD Assignments`: Formatted data for player-relevant rows

2. **Dynamic Data** (updated when group changes):
   - `Relevant Group Rows`: Rows that match player's current group
   - `OSD Group Assignments`: Formatted data for group-relevant rows

This approach optimizes performance by only reprocessing what's necessary when raid composition changes.

## Usage Example

This pre-processed data is used in several ways:

1. **Main Frame Highlighting**: 
   - Both `Relevant Rows` and `Relevant Group Rows` indices are used to highlight rows in the main assignments frame
   - Care is taken to prevent double-highlighting when a row appears in both arrays

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
- Separation of static and dynamic data processing for improved performance