-- TWRA Options-Import Module
-- Right column of the options panel: Import functionality
TWRA = TWRA or {}

-- Load this options component
function TWRA:LoadOptionsImport()
    self:Debug("general", "Loading Import options component")
    
    -- Register this component in the options system
    if not self.optionsComponents then
        self.optionsComponents = {}
    end
    
    self.optionsComponents.import = {
        name = "Import",
        create = function(column) return self:CreateOptionsImportColumn(column) end
    }
end

-- Direct import function for processing Base64 import strings
function TWRA:DirectImport(importString)
    -- Check that importString is actually a string
    if type(importString) ~= "string" then
        self:Debug("error", "DirectImport called with invalid type: " .. type(importString))
        return false
    end
    
    self:Debug("data", "DirectImport called with string length: " .. string.len(importString))
    
    -- Ensure we have a proper import string
    if not importString or importString == "" then
        self:Debug("error", "Empty import string provided")
        return false
    end
    
    -- Remove any formatting characters that might have been added
    importString = string.gsub(importString, "\n", "")
    importString = string.gsub(importString, "\r", "")
    importString = string.gsub(importString, " ", "")
    
    -- Check if the import string is valid Lua code (starts with TWRA_ImportString=)
    if string.sub(importString, 1, 17) == "TWRA_ImportString=" then
        self:Debug("data", "Processing direct Lua import string")
        
        -- Try to load the string as Lua code
        local func, err = loadstring(importString)
        if not func then
            self:Debug("error", "Failed to parse import string: " .. (err or "Unknown error"))
            return false
        end
        
        -- Execute the loaded function to define TWRA_ImportString
        local success, result = pcall(func)
        if not success then
            self:Debug("error", "Failed to execute import string: " .. (result or "Unknown error"))
            return false
        end
        
        -- Check if TWRA_ImportString was defined correctly
        if not TWRA_ImportString or not TWRA_ImportString.data then
            self:Debug("error", "Import string did not define valid TWRA_ImportString with data")
            return false
        end
        
        -- Store the imported data in TWRA_Assignments
        TWRA_Assignments = TWRA_Assignments or {}
        TWRA_Assignments.data = TWRA_ImportString.data
        TWRA_Assignments.version = 2
        TWRA_Assignments.timestamp = time()
        TWRA_Assignments.currentSection = 1
        
        -- Clear TWRA_ImportString to free memory
        TWRA_ImportString = nil
        
        self:Debug("data", "Direct Lua import successful")
        return true
    else
        -- Try Base64 import via the decode function if available
        if self.DecodeBase64 then
            -- First ensure we have clean Base64 (remove any unwanted characters)
            importString = string.gsub(importString, "[^A-Za-z0-9+/=]", "")
            
            self:Debug("data", "Processing Base64 import string (length: " .. string.len(importString) .. ")")
            
            -- Check if we need to call HandleImportedData or if we'll decode directly
            if self.HandleBase64Import then
                -- Use the dedicated handler function with better error handling
                local success, errorMessage = self:HandleBase64Import(importString)
                if not success then
                    self:Debug("error", "Base64 import failed: " .. (errorMessage or "Unknown error"))
                end
                return success
            else
                -- Try to decode and process directly - add more debug messages
                self:Debug("data", "Decoding Base64 string directly...")
                local decodedString = self:DecodeBase64(importString)
                
                if not decodedString then
                    self:Debug("error", "Failed to decode Base64 string - decoding returned nil")
                    return false
                end
                
                self:Debug("data", "Base64 decoded successfully, string length: " .. string.len(decodedString))
                
                -- Try to load the decoded string as Lua code - add more debug for parsing
                self:Debug("data", "Parsing decoded Lua code...")
                
                -- -- Additional type check before using loadstring (which requires a string)
                -- if type(decodedString) ~= "string" then
                --     self:Debug("error", "Cannot loadstring on non-string data type: " .. type(decodedString))
                --     return false
                -- end
                
                local func, err = loadstring(decodedString)
                if not func then
                    self:Debug("error", "Failed to parse decoded Base64: " .. (err or "Unknown error"))
                    return false
                end
                
                -- -- Execute the loaded function to define TWRA_ImportString - add more debug
                -- self:Debug("data", "Executing parsed Lua code...")
                -- local success, result = pcall(func)
                -- if not success then
                --     self:Debug("error", "Failed to execute decoded Base64: " .. (result or "Unknown error"))
                --     return false
                -- end
                
                -- Check if TWRA_ImportString was defined correctly - add more debug
                if not TWRA_ImportString then
                    self:Debug("error", "Decoded Base64 did not define TWRA_ImportString")
                    return false
                end
                
                if not TWRA_ImportString.data then
                    self:Debug("error", "TWRA_ImportString defined but missing 'data' field")
                    return false
                end
                
                self:Debug("data", "TWRA_ImportString parsed successfully with " .. 
                  (TWRA_ImportString.data and table.getn(TWRA_ImportString.data) or 0) .. " sections")
                
                -- Store the imported data in TWRA_Assignments
                TWRA_Assignments = TWRA_Assignments or {}
                TWRA_Assignments.data = TWRA_ImportString.data
                TWRA_Assignments.version = 2
                TWRA_Assignments.timestamp = time()
                TWRA_Assignments.currentSection = 1
                
                -- Clear TWRA_ImportString to free memory
                TWRA_ImportString = nil
                
                self:Debug("data", "Base64 import successful")
                return true
            end
        else
            self:Debug("error", "DecodeBase64 function not available")
            return false
        end
    end
