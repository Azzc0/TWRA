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
                    
                    -- Navigate to this section
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

-- Function to load example data and show main view - called by the Example button
function TWRA:LoadExampleDataAndShow()
    -- Load the example data
    if self:LoadExampleData() then
        -- Ensure UI state is correct by creating the main frame if it doesn't exist
        if not self.mainFrame then
            self:CreateMainFrame()
            self:Debug("ui", "Created main frame during LoadExampleDataAndShow")
        end
        
        -- Force complete refresh of dropdown menu
        if self.navigation and self.navigation.dropdownMenu then
            self:Debug("nav", "Force refreshing dropdown menu during LoadExampleDataAndShow")
            
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
                        
                        -- Navigate to this section
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

        -- Switch to main view if in options
        if self.currentView == "options" then
            self:ShowMainView()
        else
            -- If already in main view, force complete refresh of the UI
            -- First ensure we're showing the right page content
            if self.FilterAndDisplayHandler and self.navigation and 
               self.navigation.handlers and table.getn(self.navigation.handlers) > 0 then
                local sectionName = self.navigation.handlers[self.navigation.currentIndex]
                self:FilterAndDisplayHandler(sectionName)
                
                -- Make sure all UI elements are properly updated
                if self.navigation.handlerText then
                    self.navigation.handlerText:SetText(sectionName)
                end
                
                -- -- Show the frame if it's not already shown
                -- if self.mainFrame and not self.mainFrame:IsShown() then
                --     self.mainFrame:Show()
                -- end
                
                self:Debug("ui", "Forced refresh of main view content")
            end
        end
        
        -- Make sure OSD is not showing after loading example data
        if self.OSD and self.OSD.isVisible then
            self:HideOSD()
            self:Debug("osd", "Explicitly hiding OSD after loading example data")
        end
        
        -- Show user feedback
        DEFAULT_CHAT_FRAME:AddMessage("TWRA: Example data loaded!")
        
        return true
    end
    
    return false
end

-- Function to check if data is example data
function TWRA:IsExampleData(data)
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