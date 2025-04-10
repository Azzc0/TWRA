# TWRA Data Restructure Implementation Plan

This document outlines the steps needed to migrate TWRA to the new data structure that improves performance, readability, and extensibility.

## 1. Current vs New Data Structure

### Current Structure
```lua
TWRA_ImportString = {
  ["data"] = [
    -- Flat array where section names are repeated in every row
    -- Each row needs processing for display
  ]
}
```

### New Structure
```lua
TWRA_ImportString = {
  ["data"] = {
    [1] = {
      ["Section Name"] = "Boss or Encounter Name",
      ["Section Header"] = {
        [1] = "Icon",
        [2] = "Target",
        -- Additional headers
      },
      ["Section Rows"] = {
        [1] = {
          [1] = "Skull",
          [2] = "Boss Name",
          -- Row data
        },
        -- Additional rows
      },
      ["Relevant Rows"] = {1, 2, 3}, -- Pre-calculated for highlighting
      ["Formatted Assignments"] = {
        [1] = {"Heal", "Player1", "Player2", "Skull", "Target"},
        -- Pre-processed assignment data ready for OSD
      }
    },
    -- Additional sections
  }
}
```

## 2. Implementation Strategy

We'll use a phased approach to minimize disruption:

1. **Import/Export Phase**: Update import/export functions first
2. **Core Logic Phase**: Update core data handling and navigation
3. **UI Phase**: Update UI components to use the new structure
4. **Enhancement Phase**: Implement new features enabled by the structure

## 3. File-by-File Changes

### Phase 1: Import/Export Functions

#### `core/Base64.lua`
- ~~Update `TWRA_ConvertFromOldFormat` function to transform old format to new~~ I don't think this is worth pursuing. We should just remove the old format and not worry about it.
- Modify `TWRA_ProcessImportString` to handle the new structured format
- ~~Update `TWRA_GenerateExportString` to create structured format~~ We have never been interested in export. Remove any remnants of export functionality on sight.

#### `core/Core.lua`
- ~~Add version flag in saved variables~~ Probably not needed since we're not worried about backwards compatibility at this stage (no release yet)
- ~~Implement migration logic for existing saved data ~~ Since we haven't released I can just purge this data from the saved variables.

### Phase 2: Core Logic

#### `core/Utils.lua`
- Add utility functions for accessing nested structure
- Create helpers for section/row navigation in new format

#### `features/AutoNavigate.lua`
- Update section navigation to use the new structure
- Modify GUID handling for the structured format

#### `sync/Protocol.lua` and `sync/Handlers.lua`
- Update sync protocol to handle the new format
- Ensure chunking mechanism works with restructured data

### Phase 3: UI Components

#### `ui/Frame.lua`
- Rewrite section rendering to use the new structure
- Update row highlighting using pre-calculated "Relevant Rows"
- Modify column display logic for the new format

#### `ui/OSD.lua` and `ui/OSDContent.lua`
- Update to use pre-processed "Formatted Assignments"
- Modify display logic to work with new structure
- Remove redundant processing code

#### `ui/Options.lua`
- ~~Update options panel for any new settings related to format~~ redundant, new data format does not require new settings

### Phase 4: Enhancements

- Implement advanced OSD features using pre-formatted data
- Add functionality for section-specific settings/metadata
- Create tools for managing "Relevant Rows" manually

## 4. Implementation Details

### Pre-calculating "Relevant Rows"

During import processing:
```lua
local relevantRows = {}
for rowIndex, rowData in ipairs(sectionRows) do
  -- Logic to determine if row is relevant (has tanks, healers, etc)
  if IsRelevantRow(rowData) then
    table.insert(relevantRows, rowIndex)
  end
end
section["Relevant Rows"] = relevantRows
```

### Pre-processing "Formatted Assignments"

Similar to current PrepOSD function, but run during import:
```lua
local formattedAssignments = {}
for _, rowIndex in ipairs(relevantRows) do
  local row = sectionRows[rowIndex]
  local assignment = ProcessAssignment(row, headers)
  table.insert(formattedAssignments, assignment)
end
section["Formatted Assignments"] = formattedAssignments
```

## 5. Migration Strategy

~~1. Add backward compatibility for reading old format~~
~~2. Update UI components to handle both formats during transition~~
~~3. Convert old format to new upon import/export operations~~
~~4. After sufficient testing, remove old format support~~

## 6. Testing Strategy

1. Create test cases for various data scenarios
~~2. Verify import/export with both formats~~
3. Test navigation between sections
4. Confirm UI rendering with the new structure
5. Validate sync functionality between clients

## 7. Potential Challenges

1. **Backward Compatibility**: Ensuring older exports still work
2. **Sync Protocol**: Ensuring clients with different versions can communicate
3. **Performance Impact**: Validating actual performance improvements
4. **UI Edge Cases**: Handling unusual data combinations

## 8. Timeline Estimate

- Phase 1 (Import/Export): 1-2 days
- Phase 2 (Core Logic): 2-3 days
- Phase 3 (UI Components): 3-4 days
- Phase 4 (Enhancements): Ongoing as needed

Total time for basic migration: ~7-9 days

## 9. Future Considerations

- Implement additional metadata at section level
- Add support for section-specific settings
- Enable more advanced OSD features using pre-processed data
- Create specialized visualizations for particular boss mechanics
- Improve class coloring cache to avoid repeated lookups
