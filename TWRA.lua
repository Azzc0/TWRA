TWRA_SavedVariables = TWRA_SavedVariables or {
    assignments = {}
}
TWRA = TWRA or {}

-- Core initialization and utility functions
local b64Table = {
    ['A']=0,['B']=1,['C']=2,['D']=3,['E']=4,['F']=5,['G']=6,['H']=7,['I']=8,['J']=9,
    ['K']=10,['L']=11,['M']=12,['N']=13,['O']=14,['P']=15,['Q']=16,['R']=17,['S']=18,
    ['T']=19,['U']=20,['V']=21,['W']=22,['X']=23,['Y']=24,['Z']=25,['a']=26,['b']=27,
    ['c']=28,['d']=29,['e']=30,['f']=31,['g']=32,['h']=33,['i']=34,['j']=35,['k']=36,
    ['l']=37,['m']=38,['n']=39,['o']=40,['p']=41,['q']=42,['r']=43,['s']=44,['t']=45,
    ['u']=46,['v']=47,['w']=48,['x']=49,['y']=50,['z']=51,['0']=52,['1']=53,['2']=54,
    ['3']=55,['4']=56,['5']=57,['6']=58,['7']=59,['8']=60,['9']=61,['+'] = 62,['/'] = 63,
    ['='] = -1
}

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

-- Data constants
TWRA.VANILLA_CLASS_COLORS = {
    ["WARRIOR"] = {r=0.68, g=0.51, b=0.33},
    ["PRIEST"] = {r=0.9, g=0.9, b=0.9},
    ["DRUID"] = {r=0.9, g=0.44, b=0.04},
    ["ROGUE"] = {r=0.9, g=0.86, b=0.36},
    ["MAGE"] = {r=0.36, g=0.7, b=0.84},
    ["HUNTER"] = {r=0.57, g=0.73, b=0.35},
    ["WARLOCK"] = {r=0.53, g=0.46, b=0.74},
    ["PALADIN"] = {r=0.86, g=0.45, b=0.63},
    ["SHAMAN"] = {r=0.0, g=0.39, b=0.77}
}

TWRA.CLASS_GROUP_NAMES = {
    ["Druids"] = "DRUID",
    ["Hunters"] = "HUNTER",
    ["Mages"] = "MAGE",
    ["Paladins"] = "PALADIN",
    ["Priests"] = "PRIEST",
    ["Rogues"] = "ROGUE",
    ["Shamans"] = "SHAMAN",
    ["Warlocks"] = "WARLOCK",
    ["Warriors"] = "WARRIOR"
}

TWRA.CLASS_COORDS = {
    ["WARRIOR"] = {0, 0.25, 0, 0.25},
    ["PALADIN"] = {0, 0.25, 0.5, 0.75},
    ["HUNTER"] = {0, 0.25, 0.25, 0.5},
    ["ROGUE"] = {0.5, 0.75, 0, 0.25},
    ["PRIEST"] = {0.5, 0.75, 0.25, 0.5},
    ["SHAMAN"] = {0.25, 0.5, 0.25, 0.5},
    ["MAGE"] = {0.25, 0.5, 0, 0.25},
    ["WARLOCK"] = {0.75, 1, 0.25, 0.5},
    ["DRUID"] = {0.75, 1, 0, 0.25}
}

TWRA.ICONS = {
    -- Format: name = {texture, x1, x2, y1, y2}
    ["Skull"] = {"Interface\\TargetingFrame\\UI-RaidTargetingIcons", 0.75, 1, 0.25, 0.5},
    ["Cross"] = {"Interface\\TargetingFrame\\UI-RaidTargetingIcons", 0.5, 0.75, 0.25, 0.5},
    ["Square"] = {"Interface\\TargetingFrame\\UI-RaidTargetingIcons", 0.25, 0.5, 0.25, 0.5},
    ["Moon"] = {"Interface\\TargetingFrame\\UI-RaidTargetingIcons", 0, 0.25, 0.25, 0.5},
    ["Triangle"] = {"Interface\\TargetingFrame\\UI-RaidTargetingIcons", 0.75, 1, 0, 0.25},
    ["Diamond"] = {"Interface\\TargetingFrame\\UI-RaidTargetingIcons", 0.5, 0.75, 0, 0.25},
    ["Circle"] = {"Interface\\TargetingFrame\\UI-RaidTargetingIcons", 0.25, 0.5, 0, 0.25},
    ["Star"] = {"Interface\\TargetingFrame\\UI-RaidTargetingIcons", 0, 0.25, 0, 0.25},
    ["Warning"] = {"Interface\\DialogFrame\\DialogAlertIcon", 0, 1, 0, 1},
    ["Note"] = {"Interface\\TutorialFrame\\TutorialFrame-QuestionMark", 0, 1, 0, 1},
    ["GUID"] = {"Interface\\Icons\\INV_Misc_Note_01", 0, 1, 0, 1}  -- Added GUID icon
}

