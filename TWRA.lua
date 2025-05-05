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
        -- return false -- Always return here to stop execution if compressed data is missing
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

-- Helper function to rebuild navigation after data updates
function TWRA:RebuildNavigation()
    -- Use the implementation from core/Core.lua
    if TWRA.core and TWRA.core.RebuildNavigation then
        return TWRA.core:RebuildNavigation()
    else
        -- If not available, call implementation in Core.lua directly
        return self:core_RebuildNavigation()
    end
end

-- Helper function to update UI elements based on current data
function TWRA:UpdateUI()
    self:Debug("ui", "Updating UI")
    
    -- Call UI update functions directly
    if self.UpdateNavigationButtons then
        self:UpdateNavigationButtons()
    end
    
    if self.DisplayCurrentSection then
        self:DisplayCurrentSection()
    else
        self:Error("DisplayCurrentSection not found!")
    end
    
    -- Try to update any visible UI elements
    if self.mainFrame and self.mainFrame:IsShown() then
        -- Update section text
        if self.navigation and self.navigation.handlerText and 
           self.navigation.currentIndex and self.navigation.handlers and
           self.navigation.handlers[self.navigation.currentIndex] then
            self.navigation.handlerText:SetText(self.navigation.handlers[self.navigation.currentIndex])
        end
    end
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
            
            -- Initialize Sync system
            if addon.InitializeSync then
                addon:Debug("general", "Initializing sync system")
                addon:InitializeSync()
            else
                addon:Debug("error", "InitializeSync function not found - sync functionality will not work!")
            end
            
            addon:Debug("general", "Variables loaded")
        elseif event == "PLAYER_ENTERING_WORLD" then
            -- This fires on initial load and UI reload
            addon:Debug("general", "Player entering world - checking for UI reload")
            
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

-- Save current view state on unload
function TWRA:OnUnload()
    -- Save which view we were in
    if self.currentView then
        TWRA_SavedVariables.currentView = self.currentView
    end
    
    -- Any other state that needs to be saved on unload
    self:Debug("general", "Saved settings on unload")
end

-- Register for PLAYER_LOGOUT to save state
local logoutFrame = CreateFrame("Frame")
logoutFrame:RegisterEvent("PLAYER_LOGOUT")
logoutFrame:SetScript("OnEvent", function()
    if event == "PLAYER_LOGOUT" then
        TWRA:OnUnload()
    end
end)

-- Event handler for all game events
function TWRA:OnEvent(frame, event, ...)
    self:Debug("general", "Event received: " .. event)
    
    if event == "ADDON_LOADED" and arg1 == "TWRA" then
        self:Debug("general", "ADDON_LOADED fired for TWRA")
        -- Initialize addon here
        
    elseif event == "PLAYER_ENTERING_WORLD" then
        self:Debug("general", "PLAYER_ENTERING_WORLD fired")
        -- Additional initialization
        
    elseif event == "CHAT_MSG_ADDON" then
        self:Debug("sync", "CHAT_MSG_ADDON: " .. arg1 .. " from " .. arg4)
        self:OnChatMsgAddon(arg1, arg2, arg3, arg4)
        
    elseif event == "PARTY_MEMBERS_CHANGED" or event == "RAID_ROSTER_UPDATE" then
        self:Debug("general", event .. " fired")
        if self.OnGroupChanged then
            self:OnGroupChanged()
        end
    end
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

-- Enhanced LoadSavedAssignments to update OSD after loading
function TWRA:LoadSavedAssignments()
    -- Check if we have saved assignments
    local needExampleData = false
    
    if not TWRA_Assignments then
        self:Debug("data", "No saved assignments found, will load example data")
        needExampleData = true
    elseif not TWRA_Assignments.data or (type(TWRA_Assignments.data) == "table" and next(TWRA_Assignments.data) == nil) then
        self:Debug("data", "Assignment data is nil or empty, will load example data")
        needExampleData = true
    end
    
    -- Load example data if needed
    if needExampleData then
        if self.LoadExampleDataAndShow then
            self:Debug("data", "Loading example data for new users")
            self:LoadExampleDataAndShow()
            return true
        elseif self.LoadExampleData then
            self:Debug("data", "Loading example data (without UI refresh)")
            self:LoadExampleData()
            return true
        end
        return false
    end
    
    -- Check if the assignments structure is complete
    if not TWRA_Assignments.data then
        self:Debug("error", "Assignment data structure incomplete")
        return false
    end
    
    -- Use our ClearData function to properly preserve metadata
    if self.ClearData then
        self:ClearData()
    else
        -- Fallback if ClearData function doesn't exist
        self:Debug("data", "Clearing current data (fallback method)")
        self.fullData = nil
        if self.navigation then
            self.navigation.handlers = {}
        end
    end
    
    -- Detect data format version
    local version = TWRA_Assignments.version or 1
    self:Debug("data", "Loading saved assignments (format version " .. version .. ")")
    
    -- Handle new format (version 2+)
    self:Debug("data", "Loading new format data")
    return self:RebuildNavigation()
