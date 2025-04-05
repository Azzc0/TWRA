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
        if sectionName and sectionName ~= "" and not seenSections[sectionName] then
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
        elseif event == "CHAT_MSG_ADDON" and arg1 == self.SYNC.PREFIX then
            -- Handle addon messages
            self:HandleAddonMessage(arg2, arg3, arg4)
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

-- Fix the SaveAssignments function to properly handle example data
function TWRA:SaveAssignments(data, sourceString, originalTimestamp, noAnnounce)
    if not data or not sourceString then return end
    
    -- Use provided timestamp or generate new one
    local timestamp = originalTimestamp or time()
    
    -- Store current section before updating
    local currentSectionIndex = 1
    local currentSectionName = nil
    if self.navigation and self.navigation.currentIndex then
        currentSectionIndex = self.navigation.currentIndex
        if self.navigation.handlers and self.navigation.currentIndex <= table.getn(self.navigation.handlers) then
            currentSectionName = self.navigation.handlers[self.navigation.currentIndex]
        end
    end
    
    -- Remember the section name for post-import navigation
    self.pendingSectionName = currentSectionName
    self.pendingSectionIndex = currentSectionIndex
    
    -- Store original data for debugging
    local originalData = self.fullData
    
    -- Update our full data in flat format for use in the current session
    self.fullData = data
    
    -- Check if this is the example data and set the flag correctly
    local isExampleData = (sourceString == "example_data" or self:IsExampleData(data))
    self.usingExampleData = isExampleData
    
    -- Rebuild navigation before saving to get new section names
    self:RebuildNavigation()
    
    -- Save the data, source string, and current section index and example flag
    TWRA_SavedVariables.assignments = {
        data = data,
        source = sourceString,
        timestamp = timestamp,
        currentSection = currentSectionIndex,
        currentSectionName = currentSectionName, -- Store section name for better restoration
        version = 1,
        isExample = isExampleData,
        usingExampleData = isExampleData
    }
    
    -- Debug output for section navigation
    self:Debug("nav", "SaveAssignments - Previous section: " .. (currentSectionName or "None") .. 
                      " (index: " .. currentSectionIndex .. ")")
    
    -- Skip announcement if noAnnounce is true
    if noAnnounce then return end
    
    -- Announce update to group if we're in one
    if GetNumRaidMembers() > 0 or GetNumPartyMembers() > 0 then
        local announceMsg = string.format("%s:%d:%s", 
            self.SYNC.COMMANDS.ANNOUNCE,
            timestamp,
            UnitName("player"))
        
        self:SendAddonMessage(announceMsg)
    end
end

-- Enhanced LoadSavedAssignments to update OSD after loading
function TWRA:LoadSavedAssignments()
    local saved = TWRA_SavedVariables.assignments
    
    -- Case 1: No saved data exists
    if not saved or not saved.data then 
        return self:LoadExampleData()
    end
    
    -- Load the saved data
    self.fullData = saved.data
    
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

