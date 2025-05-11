-- Turtle WoW Raid Assignments (TWRA)
-- Minimap button implementation

TWRA = TWRA or {}

-- Add tracking variables to prevent duplicate creation
TWRA.minimapState = {
    buttonCreated = false,
    lastCreationTime = 0,
    creationCooldown = 2, -- Seconds between allowed creations
    zoneChangeHandled = false
}

-- Function to properly destroy the minimap button
function TWRA:DestroyMinimapButton()
    -- Only attempt destruction if we have a button
    if not self.minimapButton then 
        self:Debug("ui", "No minimap button to destroy")
        return false
    end
    
    -- Hide any dropdown if it exists
    if self.minimapButton.dropdown then
        self.minimapButton.dropdown:Hide()
        
        -- Clean up dropdown buttons
        if self.minimapButton.dropdown.buttons then
            for i, button in ipairs(self.minimapButton.dropdown.buttons) do
                button:Hide()
                button:SetParent(nil)
                self.minimapButton.dropdown.buttons[i] = nil
            end
        end
        
        -- Remove dropdown itself
        self.minimapButton.dropdown:SetParent(nil)
        self.minimapButton.dropdown = nil
    end
    
    -- Clear all scripts to prevent any lingering callbacks
    self.minimapButton:SetScript("OnClick", nil)
    self.minimapButton:SetScript("OnEnter", nil)
    self.minimapButton:SetScript("OnLeave", nil)
    self.minimapButton:SetScript("OnDragStart", nil)
    self.minimapButton:SetScript("OnDragStop", nil)
    self.minimapButton:SetScript("OnMouseWheel", nil)
    self.minimapButton:SetScript("OnUpdate", nil)
    
    -- Remove any textures
    if self.minimapButton.icon then
        self.minimapButton.icon:SetParent(nil)
        self.minimapButton.icon = nil
    end
    
    if self.minimapButton.highlight then
        self.minimapButton.highlight:SetParent(nil)
        self.minimapButton.highlight = nil
    end
    
    -- Instead of destroying the button, just hide it and preserve its reference
    -- This prevents PFUI from losing track of the button on zone changes
    self.minimapButton:Hide()
    
    -- Update state but DON'T set minimapButton to nil
    self.minimapState.buttonCreated = false
    
    self:Debug("ui", "Minimap button hidden for preservation")
    return true
end

