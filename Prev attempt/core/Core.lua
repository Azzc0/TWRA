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
        DEFAULT_CHAT_FRAME:AddMessage("TWRA: No sections available to navigate")
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
            seenSections[sectionName] = true  -- Mark as seen
            table.insert(self.navigation.handlers, sectionName)  -- Add to ordered list
        end
    end
    
    -- Debug output to verify sections
    DEFAULT_CHAT_FRAME:AddMessage("TWRA Debug: Built " .. table.getn(self.navigation.handlers) .. " sections: " .. 
        table.concat(self.navigation.handlers, ", "))
    
    return self.navigation.handlers
end



-- Helper function to update UI elements based on current data
function TWRA:UpdateUI()
    DEFAULT_CHAT_FRAME:AddMessage("TWRA Debug: Updating UI")
    
    -- Call UI update functions directly
    if self.UpdateNavigationButtons then
        self:UpdateNavigationButtons()
    end
    
    if self.DisplayCurrentSection then
        self:DisplayCurrentSection()
    else
        DEFAULT_CHAT_FRAME:AddMessage("TWRA Debug: ERROR - DisplayCurrentSection not found!")
    end
    
    -- Try to update any visible UI elements
    if self.mainFrame and self.mainFrame:IsShown() then
        if self.sectionTitle then
            self.sectionTitle:SetText(self.navigation.handlers[self.navigation.currentIndex] or "Unknown")
        end
        if self.RefreshAssignmentTable then
            self:RefreshAssignmentTable()
        end
    end
end

-- Function to save the current section index
function TWRA:SaveCurrentSection()
    -- Only save if we have assignments already
    if TWRA_SavedVariables and TWRA_SavedVariables.assignments and self.navigation then
        -- Make sure currentIndex exists before trying to save it
        if self.navigation.currentIndex then
            TWRA_SavedVariables.assignments.currentSection = self.navigation.currentIndex
        else
            -- If no current index, default to 1
            TWRA_SavedVariables.assignments.currentSection = 1
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
        local event = event
        
        if event == "VARIABLES_LOADED" then
            -- Load saved data or set defaults if none exist
            if not self:LoadSavedAssignments() then
                self:LoadExampleData()
            end
            
            -- Initialize options
            if self.InitOptions then self:InitOptions() end
            
            -- Initialize keybindings
            if self.InitializeBindings then self:InitializeBindings() end
            
            -- Create main frame but keep it hidden
            if not self.mainFrame and self.CreateMainFrame then
                self:CreateMainFrame()
                self.mainFrame:Hide() -- Ensure it's hidden by default
            end
            
            -- Process any pending navigations
            if self.pendingNavigation and self.navigation then
                self:NavigateToSection(self.pendingNavigation)
                self.pendingNavigation = nil
            end
            
        -- Rest of the function remains unchanged
        elseif event == "RAID_ROSTER_UPDATE" or event == "PARTY_MEMBERS_CHANGED" then
            -- Handle group composition changes
            if self.OnGroupChanged then self:OnGroupChanged() end
            
            -- Refresh display if needed for highlighting
            if self.mainFrame and self.mainFrame:IsShown() and self.DisplayCurrentSection then
                self:DisplayCurrentSection()
            end
            
        elseif event == "CHAT_MSG_ADDON" and arg1 == self.SYNC.PREFIX then
            -- Handle addon messages
            self:HandleAddonMessage(arg2, arg3, arg4)
            
        elseif event == "UPDATE_BINDINGS" then
            -- Update our binding handlers
            if self.InitializeBindings then self:InitializeBindings() end
        end
    end)

    -- Initialize AutoNavigate if SuperWoW is available
    if self.InitializeAutoNavigate then self:InitializeAutoNavigate() end
    
    -- Initialize keybindings
    if self.InitializeBindings then self:InitializeBindings() end

    -- Initialize OSD
    if self.InitOSD then self:InitOSD() end
end

