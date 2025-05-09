-- Global variables initialization
-- Early initialization at file load time to prevent nil references
TWRA_SavedVariables = TWRA_SavedVariables or {}
TWRA_Assignments = TWRA_Assignments or {}

-- CRITICAL: Ensure data table always exists
if not TWRA_Assignments.data then
    TWRA_Assignments.data = {}
end

-- Addon namespace
TWRA = TWRA or {}

-- Navigate to a specific section index
function TWRA:NavigateToSection(index, source)
    -- Debug entry with source tracking
    self:Debug("nav", "NavigateToSection called with index: " .. tostring(index) .. ", source: " .. tostring(source or "unknown"))
    -- Handle legacy case where section is passed as a name instead of index
    if type(index) == "string" then
        -- Find the index for this name
        for i, name in ipairs(self.navigation.handlers) do
            if name == index then
                index = i
                self:Debug("nav", "Converted section name to index: " .. i)
                break
            end
        end
    end
    
    -- Perform validation checks
    if not self.navigation then
        self:Debug("error", "NavigateToSection: Navigation context not initialized")
        return false
    end
    
    if not self.navigation.handlers or table.getn(self.navigation.handlers) == 0 then
        self:Debug("error", "NavigateToSection: No section handlers available")
        return false
    end
    
    -- Make sure index is a number within the valid range
    if type(index) ~= "number" or index < 1 or index > table.getn(self.navigation.handlers) then
        self:Debug("error", "NavigateToSection: Invalid section index " .. tostring(index))
        return false
    end
    
    -- Get the section name for this index
    local sectionName = self.navigation.handlers[index]
    if not sectionName then
        self:Debug("error", "NavigateToSection: No section name found at index " .. index)
        return false
    end
    
    -- Simple compressed data handling with example exception
    local missingCompressedData = false
    local needsProcessing = false
    
    -- Check if compressed data is empty (existence is guaranteed)
    if TWRA_CompressedAssignments.sections[index] == "" then
        missingCompressedData = true
        TWRA:Debug("nav", "Missing compressed data for section index: " .. index)
    else
        TWRA:Debug("nav", "Compressed data available for section index: " .. index)
    end
    
    -- Example data overrides the need for compressed data
    if TWRA_Assignments and TWRA_Assignments.isExample then
        missingCompressedData = false
        TWRA:Debug("nav", "Using example data, no compressed data needed")
    end
    
    -- If data is missing, request it and exit
    if missingCompressedData then
        if self.SYNC then
            self.SYNC.pendingSection = index
        end
        if self.RequestSectionSync then
            self:Debug("nav", "Requesting section data for index: " .. index)
            self:RequestSectionSync(index)
        else
            self:Debug("nav", "RequestSectionData function not available but data is missing")
        end
        -- return false -- We're no longer stopping, we're adding text to the frame to show the state instead.
    end
    
    -- Check if section data needs processing
    needsProcessing = TWRA_Assignments.data[index]["NeedsProcessing"] or false
    if needsProcessing then
        if self.ProcessSectionData and not missingCompressedData then
            self:Debug("nav", "Processing section data for index: " .. index)
            self:ProcessSectionData(index)
        end
    end
    
    -- Update the current index
    self.navigation.currentIndex = index
    
    -- Update the handler text in the UI
    if self.navigation.handlerText then
        self.navigation.handlerText:SetText(sectionName)
    end
    
    -- Store the current section in the assignments table to persist across sessions
    if TWRA_Assignments then
        -- Save both index and name for compatibility
        TWRA_Assignments.currentSection = index
        TWRA_Assignments.currentSectionName = sectionName
    end
    
    -- Find section data for this section
    local sectionData = nil
    if TWRA_Assignments and TWRA_Assignments.data then
        for idx, section in pairs(TWRA_Assignments.data) do
            if section["Section Name"] == sectionName then
                sectionData = section
                break
            end
        end
    end
    
    -- Prepare navigation event data
    local eventData = {
        index = index,
        sectionName = sectionName,
        source = source or "unknown",
        sectionData = sectionData
    }
    
    -- Trigger the NAVIGATE_TO_SECTION event and get number of listeners that were called
    local listenersCount = self:TriggerEvent("NAVIGATE_TO_SECTION", eventData)
    
    -- Trigger the SECTION_CHANGED event for components that listen to it
    -- This is needed for OSD, Minimap, AutoTanks, and other modules
    self:TriggerEvent("SECTION_CHANGED", sectionName, index, table.getn(self.navigation.handlers), source)
    
    -- Update UI if main frame exists and is shown
    if self.mainFrame and self.mainFrame:IsShown() and self.currentView == "main" then
        -- Update main frame content
        if previousIndex ~= index or source == "reload" then
            if self.FilterAndDisplayHandler then
                self:FilterAndDisplayHandler(sectionName)
                self:Debug("nav", "Updated main frame content for section: " .. sectionName)
            elseif self.DisplayCurrentSection then
                self:DisplayCurrentSection()
                self:Debug("nav", "Updated main frame content using DisplayCurrentSection for section: " .. sectionName)
            end
        end
    end
    
    -- Final debug to confirm navigation is complete
    self:Debug("nav", "Navigation complete: Section " .. index .. " (" .. sectionName .. ")")
    return true
