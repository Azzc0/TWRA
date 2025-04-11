-- TWRA Data Utility
-- Functions for handling the new structured data format

TWRA = TWRA or {}

-- Check if we're using the new data format
function TWRA:IsNewDataFormat()
    if not TWRA_SavedVariables or not TWRA_SavedVariables.assignments then
        return false
    end
    
    return TWRA_SavedVariables.assignments.version == 2
end

-- Build navigation from the new data format
function TWRA:BuildNavigationFromNewFormat()
    self:Debug("nav", "Building navigation from new format data")
    
    self.navigation = self.navigation or { handlers = {}, currentIndex = 1 }
    self.navigation.handlers = {}
    
    if not TWRA_SavedVariables or not TWRA_SavedVariables.assignments or
       not TWRA_SavedVariables.assignments.data then
        self:Debug("nav", "No assignment data available")
        return {}
    end
    
    local sections = TWRA_SavedVariables.assignments.data
    local sectionsAdded = 0
    
    -- Clear debug message to verify what sections are found
    local sectionNames = ""
    
    -- Add each section name to handlers
    for idx, section in pairs(sections) do
        if type(section) == "table" and section["Section Name"] then
            table.insert(self.navigation.handlers, section["Section Name"])
            sectionsAdded = sectionsAdded + 1
            
            if sectionNames ~= "" then
                sectionNames = sectionNames .. ", "
            end
            sectionNames = sectionNames .. "'" .. section["Section Name"] .. "'"
        end
    end
    
    -- Set current index to a valid value
    if sectionsAdded > 0 then
        self.navigation.currentIndex = math.min(
            TWRA_SavedVariables.assignments.currentSection or 1,
            sectionsAdded
        )
    else
        self.navigation.currentIndex = 1
    end
    
    self:Debug("nav", "Built " .. sectionsAdded .. " sections: " .. sectionNames)
    
    return self.navigation.handlers
end

-- Get section by index
function TWRA:GetNewFormatSection(index)
    if not self:IsNewDataFormat() then
        return nil
    end
    
    return TWRA_SavedVariables.assignments.data[index]
end

-- Get the section data for the current section in the new format
function TWRA:GetCurrentSectionData()
    -- Make sure we have assignments data and navigation
    if not TWRA_SavedVariables or not TWRA_SavedVariables.assignments or 
       not TWRA_SavedVariables.assignments.data or
       not self.navigation or not self.navigation.currentIndex or 
       not self.navigation.handlers then
        self:Debug("error", "Missing required data structures for GetCurrentSectionData")
        return nil
    end
    
    -- Get current section name
    local currentIndex = self.navigation.currentIndex
    if currentIndex > table.getn(self.navigation.handlers) then
        self:Debug("error", "Invalid section index: " .. currentIndex)
        return nil
    end
    
    local sectionName = self.navigation.handlers[currentIndex]
    if not sectionName then
        self:Debug("error", "No section name found for index: " .. currentIndex)
        return nil
    end
    
    -- Find the section in the data
    for idx, section in pairs(TWRA_SavedVariables.assignments.data) do
        if type(section) == "table" and section["Section Name"] == sectionName then
            return section
        end
    end
    
    self:Debug("error", "Section not found in data: " .. sectionName)
    return nil
end

-- Display the current section with the new format
function TWRA:DisplayCurrentSection()
    self:Debug("ui", "DisplayCurrentSection called")
    
    -- First check if we're using the new data format
    if self:IsNewDataFormat() then
        -- Get the section data for the current section
        local sectionData = self:GetCurrentSectionData()
        if not sectionData then
            self:Debug("ui", "No section data available")
            return
        end
        
        -- Clear any existing rows
        if self.ClearRows then
            self:ClearRows()
        end
        
        -- Create the header row
        local headerData = sectionData["Section Header"]
        if self.CreateRow and headerData then
            self:Debug("ui", "Creating header row")
            self:CreateRow(1, headerData, false, true)
        else
            self:Debug("error", "Unable to create header row - missing function or data")
        end
        
        -- Create the data rows
        local rowsData = sectionData["Section Rows"]
        if rowsData then
            -- Prepare relevance info
            local relevantRows = {}
            if sectionData["Relevant Rows"] then
                for _, index in pairs(sectionData["Relevant Rows"]) do
                    relevantRows[index] = true
                end
            else
                -- If no pre-calculated relevant rows, check each row as we display
                relevantRows = self:GetRelevantRowsForCurrentSection(sectionData)
            end
            
            -- Display rows
            local rowNum = 2  -- Start after header
            for idx, rowData in pairs(rowsData) do
                if self.CreateRow then
                    local isRelevant = relevantRows[idx] or false
                    self:CreateRow(rowNum, rowData, isRelevant)
                    rowNum = rowNum + 1
                end
            end
            
            self:Debug("ui", "Created " .. (rowNum - 2) .. " data rows")
        else
            self:Debug("error", "No row data available for section")
        end
        
        -- Update UI elements
        if self.UpdateRowDisplay then
            self:UpdateRowDisplay()
        end
        
        -- Update OSD if needed
        if self.ShouldShowOSD and self.ShouldShowOSD() and self.ShowOSD then
            self:Debug("osd", "Showing OSD for new format section")
            self:ShowOSD()
        end
        
        return true
    else
        -- Legacy format handling - call the original function
        return self:DisplayLegacySection()
    end
end