-- In SaveAssignments function
function TWRA:SaveAssignments(data, sourceString, originalTimestamp, noAnnounce)
    if not data or not sourceString then return end
    
    -- Use provided timestamp or generate new one
    local timestamp = originalTimestamp or time()
    
    -- Store current section before updating
    local currentIndex = 1
    if self.navigation and self.navigation.currentIndex then
        currentIndex = self.navigation.currentIndex
    end
    
    -- Update our full data in flat format for use in the current session
    self.fullData = data
    
    -- Save the data, source string, and current section index
    TWRA_SavedVariables.assignments = {
        data = data,
        source = sourceString,
        timestamp = timestamp,
        version = 2, -- Increment version to indicate we're using the new format
        currentSection = currentIndex
    }
    
    -- Rebuild navigation with the new data
    self:RebuildNavigation()
    
    DEFAULT_CHAT_FRAME:AddMessage("TWRA: Assignments saved with timestamp " .. timestamp)
    
    -- Skip announcement if noAnnounce is true
    if noAnnounce then return end
    
    -- Announce update to group if we're in one
    if GetNumRaidMembers() > 0 or GetNumPartyMembers() > 0 then
        local announceMsg = self.SYNC.COMMANDS.ANNOUNCE .. ":" .. timestamp .. ":" .. sourceString
        self:SendAddonMessage(announceMsg)
    end
end

function TWRA:LoadSavedAssignments()
    local saved = TWRA_SavedVariables.assignments
    if not saved or not saved.data then return false end

    -- Set the full data directly from saved data
    self.fullData = saved.data
    
    -- Rebuild navigation with the loaded data
    self:RebuildNavigation()
    
    -- Store and set current section
    local currentSection = saved.currentSection or 1
    if self.navigation then
        -- Validate section index to ensure it's valid
        if currentSection > 0 and currentSection <= table.getn(self.navigation.handlers) then
            self.navigation.currentIndex = currentSection
            DEFAULT_CHAT_FRAME:AddMessage("TWRA Debug: Set navigation to index " .. currentSection .. 
                                         " (" .. self.navigation.handlers[currentSection] .. ")")
        else
            self.navigation.currentIndex = 1
            DEFAULT_CHAT_FRAME:AddMessage("TWRA Debug: Invalid saved section index, reset to 1")
        end
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("TWRA: Loaded assignments")
    return true
end


function TWRA:UpdateTanks()
    -- Debug output our sync state
    DEFAULT_CHAT_FRAME:AddMessage("TWRA: Updating tanks for section " .. 
        self.navigation.handlers[self.navigation.currentIndex])
    
    -- Check if oRA2 is available
    if not self:IsORA2Available() then
        DEFAULT_CHAT_FRAME:AddMessage("TWRA: oRA2 is required for tank management")
        return
    end
    
    -- Check if we have data
    if not self.fullData or table.getn(self.fullData) == 0 then
        DEFAULT_CHAT_FRAME:AddMessage("TWRA: No data to update tanks from")
        return
    end
    
    -- Get current section from navigation
    local currentSection = nil
    if self.navigation and self.navigation.handlers and self.navigation.currentIndex then
        currentSection = self.navigation.handlers[self.navigation.currentIndex]
    end
    
    if not currentSection then
        DEFAULT_CHAT_FRAME:AddMessage("TWRA: No section selected")
        return
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("TWRA: Processing tanks for section " .. currentSection)
    
    -- Find header row for column names
    local headerRow = nil
    for i = 1, table.getn(self.fullData) do
        if self.fullData[i][1] == currentSection and self.fullData[i][2] == "Icon" then
            headerRow = self.fullData[i]
            break
        end
    end
    
    if not headerRow then
        DEFAULT_CHAT_FRAME:AddMessage("TWRA: Invalid data format - header row not found")
        return
    end
    
    -- Find tank columns for current section
    local tankColumns = {}
    -- Find Tank columns in this section's header
    for k = 4, table.getn(headerRow) do
        if headerRow[k] == "Tank" then
            table.insert(tankColumns, k)
            DEFAULT_CHAT_FRAME:AddMessage("TWRA Debug: Found tank column at index " .. k)
        end
    end
    
    if table.getn(tankColumns) == 0 then
        DEFAULT_CHAT_FRAME:AddMessage("TWRA: No tank columns found in section " .. currentSection)
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
    DEFAULT_CHAT_FRAME:AddMessage("TWRA: Setting " .. table.getn(uniqueTanks) .. " tanks")
    for i = 1, table.getn(uniqueTanks) do
        local tankName = uniqueTanks[i]
        oRA.maintanktable[i] = tankName
        DEFAULT_CHAT_FRAME:AddMessage("TWRA: Set MT" .. i .. " to " .. tankName)
        if GetNumRaidMembers() > 0 then
            SendAddonMessage("CTRA", "SET " .. i .. " " .. tankName, "RAID")
        end
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("TWRA: Tank updates completed")
end