-- Update to use Debug)
function TWRA:UpdateTanks()
    -- Debug output our sync state
    self:Debug("tank", "Updating tanks for section " .. 
        self.navigation.handlers[self.navigation.currentIndex])
    
    -- Check if oRA2 is available
    if not self:IsORA2Available() then
        self:Debug("error", "oRA2 is required for tank management")
        return
    end
    
    -- Check if we have data
    if not self.fullData or table.getn(self.fullData) == 0 then
        self:Debug("error", "No data to update tanks from")
        return
    end
    
    -- Get current section from navigation
    local currentSection = nil
    if self.navigation and self.navigation.handlers and self.navigation.currentIndex then
        currentSection = self.navigation.handlers[self.navigation.currentIndex]
    end
    
    if not currentSection then
        self:Debug("error", "No section selected")
        return
    end
    
    self:Debug("tank", "Processing tanks for section " .. currentSection)
    
    -- Find header row for column names
    local headerRow = nil
    for i = 1, table.getn(self.fullData) do
        if self.fullData[i][1] == currentSection and self.fullData[i][2] == "Icon" then
            headerRow = self.fullData[i]
            break
        end
    end
    
    if not headerRow then
        self:Debug("error", "Invalid data format - header row not found")
        return
    end
    
    -- Find tank columns for current section
    local tankColumns = {}
    for k = 4, table.getn(headerRow) do
        if headerRow[k] == "Tank" then
            self:Debug("tank", "Found tank column at index " .. k)
            table.insert(tankColumns, k)
        end
    end
    
    if table.getn(tankColumns) == 0 then
        self:Debug("error", "No tank columns found in section " .. currentSection)
        return
    end
    
    -- First pass: collect unique tanks in order
    local uniqueTanks = {}
    for _, columnIndex in ipairs(tankColumns) do  -- Fixed typo here (was ttankColumns)
        for i = 1, table.getn(self.fullData) do
            local row = self.fullData[i]
            if row[1] == currentSection and 
               row[2] ~= "Icon" and 
               row[2] ~= "Note" and 
               row[2] ~= "Warning" then
                if row[columnIndex] and row[columnIndex] ~= "" then
                    local tankName = row[columnIndex]
                    local alreadyAdded = false
                    
                    -- Check if tank is already in our list
                    for _, existingTank in ipairs(uniqueTanks) do
                        if existingTank == tankName then
                            alreadyAdded = true
                            break
                        end
                    end
                    
                    -- Add tank if unique and we haven't hit the limit
                    if not alreadyAdded and table.getn(uniqueTanks) < 10 then
                        table.insert(uniqueTanks, tankName)
                    end
                end 
            end
        end
    end
    
    -- Clear existing tanks first
    for i = 1, 10 do
        oRA.maintanktable[i] = nil
    end
    if GetNumRaidMembers() > 0 then
        SendAddonMessage("CTRA", "MT CLEAR", "RAID")
    end
    
    -- Second pass: assign tanks in order
    self:Debug("tank", "Setting " .. table.getn(uniqueTanks) .. " tanks")
    for i = 1, table.getn(uniqueTanks) do
        local tankName = uniqueTanks[i]
        oRA.maintanktable[i] = tankName
        self:Debug("tank", "Set MT" .. i .. " to " .. tankName)
        if GetNumRaidMembers() > 0 then
            SendAddonMessage("CTRA", "SET " .. i .. " " .. tankName, "RAID")
        end
    end
    
    self:Debug("tank", "Tank updates completed")
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
    TWRA:ToggleMainFrame()
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
            -- Set the current section
            self.navigation.currentIndex = sectionIndex
            
            -- Save it immediately
            self:SaveCurrentSection()
            
            -- Update display
            if self.DisplayCurrentSection then
                self:DisplayCurrentSection()
            end
            
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
        
        -- Convert to flat format for use in current session
        local flatData = {}
        
        -- For each section
        for section, rows in pairs(tableData) do
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
        
        -- Set the full data
        self.fullData = flatData
        
        -- Rebuild navigation
        self:RebuildNavigation()
        
        -- Get the section name for the current index
        local sectionName = nil
        if self.navigation and self.navigation.handlers and 
           sectionToUse <= table.getn(self.navigation.handlers) then
            sectionName = self.navigation.handlers[sectionToUse]
        end
        
        -- Store the structured data with section information
        TWRA_SavedVariables.assignments = {
            data = tableData,
            timestamp = timestamp,
            currentSection = sectionToUse,
            currentSectionName = sectionName, -- Add this line to store the section name
            version = 1
        }
        
        -- Set current section
        if self.navigation then
            self.navigation.currentIndex = sectionToUse
            
            -- Update UI
            if self.DisplayCurrentSection then
                self:DisplayCurrentSection()
            end
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

