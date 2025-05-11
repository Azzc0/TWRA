-- TWRA Encounter Map Module
-- Provides a hoverable encounter map display with similar styling to OSD

TWRA = TWRA or {}

-- Initialize encounter map settings and structure
function TWRA:InitEncounterMap()
    -- Skip if already initialized
    if self.encounterMap and self.encounterMap.initialized then
        self:Debug("map", "Encounter Map already initialized")
        return true
    end
    
    -- Initialize default settings
    self.encounterMap = self.encounterMap or {}
    self.encounterMap.point = self.encounterMap.point or "CENTER"
    self.encounterMap.xOffset = self.encounterMap.xOffset or 0
    self.encounterMap.yOffset = self.encounterMap.yOffset or 0
    self.encounterMap.scale = self.encounterMap.scale or 1.0
    self.encounterMap.locked = self.encounterMap.locked or false
    self.encounterMap.enabled = true
    
    -- Initialize image navigation state
    self.encounterMap.currentImages = nil
    self.encounterMap.currentImageIndex = nil
    
    -- Initialize texture cache
    self.encounterMap.textureFrames = {}
    
    -- Load saved settings if available
    if TWRA_SavedVariables and TWRA_SavedVariables.options and TWRA_SavedVariables.options.encounterMap then
        local savedMap = TWRA_SavedVariables.options.encounterMap
        self.encounterMap.point = savedMap.point or self.encounterMap.point
        self.encounterMap.xOffset = savedMap.xOffset or self.encounterMap.xOffset
        self.encounterMap.yOffset = savedMap.yOffset or self.encounterMap.yOffset
        self.encounterMap.scale = savedMap.scale or self.encounterMap.scale
        self.encounterMap.locked = savedMap.locked
        self.encounterMap.enabled = (savedMap.enabled ~= false) -- Default to true if nil
    end

    -- Register event listeners
    self:RegisterEncounterMapEvents()

    -- Mark as initialized
    self.encounterMap.initialized = true
    self:Debug("map", "Encounter Map system initialized")
    return true
end

