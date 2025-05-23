-- TWRA Internal Event System
-- Implements a simple event system for communication between modules
TWRA = TWRA or {}

-- Add debug message to verify file is loading
-- DEFAULT_CHAT_FRAME:AddMessage("TWRA Events.lua loaded")

-- Initialize event system storage
TWRA.events = TWRA.events or {}

-- Register an event listener
-- @param event The event name to listen for
-- @param callback The function to call when the event is triggered
-- @param owner (optional) An identifier for the owner of this listener, useful for removing listeners
function TWRA:RegisterEvent(event, callback, owner)
    if not event or not callback then
        self:Debug("error", "RegisterEvent called with missing arguments")
        return false
    end

    -- Initialize event listeners table if not exists
    if not self.events[event] then
        self.events[event] = {}
    end
    
    -- Create a unique ID for this listener
    local listenerId = owner and (event .. "#" .. owner) or event .. "#" .. tostring(callback)
    
    -- Add the callback to the event's listeners
    table.insert(self.events[event], {
        id = listenerId,
        callback = callback,
        owner = owner
    })
    
    self:Debug("general", "Registered event listener for '" .. event .. 
              "'" .. (owner and " (owner: " .. owner .. ")" or ""))
    
    return listenerId
end

-- Trigger an event with optional arguments
-- @param event The event to trigger
-- @param arg1-arg9 Any additional arguments to pass to the listeners
function TWRA:TriggerEvent(event, arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
    if not event or not self.events[event] then 
        return 0
    end
    
    local listeners = self.events[event]
    local count = table.getn(listeners)
    
    if count == 0 then
        return 0
    end
    
    self:Debug("general", "Triggering event '" .. event .. "' with " .. count .. " listener(s)")
    
    -- Create a copy of the listeners table to prevent issues if callbacks register/unregister listeners
    local listenersCopy = {}
    for i = 1, count do
        listenersCopy[i] = listeners[i]
    end
    
    -- Call each listener
    for i = 1, count do
        local success, errorMsg = pcall(function()
            listenersCopy[i].callback(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9)
        end)
        
        if not success then
            self:Debug("error", "Error in event listener for '" .. event .. "': " .. errorMsg)
        end
    end
    
    return count
end
