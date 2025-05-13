TWRA = TWRA or {}

-- Example player data (only used for demo purposes)
TWRA.EXAMPLE_PLAYERS = {
    -- Active players with format: {class, isOnline}
    ["Azzco"] = {"WARRIOR", true},
    ["Recin"] = {"WARRIOR", true},
    ["Nytorpa"] = {"WARRIOR", true},
    ["Dhl"] = {"DRUID", true},
    ["Lenato"] = {"PALADIN", true},
    ["Sinfuil"] = {"PALADIN", true},
    ["Kroken"] = {"ROGUE", true},
    ["Kaydaawg"] = {"PRIEST", true},
    ["Slaktaren"] = {"PRIEST", true},
    ["Pooras"] = {"DRUID", true},
    ["Ambulans"] = {"SHAMAN", true},
    ["Heartstiller"] = {"PRIEST", true},
    ["Jouthor"] = {"HUNTER", true},
    ["Nattoega"] = {"HUNTER", true},
    ["Vasslan"] = {"HUNTER", true},
    ["Falken"] = {"HUNTER", true},
    -- Offline player
    ["Slubban"] = {"PRIEST", false}
}

-- Version 2 format example data that follows the structured format
TWRA.EXAMPLE_DATA = {
    data = {
        [1] = {
            ["Section Name"] = "Welcome",
            ["Section Header"] = {
                [1] = "Icon",
                [2] = "Target",
                [3] = "Tank",
                [4] = "DPS",
                [5] = "Heal"
            },
            ["Section Rows"] = {
                [1] = {
                    [1] = "Star", 
                    [2] = "Big nasty boss",
                    [3] = UnitName("player"),
                    [4] = "Kroken",
                    [5] = "Kaydaawg"
                },
                [2] = {
                    [1] = "Skull",
                    [2] = "Add",
                    [3] = "Druids",
                    [4] = "Mages",
                    [5] = "Hunters"
                },
                [3] = {
                    [1] = "Cross",
                    [2] = "Add",
                    [3] = "Paladins",
                    [4] = "Priests",
                    [5] = "Rogues"
                },
                [4] = {
                    [1] = "Moon",
                    [2] = "Add",
                    [3] = "Shamans",
                    [4] = "Warlocks",
                    [5] = "Warriors"
                }
            },
            ["Section Metadata"] = {
                ["Note"] = {
                    [1] = "Note text will not be sent to the chat.",
                    [2] = "You need to import your own assignments! Check the README on github for how to create your own.",
                    [3] = "Players not in the raid will be marked red and they will not have an associated class icon",
                    [4] = "Players offline will be marked grey.",
                    [5] = "Lines with your name or your class (plural) will be highlighted."
                },
                ["Warning"] = {
                    [1] = "Warning text will be announced along with assignments into raidchat."
                }
            },
            ["Section Player Info"] = {
                ["OSD Assignments"] = {
                    [1] = {
                        [1] = "Tank",
                        [2] = "Star",
                        [3] = "Big nasty boss",
                        [4] = UnitName("player")
                    },
                    [2] = {
                        [1] = "Heal",
                        [2] = "Moon",
                        [3] = "Add",
                        [4] = "Shamans"
                    }
                },
                ["Relevant Rows"] = {1, 4},
                ["Relevant Group Rows"] = {}
            }
        },
        [2] = {
            ["Section Name"] = "Grand Widow Faerlina",
            ["Section Header"] = {
                [1] = "Icon",
                [2] = "Target",
                [3] = "Tank",
                [4] = "Pull",
                [5] = "MC",
                [6] = "Heal"
            },
            ["Section Rows"] = {
                [1] = {
                    [1] = "Skull",
                    [2] = "Naxxramas Follower",
                    [3] = "Azzco",
                    [4] = "",
                    [5] = "",
                    [6] = "Sinfuil"
                },
                [2] = {
                    [1] = "Cross",
                    [2] = "Naxxramas Follower",
                    [3] = "Dhl",
                    [4] = "",
                    [5] = "",
                    [6] = "Slaktaren"
                },
                [3] = {
                    [1] = "Triangle",
                    [2] = "Grand Widow Faerlina",
                    [3] = "Lenato",
                    [4] = "",
                    [5] = "",
                    [6] = "Ambulans"
                },
                [4] = {
                    [1] = "Square",
                    [2] = "Naxxramas Worshipper",
                    [3] = "",
                    [4] = "Jouthor",
                    [5] = "Slubban",
                    [6] = ""
                },
                [5] = {
                    [1] = "Circle",
                    [2] = "Naxxramas Worshipper",
                    [3] = "Recin",
                    [4] = "Nattoega",
                    [5] = "Heartstiller",
                    [6] = ""
                },
                [6] = {
                    [1] = "Moon",
                    [2] = "Naxxramas Worshipper",
                    [3] = "Nytorpa",
                    [4] = "Vasslan",
                    [5] = "Heartstiller",
                    [6] = ""
                },
                [7] = {
                    [1] = "Star",
                    [2] = "Naxxramas Worshipper",
                    [3] = "",
                    [4] = "Falken",
                    [5] = "Heartstiller",
                    [6] = ""
                }
            },
            ["Section Metadata"] = {
                ["Note"] = {
                    [1] = "We use one healing priest to sacrifice one of the worshippers early."
                },
                ["Warning"] = {
                    [1] = "Do NOT kill woshippers. We mind control and sacrifice them to counter the boss's enrage!"
                },
                ["Tank Columns"] = {3}
            },
            ["Section Player Info"] = {
                ["OSD Assignments"] = {
                    [1] = {
                        [1] = "Tank",
                        [2] = "Triangle",
                        [3] = "Grand Widow Faerlina",
                        [4] = "Lenato"
                    },
                    [2] = {
                        [1] = "MC",
                        [2] = "Square",
                        [3] = "Naxxramas Worshipper",
                        [4] = "Slubban"
                    }
                },
                ["Relevant Rows"] = {3, 4},
                ["Relevant Group Rows"] = {}
            }
        },
        [3] = {
            ["Section Name"] = "Thaddius",
            ["Section Header"] = {
                [1] = "Icon",
                [2] = "Target",
                [3] = "Tank",
                [4] = "DPS",
                [5] = "DPS",
                [6] = "DPS",
                [7] = "Heal",
                [8] = "Heal"
            },
            ["Section Rows"] = {
                [1] = {
                    [1] = "Skull",
                    [2] = "Thaddius",
                    [3] = "Lenato",
                    [4] = "",
                    [5] = "",
                    [6] = "",
                    [7] = "Pooras",
                    [8] = "Kaydaawg"
                },
                [2] = {
                    [1] = "Cross",
                    [2] = "Stalagg",
                    [3] = "Azzco",
                    [4] = "Paladins",
                    [5] = "Mages",
                    [6] = "Warlocks",
                    [7] = "Priests",
                    [8] = "Paladins"
                },
                [3] = {
                    [1] = "Square",
                    [2] = "Feugen",
                    [3] = "Dhl",
                    [4] = "Warriors",
                    [5] = "Rogues",
                    [6] = "Hunters",
                    [7] = "Shamans",
                    [8] = "Druids"
                }
            },
            ["Section Metadata"] = {
                ["Note"] = {
                    [1] = "Feugen (right) mana burns around him, it can be outranged.",
                    [2] = "if Feugen and Stalagg doesn't die at the same time they'll ressurrect."
                },
                ["Warning"] = {
                    [1] = "--- BOSS +++"
                },
                ["Tank Columns"] = {3}
            },
            ["Section Player Info"] = {
                ["OSD Assignments"] = {
                    [1] = {
                        [1] = "Tank",
                        [2] = "Cross",
                        [3] = "Stalagg",
                        [4] = "Azzco"
                    },
                    [2] = {
                        [1] = "Heal",
                        [2] = "Skull",
                        [3] = "Thaddius",
                        [4] = "Pooras",
                        [5] = "Kaydaawg"
                    }
                },
                ["Relevant Rows"] = {2},
                ["Relevant Group Rows"] = {}
            }
        }
    }
}