-- Announcement functionality
function TWRA:AnnounceAssignments()
    if not self.fullData or table.getn(self.fullData) == 0 then
        DEFAULT_CHAT_FRAME:AddMessage("TWRA: No data to announce")
        return
    end
    
    -- Get current section from navigation
    local currentSection = nil
    if self.navigation and self.navigation.handlers and self.navigation.currentIndex then
        currentSection = self.navigation.handlers[self.navigation.currentIndex]
    end
    
    if not currentSection then
        DEFAULT_CHAT_FRAME:AddMessage("TWRA: No section selected")
        return
    end
    
    -- Determine which channels to use based on options
    local headerChannel = "RAID"  -- Default
    local bodyChannel = "RAID"
    local warningChannel = "RAID_WARNING" -- Default warning channel
    local channelNumber = nil
    
    -- Get saved channel preference
    local selectedChannel = TWRA_SavedVariables.options and 
                          TWRA_SavedVariables.options.announceChannel or 
                          "GROUP"
    
    -- Adjust channels based on selection and current group context
    if selectedChannel == "GROUP" then
        if GetNumRaidMembers() > 0 then
            -- In a raid, use raid warning for header if player has permission
            local isOfficer = IsRaidLeader() or IsRaidOfficer()
            if isOfficer then
                headerChannel = "RAID_WARNING"
                warningChannel = "RAID_WARNING" -- Use RW for warnings if we're an officer
            else
                headerChannel = "RAID"
                warningChannel = "RAID" -- Default to RAID if not officer
            end
            bodyChannel = "RAID"
        elseif GetNumPartyMembers() > 0 then
            -- In a party but not raid, use party
            headerChannel = "PARTY"
            bodyChannel = "PARTY"
            warningChannel = "PARTY"
        else
            -- Solo, use say
            headerChannel = "SAY"
            bodyChannel = "SAY"
            warningChannel = "SAY"
        end
    elseif selectedChannel == "CHANNEL" then
        -- Get custom channel name
        local customChannel = TWRA_SavedVariables.options.customChannel
        if customChannel and customChannel ~= "" then
            -- Find the channel number
            channelNumber = GetChannelName(customChannel)
            if channelNumber > 0 then
                headerChannel = "CHANNEL"
                bodyChannel = "CHANNEL"
                warningChannel = "CHANNEL" -- Use same channel for warnings
            else
                -- No channel found, fall back to say
                headerChannel = "SAY"
                bodyChannel = "SAY"
                warningChannel = "SAY"
                DEFAULT_CHAT_FRAME:AddMessage("TWRA: Channel '" .. customChannel .. 
                                             "' not found, using Say instead")
            end
        else
            -- No custom channel specified, fall back to say
            headerChannel = "SAY"
            bodyChannel = "SAY"
            warningChannel = "SAY"
            DEFAULT_CHAT_FRAME:AddMessage("TWRA: No custom channel specified, using Say instead")
        end
    end
    
    -- Process data for the current section
    local messages = {}
    local warningMessages = {} -- Separate array for warnings to send last
    
    -- Add header message
    table.insert(messages, {
        text = "Raid Assignments: " .. currentSection,
        channel = headerChannel,
        channelNum = channelNumber
    })
    
    -- Get header row to identify column types
    local headerRow = nil
    for i = 1, table.getn(self.fullData) do
        if self.fullData[i][1] == currentSection and self.fullData[i][2] == "Icon" then
            headerRow = self.fullData[i]
            break
        end
    end
    
    -- Process rows in original order
    for i = 1, table.getn(self.fullData) do
        local row = self.fullData[i]
        
        -- Check if this row belongs to current section
        if row[1] == currentSection then
            -- Skip header row (Icon)
            if row[2] == "Icon" then 
                -- Skip header row
            
            -- Skip Note rows completely
            elseif row[2] == "Note" then
                -- Skip lines with Note as icon completely
            
            -- Skip GUID rows completely
            elseif row[2] == "GUID" then
                -- Skip lines with GUID as icon completely
                -- No processing needed
            
            -- Handle Warning rows specially and add to warningMessages
            elseif row[2] == "Warning" and row[3] and row[3] ~= "" then
                table.insert(warningMessages, {
                    text = row[3], -- No prefix for warning
                    channel = warningChannel, -- Use special warning channel
                    channelNum = channelNumber
                })
            
            -- Process normal assignment rows
            elseif row[2] and row[3] and row[3] ~= "" then
                -- Row[2] is the icon, row[3] is the target name
                local iconName = row[2]
                local targetName = row[3]
                
                local msgStart = ""
                if iconName and iconName ~= "" and self.COLORED_ICONS[iconName] then
                    msgStart = self.COLORED_ICONS[iconName] .. " " .. targetName
                else
                    msgStart = targetName
                end
                
                -- Group assignments by type (tank & healer only)
                local tanksList = {}
                local healersList = {}
                local otherAssignments = {}
                
                -- Process each column in this row
                if headerRow then
                    for col = 4, math.min(table.getn(row), table.getn(headerRow)) do
                        if row[col] and row[col] ~= "" then
                            local colType = headerRow[col]
                            
                            if colType == "Tank" then
                                table.insert(tanksList, row[col])
                            elseif colType == "Healer" then
                                table.insert(healersList, row[col])
                            else
                                -- For other column types, add with type label
                                table.insert(otherAssignments, colType .. ": " .. row[col])
                            end
                        end
                    end
                end
                
                -- Build the message parts
                local msgParts = {}
                
                -- Add tanks group
                if table.getn(tanksList) > 0 then
                    table.insert(msgParts, "Tanks: " .. table.concat(tanksList, ", "))
                end
                
                -- Add healers group
                if table.getn(healersList) > 0 then
                    table.insert(msgParts, "Healers: " .. table.concat(healersList, ", "))
                end
                
                -- Add other assignments
                for _, assignment in ipairs(otherAssignments) do
                    table.insert(msgParts, assignment)
                end
                
                -- Combine all parts
                local fullMsg = msgStart
                if table.getn(msgParts) > 0 then
                    fullMsg = fullMsg .. " " .. table.concat(msgParts, " ")
                end
                
                -- Split message if too long
                if string.len(fullMsg) > 240 then
                    -- Find a good split point
                    local splitPoint = 240
                    while splitPoint > 200 and string.sub(fullMsg, splitPoint, splitPoint) ~= " " do
                        splitPoint = splitPoint - 1
                    end
                    
                    table.insert(messages, {
                        text = string.sub(fullMsg, 1, splitPoint),
                        channel = bodyChannel,
                        channelNum = channelNumber
                    })
                    
                    table.insert(messages, {
                        text = "..." .. string.sub(fullMsg, splitPoint + 1),
                        channel = bodyChannel,
                        channelNum = channelNumber
                    })
                else
                    table.insert(messages, {
                        text = fullMsg,
                        channel = bodyChannel,
                        channelNum = channelNumber
                    })
                end
            end
        end
    end
    
    -- Add warning messages at the end
    for _, warningMsg in ipairs(warningMessages) do
        table.insert(messages, warningMsg)
    end
    
    -- Send all messages with throttling to avoid being disconnected
    if table.getn(messages) > 0 then
        local messageIndex = 1
        
        local function SendNextMessage()
            if messageIndex <= table.getn(messages) then
                local msg = messages[messageIndex]
                
                -- Send message to appropriate channel
                if msg.channel == "CHANNEL" then
                    SendChatMessage(msg.text, msg.channel, nil, msg.channelNum)
                else
                    SendChatMessage(msg.text, msg.channel)
                end
                
                messageIndex = messageIndex + 1
                
                -- Schedule next message with delay to avoid spam
                if messageIndex <= table.getn(messages) then
                    -- Removed debug message about sending progress
                    self:ScheduleTimer(SendNextMessage, 0.5)
                else
                    -- Show one simple completion message
                    DEFAULT_CHAT_FRAME:AddMessage("TWRA: Assignments announced")
                end
            end
        end
        
        -- Start sending messages
        SendNextMessage()
    else
        DEFAULT_CHAT_FRAME:AddMessage("TWRA: No assignments to announce")
    end
