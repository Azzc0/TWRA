-- Turtle WoW Raid Assignments (TWRA)
-- Encounter Map functionality

TWRA = TWRA or {}

-- Initialize the encounter map system
function TWRA:InitEncounterMap()
    self:Debug("map", "Initializing encounter map system")
    
    -- Create the encounter map frame
    self:CreateEncounterMapFrame()
    
    -- Initialize sample map data
    self:InitMapData()
    
    -- Mark as initialized, but don't show the map
    self.encounterMapInitialized = true
    self.encounterMapIsVisible = false
    self.encounterMapPermanent = false
    
    self:Debug("map", "Encounter map system initialized and set to hidden state")
end

-- Create the encounter map frame
function TWRA:CreateEncounterMapFrame()
    -- Check if frame already exists
    if self.encounterMapFrame then
        self:Debug("map", "Encounter map frame already exists")
        return
    end
    
    self:Debug("map", "Creating encounter map frame")
    
    -- Create main frame with tooltip-like appearance
    local frame = CreateFrame("Frame", "TWRAEncounterMapFrame", UIParent)
    frame:SetWidth(600)
    frame:SetHeight(400)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetFrameStrata("DIALOG")
    
    -- Make frame movable by click and drag anywhere
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    
    -- Add dragging functionality - always allow dragging regardless of permanent mode
    frame:SetScript("OnDragStart", function()
        this:StartMoving()
    end)
    
    frame:SetScript("OnDragStop", function()
        this:StopMovingOrSizing()
        
        -- Save position for future sessions
        local point, _, relativePoint, xOfs, yOfs = this:GetPoint()
        if not TWRA_SavedVariables.options then
            TWRA_SavedVariables.options = {}
        end
        if not TWRA_SavedVariables.options.encounterMap then
            TWRA_SavedVariables.options.encounterMap = {}
        end
        
        TWRA_SavedVariables.options.encounterMap.point = point
        TWRA_SavedVariables.options.encounterMap.relativePoint = relativePoint
        TWRA_SavedVariables.options.encounterMap.xOfs = xOfs
        TWRA_SavedVariables.options.encounterMap.yOfs = yOfs
        
        TWRA:Debug("map", "Saved map position: " .. point .. ", " .. xOfs .. ", " .. yOfs)
    end)
    
    -- Background and border (tooltip style)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    
    -- Title text (small, like tooltip)
    frame.title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.title:SetPoint("TOP", frame, "TOP", 0, -10)
    frame.title:SetText("Encounter Map")
    
    -- Close button in top right corner
    frame.closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    frame.closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -2)
    frame.closeButton:SetScript("OnClick", function() 
        TWRA:HideEncounterMap()
    end)
    
    -- Create map container (space for the image)
    frame.mapContainer = CreateFrame("Frame", nil, frame)
    frame.mapContainer:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -30)
    frame.mapContainer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 40)
    
    -- Create texture for map image
    frame.mapTexture = frame.mapContainer:CreateTexture(nil, "ARTWORK")
    frame.mapTexture:SetAllPoints(frame.mapContainer)
    frame.mapTexture:SetTexCoord(0, 1, 0, 1)
    
    -- Create "no map" message
    frame.noMapText = frame.mapContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.noMapText:SetPoint("CENTER", frame.mapContainer, "CENTER")
    frame.noMapText:SetText("No map available for this encounter")
    frame.noMapText:Hide()
    
    -- Navigation area at the bottom
    frame.navContainer = CreateFrame("Frame", nil, frame)
    frame.navContainer:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 10, 10)
    frame.navContainer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 30)
    frame.navContainer:SetHeight(20)
    
    -- Left navigation button
    frame.prevButton = CreateFrame("Button", nil, frame.navContainer)
    frame.prevButton:SetWidth(20)
    frame.prevButton:SetHeight(20)
    frame.prevButton:SetPoint("LEFT", frame.navContainer, "LEFT", 0, 0)
    
    -- Set left button textures (Normal, Pushed, Disabled)
    frame.prevButton:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up")
    frame.prevButton:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down")
    frame.prevButton:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Disabled")
    
    -- Right navigation button
    frame.nextButton = CreateFrame("Button", nil, frame.navContainer)
    frame.nextButton:SetWidth(20)
    frame.nextButton:SetHeight(20)
    frame.nextButton:SetPoint("RIGHT", frame.navContainer, "RIGHT", 0, 0)
    
    -- Set right button textures (Normal, Pushed, Disabled)
    frame.nextButton:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
    frame.nextButton:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down")
    frame.nextButton:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Disabled")
    
    -- Page indicator text (e.g., "1 of 2")
    frame.pageText = frame.navContainer:CreateFontString(nil, "OVERLAY", "GameFontSmall")
    frame.pageText:SetPoint("CENTER", frame.navContainer, "CENTER")
    frame.pageText:SetText("1 of 1")
    
    -- Add click handlers for navigation buttons
    frame.prevButton:SetScript("OnClick", function()
        TWRA:NavigateMapPage(-1)
    end)
    
    frame.nextButton:SetScript("OnClick", function()
        TWRA:NavigateMapPage(1)
    end)
    
    -- Add tooltips for navigation buttons
    frame.prevButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(frame.prevButton, "ANCHOR_RIGHT")
        GameTooltip:SetText("Previous Map")
        GameTooltip:Show()
    end)
    
    frame.prevButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    frame.nextButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(frame.nextButton, "ANCHOR_LEFT")
        GameTooltip:SetText("Next Map")
        GameTooltip:Show()
    end)
    
    frame.nextButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    -- Status text for the bottom area (above navigation)
    frame.status = frame:CreateFontString(nil, "OVERLAY", "GameFontSmall")
    frame.status:SetPoint("BOTTOM", frame.navContainer, "TOP", 0, 2)
    frame.status:SetText("No map available")
    
    -- Restore saved position
    if TWRA_SavedVariables and TWRA_SavedVariables.options and 
       TWRA_SavedVariables.options.encounterMap then
        local savedPos = TWRA_SavedVariables.options.encounterMap
        if savedPos.point and savedPos.xOfs and savedPos.yOfs then
            frame:ClearAllPoints()
            frame:SetPoint(savedPos.point, UIParent, savedPos.relativePoint or savedPos.point, 
                          savedPos.xOfs, savedPos.yOfs)
            TWRA:Debug("map", "Restored map position: " .. savedPos.point .. ", " .. 
                      savedPos.xOfs .. ", " .. savedPos.yOfs)
        end
    end
    
    -- Hide the frame initially - always start hidden
    frame:Hide()
    
    -- Store the frame reference
    self.encounterMapFrame = frame
    
    -- Initialize map navigation
    self.currentMapPage = 1
    self.totalMapPages = 1
    
    -- Reset permanent state
    self.encounterMapPermanent = false
    
    -- Reset visibility state - ensure this is false
    self.encounterMapIsVisible = false
    
    self:Debug("map", "Encounter map frame created and hidden")