-- Initialize the minimap functionality
function TWRA:InitializeMinimapButton()
    -- Check if we already have a button or creation is on cooldown
    local currentTime = GetTime()
    
    -- If button exists and is working, don't recreate it
    if self.minimapButton and self.minimapState.buttonCreated then
        -- Button exists, just check if it needs to be shown
        if not self.minimapButton:IsShown() then
            self.minimapButton:Show()
            self:Debug("ui", "Showing existing minimap button")
        end
        return true
    end
    
    -- Check if we're on creation cooldown
    if (currentTime - self.minimapState.lastCreationTime) < self.minimapState.creationCooldown then
        self:Debug("ui", "Minimap button creation on cooldown - skipping initialization")
        return false
    end
    
    -- Look for any orphaned buttons with our name
    local existingButton = _G["TWRAMinimapButton"]
    if existingButton and not self.minimapButton then
        -- Reuse the existing button instead of creating a new one
        self:Debug("ui", "Found existing button - reusing it")
        self.minimapButton = existingButton
        self.minimapState.buttonCreated = true
        return true
    end
    
    -- Create new minimap button
    self:Debug("ui", "Creating new minimap button")
    local success = self:CreateMinimapButton()
    
    if success then
        -- Update state
        self.minimapState.buttonCreated = true
        self.minimapState.lastCreationTime = currentTime
        self:Debug("ui", "Minimap button created successfully")
        
        -- Register for section changes to update dropdown highlighting
        if self.RegisterEvent then
            self:Debug("ui", "Registering minimap section change handler")
            
            self:RegisterEvent("SECTION_CHANGED", function(sectionName, currentIndex, totalSections)
                self:Debug("ui", "Minimap received SECTION_CHANGED: " .. sectionName .. " (" .. currentIndex .. ")")
                
                -- If dropdown exists and is visible, update the highlighting
                if self.minimapButton and self.minimapButton.dropdown then
                    -- Always update the selection highlight regardless of visibility
                    if self.minimapButton.dropdown.UpdateVisibleButtons then
                        -- Calculate appropriate offset to ensure current section is visible
                        if currentIndex then
                            local maxVisibleButtons = self.minimapButton.dropdown.MAX_VISIBLE_BUTTONS or 10
                            
                            -- Only adjust offset if dropdown is visible
                            if self.minimapButton.dropdown:IsShown() then
                                -- Only adjust offset if current section would be outside visible range
                                if currentIndex <= self.minimapButton.dropdown.offset or 
                                   currentIndex > (self.minimapButton.dropdown.offset + maxVisibleButtons) then
                                    
                                    -- Try to center the current section in the visible window
                                    self.minimapButton.dropdown.offset = math.max(0, currentIndex - math.floor(maxVisibleButtons / 2))
                                    
                                    -- Make sure offset doesn't go past maximum
                                    local maxOffset = math.max(0, table.getn(self.navigation.handlers) - maxVisibleButtons)
                                    self.minimapButton.dropdown.offset = math.min(self.minimapButton.dropdown.offset, maxOffset)
                                    
                                    self:Debug("ui", "Adjusted dropdown offset to " .. self.minimapButton.dropdown.offset .. 
                                              " for section " .. currentIndex)
                                end
                            end
                            
                            -- Always update the highlight (regardless of visibility)
                            self.minimapButton.dropdown:UpdateVisibleButtons()
                            
                            self:Debug("ui", "Updated dropdown highlighting for section: " .. sectionName)
                        end
                    end
                end
            end, "MinimapDropdown")
        end
        
        -- Register for PLAYER_ENTERING_WORLD to handle zone changes properly
        if self.RegisterEvent then
            self:RegisterEvent("PLAYER_ENTERING_WORLD", function()
                -- Reset zone change handled flag
                self.minimapState.zoneChangeHandled = false
                
                -- Use a timer to handle zone changes in stages
                self:ScheduleTimer(function()
                    -- Only process if not already handled for this zone change
                    if self.minimapState.zoneChangeHandled then
                        self:Debug("ui", "Zone change already handled - skipping")
                        return
                    end
                    
                    -- Mark as handled
                    self.minimapState.zoneChangeHandled = true
                    
                    -- Check if button exists and is properly showing
                    if self.minimapButton then
                        -- Make sure it's showing and properly attached
                        if not self.minimapButton:IsShown() then
                            self.minimapButton:Show()
                            self:Debug("ui", "Reshowing minimap button after zone change")
                        end
                    else
                        -- Button reference is missing completely, recreate it
                        self:Debug("ui", "No minimap button reference after zone change - recreating")
                        self:InitializeMinimapButton()
                    end
                end, 1.0)
            end, "MinimapZoneChange")
        end
        
        return true
    else
        self:Debug("error", "Failed to create minimap button")
        return false
    end
end

