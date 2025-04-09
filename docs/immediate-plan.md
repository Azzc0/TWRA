# TWRA Addon Immediate Development Plan

## Current Priorities

1. **Create Role-Based Assignment Templates**
   - Tank template: Focus on co-tanks and target information
   - Healer template: Focus on tanks being healed and their targets
   - DPS/Utility template: Focus on target and tank information

2. **UI Utility Functions**
   - Create `IconAndName()` function to standardize display of icons and text
   - Create a role mapping table to standardize role names to icons, default to Misc if no match.

3. **Data Structure Improvements**
   - Implement new structured assignment format
   - Create consistent handling of player/target/role data

4. **Component Reuse Strategy**
   - Convert from creating new frames each navigation to reusing elements

## Component Reuse Strategy

Currently, the addon creates new UI elements each time a player navigates between sections. While this approach works, it has several drawbacks:

1. **Memory Usage**: Creating and destroying frames frequently can lead to memory fragmentation
2. **Performance**: Constantly recreating frames is more CPU intensive than reusing them
3. **Consistency**: It's harder to maintain consistent behavior across recreated elements

### Proposed Solution

Instead of recreating frames, we can implement a "pool" pattern:

1. **Create a Frame Pool**:
   - Pre-create a set number of frames for each type (row frames, icons, text elements)
   - Store these in "pools" that can be drawn from when needed

2. **Show/Hide Pattern**:
   - When displaying data, get frames from the pool
   - Update their content and show them
   - Hide unused frames rather than destroying them

3. **Implementation Approach**:
   - Create a simple Pool class that manages frame creation and reuse
   - Modify DatarowsOSD to use frames from the pool rather than creating new ones
   - Reset pool counters when switching sections

### Example Frame Pool Implementation

```lua
-- Simple frame pool
TWRA.FramePool = {}

function TWRA.FramePool:New(frameType, parent, initialCount)
    local pool = {
        frameType = frameType,
        parent = parent,
        frames = {},
        index = 0
    }
    
    -- Pre-create some frames
    for i = 1, initialCount do
        table.insert(pool.frames, self:CreateFrame(frameType, parent))
    end
    
    return pool
end

function TWRA.FramePool:GetFrame()
    self.index = self.index + 1
    
    -- Create a new frame if needed
    if self.index > table.getn(self.frames) then
        table.insert(self.frames, self:CreateFrame(self.frameType, self.parent))
    end
    
    -- Reset and show the frame
    local frame = self.frames[self.index]
    frame:Show()
    return frame
end

function TWRA.FramePool:Reset()
    -- Hide all used frames
    for i = 1, self.index do
        self.frames[i]:Hide()
    end
    self.index = 0
end

function TWRA.FramePool:CreateFrame(frameType, parent)
    -- Create different types of frames based on frameType
    if frameType == "ROW" then
        return CreateFrame("Frame", nil, parent)
    elseif frameType == "ICON" then
        local frame = CreateFrame("Frame", nil, parent)
        frame.texture = frame:CreateTexture(nil, "ARTWORK")
        return frame
    elseif frameType == "TEXT" then
        local frame = CreateFrame("Frame", nil, parent)
        frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        return frame
    end
end
```

This pattern would require changing how we initialize and reset UI elements in DatarowsOSD, but would significantly improve performance for larger raid assignments.
