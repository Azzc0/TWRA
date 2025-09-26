-- Create a ScrollingMessageFrame (more reliable for hyperlinks in 1.12)
local frame = CreateFrame("ScrollingMessageFrame", "MyClickableFrame", UIParent)
frame:SetWidth(400)
frame:SetHeight(20)
frame:SetPoint("CENTER", 0, 0)
frame:SetFontObject(ChatFontNormal)
frame:SetJustifyH("LEFT")
frame:SetFading(false)
frame:SetMaxLines(1)

-- In 1.12, hyperlinks should work by default on ScrollingMessageFrame
-- Set up the hyperlink handler
frame:SetScript("OnHyperlinkClick", function()
    if arg1 and arg2 then
        -- Handle different hyperlink types
        if string.find(arg1, "^item:") then
            SetItemRef(arg1, arg2, arg3)
        elseif string.find(arg1, "^player:") then
            SetItemRef(arg1, arg2, arg3)
        else
            -- Handle custom hyperlinks like your twra: links
            DEFAULT_CHAT_FRAME:AddMessage("Clicked: " .. arg1 .. " - " .. arg2)
        end
    end
end)

-- Add your message
frame:AddMessage("|cffa335ee|Hitem:15138:0:0:0:0:0:0:0|h[Onyxia Scale Cloak]|h|r|cffb2a08e to mitigate |cff71d5ff|Htwra:Arcane Prison:51107|h[Arcane Prison]|h|r|cffb2a08e")