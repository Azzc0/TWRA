-- Add initialization function for tank sync
function TWRA:InitializeTankSync()
    -- Check if tank sync is enabled in options
    if TWRA_SavedVariables and TWRA_SavedVariables.options then
        
        -- Ensure SYNC module exists
        self.SYNC = self.SYNC or {}
        
        -- Set tankSync based on either option being enabled
        self.SYNC.tankSync = (TWRA_SavedVariables.options.oRA2TankSync or TWRA_SavedVariables.options.pfUITankSync)
        
        -- Register for the SECTION_CHANGED message
        self:RegisterEvent("SECTION_CHANGED", function(sectionName, sectionIndex, numSections, context)
            -- Only update tanks if tank sync is enabled
            if self.SYNC.tankSync then
                self:Debug("tank", "SECTION_CHANGED event received, updating tanks")
                self:UpdateTanks()
            end
        end)
        
        -- Apply current tanks if we have a current section
        if self.navigation and self.navigation.currentIndex then
            self:Debug("tank", "Initializing Tank Sync with current section")
            self:UpdateTanks()
        else
            self:Debug("tank", "Tank sync enabled but waiting for navigation")
        end
    end
end

-- Check if oRA2 is available
function TWRA:IsORA2Available()
    return oRA and oRA.maintanktable ~= nil
end

-- Check if pfUI is available
function TWRA:IsPfUIAvailable()
    return pfUI and pfUI.config and pfUI.config.nameplate ~= nil
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
    
    self:Debug("tank", "Processing tanks for section: " .. currentSection)
    
    -- Get current section data
    local sectionData = self:GetCurrentSectionData()
    if not sectionData then
        self:Debug("error", "No section data found for " .. currentSection)
        return
    end
    
    -- Initialize metadata if missing
    if not sectionData["Section Metadata"] then
        sectionData["Section Metadata"] = {}
    end
    
    -- Get tank columns from Section Metadata
    local metadata = sectionData["Section Metadata"]
    local tankColumns = metadata["Tank Columns"] or {}
    
    -- Log debugging information about tank columns
    -- self:Debug("tank", "Looking for tank columns in section " .. currentSection, true)
    -- self:Debug("tank", "Section metadata contains " .. table.getn(tankColumns) .. " pre-identified tank columns")
    
    -- If no tank columns found in metadata, scan for them now
    if table.getn(tankColumns) == 0 then
        -- Attempt to identify tank columns in the section data
        if self.FindTankRoleColumns then
            self:Debug("tank", "No tank columns found in metadata, attempting to identify them now", true)
            tankColumns = self:FindTankRoleColumns(sectionData)
            self:Debug("tank", "Found " .. table.getn(tankColumns) .. " tank columns via dynamic detection", true)
        else
            self:Debug("error", "FindTankRoleColumns function not available")
            return
        end
    end
    
    -- Display the tank columns we found
    if table.getn(tankColumns) > 0 then
        local columnList = ""
        for i, colIdx in ipairs(tankColumns) do
            if i > 1 then columnList = columnList .. ", " end
            
            -- Try to get the header name
            local headerName = "?"
            if sectionData["Section Header"] and sectionData["Section Header"][colIdx] then
                headerName = sectionData["Section Header"][colIdx]
            end
            
            columnList = columnList .. colIdx .. " (" .. headerName .. ")"
        end
        self:Debug("tank", "Using tank columns: " .. columnList)
    else
        self:Debug("error", "No tank columns found in section " .. currentSection)
        return
    end
    
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
    
    -- Update oRA2 if enabled
    if TWRA_SavedVariables and TWRA_SavedVariables.options and TWRA_SavedVariables.options.oRA2TankSync then
        self:UpdateORA2Tanks(uniqueTanks)
    end
    
    -- Update pfUI if enabled
    if TWRA_SavedVariables and TWRA_SavedVariables.options and TWRA_SavedVariables.options.pfUITankSync then
        self:UpdatePfUITanks(uniqueTanks)
    end
    
    self:Debug("tank", "Tank updates completed with " .. table.getn(uniqueTanks) .. " unique tanks")
end

-- Function to update oRA2 tanks
function TWRA:UpdateORA2Tanks(uniqueTanks)
    -- Check if oRA2 is available
    if not self:IsORA2Available() then
        -- self:Debug("error", "oRA2 is not available for tank management")
        return false
    end

    -- Clear existing tanks first
    SendAddonMessage("CTRA", "MT CLEAR", "RAID")
    -- self:Debug("tank", "Cleared existing tank assignments in oRA2")
    
    -- Fill tank slots up to 10 (oRA2 standard)
    local totalTankSlots = 10
    for i = 1, totalTankSlots do
        local tankName = uniqueTanks[i] or "Empty"  -- Use "Empty" for empty tank slots
        
        -- Update oRA2's internal table
        oRA.maintanktable[i] = tankName
        
        -- Send the command to update other clients
        if GetNumRaidMembers() > 0 then
            local commandText = "SET " .. i .. " " .. tankName
            self:Debug("tank", "Sending command: " .. commandText)
            SendAddonMessage("CTRA", commandText, "RAID")
        end
        
        self:Debug("tank", "Set oRA2 MT" .. i .. " to " .. tankName)
    end
    
    return true
end

-- Function to update pfUI tanks
function TWRA:UpdatePfUITanks(tankNames)
    -- Skip if no tanks
    if not tankNames or table.getn(tankNames) == 0 then
        self:Debug("tank", "No tanks to update in pfUI")
        return false
    end
    
    -- Check if pfUI is available
    if not pfUI_config then
        self:Debug("tank", "pfUI_config global not available")
        return false
    end
    
    -- Format the tank list in pfUI's offtank format: "#Tank1#Tank2#Tank3"
    local tankList = ""
    for i = 1, table.getn(tankNames) do
        tankList = tankList .. "#" .. tankNames[i]
    end
    
    -- Set the tank list for nameplate offtank highlighting
    self:Debug("tank", "Setting pfUI offtank list: " .. tankList)
    
    -- Update pfUI's combatofftanks setting directly as in the working command
    if pfUI_config and pfUI_config["nameplates"] then
        pfUI_config["nameplates"]["combatofftanks"] = tankList
        self:Debug("tank", "Updated pfUI_config[\"nameplates\"][\"combatofftanks\"] = \"" .. tankList .. "\"")
    else
        -- If nameplates table doesn't exist, create it
        if not pfUI_config["nameplates"] then
            pfUI_config["nameplates"] = {}
            self:Debug("tank", "Created pfUI_config[\"nameplates\"] table")
        end
        pfUI_config["nameplates"]["combatofftanks"] = tankList
    end
    
    -- Call UpdateConfig to apply changes immediately
    if pfUI and pfUI.nameplates and pfUI.nameplates.UpdateConfig then
        pfUI.nameplates:UpdateConfig()
        self:Debug("tank", "Called pfUI.nameplates:UpdateConfig() to apply changes")
    end
    
    -- Also attempt to update using the "tanklist" property for older versions
    if pfUI and pfUI.config and pfUI.config.nameplate then
        pfUI.config.nameplate.tanklist = table.concat(tankNames, ",")
        self:Debug("tank", "Updated legacy pfUI.config.nameplate.tanklist")
    end
    
    -- Comment out the chat message to silence the debug output
    -- DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA:|r Updated pfUI offtank list: |cFFFFFF00" .. tankList .. "|r")
    
    return true
end