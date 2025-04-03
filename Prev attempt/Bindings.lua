-- TWRA Keybindings
TWRA = TWRA or {}

-- Global binding strings
BINDING_HEADER_TWRA = "Turtlewow Raid Assignments";
BINDING_NAME_TWRA_TOGGLE = "Toggle Main Window";
BINDING_NAME_TWRA_NEXT_SECTION = "Navigate to Next Section";
BINDING_NAME_TWRA_PREV_SECTION = "Navigate to Previous Section";
BINDING_NAME_TWRA_SHOW_OSD = "Show On-Screen Display";

-- Keybind state tracking - simplified
TWRA.KEYBIND = {
    initialized = false
}

-- Toggle the main frame visibility
function TWRA:ToggleMainFrame()
    -- Make sure frame exists
    if not self.mainFrame then
        if self.CreateMainFrame then
            self:CreateMainFrame()
        else
            DEFAULT_CHAT_FRAME:AddMessage("TWRA: Error - Unable to create main frame")
            return
        end
    end
    
    if self.mainFrame:IsShown() then
        self.mainFrame:Hide()
        DEFAULT_CHAT_FRAME:AddMessage("TWRA: Window hidden")
    else
        self.mainFrame:Show()
        
        -- Force update content if first time opening
        if not self.initialized then
            self:LoadSavedAssignments()
            self.initialized = true
        end
        
        -- -- Make sure we're showing main view, not options. Commenting these. I want to show the options if I have the options open.
        -- if self.currentView == "options" then
        --     self:ShowMainView()
        -- end
        
        DEFAULT_CHAT_FRAME:AddMessage("TWRA: Window shown")
    end
end

-- Simplified initialization function - only keep the basic key bindings
function TWRA:InitializeBindings()
    -- Register for key events
    -- DEFAULT_CHAT_FRAME:AddMessage("TWRA: Initializing key bindings")
    
    -- Flag as initialized to avoid duplicate initialization
    self.KEYBIND.initialized = true

    -- Debug message
    -- DEFAULT_CHAT_FRAME:AddMessage("TWRA: Bindings initialized")
    
    -- Remove any test buttons that might have been created
    if self.testShowButton then
        self.testShowButton:Hide()
        self.testShowButton = nil
    end
end
TWRA:Debug("general", "Bindings module loaded")