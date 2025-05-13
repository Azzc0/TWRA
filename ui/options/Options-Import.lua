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
                self:ShowMainView()
            end
        else
            -- Import failed
            self:Debug("error", "Failed to import data - invalid format")
        end
    end)
    
    -- Example button behavior
    exampleBtn:SetScript("OnClick", function()
        self:LoadExampleDataAndShow()
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
    
    return rightColumn
end