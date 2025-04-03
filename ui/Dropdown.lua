-- TWRA Dropdown Menu Implementation
TWRA = TWRA or {}
TWRA.UI = TWRA.UI or {}

-- Create a standardized dropdown button with consistent styling
function TWRA.UI:CreateStandardDropdown(parent, width, height)
    -- Create container frame
    local dropdown = {
        container = CreateFrame("Frame", nil, parent)
    }
    
    dropdown.container:SetWidth(width or 200)
    dropdown.container:SetHeight(height or 20)
    
    -- Create the dropdown button
    dropdown.button = CreateFrame("Button", nil, dropdown.container)
    dropdown.button:SetAllPoints()
    
    -- Add background to dropdown button
    dropdown.background = dropdown.button:CreateTexture(nil, "BACKGROUND")
    dropdown.background:SetAllPoints()
    dropdown.background:SetTexture(0.1, 0.1, 0.1, 0.7)
    
    -- Add glow highlight (same as the standard UI highlight texture)
    dropdown.button:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    
    -- Add text display
    dropdown.text = dropdown.button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dropdown.text:SetPoint("LEFT", dropdown.button, "LEFT", 8, 0)
    dropdown.text:SetPoint("RIGHT", dropdown.button, "RIGHT", -16, 0) -- Leave room for arrow
    dropdown.text:SetJustifyH("CENTER")
    dropdown.text:SetText("")
    
    -- Add dropdown arrow indicator
    dropdown.arrow = dropdown.button:CreateTexture(nil, "OVERLAY")
    dropdown.arrow:SetTexture("Interface\\ChatFrame\\ChatFrameExpandArrow")
    dropdown.arrow:SetWidth(16)
    dropdown.arrow:SetHeight(16)
    dropdown.arrow:SetPoint("RIGHT", dropdown.button, "RIGHT", -2, 0)
    
    -- Create the dropdown menu panel
    dropdown.menu = CreateFrame("Frame", nil, parent)
    dropdown.menu:SetFrameStrata("DIALOG")
    dropdown.menu:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 32,
        edgeSize = 16,
        insets = { left = 5, right = 5, top = 5, bottom = 5 }
    })
    dropdown.menu:Hide()
    dropdown.menu.items = {}
    
    -- Method to set menu items
    function dropdown:SetItems(items, callback)
        self.items = items
        self.callback = callback
        
        -- Clear existing menu items
        for _, item in pairs(self.menu.items) do
            if item and item.Hide then
                item:Hide()
            end
        end
        self.menu.items = {}
        
        -- Create menu items
        if items and table.getn(items) > 0 then
            -- Calculate menu height
            local itemHeight = 20
            local padding = 10  -- 5px top and bottom
            local menuHeight = (itemHeight * table.getn(items)) + padding
            self.menu:SetHeight(menuHeight)
            self.menu:SetWidth(self.container:GetWidth())
            
            local yOffset = -5
            
            for i = 1, table.getn(items) do
                local itemData = items[i]
                local button = CreateFrame("Button", nil, self.menu)
                button:SetHeight(itemHeight)
                button:SetPoint("TOPLEFT", self.menu, "TOPLEFT", 5, yOffset)
                button:SetPoint("TOPRIGHT", self.menu, "TOPRIGHT", -5, yOffset)
                
                -- Add highlight texture for the entire button area
                button:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
                
                -- Add a separate highlight for mouseover effect
                local highlightTexture = button:CreateTexture(nil, "HIGHLIGHT")
                highlightTexture:SetAllPoints()
                highlightTexture:SetTexture(1, 1, 1, 0.3)
                
                -- Add item text
                local text = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                text:SetPoint("LEFT", button, "LEFT", 5, 0)
                text:SetPoint("RIGHT", button, "RIGHT", -5, 0)
                text:SetJustifyH("LEFT")
                text:SetText(itemData.text or itemData.name or "Unknown")
                button.text = text  -- Store reference to text for coloring
                
                -- Store item data
                button.itemData = itemData
                button.index = i
                
                -- Click handler
                button:SetScript("OnClick", function()
                    self:SetSelectedItem(this.index)
                    self:Hide()
                    if self.callback then
                        self.callback(this.itemData, this.index)
                    end
                end)
                
                -- Add hover handlers for better feedback
                button:SetScript("OnEnter", function()
                    this.text:SetTextColor(1, 1, 1)  -- Full bright on hover
                end)
                
                button:SetScript("OnLeave", function()
                    -- Only revert if not selected item
                    if self.selectedIndex ~= this.index then
                        this.text:SetTextColor(0.8, 0.8, 0.8)  -- Default color
                    else
                        this.text:SetTextColor(1, 0.82, 0)  -- Gold for selected item
                    end
                end)
                
                -- Default text color
                text:SetTextColor(self.selectedIndex == i and 1, 0.82, 0 or 0.8, 0.8, 0.8)
                
                table.insert(self.menu.items, button)
                yOffset = yOffset - itemHeight
            end
        end
    end
    
    -- Method to set selected item
    function dropdown:SetSelectedItem(index, suppressCallback)
        if not self.items or index > table.getn(self.items) then return end
        
        local selectedItem = self.items[index]
        if selectedItem then
            self.text:SetText(selectedItem.text or selectedItem.name or "Unknown")
            self.selectedIndex = index
            
            -- Update all item text colors
            for i, menuItem in ipairs(self.menu.items) do
                if menuItem.text then
                    if i == index then
                        menuItem.text:SetTextColor(1, 0.82, 0)  -- Gold for selected
                    else
                        menuItem.text:SetTextColor(0.8, 0.8, 0.8)  -- Normal text
                    end
                end
            end
            
            -- Call callback if needed
            if not suppressCallback and self.callback then
                self.callback(selectedItem, index)
            end
        end
    end
    
    -- Method to toggle dropdown visibility
    function dropdown:Toggle()
        if self.menu:IsShown() then
            self:Hide()
        else
            self:Show()
        end
    end
    
    -- Method to show dropdown
    function dropdown:Show()
        -- Close all other dropdowns first
        TWRA.UI:CloseAllDropdowns(self)
        
        -- Position dropdown under button
        self.menu:ClearAllPoints()
        self.menu:SetPoint("TOP", self.button, "BOTTOM", 0, -2)
        self.menu:Show()
        
        -- Make sure items are properly created before highlighting
        if self.items and table.getn(self.items) > 0 then
            -- Highlight currently selected item
            if self.selectedIndex and self.menu.items and self.menu.items[self.selectedIndex] then
                local selectedText = self.menu.items[self.selectedIndex]:GetFontString()
                if selectedText then
                    selectedText:SetTextColor(1, 0.82, 0) -- Gold color for selected item
                end
            end
        end
        
        -- Show click capture if it exists
        if TWRA.UI.clickCapture then
            TWRA.UI.clickCapture:Show()
        end
    end
    
    -- Method to hide dropdown
    function dropdown:Hide()
        self.menu:Hide()
        
        -- Hide click capture if it exists
        if TWRA.UI.clickCapture then
            TWRA.UI.clickCapture:Hide()
        end
    end
    
    -- Setup click handling
    dropdown.button:SetScript("OnClick", function()
        dropdown:Toggle()
    end)
    
    -- Prevent clicks on the dropdown from closing it
    dropdown.menu:SetScript("OnMouseDown", function()
        -- This stops the click from propagating to the parent frame
        return
    end)
    
    -- Store the dropdown in a global registry for management
    TWRA.UI.dropdowns = TWRA.UI.dropdowns or {}
    table.insert(TWRA.UI.dropdowns, dropdown)
    
    return dropdown
