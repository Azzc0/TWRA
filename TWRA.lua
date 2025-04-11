TWRA_SavedVariables = TWRA_SavedVariables or {
    assignments = {}
}
TWRA = TWRA or {}

-- Update NavigateHandler to save current section
function TWRA:NavigateHandler(delta)
    -- Ensure navigation exists
    if not self.navigation then
        self.navigation = { handlers = {}, currentIndex = 1 }
    end
    
    local nav = self.navigation
    
    -- Safety check for handlers
    if not nav.handlers or table.getn(nav.handlers) == 0 then
        return
    end
    
    local newIndex = nav.currentIndex + delta
    
    if newIndex < 1 then 
        newIndex = table.getn(nav.handlers)
    elseif newIndex > table.getn(nav.handlers) then
        newIndex = 1
    end
    
    -- Use the central NavigateToSection function that handles syncing
    self:NavigateToSection(newIndex)
    
    -- No need to call SaveCurrentSection here as it's now called inside NavigateToSection
end

-- Helper function to rebuild navigation after data updates
function TWRA:RebuildNavigation()
    if not self.fullData then return end
    
    -- Initialize or reset navigation
    if not self.navigation then
        self.navigation = { handlers = {}, currentIndex = 1 }
    else
        self.navigation.handlers = {}
    end
    
    -- Use an ordered list to maintain section order
    local seenSections = {}
    
    -- First pass: collect sections in the order they appear in the data
    for i = 1, table.getn(self.fullData) do
        local sectionName = self.fullData[i][1]
        -- Add explicit check for non-empty strings (trim whitespace too)
        if sectionName and sectionName ~= "" and string.gsub(sectionName, "%s", "") ~= "" and not seenSections[sectionName] then
            seenSections[sectionName] = true
            table.insert(self.navigation.handlers, sectionName)
        end
    end
    
    -- Debug output to verify sections
    self:Debug("nav", "Built " .. table.getn(self.navigation.handlers) .. " sections")
    
    return self.navigation.handlers
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
    frame:RegisterEvent("CHAT_MSG_ADDON")
    frame:RegisterEvent("UPDATE_BINDINGS")
    
    frame:SetScript("OnEvent", function()
        if event == "VARIABLES_LOADED" then
            -- Load saved assignments
            self:LoadSavedAssignments()
            
            -- Initialize debug system
            if self.InitializeDebug then
                self:InitializeDebug()
            end
            
            self:Debug("general", "Variables loaded")
        elseif event == "RAID_ROSTER_UPDATE" or event == "PARTY_MEMBERS_CHANGED" then
            -- Handle group changes
            if self.OnGroupChanged then
                self:OnGroupChanged()
            end
        elseif event == "CHAT_MSG_ADDON" then
            -- Critical fix: properly route addon messages to our handler
            if self.OnChatMsgAddon then
                self:OnChatMsgAddon(arg1, arg2, arg3, arg4)
            else
                self:Debug("error", "OnChatMsgAddon handler not available")
            end
        elseif event == "UPDATE_BINDINGS" then
            -- Handle keybinding updates
            if self.UpdateBindings then
                self:UpdateBindings()
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
end

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
    local saved = TWRA_SavedVariables.assignments
    
    -- Case 1: No saved data exists
    if not saved or not saved.data then 
        return self:LoadExampleData()
    end
    
    -- Load and clean the saved data
    self.fullData = self:CleanAssignmentData(saved.data, false)
    
    -- Rebuild navigation
    self:RebuildNavigation()
    
    -- Set example data flag properly
    self.usingExampleData = saved.usingExampleData or saved.isExample or false
    
    -- Try to navigate to the previously selected section by name first
    local sectionRestored = false
    if saved.currentSectionName and self.navigation.handlers then
        for i, name in ipairs(self.navigation.handlers) do
            if name == saved.currentSectionName then
                self.navigation.currentIndex = i
                sectionRestored = true
                self:Debug("nav", "Restored section by name: " .. name)
                break
            end
        end
    end
    
    -- If section wasn't restored by name, try by index
    if not sectionRestored then
        local index = saved.currentSection or 1
        if self.navigation.handlers and index <= table.getn(self.navigation.handlers) then
            self.navigation.currentIndex = index
            self:Debug("nav", "Restored section by index: " .. index)
        else
            self.navigation.currentIndex = 1
            self:Debug("nav", "Using default section index: 1")
        end
    end
    
    -- Update OSD with current section after loading (important for UI reload)
    if self.navigation and self.navigation.currentIndex and 
       self.navigation.handlers and table.getn(self.navigation.handlers) > 0 then
        
        local currentIndex = self.navigation.currentIndex
        local sectionName = self.navigation.handlers[currentIndex]
        local totalSections = table.getn(self.navigation.handlers)
        
        -- Update OSD content without showing it
        if self.UpdateOSDContent then
            self:UpdateOSDContent(sectionName, currentIndex, totalSections)
        end
    end
    
    self:Debug("data", "Loaded assignments (example mode: " .. (self.usingExampleData and "ON" or "OFF") .. ")")
    return true
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

-- Enhanced GetPlayerStatus function to handle example data
function TWRA:GetPlayerStatus(name)
    -- Safety checks
    if not name or name == "" then return false, nil end
    if UnitName("player") == name then return true, true end
    
    -- Check if we're using example data
    if self.usingExampleData and self.EXAMPLE_PLAYERS then
        local classInfo = self.EXAMPLE_PLAYERS[name]
        if classInfo then
            -- Consider player "in raid" with online status based on absence of |OFFLINE flag
            local isOnline = not string.find(classInfo, "|OFFLINE")
            return true, isOnline
        end
    end
    
    -- Regular player status checks
    for i = 1, GetNumRaidMembers() do
        if GetRaidRosterInfo(i) == name then
            local _, _, _, _, _, _, _, online = GetRaidRosterInfo(i)
            return true, online
        end
    end
    
    for i = 1, GetNumPartyMembers() do
        if UnitName("party"..i) == name then
            return true, UnitIsConnected("party"..i)
        end
    end
    
    return false, nil
end

-- Announcement functionality - completely rewritten
function TWRA:AnnounceAssignments()
    -- Validate we have data
    if not self.fullData or table.getn(self.fullData) == 0 then
        self:Debug("ui", "No assignments data to announce")
        return
    end
    
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
    
    -- First pass: collect all the messages we'll send
    local messageQueue = {}
    
    -- Add section header message
    table.insert(messageQueue, {
        text = "Raid Assignments: " .. currentSection,
        type = "header"
    })
    
    -- Find the header row for this section
    local headerRow = nil
    for i = 1, table.getn(self.fullData) do
        if self.fullData[i][1] == currentSection and self.fullData[i][2] == "Icon" then
            headerRow = self.fullData[i]
            break
        end
    end
    
    -- Fallback to global header if needed
    if not headerRow then
        for i = 1, table.getn(self.fullData) do
            if self.fullData[i][2] == "Icon" then
                headerRow = self.fullData[i]
                break
            end
        end
    end
    
    -- Create column role mapping if we found a header row
    local columnRoles = {}
    if headerRow then
        for i = 3, table.getn(headerRow) do
            columnRoles[i] = headerRow[i]
            self:Debug("ui", "Column " .. i .. " role: " .. (headerRow[i] or "nil"))
        end
    end
    
    -- Collect normal assignment rows
    for i = 1, table.getn(self.fullData) do
        -- Only process rows for the current section
        if self.fullData[i][1] == currentSection then
            -- Process assignment rows (skipping Icon, Note, Warning, and GUID rows)
            if self.fullData[i][2] ~= "Icon" and 
               self.fullData[i][2] ~= "Note" and 
               self.fullData[i][2] ~= "Warning" and 
               self.fullData[i][2] ~= "GUID" then
                local icon = self.fullData[i][2] 
                local target = self.fullData[i][3] or ""
                local messageText = ""
                
                -- Add colored icon text
                if icon and TWRA.COLORED_ICONS[icon] then
                    messageText = TWRA.COLORED_ICONS[icon] .. " " .. target
                else
                    messageText = target
                end
                
                -- Group roles by type
                local roleGroups = {}
                
                -- Process each column for roles
                for j = 4, table.getn(self.fullData[i]) do
                    local role = self.fullData[i][j]
                    if role and role ~= "" then
                        -- Get role name from header
                        local roleName = columnRoles[j] or "Role" -- Default to "Role" if header not found
                        
                        -- Create role group if it doesn't exist
                        if not roleGroups[roleName] then
                            roleGroups[roleName] = {}
                        end
                        
                        -- Add to appropriate role group
                        table.insert(roleGroups[roleName], role)
                    end
                end
                
                -- Add roles grouped by type
                local roleAdded = false
                for roleName, members in pairs(roleGroups) do
                    if table.getn(members) > 0 then
                        -- Make Tank/Healer plural if there are multiple members
                        local displayRoleName = roleName
                        if (roleName == "Tank" or roleName == "Healer") and table.getn(members) > 1 then
                            displayRoleName = roleName .. "s"
                        end
                        
                        -- Add role header (e.g., "Tanks: ")
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
    
    -- Collect warnings for the current section
    local uniqueWarnings = {}  -- Use a hash table to track unique warnings
    for i = 1, table.getn(self.fullData) do
        if self.fullData[i][1] == currentSection and self.fullData[i][2] == "Warning" then
            local warningText = self.fullData[i][3]
            if warningText and warningText ~= "" then
                -- Only add this warning if we haven't seen it before
                -- IMPORTANT: Use the raw text as the key, before any item processing
                local warningKey = warningText
                if not uniqueWarnings[warningKey] then
                    uniqueWarnings[warningKey] = true
                    -- FIXED: Do NOT add "WARNING:" prefix - use the text as-is
                    table.insert(messageQueue, {
                        text = warningText, -- Use raw text without "WARNING:" prefix
                        type = "warning"
                    })
                    self:Debug("ui", "Warning message created: " .. warningText)
                else
                    self:Debug("ui", "Skipping duplicate warning: " .. warningText)
                end
            end
        end
    end
    
    -- Debug print of all messages
    self:Debug("ui", "Announcement message queue prepared with " .. table.getn(messageQueue) .. " messages:")
    for i, msg in ipairs(messageQueue) do
        self:Debug("ui", "  [" .. i .. "/" .. table.getn(messageQueue) .. "] (" .. msg.type .. ") " .. msg.text)
    end
    
    -- Now send the messages using a separate function
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
            if TWRA.Items and TWRA.Items.ProcessText then
                processedText = TWRA.Items:ProcessText(processedText)
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
    else
        -- Default behavior - toggle main frame
        TWRA:ToggleMainFrame()
    end
end

-- Initialize UI at end of loading - THIS IS THE ONLY INITIALIZE CALL
TWRA:Initialize()

-- Update the HandleSectionCommand to save the current section when changed via sync
function TWRA:HandleSectionCommand(args, sender)
    -- Split parts
    local parts = self:SplitString(args, ":")
    local partsCount = table.getn(parts)
    if partsCount < 3 then return end
    
    local timestamp = tonumber(parts[1])
    local sectionName = parts[2]
    local sectionIndex = tonumber(parts[3])
    
    -- Check against our timestamp
    local ourTimestamp = TWRA_SavedVariables.assignments and TWRA_SavedVariables.assignments.timestamp or 0
    if timestamp > ourTimestamp then
        -- We need newer data
        self.SYNC.pendingSection = sectionIndex
        self:SendAddonMessage(self.SYNC.COMMANDS.DATA_REQUEST .. ":" .. timestamp)
    elseif timestamp == ourTimestamp then
        -- Timestamps match - navigate to section
        if self.navigation and sectionIndex <= table.getn(self.navigation.handlers) then
            -- Use NavigateToSection instead of manually setting values
            -- This ensures all UI elements are updated properly
            self:NavigateToSection(sectionIndex, "fromSync")
            
            DEFAULT_CHAT_FRAME:AddMessage("TWRA: Changed to section " .. sectionIndex ..
                " (" .. self.navigation.handlers[sectionIndex] .. ") by " .. sender)
        end
    end
end

-- Also update HandleTableAnnounce to save the section after receiving data
function TWRA:HandleTableAnnounce(tableData, timestamp, sender)
    -- Check against our timestamp
    local ourTimestamp = TWRA_SavedVariables.assignments and TWRA_SavedVariables.assignments.timestamp or 0
    
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
        TWRA_SavedVariables.assignments = {
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

-- Enhanced ToggleMainFrame function with better debugging
function TWRA:ToggleMainFrame()
    -- Make sure frame exists
    if not self.mainFrame then
        self:Debug("ui", "Main frame doesn't exist - creating it")
        if self.CreateMainFrame then
            self:CreateMainFrame()
        else
            self:Error("Unable to create main frame - function not found")
            return
        end
    end
    
    if self.mainFrame:IsShown() then
        self.mainFrame:Hide()
        self:Debug("ui", "Window hidden")
    else
        self.mainFrame:Show()
        
        -- Debug current view status
        self:Debug("ui", "Current view is: " .. (self.currentView or "nil"))
        
        -- Initialize if needed
        if not self.initialized then
            self:LoadSavedAssignments()
            self.initialized = true
        end
        
        -- Force update content
        if self.currentView == "options" then
            self:Debug("ui", "Switching to main view from options view")
            self:ShowMainView()
        else
            self:Debug("ui", "Already in main view - refreshing content")
            self:RefreshAssignmentTable()
        end
        
        self:Debug("ui", "Window shown")
    end
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

-- Fix ShowMainView to better handle section restoration after imports
function TWRA:ShowMainView()
    -- Set view state first
    self.currentView = "main"
    
    -- Hide options UI elements if they exist
    if self.optionsElements then
        for _, element in pairs(self.optionsElements) do
            if element.Hide then
                element:Hide()
            end
        end
    end
    
    -- Show navigation elements if they exist
    if self.navigation then
        if self.navigation.prevButton then self.navigation.prevButton:Show() end
        if self.navigation.nextButton then self.navigation.nextButton:Show() end
        if self.navigation.menuButton then self.navigation.menuButton:Show() end
        if self.navigation.handlerText then self.navigation.handlerText:Show() end
        if self.navigation.dropdown and self.navigation.dropdown.container then
            self.navigation.dropdown.container:Show()
        end
    end
    
    -- Show other main view buttons
    if self.announceButton then self.announceButton:Show() end
    if self.updateTanksButton then self.updateTanksButton:Show() end
    
    -- Display current section content
    if self.DisplayCurrentSection then
        self:DisplayCurrentSection()
    end
    
    self:Debug("ui", "Switched to main view - final currentView = " .. self.currentView)
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

-- Helper function to determine if OSD should be shown
function TWRA:ShouldShowOSD()
    -- Only show OSD if it's enabled
    if not self.OSD or not self.OSD.enabled then
        return false
    end
    
    -- Show OSD when main frame isn't visible or we're in options view
    return not self.mainFrame or 
           not self.mainFrame:IsShown() or 
           self.currentView == "options"
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

-- Add a hook to the existing DisplayCurrentSection if it exists
-- This should be added near the end of the file to override any existing implementation
if TWRA.DisplayCurrentSection then
    local originalDisplayCurrentSection = TWRA.DisplayCurrentSection
    TWRA.DisplayCurrentSection = function(self)
        -- Check if we have the DataUtility version of DisplayCurrentSection
        if self.IsNewDataFormat and self.GetCurrentSectionData then
            return self:IsNewDataFormat() and 
                  self.GetCurrentSectionData and 
                  self:GetCurrentSectionData() and
                  TWRA_DataUtility_DisplayCurrentSection(self) or
                  originalDisplayCurrentSection(self)
        else
            return originalDisplayCurrentSection(self)
        end
    end
end

-- Create a backup of the display function in case it gets overridden
function TWRA_DataUtility_DisplayCurrentSection(self)
    -- Make sure we have the utility functions
    if self.IsNewDataFormat and self.GetCurrentSectionData then
        return self:DisplayCurrentSection()
    end
    return false
end

-- -- Hook into the NavigateToSection function to ensure section is properly saved with new format
-- if TWRA.NavigateToSection then
--     local originalNavigateToSection = TWRA.NavigateToSection
--     TWRA.NavigateToSection = function(self, index, suppressSync)
--         local result = originalNavigateToSection(self, index, suppressSync)
        
--         -- Additional handling for new format
--         if self:IsNewDataFormat and self:IsNewDataFormat() and TWRA_SavedVariables and TWRA_SavedVariables.assignments then
--             TWRA_SavedVariables.assignments.currentSection = index
--             if self.navigation and self.navigation.handlers and index <= table.getn(self.navigation.handlers) then
--                 self:Debug("nav", "Saved current section: " .. index .. " (" .. self.navigation.handlers[index] .. ")")
--             end
--         end
        
--         return result
--     end
-- end