end

-- Function to check if we're dealing with example data
function TWRA:IsExampleData(data)
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
    
    -- Add section header message
    table.insert(messageQueue, {
        text = "Raid Assignments: " .. currentSection,
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
                        
                        -- Add role header
                        if roleAdded then
                            messageText = messageText .. " " .. displayRoleName .. ": "
                        else
                            messageText = messageText .. " " .. displayRoleName .. ": "
                            roleAdded = true
                        end
                        
                        -- Add members with comma separation and "and" for last
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
        
        -- Add each warning to the message queue
        for _, warningText in ipairs(warnings) do
            if warningText and warningText ~= "" then
                table.insert(messageQueue, {
                    text = warningText,
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

-- Also update HandleTableAnnounce to save the section after receiving data
function TWRA:HandleTableAnnounce(tableData, timestamp, sender)
    -- Check against our timestamp
    local ourTimestamp = TWRA_Assignments and TWRA_Assignments.timestamp or 0
    
    if timestamp and timestamp > ourTimestamp then
        -- Use the pending section if available
        local sectionToUse = self.SYNC.pendingSection or 1
        
        -- Clean the table data using our centralized function
        local cleanedTableData = self:CleanAssignmentData(tableData, true)
        
        -- Convert cleaned table data to flat format for use in current session
        local flatData = {}
        
        -- For each section in the cleaned data
        for section, rows in pairs(cleanedTableData) do
            -- For each row in this section
            for i = 1, table.getn(rows) do
                local newRow = {}
                
                -- Add section name as first column
                newRow[1] = section
                
                -- Copy the rest of the row data
                for j = 1, table.getn(rows[i]) do
                    newRow[j+1] = rows[i][j]
                end
                
                table.insert(flatData, newRow)
            end
        end
        
        -- Set the full data to the cleaned flat data
        self.fullData = flatData
        
        -- Rebuild navigation using the cleaned data
        self:RebuildNavigation()
        
        -- Get the section name for the current index
        local sectionName = nil
        if self.navigation and self.navigation.handlers and 
           sectionToUse <= table.getn(self.navigation.handlers) then
            sectionName = self.navigation.handlers[sectionToUse]
        end
        
        -- Store the cleaned structured data with section information
        TWRA_Assignments = {
            data = cleanedTableData,
            timestamp = timestamp,
            currentSection = sectionToUse,
            currentSectionName = sectionName, 
            version = 1
        }
        
        -- Navigate to the section properly using NavigateToSection
        if self.navigation then
            self:NavigateToSection(sectionToUse, "fromSync")
        end
        
        -- Clear pending section after use
        self.SYNC.pendingSection = nil
        DEFAULT_CHAT_FRAME:AddMessage("TWRA: Synchronized with " .. sender)
    end
end

-- Ensure the dropdown menu also saves current section
-- Add this to your dropdown menu selection handler if it exists
function TWRA:SectionDropdownSelected(index)
    self:NavigateToSection(index)  -- This will now save the section
end

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
    
    -- Hide other main view buttons
    if self.announceButton then self.announceButton:Hide() end
    if self.updateTanksButton then self.updateTanksButton:Hide() end
    
    -- Reset frame height to default while in options
    self.mainFrame:SetHeight(300)
    
    -- Change button text if options button exists
    if self.optionsButton then
        self.optionsButton:SetText("Back")
    end
    
    self:Debug("ui", "Switched to options view - currentView = " .. self.currentView)
end

-- Find rows relevant to the current player (either by name or class group)
function TWRA:GetPlayerRelevantRows(sectionData)
    if not sectionData or type(sectionData) ~= "table" then
        return {}
    end
    
    local relevantRows = {}
    local playerName = UnitName("player")
    local _, playerClass = UnitClass("player")
    playerClass = playerClass and string.upper(playerClass) or nil
    
    -- Find player's group number (1-8)
    local playerGroup = nil
    for i = 1, GetNumRaidMembers() do
        local name, _, subgroup = GetRaidRosterInfo(i)
        if name == playerName then
            playerGroup = subgroup
            break
        end
    end
    
    -- Scan through all rows to find matches
    for rowIndex, rowData in ipairs(sectionData) do
        -- Skip header row and special rows
        if rowIndex > 1 and rowData[2] ~= "Icon" and rowData[2] ~= "Note" and rowData[2] ~= "Warning" and rowData[2] ~= "GUID" then
            local isRelevantRow = false
            
            -- Check each cell for player name, class group, or player's group number
            for _, cellData in ipairs(rowData) do
                -- Only check string data
                if type(cellData) == "string" then
                    -- Match player name directly
                    if cellData == playerName then
                        isRelevantRow = true
                        break
                    end
                    
                    -- Match player class group (like "Warriors" for a Warrior)
                    if playerClass and self.CLASS_GROUP_NAMES and self.CLASS_GROUP_NAMES[cellData] and string.upper(self.CLASS_GROUP_NAMES[cellData]) == playerClass then
                        isRelevantRow = true
                        break
                    end
                    
                    -- Check for player's group number using a simple word boundary pattern
                    -- This will match any instance of the group number as a distinct "word"
                    -- Examples that would match for group 1: "Group 1", "G1", "1", "group 1"
                    -- But won't match group 1 in "Group 10" or "G12"
                    if playerGroup then
                        -- The pattern \b matches a word boundary
                        local groupPattern = "%f[%a%d]" .. playerGroup .. "%f[^%a%d]"
                        if string.find(cellData, groupPattern) then
                            isRelevantRow = true
                            break
                        end
                    end
                end
            end
            
            -- If row is relevant, add to our list
            if isRelevantRow then
                table.insert(relevantRows, rowIndex)
            end
        end
    end
    
    return relevantRows
end

-- Function to clear current data before loading new data
function TWRA:ClearData()
    self:Debug("data", "Clearing current data")
    
    -- Clear fullData
    self.fullData = nil
    
    -- Clear navigation
    if self.navigation then
        self.navigation.handlers = {}
        -- self.navigation.currentIndex = 1 -- We need this information for persistance during an import.
    end
    
    -- Clear rows
    self:ClearRows()
    
    -- Clear UI elements if they exist
    if self.mainFrame then
        -- Clear highlights and footers
        self:ClearFooters()
        self:ClearRows()
        
        -- Clear standard footer elements
        if self.footers then
            for _, footer in pairs(self.footers) do
                if footer.texture then
                    footer.texture:Hide()
                else
                    if footer.icon then footer.icon:Hide() end
                    if footer.text then footer.text:Hide() end
                end
            end
        end
        
        -- Clear navigation elements
        if self.navigation then
            if self.navigation.prevButton then self.navigation.prevButton:Hide() end
            if self.navigation.nextButton then self.navigation.nextButton:Hide() end
            if self.navigation.menuButton then self.navigation.menuButton:Hide() end
            if self.navigation.dropdownMenu then self.navigation.dropdownMenu:Hide() end
            if self.navigation.handlerText then self.navigation.handlerText:Hide() end
        end
        
        -- Clear action buttons
        if self.announceButton then self.announceButton:Hide() end
        if self.updateTanksButton then self.updateTanksButton:Hide() end
        
        -- Reset any example-related flags
        self.usingExampleData = false
        
        self:Debug("data", "Data cleared successfully")
    end
end

-- Handle CHAT_MSG_ADDON events
function TWRA:OnChatMsgAddon(prefix, message, distribution, sender)
    self:Debug("sync", "OnChatMsgAddon called - prefix: " .. prefix .. ", from: " .. sender)
    
    -- Forward to sync handler only if it's our prefix
    if prefix == self.SYNC.PREFIX then
        self:Debug("sync", "Recognized our prefix, forwarding to sync handlers")
        
        -- If message monitoring is enabled, show the message in chat frame
        if self.SYNC.monitorMessages then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFFF00FF[ADDON MSG]|r |cFF33FF33" .. 
                prefix .. "|r from |cFF33FFFF" .. sender .. "|r: |cFFFFFFFF" .. message .. "|r")
        end
        
        -- Skip our own messages
        if sender == UnitName("player") then
            self:Debug("sync", "Ignoring own message")
            return
        end
        
        -- Forward to our handler
        if self.HandleAddonMessage then
            self:Debug("sync", "Calling HandleAddonMessage")
            self:HandleAddonMessage(message, distribution, sender)
        else
            self:Debug("error", "HandleAddonMessage function not available")
        end
    end
end

-- Process imported data
function TWRA:ProcessImportedData(stringData)
    -- Use our ClearData function to properly preserve metadata
    if self.ClearData then
        self:ClearData()
    else
        -- Fallback if ClearData function doesn't exist
        self:Debug("data", "Clearing current data (fallback method)")
        self.fullData = nil
        if self.navigation then
            self.navigation.handlers = {}
        end
    end
    
    -- Parse the string data into table form
    local parsed = self:ParseImportString(stringData)
    if not parsed then
        self:Debug("error", "Failed to parse import string")
        return nil
    end
    
    -- Set the imported data as our current data
    self.fullData = parsed
    
    -- Update flag for example data
    local isExampleData = self:IsExampleData(parsed)
    self.usingExampleData = isExampleData
    
    -- Rebuild navigation with new section names
    self:RebuildNavigation()
    
    -- Process relevance information for the player
    self:ProcessPlayerRelevantInfo()
    
    self:Debug("data", "Import data processed successfully")
    
    return parsed
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

-- ImportString function
function TWRA:ImportString(importString, isSync, syncTimestamp)
    if not importString or type(importString) ~= "string" then
        self:Debug("error", "Invalid import string provided")
        return false
    end
    
    local decoded = self:DecodeBase64(importString)
    
    if not decoded then
        self:Debug("error", "Failed to decode import string: " .. importString:sub(1, 20) .. "...")
        return false
    end
    
    -- Check if we have compressed data (starts with specific marker)
    if decoded:sub(1, 4) == "COMP" then
        local success, decompressed = pcall(function()
            return LibStub:GetLibrary("LibDeflate"):DecompressZlib(decoded:sub(5))
        end)
        
        if success and decompressed then
            decoded = decompressed
        else
            self:Debug("error", "Failed to decompress import data")
            return false
        end
    end
    
    -- Now we should have a Lua table string, attempt to parse it
    local func, errorMsg = loadstring("return " .. decoded)
    if not func then
        self:Debug("error", "Failed to parse import data: " .. (errorMsg or "Unknown error"))
        return false
    end
    
    local success, assignmentData = pcall(func)
    if not success or not assignmentData then
        self:Debug("error", "Failed to execute import data: " .. (assignmentData or "Unknown error"))
        return false
    end
    
    -- Get timestamp from sync or create new one
    local timestamp = syncTimestamp or time()
    
    -- Save the imported assignments with proper timestamp
    -- Explicitly set isExample to false for any imported data
    if type(assignmentData) == "table" then
        self:Debug("data", "Successfully parsed import data, saving assignments")
        
        -- Import handling for sync vs manual import
        if isSync then
            self:Debug("sync", "Processing sync import with timestamp: " .. timestamp)
            -- For sync imports, we need to check if the incoming data is newer
            if TWRA_Assignments and TWRA_Assignments.timestamp and 
               TWRA_Assignments.timestamp >= timestamp then
                -- Skip import if our data is newer
                self:Debug("sync", "Skipping sync import as local data is newer")
                return false
            end
        end
        
        -- Save and always set isExample to false for imported data
        local result = self:SaveAssignments(assignmentData, importString, timestamp, isSync)
        
        -- Always ensure isExample is false for imports
        if TWRA_Assignments then
            TWRA_Assignments.isExample = false
        end
        
        return result
    else
        self:Debug("error", "Import failed: Result is not a table")
        return false
    end
end