end

-- Create the Import options column content
function TWRA:CreateOptionsImportColumn(rightColumn)
    self:Debug("ui", "Creating Import options column")
    
    -- Column title
    local importTitle = rightColumn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    importTitle:SetPoint("TOPLEFT", rightColumn, "TOPLEFT", 0, 0)
    importTitle:SetText("Import Assignments")
    table.insert(self.optionsElements, importTitle)
    
    -- Create import box container
    local container = CreateFrame("Frame", nil, rightColumn)
    container:SetWidth(220)
    container:SetHeight(160)
    container:SetPoint("TOPLEFT", importTitle, "BOTTOMLEFT", 0, -10)
    table.insert(self.optionsElements, container)
    
    -- Create a simple ScrollFrame with no visible scrollbar
    local scrollFrame = CreateFrame("ScrollFrame", nil, container)
    scrollFrame:SetAllPoints(container)
    table.insert(self.optionsElements, scrollFrame)
    
    -- Create the edit box
    local importBox = CreateFrame("EditBox", nil, scrollFrame)
    importBox:SetWidth(220)
    importBox:SetFontObject(ChatFontNormal)
    importBox:SetMultiLine(true)
    importBox:SetAutoFocus(false)
    importBox:EnableMouse(true)
    importBox:SetScript("OnEscapePressed", function() importBox:ClearFocus() end)
    scrollFrame:SetScrollChild(importBox)
    table.insert(self.optionsElements, importBox)
    
    -- Add backdrop to container
    local scrollBg = CreateFrame("Frame", nil, container)
    scrollBg:SetPoint("TOPLEFT", -5, 5)
    scrollBg:SetPoint("BOTTOMRIGHT", 5, -5)
    scrollBg:SetBackdrop({
        bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    scrollBg:SetBackdropColor(0, 0, 0, 0.6)
    table.insert(self.optionsElements, scrollBg)
    
    -- Create import buttons
    local importBtn = CreateFrame("Button", nil, rightColumn, "UIPanelButtonTemplate")
    importBtn:SetWidth(80)
    importBtn:SetHeight(22)
    importBtn:SetPoint("TOPLEFT", container, "BOTTOMLEFT", 0, -10)
    importBtn:SetText("Import")
    table.insert(self.optionsElements, importBtn)
    
    local clearBtn = CreateFrame("Button", nil, rightColumn, "UIPanelButtonTemplate")
    clearBtn:SetWidth(70)
    clearBtn:SetHeight(22)
    clearBtn:SetPoint("LEFT", importBtn, "RIGHT", 5, 0)
    clearBtn:SetText("Clear")
    table.insert(self.optionsElements, clearBtn)
    
    local exampleBtn = CreateFrame("Button", nil, rightColumn, "UIPanelButtonTemplate")
    exampleBtn:SetWidth(70)
    exampleBtn:SetHeight(22)
    exampleBtn:SetPoint("LEFT", clearBtn, "RIGHT", 5, 0)
    exampleBtn:SetText("Example")
    table.insert(self.optionsElements, exampleBtn)
    
    -- ====================== WIRE UP BEHAVIORS ======================
    
    -- Import button behavior
    importBtn:SetScript("OnClick", function()
        local importText = importBox:GetText()
        if not importText or importText == "" then
            self:Debug("data", "No data to import")
            return
        end
        
        self:Debug("data", "Importing data")
                
        -- Import using the new format
        local success = self:DirectImport(importText)
        
        if success then
            -- Clear the import box and remove focus
            importBox:SetText("")
            importBox:ClearFocus()
            
            -- CRITICAL: Rebuild navigation immediately with the new data
            if self.RebuildNavigation then
                self:Debug("data", "Rebuilding navigation with imported data")
                self:RebuildNavigation()
            else
                self:Debug("error", "RebuildNavigation function not available!")
            end
            
            -- CRITICAL: Process each section to explicitly establish Group Rows metadata
            -- This ensures Group Rows are properly identified
            if TWRA_Assignments and TWRA_Assignments.data then
                self:Debug("data", "Explicitly establishing Group Rows metadata for all sections")
                local sectionsWithGroupRows = 0
                local totalGroupRows = 0
                
                for sectionIdx, section in pairs(TWRA_Assignments.data) do
                    if type(section) == "table" and section["Section Rows"] then
                        -- Initialize Section Metadata if not present
                        section["Section Metadata"] = section["Section Metadata"] or {}
                        
                        -- Explicitly force generation of Group Rows metadata
                        section["Section Metadata"]["Group Rows"] = self:GetAllGroupRowsForSection(section)
                        
                        local groupRowCount = table.getn(section["Section Metadata"]["Group Rows"] or {})
                        totalGroupRows = totalGroupRows + groupRowCount
                        
                        if groupRowCount > 0 then
                            sectionsWithGroupRows = sectionsWithGroupRows + 1
                        end
                        
                        self:Debug("data", "Section '" .. (section["Section Name"] or tostring(sectionIdx)) .. 
                                 "': Established " .. groupRowCount .. " group rows")
                    end
                end
                
                self:Debug("data", "Established Group Rows metadata for " .. sectionsWithGroupRows .. 
                         " sections with a total of " .. totalGroupRows .. " group rows")
            end
            
            -- Apply ProcessImportedData for any other metadata processing
            if self.ProcessImportedData then
                self:Debug("data", "Applying ProcessImportedData for additional metadata processing")
                TWRA_Assignments.data = self:ProcessImportedData(TWRA_Assignments)
            end
            
            -- CRITICAL: Store compressed data immediately after establishing metadata
            -- but BEFORE processing player-specific info
            if self.StoreCompressedData then
                self:Debug("data", "Storing compressed data with established metadata")
                self:StoreCompressedData()
            elseif self.StoreSegmentedData then
                self:Debug("data", "Storing segmented data with established metadata")
                self:StoreSegmentedData()
            end
            
            -- Verify metadata was properly stored in compressed data
            if TWRA_Assignments and TWRA_Assignments.data then
                local groupRowsCheck = 0
                for sectionIdx, section in pairs(TWRA_Assignments.data) do
                    if type(section) == "table" and section["Section Metadata"] and 
                       section["Section Metadata"]["Group Rows"] and 
                       table.getn(section["Section Metadata"]["Group Rows"]) > 0 then
                        groupRowsCheck = groupRowsCheck + 1
                    end
                end
                self:Debug("data", "Verification: " .. groupRowsCheck .. " sections have Group Rows metadata after compression")
            end
            
            -- NOW process player info (this is client-specific and should happen after compression)
            if self.ProcessPlayerInfo then
                self:Debug("data", "Processing player-specific info after import")
                -- Process player info with error handling
                pcall(function() self:ProcessPlayerInfo() end)
            end
            
            -- Update OSD if it's showing
            if self.OSD and self.OSD.isVisible and self.UpdateOSDContent then
                self:UpdateOSDContent()
            end
                        
            -- Switch to main view
            if self.ShowMainView then
                self:Debug("data", "Switching to main view after successful import")
                self:ShowMainView()
                
                -- Make sure the view is actually changed
                self:ScheduleTimer(function()
                    if self.currentView ~= "main" then
                        self:Debug("error", "Failed to switch to main view - forcing view change")
                        if self.ShowMainView then
                            self:ShowMainView()
                        end
                    end
                end, 0.1)
            else
                self:Debug("error", "ShowMainView function not available!")
            end
        else
            -- Import failed
            self:Debug("error", "Failed to import data - invalid format")
        end
    end)
    
    -- Example button behavior with tooltip
    exampleBtn:SetScript("OnClick", function()
        self:LoadExampleDataAndShow()
    end)
    
    -- Add tooltip to explain what the Example button does
    exampleBtn:SetScript("OnEnter", function()
        GameTooltip:SetOwner(exampleBtn, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Load Example Data")
        GameTooltip:AddLine("Loads the example data and removes synced assignment information", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    
    exampleBtn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    -- Clear button behavior
    clearBtn:SetScript("OnClick", function()
        -- Clear the import box content
        importBox:SetText("")
        -- Remove focus from the import box
        importBox:ClearFocus()
        -- Debug log
        self:Debug("ui", "Import box cleared")
    end)
    
    -- Add an extra cleanup step when the options panel is shown
    -- This helps eliminate any stray highlights or tooltips
    local function CleanupHighlightsAndTooltips()
        -- Hide GameTooltip if it's showing
        GameTooltip:Hide()
        
        -- Forcefully disable any row click frames that might be active
        if self.rowFrames then
            for i, row in pairs(self.rowFrames) do
                if row.clickFrame then
                    row.clickFrame:Hide()
                    row.clickFrame:EnableMouse(false)
                    self:Debug("ui", "Options: Disabling clickFrame for row " .. i)
                end
            end
        end
        
        -- Explicitly hide all highlights from the pool again
        if self.highlightPool then
            for _, highlight in ipairs(self.highlightPool) do
                highlight:Hide()
                highlight:ClearAllPoints()
                self:Debug("ui", "Options: Explicitly hiding row highlight")
            end
        end
        
        -- Hide mouseover highlight if it exists
        if self.mouseoverHighlight then
            self.mouseoverHighlight:Hide()
            self.mouseoverHighlight:ClearAllPoints()
            self:Debug("ui", "Options: Hiding mouseover highlight")
        end
    end
    
    -- Call cleanup immediately
    CleanupHighlightsAndTooltips()
    
    -- Schedule another cleanup after a short delay for safety
    self:ScheduleTimer(CleanupHighlightsAndTooltips, 0.1)
    
    return rightColumn
end