end

-- Initialize map data (sample maps for testing)
function TWRA:InitMapData()
    self:Debug("map", "Initializing map data")
    
    -- Initialize maps table
    self.encounterMaps = self.encounterMaps or {}
    
    -- Sample map for C'Thun (with multiple pages)
    self.encounterMaps["C'Thun"] = {
        pages = {
            {
                texture = "Interface\\AddOns\\TWRA\\textures\\encounters\\cthon.tga",
                title = "C'Thun Phase 1"
            },
            {
                texture = "Interface\\AddOns\\TWRA\\textures\\encounters\\cthon.tga",
                title = "C'Thun Phase 2"
            }
        }
    }
    
    -- Add more maps as needed
    
    self:Debug("map", "Map data initialized")
end

-- Function to show the encounter map permanently
function TWRA:ShowEncounterMap()    
    -- Show the frame
    if self.encounterMapFrame then
        -- Update for current section before showing
        self:UpdateMapForCurrentSection()
        
        self.encounterMapFrame:Show()
        self.encounterMapIsVisible = true
        self.encounterMapPermanent = true
        self:Debug("map", "Showing encounter map permanently")
    else
        self:Debug("map", "Cannot show encounter map - frame not initialized")
    end
end

-- Function to show the encounter map temporarily (mouseover mode)
function TWRA:ShowEncounterMapTemp()   
    -- Show the frame without changing permanent state
    if self.encounterMapFrame then
        -- Update for current section before showing
        self:UpdateMapForCurrentSection()
        
        self.encounterMapFrame:Show()
        self.encounterMapIsVisible = true
        self:Debug("map", "Showing encounter map temporarily")
    else
        self:Debug("map", "Cannot show encounter map temporarily - frame not initialized")
    end
end