-- Get or create the Encounter Map frame
function TWRA:GetEncounterMapFrame()
    -- Return existing frame if we have one
    if self.encounterMapFrame then
        return self.encounterMapFrame
    end

    -- Create the main frame - use square dimensions
    local frameSize = 300 -- Square size
    local frame = CreateFrame("Frame", "TWRAEncounterMapFrame", UIParent)
    frame:SetFrameStrata("DIALOG")
    frame:SetWidth(frameSize)
    frame:SetHeight(frameSize)

    -- Position the frame
    frame:ClearAllPoints()
    frame:SetPoint(self.encounterMap.point, UIParent, self.encounterMap.point, self.encounterMap.xOffset, self.encounterMap.yOffset)
    frame:SetScale(self.encounterMap.scale or 1.0)

    -- Add background with transparency - this will be behind the map texture
    local bg = frame:CreateTexture(nil, "BACKGROUND", nil, 0)
    bg:SetAllPoints()
    bg:SetTexture(0, 0, 0, 0.7) -- Black transparent background
    frame.bg = bg

    -- Create the content container for the map texture - now covers the entire frame
    local contentContainer = CreateFrame("Frame", nil, frame)
    contentContainer:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    contentContainer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    contentContainer:SetFrameLevel(frame:GetFrameLevel()) -- Base level
    frame.contentContainer = contentContainer

    -- Add border with higher strata than content
    local border = CreateFrame("Frame", nil, frame)
    border:SetPoint("TOPLEFT", -2, 2)
    border:SetPoint("BOTTOMRIGHT", 2, -2)
    border:SetFrameLevel(frame:GetFrameLevel() + 10) -- Higher than content
    border:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    frame.border = border
    
    -- Create a controls container with high strata for all UI elements
    local controlsContainer = CreateFrame("Frame", nil, frame)
    controlsContainer:SetAllPoints()
    controlsContainer:SetFrameLevel(frame:GetFrameLevel() + 20) -- Higher than border
    frame.controlsContainer = controlsContainer
    
    -- Add close button (X) in top right corner - now part of controls container
    local closeButton = CreateFrame("Button", nil, controlsContainer)
    closeButton:SetWidth(24) -- Slightly larger
    closeButton:SetHeight(24) -- Slightly larger
    closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
    
    -- Set the texture to a standard X button
    local texture = closeButton:CreateTexture(nil, "ARTWORK")
    texture:SetTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
    texture:SetAllPoints()
    texture:SetTexCoord(0.2, 0.8, 0.2, 0.8) -- Crop to just show the X part
    closeButton.texture = texture
    
    -- Add hover and click visual feedback
    closeButton:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight", "ADD")
    closeButton:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
    
    -- Set the click handler to hide the encounter map
    closeButton:SetScript("OnClick", function()
        TWRA:HideEncounterMap()
    end)
    
    -- Add tooltip
    closeButton:SetScript("OnEnter", function()
        GameTooltip:SetOwner(closeButton, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Close Encounter Map")
        GameTooltip:Show()
    end)
    
    closeButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
    
    frame.closeButton = closeButton

    -- Make the frame movable if not locked
    frame:SetMovable(not self.encounterMap.locked)
    frame:EnableMouse(true) -- Always enable mouse for interaction
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function() 
        if not TWRA.encounterMap.locked then
            this:StartMoving()
        end 
    end)
    frame:SetScript("OnDragStop", function()
        this:StopMovingOrSizing()
        -- Save position
        local point, _, _, xOffset, yOffset = this:GetPoint()
        TWRA.encounterMap.point = point
        TWRA.encounterMap.xOffset = xOffset
        TWRA.encounterMap.yOffset = yOffset
        
        -- Update saved variables
        if TWRA_SavedVariables and TWRA_SavedVariables.options and TWRA_SavedVariables.options.encounterMap then
            TWRA_SavedVariables.options.encounterMap.point = point
            TWRA_SavedVariables.options.encounterMap.xOffset = xOffset
            TWRA_SavedVariables.options.encounterMap.yOffset = yOffset
        end
    end)
    
    -- Add mouse enter/leave scripts to prevent hiding during hover
    frame:SetScript("OnEnter", function()
        TWRA:Debug("map", "Mouse entered Encounter Map frame")
        -- Cancel any pending hide timer
        if TWRA.encounterMap.hideTimer then
            TWRA:CancelTimer(TWRA.encounterMap.hideTimer)
            TWRA.encounterMap.hideTimer = nil
            TWRA:Debug("map", "Canceled hide timer due to mouse enter")
        end
    end)
    
    frame:SetScript("OnLeave", function()
        TWRA:Debug("map", "Mouse left Encounter Map frame")
        -- Only hide if not in permanent mode
        if not TWRA.encounterMapPermanent then
            -- Add a small delay before hiding to give buffer time
            TWRA.encounterMap.hideTimer = TWRA:ScheduleTimer(function()
                TWRA:Debug("map", "Hiding encounter map after mouse leave delay")
                TWRA:HideEncounterMap()
                TWRA.encounterMap.hideTimer = nil
            end, 0.2) -- Small delay to avoid flickering
        end
    end)

    -- Create header for title - now part of controls container
    local headerContainer = CreateFrame("Frame", nil, controlsContainer)
    headerContainer:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -5)
    headerContainer:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -5)
    headerContainer:SetHeight(30) -- Slightly taller
    frame.headerContainer = headerContainer
    
    -- Semi-transparent background for the header
    local headerBg = headerContainer:CreateTexture(nil, "BACKGROUND")
    headerBg:SetAllPoints()
    headerBg:SetTexture(0, 0, 0, 0.5) -- Semi-transparent black
    headerContainer.bg = headerBg

    -- Create title text (centered, without the icon)
    local titleText = headerContainer:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    titleText:SetPoint("TOP", headerContainer, "TOP", 0, 0)
    titleText:SetPoint("LEFT", headerContainer, "LEFT", 10, 0)
    titleText:SetPoint("RIGHT", headerContainer, "RIGHT", -10, 0)
    titleText:SetHeight(25)
    titleText:SetJustifyH("CENTER")
    titleText:SetText("Encounter Map")
    titleText:SetTextColor(1, 1, 1) -- Set title text to white
    frame.titleText = titleText
    
    -- Navigation area at the bottom with semi-transparent background
    local navContainer = CreateFrame("Frame", nil, controlsContainer)
    navContainer:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 10, 10)
    navContainer:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 30)
    navContainer:SetHeight(40) -- Taller for bigger buttons
    
    -- Semi-transparent background for navigation
    local navBg = navContainer:CreateTexture(nil, "BACKGROUND")
    navBg:SetAllPoints()
    navBg:SetTexture(0, 0, 0, 0.5) -- Semi-transparent black
    navContainer.bg = navBg
    
    frame.navContainer = navContainer
    
    -- Left navigation button - much bigger
    local prevButton = CreateFrame("Button", nil, navContainer)
    prevButton:SetWidth(40) -- Doubled size
    prevButton:SetHeight(40) -- Doubled size
    prevButton:SetPoint("LEFT", navContainer, "LEFT", 10, 0)
    
    -- Set left button textures (Normal, Pushed, Disabled)
    prevButton:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up")
    prevButton:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down")
    prevButton:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Disabled")
    frame.prevButton = prevButton
    
    -- Right navigation button - much bigger
    local nextButton = CreateFrame("Button", nil, navContainer)
    nextButton:SetWidth(40) -- Doubled size
    nextButton:SetHeight(40) -- Doubled size
    nextButton:SetPoint("RIGHT", navContainer, "RIGHT", -10, 0)
    
    -- Set right button textures (Normal, Pushed, Disabled)
    nextButton:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
    nextButton:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down")
    nextButton:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Disabled")
    frame.nextButton = nextButton
    
    -- Set initial button states
    prevButton:Disable()
    nextButton:Disable()
    
    -- Set initial visibility
    frame:Hide()
    self.encounterMapFrame = frame

    self:Debug("map", "Encounter Map frame created")
    return frame
