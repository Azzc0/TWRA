-- TWRA Keybindings
TWRA = TWRA or {}

-- Section header for keybindings
BINDING_HEADER_TWRA = "TWRA"

-- Binding names - must match exactly what's in the XML file
BINDING_NAME_TWRA_TOGGLE = "Toggle Frame"
BINDING_NAME_TWRA_NEXT = "Next Section"  
BINDING_NAME_TWRA_PREV = "Previous Section"
BINDING_NAME_TWRA_TOGGLE_OSD = "Toggle OSD"

-- Keybind state tracking
TWRA.KEYBIND = {
    initialized = false,
    currentlyBinding = false,
    bindFrame = nil,
    bindingFor = nil,
    callback = nil -- New callback function property
}

-- Initialization function
function TWRA:InitializeBindings()
    -- Flag as initialized to avoid duplicate initialization
    if self.KEYBIND.initialized then return end
    self.KEYBIND.initialized = true
    
    -- Create the keybinding frame
    self:CreateBindFrame()
    
    -- Remove any test buttons that might have been created
    if self.testShowButton then
        self.testShowButton:Hide()
        self.testShowButton = nil
    end
end

-- Create the key binding frame
function TWRA:CreateBindFrame()
    -- Create a frame to capture key presses
    local frame = CreateFrame("Frame", "TWRAKeyBindFrame", UIParent)
    frame:EnableKeyboard(true)
    frame:SetFrameStrata("DIALOG")
    frame:SetWidth(300)
    frame:SetHeight(110)
    frame:SetPoint("CENTER", UIParent, "CENTER")
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 }
    })
    frame:Hide()
    
    -- Create prompt text
    local text = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    text:SetPoint("TOP", frame, "TOP", 0, -20)
    text:SetText("Press a key for binding")
    frame.text = text
    
    -- Create the binding button's name
    local buttonText = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    buttonText:SetPoint("TOP", text, "BOTTOM", 0, -10)
    buttonText:SetText("")
    frame.buttonText = buttonText
    
    -- Add instruction text
    local instructionText = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    instructionText:SetPoint("BOTTOM", frame, "BOTTOM", 0, 40)
    instructionText:SetText("Press ESC to clear binding")
    frame.instructionText = instructionText
    
    -- Add a Cancel button
    local cancelButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    cancelButton:SetWidth(100)
    cancelButton:SetHeight(24)
    cancelButton:SetPoint("BOTTOM", frame, "BOTTOM", 0, 15)
    cancelButton:SetText("Cancel")
    cancelButton:SetScript("OnClick", function()
        self:StopKeyBinding(false)
    end)
    frame.cancelButton = cancelButton
    
    -- Register key input handlers
    frame:SetScript("OnKeyDown", function()
        local key = arg1 -- In WoW 1.12, keycode is in arg1
        self:BindingsFrameOnKeyDown(key)
    end)
    
    self.KEYBIND.bindFrame = frame
    return frame
end

-- Start listening for a key binding
function TWRA:StartKeyBinding(bindingName, buttonText, callback)
    if not self.KEYBIND.initialized then
        self:InitializeBindings()
    end

    -- Setup the binding frame
    self.KEYBIND.bindingFor = bindingName
    
    -- Store callback function if provided
    self.KEYBIND.callback = callback
    
    local frame = self.KEYBIND.bindFrame
    frame.buttonText:SetText(buttonText or bindingName)
    
    -- Position the frame - centered in the screen
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER")
    frame:Show()
    
    -- Give the frame focus to capture key presses
    frame:SetFrameStrata("DIALOG")
    
    -- Remember we're binding
    self.KEYBIND.currentlyBinding = true
    
    self:Debug("general", "Started key binding for: " .. bindingName)
end

-- Stop listening for a key binding
function TWRA:StopKeyBinding(success)
    if not self.KEYBIND.currentlyBinding then return end
    
    local frame = self.KEYBIND.bindFrame
    
    -- Hide the binding frame
    frame:Hide()
    
    -- Reset binding status
    self.KEYBIND.currentlyBinding = false
    
    if success then
        self:Debug("general", "Successfully bound key for: " .. (self.KEYBIND.bindingFor or "unknown"))
    else
        self:Debug("general", "Cancelled key binding for: " .. (self.KEYBIND.bindingFor or "unknown"))
        
        -- If we have a callback, call it with nil to indicate cancellation
        if self.KEYBIND.callback then
            self.KEYBIND.callback(nil)
        end
    end
    
    self.KEYBIND.bindingFor = nil
    self.KEYBIND.callback = nil -- Clear the callback
end