-- Function to load example data
function TWRA:LoadExampleData()
    self:Debug("data", "Loading example data")
    
    -- Clear any existing data first
    if self.ClearData then
        self:ClearData()
    end
    
    -- Set the flag to indicate we're using example data
    self.usingExampleData = true
    
    -- IMPORTANT: Clear compressed assignments when using example data
    -- Example data doesn't need compressed format
    TWRA_CompressedAssignments = nil
    self:Debug("data", "Cleared TWRA_CompressedAssignments for example data")
    
    -- Temporarily disable OSD from showing on navigation change
    local originalShowOnNavigation = nil
    if self.OSD then
        originalShowOnNavigation = self.OSD.showOnNavigation
        self.OSD.showOnNavigation = false
        self:Debug("osd", "Temporarily disabled OSD showOnNavigation")
    end
    
    -- Directly assign the example data but with proper structure
    TWRA_Assignments = {
        data = self.EXAMPLE_DATA.data,
        timestamp = 0,      -- Use 0 for example data timestamp
        currentSection = 1, -- Start at first section
        currentSectionName = "Welcome",
        version = 2,        -- Use version 2 format
        isExample = true    -- Mark as example data
    }
    
    -- CRITICAL: Force complete rebuilding of navigation
    if self.RebuildNavigation then
        self:Debug("nav", "Rebuilding navigation from example data")
        self:RebuildNavigation()
    end
    
    -- Update navigation handler text
    if self.navigation and self.navigation.handlerText and 
       self.navigation.handlers and self.navigation.handlers[1] then
        self.navigation.handlerText:SetText(self.navigation.handlers[1])
        self:Debug("nav", "Updated navigation handler text to: " .. self.navigation.handlers[1])
    end
    
    -- CRITICAL: Force refresh dropdown menu completely
    if self.navigation and self.navigation.dropdownMenu then
        self:Debug("nav", "Force refreshing dropdown menu")
        
        -- Clean up any existing buttons
        if self.navigation.dropdownMenu.buttons then
            for _, button in pairs(self.navigation.dropdownMenu.buttons) do
                button:Hide()
                button:SetParent(nil)
            end
        end
        self.navigation.dropdownMenu.buttons = {}
        
        -- Rebuild dropdown button list from current handlers
        local menuButton = self.navigation.menuButton
        local dropdownMenu = self.navigation.dropdownMenu
        
        if menuButton and dropdownMenu then
            -- Position menu correctly
            dropdownMenu:ClearAllPoints()
            dropdownMenu:SetPoint("TOP", menuButton, "BOTTOM", 0, -2)
            dropdownMenu:SetWidth(menuButton:GetWidth())
            
            -- Calculate menu height based on sections
            local buttonHeight = 20
            local padding = 10  -- 5px top and bottom
            local menuHeight = (buttonHeight * table.getn(self.navigation.handlers)) + padding
            dropdownMenu:SetHeight(menuHeight)
            
            -- Recreate buttons for each section
            for i = 1, table.getn(self.navigation.handlers) do
                local handler = self.navigation.handlers[i]
                
                -- Create button for this section
                local button = CreateFrame("Button", nil, dropdownMenu)
                button:SetHeight(buttonHeight)
                button:SetPoint("TOPLEFT", dropdownMenu, "TOPLEFT", 5, -5 - ((i-1) * buttonHeight))
                button:SetPoint("TOPRIGHT", dropdownMenu, "TOPRIGHT", -5, -5 - ((i-1) * buttonHeight))
                
                -- Highlight texture
                button:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
                
                -- Button text
                local buttonText = button:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                buttonText:SetPoint("LEFT", 5, 0)
                buttonText:SetPoint("RIGHT", -5, 0)
                buttonText:SetText(handler)
                buttonText:SetJustifyH("LEFT")
                
                -- Mark current selection
                if i == self.navigation.currentIndex then
                    button:SetNormalTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
                    local normalTex = button:GetNormalTexture()
                    normalTex:SetVertexColor(1, 0.82, 0, 0.4)
                end
                
                -- Click handler
                button:SetScript("OnClick", function()
                    -- Update text immediately for responsive UI
                    if self.navigation.handlerText then
                        self.navigation.handlerText:SetText(handler)
                    end
                    
                    -- CRITICAL: Navigate to this section - explicitly use "user" as source
                    self:NavigateToSection(i, "user")
                    
                    -- Hide the dropdown
                    dropdownMenu:Hide()
                end)
                
                -- Store the button
                table.insert(dropdownMenu.buttons, button)
            end
            
            self:Debug("nav", "Rebuilt dropdown menu with " .. table.getn(self.navigation.handlers) .. " sections")
        end
    end
    
    -- CRITICAL: Process player-specific information
    if self.ProcessPlayerInfo then
        self:Debug("data", "Processing player-relevant information for example data")
        self:ProcessPlayerInfo()
    end
    
    -- Navigate to first section WITHOUT triggering OSD (bypass normal NavigateToSection)
    self:Debug("nav", "Setting up first section without triggering OSD")
    
    -- Update current index
    if self.navigation then
        self.navigation.currentIndex = 1
    end
    
    -- Update current section immediately without triggering SECTION_CHANGED event
    self:SaveCurrentSection()
    
    -- Update UI elements directly
    if self.mainFrame and self.mainFrame:IsShown() then
        -- Update navigation text elements
        if self.navigation and self.navigation.handlers and self.navigation.handlers[1] then
            local sectionName = self.navigation.handlers[1]
            
            -- Update handler text if it exists
            if self.navigation.handlerText then
                self.navigation.handlerText:SetText(sectionName)
            end
            
            -- Update dropdown text if it exists
            if self.navigation.menuButton and self.navigation.menuButton.text then
                self.navigation.menuButton.text:SetText(sectionName)
            end
            
            -- Update the content display
            if self.FilterAndDisplayHandler then
                self:FilterAndDisplayHandler(sectionName)
                self:Debug("nav", "Updated display for section: " .. sectionName)
            end
            
            -- Refresh the assignment table
            if self.RefreshAssignmentTable then
                self:RefreshAssignmentTable()
            end
        end
    end
    
    -- Restore the original OSD showOnNavigation setting
    if self.OSD and originalShowOnNavigation ~= nil then
        self.OSD.showOnNavigation = originalShowOnNavigation
        self:Debug("osd", "Restored OSD showOnNavigation to " .. tostring(originalShowOnNavigation))
    end
    
    return true
