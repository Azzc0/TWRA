TWRA = TWRA or {}

-- Store original functions
TWRA.originalFunctions = {}

-- Check if we're dealing with example data
function TWRA:IsExampleData(data)
    return data == self.EXAMPLE_DATA
end

-- Enhanced GetPlayerStatus function to handle example data
function TWRA:GetPlayerStatus(name)
    if not name or name == "" then return false, nil end
    
    -- Check if this is the current player
    if UnitName("player") == name then return true, true end
    
    -- Check if we're using example data
    if self.usingExampleData and self.EXAMPLE_PLAYERS then
        -- Get the player class directly from EXAMPLE_PLAYERS
        local classInfo = self.EXAMPLE_PLAYERS[name]
        
        -- If the player is in our example data
        if classInfo then
            -- Check if the player is marked as offline (has |OFFLINE suffix)
            local isOffline = string.find(classInfo, "|OFFLINE")
            if isOffline then
                -- Example player exists but is offline
                return true, false
            else
                -- Example player exists and is online
                return true, true
            end
        end
    end
    
    -- Standard raid roster check for normal operation
    -- Check raid roster
    for i = 1, GetNumRaidMembers() do
        local raidName, _, _, _, _, class, _, online = GetRaidRosterInfo(i)
        if raidName == name then
            return true, (online ~= 0)
        end
    end
    
    -- Check party if not in raid
    if GetNumRaidMembers() == 0 then
        if GetNumPartyMembers() > 0 then
            for i = 1, GetNumPartyMembers() do
                if UnitName("party"..i) == name then
                    return true, UnitIsConnected("party"..i)
                end
            end
        end
    end
    
    return false, nil
end

-- UI-specific functions
TWRA.currentView = "main"  -- Either "main" or "options"

-- Helper function to close dropdown menu
function TWRA:CloseDropdownMenu()
    if self.navigation and self.navigation.dropdownMenu and self.navigation.dropdownMenu:IsShown() then
        self.navigation.dropdownMenu:Hide()
    end
end

