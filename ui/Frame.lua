TWRA = TWRA or {}

-- Store original functions
TWRA.originalFunctions = {}

-- Check if we're dealing with example data
function TWRA:IsExampleData(data)
    return data == self.EXAMPLE_DATA
end

-- UI-specific functions
TWRA.currentView = "main"  -- Either "main" or "options"

-- Helper function to close dropdown menu
function TWRA:CloseDropdownMenu()
    if self.navigation and self.navigation.dropdownMenu and self.navigation.dropdownMenu:IsShown() then
        self.navigation.dropdownMenu:Hide()
    end
end

-- Register for player update events
function TWRA:RegisterPlayerEvents()
    -- Only register if we have the event system
    if not self.RegisterEvent then
        self:Debug("ui", "Event system not available, cannot register player events")
        return false
    end
    
    -- Register for PLAYERS_UPDATED event
    self:RegisterEvent("PLAYERS_UPDATED", function()
        -- Only update UI if main frame is visible and in main view
        if self.mainFrame and self.mainFrame:IsShown() and self.currentView == "main" then
            -- If we have a refresh function, call it to update the UI
            if self.RefreshAssignmentTable then
                self:Debug("ui", "Refreshing display after player update")
                self:RefreshAssignmentTable()
            end
        end
    end)
    
    self:Debug("ui", "Registered for player update events")
    return true
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
    
    -- Store default width for proper resizing
    self.defaultFrameWidth = 800
    
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
    
    -- Add Sync All button in the top left corner
    local syncAllButton = CreateFrame("Button", nil, self.mainFrame, "UIPanelButtonTemplate")
    syncAllButton:SetWidth(70)
    syncAllButton:SetHeight(20)
    syncAllButton:SetPoint("TOPLEFT", 20, -15)
    syncAllButton:SetText("Sync All")
    syncAllButton:SetScript("OnClick", function() 
        -- Close dropdown when syncing
        self:CloseDropdownMenu()
        self:SendAllSections()
    end)
    self.syncAllButton = syncAllButton  -- Store reference

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
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, 
        tileSize = 16, 
        edgeSize = 16,
        insets = { left = 5, right = 5, top = 5, bottom = 5 }
    })
    dropdownMenu:SetBackdropColor(0, 0, 0, 0.9)  -- Darker background for better contrast
    dropdownMenu:SetBackdropBorderColor(1, 1, 1, 0.7)  -- White border with slight transparency
    dropdownMenu:Hide()
    self.navigation.dropdownMenu = dropdownMenu
    dropdownMenu.buttons = {}
    
    -- Constants for dropdown
    local MAX_VISIBLE_BUTTONS = 15  -- Maximum number of buttons to show at once
    local BUTTON_HEIGHT = 20  -- Height of each dropdown button
    local BUTTON_SPACING = 0  -- No additional spacing between buttons
    local DROPDOWN_PADDING = 10  -- 5px top and 5px bottom padding
    
    -- Add navigation state
    dropdownMenu.offset = 0  -- Starting offset for visible buttons
    
    -- Create up arrow button
    local upButton = CreateFrame("Button", nil, dropdownMenu)
    upButton:SetPoint("TOPLEFT", dropdownMenu, "TOPLEFT", 5, -5)
    upButton:SetWidth(20)
    upButton:SetHeight(20)
    upButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollUp-Up")
    upButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollUp-Down")
    upButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    upButton:SetFrameLevel(dropdownMenu:GetFrameLevel() + 5)
    upButton:Hide()  -- Initially hidden
    dropdownMenu.upButton = upButton
    
    -- Create down arrow button
    local downButton = CreateFrame("Button", nil, dropdownMenu)
    downButton:SetPoint("BOTTOMLEFT", dropdownMenu, "BOTTOMLEFT", 5, 5)
    downButton:SetWidth(20)
    downButton:SetHeight(20)
    downButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
    downButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Down")
    downButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    downButton:SetFrameLevel(dropdownMenu:GetFrameLevel() + 5)
    downButton:Hide()  -- Initially hidden
    dropdownMenu.downButton = downButton
    
    -- Set click handlers for navigation buttons
    upButton:SetScript("OnClick", function()
        if dropdownMenu.offset <= 0 then return end
        dropdownMenu.offset = dropdownMenu.offset - 1
        dropdownMenu:UpdateVisibleButtons()
    end)
    
    downButton:SetScript("OnClick", function()
        local maxOffset = table.getn(self.navigation.handlers) - MAX_VISIBLE_BUTTONS
        if dropdownMenu.offset >= maxOffset then return end
        dropdownMenu.offset = dropdownMenu.offset + 1
        dropdownMenu:UpdateVisibleButtons()
    end)
    
    -- Function to update which buttons are visible based on current offset
    function dropdownMenu:UpdateVisibleButtons()
        if not TWRA.navigation or not TWRA.navigation.handlers then return end
        
        local numSections = table.getn(TWRA.navigation.handlers)
        local maxOffset = math.max(0, numSections - MAX_VISIBLE_BUTTONS)
        
        -- Clamp offset to valid range
        self.offset = math.max(0, math.min(self.offset, maxOffset))
        
        -- Show/hide up button based on offset
        if self.offset > 0 then
            self.upButton:Show()
        else
            self.upButton:Hide()
        end
        
        -- Show/hide down button based on offset
        if self.offset < maxOffset then
            self.downButton:Show()
        else
            self.downButton:Hide()
        end
        
        -- Update button visibility and content
        for i = 1, MAX_VISIBLE_BUTTONS do
            local sectionIndex = i + self.offset
            local button = self.buttons[i]
            
            if sectionIndex <= numSections then
                local sectionName = TWRA.navigation.handlers[sectionIndex]
                -- Add section index to the display text
                button.text:SetText(sectionIndex .. ". " .. sectionName)
                button.sectionIndex = sectionIndex
                
                -- Highlight current section
                if sectionIndex == TWRA.navigation.currentIndex then
                    button.text:SetTextColor(1, 0.82, 0) -- Gold for current section
                    button:SetNormalTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
                    local normalTex = button:GetNormalTexture()
                    normalTex:SetVertexColor(1, 0.82, 0, 0.4)
                else
                    button.text:SetTextColor(1, 1, 1) -- White for other sections
                    button:SetNormalTexture(nil)
                end
                
                button:Show()
            else
                button:Hide()
            end
        end
    end
    
    -- Enable mousewheel for navigation
    dropdownMenu:EnableMouseWheel(true)
    dropdownMenu:SetScript("OnMouseWheel", function()
        local delta = arg1 -- In WoW 1.12, delta is passed via arg1
        
        if delta > 0 then
            -- Wheel up = navigate up the list (decrease offset)
            if dropdownMenu.offset > 0 then
                dropdownMenu.offset = dropdownMenu.offset - 1
                dropdownMenu:UpdateVisibleButtons()
            end
        else
            -- Wheel down = navigate down the list (increase offset)
            local maxOffset = table.getn(TWRA.navigation.handlers) - MAX_VISIBLE_BUTTONS
            if dropdownMenu.offset < maxOffset then
                dropdownMenu.offset = dropdownMenu.offset + 1
                dropdownMenu:UpdateVisibleButtons()
            end
        end
    end)
    
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
        
        -- If we need to create buttons for the first time
        if table.getn(dropdownMenu.buttons) == 0 then
            for i = 1, MAX_VISIBLE_BUTTONS do
                -- Create button
                local button = CreateFrame("Button", nil, dropdownMenu)
                button:SetHeight(BUTTON_HEIGHT)
                button:SetPoint("TOPLEFT", dropdownMenu, "TOPLEFT", 30, -5 - ((i-1) * BUTTON_HEIGHT))
                button:SetPoint("TOPRIGHT", dropdownMenu, "TOPRIGHT", -5, -5 - ((i-1) * BUTTON_HEIGHT))
                
                -- Highlight texture
                button:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
                
                -- Button text
                local buttonText = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                buttonText:SetPoint("LEFT", 5, 0)
                buttonText:SetPoint("RIGHT", -5, 0)
                buttonText:SetJustifyH("LEFT")
                button.text = buttonText
                
                -- Click handler for dropdown menu items
                button:SetScript("OnClick", function()
                    local sectionIndex = button.sectionIndex
                    if sectionIndex then
                        -- Use the centralized NavigateToSection function with user source
                        TWRA:NavigateToSection(sectionIndex, "user")
                        
                        -- Hide the dropdown
                        dropdownMenu:Hide()
                    end
                end)
                
                table.insert(dropdownMenu.buttons, button)
            end
        end
        
        -- Calculate optimal dropdown height
        local numHandlers = table.getn(self.navigation.handlers)
        local visibleButtons = math.min(numHandlers, MAX_VISIBLE_BUTTONS)
        local contentHeight = (visibleButtons * BUTTON_HEIGHT) + DROPDOWN_PADDING
        
        -- Make room for scroll buttons if needed
        if numHandlers > MAX_VISIBLE_BUTTONS then
            contentHeight = contentHeight + 10  -- Extra space for scroll buttons
        end
        
        -- Position menu and set dimensions
        dropdownMenu:ClearAllPoints()
        dropdownMenu:SetPoint("TOP", menuButton, "BOTTOM", 0, -2)
        dropdownMenu:SetWidth(menuButton:GetWidth())
        dropdownMenu:SetHeight(contentHeight)
        
        -- Reset offset to ensure current section is visible
        if self.navigation.currentIndex then
            -- Calculate appropriate offset to show current section
            local currentIndex = self.navigation.currentIndex
            
            -- Make sure current section is visible in the window
            if currentIndex > MAX_VISIBLE_BUTTONS then
                -- Center the current index in the visible window if possible
                dropdownMenu.offset = math.max(0, currentIndex - math.floor(MAX_VISIBLE_BUTTONS / 2))
                
                -- Make sure offset doesn't go past maximum
                local maxOffset = math.max(0, table.getn(self.navigation.handlers) - MAX_VISIBLE_BUTTONS)
                dropdownMenu.offset = math.min(dropdownMenu.offset, maxOffset)
            else
                dropdownMenu.offset = 0
            end
        else
            dropdownMenu.offset = 0
        end
        
        -- Update buttons before showing
        dropdownMenu:UpdateVisibleButtons()
        
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
    if TWRA_Assignments and TWRA_Assignments.data then
        -- Check if we're using the new data format
        local isNewFormat = false
        if type(TWRA_Assignments.data) == "table" then
            for idx, section in pairs(TWRA_Assignments.data) do
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
            self.usingExampleData = TWRA_Assignments.usingExampleData or
                                    TWRA_Assignments.isExample or false
            
            -- Restore saved section index or name for later use (but don't display yet)
            if TWRA_Assignments.currentSectionName and self.navigation.handlers then
                local found = false
                for i, name in ipairs(self.navigation.handlers) do
                    if name == TWRA_Assignments.currentSectionName then
                        self.navigation.currentIndex = i
                        found = true
                        self:Debug("nav", "Main frame stored section by name: " .. name)
                        break
                    end
                end
                
                if not found and TWRA_Assignments.currentSection then
                    local index = TWRA_Assignments.currentSection
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
            self.fullData = TWRA_Assignments.data
            
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
            if TWRA_Assignments.currentSection then
                self.navigation.currentIndex = TWRA_Assignments.currentSection
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
    if self.syncAllButton then self.syncAllButton:Show() end

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
        
        -- Check if we have a pending handler that was deferred while in options view
        if self.pendingHandler then
            self:Debug("ui", "Found pending handler: " .. self.pendingHandler)
            local handlerToUse = self.pendingHandler
            self.pendingHandler = nil -- Clear it before using
            self:FilterAndDisplayHandler(handlerToUse)
        else
            -- Display current section using the normal process
            local currentHandler = self.navigation.handlers[self.navigation.currentIndex]
            if currentHandler then
                self:Debug("ui", "Directly calling FilterAndDisplayHandler for section: " .. currentHandler)
                self:FilterAndDisplayHandler(currentHandler)
            end
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

-- Replace NavigateHandler to use event system
function TWRA:NavigateHandler(delta)
    -- Safety checks
    if not self.navigation or not self.navigation.handlers then
        self:Debug("error", "NavigateHandler: No navigation or handlers")
        return
    end
    
    if not self.navigation.currentIndex then
        self.navigation.currentIndex = 1
    end
    
    -- Calculate the new index with bounds checking
    local newIndex = self.navigation.currentIndex + delta
    local maxIndex = table.getn(self.navigation.handlers)
    
    -- Wrap around navigation
    if newIndex < 1 then
        newIndex = maxIndex
    elseif newIndex > maxIndex then
        newIndex = 1
    end
    
    -- Use NavigateToSection for consistent event dispatching
    self:NavigateToSection(newIndex)
end

-- Replace FilterAndDisplayHandler to use dynamic column widths and hide headers when data needs processing
function TWRA:FilterAndDisplayHandler(currentHandler)
    -- Debug entry
    self:Debug("ui", "FilterAndDisplayHandler called for section: " .. (currentHandler or "nil"))
    
    -- Store current handler for when we switch back to main view
    self.pendingHandler = currentHandler
    
    -- If we're not in the main view, defer creating content until we switch back
    if self.currentView ~= "main" then
        self:Debug("ui", "Not in main view - deferring content creation for: " .. currentHandler)
        return
    end
    
    -- Clear pending handler since we're about to process it
    self.pendingHandler = nil
    
    -- Get the current section data based on the handler name
    local sectionData = nil
    local sectionIndex = nil
    
    -- Try to find the section data and index for the current handler
    if TWRA_Assignments and TWRA_Assignments.data then
        for idx, section in pairs(TWRA_Assignments.data) do
            if section["Section Name"] == currentHandler then
                sectionData = section
                sectionIndex = idx
                break
            end
        end
    end
    
    -- Clear existing content
    self:ClearRows()
    self:ClearFooters()
    
    -- Check if we're using example data
    local isExampleData = (TWRA_Assignments and TWRA_Assignments.isExample) or self.usingExampleData
    
    -- EARLY CHECK: If section needs processing or we're missing compressed data, show warning and don't display headers
    local needsProcessing = sectionData and sectionData["NeedsProcessing"] == true
    local missingCompressedData = false
    
    -- Check if compressed data is available for this section, but ONLY if not using example data
    if not isExampleData and sectionIndex then
        -- First check if we have TWRA_CompressedAssignments structure
        if not TWRA_CompressedAssignments then
            missingCompressedData = true
            self:Debug("ui", "TWRA_CompressedAssignments is nil")
        elseif not TWRA_CompressedAssignments.sections then
            missingCompressedData = true
            self:Debug("ui", "TWRA_CompressedAssignments.sections is nil")
        else
            -- Check compressed data more carefully, differentiating between:
            -- 1. Non-existent key (nil)
            -- 2. Empty string ("")
            -- 3. Valid data (any non-empty string)
            
            local compressedData = TWRA_CompressedAssignments.sections[sectionIndex]
            local dataExists = compressedData ~= nil
            local dataNotEmpty = dataExists and compressedData ~= ""
            
            -- Log what we found for debugging
            if not dataExists then
                self:Debug("ui", "Section " .. currentHandler .. ": Compressed data key doesn't exist")
            elseif not dataNotEmpty then
                self:Debug("ui", "Section " .. currentHandler .. ": Compressed data is empty string")
            else
                self:Debug("ui", "Section " .. currentHandler .. ": Compressed data exists and is not empty")
            end
            
            -- Only consider data missing if it doesn't exist or is empty
            missingCompressedData = not dataNotEmpty
            
            self:Debug("ui", "Section " .. currentHandler .. " (" .. sectionIndex .. 
                     ") - Has compressed data: " .. tostring(dataNotEmpty) .. 
                     ", missingCompressedData: " .. tostring(missingCompressedData))
        end
    end
    
    self:Debug("ui", "Section " .. currentHandler .. " - needsProcessing: " .. tostring(needsProcessing) .. 
              ", missingCompressedData: " .. tostring(missingCompressedData))
    
    -- Only show the warning and return early if explicitly needsProcessing is true
    -- OR if missingCompressedData is true AND we're not using example data
    if (needsProcessing) or (missingCompressedData and not isExampleData) then
        self:Debug("ui", "Section " .. currentHandler .. " - needsProcessing: " .. tostring(needsProcessing) .. 
                  ", missingCompressedData: " .. tostring(missingCompressedData))
        
        -- Create warning elements if they don't exist
        if not self.processingWarningElements then
            self.processingWarningElements = {}
            
            -- Create warning header
            local warningHeader = self.mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
            warningHeader:SetPoint("TOP", self.mainFrame, "TOP", 0, -60)
            warningHeader:SetText("Section assignments not processed")
            warningHeader:SetTextColor(1, 0.8, 0)
            self.processingWarningElements.header = warningHeader
            
            -- Create warning icons (left and right)
            local iconLeft = self.mainFrame:CreateTexture(nil, "OVERLAY")
            iconLeft:SetTexture("Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew")
            iconLeft:SetWidth(32)
            iconLeft:SetHeight(32)
            iconLeft:SetPoint("RIGHT", warningHeader, "LEFT", -10, 0)
            self.processingWarningElements.iconLeft = iconLeft
            
            local iconRight = self.mainFrame:CreateTexture(nil, "OVERLAY")
            iconRight:SetTexture("Interface\\DialogFrame\\UI-Dialog-Icon-AlertNew")
            iconRight:SetWidth(32)
            iconRight:SetHeight(32)
            iconRight:SetPoint("LEFT", warningHeader, "RIGHT", 10, 0)
            self.processingWarningElements.iconRight = iconRight
            
            -- Create additional info text for synced sections
            local infoText = self.mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            infoText:SetPoint("TOP", warningHeader, "BOTTOM", 0, -10)
            infoText:SetText("Waiting for data from raid members...")
            infoText:SetTextColor(0.8, 0.8, 1)
            self.processingWarningElements.infoText = infoText
        end
        
        -- Always show header and icons when processing is needed
        self.processingWarningElements.header:Show()
        self.processingWarningElements.iconLeft:Show()
        self.processingWarningElements.iconRight:Show()
        
        -- Set the appropriate warning messages based on condition
        if isExampleData then
            -- For example data
            self:Debug("ui", "Example data - displaying specific message")
            self.processingWarningElements.header:SetText("Displaying example data")
            -- Hide the "waiting for data" message for example data
            if self.processingWarningElements.infoText then
                self.processingWarningElements.infoText:Hide()
            end
            
            -- Update the section to mark it as processed (for example data only)
            for idx, section in pairs(TWRA_Assignments.data) do
                if section["Section Name"] == currentHandler then
                    -- For example data, just mark it as processed without actually processing
                    section["NeedsProcessing"] = false
                    
                    -- Create minimal structure if needed
                    section["Section Header"] = section["Section Header"] or {"Icon", "Target"}
                    section["Section Rows"] = section["Section Rows"] or {}
                    section["Section Metadata"] = section["Section Metadata"] or {
                        ["Note"] = {},
                        ["Warning"] = {},
                        ["GUID"] = {}
                    }
                    
                    -- Refresh our sectionData reference
                    sectionData = section
                    
                    self:Debug("ui", "Example data marked as processed")
                    needsProcessing = false
                    break
                end
            end
        else
            -- Not example data - determine if we need to show the waiting message
            self.processingWarningElements.header:SetText("Section assignments not processed")
            
            -- EXACTLY MATCH THE LOGIC FROM TWRA.lua:
            -- 1. First hide the infoText (default state)
            if self.processingWarningElements.infoText then
                self.processingWarningElements.infoText:Hide()
                self:Debug("ui", "Hidden infoText by default for section " .. currentHandler)
            end
            
            -- 2. Check if compressed data is EXPLICITLY an empty string
            local missingData = false
            if TWRA_CompressedAssignments and 
               TWRA_CompressedAssignments.sections and 
               sectionIndex and 
               TWRA_CompressedAssignments.sections[sectionIndex] == "" then
                missingData = true
                self:Debug("ui", "Section " .. currentHandler .. ": Compressed data is empty string")
            end
            
            -- 3. Only show the infoText when missingData is true
            if missingData and self.processingWarningElements.infoText then
                self.processingWarningElements.infoText:SetText("Waiting for data from raid members...")
                self.processingWarningElements.infoText:Show()
                self:Debug("ui", "Showing 'waiting for data' message for section " .. currentHandler)
            end
        end
        
        -- Important: Return early to prevent showing headers and content
        return
    else
        -- Hide the warning elements if they exist, since we don't need them
        if self.processingWarningElements then
            self.processingWarningElements.header:Hide()
            self.processingWarningElements.iconLeft:Hide()
            self.processingWarningElements.iconRight:Hide()
            if self.processingWarningElements.infoText then
                self.processingWarningElements.infoText:Hide()
            end
        end
    end
    
    -- Create filtered data structure
    local filteredData = {}
    
    -- Process header from Section Header
    if sectionData and sectionData["Section Header"] then
        table.insert(filteredData, sectionData["Section Header"])
        
        -- Determine max columns from header
        self.headerColumns = table.getn(sectionData["Section Header"])
        self:Debug("ui", "Got header with " .. self.headerColumns .. " columns")
    else
        self:Debug("error", "No header found in section data")
        return
    end
    
    -- Process rows from Section Rows
    -- No need to filter out special rows since they've already been removed
    if sectionData and sectionData["Section Rows"] then
        for i, rowData in ipairs(sectionData["Section Rows"]) do
            -- Add the row to our filtered data
            table.insert(filteredData, rowData)
            self:Debug("ui", "Added row with icon: " .. tostring(rowData[1]) .. ", target: " .. tostring(rowData[2]))
        end
    else
        self:Debug("error", "No rows found in section data")
        return
    end
    
    -- Calculate dynamic column widths based on actual content
    self.dynamicColumnWidths = self:CalculateColumnWidths(filteredData)
    
    -- Calculate total required width based on dynamic column widths
    local totalRequiredWidth = 0
    for _, width in pairs(self.dynamicColumnWidths) do
        totalRequiredWidth = totalRequiredWidth + width
    end
    
    -- Standard frame width and padding
    local standardFrameWidth = self.defaultFrameWidth or 800
    local framePadding = 40  -- 20px on each side
    
    -- Check if we need to expand the frame or can shrink it
    if self.mainFrame then
        local currentWidth = self.mainFrame:GetWidth()
        
        if totalRequiredWidth + framePadding > standardFrameWidth then
            -- Need to expand the frame
            self.mainFrame:SetWidth(totalRequiredWidth + framePadding)
            self:Debug("ui", "Expanded frame width to " .. (totalRequiredWidth + framePadding) .. " to fit dynamic columns")
        elseif currentWidth > standardFrameWidth and totalRequiredWidth + framePadding <= standardFrameWidth then
            -- Frame is expanded but we no longer need it to be - shrink it back
            self.mainFrame:SetWidth(standardFrameWidth)
            self:Debug("ui", "Shrinking frame width back to standard size: " .. standardFrameWidth)
        end
    end
    
    -- Create new rows
    self:Debug("ui", "Creating " .. table.getn(filteredData) .. " rows from filtered data")
    self:CreateRows(filteredData, true)
    
    -- Apply highlights based on section player info
    self:ApplyRowHighlights(sectionData, filteredData)
    
    -- Create footers for this section (notes and warnings)
    self:CreateFootersNewFormat(currentHandler, sectionData)
    
    -- Trigger an event when display is complete
    if self.TriggerEvent then
        self:TriggerEvent("SECTION_DISPLAYED", currentHandler, sectionData)
    end
    
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
    
    -- Get notes and warnings directly from Section Metadata
    local notes = {}
    local warnings = {}
    
    -- Access metadata for notes and warnings
    if sectionData["Section Metadata"] then
        local metadata = sectionData["Section Metadata"]
        
        -- Process notes from metadata
        if metadata["Note"] then
            for _, noteText in ipairs(metadata["Note"]) do
                if noteText and noteText ~= "" then
                    table.insert(notes, {
                        text = noteText,
                        icon = "Note"
                    })
                    self:Debug("ui", "Found note in metadata: " .. noteText)
                end
            end
        end
        
        -- Process warnings from metadata
        if metadata["Warning"] then
            for _, warningText in ipairs(metadata["Warning"]) do
                if warningText and warningText ~= "" then
                    table.insert(warnings, {
                        text = warningText,
                        icon = "Warning"
                    })
                    self:Debug("ui", "Found warning in metadata: " .. warningText)
                end
            end
        end
    else
        self:Debug("ui", "No Section Metadata found for footers")
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

-- Make sure CreateFooterElement creates visible elements with item link support
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
    
    -- Process text with item links
    local processedText = text
    if TWRA.Items and TWRA.Items.ProcessText then
        processedText = TWRA.Items:ProcessText(text)
    end
    
    -- Create text element with item link support
    local textElement = self.mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    textElement:SetPoint("TOPLEFT", bg, "TOPLEFT", icon and 32 or 10, -6)  -- More space for larger icon
    textElement:SetPoint("TOPRIGHT", bg, "TOPRIGHT", -10, -4)
    textElement:SetText(processedText)
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
    
    -- Add the click handler to send to chat with item links
    clickFrame:SetScript("OnClick", function()
        -- Call the announce function with the footer text, processing item links
        self:Debug("ui", "Announcing footer: " .. text)
        
        -- Process the text with item links before sending
        local announcementText = text
        if self.Items and self.Items.EnhancedProcessText then
            -- Use the enhanced processor that does both bracketed items and consumables
            announcementText = self.Items:EnhancedProcessText(text)
        elseif self.Items and self.Items.ProcessText then
            -- Fall back to basic processor if enhanced not available
            announcementText = self.Items:ProcessText(text)
        end
        
        -- Use specific channel logic based on footer type, ignoring channel settings
        local success = false
        
        if footerType == "Warning" then
            -- For warnings, try raid warning first, then fall back to raid announcement
            if IsRaidOfficer() or IsRaidLeader() then
                SendChatMessage(announcementText, "RAID_WARNING")
                success = true
            end
            
            -- Fall back to raid announcement if raid warning failed
            if not success then
                SendChatMessage(announcementText, "RAID")
            end
        else
            -- For notes, always use raid announcement
            SendChatMessage(announcementText, "RAID")
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

-- Update CreateRow to improve column widths and resize frame as needed
function TWRA:CreateRow(rowNum, data)
    local rowFrames = {}
    local yOffset = -40 - (rowNum * 20)
    local fontStyle = rowNum == 1 and "GameFontNormalLarge" or "GameFontNormal"
    local isHeader = rowNum == 1
    
    local numColumns = self.headerColumns or table.getn(data)
    
    -- Use dynamic column widths if available, otherwise use defaults
    local xOffset = 20 -- Starting offset
    
    -- Process all columns
    for i = 1, numColumns do
        local cellWidth
        
        -- Determine column width based on dynamic widths or fallback to defaults
        if self.dynamicColumnWidths and self.dynamicColumnWidths[i] then
            cellWidth = self.dynamicColumnWidths[i]
        else
            -- Use fixed defaults if no dynamic widths available
            if i == 1 then
                cellWidth = 15     -- Icon column
            elseif i == 2 then
                cellWidth = 10    -- Target column
            else
                cellWidth = 80    -- Player/role columns
            end
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
                -- Header displays "Icon" text
                cell = self:CreateHeaderCell(cell, "", cellWidth, 0)
            else
                cell:SetText("") -- Don't show icon text
                
                -- Create icon texture if we have valid icon data
                if cellData and cellData ~= "" and TWRA.ICONS and TWRA.ICONS[cellData] then
                    iconTexture = self.mainFrame:CreateTexture(nil, "OVERLAY")
                    iconTexture:SetPoint("CENTER", bg, "CENTER", 8, 0)
                    iconTexture:SetWidth(16)
                    iconTexture:SetHeight(16)
                    local iconInfo = TWRA.ICONS[cellData]
                    iconTexture:SetTexture(iconInfo[1])
                    iconTexture:SetTexCoord(iconInfo[2], iconInfo[3], iconInfo[4], iconInfo[5])
                end
            end
        elseif i == 2 then
            -- Target column - ensure this is always displayed regardless of icon
            if isHeader then
                cell = self:CreateHeaderCell(cell, "Target", cellWidth, 0)
            elseif cellData and cellData ~= "" then
                cell:SetText(cellData)
                cell:SetJustifyH("LEFT")
                cell:SetTextColor(1, 1, 1) -- White text for target
            else
                -- Empty target cell
                cell:SetText("")
            end
        else
            -- Role/player columns
            if isHeader then
                cell = self:CreateHeaderCell(cell, cellData, cellWidth, 0)
            else
                cell:SetText(cellData)
                
                if cellData and cellData ~= "" then
                    -- Get player info from PLAYERS table
                    local playerInfo = self.PLAYERS and self.PLAYERS[cellData]
                    
                    -- Default values if not found in PLAYERS table
                    local playerClass = nil
                    local isInRaid = false
                    local isOnline = false
                    
                    -- Create icon texture for the player cell - ALWAYS create one
                    iconTexture = self.mainFrame:CreateTexture(nil, "OVERLAY")
                    iconTexture:SetPoint("LEFT", bg, "LEFT", 4, 0)
                    iconTexture:SetWidth(12)
                    iconTexture:SetHeight(12)
                    
                    if playerInfo then
                        -- Extract class and online status from PLAYERS table
                        playerClass = playerInfo[1]
                        isInRaid = true
                        isOnline = playerInfo[2]
                        
                        -- Set class icon texture for players in raid
                        iconTexture:SetTexture("Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES")
                        local coords = self.CLASS_COORDS and self.CLASS_COORDS[string.upper(playerClass)]
                        if coords then
                            iconTexture:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
                        end
                    else
                        -- Player not in raid - use Missing icon
                        if self.ICONS and self.ICONS["Missing"] then
                            local iconInfo = self.ICONS["Missing"]
                            iconTexture:SetTexture(iconInfo[1])
                            iconTexture:SetTexCoord(iconInfo[2], iconInfo[3], iconInfo[4], iconInfo[5])
                        else
                            -- Fallback to disconnect icon if Missing icon not available
                            iconTexture:SetTexture("Interface\\CharacterFrame\\Disconnect-Icon")
                            iconTexture:SetTexCoord(0, 1, 0, 1)
                        end
                    end
                    
                    -- Apply class coloring
                    if self.UI and self.UI.ApplyClassColoring then
                        -- Use the UIUtils function for consistent coloring
                        self.UI:ApplyClassColoring(cell, nil, playerClass, isInRaid, isOnline)
                    else
                        -- Fallback coloring
                        if not isInRaid then
                            cell:SetTextColor(1, 0.3, 0.3) -- Red for not in raid
                        elseif not isOnline then
                            cell:SetTextColor(0.5, 0.5, 0.5) -- Gray for offline
                        elseif playerClass and self.VANILLA_CLASS_COLORS then
                            local color = self.VANILLA_CLASS_COLORS[string.upper(playerClass)]
                            if color then
                                cell:SetTextColor(color.r, color.g, color.b)
                            else
                                cell:SetTextColor(1, 1, 1) -- White fallback
                            end
                        else
                            cell:SetTextColor(1, 1, 1) -- White fallback
                        end
                    end
                else
                    -- Empty cell is white
                    cell:SetTextColor(1, 1, 1)
                end
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
    
    -- Also hide all processing warning elements if they exist
    if self.processingWarningElements then
        if self.processingWarningElements.header then
            self.processingWarningElements.header:Hide()
        end
        if self.processingWarningElements.iconLeft then
            self.processingWarningElements.iconLeft:Hide()
        end
        if self.processingWarningElements.iconRight then
            self.processingWarningElements.iconRight:Hide()
        end
        if self.processingWarningElements.infoText then
            self.processingWarningElements.infoText:Hide()
        end
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
    
    -- Check if we have player info in section
    if not sectionData["Section Player Info"] then
        self:Debug("ui", "ApplyRowHighlights: No player info available")
        return
    end
    
    -- Get both relevant rows (name/class based) and relevant group rows (group based)
    local relevantRows = sectionData["Section Player Info"]["Relevant Rows"] or {}
    local relevantGroupRows = sectionData["Section Player Info"]["Relevant Group Rows"] or {}
    
    -- Create a combined set of unique row indices to highlight
    local rowsToHighlight = {}
    local rowsAdded = {}
    
    -- First add regular relevant rows
    for _, rowIndex in ipairs(relevantRows) do
        if not rowsAdded[rowIndex] then
            table.insert(rowsToHighlight, rowIndex)
            rowsAdded[rowIndex] = true
            self:Debug("ui", "Adding name/class relevant row " .. rowIndex .. " to highlight list")
        end
    end
    
    -- Then add group relevant rows, but only if not already added
    for _, rowIndex in ipairs(relevantGroupRows) do
        if not rowsAdded[rowIndex] then
            table.insert(rowsToHighlight, rowIndex)
            rowsAdded[rowIndex] = true
            self:Debug("ui", "Adding group relevant row " .. rowIndex .. " to highlight list")
        end
    end
    
    -- If no rows to highlight, we're done
    if table.getn(rowsToHighlight) == 0 then
        self:Debug("ui", "ApplyRowHighlights: No rows to highlight")
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
    
    -- Apply highlights to the unique set of relevant rows
    local highlightCount = 0
    
    for _, sectionRowIdx in ipairs(rowsToHighlight) do
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

-- Function to create header cells with automatic font size scaling
function TWRA:CreateHeaderCell(cell, cellData, cellWidth, iconPadding)
    -- Set initial text and properties
    cell:SetText(cellData)
    cell:SetJustifyH("CENTER")
    cell:SetTextColor(1, 1, 1)
    
    -- Set initial dimensions
    cell:SetWidth(cellWidth - iconPadding - 4)
    
    -- Get the width of the text at current font size
    local textWidth = cell:GetStringWidth()
    
    -- Check if text is wider than the available space (with some margin)
    if textWidth > (cellWidth - iconPadding - 8) then
        -- Text is too wide, we need to scale down the font
        local fontName, fontHeight, fontFlags = cell:GetFont()
        local originalHeight = fontHeight
        
        -- Iteratively reduce font size until it fits
        local attempt = 1
        local maxAttempts = 3  -- Prevent infinite loops
        
        while textWidth > (cellWidth - iconPadding - 8) and attempt <= maxAttempts do
            -- Reduce font size by 2 pixels each attempt
            fontHeight = originalHeight - (attempt * 2)
            
            -- Don't go below a minimum readable size
            if fontHeight < 10 then
                fontHeight = 10
            end
            
            -- Set new font size
            cell:SetFont(fontName, fontHeight, fontFlags)
            
            -- Re-calculate text width with new font size
            textWidth = cell:GetStringWidth()
            attempt = attempt + 1
        end
        
        self:Debug("ui", "Scaled header font from " .. originalHeight .. " to " .. fontHeight .. " to fit text: " .. cellData)
    end
    
    return cell
end

-- Calculate optimal column widths based on content
function TWRA:CalculateColumnWidths(data)
    -- Define default minimum widths - these are the widths columns should return to when not expanded
    local defaultColumnWidths = {
        [1] = 15,   -- Icon column
        [2] = 80,  -- Target column
    }
    
    -- Set default width for all player columns (columns 3+)
    local defaultPlayerColumnWidth = 50
    
    -- Determine the actual maximum number of columns in the data
    local maxColumns = 0
    for _, row in ipairs(data) do
        maxColumns = math.max(maxColumns, table.getn(row))
    end
    
    self:Debug("ui", "CalculateColumnWidths: Found " .. maxColumns .. " actual columns in the data")
    
    -- Start with default widths for all columns
    local columnWidths = {}
    for i = 1, maxColumns do -- Only process columns we actually have
        if i == 1 then
            columnWidths[i] = defaultColumnWidths[1]
        elseif i == 2 then
            columnWidths[i] = defaultColumnWidths[2]
        else
            columnWidths[i] = defaultPlayerColumnWidth
        end
    end
    
    -- Store these default widths globally for reference
    if not self.defaultColumnWidths then
        self.defaultColumnWidths = {}
        for i = 1, maxColumns do
            self.defaultColumnWidths[i] = columnWidths[i]
        end
    end
    
    -- Temporary font strings to measure text widths
    local textMeasure = self.mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    local headerMeasure = self.mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    
    -- Scan all data to find widest content in each column
    for rowIndex, row in ipairs(data) do
        local isHeader = (rowIndex == 1)
        local measure = isHeader and headerMeasure or textMeasure
        
        for colIndex, cellData in ipairs(row) do
            -- Skip icon column width calculation
            if colIndex > 1 then
                if cellData and cellData ~= "" then
                    -- Set the text to measure its width
                    measure:SetText(cellData)
                    local textWidth = measure:GetStringWidth()
                    
                    -- Add padding:
                    -- - For column 2 (target): minimal padding
                    -- - For player columns: space for class icon (18px) + padding
                    local padding = 24
                    
                    -- Update column width if this content is wider than default
                    if textWidth + padding > columnWidths[colIndex] then
                        columnWidths[colIndex] = textWidth + padding
                        self:Debug("ui", "Column " .. colIndex .. " width updated to " .. columnWidths[colIndex] .. " for: " .. cellData)
                    end
                end
            end
        end
    end
    
    -- Clean up temporary font strings
    textMeasure:Hide()
    headerMeasure:Hide()
    
    return columnWidths
end