end

-- Main initialization - called only once
function TWRA:Initialize()
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("VARIABLES_LOADED")
    frame:RegisterEvent("RAID_ROSTER_UPDATE")
    frame:RegisterEvent("PARTY_MEMBERS_CHANGED")
    frame:RegisterEvent("GROUP_ROSTER_UPDATE")
    frame:RegisterEvent("CHAT_MSG_ADDON")
    frame:RegisterEvent("UPDATE_BINDINGS")
    frame:RegisterEvent("PLAYER_ENTERING_WORLD")  -- Add this to catch UI reloads
    frame:RegisterEvent("RAID_TARGET_UPDATE")  
    
    -- Store a reference to TWRA for the event handler to use
    local addon = self
    
    frame:SetScript("OnEvent", function()
        if event == "VARIABLES_LOADED" then
            -- Initialize compression system early
            if addon.InitializeCompression then
                addon:Debug("general", "Initializing compression system")
                addon:InitializeCompression()
            else
                addon:Debug("error", "InitializeCompression function not found - sync may not work properly!")
            end
            
            -- Load saved assignments
            addon:LoadSavedAssignments()
            
            -- Initialize debug system
            if addon.InitializeDebug then
                addon:InitializeDebug()
            end
            
            -- Initialize Performance monitoring
            if addon.InitializePerformance then
                addon:Debug("general", "Initializing performance monitoring system")
                addon:InitializePerformance()
            else
                addon:Debug("error", "InitializePerformance function not found")
            end
            
            -- Initialize Sync namespace if needed
            addon.SYNC = addon.SYNC or {}
            
            -- *** IMPORTANT: Check LiveSync setting early and activate if needed ***
            if TWRA_SavedVariables and TWRA_SavedVariables.options and TWRA_SavedVariables.options.liveSync then
                addon:Debug("general", "LiveSync is enabled in saved settings, activating early")
                addon.SYNC.liveSync = true
                
                -- Make sure CHAT_MSG_ADDON is registered for LiveSync
                if frame and not frame:IsEventRegistered("CHAT_MSG_ADDON") then
                    frame:RegisterEvent("CHAT_MSG_ADDON")
                    addon:Debug("general", "Registered for CHAT_MSG_ADDON early for LiveSync")
                end
            else
                addon:Debug("general", "LiveSync not enabled in saved settings")
                addon.SYNC.liveSync = false
            end
            
            -- *** IMPORTANT FIX: Register section change handler early, regardless of sync status ***
            -- This ensures section changes are properly broadcasted
            if addon.RegisterSectionChangeHandler then
                addon:Debug("general", "Registering section change handler during main initialization")
                addon:RegisterSectionChangeHandler()
                
                -- Verify that it registered successfully
                if addon.SYNC and not addon.SYNC.sectionChangeHandlerRegistered then
                    addon:Debug("error", "Section change handler was not registered properly. Trying again...")
                    addon:RegisterSectionChangeHandler()
                end
                
                -- Debug the LiveSync status
                addon:Debug("error", "After registering section handler - LiveSync status: " .. tostring(addon.SYNC.liveSync))
            else
                addon:Debug("error", "RegisterSectionChangeHandler function not found!")
            end
            
            -- Initialize Sync system
            if addon.InitializeSync then
                addon:Debug("general", "Initializing sync system")
                addon:InitializeSync()
                
                -- Double-check LiveSync status after initialization
                if addon.SYNC then
                    addon:Debug("error", "After InitializeSync - LiveSync status: " .. tostring(addon.SYNC.liveSync))
                end
            else
                addon:Debug("error", "InitializeSync function not found - sync functionality will not work!")
            end
            
            addon:Debug("general", "Variables loaded")
        elseif event == "PLAYER_ENTERING_WORLD" then
            -- This fires on initial load and UI reload
            addon:Debug("general", "Player entering world - checking for UI reload")
            
            -- Extra check to make sure section change handler is registered
            if addon.RegisterSectionChangeHandler and addon.SYNC and not addon.SYNC.sectionChangeHandlerRegistered then
                addon:Debug("general", "Registering section change handler during PLAYER_ENTERING_WORLD")
                addon:RegisterSectionChangeHandler()
            end
            
            -- Extra check for LiveSync after reload
            if addon.SYNC and TWRA_SavedVariables and TWRA_SavedVariables.options and TWRA_SavedVariables.options.liveSync then
                addon:Debug("general", "Re-activating LiveSync after UI reload")
                addon.SYNC.liveSync = true
                
                -- If we have an ActivateLiveSync function, call it
                if addon.ActivateLiveSync then
                    addon:ActivateLiveSync()
                end
            end
            
            -- Delay slightly to ensure other systems are ready
            addon:ScheduleTimer(function()
                -- If main frame exists and is shown, force refresh content
                if addon.mainFrame and addon.mainFrame:IsShown() and addon.currentView == "main" then
                    addon:Debug("ui", "UI reload detected with visible frame - refreshing content")
                    
                    -- Ensure navigation is restored first
                    if not addon.navigation or not addon.navigation.handlers or 
                       not addon.navigation.currentIndex then
                        addon:Debug("ui", "Rebuilding navigation after UI reload")
                        addon:RebuildNavigation()
                    end
                    
                    -- Force display current section
                    if addon.navigation and addon.navigation.handlers and 
                       addon.navigation.currentIndex and 
                       addon.navigation.handlers[addon.navigation.currentIndex] then
                        local currentSection = addon.navigation.handlers[addon.navigation.currentIndex]
                        addon:Debug("ui", "Refreshing to section: " .. currentSection)
                        addon:FilterAndDisplayHandler(currentSection)
                    end
                end
            end, 0.5)  -- Half second delay to ensure everything is loaded
        elseif event == "RAID_ROSTER_UPDATE" or event == "PARTY_MEMBERS_CHANGED" then
            -- Handle group changes
            if addon.OnGroupChanged then
                addon:OnGroupChanged()
            end
        elseif event == "CHAT_MSG_ADDON" then
            -- Critical fix: properly route addon messages to our handler
            if addon.OnChatMsgAddon then
                addon:OnChatMsgAddon(arg1, arg2, arg3, arg4)
            else
                addon:Debug("error", "OnChatMsgAddon handler not available")
            end
        elseif event == "UPDATE_BINDINGS" then
            -- Handle keybinding updates
            if addon.UpdateBindings then
                addon:UpdateBindings()
            end
        elseif event == "RAID_TARGET_UPDATE" then
            if self:CheckSkullMarkedMob() then
                -- Check if we have
                TWRA:CheckSkullMarkedMob()
            end
        end
    end)

    -- Initialize AutoNavigate if SuperWoW is available
    if self.InitializeAutoNavigate then self:InitializeAutoNavigate() end
    
    -- Initialize keybindings
    if self.InitializeBindings then self:InitializeBindings() end

    -- Initialize OSD
    if self.InitOSD then self:InitOSD() end
    
    -- Initialize Debug system (must be early)
    if self.InitDebug then 
        self:Debug("general", "Debug system initialized")
    end

    -- Also initialize Sync outside of event handler to ensure it runs
    if self.InitializeSync then
        self:Debug("general", "Initializing sync system during startup")
        self:InitializeSync()
    end

    -- Check if this is a UI reload and restore state
    if self.mainFrame and TWRA_Assignments then
        -- Restore current view
        if TWRA_SavedVariables.currentView then
            self.currentView = TWRA_SavedVariables.currentView
        end
        
        -- If we were in main view before reload, restore section too
        if self.currentView == "main" and 
           TWRA_Assignments.currentSection then
            self:Debug("ui", "UI reload detected - restoring section: " .. 
                      TWRA_Assignments.currentSection)
            self:NavigateToSection(TWRA_Assignments.currentSection, "reload")
        end
    end