-- Add colored icon text for announcements
TWRA.COLORED_ICONS = {
    ['Skull'] = '|cFFF1EFE4[Skull]|r',
    ['Cross'] = '|cFFB20A05[Cross]|r',
    ['Square'] = '|cFF00B9F3[Square]|r',
    ['Moon'] = '|cFF8FB9D0[Moon]|r',
    ['Triangle'] = '|cFF2BD923[Triangle]|r',
    ['Diamond'] = '|cffB035F2[Diamond]|r',
    ['Circle'] = '|cFFE76100[Circle]|r',
    ['Star'] = '|cFFF7EF52[Star]|r',
}

TWRA.ROLE_ICONS = {
    -- Basic role icons using standard game textures
    ["Tank"] = "Interface\\Icons\\Ability_Warrior_DefensiveStance",     -- Tank
    ["Heal"] = "Interface\\Icons\\Spell_Holy_HolyBolt",                 -- Heal
    ["DPS"] = "Interface\\Icons\\INV_Sword_04",                         -- DPS
    ["CC"] = "Interface\\Icons\\Spell_Frost_ChainsOfIce",               -- CC
    ["Pull"] = "Interface\\Icons\\Ability_Hunter_SniperShot",           -- Pull
    ["Ress"] = "Interface\\Icons\\Spell_Holy_Resurrection",             -- Ress
    ["Assist"] = "Interface\\Icons\\Ability_Warrior_BattleShout",       -- Assist
    ["Scout"] = "Interface\\Icons\\Ability_Hunter_EagleEye",            -- Scout
    ["Lead"] = "Interface\\Icons\\Ability_Warrior_RallyingCry",         -- Lead
    
    -- Fallbacks for roles that don't match our custom icons
    ["MC"] = "Interface\\Icons\\Spell_Shadow_ShadowWordDominate",
    ["Kick"] = "Interface\\Icons\\Ability_Kick",
    ["Decurse"] = "Interface\\Icons\\Spell_Holy_RemoveCurse",
    ["Taunt"] = "Interface\\Icons\\Spell_Nature_Reincarnation",
    ["MD"] = "Interface\\Icons\\Ability_Hunter_Misdirection",
    ["Sap"] = "Interface\\Icons\\Ability_Sap",
    ["Purge"] = "Interface\\Icons\\Spell_Holy_Dispel",
    ["Shackle"] = "Interface\\Icons\\Spell_Nature_Slow",
    ["Banish"] = "Interface\\Icons\\Spell_Shadow_Cripple",
    ["Kite"] = "Interface\\Icons\\Ability_Rogue_Sprint",
    ["Bomb"] = "Interface\\Icons\\spell_fire_selfdestruct",
    ["Interrupt"] = "Interface\\Icons\\Ability_Kick",
    ["Misc"] = "Interface\\Icons\\INV_Misc_Gear_01"
}

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
    
    -- Check if this is the example data and set the flag accordingly
    self.usingExampleData = (sourceString == "example_data" or self:IsExampleData(data))
    
    -- Save the data, source string, and current section index
    TWRA_SavedVariables.assignments = {
        data = data,
        source = sourceString,
        timestamp = timestamp,
        currentSection = currentIndex,
        version = 1,
        isExample = self.usingExampleData
    }
    
    -- Rebuild navigation with the new data
    self:RebuildNavigation()
    
    -- Replace direct message with Debug call
    self:Debug("data", "Assignments saved with timestamp " .. timestamp)
    
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
        self.navigation.currentIndex = math.min(currentSection, table.getn(self.navigation.handlers))
    end
    
    self:Debug("data", "Loaded assignments")
    return true
end

-- Utility functions
function TWRA:GetPlayerStatus(name)
    if not name or name == "" then return false, nil end
    
    if UnitName("player") == name then return true, true end
    
    -- Check raid roster
    for i = 1, GetNumRaidMembers() do
        local raidName, _, _, _, _, _, _, online = GetRaidRosterInfo(i)
        if raidName == name then
            return true, online
        end
    end
    
    -- Check party if not in raid
    if GetNumRaidMembers() == 0 then
        for i = 1, GetNumPartyMembers() do
            if UnitName("party" .. i) == name then
                return true, UnitIsConnected("party" .. i)
            end
        end
    end
    
    return false, nil