-- Handle key presses during binding
function TWRA:BindingsFrameOnKeyDown(key)
    if not self.KEYBIND.currentlyBinding then return end
    
    self:Debug("general", "Detected key press: " .. (key or "nil"))
    
    -- IMMEDIATELY close dialog for any key press
    if key and key ~= "SHIFT" and key ~= "CTRL" and key ~= "ALT" then
        self:Debug("general", "Key detected, closing dialog.")
        
        -- Handle escape key to clear the binding
        if key == "ESCAPE" then
            -- IMPORTANT: Stop the binding mode FIRST before doing anything else
            self.KEYBIND.bindFrame:Hide()
            self.KEYBIND.currentlyBinding = false
            local bindingName = self.KEYBIND.bindingFor
            local callback = self.KEYBIND.callback -- Store callback before clearing
            self.KEYBIND.bindingFor = nil
            self.KEYBIND.callback = nil -- Clear callback reference
            
            -- NOW clear existing bindings for this action
            self:ClearBinding(bindingName)
            
            -- Call the callback if provided, with nil to indicate cleared binding
            if callback then
                callback(nil)
            end
            
            -- Send notification and exit
            DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA:|r Binding cleared")
            return
        end
        
        -- Get modifier state
        local modifier = ""
        if IsShiftKeyDown() then modifier = modifier .. "SHIFT-" end
        if IsControlKeyDown() then modifier = modifier .. "CTRL-" end
        if IsAltKeyDown() then modifier = modifier .. "ALT-" end
        
        -- Create the full binding
        local fullBinding = modifier .. key
        
        -- Debug the binding attempt
        self:Debug("general", "Attempting to set binding for " .. self.KEYBIND.bindingFor .. " to " .. fullBinding)
        
        -- IMPORTANT: Stop the binding mode FIRST before setting the binding
        local bindingName = self.KEYBIND.bindingFor
        local callback = self.KEYBIND.callback -- Store callback before clearing
        self.KEYBIND.bindFrame:Hide()
        self.KEYBIND.currentlyBinding = false
        self.KEYBIND.bindingFor = nil
        self.KEYBIND.callback = nil -- Clear callback reference
        
        -- THEN set the binding
        self:SetBinding(bindingName, fullBinding, callback)
        
        return
    end
    
    -- Only process modifiers here, everything else has already been handled above
    -- These modifiers need to be handled specially
    if key == "SHIFT" or key == "CTRL" or key == "ALT" then
        -- Do not process modifier keys alone
        return
    end
end

-- Set a binding for a specific command
function TWRA:SetBinding(bindingName, key, callback)
    self:Debug("general", "Setting binding for " .. bindingName .. " to " .. key)
    
    -- The binding name in XML now has TWRA_ prefix
    local command = "TWRA_" .. string.upper(bindingName)
    
    -- Clear any existing bindings using this key
    local existingAction = GetBindingAction(key)
    if existingAction ~= "" and existingAction ~= command then
        self:Debug("general", "Clearing existing binding for key: " .. key .. " (was bound to " .. existingAction .. ")")
        SetBinding(key, nil)
    end
    
    -- Clear any existing bindings for this command
    self:ClearBinding(bindingName)
    
    -- Set the new binding using WoW's API
    local success = SetBinding(key, command)
    
    -- Debug result
    if not success then
        self:Debug("error", "Failed to set binding for " .. bindingName .. " to " .. key)
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF3333TWRA:|r Failed to set keybinding. Try a different key.")
        
        -- Call callback with nil if binding failed
        if callback then
            callback(nil)
        end
        
        return false
    end
    
    -- Save the bindings to account
    SaveBindings(GetCurrentBindingSet())
    
    -- Call the callback with the new key if provided
    if callback then
        callback(key)
    end
    
    -- Update the display in options panel if it exists
    self:UpdateKeyBindingDisplay(bindingName)
    
    -- Inform the user
    DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA:|r Bound |cFFFFFFFF" .. bindingName .. "|r to |cFFFFFFFF" .. key .. "|r")
    return true
end

-- Clear all bindings for a command
function TWRA:ClearBinding(bindingName)
    self:Debug("general", "Clearing bindings for " .. bindingName)
    
    -- Use the correct format for the binding name
    local command = "TWRA_" .. string.upper(bindingName)
    
    -- Get all current key bindings
    for i = 1, GetNumBindings() do
        local action, category, key1, key2 = GetBinding(i)
        
        -- We need to check if the action matches our command
        -- In WoW 1.12, GetBinding returns action, category, key1, key2
        if action == command then
            if key1 then
                self:Debug("general", "Clearing binding: " .. key1 .. " from " .. command)
                SetBinding(key1, nil)
            end
            
            if key2 then
                self:Debug("general", "Clearing binding: " .. key2 .. " from " .. command)
                SetBinding(key2, nil)
            end
        end
    end
    
    -- Save the bindings to account
    SaveBindings(GetCurrentBindingSet())
    
    -- Inform the user
    DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA:|r Cleared all bindings for |cFFFFFFFF" .. bindingName .. "|r")
end

-- Update the keybinding display in the options panel
function TWRA:UpdateKeyBindingDisplay(bindingName)
    -- Only continue if we have options elements to update
    if not self.optionsElements then
        return
    end
    
    -- Instead of just updating the button for the changed binding,
    -- let's update all keybinding buttons to ensure consistency
    self:Debug("general", "Updating all keybinding displays")
    
    -- Update TOGGLE binding display
    local toggleKey = GetBindingKey("TWRA_TOGGLE") or "Not bound"
    -- Update NEXT binding display
    local nextKey = GetBindingKey("TWRA_NEXT") or "Not bound"
    -- Update PREV binding display
    local prevKey = GetBindingKey("TWRA_PREV") or "Not bound"
    -- Update TOGGLE_OSD binding display
    local osdKey = GetBindingKey("TWRA_TOGGLE_OSD") or "Not bound"
    
    -- Find and update all keybinding buttons by their specific name
    local toggleButton = getglobal("TWRA_ToggleFrameKeyButton")
    local nextButton = getglobal("TWRA_NextSectionKeyButton")
    local prevButton = getglobal("TWRA_PrevSectionKeyButton")
    local osdButton = getglobal("TWRA_ToggleOSDKeyButton")
    
    -- Update each button if it exists
    if toggleButton then toggleButton:SetText(toggleKey) end
    if nextButton then nextButton:SetText(nextKey) end
    if prevButton then prevButton:SetText(prevKey) end
    if osdButton then osdButton:SetText(osdKey) end
    
    self:Debug("general", "All keybinding displays updated")
end