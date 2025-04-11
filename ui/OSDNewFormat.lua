-- TWRA OSD New Format module
-- Handles OSD display with the new data structure

TWRA = TWRA or {}

-- Function to prepare OSD content from the new format
function TWRA:PrepareOSDContentNewFormat()
    if not self:IsNewDataFormat() then
        return self:PrepareOSDContentLegacy()
    end
    
    local sectionData = self:GetCurrentSectionData()
    if not sectionData then
        self:Debug("osd", "No section data available for OSD")
        return {}
    end
    
    -- Check if we have pre-calculated formatted assignments
    if sectionData["Formatted Assignments"] then
        self:Debug("osd", "Using pre-calculated formatted assignments for OSD")
        return sectionData["Formatted Assignments"]
    end
    
    -- Otherwise, generate them on the fly
    local osdContent = {}
    
    -- Get header data to understand column meanings
    local headers = sectionData["Section Header"]
    if not headers then
        self:Debug("error", "Missing headers in section data")
        return {}
    end
    
    -- Get relevance info
    local relevantRows = {}
    if sectionData["Relevant Rows"] then
        for _, idx in pairs(sectionData["Relevant Rows"]) do
            relevantRows[idx] = true
        end
    else
        -- If no pre-calculated relevant rows, determine them
        relevantRows = self:GetRelevantRowsForCurrentSection(sectionData)
    end
    
    -- Process relevant rows for OSD display
    local rowsData = sectionData["Section Rows"]
    if rowsData then
        for idx, rowData in pairs(rowsData) do
            if relevantRows[idx] then
                local roleCol = self:FindRoleColumnIndex(headers)
                local iconCol = self:FindIconColumnIndex(headers)
                local targetCol = self:FindTargetColumnIndex(headers)
                
                local role = roleCol and rowData[roleCol] or nil
                local icon = iconCol and rowData[iconCol] or nil
                local target = targetCol and rowData[targetCol] or nil
                
                -- Create a display item
                local displayItem = self:CreateOSDItemFromRow(rowData, headers, role, icon, target)
                if displayItem then
                    table.insert(osdContent, displayItem)
                end
            end
        end
    end
    
    return osdContent
end

-- Helper to find the role column index in the headers
function TWRA:FindRoleColumnIndex(headers)
    for i, header in pairs(headers) do
        if header == "Role" or header == "Heal" or header == "Healer" or 
           header == "Heals" or header == "Healers" then
            return i
        end
    end
    return nil
end

-- Helper to find the icon column index in the headers
function TWRA:FindIconColumnIndex(headers)
    for i, header in pairs(headers) do
        if header == "Icon" or header == "Mark" or header == "Marker" then
            return i
        end
    end
    return 1  -- Default to first column if not found
end

-- Helper to find the target column index in the headers
function TWRA:FindTargetColumnIndex(headers)
    for i, header in pairs(headers) do
        if header == "Target" or header == "Mob" or header == "Enemy" then
            return i
        end
    end
    return 2  -- Default to second column if not found
end

-- Create an OSD display item from a row
function TWRA:CreateOSDItemFromRow(rowData, headers, role, icon, target)
    if not rowData then return nil end
    
    local result = {}
    
    -- Add the role if available
    if role and role ~= "" then
        table.insert(result, role)
    end
    
    -- Add player assignments
    for i, header in pairs(headers) do
        -- Skip icon, target, and role columns which we handle separately
        if i ~= self:FindIconColumnIndex(headers) and
           i ~= self:FindTargetColumnIndex(headers) and
           i ~= self:FindRoleColumnIndex(headers) then
            
            local value = rowData[i]
            if value and value ~= "" then
                table.insert(result, value)
            end
        end
    end
    
    -- Add icon and target if available
    if icon and icon ~= "" then
        table.insert(result, icon)
    end
    
    if target and target ~= "" then
        table.insert(result, target)
    end
    
    -- Only return non-empty results
    return table.getn(result) > 0 and result or nil
end

-- Hook into OSD preparation to support new format
if TWRA.PrepareOSDContent then
    local originalPrepareOSDContent = TWRA.PrepareOSDContent
    TWRA.PrepareOSDContent = function(self)
        if self.IsNewDataFormat and type(self.IsNewDataFormat) == "function" then
            return self:PrepareOSDContentNewFormat()
        else
            return originalPrepareOSDContent(self)
        end
    end
end

-- Keep the legacy function for backward compatibility
function TWRA:PrepareOSDContentLegacy()
    -- This would be implemented elsewhere or could call the original function
    return {}
end
