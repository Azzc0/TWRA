-- TWRA Internal Event System
-- Implements a simple event system for communication between modules
TWRA = TWRA or {}

-- Add debug message to verify file is loading
DEFAULT_CHAT_FRAME:AddMessage("TWRA Events.lua loaded")

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

-- Unregister a specific event listener
-- @param listenerId The unique ID of the listener to remove
function TWRA:UnregisterEventById(listenerId)
    if not listenerId then return false end
    
    for event, listeners in pairs(self.events) do
        for i = table.getn(listeners), 1, -1 do
            if listeners[i].id == listenerId then
                table.remove(self.events[event], i)
                self:Debug("general", "Unregistered event listener with ID: " .. listenerId)
                return true
            end
        end
    end
    
    return false
end

-- Unregister all event listeners for a specific owner
-- @param owner The owner identifier to remove listeners for
function TWRA:UnregisterEventsByOwner(owner)
    if not owner then return false end
    
    local count = 0
    
    for event, listeners in pairs(self.events) do
        for i = table.getn(listeners), 1, -1 do
            if listeners[i].owner == owner then
                table.remove(self.events[event], i)
                count = count + 1
            end
        end
    end
    
    if count > 0 then
        self:Debug("general", "Unregistered " .. count .. " event listener(s) for owner: " .. owner)
    end
    
    return count > 0
end

-- Unregister all listeners for a specific event
-- @param event The event to unregister all listeners for
function TWRA:UnregisterAllEventListeners(event)
    if not event or not self.events[event] then return false end
    
    local count = table.getn(self.events[event])
    self.events[event] = {}
    
    self:Debug("general", "Unregistered all " .. count .. " listeners for event: " .. event)
    
    return true
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

-- Check if an event has any listeners
-- @param event The event to check
-- @return true if the event has listeners, false otherwise
function TWRA:HasEventListeners(event)
    return event and self.events[event] and table.getn(self.events[event]) > 0
end

-- List all registered events and their listener counts
-- @param includeDetails Whether to include detailed information about each listener
function TWRA:ListRegisteredEvents(includeDetails)
    DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA Internal Events:|r")
    
    local eventCount = 0
    local totalListeners = 0
    
    for event, listeners in pairs(self.events) do
        local count = table.getn(listeners)
        totalListeners = totalListeners + count
        
        if count > 0 then
            eventCount = eventCount + 1
            DEFAULT_CHAT_FRAME:AddMessage("  |cFFFFFFFF" .. event .. "|r: " .. count .. " listener(s)")
            
            if includeDetails then
                for i, listener in ipairs(listeners) do
                    local ownerInfo = listener.owner and " (owner: " .. listener.owner .. ")" or ""
                    DEFAULT_CHAT_FRAME:AddMessage("    - ID: " .. listener.id .. ownerInfo)
                end
            end
        end
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("Total: " .. eventCount .. " events with " .. totalListeners .. " listeners")
end

-- Provide slash command to list registered events
SLASH_TWRAEVENTS1 = "/twraevents"
SlashCmdList["TWRAEVENTS"] = function(msg)
    TWRA:ListRegisteredEvents(msg == "details")
end