-- Enhance CreateMainFrame to use the standardized dropdown and remove Edit button
function TWRA:CreateMainFrame()
    -- Check if frame already exists
    if self.mainFrame then
        return self.mainFrame
    end

    self.navigation = { handlers = {}, currentIndex = 1 }
    self.mainFrame = CreateFrame("Frame", "TWRAMainFrame", UIParent)
    self.mainFrame:SetWidth(800)
    self.mainFrame:SetHeight(300)
    self.mainFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    
    -- Add a proper backdrop with all required properties
    self.mainFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })

    -- Add the frame to UISpecialFrames so it can be closed with Escape key
    tinsert(UISpecialFrames, "TWRAMainFrame")

    self.mainFrame:SetMovable(true)
    self.mainFrame:EnableMouse(true)
    self.mainFrame:RegisterForDrag("LeftButton")
    self.mainFrame:SetScript("OnDragStart", function() self.mainFrame:StartMoving() end)
    self.mainFrame:SetScript("OnDragStop", function() self.mainFrame:StopMovingOrSizing() end)

    local titleText = self.mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    titleText:SetPoint("TOP", 0, -15)
    titleText:SetText("Raid Assignments")

    -- Options button
    local optionsButton = CreateFrame("Button", nil, self.mainFrame, "UIPanelButtonTemplate")
    optionsButton:SetWidth(60)
    optionsButton:SetHeight(20)
    optionsButton:SetPoint("TOPRIGHT", -20, -15)
    optionsButton:SetText("Options")
    
    -- Add debugging to the click handler
    optionsButton:SetScript("OnClick", function() 
        -- Replace direct chat messages with Debug calls
        TWRA:Debug("ui", "Options button clicked, currentView=" .. self.currentView)
        
        if self.currentView == "main" then
            TWRA:Debug("ui", "Will call ShowOptionsView")
            self:ShowOptionsView()
        else
            TWRA:Debug("ui", "Will call ShowMainView")
            self:ShowMainView()
        end
        
        TWRA:Debug("ui", "After options button click, currentView=" .. self.currentView)
    end)
    self.optionsButton = optionsButton

    local announceButton = CreateFrame("Button", nil, self.mainFrame, "UIPanelButtonTemplate")
    announceButton:SetWidth(80)
    announceButton:SetHeight(20)
    announceButton:SetPoint("TOPRIGHT", optionsButton, "TOPLEFT", -10, 0)
    announceButton:SetText("Announce")  -- Shorter text
    announceButton:SetScript("OnClick", function() 
        -- Close dropdown when announcing
        self:CloseDropdownMenu()
        TWRA:AnnounceAssignments() 
    end)
    self.announceButton = announceButton  -- Store reference

    -- Create Update Tanks button
    local updateTanksButton = CreateFrame("Button", nil, self.mainFrame, "UIPanelButtonTemplate")
    updateTanksButton:SetWidth(100)
    updateTanksButton:SetHeight(20)
    updateTanksButton:SetPoint("TOPRIGHT", announceButton, "TOPLEFT", -10, 0)
    updateTanksButton:SetText("Update Tanks")
    
    updateTanksButton:SetScript("OnClick", function()
        -- Close dropdown when updating tanks
        self:CloseDropdownMenu()
        TWRA:UpdateTanks()
    end)
    self.updateTanksButton = updateTanksButton  -- Store reference

    -- Create navigation container - moved down
    local navContainer = CreateFrame("Frame", nil, self.mainFrame)
    navContainer:SetHeight(20)
    navContainer:SetPoint("TOPLEFT", self.mainFrame, "TOPLEFT", 20, -35)  -- Moved down
    navContainer:SetPoint("TOPRIGHT", self.mainFrame, "TOPRIGHT", -20, -35)
    
    -- Previous button
    local prevButton = CreateFrame("Button", nil, navContainer, "UIPanelButtonTemplate")
    prevButton:SetWidth(24)
    prevButton:SetHeight(20)
    prevButton:SetPoint("LEFT", 0, 0)
    prevButton:SetText("<")
    prevButton:SetScript("OnClick", function() 
        -- Close dropdown when navigating
        self:CloseDropdownMenu()
        self:NavigateHandler(-1) 
    end)
    
    -- Next button
    local nextButton = CreateFrame("Button", nil, navContainer, "UIPanelButtonTemplate")
    nextButton:SetWidth(24)
    nextButton:SetHeight(20)
    nextButton:SetPoint("RIGHT", 0, 0)
    nextButton:SetText(">")
    nextButton:SetScript("OnClick", function() 
        -- Close dropdown when navigating
        self:CloseDropdownMenu()
        self:NavigateHandler(1) 
    end)
    
    -- Create section menu button
    local menuButton = CreateFrame("Button", nil, navContainer)
    menuButton:SetPoint("LEFT", prevButton, "RIGHT", 5, 0)
    menuButton:SetPoint("RIGHT", nextButton, "LEFT", -5, 0)
    menuButton:SetHeight(20)
    
    -- Add background to menu button
    local menuBg = menuButton:CreateTexture(nil, "BACKGROUND")
    menuBg:SetAllPoints()
    menuBg:SetTexture(0.1, 0.1, 0.1, 0.7)
    
    -- Menu button text
    local menuText = menuButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    menuText:SetPoint("LEFT", 8, 0)
    menuText:SetPoint("RIGHT", -16, 0)  -- Leave room for dropdown arrow
    menuText:SetJustifyH("CENTER")
    
    -- Dropdown arrow indicator
    local dropdownArrow = menuButton:CreateTexture(nil, "OVERLAY")
    dropdownArrow:SetTexture("Interface\\ChatFrame\\ChatFrameExpandArrow")
    dropdownArrow:SetWidth(16)
    dropdownArrow:SetHeight(16)
    dropdownArrow:SetPoint("RIGHT", -2, 0)
    
    -- Update navigation references
    self.navigation.prevButton = prevButton
    self.navigation.nextButton = nextButton
    self.navigation.handlerText = menuText  -- Use the same reference name for compatibility
    self.navigation.menuButton = menuButton  -- Store reference to the menu button

    -- Create the dropdown menu
    local dropdownMenu = CreateFrame("Frame", nil, self.mainFrame) 
    dropdownMenu:SetFrameStrata("DIALOG")
    dropdownMenu:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 16,
        insets = { left = 5, right = 5, top = 5, bottom = 5 }
    })
    dropdownMenu:Hide()
    self.navigation.dropdownMenu = dropdownMenu
    dropdownMenu.buttons = {}
    
    -- Create simple dropdown functionality
    menuButton:SetScript("OnClick", function()
        -- Toggle the dropdown menu
        if dropdownMenu:IsShown() then
            dropdownMenu:Hide()
            return
        end
        
        -- Clear previous menu items
        for i = 1, table.getn(dropdownMenu.buttons or {}) do
            if dropdownMenu.buttons[i] then
                dropdownMenu.buttons[i]:Hide()
            end
        end
        dropdownMenu.buttons = {}
        
        -- Position menu
        dropdownMenu:ClearAllPoints()
        dropdownMenu:SetPoint("TOP", menuButton, "BOTTOM", 0, -2)
        dropdownMenu:SetWidth(menuButton:GetWidth())
        
        -- Calculate menu height
        local buttonHeight = 20
        local padding = 10  -- 5px top and bottom
        local menuHeight = (buttonHeight * table.getn(self.navigation.handlers)) + padding
        dropdownMenu:SetHeight(menuHeight)
        
        -- Create menu items
        for i = 1, table.getn(self.navigation.handlers) do
            local handler = self.navigation.handlers[i]
            
            -- Create button
            local button = CreateFrame("Button", nil, dropdownMenu)
            button:SetHeight(buttonHeight)
            button:SetPoint("TOPLEFT", dropdownMenu, "TOPLEFT", 5, -5 - ((i-1) * buttonHeight))
            button:SetPoint("TOPRIGHT", dropdownMenu, "TOPRIGHT", -5, -5 - ((i-1) * buttonHeight))
            
            -- Highlight texture
            button:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
            
            -- Button text
            local buttonText = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            buttonText:SetPoint("LEFT", 5, 0)
            buttonText:SetPoint("RIGHT", -5, 0)
            buttonText:SetText(handler)
            buttonText:SetJustifyH("LEFT")
            
            -- Indicate current selection
            if i == self.navigation.currentIndex then
                button:SetNormalTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
                local normalTex = button:GetNormalTexture()
                normalTex:SetVertexColor(1, 0.82, 0, 0.4)
            end
            
            -- Click handler for dropdown menu items
            button:SetScript("OnClick", function()
                -- Update text immediately
                menuText:SetText(handler)
                
                -- Find the correct index for this handler
                for idx = 1, table.getn(self.navigation.handlers) do
                    if self.navigation.handlers[idx] == handler then
                        -- Use the centralized NavigateToSection function that handles syncing
                        self:NavigateToSection(idx)
                        break
                    end
                end
                
                -- Hide the dropdown
                dropdownMenu:Hide()
            end)
            
            table.insert(dropdownMenu.buttons, button)
        end
        
        dropdownMenu:Show()
    end)
    
    -- Close dropdown when clicking elsewhere
    self.mainFrame:SetScript("OnMouseDown", function()
        if dropdownMenu:IsShown() then
            dropdownMenu:Hide()
        end
    end)
    
    -- Prevent clicks on the dropdown from closing it
    dropdownMenu:SetScript("OnMouseDown", function(self, button)
        -- This stops the click from propagating to the parent frame
        return
    end)

    -- After creating all UI elements, load data
    if TWRA_SavedVariables.assignments and TWRA_SavedVariables.assignments.data then
        self.fullData = TWRA_SavedVariables.assignments.data
        
        -- Update navigation handlers
        self.navigation.handlers = {}
        local seenSections = {}
        
        for i = 1, table.getn(self.fullData) do
            local sectionName = self.fullData[i][1]
            if sectionName and not seenSections[sectionName] then
                seenSections[sectionName] = true
                table.insert(self.navigation.handlers, sectionName)
            end
        end

        -- Restore saved section index
        if TWRA_SavedVariables.assignments.currentSection then
            self.navigation.currentIndex = TWRA_SavedVariables.assignments.currentSection
        else
            self.navigation.currentIndex = 1
        end
        
        -- Update menu button text
        if self.navigation.handlerText and self.navigation.handlers[self.navigation.currentIndex] then
            self.navigation.handlerText:SetText(self.navigation.handlers[self.navigation.currentIndex])
        end
        
        -- Update display
        self:DisplayCurrentSection()
    end

    self:Debug("ui", "Main frame created")
    return self.mainFrame