end

-- Register for PLAYER_LOGOUT to save state
local logoutFrame = CreateFrame("Frame")
logoutFrame:RegisterEvent("PLAYER_LOGOUT")
logoutFrame:SetScript("OnEvent", function()
    if event == "PLAYER_LOGOUT" then
        TWRA:OnUnload()
    end
end)

-- Function to handle CHAT_MSG_ADDON events
function TWRA:OnChatMsgAddon(prefix, message, distribution, sender)
    -- Skip messages that aren't from our addon
    if prefix ~= "TWRA" then
        return
    end
    
    -- Always log the message for debugging
    self:Debug("sync", "Received " .. distribution .. " addon message from " .. sender .. ": " .. self:TruncateString(message, 50), true)
    
    -- Route the message to our handler if available
    if self.HandleAddonMessage then
        self:HandleAddonMessage(message, distribution, sender)
    else
        self:Debug("error", "HandleAddonMessage function not available - sync system not initialized properly")
    end
end

-- Utility function to truncate strings with ellipsis for better debugging
function TWRA:TruncateString(str, maxLength)
    if not str then return "nil" end
    if string.len(str) <= maxLength then return str end
    return string.sub(str, 1, maxLength) .. "..."
end

-- Add this utility function to clean data at all entry points
function TWRA:CleanAssignmentData(data, isTableFormat)
    self:Debug("data", "Cleaning assignment data")
    
    if isTableFormat then
        -- Handle table format (section => rows)
        local cleanedData = {}
        for section, rows in pairs(data) do
            -- Only include non-empty section names (after thorough whitespace trimming)
            if section and section ~= "" and string.gsub(section, "%s", "") ~= "" then
                -- Also filter out any empty rows for this section
                local filteredRows = {}
                for i = 1, table.getn(rows) do
                    -- Filter out completely empty rows
                    local isEmptyRow = true
                    for j = 1, table.getn(rows[i]) do
                        if rows[i][j] and rows[i][j] ~= "" then
                            isEmptyRow = false
                            break
                        end
                    end
                    
                    if not isEmptyRow then
                        table.insert(filteredRows, rows[i])
                    else
                        self:Debug("data", "Skipping empty row in section: " .. section)
                    end
                end
                
                -- Only include sections that have at least one non-empty row
                if table.getn(filteredRows) > 0 then
                    cleanedData[section] = filteredRows
                else
                    self:Debug("data", "Skipping section with only empty rows: " .. section)
                end
            else
                self:Debug("data", "Skipping empty section name")
            end
        end
        return cleanedData
    else
        -- Handle flat format (array of rows)
        local cleanedData = {}
        if data then
            for i = 1, table.getn(data) do
                -- Only include rows that have a valid section name
                if data[i] and data[i][1] and data[i][1] ~= "" and string.gsub(data[i][1], "%s", "") ~= "" then
                    table.insert(cleanedData, data[i])
                else
                    -- Log that we're skipping an empty section
                    self:Debug("data", "Skipping row with empty section name at index " .. i)
                end
            end
        end
        return cleanedData
    end