-- Function to hide the encounter map
function TWRA:HideEncounterMap()
    if self.encounterMapFrame then
        -- Always hide the actual frame
        self.encounterMapFrame:Hide()
        
        -- If not in permanent mode, update the visibility flag
        if not self.encounterMapPermanent then
            self.encounterMapIsVisible = false
        end
        
        self:Debug("map", "Hiding encounter map (permanent mode: " .. 
                 (self.encounterMapPermanent and "ON" or "OFF") .. ")")
    end
end

-- Add proper section getter functions that were missing
function TWRA:GetCurrentSectionIndex()
    -- Return the current section index from navigation
    return self.navigation and self.navigation.currentIndex or 1
end

function TWRA:GetCurrentSection()
    -- Safely get the current section data
    local index = self:GetCurrentSectionIndex()
    if TWRA_Assignments and TWRA_Assignments.data and index then
        -- In the new format, sections are accessed by index
        return TWRA_Assignments.data[index]
    end
    return nil
end

-- ToggleEncounterMap with enhanced frame checking and debug information
function TWRA:ToggleEncounterMap()
    self:Debug("map", "ToggleEncounterMap called")
    
    -- Always check for existing frame first - extra safety
    if _G["TWRAEncounterMapFrame"] and not self.encounterMapFrame then
        self:Debug("map", "Found global frame but missing addon reference, fixing reference")
        self.encounterMapFrame = _G["TWRAEncounterMapFrame"]
        self.encounterMapInitialized = true
    end
    
    -- Verify frame exists
    if not self.encounterMapFrame then
        self:Debug("map", "ERROR: No encounter map frame available!")
        return
    end
    
    -- Toggle visibility using isVisible flag like OSD does
    if self.encounterMapIsVisible then
        self.encounterMapFrame:Hide()
        self.encounterMapIsVisible = false
        self.encounterMapPermanent = false
        self:Debug("map", "Toggled encounter map OFF")
    else
        self.encounterMapFrame:Show()
        self.encounterMapIsVisible = true
        self.encounterMapPermanent = true
        self:Debug("map", "Toggled encounter map ON (permanent)")
    end
    
    return self.encounterMapPermanent
end

-- Fix the UpdateMapForCurrentSection function to handle missing data gracefully
function TWRA:UpdateMapForCurrentSection()
    self:Debug("map", "Updating map for current section")
    
    -- Ensure we have a frame before proceeding
    if not self.encounterMapFrame then
        self:Debug("map", "Error: No encounter map frame")
        return
    end
    
    -- Get current section data
    local currentSection = self:GetCurrentSection()
    
    -- Get section name, with fallback options if data structure varies
    local sectionName = "Unknown"
    if currentSection then
        if currentSection["Section Name"] then
            sectionName = currentSection["Section Name"]
        elseif currentSection["sn"] then
            sectionName = currentSection["sn"]
        elseif currentSection[1] then
            -- Try to get name from first column in legacy format
            sectionName = currentSection[1]
        end
    end
    
    -- Update title with section name
    self.encounterMapFrame.title:SetText(sectionName)
    
    -- Look for map data for this section
    local mapData = self:GetMapForSection(sectionName)
    
    -- Reset current page
    self.currentMapPage = 1
    
    if mapData and mapData.pages and table.getn(mapData.pages) > 0 then
        -- Get the total number of pages
        self.totalMapPages = table.getn(mapData.pages)
        
        -- Update navigation buttons state
        self:UpdateMapNavigation()
        
        -- Show the current page
        self:ShowMapPage(1)
    else
        -- No map for this section
        self.totalMapPages = 0
        self.encounterMapFrame.mapTexture:Hide()
        self.encounterMapFrame.noMapText:Show()
        self.encounterMapFrame.status:SetText("No map available for " .. sectionName)
        
        -- Update page text
        self.encounterMapFrame.pageText:SetText("0 of 0")
        
        -- Disable navigation buttons
        self.encounterMapFrame.prevButton:Disable()
        self.encounterMapFrame.nextButton:Disable()
    end
end

-- Get map data for a section name
function TWRA:GetMapForSection(sectionName)
    -- Try direct match
    if sectionName and self.encounterMaps and self.encounterMaps[sectionName] then
        return self.encounterMaps[sectionName]
    end
    
    -- Try partial match (contains)
    if sectionName then
        for name, data in pairs(self.encounterMaps or {}) do
            if string.find(sectionName, name) or string.find(name, sectionName) then
                return data
            end
        end
    end
    
    return nil
end