end

-- Add slash command
SLASH_TWRA1 = "/twra"
SlashCmdList["TWRA"] = function(msg)
    TWRA:ToggleMainFrame()
end

-- Initialize UI at end of loading - THIS IS THE ONLY INITIALIZE CALL
TWRA:Initialize()

-- At the end of the file, add a test function to verify DisplayCurrentSection works
function TWRA:TestDisplayCurrentSection()
    DEFAULT_CHAT_FRAME:AddMessage("TWRA Debug: Testing DisplayCurrentSection")
    
    if not self.DisplayCurrentSection then
        DEFAULT_CHAT_FRAME:AddMessage("TWRA Debug: ERROR - DisplayCurrentSection function does not exist!")
        return false
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("TWRA Debug: DisplayCurrentSection function exists")
    
    if not self.navigation then
        DEFAULT_CHAT_FRAME:AddMessage("TWRA Debug: ERROR - navigation table does not exist!")
        return false
    end
    
    DEFAULT_CHAT_FRAME:AddMessage("TWRA Debug: Navigation: " .. 
        tostring(self.navigation.currentIndex) .. " of " .. 
        table.getn(self.navigation.handlers))
    
    if self.navigation.currentIndex and self.navigation.handlers and 
       self.navigation.currentIndex <= table.getn(self.navigation.handlers) then
        DEFAULT_CHAT_FRAME:AddMessage("TWRA Debug: Current section is " .. 
            self.navigation.handlers[self.navigation.currentIndex])
    end
    
    -- Try to call the function
    DEFAULT_CHAT_FRAME:AddMessage("TWRA Debug: Calling DisplayCurrentSection")
    pcall(function() self:DisplayCurrentSection() end)
    DEFAULT_CHAT_FRAME:AddMessage("TWRA Debug: DisplayCurrentSection called")
    
    return true