-- Function to get relevant rows for the current player
function TWRA:GetRelevantRowsForCurrentSection(sectionData)
    local relevantRows = {}
    local playerName = UnitName("player")
    local _, playerClass = UnitClass("player")
    playerClass = playerClass and string.upper(playerClass) or nil
    
    -- Find player's group number (1-8)
    local playerGroup = nil
    for i = 1, GetNumRaidMembers() do
        local name, _, subgroup = GetRaidRosterInfo(i)
        if name == playerName then
            playerGroup = subgroup
            break
        end
    end
    
    -- Scan through all rows to find matches
    local rowsData = sectionData["Section Rows"]
    if not rowsData then return {} end
    
    for idx, rowData in pairs(rowsData) do
        local isRelevantRow = false
        
        -- Check each cell for player name, class group, or player's group number
        for _, cellData in pairs(rowData) do
            -- Only check string data
            if type(cellData) == "string" and cellData ~= "" then
                -- Match player name directly
                if cellData == playerName then
                    isRelevantRow = true
                    break
                end
                
                -- Match player class directly
                if playerClass and string.upper(cellData) == playerClass then
                    isRelevantRow = true
                    break
                end
                
                -- Match player class group (like "Warriors" for a Warrior)
                if playerClass and self.CLASS_GROUP_NAMES and 
                   self.CLASS_GROUP_NAMES[cellData] and 
                   string.upper(self.CLASS_GROUP_NAMES[cellData]) == playerClass then
                    isRelevantRow = true
                    break
                end
                
                -- Check for player's group number using a pattern
                if playerGroup then
                    local groupPattern = "%f[%a%d]" .. playerGroup .. "%f[^%a%d]"
                    if string.find(cellData, groupPattern) then
                        isRelevantRow = true
                        break
                    end
                end
            end
        end
        
        -- If row is relevant, add to our list
        if isRelevantRow then
            relevantRows[idx] = true
        end
    end
    
    return relevantRows
end

-- Legacy display function to handle the old format
function TWRA:DisplayLegacySection()
    self:Debug("ui", "Displaying legacy format section")
    
    -- Check if we have data and navigation
    if not self.fullData or not self.navigation or 
       not self.navigation.currentIndex or
       not self.navigation.handlers then
        self:Debug("ui", "No data or navigation available")
        return
    end
    
    local currentSection = self.navigation.handlers[self.navigation.currentIndex]
    if not currentSection then
        self:Debug("ui", "No current section selected")
        return
    end
    
    -- Clear any existing rows
    if self.ClearRows then
        self:ClearRows()
    end
    
    -- Find header row for this section and create it
    local headerRow = nil
    for i = 1, table.getn(self.fullData) do
        if self.fullData[i][1] == currentSection and self.fullData[i][2] == "Icon" then
            headerRow = self.fullData[i]
            break
        end
    end
    
    if headerRow and self.CreateRow then
        self:CreateRow(1, headerRow, false, true)
    end
    
    -- Find rows for this section and create them
    local rowIdx = 2  -- Start after header
    local relevantRows = self:GetPlayerRelevantRows(currentSection)
    
    for i = 1, table.getn(self.fullData) do
        if self.fullData[i][1] == currentSection and self.fullData[i][2] ~= "Icon" then
            local isRelevant = false
            for _, r in ipairs(relevantRows) do
                if r == i then
                    isRelevant = true
                    break
                end
            end
            
            if self.CreateRow then
                self:CreateRow(rowIdx, self.fullData[i], isRelevant)
                rowIdx = rowIdx + 1
            end
        end
    end
    
    -- Update UI elements
    if self.UpdateRowDisplay then
        self:UpdateRowDisplay()
    end
    
    -- Update OSD if needed
    if self.ShouldShowOSD and self.ShouldShowOSD() and self.ShowOSD then
        self:Debug("osd", "Showing OSD for legacy section")
        self:ShowOSD()
    end
    
    return true
end

-- Verify and log the new data structure
function TWRA:VerifyNewDataStructure()
    if not TWRA_SavedVariables or not TWRA_SavedVariables.assignments then
        self:Debug("error", "SavedVariables or assignments not found")
        return false
    end
    
    local assignments = TWRA_SavedVariables.assignments
    self:Debug("data", "Verifying assignments structure:")
    self:Debug("data", "  version: " .. (assignments.version or "nil"))
    self:Debug("data", "  timestamp: " .. (assignments.timestamp or "nil"))
    self:Debug("data", "  currentSection: " .. (assignments.currentSection or "nil"))
    
    if not assignments.data then
        self:Debug("error", "assignments.data is nil")
        return false
    end
    
    if type(assignments.data) ~= "table" then
        self:Debug("error", "assignments.data is not a table, but " .. type(assignments.data))
        return false
    end
    
    local count = 0
    for idx, section in pairs(assignments.data) do
        count = count + 1
        self:Debug("data", "  Section " .. idx .. ": " .. 
                  (section["Section Name"] or "unnamed"))
    end
    
    self:Debug("data", "Found " .. count .. " sections in assignments.data")
    
    -- Register diagnostic command
    if SLASH_TWRA1 and not self.diagCommandAdded then
        local originalHandler = SlashCmdList["TWRA"]
        SlashCmdList["TWRA"] = function(msg)
            if msg == "diag" then
                TWRA:VerifyNewDataStructure()
            else
                originalHandler(msg)
            end
        end
        self.diagCommandAdded = true
        self:Debug("data", "Added 'diag' command - use /twra diag to verify structure")
    end
    
    return true
end

-- Initialize diagnostics when this file loads
TWRA:VerifyNewDataStructure()