end

-- Apply encounter map settings to the frame
function TWRA:UpdateEncounterMapSettings()
    if not self.encounterMapFrame then
        self:Debug("map", "Cannot update Encounter Map settings: frame doesn't exist")
        return false
    end
    
    -- Apply scale setting
    self.encounterMapFrame:SetScale(self.encounterMap.scale or 1.0)
    
    -- Apply position settings
    self.encounterMapFrame:ClearAllPoints()
    self.encounterMapFrame:SetPoint(self.encounterMap.point or "CENTER", UIParent, self.encounterMap.point or "CENTER", 
        self.encounterMap.xOffset or 0, self.encounterMap.yOffset or 0)
    
    -- Apply movable/locked state
    self.encounterMapFrame:SetMovable(not self.encounterMap.locked)
    
    -- Show/hide based on enabled setting
    if not self.encounterMap.enabled and self.encounterMapFrame:IsShown() then
        self:HideEncounterMap()
    end
    
    self:Debug("map", "Encounter Map settings updated")
    return true
end

-- Create a texture frame for a specific image
function TWRA:CreateTextureFrame(imageRef)
    -- Skip if already exists
    if self.encounterMap.textureFrames[imageRef] then
        return self.encounterMap.textureFrames[imageRef]
    end
    
    -- Get the main frame
    local mainFrame = self:GetEncounterMapFrame()
    if not mainFrame then return nil end
    
    -- Create a new frame for this texture that fills the entire content area
    local textureFrame = CreateFrame("Frame", nil, mainFrame.contentContainer)
    textureFrame:SetAllPoints()
    textureFrame:Hide()
    
    -- Create the texture
    local texture = textureFrame:CreateTexture(nil, "BACKGROUND", nil, 1) -- Set as BACKGROUND with subindex 1
    texture:SetAllPoints()
    
    -- Set the texture (no extension)
    local texturePath = "Interface\\AddOns\\TWRA\\textures\\encounters\\" .. imageRef
    texture:SetTexture(texturePath)
    
    -- Store the texture information
    textureFrame.texture = texture
    textureFrame.imageRef = imageRef
    textureFrame.loaded = true
    
    -- Store in our cache
    self.encounterMap.textureFrames[imageRef] = textureFrame
    
    self:Debug("map", "Created texture frame for: " .. imageRef)
    return textureFrame
end

