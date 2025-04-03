-- TWRA Data Processing
-- Handles decoding and applying received data

TWRA = TWRA or {}

-- Process received data (either from single message or combined chunks)
function TWRA:ProcessReceivedData(data, timestamp, sender)
    local ourTimestamp = TWRA_SavedVariables.assignments and TWRA_SavedVariables.assignments.timestamp or 0
    
    if timestamp and timestamp > ourTimestamp then
        self:Debug("sync", "Processing newer data from " .. sender)
        
        -- We'll decode using Base64 module later
        -- For now, just a placeholder
        local decodedData = data
        
        if not decodedData then
            self:Debug("error", "Failed to decode data from " .. sender)
            return false
        end
        
        -- Update our data - will be expanded later
        TWRA_SavedVariables.assignments = {
            data = decodedData,
            source = data,
            timestamp = timestamp,
            version = 1
        }
        
        self:Debug("sync", "Successfully synchronized with " .. sender)
        return true
    else
        self:Debug("sync", "Ignoring data from " .. sender .. " - our data is newer or the same")
        return false
    end
end
