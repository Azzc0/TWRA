-- Add initialization function for tank sync
function TWRA:InitializeTankSync()
    -- Check if sync is enabled in options
    if TWRA_SavedVariables and TWRA_SavedVariables.options and 
       TWRA_SavedVariables.options.liveSync and TWRA_SavedVariables.options.tankSync then
        
        -- Ensure SYNC module exists
        self.SYNC = self.SYNC or {}
        self.SYNC.tankSync = true
        self.SYNC.liveSync = true
        
        -- Apply current tanks if oRA2 is available
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

-- Consolidated UpdateTanks function with comprehensive functionality
function TWRA:UpdateTanks()
    -- Debug output our sync state
    self:Debug("tank", "Updating tanks for section " .. 
        self.navigation.handlers[self.navigation.currentIndex])
    
    -- Check if oRA2 is available
    if not self:IsORA2Available() then
        self:Debug("error", "oRA2 is required for tank management")
        return
    end
    
    -- Get current section from navigation
    local currentSection = nil
    if self.navigation and self.navigation.handlers and self.navigation.currentIndex then
        currentSection = self.navigation.handlers[self.navigation.currentIndex]
    end
    
    if not currentSection then
        self:Debug("error", "No section selected")
        return
    end
    
    self:Debug("tank", "Processing tanks for section " .. currentSection)
    
    -- Handle based on data format
    local uniqueTanks = {}
    
    -- Check if we're using the new data format
    if self:IsNewDataFormat() then
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
        
        -- Process rows to find unique tanks
        if sectionData["Section Rows"] then
            for _, rowData in ipairs(sectionData["Section Rows"]) do
                -- Skip special rows
                if rowData[1] ~= "Note" and rowData[1] ~= "Warning" and rowData[1] ~= "GUID" then
                    -- Check each tank column for tanks
                    for _, tankCol in ipairs(tankColumns) do
                        if tankCol <= table.getn(rowData) and rowData[tankCol] and rowData[tankCol] ~= "" then
                            local tankName = rowData[tankCol]
                            local alreadyAdded = false
                            
                            -- Check if tank is already in our list
                            for _, existingTank in ipairs(uniqueTanks) do
                                if existingTank == tankName then
                                    alreadyAdded = true
                                    break
                                end
                            end
                            
                            -- Add tank if unique and we haven't hit the limit
                            if not alreadyAdded and table.getn(uniqueTanks) < 10 then
                                table.insert(uniqueTanks, tankName)
                            end
                        end
                    end
                end
            end
        end
    else
        -- Legacy format using fullData
        -- Check if we have data
        if not self.fullData or table.getn(self.fullData) == 0 then
            self:Debug("error", "No data to update tanks from")
            return
        end
        
        -- Find header row for column names
        local headerRow = nil
        for i = 1, table.getn(self.fullData) do
            if self.fullData[i][1] == currentSection and self.fullData[i][2] == "Icon" then
                headerRow = self.fullData[i]
                break
            end
        end
        
        if not headerRow then
            self:Debug("error", "Invalid data format - header row not found")
            return
        end
        
        -- Find tank columns for current section
        local tankColumns = {}
        for k = 4, table.getn(headerRow) do
            if headerRow[k] == "Tank" then
                self:Debug("tank", "Found tank column at index " .. k)
                table.insert(tankColumns, k)
            end
        end
        
        if table.getn(tankColumns) == 0 then
            self:Debug("error", "No tank columns found in section " .. currentSection)
            return
        end
        
        -- First pass: collect unique tanks in order
        for _, columnIndex in ipairs(tankColumns) do
            for i = 1, table.getn(self.fullData) do
                local row = self.fullData[i]
                if row[1] == currentSection and 
                   row[2] ~= "Icon" and 
                   row[2] ~= "Note" and 
                   row[2] ~= "Warning" then
                    if row[columnIndex] and row[columnIndex] ~= "" then
                        local tankName = row[columnIndex]
                        local alreadyAdded = false
                        
                        -- Check if tank is already in our list
                        for _, existingTank in ipairs(uniqueTanks) do
                            if existingTank == tankName then
                                alreadyAdded = true
                                break
                            end
                        end
                        
                        -- Add tank if unique and we haven't hit the limit
                        if not alreadyAdded and table.getn(uniqueTanks) < 10 then
                            table.insert(uniqueTanks, tankName)
                        end
                    end 
                end
            end
        end
    end
    
    -- Clear existing tanks first
    SendAddonMessage("CTRA", "MT CLEAR", "RAID")
    
    -- Second pass: assign tanks in order
    self:Debug("tank", "Setting " .. table.getn(uniqueTanks) .. " tanks")
    for i = 1, table.getn(uniqueTanks) do
        local tankName = uniqueTanks[i]
        oRA.maintanktable[i] = tankName
        self:Debug("tank", "Set MT" .. i .. " to " .. tankName)
        if GetNumRaidMembers() > 0 then
            SendAddonMessage("CTRA", "SET " .. i .. " " .. tankName, "RAID")
        end
    end
    
    self:Debug("tank", "Tank updates completed")
end