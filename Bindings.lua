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