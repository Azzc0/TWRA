-- Add initialization function for tank sync
function TWRA:InitializeTankSync()
    -- Check if tank sync is enabled in options
    if TWRA_SavedVariables and TWRA_SavedVariables.options and TWRA_SavedVariables.options.tankSync then
        
        -- Ensure SYNC module exists
        self.SYNC = self.SYNC or {}
        self.SYNC.tankSync = true
        
        -- Register for the SECTION_CHANGED message
        self:RegisterEvent("SECTION_CHANGED", function(sectionName, sectionIndex, numSections, context)
            -- Only update tanks if tank sync is enabled
            if self.SYNC.tankSync then
                self:Debug("tank", "SECTION_CHANGED event received, updating tanks")
                self:UpdateTanks()
            end
        end)
        
        -- Apply current tanks if oRA2 is available and we have a current section
        if self:IsORA2Available() and self.navigation and self.navigation.currentIndex then
            self:Debug("tank", "Initializing Tank Sync with current section")
            self:UpdateTanks()
        else
            self:Debug("tank", "Tank sync enabled but waiting for oRA2/navigation")
        end
    end
end

-- Check if oRA2 is available
function TWRA:IsORA2Available()
    return oRA and oRA.maintanktable ~= nil  -- Changed to lowercase
end

-- Consolidated UpdateTanks function focused on new data format
function TWRA:UpdateTanks()
    -- Check if feature is enabled
    if not (self.SYNC and self.SYNC.tankSync) then
        self:Debug("tank", "Tank sync is disabled, skipping update")
        return
    end
    
    -- Get current section from navigation
    local currentSection = nil
    if self.navigation and self.navigation.handlers and self.navigation.currentIndex then
        currentSection = self.navigation.handlers[self.navigation.currentIndex]
    end
    
    if not currentSection then
        self:Debug("error", "No section selected for tank updates")
        return
    end
    
    -- Check if oRA2 is available
    if not self:IsORA2Available() then
        self:Debug("error", "oRA2 is required for tank management")
        return
    end
    
    self:Debug("tank", "Processing tanks for section: " .. currentSection)
    
    -- Get current section data
    local sectionData = self:GetCurrentSectionData()
    if not sectionData then
        self:Debug("error", "No section data found for " .. currentSection)
        return
    end
    
    -- Get tank columns from Section Metadata
    local metadata = sectionData["Section Metadata"] or {}
    local tankColumns = metadata["Tank Columns"] or {}
    
    if table.getn(tankColumns) == 0 then
        self:Debug("error", "No tank columns found in section " .. currentSection)
        return
    end
    
    self:Debug("tank", "Found " .. table.getn(tankColumns) .. " tank columns")
    
    -- Track unique tanks in order of appearance
    local uniqueTanks = {}
    local seenTanks = {}
    
    -- Process each tank column in order (this preserves the order you want)
    for _, tankCol in ipairs(tankColumns) do
        self:Debug("tank", "Processing tank column index: " .. tankCol)
        
        -- Process all rows for this tank column
        if sectionData["Section Rows"] then
            for _, rowData in ipairs(sectionData["Section Rows"]) do
                -- Skip special rows
                if rowData[1] ~= "Note" and rowData[1] ~= "Warning" and rowData[1] ~= "GUID" then
                    -- Check if this column has a tank name
                    if tankCol <= table.getn(rowData) and rowData[tankCol] and rowData[tankCol] ~= "" then
                        local tankName = rowData[tankCol]
                        
                        -- Only add if we haven't seen this tank before
                        if not seenTanks[tankName] then
                            seenTanks[tankName] = true
                            
                            -- Add the tank if we haven't hit the limit
                            if table.getn(uniqueTanks) < 10 then
                                table.insert(uniqueTanks, tankName)
                                self:Debug("tank", "Added tank: " .. tankName .. " from column " .. tankCol)
                            else
                                self:Debug("tank", "Tank limit reached (10), ignoring: " .. tankName)
                            end
                        else
                            self:Debug("tank", "Skipping duplicate tank: " .. tankName)
                        end
                    end
                end
            end
        end
    end
    
    -- Clear existing tanks first
    SendAddonMessage("CTRA", "MT CLEAR", "RAID")
    self:Debug("tank", "Cleared existing tank assignments")
    
    -- Set tanks in the order they were collected
    self:Debug("tank", "Setting " .. table.getn(uniqueTanks) .. " tanks")
    
    -- Fill tank slots up to 8 (oRA2 standard) - This ensures unused slots are set to " ."
    local totalTankSlots = 10
    for i = 1, totalTankSlots do
        local tankName = uniqueTanks[i] or "Empty"  -- Use " ." for empty tank slots
        
        -- Update oRA2's internal table
        oRA.maintanktable[i] = tankName
        
        -- Send the command to update other clients
        if GetNumRaidMembers() > 0 then
            local commandText = "SET " .. i .. " " .. tankName
            self:Debug("tank", "Sending command: " .. commandText)
            SendAddonMessage("CTRA", commandText, "RAID")
        end
        
        self:Debug("tank", "Set MT" .. i .. " to " .. tankName)
    end
    
    self:Debug("tank", "Tank updates completed")
end