# TWRA On-Screen Display (OSD) Rework Plan

## Overview
This document outlines the plan for reworking the TWRA On-Screen Display (OSD) system. The OSD has two primary functions:

1. Display relevant assignments from the saved variables
2. Show progress during data transmission/reception

## Data Structure
The OSD will use data from the following sources in the saved variables:
```lua
assignments.data.section["Section Metadata"].["Name"]
assignments.data.section["Section Metadata"].["Warning"]
assignments.data.section["Section Player Info"].["OSD Assignments"]
assignments.data.section["Section Player Info"].["OSD Group Assignments"]
```

OSD row data follows this pattern:
```lua
["OSD Group Assignments"] = {
    [1] = {
        [1] = "Grab debuff", -- Role
        [2] = "",            -- Icon associated with target
        [3] = "",            -- Target for the current row
        [4] = "",            -- This and subsequent indices are tanks in the row
    },
},
```

## Primary Function - Assignment Display
The OSD will display:
- Section Title
- OSD Rows (OSD Assignments & OSD Group Assignments)
- Warning footer

### Display Format
Each row will be formatted based on role type:

1. **Tank Role:**
   - `[roleIcon] Role - [raidIcon] Target w/ [classIcon] Tank1 & [classIcon] Tank2`

2. **Healer Role:**
   - `[roleIcon] Role - [classIcon] Tank1 & [classIcon] Tank2 tanking [raidIcon] Target`

3. **Other Roles:**
   - `[roleIcon] Role - [raidIcon] Target tanked by [classIcon] Tank1 & [classIcon] Tank2`

### Icon Usage
- Role icons from `TWRA.ROLE_ICONS` (use `TWRA.ROLE_MAPPINGS` to determine icon, default to "misc")
- Raid icons from `TWRA.ICONS` (only display if exact match found)
- Class icons from class coordinates in `TWRA.CLASS_COORDS` using this texture Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES if missing use TWRA.ICONS.Missing
- Class colored text for player names. Red for missing and grey for offline.

## Secondary Function - Progress Display
During data reception, the OSD will show:
- "Receiving data" message
- Progress bar with percentage text overlay
- "Receiving from X" message

## Visibility Management
The OSD will follow these visibility rules:

1. **Auto-show on Navigation:**
   - The OSD will appear when navigating to a new section
   - It will remain visible for a configurable duration ("Display Duration" setting)
   - The OSD does not show if the main TWRA frame is open, except when the options view is open

2. **Manual Toggle Mode:**
   - If activated via `ToggleOSD()`, the OSD will remain visible until manually toggled off
   - In this mode, the OSD will stay open even during navigation events
   - This overrides the auto-hide timer until explicitly toggled off

3. **Conditional Display:**
   - Will not display if explicitly disabled in options
   - Provides a user-controlled option to show/hide during navigation

4. **Minimap Interaction:**
   - When the user hovers over the TWRA minimap icon, the OSD will show automatically
   - When the mouse leaves the minimap icon, the OSD will hide again
   - This feature provides quick access to assignments without requiring clicks

5. **Group Change Detection:**
   - The OSD will display when the player's group changes AND the player has new assignments
   - If a player changes to a group with no assignments (assignments were removed), the OSD will not show
   - This prevents showing an empty OSD when assignments are no longer relevant

## UI Implementation
- Maintain tooltip styling for the frame
- Remove background on OSD row elements
- Reuse UI elements rather than recreating them
- Prepare for maximum 10 rows and 10 footer items

### UI Element Layout
Each row in the OSD will be structured as follows:

1. **Row Container**:
   - Spans the full width of the OSD frame
   - Height adjusted based on content
   - Positioned sequentially from top to bottom

2. **Element Positioning Within Row**:
   - Elements flow horizontally from left to right
   - Each element (text or icon) anchors to the previous element
   - Text elements handled as separate FontStrings to support proper formatting
   
3. **Element Structure**:
   - Role Icon (leftmost)
   - Role Text FontString (anchored to Role Icon)
   - Target Icon (if applicable, anchored to Role Text)
   - Target Text FontString (anchored to Target Icon or Role Text)
   - Tank Class Icons (anchored to previous elements)
   - Various connecting text pieces ("with", "tanked by", etc.) as separate FontStrings
   
4. **Text Handling**:
   - Font strings will be created to contain segments of text
   - If text needs an icon in the middle, the text will be split into multiple FontStrings
   - Class names will be colored using their class colors
   - Missing/offline players will use red/grey colors respectively

5. **Width Handling**:
   - Row will have minimum width (equal to frame width)
   - If content exceeds width, it will:
     - Not wrap (single line per assignment)
     - Truncate with ellipsis (...) if necessary
   - Option to expand frame width if needed for important information

6. **Height Calculation**:
   - Each row has fixed height
   - Frame height calculated as: Header + (Row Height × Number of Rows) + Warnings + Padding

