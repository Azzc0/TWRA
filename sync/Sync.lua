-- Sync functionality for TWRA
TWRA = TWRA or {}
-- Replace direct chat message with Debug call
TWRA:Debug("sync", "***** TEST MARKER LOADED - VERSION 124 *****")
-- Sync constants
TWRA.SYNC = {
    PREFIX = "TWRA",
    COMMANDS = {
        VERSION = "VERSION",      -- For version checking
        SECTION = "SECTION",      -- For live section updates
        DATA_REQUEST = "DREQ",    -- Request full data
        DATA_RESPONSE = "DRES",   -- Send full data
        ANNOUNCE = "ANC"          -- Announce new import
    },
    liveSync = false,            -- Live sync enabled
    pendingSection = nil,        -- Section to navigate to after sync
    lastRequestTime = 0,         -- Throttle requests
    requestTimeout = 5,          -- Time to wait before requesting again
}

TWRA.DEBUG_FRAME = nil

-- Simple debug system for WoW 1.12
TWRA.DEBUG_BARS = {}
TWRA.DEBUG_COUNT = 0
TWRA.DEBUG_MAX = 8  -- Maximum number of debug bars to show

function TWRA:SimpleDebug(message)
    -- Always output to chat with special prefix
    DEFAULT_CHAT_FRAME:AddMessage("§§§ " .. message)
    
    -- Create parent frame if it doesn't exist
    if not self.DEBUG_PARENT then
        self.DEBUG_PARENT = CreateFrame("Frame", "TWRADebugParent", UIParent)
        self.DEBUG_PARENT:SetPoint("CENTER", 0, 200)
        self.DEBUG_PARENT:SetWidth(500)
        self.DEBUG_PARENT:SetHeight(200)
        self.DEBUG_PARENT:Show()
    end
    
    -- Create or reuse a debug bar
    self.DEBUG_COUNT = self.DEBUG_COUNT + 1
    if self.DEBUG_COUNT > self.DEBUG_MAX then
        self.DEBUG_COUNT = 1
    end
    
    local bar = self.DEBUG_BARS[self.DEBUG_COUNT]
    if not bar then
        bar = CreateFrame("Frame", "TWRADebugBar"..self.DEBUG_COUNT, self.DEBUG_PARENT)
        bar:SetHeight(20)
        bar:SetWidth(500)
        
        -- Position bars from bottom to top
        bar:SetPoint("BOTTOMLEFT", self.DEBUG_PARENT, "BOTTOMLEFT", 0, (self.DEBUG_COUNT-1) * 20)
        
        -- Add background
        local bg = bar:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints(bar)
        bg:SetTexture(0, 0, 0.5, 0.7)  -- Blue semi-transparent background
        
        -- Add text
        bar.text = bar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        bar.text:SetPoint("LEFT", 5, 0)
        bar.text:SetWidth(490)
        bar.text:SetJustifyH("LEFT")
        
        self.DEBUG_BARS[self.DEBUG_COUNT] = bar
    end
    
    -- Update the text and show the bar
    bar.text:SetText(message)
    bar:Show()
    
    -- Schedule hiding the bar
    self:ScheduleTimer(function()
        if bar then bar:Hide() end
    end, 10)
end

