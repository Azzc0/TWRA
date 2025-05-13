-- TWRA Options-General Module
-- Left column of the options panel: General settings and keybindings
TWRA = TWRA or {}

-- Load this options component
function TWRA:LoadOptionsGeneral()
    self:Debug("general", "Loading General options component")
    
    -- Register this component in the options system
    if not self.optionsComponents then
        self.optionsComponents = {}
    end
    
    self.optionsComponents.general = {
        name = "General",
        create = function(column) return self:CreateOptionsGeneralColumn(column) end
    }
end

-- Create the General options column content
function TWRA:CreateOptionsGeneralColumn(leftColumn)
    self:Debug("ui", "Creating General options column")
    
    -- Column title
    local syncTitle = leftColumn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    syncTitle:SetPoint("TOPLEFT", leftColumn, "TOPLEFT", 0, 0)
    syncTitle:SetText("General")
    table.insert(self.optionsElements, syncTitle)
    
    -- Announcement Channel
    local channelLabel = leftColumn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    channelLabel:SetPoint("TOPLEFT", syncTitle, "BOTTOMLEFT", 0, -10)
    channelLabel:SetText("Announce:")
    table.insert(self.optionsElements, channelLabel)

    -- Create a menu button styled like the main view dropdown
    local channelButton = CreateFrame("Button", "TWRA_ChannelButton", leftColumn)
    channelButton:SetWidth(130)
    channelButton:SetHeight(22)
    channelButton:SetPoint("LEFT", channelLabel, "RIGHT", 5, 0)
    
    -- Add background to channel button
    local menuBg = channelButton:CreateTexture(nil, "BACKGROUND")
    menuBg:SetAllPoints()
    menuBg:SetTexture(0.1, 0.1, 0.1, 0.7)
    
    -- Menu button text
    local menuText = channelButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    menuText:SetPoint("LEFT", 8, 0)
    menuText:SetPoint("RIGHT", -16, 0)  -- Leave room for dropdown arrow
    menuText:SetJustifyH("LEFT")
    
    -- Dropdown arrow indicator
    local dropdownArrow = channelButton:CreateTexture(nil, "OVERLAY")
    dropdownArrow:SetTexture("Interface\\ChatFrame\\ChatFrameExpandArrow")
    dropdownArrow:SetWidth(16)
    dropdownArrow:SetHeight(16)
    dropdownArrow:SetPoint("RIGHT", -2, 0)
    
    -- Set initial text based on saved options
    local selectedValue = TWRA_SavedVariables.options and TWRA_SavedVariables.options.announceChannel or "GROUP"
    local customChannel = TWRA_SavedVariables.options and TWRA_SavedVariables.options.customChannel or ""
    
    local buttonText = "Group (Default)"
    if selectedValue == "CHANNEL" and customChannel ~= "" then
        buttonText = customChannel
    end
    
    menuText:SetText(buttonText)
    
    -- Create the dropdown menu with similar style as the main view dropdown
    local dropdownMenu = CreateFrame("Frame", "TWRA_ChannelDropdown", self.mainFrame) 
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
    
    -- Create option buttons in the dropdown
    local function CreateOption(text, value, yOffset)
        local button = CreateFrame("Button", nil, dropdownMenu)
        button:SetHeight(20)
        button:SetPoint("TOPLEFT", dropdownMenu, "TOPLEFT", 5, yOffset)
        button:SetPoint("TOPRIGHT", dropdownMenu, "TOPRIGHT", -5, yOffset)
        
        -- Highlight texture
        button:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
        
        -- Button text
        local buttonText = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        buttonText:SetPoint("LEFT", 5, 0)
        buttonText:SetPoint("RIGHT", -5, 0)
        buttonText:SetJustifyH("LEFT")
        buttonText:SetText(text)
        
        -- Click handler
        button:SetScript("OnClick", function()
            -- Update saved value
            if not TWRA_SavedVariables.options then
                TWRA_SavedVariables.options = {}
            end
            
            if value == "CHANNEL" then
                -- For predefined custom channels, set directly
                TWRA_SavedVariables.options.announceChannel = "CHANNEL"
                TWRA_SavedVariables.options.customChannel = text
                menuText:SetText(text)
            else
                TWRA_SavedVariables.options.announceChannel = value
                menuText:SetText(text)
            end
            
            -- Hide dropdown
            dropdownMenu:Hide()
        end)
        
        return button
    end
    
    -- Helper function to get custom channels
    local function GetCustomChannels()
        local customChannels = {}
        
        -- Get custom channels using GetChannelName
        for i = 1, 10 do
            local id, name = GetChannelName(i)
            if id > 0 and name and name ~= "" then
                -- Skip default channels like General, Trade, LookingForGroup, etc.
                local isDefault = false
                if string.find(name, "General") or 
                   string.find(name, "Trade") or 
                   string.find(name, "LocalDefense") or 
                   string.find(name, "WorldDefense") or 
                   string.find(name, "LookingForGroup") or
                   name == "World" then
                    isDefault = true
                end
                
                if not isDefault then
                    table.insert(customChannels, name)
                end
            end
        end
        
        -- Sort channels alphabetically
        table.sort(customChannels)
        
        return customChannels
    end
    
    -- Store created buttons for reuse
    local dropdownButtons = {}
    
    -- Toggle dropdown visibility when channel button is clicked
    channelButton:SetScript("OnClick", function()
        if dropdownMenu:IsShown() then
            dropdownMenu:Hide()
            return
        end
        
        -- Hide all existing buttons first
        for _, button in pairs(dropdownButtons) do
            button:Hide()
        end
        
        -- Calculate initial y offset
        local yOffset = -10
        
        -- Get current custom channels
        local customChannels = GetCustomChannels()
        
        -- Calculate number of options and dropdown height
        local numOptions = 1 + table.getn(customChannels) -- Group + custom channels
        local dropdownHeight = (numOptions * 20) + 20 -- 20px per option + padding
        
        -- Create or reuse the "Group" option button
        if not dropdownButtons["group"] then
            dropdownButtons["group"] = CreateOption("Group (Default)", "GROUP", yOffset)
        else
            -- Reuse existing button
            dropdownButtons["group"]:ClearAllPoints()
            dropdownButtons["group"]:SetPoint("TOPLEFT", dropdownMenu, "TOPLEFT", 5, yOffset)
            dropdownButtons["group"]:SetPoint("TOPRIGHT", dropdownMenu, "TOPRIGHT", -5, yOffset)
            dropdownButtons["group"]:Show()
        end
        yOffset = yOffset - 20
        
        -- Add custom channels
        for _, channelName in ipairs(customChannels) do
            if not dropdownButtons[channelName] then
                dropdownButtons[channelName] = CreateOption(channelName, "CHANNEL", yOffset)
            else
                -- Reuse existing button
                dropdownButtons[channelName]:ClearAllPoints()
                dropdownButtons[channelName]:SetPoint("TOPLEFT", dropdownMenu, "TOPLEFT", 5, yOffset)
                dropdownButtons[channelName]:SetPoint("TOPRIGHT", dropdownMenu, "TOPRIGHT", -5, yOffset)
                dropdownButtons[channelName]:Show()
            end
            yOffset = yOffset - 20
        end
        
        -- Position dropdown directly below the button
        dropdownMenu:ClearAllPoints()
        dropdownMenu:SetPoint("TOPLEFT", channelButton, "BOTTOMLEFT", 0, -2)
        dropdownMenu:SetWidth(130)
        dropdownMenu:SetHeight(dropdownHeight)
        dropdownMenu:Show()
    end)
    
    -- Close dropdown when clicking elsewhere
    dropdownMenu:SetScript("OnMouseDown", function(self, button)
        -- This stops the click from propagating to the parent frame
        return
    end)
    
    -- Store reference for later hiding
    self.channelDropdown = dropdownMenu
    
    -- Add info icon for channel selection
    local channelIcon, channelIconFrame = self.UI:CreateIconWithTooltip(
        leftColumn,
        "Interface\\TutorialFrame\\TutorialFrame-QuestionMark",
        "Announcement Channel",
        "Select where raid assignments will be announced. Group will use raid or party chat depending on your current group type.",
        channelButton,
        5, 22, 22
    )
    
    channelIcon:ClearAllPoints()
    channelIcon:SetPoint("LEFT", channelButton, "RIGHT", 5, 0)
    
    table.insert(self.optionsElements, channelIcon)
    table.insert(self.optionsElements, channelIconFrame)
    
    -- Section Sync Option
    local liveSync, liveSyncText = self:CreateCheckbox(leftColumn, "Section Sync", "TOPLEFT", channelLabel, "BOTTOMLEFT", 0, -15)
    table.insert(self.optionsElements, liveSync)
    table.insert(self.optionsElements, liveSyncText)
    
    -- Tank Sync Option
    local tankSyncCheckbox, tankSyncText = self:CreateCheckbox(leftColumn, "Tank Sync", "TOPLEFT", liveSync, "BOTTOMLEFT", 0, -3)
    table.insert(self.optionsElements, tankSyncCheckbox)
    table.insert(self.optionsElements, tankSyncText)
    
    -- Add info icon for tank sync
    local tankSyncIcon, tankSyncIconFrame = self.UI:CreateIconWithTooltip(
        leftColumn,
        "Interface\\TutorialFrame\\TutorialFrame-QuestionMark",
        "Tank Sync Requires oRA2",
        "When enabled, tanks will be automatically assigned in oRA2 based on the currently selected section.",
        tankSyncText,
        5, 22, 22
    )
    
    tankSyncIcon:ClearAllPoints()
    tankSyncIcon:SetPoint("LEFT", tankSyncText, "RIGHT", 5, 0)
    
    table.insert(self.optionsElements, tankSyncIcon)
    table.insert(self.optionsElements, tankSyncIconFrame)
    
    -- AutoNavigate Option
    local autoNavigate, autoNavigateText = self:CreateCheckbox(leftColumn, "AutoNavigate", "TOPLEFT", tankSyncCheckbox, "BOTTOMLEFT", 0, -3)
    table.insert(self.optionsElements, autoNavigate)
    table.insert(self.optionsElements, autoNavigateText)
    
    -- Add info icon for autonavigate
    local autoNavIcon, autoNavIconFrame = self.UI:CreateIconWithTooltip(
        leftColumn,
        "Interface\\TutorialFrame\\TutorialFrame-QuestionMark",
        "AutoNavigate (Requires SuperWoW)",
        "Automatically navigate to the appropriate section based on raid markers or target selection.",
        autoNavigateText,
        5, 22, 22
    )
    
    autoNavIcon:ClearAllPoints()
    autoNavIcon:SetPoint("LEFT", autoNavigateText, "RIGHT", 5, 0)
    
    table.insert(self.optionsElements, autoNavIcon)
    table.insert(self.optionsElements, autoNavIconFrame)
    
    -- Add keybinding options header
    local keybindHeader = leftColumn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    keybindHeader:SetPoint("TOPLEFT", autoNavigate, "BOTTOMLEFT", 0, -5)
    keybindHeader:SetText("Keybindings:")
    table.insert(self.optionsElements, keybindHeader)
    
    -- Define label width for uniform presentation
    local labelWidth = 100
    
    -- ==== TOGGLE FRAME KEYBINDING ====
    -- Create keybinding label for Toggle Frame
    local toggleFrameLabel = leftColumn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    toggleFrameLabel:SetPoint("TOPLEFT", keybindHeader, "BOTTOMLEFT", 5, -5)
    toggleFrameLabel:SetText("Toggle Frame:")
    toggleFrameLabel:SetWidth(labelWidth)
    toggleFrameLabel:SetJustifyH("LEFT")
    table.insert(self.optionsElements, toggleFrameLabel)
    
    -- Get current binding for Toggle Frame
    local currentBinding = GetBindingKey("TWRA_TOGGLE")
    
    -- Create keybinding button for Toggle Main Frame (smaller size)
    local toggleFrameKey = CreateFrame("Button", "TWRA_ToggleFrameKeyButton", leftColumn, "UIPanelButtonTemplate")
    toggleFrameKey:SetWidth(80)
    toggleFrameKey:SetHeight(20)
    toggleFrameKey:SetPoint("LEFT", toggleFrameLabel, "RIGHT", 5, 0)
    toggleFrameKey:SetText(currentBinding or "Not bound")
    toggleFrameKey:SetTextColor(1, 0.82, 0, 1) -- Gold color for key bindings
    table.insert(self.optionsElements, toggleFrameKey)
    
    -- Add handler for the keybinding button
    toggleFrameKey:SetScript("OnClick", function()
        -- Use the keybinding system from Bindings.lua
        if self.StartKeyBinding then
            self:Debug("general", "Starting key binding for Toggle function")
            self:StartKeyBinding("TOGGLE", "Toggle Frame", function(key)
                -- No need to update here, UpdateKeyBindingDisplay will handle it
            end)
        else
            -- Fallback if Bindings.lua hasn't been loaded
            self:Debug("error", "StartKeyBinding function not found")
            DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA:|r Keybinding system not available.")
        end
    end)
    
    -- ==== NEXT SECTION KEYBINDING ====
    -- Create keybinding label for Next Section
    local nextSectionLabel = leftColumn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    nextSectionLabel:SetPoint("TOPLEFT", toggleFrameKey, "BOTTOMLEFT", -labelWidth-5, -5)
    nextSectionLabel:SetText("Next Section:")
    nextSectionLabel:SetWidth(labelWidth)
    nextSectionLabel:SetJustifyH("LEFT")
    table.insert(self.optionsElements, nextSectionLabel)
    
    -- Get current binding for Next Section
    local nextBinding = GetBindingKey("TWRA_NEXT")
    
    -- Create keybinding button for Next Section
    local nextSectionKey = CreateFrame("Button", "TWRA_NextSectionKeyButton", leftColumn, "UIPanelButtonTemplate")
    nextSectionKey:SetWidth(80)
    nextSectionKey:SetHeight(20)
    nextSectionKey:SetPoint("LEFT", nextSectionLabel, "RIGHT", 5, 0)
    nextSectionKey:SetText(nextBinding or "Not bound")
    nextSectionKey:SetTextColor(1, 0.82, 0, 1) -- Gold color for key bindings
    table.insert(self.optionsElements, nextSectionKey)
    
    -- Add handler for the keybinding button
    nextSectionKey:SetScript("OnClick", function()
        if self.StartKeyBinding then
            self:Debug("general", "Starting key binding for Next function")
            self:StartKeyBinding("NEXT", "Next Section", function(key)
                -- No need to update here, UpdateKeyBindingDisplay will handle it
            end)
        else
            self:Debug("error", "StartKeyBinding function not found")
            DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA:|r Keybinding system not available.")
        end
    end)
    
    -- ==== PREVIOUS SECTION KEYBINDING ====
    -- Create keybinding label for Previous Section
    local prevSectionLabel = leftColumn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    prevSectionLabel:SetPoint("TOPLEFT", nextSectionKey, "BOTTOMLEFT", -labelWidth-5, -5)
    prevSectionLabel:SetText("Previous Section:")
    prevSectionLabel:SetWidth(labelWidth)
    prevSectionLabel:SetJustifyH("LEFT")
    table.insert(self.optionsElements, prevSectionLabel)
    
    -- Get current binding for Previous Section
    local prevBinding = GetBindingKey("TWRA_PREV")
    
    -- Create keybinding button for Previous Section
    local prevSectionKey = CreateFrame("Button", "TWRA_PrevSectionKeyButton", leftColumn, "UIPanelButtonTemplate")
    prevSectionKey:SetWidth(80)
    prevSectionKey:SetHeight(20)
    prevSectionKey:SetPoint("LEFT", prevSectionLabel, "RIGHT", 5, 0)
    prevSectionKey:SetText(prevBinding or "Not bound")
    prevSectionKey:SetTextColor(1, 0.82, 0, 1) -- Gold color for key bindings
    table.insert(self.optionsElements, prevSectionKey)
    
    -- Add handler for the keybinding button
    prevSectionKey:SetScript("OnClick", function()
        if self.StartKeyBinding then
            self:Debug("general", "Starting key binding for Previous function")
            self:StartKeyBinding("PREV", "Previous Section", function(key)
                -- Update the displayed text with the new keybind
                prevSectionKey:SetText(key or "Not bound")
            end)
        else
            self:Debug("error", "StartKeyBinding function not found")
            DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA:|r Keybinding system not available.")
        end
    end)
    
    -- ==== TOGGLE OSD KEYBINDING ====
    -- Create keybinding label for Toggle OSD
    local toggleOSDLabel = leftColumn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    toggleOSDLabel:SetPoint("TOPLEFT", prevSectionKey, "BOTTOMLEFT", -labelWidth-5, -5)
    toggleOSDLabel:SetText("Toggle OSD:")
    toggleOSDLabel:SetWidth(labelWidth)
    toggleOSDLabel:SetJustifyH("LEFT")
    table.insert(self.optionsElements, toggleOSDLabel)
    
    -- Get current binding for Toggle OSD
    local osdBinding = GetBindingKey("TWRA_TOGGLE_OSD")
    
    -- Create keybinding button for Toggle OSD
    local toggleOSDKey = CreateFrame("Button", "TWRA_ToggleOSDKeyButton", leftColumn, "UIPanelButtonTemplate")
    toggleOSDKey:SetWidth(80)
    toggleOSDKey:SetHeight(20)
    toggleOSDKey:SetPoint("LEFT", toggleOSDLabel, "RIGHT", 5, 0)
    toggleOSDKey:SetText(osdBinding or "Not bound")
    toggleOSDKey:SetTextColor(1, 0.82, 0, 1) -- Gold color for key bindings
    table.insert(self.optionsElements, toggleOSDKey)
    
    -- Add handler for the keybinding button
    toggleOSDKey:SetScript("OnClick", function()
        if self.StartKeyBinding then
            self:Debug("general", "Starting key binding for Toggle OSD function")
            self:StartKeyBinding("TOGGLE_OSD", "Toggle OSD", function(key)
                -- Update the displayed text with the new keybind
                toggleOSDKey:SetText(key or "Not bound")
            end)
        else
            self:Debug("error", "StartKeyBinding function not found")
            DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA:|r Keybinding system not available.")
        end
    end)

    -- ====================== LOAD SAVED VALUES ======================
    -- Get saved options and apply them to the UI elements
    local options = TWRA_SavedVariables.options or {}
    
    -- Live Sync checkbox
    local liveSyncEnabled = self.SYNC and self.SYNC.liveSync or false
    if options.liveSync ~= nil then
        liveSyncEnabled = options.liveSync
    end
    liveSync:SetChecked(liveSyncEnabled)
    
    -- Tank Sync checkbox
    local tankSyncEnabled = self.SYNC and self.SYNC.tankSync or false
    if options.tankSync ~= nil then
        tankSyncEnabled = options.tankSync
    end
    tankSyncCheckbox:SetChecked(tankSyncEnabled)
    
    -- AutoNavigate checkbox
    local autoNavEnabled = self.AUTONAVIGATE and self.AUTONAVIGATE.enabled or false
    if options.autoNavigate ~= nil then
        autoNavEnabled = options.autoNavigate
    end
    autoNavigate:SetChecked(autoNavEnabled)
    
    -- ====================== WIRE UP BEHAVIORS ======================
    
    -- Live Sync checkbox behavior
    liveSync:SetScript("OnClick", function()
        local isChecked = (this:GetChecked() == 1)
        TWRA_SavedVariables.options.liveSync = isChecked
        
        -- Update memory value
        if self.SYNC then
            self.SYNC.liveSync = isChecked
        end
        
        -- Debug output
        self:Debug("sync", "Option 'Live Section Sync' set to " .. (isChecked and "ON" or "OFF"))
    end)
    
    -- Tank Sync checkbox behavior
    tankSyncCheckbox:SetScript("OnClick", function()
        local isChecked = (this:GetChecked() == 1)
        TWRA_SavedVariables.options.tankSync = isChecked
        
        -- Update memory value
        if self.SYNC then
            self.SYNC.tankSync = isChecked
        end
        
        -- Debug output
        self:Debug("tank", "Option 'Tank Sync' set to " .. (isChecked and "ON" or "OFF"))
        
        -- Initialize tank sync if it was just enabled
        if isChecked and self.InitializeTankSync then
            self:InitializeTankSync()
        end
    end)
    
    -- AutoNavigate checkbox behavior
    autoNavigate:SetScript("OnClick", function()
        local isChecked = (this:GetChecked() == 1)
        TWRA_SavedVariables.options.autoNavigate = isChecked
        self.AUTONAVIGATE.enabled = isChecked
        
        -- Debug output
        self:Debug("nav", "Option 'AutoNavigate' set to " .. (isChecked and "ON" or "OFF"))
        
        -- Enable or disable scanning based on checkbox state
        if isChecked then
            if self.StartAutoNavigateScan then
                self:StartAutoNavigateScan()
                self:Debug("nav", "AutoNavigate scanning started")
            end
        else
            if self.StopAutoNavigateScan then
                self:StopAutoNavigateScan()
                self:Debug("nav", "AutoNavigate scanning stopped")
            end
        end
    end)
    
    -- Update initial AutoNavigate UI state
    if not SUPERWOW_VERSION then
        -- SuperWoW not available, gray out everything
        autoNavigateText:SetTextColor(0.5, 0.5, 0.5)
        autoNavigate:EnableMouse(false)
    else
        -- SuperWoW is available, ensure AutoNavigate text is normal color
        autoNavigateText:SetTextColor(1, 1, 1)
        autoNavigate:EnableMouse(true)
    end
    
    return leftColumn
end