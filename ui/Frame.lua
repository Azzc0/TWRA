TWRA = TWRA or {}

-- Store original functions
TWRA.originalFunctions = {}

-- Check if we're dealing with example data
function TWRA:IsExampleData(data)
    return data == self.EXAMPLE_DATA
end

-- Enhanced GetPlayerStatus function to handle example data with better debugging
function TWRA:GetPlayerStatus(name)
    -- Safety check
    if not name or name == "" then 
        return false, nil 
    end
    
    -- Debug mode - enable this to see all GetPlayerStatus calls
    local debugMe = false
    
    -- Check if this is the current player
    if UnitName("player") == name then 
        return true, true 
    end
    
    -- Check if we're using example data
    if self.usingExampleData and self.EXAMPLE_PLAYERS then
        -- Get the player class directly from EXAMPLE_PLAYERS
        local classInfo = self.EXAMPLE_PLAYERS[name]
        
        -- If the player is in our example data
        if classInfo then
            -- Check if the player is marked as offline (has |OFFLINE suffix)
            local isOffline = string.find(classInfo, "|OFFLINE")
            
            if debugMe then
                DEFAULT_CHAT_FRAME:AddMessage("GetPlayerStatus (example): " .. name .. 
                                           " classInfo=" .. tostring(classInfo) .. 
                                           " offline=" .. tostring(isOffline ~= nil))
            end
            
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
    if GetNumRaidMembers() > 0 then
        for i = 1, GetNumRaidMembers() do
            local raidName, _, _, _, _, _, _, online = GetRaidRosterInfo(i)
            if raidName == name then
                return true, (online ~= 0)
            end
        end
    end
    
    -- Check party if not in raid
    if GetNumRaidMembers() == 0 and GetNumPartyMembers() > 0 then
        for i = 1, GetNumPartyMembers() do
            if UnitName("party"..i) == name then
                return true, UnitIsConnected("party"..i)
            end
        end
    end
    
    -- Not found
    if debugMe then
        DEFAULT_CHAT_FRAME:AddMessage("GetPlayerStatus: " .. name .. " - not found")
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
    
    -- Create highlight pool for row highlighting
    self.highlightPool = {}
    local POOL_SIZE = 15  -- Maximum number of highlighted rows we expect
    
    for i = 1, POOL_SIZE do
        local highlight = self.mainFrame:CreateTexture(nil, "BACKGROUND", nil, -2)
        highlight:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-Skills-Bar", "REPEAT", "REPEAT")
        highlight:SetTexCoord(0.05, 0.95, 0.1, 0.9)
        highlight:SetBlendMode("ADD")
        highlight:SetVertexColor(1, 1, 0.5, 0.2)  -- Yellowish highlight
        highlight:Hide()  -- Hidden by default
        table.insert(self.highlightPool, highlight)
    end
    
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

    -- After creating all UI elements, rebuild navigation but don't display content yet
    if TWRA_SavedVariables.assignments and TWRA_SavedVariables.assignments.data then
        -- Check if we're using the new data format
        local isNewFormat = false
        if type(TWRA_SavedVariables.assignments.data) == "table" then
            for idx, section in pairs(TWRA_SavedVariables.assignments.data) do
                if type(section) == "table" and section["Section Name"] then
                    isNewFormat = true
                    break
                end
            end
        end
        
        if isNewFormat then
            -- For new format, use RebuildNavigation to get handlers
            self:Debug("ui", "Main frame detected new data format, rebuilding navigation")
            self:RebuildNavigation()
            
            -- Set example data flag properly
            self.usingExampleData = TWRA_SavedVariables.assignments.usingExampleData or
                                    TWRA_SavedVariables.assignments.isExample or false
            
            -- Restore saved section index or name for later use (but don't display yet)
            if TWRA_SavedVariables.assignments.currentSectionName and self.navigation.handlers then
                local found = false
                for i, name in ipairs(self.navigation.handlers) do
                    if name == TWRA_SavedVariables.assignments.currentSectionName then
                        self.navigation.currentIndex = i
                        found = true
                        self:Debug("nav", "Main frame stored section by name: " .. name)
                        break
                    end
                end
                
                -- If not found by name, try by index
                if not found and TWRA_SavedVariables.assignments.currentSection then
                    local index = TWRA_SavedVariables.assignments.currentSection
                    if self.navigation.handlers and index <= table.getn(self.navigation.handlers) then
                        self.navigation.currentIndex = index
                        self:Debug("nav", "Main frame stored section by index: " .. index)
                    else
                        self.navigation.currentIndex = 1
                        self:Debug("nav", "Main frame using default section index: 1")
                    end
                end
            end
        else
            -- Legacy format handling (unchanged but no content display)
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
        end
        
        -- Update menu button text, but don't load or display content yet
        if self.navigation.handlerText and self.navigation.handlers and 
           self.navigation.currentIndex and self.navigation.handlers[self.navigation.currentIndex] then
            self.navigation.handlerText:SetText(self.navigation.handlers[self.navigation.currentIndex])
        end
    end

    self:Debug("ui", "Main frame created - content will load when shown")
    return self.mainFrame
end

-- Add a function to load initial content when the frame is first shown
function TWRA:LoadInitialContent()
    self:Debug("ui", "LoadInitialContent called")
    
    -- Make sure we have navigation data
    if not self.navigation or not self.navigation.handlers or table.getn(self.navigation.handlers) == 0 then
        self:Debug("error", "LoadInitialContent: No navigation handlers available")
        return false
    end
    
    -- Ensure we have a valid current index
    if not self.navigation.currentIndex or 
       self.navigation.currentIndex < 1 or 
       self.navigation.currentIndex > table.getn(self.navigation.handlers) then
        self:Debug("ui", "LoadInitialContent: Invalid index, resetting to 1")
        self.navigation.currentIndex = 1
    end
    
    local currentSection = self.navigation.handlers[self.navigation.currentIndex]
    if not currentSection then
        self:Debug("error", "LoadInitialContent: No section found at index " .. self.navigation.currentIndex)
        return false
    end
    
    self:Debug("ui", "LoadInitialContent: Loading section: " .. currentSection)
    
    -- Clear any existing content first to prevent duplication
    self:ClearRows()
    self:ClearFooters()
    
    -- Update UI elements
    if self.navigation.handlerText then
        self.navigation.handlerText:SetText(currentSection)
    end
    
    if self.navigation.menuButton and self.navigation.menuButton.text then
        self.navigation.menuButton.text:SetText(currentSection)
    end
    
    -- Use FilterAndDisplayHandler to load content (same as navigation would)
    self:FilterAndDisplayHandler(currentSection)
    
    self:Debug("ui", "LoadInitialContent complete")
    return true
end

-- Modify ShowMainView to ensure content is displayed properly when switching from options
function TWRA:ShowMainView()
    -- Set view state first
    self.currentView = "main"
    
    -- Hide options UI elements if they exist
    if self.optionsElements then
        for _, element in pairs(self.optionsElements) do
            if element.Hide then
                element:Hide()
            end
        end
    end
    
    -- Show navigation elements if they exist
    if self.navigation then
        if self.navigation.prevButton then self.navigation.prevButton:Show() end
        if self.navigation.nextButton then self.navigation.nextButton:Show() end
        if self.navigation.menuButton then self.navigation.menuButton:Show() end
        if self.navigation.handlerText then self.navigation.handlerText:Show() end
        if self.navigation.dropdown and self.navigation.dropdown.container then
            self.navigation.dropdown.container:Show()
        end
    end
    
    -- Show other main view buttons
    if self.announceButton then self.announceButton:Show() end
    if self.updateTanksButton then self.updateTanksButton:Show() end

    -- Change button text if options button exists
    if self.optionsButton then
        self.optionsButton:SetText("Options")
    end
    
    -- Debug the state before displaying content
    self:Debug("ui", "ShowMainView: About to display content. CurrentIndex: " .. 
        (self.navigation and self.navigation.currentIndex or "nil") .. 
        ", handlers count: " .. (self.navigation and self.navigation.handlers and table.getn(self.navigation.handlers) or "nil"))
    
    -- Clear any elements that might remain from options view
    self:ClearRows()
    self:ClearFooters()
    
    -- Make sure we have a current section to display
    if self.navigation and self.navigation.handlers and table.getn(self.navigation.handlers) > 0 then
        if not self.navigation.currentIndex or self.navigation.currentIndex < 1 or 
           self.navigation.currentIndex > table.getn(self.navigation.handlers) then
            self.navigation.currentIndex = 1
        end
        
        -- Update navigation text first
        if self.navigation.handlerText then
            local sectionName = self.navigation.handlers[self.navigation.currentIndex]
            self.navigation.handlerText:SetText(sectionName)
            self:Debug("ui", "Updated handlerText to: " .. sectionName)
        end
        
        -- Display current section directly using FilterAndDisplayHandler instead of DisplayCurrentSection
        -- This ensures we rebuild the content directly rather than depending on possible hooks
        local currentHandler = self.navigation.handlers[self.navigation.currentIndex]
        if currentHandler then
            self:Debug("ui", "Directly calling FilterAndDisplayHandler for section: " .. currentHandler)
            self:FilterAndDisplayHandler(currentHandler)
        end
    else
        self:Debug("error", "No handlers available to display in ShowMainView")
    end
    
    self:Debug("ui", "Switched to main view - final currentView = " .. self.currentView)
end

-- Helper function for handler management
local function getUniqueHandlers(data)
    local handlers = {}
    local seen = {}
    
    if not data then return handlers end
    
    -- In new format, we shouldn't have to skip a header row
    for i = 1, table.getn(data) do  -- Process all rows
        if data[i][1] and not seen[data[i][1]] then
            -- Skip special rows with empty targets or note/warning/guid types
            if data[i][1] ~= "" and data[i][1] ~= "Warning" and data[i][1] ~= "Note" and data[i][1] ~= "GUID" then
                seen[data[i][1]] = true
                table.insert(handlers, data[i][1])
            end
        end
    end
    return handlers
end

-- Replace FilterAndDisplayHandler to work with the new format
function TWRA:FilterAndDisplayHandler(currentHandler)
    -- Debug entry
    self:Debug("ui", "FilterAndDisplayHandler called for section: " .. (currentHandler or "nil"))
    
    -- Get the current section data based on the handler name
    local sectionData = nil
    if TWRA_SavedVariables and TWRA_SavedVariables.assignments and 
       TWRA_SavedVariables.assignments.data then
        for _, section in pairs(TWRA_SavedVariables.assignments.data) do
            if section["Section Name"] == currentHandler then
                sectionData = section
                break
            end
        end
    end
    
    if not sectionData then
        self:Debug("error", "No section data found for handler: " .. (currentHandler or "nil"))
        return
    end
    
    -- Create filtered data structure
    local filteredData = {}
    
    -- Process header from Section Header
    if sectionData["Section Header"] then
        table.insert(filteredData, sectionData["Section Header"])
        
        -- Determine max columns from header
        self.headerColumns = table.getn(sectionData["Section Header"])
        self:Debug("ui", "Got header with " .. self.headerColumns .. " columns")
    else
        self:Debug("error", "No header found in section data")
        return
    end
    
    -- Process rows, skipping special rows in new format
    if sectionData["Section Rows"] then
        for i, rowData in ipairs(sectionData["Section Rows"]) do
            -- Skip special rows (Note, Warning, GUID rows)
            if rowData[1] ~= "Note" and rowData[1] ~= "Warning" and rowData[1] ~= "GUID" then
                -- Insert the row into our filtered data
                table.insert(filteredData, rowData)
                self:Debug("ui", "Added row with icon: " .. tostring(rowData[1]) .. ", target: " .. tostring(rowData[2]))
            end
        end
    else
        self:Debug("error", "No rows found in section data")
        return
    end
    
    -- Clear existing content
    self:ClearRows()
    
    -- Create new rows
    self:Debug("ui", "Creating " .. table.getn(filteredData) .. " rows from filtered data")
    self:CreateRows(filteredData, true)
    
    -- Apply highlights based on section player info
    self:ApplyRowHighlights(sectionData, filteredData)
    
    -- Create footers for this section (notes and warnings)
    self:CreateFootersNewFormat(currentHandler, sectionData)
    
    self:Debug("ui", "DisplayCurrentSection complete - displayed " .. table.getn(filteredData) .. " rows")
end

-- Add function to create footers from the new format
function TWRA:CreateFootersNewFormat(currentHandler, sectionData)
    -- Clear any existing footers
    self:ClearFooters()
    
    -- Skip if no section data
    if not sectionData then 
        self:Debug("ui", "No section data for footers")
        return 
    end
    
    -- Find Notes and Warnings in the section data
    local notes = {}
    local warnings = {}
    
    -- Process special rows from Section Rows with better debugging
    if sectionData["Section Rows"] then
        self:Debug("ui", "Scanning " .. table.getn(sectionData["Section Rows"]) .. " rows for notes/warnings")
        
        for i, rowData in ipairs(sectionData["Section Rows"]) do
            -- More detailed debugging
            self:Debug("ui", "Row " .. i .. " check: [1]=" .. tostring(rowData[1]) .. 
                       ", [2]=" .. tostring(rowData[2] or "nil"))
            
            -- Note rows have "Note" in first column and text in second column
            if rowData[1] == "Note" then
                if rowData[2] and rowData[2] ~= "" then
                    table.insert(notes, {
                        text = rowData[2],  -- Text is in column 2
                        icon = "Note"
                    })
                    self:Debug("ui", "Found note: " .. rowData[2])
                end
            -- Warning rows have "Warning" in first column and text in second column
            elseif rowData[1] == "Warning" then
                if rowData[2] and rowData[2] ~= "" then
                    table.insert(warnings, {
                        text = rowData[2],  -- Text is in column 2
                        icon = "Warning"
                    })
                    self:Debug("ui", "Found warning: " .. rowData[2])
                end
            end
        end
    else
        self:Debug("ui", "No Section Rows found for footers")
    end
    
    -- Debug the counts we found
    self:Debug("ui", "Found: " .. table.getn(warnings) .. " warnings and " .. table.getn(notes) .. " notes")
    
    -- If no notes or warnings, just return
    if table.getn(notes) == 0 and table.getn(warnings) == 0 then
        self:Debug("ui", "No notes or warnings found")
        return
    end
    
    self:Debug("ui", "Creating footers: " .. table.getn(warnings) .. " warnings, " .. table.getn(notes) .. " notes")
    
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
    local totalHeight = 40 +                                   -- Initial offset
                      (table.getn(self.rowFrames) * 20) +     -- Data rows
                      25 +                                     -- Padding before separator
                      1 +                                      -- Separator line
                      5 +                                      -- Padding after separator
                      ((table.getn(notes) + table.getn(warnings)) * footerHeight) + -- Footer elements
                      10                                       -- Bottom padding

    if totalHeight > 300 then  -- 300 is the default frame height
        self.mainFrame:SetHeight(totalHeight)
        self:Debug("ui", "Adjusted frame height to " .. totalHeight)
    end
end

-- Clears all footer elements properly
function TWRA:ClearFooters()
    self:Debug("ui", "Clearing footers")
    
    if not self.footers then
        self.footers = {}
        return
    end
    
    for i, footer in pairs(self.footers) do
        -- Special handling for separator which only has a texture
        if footer.texture then
            footer.texture:Hide()
            footer.texture:SetParent(nil)
            footer.texture = nil
        else
            -- Normal footer with multiple elements
            if footer.bg then
                footer.bg:Hide()
                footer.bg:SetParent(nil)
                footer.bg = nil
            end
            if footer.icon then
                footer.icon:Hide()
                footer.icon:SetParent(nil)
                footer.icon = nil
            end
            if footer.text then
                footer.text:Hide()
                footer.text:SetParent(nil)
                footer.text = nil
            end
            -- Also handle the clickable overlay
            if footer.clickFrame then
                footer.clickFrame:Hide()
                footer.clickFrame:EnableMouse(false)
                footer.clickFrame:SetParent(nil)
                footer.clickFrame = nil
            end
        end
        self.footers[i] = nil
    end
    
    self.footers = {}
    
    -- Reset frame height to default
    if self.mainFrame then
        self.mainFrame:SetHeight(300)
    end
end

-- Make sure CreateFooterElement creates visible elements
function TWRA:CreateFooterElement(text, iconName, footerType, yOffset)
    self:Debug("ui", "Creating footer element: " .. footerType .. " at y=" .. yOffset)
    
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
    
    -- Create icon - use footerType directly instead of iconName
    local icon = nil
    local iconToUse = footerType  -- Use Warning or Note directly
    
    if TWRA.ICONS and TWRA.ICONS[iconToUse] then
        icon = self.mainFrame:CreateTexture(nil, "OVERLAY")
        icon:SetPoint("TOPLEFT", bg, "TOPLEFT", 6, -5)
        icon:SetWidth(18)
        icon:SetHeight(18)
        local iconInfo = TWRA.ICONS[iconToUse]
        icon:SetTexture(iconInfo[1])
        icon:SetTexCoord(iconInfo[2], iconInfo[3], iconInfo[4], iconInfo[5])
    end
    
    -- Create text (don't process with Items module yet to avoid nil errors)
    local textElement = self.mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    textElement:SetPoint("TOPLEFT", bg, "TOPLEFT", icon and 32 or 10, -6)  -- More space for larger icon
    textElement:SetPoint("TOPRIGHT", bg, "TOPRIGHT", -10, -4)
    textElement:SetText(text)
    textElement:SetJustifyH("LEFT")
    
    -- Set text color based on type
    if footerType == "Warning" then
        textElement:SetTextColor(1, 0.7, 0.7)  -- Light red for warnings
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
        -- Call the announce function with the footer text
        self:Debug("ui", "Announcing footer: " .. text)
        SendChatMessage(text, "RAID")
        
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

-- Add frame creation logic to convert from 0/1 to boolean
function TWRA:ConvertOptionValues()
    -- Ensure options exist
    if not TWRA_SavedVariables.options then
        TWRA_SavedVariables.options = {}
    end
    
    -- Convert any 0/1 values to proper booleans
    local optionsToConvert = {
        "hideFrameByDefault", "lockFramePosition", "autoNavigate", 
        "liveSync", "tankSync"
    }
    
    for _, option in ipairs(optionsToConvert) do
        if TWRA_SavedVariables.options[option] ~= nil then
            if type(TWRA_SavedVariables.options[option]) == "number" then
                -- Convert 0/1 to boolean
                TWRA_SavedVariables.options[option] = (TWRA_SavedVariables.options[option] == 1)
            end
        end
    end
    
    -- Also check OSD options
    if TWRA_SavedVariables.options.osd then
        local osdOptions = {"locked", "enabled", "showOnNavigation"}
        for _, option in ipairs(osdOptions) do
            if TWRA_SavedVariables.options.osd[option] ~= nil then
                if type(TWRA_SavedVariables.options.osd[option]) == "number" then
                    -- Convert 0/1 to boolean
                    TWRA_SavedVariables.options.osd[option] = (TWRA_SavedVariables.options.osd[option] == 1)
                end
            end
        end
    end
end

-- Call this function during OnLoad to fix any 0/1 values
TWRA:ConvertOptionValues()

-- Update RefreshAssignmentTable to properly display content using FilterAndDisplayHandler
function TWRA:RefreshAssignmentTable()
    self:Debug("ui", "RefreshAssignmentTable called")
    
    -- Ensure we have navigation and handlers
    if not self.navigation or not self.navigation.handlers or 
       not self.navigation.currentIndex or table.getn(self.navigation.handlers) == 0 then
        self:Debug("error", "Cannot refresh - navigation data incomplete")
        return
    end
    
    -- Get current section name
    local currentSection = self.navigation.handlers[self.navigation.currentIndex]
    if not currentSection then
        self:Debug("error", "Cannot refresh - no current section found")
        return
    end
    
    -- Use FilterAndDisplayHandler for consistent display
    self:Debug("ui", "Refreshing assignment table to section: " .. currentSection)
    self:FilterAndDisplayHandler(currentSection)
end

-- Update CreateRow to remove highlighting
function TWRA:CreateRow(rowNum, data)
    local rowFrames = {}
    local yOffset = -40 - (rowNum * 20)
    local fontStyle = rowNum == 1 and "GameFontNormalLarge" or "GameFontNormal"
    local isHeader = rowNum == 1
    
    local numColumns = self.headerColumns or table.getn(data)
    
    -- Calculate total available width
    local totalAvailableWidth = self.mainFrame:GetWidth() - 40

    -- Adjust icon column width here - change this value to make the icon column wider/narrower
    local iconColumnWidth = 10  -- Reduced from 40px to 30px
    local targetColumnWidth = 170
    local remainingWidth = totalAvailableWidth - iconColumnWidth - targetColumnWidth
    local roleColumnsCount = numColumns - 2
    
    local roleColumnWidth = 100 -- Default minimum width
    if roleColumnsCount > 0 then
        roleColumnWidth = math.max(roleColumnWidth, math.floor(remainingWidth / roleColumnsCount))
    end
    
    -- If columns don't fit, adjust proportionally
    if iconColumnWidth + targetColumnWidth + (roleColumnWidth * roleColumnsCount) > totalAvailableWidth then
        local totalWidth = totalAvailableWidth
        iconColumnWidth = math.floor(totalWidth / (numColumns + 0.5)) -- Icon column is half-sized
        targetColumnWidth = math.floor(totalWidth / numColumns)
        roleColumnWidth = math.floor(totalWidth / numColumns)
    end
    
    local xOffset = 20 -- Starting offset
    
    -- Process all columns
    for i = 1, numColumns do
        local cellWidth = iconColumnWidth
        if i == 2 then
            cellWidth = targetColumnWidth
        elseif i > 2 then
            cellWidth = roleColumnWidth
        end
        
        local cellData = data[i] or ""
        
        -- Create cell background (except for header row)
        local bg = nil
        if not isHeader then
            bg = self.mainFrame:CreateTexture(nil, "BACKGROUND", nil, 1)
            bg:SetPoint("TOPLEFT", xOffset, yOffset)
            bg:SetWidth(cellWidth)
            bg:SetHeight(14)
            
            -- Alternate background shading
            local isEven = (math.floor(i / 2) * 2) == i -- Check if i is even
            bg:SetVertexColor(0.1, 0.1, 0.1, isEven and 0.3 or 0.1)
        end
        
        -- Create cell text
        local cell = self.mainFrame:CreateFontString(nil, "OVERLAY", fontStyle)
        
        -- Prepare icon for this cell
        local iconTexture = nil
        
        -- Special handling based on column type
        if i == 1 then
            -- Icon column - don't show text, only icon
            if isHeader then
                -- Hide the header text for the icon column
                cell:SetText("")
                cell:SetJustifyH("CENTER")
                cell:SetTextColor(1, 1, 1)
            else
                cell:SetText("") -- Don't show icon text
                
                -- Create icon texture if we have valid icon data
                if cellData and TWRA.ICONS and TWRA.ICONS[cellData] then
                    iconTexture = self.mainFrame:CreateTexture(nil, "OVERLAY")
                    iconTexture:SetPoint("CENTER", bg, "CENTER", 0, 0)
                    iconTexture:SetWidth(16)
                    iconTexture:SetHeight(16)
                    local iconInfo = TWRA.ICONS[cellData]
                    iconTexture:SetTexture(iconInfo[1])
                    iconTexture:SetTexCoord(iconInfo[2], iconInfo[3], iconInfo[4], iconInfo[5])
                end
            end
        elseif i == 2 then
            -- Target column
            cell:SetText(cellData)
            cell:SetTextColor(1, 1, 1) -- White text for target
        else
            -- Role/player columns
            cell:SetText(cellData)
            
            if isHeader then
                -- Header is white
                cell:SetTextColor(1, 1, 1)
            elseif cellData and cellData ~= "" then
                -- Color by player status or class group
                local isClassGroup = TWRA.CLASS_GROUP_NAMES and TWRA.CLASS_GROUP_NAMES[cellData]
                
                if isClassGroup then
                    -- Class group coloring
                    local color = TWRA.VANILLA_CLASS_COLORS[TWRA.CLASS_GROUP_NAMES[cellData]]
                    if color then
                        cell:SetTextColor(color.r, color.g, color.b)
                    else
                        cell:SetTextColor(1, 1, 1)
                    end
                    
                    -- Add class icon
                    iconTexture = self.mainFrame:CreateTexture(nil, "OVERLAY")
                    iconTexture:SetPoint("LEFT", bg, "LEFT", 4, 0)
                    iconTexture:SetWidth(12)
                    iconTexture:SetHeight(12)
                    iconTexture:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
                    
                    local coords = TWRA.CLASS_COORDS[string.upper(TWRA.CLASS_GROUP_NAMES[cellData])]
                    if coords then
                        iconTexture:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
                    end
                else
                    -- Player coloring
                    local inRaid, online = self:GetPlayerStatus(cellData)
                    local classToUse = nil
                    
                    -- Try to determine player class
                    if cellData == UnitName("player") then
                        local _, playerClass = UnitClass("player")
                        classToUse = playerClass
                    elseif self.usingExampleData and self.EXAMPLE_PLAYERS then
                        local classInfo = self.EXAMPLE_PLAYERS[cellData]
                        if classInfo then
                            classToUse = string.gsub(classInfo, "|OFFLINE", "")
                        end
                    elseif inRaid then
                        for j = 1, GetNumRaidMembers() do
                            local name, _, _, _, _, class = GetRaidRosterInfo(j)
                            if name == cellData then
                                classToUse = class
                                break
                            end
                        end
                    end
                    
                    -- Add class icon if we found a class
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
                    
                    -- Color text based on raid status
                    if TWRA.UI and TWRA.UI.ApplyClassColoring then
                        TWRA.UI:ApplyClassColoring(cell, cellData, classToUse, inRaid, online)
                    else
                        -- Fallback coloring
                        if inRaid and not online then
                            cell:SetTextColor(0.5, 0.5, 0.5) -- Gray for offline
                        elseif classToUse and TWRA.VANILLA_CLASS_COLORS and TWRA.VANILLA_CLASS_COLORS[string.upper(classToUse)] then
                            local color = TWRA.VANILLA_CLASS_COLORS[string.upper(classToUse)]
                            cell:SetTextColor(color.r, color.g, color.b)
                        else
                            cell:SetTextColor(1, 1, 1) -- White fallback
                        end
                    end
                end
            else
                -- Empty cell is white
                cell:SetTextColor(1, 1, 1)
            end
        end
        
        -- Position text with proper padding
        local iconPadding = 0
        if i == 1 then
            -- No padding for icon column when in header
            if isHeader then
                iconPadding = 0
            else
                -- Center the icon text
                iconPadding = 0
                cell:SetJustifyH("CENTER")
            end
        else
            -- Add space for potential class icons in other columns
            iconPadding = 18
            cell:SetJustifyH("LEFT")
        end
        
        cell:SetPoint("TOPLEFT", xOffset + iconPadding, yOffset)
        cell:SetWidth(cellWidth - iconPadding - 4)
        
        -- Store cell references
        rowFrames[i] = {text = cell, bg = bg, icon = iconTexture}
        
        -- Update offset for next column
        xOffset = xOffset + cellWidth
    end
    
    return rowFrames
end

-- Update CreateRows to remove highlighting logic
function TWRA:CreateRows(data, forceHeader)
    if not data or table.getn(data) == 0 then
        self:Debug("ui", "CreateRows called with empty data")
        return
    end

    -- Initialize row frames array if needed
    if not self.rowFrames then
        self.rowFrames = {}
    end
    
    -- Create rows based on data
    for i = 1, table.getn(data) do
        self.rowFrames[i] = self:CreateRow(i, data[i])
    end
    
    self:Debug("ui", "Created " .. table.getn(self.rowFrames) .. " total rows")
end

-- Update ClearRows to hide all highlights but not destroy them
function TWRA:ClearRows()
    -- Hide all highlights from the pool
    if self.highlightPool then
        for _, highlight in ipairs(self.highlightPool) do
            highlight:Hide()
            highlight:ClearAllPoints()
        end
    end
    
    -- Clear existing row frames
    if self.rowFrames then
        for i, row in pairs(self.rowFrames) do
            for j, cell in pairs(row) do
                if cell.text then cell.text:Hide() end
                if cell.bg then cell.bg:Hide() end
                if cell.icon then cell.icon:Hide() end
            end
            self.rowFrames[i] = nil
        end
        self.rowFrames = {}
    else
        self.rowFrames = {}
    end
    
    -- Also clear footers
    self:ClearFooters()
    
    self.headerColumns = nil
end

-- Create a function to apply highlights based on section data
function TWRA:ApplyRowHighlights(sectionData, displayData)
    -- Hide all highlights first
    for _, highlight in ipairs(self.highlightPool) do
        highlight:Hide()
        highlight:ClearAllPoints()
    end
    
    -- If no section data or no display data, we're done
    if not sectionData or not displayData then
        self:Debug("ui", "ApplyRowHighlights: No data to work with")
        return
    end
    
    -- Check if we have relevant rows in section player info
    if not sectionData["Section Player Info"] or not sectionData["Section Player Info"]["Relevant Rows"] then
        self:Debug("ui", "ApplyRowHighlights: No player info available")
        return
    end
    
    -- Get the relevant rows we need to highlight
    local relevantRows = sectionData["Section Player Info"]["Relevant Rows"]
    if not relevantRows or table.getn(relevantRows) == 0 then
        self:Debug("ui", "ApplyRowHighlights: No relevant rows to highlight")
        return
    end
    
    -- Create a mapping from section row index to display row index
    -- This is needed because filtered display data skips special rows
    local sectionToDisplayMap = {}
    
    -- Create mapping of normal rows between section data and display data
    -- Normal row = not a note, warning or guid row
    local normalRowCounter = 0
    
    -- First, count how many normal rows are in the section data and their indices
    if sectionData["Section Rows"] then
        for i, rowData in ipairs(sectionData["Section Rows"]) do
            -- Skip special rows
            if rowData[1] ~= "Note" and rowData[1] ~= "Warning" and rowData[1] ~= "GUID" then
                normalRowCounter = normalRowCounter + 1
                
                -- Map this normal row to its position in filtered data
                -- +1 because display data has header at index 1
                sectionToDisplayMap[i] = normalRowCounter + 1
            end
        end
    end
    
    -- Debug the mapping
    local debugMapping = "Section-to-Display mapping: "
    for secIdx, dispIdx in pairs(sectionToDisplayMap) do
        debugMapping = debugMapping .. secIdx .. "->" .. dispIdx .. " "
    end
    self:Debug("ui", debugMapping)
    
    -- Apply highlights to the relevant rows
    local highlightCount = 0
    
    for _, sectionRowIdx in ipairs(relevantRows) do
        local displayRowIdx = sectionToDisplayMap[sectionRowIdx]
        
        if displayRowIdx then
            highlightCount = highlightCount + 1
            
            -- Make sure we don't exceed our pool size
            if highlightCount <= table.getn(self.highlightPool) then
                local highlight = self.highlightPool[highlightCount]
                local yOffset = -40 - (displayRowIdx * 20)
                
                -- Position highlight over the correct row
                highlight:SetPoint("TOPLEFT", self.mainFrame, "TOPLEFT", 22, yOffset + 1)
                highlight:SetPoint("BOTTOMRIGHT", self.mainFrame, "TOPRIGHT", -22, yOffset - 15)
                highlight:Show()
                
                self:Debug("ui", "Highlighted row " .. sectionRowIdx .. " -> " .. displayRowIdx)
            else
                self:Debug("error", "Not enough highlights in pool for all relevant rows")
                break
            end
        end
    end
    
    self:Debug("ui", "Applied " .. highlightCount .. " highlights")
end