end

-- Add a slash command to test
SLASH_TWRATEST1 = "/twratest"
SlashCmdList["TWRATEST"] = function(msg)
    TWRA:TestDisplayCurrentSection()
end

-- Helper function to navigate to a specific section (supports both name and index)
function TWRA:NavigateToSection(targetSection, suppressSync)
    -- Debug output
    DEFAULT_CHAT_FRAME:AddMessage(string.format("TWRA Debug: NavigateToSection(%s, %s) called - mainFrame:%s, isShown:%s", 
        tostring(targetSection), tostring(suppressSync),
        tostring(self.mainFrame), 
        self.mainFrame and tostring(self.mainFrame:IsShown()) or "nil"))
    
    -- Ensure navigation exists
    if not self.navigation then
        self.navigation = { handlers = {}, currentIndex = 1 }
    end
    
    local handlers = self.navigation.handlers
    local numSections = table.getn(handlers)
    
    if numSections == 0 then 
        DEFAULT_CHAT_FRAME:AddMessage("TWRA: No sections available")
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
        DEFAULT_CHAT_FRAME:AddMessage("TWRA: Invalid section index: "..tostring(targetSection))
        return false
    end
    
    -- Update current index
    self.navigation.currentIndex = sectionIndex
    
    -- Always update the dropdown text
    if self.navigation.handlerText then
        self.navigation.handlerText:SetText(sectionName)
    end
    
    -- Save current section
    self:SaveCurrentSection()
    
    -- Update display based on current view
    if self.currentView == "options" then
        self:ClearRows()
        DEFAULT_CHAT_FRAME:AddMessage("TWRA: Skipping display update while in options view")
    else
        self:FilterAndDisplayHandler(sectionName)
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
    
    DEFAULT_CHAT_FRAME:AddMessage(string.format("TWRA Debug: shouldShowOSD=%s (mainFrame:%s, isShown:%s, currentView:%s)",
        tostring(shouldShowOSD),
        tostring(self.mainFrame),
        self.mainFrame and tostring(self.mainFrame:IsShown()) or "nil",
        self.currentView or "nil"))
    
    if shouldShowOSD and self.ShowSectionNameOverlay then
        self:ShowSectionNameOverlay(sectionName, sectionIndex, numSections)
    end
    
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