end

function TWRA:HasClassInRaid(className)
    for i = 1, GetNumRaidMembers() do
        local _, _, _, _, _, class = GetRaidRosterInfo(i)
        if class == className then
            return true
        end
    end
    return false
end

function TWRA:IsRaidAssist()
    if GetNumRaidMembers() == 0 then
        return false
    end
    
    local playerName = UnitName("player")
    for i = 1, GetNumRaidMembers() do
        if UnitName("raid"..i) == playerName then
            -- Use the Classic function names
            return IsRaidOfficer("raid"..i) or IsRaidLeader("raid"..i)
        end
    end
    return false
end

-- Check if oRA2 is available
function TWRA:IsORA2Available()
    return oRA and oRA.maintanktable ~= nil  -- Changed to lowercase
end

-- Update to use Debug
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

-- Basic function to display section name overlay when navigating with window closed
-- Enhanced version is in OSD.lua
function TWRA:ShowSectionNameOverlay(sectionName, currentIndex, totalSections)
    -- Forward to OSD module if available
    if self.OSD and self.OSD.ShowSectionNameOverlay then
        self.OSD.ShowSectionNameOverlay(sectionName, currentIndex, totalSections)
        return
    end
    
    -- Create the overlay frame if it doesn't exist
    if not self.sectionOverlay then
        self.sectionOverlay = CreateFrame("Frame", "TWRA_SectionOverlay", UIParent)
        self.sectionOverlay:SetFrameStrata("DIALOG")
        self.sectionOverlay:SetWidth(400)
        self.sectionOverlay:SetHeight(60)
        self.sectionOverlay:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
        
        -- Add background
        local bg = self.sectionOverlay:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetTexture(0, 0, 0, 0.7)
        
        -- Add border
        local border = CreateFrame("Frame", nil, self.sectionOverlay)
        border:SetPoint("TOPLEFT", -2, 2)
        border:SetPoint("BOTTOMRIGHT", 2, -2)
        border:SetBackdrop({
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 16,
            insets = { left = 4, right = 4, top = 4, bottom = 4 }
        })
        
        -- Section name text
        self.sectionOverlayText = self.sectionOverlay:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        self.sectionOverlayText:SetPoint("TOP", self.sectionOverlay, "TOP", 0, -10)
        self.sectionOverlayText:SetTextColor(1, 0.82, 0)
        
        -- Section count text
        self.sectionOverlayCount = self.sectionOverlay:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        self.sectionOverlayCount:SetPoint("BOTTOM", self.sectionOverlay, "BOTTOM", 0, 10)
        self.sectionOverlayCount:SetTextColor(1, 1, 1)
    end
    
    -- Update the text
    self.sectionOverlayText:SetText(sectionName)
    self.sectionOverlayCount:SetText("Section " .. currentIndex .. " of " .. totalSections)
    
    -- Show the overlay
    self.sectionOverlay:Show()
    
    -- Hide after 2 seconds
    if self.sectionOverlayTimer then
        self:CancelTimer(self.sectionOverlayTimer)
    end
    
    self.sectionOverlayTimer = self:ScheduleTimer(function()
        if self.sectionOverlay then
            self.sectionOverlay:Hide()
        end
    end, 2)
end

-- Timer functionality for older WoW versions
function TWRA:ScheduleTimer(func, delay)
    local timer = CreateFrame("Frame")
    timer.start = GetTime()
    timer.delay = delay
    timer.func = func
    
    timer:SetScript("OnUpdate", function()
        local elapsed = GetTime() - timer.start
        if elapsed >= timer.delay then
            timer:SetScript("OnUpdate", nil)
            timer.func()
        end
    end)
    
    return timer
end

function TWRA:CancelTimer(timer)
    if timer then
        timer:SetScript("OnUpdate", nil)
    end
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