end

-- Function to import data from Base64 string
function TWRA:ImportString(importString, isSync, syncTimestamp)
    -- Debug the import process
    self:Debug("data", "Importing data string (length: " .. string.len(importString) .. ")")

    -- Always clear example data mode when importing
    if self.usingExampleData then
        self:Debug("data", "Clearing example data mode before import")
        -- Restore original NavigateToSection function if we've overridden it
        if self.NavigateToSectionExample then
            self:Debug("nav", "Restoring original NavigateToSection function")
            -- No need to explicitly restore, as import will create a new instance anyway
            self.NavigateToSectionExample = nil
        end
        
        -- Clear example data flag
        self.usingExampleData = false
    end
    
    -- Explicitly set non-example mode for the incoming data
    if TWRA_Assignments then
        self:Debug("data", "Explicitly set isExample = false for manual import")
        TWRA_Assignments.isExample = false
    end
    
    -- Ensure we're starting with a clean slate for indexes
    if self.navigation then
        self:Debug("nav", "Resetting navigation indexes before import")
        self.navigation.currentIndex = 1
    end

    -- Disable OSD temporarily
    local osdWasVisible = false
    if self.OSD and self.OSD.isVisible then
        osdWasVisible = true
        self.OSD:Hide()
    end

    -- Try to decode the import string
    local success, result = pcall(function()
        return self:Base64Decode(importString)
    end)

    -- Handle decode errors
    if not success or not result then
        self:Debug("error", "Failed to decode Base64 string")
        -- Show error message
        DEFAULT_CHAT_FRAME:AddMessage("|cFFFF0000TWRA: Import failed - Invalid data format|r")
        return false
    end

    -- Try to load the decoded string
    local encodingType = 0
    
    -- Attempt to determine encoding type from first byte
    local firstByte = string.byte(result, 1)
    if firstByte == 241 then -- 0xF1 - Compressed data
        encodingType = 1
    end
    
    -- Handle different encoding types
    if encodingType == 1 then
        -- Compressed data - pass directly to SaveAssignments
        success = self:SaveAssignments(result, importString, syncTimestamp or nil, isSync)
    else
        -- Legacy format - decode the string
        success = self:DecodeLegacyImportString(result, importString, isSync, syncTimestamp)
    end
    
    -- Show OSD if it was visible before
    if osdWasVisible and success and self.OSD then
        self.OSD:Show()
    end
    
    -- Update minimap icon if import was successful
    if success and self.Minimap and self.Minimap.SetHasData then
        self.Minimap:SetHasData(true)
    end
    
    -- Refresh UI views if import was successful
    if success then
        -- Create main frame if it doesn't exist
        if not self.mainFrame then
            self:CreateMainFrame()
        end
        
        -- Reset the UI to main view
        self:Debug("ui", "Resetting UI to main view after import")
        self:ShowMainView()
    end
    
    return success
