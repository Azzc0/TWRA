-- TWRA Debug Options Module
TWRA = TWRA or {}
TWRA.OPTIONS = TWRA.OPTIONS or {}

-- Create Debug options panel
function TWRA.OPTIONS:CreateDebugOptions(parent)
    -- Better parent handling using the utility function
    if not parent then
        parent = TWRA.UI:GetOptionsContainer()
        
        if not parent then
            TWRA:Debug("error", "No parent frame provided for DebugOptions")
            -- Create a minimal placeholder frame so the function doesn't fail
            local placeholder = CreateFrame("Frame")
            placeholder:Hide()
            return placeholder
        end
    end
    
    -- Make sure parent is valid and has GetWidth
    if not parent.GetWidth then
        TWRA:Debug("error", "Invalid parent for DebugOptions")
        local placeholder = CreateFrame("Frame")
        placeholder:Hide()
        return placeholder
    end

    -- Create a properly anchored container frame
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints(parent)
    
    -- Master Debug Toggle positioned at the top with proper margin
    local masterToggle, masterToggleText = TWRA.UI:CreateCheckbox(
        frame, 
        "Enable Debug Mode", 
        TWRA.DEBUG and TWRA.DEBUG.enabled or false,
        frame, "TOPLEFT", 10, -10  -- Position from top-left with proper margin
    )
    
    masterToggle:SetScript("OnClick", function()
        local isChecked = masterToggle:GetChecked()
        if TWRA.ToggleDebug then
            TWRA:ToggleDebug(isChecked)
            TWRA:UpdateCategoryCheckboxes() -- Update category checkboxes
        end
    end)
    
    -- Debug Level Slider
    local debugLevelSlider = TWRA.UI:CreateSlider(
        frame,
        "Debug Level: %d",
        1, 4, 1,
        TWRA.DEBUG and TWRA.DEBUG.logLevel or 3,
        masterToggle, "BOTTOMLEFT", 0, -30
    )
    
    -- Set slider labels
    local levelLow = getglobal(debugLevelSlider:GetName() .. "Low")
    local levelHigh = getglobal(debugLevelSlider:GetName() .. "High")
    if levelLow then levelLow:SetText("Errors Only") end
    if levelHigh then levelHigh:SetText("All Details") end
    
    debugLevelSlider:SetScript("OnValueChanged", function()
        local value = math.floor(debugLevelSlider:GetValue())
        getglobal(debugLevelSlider:GetName() .. "Text"):SetText("Debug Level: " .. value)
        
        if TWRA.SetDebugLevel then
            TWRA:SetDebugLevel(value)
        end
    end)
    
    -- Show Details Toggle
    local detailsToggle, detailsToggleText = TWRA.UI:CreateCheckbox(
        frame, 
        "Show Detailed Logs", 
        TWRA.DEBUG and TWRA.DEBUG.showDetails or false,
        debugLevelSlider, "BOTTOMLEFT", 0, -20
    )
    
    detailsToggle:SetScript("OnClick", function()
        local isChecked = detailsToggle:GetChecked()
        if TWRA.ToggleDetailedLogging then
            TWRA:ToggleDetailedLogging(isChecked)
        end
    end)
    
    -- Create Category Section Header
    local categoryTitle = TWRA.UI:CreateSectionHeader(frame, "Debug Categories", 0, -30)
    categoryTitle:SetPoint("TOPLEFT", detailsToggle, "BOTTOMLEFT", 0, -25)
    
    -- Ensure we have categories to work with
    if not TWRA.DEBUG or not TWRA.DEBUG.CATEGORIES then
        local noCategories = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        noCategories:SetPoint("TOPLEFT", categoryTitle, "BOTTOMLEFT", 10, -10)
        noCategories:SetText("No debug categories available")
        return frame
    end
    
    -- Count how many categories we have (using table.getn equivalent for tables that aren't arrays)
    local categoryCount = 0
    for _, _ in pairs(TWRA.DEBUG.CATEGORIES) do
        categoryCount = categoryCount + 1
    end
    
    -- Add checkboxes for each debug category
    local categoryCheckboxes = {}
    local yOffset = -10
    
    for category, settings in pairs(TWRA.DEBUG.CATEGORIES) do
        local catToggle, catText = TWRA.UI:CreateCheckbox(
            frame, 
            settings.name or category, 
            TWRA.DEBUG.categories and TWRA.DEBUG.categories[category] or false,
            categoryTitle, "BOTTOMLEFT", 10, yOffset
        )
        
        -- Store category name for reference in click handler
        catToggle.category = category
        
        catToggle:SetScript("OnClick", function()
            if TWRA.ToggleDebugCategory then
                TWRA:ToggleDebugCategory(this.category, this:GetChecked())
            end
        end)
        
        -- Add tooltip with description if available
        if settings.description then
            catToggle:SetScript("OnEnter", function()
                GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
                GameTooltip:AddLine(settings.name or category)
                GameTooltip:AddLine(settings.description, 1, 1, 1, true)
                GameTooltip:Show()
            end)
            
            catToggle:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)
        end
        
        -- Store reference for later updates
        categoryCheckboxes[category] = catToggle
        
        yOffset = yOffset - 25
    end
    
    -- Add button to enable full debugging
    local fullDebugBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    fullDebugBtn:SetWidth(150)
    fullDebugBtn:SetHeight(22)
    fullDebugBtn:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 10, 10)
    fullDebugBtn:SetText("Enable Full Debugging")
    
    fullDebugBtn:SetScript("OnClick", function()
        if TWRA.EnableFullDebug then
            TWRA:EnableFullDebug()
            
            -- Update UI to reflect changes
            masterToggle:SetChecked(true)
            debugLevelSlider:SetValue(4)
            detailsToggle:SetChecked(true)
            
            -- Update category checkboxes
            for cat, checkbox in pairs(categoryCheckboxes) do
                checkbox:SetChecked(true)
            end
        end
    end)
    
    -- Add Show Status button
    local statusBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    statusBtn:SetWidth(100)
    statusBtn:SetHeight(22)
    statusBtn:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 10)
    statusBtn:SetText("Show Status")
    
    statusBtn:SetScript("OnClick", function()
        if TWRA.DEBUG then
            SlashCmdList["TWRADEBUG"]("status")
        else
            TWRA:Debug("error", "Debug system not initialized")
        end
    end)
    
    -- Add function to update checkbox states
    function TWRA:UpdateCategoryCheckboxes()
        for cat, checkbox in pairs(categoryCheckboxes) do
            if not self.DEBUG or not self.DEBUG.enabled then
                -- Disable and grey out checkboxes when master debug is off
                checkbox:Disable()
                checkbox:SetAlpha(0.5)
            else
                -- Enable checkboxes when master debug is on
                checkbox:Enable()
                checkbox:SetAlpha(1.0)
                
                -- Update checked state
                if self.DEBUG.categories and self.DEBUG.categories[cat] ~= nil then
                    checkbox:SetChecked(self.DEBUG.categories[cat])
                end
            end
        end
    end
    
    -- Initially update category checkboxes
    TWRA:UpdateCategoryCheckboxes()
    
    return frame
end