-- Navigate to a specific map page
function TWRA:NavigateMapPage(delta)
    self:Debug("map", "Navigating map page with delta: " .. delta)
    
    -- Calculate new page index
    local newPage = self.currentMapPage + delta
    
    -- Ensure page is within bounds
    if newPage < 1 then
        newPage = 1
    elseif newPage > self.totalMapPages then
        newPage = self.totalMapPages
    end
    
    -- Only update if page changed
    if newPage ~= self.currentMapPage then
        self.currentMapPage = newPage
        self:ShowMapPage(newPage)
    end
end

-- Show a specific map page
function TWRA:ShowMapPage(pageIndex)
    self:Debug("map", "Showing map page: " .. pageIndex)
    
    -- Make sure we have a frame
    if not self.encounterMapFrame then return end
    
    -- Get current section
    local currentSection = self:GetCurrentSection()
    if not currentSection then return end
    
    -- Get section name
    local sectionName = currentSection["Section Name"] or currentSection["sn"] or "Unknown"
    
    -- Get map data
    local mapData = self:GetMapForSection(sectionName)
    if not mapData or not mapData.pages then
        self:Debug("map", "No map data found for section: " .. sectionName)
        return
    end
    
    -- Make sure page index is valid
    if pageIndex < 1 or pageIndex > table.getn(mapData.pages) then
        self:Debug("map", "Invalid page index: " .. pageIndex)
        return
    end
    
    -- Get page data
    local pageData = mapData.pages[pageIndex]
    
    -- Update map display
    if pageData and pageData.texture then
        self.encounterMapFrame.mapTexture:SetTexture(pageData.texture)
        self.encounterMapFrame.mapTexture:Show()
        self.encounterMapFrame.noMapText:Hide()
        
        -- Update status
        self.encounterMapFrame.status:SetText(pageData.title or "")
    else
        -- No texture for this page
        self.encounterMapFrame.mapTexture:Hide()
        self.encounterMapFrame.noMapText:Show()
        self.encounterMapFrame.status:SetText("No image for page " .. pageIndex)
    end
    
    -- Update page text
    self.encounterMapFrame.pageText:SetText(pageIndex .. " of " .. self.totalMapPages)
    
    -- Update navigation buttons
    self:UpdateMapNavigation()
end

-- Update navigation buttons state
function TWRA:UpdateMapNavigation()
    if not self.encounterMapFrame then return end
    
    -- Update previous button state
    if self.currentMapPage <= 1 then
        self.encounterMapFrame.prevButton:Disable()
    else
        self.encounterMapFrame.prevButton:Enable()
    end
    
    -- Update next button state
    if self.currentMapPage >= self.totalMapPages then
        self.encounterMapFrame.nextButton:Disable()
    else
        self.encounterMapFrame.nextButton:Enable()
    end
    
    -- Update page text
    self.encounterMapFrame.pageText:SetText(self.currentMapPage .. " of " .. self.totalMapPages)
end

-- Add encounter map button to main UI
function TWRA:AddEncounterMapButton()
    -- Skip if button already exists
    if self.encounterMapButton then
        return
    end
    
    -- Check if we have a main frame
    if not self.mainFrame then
        return
    end
    
    -- Create the button
    local button = CreateFrame("Button", "TWRAEncounterMapButton", self.mainFrame, "UIPanelButtonTemplate")
    button:SetWidth(80)
    button:SetHeight(22)
    button:SetText("Map")
    
    -- Position based on other buttons
    if self.announceButton then
        button:SetPoint("TOPLEFT", self.announceButton, "TOPRIGHT", 5, 0)
    elseif self.updateTanksButton then
        button:SetPoint("TOPLEFT", self.updateTanksButton, "TOPRIGHT", 5, 0)
    else
        button:SetPoint("BOTTOMLEFT", self.mainFrame, "BOTTOMLEFT", 10, 10)
    end
    
    -- Add click handler
    button:SetScript("OnClick", function()
        TWRA:ToggleEncounterMap()
    end)
    
    -- Add tooltip
    button:SetScript("OnEnter", function()
        GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
        GameTooltip:SetText("Show Encounter Map")
        GameTooltip:AddLine("Display a visual map of the current encounter", 1, 1, 1)
        GameTooltip:Show()
    end)
    
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    -- Store button reference
    self.encounterMapButton = button
end

-- Hook to PLAYER_ENTERING_WORLD
-- This is already called in Core.lua, no need to add it again

-- Hook to main frame creation
local originalCreateMainFrame = TWRA.CreateMainFrame
if originalCreateMainFrame then
    TWRA.CreateMainFrame = function(self)
        local result = originalCreateMainFrame(self)
        self:AddEncounterMapButton()
        return result
    end
end