end

-- Function to check if we're dealing with example data
function TWRA:IsExampleData(data)
    self:Debug("error", "IsExampleData called from TWRA.lua")
    if not data then return false end
    
    -- Quick check for known example data markers
    for i = 1, table.getn(data) do
        if data[i][1] == "Welcome" and 
           data[i][2] == "Star" and
           data[i][3] == "Big nasty boss" then
            return true
        end
    end
    
    return false
end

-- Announcement functionality - completely rewritten
function TWRA:AnnounceAssignments()
    -- Get current section from navigation
    local currentSection = nil
    if self.navigation and self.navigation.handlers and self.navigation.currentIndex then
        currentSection = self.navigation.handlers[self.navigation.currentIndex]
    end
    
    if not currentSection then
        self:Debug("ui", "No current section to announce")
        return
    end
    
    self:Debug("ui", "Preparing to announce section: " .. currentSection)
    
    -- Get the current section data
    local sectionData = self:GetCurrentSectionData()
    if not sectionData then
        self:Debug("error", "Failed to get section data for " .. currentSection)
        return
    end
    
    -- First pass: collect all the messages we'll send
    local messageQueue = {}
    
    -- Add section header message with subtle gold color for emphasis
    table.insert(messageQueue, {
        text = "|cFFDDCC55Raid Assignments:|r " .. currentSection,
        type = "header"
    })
    
    -- Get header row
    local headerRow = sectionData["Section Header"]
    if not headerRow then
        self:Debug("error", "No header found in section data")
        return
    end
    
    -- Create column role mapping from header and track the original order of roles
    local columnRoles = {}
    local roleOrder = {}
    local seenRoles = {}
    
    -- In new format: Column 1 = "Icon", Column 2 = "Target", Column 3+ = roles
    for i = 3, table.getn(headerRow) do
        local roleName = headerRow[i]
        columnRoles[i] = roleName
        
        -- Track the order of unique roles as they first appear
        if roleName and not seenRoles[roleName] then
            seenRoles[roleName] = true
            table.insert(roleOrder, roleName)
        end
        
        self:Debug("ui", "Column " .. i .. " role: " .. (roleName or "nil"))
    end
    
    self:Debug("ui", "Role order: " .. table.concat(roleOrder, ", "))
    
    -- Define role colors with more muted tones
    local roleColors = {
        ["Tank"] = "|cFF7799CC", -- Muted blue
        ["Tanks"] = "|cFF7799CC", -- Muted blue
        ["Heal"] = "|cFF88BB99", -- Muted green
        ["Heals"] = "|cFF88BB99", -- Muted green
        ["Healer"] = "|cFF88BB99", -- Muted green
        ["Healers"] = "|cFF88BB99", -- Muted green
        ["DPS"] = "|cFFCC8877", -- Muted red
        ["Pull"] = "|cFFCCBB77", -- Muted yellow
        ["MC"] = "|cFFAA99BB",  -- Muted purple
        ["Raid Depoison"] = "|cFF88BBAA", -- Muted teal
        ["default"] = "|cFFBBAA88" -- Muted orange for other roles
    }
    
    local roleEndColor = "|r"
    
    -- Process normal assignment rows
    if sectionData["Section Rows"] then
        for _, rowData in ipairs(sectionData["Section Rows"]) do
            -- Skip special rows
            if rowData[1] ~= "Note" and rowData[1] ~= "Warning" and rowData[1] ~= "GUID" then
                local icon = rowData[1] -- Icon is now column 1
                local target = rowData[2] or "" -- Target is now column 2
                local messageText = ""
                
                -- Add colored icon text
                if icon and TWRA.COLORED_ICONS[icon] then
                    messageText = TWRA.COLORED_ICONS[icon] .. " " .. target
                else
                    messageText = target
                end
                
                -- Group roles by type, preserving the order from the header
                local roleGroups = {}
                
                -- Process each column for roles (start from column 3)
                for j = 3, table.getn(rowData) do
                    local role = rowData[j]
                    if role and role ~= "" then
                        -- Get role name from header
                        local roleName = columnRoles[j] or "Role"
                        
                        -- Create role group if it doesn't exist
                        if not roleGroups[roleName] then
                            roleGroups[roleName] = {}
                        end
                        
                        -- Add to appropriate role group
                        table.insert(roleGroups[roleName], role)
                    end
                end
                
                -- Add roles grouped by type, following the original order in the header
                local roleAdded = false
                for _, roleName in ipairs(roleOrder) do
                    local members = roleGroups[roleName]
                    if members and table.getn(members) > 0 then
                        -- Make Tank/Healer plural if there are multiple members
                        local displayRoleName = roleName
                        if (roleName == "Tank" or roleName == "Healer") and table.getn(members) > 1 then
                            displayRoleName = roleName .. "s"
                        end
                        
                        -- Get color for this role
                        local roleColor = roleColors[displayRoleName] or roleColors["default"]
                        
                        -- Add role header with proper color and delimiter
                        if roleAdded then
                            messageText = messageText .. " " .. roleColor .. displayRoleName .. ":" .. roleEndColor .. " "
                        else
                            messageText = messageText .. " " .. roleColor .. displayRoleName .. ":" .. roleEndColor .. " "
                            roleAdded = true
                        end
                        
                        -- Add members with comma separation and "and" for last (no coloring for names)
                        if table.getn(members) == 1 then
                            messageText = messageText .. members[1]
                        elseif table.getn(members) == 2 then
                            messageText = messageText .. members[1] .. " and " .. members[2]
                        else
                            for m = 1, table.getn(members) - 1 do
                                messageText = messageText .. members[m]
                                if m < table.getn(members) - 1 then
                                    messageText = messageText .. ", "
                                else
                                    messageText = messageText .. ", and "
                                end
                            end
                            messageText = messageText .. members[table.getn(members)]
                        end
                    end
                end
                
                -- Add to message queue
                table.insert(messageQueue, {
                    text = messageText,
                    type = "assignment"
                })
                
                self:Debug("ui", "Assignment message created: " .. messageText)
            end
        end
    end
    
    -- Get warnings from Section Metadata
    if sectionData["Section Metadata"] and sectionData["Section Metadata"]["Warning"] then
        local warnings = sectionData["Section Metadata"]["Warning"]
        
        -- Add each warning to the message queue with more subtle red highlighting
        for _, warningText in ipairs(warnings) do
            if warningText and warningText ~= "" then
                table.insert(messageQueue, {
                    text = "|cFFDD5555WARNING:|r " .. warningText,
                    type = "warning"
                })
                self:Debug("ui", "Warning message added from metadata: " .. warningText)
            end
        end
    else
        self:Debug("ui", "No warnings found in section metadata")
    end
    
    -- Now send the messages using the existing function
    self:SendAnnouncementMessages(messageQueue)