end

-- Helper function for handler management
local function getUniqueHandlers(data)
    local handlers = {}
    local seen = {}
    for i = 2, table.getn(data) do  -- Start from row 2 (skip only header)
        if data[i][1] and not seen[data[i][1]] then
            -- Skip empty or special rows
            if data[i][1] ~= "" and data[i][1] ~= "Warning" and data[i][1] ~= "Note" then
                seen[data[i][1]] = true
                table.insert(handlers, data[i][1])
            end
        end
    end
    return handlers
end

-- Update the FilterAndDisplayHandler function to ignore GUID rows

function TWRA:FilterAndDisplayHandler(currentHandler)
    -- Create filtered data structure
    local filteredData = {}
    local maxColumns = 2
    
    -- First, find the header row for this specific section
    local headerRow = nil
    for i = 1, table.getn(self.fullData) do
        if self.fullData[i][1] == currentHandler and self.fullData[i][2] == "Icon" then
            headerRow = self.fullData[i]
            break
        end
    end
    
    -- If no section-specific header found, use the global header (first row)
    if not headerRow then
        for i = 1, table.getn(self.fullData) do
            if self.fullData[i][2] == "Icon" then
                headerRow = self.fullData[i]
                break
            end
        end
    end
    
    -- Add header row first and determine max columns from it
    if headerRow then
        -- Always use the full width of the header row
        maxColumns = table.getn(headerRow)
        table.insert(filteredData, headerRow)
    end
    
    -- Add data rows for current handler (excluding Notes, Warnings, and GUIDs by icon)
    for i = 1, table.getn(self.fullData) do
        if self.fullData[i][1] == currentHandler and 
           self.fullData[i][2] ~= "Icon" and
           self.fullData[i][2] ~= "GUID" and  -- Skip GUID rows
           self.fullData[i][2] ~= "Note" and
           self.fullData[i][2] ~= "Warning" then
            
            -- Ensure all rows have the same number of columns as the header
            local paddedRow = {}
            for j = 1, maxColumns do
                paddedRow[j] = self.fullData[i][j] or ""
            end
            table.insert(filteredData, paddedRow)
        end
    end
    
    -- Update column count and create rows
    self.headerColumns = maxColumns
    self:ClearRows()
    self:CreateRows(filteredData, true)
    
    -- Create footers after rows
    self:CreateFooters(currentHandler)
end

-- Simplify CreateRows to focus only on row creation
function TWRA:CreateRows(data, forceHeader)
    if not data or table.getn(data) == 0 then
        return
    end
    
    -- Initialize row frames array if needed
    if not self.rowFrames then
        self.rowFrames = {}
    end
    
    -- Get rows relevant to current player for highlighting
    local relevantRows = self:GetPlayerRelevantRows(data)
    
    -- Create rows based on data
    for i = 1, table.getn(data) do
        -- Check if this row should be highlighted
        local shouldHighlight = false
        for _, rowIdx in ipairs(relevantRows) do
            if i == rowIdx then
                shouldHighlight = true
                break
            end
        end
        
        self.rowFrames[i] = self:CreateRow(i, data[i], shouldHighlight)
    end
end

function TWRA:ClearRows()
    -- Initialize rowHighlights if it doesn't exist
    if not self.rowHighlights then
        self.rowHighlights = {}
    end
    
    -- Clear existing highlights more thoroughly
    for i, highlight in pairs(self.rowHighlights) do
        highlight:Hide()
        highlight:SetParent(nil) 
        highlight:ClearAllPoints()
        self.rowHighlights[i] = nil
    end
    self.rowHighlights = {}

    -- Clear existing row frames more thoroughly
    if self.rowFrames then
        for i, row in pairs(self.rowFrames) do
            for j, cell in pairs(row) do
                -- Hide and remove all elements in the cell
                for _, element in pairs({"text", "bg", "icon"}) do
                    if cell[element] then 
                        cell[element]:Hide()
                        cell[element]:SetParent(nil)
                        cell[element]:ClearAllPoints()
                        cell[element] = nil
                    end
                end
                row[j] = nil
            end
            self.rowFrames[i] = nil
        end
        self.rowFrames = {}
    end
    
    -- Also clear footers
    self:ClearFooters()
    
    self.headerColumns = nil