-- At the end of the file, add a test function to verify DisplayCurrentSection works
function TWRA:TestDisplayCurrentSection()
    self:Debug("nav", "Testing DisplayCurrentSection")
    
    if not self.DisplayCurrentSection then
        self:Debug("error", "DisplayCurrentSection function does not exist!", true)
        return false
    end
    
    self:Debug("nav", "DisplayCurrentSection function exists")
    
    if not self.navigation then
        self:Debug("error", "Navigation table does not exist!", true)
        return false
    end
    
    self:Debug("nav", "Navigation: " .. 
        tostring(self.navigation.currentIndex) .. " of " .. 
        table.getn(self.navigation.handlers))
    
    if self.navigation.currentIndex and self.navigation.handlers and 
       self.navigation.currentIndex <= table.getn(self.navigation.handlers) then
        self:Debug("nav", "Current section is " .. 
            self.navigation.handlers[self.navigation.currentIndex])
    end
    
    -- Try to call the function
    self:Debug("nav", "Calling DisplayCurrentSection")
    pcall(function() self:DisplayCurrentSection() end)
    self:Debug("nav", "DisplayCurrentSection called")
    
    return true
end

-- Add a slash command to test
SLASH_TWRATEST1 = "/twratest"
SlashCmdList["TWRATEST"] = function(msg)
    TWRA:TestDisplayCurrentSection()
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

-- Add CreateMinimapButton function - moved from OSD.lua to TWRA.lua as requested
function TWRA:CreateMinimapButton()
    self:Debug("general", "Creating minimap button")
    
    -- Create a frame for our minimap button
    local miniButton = CreateFrame("Button", "TWRAMinimapButton", Minimap)
    miniButton:SetWidth(32)
    miniButton:SetHeight(32)
    miniButton:SetFrameStrata("MEDIUM")
    miniButton:SetFrameLevel(8)
    
    -- Set position (default to 180 degrees)
    local defaultAngle = 180
    local angle = defaultAngle
    
    -- Use saved angle if available
    if TWRA_SavedVariables and TWRA_SavedVariables.options and TWRA_SavedVariables.options.minimapAngle then
        angle = TWRA_SavedVariables.options.minimapAngle
    end
    
    -- Calculate position
    local radius = 80
    local radian = math.rad(angle)
    local x = math.cos(radian) * radius
    local y = math.sin(radian) * radius
    miniButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
    
    -- Set icon texture
    local icon = miniButton:CreateTexture(nil, "BACKGROUND")
    icon:SetTexture("Interface\\AddOns\\TWRA\\textures\\minimap_icon")
    
    -- If the custom texture doesn't exist, use a default
    if not icon:GetTexture() then
        icon:SetTexture("Interface\\Icons\\INV_Misc_Book_11")
    end
    
    icon:SetAllPoints(miniButton)
    miniButton.icon = icon
    
    -- Add highlight texture
    local highlight = miniButton:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    highlight:SetBlendMode("ADD")
    highlight:SetAllPoints(miniButton)
    miniButton.highlight = highlight
    
    -- Set up scripts
    miniButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(miniButton, "ANCHOR_LEFT")
        GameTooltip:AddLine("TWRA - Raid Assignments")
        GameTooltip:AddLine("Left-click: Toggle assignments window", 1, 1, 1)
        GameTooltip:AddLine("Right-click: Toggle assignments OSD", 1, 1, 1)
        GameTooltip:Show()
    end)
    miniButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    miniButton:SetScript("OnClick", function()
        if arg1 == "RightButton" then
            -- Right click: Toggle OSD
            if TWRA.ToggleOSD then
                TWRA:ToggleOSD()
            end
        else
            -- Left click: Toggle main window
            if TWRA.ToggleMainFrame then
                TWRA:ToggleMainFrame()
            else
                DEFAULT_CHAT_FRAME:AddMessage("TWRA: Main window not available")
            end
        end
    end)
    
    -- Make the button draggable
    miniButton:RegisterForDrag("LeftButton")
    miniButton:SetScript("OnDragStart", function()
        this:LockHighlight()
        this:StartMoving()
    end)
    miniButton:SetScript("OnDragStop", function()
        this:StopMovingOrSizing()
        this:UnlockHighlight()
        
        -- Calculate and save angle
        local x, y = this:GetCenter()
        local mx, my = Minimap:GetCenter()
        local angle = math.deg(math.atan2(y - my, x - mx))
        
        -- Save to settings
        if TWRA_SavedVariables and TWRA_SavedVariables.options then
            TWRA_SavedVariables.options.minimapAngle = angle
        end
    end)
    
    -- Store reference in addon
    self.minimapButton = miniButton
    
    self:Debug("general", "Minimap button created")
    return miniButton
end