end

-- New function to handle sending the prepared messages
function TWRA:SendAnnouncementMessages(messageQueue)
    if not messageQueue or table.getn(messageQueue) == 0 then
        self:Debug("ui", "No messages to announce")
        return
    end
    
    -- Determine which channels to use for different message types
    local channelInfo = self:GetAnnouncementChannels()
    
    -- Debug print of channel configuration
    self:Debug("ui", "Channel configuration: header=" .. channelInfo.header .. 
              ", assignment=" .. channelInfo.assignment .. 
              ", warning=" .. channelInfo.warning)
    
    -- Send all messages with throttling
    local index = 1
    local messagesToSend = {}
    
    -- First pass: prepare all messages with their proper channels
    for i, msg in ipairs(messageQueue) do
        local channel = channelInfo.assignment -- Default
        if msg.type == "header" then
            channel = channelInfo.header
        elseif msg.type == "warning" then
            channel = channelInfo.warning
        end
        table.insert(messagesToSend, {
            text = msg.text,
            channel = channel,
            channelNum = channelInfo.channelNum
        })
    end
    
    -- Debug print of final message queue with channels
    self:Debug("ui", "Final announcement queue:")
    for i, msg in ipairs(messagesToSend) do
        self:Debug("ui", "  [" .. i .. "/" .. table.getn(messagesToSend) .. "] " .. 
                  msg.text .. " to " .. msg.channel)
    end
    
    -- Send function with proper throttling
    local function SendNextMessage()
        if index <= table.getn(messagesToSend) then
            local msg = messagesToSend[index]
            
            self:Debug("ui", "Announcing [" .. index .. "/" .. table.getn(messagesToSend) .. "]: " .. 
                      msg.text .. " to " .. msg.channel)
            
            -- Process item links before sending
            local processedText = msg.text
            if self.Items and self.Items.ProcessText then
                self:Debug("items", "Processing item links in announcement: " .. msg.text)
                processedText = self.Items:ProcessText(processedText)
                
                -- Also try to process common consumable names
                if self.Items.ProcessConsumables then
                    processedText = self.Items:ProcessConsumables(processedText)
                end
                
                -- Log the processed text for debugging
                if processedText ~= msg.text then
                    self:Debug("items", "Processed item links: " .. processedText)
                end
            end
            
            -- Send the actual message
            if msg.channel == "CHANNEL" and msg.channelNum then
                SendChatMessage(processedText, msg.channel, nil, msg.channelNum)
            else
                SendChatMessage(processedText, msg.channel)
            end
            
            -- Increment index for next message
            index = index + 1
            
            -- Only schedule next message if there are more to send
            if index <= table.getn(messagesToSend) then
                self:ScheduleTimer(SendNextMessage, 0.3)
            else
                self:Debug("ui", "All messages sent successfully")
            end
        end
    end
    
    -- Start sending the first message
    SendNextMessage()
