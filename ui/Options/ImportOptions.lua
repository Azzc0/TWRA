-- TWRA Import Options Module
TWRA = TWRA or {}
TWRA.OPTIONS = TWRA.OPTIONS or {}

-- Create Import/Export options panel
function TWRA.OPTIONS:CreateImportOptions(parent)
    -- Better parent handling using the utility function
    if not parent then
        parent = TWRA.UI:GetOptionsContainer()
        
        if not parent then
            TWRA:Debug("error", "No parent frame provided for ImportOptions")
            -- Create a minimal placeholder frame so the function doesn't fail
            local placeholder = CreateFrame("Frame")
            placeholder:Hide()
            return placeholder
        end
    end
    
    -- Make sure parent is valid and has GetWidth
    if not parent.GetWidth then
        TWRA:Debug("error", "Invalid parent for ImportOptions")
        local placeholder = CreateFrame("Frame")
        placeholder:Hide()
        return placeholder
    end
    
    -- Create a properly anchored container frame
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetAllPoints(parent)
    
    -- Calculate available width, accounting for possible scrollbars
    local availableWidth = parent:GetWidth() - 10
    
    -- Import help text with proper spacing from top
    local importHelp = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    importHelp:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -10) -- Position from top-left with proper margin
    importHelp:SetWidth(220)
    importHelp:SetJustifyH("LEFT")
    importHelp:SetText("Paste assignment data below and click Import, or click Example Data to load sample assignments.")
    
    -- Create a backdrop frame for the import box with proper height
    local importBoxFrame = CreateFrame("Frame", nil, frame)
    importBoxFrame:SetPoint("TOPLEFT", importHelp, "BOTTOMLEFT", 0, -10)
    importBoxFrame:SetWidth(math.min(230, availableWidth - 10))
    importBoxFrame:SetHeight(100)  -- Height that fits in the panel
    importBoxFrame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    
    -- Create the actual edit box inside the backdrop frame
    local importBox = CreateFrame("EditBox", nil, importBoxFrame)
    importBox:SetPoint("TOPLEFT", importBoxFrame, "TOPLEFT", 8, -8)
    importBox:SetPoint("BOTTOMRIGHT", importBoxFrame, "BOTTOMRIGHT", -8, 8)
    importBox:SetMultiLine(true)
    importBox:SetAutoFocus(false)
    importBox:EnableMouse(true)
    importBox:SetFontObject(ChatFontNormal)
    importBox:SetText("")
    importBox:SetMaxLetters(9999)
    importBox:SetScript("OnEscapePressed", function() this:ClearFocus() end)
    importBox:SetScript("OnTabPressed", function() this:ClearFocus() end)
    
    -- Create import and clear buttons with proper vertical spacing
    local importBtnsRow = CreateFrame("Frame", nil, frame)
    importBtnsRow:SetWidth(230)
    importBtnsRow:SetHeight(25)
    importBtnsRow:SetPoint("TOPLEFT", importBoxFrame, "BOTTOMLEFT", 0, -10)
    
    -- Add import button
    local importBtn = CreateFrame("Button", nil, importBtnsRow, "UIPanelButtonTemplate")
    importBtn:SetWidth(math.min(110, (availableWidth - 20)/2))
    importBtn:SetHeight(25)
    importBtn:SetPoint("LEFT", importBtnsRow, "LEFT", 0, 0)
    importBtn:SetText("Import")
    
    importBtn:SetScript("OnClick", function()
        local importText = importBox:GetText()
        if importText and importText ~= "" then
            -- Call import function
            if TWRA.ImportData then
                local success = TWRA:ImportData(importText)
                if success then
                    TWRA:Debug("data", "Assignments imported successfully!")
                    importBox:SetText("")
                    TWRA:ShowMainView()
                    TWRA.optionsButton:SetText("Options")
                else
                    TWRA:Debug("error", "Import failed. Please check format.")
                end
            else
                TWRA:Debug("error", "ImportData function not found!")
            end
        else
            TWRA:Debug("error", "No data to import!")
        end
    end)
    
    -- Add clear button
    local clearBtn = CreateFrame("Button", nil, importBtnsRow, "UIPanelButtonTemplate")
    clearBtn:SetWidth(math.min(110, (availableWidth - 20)/2))
    clearBtn:SetHeight(25)
    clearBtn:SetPoint("LEFT", importBtn, "RIGHT", 10, 0)
    clearBtn:SetText("Clear")
    
    clearBtn:SetScript("OnClick", function()
        importBox:SetText("")
        TWRA:Debug("data", "Import text cleared")
    end)
    
    -- Add example data button
    local exampleBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    exampleBtn:SetWidth(math.min(230, availableWidth - 10))
    exampleBtn:SetHeight(25)
    exampleBtn:SetPoint("TOPLEFT", importBtnsRow, "BOTTOMLEFT", 0, -10)
    exampleBtn:SetText("Load Example Data")
    
    exampleBtn:SetScript("OnClick", function()
        if TWRA.LoadExampleData then
            if TWRA:LoadExampleData() then
                TWRA:Debug("data", "Example data loaded successfully!")
                TWRA:ShowMainView()
                TWRA.optionsButton:SetText("Options")
            else
                TWRA:Debug("error", "Failed to load example data.")
            end
        else
            TWRA:Debug("error", "LoadExampleData function not found!")
        end
    end)
    
    -- Add export section with separator
    local exportSeparator = frame:CreateTexture(nil, "BACKGROUND")
    exportSeparator:SetTexture(0.3, 0.3, 0.3, 0.8)
    exportSeparator:SetHeight(1)
    exportSeparator:SetPoint("TOPLEFT", exampleBtn, "BOTTOMLEFT", 0, -15)
    exportSeparator:SetPoint("TOPRIGHT", exampleBtn, "BOTTOMRIGHT", 0, -15)
    
    -- Export title
    local exportTitle = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    exportTitle:SetPoint("TOPLEFT", exportSeparator, "BOTTOMLEFT", 0, -10)
    exportTitle:SetText("Export Current Assignments")
    
    -- Add export button
    local exportBtn = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    exportBtn:SetWidth(math.min(230, availableWidth - 10))
    exportBtn:SetHeight(25)
    exportBtn:SetPoint("TOPLEFT", exportTitle, "BOTTOMLEFT", 0, -10)
    exportBtn:SetText("Copy to Clipboard")
    
    -- Function to safely check if a table is empty in WoW Classic Lua
    local function tableIsEmpty(t)
        if t == nil then return true end
        for _, _ in pairs(t) do
            return false
        end
        return true
    end

    exportBtn:SetScript("OnClick", function()
        if TWRA.ExportData then
            local exportText = TWRA:ExportData()
            if exportText and exportText ~= "" and not tableIsEmpty(exportText) then
                importBox:SetText(exportText)
                
                -- Safe cursor position and highlight
                TWRA.UI:SafeSetCursorPosition(importBox, 0)
                TWRA.UI:SafeHighlightText(importBox)
                
                importBox:SetFocus()
                TWRA:Debug("data", "Assignments exported! Press Ctrl+C to copy.")
            else
                TWRA:Debug("error", "No assignments data to export.")
            end
        else
            TWRA:Debug("error", "ExportData function not found!")
        end
    end)
    
    return frame
end