-- Load current image based on current index
function TWRA:LoadCurrentImage()
    if not self.encounterMap.currentImages or not self.encounterMap.currentImageIndex then
        self:Debug("map", "Cannot load image: no current images or index")
        return false
    end
    
    local frame = self.encounterMapFrame
    if not frame then 
        self:Debug("map", "Cannot load image: no frame")
        return false 
    end
    
    local currentIndex = self.encounterMap.currentImageIndex
    local imageRef = self.encounterMap.currentImages[currentIndex]
    
    if not imageRef then 
        self:Debug("map", "Cannot load image: no image reference at index " .. currentIndex)
        return false 
    end
    
    -- Hide all texture frames first
    if self.encounterMap.textureFrames then
        for _, textureFrame in pairs(self.encounterMap.textureFrames) do
            textureFrame:Hide()
        end
    end
    
    -- Get or create the texture frame for this image
    local textureFrame = self:CreateTextureFrame(imageRef)
    if not textureFrame then
        self:Debug("map", "Failed to create texture frame for: " .. imageRef)
        return false
    end
    
    -- Show the texture frame
    textureFrame:Show()
    
    -- Hide the "no map available" text if it exists
    if frame.noMapText then
        frame.noMapText:Hide()
    end
    
    -- Update title with section name and image count
    if frame.titleText then
        local sectionName = self.encounterMap.currentSectionName or "Encounter Map"
        local totalImages = table.getn(self.encounterMap.currentImages)
        
        -- Truncate section name if it's too long (over 20 chars)
        if string.len(sectionName) > 20 then
            sectionName = string.sub(sectionName, 1, 18) .. "..."
        end
        
        -- Only show image number if we have multiple images
        if totalImages > 1 then
            frame.titleText:SetText(sectionName .. " (" .. currentIndex .. ")")
        else
            frame.titleText:SetText(sectionName)
        end
    end
    
    self:Debug("map", "Showing texture frame for image " .. currentIndex .. " of " .. table.getn(self.encounterMap.currentImages) .. ": " .. imageRef)
    
    -- Update navigation buttons
    self:UpdateEncounterMapNavigation()
    
    return true
end

-- Navigate to previous image
function TWRA:NavigateToPreviousImage()
    if not self.encounterMap.currentImages or not self.encounterMap.currentImageIndex then
        self:Debug("map", "Cannot navigate to previous image: no images defined")
        return false
    end
    
    local currentIndex = self.encounterMap.currentImageIndex
    if currentIndex <= 1 then 
        self:Debug("map", "Already at first image")
        return false 
    end
    
    -- Update index and refresh
    self.encounterMap.currentImageIndex = currentIndex - 1
    self:Debug("map", "Navigating to previous image: " .. self.encounterMap.currentImageIndex .. " of " .. table.getn(self.encounterMap.currentImages))
    
    -- Load the new image
    self:LoadCurrentImage()
    
    return true
end

-- Navigate to next image
function TWRA:NavigateToNextImage()
    if not self.encounterMap.currentImages or not self.encounterMap.currentImageIndex then
        self:Debug("map", "Cannot navigate to next image: no images defined")
        return false
    end
    
    local currentIndex = self.encounterMap.currentImageIndex
    local totalImages = table.getn(self.encounterMap.currentImages)
    
    if currentIndex >= totalImages then 
        self:Debug("map", "Already at last image")
        return false 
    end
    
    -- Update index and refresh
    self.encounterMap.currentImageIndex = currentIndex + 1
    self:Debug("map", "Navigating to next image: " .. self.encounterMap.currentImageIndex .. " of " .. totalImages)
    
    -- Load the new image
    self:LoadCurrentImage()
    
    return true
end

-- Preload all known textures
function TWRA:PreloadMapTextures()
    self:Debug("map", "Preloading all map textures...")
    
    -- List of common texture names to preload
    local knownTextures = {"cthon", "anken", "minimap", "linken"}
    
    -- Create the encounter map frame if it doesn't exist
    local frame = self:GetEncounterMapFrame()
    if not frame then
        self:Debug("map", "Cannot preload textures: no frame")
        return false
    end
    
    -- Preload each texture with its own frame
    for _, texName in pairs(knownTextures) do
        self:CreateTextureFrame(texName)
    end
    
    -- Also scan through TWRA_Assignments to find all referenced textures
    if TWRA_Assignments and TWRA_Assignments.data then
        for _, section in pairs(TWRA_Assignments.data) do
            if section["Section Metadata"] then
                -- Check for images array
                if section["Section Metadata"]["Images"] and type(section["Section Metadata"]["Images"]) == "table" then
                    for _, imageRef in pairs(section["Section Metadata"]["Images"]) do
                        self:CreateTextureFrame(imageRef)
                    end
                end
                
                -- Check for single image
                if section["Section Metadata"]["Image"] then
                    self:CreateTextureFrame(section["Section Metadata"]["Image"])
                end
            end
        end
    end
    
    self:Debug("map", "Texture preloading complete")
    return true