-- Add message handling system functions to TWRA.lua
-- These were previously in OSD.lua but should be core functionality
function TWRA:RegisterMessageHandler(message, callback)
    -- Initialize the message handlers table if it doesn't exist
    self.messageHandlers = self.messageHandlers or {}
    
    -- Create array for this message type if needed
    if not self.messageHandlers[message] then
        self.messageHandlers[message] = {}
    end
    
    -- Add the callback to the handlers array
    table.insert(self.messageHandlers[message], callback)
    self:Debug("general", "Registered message handler for: " .. message)
end

-- Send message function to complete the messaging system
function TWRA:SendMessage(message, arg1, arg2, arg3, arg4, arg5)
    -- Initialize the message handlers table if it doesn't exist
    self.messageHandlers = self.messageHandlers or {}
    
    -- Check if we have any handlers for this message
    if not self.messageHandlers[message] then
        return -- No handlers registered
    end
    
    self:Debug("general", "Sending message: " .. message)
    
    -- Call each registered handler with the arguments
    for _, callback in ipairs(self.messageHandlers[message]) do
        -- Use explicit arguments instead of varargs (... unpacking)
        callback(arg1, arg2, arg3, arg4, arg5)
    end
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
        self:Debug("nav", "In options view - clearing rows and skipping display update")
        self:ClearRows()
    else
        self:Debug("nav", "In main view - updating display with section: " .. sectionName)
        
        -- Force the view to main view to ensure content is visible
        if self.currentView ~= "main" then
            self.currentView = "main"
            
            -- Show and hide appropriate frames
            if self.contentFrame then self.contentFrame:Show() end
            if self.optionsFrame then self.optionsFrame:Hide() end
        end
        
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
    
    self:Debug("nav", string.format("shouldShowOSD=%s (mainFrame:%s, isShown:%s, currentView:%s)",
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
    -- Check if mainFrame exists
    if not self.mainFrame then
        self:CreateMainFrame()
    end
    
    -- Safety: Use pcall to avoid errors
    local success, err = pcall(function()
                
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
        
        -- Hide action buttons
        if self.announceButton then self.announceButton:Hide() end
        if self.updateTanksButton then self.updateTanksButton:Hide() end
        
        -- Reset frame height to default while in options
        self.mainFrame:SetHeight(300)
        
        -- Change "Options" button text to "Back"
        if self.optionsButton then 
            self.optionsButton:SetText("Back")
        end
        
        -- Create options panel if it doesn't exist
        if not self.optionsPanel then
            self:CreateOptionsPanel()
        end
        
        -- Show options panel
        if self.optionsPanel then
            self.optionsPanel:Show()
        end
        
        -- Update current view state
        self.currentView = "options"
    end)
    
    if not success then
        self:Error("Error in ShowOptionsView: " .. tostring(err))
    end
    
    self:Debug("ui", "Switched to options view - currentView = " .. self.currentView)
end

-- Fix ShowMainView to safely handle view transition
function TWRA:ShowMainView()
    -- Check if mainFrame exists
    if not self.mainFrame then
        self:CreateMainFrame()
    end
    
    -- Safety: Use pcall to avoid errors
    local success, err = pcall(function()
        -- Hide options panel
        if self.optionsPanel then
            self.optionsPanel:Hide()
        end
        
        -- Show navigation elements
        if self.navigation then
            if self.navigation.prevButton then self.navigation.prevButton:Show() end
            if self.navigation.nextButton then self.navigation.nextButton:Show() end
            if self.navigation.menuButton then self.navigation.menuButton:Show() end
            if self.navigation.handlerText then self.navigation.handlerText:Show() end
        end
        
        -- Show action buttons
        if self.announceButton then self.announceButton:Show() end
        if self.updateTanksButton then self.updateTanksButton:Show() end
        
        -- Change button text back to "Options"
        if self.optionsButton then 
            self.optionsButton:SetText("Options")
        end
        
        -- Update the current view state
        self.currentView = "main"
        
        -- Check if we have pending navigation
        if self.pendingNavigation then
            self.navigation.currentIndex = self.pendingNavigation
            self.pendingNavigation = nil
        end
        
        -- Update display
        self:DisplayCurrentSection()
    end)
    
    if not success then
        self:Error("Error in ShowMainView: " .. tostring(err))
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
        self.navigation.currentIndex = 1
    end
    
    -- Clear rows
    self:ClearRows()
    
    -- Clear navigation text if it exists
    if self.navigation and self.navigation.handlerText then
        self.navigation.handlerText:SetText("")
    end
    
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