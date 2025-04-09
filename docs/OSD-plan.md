# TWRA Addon OSD Improvement Plan

## Current OSD Enhancement Priorities

1. **UI Improvements**
   - Remove the "(offline)" text as it takes too much space in the display
   - Incorporate class icons (use TWRA.ICONS.Missing if player not found in raid)
   - Implement ApplyClassColoring for player names

2. **Role-Based Assignment Templates**
   - Tank template: Focus on co-tanks and target information
   - Healer template: Focus on tanks being healed and their targets
   - DPS/Utility template: Focus on target and tank information

3. **UI Utility Functions**
   - Create `IconAndName()` function to standardize display of icons and text
   - Create a role mapping table to standardize role names to icons, default to Misc if no match

4. **Data Structure Improvements**
   - Implement new structured assignment format
   - Create consistent handling of player/target/role data

## Implementation Guidelines

### Class Icons Integration
- Add class icons next to player names in the OSD
- Use the existing class detection mechanism to determine which icon to show
- Use TWRA.ICONS.Missing (UI-GroupLoot-Pass-Up) for players not found in current raid/party

### Class Coloring
- Apply class coloring to player names using ApplyClassColoring function, this includes red for missing player and grey for offline.
- Ensure consistent coloring between main UI and OSD displays
- Keep target names in their default color for better readability

### Offline Status
- Remove "(offline)" text completely from OSD display
- Consider using a visual indicator (like grayscale or opacity) for offline players instead
- Maintain the offline status in data but don't display the text

### Role Standardization
- Map various role names (e.g., "tank heal", "raid heal") to standardized forms ("Tank", "Heal")
- Create consistent icons for each role type
- Apply standardized role names and icons throughout the OSD interface