-- Create the minimap button
function TWRA:CreateMinimapButton()
    self:Debug("general", "CreateMinimapButton called")
    
    -- Check if button already exists - if it does, just return it
    if self.minimapButton and self.minimapButton:IsShown() then
        self:Debug("ui", "Minimap button already exists and is shown - not recreating")
        return self.minimapButton
    elseif self.minimapButton then
        -- If button exists but is hidden, just show it and return
        self.minimapButton:Show()
        self:Debug("ui", "Existing minimap button was hidden - showing it")
        return self.minimapButton
    end
    
    -- Create a frame for our minimap button (with explicit global name for cleanup)
    local miniButton = CreateFrame("Button", "TWRAMinimapButton", Minimap)
    miniButton:SetWidth(32)
    miniButton:SetHeight(32)
    miniButton:SetFrameStrata("MEDIUM")
    miniButton:SetFrameLevel(8)
    
    -- IMPORTANT: Register for both left and right clicks properly
    miniButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    
    -- Set position (default to 180 degrees)
    local defaultAngle = 180
    local angle = defaultAngle
    
    -- Use saved angle if available
    if TWRA_SavedVariables and TWRA_SavedVariables.options and TWRA_SavedVariables.options.minimapAngle then
        angle = TWRA_SavedVariables.options.minimapAngle
    end
    
    -- Calculate position
    local radius = 80
    local radian = math.rad(angle)
    local x = math.cos(radian) * radius
    local y = math.sin(radian) * radius
    miniButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
    
    -- Set icon texture
    local icon = miniButton:CreateTexture(nil, "BACKGROUND")
    icon:SetTexture("Interface\\AddOns\\TWRA\\textures\\MinimapIcon")
    
    -- If the custom texture doesn't exist, use a default
    if not icon:GetTexture() then
        icon:SetTexture("Interface\\FriendsFrame\\FriendsFrameScrollIcon")
    end
    
    icon:SetAllPoints(miniButton)
    miniButton.icon = icon
    
    -- Add highlight texture
    local highlight = miniButton:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    highlight:SetBlendMode("ADD")
    highlight:SetAllPoints(miniButton)
    miniButton.highlight = highlight
    
    -- Track whether the OSD was already shown before hover
    miniButton.osdWasShown = false
    
    -- Create a simpler dropdown menu implementation
    self:CreateMinimapDropdown(miniButton)
    
    -- Set up scripts
    miniButton:SetScript("OnEnter", function()
        -- Store whether OSD was already shown
        miniButton.osdWasShown = TWRA.OSD and TWRA.OSD.shown or false
        
        -- Show OSD permanently (no auto-hide)
        if TWRA.ShowOSDPermanent then
            TWRA:ShowOSDPermanent()
        elseif TWRA.ShowOSD then
            -- If ShowOSDPermanent doesn't exist, use ShowOSD directly
            TWRA:ShowOSD(9999) -- Very long duration effectively makes it permanent
        end
        
        -- Debug the navigation state
        if TWRA.navigation then
            if TWRA.navigation.handlers and type(TWRA.navigation.handlers) == "table" then
                local count = table.getn(TWRA.navigation.handlers)
                TWRA:Debug("ui", "Minimap hover - found " .. count .. " navigation handlers")
                
                -- Print the first few section names for debugging
                if count > 0 then
                    local debugStr = "First sections: "
                    for i=1, math.min(3, count) do
                        debugStr = debugStr .. i .. "=" .. TWRA.navigation.handlers[i] .. ", "
                    end
                    TWRA:Debug("ui", debugStr)
                else
                    TWRA:Debug("ui", "WARNING: Navigation handlers array is empty!")
                    -- Force log to chat for visibility
                    DEFAULT_CHAT_FRAME:AddMessage("|cFFFF3333TWRA:|r No sections found - navigation array is empty")
                end
            else
                TWRA:Debug("ui", "WARNING: Navigation handlers is nil or not a table")
                DEFAULT_CHAT_FRAME:AddMessage("|cFFFF3333TWRA:|r Navigation handlers missing or invalid")
            end
        else
            TWRA:Debug("ui", "WARNING: Navigation object is nil")
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF3333TWRA:|r Navigation object missing")
        end
        
        -- Display the dropdown
        if miniButton.dropdown then
            miniButton:ShowDropdown()
        end
        
        -- Show tooltip
        GameTooltip:SetOwner(miniButton, "ANCHOR_LEFT")
        GameTooltip:AddLine("TWRA - Raid Assignments")
        GameTooltip:AddLine("Left-click: Toggle assignments window", 1, 1, 1)
        GameTooltip:AddLine("Right-click: Toggle options", 1, 1, 1)
        GameTooltip:AddLine("Mousewheel: Navigate sections", 1, 1, 1)
        GameTooltip:AddLine("Drag: Move button", 1, 1, 1)
        GameTooltip:Show()
    end)
    
    miniButton:SetScript("OnLeave", function()
        -- Hide tooltip
        GameTooltip:Hide()
        
        -- Use a slight delay before hiding dropdown to allow mouse to move to it
        miniButton.hideTimer = miniButton.hideTimer or CreateFrame("Frame")
        miniButton.hideTimer:SetScript("OnUpdate", function()
            -- Check if mouse is over dropdown
            if not MouseIsOver(miniButton.dropdown) and not MouseIsOver(miniButton) then
                miniButton.dropdown:Hide()
                miniButton.hideTimer:SetScript("OnUpdate", nil)
                
                -- Instead of hiding the OSD, show it with default duration when it wasn't showing before
                if not miniButton.osdWasShown then
                    if TWRA.ShowOSD then
                        TWRA:ShowOSD() -- Use default duration from OSD settings
                    end
                end
            end
        end)
    end)
    
    -- Click handler (left/right click)
    miniButton:SetScript("OnClick", function()
        local button = arg1  -- In WoW 1.12, click button is passed via arg1
        TWRA:Debug("ui", button .. "-click on minimap button")
        
        if button == "RightButton" then
            -- Right-click behavior:
            -- 1. If frame not visible: behave like /twra options
            if not TWRA.mainFrame or not TWRA.mainFrame:IsShown() then
                -- Create frame if it doesn't exist
                if not TWRA.mainFrame and TWRA.CreateMainFrame then
                    TWRA:CreateMainFrame()
                end
                
                -- Show the frame and switch to options view
                if TWRA.mainFrame then
                    TWRA.mainFrame:Show()
                    if TWRA.ShowOptionsView then
                        TWRA:ShowOptionsView()
                    end
                end
            -- 2. If visible with main view: behave like /twra options
            elseif TWRA.currentView ~= "options" then
                -- Just switch to options view
                if TWRA.ShowOptionsView then
                    TWRA:ShowOptionsView()
                end
            -- 3. If visible with options view: Hide the main frame
            else
                -- Hide the main frame if options view is already visible
                TWRA.mainFrame:Hide()
                TWRA:Debug("ui", "Hiding main frame from minimap button")
            end
        else -- LeftButton is the default
            -- Left click: Toggle main frame in main view
            if not TWRA.mainFrame then
                if TWRA.CreateMainFrame then
                    TWRA:CreateMainFrame()
                else
                    DEFAULT_CHAT_FRAME:AddMessage("|cFFFF3333TWRA Error:|r Unable to create main frame")
                    return
                end
            end
            
            -- If frame is shown and already in main view, hide it
            if TWRA.mainFrame:IsShown() and TWRA.currentView == "main" then
                TWRA.mainFrame:Hide()
            else
                -- Otherwise show frame and ensure we're in main view
                TWRA.mainFrame:Show()
                if TWRA.ShowMainView then
                    TWRA:ShowMainView() -- Call the main view function
                else
                    DEFAULT_CHAT_FRAME:AddMessage("|cFFFF3333TWRA Error:|r ShowMainView function not available")
                end
            end
        end
    end)
    
    -- Add mousewheel support to navigate between sections
    miniButton:EnableMouseWheel(true)
    miniButton:SetScript("OnMouseWheel", function()
        local delta = arg1  -- In WoW 1.12, delta is passed via arg1
        
        -- Check if we have navigation handlers
        if not TWRA.navigation or not TWRA.navigation.handlers or table.getn(TWRA.navigation.handlers) == 0 then
            TWRA:Debug("ui", "No sections to navigate through")
            return
        end
        
        -- -- Show a notification of the section being navigated to
        -- local function showSectionNotification(index)
        --     if TWRA.navigation.handlers[index] then
        --         -- Show a brief notification about which section was changed to
        --         local sectionName = TWRA.navigation.handlers[index]
        --         if DEFAULT_CHAT_FRAME and sectionName then
        --             DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF33TWRA:|r Navigating to "..sectionName)
        --         end
        --     end
        -- end
        
        -- Navigate through sections with the mousewheel
        if delta > 0 then
            -- Scroll up - go to previous section
            TWRA:Debug("ui", "Mousewheel up - navigate to previous section")
            
            if TWRA.NavigateHandler then
                TWRA:NavigateHandler(-1)
                
                -- Show section notification
                if TWRA.navigation and TWRA.navigation.currentIndex then
                    showSectionNotification(TWRA.navigation.currentIndex)
                end
                
                -- Make sure OSD is visible when changing sections
                if TWRA.ShowOSD and TWRA.OSD and not TWRA.OSD.shown then
                    TWRA:ShowOSD(3) -- Show OSD briefly
                end
            end
        else
            -- Scroll down - go to next section
            TWRA:Debug("ui", "Mousewheel down - navigate to next section")
            
            if TWRA.NavigateHandler then
                TWRA:NavigateHandler(1)
                
                -- Show section notification
                if TWRA.navigation and TWRA.navigation.currentIndex then
                    showSectionNotification(TWRA.navigation.currentIndex)
                end
                
                -- Make sure OSD is visible when changing sections
                if TWRA.ShowOSD and TWRA.OSD and not TWRA.OSD.shown then
                    TWRA:ShowOSD(3) -- Show OSD briefly
                end
            end
        end
    end)
    
    -- Make the button draggable around the minimap
    miniButton:RegisterForDrag("LeftButton")
    
    -- Variables to track drag state
    miniButton.isDragging = false
    miniButton.dragStartTime = 0
    
    -- Add OnUpdate handler for real-time dragging
    miniButton:SetScript("OnUpdate", function()
        -- Only process if we're currently dragging
        if miniButton.isDragging then
            -- Calculate position around minimap in real-time
            local xpos, ypos = GetCursorPosition()
            local scale = UIParent:GetEffectiveScale()
            xpos = xpos / scale
            ypos = ypos / scale
            
            -- Get minimap center
            local minimapCenterX, minimapCenterY = Minimap:GetCenter()
            
            -- Convert cursor position to angle
            local dx = xpos - minimapCenterX
            local dy = ypos - minimapCenterY
            local angle = math.deg(math.atan2(dy, dx))
            
            -- Position the button along the minimap's edge in real-time
            local radius = 80 -- Distance from center of minimap
            local radian = math.rad(angle)
            local x = math.cos(radian) * radius
            local y = math.sin(radian) * radius
            
            miniButton:ClearAllPoints()
            miniButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
            
            -- Store current angle for OnDragStop to use
            miniButton.currentAngle = angle
        end
    end)
    
    miniButton:SetScript("OnDragStart", function()
        -- Record when the drag started
        miniButton.isDragging = true
        miniButton.dragStartTime = GetTime()
        
        -- Visual feedback
        miniButton:LockHighlight()
        
        -- Hide dropdown while dragging
        if miniButton.dropdown then
            miniButton.dropdown:Hide()
        end
    end)
    
    miniButton:SetScript("OnDragStop", function()
        -- Visual feedback
        miniButton:UnlockHighlight()
        
        -- Get the final angle (already calculated in OnUpdate)
        local angle = miniButton.currentAngle or 180
        
        -- Stop the dragging state
        miniButton.isDragging = false
        
        -- Save the angle in saved variables
        if TWRA_SavedVariables and TWRA_SavedVariables.options then
            TWRA_SavedVariables.options.minimapAngle = angle
        end
        
        -- Check if this was a short drag (click) or a real drag
        local dragDuration = GetTime() - miniButton.dragStartTime
        
        -- If it was a very short drag, treat it as a click
        if dragDuration < 0.2 then
            -- Simulate the click behavior
            local button = "LeftButton" -- It was registered as a left button drag
            TWRA:Debug("ui", "Short drag detected, treating as " .. button .. "-click")
            
            -- Toggle main frame in main view (similar to click handler)
            if not TWRA.mainFrame then
                if TWRA.CreateMainFrame then
                    TWRA:CreateMainFrame()
                else
                    return
                end
            end
            
            -- If frame is shown and already in main view, hide it
            if TWRA.mainFrame:IsShown() and TWRA.currentView == "main" then
                TWRA.mainFrame:Hide()
            else
                -- Otherwise show frame and ensure we're in main view
                TWRA.mainFrame:Show()
                if TWRA.ShowMainView then
                    TWRA:ShowMainView()
                end
            end
        end
    end)
    
    -- Register for section changes to update the highlight in the dropdown menu
    if self.RegisterEvent then
        self:RegisterEvent("SECTION_CHANGED", function(sectionName, currentIndex, totalSections)
            -- Add highly visible debug message to verify event registration
            TWRA:Debug("ui", "MINIMAP SECTION CHANGE DETECTED: Section " .. currentIndex .. 
                      " (" .. sectionName .. ") of " .. totalSections)
            
            -- Always update the minimap dropdown if it's showing
            TWRA.minimapButton.dropdown:UpdateVisibleButtons()
        end, "MinimapDropdownHighlight")
    end
    
    -- Position dropdown based on screen position
    function miniButton:PositionDropdown()
        if not self.dropdown then return end
        
        local x, y = self:GetCenter()
        if not x or not y then return end
        
        local screenWidth = GetScreenWidth()
        local screenHeight = GetScreenHeight()
        
        self.dropdown:ClearAllPoints()
        
        -- Determine which part of the screen the minimap button is in
        local isLeft = (x < screenWidth/2)
        local isBottom = (y < screenHeight/2)
        
        -- Position dropdown based on screen space
        if isBottom then
            -- Bottom half of screen - show dropdown above the minimap button
            if isLeft then
                -- Bottom left - dropdown appears above and to the left
                self.dropdown:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 0)
            else
                -- Bottom right - dropdown appears above and to the right
                self.dropdown:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", 0, 0)
            end
        else
            -- Top half of screen - show dropdown below the minimap button
            if isLeft then
                -- Top left - dropdown appears below and to the left
                self.dropdown:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, 0)
            else
                -- Top right - dropdown appears below and to the right
                self.dropdown:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, 0)
            end
        end
    end
    
    -- Store reference in addon
    self.minimapButton = miniButton
    
    self:Debug("general", "Minimap button created")
    return miniButton