### Footer Elements
Footer elements (particularly warnings) will have specific styling:

1. **Warning Design**:
   - Slight red background tint for visibility (rgba(0.3, 0.1, 0.1, 0.3))
   - Warning icon (`TWRA.ICONS.Warning`) positioned at the left side
   - Warning text following the icon in light red color
   - Each warning on its own line with consistent height (18px)

2. **Maximum Content Expectations**:
   - Player names: maximum of 12 characters
   - Target/boss names: assume maximum length similar to "Grand Widow Faerlina"
   - Roles: variable length but not excessively long (sourced from spreadsheet headers)
   - Longest expected row content: 
     `[healIcon] Main Tank Healer - [classIcon]Tank1 & [classIcon]Tank2 & [classIcon]Tank3 tanking [raidIcon] Grand Widow Faerlina`

3. **Width Handling**:
   - Minimum width to accommodate expected content (400px recommended)
   - Option to expand if content requires it
   - Truncate with ellipsis for extremely long content

### Row Creation Process
1. **Layout Algorithm**:
   ```
   For each assignment:
     - Create/reuse row container
     - Create/reuse role icon texture
     - Position icon at left side of row
     - Create/reuse role text font string
     - Create text for "Role - " anchored to role icon
     - If target has raid icon:
       - Create/reuse target icon texture anchored to role text
       - Create/reuse target text font string anchored to target icon
     - Else:
       - Create/reuse target text font string anchored to role text
     - Depending on role type (tank, healer, other):
       - Create appropriate connector text ("with", "tanking", "tanked by")
       - For each tank:
         - Create/reuse class icon texture
         - Apply class color to tank name
         - Position anchored to previous element
   ```

2. **Element Reuse Strategy**:
   - Maintain pools of textures and font strings
   - Show/hide as needed rather than creating/destroying
   - Reset positions and content for each update

### Element Pools
We'll implement UI element pools for efficient reuse:

1. **Element Types**:
   - Row frames (containers for each assignment row)
   - Role icons (textures for role icons)
   - Target icons (textures for raid target icons)
   - Class icons (textures for tank class icons)
   - Text segments (font strings for various text components)

2. **Pool Structure**:
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

3. **Element Acquisition**:
   ```lua
   -- Function to get or create a UI element from a pool
   function TWRA:GetPooledElement(poolName, parent, createFunc)
       local pool = self.OSD.pools[poolName]
       
       -- Find an unused element in the pool
       for i, element in ipairs(pool) do
           if not element.inUse then
               element.inUse = true
               element:Show()
               return element
           end
       end
       
       -- No unused elements, create new one
       local newElement = createFunc(parent)
       newElement.inUse = true
       table.insert(pool, newElement)
       
       return newElement
   end
   ```

4. **Pool Reset**:
   ```lua
   -- Function to reset all pools after use
   function TWRA:ResetElementPools()
       for poolName, pool in pairs(self.OSD.pools) do
           for _, element in ipairs(pool) do
               element.inUse = false
               element:Hide()
           end
       end
   end
   ```

## Implementation Steps

1. **Frame Creation and Management (OSD.lua)**
   - Handle frame creation and positioning
   - Manage visibility and auto-hiding
   - Support switching between assignment and progress display modes

2. **UI Element Management**
   - Create a pool of reusable UI elements
   - Initialize elements on first use
   - Show/hide elements as needed

3. **Content Display Logic**
   - Process assignment data for display
   - Format rows based on role type
   - Update warning footer

4. **Progress Display**
   - Create progress bar with percentage text
   - Update progress based on chunk reception

5. **Transition Management**
   - Ensure smooth transitions between different OSD states
   - Handle resizing based on content

6. **Minimap Button Integration**
   - Modify existing `OnEnter` handler to show OSD automatically
   ```lua
   miniButton:SetScript("OnEnter", function()
       -- Show tooltip
       GameTooltip:SetOwner(miniButton, "ANCHOR_LEFT")
       GameTooltip:AddLine("TWRA - Raid Assignments")
       GameTooltip:AddLine("Left-click: Toggle assignments window", 1, 1, 1)
       GameTooltip:AddLine("Right-click: Toggle assignments OSD", 1, 1, 1)
       GameTooltip:Show()
       
       -- Show OSD without auto-hide timer
       -- Store previous visibility state to restore on mouse leave
       this.previousOSDState = TWRA.OSD and TWRA.OSD.isVisible
       
       -- Only show if not already showing from manual toggle
       if TWRA.ShowOSD and (not TWRA.OSD or not TWRA.OSD.manuallyToggled) then
           TWRA:ShowOSDPermanent()
           TWRA.OSD.hoveredFromMinimap = true
       end
   end)
   ```
   
   - Modify `OnLeave` handler to hide OSD if it was shown by hover
   ```lua
   miniButton:SetScript("OnLeave", function()
       GameTooltip:Hide()
       
       -- Only hide if we showed it on hover and not manually toggled
       if TWRA.HideOSD and TWRA.OSD and TWRA.OSD.hoveredFromMinimap and not TWRA.OSD.manuallyToggled then
           TWRA:HideOSD()
           TWRA.OSD.hoveredFromMinimap = false
       end
       
       -- Restore previous state if needed
       if this.previousOSDState ~= nil then
           if this.previousOSDState and not TWRA.OSD.isVisible then
               TWRA:ShowOSDPermanent()
           end
           this.previousOSDState = nil
       end
   end)
   ```