-- Create a function to show debug in a UI frame
function TWRA:ShowVisualDebug(message)
    -- Create debug frame if it doesn't exist
    if not self.DEBUG_FRAME then
        self.DEBUG_FRAME = CreateFrame("Frame", "TWRADebugFrame", UIParent)
        self.DEBUG_FRAME:SetPoint("CENTER", 0, 200)
        self.DEBUG_FRAME:SetWidth(600)
        self.DEBUG_FRAME:SetHeight(400)
        self.DEBUG_FRAME:SetBackdrop({
            bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
            edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", 
            tile = true, tileSize = 32, edgeSize = 32, 
            insets = { left = 11, right = 12, top = 12, bottom = 11 }
        })
        self.DEBUG_FRAME:SetBackdropColor(0, 0, 0, 0.8)
        
        -- Add title
        local title = self.DEBUG_FRAME:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOP", 0, -20)
        title:SetText("TWRA Debug Output")
        
        -- Add debug text
        self.DEBUG_TEXT = self.DEBUG_FRAME:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        self.DEBUG_TEXT:SetPoint("TOPLEFT", 20, -40)
        self.DEBUG_TEXT:SetPoint("BOTTOMRIGHT", -20, 20)
        self.DEBUG_TEXT:SetJustifyH("LEFT")
        self.DEBUG_TEXT:SetText("")
        
        -- Add debug lines array
        self.DEBUG_LINES = {}
        
        -- Add close button
        local close = CreateFrame("Button", nil, self.DEBUG_FRAME, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", -5, -5)
    end
    
    -- Add new message to top of debug lines
    table.insert(self.DEBUG_LINES, 1, message)
    
    -- Keep only last 20 lines
    while table.getn(self.DEBUG_LINES) > 20 do
        table.remove(self.DEBUG_LINES)
    end
    
    -- Update display text
    self.DEBUG_TEXT:SetText(table.concat(self.DEBUG_LINES, "\n"))
    
    -- Show the frame
    self.DEBUG_FRAME:Show()
end

-- Helper function to split strings
function TWRA:SplitString(str, sep)
    if not str or str == "" then return {} end
    if not sep or sep == "" then return {str} end
    
    local parts = {}
    local start = 1
    local max = string.len(str)
    
    while start <= max do
        local pos = string.find(str, sep, start, true)
        if not pos then
            -- Add the last part
            table.insert(parts, string.sub(str, start))
            break
        else
            -- Add the current part
            table.insert(parts, string.sub(str, start, pos - 1))
            start = pos + string.len(sep)
        end
    end
    
    return parts
end

-- Function to send addon messages
function TWRA:SendAddonMessage(message, distribution, target)
    if not message then return end
    
    -- Replace direct chat message with Debug call
    self:Debug("sync", "Sending message (" .. string.len(message) .. " chars): " .. 
        string.sub(message, 1, 50) .. (string.len(message) > 50 and "..." or ""))
    
    -- Detect message type for extra debugging
    local colonPos = string.find(message, ":", 1, true)
    if colonPos then
        local commandName = string.sub(message, 1, colonPos - 1)
        if commandName == self.SYNC.COMMANDS.DATA_RESPONSE then
            self:Debug("sync", "Sending DATA_RESPONSE")
        elseif commandName == self.SYNC.COMMANDS.DATA_REQUEST then
            self:Debug("sync", "Sending DATA_REQUEST")
        end
    end
    
    -- Send appropriately based on group
    if GetNumRaidMembers() > 0 then
        self:Debug("sync", "Sending to RAID")
        SendAddonMessage(self.SYNC.PREFIX, message, "RAID")
    elseif GetNumPartyMembers() > 0 then
        self:Debug("sync", "Sending to PARTY")
        SendAddonMessage(self.SYNC.PREFIX, message, "PARTY")
    else
        self:Debug("sync", "Not in a group, message not sent")
    end
end

-- Function to handle incoming addon messages
function TWRA:HandleAddonMessage(message, channel, sender)
    if sender == UnitName("player") then return end
    
    -- Parse command and args
    local colonPos = string.find(message, ":", 1, true)
    if not colonPos then return end
    
    local command = string.sub(message, 1, colonPos - 1)
    local args = string.sub(message, colonPos + 1)
    
    self:Debug("sync", "Received from " .. sender .. ": " .. command .. ":...")
    self:Debug("sync", "Trying to delegate to command handler")
    
    -- Handle each command type
    if command == self.SYNC.COMMANDS.ANNOUNCE then
        self:Debug("sync", "Delegating to Announce handler")
        self:HandleAnnounceCommand(args, sender)
    elseif command == self.SYNC.COMMANDS.SECTION then
        self:Debug("sync", "Delegating to Section handler")
        self:HandleSectionCommand(args, sender)
    elseif command == self.SYNC.COMMANDS.VERSION then
        self:Debug("sync", "Delegating to Version handler")
        self:HandleVersionCommand(args, sender)
    elseif command == self.SYNC.COMMANDS.DATA_REQUEST then
        self:Debug("sync", "Delegating to Request handler")
        self:HandleDataRequestCommand(args, sender)
    elseif command == self.SYNC.COMMANDS.DATA_RESPONSE then
        self:Debug("sync", "Delegating to Response handler")
        self:HandleDataResponseCommand(args, sender)
    else
        self:Debug("error", "Could not delegate command: " .. tostring(command))
    end
end

-- Handle ANNOUNCE command
function TWRA:HandleAnnounceCommand(args, sender)
    self:Debug("sync", "Processing ANNOUNCE command")
    
    -- Parse timestamp and data
    local colonPos = string.find(args, ":", 1, true)
    if not colonPos then
        self:Debug("error", "Invalid announce format")
        return
    end
    
    local timestamp = tonumber(string.sub(args, 1, colonPos - 1))
    local data = string.sub(args, colonPos + 1)
    
    self:Debug("sync", "------------- ANNOUNCE ------------")
    self:Debug("sync", "Timestamp: " .. tostring(timestamp))
    self:Debug("sync", "String length: " .. string.len(data))
    self:Debug("sync", "String preview: " .. string.sub(data, 1, 50) .. "...")
    
    -- Check against our timestamp
    local ourTimestamp = TWRA_SavedVariables.assignments and TWRA_SavedVariables.assignments.timestamp or 0
    self:Debug("sync", "Our timestamp: " .. tostring(ourTimestamp))
    
    if timestamp and timestamp > ourTimestamp then
        self:Debug("sync", "Timestamp is newer - processing")
        
        -- Directly use ForceUpdateFromSync with the pending section if available
        local sectionToUse = self.SYNC.pendingSection or 1
        if self:ForceUpdateFromSync(data, timestamp, sectionToUse, true) then
            -- Clear pending section after use
            self.SYNC.pendingSection = nil
            self:Debug("sync", "Successfully synchronized with " .. sender)
        else
            self:Debug("error", "Failed to update from sync")
        end
        
    else
        self:Debug("sync", "Our data is newer or the same - ignoring")
    end
end

-- Completely refactored HandleSectionCommand to be simple and direct
function TWRA:HandleSectionCommand(args, sender)
    -- Send distinctive visible messages using debug
    self:Debug("sync", "SECTION HANDLER START", true)
    
    -- Safety first
    if not args then 
        self:Debug("error", "ARGS IS NIL!", true)
        return 
    end
    
    -- Parse the message
    local parts = self:SplitString(args, ":")
    if table.getn(parts) < 3 then
        self:Debug("error", "Invalid format: " .. args, true)
        return
    end
    
    local timestamp = tonumber(parts[1])
    local sectionName = parts[2]
    local sectionIndex = tonumber(parts[3])
    
    self:Debug("sync", "PROCESSING: " .. sectionName .. " (idx:" .. sectionIndex .. ")", true)
    
    -- Check timestamp
    local ourTimestamp = TWRA_SavedVariables.assignments and TWRA_SavedVariables.assignments.timestamp or 0
    
    if timestamp > ourTimestamp then
        -- Need newer data
        self:Debug("sync", "Requesting newer data", true)
        self.SYNC.pendingSection = sectionIndex
        self:SendAddonMessage(self.SYNC.COMMANDS.DATA_REQUEST .. ":" .. timestamp)
    elseif timestamp == ourTimestamp then
        self:Debug("sync", "TIMESTAMPS MATCH - CHANGING SECTION", true)
        
        -- 1. Ensure navigation exists
        if not self.navigation or not self.navigation.handlers then
            self:Debug("sync", "Rebuilding navigation", true)
            self:RebuildNavigation()
        end
        
        -- 2. Validate section index
        if not self.navigation or sectionIndex > table.getn(self.navigation.handlers) then
            self:Debug("error", "Invalid section index", true)
            return
        end
        
        -- 3. Update state
        self:Debug("sync", "Updating state: " .. sectionIndex, true)
        local oldIndex = self.navigation.currentIndex
        self.navigation.currentIndex = sectionIndex
        
        -- 4. Save to SavedVariables
        if TWRA_SavedVariables.assignments then
            TWRA_SavedVariables.assignments.currentSection = sectionIndex
            self:Debug("sync", "Saved current section: " .. sectionIndex, true)
        end
        
        -- 5. Update dropdown text ALWAYS
        if self.navigation and self.navigation.handlerText then
            self:Debug("sync", "Updating dropdown to: " .. sectionName, true)
            self.navigation.handlerText:SetText(sectionName)
        else
            self:Debug("error", "NO HANDLER TEXT UI ELEMENT!", true)
        end
        
        -- 6. Update display if visible
        if self.mainFrame and self.mainFrame:IsShown() and self.currentView ~= "options" and self.DisplayCurrentSection then
            self:Debug("sync", "Updating display", true)
            self:DisplayCurrentSection()
        end
        
        -- 7. ALWAYS show OSD
        if self.ShowSectionNameOverlay then
            self:Debug("sync", "Showing OSD overlay", true)
            self:ShowSectionNameOverlay(sectionName, sectionIndex, table.getn(self.navigation.handlers))
        else
            self:Debug("error", "NO OSD FUNCTION!", true)
        end
        
        -- Success message
        self:Debug("sync", "Changed to section " .. sectionIndex .. " (" .. sectionName .. ") by " .. sender)
    else
        self:Debug("sync", "Ignoring older timestamp", true)
    end
    
    self:Debug("sync", "SECTION HANDLER COMPLETE", true)
end

-- Handle VERSION command
function TWRA:HandleVersionCommand(args, sender)
    self:Debug("sync", "Processing VERSION command")
    
    local parts = self:SplitString(args, ":")
    if table.getn(parts) < 2 then 
        self:Debug("error", "Invalid VERSION format")
        return 
    end
    
    local timestamp = tonumber(parts[1])
    local senderName = parts[2]
    
    -- Safety check for valid timestamp
    if not timestamp then
        self:Debug("error", "Invalid timestamp in VERSION from " .. sender)
        return
    end
    
    self:Debug("sync", sender .. " has version with timestamp: " .. tostring(timestamp))
    
    -- Check if we have newer data to share
    local ourTimestamp = TWRA_SavedVariables.assignments and TWRA_SavedVariables.assignments.timestamp or 0
    
    if ourTimestamp > timestamp then
        self:Debug("sync", "Our data is newer - announcing to group")
        
        -- Announce our data to the group
        if TWRA_SavedVariables.assignments and TWRA_SavedVariables.assignments.source then
            local announceMsg = string.format("%s:%d:%s", 
                self.SYNC.COMMANDS.ANNOUNCE,
                ourTimestamp,
                TWRA_SavedVariables.assignments.source)
            
            self:SendAddonMessage(announceMsg)
        else
            self:Debug("error", "Can't announce - no source data")
        end
    elseif timestamp > ourTimestamp then
        self:Debug("sync", "Their data is newer - requesting")
        
        -- Request newer data
        self:SendAddonMessage(self.SYNC.COMMANDS.DATA_REQUEST .. ":" .. timestamp)
    else
        self:Debug("sync", "Same timestamp, no action needed")
    end
end

-- Handle DATA_REQUEST command with chunking
function TWRA:HandleDataRequestCommand(args, sender)
    self:Debug("sync", "Processing DATA_REQUEST command")
    
    -- Parse the requested timestamp
    local requestedTimestamp = tonumber(args)
    if not requestedTimestamp then 
        self:Debug("error", "Invalid timestamp in DATA_REQUEST")
        return 
    end
    
    local ourTimestamp = TWRA_SavedVariables.assignments and TWRA_SavedVariables.assignments.timestamp or 0
    
    -- Only respond if we have the requested version and have source data
    if requestedTimestamp == ourTimestamp and TWRA_SavedVariables.assignments and TWRA_SavedVariables.assignments.source then
        -- Add a small random delay (0-1 seconds) to reduce chance of multiple simultaneous responses
        local delay = math.random()
        
        -- Store the fact that we're going to respond
        self.SYNC.pendingResponse = true
        
        -- Wait a moment before sending
        self:ScheduleTimer(function()
            -- Check if someone else already responded
            if not self.SYNC.pendingResponse then
                self:Debug("sync", "Someone else already responded, skipping")
                return
            end
            
            self.SYNC.pendingResponse = false
            
            -- Get the data to send
            local data = TWRA_SavedVariables.assignments.source
            local dataLength = string.len(data)
            
            self:Debug("sync", "Sending requested data to " .. sender)
            
            -- Maximum chunk size (safe for addon communication)
            local maxChunkSize = 200  -- Reduced for safety
            
            -- If small enough, send as one message
            if dataLength <= maxChunkSize then
                local responseMsg = string.format("%s:%d:%s", 
                    self.SYNC.COMMANDS.DATA_RESPONSE,
                    requestedTimestamp,
                    data)
                self:SendAddonMessage(responseMsg)
                self:Debug("sync", "Sent data in one part (" .. dataLength .. " bytes)")
            else
                -- Send in chunks
                local chunks = math.ceil(dataLength / maxChunkSize)
                self:Debug("sync", "Splitting data into " .. chunks .. " chunks")
                
                for i = 1, chunks do
                    local start = (i-1) * maxChunkSize + 1
                    local finish = math.min(i * maxChunkSize, dataLength)
                    local chunk = string.sub(data, start, finish)
                    
                    -- Format: DATA_RESPONSE:timestamp:chunkNum:totalChunks:chunkData
                    local chunkMsg = string.format("%s:%d:%d:%d:%s", 
                        self.SYNC.COMMANDS.DATA_RESPONSE,
                        requestedTimestamp,
                        i,
                        chunks,
                        chunk)
                    
                    -- Delay each chunk to avoid flooding
                    local chunkDelay = (i-1) * 0.3  -- 300ms between chunks
                    self:ScheduleTimer(function()
                        self:SendAddonMessage(chunkMsg)
                        self:Debug("sync", "Sent chunk " .. i .. " of " .. chunks)
                    end, chunkDelay)
                end
            end
        end, delay)
    else
        -- Log message for debugging when we can't respond
        if requestedTimestamp ~= ourTimestamp then
            self:Debug("sync", "Can't respond - timestamp mismatch (requested " .. 
                requestedTimestamp .. ", we have " .. ourTimestamp .. ")")
        elseif not TWRA_SavedVariables.assignments then
            self:Debug("error", "Can't respond - no assignments data")
        elseif not TWRA_SavedVariables.assignments.source then
            self:Debug("error", "Can't respond - no source data")
        end
    end
end

-- Handle DATA_RESPONSE command with OSD progress updates
function TWRA:HandleDataResponseCommand(args, sender)
    self:Debug("sync", "Processing DATA_RESPONSE command from " .. sender)
    
    -- Mark that someone has responded (to avoid duplicate responses)
    self.SYNC.pendingResponse = false
    
    -- Check if this is a chunked response
    local colonPos1 = string.find(args, ":", 1, true)
    if not colonPos1 then 
        self:Debug("error", "Invalid DATA_RESPONSE format")
        return 
    end
    
    local timestamp = tonumber(string.sub(args, 1, colonPos1 - 1))
    local remaining = string.sub(args, colonPos1 + 1)
    
    -- Check for chunked format
    local colonPos2 = string.find(remaining, ":", 1, true)
    if colonPos2 then
        -- This is a chunked message format: timestamp:chunkNum:totalChunks:data
        local chunkNum = tonumber(string.sub(remaining, 1, colonPos2 - 1))
        remaining = string.sub(remaining, colonPos2 + 1)
        
        local colonPos3 = string.find(remaining, ":", 1, true)
        if not colonPos3 then
            self:Debug("error", "Invalid chunked message format - missing totalChunks")
            return
        end
        
        local totalChunks = tonumber(string.sub(remaining, 1, colonPos3 - 1))
        local chunkData = string.sub(remaining, colonPos3 + 1)
        
        if not timestamp or not chunkNum or not totalChunks then
            self:Debug("error", "Invalid chunked message format - missing values")
            return
        end
        
        self:Debug("sync", "Received chunk " .. chunkNum .. " of " .. totalChunks)
        
        -- Initialize chunk storage if needed
        if not self.SYNC.chunks then
            self.SYNC.chunks = {}
        end
        
        -- Initialize specific timestamp chunk storage if needed
        if not self.SYNC.chunks[timestamp] then
            self.SYNC.chunks[timestamp] = {
                data = {},
                receivedChunks = 0,
                totalChunks = totalChunks,
                sender = sender
            }
        end
        
        -- Store this chunk
        self.SYNC.chunks[timestamp].data[chunkNum] = chunkData
        self.SYNC.chunks[timestamp].receivedChunks = self.SYNC.chunks[timestamp].receivedChunks + 1
        
        -- Calculate progress percentage
        local progress = math.floor((self.SYNC.chunks[timestamp].receivedChunks / totalChunks) * 100)
        self:Debug("sync", "Receiving data: " .. progress .. "% complete")
        
        -- Show sync progress in OSD
        self:ShowSyncProgressInOSD(progress, sender)
        
        -- If we have all chunks, combine and process
        if self.SYNC.chunks[timestamp].receivedChunks == totalChunks then
            self:Debug("sync", "All chunks received, combining data")
            
            -- Combine all chunks in correct order
            local completeData = ""
            for i = 1, totalChunks do
                if self.SYNC.chunks[timestamp].data[i] then
                    completeData = completeData .. self.SYNC.chunks[timestamp].data[i]
                else
                    self:Debug("error", "Missing chunk " .. i .. ", can't combine")
                    return
                end
            end
            
            self:Debug("sync", "Combined data length: " .. string.len(completeData))
            
            -- Process the complete data
            self:ProcessCompleteData(completeData, timestamp, sender)
            
            -- Clean up
            self.SYNC.chunks[timestamp] = nil
            
            -- Hide sync progress OSD
            self:HideSyncProgressOSD()
        end
    else
        -- Single part format: timestamp:data
        local data = remaining
        self:Debug("sync", "Received single-part data, length: " .. string.len(data))
        
        -- Show 100% progress for single-part data
        self:ShowSyncProgressInOSD(100, sender)
        
        -- Process the data directly
        self:ProcessCompleteData(data, timestamp, sender)
        
        -- Hide sync progress OSD after a short delay
        self:ScheduleTimer(function()
            self:HideSyncProgressOSD()
        end, 0.5)
    end
end

-- New function to process complete data after all chunks are assembled
function TWRA:ProcessCompleteData(data, timestamp, sender)
    local ourTimestamp = TWRA_SavedVariables.assignments and TWRA_SavedVariables.assignments.timestamp or 0
    
    if timestamp and timestamp > ourTimestamp then
        self:Debug("sync", "Processing newer data from " .. sender)
        
        -- Decode the data
        local decodedData = self:DecodeBase64(data, timestamp, true)
        if not decodedData then
            self:Debug("error", "Failed to decode data from " .. sender)
            return
        end
        
        self:Debug("sync", "Successfully decoded data with " .. 
            table.getn(decodedData) .. " entries")
        
        -- Update our data
        TWRA_SavedVariables.assignments = {
            data = decodedData,
            source = data,
            timestamp = timestamp,
            version = 1,
            currentSection = self.SYNC.pendingSection or 
                            (self.navigation and self.navigation.currentIndex) or 
                            1
        }
        
        -- Update fullData
        self.fullData = decodedData
        
        -- Rebuild navigation
        self:RebuildNavigation()
        
        -- Handle any pending section navigation
        if self.SYNC.pendingSection then
            if self.navigation and self.SYNC.pendingSection <= table.getn(self.navigation.handlers) then
                self.navigation.currentIndex = self.SYNC.pendingSection
                self:SaveCurrentSection()
            end
            self.SYNC.pendingSection = nil
        end
        
        -- Update the display
        self:HandleDisplayUpdate()
        
        self:Debug("sync", "Successfully synchronized with " .. sender)
    else
        self:Debug("sync", "Ignoring data from " .. sender .. 
                                    " - our data is newer or the same")
    end
end

-- Helper function to process sync data
function TWRA:ProcessSyncData(data, timestamp, sender)
    local ourTimestamp = TWRA_SavedVariables.assignments and TWRA_SavedVariables.assignments.timestamp or 0
    
    if timestamp and timestamp > ourTimestamp then
        self:Debug("sync", "Processing newer data from " .. sender)
        
        -- Decode the data
        local decodedData = self:DecodeBase64(data, timestamp, true)
        if not decodedData then
            self:Debug("error", "Failed to decode data from " .. sender)
            return
        end
        
        -- Update our data
        TWRA_SavedVariables.assignments = {
            data = decodedData,
            source = data,
            timestamp = timestamp,
            version = 1,
            currentSection = self.SYNC.pendingSection or 
                            (self.navigation and self.navigation.currentIndex) or 
                            1
        }
        
        -- Update fullData
        self.fullData = decodedData
        
        -- Rebuild navigation
        self:RebuildNavigation()
        
        -- Handle any pending section navigation
        if self.SYNC.pendingSection then
            if self.navigation and self.SYNC.pendingSection <= table.getn(self.navigation.handlers) then
                self.navigation.currentIndex = self.SYNC.pendingSection
                self:SaveCurrentSection()
            end
            self.SYNC.pendingSection = nil
        end
        
        -- Update the display
        self:HandleDisplayUpdate()
        
        self:Debug("sync", "Successfully synchronized with " .. sender)
    else
        self:Debug("sync", "Ignoring data from " .. sender .. 
                                    " - our data is newer or the same")
    end
end

-- Split the data update from display update
function TWRA:UpdateStoredData(data, timestamp, targetSection)
    local decodedData
    if type(data) == "string" then
        -- Use noAnnounce=true to avoid recursive broadcasts
        decodedData = self:DecodeBase64(data, timestamp, true)
    else
        decodedData = data
    end
    
    if not decodedData then
        self:Debug("error", "Failed to decode sync data")
        return false
    end
    
    -- Use the specified section, default to 1, or keep current if available
    local sectionToUse = targetSection or 
                        (self.navigation and self.navigation.currentIndex) or 
                        1
    
    -- Update saved variables
    TWRA_SavedVariables.assignments = {
        data = decodedData,
        source = type(data) == "string" and data or nil,
        timestamp = timestamp,
        version = 1,
        currentSection = sectionToUse
    }
    
    -- Update fullData
    self.fullData = decodedData
    
    -- Rebuild navigation
    self:RebuildNavigation()
    
    -- Set the current section index
    if self.navigation and self.navigation.handlers then
        -- Make sure the section index is valid
        if sectionToUse > table.getn(self.navigation.handlers) then
            sectionToUse = 1
        end
        self.navigation.currentIndex = sectionToUse
    end
    
    return true
end

-- Handle display updates based on current view
function TWRA:HandleDisplayUpdate()
    if self.currentView == "options" then
        -- Store a flag indicating that we should update when returning to main view
        self.pendingNavigation = self.navigation.currentIndex
        self:Debug("ui", "In options view - deferring UI update")
    else
        -- We're in main view, update immediately
        if self.DisplayCurrentSection then
            self:DisplayCurrentSection()
            self:Debug("ui", "In main view - updating UI immediately")
        else
            self:Debug("error", "DisplayCurrentSection function not found")
        end
    end
end

-- Called when group composition changes
function TWRA:OnGroupChanged()
    if GetNumRaidMembers() > 0 or GetNumPartyMembers() > 0 then
        -- Announce our version and data timestamp to the group
        local msg = string.format("%s:%d:%s", 
            self.SYNC.COMMANDS.VERSION,
            TWRA_SavedVariables.assignments and TWRA_SavedVariables.assignments.timestamp or 0,
            UnitName("player"))
        self:SendAddonMessage(msg)
    end
end

-- Function to broadcast section change
function TWRA:BroadcastSectionChange(sectionIndex)
    -- Skip if live sync is disabled or we're not in a group
    if not self.SYNC.liveSync then 
        self:Debug("sync", "Live sync disabled - not broadcasting section")
        return 
    end
    
    -- Skip if we're not in a group
    if GetNumRaidMembers() == 0 and GetNumPartyMembers() == 0 then
        self:Debug("sync", "Not in a group - not broadcasting section")
        return
    end
    
    -- Skip if we don't have assignments data
    if not TWRA_SavedVariables.assignments or not TWRA_SavedVariables.assignments.timestamp then
        self:Debug("sync", "No assignments data - not broadcasting section") 
        return
    end
    
    -- Skip if navigation is not properly initialized
    if not self.navigation or not self.navigation.handlers then
        self:Debug("sync", "Navigation not initialized - not broadcasting section")
        return
    end
    
    -- Validate section index
    if not sectionIndex or sectionIndex < 1 or sectionIndex > table.getn(self.navigation.handlers) then
        self:Debug("error", "Invalid section index: " .. tostring(sectionIndex))
        return
    end
    
    -- Build and send section message
    local sectionMsg = string.format("%s:%d:%s:%d", 
        self.SYNC.COMMANDS.SECTION,
        TWRA_SavedVariables.assignments.timestamp,
        self.navigation.handlers[sectionIndex],
        sectionIndex)
    
    self:Debug("sync", "Broadcasting section change: " .. 
        self.navigation.handlers[sectionIndex] .. " (index " .. sectionIndex .. ")")
    
    self:SendAddonMessage(sectionMsg)
end

-- Toggle LiveSync feature
function TWRA:ToggleLiveSync(state)
    -- Set state if provided, otherwise toggle
    if state ~= nil then
        self.SYNC.liveSync = state
    else
        self.SYNC.liveSync = not self.SYNC.liveSync
    end
    
    -- Save to config
    if not TWRA_SavedVariables.options then TWRA_SavedVariables.options = {} end
    TWRA_SavedVariables.options.liveSync = self.SYNC.liveSync -- Store as boolean
    
    -- Auto-disable tank sync if live sync is disabled
    if not self.SYNC.liveSync and self.SYNC.tankSync then
        self:ToggleTankSync(false)
    end
    
    -- Debug message
    self:Debug("sync", "LiveSync " .. (self.SYNC.liveSync and "enabled" or "disabled"))
    
    return self.SYNC.liveSync
end

-- Toggle Tank Sync feature
function TWRA:ToggleTankSync(state)
    -- Set state if provided, otherwise toggle
    if state ~= nil then
        self.SYNC.tankSync = state
    else
        self.SYNC.tankSync = not self.SYNC.tankSync
    end
    
    -- Auto-enable live sync if tank sync is enabled
    if self.SYNC.tankSync and not self.SYNC.liveSync then
        self:ToggleLiveSync(true)
    end
    
    -- Save to config
    if not TWRA_SavedVariables.options then TWRA_SavedVariables.options = {} end
    TWRA_SavedVariables.options.tankSync = self.SYNC.tankSync -- Store as boolean
    
    -- Debug message
    self:Debug("sync", "TankSync " .. (self.SYNC.tankSync and "enabled" or "disabled"))
    
    return self.SYNC.tankSync
end