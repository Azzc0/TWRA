-- Turtle WoW Raid Assignments (TWRA)
-- Minimap button implementation

TWRA = TWRA or {}

-- Initialize the minimap functionality
function TWRA:InitializeMinimapButton()
    -- Create minimap button if it doesn't exist
    if not self.minimapButton then
        self:CreateMinimapButton()
    end
    
    self:Debug("ui", "Minimap button initialized")
    return true
end

-- Create the minimap button
function TWRA:CreateMinimapButton()
    self:Debug("general", "Creating minimap button")
    
    -- Create a frame for our minimap button
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
    icon:SetTexture("Interface\\AddOns\\TWRA\\textures\\minimap_icon")
    
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
    
    -- Create dropdown menu for sections
    miniButton.dropdown = CreateFrame("Frame", "TWRAMinimapDropdown", UIParent) -- Attach to UIParent for better stacking
    miniButton.dropdown:SetWidth(180) -- Wider dropdown for better visibility
    miniButton.dropdown:SetFrameStrata("FULLSCREEN_DIALOG") -- Even higher strata to ensure visibility
    miniButton.dropdown:SetToplevel(true) -- Ensure it stays on top of other UI elements
    miniButton.dropdown:SetClampedToScreen(true) -- Keep it on screen
    
    -- Use GameTooltip style background for better look (reverting to tooltip style)
    miniButton.dropdown:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 5, right = 5, top = 5, bottom = 5 }
    })
    miniButton.dropdown:SetBackdropColor(0, 0, 0, 0.9) -- Darker background for better contrast
    miniButton.dropdown:SetBackdropBorderColor(1, 1, 1, 0.7) -- White border for tooltip style
    
    -- Initial hide
    miniButton.dropdown:Hide()
    
    -- Create dropdown title with larger font
    miniButton.dropdown.title = miniButton.dropdown:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    miniButton.dropdown.title:SetPoint("TOPLEFT", miniButton.dropdown, "TOPLEFT", 10, -10)
    miniButton.dropdown.title:SetText("Sections:")
    miniButton.dropdown.title:SetTextColor(1, 0.82, 0) -- Gold text for header
    
    -- Create a scroll frame to contain all buttons
    miniButton.dropdown.scrollFrame = CreateFrame("ScrollFrame", "TWRAMinimapDropdownScrollFrame", miniButton.dropdown)
    miniButton.dropdown.scrollFrame:SetPoint("TOPLEFT", miniButton.dropdown.title, "BOTTOMLEFT", 0, -5)
    miniButton.dropdown.scrollFrame:SetPoint("BOTTOMRIGHT", miniButton.dropdown, "BOTTOMRIGHT", -5, 5)
    
    -- Create a content frame inside the scroll frame
    miniButton.dropdown.contentFrame = CreateFrame("Frame", "TWRAMinimapDropdownContent", miniButton.dropdown.scrollFrame)
    miniButton.dropdown.contentFrame:SetWidth(165) -- Slightly narrower than scrollFrame to account for scrollbar
    
    -- Assign the content frame to the scroll frame
    miniButton.dropdown.scrollFrame:SetScrollChild(miniButton.dropdown.contentFrame)
    
    -- Create scroll indicators
    miniButton.dropdown.scrollUpIndicator = miniButton.dropdown:CreateTexture(nil, "OVERLAY")
    miniButton.dropdown.scrollUpIndicator:SetTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollUp-Up")
    miniButton.dropdown.scrollUpIndicator:SetWidth(16)
    miniButton.dropdown.scrollUpIndicator:SetHeight(16)
    miniButton.dropdown.scrollUpIndicator:SetPoint("TOPRIGHT", miniButton.dropdown, "TOPRIGHT", -5, -5)
    miniButton.dropdown.scrollUpIndicator:Hide()
    
    miniButton.dropdown.scrollDownIndicator = miniButton.dropdown:CreateTexture(nil, "OVERLAY")
    miniButton.dropdown.scrollDownIndicator:SetTexture("Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up")
    miniButton.dropdown.scrollDownIndicator:SetWidth(16)
    miniButton.dropdown.scrollDownIndicator:SetHeight(16)
    miniButton.dropdown.scrollDownIndicator:SetPoint("BOTTOMRIGHT", miniButton.dropdown, "BOTTOMRIGHT", -5, 5)
    miniButton.dropdown.scrollDownIndicator:Hide()
    
    -- Function to update scroll indicators
    function miniButton.dropdown.UpdateScrollIndicators()
        local scroll = miniButton.dropdown.scrollFrame:GetVerticalScroll()
        local maxScroll = miniButton.dropdown.contentFrame:GetHeight() - miniButton.dropdown.scrollFrame:GetHeight()
        
        -- Only show indicators if we have scrollable content
        if maxScroll <= 0 then
            miniButton.dropdown.scrollUpIndicator:Hide()
            miniButton.dropdown.scrollDownIndicator:Hide()
            return
        end
        
        -- Show/hide up indicator based on scroll position
        if scroll > 0 then -- Changed from 1 to 0 for proper visibility at the top
            miniButton.dropdown.scrollUpIndicator:Show()
        else
            miniButton.dropdown.scrollUpIndicator:Hide()
        end
        
        -- Show/hide down indicator based on scroll position
        if scroll < maxScroll then -- Removed the -1 threshold to ensure indicator visibility
            miniButton.dropdown.scrollDownIndicator:Show()
        else
            miniButton.dropdown.scrollDownIndicator:Hide()
        end
        
        -- Ensure the content is properly positioned within the scroll frame
        miniButton.dropdown.contentFrame:ClearAllPoints()
        miniButton.dropdown.contentFrame:SetPoint("TOPLEFT", miniButton.dropdown.scrollFrame, "TOPLEFT", 0, -scroll)
        miniButton.dropdown.contentFrame:SetPoint("TOPRIGHT", miniButton.dropdown.scrollFrame, "TOPRIGHT", 0, -scroll)
    end
    
    -- Enable mousewheel scrolling on the dropdown
    miniButton.dropdown:EnableMouseWheel(true)
    miniButton.dropdown:SetScript("OnMouseWheel", function()
        local delta = arg1  -- In WoW 1.12, delta is passed via arg1
        local scrollFrame = miniButton.dropdown.scrollFrame
        local scroll = scrollFrame:GetVerticalScroll()
        local maxScroll = miniButton.dropdown.contentFrame:GetHeight() - scrollFrame:GetHeight()
        
        -- Adjust scroll position with smoother steps
        if delta > 0 then -- Scroll up
            scroll = math.max(0, scroll - 30)
        else -- Scroll down
            scroll = math.min(maxScroll, scroll + 30)
        end
        
        scrollFrame:SetVerticalScroll(scroll)
        
        -- Update the scroll indicators and content position
        miniButton.dropdown.UpdateScrollIndicators()
    end)
    
    -- Also enable mousewheel scrolling directly on the scroll frame itself
    miniButton.dropdown.scrollFrame:EnableMouseWheel(true)
    miniButton.dropdown.scrollFrame:SetScript("OnMouseWheel", function()
        -- Use the function we defined above to ensure consistent behavior
        miniButton.dropdown:GetScript("OnMouseWheel")()
    end)
    
    -- Enable mousewheel scrolling on the content frame as well to catch more scroll events
    miniButton.dropdown.contentFrame:EnableMouseWheel(true)
    miniButton.dropdown.contentFrame:SetScript("OnMouseWheel", function()
        -- Use the function we defined above to ensure consistent behavior
        miniButton.dropdown:GetScript("OnMouseWheel")()
    end)
    
    -- Function to position dropdown properly based on screen space
    function miniButton.PositionDropdown()
        local x, y = miniButton:GetCenter()
        if not x or not y then return end
        
        local screenWidth = GetScreenWidth()
        local screenHeight = GetScreenHeight()
        
        miniButton.dropdown:ClearAllPoints()
        
        -- Determine which part of the screen the minimap button is in
        local isLeft = (x < screenWidth/2)
        local isBottom = (y < screenHeight/2)
        
        -- Position dropdown based on screen space - with CORRECTED left/right logic
        if isBottom then
            -- Bottom half of screen - show dropdown above the minimap button
            if isLeft then
                -- Bottom left - dropdown appears above and LEFT (corrected)
                miniButton.dropdown:SetPoint("BOTTOMLEFT", miniButton, "TOPLEFT", 0, 0)
            else
                -- Bottom right - dropdown appears above and RIGHT (corrected)
                miniButton.dropdown:SetPoint("BOTTOMRIGHT", miniButton, "TOPRIGHT", 0, 0)
            end
        else
            -- Top half of screen - show dropdown below the minimap button
            if isLeft then
                -- Top left - dropdown appears below and LEFT (corrected)
                miniButton.dropdown:SetPoint("TOPLEFT", miniButton, "BOTTOMLEFT", 0, 0)
            else
                -- Top right - dropdown appears below and RIGHT (corrected)
                miniButton.dropdown:SetPoint("TOPRIGHT", miniButton, "BOTTOMRIGHT", 0, 0)
            end
        end
    end
    
    -- Function to populate sections dropdown
    function miniButton.PopulateSections()
        -- Clear any existing buttons first
        if miniButton.dropdown.buttons then
            for _, button in ipairs(miniButton.dropdown.buttons) do
                button:Hide()
                button:SetParent(nil)
            end
        end
        
        miniButton.dropdown.buttons = {}
        
        -- Ensure the dropdown is fully updated before adding content
        miniButton.dropdown:SetFrameLevel(miniButton:GetFrameLevel() + 10)
        
        -- Check if we have sections to show
        if not TWRA.navigation or not TWRA.navigation.handlers or table.getn(TWRA.navigation.handlers) == 0 then
            local noSections = miniButton.dropdown.contentFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            noSections:SetPoint("TOP", miniButton.dropdown.title, "BOTTOM", 0, -5)
            noSections:SetText("No sections available")
            table.insert(miniButton.dropdown.buttons, noSections)
            
            -- Adjust dropdown height
            miniButton.dropdown:SetHeight(50)
            return
        end
        
        -- Add section buttons
        local lastElement = miniButton.dropdown.title
        local totalHeight = 30 -- Starting height for title and padding
        
        for i, sectionName in ipairs(TWRA.navigation.handlers) do
            local button = CreateFrame("Button", "TWRADropdownButton"..i, miniButton.dropdown.contentFrame)
            button:SetWidth(160) -- Wider buttons
            button:SetHeight(22) -- Taller buttons
            button:SetPoint("TOPLEFT", lastElement, "BOTTOMLEFT", 0, -5)
            
            -- Set appropriate frame level
            button:SetFrameLevel(miniButton.dropdown:GetFrameLevel() + 5)
            
            -- Create background texture for highlighting
            local bg = button:CreateTexture(nil, "BACKGROUND")
            bg:SetTexture("Interface\\Buttons\\UI-Listbox-Highlight")
            bg:SetBlendMode("ADD")
            bg:SetAllPoints(button)
            bg:SetAlpha(0) -- Start hidden
            button.bg = bg
            
            -- Create selection texture (persistent highlight for current section)
            local selection = button:CreateTexture(nil, "BACKGROUND")
            selection:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
            selection:SetBlendMode("ADD")
            selection:SetAllPoints(button)
            selection:SetAlpha(0) -- Start hidden
            button.selection = selection
            
            -- Add section text with larger font - ensure it's above backdrop
            local text = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            text:SetPoint("LEFT", button, "LEFT", 5, 0)
            text:SetText(sectionName)
            text:SetJustifyH("LEFT")
            button.text = text
            
            -- Truncate long section names
            if string.len(sectionName) > 22 then
                text:SetText(string.sub(sectionName, 1, 19) .. "...")
            end
            
            -- Set click handler to navigate to this section
            button:SetScript("OnClick", function()
                TWRA:NavigateToSection(i)
                -- If OSD isn't shown permanently, hide it after selection
                if not TWRA.OSD or not TWRA.OSD.shown then
                    if TWRA.HideOSD then TWRA:HideOSD() end
                end
                miniButton.dropdown:Hide()
            end)
            
            -- Add mouse over highlight
            button:SetScript("OnEnter", function()
                button.bg:SetAlpha(1) -- Show hover highlight
                GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
                GameTooltip:SetText(sectionName)
                GameTooltip:Show()
            end)
            
            button:SetScript("OnLeave", function()
                button.bg:SetAlpha(0) -- Hide hover highlight
                GameTooltip:Hide()
            end)
            
            -- Highlight current section with both text color and background highlight
            if TWRA.navigation.currentIndex == i then
                text:SetTextColor(1, 0.82, 0) -- Gold text for current section
                button.selection:SetAlpha(0.3) -- Show selection highlight with reduced opacity
            end
            
            table.insert(miniButton.dropdown.buttons, button)
            lastElement = button
            totalHeight = totalHeight + 27 -- Height of each button + spacing
        end
        
        -- Adjust dropdown height based on content
        miniButton.dropdown.contentFrame:SetHeight(totalHeight + 15)
        miniButton.dropdown:SetHeight(math.min(300, totalHeight + 15)) -- Max height of 300
        
        -- Force dropdown to render properly
        miniButton.dropdown:SetAlpha(0.99)
        miniButton.dropdown:SetAlpha(1)
        
        -- Update scroll indicators
        miniButton.dropdown.UpdateScrollIndicators()
    end
    
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
        
        -- Populate and position dropdown
        miniButton.PopulateSections()
        miniButton.PositionDropdown()
        miniButton.dropdown:Show()
        
        -- Ensure dropdown is above other frames
        miniButton.dropdown:SetFrameLevel(miniButton:GetFrameLevel() + 10)
        
        -- Force immediate rendering update to prevent first-time display issues
        miniButton.dropdown:SetAlpha(0.999)
        miniButton.dropdown:SetAlpha(1)
        
        -- Show tooltip
        GameTooltip:SetOwner(miniButton, "ANCHOR_LEFT")
        GameTooltip:AddLine("TWRA - Raid Assignments")
        GameTooltip:AddLine("Left-click: Toggle assignments window", 1, 1, 1)
        GameTooltip:AddLine("Right-click: Toggle options", 1, 1, 1)
        GameTooltip:AddLine("Mousewheel: Navigate sections", 1, 1, 1)
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
                
                -- Hide OSD if it wasn't shown before
                if not miniButton.osdWasShown then
                    if TWRA.HideOSD then
                        TWRA:HideOSD()
                    end
                end
            end
        end)
    end)
    
    -- Add mouse leave to dropdown as well
    miniButton.dropdown:SetScript("OnLeave", function()
        if not MouseIsOver(miniButton) then
            miniButton.hideTimer = miniButton.hideTimer or CreateFrame("Frame")
            miniButton.hideTimer:SetScript("OnUpdate", function()
                if not MouseIsOver(miniButton.dropdown) and not MouseIsOver(miniButton) then
                    miniButton.dropdown:Hide()
                    miniButton.hideTimer:SetScript("OnUpdate", nil)
                    
                    -- Hide OSD if it wasn't shown before
                    if not miniButton.osdWasShown then
                        if TWRA.HideOSD then
                            TWRA:HideOSD()
                        end
                    end
                end
            end)
        end
    end)
    
    -- Updated click handler to use 'this' instead of 'self' to properly work in WoW 1.12
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
        
        -- Show a notification of the section being navigated to
        local function showSectionNotification(index)
            if TWRA.navigation.handlers[index] then
                -- Show a brief notification about which section was changed to
                local sectionName = TWRA.navigation.handlers[index]
                if DEFAULT_CHAT_FRAME and sectionName then
                    DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF33TWRA:|r Navigating to "..sectionName)
                end
            end
        end
        
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
    
    -- Make the button draggable
    miniButton:RegisterForDrag("LeftButton")
    miniButton:SetScript("OnDragStart", function()
        this:LockHighlight()
        this:StartMoving()
        -- Hide dropdown while dragging
        miniButton.dropdown:Hide()
    end)
    miniButton:SetScript("OnDragStop", function()
        this:StopMovingOrSizing()
        this:UnlockHighlight()
        
        -- Calculate and save angle
        local x, y = this:GetCenter()
        local mx, my = Minimap:GetCenter()
        local angle = math.deg(math.atan2(y - my, x - mx))
        
        -- Save to settings
        if TWRA_SavedVariables and TWRA_SavedVariables.options then
            TWRA_SavedVariables.options.minimapAngle = angle
        end
    end)
    
    -- Store reference in addon
    self.minimapButton = miniButton
    
    self:Debug("general", "Minimap button created")
    return miniButton
end

-- Helper function to update the minimap button with current section information
function TWRA:UpdateMinimapButton()
    if not self.minimapButton then return end
    
    -- If we have a dropdown and it's shown, update it
    if self.minimapButton.dropdown and self.minimapButton.dropdown:IsShown() then
        self.minimapButton.PopulateSections()
    end
    
    self:Debug("ui", "Minimap button updated")
end

-- Helper function to toggle the minimap button visibility
function TWRA:ToggleMinimapButton()
    if not self.minimapButton then
        self:CreateMinimapButton()
        self:Debug("ui", "Created and showing minimap button")
        return
    end
    
    if self.minimapButton:IsShown() then
        self.minimapButton:Hide()
        self:Debug("ui", "Minimap button hidden")
    else
        self.minimapButton:Show()
        self:Debug("ui", "Minimap button shown")
    end
end