-- Item linking functionality for TWRA
TWRA = TWRA or {}
TWRA.Items = {}

-- Get a proper item link for the given item name
function TWRA.Items:GetLinkByName(itemName)
    if not itemName then return nil end
    
    local itemData = TWRA.ITEM_DATABASE[itemName]
    if not itemData then 
        -- Use SafeToString to handle the case where itemName might be a table
        TWRA:Debug("items", "Item not found in database: " .. TWRA:SafeToString(itemName))
        return nil 
    end
    
    -- Get the item's color based on quality
    local colorHex = TWRA.ITEM_QUALITY_COLORS[itemData.quality] or TWRA.ITEM_QUALITY_COLORS["Common"]
    
    -- Create the proper item link
    return "|cff" .. colorHex .. "|Hitem:" .. itemData.id .. ":0:0:0|h[" .. TWRA:SafeToString(itemName) .. "]|h|r"
end

-- Process text to replace item name patterns with item links
function TWRA.Items:ProcessText(text)
    -- Use SafeToString to handle the case where text might be a table
    if not text then return "" end
    
    -- Convert text to string if it's a table
    if type(text) == "table" then
        TWRA:Debug("error", "ProcessText received a table instead of a string")
        return "[Table]"
    end
    
    -- IMPORTANT FIX: First check if the text already contains item links (|Hitem:)
    -- If it does, don't try to process further to avoid breaking existing links
    if string.find(text, "|Hitem:") then
        self:Debug("items", "Text already contains item links, preserving as-is: " .. TWRA:SafeToString(text))
        return text
    end
    
    -- Look for [ItemName] patterns and replace with links
    local result = string.gsub(text, "%[([^%]]+)%]", function(itemName)
        local link = self:GetLinkByName(itemName)
        if link then
            return link
        else
            -- Keep the original bracketed text if no item found
            return "[" .. TWRA:SafeToString(itemName) .. "]"
        end
    end)
    
    -- Also process plain text items that don't have brackets
    -- This is more advanced but allows for better automation
    for itemName, _ in pairs(TWRA.ITEM_DATABASE) do
        -- Avoid replacing text that's already part of a link
        -- Look for the item name with word boundaries (not within other words)
        local pattern = "([^|])(" .. itemName .. ")([^%]|])"
        result = string.gsub(result, pattern, function(prefix, matched, suffix)
            local link = self:GetLinkByName(matched)
            if link then
                return prefix .. link .. suffix
            else
                return prefix .. matched .. suffix
            end
        end)
    end
    
    return result
end

-- Helper function to convert specific potion/consumable names in a message
function TWRA.Items:ProcessConsumables(text)
    if not text then return text end
    
    -- Common consumables that might appear in raid instructions
    local consumables = {
        ["fire prot"] = "Greater Fire Protection Potion",
        ["fire protection"] = "Greater Fire Protection Potion",
        ["nature prot"] = "Greater Nature Protection Potion",
        ["nature protection"] = "Greater Nature Protection Potion",
        ["shadow prot"] = "Greater Shadow Protection Potion",
        ["shadow protection"] = "Greater Shadow Protection Potion",
        ["frost prot"] = "Greater Frost Protection Potion",
        ["frost protection"] = "Greater Frost Protection Potion",
        ["arcane prot"] = "Greater Arcane Protection Potion",
        ["arcane protection"] = "Greater Arcane Protection Potion",
        ["poison resist"] = "Elixir of Poison Resistance",
        ["poison resistance"] = "Elixir of Poison Resistance"
    }
    
    -- Replace common abbreviations with full item links
    for shortName, fullName in pairs(consumables) do
        local pattern = "([^|])(" .. shortName .. ")([^%]|])"
        text = string.gsub(text, pattern, function(prefix, matched, suffix)
            local link = self:GetLinkByName(fullName)
            if link then
                return prefix .. link .. suffix
            else
                return prefix .. matched .. suffix
            end
        end)
    end
    
    return text
end

-- Enhanced process function that combines all processing methods
function TWRA.Items:EnhancedProcessText(text)
    if not text then return text end
    
    -- First process bracketed items
    text = self:ProcessText(text)
    
    -- Then try to identify consumables by common names
    text = self:ProcessConsumables(text)
    
    return text
end

TWRA:Debug("items", "Item linking system initialized")