end

-- Update map content
function TWRA:UpdateEncounterMapContent(sectionName)
    local frame = self:GetEncounterMapFrame()
    if not frame then
        self:Debug("map", "Failed to get Encounter Map frame")
        return false
    end
    
    -- Update title if section name provided
    if sectionName and frame.titleText then
        frame.titleText:SetText(sectionName)
    end
    
    -- Get current section and find appropriate map texture
    local currentSection = sectionName
    if not currentSection and self.navigation and self.navigation.currentIndex and self.navigation.handlers then
        currentSection = self.navigation.handlers[self.navigation.currentIndex]
    end
    
    -- Reset image navigation state for new section
    self.encounterMap.currentImages = nil
    self.encounterMap.currentImageIndex = nil
    
    -- Hide all texture frames first
    if self.encounterMap.textureFrames then
        for _, textureFrame in pairs(self.encounterMap.textureFrames) do
            textureFrame:Hide()
        end
    end
    
    -- Load the map texture based on the current section
    if currentSection then
        local mapPath = self:GetEncounterMapPath(currentSection)
        if mapPath then
            -- Instead of setting a texture, just show the correct frame
            local success = self:LoadCurrentImage()
            
            if success then
                -- Show/hide "No map available" text
                if frame.noMapText then
                    frame.noMapText:Hide()
                end
                
                -- Update navigation buttons if we have multiple images
                self:UpdateEncounterMapNavigation()
                
                return true
            end
        else
            -- Set default "no map available" texture and background
            if frame.noMapText then
                frame.noMapText:Show()
            else
                frame.noMapText = frame.contentContainer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
                frame.noMapText:SetPoint("CENTER", frame.contentContainer, "CENTER")
                frame.noMapText:SetText("No map available")
                frame.noMapText:SetTextColor(0.8, 0.8, 0.8)
            end
            
            -- Disable navigation buttons
            if frame.prevButton then frame.prevButton:Disable() end
            if frame.nextButton then frame.nextButton:Disable() end
            
            self:Debug("map", "No map texture found for section: " .. currentSection)
        end
    end
    
    return false
end

-- Update navigation buttons based on current image index
function TWRA:UpdateEncounterMapNavigation()
    local frame = self.encounterMapFrame
    if not frame then return false end
    
    -- Disable both buttons by default
    frame.prevButton:Disable()
    frame.nextButton:Disable()
    
    -- If we have multiple images, enable navigation buttons as appropriate
    if self.encounterMap.currentImages and type(self.encounterMap.currentImages) == "table" then
        local totalImages = table.getn(self.encounterMap.currentImages)
        local currentIndex = self.encounterMap.currentImageIndex or 1
        
        self:Debug("map", "Updating navigation buttons: image " .. currentIndex .. " of " .. totalImages)
        
        -- Enable prev button if not on first image
        if currentIndex > 1 then
            frame.prevButton:Enable()
        end
        
        -- Enable next button if not on last image
        if currentIndex < totalImages then
            frame.nextButton:Enable()
        end
        
        -- Add click handlers if not already added
        if not frame.prevButton.clickHandlerAdded then
            frame.prevButton:SetScript("OnClick", function()
                TWRA:NavigateToPreviousImage()
            end)
            frame.prevButton.clickHandlerAdded = true
        end
        
        if not frame.nextButton.clickHandlerAdded then
            frame.nextButton:SetScript("OnClick", function()
                TWRA:NavigateToNextImage()
            end)
            frame.nextButton.clickHandlerAdded = true
        end
    end
    
    return true
end