end

-- Row creation with proper formatting
function TWRA:CreateRow(rowNum, data, shouldHighlight)
    local rowFrames = {}
    local yOffset = -40 - (rowNum * 20)
    local fontStyle = rowNum == 1 and "GameFontNormalLarge" or "GameFontNormal"
    local isHeader = rowNum == 1
    local isSpecialRow = data[1] == "Warning" or data[1] == "Note"
    
    -- Player row highlighting logic
    if not isHeader and shouldHighlight then
        local highlight = self.mainFrame:CreateTexture(nil, "BACKGROUND", nil, -2)
        highlight:SetPoint("TOPLEFT", self.mainFrame, "TOPLEFT", 22, yOffset + 1)
        highlight:SetPoint("BOTTOMRIGHT", self.mainFrame, "TOPRIGHT", -22, yOffset - 15)
        highlight:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-Skills-Bar", "REPEAT", "REPEAT")
        highlight:SetTexCoord(0.05, 0.95, 0.1, 0.9)
        highlight:SetBlendMode("ADD")
        highlight:SetVertexColor(1, 1, 0.5, 0.2)
        table.insert(self.rowHighlights, highlight)
    end
    
    -- For special rows (Notes and Warnings) - handle differently with full width span
    if isSpecialRow then
        -- Calculate the full available width of the frame
        local totalWidth = self.mainFrame:GetWidth() - 40  -- 20px padding on each side
        
        -- Create background for special row - spans full width
        local bg = self.mainFrame:CreateTexture(nil, "BACKGROUND", nil, 1)
        bg:SetPoint("TOPLEFT", 20, yOffset)
        bg:SetWidth(totalWidth)
        bg:SetHeight(14)
        bg:SetVertexColor(0.1, 0.1, 0.1, 0.3)
        
        -- Create icon for special rows - positioned at far left
        local iconTexture = nil
        if data[2] and TWRA.ICONS[data[2]] then
            iconTexture = self.mainFrame:CreateTexture(nil, "OVERLAY")
            iconTexture:SetPoint("LEFT", bg, "LEFT", 4, 0)
            iconTexture:SetWidth(12)
            iconTexture:SetHeight(12)
            local iconInfo = TWRA.ICONS[data[2]]
            iconTexture:SetTexture(iconInfo[1])
            iconTexture:SetTexCoord(iconInfo[2], iconInfo[3], iconInfo[4], iconInfo[5])
        end
        
        -- Create text that spans full width
        local cell = self.mainFrame:CreateFontString(nil, "OVERLAY", fontStyle)
        
        -- Position text with icon consideration and set width to fill the remaining space
        local iconPadding = iconTexture and 20 or 8  -- More space when icon exists
        cell:SetPoint("TOPLEFT", 20 + iconPadding, yOffset)
        cell:SetWidth(totalWidth - iconPadding - 4)  -- Full width minus icon space and padding
        cell:SetText(data[3] or "")
        cell:SetJustifyH("LEFT")
        
        -- Use a different color for Notes vs Warnings
        if data[1] == "Warning" then
            cell:SetTextColor(1, 0.7, 0.7)  -- Light red for warnings
        else
            cell:SetTextColor(0.9, 0.9, 1)  -- Light blue-white for notes
        end
        
        rowFrames[1] = {text = cell, bg = bg, icon = iconTexture}
        return rowFrames
    end
    
    -- For normal rows - handle all columns consistently
    -- Calculate column widths - we'll combine columns 1 & 2 (Section & Icon)
    -- and treat column 3 (Target) as the first visible column
    local numColumns = self.headerColumns or table.getn(data)
    local visibleColumns = numColumns - 2  -- Skip section and icon columns
    
    -- Calculate total available width
    local totalAvailableWidth = self.mainFrame:GetWidth() - 40

    -- Use a fixed width for target column that fits "Grand Widow Faerlina"
    local fixedTargetWidth = 170 -- Fixed width for target column
    local remainingWidth = totalAvailableWidth - fixedTargetWidth
    local standardColumnWidth = math.floor(remainingWidth / math.max(1, visibleColumns - 1))

    -- Ensure minimum width for standard columns to fit player names
    local minStandardWidth = 100 -- Minimum width for player columns
    if standardColumnWidth < minStandardWidth and visibleColumns > 1 then
        -- If standard columns would be too narrow, adjust proportionally
        standardColumnWidth = minStandardWidth
        
        -- If we can't fit everything, reduce target column width (but preserve minimum)
        if (standardColumnWidth * (visibleColumns - 1)) > remainingWidth then
            local minTargetWidth = 140 -- Minimum for target column
            local totalNeeded = (standardColumnWidth * (visibleColumns - 1))
            
            -- Check if we can reduce target column
            if totalNeeded <= (totalAvailableWidth - minTargetWidth) then
                fixedTargetWidth = totalAvailableWidth - totalNeeded
            else
                -- Last resort - proportionally reduce all columns
                local totalColumns = visibleColumns
                local widthPerColumn = math.floor(totalAvailableWidth / totalColumns)
                fixedTargetWidth = widthPerColumn
                standardColumnWidth = widthPerColumn
            end
        end
    end
    
    local xOffset = 20 -- Starting offset
    
    -- Process all visible columns (starting from column 3)
    for i = 3, numColumns do
        local displayIndex = i - 2  -- Adjust index (1 = target, 2 = first role, etc.)
        local cellWidth = (i == 3) and fixedTargetWidth or standardColumnWidth
        local cellData = data[i] or ""
        
        -- Create cell background (except for header row)
        local bg = nil
        if not isHeader then
            bg = self.mainFrame:CreateTexture(nil, "BACKGROUND", nil, 1)
            bg:SetPoint("TOPLEFT", xOffset, yOffset)
            bg:SetWidth(cellWidth)
            bg:SetHeight(14)
            
            -- Alternate background shading
            local isEven = (i / 2) == math.floor(i / 2)
            bg:SetVertexColor(0.1, 0.1, 0.1, isEven and 0.3 or 0.1)
        end
        
        -- Create cell text
        local cell = self.mainFrame:CreateFontString(nil, "OVERLAY", fontStyle)
        
        -- Prepare icon for this cell
        local iconTexture = nil
        
        -- Target column (column 3) - use raid target icon if available
        if i == 3 and not isHeader and data[2] and TWRA.ICONS[data[2]] then
            iconTexture = self.mainFrame:CreateTexture(nil, "OVERLAY")
            iconTexture:SetPoint("LEFT", bg or self.mainFrame, "LEFT", xOffset - 16, 0)
            iconTexture:SetWidth(12)
            iconTexture:SetHeight(12)
            local iconInfo = TWRA.ICONS[data[2]]
            iconTexture:SetTexture(iconInfo[1])
            iconTexture:SetTexCoord(iconInfo[2], iconInfo[3], iconInfo[4], iconInfo[5])
        elseif i > 3 and not isHeader then  -- Player columns - use class icon
            local isClassGroup = TWRA.CLASS_GROUP_NAMES[cellData] and true or false
            local className = isClassGroup and TWRA.CLASS_GROUP_NAMES[cellData] or nil
            local inRaid, online = TWRA:GetPlayerStatus(cellData)
            
            -- Add class icon for players or class groups
            if inRaid or isClassGroup or cellData == UnitName("player") then
                local classToUse = className
                if not isClassGroup then
                    if cellData == UnitName("player") then
                        -- Get actual player class
                        local _, playerClass = UnitClass("player")
                        classToUse = playerClass
                    elseif self.usingExampleData then
                        -- Get class directly from EXAMPLE_PLAYERS for example data
                        local classInfo = self.EXAMPLE_PLAYERS[cellData]
                        if classInfo then
                            -- Strip any |OFFLINE suffix to get just the class
                            classToUse = string.gsub(classInfo or "", "|OFFLINE", "")
                        end
                    else
                        -- Find player's class from raid roster
                        for j = 1, GetNumRaidMembers() do
                            local name, _, _, _, _, class = GetRaidRosterInfo(j)
                            if name == cellData then
                                classToUse = class
                                break
                            end
                        end
                    end
                end
                
                if classToUse then
                    iconTexture = self.mainFrame:CreateTexture(nil, "OVERLAY")
                    iconTexture:SetPoint("LEFT", bg, "LEFT", 4, 0)
                    iconTexture:SetWidth(12)
                    iconTexture:SetHeight(12)
                    iconTexture:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
                    
                    local coords = TWRA.CLASS_COORDS[string.upper(classToUse)]
                    if coords then
                        iconTexture:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
                    end
                end
            end
        end
        
        -- Position text with consistent padding - ALWAYS reserve space for an icon
        -- No matter if there's an icon or not, provide consistent indentation
        local iconSpace = 18  -- Consistent space for all potential icons
        cell:SetPoint("TOPLEFT", xOffset + iconSpace, yOffset)
        cell:SetWidth(cellWidth - iconSpace - 4)
        cell:SetText(cellData)
        cell:SetJustifyH("LEFT")
        
        -- Set text color based on type and status
        if isHeader then
            -- Headers always white for visibility
            cell:SetTextColor(1, 1, 1)
        elseif i == 3 then
            -- Target column always white
            cell:SetTextColor(1, 1, 1)
        else
            -- Player/role columns - color by status
            if not cellData or cellData == "" then
                cell:SetTextColor(1, 1, 1)  -- Empty cells are white
            else
                -- Get player status for this cell
                local inRaid, online = TWRA:GetPlayerStatus(cellData)
                
                -- Handle class groups differently
                local isClassGroup = TWRA.CLASS_GROUP_NAMES and TWRA.CLASS_GROUP_NAMES[cellData] and true or false
                if isClassGroup then
                    -- For class groups, use the class color directly
                    local className = TWRA.CLASS_GROUP_NAMES[cellData]
                    local color = TWRA.VANILLA_CLASS_COLORS[className]
                    if color then
                        cell:SetTextColor(color.r, color.g, color.b)
                    else
                        cell:SetTextColor(1, 1, 1)  -- Fallback to white
                    end
                else
                    -- Use the proper class coloring for player names
                    local classToUse = nil
                    
                    -- First check if it's the current player
                    if cellData == UnitName("player") then
                        local _, playerClass = UnitClass("player")
                        classToUse = playerClass
                    elseif self.usingExampleData then
                        -- Extract class from EXAMPLE_PLAYERS for example data
                        local classInfo = self.EXAMPLE_PLAYERS[cellData]
                        if classInfo then
                            classToUse = string.gsub(classInfo or "", "|OFFLINE", "")
                        end
                    else
                        -- Find player's class from raid roster
                        for j = 1, GetNumRaidMembers() do
                            local name, _, _, _, _, class = GetRaidRosterInfo(j)
                            if name == cellData then
                                classToUse = class
                                break
                            end
                        end
                    end
                    
                    -- Now call ApplyClassColoring with complete information
                    TWRA.UI:ApplyClassColoring(cell, cellData, classToUse, inRaid, online)
                end
            end
        end
        
        -- Store cell references
        rowFrames[displayIndex] = {text = cell, bg = bg, icon = iconTexture}
        
        -- Update offset for next column
        xOffset = xOffset + cellWidth
    end
    
    return rowFrames