end

-- Close all dropdowns except the provided one
function TWRA.UI:CloseAllDropdowns(exceptDropdown)
    if not self.dropdowns then return end
    
    for i = 1, table.getn(self.dropdowns) do
        local dropdown = self.dropdowns[i]
        if dropdown ~= exceptDropdown and dropdown.menu and dropdown.menu:IsShown() then
            dropdown:Hide()
        end
    end
    
    TWRA:Debug("ui", "All dropdowns closed except active selection")
end

-- Add a global click handler to close dropdowns when clicking elsewhere
function TWRA.UI:SetupGlobalClickHandler()
    if self.globalClickHandlerSet then return end
    
    -- Create a special frame that covers the entire screen
    local clickCapture = CreateFrame("Frame", "TWRA_DropdownClickCapture")
    clickCapture:SetFrameStrata("TOOLTIP") -- Above most UI elements but below dropdowns
    clickCapture:SetAllPoints(UIParent)
    clickCapture:EnableMouse(true)
    clickCapture:Hide()
    
    -- Use standard event handling instead of HookScript
    clickCapture:SetScript("OnMouseDown", function()
        -- Close all dropdowns
        TWRA.UI:CloseAllDropdowns()
        -- Hide the click capture frame
        clickCapture:Hide()
    end)
    
    -- Store the capture frame for later use
    self.clickCapture = clickCapture
    
    -- Fix the Show method to properly display clickCapture
    self.originalDropdownShow = self.dropdowns[1] and self.dropdowns[1].Show
    
    for i = 1, table.getn(self.dropdowns) do
        local dropdown = self.dropdowns[i]
        if dropdown then
            -- Store original Show method reference
            dropdown.originalShow = dropdown.Show
            
            -- Replace Show method
            dropdown.Show = function(self)
                -- Call original method
                self:originalShow()
                
                -- Show click capture behind the menu
                if TWRA.UI.clickCapture then
                    TWRA.UI.clickCapture:Show()
                end
            end
            
            -- Store original Hide method reference
            dropdown.originalHide = dropdown.Hide
            
            -- Replace Hide method
            dropdown.Hide = function(self)
                -- Call original method
                self:originalHide()
                
                -- Hide click capture
                if TWRA.UI.clickCapture then
                    TWRA.UI.clickCapture:Hide()
                end
            end
        end
    end
    
    self.globalClickHandlerSet = true
end

-- Initialize dropdowns system
function TWRA.UI:InitializeDropdowns()
    self.dropdowns = self.dropdowns or {}
    self:SetupGlobalClickHandler()
    TWRA:Debug("ui", "Dropdown system initialized")
end