-- Register event listener for section change
function TWRA:RegisterEncounterMapEvents()
    -- Listen for section changes to update encounter map
    self:RegisterEvent("SECTION_CHANGED", function()
        -- Only update if encounter map is visible
        if TWRA.encounterMapFrame and TWRA.encounterMapFrame:IsShown() then
            TWRA:Debug("map", "Section changed - updating encounter map via event")
            TWRA:UpdateEncounterMapContent()
        end
    end, "EncounterMap")
    
    self:Debug("map", "Registered encounter map events")
    return true
end

-- Get the texture path for a specific encounter section
function TWRA:GetEncounterMapPath(sectionName)
    if not sectionName then return nil end
    
    -- Store the current section name for title display
    self.encounterMap.currentSectionName = sectionName
    
    -- Check section data for map path information
    if TWRA_Assignments and TWRA_Assignments.data then
        for _, section in pairs(TWRA_Assignments.data) do
            if section["Section Name"] == sectionName then
                -- First check for image information in section metadata
                if section["Section Metadata"] then
                    -- Check for multiple image references - prioritize "Images" array
                    if section["Section Metadata"]["Images"] and type(section["Section Metadata"]["Images"]) == "table" then
                        -- Image array found - set up navigation and return first image
                        local images = section["Section Metadata"]["Images"]
                        local imageCount = table.getn(images)
                        
                        -- Skip if array is empty
                        if imageCount == 0 then
                            self:Debug("map", "Images array is empty for section: " .. sectionName)
                        else
                            -- Store all images for navigation
                            self.encounterMap.currentImages = images
                            self.encounterMap.currentImageIndex = 1
                            
                            -- Get first image reference
                            local imageRef = images[1]
                            if imageRef then
                                -- Don't add extension here, let LoadCurrentImage handle it
                                local texturePath = "Interface\\AddOns\\TWRA\\textures\\encounters\\" .. imageRef
                                self:Debug("map", "Using image " .. imageRef .. " (1 of " .. imageCount .. ")")
                                
                                -- List all available images in debug
                                local imageList = ""
                                for i = 1, imageCount do
                                    imageList = imageList .. images[i]
                                    if i < imageCount then imageList = imageList .. ", " end
                                end
                                self:Debug("map", "Available images: " .. imageList)
                                
                                return texturePath
                            end
                        end
                    -- Check for single image reference (fallback)
                    elseif section["Section Metadata"]["Image"] then
                        local imageRef = section["Section Metadata"]["Image"]
                        -- Don't add extension here, let LoadCurrentImage handle it
                        local texturePath = "Interface\\AddOns\\TWRA\\textures\\encounters\\" .. imageRef
                        self:Debug("map", "Found single image reference: " .. imageRef)
                        
                        -- Create a single-item array for navigation consistency
                        self.encounterMap.currentImages = {imageRef}
                        self.encounterMap.currentImageIndex = 1
                        
                        return texturePath
                    end
                end
                
                -- No valid image found in metadata, use the missing texture icon
                self:Debug("map", "No image found in metadata for section: " .. sectionName)
                
                -- Return the missing icon texture
                if TWRA.ICONS and TWRA.ICONS["Missing"] and TWRA.ICONS["Missing"][1] then
                    self:Debug("map", "Using missing texture icon")
                    return TWRA.ICONS["Missing"][1]
                end
                
                return nil
            end
        end
    end
    
    self:Debug("map", "No section found with name: " .. sectionName)
    return nil
end

-- Show the Encounter Map (applies to both permanent and temporary)
function TWRA:ShowEncounterMap(permanent)
    -- Skip if encounter map is disabled
    if not self.encounterMap or not self.encounterMap.enabled then
        self:Debug("map", "Encounter Map is disabled, cannot show")
        return false
    end
    
    -- Create or ensure the frame exists
    local frame = self:GetEncounterMapFrame()
    if not frame then
        self:Debug("map", "Failed to get or create Encounter Map frame")
        return false
    end
    
    -- Update content with current section information
    self:UpdateEncounterMapContent()
    
    -- Show the frame
    frame:Show()
    
    -- Clear any existing hide timer
    if self.encounterMap.hideTimer then
        self:CancelTimer(self.encounterMap.hideTimer)
        self.encounterMap.hideTimer = nil
    end
    
    -- Set permanent mode if requested
    if permanent then
        self.encounterMapPermanent = true
        self:Debug("map", "Encounter Map shown permanently")
    else
        self:Debug("map", "Encounter Map shown temporarily")
    end
    
    return true