end

-- Separate function to determine which channels to use
function TWRA:GetAnnouncementChannels()
    local headerChannel = "RAID_WARNING"  -- Default for section header
    local assignmentChannel = "RAID"      -- Default for assignments
    local warningChannel = "RAID_WARNING" -- Default for warnings
    local channelNum = nil                -- For custom channel
    
    -- Get saved channel preference
    local selectedChannel = TWRA_SavedVariables.options and 
                          TWRA_SavedVariables.options.announceChannel or 
                          "GROUP"
    
    -- Adjust channels based on selection and current group context
    if selectedChannel == "GROUP" then
        if GetNumRaidMembers() > 0 then
            -- In a raid - use raid warnings if player has assist
            headerChannel = "RAID_WARNING"
            assignmentChannel = "RAID"
            warningChannel = (IsRaidLeader() or IsRaidOfficer()) and "RAID_WARNING" or "RAID"
        elseif GetNumPartyMembers() > 0 then
            -- In a party
            headerChannel = "PARTY"
            assignmentChannel = "PARTY"
            warningChannel = "PARTY"
        else
            -- Solo
            headerChannel = "SAY"
            assignmentChannel = "SAY"
            warningChannel = "SAY"
        end
    elseif selectedChannel == "CHANNEL" then
        -- Custom channel
        local customChannel = TWRA_SavedVariables.options and TWRA_SavedVariables.options.customChannel
        if customChannel and customChannel ~= "" then
            -- Find the channel number
            channelNum = GetChannelName(customChannel)
            if channelNum and channelNum > 0 then
                headerChannel = "CHANNEL"
                assignmentChannel = "CHANNEL"
                warningChannel = "CHANNEL"
            else
                -- Fall back to SAY if channel not found
                headerChannel = "SAY"
                assignmentChannel = "SAY"
                warningChannel = "SAY"
                self:Debug("ui", "Custom channel not found, falling back to SAY")
            end
        else
            -- No custom channel specified
            headerChannel = "SAY"
            assignmentChannel = "SAY"
            warningChannel = "SAY"
            self:Debug("ui", "No custom channel specified, using SAY")
        end
    end
    
    -- Return info as a structured table
    return {
        header = headerChannel,
        assignment = assignmentChannel,
        warning = warningChannel,
        channelNum = channelNum
    }