-- Enhanced NavigateToSection function with better debugging
function TWRA:NavigateToSection(targetSection, suppressSync)
    -- Extended debug output
    self:Debug("nav", string.format("NavigateToSection(%s, %s) - mainFrame:%s, isShown:%s, currentView:%s",
        tostring(targetSection), 
        tostring(suppressSync),
        tostring(self.mainFrame),
        self.mainFrame and tostring(self.mainFrame:IsShown()) or "nil",
        tostring(self.currentView)))
    
    -- Ensure navigation exists
    if not self.navigation then
        self.navigation = { handlers = {}, currentIndex = 1 }
    end
    
    local handlers = self.navigation.handlers
    local numSections = table.getn(handlers)
    if numSections == 0 then 
        self:Debug("nav", "No sections available")
        return false
    end
    
    local sectionIndex = targetSection
    local sectionName = nil
    -- If sectionIndex is a string, find its index
    if type(targetSection) == "string" then
        for i, name in ipairs(handlers) do
            if name == targetSection then
                sectionIndex = i
                sectionName = name
                break
            end
        end
    else
        -- Make sure targetSection is within bounds
        sectionIndex = math.max(1, math.min(numSections, targetSection))
        sectionName = handlers[sectionIndex]
    end
    
    if not sectionName then
        self:Debug("nav", "Invalid section index: "..tostring(targetSection))
        return false
    end
    
    -- Update current index
    self.navigation.currentIndex = sectionIndex
    
    -- Save current section immediately
    self:SaveCurrentSection()
    
    -- Update display based on current view
    if self.currentView == "options" then
        if self.ClearRows then
            self:ClearRows()
        end
    else
        if self.FilterAndDisplayHandler then
            self:FilterAndDisplayHandler(sectionName)
        end
    end
    
    -- Determine if we should show OSD
    local shouldShowOSD = false
    -- Case 1: Main frame doesn't exist or isn't shown
    if not self.mainFrame or not self.mainFrame:IsShown() then
        shouldShowOSD = true
    -- Case 2: We're in options view
    elseif self.currentView == "options" then
        shouldShowOSD = true
    -- Case 3: This is a sync-triggered navigation
    elseif suppressSync == "fromSync" then
        shouldShowOSD = true
    end
    
    self:Debug("nav", string.format("shouldShowOSD=%s (mainFrame:%s, isShown:%s, currentView:%s)",
        tostring(shouldShowOSD),
        tostring(self.mainFrame),
        self.mainFrame and tostring(self.mainFrame:IsShown()) or "nil",
        self.currentView or "nil"))
    
    -- Create context for section change message - with forceUpdate flag
    local context = {
        isMainFrameVisible = self.mainFrame and self.mainFrame:IsShown() or false,
        inOptionsView = self.currentView == "options" or false,
        fromSync = suppressSync == "fromSync",
        forceUpdate = true  -- Always force OSD content update
    }
    
    -- Send section changed message which triggers OSD if appropriate
    self:SendMessage("SECTION_CHANGED", sectionName, sectionIndex, numSections, context)
    
    -- Broadcast to group if sync enabled and not suppressed
    if not suppressSync and self.SYNC and self.SYNC.liveSync and self.BroadcastSectionChange then
        self:BroadcastSectionChange(sectionIndex)
    end
    
    -- If enabled, update tanks
    if self.SYNC and self.SYNC.tankSync and self:IsORA2Available() then
        self:UpdateTanks()
    end
    
    return true
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
    -- Set view state
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
    
    -- Reset frame height to default while in options
    self.mainFrame:SetHeight(300)

    -- Change button text if options button exists
    if self.optionsButton then
        self.optionsButton:SetText("Back")
    end
    
    -- -- Hide main view elements if they exist
    -- if self.navigation then
    --     if self.navigation.prevButton then self.navigation.prevButton:Hide() end
    --     if self.navigation.nextButton then self.navigation.nextButton:Hide() end
    --     if self.navigation.handlerText then self.navigation.handlerText:Hide() end
    --     if self.navigation.dropdown and self.navigation.dropdown.container then
    --         self.navigation.dropdown.container:Hide()
    --     end
    -- end
    
    -- Hide other main view buttons
    if self.announceButton then self.announceButton:Hide() end
    if self.updateTanksButton then self.updateTanksButton:Hide() end
    
    self:Debug("ui", "Switched to options view - currentView = " .. self.currentView)
end

-- Fix ShowMainView to better handle section restoration after import
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
    
    -- Change button text if options button exists
    if self.optionsButton then
        self.optionsButton:SetText("Options")
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
    
    -- -- Clear navigation text if it exists -- we need this information for persistance during an import.
    -- if self.navigation and self.navigation.handlerText then
    --     self.navigation.handlerText:SetText("")
    -- end
    
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
                    if footer.bg then footer.bg:Hide() end
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
    end
    
    -- Reset any example-related flags
    self.usingExampleData = false
    
    self:Debug("data", "Data cleared successfully")
end
