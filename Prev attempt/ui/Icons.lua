-- TWRA Icons Module
TWRA = TWRA or {}
TWRA.UI = TWRA.UI or {}

-- Class color definitions
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

-- Class names for group assignments
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

-- Class icon texture coordinates
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

-- Raid target and special icons
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

-- Colored icon text for announcements
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

-- Role icons with textures
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
    
    -- Specialized role icons
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

-- Role to icon name mapping table
TWRA.UI.ROLE_MAPPINGS = {
    ["tank"] = "Tank",
    ["heal"] = "Heal",
    ["dps"] = "DPS",
    ["cc"] = "CC",
    ["pull"] = "Pull",
    ["ress"] = "Ress",
    ["res"] = "Ress", -- Alternative spelling
    ["assist"] = "Assist",
    ["scout"] = "Scout",
    ["lead"] = "Lead",
    ["mc"] = "MC",
    ["kick"] = "Kick",
    ["decurse"] = "Decurse",
    ["taunt"] = "Taunt",
    ["md"] = "MD",
    ["sap"] = "Sap",
    ["purge"] = "Purge",
    ["shackle"] = "Shackle",
    ["banish"] = "Banish",
    ["kite"] = "Kite",
    ["bomb"] = "Bomb",
    ["interrupt"] = "Interrupt"
}

-- Get the appropriate role icon name based on role text
function TWRA.UI:GetRoleIconName(roleText)
    if not roleText then return "Misc" end
    
    -- Convert to lowercase for comparison
    local lowerRole = string.lower(roleText)
    
    -- Check each mapping
    for keyword, iconName in pairs(self.ROLE_MAPPINGS) do
        if string.find(lowerRole, keyword) then
            return iconName
        end
    end
    
    -- Default fallback
    return "Misc"
end

-- Apply class coloring to a text element
function TWRA.UI:ApplyClassColoring(textElement, name)
    if not textElement or not name then return end
    
    -- Class group check
    local className = TWRA.CLASS_GROUP_NAMES[name]
    
    -- If name is a class group, use class colors
    if className then
        local color = TWRA.VANILLA_CLASS_COLORS[className]
        if color then
            textElement:SetTextColor(color.r, color.g, color.b)
            return
        end
    end
    
    -- Check if it's a player name
    local isInRaid, isOnline = TWRA:GetPlayerStatus(name)
    
    if isInRaid then
        local playerClass = TWRA:GetPlayerClass(name)
        if playerClass and TWRA.VANILLA_CLASS_COLORS[playerClass] then
            local color = TWRA.VANILLA_CLASS_COLORS[playerClass]
            
            -- Gray out if offline
            if not isOnline then
                textElement:SetTextColor(color.r * 0.5, color.g * 0.5, color.b * 0.5)
            else
                textElement:SetTextColor(color.r, color.g, color.b)
            end
        else
            -- No class found, use default coloring
            textElement:SetTextColor(1, 1, 1)
        end
    else
        -- Not in raid - default white with slight dimming
        textElement:SetTextColor(0.9, 0.9, 0.9)
    end
end

-- Helper function to extract texture and coordinates from an icon string
function TWRA.UI:GetTextureInfo(iconString)
    if not iconString then return nil, nil end
    
    -- Check if this is a formatted string with texture coordinates
    local pattern = "(.+):(%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(%d+)"
    local texture, width, height, xOffset, yOffset, texWidth, texHeight, left, right, top, bottom = string.find(iconString, pattern)
    
    -- If pattern match failed, try the older direct method
    if not texture then
        -- Match function expects pattern first, then string
        texture, width, height, xOffset, yOffset, texWidth, texHeight, left, right, top, bottom = 
            string.match(iconString, "(.+):(%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(%d+):(%d+)")
    end
    
    if texture then
        -- Return parsed texture and coordinates
        return texture, {
            left = tonumber(left)/tonumber(texWidth), 
            right = tonumber(right)/tonumber(texWidth), 
            top = tonumber(top)/tonumber(texHeight), 
            bottom = tonumber(bottom)/tonumber(texHeight),
            width = tonumber(width),
            height = tonumber(height)
        }
    else
        -- Return just the texture without coordinates
        return iconString, nil
    end
end

TWRA:Debug("ui", "Icons module loaded")