end

-- Add slash command
SLASH_TWRA1 = "/twra"
SlashCmdList["TWRA"] = function(msg)
    -- Parse the command
    local command, arg = string.match(msg, "^(%S+)%s*(.*)$")
    command = command and string.lower(command) or ""
    
    if command == "debug" then
        -- Handle debug commands
        if arg == "list" then
            -- List all debug categories
            TWRA:ListDebugCategories()
        elseif arg == "all" or arg == "" then
            -- Toggle all debug categories
            TWRA:ToggleDebug()
            DEFAULT_CHAT_FRAME:AddMessage("TWRA: Debug mode " .. 
                (TWRA.DEBUG.enabled and "enabled" or "disabled"))
        elseif TWRA.DEBUG_CATEGORIES[arg] then
            -- Toggle specific category
            TWRA:ToggleDebugCategory(arg)
        else
            DEFAULT_CHAT_FRAME:AddMessage("TWRA: Unknown debug category: " .. arg)
            TWRA:ListDebugCategories()
        end
    elseif command == "perf" or command == "performance" then
        -- Handle performance commands by splitting remaining arguments
        local args = {}
        for word in string.gmatch(arg, "%S+") do
            table.insert(args, word)
        end
        
        -- Call the performance command handler if it exists
        if TWRA.HandlePerfCommand then
            TWRA:HandlePerfCommand(args)
        else
            DEFAULT_CHAT_FRAME:AddMessage("TWRA: Performance monitoring system not initialized")
        end
    else
        -- Default behavior - toggle main frame
        TWRA:ToggleMainFrame()
    end
