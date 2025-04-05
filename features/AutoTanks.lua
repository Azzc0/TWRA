-- -- ...existing code...

-- -- Update tank assignments in ORA2
-- function TWRA:UpdateTanks()
--     -- Verify we have ORA2 and tank sync is enabled
--     if not self:IsORA2Available() then
--         self:Debug("tank", "ORA2 not available for tank sync")
--         return false
--     end
    
--     if not self.SYNC or self.SYNC.tankSync ~= true then  -- Access through stored boolean
--         self:Debug("tank", "Tank sync is disabled")
--         return false
--     end
    
--     -- ...existing code...
-- end

-- -- ...existing code...
-- Check if oRA2 is available

function TWRA:IsORA2Available()
    return oRA and oRA.maintanktable ~= nil  -- Changed to lowercase
end

function TWRA:UpdateTanks()
    -- Debug output our sync state
    DEFAULT_CHAT_FRAME:AddMessage("TWRA: Updating tanks for section " .. 
        self.navigation.handlers[self.navigation.currentIndex])
    
    -- Check if oRA2 is available
    if not self:IsORA2Available() then
        DEFAULT_CHAT_FRAME:AddMessage("TWRA: oRA2 is required for tank management")
        return
    end
    
    -- Check if we have data
    if not self.fullData or table.getn(self.fullData) == 0 then
        DEFAULT_CHAT_FRAME:AddMessage("TWRA: No data to update tanks from")
        return
    end
    
    -- Get current section from navigation
    local currentSection = nil
    if self.navigation and self.navigation.handlers and self.navigation.currentIndex then
        currentSection = self.navigation.handlers[self.navigation.currentIndex]
    end
    
    if not currentSection then
        DEFAULT_CHAT_FRAME:AddMessage("TWRA: No section selected")
        return
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("TWRA: Processing tanks for section " .. currentSection)
    
    -- Find header row for column names
    local headerRow = nil
    for i = 1, table.getn(self.fullData) do
        if self.fullData[i][1] == currentSection and self.fullData[i][2] == "Icon" then
            headerRow = self.fullData[i]
            break
        end
    end
    
    if not headerRow then
        DEFAULT_CHAT_FRAME:AddMessage("TWRA: Invalid data format - header row not found")
        return
    end
    
    -- Find tank columns for current section
    local tankColumns = {}
    -- Find Tank columns in this section's header
    for k = 4, table.getn(headerRow) do
        if headerRow[k] == "Tank" then
            table.insert(tankColumns, k)
            DEFAULT_CHAT_FRAME:AddMessage("TWRA Debug: Found tank column at index " .. k)
        end
    end
    
    if table.getn(tankColumns) == 0 then
        DEFAULT_CHAT_FRAME:AddMessage("TWRA: No tank columns found in section " .. currentSection)
        return
    end
    
    -- First pass: collect unique tanks in order
    local uniqueTanks = {}
    for _, columnIndex in ipairs(tankColumns) do  -- Fixed typo here (was ttankColumns)
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
    
    -- Clear existing tanks first
    for i = 1, 10 do
        oRA.maintanktable[i] = nil
    end
    if GetNumRaidMembers() > 0 then
        SendAddonMessage("CTRA", "MT CLEAR", "RAID")
    end
    
    -- Second pass: assign tanks in order
    DEFAULT_CHAT_FRAME:AddMessage("TWRA: Setting " .. table.getn(uniqueTanks) .. " tanks")
    for i = 1, table.getn(uniqueTanks) do
        local tankName = uniqueTanks[i]
        oRA.maintanktable[i] = tankName
        DEFAULT_CHAT_FRAME:AddMessage("TWRA: Set MT" .. i .. " to " .. tankName)
        if GetNumRaidMembers() > 0 then
            SendAddonMessage("CTRA", "SET " .. i .. " " .. tankName, "RAID")
        end
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("TWRA: Tank updates completed")
end