end

-- Show Encounter Map permanently
function TWRA:ShowEncounterMapPermanent()
    return self:ShowEncounterMap(true)
end

-- Show the Encounter Map temporarily (for mouse hover)
function TWRA:ShowEncounterMapTemp()
    -- Skip if already in permanent mode
    if self.encounterMapPermanent then
        self:Debug("map", "Encounter Map already in permanent mode, ignoring temporary show request")
        return true
    end
    
    return self:ShowEncounterMap(false)
end

-- Hide the Encounter Map
function TWRA:HideEncounterMap()
    -- If in permanent mode, don't hide
    if self.encounterMapPermanent then
        self:Debug("map", "Encounter Map is in permanent mode, ignoring hide request")
        return false
    end
    
    -- Clear any pending hide timer
    if self.encounterMap and self.encounterMap.hideTimer then
        self:CancelTimer(self.encounterMap.hideTimer)
        self.encounterMap.hideTimer = nil
    end
    
    -- Check if the frame exists and hide it safely
    if self.encounterMapFrame then
        self.encounterMapFrame:Hide()
        self:Debug("map", "Encounter Map hidden")
    end
    
    return true
end

-- Toggle Encounter Map visibility (permanent on/off)
function TWRA:ToggleEncounterMap()
    -- Make sure Encounter Map is initialized
    if not self.encounterMap then
        self:InitEncounterMap()
    end
    
    if self.encounterMapPermanent then
        self.encounterMapPermanent = false
        self:HideEncounterMap()
        self:Debug("map", "Encounter Map permanent mode disabled")
    else
        self:ShowEncounterMapPermanent()
        self:Debug("map", "Encounter Map permanent mode enabled")
    end
    
    return self.encounterMapPermanent
end

-- Reset the Encounter Map position to default center values
function TWRA:ResetEncounterMapPosition()
    -- Default position values
    local defaultPoint = "CENTER"
    local defaultXOffset = 0
    local defaultYOffset = 0
    
    -- Update Encounter Map settings
    self.encounterMap.point = defaultPoint
    self.encounterMap.xOffset = defaultXOffset
    self.encounterMap.yOffset = defaultYOffset
    
    -- Save to saved variables
    if TWRA_SavedVariables and TWRA_SavedVariables.options and TWRA_SavedVariables.options.encounterMap then
        TWRA_SavedVariables.options.encounterMap.point = defaultPoint
        TWRA_SavedVariables.options.encounterMap.xOffset = defaultXOffset
        TWRA_SavedVariables.options.encounterMap.yOffset = defaultYOffset
    end
    
    -- Apply new position if frame exists
    if self.encounterMapFrame then
        self.encounterMapFrame:ClearAllPoints()
        self.encounterMapFrame:SetPoint(defaultPoint, UIParent, defaultPoint, defaultXOffset, defaultYOffset)
        self:Debug("map", "Encounter Map position reset to default center position")
    end
    
    return true
end

-- Hook for section navigation - updates encounter map
function TWRA:OnSectionChanged()
    -- Update encounter map if it's visible
    if self.encounterMapFrame and self.encounterMapFrame:IsShown() then
        self:Debug("map", "Section changed - updating encounter map")
        self:UpdateEncounterMapContent()
    end
end

-- Register the preload function to run after addon initialization
TWRA:RegisterEvent("VARIABLES_LOADED", function()
    -- Wait a short time to ensure everything is loaded
    TWRA:ScheduleTimer(function() 
        TWRA:PreloadMapTextures() 
    end, 1)
end, "EncounterMapPreload")

-- Register slash command for testing
SLASH_TWRAMAP1 = "/twramap"
SlashCmdList["TWRAMAP"] = function(msg)
    if msg == "toggle" or msg == "" then
        TWRA:ToggleEncounterMap()
    elseif msg == "hide" then
        TWRA:HideEncounterMap()
    elseif msg == "show" then
        TWRA:ShowEncounterMapPermanent()
    elseif msg == "reset" then
        TWRA:ResetEncounterMapPosition()
    end
end