end

-- Initialize UI at end of loading - THIS IS THE ONLY INITIALIZE CALL
TWRA:Initialize()

-- Improve ShowOptionsView to properly set current view and safely handle UI elements
function TWRA:ShowOptionsView()
    -- Set view state first
    self.currentView = "options"

    -- Create options interface if it doesn't exist yet
    if not self.optionsElements or table.getn(self.optionsElements) == 0 then
        self:CreateOptionsInMainFrame()
    end

    -- Show options elements
    if self.optionsElements then
        for _, element in pairs(self.optionsElements) do
            if element.Show then
                element:Show()
            end
        end
    end
    
    -- Clear any footers and rows
    self:ClearFooters()
    self:ClearRows()
    
    -- Hide navigation elements
    if self.navigation then
        if self.navigation.prevButton then self.navigation.prevButton:Hide() end
        if self.navigation.nextButton then self.navigation.nextButton:Hide() end
        if self.navigation.menuButton then self.navigation.menuButton:Hide() end
        if self.navigation.dropdownMenu then self.navigation.dropdownMenu:Hide() end
        if self.navigation.handlerText then self.navigation.handlerText:Hide() end
    end
    
    -- Hide other main view buttons but show Sync All
    if self.announceButton then self.announceButton:Hide() end
    if self.updateTanksButton then self.updateTanksButton:Hide() end
    if self.syncAllButton then self.syncAllButton:Show() end  -- Show Sync All button in options view
    
    -- Reset frame height to default while in options
    self.mainFrame:SetHeight(300)
    
    -- Change button text if options button exists
    if self.optionsButton then
        self.optionsButton:SetText("Back")
    end
    
    self:Debug("ui", "Switched to options view - currentView = " .. self.currentView)
end

-- Handle group composition changes
function TWRA:OnGroupChanged()
    self:Debug("general", "Group composition changed, updating player table and dynamic info")
    
    -- Update the player table with current group information
    -- UpdatePlayerTable now checks TWRA_Assignments.isExample automatically
    self:UpdatePlayerTable()
    self:RefreshPlayerInfo()
    -- Update UI if main frame exists and is shown
    if self.mainFrame and self.mainFrame:IsShown() and self.currentView == "main" then
        -- Update main frame content
        if previousIndex ~= index or source == "reload" then
            if self.FilterAndDisplayHandler then
                self:FilterAndDisplayHandler(sectionName)
                self:Debug("nav", "Updated main frame content for section: " .. sectionName)
            elseif self.DisplayCurrentSection then
                self:DisplayCurrentSection()
                self:Debug("nav", "Updated main frame content using DisplayCurrentSection for section: " .. sectionName)
            end
        end
    end
    TWRA:UpdateOSDContent(TWRA_Assignments.currentSectionName, TWRA_Assignments.currentSection)
end