end

-- Add this function to handle footer creation:

-- Creates and displays footer elements for Notes and Warnings
function TWRA:CreateFooters(currentHandler)
    -- Clear any existing footers
    self:ClearFooters()
    
    -- Find Notes and Warnings for the current handler
    local notes = {}
    local warnings = {}
    
    -- Collect all notes and warnings for this handler
    for i = 1, table.getn(self.fullData) do
        if i > 1 and self.fullData[i-1][1] == currentHandler then
            -- Skip GUID rows entirely
            if self.fullData[i][2] ~= "GUID" then
                if self.fullData[i][2] == "Note" and self.fullData[i][3] and self.fullData[i][3] ~= "" then
                    table.insert(notes, {
                        text = self.fullData[i][3],
                        icon = self.fullData[i][2]
                    })
                elseif self.fullData[i][2] == "Warning" and self.fullData[i][3] and self.fullData[i][3] ~= "" then
                    table.insert(warnings, {
                        text = self.fullData[i][3],
                        icon = self.fullData[i][2]
                    })
                end
            end
        end
    end
    
    -- If no notes or warnings, just return
    if table.getn(notes) == 0 and table.getn(warnings) == 0 then
        return
    end
    
    -- Initialize footer storage if needed
    if not self.footers then
        self.footers = {}
    end
    
    -- Calculate positions and dimensions
    local footerHeight = 28  -- Increased height for each footer element
    local yOffset = -(40 + (table.getn(self.rowFrames) * 20) + 25)  -- Start below the last row with padding
    
    -- Create separator line
    local separator = self.mainFrame:CreateTexture(nil, "BACKGROUND")
    separator:SetTexture(0.3, 0.3, 0.3, 1)
    separator:SetHeight(1)
    separator:SetPoint("TOPLEFT", self.mainFrame, "TOPLEFT", 20, yOffset)
    separator:SetPoint("TOPRIGHT", self.mainFrame, "TOPRIGHT", -20, yOffset)
    table.insert(self.footers, {texture = separator})
    
    -- Adjust starting position for first footer
    yOffset = yOffset - 5
    
    -- First create warnings (more important)
    for i = 1, table.getn(warnings) do
        local warning = warnings[i]
        local footer = self:CreateFooterElement(warning.text, warning.icon, "Warning", yOffset)
        table.insert(self.footers, footer)
        yOffset = yOffset - footerHeight
    end
    
    -- Then create notes
    for i = 1, table.getn(notes) do
        local note = notes[i]
        local footer = self:CreateFooterElement(note.text, note.icon, "Note", yOffset)
        table.insert(self.footers, footer)
        yOffset = yOffset - footerHeight
    end
    
    -- Extend frame height if needed to fit footers
    local totalHeight = 40 +                                    -- Initial offset
                        (table.getn(self.rowFrames) * 20) +     -- Data rows
                        25 +                                     -- Padding before separator
                        1 +                                      -- Separator line
                        5 +                                      -- Padding after separator
                        ((table.getn(notes) + table.getn(warnings)) * footerHeight) + -- Footer elements
                        10                                       -- Bottom padding

    if totalHeight > 300 then  -- 300 is the default frame height
        self.mainFrame:SetHeight(totalHeight)
    end