end

-- Function to load example data and show main view - called by the Example button
function TWRA:LoadExampleDataAndShow()
    self:Debug("ui", "Loading example data and showing main view")
    
    -- Clear any existing data first
    if self.ClearData then
        self:ClearData()
        self:Debug("data", "Cleared existing data")
    end
    
    -- Ensure we don't have a stale custom navigation function
    self.NavigateToSectionExample = nil
    
    -- Store the original NavigateToSection function
    local originalNavigateToSection = self.NavigateToSection
    
    -- Setup data and flags for example mode
    self.usingExampleData = true
    TWRA_CompressedAssignments = nil
    self:Debug("data", "Cleared TWRA_CompressedAssignments for example data")
    
    -- Temporarily disable OSD from showing on navigation change
    local originalShowOnNavigation = nil
    if self.OSD then
        originalShowOnNavigation = self.OSD.showOnNavigation
        self.OSD.showOnNavigation = false
        self:Debug("osd", "Temporarily disabled OSD showOnNavigation")
    end
    
    -- Directly assign the example data with proper structure
    TWRA_Assignments = {
        data = self.EXAMPLE_DATA.data,
        timestamp = 0,      -- Use 0 for example data timestamp
        currentSection = 1, -- Start at first section
        currentSectionName = "Welcome",
        version = 2,        -- Use version 2 format
        isExample = true,   -- Mark as example data
        needsProcessing = false  -- Mark as already processed to avoid compression check
    }
    
    -- Mark sections as not needing compression or processing
    if TWRA_Assignments.data then
        for idx, section in pairs(TWRA_Assignments.data) do
            if type(idx) == "number" and section then
                section.missingCompressedData = false
                section.needsProcessing = false
            end
        end
    end
    
    -- CRITICAL: Force complete rebuilding of navigation
    if self.RebuildNavigation then
        self:Debug("nav", "Rebuilding navigation from example data")
        self:RebuildNavigation()
    else
        self:Debug("error", "RebuildNavigation function not available")
    end
    
    -- Ensure UI state is correct by creating the main frame if it doesn't exist
    if not self.mainFrame then
        self:CreateMainFrame()
        self:Debug("ui", "Created main frame for example data")
    end
    
    -- Process player-specific information for relevant highlighting
    if self.ProcessPlayerInfo then
        self:Debug("data", "Processing player-relevant information for example data")
        self:ProcessPlayerInfo()
    else
        self:Debug("error", "ProcessPlayerInfo function not available")
    end
    
    -- Create our safe example navigation function
    self.NavigateToSectionExample = function(self, index, source)
        -- Ensure source is a string to prevent nil concatenation errors
        source = source or "fromExample"
        
        -- Ensure index is a number, not a string
        if type(index) == "string" then
            self:Debug("nav", "Converting string index to number: " .. index)
            -- Try to find the section with this name
            if self.navigation and self.navigation.handlers then
                for i, name in ipairs(self.navigation.handlers) do
                    if name == index then
                        index = i
                        break
                    end
                end
            end
            
            -- If we still have a string, it's invalid
            if type(index) == "string" then
                self:Debug("error", "No section found with name: " .. index)
                return false
            end
        end
        
        self:Debug("nav", "Custom example NavigateToSection called: index=" .. index .. ", source=" .. source)
        
        -- Update navigation tracking variables
        if self.navigation then
            self.navigation.currentIndex = index
        end
        
        -- Get the section name
        local sectionName = nil
        if self.navigation and self.navigation.handlers and self.navigation.handlers[index] then
            sectionName = self.navigation.handlers[index]
        else
            self:Debug("error", "No section name found for index: " .. index)
            return false
        end
        
        -- Update TWRA_Assignments
        TWRA_Assignments.currentSection = index
        TWRA_Assignments.currentSectionName = sectionName
        
        -- Update UI elements
        if self.navigation.handlerText then
            self.navigation.handlerText:SetText(sectionName)
        end
        
        if self.navigation.menuButton and self.navigation.menuButton.text then
            self.navigation.menuButton.text:SetText(sectionName)
        end
        
        -- CRITICAL: Force display update for the section
        if self.FilterAndDisplayHandler then
            self:Debug("nav", "Directly calling FilterAndDisplayHandler for example section: " .. sectionName)
            self:FilterAndDisplayHandler(sectionName)
        end
        
        -- Refresh the assignment table
        if self.RefreshAssignmentTable then
            self:RefreshAssignmentTable()
        end
        
        return true
    end
    
    -- Create hook for NavigateToSection specifically for example data
    -- This will be the active navigation function during example data mode
    self.NavigateToSection = function(self, index, source)
        -- Forward to our safety-enhanced example function
        if self.usingExampleData and self.NavigateToSectionExample then
            return self:NavigateToSectionExample(index, source)
        else
            -- Ensure source is a string even for the original function
            source = source or "unknown"
            return originalNavigateToSection(self, index, source)
        end
    end
    
    -- Register an addon cleanup function to restore original behavior
    -- This is essential for proper cleanup when addon is reloaded or disabled
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("PLAYER_LOGOUT")
    frame:SetScript("OnEvent", function()
        -- Restore original NavigateToSection function on logout/reload
        if self.usingExampleData then
            self:Debug("nav", "Restoring original NavigateToSection function on logout/reload")
            self.NavigateToSection = originalNavigateToSection
            self.NavigateToSectionExample = nil
            self.usingExampleData = false
        end
    end)
    
    -- Ensure main frame is shown
    if self.mainFrame and not self.mainFrame:IsShown() then
        -- Use ToggleMainFrame to ensure proper visibility handling
        self:ToggleMainFrame()
        self:Debug("ui", "Showing main frame for example data")
    end
    
    -- Switch to main view if we're in options view
    if self.currentView == "options" then
        self:ShowMainView()
        self:Debug("ui", "Switched from options to main view for example data")
    end
    
    -- IMPORTANT: Navigate to first section to properly initialize all UI elements
    if self.navigation and self.navigation.handlers and table.getn(self.navigation.handlers) > 0 then
        self:Debug("nav", "Navigating to first section")
        self:NavigateToSection(1, "fromExample")
        
        -- Update the dropdown button text to match the current section
        if self.navigation.menuButton and self.navigation.menuButton.text and 
           self.navigation.handlers[1] then
            self.navigation.menuButton.text:SetText(self.navigation.handlers[1])
        end
    end
    
    -- Make sure OSD is not showing after loading example data
    if self.OSD and self.OSD.isVisible then
        self:Debug("osd", "Hiding OSD after loading example data")
        self:HideOSD() -- Use the proper method instead of trying to call :Hide() directly
    end
    
    -- Explicitly refresh the assignment table to ensure data is displayed
    if self.RefreshAssignmentTable then
        self:RefreshAssignmentTable()
        self:Debug("ui", "Refreshed assignment table")
    else
        self:Debug("error", "RefreshAssignmentTable function not available")
    end
    
    -- Set up a timer to restore the original NavigateToSection function
    self:ScheduleTimer(function()
        -- Only restore if we're still in example mode
        if self.usingExampleData then
            self:Debug("nav", "Restoring original NavigateToSection function")
            self.NavigateToSection = originalNavigateToSection
            self.NavigateToSectionExample = nil
            self.usingExampleData = false
        end
    end, 300) -- Restore after 5 minutes instead of 1 hour
    
    -- Restore the original OSD showOnNavigation setting
    if self.OSD and originalShowOnNavigation ~= nil then
        self.OSD.showOnNavigation = originalShowOnNavigation
        self:Debug("osd", "Restored OSD showOnNavigation to " .. tostring(originalShowOnNavigation))
    end
    
    -- Show user feedback
    DEFAULT_CHAT_FRAME:AddMessage("|cFF33FF99TWRA:|r Example data loaded!")
    
    return true