-- Add a function to immediately save the current section when it changes
function TWRA:SaveCurrentSection()
    -- Only save if we have assignments already
    if TWRA_SavedVariables.assignments and self.navigation and self.navigation.currentIndex then
        TWRA_SavedVariables.assignments.currentSection = self.navigation.currentIndex
        -- No need for a message here as it would be too spammy
    end
end

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

-- Make SaveCurrentSection more robust
function TWRA:SaveCurrentSection()
    if not TWRA_SavedVariables.assignments then
        -- Create assignments structure if it doesn't exist
        TWRA_SavedVariables.assignments = {
            data = nil,
            source = nil,
            timestamp = time(),
            currentSection = 1
        }
    end
    
    if self.navigation and self.navigation.currentIndex then
        local oldSection = TWRA_SavedVariables.assignments.currentSection or 1
        TWRA_SavedVariables.assignments.currentSection = self.navigation.currentIndex
        
        if oldSection ~= self.navigation.currentIndex then
            DEFAULT_CHAT_FRAME:AddMessage("TWRA: Saved current section: " .. 
                self.navigation.currentIndex .. " (" .. 
                self.navigation.handlers[self.navigation.currentIndex] .. ")")
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
        
        -- Store the structured data directly
        TWRA_SavedVariables.assignments = {
            data = tableData,
            timestamp = timestamp,
            currentSection = sectionToUse  -- Save the section here
        }
        
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

-- Add to the end of the file or replace existing ToggleMainFrame function if it exists
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
        
        -- Make sure we're showing main view, not options
        if self.currentView == "options" then
            self:ShowMainView()
        end
        
        DEFAULT_CHAT_FRAME:AddMessage("TWRA: Window shown")
    end
end

-- Add slash command to test keybinding functionality
SLASH_TWRASHOW1 = "/twrashow"
SlashCmdList["TWRASHOW"] = function(msg)
    if TWRA and TWRA.ShowWhilePressed then
        if msg == "up" then
            TWRA:ShowWhilePressed("up")
        else
            TWRA:ShowWhilePressed("down")
        end
    end
end

-- Add slash command to toggle the test button
SLASH_TWRATEST1 = "/twratest"
SlashCmdList["TWRATEST"] = function(msg)
    if msg == "button" and TWRA and TWRA.ToggleTestButton then
        TWRA:ToggleTestButton()
    else
        TWRA:TestDisplayCurrentSection()
    end
end
TWRA:Debug("nav", "Core module loaded")