7. **Group Change Detection**
   - Create a function to track player's current assignments
   ```lua
   function TWRA:StoreCurrentAssignments()
       self.previousAssignments = {
           personal = {},
           group = {}
       }
       
       -- Check if we have the needed data
       if not self.assignments or not self.assignments.playerAssignments then
           return
       end
       
       -- Store current personal assignments
       for i, assignment in ipairs(self.assignments.playerAssignments) do
           table.insert(self.previousAssignments.personal, {
               role = assignment.role,
               target = assignment.target,
               icon = assignment.icon,
               tanks = assignment.tanks or {}
           })
       end
       
       -- Store current group assignments
       if self.assignments.groupAssignments then
           for i, assignment in ipairs(self.assignments.groupAssignments) do
               table.insert(self.previousAssignments.group, {
                   role = assignment.role,
                   target = assignment.target,
                   icon = assignment.icon,
                   tanks = assignment.tanks or {}
               })
           end
       end
   end
   ```
   
   - Modify `OnGroupChanged` function to compare assignments and show OSD
   ```lua
   function TWRA:OnGroupChanged()
       -- First store the current group number
       local oldGroup = self.playerGroup or 0
       local newGroup = 0
       
       -- Get player's current raid group
       if GetNumRaidMembers() > 0 then
           for i = 1, GetNumRaidMembers() do
               local name, _, subgroup = GetRaidRosterInfo(i)
               if name == UnitName("player") then
                   newGroup = subgroup
                   break
               end
           end
       end
       
       -- Store new group
       self.playerGroup = newGroup
       
       -- If group didn't change, no need to continue
       if oldGroup == newGroup then
           return
       end
       
       -- Process current assignments for the new group
       self:BuildPlayerAssignments()
       
       -- Check if there are new assignments
       local hasNewAssignments = false
       if self.assignments and self.assignments.playerAssignments and 
          table.getn(self.assignments.playerAssignments) > 0 then
           if not self.previousAssignments or 
              not self.previousAssignments.personal or 
              table.getn(self.previousAssignments.personal) == 0 then
               -- No previous assignments but we have some now
               hasNewAssignments = true
           else
               -- Compare with previous assignments to see if they're different
               hasNewAssignments = not self:AreAssignmentsEqual(
                   self.assignments.playerAssignments,
                   self.previousAssignments.personal
               )
           end
       end
       
       -- Only show OSD if we have new assignments
       if hasNewAssignments then
           -- Show the OSD with assignments
           self:ShowOSD(self.OSD.duration)
       end
       
       -- Store current assignments for next comparison
       self:StoreCurrentAssignments()
   end
   ```
   
   - Add helper function to compare assignments
   ```lua
   function TWRA:AreAssignmentsEqual(assignments1, assignments2)
       if not assignments1 or not assignments2 then
           return false
       end
       
       if table.getn(assignments1) ~= table.getn(assignments2) then
           return false
       end
       
       -- Simple comparison - just check if role and target are the same
       for i, assignment1 in ipairs(assignments1) do
           local found = false
           for _, assignment2 in ipairs(assignments2) do
               if assignment1.role == assignment2.role and
                  assignment1.target == assignment2.target then
                   found = true
                   break
               end
           end
           if not found then
               return false
           end
       end
       
       return true
   end
   ```

8. **OSD Toggle Function Update**
   - Modify `ToggleOSD` to track manual toggle state
   ```lua
   function TWRA:ToggleOSD()
       -- Make sure OSD is initialized
       if not self.OSD then
           self:InitOSD()
       end
       
       if self.OSD.isVisible then
           self:HideOSD()
           self.OSD.manuallyToggled = false
       else
           self:ShowOSDPermanent()
           self.OSD.manuallyToggled = true
           self.OSD.hoveredFromMinimap = false  -- Reset hover state
       end
       
       return self.OSD.isVisible
   end
   ```

## Migration Notes
- `OSDContent.lua` will be deprecated
- Data will be generated by `DataProcessing.lua` functions during import
- OSD will update on group changes

## Implementation Order
1. Create the core OSD frame structure with reusable elements
2. Implement the assignment display with role-based formatting
3. Add progress display mode
4. Update visibility management with auto-hide timer
5. Add minimap hover functionality
6. Implement group change detection
7. Test with various assignments and scenarios