end

-- Custom navigation function specifically for example data
-- This follows the pattern used in HandleBulkStructureCommand but simplified
function TWRA:CustomNavigateSection(index, sectionName, source)
    self:Debug("nav", "CustomNavigateSection called for section " .. index .. ": " .. sectionName)
    
    -- Update tracking variables
    if self.navigation then
        self.navigation.currentIndex = index
    end
    
    -- Update assignments current section
    TWRA_Assignments.currentSection = index
    TWRA_Assignments.currentSectionName = sectionName
    
    -- Update UI text elements
    if self.navigation and self.navigation.handlerText then
        self.navigation.handlerText:SetText(sectionName)
    end
    
    if self.navigation and self.navigation.menuButton and self.navigation.menuButton.text then
        self.navigation.menuButton.text:SetText(sectionName)
    end
    
    -- CRITICAL: Direct display update - this is what was missing before
    if self.FilterAndDisplayHandler then
        self:Debug("nav", "Directly calling FilterAndDisplayHandler for section: " .. sectionName)
        self:FilterAndDisplayHandler(sectionName)
    else
        self:Debug("error", "FilterAndDisplayHandler not available")
    end
    
    -- Refresh assignment table to ensure data is properly displayed
    if self.RefreshAssignmentTable then
        self:RefreshAssignmentTable()
    end
    
    -- Update OSD if needed (following the SyncHandlers pattern)
    if self.RebuildOSDIfVisible then
        self:RebuildOSDIfVisible()
    end
    
    -- Clear any pending sections (similar to SyncHandlers)
    if self.SYNC and self.SYNC.pendingSection then
        self.SYNC.pendingSection = nil
    end
    
    -- This is a complete navigation operation
    self:Debug("nav", "CustomNavigateSection complete for " .. sectionName)
    
    return true
end

-- Function to check if data is example data
function TWRA:IsExampleData(data)
    self:Debug("error", "TWRA:IsExampleData called from Example.lua")
    if not data then return false end
    
    -- Check for explicit example flag
    if data.isExample then
        return true
    end
    
    -- Check new format structure
    if type(data) == "table" and data.data and type(data.data) == "table" then
        for _, section in pairs(data.data) do
            if section["Section Name"] == "Welcome" then
                -- Look for our welcome notes in metadata
                if section["Section Metadata"] and section["Section Metadata"]["Note"] then
                    for _, note in ipairs(section["Section Metadata"]["Note"]) do
                        if string.find(note or "", "import your own assignments") then
                            return true
                        end
                    end
                end
            end
        end
    end
    
    return false
end