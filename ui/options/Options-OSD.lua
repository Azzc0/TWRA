-- TWRA Options-OSD Module
-- Middle column of the options panel: OSD (On-Screen Display) settings
TWRA = TWRA or {}

-- Load this options component
function TWRA:LoadOptionsOSD()
    self:Debug("general", "Loading OSD options component")
    
    -- Register this component in the options system
    if not self.optionsComponents then
        self.optionsComponents = {}
    end
    
    self.optionsComponents.osd = {
        name = "OSD",
        create = function(column) return self:CreateOptionsOSDColumn(column) end
    }
end

-- Create the OSD options column content
function TWRA:CreateOptionsOSDColumn(middleColumn)
    self:Debug("ui", "Creating OSD options column")
    
    -- Column title
    local osdTitle = middleColumn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    osdTitle:SetPoint("TOPLEFT", middleColumn, "TOPLEFT", 10, 0)
    osdTitle:SetText("On-Screen Display")
    table.insert(self.optionsElements, osdTitle)
    
    -- Show Notes in OSD checkbox (replacing Enable OSD)
    local showNotesInOSD, showNotesInOSDText = self:CreateCheckbox(middleColumn, "Show Notes in OSD", "TOPLEFT", osdTitle, "BOTTOMLEFT", 0, -10)
    table.insert(self.optionsElements, showNotesInOSD)
    table.insert(self.optionsElements, showNotesInOSDText)
    
    -- Add info icon for show notes option
    local notesIcon, notesIconFrame = self.UI:CreateIconWithTooltip(
        middleColumn,
        "Interface\\TutorialFrame\\TutorialFrame-QuestionMark",
        "Show Notes in OSD",
        "When enabled, notes will be displayed in the OSD alongside warnings. Notes are shown with blue background.",
        showNotesInOSDText,
        5, 22, 22
    )
    
    notesIcon:ClearAllPoints()
    notesIcon:SetPoint("LEFT", showNotesInOSDText, "RIGHT", 5, 0)
    
    table.insert(self.optionsElements, notesIcon)
    table.insert(self.optionsElements, notesIconFrame)
    
    -- OSD on Navigation checkbox
    local showOnNavOSD, showOnNavOSDText = self:CreateCheckbox(middleColumn, "Show on Navigation", "TOPLEFT", showNotesInOSD, "BOTTOMLEFT", 0, -5)
    table.insert(self.optionsElements, showOnNavOSD)
    table.insert(self.optionsElements, showOnNavOSDText)
    
    -- Lock Position checkbox
    local lockOSD, lockOSDText = self:CreateCheckbox(middleColumn, "Lock Position", "TOPLEFT", showOnNavOSD, "BOTTOMLEFT", 0, -10)
    table.insert(self.optionsElements, lockOSD)
    table.insert(self.optionsElements, lockOSDText)
    
    -- OSD Duration slider
    local durationSlider = CreateFrame("Slider", "TWRA_OSDDurationSlider", middleColumn, "OptionsSliderTemplate")
    durationSlider:SetPoint("TOPLEFT", lockOSD, "BOTTOMLEFT", 0, -20)
    durationSlider:SetWidth(180)
    durationSlider:SetHeight(16)
    durationSlider:SetMinMaxValues(1, 10)
    durationSlider:SetValueStep(0.5)
    durationSlider:SetOrientation("HORIZONTAL")
    table.insert(self.optionsElements, durationSlider)
    
    -- Set slider text
    getglobal(durationSlider:GetName() .. "Low"):SetText("1s")
    getglobal(durationSlider:GetName() .. "High"):SetText("10s")
    
    -- OSD Scale slider
    local scaleSlider = CreateFrame("Slider", "TWRA_OSDScaleSlider", middleColumn, "OptionsSliderTemplate")
    scaleSlider:SetPoint("TOPLEFT", durationSlider, "BOTTOMLEFT", 0, -20)
    scaleSlider:SetWidth(180)
    scaleSlider:SetHeight(16)
    scaleSlider:SetMinMaxValues(0.5, 2.0)
    scaleSlider:SetValueStep(0.1)
    scaleSlider:SetOrientation("HORIZONTAL")
    table.insert(self.optionsElements, scaleSlider)
    
    -- Set slider text
    getglobal(scaleSlider:GetName() .. "Low"):SetText("Small")
    getglobal(scaleSlider:GetName() .. "High"):SetText("Large")
    
    -- OSD action buttons
    local testOSDBtn = CreateFrame("Button", nil, middleColumn, "UIPanelButtonTemplate")
    testOSDBtn:SetWidth(80)
    testOSDBtn:SetHeight(22)
    testOSDBtn:SetPoint("TOPLEFT", scaleSlider, "BOTTOMLEFT", 0, -15)
    testOSDBtn:SetText("Show OSD")
    testOSDBtn:SetScript("OnClick", function()
        -- Use ToggleOSD to properly toggle visibility
        local isVisible = TWRA:ToggleOSD()
        
        -- Update button text to reflect current state
        if isVisible then
            testOSDBtn:SetText("Hide OSD")
            
            -- Update current section content if available
            if TWRA.navigation and TWRA.navigation.currentIndex and TWRA.navigation.handlers then
                local sectionName = TWRA.navigation.handlers[TWRA.navigation.currentIndex]
                local currentIndex = TWRA.navigation.currentIndex
                local totalSections = table.getn(TWRA.navigation.handlers)
                
                -- Update OSD content with current section data
                TWRA:UpdateOSDContent(sectionName, currentIndex, totalSections)
            end
        else
            testOSDBtn:SetText("Show OSD")
        end
        
        -- Debug output
        TWRA:Debug("osd", "OSD " .. (isVisible and "shown" or "hidden") .. " from options panel")
    end)
    table.insert(self.optionsElements, testOSDBtn)
    
    local resetPosBtn = CreateFrame("Button", nil, middleColumn, "UIPanelButtonTemplate")
    resetPosBtn:SetWidth(80)
    resetPosBtn:SetHeight(22)
    resetPosBtn:SetPoint("LEFT", testOSDBtn, "RIGHT", 10, 0)
    resetPosBtn:SetText("Reset")
    table.insert(self.optionsElements, resetPosBtn)
    
    -- ====================== LOAD SAVED VALUES ======================
    -- Get saved options and apply them to the UI elements
    local options = TWRA_SavedVariables.options or {}
    
    -- Make sure options.osd exists to avoid nil errors
    options.osd = options.osd or {}
    
    -- Show Notes in OSD checkbox
    local showNotesEnabled = true
    if options.osd and options.osd.showNotes ~= nil then
        showNotesEnabled = options.osd.showNotes
    elseif self.OSD and self.OSD.showNotes ~= nil then
        showNotesEnabled = self.OSD.showNotes
    end
    showNotesInOSD:SetChecked(showNotesEnabled)
    
    -- OSD Navigation checkbox
    local osdNavEnabled = true
    if options.osd and options.osd.showOnNavigation ~= nil then
        osdNavEnabled = options.osd.showOnNavigation
    elseif self.OSD and self.OSD.showOnNavigation ~= nil then
        osdNavEnabled = self.OSD.showOnNavigation
    end
    showOnNavOSD:SetChecked(osdNavEnabled)
    
    -- Lock Position checkbox
    local osdLocked = false
    if options.osd and options.osd.locked ~= nil then
        osdLocked = options.osd.locked
    elseif self.OSD and self.OSD.locked ~= nil then
        osdLocked = self.OSD.locked
    end
    lockOSD:SetChecked(osdLocked)
    
    -- Duration slider
    local osdDuration = 2
    if options.osd and options.osd.duration ~= nil then
        osdDuration = options.osd.duration
    elseif self.OSD and self.OSD.duration ~= nil then
        osdDuration = self.OSD.duration
    end
    durationSlider:SetValue(osdDuration)
    getglobal(durationSlider:GetName() .. "Text"):SetText("Display Duration: " .. osdDuration .. " seconds")
    
    -- Scale slider
    local osdScale = 1.0
    if options.osd and options.osd.scale ~= nil then
        osdScale = options.osd.scale
    elseif self.OSD and self.OSD.scale ~= nil then
        osdScale = self.OSD.scale
    end
    scaleSlider:SetValue(osdScale)
    getglobal(scaleSlider:GetName() .. "Text"):SetText("Scale: " .. osdScale)
    
    -- ====================== WIRE UP BEHAVIORS ======================
    
    -- OSD Notes in OSD checkbox behavior
    showNotesInOSD:SetScript("OnClick", function()
        local isChecked = (this:GetChecked() == 1)
        
        -- Ensure OSD settings structure exists
        if not TWRA_SavedVariables.options.osd then 
            TWRA_SavedVariables.options.osd = {} 
        end
        
        -- Save setting
        TWRA_SavedVariables.options.osd.showNotes = isChecked
        
        -- Update runtime value
        if self.OSD then
            self.OSD.showNotes = isChecked
        end
        
        -- Debug output
        self:Debug("osd", "Option 'Show Notes in OSD' set to " .. (isChecked and "ON" or "OFF"))
        
        -- Update OSD if visible
        if self.OSD and self.OSD.isVisible and self.UpdateOSDContent then
            if self.navigation and self.navigation.currentIndex and self.navigation.handlers then
                local sectionName = self.navigation.handlers[self.navigation.currentIndex]
                local currentIndex = self.navigation.currentIndex
                local totalSections = table.getn(self.navigation.handlers)
                self:UpdateOSDContent(sectionName, currentIndex, totalSections)
            end
        end
    end)
    
    -- OSD on Navigation checkbox behavior
    showOnNavOSD:SetScript("OnClick", function()
        local isChecked = (this:GetChecked() == 1)
        
        -- Ensure OSD settings structure exists
        if not TWRA_SavedVariables.options.osd then 
            TWRA_SavedVariables.options.osd = {} 
        end
        
        -- Save setting
        TWRA_SavedVariables.options.osd.showOnNavigation = isChecked
        
        -- Update runtime value
        if self.OSD then
            self.OSD.showOnNavigation = isChecked
        end
        
        -- Debug output
        self:Debug("osd", "Option 'Show on Navigation' set to " .. (isChecked and "ON" or "OFF"))
        
        -- Call the toggle function if it exists
        if self.ToggleOSDOnNavigation then
            self:ToggleOSDOnNavigation(isChecked)
        end
    end)
    
    -- OSD Lock checkbox behavior
    lockOSD:SetScript("OnClick", function()
        local isChecked = (this:GetChecked() == 1)
        
        -- Ensure OSD settings structure exists
        if not TWRA_SavedVariables.options.osd then 
            TWRA_SavedVariables.options.osd = {} 
        end
        
        -- Save setting
        TWRA_SavedVariables.options.osd.locked = isChecked
        
        -- Update runtime value
        if self.OSD then
            self.OSD.locked = isChecked
        end
        
        -- Debug output
        self:Debug("osd", "Option 'Lock Position' set to " .. (isChecked and "ON" or "OFF"))
        
        -- Update OSD frame if needed
        if self.UpdateOSDSettings then
            self:UpdateOSDSettings()
        end
    end)
    
    -- Duration slider behavior
    durationSlider:SetScript("OnValueChanged", function()
        local value = math.floor(this:GetValue() * 2) / 2  -- Round to nearest 0.5
        
        -- Ensure OSD settings structure exists
        if not TWRA_SavedVariables.options.osd then 
            TWRA_SavedVariables.options.osd = {} 
        end
        
        -- Save setting
        TWRA_SavedVariables.options.osd.duration = value
        
        -- Update runtime value
        if self.OSD then
            self.OSD.duration = value
        end
        
        -- Update display text
        getglobal(this:GetName() .. "Text"):SetText("Display Duration: " .. value .. " seconds")
    end)
    
    -- Scale slider behavior
    scaleSlider:SetScript("OnValueChanged", function()
        local value = math.floor(this:GetValue() * 10) / 10  -- Round to nearest 0.1
        
        -- Ensure OSD settings structure exists
        if not TWRA_SavedVariables.options.osd then 
            TWRA_SavedVariables.options.osd = {} 
        end
        
        -- Save setting
        TWRA_SavedVariables.options.osd.scale = value
        
        -- Update runtime value
        if self.OSD then
            self.OSD.scale = value
        end
        
        -- Update display text
        getglobal(this:GetName() .. "Text"):SetText("Scale: " .. value)
        
        -- Update OSD frame if needed
        if self.UpdateOSDSettings then
            self:UpdateOSDSettings()
        end
    end)
    
    -- Reset OSD position button behavior
    resetPosBtn:SetScript("OnClick", function()
        if self.ResetOSDPosition then
            self:ResetOSDPosition()
        end
        
        -- Update OSD settings if needed
        if self.UpdateOSDSettings then
            self:UpdateOSDSettings()
        end
    end)
    
    return middleColumn
end