end

-- Creates a single footer element (Note or Warning)
function TWRA:CreateFooterElement(text, iconName, footerType, yOffset)
    local footer = {}
    
    -- Create background
    local bg = self.mainFrame:CreateTexture(nil, "BACKGROUND")
    if footerType == "Warning" then
        bg:SetTexture(0.3, 0.1, 0.1, 0.15)  -- Subtle red for warnings
    else
        bg:SetTexture(0.1, 0.1, 0.3, 0.15)  -- Subtle blue for notes
    end
    bg:SetPoint("TOPLEFT", self.mainFrame, "TOPLEFT", 20, yOffset)
    bg:SetPoint("TOPRIGHT", self.mainFrame, "TOPRIGHT", -20, yOffset)
    bg:SetHeight(26)  -- Larger background height
    
    -- Create icon
    local icon = nil
    if iconName and TWRA.ICONS[iconName] then
        icon = self.mainFrame:CreateTexture(nil, "OVERLAY")
        icon:SetPoint("TOPLEFT", bg, "TOPLEFT", 6, -5)  -- Lower position by 1px
        icon:SetWidth(18)  -- Larger icon width
        icon:SetHeight(18)  -- Larger icon height
        local iconInfo = TWRA.ICONS[iconName]
        icon:SetTexture(iconInfo[1])
        icon:SetTexCoord(iconInfo[2], iconInfo[3], iconInfo[4], iconInfo[5])
    end
    
    -- FIXED: Check if text already contains an item link before processing
    -- Process text to replace item names with proper links
    local processedText
    if string.find(text, "|Hitem:") then
        -- Text already contains item links, don't process further
        processedText = text
    else
        processedText = TWRA.Items and TWRA.Items.ProcessText and TWRA.Items:ProcessText(text) or text
    end
    
    -- Create text
    local textElement = self.mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    textElement:SetPoint("TOPLEFT", bg, "TOPLEFT", icon and 32 or 10, -6)  -- More space for larger icon
    textElement:SetPoint("TOPRIGHT", bg, "TOPRIGHT", -10, -4)
    textElement:SetText(processedText)
    textElement:SetJustifyH("LEFT")
    
    -- Set text color based on type
    if footerType == "Warning" then
        textElement:SetTextColor(1, 1, 1)  -- White text for warnings
    else
        textElement:SetTextColor(0.85, 0.85, 1)  -- Light blue for notes
    end
    
    -- Create a clickable overlay for the entire footer element
    local clickFrame = CreateFrame("Button", nil, self.mainFrame)
    clickFrame:SetAllPoints(bg)
    clickFrame:EnableMouse(true)
    
    -- Setup mouseover highlighting
    clickFrame:SetScript("OnEnter", function()
        -- Highlight on mouseover
        if footerType == "Warning" then
            bg:SetTexture(0.5, 0.1, 0.1, 0.25)  -- Brighter red for warnings
        else
            bg:SetTexture(0.1, 0.1, 0.5, 0.25)  -- Brighter blue for notes
        end
        
        -- Add tooltip to show it's clickable
        GameTooltip:SetOwner(clickFrame, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Click to announce to raid")
        GameTooltip:Show()
    end)
    
    clickFrame:SetScript("OnLeave", function()
        -- Restore normal color
        if footerType == "Warning" then
            bg:SetTexture(0.3, 0.1, 0.1, 0.15)  -- Normal red for warnings
        else
            bg:SetTexture(0.1, 0.1, 0.3, 0.15)  -- Normal blue for notes
        end
        
        -- Hide tooltip
        GameTooltip:Hide()
    end)
    
    -- Add the click handler to send to chat
    clickFrame:SetScript("OnClick", function()
        -- Determine which channels to use based on options
        local messageChannel = "RAID"  -- Default
        local channelNumber = nil
        
        -- Get saved channel preference from options
        local selectedChannel = TWRA_SavedVariables.options and 
                              TWRA_SavedVariables.options.announceChannel or 
                              "GROUP"
        
        -- For warnings, use raid warning if player has assist/leader and using GROUP channel
        local isWarning = (footerType == "Warning")
        local isOfficer = IsRaidLeader() or IsRaidOfficer()
        
        -- Adjust channels based on selection and current group context
        if selectedChannel == "GROUP" then
            if GetNumRaidMembers() > 0 then
                -- In a raid, use raid warning for warnings if player has permission
                if isWarning and isOfficer then
                    messageChannel = "RAID_WARNING"
                else
                    messageChannel = "RAID"
                end
            elseif GetNumPartyMembers() > 0 then
                messageChannel = "PARTY"
            else
                messageChannel = "SAY"
            end
        elseif selectedChannel == "CHANNEL" then
            -- Get custom channel name
            local customChannel = TWRA_SavedVariables.options and TWRA_SavedVariables.options.customChannel
            if customChannel and customChannel ~= "" then
                -- Find the channel number
                channelNumber = GetChannelName(customChannel)
                if channelNumber > 0 then
                    messageChannel = "CHANNEL"
                else
                    -- No channel found, fall back to say
                    messageChannel = "SAY"
                    self:Debug("ui", "Channel '" .. customChannel .. "' not found, using Say instead")
                end
            else
                -- No custom channel specified, fall back to say
                messageChannel = "SAY"
                self:Debug("ui", "No custom channel specified, using Say instead")
            end
        end
        
        -- FIXED: Remove prepending of prefixes. We don't want any prefix anymore.
        local announceText = text
        
        -- FIXED: Check if the text already contains an item link
        if not string.find(announceText, "|Hitem:") and TWRA.Items and TWRA.Items.ProcessText then
            announceText = TWRA.Items:ProcessText(announceText)
        end
        
        -- Send the message to the appropriate channel
        if messageChannel == "CHANNEL" then
            SendChatMessage(announceText, messageChannel, nil, channelNumber)
        else
            SendChatMessage(announceText, messageChannel)
        end
        
        -- Visual feedback for click
        if footerType == "Warning" then
            bg:SetTexture(0.7, 0.1, 0.1, 0.3)  -- Very bright red flash
        else
            bg:SetTexture(0.1, 0.1, 0.7, 0.3)  -- Very bright blue flash
        end
        
        -- Use our custom timer system for the visual feedback
        self:ScheduleTimer(function()
            if footerType == "Warning" then
                bg:SetTexture(0.3, 0.1, 0.1, 0.15)  -- Back to normal
            else
                bg:SetTexture(0.1, 0.1, 0.3, 0.15)  -- Back to normal
            end
        end, 0.2)
    end)
    
    -- Store all elements in the footer object
    footer.bg = bg
    footer.icon = icon
    footer.text = textElement
    footer.type = footerType
    footer.clickFrame = clickFrame
    
    return footer
end

-- Clears all footer elements
function TWRA:ClearFooters()
    if not self.footers then
        self.footers = {}
        return
    end
    
    for _, footer in pairs(self.footers) do
        -- Special handling for separator which only has a texture
        if footer.texture then
            footer.texture:Hide()
            footer.texture:SetParent(nil)
        else
            -- Normal footer with multiple elements
            if footer.bg then
                footer.bg:Hide()
                footer.bg:SetParent(nil)
            end
            if footer.icon then
                footer.icon:Hide()
                footer.icon:SetParent(nil)
            end
            if footer.text then
                footer.text:Hide()
                footer.text:SetParent(nil)
            end
            -- Also handle the clickable overlay
            if footer.clickFrame then
                footer.clickFrame:Hide()
                footer.clickFrame:EnableMouse(false)
                footer.clickFrame:SetParent(nil)
            end
        end
    end
    
    self.footers = {}
    
    -- Reset frame height to default if no footers
    self.mainFrame:SetHeight(300)
end

-- Add after other UI functions
function TWRA:DisplayCurrentSection()
    -- If we're in options view, don't try to display sections
    if self.currentView == "options" then
        TWRA:Debug("ui", "Skipping display update while in options view")
        return
    end
    
    -- Make sure we have navigation
    if not self.navigation or not self.navigation.currentIndex or not self.navigation.handlers then
        TWRA:Debug("error", "Can't display section - navigation not initialized")
        return
    end
    
    -- Get current handler from navigation
    local currentHandler = self.navigation.handlers[self.navigation.currentIndex]
    if not currentHandler then
        TWRA:Debug("error", "Can't display section - invalid current index")
        return
    end
    
    -- Call the actual display function
    self:FilterAndDisplayHandler(currentHandler)
end

-- Modify the GetPlayerRelevantRows function to work with example data
function TWRA:GetPlayerRelevantRows(sectionData)
    if not sectionData then return {} end
    
    local relevantRows = {}
    local playerName = UnitName("player")
    local _, playerClass = UnitClass("player")
    
    -- Check each row
    for rowIndex = 1, table.getn(sectionData) do
        -- Skip the header row
        if rowIndex > 1 then
            local row = sectionData[rowIndex]
            local isRelevantRow = false
            
            -- Check each column except section name and icon
            for colIndex = 3, table.getn(row) do
                local cellValue = row[colIndex]
                -- Check if the cell contains player name
                if cellValue == playerName then
                    isRelevantRow = true
                    break
                end
                
                -- Check if the cell is a class group matching player's class
                local className = TWRA.CLASS_GROUP_NAMES and TWRA.CLASS_GROUP_NAMES[cellValue]
                if className and className == playerClass then
                    isRelevantRow = true
                    break
                end
                
                -- Check for group assignments like "Group 1,2"
                if string.find(cellValue, "Group") then
                    -- Extract group numbers
                    local groupNums = {}
                    for groupNum in string.gmatch(cellValue, "%d+") do
                        groupNums[tonumber(groupNum)] = true
                    end
                    
                    -- Check if player is in any of these groups
                    local playerGroup = 0
                    for i = 1, GetNumRaidMembers() do
                        local name, _, subgroup = GetRaidRosterInfo(i)
                        if name == playerName then
                            playerGroup = subgroup
                            break
                        end
                    end
                    if playerGroup > 0 and groupNums[playerGroup] then
                        isRelevantRow = true
                        break
                    end
                end
            end
            
            -- If row is relevant, add to our list
            if isRelevantRow then
                table.insert(relevantRows, rowIndex)
            end
        end
    end
    
    return relevantRows
end

-- AutoMarker toggle (only shown if SuperWoW is available)
if SUPERWOW_VERSION ~= nil then
    -- Create checkbox for AutoMarker
    local autoNavigateCheckbox = CreateFrame("CheckButton", "TWRA_AutoMarkerCheckbox", optionsFrame, "UICheckButtonTemplate")
    autoNavigateCheckbox:SetPoint("TOPLEFT", lastElement, "BOTTOMLEFT", 0, -10)
    autoNavigateCheckbox:SetChecked(TWRA.AUTONAVIGATE.enabled)
    
    -- Set label
    getglobal(autoNavigateCheckbox:GetName() .. "Text"):SetText("Enable AutoMarker (SuperWoW)")
    autoNavigateCheckbox.tooltipText = "Automatically switch sections when raid markers are placed on mobs with matching GUIDs"
    
    -- Set OnClick handler
    autoNavigateCheckbox:SetScript("OnClick", function()
        TWRA:ToggleAutoMarker()
        this:SetChecked(TWRA.AUTONAVIGATE.enabled)
    end)
    
    -- Update last element reference for positioning
    lastElement = autoNavigateCheckbox
    
    -- Add debug checkbox for development
    if isGM then  -- Only show to GMs or add a debug mode toggle elsewhere
        local debugCheckbox = CreateFrame("CheckButton", "TWRA_AutoMarkerDebugCheckbox", optionsFrame, "UICheckButtonTemplate")
        debugCheckbox:SetPoint("TOPLEFT", lastElement, "BOTTOMLEFT", 20, -5)
        debugCheckbox:SetChecked(TWRA.AUTONAVIGATE.debug)
        
        getglobal(debugCheckbox:GetName() .. "Text"):SetText("Debug mode")
        debugCheckbox.tooltipText = "Show debug messages for AutoMarker"
        
        debugCheckbox:SetScript("OnClick", function() 
            TWRA.AUTONAVIGATE.debug = not TWRA.AUTONAVIGATE.debug
            this:SetChecked(TWRA.AUTONAVIGATE.debug)
        end)
        
        lastElement = debugCheckbox
    end
end