end

-- Create a new dropdown menu with simple navigation instead of scrolling
function TWRA:CreateMinimapDropdown(miniButton)
    if not miniButton then return end
    
    -- Create dropdown main frame
    local dropdown = CreateFrame("Frame", "TWRAMinimapDropdown", UIParent)
    dropdown:SetWidth(180)
    dropdown:SetHeight(300) -- Fixed height
    dropdown:SetFrameStrata("FULLSCREEN_DIALOG") -- Ensure it's above everything
    dropdown:SetFrameLevel(100) -- Very high frame level
    dropdown:SetToplevel(true)
    dropdown:SetClampedToScreen(true)
    dropdown:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 5, right = 5, top = 5, bottom = 5 }
    })
    dropdown:SetBackdropColor(0, 0, 0, 0.9)
    dropdown:SetBackdropBorderColor(1, 1, 1, 0.7)
    dropdown:Hide()
    
    -- Create header
    local title = dropdown:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", dropdown, "TOPLEFT", 10, -10)
    title:SetText("Sections:")
    title:SetTextColor(1, 0.82, 0) -- Gold text for header
    dropdown.title = title
    
    -- Constants for layout
    local MAX_VISIBLE_BUTTONS = 10
    local BUTTON_HEIGHT = 22
    local BUTTON_SPACING = 2
    local CONTENT_PADDING_TOP = 35
    local CONTENT_PADDING_BOTTOM = 30
    
    -- Navigation state
    dropdown.offset = 0 -- Starting offset for visible buttons
    dropdown.buttons = {}
    
    -- Create up arrow button
    local upButton = CreateFrame("Button", nil, dropdown)
    upButton:SetPoint("BOTTOMLEFT", dropdown, "BOTTOMLEFT", 10, 10)
    upButton:SetWidth(20)
    upButton:SetHeight(20)
    upButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollUp-Up")
    upButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollUp-Down")
    upButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    upButton:SetFrameLevel(dropdown:GetFrameLevel() + 5)
    upButton:Hide() -- Initially hidden
    dropdown.upButton = upButton
    
    -- Create down arrow button
    local downButton = CreateFrame("Button", nil, dropdown)
    downButton:SetPoint("BOTTOMRIGHT", dropdown, "BOTTOMRIGHT", -10, 10)
    downButton:SetWidth(20)
    downButton:SetHeight(20)
    downButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
    downButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Down")
    downButton:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    downButton:SetFrameLevel(dropdown:GetFrameLevel() + 5)
    downButton:Hide() -- Initially hidden
    dropdown.downButton = downButton
    
    -- Set click handlers for navigation buttons
    upButton:SetScript("OnClick", function()
        if dropdown.offset <= 0 then return end
        dropdown.offset = dropdown.offset - 1
        dropdown:UpdateVisibleButtons()
    end)
    
    downButton:SetScript("OnClick", function()
        local maxOffset = table.getn(TWRA.navigation.handlers) - MAX_VISIBLE_BUTTONS
        if dropdown.offset >= maxOffset then return end
        dropdown.offset = dropdown.offset + 1
        dropdown:UpdateVisibleButtons()
    end)
    
    -- Function to update which buttons are visible based on current offset
    function dropdown:UpdateVisibleButtons()
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
                button.text:SetText(sectionIndex .. ". " .. sectionName)
                button.sectionIndex = sectionIndex
                
                -- Highlight current section
                if sectionIndex == TWRA.navigation.currentIndex then
                    button.text:SetTextColor(1, 0.82, 0) -- Gold for current section
                    button.bg:SetTexture(0.2, 0.2, 0.4, 0.5) -- Highlight background
                else
                    button.text:SetTextColor(1, 1, 1) -- White for other sections
                    button.bg:SetTexture(0.1, 0.1, 0.1, 0.7) -- Normal background
                end
                
                button:Show()
            else
                button:Hide()
            end
        end
    end
    
    -- Create the section buttons (fixed number)
    for i = 1, MAX_VISIBLE_BUTTONS do
        local button = CreateFrame("Button", "TWRADropdownButton"..i, dropdown)
        button:SetWidth(dropdown:GetWidth() - 20)
        button:SetHeight(BUTTON_HEIGHT)
        button:SetPoint("TOPLEFT", dropdown, "TOPLEFT", 10, -(CONTENT_PADDING_TOP + ((i-1) * (BUTTON_HEIGHT + BUTTON_SPACING))))
        button:SetFrameLevel(dropdown:GetFrameLevel() + 5)
        
        -- Create visible background
        local bg = button:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(button)
        bg:SetTexture(0.1, 0.1, 0.1, 0.7)
        button.bg = bg
        
        -- Create highlight effect
        button:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
        
        -- Create button text
        local text = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        text:SetPoint("LEFT", button, "LEFT", 5, 0)
        text:SetPoint("RIGHT", button, "RIGHT", -5, 0)
        text:SetJustifyH("LEFT")
        text:SetText("Empty")
        button.text = text
        
        -- Store button and set hidden initially
        table.insert(dropdown.buttons, button)
        button:Hide()
        
        -- Click handler added when updating buttons
        button:SetScript("OnClick", function()
            if not button.sectionIndex then return end
            
            -- Navigate to section
            TWRA:Debug("ui", "Clicked section " .. button.sectionIndex)
            TWRA:NavigateToSection(button.sectionIndex, "user")
            
            -- Hide dropdown
            dropdown:Hide()
        end)
    end
    
    -- Mouse leave handling for dropdown
    dropdown:SetScript("OnLeave", function()
        if not MouseIsOver(dropdown) and not MouseIsOver(miniButton) then
            dropdown.hideTimer = dropdown.hideTimer or CreateFrame("Frame")
            dropdown.hideTimer:SetScript("OnUpdate", function()
                if not MouseIsOver(dropdown) and not MouseIsOver(miniButton) then
                    dropdown:Hide()
                    dropdown.hideTimer:SetScript("OnUpdate", nil)
                    
                    -- Instead of hiding the OSD, show it with default duration when it wasn't showing before
                    if not miniButton.osdWasShown and TWRA.ShowOSD then
                        TWRA:ShowOSD() -- Use default duration from OSD settings
                    end
                end
            end)
        end
    end)
    
    -- Enable mousewheel for navigation
    dropdown:EnableMouseWheel(true)
    dropdown:SetScript("OnMouseWheel", function()
        local delta = arg1 -- In WoW 1.12, delta is passed via arg1
        
        if delta > 0 then
            -- Wheel up = navigate up the list (decrease offset)
            if dropdown.offset > 0 then
                dropdown.offset = dropdown.offset - 1
                dropdown:UpdateVisibleButtons()
            end
        else
            -- Wheel down = navigate down the list (increase offset)
            local maxOffset = table.getn(TWRA.navigation.handlers) - MAX_VISIBLE_BUTTONS
            if dropdown.offset < maxOffset then
                dropdown.offset = dropdown.offset + 1
                dropdown:UpdateVisibleButtons()
            end
        end
    end)
    
    -- Store reference in the minimap button
    miniButton.dropdown = dropdown
    
    -- Function for miniButton to show dropdown
    function miniButton:ShowDropdown()
        if not self.dropdown then return end
        
        -- Position the dropdown
        self:PositionDropdown()
        
        -- Reset offset to ensure current section is visible
        if TWRA.navigation and TWRA.navigation.currentIndex then
            -- Calculate appropriate offset to show current section
            local currentIndex = TWRA.navigation.currentIndex
            local maxVisibleIndex = MAX_VISIBLE_BUTTONS
            
            -- Make sure current section is visible in the window
            if currentIndex > maxVisibleIndex then
                self.dropdown.offset = currentIndex - math.floor(maxVisibleIndex / 2)
            else
                self.dropdown.offset = 0
            end
        else
            self.dropdown.offset = 0
        end
        
        -- Update buttons before showing
        self.dropdown:UpdateVisibleButtons()
        
        -- Show the dropdown
        self.dropdown:Show()
    end
    
    return dropdown
end